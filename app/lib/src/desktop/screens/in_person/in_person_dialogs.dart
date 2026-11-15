// SPDX-License-Identifier: Apache-2.0
/// The desktop's in-person payments (spec D3, D5, P6): one dialog that makes a code, shows it
/// and asks the check, and one that reviews a pasted code and answers it. The desktop has no
/// camera: answers come through the server or are pasted.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../epic1.dart';
import '../../../l10n.dart' show LocalizedFormatException;
import '../../../models.dart' show WalletError, WalletErrorKind, slateMessageMaxBytes;
import '../../../qr_slate.dart' show QrFrames;
import '../../../trust_ids.dart';
import '../../../ui/in_person/in_person_logic.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../../../ui/in_person/in_person_scan.dart' show InPersonScanned;
import '../scan/desk_scan.dart';
import 'in_person_online.dart';
import 'in_person_reader.dart';

/// Test keys.
const Key deskInPersonAmountKey = ValueKey('desk-ip-amount');
const Key deskInPersonMessageKey = ValueKey('desk-ip-message');
const Key deskInPersonPasswordKey = ValueKey('desk-ip-password');
const Key deskInPersonQrKey = ValueKey('desk-ip-qr');
const Key deskInPersonCodeTextKey = ValueKey('desk-ip-code-text');
const Key deskInPersonCheckKey = ValueKey('desk-ip-check');

/// The dialog's title for a code of [stage] this wallet shows.
String deskInPersonTitle(BuildContext context, InPersonStage stage) =>
    stage == InPersonStage.request ? context.l10n.deskIpRequestTitle : context.l10n.deskIpPayTitle;

/// The dialog's title for a pasted code of [stage].
String deskInPersonReviewTitle(BuildContext context, InPersonStage stage) =>
    stage == InPersonStage.send ? context.l10n.deskIpReceiveTitle : context.l10n.deskIpPayRequestTitle;

/// Checks the wallet password before [password] spends; the error to show, or null.
Future<String?> deskInPersonPasswordError(WidgetRef ref, AppLocalizations l, String password) async {
  if (password.isEmpty) return l.deskInvPayerEnterPassword;
  if (!await ref.read(deskApiProvider).checkPassword(password)) return l.deskInvPayerWrongPassword;
  return null;
}

/// Request or pay in person: the form, then the code and its check. With [watch] (an answer
/// pasted outside its code's dialog) it opens at the check.
const Key deskIpScanKey = ValueKey('desk-ip-scan');

class DeskInPersonCodeDialog extends ConsumerStatefulWidget {
  const DeskInPersonCodeDialog({super.key, required this.stage, this.watch});

  final InPersonStage stage;
  final InPersonCodeWatch? watch;

  @override
  ConsumerState<DeskInPersonCodeDialog> createState() => _DeskInPersonCodeDialogState();
}

class _DeskInPersonCodeDialogState extends ConsumerState<DeskInPersonCodeDialog> {
  final _amount = TextEditingController();
  final _message = TextEditingController();
  final _password = TextEditingController(text: deskNoLock ? 'demo' : '');
  InPersonCodeWatch? _watch;
  bool _submitted = false;
  bool _busy = false;
  String? _failure;
  String? _passwordError;
  String? _pasteError;

  bool get _send => widget.stage == InPersonStage.send;
  String? get _msg => _message.text.trim().isEmpty ? null : _message.text.trim();

  @override
  void initState() {
    super.initState();
    _watch = widget.watch?..addListener(_changed);
  }

