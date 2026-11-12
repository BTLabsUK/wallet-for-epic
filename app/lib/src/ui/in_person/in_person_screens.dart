// SPDX-License-Identifier: Apache-2.0
/// The phone's in-person screens (spec D5, P3, P5, P6): the form that makes a code, the code
/// waiting for its answer with the check question, the review of a scanned code, and the check
/// code shown after answering one.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../amount.dart';
import '../../epic1.dart';
import '../../errors.dart';
import '../../l10n.dart';
import '../../models.dart';
import '../../providers.dart';
import '../../qr_slate.dart' show QrFrames;
import '../../trust_ids.dart';
import '../../utf8_limit.dart';
import '../app_dialog.dart';
import '../common.dart';
import '../contacts_screen.dart' show LiveFieldError;
import '../kit/kit_corner_marks.dart';
import '../kit/kit_button.dart';
import '../kit/kit_headers.dart';
import '../kit/kit_hero_amount.dart';
import '../kit/kit_icons.dart';
import '../kit/kit_step_strip.dart';
import '../kit/kit_tokens.dart';
import '../pin.dart';
import '../theme/logo_qr.dart';
import '../theme/tokens.dart';
import 'in_person_logic.dart';
import 'in_person_online.dart';
import 'in_person_scan.dart';

/// The keys of the in-person screens, for tests.
const Key inPersonAmountKey = ValueKey('in-person-amount');
const Key inPersonMessageKey = ValueKey('in-person-message');
const Key inPersonQrKey = ValueKey('in-person-qr');
const Key inPersonAnswerQrKey = ValueKey('in-person-answer-qr');
const Key inPersonCodeTextKey = ValueKey('in-person-code-text');
const Key inPersonCheckKey = ValueKey('in-person-check');

/// Asks the PIN of the open wallet (or its biometric copy) before [amount] is spent. True once
/// it checked out.
Future<bool> inPersonSpendGate(BuildContext context, WidgetRef ref, BigInt amount) async {
  final session = ref.read(sessionProvider);
  final config = ref.read(walletConfigProvider);
  if (session == null || config == null) return false;
  final vault = ref.read(vaultProvider);
  final l = context.l10n;
  final shown = epicExact(l, amount);
  final approved = await showPinSheet(
    context,
    reason: usesPassphrase(ref) ? l.sendPassphraseReason(shown) : l.sendPinReason(shown),
    action: (pin) async {
      await vault.checkPin(session, config, pin);
      return true;
    },
  );
  return approved == true;
}

/// Makes a code of [stage] for [amount]: a send code asks the PIN first. Null when the PIN
/// was not given. Throws what the wallet refused.
Future<InPersonCodeMade?> makeInPersonCode(
  BuildContext context,
  WidgetRef ref,
  InPersonStage stage,
  BigInt amount,
  String? message,
) async {
  final wallet = ref.read(epic1Provider);
  if (wallet == null) return null;
  if (stage == InPersonStage.request) return wallet.inPersonRequest(amount: amount, message: message);
  if (!await inPersonSpendGate(context, ref, amount)) return null;
  return wallet.inPersonSend(amount: amount, minimumConfirmations: ref.read(countedConfirmationsProvider), message: message);
}

/// The page of an in-person screen: the flow header (a close mark),
/// the three-step strip when there is one, a thin progress line for [idle], and the body.
class _InPersonPage extends StatelessWidget {
  const _InPersonPage({
    required this.title,
    required this.children,
    this.bottom,
    this.idle,
    this.steps,
    this.current = 0,
  });

  final String title;
  final List<Widget> children;
  final Widget? bottom;
  final Widget? idle;
  final List<String>? steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    final steps = this.steps;
    return SlotScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitFlowHeader(title: title, onLeading: () => Navigator.of(context).maybePop()),
            if (steps != null) KitStepStrip(labels: steps, current: current),
            ProgressSlot(idle: idle),
            Expanded(child: ScreenBody(bottom: bottom, children: children)),
          ],
        ),
      ),
    );
  }
}

