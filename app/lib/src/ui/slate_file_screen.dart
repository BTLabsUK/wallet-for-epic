// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amount.dart';
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
import '../tor_build.dart';
import '../updater.dart' show updateProvider;
import '../wallet_service.dart';
import '../trust_ids.dart';
import 'common.dart';
import 'file_exchange_help.dart' show FileExchangeRole, showFileExchangeHelp;
import 'file_flow_pages.dart';
import 'kit/kit_button.dart';
import 'kit/kit_group.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_hero_amount.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_kv.dart';
import 'kit/kit_row.dart';
import 'kit/kit_sheet.dart' show KitSheet;
import 'kit/kit_step_strip.dart';
import 'kit/kit_tokens.dart';
import '../epic1.dart' show PaymentMode, looksLikeEpictx;
import 'epic1/epic1_common.dart' show epic1ModeSettingsKey, openEpic1Settings;
import 'in_person/in_person_entry.dart' show openInPersonText;
import 'finished_not_posted.dart' show FinishedNotPosted, isPostElsewhere;
import 'invoice_request_screen.dart' show requestFilesOn;
import 'invoice_review_screen.dart' show RequestFileReviewScreen, requestFileRefusal;
import 'pairing/pairing_parts.dart';
import 'qr_scan_screen.dart';
import 'qr_show_screen.dart';
import 'scan_screen.dart' show offersQrPayment;
import 'theme/brand.dart' show GlyphTile;
import 'theme/tokens.dart';
import 'tx_details_screen.dart';

/// The [SlateFile.name] of payment text pasted on Receive.
const String pastedSlateName = 'pasted';

/// The [SlateFile.name] of a payment read from an animated QR code.
const String scannedSlateName = 'scanned';

/// The keys of the QR buttons of the payment file screen, for tests.
const Key showReplyQrKey = ValueKey('slate-show-reply-qr');
const Key scanAgainKey = ValueKey('slate-scan-again');

