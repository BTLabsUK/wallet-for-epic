import 'dart:async';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../errors.dart';
import '../l10n.dart';
import '../pairing_providers.dart';
import '../pairing_text.dart';
import '../contacts.dart' show contactsProvider;
import '../payment_prefs.dart';
import '../providers.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../updater.dart' show updateProvider;
import '../wallet_service.dart';
import 'common.dart';
import 'pairing/pairing_parts.dart';
import 'qr_scan_screen.dart';
import 'qr_show_screen.dart';
import 'scan_screen.dart' show offersQrPayment;
import 'theme/tokens.dart';
import 'tx_details_screen.dart';
import 'pairing/experimental_off.dart';

/// The [SlateFile.name] of payment text pasted on Receive.
const String pastedSlateName = 'pasted';

/// The [SlateFile.name] of a payment read from an animated QR code.
const String scannedSlateName = 'scanned';

/// The keys of the QR buttons of the payment file screen, for tests.
const Key showReplyQrKey = ValueKey('slate-show-reply-qr');
const Key scanAgainKey = ValueKey('slate-scan-again');

/// How many payment screens of a scanned QR code are open. Home then keeps its "on the way"
/// notice to itself: the screen already says the payment is accepted, and the notice would
/// cover its headline. A plain counter: a provider cannot change in a widget's life cycle.
int qrPaymentScreensOpen = 0;

/// One transaction file: shows what it is, then signs it (a send to us) or finalizes it (the
/// answer to our send). Opened from Receive (a file or pasted text), from Send's second step,
/// and from files other apps hand to the wallet.
/// The Check for updates button of a file sealed by a newer wallet, for tests.
const Key slateCheckUpdatesKey = ValueKey('slate-check-updates');

class SlateFileScreen extends ConsumerStatefulWidget {
  const SlateFileScreen({
    super.key,
    required this.file,
    this.expectedSlateId,
    this.pasted = false,
    this.scanned = false,
  });

  final SlateFile file;

  /// The text was pasted, not picked: it has no file name, and the reply can be copied too.
  final bool pasted;

  /// The text was read from an animated QR code (it counts as [pasted], too): the reply can
  /// be shown as a QR code.
  final bool scanned;

  /// When finalizing our own send, the id the response must carry.
  final String? expectedSlateId;

  @override
  ConsumerState<SlateFileScreen> createState() => _SlateFileScreenState();
}

class _SlateFileScreenState extends ConsumerState<SlateFileScreen> {
  /// The text being read: [SlateFileScreen.file], or what Scan again read after it.
  late SlateFile _file = widget.file;
  SlateInfo? _info;

  /// What went wrong, worded when shown: the file is checked from [initState], before the
  /// screen's strings can be read.
  String Function(AppLocalizations l)? _error;
  bool _busy = false;

  /// The signed answer, once made, so it can be handed over again. A repeat carries the answer
  /// given the first time.
  ReceivedSlate? _response;
  TxEntry? _posted;

  /// True until the core has read the file.
  bool _reading = true;

  /// The paired contact a sealed file came from (RFC 3.4): the answer goes back sealed.
  PairingRecord? _sealedFrom;

  /// The sealed text as it came, acted on sealed ([PairingApi.receiveSealed],
  /// [PairingApi.finalizeSealed]); and what it holds when the engine does not hand out the
  /// slate inside.
  String? _sealedText;
  SlateInfo? _sealedInfo;

  /// "This arrived unsealed" was said already.
  bool _toldUnsealed = false;

  /// Why a sealed file did not open: sealed for another wallet or install, or by a newer one.
  PairingFailure? _sealFailure;

  @override
  void initState() {
    super.initState();
    if (widget.scanned) qrPaymentScreensOpen++;
    _read();
  }

  @override
  void dispose() {
    if (widget.scanned) qrPaymentScreensOpen--;
    super.dispose();
  }

