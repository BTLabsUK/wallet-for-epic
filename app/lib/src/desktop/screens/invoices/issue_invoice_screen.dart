/// Request a payment (SPEC 2.8, desktop): a paired contact whose wallet pays requests, or a
/// payment file for anyone; how much and why. Nothing leaves the wallet, so no password.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n.dart' show LocalizedFormatException;
import '../../../models.dart' show PairingRecord, PairingState;
import '../../../slate_files.dart' show sendFileName;
import '../../data/history_files.dart';
import '../../data/invoice_state.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../data/pairing_state.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'invoice_parts.dart';

/// Epic's supply cap, in nanoepic: no request asks for more.
const int _supplyCap = 21000000 * nanoPerEpic;

/// The paired contacts a request can go to: verified, and their card says they pay requests.
List<PairingRecord> deskRequestPayers(Iterable<PairingRecord> all) => [
  for (final r in all)
    if (r.state == PairingState.verified && r.caps.paysInvoices) r,
];

class IssueInvoiceScreen extends ConsumerStatefulWidget {
  const IssueInvoiceScreen({super.key, this.arg});

  /// A pairing id or a [Contact] (its pairing) to ask.
  final Object? arg;

  @override
  ConsumerState<IssueInvoiceScreen> createState() => _IssueInvoiceScreenState();
}

class _IssueInvoiceScreenState extends ConsumerState<IssueInvoiceScreen> {
  final _amount = TextEditingController();
  final _message = TextEditingController();
  String? _to;
  bool _submitted = false;
  bool _busy = false;
  String? _failure;

  @override
  void initState() {
    super.initState();
    _apply(widget.arg);
  }

  @override
  void didUpdateWidget(IssueInvoiceScreen old) {
    super.didUpdateWidget(old);
    if (widget.arg != old.arg) _apply(widget.arg);
  }