  @override
  void dispose() {
    _watch?.removeListener(_changed);
    _watch?.dispose();
    _amount.dispose();
    _message.dispose();
    _password.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  String? _amountError() {
    final l = context.l10n;
    if (_amount.text.trim().isEmpty) return l.deskInvIssuerAmountMissing;
    final int p;
    try {
      p = parseEpicIn(l, _amount.text);
    } on AmountFormatException catch (e) {
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

  /// A new code for the amount and message given: the first, or one after P6 or expiry.
  Future<InPersonCodeMade> _code(Epic1Wallet wallet, BigInt amount) async {
    if (!_send) return wallet.inPersonRequest(amount: amount, message: _msg);
    final api = ref.read(deskApiProvider);
    return wallet.inPersonSend(amount: amount, minimumConfirmations: BigInt.from(await api.minimumConfirmations()), message: _msg);
  }

  Future<void> _make() async {
    final l = context.l10n;
    setState(() {
      _submitted = true;
      _failure = null;
      _passwordError = null;
    });
    if (_amountError() != null || _messageBytes > slateMessageMaxBytes) return;
    final wallet = ref.read(deskApiProvider).epic1;
    if (wallet == null) return;
    final amount = BigInt.from(parseEpicIn(l, _amount.text));
    setState(() => _busy = true);
    try {
      if (_send) {
        final refused = await deskInPersonPasswordError(ref, l, _password.text);
        if (refused != null) {
          if (mounted) setState(() => _passwordError = refused);
          return;
        }
      }
      final made = await _code(wallet, amount);
      if (!mounted) return;
      setState(() => _watch = InPersonCodeWatch(wallet: wallet, stage: widget.stage, amount: amount, made: made, boosts: ref.read(deskApiProvider).boosts)..addListener(_changed));
    } on Object catch (e) {
      if (mounted) setState(() => _failure = deskErrorText(e, l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "Show a new code" (P6, or after expiry): the same amount and message.
  Future<void> _renew() async {
    final watch = _watch;
    final amount = watch?.amount;
    final wallet = ref.read(deskApiProvider).epic1;
    if (watch == null || amount == null || wallet == null) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final made = await _code(wallet, amount);
      if (mounted) watch.renew(made);
    } on Object catch (e) {
      if (mounted) setState(() => _failure = deskErrorText(e, context.l10n));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Paste answer: reads the clipboard on the press only.
  Future<void> _paste() async {
    final watch = _watch;
    if (watch == null) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    final ok = text.isNotEmpty && await watch.take(text);
    if (mounted) setState(() => _pasteError = ok ? null : context.l10n.deskIpNotAnswer);
  }

  /// Scan answer: the camera (parts of an animated code included) or the dialog's paste.
  Future<void> _scanAnswer() async {
    final watch = _watch;
    final wallet = ref.read(deskApiProvider).epic1;
    if (watch == null || wallet == null) return;
    final l = context.l10n;
    final got = await deskScanParts<InPersonScanned>(context, title: l.deskIpScanAnswer, hint: l.deskIpScanAim, reader: DeskInPersonReader(wallet));
    if (got == null || !mounted) return;
    final bool ok;
    switch (got) {
      case DeskScanned<InPersonScanned>(:final value):
        final bytes = value.bytes;
        final text = value.text;
        ok = bytes != null ? await watch.takeBytes(bytes) : (text != null && text.isNotEmpty && await watch.take(text));
      case DeskPasted<InPersonScanned>(:final text):
        final t = text.trim();
        ok = t.isNotEmpty && await watch.take(t);
    }
    if (mounted) setState(() => _pasteError = ok ? null : context.l10n.deskIpNotAnswer);
  }

  @override
  Widget build(BuildContext context) {
    final watch = _watch;
    if (watch == null) return _form(context);
    final l = context.l10n;
    final title = deskInPersonTitle(context, watch.stage);
    final close = EButton(label: l.commonClose, onPressed: () => Navigator.of(context).pop());
    switch (watch.phase) {
      case InPersonPhase.waiting:
        return _waiting(context, watch, title);
      case InPersonPhase.check:
      case InPersonPhase.finishing:
        return _check(context, watch, title);
      case InPersonPhase.done:
        final amount = watch.amount;
        return EDialog(
          title: watch.stage == InPersonStage.send ? l.deskIpSent : l.deskIpReceived,
          tone: ETone.ok,
          description: amount == null ? null : '${formatEpicL(l, amount.toInt())} $epicUnit',
          actions: [EButton.primary(semanticsId: TrustIds.txIpDone, label: l.commonDone, onPressed: () => Navigator.of(context).pop())],
        );
      case InPersonPhase.stopped:
        return EDialog(title: title, tone: ETone.warn, description: l.deskE1PaymentStopped, actions: [close]);
      case InPersonPhase.sameCode:
      case InPersonPhase.expired:
        final failure = _failure;
        return EDialog(
          title: title,
          tone: ETone.warn,
          description: watch.phase == InPersonPhase.sameCode ? l.deskE1SameCodeTwice : l.deskE1ErrCodeExpired,
          body: failure == null ? null : ENotice(tone: ETone.risk, icon: EIcons.error, title: failure),
          actions: [
            close,
            if (watch.amount != null)
              EButton.primary(semanticsId: TrustIds.txIpNewcode, label: l.deskE1ShowNewCode, busy: _busy, onPressed: _busy ? null : _renew),
          ],
        );
    }
  }

  Widget _form(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final amountErr = _submitted ? _amountError() : null;
    final bytes = _messageBytes;
    final failure = _failure;
    return EDialog(
      title: deskInPersonTitle(context, widget.stage),
      icon: _send ? EIcons.send : EIcons.request,
      dismissible: !_busy,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          EField(
            label: l.deskInvIssuerAmount,
            error: amountErr,
            child: EInput(
              key: deskInPersonAmountKey,
              controller: _amount,
              mono: true,
              autofocus: true,
              invalid: amountErr != null,
              hint: '0.00',
              trailing: Padding(padding: EdgeInsets.only(right: Sp.x3), child: Text(epicUnit, style: ts.small.copyWith(color: c.dim))),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              semanticLabel: l.deskInvIssuerAmount,
              onChanged: (_) => setState(() => _failure = null),
            ),
          ),
          SizedBox(height: Sp.x4),
          EField(
            label: l.deskInvIssuerMessage,
            optional: true,
            help: l.deskSendMessageCount(bytes, slateMessageMaxBytes),
            error: bytes > slateMessageMaxBytes ? l.deskInvIssuerMessageLong : null,
            child: EInput(key: deskInPersonMessageKey, controller: _message, maxLines: 3, semanticLabel: l.deskInvIssuerMessage, onChanged: (_) => setState(() {})),
          ),
          if (failure != null) ...[
            SizedBox(height: Sp.x4),
            ENotice(tone: ETone.risk, icon: EIcons.error, title: failure),
          ],
        ],
      ),
      foot: !_send
          ? null
          : EField(
              label: l.deskInvPayerPassword,
              error: _passwordError,
              child: EPasswordInput(
                key: deskInPersonPasswordKey,
                controller: _password,
                invalid: _passwordError != null,
                semanticLabel: l.deskInvPayerPassword,
                onChanged: (_) => setState(() => _passwordError = null),
                onSubmitted: (_) => _busy ? null : _make(),
              ),
            ),
      actions: [
        EButton(label: l.commonCancel, onPressed: _busy ? null : () => Navigator.of(context).pop()),
        EButton.primary(semanticsId: TrustIds.txIpMake, label: l.deskIpMakeCode, busy: _busy, onPressed: _busy ? null : _make),
      ],
    );
  }

  Widget _waiting(BuildContext context, InPersonCodeWatch watch, String title) {
    final l = context.l10n;
    final ts = context.ts;
    final made = watch.made!;
    final amount = watch.amount;
    final tip = ref.watch(deskProvider.select((s) => s.status?.nodeHeight));
    final minutes = inPersonMinutesLeft(made.ttlCutoff, tip == null ? null : BigInt.from(tip));
    final paste = _pasteError;
    return EDialog(
      title: title,
      icon: EIcons.qr,
      description: watch.stage == InPersonStage.request ? l.deskIpCodeLeadRequest : l.deskIpCodeLeadPay,
      dismissible: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (amount != null) Text('${formatEpicL(l, amount.toInt())} $epicUnit', style: ts.h2),
          if (_msg != null) ...[SizedBox(height: Sp.x1), Text(_msg!, style: ts.bodyDim)],
          SizedBox(height: Sp.x4),
          Center(child: DeskInPersonQr(key: deskInPersonQrKey, parts: watch.parts, label: l.deskKitQrOf(l.deskIpCodeOf))),
          SizedBox(height: Sp.x4),
          DeskInPersonText(key: deskInPersonCodeTextKey, label: l.deskIpCodeText, text: base64Url.encode(made.bytes)),
          SizedBox(height: Sp.x3),
          if (minutes != null)
            Row(
              children: [
                Icon(EIcons.clock, size: Ctl.iconSm, color: context.dc.dim),
                SizedBox(width: Sp.x2),
                Expanded(child: Text(l.deskIpExpiresIn(minutes), style: ts.bodyDim)),
              ],
            ),
          SizedBox(height: Sp.x2),
          if (watch.online)
            DeskInPersonOnlineLine(online: watch)
          else
            Semantics(liveRegion: true, child: Text(l.deskIpWaiting, style: ts.bodyDim)),
          if (watch.manual) const DeskNoCameraLine(),
          if (paste != null) ...[
            SizedBox(height: Sp.x3),
            ENotice(tone: ETone.risk, icon: EIcons.error, title: paste),
          ],
        ],
      ),
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.of(context).pop()),
        if (watch.manual) ...[
          EButton(semanticsId: TrustIds.txIpPaste, label: l.deskIpPasteAnswer, icon: EIcons.paste, onPressed: _paste),
          DeskScanButton(key: deskIpScanKey, onScan: _scanAnswer),
        ],
      ],
    );
  }

  Widget _check(BuildContext context, InPersonCodeWatch watch, String title) {
    final l = context.l10n;
    final code = watch.checkCode ?? '';
    final finishing = watch.phase == InPersonPhase.finishing;
    final error = watch.error;
    return EDialog(
      title: title,
      icon: EIcons.shield,
      dismissible: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(watch.stage == InPersonStage.request ? l.deskIpCheckPayer(code) : l.deskIpCheckOther(code), style: context.ts.lead),
          SizedBox(height: Sp.x4),
          DeskInPersonCheck(key: deskInPersonCheckKey, code: code),
          if (error != null) ...[
            SizedBox(height: Sp.x4),
            ENotice(tone: ETone.risk, icon: EIcons.error, title: deskErrorText(error, l)),
          ],
        ],
      ),
      actions: [
        EButton(semanticsId: TrustIds.txIpDifferent, label: l.deskIpDifferent, onPressed: finishing ? null : watch.different),
        EButton.primary(semanticsId: TrustIds.txIpMatches, label: l.deskIpMatches, busy: finishing, onPressed: finishing ? null : watch.matches),
      ],
    );
  }
}