/// The risk card of an answer to a request this wallet does not have, for tests.
const Key requestAnswerUnknownKey = ValueKey('slate-request-answer-unknown');

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
    this.scanner,
  });

  final SlateFile file;

  /// The text was pasted, not picked: it has no file name, and the reply can be copied too.
  final bool pasted;

  /// The text was read from an animated QR code (it counts as [pasted], too): the reply can
  /// be shown as a QR code.
  final bool scanned;

  /// When finalizing our own send, the id the response must carry.
  final String? expectedSlateId;

  /// The scanner this payment was read with, still open under it ([openScannedPayment]): a
  /// payment to us is offered as a sheet over the camera (InPerson-3), and anything else takes
  /// the scanner away and shows as a page.
  final Route<dynamic>? scanner;

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

  /// The scanner under this screen was taken away: the screen is a page from now on.
  bool _leftScanner = false;

  /// Takes the scanner under this screen away, once; its camera closes with it.
  void _leaveScanner() {
    if (_leftScanner) return;
    _leftScanner = true;
    final scanner = widget.scanner;
    if (scanner != null && scanner.isActive) scanner.navigator?.removeRoute(scanner);
  }

  /// True while this screen is the sheet over the scanner: reading, then a payment to us that
  /// can be accepted.
  bool _overScanner(SlateInfo? info) =>
      widget.scanner != null &&
      !_leftScanner &&
      _modeLine == null &&
      _posted == null &&
      _response == null &&
      _sealFailure == null &&
      !_answerUnknown &&
      (_reading || info != null && info.stage == SlateStage.send && _error == null);

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
    final api = ref.read(pairingApiProvider);
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
            messages: opened.messages,
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

  /// The payment mode's say on the file (epic1 spec, Files): a file of the other mode is not
  /// read, its line shown instead.
  String Function(AppLocalizations l)? _modeLine;

  /// True when the file is not read here: a file of the other mode, or an in-person code
  /// taken by its own flow. An epic1 file is opened with [Epic1Wallet.openEpictx] first.
  Future<bool> _epic1Gate() async {
    final epictx = looksLikeEpictx(_file.json) || _file.name.toLowerCase().endsWith('.epictx');
    final epic1 = ref.read(paymentModeProvider) == PaymentMode.epic1;
    if (epictx != epic1) {
      // Still in initState: the first build shows it.
      _modeLine = epic1 ? (l) => l.deskE1ModeClassicFile : (l) => l.deskE1ModeEpic1File;
      _reading = false;
      return true;
    }
    if (!epic1) return false;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return true;
    final navigator = Navigator.of(context);
    _leaveScanner();
    if (await openInPersonText(context, _file.json)) {
      if (mounted) navigator.pop(true);
      return true;
    }
    final epic1Wallet = ref.read(epic1Provider);
    if (epic1Wallet == null || !mounted) return false;
    try {
      final opened = await epic1Wallet.openEpictx(_file.json);
      // Not from a paired contact: the slate inside goes on as a plain file.
      if (opened.contactId == null && mounted) _file = SlateFile(name: _file.name, json: opened.slateJson);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = (l) => describeError(l, e);
          _reading = false;
        });
      }
      return true;
    }
    return !mounted;
  }

  Future<void> _read() async {
    SlateInfo? info;
    String Function(AppLocalizations l)? error;
    if (await _epic1Gate()) return;
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
      } else if (info.stage == SlateStage.request || info.stage == SlateStage.requestAnswer) {
        error = await _requestProblem(info);
      }
    } catch (e) {
      error = e is WalletError
          ? (l) =>
                widget.scanned ? l.qrScanNotPayment : l.slateNotTransactionFile
          : (l) => describeError(l, e);
    }
    if (!mounted) return;
    if (error == null && info != null && info.stage == SlateStage.request) {
      _toReview(info);
      return;
    }
    setState(() {
      _reading = false;
      _info = info;
      _error = error;
    });
  }

  /// Why a payment request file, or the answer to one, cannot be acted on here; null when it
  /// can (DESIGN §3.3, §3.4).
  Future<String Function(AppLocalizations l)?> _requestProblem(SlateInfo info) async {
    // A request scanned from a QR is paid like any send: only a core that pays requests.
    if (widget.scanned && info.stage == SlateStage.request && _sealedText == null) {
      final session = ref.read(sessionProvider);
      return session == null || session.supportsRequestFiles ? null : (AppLocalizations l) => l.qrScanNotPayment;
    }
    if (!requestFilesOn(ref, listen: false)) return (AppLocalizations l) => l.slateNotTransactionFile;
    // A sealed request is paid sealed ([PairingApi.paySealedRequest]), whether or not the
    // engine hands out the slate inside.
    if (info.stage == SlateStage.request) return null;
    final session = ref.read(sessionProvider);
    if (session == null) return null;
    final IssuedInvoice? issued;
    try {
      issued = await session.issuedInvoice(slateId: info.slateId);
    } on WalletError catch (_) {
      // Finishing says what is wrong, if anything.
      return null;
    }
    if (issued == null) {
      _answerUnknown = true;
      return (AppLocalizations l) => l.reqAnswerUnknown;
    }
    return switch (issued.state) {
      IssuedInvoiceState.waiting => null,
      // A second payer's answer to a code shown in person: say what it means for them.
      IssuedInvoiceState.paid when widget.scanned => (AppLocalizations l) => l.reqQrAlreadyPaid,
      IssuedInvoiceState.paid => (AppLocalizations l) => l.reqFileAlreadyPaid,
      _ => (AppLocalizations l) => l.reqFileEnded,
    };
  }

  /// The answer names no request this wallet has: a risk card and Close, nothing to finish.
  bool _answerUnknown = false;

  /// A payment request: the Review in its file form takes over this screen (DESIGN §3.3).
  void _toReview(SlateInfo info) {
    _leaveScanner();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<bool>(
        builder: (_) => RequestFileReviewScreen(
          json: _file.json,
          info: info,
          sealedText: _sealedText,
          pairingId: _sealedText != null ? _sealedFrom?.id : null,
          pasted: widget.pasted && !widget.scanned,
          scanned: widget.scanned,
        ),
      ),
    );
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

  /// "This arrived unsealed": a plain file from a paired contact that seals.
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
      final answer = _info?.stage == SlateStage.requestAnswer;
      final TxEntry tx;
      try {
        tx = await hold.during(
          () => sealedText != null ? session.pairing.finalizeSealed(sealedText) : session.finalizeAndPost(slateJson: _file.json),
        );
      } catch (error) {
        final refused = answer ? requestFileRefusal(error) : null;
        if (refused == null) rethrow;
        if (mounted) setState(() => _error = refused);
        return false;
      }
      if (answer) ref.invalidate(issuedInvoicesProvider);
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

  /// When the reply was first shown, for its "made 18:20" line.
  DateTime? _madeAt;

  /// The three steps of this exchange (HANDOFF 4) and the one in progress. An answer to our own
  /// send is the payer's side, a payment to us the receiver's; a scanned code is in person.
  (List<String>, int)? _steps(AppLocalizations l, SlateInfo? info) {
    if (info == null || _error != null && _response == null && _posted == null) return null;
    final receiving = info.stage == SlateStage.send;
    final qr = widget.scanned;
    final labels = receiving
        ? (qr
              ? [l.phoneStepRecvScan, l.phoneStepRecvShow, l.commonDone]
              : [l.phoneStepRecvFileOpen, l.phoneStepRecvFileReply, l.commonDone])
        : (qr
              ? [l.phoneStepPayShow, l.phoneStepPayScan, l.commonDone]
              : [l.phoneStepPayFileSend, l.phoneStepPayFileReply, l.commonDone]);
    final now = _posted != null ? 3 : (_response != null ? 1 : (receiving ? 0 : 1));
    return (labels, now);
  }

  /// A payment to us under its title (InPerson-3), on the page and on the sheet: the amount in
  /// the figure face at 40 with the unit and value under it, the sender's note, and what Accept
  /// does while it can be done.
  List<Widget> _incoming(AppLocalizations l, WalletTokens t, SlateInfo info) {
    final message = messageBy(info.messages, SlateRole.sender);
    final amount = epicFor(l, info.amount, surface: AmountSurface.exact, unit: false);
    final fiat = phoneFiat(l, info.amount, amountDisplay(ref), approx: true);
    return [
      const SizedBox(height: 18),
      Semantics(
        label: '+$amount $epicUnit',
        excludeSemantics: true,
        child: Text(
          '+$amount',
          textAlign: TextAlign.center,
          textScaler: TextScaler.noScaling,
          style: KitType.amountOnPage.copyWith(fontSize: 40, letterSpacing: -1.6, height: 1, color: t.ok),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        fiat == null ? epicUnit : '$epicUnit · $fiat',
        textAlign: TextAlign.center,
        style: KitType.body.copyWith(color: t.dim),
      ),
      const SizedBox(height: 18),
      if (message != null) ...[
        KitGroup(margin: EdgeInsets.zero, children: [KitKvRow(label: l.phoneAcceptNote, value: message)]),
        const SizedBox(height: 14),
      ],
      // What to do next, only while it can be done: never above a refusal.
      if (_error == null) FileInfoLine(widget.scanned ? l.phoneAcceptHintQr : l.phoneAcceptHintFile),
    ];
  }

  /// "Not now" on the sheet: back to the scanner, which reads again.
  void _notNow() {
    if (!_busy) Navigator.of(context).pop(false);
  }

  /// The payment as a sheet over the dimmed scanner (InPerson-3): the scrim, then the sheet
  /// rising from the bottom with the payment, Accept and Not now. While the payment is read
  /// there is only the scrim: the scanner's tick shows through it.
  Widget _sheet(BuildContext context, SlateInfo? info) {
    final l = context.l10n;
    final t = context.tokens;
    final route = ModalRoute.of(context);
    final shown = route?.animation ?? kAlwaysCompleteAnimation;
    final ready = !_reading && info != null;
    final shape = Theme.of(context).bottomSheetTheme.shape;
    final curve = CurvedAnimation(parent: shown, curve: Curves.easeOutCubic);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _notNow();
      },
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: curve,
                child: ModalBarrier(
                  color: t.scrim,
                  onDismiss: _notNow,
                  semanticsLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                ),
              ),
            ),
            if (ready)
              Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curve),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 640,
                      maxHeight: MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).top,
                    ),
                    child: Material(
                      color: t.sheet,
                      shape: shape,
                      clipBehavior: Clip.antiAlias,
                      child: KitSheet(
                        title: l.phoneAcceptTitle,
                        titleGap: 0,
                        actionsTop: 18,
                        buttonsGap: 4,
                        primary: KitButton(
                          label: l.phoneAcceptAccept,
                          semanticsId: TrustIds.acceptAccept,
                          busy: _busy,
                          onPressed: _busy ? null : _sign,
                        ),
                        secondary: KitButton(
                          label: l.phoneAcceptNotNow,
                          kind: KitButtonKind.ghost,
                          semanticsId: TrustIds.acceptLater,
                          onPressed: _busy ? null : _notNow,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: _incoming(l, t, info),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Semantics(liveRegion: true, label: l.slateReadingQr, child: const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final info = _info;
    final showQr = widget.scanned && offersQrPayment(ref);
    // The reply goes by QR Payment on a phone with File Transfer off; the file buttons need it on.
    final fileOn =
        (ref.watch(appSettingsProvider.select((s) => s.value?.payments)) ??
                (ref.watch(phonePaymentsProvider)
                    ? PaymentPrefs.phoneDefaults
                    : PaymentPrefs.defaults))
            .directFile;
    final List<Widget> body;
    Widget? foot;
    final receivingNow = info?.stage == SlateStage.send;
    if (_modeLine case final line?) {
      // A file of the other payment mode: why it is not read, with Settings.
      body = [
        _Headline(icon: Icons.info_outline, text: line(l)),
        const SizedBox(height: 24),
        KitButton(
          key: epic1ModeSettingsKey,
          label: l.deskE1PhSettings,
          onPressed: () {
            Navigator.pop(context, false);
            unawaited(openEpic1Settings(context));
          },
        ),
        const SizedBox(height: 8),
        KitButton(
          label: l.commonClose,
          kind: KitButtonKind.ghost,
          onPressed: () => Navigator.pop(context, false),
        ),
      ];
    } else if (_posted case final posted? when posted.repostable) {
      body = [
        NotPostedNotice(tx: posted),
        const SizedBox(height: 8),
        KitButton(label: l.commonDone, semanticsId: TrustIds.fileDone, onPressed: () => Navigator.pop(context, true)),
      ];
    } else if (_posted != null) {
      body = [
        _Headline(
          icon: Icons.check_circle,
          text: l.slatePostedHeadline(epicExact(l, info!.amount)),
        ),
        const SizedBox(height: 8),
        Text(l.slatePostedBody(confirmationsTargetOf(ref)), style: KitType.body.copyWith(color: t.dim)),
        const SizedBox(height: 24),
        KitButton(label: l.commonDone, semanticsId: TrustIds.fileDone, onPressed: () => Navigator.pop(context, true)),
      ];
    } else if (_response case final response?) {
      // A sealed answer is its own file type (RFC 3.5).
      final name = _sealedAnswer != null
          ? sealedFileName(info!.slateId, text: _sealedAnswer)
          : replyFileName(info!.slateId, loaded: _file.name == pastedSlateName || _file.name == scannedSlateName ? null : _file.name);
      final made = fileMadeTime(context, _madeAt ??= ref.read(clockProvider)());
      final amount = epicFor(l, info.amount, surface: AmountSurface.exact, unit: false);
      final hint = FileInfoLine(widget.scanned ? l.slateAcceptedHeadlineQr : (response.repeated ? l.slateRepeatedBody(epicExact(l, info.amount)) : l.phoneFileReplyHint));
      body = [
        const SizedBox(height: 22),
        KitHeroAmount(amount: '+$amount', unit: epicUnit, incoming: true),
        const SizedBox(height: 28),
        Semantics(
          liveRegion: true,
          child: FileCard(
            title: l.phoneFileReplyCard,
            sub: l.phoneFileReplySub(epicExact(l, info.amount), made),
          ),
        ),
        const SizedBox(height: 12),
        if (showQr) ...[
          KitButton(
            key: showReplyQrKey,
            icon: KitIcons.qr,
            label: l.qrShowReplyAsQr,
            semanticsId: TrustIds.fileShowqr,
            onPressed: () => _showReply(response.json, info.amount, info.slateId),
          ),
          const SizedBox(height: 10),
        ],
        if (_sealedAnswer case final sealed? when _sealedFrom != null) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SealedBadge(name: pairingName(_sealedFrom!, ref.watch(contactsProvider).value ?? const [])),
          ),
          const SizedBox(height: 12),
          SlateFileButtons(name: name, json: sealed, framed: true, reply: true, hint: hint),
        ] else if (!showQr || fileOn)
          SlateFileButtons(name: name, json: response.json, primary: !showQr, framed: true, reply: true, hint: hint)
        else ...[
          const SizedBox(height: 16),
          hint,
        ],
      ];
      foot = KitButton(label: l.commonDone, kind: KitButtonKind.quiet, semanticsId: TrustIds.fileDone, onPressed: () => Navigator.pop(context, true));
    } else if (_reading) {
      body = [
        Semantics(
          label: widget.scanned ? l.slateReadingQr : l.slateReading,
          child: const Center(child: CircularProgressIndicator()),
        ),
      ];
    } else if (_sealFailure case final failure?) {
      // A sealed file that did not open here.
      body = [
        PairEdgeNotice(
          tone: failure == PairingFailure.newerVersion ? BadgeTone.info : BadgeTone.risk,
          title: pairingFailureText(l, failure),
          body: pairingFailureBody(l, failure, file: true),
          actions: [
            // No in-app updates in the build without Tor: its store updates it.
            if (failure == PairingFailure.newerVersion && inAppUpdates)
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
        KitButton(label: l.pairClosed, kind: KitButtonKind.ghost, onPressed: () => Navigator.pop(context)),
      ];
    } else if (info == null) {
      body = [];
    } else if (_answerUnknown) {
      body = [
        InlineNotice(key: requestAnswerUnknownKey, level: NoticeLevel.error, text: l.reqAnswerUnknown, liveRegion: true),
        const SizedBox(height: 16),
        KitButton(label: l.pairClosed, kind: KitButtonKind.ghost, onPressed: () => Navigator.pop(context)),
      ];
    } else {
      final receiving = info.stage == SlateStage.send;
      // The other party's words: the sender's on a payment to us, the recipient's on an answer.
      final message = messageBy(
        info.messages,
        receiving ? SlateRole.sender : SlateRole.receiver,
      );
      final amount = epicFor(l, info.amount, surface: AmountSurface.exact, unit: false);
      body = receiving
          ? [
              // A payment to us reads as the frame's sheet (InPerson-3): `.sheet h2`, 4 further
              // in than the page.
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 14),
                child: Text(l.phoneAcceptTitle, style: KitType.sheetTitle.copyWith(color: t.text)),
              ),
              ..._incoming(l, t, info),
            ]
          : [
              // Where it came from: the file's name, or what kind of text it was.
              Text(
                widget.scanned ? l.slateScannedReplyTitle : widget.pasted ? l.slatePastedTitle : _file.name,
                style: KitType.rowTitle.copyWith(fontSize: 20, color: t.text),
              ),
              const SizedBox(height: 14),
              KitHeroAmount(amount: amount, unit: epicUnit),
              const SizedBox(height: 10),
              FileInfoLine(
                info.stage == SlateStage.requestAnswer
                    ? l.slateIncomingRequestAnswer(epicExact(l, info.amount))
                    : l.slateIncomingResponse(epicExact(l, info.amount), epicExact(l, info.fee)),
                bare: true,
              ),
              const SizedBox(height: 16),
              if (message != null) ...[
                KitGroup(
                  margin: EdgeInsets.zero,
                  children: [
                    KitRow(
                      // A request's answer carries the issuer's own message: it is this wallet's.
                      title: info.stage == SlateStage.requestAnswer ? l.invoicesMessage : l.txDetailsMessageFromRecipient,
                      value: message,
                      size: KitRowSize.settings,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              // What to do next, only while it can be done: never above a refusal.
              if (_error == null) FileInfoLine(l.slateIncomingResponseHint),
            ];
      // The primary at the foot, as on every other step (UP-013).
      if (_error == null) {
        foot = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitButton(
              label: receiving ? l.phoneAcceptAccept : l.slateFinishPayment,
              semanticsId: receiving ? TrustIds.acceptAccept : TrustIds.fileFinish,
              onPressed: _busy ? null : (receiving ? _sign : _finalize),
            ),
            if (receiving) ...[
              const SizedBox(height: 6),
              KitButton(
                label: l.phoneAcceptNotNow,
                kind: KitButtonKind.ghost,
                semanticsId: TrustIds.acceptLater,
                onPressed: _busy ? null : () => Navigator.pop(context),
              ),
            ],
          ],
        );
      }
    }
    if (_overScanner(info)) return _sheet(context, info);
    if (widget.scanner != null && !_leftScanner) {
      // A page from here on: the scanner under it goes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _leaveScanner();
      });
    }
    final error = _error;
    final strip = _steps(l, info);
    final title = widget.scanned
        ? (receivingNow == false ? l.phoneQrTitlePay : l.phoneQrTitleReceive)
        : (receivingNow == false ? l.sendPayByFile : l.phoneFileTitleReceive);
    return SlotScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitFlowHeader(
              title: title,
              back: true,
              onLeading: () => Navigator.of(context).maybePop(),
              leadingId: TrustIds.fileBack,
              onHelp: widget.scanned || info == null
                  ? null
                  : () => showFileExchangeHelp(context, role: receivingNow == false ? FileExchangeRole.sender : FileExchangeRole.receiver),
            ),
            if (strip != null) KitStepStrip(labels: strip.$1, current: strip.$2),
            Expanded(
              child: _FileBody(
                foot: foot,
                children: [
                  ...body,
                  if (error != null && !_answerUnknown) ...[
                    ErrorText(error(l)),
                    // A scan that failed is not the end: read the code again.
                    if (widget.scanned && !_busy && _response == null) ...[
                      const SizedBox(height: 8),
                      KitButton(
                        key: scanAgainKey,
                        icon: KitIcons.scan,
                        label: l.qrScanAgain,
                        semanticsId: TrustIds.fileScanagain,
                        onPressed: _scanAgain,
                      ),
                      const SizedBox(height: 4),
                      KitButton(label: l.scanQrBack, kind: KitButtonKind.ghost, onPressed: () => Navigator.pop(context)),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The body of a file page, as in the frames: [children] scrolling at 16 from the edges and the
/// [foot] at the bottom with no rule above it (`.foot`).
class _FileBody extends StatelessWidget {
  const _FileBody({required this.children, this.foot});

  final List<Widget> children;
  final Widget? foot;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(Kit.gutter, 0, Kit.gutter, Kit.gutter), children: children)),
          if (foot != null) Padding(padding: const EdgeInsets.symmetric(horizontal: Kit.gutter), child: foot),
        ],
      ),
    ),
  );
}

/// A payment file the wallet made, ready to hand over (DESIGN §3.2, §3.3): a file tile, the
/// title and what to do with the file, the file's name and amount, Save to device and Share.
/// [badge] goes under the lead ("Sealed for Anna").
class SlateFileResult extends StatelessWidget {
  const SlateFileResult({
    super.key,
    required this.title,
    required this.lead,
    required this.fileName,
    required this.amount,
    required this.json,
    this.copyable = false,
    this.badge,
  });

  final String title;
  final String lead;
  final String fileName;
  final BigInt amount;
  final String json;
  final bool copyable;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GlyphTile(size: 48, child: Icon(Icons.description_outlined, color: t.accentText)),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                header: true,
                liveRegion: true,
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(lead, style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
        if (badge != null) ...[
          const SizedBox(height: 8),
          Align(alignment: AlignmentDirectional.centerStart, child: badge),
        ],
        const SizedBox(height: 12),
        PairCard(
          children: [
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(fileName, style: TextStyle(fontFamily: t.monoFamily), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            ListTile(leading: const Icon(Icons.payments_outlined), title: Text(epicExact(l, amount))),
          ],
        ),
        const SizedBox(height: 12),
        SlateFileButtons(name: fileName, json: json, copyable: copyable),
      ],
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
    this.onHandedOver,
    this.framed = false,
    this.reply = false,
    this.hint,
    this.saveApart = false,
    this.saveOnly = false,
  });

  final String name;
  final String json;
  final bool copyable;

  /// Whether "Save to device" is the filled button. False when another button above it is.
  final bool primary;

  /// Called once the file was saved or shared, so the screen can move its primary on.
  final VoidCallback? onHandedOver;

  /// On the file pages of the redesign: "Copy as text" beside a gold "Share reply", "Save to
  /// device" under them. Off, the buttons keep their older words.
  final bool framed;

  /// With [framed]: the file is a reply, so the share button says "Share reply", not "Share file".
  final bool reply;

  /// With [framed]: the line under the buttons; "Save to device" follows it.
  final Widget? hint;

  /// With [framed]: leave "Save to device" out where a share sheet exists; the page draws it
  /// lower with [saveOnly], where its frame has room.
  final bool saveApart;

  /// With [framed]: only the quiet "Save to device" of a [saveApart] page; nothing where the
  /// platform has no share sheet (Save is then the button beside Copy).
  final bool saveOnly;

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
      if (ok) onHandedOver?.call();
    } catch (error) {
      logWarn('files', 'handing over a transaction file failed: $error');
      notice.show(failed, level: NoticeLevel.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final files = ref.watch(slateFilesProvider);
    final saveLabel = l.slateSaveToDevice;
    void save() => _out(
      context,
      ref,
      (f) =>
          f.save(name: name, json: json, dialogTitle: l.slateSaveDialogTitle),
      done: l.slateSaved(name),
    );
    final copy = copyable || framed
        ? KitButton(
            icon: KitIcons.copy,
            label: framed ? l.phoneFileCopyText : l.slateCopyReply,
            kind: KitButtonKind.quiet,
            semanticsId: TrustIds.fileCopy,
            onPressed: () => copySecretText(context, json, l.slateCopied),
          )
        : null;
    final share = files.canShare
        ? KitButton(
            icon: KitIcons.share,
            label: framed ? (reply ? l.phoneFileShareReply : l.phoneFileShare) : l.commonShare,
            kind: primary ? KitButtonKind.gold : KitButtonKind.quiet,
            semanticsId: TrustIds.fileShare,
            onPressed: () => _out(context, ref, (f) => f.share(name: name, json: json)),
          )
        : null;
    final saveButton = KitButton(
      icon: Icons.save_alt_rounded,
      label: saveLabel,
      kind: framed && share != null ? KitButtonKind.ghost : (share == null && primary ? KitButtonKind.gold : KitButtonKind.quiet),
      semanticsId: TrustIds.fileSave,
      onPressed: save,
    );
    if (framed && saveOnly) return share == null ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.only(top: 12), child: saveButton);
    if (framed && copy != null) {
      // The frame: Copy as text beside the gold share, the hint, and Save to device last (the
      // frame has no room for it, so it is a quiet line under the hint).
      final noShare = share == null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [Expanded(child: copy), const SizedBox(width: 10), Expanded(child: share ?? saveButton)]),
          if (hint != null) ...[const SizedBox(height: 16), hint!],
          if (!noShare && !saveApart) ...[const SizedBox(height: 22), saveButton],
        ],
      );
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?share,
          if (share != null && copy != null) const SizedBox(height: 10),
          ?copy,
          if (share != null || copy != null) const SizedBox(height: 10),
          saveButton,
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
    // Finalized under Kill switch: not a refusal, a payment for a device that is online.
    if (isPostElsewhere(tx)) return FinishedNotPosted(tx: tx);
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