  void _apply(Object? a) {
    if (a is String) {
      _to = a;
    } else if (a is Contact) {
      _to = ref.read(deskContactPairingProvider(a.id))?.id;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  String? _amountError() {
    final l = context.l10n;
    final int? p;
    try {
      p = parseEpicIn(l, _amount.text);
    } on LocalizedFormatException catch (e) {
      return e.text(l);
    }
    if (_amount.text.trim().isEmpty || p == null) return l.deskInvIssuerAmountMissing;
    if (p == epicTooLong) return l.deskInvIssuerAmountDecimals;
    if (p <= 0) return l.deskInvIssuerAmountZero;
    if (p > _supplyCap) return l.deskInvIssuerAmountCap;
    return null;
  }

  int get _messageBytes => utf8.encode(_message.text).length;

  String? get _msg => _message.text.trim().isEmpty ? null : _message.text.trim();

  Future<void> _request() async {
    setState(() {
      _submitted = true;
      _failure = null;
    });
    // Only a payer listed now: a pairing gone meanwhile asks for a contact again.
    final payers = deskRequestPayers(ref.read(deskPairingsProvider).value ?? const <PairingRecord>[]);
    final to = payers.where((r) => r.id == _to).firstOrNull?.id;
    if (to == null || _amountError() != null || _messageBytes > requestMessageMaxBytes) return;
    setState(() => _busy = true);
    final l = context.l10n;
    final name = ref.read(deskPairingNameProvider(to));
    try {
      await ref
          .read(deskInvoicesProvider.notifier)
          .request(PaymentRequestDraft(pairingId: to, payerName: name, amount: parseEpicIn(l, _amount.text)!, message: _msg));
      if (!mounted) return;
      showEToast(context, l.reqSent(name), tone: ETone.ok);
      ref.read(deskNavProvider.notifier).go(DeskRoute.invoices, InvoicesTab.issue);
    } on InvoiceError catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = e.problem == InvoiceProblem.notDelivered || e.problem == InvoiceProblem.relayDown ? l.deskInvIssuerNotDelivered : l.deskInvFailed;
      });
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _failure = l.deskInvFailed;
        });
      }
    }
  }

  Future<void> _saveFile() async {
    setState(() {
      _submitted = true;
      _failure = null;
    });
    if (_amountError() != null || _messageBytes > requestMessageMaxBytes) return;
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final slate = await deskPairingCall(ref, (api) => api.requestFile(amount: BigInt.from(parseEpicIn(l, _amount.text)!), message: _msg));
      final path = await ref.read(deskHistoryFilesProvider).save(
        name: sendFileName(slate.slateId),
        bytes: Uint8List.fromList(utf8.encode(slate.json)),
        title: l.reqFileTitle,
      );
      if (mounted && path != null) showEToast(context, l.reqFileSaved, text: path, tone: ETone.ok);
    } on Object catch (e) {
      if (mounted) setState(() => _failure = deskErrorText(e, l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final st = ref.watch(deskProvider);
    final book = ref.watch(deskInvoicesProvider);
    final relayDown = st.status?.epicboxHealth == ServiceHealth.down || book?.check == InvoiceCheck.failed;
    final payers = deskRequestPayers(ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[]);
    final amountErr = _submitted ? _amountError() : null;
    final bytes = _messageBytes;
    final hours = (book?.expiry ?? defaultInvoiceExpiry).inHours;
    final to = payers.where((r) => r.id == _to).firstOrNull;
    // LEPIC requests from paired contacts only: no file to save.
    final byFile = ref.watch(deskApiProvider).supportsRequestFiles;

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(byFile ? l.reqNewLead : l.reqNewLeadContacts, style: ts.bodyDim),
        SizedBox(height: Sp.x5),
        if (relayDown) ...[
          ENotice(tone: ETone.risk, icon: EIcons.epicbox, title: l.deskInvIssuerRelayDown),
          SizedBox(height: Sp.x5),
        ],
        EField(
          label: l.reqNewTo,
          // No file to save on a core without request files: the hint names contacts only.
          help: payers.isEmpty ? (byFile ? l.reqNoPayers : l.reqNoPayersContacts) : (byFile ? l.reqNewToHint : l.reqNewToHintContacts),
          error: _submitted && to == null && payers.isNotEmpty ? l.reqPickContact : null,
          child: SizedBox(
            width: InvW.lg * 1.4,
            child: ESelect<String>(
              semanticLabel: l.reqNewTo,
              value: to?.id ?? '',
              items: [
                ESelectItem('', l.reqPickContact),
                for (final r in payers) ESelectItem(r.id, deskPairingName(r, st.contacts), subtitle: l.trustVerified),
              ],
              onChanged: (id) => setState(() {
                _to = id.isEmpty ? null : id;
                _failure = null;
              }),
            ),
          ),
        ),
        SizedBox(height: Sp.x5),
        EField(
          label: l.deskInvIssuerAmount,
          help: l.deskInvIssuerAmountHelp,
          error: amountErr,
          child: SizedBox(
            width: InvW.lg,
            child: EInput(
              controller: _amount,
              mono: true,
              invalid: amountErr != null,
              hint: '0.00',
              trailing: Padding(padding: EdgeInsets.only(right: Sp.x3), child: Text('EPIC', style: ts.small.copyWith(color: c.dim))),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              semanticLabel: l.deskInvIssuerAmount,
              onChanged: (_) => setState(() => _failure = null),
            ),
          ),
        ),
        SizedBox(height: Sp.x5),
        EField(
          label: l.deskInvIssuerMessage,
          optional: true,
          help: l.deskInvIssuerMessageCount(bytes, requestMessageMaxBytes),
          error: bytes > requestMessageMaxBytes ? l.deskInvIssuerMessageLong : null,
          child: EInput(controller: _message, maxLines: 3, semanticLabel: l.deskInvIssuerMessage, onChanged: (_) => setState(() {})),
        ),
        SizedBox(height: Sp.x4),
        Row(
          children: [
            Icon(EIcons.clock, size: Ctl.iconSm, color: c.dim),
            SizedBox(width: Sp.x2),
            Expanded(child: Text(l.deskInvIssuerExpiry(hours), style: ts.bodyDim)),
          ],
        ),
        if (_failure != null) ...[
          SizedBox(height: Sp.x4),
          ENotice(tone: ETone.risk, icon: EIcons.error, title: _failure!),
        ],
        SizedBox(height: Sp.x6),
        Wrap(
          spacing: Sp.x3,
          runSpacing: Sp.x2,
          children: [
            if (byFile) InvButton(label: l.reqNewSaveFile, icon: EIcons.file, width: InvW.md, onPressed: _busy ? null : _saveFile),
            InvButton(
              label: l.reqNewSend,
              icon: EIcons.request,
              kind: EBtnKind.primary,
              size: EBtnSize.md,
              width: InvW.md,
              busy: _busy,
              onPressed: _busy || relayDown || payers.isEmpty ? null : _request,
            ),
          ],
        ),
      ],
    );

    return EPage(
      title: l.reqNewTitle,
      width: EPageWidth.mid,
      onBack: () => ref.read(deskNavProvider.notifier).back(),
      child: EPanel(child: form),
    );
  }
}
