/// Request a payment (docs/invoices/flow.md §3.1, §3.2): who pays, how much, and what the payer
/// must have done first. Nothing leaves the wallet, so no password.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n.dart' show LocalizedFormatException;
import '../../desk_l10n.dart';
import '../../data/invoice_state.dart';
import '../../widgets/kit.dart';
import 'invoice_parts.dart';

/// Epic's supply cap, in nanoepic: no request asks for more.
const int _supplyCap = 21000000 * nanoPerEpic;

enum _Method { epicbox, file, direct }

class IssueInvoiceScreen extends ConsumerStatefulWidget {
  const IssueInvoiceScreen({super.key, this.arg});

  /// A [Contact] or an invoice address to start from.
  final Object? arg;

  @override
  ConsumerState<IssueInvoiceScreen> createState() => _IssueInvoiceScreenState();
}

class _IssueInvoiceScreenState extends ConsumerState<IssueInvoiceScreen> {
  final _payer = TextEditingController();
  final _amount = TextEditingController();
  final _message = TextEditingController();
  String? _payerName;
  bool _submitted = false;
  bool _busy = false;
  String? _failure;
  PeerCapability? _capability;
  String _checkedFor = '';

  @override
  void initState() {
    super.initState();
    _apply(widget.arg);
    WidgetsBinding.instance.addPostFrameCallback((_) => _probe());
  }

  @override
  void didUpdateWidget(IssueInvoiceScreen old) {
    super.didUpdateWidget(old);
    if (widget.arg == old.arg) return;
    _apply(widget.arg);
    WidgetsBinding.instance.addPostFrameCallback((_) => _probe());
  }

  void _apply(Object? a) {
    if (a is Contact) {
      _payer.text = a.invoiceAddress ?? '';
      _payerName = a.name;
    } else if (a is String) {
      _payer.text = a;
      _payerName = null;
    }
  }