/// The steps of a code this phone shows (a request, or a send code): show it, take the answer,
/// done.
List<String> _showSteps(AppLocalizations l) => [l.phoneStepPayShow, l.phoneStepPayScan, l.commonDone];

/// The steps of a code this phone scans: scan it, show the answer, done.
List<String> _answerSteps(AppLocalizations l) => [l.phoneStepRecvScan, l.phoneStepRecvShow, l.commonDone];

/// The amount of an in-person page, centred and big, as on the other payment pages.
class _InPersonAmount extends StatelessWidget {
  const _InPersonAmount(this.amount);

  final BigInt amount;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return KitHeroAmount(amount: epicFor(l, amount, surface: AmountSurface.exact, unit: false), unit: epicUnit);
  }
}

/// The one gold button at the foot of an in-person page; off while [busy] (the progress line
/// under the header shows the work).
class _GoButton extends StatelessWidget {
  const _GoButton({required this.label, required this.busy, required this.onPressed, required this.semanticsId});

  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  final String semanticsId;

  @override
  Widget build(BuildContext context) =>
      KitButton(label: label, onPressed: busy ? null : onPressed, semanticsId: semanticsId);
}

/// The amount and message of a code to show: "Request in person" or "Pay in person".
class InPersonFormScreen extends ConsumerStatefulWidget {
  const InPersonFormScreen({super.key, required this.stage});

  final InPersonStage stage;

  @override
  ConsumerState<InPersonFormScreen> createState() => _InPersonFormScreenState();
}

class _InPersonFormScreenState extends ConsumerState<InPersonFormScreen> {
  final _amount = TextEditingController();
  final _message = TextEditingController();
  String? _amountError;
  Object? _error;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  BigInt? _parse() {
    final l = context.l10n;
    try {
      final amount = parseEpic(
        normalizeAmountText(
          _amount.text,
          unit: 'epic',
          groupSeparator: NumberFormat.decimalPattern(l.localeName).symbols.GROUP_SEP,
        ),
      );
      if (amount <= BigInt.zero) {
        setState(() => _amountError = l.sendAmountZero);
        return null;
      }
      return amount;
    } on FormatException catch (e) {
      setState(() => _amountError = describeError(l, e));
      return null;
    }
  }

  Future<void> _make() async {
    final amount = _parse();
    if (amount == null) return;
    final text = _message.text.trim();
    final message = text.isEmpty ? null : text;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final made = await makeInPersonCode(context, ref, widget.stage, amount, message);
      if (!mounted || made == null) return;
      final wallet = ref.read(epic1Provider);
      if (wallet == null) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => InPersonCodeScreen(
            watch: InPersonCodeWatch(wallet: wallet, stage: widget.stage, amount: amount, made: made),
            message: message,
          ),
        ),
      );
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final request = widget.stage == InPersonStage.request;
    final error = _error;
    final amountError = _amountError;
    return _InPersonPage(
      title: request ? l.deskIpRequestTitle : l.deskIpPayTitle,
      idle: _busy ? SlotProgress(label: l.deskIpMakeCode) : null,
      bottom: _GoButton(label: l.deskIpMakeCode, busy: _busy, onPressed: _make, semanticsId: TrustIds.txIpMake),
      children: [
        TextField(
          key: inPersonAmountKey,
          controller: _amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            if (_amountError != null) setState(() => _amountError = null);
          },
          decoration: InputDecoration(
            labelText: l.sendAmountLabel(epicUnit),
            error: amountError == null ? null : LiveFieldError(amountError),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: inPersonMessageKey,
          controller: _message,
          inputFormatters: const [Utf8LengthLimiter(slateMessageMaxBytes)],
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => Text(
            l.sendMessageCounter(utf8Length(_message.text), slateMessageMaxBytes),
            style: KitType.rowSub.copyWith(color: context.tokens.dim),
          ),
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _busy ? null : _make(),
          decoration: InputDecoration(labelText: request ? l.requestMessageLabel : l.sendNoteLabel),
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          InlineNotice(level: NoticeLevel.error, text: describeError(l, error), liveRegion: true),
        ],
      ],
    );
  }
}