  /// Opens sealed text with the pairing engine (RFC 3.4), and tells a plain file from a paired
  /// contact that seals ("This arrived unsealed"). False when a sealed file did not open.
  Future<bool> _open() async {
    final sealed = isSealedText(_file.json);
    // A sealed file needs Pairing; off (Settings › Advanced) it says so and opens nothing. The
    // settings are read first: the screen can open before they are loaded.
    final settings = await ref.read(appSettingsProvider.future);
    if (!mounted) return false;
    final api = ref.read(pairingApiProvider);
    if (sealed && !settings.advanced.pairingOn) {
      if (mounted) unawaited(showExperimentalOffSheet(context, ref));
      return false;
    }
    if (!api.supported) return true;
    try {
      final opened = await api.openSlate(_file.json);
      final from = opened.pairingId == null ? null : await api.pairing(opened.pairingId!);
      if (!mounted) return false;
      if (sealed) {
        _sealedText = _file.json;
        _sealedFrom = from;
        if (opened.slateJson case final json?) {
          _file = SlateFile(name: _file.name, json: json);
        } else {
          _sealedInfo = SlateInfo(
            slateId: opened.slateId ?? '',
            amount: opened.amount ?? BigInt.zero,
            fee: opened.fee ?? BigInt.zero,
            stage: opened.stage ?? SlateStage.send,
          );
        }
      } else if (from != null && from.seals) {
        _tellUnsealed(from);
      }
      return true;
    } catch (error) {
      final failure = pairingFailureOf(error);
      if (!sealed) return true;
      if (mounted) setState(() => _sealFailure = failure ?? PairingFailure.invalid);
      return false;
    }
  }

  Future<void> _read() async {
    SlateInfo? info;
    String Function(AppLocalizations l)? error;
    if (!await _open()) {
      if (mounted) setState(() => _reading = false);
      return;
    }
    try {
      info = _sealedInfo ?? await ref.read(walletServiceProvider).inspectSlate(json: _file.json);
      final expected = widget.expectedSlateId;
      if (expected != null && info.slateId != expected) {
        error = (l) =>
            widget.scanned ? l.slateWrongPaymentQr : l.slateWrongPayment;
      } else if (info.stage == SlateStage.invoice) {
        error = (l) => l.slateInvoiceUnsupported;
      }
    } catch (e) {
      error = e is WalletError
          ? (l) =>
                widget.scanned ? l.qrScanNotPayment : l.slateNotTransactionFile
          : (l) => describeError(l, e);
    }
    if (!mounted) return;
    setState(() {
      _reading = false;
      _info = info;
      _error = error;
    });
  }