/// The four check digits, large.
class DeskInPersonCheck extends StatelessWidget {
  const DeskInPersonCheck({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      padding: EdgeInsets.symmetric(vertical: Sp.x4),
      decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.line)),
      alignment: Alignment.center,
      child: Text(code, style: context.ts.mono(size: Fs.display, color: c.accentText, weight: FontWeight.w600).copyWith(letterSpacing: Fs.display * 0.2)),
    );
  }
}

/// A code or answer as a QR code, covered until Show QR is pressed; a code too long for one
/// QR code shows its [parts] in turn. A new code covers it again.
class DeskInPersonQr extends StatefulWidget {
  const DeskInPersonQr({super.key, required this.parts, required this.label});

  final List<String> parts;

  /// What the code is, for screen readers.
  final String label;

  @override
  State<DeskInPersonQr> createState() => _DeskInPersonQrState();
}

class _DeskInPersonQrState extends State<DeskInPersonQr> {
  bool _shown = false;
  int _frame = 0;
  Timer? _frames;
  QrFrames? _drawn;

  /// The parts drawn once, in one version and mask.
  QrFrames _framesOf(List<String> parts) {
    final drawn = _drawn;
    if (drawn != null && identical(drawn.texts, parts)) return drawn;
    return _drawn = QrFrames.of(parts);
  }

