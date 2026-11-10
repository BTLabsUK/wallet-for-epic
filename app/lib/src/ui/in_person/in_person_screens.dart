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
import '../../trust_ids.dart';
import '../../utf8_limit.dart';
import '../app_dialog.dart';
import '../common.dart';
import '../contacts_screen.dart' show LiveFieldError;
import '../invoice_review_screen.dart' show ReviewAmount;
import '../pin.dart';
import '../theme/brand.dart' show GlyphTile, MarkedQr;
import '../theme/protocol.dart';
import '../theme/tokens.dart';
import 'in_person_logic.dart';
import 'in_person_scan.dart';

/// The keys of the in-person screens, for tests.
const Key inPersonAmountKey = ValueKey('in-person-amount');
const Key inPersonMessageKey = ValueKey('in-person-message');
const Key inPersonQrKey = ValueKey('in-person-qr');
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
  final approved = await askPin(
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
    final theme = Theme.of(context);
    final request = widget.stage == InPersonStage.request;
    final error = _error;
    final amountError = _amountError;
    return SlotScaffold(
      appBar: AppBar(title: Text(request ? l.deskIpRequestTitle : l.deskIpPayTitle)),
      idle: _busy ? SlotProgress(label: l.deskIpMakeCode) : null,
      body: ScreenBody(
        bottom: BusyButton(label: l.deskIpMakeCode, busy: _busy, onPressed: _make, semanticsId: TrustIds.txIpMake),
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
              style: theme.textTheme.bodySmall,
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
      ),
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
    final done = TextButton(
      style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: () => Navigator.pop(context),
      child: Text(l.commonClose),
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
            if (_watch.amount != null)
              BusyButton(label: l.deskE1ShowNewCode, busy: _renewing, onPressed: _renew, semanticsId: TrustIds.txIpNewcode),
            done,
          ],
        );
    }
  }

  Widget _waiting(BuildContext context, String title) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final made = _watch.made!;
    final amount = _watch.amount;
    final message = widget.message;
    final left = inPersonMinutesLeft(made.ttlCutoff, tipHeight(ref));
    final takeError = _takeError;
    return SlotScaffold(
      appBar: AppBar(title: Text(title)),
      idle: SlotProgress(label: l.deskIpWaiting),
      body: ScreenBody(
        bottom: Row(
          children: [
            Expanded(
              child: TrustId(
                TrustIds.txIpPaste,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  icon: const Icon(Icons.content_paste),
                  label: Text(l.deskIpPasteAnswer),
                  onPressed: _paste,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TrustId(
                TrustIds.txIpScan,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(l.deskIpScanAnswer),
                  onPressed: _scan,
                ),
              ),
            ),
          ],
        ),
        children: [
          Text(
            _watch.stage == InPersonStage.request ? l.deskIpCodeLeadRequest : l.deskIpCodeLeadPay,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          if (amount != null) ReviewAmount(amount: amount),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge),
            ),
          const SizedBox(height: 16),
          InPersonQr(key: inPersonQrKey, parts: _watch.parts, label: l.deskKitQrOf(l.deskIpCodeOf)),
          const SizedBox(height: 16),
          InPersonCodeText(label: l.deskIpCodeText, text: made.text),
          if (left != null) ...[
            const SizedBox(height: 8),
            Text(l.deskIpExpiresIn(left), style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
          ],
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(l.deskIpWaiting, style: theme.textTheme.bodyMedium?.copyWith(color: t.info)),
          ),
          if (takeError != null) ...[
            const SizedBox(height: 12),
            InlineNotice(level: NoticeLevel.error, text: takeError, liveRegion: true),
          ],
        ],
      ),
    );
  }

  Widget _check(BuildContext context, String title) {
    final l = context.l10n;
    final code = _watch.checkCode ?? '';
    final finishing = _watch.phase == InPersonPhase.finishing;
    final error = _watch.error;
    final question = _watch.stage == InPersonStage.request ? l.deskIpCheckPayer(code) : l.deskIpCheckOther(code);
    return SlotScaffold(
      appBar: AppBar(title: Text(title)),
      idle: finishing ? SlotProgress(label: l.deskIpMatches) : null,
      body: ScreenBody(
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BusyButton(label: l.deskIpMatches, busy: finishing, onPressed: _watch.matches, semanticsId: TrustIds.txIpMatches),
            const SizedBox(height: 8),
            TrustId(
              TrustIds.txIpDifferent,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: finishing ? null : _watch.different,
                child: Text(l.deskIpDifferent),
              ),
            ),
          ],
        ),
        children: [
          InPersonCheck(key: inPersonCheckKey, question: question, code: code),
          if (error != null) ...[
            const SizedBox(height: 16),
            InlineNotice(level: NoticeLevel.error, text: describeError(l, error), liveRegion: true),
          ],
        ],
      ),
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
    final theme = Theme.of(context);
    final question = this.question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (question != null) ...[
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(question, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 24),
        ],
        // The question reads the code out; the large copy is for the eyes.
        ExcludeSemantics(
          excluding: question != null,
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
    final theme = Theme.of(context);
    final amount = this.amount;
    final below = this.below;
    return SlotScaffold(
      appBar: AppBar(title: Text(title)),
      idle: busy ? SlotProgress(label: headline) : null,
      body: ScreenBody(
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:
              actions ??
              [
                BusyButton(label: ok ? l.commonDone : l.commonClose, onPressed: () => Navigator.pop(context), semanticsId: TrustIds.txIpDone),
              ],
        ),
        children: [
          Row(
            children: [
              GlyphTile(
                size: 48,
                child: Icon(ok ? Icons.check_circle_outline : Icons.block, color: ok ? t.ok : t.risk),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(headline, style: theme.textTheme.titleMedium),
                ),
              ),
            ],
          ),
          if (amount != null) ...[const SizedBox(height: 16), ReviewAmount(amount: amount)],
          if (below != null) ...[const SizedBox(height: 16), below],
        ],
      ),
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
          child: InkWell(
            onTap: () => _set(true),
            borderRadius: BorderRadius.circular(t.radiusSmall),
            child: Container(
              width: side + 32,
              height: side + 32,
              decoration: BoxDecoration(
                color: t.surface,
                border: Border.all(color: t.line),
                borderRadius: BorderRadius.circular(t.radiusSmall),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2, size: 48, color: t.accentText),
                  const SizedBox(height: 8),
                  Text(l.qrShow, style: Theme.of(context).textTheme.labelLarge),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      inner = GestureDetector(
        onTap: () => _set(false),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Dark modules on white scan reliably in either theme.
            color: protocolLight.surface,
            borderRadius: BorderRadius.circular(t.radiusSmall),
            boxShadow: [BoxShadow(color: t.accent.withValues(alpha: dark ? 0.22 : 0.12), blurRadius: 40)],
          ),
          child: Semantics(
            label: widget.label,
            image: true,
            child: MarkedQr(data: parts[_frame % parts.length], size: side),
          ),
        ),
      );
    }
    return Center(
      heightFactor: 1,
      child: CustomPaint(
        foregroundPainter: CornerTicksPainter(t.tick, length: 16),
        child: Padding(padding: const EdgeInsets.all(12), child: inner),
      ),
    );
  }
}