  @override
  void dispose() {
    _payer.dispose();
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  /// Asks what the wallet knows of the payer's wallet, once per valid address.
  Future<void> _probe() async {
    final t = _payer.text.trim();
    if (!mounted || t == _checkedFor) return;
    _checkedFor = t;
    if (_payerError(t) != null) {
      setState(() => _capability = null);
      return;
    }
    PeerCapability? cap;
    try {
      cap = await ref.read(deskInvoicesProvider.notifier).capability(t);
    } on Object {
      // A well-formed address LEPIC does not accept (no relay on this network): the form
      // checks the address on Issue; the probe only adds a hint.
      cap = null;
    }
    if (mounted && _payer.text.trim() == t) setState(() => _capability = cap);
  }

  String? _payerError(String t) {
    final l = context.l10n;
    if (t.isEmpty) return l.deskInvIssuerPayerMissing;
    final api = ref.read(deskApiProvider);
    final p = parseAddress(t, api);
    if (p.kind == AddressKind.http || p.kind == AddressKind.tor) return l.deskInvIssuerPayerHttp;
    if (p.kind != AddressKind.epicbox || !p.complete) return l.deskInvIssuerPayerInvalid;
    final own = [ref.read(deskProvider).epicboxAddress, ref.read(deskInvoicesProvider)?.invoiceAddress];
    if (own.any((o) => o != null && addressKey(o) == addressKey(t))) return l.deskInvIssuerPayerOwn;
    return null;
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

  Future<void> _request() async {
    setState(() {
      _submitted = true;
      _failure = null;
    });
    final payer = _payer.text.trim();
    if (_payerError(payer) != null || _amountError() != null || _messageBytes > requestMessageMaxBytes) return;
    setState(() => _busy = true);
    final l = context.l10n;
    final contacts = ref.read(deskProvider).contacts ?? const <Contact>[];
    final name = _payerName ?? contacts.where((c) => c.invoiceAddress != null && addressKey(c.invoiceAddress!) == addressKey(payer)).firstOrNull?.name;
    try {
      final msg = _message.text.trim();
      await ref
          .read(deskInvoicesProvider.notifier)
          .request(PaymentRequestDraft(payerAddress: payer, payerName: name, amount: parseEpicIn(l, _amount.text)!, message: msg.isEmpty ? null : msg));
      if (!mounted) return;
      showEToast(context, l.deskInvIssuerSent(name ?? shortAddress(payer)), tone: ETone.ok);
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final st = ref.watch(deskProvider);
    final book = ref.watch(deskInvoicesProvider);
    final own = st.epicboxAddress ?? '';
    final relayDown = st.status?.epicboxHealth == ServiceHealth.down || book?.check == InvoiceCheck.failed;
    final payer = _payer.text.trim();
    final payerErr = _submitted || payer.isNotEmpty ? _payerError(payer) : null;
    final amountErr = _submitted ? _amountError() : null;
    final bytes = _messageBytes;
    final withInvoice = [for (final x in st.contacts ?? const <Contact>[]) if (x.invoiceAddress != null) x];
    final hours = (book?.expiry ?? defaultInvoiceExpiry).inHours;

    final first = EPanel(
      title: l.deskInvIssuerFirstTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.deskInvIssuerStepsIntro, style: ts.body),
          SizedBox(height: Sp.x2),
          Text(l.deskInvIssuerStepTrust, style: ts.bodyDim),
          SizedBox(height: Sp.x1),
          Text(l.deskInvIssuerStepAddress, style: ts.bodyDim),
          SizedBox(height: Sp.x4),
          Text(l.deskInvIssuerYourAddress, style: ts.label),
          SizedBox(height: Sp.x2),
          if (own.isNotEmpty)
            EQrReveal(address: own, form: QrRevealForm.compact, title: l.deskInvEpicboxAddress, copyLabel: l.deskInvIssuerYourAddress)
          else
            const ESpinner(),
        ],
      ),
    );

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Why Issue is off, first, so it shows without scrolling.
        if (relayDown) ...[
          ENotice(tone: ETone.risk, icon: EIcons.epicbox, title: l.deskInvIssuerRelayDown),
          SizedBox(height: Sp.x5),
        ],
        EField(
          label: l.deskInvIssuerMethod,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: Sp.x3,
              runSpacing: Sp.x2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ESegmented<_Method>(
                  value: _Method.epicbox,
                  onChanged: (_) {},
                  segments: [
                    ESegment(_Method.epicbox, l.deskInvIssuerEpicbox, icon: EIcons.epicbox),
                    ESegment(_Method.file, l.deskInvIssuerFile, icon: EIcons.file, enabled: false, tooltip: l.deskInvIssuerSoon),
                    ESegment(_Method.direct, l.deskInvIssuerDirect, icon: EIcons.link, enabled: false, tooltip: l.deskInvIssuerSoon),
                  ],
                ),
                Text('${l.deskInvIssuerFile}, ${l.deskInvIssuerDirect}: ${l.deskInvIssuerSoon}', style: ts.small.copyWith(color: c.dim)),
              ],
            ),
          ),
        ),
        SizedBox(height: Sp.x5),
        EField(
          label: l.deskInvIssuerPayer,
          help: l.deskInvIssuerPayerHelp,
          error: payerErr,
          child: Row(
            children: [
              Expanded(
                child: EInput(
                  controller: _payer,
                  mono: true,
                  invalid: payerErr != null,
                  hint: l.deskInvAddressHint,
                  semanticLabel: l.deskInvIssuerPayer,
                  onChanged: (_) {
                    setState(() {
                      _payerName = null;
                      _failure = null;
                    });
                    _probe();
                  },
                ),
              ),
              SizedBox(width: Sp.x2),
              SizedBox(
                width: InvW.md,
                child: ESelect<String>(
                  semanticLabel: l.deskInvIssuerContacts,
                  value: '',
                  items: [
                    ESelectItem('', l.deskInvIssuerContacts),
                    for (final x in withInvoice) ESelectItem(x.id, x.name, subtitle: shortAddress(x.invoiceAddress!)),
                  ],
                  onChanged: (id) {
                    final x = withInvoice.where((x) => x.id == id).firstOrNull;
                    if (x == null) return;
                    setState(() {
                      _payer.text = x.invoiceAddress!;
                      _payerName = x.name;
                      _failure = null;
                    });
                    _probe();
                  },
                ),
              ),
            ],
          ),
        ),
        if (payerErr == null && _capability == PeerCapability.noInvoices) ...[
          SizedBox(height: Sp.x3),
          ENotice(
            tone: ETone.warn,
            icon: EIcons.alert,
            title: l.deskInvIssuerNoInvoices,
            actions: [InvButton(label: l.deskInvIssuerUseFile, tooltip: l.deskInvIssuerSoon, onPressed: null)],
          ),
        ],
        if (payerErr == null && _capability == PeerCapability.unknown) ...[
          SizedBox(height: Sp.x3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(EIcons.info, size: Ctl.iconSm, color: c.dim),
              SizedBox(width: Sp.x2),
              Expanded(child: Text(l.deskInvIssuerUnknown, style: ts.small.copyWith(color: c.dim))),
            ],
          ),
        ],
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
        SizedBox(height: Sp.x2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(EIcons.monitor, size: Ctl.iconSm, color: c.dim),
            SizedBox(width: Sp.x2),
            Expanded(child: Text(l.deskInvOneDevice, style: ts.small.copyWith(color: c.dim))),
          ],
        ),
        if (_failure != null) ...[
          SizedBox(height: Sp.x4),
          ENotice(tone: ETone.risk, icon: EIcons.error, title: _failure!),
        ],
        SizedBox(height: Sp.x6),
        Row(
          children: [
            InvButton(
              label: l.deskInvIssuerIssue,
              icon: EIcons.request,
              kind: EBtnKind.primary,
              size: EBtnSize.md,
              width: InvW.md,
              busy: _busy,
              onPressed: _busy || relayDown ? null : _request,
            ),
            if (_submitted && (payerErr != null || amountErr != null)) ...[
              SizedBox(width: Sp.x4),
              Expanded(child: Text(l.deskInvIssuerFixFields, style: ts.small.copyWith(color: c.risk))),
            ],
          ],
        ),
      ],
    );

    return EPage(
      title: l.deskInvIssuerFormTitle,
      width: EPageWidth.mid,
      onBack: () => ref.read(deskNavProvider.notifier).back(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [first, SizedBox(height: Sp.x5), EPanel(child: form)]),
    );
  }
}