  @override
  void didUpdateWidget(DeskInPersonQr old) {
    super.didUpdateWidget(old);
    if (old.parts.isEmpty || widget.parts.isEmpty || old.parts.first != widget.parts.first) _hide();
  }

  @override
  void dispose() {
    _frames?.cancel();
    super.dispose();
  }

  void _show() {
    setState(() {
      _shown = true;
      _frame = 0;
    });
    _frames?.cancel();
    if (widget.parts.length > 1) {
      _frames = Timer.periodic(inPersonFrameEvery, (_) {
        if (mounted) setState(() => _frame = (_frame + 1) % widget.parts.length);
      });
    }
  }

  void _hide() {
    _frames?.cancel();
    _frames = null;
    _shown = false;
    _frame = 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final size = 216.u;
    if (widget.parts.isEmpty) return const SizedBox.shrink();
    if (_shown) {
      return Semantics(
        image: true,
        label: widget.label,
        child: ExcludeSemantics(child: EQr.frame(_framesOf(widget.parts).images[_frame % widget.parts.length], size: size, epic1: true)),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.line)),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(EIcons.qr, size: 48.u, color: c.faint),
          SizedBox(height: Sp.x3),
          EButton(semanticsId: TrustIds.txIpReveal, label: context.l10n.qrShow, icon: EIcons.eye, size: EBtnSize.sm, onPressed: _show),
        ],
      ),
    );
  }
}