/// A code on screen: covered QR, its text with Copy and its expiry, then the check question
/// once the other phone answered, and how it ended.
class InPersonCodeScreen extends ConsumerStatefulWidget {
  const InPersonCodeScreen({super.key, required this.watch, this.message});

  /// The code and its answers; the screen disposes it.
  final InPersonCodeWatch watch;

  /// The message signed into the code, as typed.
  final String? message;

  @override
  ConsumerState<InPersonCodeScreen> createState() => _InPersonCodeScreenState();
}

class _InPersonCodeScreenState extends ConsumerState<InPersonCodeScreen> {
  InPersonCodeWatch get _watch => widget.watch;

  String? _takeError;
  Object? _renewError;
  bool _renewing = false;

  @override
  void dispose() {
    _watch.dispose();
    super.dispose();
  }

  /// Paste answer: reads the clipboard on the press only.
  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    final ok = text.trim().isNotEmpty && await _watch.take(text);
    if (mounted) setState(() => _takeError = ok ? null : context.l10n.deskIpNotAnswer);
  }

  Future<void> _scan() async {
    final got = await Navigator.of(context).push<InPersonScanned>(
      MaterialPageRoute<InPersonScanned>(builder: (_) => const InPersonScanScreen(answer: true)),
    );
    if (got == null || !mounted) return;
    final ok = switch (got) {
      InPersonScanned(:final bytes?) => await _watch.takeBytes(bytes),
      InPersonScanned(:final text?) => await _watch.take(text),
      _ => false,
    };
    if (mounted) setState(() => _takeError = ok ? null : context.l10n.deskIpNotAnswer);
  }

  Future<void> _renew() async {
    final amount = _watch.amount;
    if (amount == null) return;
    setState(() {
      _renewing = true;
      _renewError = null;
    });
    try {
      final made = await makeInPersonCode(context, ref, _watch.stage, amount, widget.message);
      if (made != null) _watch.renew(made);
    } on Object catch (e) {
      if (mounted) setState(() => _renewError = e);
    } finally {
      if (mounted) setState(() => _renewing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _watch, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final l = context.l10n;
    final request = _watch.stage == InPersonStage.request;
    final title = request ? l.deskIpRequestTitle : l.deskIpPayTitle;
    final done = KitButton(
      kind: KitButtonKind.quiet,
      label: l.commonClose,
      onPressed: () => Navigator.pop(context),
    );
    switch (_watch.phase) {
      case InPersonPhase.waiting:
        return _waiting(context, title);
      case InPersonPhase.check:
      case InPersonPhase.finishing:
        return _check(context, title);
      case InPersonPhase.done:
        return InPersonEndScreen(
          title: title,
          headline: _watch.stage == InPersonStage.send ? l.deskIpSent : l.deskIpReceived,
          amount: _watch.amount,
          ok: true,
        );
      case InPersonPhase.stopped:
        return InPersonEndScreen(title: title, headline: l.deskE1PaymentStopped);
      case InPersonPhase.sameCode:
      case InPersonPhase.expired:
        final renewError = _renewError;
        return InPersonEndScreen(
          title: title,
          headline: _watch.phase == InPersonPhase.sameCode ? l.deskE1SameCodeTwice : l.deskE1ErrCodeExpired,
          busy: _renewing,
          below: renewError == null
              ? null
              : InlineNotice(level: NoticeLevel.error, text: describeError(l, renewError), liveRegion: true),
          actions: [
            if (_watch.amount != null) ...[
              _GoButton(label: l.deskE1ShowNewCode, busy: _renewing, onPressed: _renew, semanticsId: TrustIds.txIpNewcode),
              const SizedBox(height: 8),
            ],
            done,
          ],
        );
    }
  }

  Widget _waiting(BuildContext context, String title) {
    final l = context.l10n;
    final t = context.tokens;
    final made = _watch.made!;
    final amount = _watch.amount;
    final message = widget.message;
    final left = inPersonMinutesLeft(made.ttlCutoff, tipHeight(ref));
    final takeError = _takeError;
    return _InPersonPage(
      title: title,
      steps: _showSteps(l),
      current: 0,
      idle: SlotProgress(label: l.deskIpWaiting),
      // While the answer comes back online, no paste or scan: they show again once the
      // server failed or the online reply was cancelled.
      bottom: !_watch.manual
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitButton(icon: KitIcons.scan, label: l.deskIpScanAnswer, onPressed: _scan, semanticsId: TrustIds.txIpScan),
                const SizedBox(height: 8),
                KitButton(
                  kind: KitButtonKind.quiet,
                  icon: KitIcons.paste,
                  label: l.deskIpPasteAnswer,
                  onPressed: _paste,
                  semanticsId: TrustIds.txIpPaste,
                ),
              ],
            ),
      children: [
        if (amount != null) ...[const SizedBox(height: 4), _InPersonAmount(amount)],
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: KitType.body.copyWith(color: t.text),
            ),
          ),
        const SizedBox(height: 10),
        Text(
          _watch.stage == InPersonStage.request ? l.deskIpCodeLeadRequest : l.deskIpCodeLeadPay,
          textAlign: TextAlign.center,
          style: KitType.body.copyWith(color: t.dim),
        ),
        const SizedBox(height: 16),
        InPersonQr(key: inPersonQrKey, parts: _watch.parts, label: l.deskKitQrOf(l.deskIpCodeOf)),
        const SizedBox(height: 16),
        InPersonCodeText(label: l.deskIpCodeText, text: made.text),
        if (left != null) ...[
          const SizedBox(height: 10),
          Text(l.deskIpExpiresIn(left), textAlign: TextAlign.center, style: KitType.rowSub.copyWith(color: t.dim)),
        ],
        const SizedBox(height: 12),
        if (_watch.online)
          InPersonOnlineLine(online: _watch)
        else
          Semantics(
            liveRegion: true,
            child: Text(l.deskIpWaiting, textAlign: TextAlign.center, style: KitType.body.copyWith(color: t.info)),
          ),
        if (takeError != null) ...[
          const SizedBox(height: 12),
          InlineNotice(level: NoticeLevel.error, text: takeError, liveRegion: true),
        ],
      ],
    );
  }

  Widget _check(BuildContext context, String title) {
    final l = context.l10n;
    final code = _watch.checkCode ?? '';
    final finishing = _watch.phase == InPersonPhase.finishing;
    final error = _watch.error;
    final question = _watch.stage == InPersonStage.request ? l.deskIpCheckPayer(code) : l.deskIpCheckOther(code);
    return _InPersonPage(
      title: title,
      steps: _showSteps(l),
      current: 1,
      idle: finishing ? SlotProgress(label: l.deskIpMatches) : null,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GoButton(label: l.deskIpMatches, busy: finishing, onPressed: _watch.matches, semanticsId: TrustIds.txIpMatches),
          const SizedBox(height: 8),
          KitButton(
            kind: KitButtonKind.quiet,
            label: l.deskIpDifferent,
            onPressed: finishing ? null : _watch.different,
            semanticsId: TrustIds.txIpDifferent,
          ),
        ],
      ),
      children: [
        const SizedBox(height: 12),
        InPersonCheck(key: inPersonCheckKey, question: question, code: code),
        if (error != null) ...[
          const SizedBox(height: 16),
          InlineNotice(level: NoticeLevel.error, text: describeError(l, error), liveRegion: true),
        ],
      ],
    );
  }
}