/// A code's or answer's text, a few lines in mono, with Copy (on press).
class InPersonCodeText extends StatelessWidget {
  const InPersonCodeText({super.key, required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: t.dim)),
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
        TrustId(
          TrustIds.txIpCopy,
          child: TextButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l.commonCopy),
            onPressed: () => copySecretText(context, text, l.deskIpCopied),
          ),
        ),
      ],
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
      final (posted, checkCode) = await postInPersonAnswer(context, wallet, made.slateId, made.mailbox ?? info.mailbox);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => InPersonAnsweredScreen(
            title: inPersonReviewTitle(context, info.stage),
            answer: made,
            posted: posted,
            checkCode: checkCode,
            mailbox: made.mailbox ?? info.mailbox,
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
    final theme = Theme.of(context);
    final info = widget.info;
    final fee = info.fee;
    final message = info.message;
    final error = _error;
    final label = _receive ? l.deskIpReceiveButton : l.deskIpPayButton;
    return SlotScaffold(
      appBar: AppBar(title: Text(inPersonReviewTitle(context, info.stage))),
      idle: _busy ? SlotProgress(label: label) : null,
      body: ScreenBody(
        bottom: BusyButton(
          label: label,
          busy: _busy,
          onPressed: _go,
          semanticsId: _receive ? TrustIds.txIpReceive : TrustIds.txIpPay,
        ),
        children: [
          ReviewAmount(amount: info.amount),
          if (!_receive && fee != null) ...[
            const SizedBox(height: 12),
            Text('${l.txDetailsFee}: ${epicExact(l, fee)}', style: theme.textTheme.bodyLarge),
          ],
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(message, maxLines: 3, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge),
          ],
          if (error != null) ...[
            const SizedBox(height: 16),
            InlineNotice(level: NoticeLevel.error, text: describeError(l, error), liveRegion: true),
          ],
        ],
      ),
    );
  }
}

