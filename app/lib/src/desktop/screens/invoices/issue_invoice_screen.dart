// SPDX-License-Identifier: Apache-2.0
/// Request a payment: a paired contact whose wallet pays requests, or a
/// payment file for anyone; how much and why. Nothing leaves the wallet, so no password.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n.dart' show LocalizedFormatException;
import '../../../models.dart' show PairingRecord, PairingState;
import '../../../slate_files.dart' show sendFileName;
import '../../../trust_ids.dart';
import '../../data/history_files.dart';
import '../../data/invoice_state.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/pairing_state.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../scan/desk_scan.dart' show DeskPasted, DeskScanned;
import '../transfer/file_panels.dart' show FileChip, ResultPanel, ResultGlyph;
import '../transfer/finalize_screen.dart' show FinalizeArgs;
import '../transfer/qr_payment.dart';
import 'invoice_parts.dart';

/// The To select's value for "Save as a file for anyone".
const String _fileItem = '\u0001file'; // l10n-ok

/// The keys of the request form's file parts, for tests.
const Key deskRequestSaveFileKey = ValueKey('desk-request-save-file');
const Key deskRequestFileDoneKey = ValueKey('desk-request-file-done');

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

  /// "Save as a file for anyone" is chosen; null until the user picks, when it is the choice
  /// only while no paired contact pays requests.
  bool? _toFile;

  /// The request saved as a file, and where (null until the save dialog saved it).
  RequestFileMade? _made;
  String? _path;
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
    if (_amount.text.trim().isEmpty) return l.deskInvIssuerAmountMissing;
    final int p;
    try {
      p = parseEpicIn(l, _amount.text);
    } on AmountFormatException catch (e) {
      // Epic's supply cap is the parser's: no request asks for more.
      return switch (e.problem) {
        AmountProblem.malformed => l.deskInvIssuerAmountMissing,
        AmountProblem.decimals => l.deskInvIssuerAmountDecimals,
        AmountProblem.tooLarge => l.deskInvIssuerAmountCap,
      };
    } on LocalizedFormatException catch (e) {
      return e.text(l);
    }
    if (p <= 0) return l.deskInvIssuerAmountZero;
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
          .request(PaymentRequestDraft(pairingId: to, payerName: name, amount: parseEpicIn(l, _amount.text), message: _msg));
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

  /// Makes the request file, then the system dialog saves it (DESIGN §3.2). Nothing is
  /// spent, so no password; the request waits in Requests sent.
  Future<void> _saveFile() async {
    setState(() {
      _submitted = true;
      _failure = null;
    });
    if (_amountError() != null || _messageBytes > requestMessageMaxBytes) return;
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final made = await ref.read(deskInvoicesProvider.notifier).requestFile(parseEpicIn(l, _amount.text), _msg);
      if (!mounted) return;
      setState(() => _made = made);
      await _saveMade(made);
    } on Object catch (e) {
      if (mounted) setState(() => _failure = deskErrorText(e, l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The system save dialog for the made request; closing it leaves the panel's Save button.
  Future<void> _saveMade(RequestFileMade made) async {
    final path = await ref.read(deskHistoryFilesProvider).save(
      name: sendFileName(made.slateId),
      bytes: Uint8List.fromList(utf8.encode(made.json)),
      title: context.l10n.reqFileTitle,
    );
    if (mounted && path != null) setState(() => _path = path);
  }

  /// The payer's answer, scanned as a QR code: Finalize takes it, as an opened answer file.
  Future<void> _scanReply() async {
    final l = context.l10n;
    final got = await deskScanSlate(context, ref, title: l.qrScanReply, hint: l.deskQrAimReply, notSlate: (l) => l.qrScanNotReply);
    if (!mounted || got == null) return;
    final text = switch (got) {
      DeskScanned(:final value) => value,
      DeskPasted(:final text) => text,
    };
    ref.read(deskNavProvider.notifier).go(DeskRoute.finalize, FinalizeArgs(text: text));
  }

  /// Another request: the form again, empty.
  void _another() => setState(() {
    _made = null;
    _path = null;
    _submitted = false;
    _amount.clear();
    _message.clear();
  });

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
    // Request files off (the core or the Invoices switch): contacts only.
    final byFile = deskRequestFilesOn(ref);
    // The file is the choice the user made, or the only one while no contact pays requests.
    final toFile = byFile && (_toFile ?? (payers.isEmpty && to == null));
    final made = _made;
    if (made != null) {
      return EPage(
        title: l.reqNewTitle,
        width: EPageWidth.mid,
        onBack: () => ref.read(deskNavProvider.notifier).back(),
        child: ResultPanel(
          key: deskRequestFileDoneKey,
          glyph: const ResultGlyph(icon: EIcons.file),
          title: l.reqFileSaved,
          text: l.reqFileLead,
          body: _path == null ? null : FileChip(_path!),
          actions: [
            if (_path == null) InvButton(label: l.reqSaveFile, icon: EIcons.file, kind: EBtnKind.primary, width: InvW.md, onPressed: () => _saveMade(made)),
            DeskShowQrButton(key: const ValueKey('req-file-qr'), kind: DeskQrKind.request, json: made.json, size: EBtnSize.sm, onScanReply: _scanReply),
            InvButton(label: l.deskInvIssuerAnother, icon: EIcons.request, kind: _path == null ? EBtnKind.secondary : EBtnKind.primary, width: InvW.md, onPressed: _another),
          ],
        ),
      );
    }

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(byFile ? l.reqNewLead : l.reqNewLeadContacts, style: ts.bodyDim),
        SizedBox(height: Sp.x5),
        if (relayDown && !toFile) ...[
          ENotice(tone: ETone.risk, icon: EIcons.epicbox, title: l.deskInvIssuerRelayDown),
          SizedBox(height: Sp.x5),
        ],
        EField(
          label: l.reqNewTo,
          // No file to save on a core without request files: the hint names contacts only.
          help: payers.isEmpty ? (byFile ? l.reqNoPayers : l.reqNoPayersContacts) : (byFile ? l.reqNewToHint : l.reqNewToHintContacts),
          error: _submitted && !toFile && to == null && payers.isNotEmpty ? l.reqPickContact : null,
          child: SizedBox(
            width: InvW.lg * 1.4,
            child: ESelect<String>(
              semanticLabel: l.reqNewTo,
              value: toFile ? _fileItem : to?.id ?? '',
              items: [
                if (payers.isNotEmpty || !byFile) ESelectItem('', l.reqPickContact),
                for (final r in payers) ESelectItem(r.id, deskPairingName(r, st.contacts), subtitle: l.trustVerified),
                if (byFile) ESelectItem(_fileItem, l.reqToFile),
              ],
              onChanged: (id) => setState(() {
                _toFile = id == _fileItem;
                if (id != _fileItem) _to = id.isEmpty ? null : id;
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
              semanticsId: TrustIds.invIssueAmount,
              controller: _amount,
              mono: true,
              invalid: amountErr != null,
              hint: '0.00',
              trailing: Padding(padding: EdgeInsets.only(right: Sp.x3), child: Text(epicUnit, style: ts.small.copyWith(color: c.dim))),
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
          help: l.deskSendMessageCount(bytes, requestMessageMaxBytes),
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
            if (toFile)
              InvButton(
                key: deskRequestSaveFileKey,
                label: l.reqSaveFile,
                icon: EIcons.file,
                kind: EBtnKind.primary,
                size: EBtnSize.md,
                width: InvW.md,
                busy: _busy,
                onPressed: _busy ? null : _saveFile,
              )
            else
              InvButton(
                semanticsId: TrustIds.invIssueSend,
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