/// The check question with its code large: "Does the payer's phone show 4821?"
class InPersonCheck extends StatelessWidget {
  const InPersonCheck({super.key, this.question, required this.code});

  final String? question;
  final String code;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final question = this.question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (question != null) ...[
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(question, textAlign: TextAlign.center, style: KitType.sheetTitle.copyWith(color: t.text)),
          ),
          const SizedBox(height: 24),
        ],
        // The question reads the code out; the large copy is for the eyes.
        ExcludeSemantics(
          excluding: question != null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: t.group,
              borderRadius: BorderRadius.circular(Kit.rGroup),
              border: Border.all(color: t.hair),
            ),
            child: Center(
              child: Text(
                code,
                style: TextStyle(
                  fontFamily: t.monoFamily,
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 8,
                  color: t.accentText,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// How a code ended: a glyph, one headline, the amount when it went through, and [actions]
/// (Close when none).
class InPersonEndScreen extends StatelessWidget {
  const InPersonEndScreen({
    super.key,
    required this.title,
    required this.headline,
    this.amount,
    this.ok = false,
    this.busy = false,
    this.below,
    this.actions,
  });

  final String title;
  final String headline;
  final BigInt? amount;
  final bool ok;
  final bool busy;
  final Widget? below;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final amount = this.amount;
    final below = this.below;
    return _InPersonPage(
      title: title,
      idle: busy ? SlotProgress(label: headline) : null,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:
            actions ??
            [
              KitButton(
                kind: ok ? KitButtonKind.gold : KitButtonKind.quiet,
                label: ok ? l.commonDone : l.commonClose,
                onPressed: () => Navigator.pop(context),
                semanticsId: TrustIds.txIpDone,
              ),
            ],
      ),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: Kit.emptyWell,
            height: Kit.emptyWell,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.raised, borderRadius: BorderRadius.circular(Kit.rGroup)),
            child: ExcludeSemantics(
              child: Icon(ok ? KitIcons.success : Icons.block, size: 34, color: ok ? t.ok : t.risk),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(headline, textAlign: TextAlign.center, style: KitType.sheetTitle.copyWith(color: t.text)),
        ),
        if (amount != null) ...[const SizedBox(height: 16), _InPersonAmount(amount)],
        if (below != null) ...[const SizedBox(height: 16), below],
      ],
    );
  }
}