/// A code or answer as text, three lines at most, with Copy.
class DeskInPersonText extends StatelessWidget {
  const DeskInPersonText({super.key, required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return EField(
      label: label,
      child: Container(
        padding: EdgeInsets.fromLTRB(Sp.x3, Sp.x2, Sp.x2, Sp.x2),
        decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.line)),
        child: Row(
          children: [
            Expanded(child: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis, style: ts.mono(color: c.dim))),
            SizedBox(width: Sp.x2),
            ECopyButton(semanticsId: TrustIds.txIpCopy, text: text),
          ],
        ),
      ),
    );
  }
}

/// A pasted code: its review, the answer and its check code.
class DeskInPersonReviewDialog extends ConsumerStatefulWidget {
  const DeskInPersonReviewDialog({super.key, required this.code, required this.info});

  final Uint8List code;
  final InPersonCodeInfo info;

  @override
  ConsumerState<DeskInPersonReviewDialog> createState() => _DeskInPersonReviewDialogState();
}

class _DeskInPersonReviewDialogState extends ConsumerState<DeskInPersonReviewDialog> {
  final _password = TextEditingController(text: deskNoLock ? 'demo' : '');
  bool _busy = false;
  String? _failure;
  String? _passwordError;
  InPersonAnswerMade? _answer;

  /// The answer going to its code's server; null without a server or once declined.
  InPersonAnswerPost? _online;

  /// The answer is shown, not posted: the code names no server, or the server was declined.
  bool _noPost = false;

  /// The server is not in the list: asks before posting.
  bool _ask = false;
  List<String> _parts = const [];

  bool get _pay => widget.info.stage == InPersonStage.request;