  /// Runs one wallet action at a time, then refreshes home, even if this screen has closed,
  /// unless the action returns false because it changed nothing.
  Future<void> _run(Future<bool> Function(WalletSession session) action) async {
    if (_busy) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (await action(session)) container.invalidate(homeProvider);
    } catch (error) {
      if (mounted) setState(() => _error = (l) => describeError(l, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "This arrived unsealed": a plain file from a paired contact that seals (SPEC 2.9).
  void _tellUnsealed(PairingRecord from) {
    if (_toldUnsealed || !mounted) return;
    _toldUnsealed = true;
    final l = context.l10n;
    final name = pairingName(from, ref.read(contactsProvider).value ?? const []);
    ref.read(noticeProvider.notifier).show('${l.openArrivedUnsealed} ${l.openArrivedUnsealedBody(name)}', level: NoticeLevel.info);
  }

  Future<void> _sign() => _run((session) async {
    // Sealed in, sealed back (RFC 9.2): the engine receives it and seals the answer to the
    // sender when it can.
    final sealedText = _sealedText;
    if (sealedText != null) {
      final reply = await session.pairing.receiveSealed(sealedText);
      if (mounted) {
        setState(() {
          _response = ReceivedSlate(slateId: reply.slateId, json: reply.answer, repeated: reply.repeated);
          _sealedAnswer = reply.sealed ? reply.answer : null;
        });
      }
      return !reply.repeated;
    }
    final response = await session.receiveSlate(slateJson: _file.json);
    if (mounted) setState(() => _response = response);
    // A plain file can name its paired sender only once it is received.
    if (ref.read(pairingSupportedProvider) && !_toldUnsealed) {
      try {
        final slate = await session.pairing.slateOf(response.slateId);
        final from = slate == null ? null : await session.pairing.pairing(slate.pairingId);
        if (from != null && from.seals) _tellUnsealed(from);
      } on WalletError catch (_) {
        // Only the notice is lost.
      }
    }
    return !response.repeated;
  });

  /// The answer sealed for [_sealedFrom], when the payment came sealed.
  String? _sealedAnswer;

  Future<void> _finalize() {
    final hold = ref.read(autoLockHoldProvider.notifier);
    return _run((session) async {
      final sealedText = _sealedText;
      final tx = await hold.during(
        () => sealedText != null ? session.pairing.finalizeSealed(sealedText) : session.finalizeAndPost(slateJson: _file.json),
      );
      if (mounted) setState(() => _posted = tx);
      return true;
    });
  }

  /// The reply as an animated QR for the sender; Done there closes this screen too.
  Future<void> _showReply(String json, BigInt amount, String slateId) async {
    final result = await showReplyQr(
      context,
      json: json,
      amount: amount,
      slateId: slateId,
    );
    if (result is QrShowDone && mounted) Navigator.pop(context, true);
  }

  /// Reads another code in place of the one that failed.
  Future<void> _scanAgain() async {
    final reply = widget.expectedSlateId != null;
    final result = await scanQrSlate(
      context,
      reply ? QrScanKind.reply : QrScanKind.payment,
    );
    if (!mounted || result is! QrScanned) return;
    final String decoded;
    try {
      decoded = decodeSlateFile(utf8.encode(result.json));
    } on FormatException {
      setState(() => _error = (l) => l.qrScanNotPayment);
      return;
    }
    setState(() {
      _file = SlateFile(name: scannedSlateName, json: decoded);
      _reading = true;
      _info = null;
      _error = null;
    });
    await _read();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final info = _info;
    final theme = Theme.of(context);
    final showQr = widget.scanned && offersQrPayment(ref);
    // The reply goes by QR Payment on a phone with File Transfer off; the file buttons need it on.
    final fileOn =
        (ref.watch(appSettingsProvider.select((s) => s.value?.payments)) ??
                (ref.watch(phonePaymentsProvider)
                    ? PaymentPrefs.phoneDefaults
                    : PaymentPrefs.defaults))
            .directFile;
    final List<Widget> body;
    if (_posted case final posted? when posted.repostable) {
      body = [
        NotPostedNotice(tx: posted),
        const SizedBox(height: 8),
        BusyButton(
          label: l.commonDone,
          onPressed: () => Navigator.pop(context, true),
        ),
      ];
    } else if (_posted != null) {
      body = [
        _Headline(
          icon: Icons.check_circle,
          text: l.slatePostedHeadline(epicExact(l, info!.amount)),
        ),
        const SizedBox(height: 8),
        Text(l.slatePostedBody(confirmationsTargetOf(ref))),
        const SizedBox(height: 24),
        BusyButton(
          label: l.commonDone,
          onPressed: () => Navigator.pop(context, true),
        ),
      ];
    } else if (_response case final response?) {
      // A sealed answer is its own file type (RFC 3.5).
      final name = _sealedAnswer != null ? sealedFileName(info!.slateId) : responseFileName(info!.slateId);
      body = [
        _Headline(
          icon: Icons.check_circle,
          text: widget.scanned
              ? l.slateAcceptedHeadlineQr
              : response.repeated
              ? l.slateRepeatedHeadline(name)
              : l.slateAcceptedHeadline(name),
        ),
        const SizedBox(height: 8),
        Text(
          response.repeated
              ? l.slateRepeatedBody(epicExact(l, info.amount))
              : l.slateAcceptedBody(epicExact(l, info.amount)),
        ),
        const SizedBox(height: 24),
        if (showQr) ...[
          FilledButton.icon(
            key: showReplyQrKey,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(MethodIcons.qr),
            label: Text(l.qrShowReplyAsQr),
            onPressed: () =>
                _showReply(response.json, info.amount, info.slateId),
          ),
          const SizedBox(height: 8),
        ],
        if (_sealedAnswer case final sealed? when _sealedFrom != null) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SealedBadge(name: pairingName(_sealedFrom!, ref.watch(contactsProvider).value ?? const [])),
          ),
          const SizedBox(height: 12),
          SlateFileButtons(
            name: name,
            json: sealed,
            copyable: widget.pasted,
          ),
        ] else if (!showQr || fileOn)
          SlateFileButtons(
            name: name,
            json: response.json,
            copyable: widget.pasted,
            primary: !showQr,
          ),
        if (!showQr || fileOn) const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.commonDone),
        ),
      ];
    } else if (_reading) {
      body = [
        Semantics(
          label: widget.scanned ? l.slateReadingQr : l.slateReading,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ];
    } else if (_sealFailure case final failure?) {
      // A sealed file that did not open here (RFC 3.4, SPEC 2.9).
      body = [
        PairEdgeNotice(
          tone: failure == PairingFailure.newerVersion ? BadgeTone.info : BadgeTone.risk,
          title: pairingFailureText(l, failure),
          body: pairingFailureBody(l, failure, file: true),
          actions: [
            if (failure == PairingFailure.newerVersion)
              FilledButton(
                key: slateCheckUpdatesKey,
                onPressed: () {
                  ref.read(updateProvider.notifier).check();
                  ref.read(noticeProvider.notifier).show(l.updateChecking, level: NoticeLevel.info);
                },
                child: Text(l.pairCheckForUpdates),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () => Navigator.pop(context),
          child: Text(l.pairClosed),
        ),
      ];
    } else if (info == null) {
      body = [];
    } else {
      final receiving = info.stage == SlateStage.send;
      // The other party's words: the sender's on a payment to us, the recipient's on an answer.
      final message = messageBy(
        info.messages,
        receiving ? SlateRole.sender : SlateRole.receiver,
      );
      body = [
        Text(
          widget.scanned
              ? (receiving
                    ? l.slateScannedPaymentTitle
                    : l.slateScannedReplyTitle)
              : widget.pasted
              ? l.slatePastedTitle
              : _file.name,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          receiving
              ? l.slateIncomingSend(epicExact(l, info.amount))
              : l.slateIncomingResponse(
                  epicExact(l, info.amount),
                  epicExact(l, info.fee),
                ),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          receiving
              ? (widget.scanned
                    ? l.slateIncomingSendHintQr
                    : l.slateIncomingSendHint)
              : l.slateIncomingResponseHint,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            receiving
                ? l.txDetailsMessageFromSender
                : l.txDetailsMessageFromRecipient,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          SelectableText(message, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: 24),
        if (_error == null)
          BusyButton(
            label: receiving ? l.slateAcceptPayment : l.slateFinishPayment,
            busy: _busy,
            onPressed: receiving ? _sign : _finalize,
          ),
      ];
    }
    final error = _error;
    return SlotScaffold(
      appBar: AppBar(
        title: Text(widget.scanned ? MethodIcons.fullName(l, MethodKind.directQr) : l.slateFileTitle),
      ),
      body: ScreenBody(
        children: [
          ...body,
          if (error != null) ...[
            ErrorText(error(l)),
            // A scan that failed is not the end: read the code again.
            if (widget.scanned && !_busy && _response == null) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                key: scanAgainKey,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(l.qrScanAgain),
                onPressed: _scanAgain,
              ),
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(l.scanQrBack),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// "Save to device" first, then "Share" where the platform has a share sheet for files. Many
/// phones' share sheets have no "save to files" target, so saving must not depend on it. Both
/// run under the auto-lock hold, since they open another app. With [copyable], a "Copy reply"
/// button follows, for an answer to pasted text.
class SlateFileButtons extends ConsumerWidget {
  const SlateFileButtons({
    super.key,
    required this.name,
    required this.json,
    this.copyable = false,
    this.primary = true,
  });

  final String name;
  final String json;
  final bool copyable;

  /// Whether "Save to device" is the filled button. False when another button above it is.
  final bool primary;

  Future<void> _out(
    BuildContext context,
    WidgetRef ref,
    Future<bool> Function(SlateFiles files) action, {
    String? done,
  }) async {
    final files = ref.read(slateFilesProvider);
    // Read now: the notice outlives this button if the screen closes meanwhile.
    final notice = ref.read(noticeProvider.notifier);
    final failed = context.l10n.slateHandOverFailed(name);
    try {
      final ok = await ref
          .read(autoLockHoldProvider.notifier)
          .during(() => action(files));
      if (ok && done != null) notice.show(done, level: NoticeLevel.success);
    } catch (error) {
      logWarn('files', 'handing over a transaction file failed: $error');
      notice.show(failed, level: NoticeLevel.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final files = ref.watch(slateFilesProvider);
    const icon = Icon(Icons.save_alt);
    final label = Text(l.slateSaveToDevice);
    void save() => _out(
      context,
      ref,
      (f) =>
          f.save(name: name, json: json, dialogTitle: l.slateSaveDialogTitle),
      done: l.slateSaved(name),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (primary)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: icon,
            label: label,
            onPressed: save,
          )
        else
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: icon,
            label: label,
            onPressed: save,
          ),
        if (files.canShare) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.share),
            label: Text(l.commonShare),
            onPressed: () =>
                _out(context, ref, (f) => f.share(name: name, json: json)),
          ),
        ],
        if (copyable) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.copy),
            label: Text(l.slateCopyReply),
            onPressed: () => copyText(context, json, l.slateCopied),
          ),
        ],
      ],
    );
  }
}

/// A send that is finished (finalized) but that the network has not taken yet. The wallet will
/// broadcast it again from the payment; sending again would pay twice.
class NotPostedNotice extends StatelessWidget {
  const NotPostedNotice({super.key, required this.tx});