/// A code's QR, covered until tapped (UI rule); several parts show in turn, one every
/// [inPersonFrameEvery].
class InPersonQr extends StatefulWidget {
  const InPersonQr({super.key, required this.parts, required this.label, this.size = 240});

  final List<String> parts;
  final String label;
  final double size;

  @override
  State<InPersonQr> createState() => _InPersonQrState();
}

class _InPersonQrState extends State<InPersonQr> {
  bool _shown = false;
  int _frame = 0;
  Timer? _timer;
  QrFrames? _frames;

  /// The parts drawn once, in one version and mask.
  QrFrames _framesOf(List<String> parts) {
    final drawn = _frames;
    if (drawn != null && identical(drawn.texts, parts)) return drawn;
    return _frames = QrFrames.of(parts);
  }

  @override
  void didUpdateWidget(InPersonQr old) {
    super.didUpdateWidget(old);
    // A new code covers again.
    if (old.parts.firstOrNull != widget.parts.firstOrNull) _set(false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _set(bool shown) {
    _timer?.cancel();
    _timer = null;
    _frame = 0;
    if (shown && widget.parts.length > 1) {
      _timer = Timer.periodic(inPersonFrameEvery, (_) {
        if (mounted) setState(() => _frame = (_frame + 1) % widget.parts.length);
      });
    }
    setState(() => _shown = shown);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final parts = widget.parts;
    final side = widget.size;
    final Widget inner;
    if (!_shown || parts.isEmpty) {
      inner = TrustId(
        TrustIds.txIpReveal,
        child: Semantics(
          button: true,
          label: l.qrShow,
          excludeSemantics: true,
          child: Material(
            color: t.group,
            borderRadius: BorderRadius.circular(Kit.rQr),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _set(true),
              child: Container(
                width: side,
                height: side,
                decoration: BoxDecoration(
                  border: Border.all(color: t.hair),
                  borderRadius: BorderRadius.circular(Kit.rQr),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(KitIcons.qr, size: 48, color: t.accentText),
                    const SizedBox(height: 8),
                    Text(l.qrShow, style: KitType.rowTitle.copyWith(color: t.text)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      final frames = _framesOf(parts);
      inner = GestureDetector(
        onTap: () => _set(false),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Dark modules on white scan reliably in either theme.
            color: protocolLight.surface,
            borderRadius: BorderRadius.circular(Kit.rQr),
            boxShadow: [BoxShadow(color: t.accent.withValues(alpha: dark ? 0.22 : 0.12), blurRadius: 40)],
          ),
          child: Semantics(
            label: widget.label,
            image: true,
            child: LogoQrImage(image: frames.images[_frame % frames.length], size: side - 32, logo: QrLogo.epic1),
          ),
        ),
      );
    }
    return Center(
      heightFactor: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: KitCornerMarks(inset: 14, arm: 22, child: inner),
      ),
    );
  }
}

/// A code's or answer's text, a few lines in mono, with Copy (on press), in a card.
class InPersonCodeText extends StatelessWidget {
  const InPersonCodeText({super.key, required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: t.group,
        borderRadius: BorderRadius.circular(Kit.rGroup),
        border: Border.all(color: t.hair),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: KitType.groupLabel.copyWith(color: t.dim)),
                const SizedBox(height: 4),
                Text(
                  text,
                  key: inPersonCodeTextKey,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: t.monoFamily, fontSize: 13, color: t.text),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          KitButton(
            kind: KitButtonKind.quiet,
            small: true,
            expand: false,
            icon: KitIcons.copy,
            label: l.commonCopy,
            semanticsId: TrustIds.txIpCopy,
            onPressed: () => copySecretText(context, text, l.deskIpCopied),
          ),
        ],
      ),
    );
  }
}

/// A scanned or pasted code read ([Epic1Wallet.inPersonRead]): its amount, fee and message,
/// and Receive or Pay. Then the answer, its post, and the check code.
class InPersonReviewScreen extends ConsumerStatefulWidget {
  const InPersonReviewScreen({super.key, required this.code, required this.info});

  final Uint8List code;
  final InPersonCodeInfo info;

  @override
  ConsumerState<InPersonReviewScreen> createState() => _InPersonReviewScreenState();
}

class _InPersonReviewScreenState extends ConsumerState<InPersonReviewScreen> {
  bool _busy = false;
  Object? _error;

  bool get _receive => widget.info.stage == InPersonStage.send;

  Future<void> _go() async {
    final wallet = ref.read(epic1Provider);
    if (wallet == null) return;
    final info = widget.info;
    if (!_receive && !await inPersonSpendGate(context, ref, info.amount)) return;
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final made = _receive
          ? await wallet.inPersonReceive(widget.code)
          : await wallet.inPersonPay(
              widget.code,
              amount: info.amount,
              minimumConfirmations: ref.read(countedConfirmationsProvider),
            );
      if (!mounted) return;
      final mailbox = made.mailbox ?? info.mailbox;
      final online = mailbox != null && await askInPersonServer(context, mailbox);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => InPersonAnsweredScreen(
            title: inPersonReviewTitle(context, info.stage),
            answer: made,
            mailbox: online ? mailbox : null,
            cutoff: info.ttlCutoff,
          ),
        ),
      );
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final info = widget.info;
    final fee = info.fee;
    final message = info.message;
    final error = _error;
    final label = _receive ? l.deskIpReceiveButton : l.deskIpPayButton;
    return _InPersonPage(
      title: inPersonReviewTitle(context, info.stage),
      steps: _answerSteps(l),
      current: 1,
      idle: _busy ? SlotProgress(label: label) : null,
      bottom: _GoButton(
        label: label,
        busy: _busy,
        onPressed: _go,
        semanticsId: _receive ? TrustIds.txIpReceive : TrustIds.txIpPay,
      ),
      children: [
        const SizedBox(height: 12),
        _InPersonAmount(info.amount),
        if (!_receive && fee != null) ...[
          const SizedBox(height: 12),
          Text(
            '${l.txDetailsFee}: ${epicExact(l, fee)}',
            textAlign: TextAlign.center,
            style: KitType.body.copyWith(color: t.dim),
          ),
        ],
        if (message != null && message.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: KitType.body.copyWith(color: t.text),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 16),
          InlineNotice(level: NoticeLevel.error, text: describeError(l, error), liveRegion: true),
        ],
      ],
    );
  }
}