/// Opens a payment read by the receiver's scanner over the scanner itself ([QrOpen]): a payment
/// to us is the sheet of InPerson-3, anything else a page that takes the scanner away. True
/// when the scanner should read again: "Not now", back, or text that is not a payment file.
Future<bool> openScannedPayment(BuildContext scanner, String json) async {
  final String text;
  try {
    text = decodeSlateFile(utf8.encode(json));
  } on FormatException catch (error) {
    final container = ProviderScope.containerOf(scanner, listen: false);
    container.read(noticeProvider.notifier).show(describeError(scanner.l10n, error), level: NoticeLevel.error);
    return true;
  }
  final route = ModalRoute.of(scanner);
  final still = MediaQuery.disableAnimationsOf(scanner);
  await Navigator.of(scanner).push<bool>(
    PageRouteBuilder<bool>(
      opaque: false,
      transitionDuration: still ? Duration.zero : const Duration(milliseconds: 280),
      reverseTransitionDuration: still ? Duration.zero : const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => SlateFileScreen(
        file: SlateFile(name: scannedSlateName, json: text),
        pasted: true,
        scanned: true,
        scanner: route,
      ),
      transitionsBuilder: (_, _, _, child) => child,
    ),
  );
  // A scanner taken away meanwhile is closed already; one still here reads again.
  return true;
}