  final TxEntry tx;

  /// The explanation under the headline.
  static String text(AppLocalizations l) => l.slateNotPostedBody;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: theme.colorScheme.error, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.slateNotPostedTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(text(l), style: theme.textTheme.bodyLarge),
        if (tx.statusDetail case final detail? when detail.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(detail, style: theme.textTheme.bodySmall),
          ),
        const SizedBox(height: 16),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => TxDetailsScreen(txKey: tx.key),
            ),
          ),
          child: Text(l.slateOpenPayment),
        ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          // A done headline: the success green, not the brand gold.
          Icon(icon, color: context.tokens.ok),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

/// Picks a transaction file and opens it in [SlateFileScreen]. Shows a notice when the file
/// cannot be read. Returns true when the file was signed or finalized.
Future<bool> openSlateFile(
  BuildContext context,
  WidgetRef ref, {
  String? expectedSlateId,
}) async {
  // Read before the picker: the calling screen may be gone when it returns.
  final notice = ref.read(noticeProvider.notifier);
  final l = context.l10n;
  final SlateFile? file;
  try {
    file = await ref
        .read(autoLockHoldProvider.notifier)
        .during(
          () => ref
              .read(slateFilesProvider)
              .pick(dialogTitle: l.slateOpenDialogTitle),
        );
  } on FormatException catch (e) {
    notice.show(describeError(l, e), level: NoticeLevel.error);
    return false;
  }
  if (file == null || !context.mounted) return false;
  final done = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) =>
          SlateFileScreen(file: file!, expectedSlateId: expectedSlateId),
    ),
  );
  return done ?? false;
}