/// The title of the review of a code of [stage]: a send code is received, a request is paid.
String inPersonReviewTitle(BuildContext context, InPersonStage stage) =>
    stage == InPersonStage.send ? context.l10n.deskIpReceiveTitle : context.l10n.deskIpPayRequestTitle;

/// Whether the answer may go through [mailbox]: a server not in the list is asked about first.
Future<bool> askInPersonServer(BuildContext context, Epic1Host mailbox) async {
  if (mailbox.inRelayList) return true;
  final l = context.l10n;
  final use = await showAppDialog<bool>(
    context,
    builder: (context) => AppDialog(
      title: l.deskIpUseServerAsk,
      description: l.deskIpNotInList(mailbox.host),
      icon: Icons.dns_outlined,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
        TrustId(
          TrustIds.txIpUseserver,
          child: FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.deskIpUseServer)),
        ),
      ],
    ),
  );
  return use == true;
}

/// After answering a code: the answer goes to the code's Epicbox server [mailbox] (the line
/// "Sending the answer online…" meanwhile, no QR code), then the check code for the other phone
/// to compare. Without a server, after a failed post or "Cancel online reply", the answer as a
/// QR code and text for the other phone to scan or paste.
class InPersonAnsweredScreen extends ConsumerStatefulWidget {
  const InPersonAnsweredScreen({super.key, required this.title, required this.answer, this.mailbox, required this.cutoff});