  @override
  void dispose() {
    _password.dispose();
    _online?.removeListener(_changed);
    _online?.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _answerCode() async {
    final l = context.l10n;
    final api = ref.read(deskApiProvider);
    final wallet = api.epic1;
    if (wallet == null) return;
    setState(() {
      _busy = true;
      _failure = null;
      _passwordError = null;
    });
    try {
      final InPersonAnswerMade made;
      if (_pay) {
        final refused = await deskInPersonPasswordError(ref, l, _password.text);
        if (refused != null) {
          if (mounted) setState(() => _passwordError = refused);
          return;
        }
        made = await wallet.inPersonPay(widget.code, amount: widget.info.amount, minimumConfirmations: BigInt.from(await api.minimumConfirmations()));
      } else {
        made = await wallet.inPersonReceive(widget.code);
      }
      if (!mounted) return;
      _answer = made;
      _parts = wallet.qrParts(made.envelope);
      final mailbox = made.mailbox ?? widget.info.mailbox;
      if (mailbox == null) {
        setState(() => _noPost = true);
      } else if (!mailbox.inRelayList) {
        setState(() => _ask = true);
      } else {
        _start(mailbox);
      }
    } on Object catch (e) {
      if (mounted) setState(() => _failure = deskErrorText(e, l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Posts the answer to [mailbox], its code's server; the dialog follows the post.
  void _start(Epic1Host mailbox) {
    final answer = _answer;
    final wallet = ref.read(deskApiProvider).epic1;
    if (answer == null || wallet == null) return;
    final post = InPersonAnswerPost(wallet: wallet, slateId: answer.slateId, mailbox: mailbox, cutoff: widget.info.ttlCutoff)
      ..addListener(_changed);
    setState(() {
      _ask = false;
      _online = post;
    });
    unawaited(post.post());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final title = deskInPersonReviewTitle(context, widget.info.stage);
    final answer = _answer;
    if (answer != null && _ask) {
      final host = (answer.mailbox ?? widget.info.mailbox)!;
      return EDialog(
        title: l.deskIpUseServerAsk,
        tone: ETone.warn,
        description: l.deskIpNotInList(host.label),
        dismissible: false,
        actions: [
          EButton(label: l.commonCancel, onPressed: () => setState(() {
            _ask = false;
            _noPost = true;
          })),
          EButton.primary(semanticsId: TrustIds.txIpUseserver, label: l.deskIpUseServer, onPressed: () => _start(host)),
        ],
      );
    }
    if (answer != null && (_noPost || _online != null)) return _answered(context, title, answer, _online);
    return _review(context, title);
  }

  Widget _review(BuildContext context, String title) {
    final l = context.l10n;
    final ts = context.ts;
    final info = widget.info;
    final fee = info.fee;
    final message = info.message;
    final failure = _failure;
    return EDialog(
      title: title,
      icon: _pay ? EIcons.send : EIcons.receive,
      dismissible: !_busy,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${formatEpicL(l, info.amount.toInt(), decimals: 8, minDecimals: 0)} $epicUnit', style: ts.h2),
          SizedBox(height: Sp.x3),
          EFacts([
            if (_pay && fee != null) (l.txDetailsFee, Text('${formatEpicL(l, fee.toInt(), decimals: 8, minDecimals: 0)} $epicUnit', style: ts.body)),
            if (message != null && message.isNotEmpty) (l.deskInvIssuerMessage, Text(message, style: ts.body)),
          ]),
          if (failure != null) ...[
            SizedBox(height: Sp.x4),
            ENotice(tone: ETone.risk, icon: EIcons.error, title: failure),
          ],
        ],
      ),
      foot: !_pay
          ? null
          : EField(
              label: l.deskInvPayerPassword,
              error: _passwordError,
              child: EPasswordInput(
                key: deskInPersonPasswordKey,
                controller: _password,
                autofocus: true,
                invalid: _passwordError != null,
                semanticLabel: l.deskInvPayerPassword,
                onChanged: (_) => setState(() => _passwordError = null),
                onSubmitted: (_) => _busy ? null : _answerCode(),
              ),
            ),
      actions: [
        EButton(label: l.commonCancel, onPressed: _busy ? null : () => Navigator.of(context).pop()),
        EButton.primary(
          semanticsId: _pay ? TrustIds.txIpPay : TrustIds.txIpReceive,
          label: _pay ? l.deskIpPayButton : l.deskIpReceiveButton,
          busy: _busy,
          onPressed: _busy ? null : _answerCode,
        ),
      ],
    );
  }

  /// The check code once the answer is posted; until then [title], the review's. While
  /// [online] sends there is no answer code; it shows once the post failed or was cancelled.
  Widget _answered(BuildContext context, String title, InPersonAnswerMade answer, InPersonAnswerPost? online) {
    final l = context.l10n;
    final checkCode = online?.checkCode;
    final step = online?.step;
    return EDialog(
      title: checkCode != null ? l.deskIpCheckTitle : title,
      icon: EIcons.shield,
      description: checkCode != null ? l.deskIpCheckLead : null,
      dismissible: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (checkCode != null) DeskInPersonCheck(key: deskInPersonCheckKey, code: checkCode),
          if (step == InPersonOnlineStep.posting) DeskInPersonOnlineLine(online: online!),
          if (step == InPersonOnlineStep.failed) ...[
            SizedBox(height: Sp.x4),
            ENotice(
              tone: ETone.warn,
              icon: EIcons.alert,
              title: l.deskIpPostFailed,
              actions: [EButton(label: l.commonRetry, size: EBtnSize.inline, onPressed: online!.post)],
            ),
          ],
          if (online == null || online.showAnswer) ...[
            SizedBox(height: Sp.x5),
            Text(l.deskIpAnswerLead, style: context.ts.bodyDim),
            SizedBox(height: Sp.x3),
            Center(child: DeskInPersonQr(key: deskInPersonQrKey, parts: _parts, label: l.deskKitQrOf(l.deskIpAnswerOf))),
            SizedBox(height: Sp.x4),
            DeskInPersonText(key: deskInPersonCodeTextKey, label: l.deskIpAnswerLabel, text: answer.armored),
          ],
        ],
      ),
      actions: [EButton.primary(semanticsId: TrustIds.txIpDone, label: l.commonDone, onPressed: () => Navigator.of(context).pop())],
    );
  }
}

/// An expired pasted code.
class DeskInPersonExpiredDialog extends StatelessWidget {
  const DeskInPersonExpiredDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EDialog(
      title: l.deskE1ErrCodeExpired,
      tone: ETone.warn,
      actions: [EButton(label: l.commonClose, onPressed: () => Navigator.of(context).pop())],
    );
  }
}

/// Whether [e] says the code expired.
bool deskInPersonExpired(Object e) => e is WalletError && e.kind == WalletErrorKind.codeExpired;