/// The title of the review of a code of [stage]: a send code is received, a request is paid.
String inPersonReviewTitle(BuildContext context, InPersonStage stage) =>
    stage == InPersonStage.send ? context.l10n.deskIpReceiveTitle : context.l10n.deskIpPayRequestTitle;

/// How an answer's post went.
enum InPersonPosted {
  /// Through the code's server.
  posted,

  /// Not sent: the code names no server, or the user said Cancel. The other phone scans it.
  none,

  /// The server did not take it.
  failed,
}

/// Posts the answer [slateId] to [mailbox]: a server not in the list is asked about first.
/// Returns how it went and, once posted, the answer's check code.
Future<(InPersonPosted, String?)> postInPersonAnswer(BuildContext context, Epic1Wallet wallet, String slateId, Epic1Host? mailbox) async {
  if (mailbox == null) return (InPersonPosted.none, null);
  if (!mailbox.inRelayList) {
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
    if (use != true) return (InPersonPosted.none, null);
  }
  try {
    return (InPersonPosted.posted, await wallet.inPersonPost(slateId: slateId, relayOk: true));
  } on Object {
    return (InPersonPosted.failed, null);
  }
}

/// After answering a code: the check code for the other phone to compare once the answer is
/// posted, and the answer as a QR and text when it did not go through a server.
class InPersonAnsweredScreen extends ConsumerStatefulWidget {
  const InPersonAnsweredScreen({super.key, required this.title, required this.answer, required this.posted, this.checkCode, this.mailbox});

  final String title;
  final InPersonAnswerMade answer;
  final InPersonPosted posted;

  /// From the post; null until the answer is posted.
  final String? checkCode;

  /// The server Retry posts to.
  final Epic1Host? mailbox;

  @override
  ConsumerState<InPersonAnsweredScreen> createState() => _InPersonAnsweredScreenState();
}

class _InPersonAnsweredScreenState extends ConsumerState<InPersonAnsweredScreen> {
  late final List<String> _parts = ref.read(epic1Provider)?.qrParts(widget.answer.envelope) ?? const [];
  late InPersonPosted _posted = widget.posted;
  late String? _checkCode = widget.checkCode;
  bool _busy = false;

  Future<void> _retry() async {
    final wallet = ref.read(epic1Provider);
    if (wallet == null) return;
    setState(() => _busy = true);
    final (posted, checkCode) = await postInPersonAnswer(context, wallet, widget.answer.slateId, widget.mailbox);
    if (mounted) {
      setState(() {
        _busy = false;
        _posted = posted;
        _checkCode = checkCode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final answer = widget.answer;
    final failed = _posted == InPersonPosted.failed;
    final checkCode = _checkCode;
    return SlotScaffold(
      appBar: AppBar(title: Text(widget.title)),
      idle: _busy ? SlotProgress(label: l.commonRetry) : null,
      body: ScreenBody(
        bottom: BusyButton(label: l.commonDone, onPressed: () => Navigator.pop(context), semanticsId: TrustIds.txIpDone),
        children: [
          if (checkCode != null) ...[
            Semantics(header: true, child: Text(l.deskIpCheckTitle, style: theme.textTheme.titleLarge)),
            const SizedBox(height: 8),
            Text(l.deskIpCheckLead, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            InPersonCheck(key: inPersonCheckKey, code: checkCode),
          ],
          if (failed) ...[
            const SizedBox(height: 16),
            InlineNotice(
              level: NoticeLevel.warning,
              text: l.deskIpPostFailed,
              liveRegion: true,
              actions: [TextButton(onPressed: _busy ? null : _retry, child: Text(l.commonRetry))],
            ),
          ],
          if (_posted != InPersonPosted.posted) ...[
            const SizedBox(height: 24),
            Text(l.deskIpAnswerLead, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            InPersonQr(parts: _parts, label: l.deskKitQrOf(l.deskIpAnswerOf)),
            const SizedBox(height: 16),
            InPersonCodeText(label: l.deskIpAnswerLabel, text: answer.armored),
          ],
        ],
      ),
    );
  }
}