  final String title;
  final InPersonAnswerMade answer;

  /// The server the answer goes to, agreed; null: shown to scan only.
  final Epic1Host? mailbox;

  /// The block height the code stops working at.
  final BigInt cutoff;

  @override
  ConsumerState<InPersonAnsweredScreen> createState() => _InPersonAnsweredScreenState();
}

class _InPersonAnsweredScreenState extends ConsumerState<InPersonAnsweredScreen> {
  late final List<String> _parts = ref.read(epic1Provider)?.qrParts(widget.answer.envelope) ?? const [];
  InPersonAnswerPost? _post;

  @override
  void initState() {
    super.initState();
    final wallet = ref.read(epic1Provider);
    final mailbox = widget.mailbox;
    if (wallet != null && mailbox != null) {
      _post = InPersonAnswerPost(wallet: wallet, slateId: widget.answer.slateId, mailbox: mailbox, cutoff: widget.cutoff);
      unawaited(_post!.post());
    }
  }

  @override
  void dispose() {
    _post?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    return post == null ? _build(context) : ListenableBuilder(listenable: post, builder: (context, _) => _build(context));
  }

  Widget _build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final answer = widget.answer;
    final post = _post;
    final step = post?.step;
    final failed = step == InPersonOnlineStep.failed;
    final checkCode = post?.checkCode;
    return _InPersonPage(
      title: widget.title,
      steps: _answerSteps(l),
      current: 1,
      bottom: KitButton(label: l.commonDone, onPressed: () => Navigator.pop(context), semanticsId: TrustIds.txIpDone),
      children: [
        if (checkCode != null) ...[
          Semantics(
            header: true,
            child: Text(l.deskIpCheckTitle, textAlign: TextAlign.center, style: KitType.sheetTitle.copyWith(color: t.text)),
          ),
          const SizedBox(height: 8),
          Text(l.deskIpCheckLead, textAlign: TextAlign.center, style: KitType.body.copyWith(color: t.dim)),
          const SizedBox(height: 16),
          InPersonCheck(key: inPersonCheckKey, code: checkCode),
        ],
        if (post != null && step == InPersonOnlineStep.posting) InPersonOnlineLine(online: post),
        if (failed) ...[
          const SizedBox(height: 16),
          InlineNotice(
            level: NoticeLevel.warning,
            text: l.deskIpPostFailed,
            liveRegion: true,
            actions: [TextButton(onPressed: post?.post, child: Text(l.commonRetry))],
          ),
        ],
        if (post == null || post.showAnswer) ...[
          const SizedBox(height: 24),
          Text(l.deskIpAnswerLead, textAlign: TextAlign.center, style: KitType.body.copyWith(color: t.dim)),
          const SizedBox(height: 12),
          InPersonQr(key: inPersonAnswerQrKey, parts: _parts, label: l.deskKitQrOf(l.deskIpAnswerOf)),
          const SizedBox(height: 16),
          InPersonCodeText(label: l.deskIpAnswerLabel, text: answer.armored),
        ],
      ],
    );
  }
}
