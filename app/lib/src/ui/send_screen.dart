// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import '../help/help_content.dart' show HelpAnchor;
import 'cancel_note.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../app_log.dart';
import '../amount.dart';
import '../contacts.dart';
import '../pairing_providers.dart'
    show PairNet, contactPairingProvider, pairNetProvider, pairingApiProvider, pairingByIdProvider, pairingName, pairingNameProvider, pairingSupportedProvider, pairingsProvider;
import '../demo.dart' show demoModeProvider;
import '../errors.dart';
import '../initials.dart';
import '../l10n.dart';
import '../tor_build.dart';
import '../network.dart';
import '../network_gate.dart';
import '../payment_prefs.dart';
import '../phone_tor.dart';
import '../price.dart';
import '../providers.dart';
import '../connection_state.dart' show walletStatusProvider;
import 'status.dart' show EpicboxState;
import '../scan/incoming_link.dart' show linkBusyProvider;
import '../scan/scan_checks.dart';
import '../scan/scan_router.dart';
import '../scan/scan_text.dart' show directHostBesideOf;
import '../send_preflight.dart';
import '../settings.dart';
import '../smart_outputs.dart' show planSessionSend;
import '../slate_files.dart';
import '../tor_phone.dart';
import '../tor_routes.dart';
import '../utf8_limit.dart';
import '../wallet_service.dart';
import '../wallet/stored_send.dart';
import '../devices/device_providers.dart' show heldValueByDevice;
import '../devices/phone_devices.dart' show deviceServiceProvider, phoneDevices;
import 'centered_body.dart';
import 'common.dart';
import 'contacts_screen.dart';
import 'demo_screens.dart' show TestCoinsButton;
import 'file_exchange_help.dart';
import 'handshake.dart';
import 'home_parts.dart' show outputsShown;
import 'help_screen.dart';
import 'info_hint.dart';
import 'method_names.dart';
import 'method_strip.dart';
import 'pairing/pair_check.dart' show CheckWordsScreen;
import 'pairing/pairing_parts.dart';
import 'pairing/send_pairing.dart';
import 'status_icons.dart';
import 'net_block.dart';
import 'payment_gate.dart';
import 'pin.dart' show askPin, usesPassphrase;
import 'qr_scan_screen.dart';
import 'payment_code_ui.dart';
import 'qr_show_screen.dart';
import 'scan_route.dart';
import 'scan_screen.dart';
import 'shell_header.dart' show comingIn;
import 'send_tracker.dart';
import 'slate_file_screen.dart';
import 'theme/brand.dart';
import 'theme/protocol.dart' show EdgeCard, TimelineStep;
import 'theme/advanced.dart';
import 'theme/tokens.dart';
import 'tor_ui.dart';
import 'tour/tour_target.dart';
import '../settings_file/host_settings.dart' show appConfig, hostSettings;

export '../utf8_limit.dart';

// Sending, in three steps: the recipient, the amount, a review with quiet checks; then a
// tracker that follows the payment as both wallets finish it. A method selector on top picks
// Epicbox, HTTP, Tor or File, and follows the kind of address given. A payment file is also
// the fallback when their relay does not answer.

/// The key of the row under the amount with "Use USD" and "Max", for tests.
const Key amountSuffixKey = ValueKey('send-amount-suffix');

/// The key of the Epicbox-not-connected card on the method step, for tests.
const Key sendEpicboxDownKey = ValueKey('send-epicbox-down');

/// Each step's fields have their own key, so a step never takes over another's text field:
/// on the web, Flutter keeps one DOM element per field and cannot turn the address's
/// multi-line one into a number input.
const Key sendRecipientFieldKey = ValueKey('send-recipient-field');
const Key sendAmountFieldKey = ValueKey('send-amount-field');
const Key sendFileAmountFieldKey = ValueKey('send-file-amount-field');

/// The × in the filled To field, for tests.
const Key sendRecipientClearKey = ValueKey('send-recipient-clear');
const Key sendNoteFieldKey = ValueKey('send-note-field');

/// The review's "Uses all N outputs · change 1 output" line (strategy All).
const Key sendUsesAllOutputsKey = ValueKey('send-uses-all-outputs');
const Key sendFileNoteFieldKey = ValueKey('send-file-note-field');

/// The review's Message block: the text as entered, and that it is kept in the history.
const Key sendReviewMessageKey = ValueKey('send-review-message');
const Key sendReplyFieldKey = ValueKey('send-reply-field');

/// The keys of the QR buttons of the file made step, for tests.
const Key sendShowQrKey = ValueKey('send-show-qr');
const Key sendScanReplyKey = ValueKey('send-scan-reply');
const Key sendOpenReplyKey = ValueKey('send-open-reply');

/// Try again and Cancel payment on the review after a failed Tor send, for tests.
const Key sendTryAgainKey = ValueKey('send-try-again');

/// The warning that the recipient's relay is not one the app knows, for tests.
const Key sendUnknownRelayKey = ValueKey('send-unknown-relay');
const Key sendCancelPaymentKey = ValueKey('send-cancel-payment');

/// The review's card that a mailbox payment waits while Epicbox is off, and the tracker's
/// "Payment queued", for tests.
const Key sendQueuedCardKey = ValueKey('send-queued-card');
const Key sendQueuedHeadlineKey = ValueKey('send-queued-headline');

/// Send's method selector, and the tag beside the To label after the method followed the
/// address, for tests.
const Key sendMethodsKey = ValueKey('send-methods');

/// The off-note's Turn on button, under a Link method switched off.
const Key sendTurnOnMethodKey = ValueKey('send-turn-on-method');

/// The Smallest / All choice for this payment, shown with Advanced › Send options.
const Key sendStrategyKey = ValueKey('send-strategy');
const Key sendSwitchedTagKey = ValueKey('send-switched-tag');

/// The shape of an HTTP address, in the sentence about an incomplete one: the configured
/// listener port (`http.listen_port`).
String get sendHttpShape => 'http://host:${appConfig.httpListenPort}';

/// The shape of an address for [method], under the To field while it is empty.
String? sendAddressShape(AppLocalizations l, TransferMethod method) =>
    switch (method) {
      TransferMethod.epicbox => 'esXXXX…XXXX@${hostSettings.epicboxUse}',
      TransferMethod.direct => torBuilt ? l.methodDirectShape('${appConfig.httpListenPort}') : sendHttpShape,
      TransferMethod.qr || TransferMethod.file => null,
    };

/// The method a recipient of [kind] is paid by: an http(s) or onion address is Direct.
TransferMethod methodForRecipient(RecipientKind kind) => switch (kind) {
  RecipientKind.epicbox => TransferMethod.epicbox,
  RecipientKind.http || RecipientKind.tor => TransferMethod.direct,
};

/// The connection a payment to [to] takes, for the Tor switch ([torWay]). Plain `http://` to
/// another device is a route of its own: it never goes through a Tor exit.
TorRoute sendRoute(Recipient to) => switch (to.kind) {
  RecipientKind.epicbox => TorRoute.epicbox,
  RecipientKind.http when plainHttpToOtherDevice(to.address) => TorRoute.plainHttpDirect,
  RecipientKind.http => TorRoute.httpDirect,
  RecipientKind.tor => TorRoute.onionDirect,
};

/// Send's notice under To and the Tor buttons in it, for tests.
const Key sendTorNoticeKey = ValueKey('send-tor-notice');
const Key sendTurnOnTorKey = ValueKey('send-turn-on-tor');
const Key sendTurnOffTorKey = ValueKey('send-turn-off-tor');
const Key sendPlainHttpOffInfoKey = ValueKey('send-plain-http-off-info');

/// The tag beside To that says whether the payment goes over Tor, for tests.
const Key sendTorTagKey = ValueKey('send-tor-tag');

/// Keys of the sealed file route, for tests.
const Key sendSealedOptionKey = ValueKey('send-sealed-option');
const Key sendPlainOptionKey = ValueKey('send-plain-option');
const Key sendPlainShortKey = ValueKey('send-plain-short');
const Key sendAsPlainKey = ValueKey('send-as-plain');
const Key sendAsPlainConfirmKey = ValueKey('send-as-plain-confirm');

/// The payment Send's tracker is showing, while it shows one, so home does not repeat the
/// tracker's news in a notice.
final trackedSendProvider = NotifierProvider<TrackedSendNotifier, String?>(
  TrackedSendNotifier.new,
);

class TrackedSendNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(sessionProvider);
    return null;
  }

  /// [key] is the [TxEntry.key] on the tracker, or null when none is shown.
  void track(String? key) => state = key;
}

/// Where the Send tab is. An address payment goes recipient, amount, review, then the
/// tracker; a payment file goes amount, file made, then sent.
enum SendStage {
  recipient,
  amount,
  review,
  sent,
  fileAmount,
  fileMade,
  fileSent,
}

/// The Send tab's content. The recipient comes from [sendRecipientProvider] (a scanned QR code,
/// Send again), at the start and whenever a new one is handed over.
class SendView extends ConsumerStatefulWidget {
  const SendView({super.key, required this.onDone});

  /// The payment is finished or handed to the network: the shell goes back to Wallet and
  /// starts a fresh form.
  final VoidCallback onDone;

  @override
  ConsumerState<SendView> createState() => _SendViewState();
}

/// What the tracker follows.
class _Sent {
  const _Sent({
    required this.tx,
    required this.amount,
    required this.to,
    this.reviewedFee,
    this.noteSaved = true,
    this.pairingId,
    this.queued = false,
  });

  /// The payment as the send returned it; the tracker follows it in [homeProvider].
  final TxEntry tx;
  final BigInt amount;
  final Recipient to;

  /// Sent through the mailbox of this pairing (a contact with no address; [to] is empty).
  final String? pairingId;

  /// Made while Epicbox was off: it waits in the outbox until Epicbox is on again.
  final bool queued;

  /// The fee the review showed, to compare with the one charged.
  final BigInt? reviewedFee;
  final bool noteSaved;

  /// The fee charged, when it differs from the one reviewed.
  BigInt? get changedFee {
    final charged = tx.fee;
    final reviewed = reviewedFee;
    if (charged == null || reviewed == null || charged == reviewed) return null;
    return charged;
  }
}

/// Whether any coins are held back from spending (confirming, coming in, newly mined or in a
/// pending send): a gate for the empty state, not a money figure to show.
BigInt _pending(WalletSummary s) =>
    s.awaitingConfirmation + s.awaitingFinalization + s.immature + s.locked;

class _SendViewState extends ConsumerState<SendView> {
  final _recipient = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _response = TextEditingController();
  final _recipientFocus = FocusNode();
  final _amountFocus = FocusNode();
  final _noteFocus = FocusNode();

  /// The [RecipientHandoff.id] this form took last.
  int? _handoff;

  SendStage _stage = SendStage.recipient;

  /// The amount field holds fiat instead of EPIC.
  bool _fiatEntry = false;
  Timer? _debounce;
  BigInt? _parsedAmount;
  String? _amountError;
  String? _recipientError;
  FeeEstimate? _estimate;
  String? _estimateError;

  /// What [_estimate] was made with: the Outputs strategy and change outputs.
  SendOptions? _options;

  /// The amount came from Max, so Continue asks for the maximum again rather than a fee.
  bool _maxUsed = false;

  /// The payment file was saved or shared: Open response file is the primary now (UP-008).
  bool _fileHandedOver = false;

  /// The options a send goes out with: those reviewed, or LEPIC's send-all after Max.
  SendOptions? get _sendOptions => _maxUsed ? null : _options;

  /// The strategy picked for this one payment under Advanced › Send options; null = the setting.
  SelectionStrategy? _strategyOverride;

  /// [planSessionSend] with the Outputs settings.
  Future<({FeeEstimate estimate, SendOptions options})> _plan(
    WalletSession session,
    BigInt amount,
    BigInt minimumConfirmations,
  ) {
    final settings = ref.read(appSettingsProvider).value;
    return planSessionSend(
      session,
      amount: amount,
      minimumConfirmations: minimumConfirmations,
      strategy:
          _strategyOverride ??
          settings?.sendStrategy ??
          SelectionStrategy.smallest,
      splitChange: settings?.splitChange ?? true,
    );
  }

  /// The note field is unfolded.
  bool _noteOpen = false;

  /// The review's checks, kept from the tap on Continue until the review is left, so they
  /// run beside the fee estimate and each review asks the node again.
  ProviderSubscription<SendPreflight>? _checks;

  /// The send itself failed at their relay. LEPIC stored the payment with its coins on hold,
  /// so the review never sends again: it offers to cancel that payment ([_undelivered]) and
  /// pay by file, or says it could not find it.
  bool _sendFailed = false;

  /// The payment a failed send left behind, when it was found.
  TxEntry? _undelivered;

  /// The failed send changed neither the balance nor the payments: nothing is held, so a
  /// payment file cannot pay twice.
  bool _nothingStored = false;

  /// Cancelling [_undelivered] failed and it did not go ahead either: only Done is left.
  bool _cancelFailed = false;

  /// The recipient is an onion address: the payment goes over Tor.
  bool get _overTor =>
      parseRecipient(_recipient.text).kind == RecipientKind.tor;

  /// The recipient is a wallet URL: the payment goes straight to it over HTTP.
  bool get _overHttp =>
      parseRecipient(_recipient.text).kind == RecipientKind.http;

  /// The method the selector shows for the address way. File and QR are their own route
  /// ([SendStage.fileAmount] and after), so this is never [TransferMethod.file] or
  /// [TransferMethod.qr].
  TransferMethod _method = TransferMethod.epicbox;

  /// The file route is the QR way: the payment is shown as an animated code to the phone next
  /// to this one, and the reply is scanned.
  bool _viaQr = false;

  /// The To text at the last change, to tell a paste (8 or more characters at once).
  String _lastTo = '';

  /// The method the address moved the selector to, and whether its tag still shows.
  TransferMethod? _switchedTo;
  bool _tagOn = false;
  Timer? _tagTimer;

  /// The user agreed to send over plain HTTP to another device, for this recipient.

  /// Send's consent or PIN dialog is open.
  bool _asking = false;

  /// A recipient handed over while the tracker or a file screen shows, for the next form.
  String? _laterRecipient;

  /// Where [_laterRecipient] came from (a scan or link), for the next form's review.
  CodeOrigin? _laterOrigin;

  /// A payment code handed over meanwhile, for the next form.
  ({PaymentRequest request, CodeOrigin origin})? _laterRequest;

  /// The payment code that filled this form, and where it came from. Its note and name are
  /// the payee's claims; they show only while the To field still holds the code's address.
  PaymentRequest? _request;
  CodeOrigin? _origin;

  /// The code's banner is open; × closes it for this code.
  bool _requestBanner = false;

  /// [_request] while the To field still holds its address, else null.
  PaymentRequest? get _activeRequest {
    final request = _request;
    if (request == null) return null;
    return parseRecipient(_recipient.text).address == _requestAddress
        ? request
        : null;
  }

  /// The address the code filled in (the code's own, or its Direct one), or a scanned, pasted
  /// or linked address alone; [_origin] says where from while the To field still holds it.
  String? _requestAddress;

  /// Where the address in the To field came from, while it is still that address.
  CodeOrigin? get _activeOrigin =>
      _requestAddress != null &&
          parseRecipient(_recipient.text).address == _requestAddress
      ? _origin
      : null;

  /// The To field moved off the code's address: the code's amount and note go too, unless
  /// the user changed them, and so do its banner and payee block.
  void _leaveRequest() {
    final address = _requestAddress;
    if (address == null ||
        parseRecipient(_recipient.text).address == address) {
      return;
    }
    final request = _request;
    if (request != null) {
      final amount = request.amount;
      if (amount != null && _parsedAmount == amount && !_fiatEntry) {
        _amount.clear();
        _parsedAmount = null;
        _estimate = null;
      }
      if (request.note != null && _note.text == request.note) _note.clear();
    }
    _request = null;
    _origin = null;
    _requestAddress = null;
    _requestBanner = false;
  }

  Slate? _slate;
  _Sent? _sent;

  /// A file payment finished from a pasted reply.
  TxEntry? _filePosted;
  String? _error;
  bool _busy = false;

  /// Continue on the amount is asking the wallet for the fee; its button shows a spinner.
  bool _estimating = false;

  @override
  void initState() {
    super.initState();
    _recipientFocus.addListener(_recipientFocusChanged);
    final handoff = ref.read(sendRecipientProvider);
    if (handoff != null && handoff.pairingId != null) {
      _handoff = handoff.id;
      _pairingTo = handoff.pairingId;
    } else if (handoff != null) {
      _handoff = handoff.id;
      final request = handoff.request;
      final to = parseRecipient(
        request == null
            ? handoff.text
            : _requestRecipient(request).address,
      );
      _recipient.text = to.address;
      _lastTo = to.address;
      if (recipientShaped(to)) _method = methodForRecipient(to.kind);
      if (request != null) {
        // The amount is written in the user's number format, which needs the locale.
        final origin = handoff.origin ?? CodeOrigin.qr;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _applyRequest(request, origin);
        });
      } else {
        _origin = handoff.origin;
        _requestAddress = handoff.origin == null ? null : to.address;
      }
    }
    ref.listenManual(
      appSettingsProvider.select((s) => s.value?.payments),
      (_, payments) => _paymentsChanged(payments),
    );
    // Settings › Transactions: the method Send starts on. A recipient handed over wins; the
    // settings load on their own, so a form still untouched takes them when they arrive.
    if (handoff == null || (handoff.pairingId == null && !recipientShaped(parseRecipient(handoff.text)))) {
      _startOn(ref.read(appSettingsProvider).value?.payments.startMethod);
      if (!_startApplied) {
        ref.listenManual(
          appSettingsProvider.select((s) => s.value?.payments.startMethod),
          (_, start) {
            if (start == null || _startApplied || !mounted) return;
            if (_stage != SendStage.recipient ||
                _recipient.text.isNotEmpty ||
                _pairingTo != null ||
                _method != TransferMethod.epicbox) {
              return;
            }
            setState(() => _startOn(start));
          },
        );
      }
    }
  }

  bool _startApplied = false;

  /// A method switched off in Settings › Transactions while Send is open: an idle form moves to
  /// the method Send starts on now, as after a restart. An address in To keeps its method,
  /// with the note that it is off.
  void _paymentsChanged(PaymentPrefs? payments) {
    if (payments == null || !mounted || _holdsPayment || _formOffered(payments)) return;
    setState(() {
      _stage = SendStage.recipient;
      _viaQr = false;
      _method = TransferMethod.epicbox;
      _error = null;
      _startOn(payments.startMethod);
    });
  }

  /// Whether the method the idle form shows is still on in [payments].
  bool _formOffered(PaymentPrefs payments) {
    if (_stage == SendStage.fileAmount) {
      return payments.offers(_viaQr ? MethodKind.directQr : MethodKind.directFile);
    }
    if (_stage != SendStage.recipient) return true;
    if (_pairingTo != null || recipientShaped(parseRecipient(_recipient.text))) return true;
    return switch (_method) {
      TransferMethod.epicbox => payments.epicbox,
      // Link is always listed: with its switches off it stays, with the note and Turn on.
      _ => true,
    };
  }

  /// Opens the form on [start], the method Settings › Transactions chose (null: not loaded).
  void _startOn(MethodKind? start) {
    if (start == null) return;
    _startApplied = true;
    switch (start) {
      case MethodKind.linkHttp || MethodKind.linkTor:
        _method = TransferMethod.direct;
      case MethodKind.directFile:
        _stage = SendStage.fileAmount;
      case MethodKind.directQr:
        _stage = SendStage.fileAmount;
        _viaQr = true;
      case MethodKind.epicbox:
        break;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tagTimer?.cancel();
    _checks?.close();
    _recipient.dispose();
    _amount.dispose();
    _note.dispose();
    _response.dispose();
    _recipientFocus.dispose();
    _amountFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  double? get _price => ref.read(priceProvider).value;

  String get _currency =>
      ref.read(appSettingsProvider).value?.fiatCurrency ?? 'usd';

  String get _noteText => _note.text.trim();

  // Recipient.

  /// What is wrong with [text] as a recipient, in one short line, or null. Empty text is
  /// only a problem with [required], when the user tries to go on.
  String? _recipientProblem(String text, {bool required = false}) {
    final l = context.l10n;
    // A pairing recipient has no address to check: its card says whether it can be paid.
    if (_pairingTo != null) return null;
    if (text.trim().isEmpty) return required ? l.sendAddressMissing : null;
    final to = parseRecipient(text);
    // A whole address of another kind has moved the method already; text that does not fit
    // the method chosen by hand gets that method's own sentence.
    if (_method == TransferMethod.direct && to.kind == RecipientKind.epicbox) {
      return torBuilt ? l.sendDirectAddressShape : l.sendDirectAddressShapeNoTor;
    }
    if (to.kind == RecipientKind.http) {
      return httpAddressComplete(to.address)
          ? null
          : l.contactsUrlIncomplete(sendHttpShape);
    }
    if (to.kind == RecipientKind.tor && !torBuilt) return l.sendTorNotInVersion;
    if (to.kind == RecipientKind.tor &&
        ref.read(phoneTorProvider).phase == PhoneTorPhase.unavailable) {
      return l.sendTorUnavailable;
    }
    final problem = checkRecipient(l, ref.read(walletServiceProvider), text);
    if (problem == null) return null;
    // An onion with a typo: the check's own sentence says so.
    if (to.kind == RecipientKind.tor) return problem;
    final at = to.address.indexOf('@');
    final key = at < 0 ? to.address : to.address.substring(0, at);
    final looksLikeKey = RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$').hasMatch(key);
    return looksLikeKey && (key.length < 52 || at < 0)
        ? l.sendAddressIncomplete
        : l.sendAddressNotEpic;
  }

  void _recipientFocusChanged() {
    if (_recipientFocus.hasFocus || _stage != SendStage.recipient) return;
    setState(() => _recipientError = _recipientProblem(_recipient.text));
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    _openText(text, CodeOrigin.paste);
  }

  /// A scanned or pasted text: a payment code fills the form, an address the To field, and
  /// anything the router knows elsewhere goes there. Plain text that is none of these (a name,
  /// half an address) lands in the To field as before, where its own check speaks.
  /// [typedOver] is the To text before the code was typed or pasted into the field: a code
  /// that opens a sheet puts it back, so the field never keeps the code behind the sheet.
  void _openText(String text, CodeOrigin origin, {String? typedOver}) {
    final l = context.l10n;
    final code = classifyFor(ref.read(walletServiceProvider), text);
    switch (code) {
      case PaymentRequest() when requestCarriesMore(code):
        _applyRequest(code, origin);
      case PaymentRequest(:final recipient) || ScannedAddress(:final recipient):
        // A code with a second address fills the one whose method is on.
        final to = code is PaymentRequest ? _requestRecipient(code) : recipient;
        _setRecipient(to.address, origin: origin);
      case UnknownCode(reason: UnknownReason.notEpic)
          when origin == CodeOrigin.paste && !looksLikeCode(text):
        _setRecipient(text);
      // A pasted code that is no payment: the text stays in the field, to be read and edited.
      case WrongNetwork() when origin == CodeOrigin.paste:
        _pastedWithError(text, l.scanWrongNetworkBody);
      case UnknownCode(:final reason)
          when origin == CodeOrigin.paste:
        _pastedWithError(
          text,
          reason == UnknownReason.badAddress
              ? l.scanBadAddress
              : l.scanNotEpicBody,
        );
      default:
        if (typedOver != null) {
          setState(() {
            _recipient.text = typedOver;
            _lastTo = typedOver;
            _recipientError = null;
          });
        }
        unawaited(
          openScannedCode(
            context,
            ref,
            code,
            origin: origin,
            scanAgain: origin == CodeOrigin.qr ? _scan : null,
          ),
        );
    }
  }

  /// Puts a pasted [text] that cannot be paid in the To field, with [problem] under it.
  void _pastedWithError(String text, String problem) {
    _setRecipient(text);
    setState(() => _recipientError = problem);
  }

  /// Whether the wallet can pay [to] as it is: the checksum, chain and host hold.
  bool _complete(Recipient to) {
    final service = ref.read(walletServiceProvider);
    return switch (to.kind) {
      RecipientKind.epicbox => service.validateEpicboxAddress(
        address: to.address,
      ),
      RecipientKind.tor => service.validateOnionAddress(address: to.address),
      RecipientKind.http => httpAddressComplete(to.address),
    };
  }

  /// The connection the To text takes, for the Tor switch: Epicbox's whatever is typed, and
  /// on Direct the address's own once it has a shape; null before that.
  TorRoute? get _toRoute {
    if (_method == TransferMethod.epicbox) return TorRoute.epicbox;
    final to = parseRecipient(_recipient.text);
    if (to.kind == RecipientKind.epicbox || !recipientShaped(to)) return null;
    return sendRoute(to);
  }

  /// The Tor switch's state, watched: for build only.
  TorState get _torState => phoneTorState(ref.watch(phoneTorProvider));

  /// How [route] goes with the Tor switch at [state] (now, watched, by default); clearnet for
  /// no route.
  TorWay _wayOf(TorRoute? route, [TorState? state]) =>
      route == null ? TorWay.clearnet : torWay(route, state ?? _torState);

  /// The code's name and note, unverified, after a [gapBefore] gap; nothing without a code.
  /// The name is left out when a saved contact for the address has that name already.
  List<Widget> _payeeClaims({required double gapBefore}) {
    final request = _activeRequest;
    if (request == null || (request.label == null && request.note == null)) {
      return const [];
    }
    final contact = _contactName(parseRecipient(_recipient.text).address);
    final label = request.label;
    final sameName =
        label != null &&
        contact != null &&
        contact.trim().toLowerCase() == label.trim().toLowerCase();
    return [
      SizedBox(height: gapBefore),
      PayeeClaims(name: sameName ? null : label, note: request.note),
    ];
  }

  /// The method follows the address: a whole address of another kind, or
  /// any address that was pasted, scanned or picked ([forced], or one change adding 8 or more
  /// characters), moves it to that kind, with a tag for 3 s. Text still being typed never
  /// does, nothing switches back when the text becomes incomplete, and the field keeps its
  /// text. Call inside setState.
  void _followAddress(String text, {bool forced = false}) {
    final added = text.length - _lastTo.length;
    _lastTo = text;
    final to = parseRecipient(text);
    if (!recipientShaped(to)) return;
    final method = methodForRecipient(to.kind);
    if (method == _method) return;
    if (!(forced || added >= 8 || _complete(to))) return;
    _method = method;
    _switchedTo = method;
    _tagOn = true;
    _tagTimer?.cancel();
    _tagTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _tagOn = false);
      // Once faded out it leaves the label, or the outline's notch keeps its width (android-08).
      _tagTimer = Timer(_switchTagFade, () {
        if (mounted && !_tagOn) setState(() => _switchedTo = null);
      });
    });
  }

  /// The selector: an address method keeps the To text; File opens the file route.
  void _chooseMethod(TransferMethod method) {
    if (_busy || _estimating) return;
    if (method == TransferMethod.file || method == TransferMethod.qr) {
      _toFileRoute(qr: method == TransferMethod.qr);
      return;
    }
    _tagTimer?.cancel();
    setState(() {
      _method = method;
      _viaQr = false;
      _tagOn = false;
      _stage = SendStage.recipient;
      _error = null;
      _recipientError = _recipient.text.trim().isEmpty
          ? null
          : _recipientProblem(_recipient.text);
    });
  }

  Future<void> _scan() async {
    final text = await ref.read(qrScannerProvider).scan(context);
    if (text != null && mounted) _openText(text, CodeOrigin.qr);
  }

  PaymentPrefs get _payments => sendPayments(ref);

  /// The address a payment code fills in, picked by which methods are on
  /// ([PaymentRequest.recipientFor]).
  Recipient _requestRecipient(PaymentRequest request) =>
      request.recipientFor(_payments.offers);

  /// Fills the form from a payment code: the address, the amount and the note. Nothing is
  /// sent; every field stays editable and the review and PIN still come first.
  void _applyRequest(PaymentRequest request, CodeOrigin origin) {
    if (_holdsPayment) {
      _laterRequest = (request: request, origin: origin);
      _laterRecipient = null;
      _laterPairing = null;
      return;
    }
    if (_stage == SendStage.fileAmount) {
      _viaQr = false;
      _stage = SendStage.recipient;
    }
    _setRecipient(_requestRecipient(request).address);
    setState(() => _fillFromRequest(request, origin));
    if (_amount.text.isNotEmpty) _onAmountChanged(_amount.text);
    // The router checked the address; the amount is the one thing left to check. After the
    // next build, which works out what the network mode allows for the method the code set.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _request != request) return;
      if (_stage == SendStage.recipient &&
          _recipientError == null &&
          _block == NetBlock.none) {
        _toAmount(focus: false);
      }
    });
  }

  /// A payment is under way or held here: a send runs, waits for its tracker or a file, or
  /// a refused send keeps its payment. A new recipient waits for the next form.
  bool get _holdsPayment =>
      _busy ||
      _stage == SendStage.sent ||
      _stage == SendStage.fileMade ||
      _stage == SendStage.fileSent ||
      _sendFailed;

  /// The amount and note fields from [request]. Call inside setState or initState.
  void _fillFromRequest(PaymentRequest request, CodeOrigin? origin) {
    final previousNote = _request?.note;
    if (previousNote != null && _note.text == previousNote) _note.clear();
    _request = request;
    _origin = origin;
    _requestAddress = parseRecipient(_requestRecipient(request).address).address;
    _requestBanner = true;
    _fiatEntry = false;
    _maxUsed = false;
    final amount = request.amount;
    _amount.text = amount == null
        ? ''
        : localDecimal(context.l10n, formatEpic(amount));
    _parsedAmount = amount;
    _amountError = null;
    _estimate = null;
    final note = request.note;
    // The note travels in the payment, signed, up to its byte limit; a longer one shows only
    // in the payee block, never cut. Prefilled, its tile stays folded and shows it.
    if (note != null && utf8Length(note) <= slateMessageMaxBytes) {
      _note.text = note;
    }
  }

  Future<void> _pickContact() async {
    final contact = await Navigator.of(context).push<Contact>(
      MaterialPageRoute<Contact>(
        builder: (_) => const ContactsScreen(pick: true),
      ),
    );
    if (contact == null || !mounted) return;
    _useContact(contact);
  }

  /// The pairing a contact with no address is paid through, when the wallet pairs.
  PairingRecord? _pairingOnly(Contact contact, {bool watch = false}) {
    if (contact.addresses.isNotEmpty) return null;
    if (!(watch ? ref.watch(pairingSupportedProvider) : ref.read(pairingSupportedProvider))) return null;
    return watch ? ref.watch(contactPairingProvider(contact.id)) : ref.read(contactPairingProvider(contact.id));
  }

  /// [contact] as the recipient: its address whose method is on, or its pairing.
  void _useContact(Contact contact) {
    if (_pairingOnly(contact) case final pairing?) {
      _setPairing(pairing.id);
      return;
    }
    _setRecipient(contactSendAddress(contact, _payments.offers));
  }

  /// The recipient is the pairing [id], a contact with no address: its card takes the To
  /// field's place and the payment goes through its mailbox. Over a payment in progress, the
  /// next form takes it.
  void _setPairing(String id) {
    if (_holdsPayment) {
      _laterPairing = id;
      _laterRecipient = null;
      _laterRequest = null;
      return;
    }
    _closeChecks();
    _tagTimer?.cancel();
    setState(() {
      _recipient.clear();
      _lastTo = '';
      _leaveRequest();
      _pairingTo = id;
      _viaMailbox = false;
      _method = TransferMethod.epicbox;
      _viaQr = false;
      _switchedTo = null;
      _tagOn = false;
      // Not held (above): the amount, the review or the file route go back to the recipient.
      _stage = SendStage.recipient;
      _recipientError = null;
      _error = null;
    });
  }

  /// × on the filled To field or on the pairing card. Leaving Send keeps the draft (people
  /// switch tabs to check the balance), so a filled recipient always has this way out: the
  /// recipient goes with everything that followed from it (the method it moved, a code's
  /// untouched amount and note, the warnings), back to step 1's empty start. Amount and note
  /// typed by hand stay.
  void _clearRecipient() {
    _closeChecks();
    _tagTimer?.cancel();
    setState(() {
      _recipient.clear();
      _lastTo = '';
      _leaveRequest();
      _pairingTo = null;
      _viaMailbox = false;
      _switchedTo = null;
      _tagOn = false;
      _recipientError = null;
      _error = null;
      _viaQr = false;
      _stage = SendStage.recipient;
      _method = TransferMethod.epicbox;
      _startOn(_payments.startMethod);
    });
  }

  /// Fills the recipient and checks it at once, as after a paste.
  void _setRecipient(String text, {CodeOrigin? origin}) {
    if (_holdsPayment) {
      // Not over a payment in progress, or one a refused send holds: the next form takes
      // it, so Send again cannot make a second payment meanwhile.
      _laterRecipient = text;
      _laterOrigin = origin;
      _laterRequest = null;
      _laterPairing = null;
      return;
    }
    _pairingTo = null;
    _recipient.text = parseRecipient(text).address;
    if (_stage == SendStage.amount || _stage == SendStage.review) {
      _closeChecks();
      _stage = SendStage.recipient;
    }
    setState(() {
      _leaveRequest();
      if (origin != null) {
        _origin = origin;
        _requestAddress = _recipient.text;
      }
      _followAddress(_recipient.text, forced: true);
      _recipientError = _recipientProblem(_recipient.text);
      _error = null;
    });
  }

  void _saveContact(String address) => Navigator.of(context).push<Contact>(
    MaterialPageRoute<Contact>(
      builder: (_) => ContactEditScreen(address: address),
    ),
  );

  /// On to the amount; [focus] puts the cursor there (not for a code, whose amount is read
  /// first, with the keyboard down).
  void _toAmount({bool focus = true}) {
    final problem = _recipientProblem(_recipient.text, required: true);
    setState(() {
      _recipientError = problem;
      _error = null;
      if (problem == null) _stage = SendStage.amount;
    });
    if (problem == null && focus) _amountFocus.requestFocus();
  }

  void _toRecipient() {
    _closeChecks();
    setState(() {
      _stage = SendStage.recipient;
      _error = null;
    });
  }

  /// The file route, from the recipient step or from a relay that does not answer. The
  /// amount and the note stay.
  void _toFileRoute({bool qr = false}) {
    _closeChecks();
    setState(() {
      _viaQr = qr;
      _filePlain = false;
      _stage = SendStage.fileAmount;
      _error = null;
      _sendFailed = false;
      _undelivered = null;
      _nothingStored = false;
      _cancelFailed = false;
    });
  }

  // Amount.

  /// Parses the amount field in the current unit into atomic EPIC.
  BigInt _parseAmount(String text) {
    final clean = normalizeAmountText(
      text,
      unit: _fiatEntry ? _currency : 'epic',
      groupSeparator: NumberFormat.decimalPattern(context.l10n.localeName)
          .symbols
          .GROUP_SEP,
    );
    final BigInt amount;
    if (_fiatEntry) {
      final price = _price;
      if (price == null || price <= 0) {
        throw LocalizedFormatException((l) => l.sendAmountNoPrice, text);
      }
      amount = fiatToAtomic(clean, price, text);
    } else {
      amount = parseEpic(clean);
    }
    return amount;
  }

  void _onAmountChanged(String text) {
    _debounce?.cancel();
    _maxUsed = false;
    final l = context.l10n;
    BigInt? amount;
    String? problem;
    if (text.trim().isNotEmpty) {
      try {
        amount = _parseAmount(text);
        if (amount == BigInt.zero) problem = l.sendAmountZero;
      } on FormatException catch (e) {
        problem = describeError(l, e);
      }
    }
    setState(() {
      _parsedAmount = problem == null ? amount : null;
      _amountError = problem;
      _estimate = null;
      _estimateError = null;
      _error = null;
    });
    final valid = _parsedAmount;
    if (valid != null) {
      _debounce = Timer(
        const Duration(milliseconds: 400),
        () => _estimateFee(valid),
      );
    }
  }

  Future<FeeEstimate?> _estimateFee(BigInt amount) async {
    final session = ref.read(sessionProvider);
    if (session == null) return null;
    try {
      final plan = await _plan(
        session,
        amount,
        ref.read(countedConfirmationsProvider),
      );
      if (mounted && _parsedAmount == amount) {
        setState(() {
          _estimate = plan.estimate;
          _options = plan.options;
        });
      }
      return plan.estimate;
    } catch (error) {
      if (mounted && _parsedAmount == amount) {
        setState(() => _estimateError = describeError(context.l10n, error));
      }
      return null;
    }
  }

  void _chooseStrategy(SelectionStrategy strategy) {
    setState(() => _strategyOverride = strategy);
    final amount = _parsedAmount;
    if (amount != null && !_maxUsed) _estimateFee(amount);
  }

  /// Smallest / All for this payment; only with Send options on.
  Widget _strategyPicker(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final current =
        _strategyOverride ??
        ref.watch(appSettingsProvider).value?.sendStrategy ??
        SelectionStrategy.smallest;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Named, so All never reads as "send all".
          Text(
            l.deskSendAdvStrategy,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.dim),
          ),
          const SizedBox(height: 6),
          Semantics(
            label: l.deskSendAdvStrategy,
            container: true,
            child: SegmentedButton<SelectionStrategy>(
              key: sendStrategyKey,
              segments: [
                ButtonSegment(
                  value: SelectionStrategy.smallest,
                  label: Text(l.outputsSmallest),
                ),
                ButtonSegment(
                  value: SelectionStrategy.all,
                  label: Text(l.outputsAll),
                ),
              ],
              selected: {current},
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(Size(0, 44)),
              ),
              onSelectionChanged: (chosen) => _chooseStrategy(chosen.first),
            ),
          ),
        ],
      ),
    );
  }

  /// Switches the amount field between EPIC and fiat, keeping the amount.
  void _toggleUnit() {
    final price = _price;
    final amount = _parsedAmount;
    if (price == null) {
      // The price went away while entering fiat: start over in EPIC.
      _amount.clear();
      setState(() => _fiatEntry = false);
      _onAmountChanged('');
      return;
    }
    setState(() => _fiatEntry = !_fiatEntry);
    if (amount == null) {
      _onAmountChanged(_amount.text);
      return;
    }
    // Only the text changes. The exact amount (from Max, say) stays until the user edits the
    // field; re-reading the rounded fiat text would change it.
    _amount.text = localDecimal(
      context.l10n,
      _fiatEntry
          ? (amount / atomicPerEpic * price).toStringAsFixed(2)
          : formatEpic(amount),
    );
  }

  /// Fills in the largest amount that can be sent now, with its fee.
  Future<void> _max() async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    _debounce?.cancel();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final estimate = await session.estimateMax(
        minimumConfirmations: ref.read(countedConfirmationsProvider),
      );
      if (!mounted) return;
      _amount.text = localDecimal(context.l10n, formatEpic(estimate.amount));
      setState(() {
        _fiatEntry = false;
        _maxUsed = true;
        _parsedAmount = estimate.amount;
        _amountError = null;
        _estimate = estimate;
        _estimateError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _estimateError = describeError(context.l10n, error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _amountReady =>
      _parsedAmount != null && _estimateError == null && !_estimating;

  // Review.

  void _closeChecks() {
    _checks?.close();
    _checks = null;
  }

  /// The recipient's relay for the review's check; none for a pairing recipient, whose
  /// mailbox payment LEPIC holds in its outbox until the relay takes it.
  EpicboxRelay? get _relay => _pairingTo != null
      ? null
      : recipientRelay(parseRecipient(_recipient.text).address);

  /// Asks the wallet for the fee again (outputs may have changed since the last estimate)
  /// while [sendPreflightProvider] checks the node and epicbox, then shows the review.
  Future<void> _toReview() async {
    if (_estimating || _busy) return;
    final session = ref.read(sessionProvider);
    final amount = _parsedAmount;
    if (session == null || amount == null) return;
    final problem = _recipientProblem(_recipient.text, required: true);
    if (problem != null) {
      setState(() {
        _recipientError = problem;
        _stage = SendStage.recipient;
      });
      return;
    }
    _closeChecks();
    _checks = ref.listenManual(sendPreflightProvider(_relay), (_, _) {});
    setState(() {
      _estimating = true;
      _error = null;
      _sendFailed = false;
      _undelivered = null;
      _nothingStored = false;
      _cancelFailed = false;
    });
    try {
      final minimum = ref.read(countedConfirmationsProvider);
      final plan = _maxUsed
          ? (
              estimate: await session.estimateMax(minimumConfirmations: minimum),
              options: null,
            )
          : await _plan(session, amount, minimum);
      final estimate = plan.estimate;
      if (!mounted) return;
      setState(() {
        _estimate = estimate;
        _options = plan.options;
        _estimateError = null;
        if (_maxUsed && estimate.amount != amount) {
          _parsedAmount = estimate.amount;
          if (!_fiatEntry) {
            _amount.text = localDecimal(
              context.l10n,
              formatEpic(estimate.amount),
            );
          }
        }
        _stage = SendStage.review;
      });
    } catch (error) {
      _closeChecks();
      if (mounted) {
        setState(() => _estimateError = describeError(context.l10n, error));
      }
    } finally {
      if (mounted) setState(() => _estimating = false);
    }
  }

  void _backToAmount() {
    _closeChecks();
    setState(() {
      _stage = SendStage.amount;
      _error = null;
      _sendFailed = false;
      _undelivered = null;
      _nothingStored = false;
      _cancelFailed = false;
    });
  }

  /// Runs one wallet action at a time; a second tap while one runs does nothing.
  /// "x EPIC is held by a payment Desktop is making.", one line per device holding coins here.
  List<Widget> _heldLines(BuildContext context) {
    final l = context.l10n;
    final view = ref.watch(phoneDevices.view);
    if (view == null || view.held.isEmpty) return const [];
    final outputs = ref.watch(walletOutputsProvider).value ?? const <WalletOutput>[];
    return [
      for (final e in heldValueByDevice(view.book, outputs).entries)
        if (e.value > BigInt.zero)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l.sendHeldByDevice(localDecimal(l, formatEpic(e.value)), view.nameOf(e.key)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.tokens.dim),
            ),
          ),
    ];
  }

  Future<void> _run(Future<void> Function(WalletSession session) action) async {
    if (_busy) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    // Linked devices: one read (at most 3 s) so coins another device just took stay out, and
    // after the send the others hear at once.
    final devices = ref.read(deviceServiceProvider);
    try {
      await devices?.beforeSend();
      await action(session);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(context.l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
      unawaited(devices?.announceNow());
    }
  }

  /// Every send asks the PIN right before money moves (the desktop asks the password). True
  /// once it checked out; false when the user cancelled or the wallet is gone.
  Future<bool> _pinGate(String reason) async {
    final session = ref.read(sessionProvider);
    final config = ref.read(walletConfigProvider);
    if (session == null || config == null) return false;
    final vault = ref.read(vaultProvider);
    final ok = await askPin<bool>(
      context,
      reason: reason,
      action: (pin) async {
        await vault.checkPin(session, config, pin);
        return true;
      },
    );
    return ok == true && mounted;
  }

  /// Sends the reviewed payment. A payment link that comes meanwhile is dropped, so it cannot
  /// change what the user is confirming.
  Future<void> _send() async {
    // A second tap while the first one's dialogs show: that send holds the flag.
    if (_asking) return;
    final busy = ref.read(linkBusyProvider.notifier);
    busy.set(true);
    try {
      await _sendReviewed();
    } finally {
      busy.set(false);
    }
  }

  Future<void> _sendReviewed() async {
    final reviewed = _estimate;
    // A second tap can land on the old button after the first send already finished.
    if (reviewed == null || _stage != SendStage.review) return;
    // A second tap while the first one's dialogs show opens no second set.
    if (_asking) return;
    final l = context.l10n;
    final to = parseRecipient(_recipient.text);
    _asking = true;
    try {
      final amountText = epicText(l, reviewed.amount);
      if (!await _pinGate(usesPassphrase(ref) ? l.sendPassphraseReason(amountText) : l.sendPinReason(amountText))) {
        return;
      }
    } finally {
      _asking = false;
    }
    if (!mounted || _stage != SendStage.review || _busy) return;
    if (to.kind == RecipientKind.tor) return _sendTor(reviewed, to);
    if (to.kind == RecipientKind.http) return _sendHttp(reviewed, to);
    // Captured now: after the await the screen may be gone, and home must still refresh.
    final container = ProviderScope.containerOf(context, listen: false);
    // A slow send must not lock the wallet under the user and lose the tracker.
    final hold = ref.read(autoLockHoldProvider.notifier);
    final amount = reviewed.amount;
    final options = _sendOptions;
    final note = _noteText;
    // Through the paired contact's mailbox, sealed (RFC 9.1): a contact with no address, or
    // one whose switch the user turned on. Read now: the screen may be gone after the await.
    final pairingTo = _pairingTo;
    final mailbox = pairingTo != null
        ? _toPairing(watch: false)
        : (_viaMailbox ? sendPairingFor(ref, to.address, watch: false) : null);
    if (pairingTo != null && mailbox == null) return;
    final pairingApi = ref.read(pairingApiProvider);
    final queued = _queues(watch: false);
    final minimum = ref.read(countedConfirmationsProvider);
    return _run((session) async {
      // What the wallet held before, to tell the payment a failed send leaves behind.
      final before = await SendBefore.take(
        session,
        minimumConfirmations: minimum,
      );
      final TxEntry tx;
      try {
        tx = await hold.during(
          () => mailbox != null
              ? pairingApi.sendViaMailbox(
                  id: mailbox.id,
                  amount: amount,
                  minimumConfirmations: minimum,
                  message: note.isEmpty ? null : note,
                  options: options,
                )
              : session.sendEpicbox(
                  amount: amount,
                  minimumConfirmations: minimum,
                  address: to.address,
                  message: note.isEmpty ? null : note,
                  options: options,
                ),
        );
      } on WalletError catch (error) {
        if (error.kind != WalletErrorKind.transportFailed) rethrow;
        logWarn(
          'send',
          'the relay did not take it: ${describeError(englishStrings, error)}',
        );
        // LEPIC stores the payment and holds its coins before the relay refuses it.
        container.invalidate(homeProvider);
        final left = await before.leftBehind(
          to: to.address,
          amount: amount,
          match: SentToMatch.exact,
          minimumConfirmations: minimum,
        );
        if (mounted) {
          setState(() {
            _sendFailed = true;
            _undelivered = left.payment;
            _nothingStored = left.nothingStored;
          });
        }
        return;
      }
      // The payment is out; a note that fails to save must not look like a failed send.
      var noteSaved = true;
      if (note.isNotEmpty) {
        try {
          await session.setTxNote(key: tx.key, note: note);
        } catch (error) {
          logWarn(
            'send',
            'saving the note failed: ${describeError(englishStrings, error)}',
          );
          noteSaved = false;
        }
      }
      container.invalidate(homeProvider);
      container.read(trackedSendProvider.notifier).track(tx.key);
      if (mounted) {
        _closeChecks();
        setState(() {
          _sent = _Sent(
            tx: tx,
            amount: amount,
            to: to,
            reviewedFee: reviewed.fee,
            noteSaved: noteSaved,
            pairingId: pairingTo,
            queued: queued,
          );
          _stage = SendStage.sent;
        });
      }
    });
  }

  /// A payment straight to a wallet URL over HTTP. Reaching it is the whole exchange, as over
  /// Tor, so a success lands on the tracker past "signed". When LEPIC stored the payment
  /// before the failure (their wallet did not answer or refused), it waits with its coins on
  /// hold: the review offers Try again ([_resendDirect]) and Cancel payment. A failure that
  /// stored nothing (a bad address) shows in words.
  Future<void> _sendHttp(FeeEstimate reviewed, Recipient to) {
    final container = ProviderScope.containerOf(context, listen: false);
    final hold = ref.read(autoLockHoldProvider.notifier);
    final amount = reviewed.amount;
    final options = _sendOptions;
    final note = _noteText;
    final minimum = ref.read(countedConfirmationsProvider);
    return _run((session) async {
      final before = await SendBefore.take(session);
      final HttpSent sent;
      try {
        sent = await hold.during(
          () => session.sendHttp(
            amount: amount,
            minimumConfirmations: minimum,
            url: to.address,
            allowPlainHttp: plainHttpToOtherDevice(to.address),
            message: note.isEmpty ? null : note,
            options: options,
          ),
        );
      } on WalletError catch (error) {
        container.invalidate(homeProvider);
        final stuck = (await before.leftBehind(
          to: to.address,
          amount: amount,
          match: SentToMatch.host,
        )).payment;
        if (stuck == null) rethrow;
        logWarn(
          'send',
          'not delivered over HTTP: ${describeError(englishStrings, error)}',
        );
        if (note.isNotEmpty) {
          try {
            await session.setTxNote(key: stuck.key, note: note);
          } catch (error) {
            logWarn(
              'send',
              'saving the note failed: ${describeError(englishStrings, error)}',
            );
          }
        }
        if (mounted) {
          setState(() {
            _sendFailed = true;
            _undelivered = stuck;
            _nothingStored = false;
          });
        }
        return;
      }
      await _directSent(
        session,
        container,
        slateId: sent.slateId,
        amount: amount,
        to: to,
        reviewedFee: reviewed.fee,
        note: note,
      );
    });
  }

  /// Failures that leave a Tor send stored and waiting (LEPIC): the review offers Try again
  /// and Cancel payment. Before anything was sent, `torNotRunning` stores nothing.
  static bool _torStores(WalletErrorKind kind) => const {
    WalletErrorKind.torNotRunning,
    WalletErrorKind.onionUnreachable,
    WalletErrorKind.transportFailed,
  }.contains(kind);

  /// A payment over Tor: tor starts if it is off (the review shows it connecting), then the
  /// other wallet is reached, which can take a while. Reaching it is the whole exchange, so
  /// a success lands on the tracker past "signed". A failure to reach it leaves the payment
  /// stored and waiting: the review offers Try again ([_resendDirect]) and Cancel payment.
  Future<void> _sendTor(FeeEstimate reviewed, Recipient to) {
    final container = ProviderScope.containerOf(context, listen: false);
    final hold = ref.read(autoLockHoldProvider.notifier);
    final tor = ref.read(phoneTorProvider.notifier);
    final amount = reviewed.amount;
    final options = _sendOptions;
    final note = _noteText;
    final minimum = ref.read(countedConfirmationsProvider);
    return _run((session) async {
      final before = await SendBefore.take(session);
      final HttpSent sent;
      try {
        sent = await hold.during(
          () => tor.whileSending(
            () => session.sendTor(
              amount: amount,
              minimumConfirmations: minimum,
              onion: to.address,
              message: note.isEmpty ? null : note,
              options: options,
            ),
          ),
        );
      } on WalletError catch (error) {
        if (!_torStores(error.kind)) rethrow;
        logWarn(
          'send',
          'not delivered over Tor: ${describeError(englishStrings, error)}',
        );
        container.invalidate(homeProvider);
        final stuck = (await before.leftBehind(
          to: to.address,
          amount: amount,
          match: SentToMatch.host,
        )).payment;
        // The note is the sender's own record; a resend sends the stored message again.
        if (stuck != null && note.isNotEmpty) {
          try {
            await session.setTxNote(key: stuck.key, note: note);
          } catch (error) {
            logWarn(
              'send',
              'saving the note failed: ${describeError(englishStrings, error)}',
            );
          }
        }
        if (mounted) {
          setState(() {
            _sendFailed = true;
            _undelivered = stuck;
            _nothingStored = stuck == null;
          });
        }
        return;
      }
      await _directSent(
        session,
        container,
        slateId: sent.slateId,
        amount: amount,
        to: to,
        reviewedFee: reviewed.fee,
        note: note,
      );
    });
  }

  /// Delivers the waiting Tor or HTTP payment [_undelivered] again.
  Future<void> _resendDirect() {
    final stuck = _undelivered;
    if (stuck == null) return Future.value();
    final to = parseRecipient(_recipient.text);
    final http = to.kind == RecipientKind.http;
    final container = ProviderScope.containerOf(context, listen: false);
    final hold = ref.read(autoLockHoldProvider.notifier);
    final tor = ref.read(phoneTorProvider.notifier);
    return _run((session) async {
      final HttpSent sent;
      try {
        sent = await hold.during(
          () => http
              ? session.resendHttp(
                  txId: stuck.id!,
                  url: to.address,
                  allowPlainHttp: plainHttpToOtherDevice(to.address),
                )
              : tor.whileSending(
                  () => session.resendTor(txId: stuck.id!, onion: to.address),
                ),
        );
      } on WalletError catch (error) {
        final stillWaiting = http
            ? error.kind == WalletErrorKind.transportFailed
            : _torStores(error.kind);
        if (!stillWaiting) rethrow;
        logWarn(
          'send',
          'not delivered ${http ? 'over HTTP' : 'over Tor'} again: '
              '${describeError(englishStrings, error)}',
        );
        // Still stored and waiting: the review keeps its offer.
        container.invalidate(homeProvider);
        return;
      }
      await _directSent(
        session,
        container,
        slateId: sent.slateId,
        amount: txAmount(stuck).amount,
        to: to,
        reviewedFee: _estimate?.fee,
        note: '',
      );
    });
  }

  /// The other wallet answered over Tor or HTTP and the payment is finalized: the tracker
  /// follows it from the wallet's own record of [slateId].
  Future<void> _directSent(
    WalletSession session,
    ProviderContainer container, {
    required String slateId,
    required BigInt amount,
    required Recipient to,
    required BigInt? reviewedFee,
    required String note,
  }) async {
    final tx = (await session.transactions(refresh: false))
        .where((t) => t.slateId == slateId)
        .firstOrNull;
    container.invalidate(homeProvider);
    if (tx == null) {
      // Sent, but not found by its id: Wallet shows it. Nothing to track from here.
      logWarn('send', 'direct send $slateId not in the wallet\'s payments');
      if (mounted) _done();
      return;
    }
    var noteSaved = true;
    if (note.isNotEmpty) {
      try {
        await session.setTxNote(key: tx.key, note: note);
      } catch (error) {
        logWarn(
          'send',
          'saving the note failed: ${describeError(englishStrings, error)}',
        );
        noteSaved = false;
      }
    }
    container.read(trackedSendProvider.notifier).track(tx.key);
    if (mounted) {
      _closeChecks();
      setState(() {
        _sent = _Sent(
          tx: tx,
          amount: amount,
          to: to,
          reviewedFee: reviewedFee,
          noteSaved: noteSaved,
        );
        _sendFailed = false;
        _undelivered = null;
        _stage = SendStage.sent;
      });
    }
  }

  /// Cancels the payment a failed send left behind, then the file route with the amount and
  /// the note. After Max the maximum is asked again, now that the coins are free.
  Future<void> _cancelAndFile() =>
      _cancelUndelivered(then: SendStage.fileAmount);

  /// Cancels the waiting Tor or HTTP payment, back to the amount with the recipient kept.
  Future<void> _cancelDirectSend() =>
      _cancelUndelivered(then: SendStage.amount);

  /// Cancels [_undelivered], then shows [then] with the amount and the note. After Max the
  /// maximum is asked again, now that the coins are free.
  Future<void> _cancelUndelivered({required SendStage then}) async {
    final stuck = _undelivered;
    final session = ref.read(sessionProvider);
    if (stuck == null || session == null || _busy) return;
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.cancelTransaction(txId: stuck.id!);
      // The linked devices free its coins at once, not at the next tick.
      unawaited(container.read(deviceServiceProvider)?.announceNow());
      container.invalidate(homeProvider);
      if (!mounted) return;
      _closeChecks();
      setState(() {
        _sendFailed = false;
        _undelivered = null;
        _stage = then;
      });
    } catch (error) {
      // Their reply may have come first: then the payment is going ahead, not held.
      container.invalidate(homeProvider);
      TxEntry? now;
      try {
        now = (await session.transactions(refresh: true))
            .where((t) => t.key == stuck.key)
            .firstOrNull;
      } catch (_) {
        // Said by the error below.
      }
      if (!mounted) return;
      final moved =
          now != null &&
          now.status != TxStatus.awaitingRecipient &&
          now.status != TxStatus.cancelled;
      if (moved) {
        container.read(trackedSendProvider.notifier).track(now.key);
        _closeChecks();
        setState(() {
          _sent = _Sent(
            tx: now!,
            amount: txAmount(now).amount,
            to: parseRecipient(_recipient.text),
            reviewedFee: _estimate?.fee,
          );
          _stage = SendStage.sent;
          _sendFailed = false;
          _undelivered = null;
        });
      } else {
        setState(() {
          _cancelFailed = true;
          _error = describeError(context.l10n, error);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted || _stage != then) return;
    final amount = _parsedAmount;
    if (_maxUsed) {
      await _max();
    } else if (amount != null) {
      setState(() {
        _estimate = null;
        _estimateError = null;
      });
      await _estimateFee(amount);
    }
  }

  // File route.

  Future<void> _createFile() async {
    final amount = _parsedAmount;
    if (amount == null) return;
    final l = context.l10n;
    final amountText = epicText(l, amount);
    final reason = switch ((_viaQr, usesPassphrase(ref))) {
      (true, true) => l.sendQrPassphraseReason(amountText),
      (true, false) => l.sendQrPinReason(amountText),
      (false, true) => l.sendFilePassphraseReason(amountText),
      (false, false) => l.sendFilePinReason(amountText),
    };
    if (!await _pinGate(reason)) return;
    if (!mounted) return;
    final container = ProviderScope.containerOf(context, listen: false);
    final options = _sendOptions;
    await _run((session) async {
      final message = _noteText;
      final slate = await session.createSendSlate(
        amount: amount,
        minimumConfirmations: ref.read(countedConfirmationsProvider),
        message: message.isEmpty ? null : message,
        options: options,
      );
      // The sender keeps the message as the private note too. The file is made, so a note
      // that fails to save only goes to the log.
      if (message.isNotEmpty) {
        try {
          await session.setTxNote(key: 's:${slate.slateId}', note: message);
        } catch (error) {
          logWarn(
            'send',
            'saving the note failed: ${describeError(englishStrings, error)}',
          );
        }
      }
      // Sealed for the paired contact (RFC 9.2): only its wallet opens the file.
      final sealFor = _filePlain ? null : _fileSealTarget(watch: false);
      final sealed = sealFor == null ? null : await session.pairing.sealSlate(id: sealFor.id, slateJson: slate.json);
      container.invalidate(homeProvider);
      if (mounted) {
        setState(() {
          _slate = slate;
          _sealedText = sealed;
          _sealedFor = sealed == null ? null : sealFor;
          _plainCopy = null;
          _stage = SendStage.fileMade;
        });
        // The QR way goes on to the code at once; the step under it waits for the reply.
        if (_viaQr) Future.microtask(() => _showQr(slate));
      }
    });
  }

  Future<void> _openReply() async {
    final slate = _slate;
    if (slate == null) return;
    final posted = await openSlateFile(
      context,
      ref,
      expectedSlateId: slate.slateId,
    );
    if (posted && mounted) setState(() => _stage = SendStage.fileSent);
  }

  Future<void> _finalizePasted() async {
    final json = _response.text.trim();
    if (json.isEmpty) {
      setState(() => _error = context.l10n.sendPasteResponseMissing);
      return;
    }
    await _finalizeText(json);
  }

  /// Shows the payment as an animated QR code. Scanning the reply from there finishes and posts
  /// the payment ([_finalizeText]); what comes back says how it went.
  Future<void> _showQr(Slate slate) async {
    final result = await showPaymentQr(
      context,
      json: slate.json,
      amount: _parsedAmount ?? BigInt.zero,
      slateId: slate.slateId,
      scanEnabled: _postBlock == NetBlock.none,
      finish: (json) => _finalizeText(json, scanned: true),
    );
    if (!mounted) return;
    if (result is QrShowOpenFile) await _openReply();
  }

  /// Reads the reply with the camera, from the step under the code.
  Future<void> _scanReply() async {
    final result = await scanQrSlate(
      context,
      QrScanKind.reply,
      finish: (json) => _finalizeText(json, scanned: true),
    );
    if (!mounted) return;
    if (result is QrScanOpenFile) await _openReply();
  }

  /// Finishes the send with the reply [json]: pasted, or read from a QR code ([scanned]). True
  /// once it is posted; the reason it is not shows under the step.
  Future<bool> _finalizeText(String json, {bool scanned = false}) async {
    final slate = _slate;
    final container = ProviderScope.containerOf(context, listen: false);
    final hold = ref.read(autoLockHoldProvider.notifier);
    final service = ref.read(walletServiceProvider);
    var posted = false;
    await _run((session) async {
      // Only the answer to this file, as opening a reply file checks.
      final SlateInfo info;
      try {
        info = await service.inspectSlate(json: json);
      } on WalletError {
        if (mounted) {
          setState(() => _error = context.l10n.slateNotTransactionFile);
        }
        return;
      }
      if (slate != null && info.slateId != slate.slateId) {
        if (mounted) {
          setState(
            () => _error = scanned
                ? context.l10n.slateWrongPaymentQr
                : context.l10n.slateWrongPayment,
          );
        }
        return;
      }
      final tx = await hold.during(
        () => session.finalizeAndPost(slateJson: json),
      );
      container.invalidate(homeProvider);
      posted = true;
      if (mounted) {
        setState(() {
          _filePosted = tx;
          _stage = SendStage.fileSent;
        });
      }
    });
    return posted;
  }

  void _done() {
    ref.read(trackedSendProvider.notifier).track(null);
    final later = _laterRecipient;
    final laterOrigin = _laterOrigin;
    final laterRequest = _laterRequest;
    final laterPairing = _laterPairing;
    // The shell clears the handoff for a fresh form; one that came meanwhile goes to it.
    final handoff = ref.read(sendRecipientProvider.notifier);
    widget.onDone();
    if (laterPairing != null) {
      _laterPairing = null;
      handoff.handPairing(laterPairing);
    } else if (laterRequest != null) {
      _laterRequest = null;
      _laterRecipient = null;
      handoff.handRequest(laterRequest.request, laterRequest.origin);
    } else if (later != null) {
      _laterRecipient = null;
      _laterOrigin = null;
      handoff.hand(later, origin: laterOrigin);
    }
  }

  // Build.

  /// What the Advanced network mode allows now, read in [build]: Epicbox and Direct sends
  /// wait while it is not [NetBlock.none]; the File route never does.
  NetBlock _block = NetBlock.none;

  /// What the network mode alone allows Epicbox and Link now (Node only, Kill switch, Tor only
  /// waiting), read in [build]: the selector shows them Off while it is not [NetBlock.none].
  NetBlock _modeBlock = NetBlock.none;

  /// What it allows the File method: Offline stops making a file too (it asks the node),
  /// unless the node is local.
  /// What the network mode allows finishing and posting a file or QR Payment, which reach
  /// only the node: Tor only waits for tor; Offline lets them use the node in use. Making a
  /// file waits for nothing (LEPIC asks the node for its tip, which Offline allows too).
  NetBlock _postBlock = NetBlock.none;

  /// Offline on a node that is not local: the file steps carry [OfflineNodeNote].
  bool _offlineNode = false;

  /// Send through the paired contact's mailbox instead of its payments address (RFC 9.1).
  bool _viaMailbox = false;

  /// A paired contact with no address, paid through its mailbox (DESIGN 1.2): the pairing's
  /// id. Its card takes the To field's place; the To text stays empty.
  String? _pairingTo;

  /// A pairing handed over while a payment is held, for the next form.
  String? _laterPairing;

  /// [_pairingTo]'s record, watched in a build; null without one, or once it is removed.
  PairingRecord? _toPairing({bool watch = true}) {
    final id = _pairingTo;
    if (id == null) return null;
    return watch ? ref.watch(pairingByIdProvider(id)) : ref.read(pairingByIdProvider(id));
  }

  /// The name of the pairing [id]: its contact's, else the one it chose.
  String _pairingNameOf(String id, {bool watch = true}) =>
      watch ? ref.watch(pairingNameProvider(id)) : ref.read(pairingNameProvider(id));

  /// A mailbox payment made now waits in the outbox: Epicbox is off (LEPIC queues it).
  bool _queues({bool watch = true}) =>
      _pairingTo != null && (watch ? ref.watch(pairNetProvider) : ref.read(pairNetProvider)) == PairNet.epicboxOff;

  /// The file route seals for the paired contact the recipient belongs to unless
  /// the user chose plain ("Seal this file?", or Send plain from the 90-day hint).
  bool _filePlain = false;

  /// The file made, sealed for [_sealedFor]; and its plain copy once "Send as plain instead"
  /// was confirmed (the same payment, unsealed).
  String? _sealedText;
  PairingRecord? _sealedFor;
  String? _plainCopy;

  /// The paired contact a file to the recipient is sealed for, or null: the QR way, a
  /// recipient not paired, or Seal payments off.
  PairingRecord? _fileSealTarget({bool watch = true}) {
    if (_viaQr) return null;
    final r = _pairingTo != null ? _toPairing(watch: watch) : sendPairingFor(ref, _recipient.text.trim(), watch: watch);
    return r != null && r.seals ? r : null;
  }

  /// The payment method the form sends by now: Epicbox, or for a Link send the Link method
  /// the address picks (Link · HTTP or Link · Tor); null while a Link send has no address yet,
  /// and for the file routes (their gate is [_postBlock]).
  MethodKind? get _sendMethod {
    if (_method == TransferMethod.epicbox) return MethodKind.epicbox;
    if (_method != TransferMethod.direct) return null;
    // Link chosen with both its switches off: Link · HTTP is the one to turn on (Tor's needs Tor).
    if (_recipient.text.trim().isEmpty) return _linkOff ? MethodKind.linkHttp : null;
    final kind = parseRecipient(_recipient.text).kind;
    // No Tor in this build: an onion has no method to turn on, its own error says so.
    if (kind == RecipientKind.tor && !torBuilt) return null;
    return kind == RecipientKind.epicbox ? null : MethodKind.ofRecipient(kind);
  }

  /// Settings › Transactions, watched: the build follows a switch (the defaults until it loads).
  PaymentPrefs get _watchedPayments =>
      ref.watch(appSettingsProvider.select((s) => s.value?.payments)) ??
      (ref.watch(phonePaymentsProvider) ? PaymentPrefs.phoneDefaults : PaymentPrefs.defaults);

  /// Both Link switches are off: Send still lists Link, and says how to turn it on.
  bool get _linkOff => !_watchedPayments.offersFamily(MethodFamily.link);

  /// One tap on the off-note's button: [m]'s switch on, as Settings › Transactions would.
  Future<void> _turnOn(MethodKind m) async {
    final notifier = ref.read(appSettingsProvider.notifier);
    await notifier.setPayments(_payments.withMethod(m, true));
  }

  /// The method the form sends by is off in Settings › Transactions: its reason, then, when
  /// the recipient is a saved contact whose one address is of that kind, that the contact
  /// can be paid only that way. Null for any other [note].
  String? _methodOffLine(NetBlock note) {
    final m = _sendMethod;
    final lm = context.l10n;
    // The mode itself holds an Epicbox or Link send: name it and say what still works.
    if (note == NetBlock.killSwitch) return lm.netBlockSendKillSwitch;
    if (note == NetBlock.nodeOnly) return m?.family == MethodFamily.link ? lm.netBlockLinkNodeOnly : lm.netBlockEpicboxNodeOnly;
    if (m == null || (note != NetBlock.epicboxOff && note != NetBlock.methodOff)) return null;
    final l = context.l10n;
    final reason = methodOffReason(l, m);
    final contact = contactFor(
      ref.watch(contactsProvider).value ?? const <Contact>[],
      parseRecipient(_recipient.text).address,
    );
    // A contact with another address is not "only" this way: pick it again for the address
    // whose method is on.
    if (contact == null || contact.kinds.length > 1) return reason;
    final name = contact.name;
    final only = m == MethodKind.epicbox
        ? l.sendContactOnlyEpicbox(name)
        : l.sendContactOnlyMethod(name, MethodIcons.fullName(l, m));
    return '$reason $only';
  }

  @override
  Widget build(BuildContext context) {
    // A method off in Settings › Transactions holds the send too: Epicbox, or the Link method
    // the address picks (a pasted onion with Link · Tor off says so, never a silent refusal).
    // A pairing recipient's payment waits in the outbox while Epicbox is off ("Queue
    // payment"); Offline and Tor still hold it.
    _block = watchNetBlock(context, ref, method: _pairingTo != null ? null : _sendMethod);
    _modeBlock = watchNetBlock(context, ref);
    _onNow = {for (final m in TransferMethod.values) if (_methodOnNow(m)) m};
    _keepMethodOn();
    // The pairing went (removed elsewhere): back to the To field.
    if (_pairingTo != null && _toPairing() == null && ref.watch(pairingsProvider).hasValue && !_holdsPayment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pairingTo != null && _toPairing(watch: false) == null) _clearRecipient();
      });
    }
    // A file or QR Payment is made, finalized and posted through the node in use, which
    // Offline allows on any node (the note under the button says so).
    _postBlock = watchPaymentBlock(context, ref);
    _offlineNode = watchOfflineUsesNode(context, ref);
    // An estimate made against the old balance is stale: coins that confirmed may cover it
    // now, or a send elsewhere may have spent them (F-06).
    ref.listen(homeProvider.select((home) => home.value?.summary.spendable), (
      before,
      now,
    ) {
      final amount = _parsedAmount;
      if (before == now || amount == null) return;
      if (_stage != SendStage.amount && _stage != SendStage.fileAmount) {
        return;
      }
      setState(() {
        _estimate = null;
        _estimateError = null;
      });
      // After Max the amount is the old balance's maximum; ask for the new one.
      _maxUsed ? _max() : _estimateFee(amount);
    });
    // A recipient handed over while the tab is kept alive fills the form in place.
    ref.listen(sendRecipientProvider, (_, handoff) {
      if (handoff == null || handoff.id == _handoff) return;
      _handoff = handoff.id;
      final request = handoff.request;
      if (handoff.pairingId case final id?) {
        _setPairing(id);
      } else if (request != null) {
        _applyRequest(request, handoff.origin ?? CodeOrigin.qr);
      } else {
        _setRecipient(handoff.text, origin: handoff.origin);
      }
    });

    // Keeps the listener running while Send shows, as home does, so the review's check sees
    // its state at once.
    ref.watch(listenerProvider.select((s) => s.connected));
    final summary = ref.watch(homeProvider).value?.summary;
    final starting =
        _stage == SendStage.recipient ||
        _stage == SendStage.amount ||
        _stage == SendStage.fileAmount;
    // Nothing to send and nothing on its way: say so instead of a form that fails late.
    if (starting &&
        summary != null &&
        summary.spendable == BigInt.zero &&
        _pending(summary) == BigInt.zero) {
      return _emptyState(context);
    }

    final (children, bottom) = switch (_stage) {
      SendStage.recipient => (_recipientStep(context), _recipientAction()),
      SendStage.amount => (_amountStep(context), _amountAction()),
      SendStage.review => (_reviewStep(context), _reviewAction(context)),
      SendStage.sent => (_trackerStep(context, _sent!), _doneAction()),
      SendStage.fileAmount => (_fileAmountStep(context), _fileAmountAction()),
      SendStage.fileMade => (
        _fileMadeStep(context, _slate!),
        _openReplyAction(),
      ),
      SendStage.fileSent => (_fileSentStep(context), _doneAction()),
    };
    // The reason sits above the button that waits for the network (not after a send).
    final note = switch (_stage) {
      SendStage.recipient || SendStage.amount => _block,
      SendStage.review when !_sendFailed => _block,
      // Making a file needs no connection of its own (Tor only without tor makes it too).
      SendStage.fileMade => _postBlock,
      SendStage.fileAmount when _postBlock == NetBlock.killSwitch => _postBlock,
      _ => NetBlock.none,
    };
    // Offline on a local node without peers: what is posted waits in its pool.
    final noPeers =
        note == NetBlock.none &&
        (_stage == SendStage.review || _stage == SendStage.fileMade) &&
        ref.watch(offlineNodePeersProvider).value == 0;
    // Offline on a node that is not local: the file steps say the node is used.
    final offlineNode = _offlineNode && note == NetBlock.none && (_stage == SendStage.fileAmount || _stage == SendStage.fileMade);
    return ScreenBody(
      bottom: note != NetBlock.none || noPeers || offlineNode
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (noPeers)
                  NetBlockNote(NetBlock.none, key: offlineNoPeersKey, line: context.l10n.netOfflineNoPeers)
                else if (offlineNode)
                  const OfflineNodeNote()
                else ...[
                  NetBlockNote(
                    note,
                    line: note == _postBlock && note == NetBlock.killSwitch && _stage != SendStage.recipient && _stage != SendStage.amount && _stage != SendStage.review
                        ? context.l10n.coldNeedsOnlineCheck
                        : _methodOffLine(note),
                  ),
                  // A Link method off: one tap turns it on here (Epicbox keeps its own way).
                  if (_sendMethod case final m? when note == NetBlock.methodOff && m.family == MethodFamily.link) ...[
                    OutlinedButton(
                      key: sendTurnOnMethodKey,
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                      onPressed: () => _turnOn(m),
                      child: Text(context.l10n.sendTurnOnMethod(MethodIcons.fullName(context.l10n, m))),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
                bottom,
              ],
            )
          : bottom,
      children: [...children, if (_error != null) ErrorText(_error!)],
    );
  }

  Widget _emptyState(BuildContext context) {
    final demo = ref.watch(demoModeProvider);
    final request = _activeRequest;
    return CenteredScroll(
      child: CenteredBody(
        children: [
          // A code or link that came in still shows it did; the form takes it once coins arrive.
          if (request != null)
            RequestBanner(
              open: _requestBanner,
              origin: _origin ?? CodeOrigin.qr,
              problems: request.problems,
              onDismiss: () => setState(() => _requestBanner = false),
            ),
          PhoneTourTarget(
            id: 'tour-send-empty',
            child: EmptyState(
            icon: const Icon(Icons.north_east),
            message: context.l10n.sendNoCoins,
            // Never a dead end: the next step is the Receive tab.
            action: demo
                ? const TestCoinsButton()
                : TextButton(
                    onPressed: () => ref
                        .read(shellTabProvider.notifier)
                        .go(ShellTab.receive),
                    child: Text(context.l10n.homeReceiveButton),
                  ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _header(
    BuildContext context,
    String title, {
    int? step,
    VoidCallback? onBack,
    Widget? extra,
  }) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = context.tokens;
    final counterStyle = theme.textTheme.bodySmall?.copyWith(color: t.dim);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(
        builder: (context, box) {
          // At a large text size or on a narrow phone the step counter goes under the
          // title, so the title still breaks by word, never by letter.
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final stacked = step != null && (scale >= 1.5 || box.maxWidth < 340);
          final heading = Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleLarge),
          );
          return Row(
            crossAxisAlignment: stacked ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (onBack != null)
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _busy || _estimating ? null : onBack,
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: onBack == null ? 0 : 4,
                  ),
                  child: stacked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            heading,
                            Text(l.sendStepOf(step, 3), style: counterStyle),
                          ],
                        )
                      : heading,
                ),
              ),
              if (step != null && !stacked)
                Text(l.sendStepOf(step, 3), style: counterStyle),
              // One help icon per header: a step with its own help shows that.
              if (extra != null)
                extra
              else
                IconButton(
                  tooltip: l.sendHowItWorks,
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => showHandshakeSheet(context, flow: _howFlow),
                ),
            ],
          );
        },
      ),
    );
  }

  /// The "How it works" tab of the way this payment goes: its own method's, never Epicbox's
  /// by default.
  HandshakeFlow get _howFlow => switch (_stage) {
    SendStage.fileAmount ||
    SendStage.fileMade ||
    SendStage.fileSent => _viaQr ? HandshakeFlow.qr : HandshakeFlow.file,
    SendStage.sent =>
      _sent == null || _sent!.to.kind == RecipientKind.epicbox
          ? HandshakeFlow.payment
          : HandshakeFlow.direct,
    _ =>
      _method == TransferMethod.direct
          ? HandshakeFlow.direct
          : HandshakeFlow.payment,
  };

  String? _contactName(String address) {
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    return contactNameFor(contacts, address);
  }

  /// Epicbox, Link, Direct · QR and Direct · File, one segment each, icon over label. Link is
  /// the family: the address picks Link · HTTP or Link · Tor. Tor is not a method: the one Tor
  /// switch (Settings › Privacy) changes how Epicbox and Link connect.
  /// [m] can be chosen now: Epicbox and Link wait for the network mode, Epicbox for its switch
  /// too (a pairing's mailbox queues), and a pairing recipient has no Link address. QR Payment
  /// and File Transfer are made without a connection: always, while offered.
  bool _methodOnNow(TransferMethod m) => switch (m) {
    TransferMethod.epicbox => _modeBlock == NetBlock.none && (_watchedPayments.epicbox || _pairingTo != null),
    TransferMethod.direct => _modeBlock == NetBlock.none && _pairingTo == null,
    TransferMethod.qr => _watchedPayments.directQr && offersQrPayment(ref),
    TransferMethod.file => _watchedPayments.directFile || hasPendingFileSend(ref.watch(homeProvider.select((h) => h.value?.transactions))),
  };

  /// The methods that can be chosen now, worked out in [build] ([_methodOnNow]).
  Set<TransferMethod> _onNow = TransferMethod.values.toSet();

  bool _methodOn(TransferMethod m) => _onNow.contains(m);

  /// No method can be chosen on the address steps (Node only with QR Payment and File Transfer
  /// off): nothing is selected and the form waits, the note says why.
  bool get _noMethod =>
      (_stage == SendStage.recipient || _stage == SendStage.amount) && _onNow.isEmpty;

  bool _moving = false;

  /// A method that cannot be chosen now never stays chosen with a live form (D-06): on the
  /// address steps Send moves to the first that can, after this frame (QR Payment and File
  /// Transfer open their route). Only this screen's choice moves; Settings stay as they are.
  void _keepMethodOn() {
    if (_moving || _holdsPayment || _busy || _estimating) return;
    if (_stage != SendStage.recipient && _stage != SendStage.amount) return;
    if (_methodOn(_method)) return;
    if (_onNow.isEmpty) return;
    _moving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _moving = false;
      if (!mounted || _holdsPayment || _busy || _estimating) return;
      if (_stage != SendStage.recipient && _stage != SendStage.amount) return;
      if (_methodOn(_method)) return;
      for (final m in TransferMethod.values) {
        if (!_methodOn(m)) continue;
        _chooseMethod(m);
        return;
      }
    });
  }

  /// The form under the selector, dimmed and out of reach while [_noMethod].
  List<Widget> _waitForMethod(List<Widget> children) => !_noMethod
      ? children
      : [
          ExcludeFocus(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.4,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
              ),
            ),
          ),
        ];

  Widget _methodSelector(BuildContext context, TransferMethod selected) {
    final l = context.l10n;
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    ButtonSegment<TransferMethod> segment(
      TransferMethod value,
      IconData icon,
      String label,
    ) {
      // Not available now: Off under the name, and it cannot be chosen.
      final on = _methodOn(value);
      return ButtonSegment(
        value: value,
        tooltip: label,
        enabled: on,
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: labelStyle),
            ),
            if (!on) ...[
              const SizedBox(height: 2),
              FittedBox(fit: BoxFit.scaleDown, child: EBadge.state(l.netStatusOff, on: false)),
            ],
          ],
        ),
      );
    }
    // Settings › Transactions says which methods are offered; the method in use stays
    // whatever the switch says (a pasted onion picks Link; a file send, the failed-Epicbox
    // file fallback and a file waiting for its reply keep File).
    final payments = _watchedPayments;
    final filePending = hasPendingFileSend(
      ref.watch(homeProvider.select((h) => h.value?.transactions)),
    );
    final segments = [
      // Epicbox off (Settings › Transactions) hides it too; a pasted Epicbox address brings it
      // back for this send, where the note says it is off.
      if (selected == TransferMethod.epicbox || payments.epicbox || _pairingTo != null)
        segment(TransferMethod.epicbox, MethodIcons.of(MethodKind.epicbox), MethodIcons.shortName(l, MethodKind.epicbox)),
      // Link is listed from the start: sending by it needs no listener. With Link · HTTP
      // and Link · Tor both off the note names the method and Turn on is one tap.
      // A pairing recipient has no Link address.
      if (selected == TransferMethod.direct || _pairingTo == null)
        segment(TransferMethod.direct, MethodIcons.family(MethodFamily.link), MethodIcons.familyName(l, MethodFamily.link)),
      if (selected == TransferMethod.qr || (payments.directQr && offersQrPayment(ref)))
        segment(TransferMethod.qr, MethodIcons.of(MethodKind.directQr), MethodIcons.shortName(l, MethodKind.directQr)),
      if (selected == TransferMethod.file || payments.directFile || filePending)
        segment(TransferMethod.file, MethodIcons.of(MethodKind.directFile), MethodIcons.shortName(l, MethodKind.directFile)),
    ];
    if (segments.length == 1) return const SizedBox.shrink();
    return PhoneTourTarget(
      id: 'tour-send-methods',
      child: Semantics(
      label: l.sendMethodLabel,
      container: true,
      child: SegmentedButton<TransferMethod>(
        key: sendMethodsKey,
        segments: segments,
        selected: _noMethod ? const {} : {selected},
        emptySelectionAllowed: _noMethod,
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        style: const ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, 44)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          ),
          visualDensity: VisualDensity.standard,
        ),
        onSelectionChanged: (chosen) => _chooseMethod(chosen.first),
      ),
    ),
    );
  }

  /// The selector and, 12 dp under it, the strip that says what [method] means.
  List<Widget> _methodHead(BuildContext context, TransferMethod method) {
    // Epicbox chosen while its listener is down: say so and offer Retry (UP-038); the other
    // methods go on as before.
    final epicbox = ref.watch(walletStatusProvider.select((s) => s.epicbox));
    final none = _noMethod;
    final down = !none && method == TransferMethod.epicbox && (epicbox == null || epicbox == EpicboxState.offline);
    return [
      _methodSelector(context, method),
      // No method can be chosen: no picture of one.
      if (!none) ...[
        const SizedBox(height: 12),
        DismissibleTip(
          id: sendMethodTipId,
          child: MethodStrip(method: method),
        ),
      ],
      if (down) ...[
        const SizedBox(height: 12),
        EdgeCard(
          key: sendEpicboxDownKey,
          edge: context.tokens.warn,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Icon(Icons.cloud_off, size: 18, color: context.tokens.warn),
                const SizedBox(width: 10),
                Expanded(child: Text(context.l10n.statusEpicboxOffline)),
                TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.commonRetry),
                  onPressed: () => ref.read(listenerProvider.notifier).restart(),
                ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
    ];
  }

  /// Saved contacts whose name holds [text], for "Address or contact": at most three.
  List<Contact> _nameMatches(String text) {
    final query = text.trim().toLowerCase();
    if (query.length < 2 || recipientShaped(parseRecipient(query))) {
      return const [];
    }
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    return contacts
        .where((c) => c.name.toLowerCase().contains(query))
        .take(3)
        .toList();
  }

  List<Widget> _recipientStep(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = context.tokens;
    final scan = offersQrScan(ref);
    final text = _recipient.text.trim();
    final to = parseRecipient(text);
    final valid = text.isNotEmpty && _recipientProblem(text) == null;
    final recent = recentRecipients(
      ref.watch(homeProvider).value?.transactions ?? const <TxEntry>[],
    );
    final matches = _nameMatches(text);
    final shape = sendAddressShape(l, _method);
    final way = _wayOf(_toRoute);
    final pairing = _toPairing();
    if (pairing != null) {
      final name = _pairingNameOf(pairing.id);
      return [
        _header(context, l.sendStepMethod, step: 1),
        ..._methodHead(context, _method),
        Semantics(
          label: l.sendToLabel,
          container: true,
          child: PairingRecipientCard(pairing: pairing, name: name, onClear: _clearRecipient),
        ),
        const SizedBox(height: 8),
        SendPairingMailbox(
          pairing: pairing,
          name: name,
          onCheck: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: pairing.id, recheck: true)),
          ),
        ),
        const SizedBox(height: 4),
        _recipientButtons(scan),
      ];
    }
    return [
      _header(context, l.sendStepMethod, step: 1),
      ..._methodHead(context, _method),
      ..._waitForMethod([
      PhoneTourTarget(
        id: 'tour-send-recipient',
        child: TextField(
        key: sendRecipientFieldKey,
        controller: _recipient,
        focusNode: _recipientFocus,
        autocorrect: false,
        enableSuggestions: false,
        // Grows to show the whole address, so its start can be checked.
        minLines: 1,
        maxLines: null,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.next,
        onEditingComplete: _toAmount,
        style: theme.textTheme.bodyMedium?.copyWith(fontFamily: t.monoFamily),
        onChanged: (text) {
          if (text.length - _lastTo.length >= 8 && looksLikeCode(text)) {
            final before = _lastTo;
            _lastTo = text;
            _openText(text.trim(), CodeOrigin.paste, typedOver: before);
            return;
          }
          setState(() {
            _followAddress(text);
            _recipientError = null;
            _error = null;
            _leaveRequest();
          });
        },
        decoration: InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.sendToLabel),
              if (_switchedTo != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: _SwitchTag(method: _switchedTo, shown: _tagOn),
                ),
              ],
              if (_TorTag.shows(way, _torState)) ...[
                const SizedBox(width: 8),
                Flexible(child: _TorTag(way: way)),
              ],
            ],
          ),
          hintText: l.sendToHint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          suffixIcon: _recipient.text.isEmpty
              ? null
              : IconButton(
                  key: sendRecipientClearKey,
                  tooltip: l.sendClearRecipient,
                  icon: const Icon(Icons.close),
                  onPressed: _clearRecipient,
                ),
          error: _recipientError == null
              ? null
              : LiveFieldError(_recipientError!),
          border: const OutlineInputBorder(),
        ),
      ),
      ),
      if (_tagOn && _switchedTo != null)
        _SwitchAnnouncement(method: _switchedTo!),
      _TorNotice(way: way, onion: parseRecipient(_recipient.text).kind == RecipientKind.tor),
      // A saved contact: Send via its other addresses; paired, its trust and the seal.
      if (valid)
        SendPairingLine(
          address: to.address,
          epicbox: _method == TransferMethod.epicbox,
          viaMailbox: _viaMailbox,
          onViaMailbox: (on) => setState(() => _viaMailbox = on),
          onAddress: (address) => setState(() {
            _recipient.text = address;
            _followAddress(address);
            _recipientError = null;
          }),
        ),
      if (text.isEmpty && shape != null)
        Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                shape,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: t.monoFamily,
                  fontSize: 12,
                  color: t.dim,
                ),
              ),
            ),
            IconButton(
              tooltip: l.methodAddressKindsTooltip,
              icon: Icon(Icons.help_outline, size: 20, color: t.dim),
              onPressed: () => openHelp(context, HelpId.addresses),
            ),
          ],
        ),
      _recipientButtons(scan),
      if (valid) ...[
        const SizedBox(height: 8),
        RecipientCard(
          address: to.address,
          name: _contactName(to.address),
          onSave: _contactName(to.address) == null
              ? () => _saveContact(to.address)
              : null,
        ),
        ..._payeeClaims(gapBefore: 8),
      ],
      if (matches.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          l.sendContactsButton,
          style: theme.textTheme.labelLarge?.copyWith(color: t.dim),
        ),
        const SizedBox(height: 4),
        for (final contact in matches)
          _RecentRow(
            address: contactSendAddress(contact, _payments.offers),
            name: contact.name,
            // A contact with no address: through its pairing, never an empty address.
            subtitle: _pairingOnly(contact, watch: true) == null ? null : l.sendRecipientPairing(contact.name),
            onTap: () => _useContact(contact),
          ),
      ],
      if (text.isEmpty && recent.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(
          l.sendRecent,
          style: theme.textTheme.labelLarge?.copyWith(color: t.dim),
        ),
        const SizedBox(height: 4),
        for (final address in recent)
          _RecentRow(
            address: address,
            name: _contactName(address),
            onTap: () {
              _setRecipient(address);
              _toAmount();
            },
          ),
      ],
      ]),
    ];
  }

  /// Paste, Scan (where the phone scans) and Contacts under the recipient.
  Widget _recipientButtons(bool scan) {
    final l = context.l10n;
    return Wrap(
      spacing: 8,
      children: [
        Tooltip(
          message: l.commonPaste,
          child: TextButton.icon(
            icon: const Icon(Icons.content_paste),
            label: Text(l.commonPaste),
            onPressed: _paste,
          ),
        ),
        if (scan)
          Tooltip(
            message: l.scanQrTooltip,
            child: TextButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l.sendScanButton),
              onPressed: _scan,
            ),
          ),
        Tooltip(
          message: l.sendChooseContactTooltip,
          child: TextButton.icon(
            icon: const Icon(Icons.contacts),
            label: Text(l.sendContactsButton),
            onPressed: _pickContact,
          ),
        ),
      ],
    );
  }

  /// A pairing recipient can be paid while paired or verified and its wallet opens sealed
  /// messages; keys that changed meanwhile hold Continue until the words are checked.
  bool get _hasRecipient => _pairingTo != null
      ? _toPairing()?.paysByMailbox ?? false
      : _recipient.text.trim().isNotEmpty;

  /// Plain `http://` to another device with the Tor switch on: the notice under To says so,
  /// and Continue waits until Tor is off or the address changes.
  bool get _plainHttpOff =>
      _pairingTo == null &&
      _toRoute == TorRoute.plainHttpDirect &&
      _wayOf(TorRoute.plainHttpDirect) == TorWay.off;

  Widget _recipientAction() => BusyButton(
    label: context.l10n.commonContinue,
    onPressed: !_hasRecipient || _block != NetBlock.none || _plainHttpOff
        ? null
        : _toAmount,
  );

  /// The big amount, what is available, Use USD and Max, the fee, and the folded note.
  List<Widget> _amountFields(BuildContext context, {required bool file}) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = context.tokens;
    final summary = ref.watch(homeProvider).value?.summary;
    final price = ref.watch(priceProvider).value;
    final currency =
        ref.watch(appSettingsProvider).value?.fiatCurrency ?? 'usd';
    final amount = _parsedAmount;
    final estimate = _estimate;
    String? amountHelper;
    if (amount != null && price != null) {
      amountHelper = _fiatEntry
          ? '≈ ${epicText(l, amount)}'
          : '≈ ${localDigits(l, fiatText(amount, price, currency))}';
    }
    // A code's amount: "Requested by the code" while the field holds it, what it asked for
    // once changed.
    final asked = file ? null : _activeRequest?.amount;
    final fromCode = asked != null && amount == asked;
    if (asked != null) {
      final marker = fromCode
          ? l.sendAmountFromCode
          : l.sendAmountCodeAsked(epicText(l, asked));
      amountHelper = amountHelper == null ? marker : '$marker · $amountHelper';
    }
    // Why nothing is available yet, in the header's words.
    final held = [
      if (summary != null && summary.spendable == BigInt.zero) ...[
        if (summary.locked > BigInt.zero)
          l.balanceLineOnHold(epicText(l, summary.locked)),
        if (comingIn(summary) > BigInt.zero)
          l.balanceLineComingIn(epicText(l, comingIn(summary))),
      ],
    ];
    return [
      TextField(
        key: file ? sendFileAmountFieldKey : sendAmountFieldKey,
        controller: _amount,
        focusNode: _amountFocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        textAlign: TextAlign.center,
        onEditingComplete: () {
          if (_noteOpen) {
            _noteFocus.requestFocus();
          } else {
            _submitAmount(file: file);
          }
        },
        onChanged: _onAmountChanged,
        style: theme.textTheme.displaySmall?.copyWith(
          fontFamily: t.monoFamily,
          color: t.text,
        ),
        decoration: InputDecoration(
          labelText: l.sendAmountLabel(
            _fiatEntry ? currency.toUpperCase() : 'EPIC',
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          floatingLabelAlignment: FloatingLabelAlignment.center,
          hintText: '0',
          // Max and the unit live in the field's trailing slot, as the desktop's (UP-020):
          // the unit is a tap to the other one.
          suffixIcon: Row(
            key: amountSuffixKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (price != null || _fiatEntry)
                Tooltip(
                  message: l.sendUseUnit(_fiatEntry ? 'EPIC' : currency.toUpperCase()),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: t.dim,
                    ),
                    onPressed: _toggleUnit,
                    child: Semantics(
                      label: l.sendUseUnit(_fiatEntry ? 'EPIC' : currency.toUpperCase()),
                      excludeSemantics: true,
                      child: Text(_fiatEntry ? currency.toUpperCase() : 'EPIC'),
                    ),
                  ),
                ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: _busy ? null : _max,
                child: Text(l.sendMax),
              ),
              const SizedBox(width: 4),
            ],
          ),
          suffixIconConstraints: const BoxConstraints(minHeight: 48),
          helperText: amountHelper,
          helperStyle: fromCode
              ? theme.textTheme.bodySmall?.copyWith(color: t.info)
              : null,
          helperMaxLines: 2,
          error: _amountError == null ? null : LiveFieldError(_amountError!),
        ),
      ),
      const SizedBox(height: 12),
      if (summary != null)
        Text(
          l.sendAvailable(epicText(l, summary.spendable)),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
        ),
      for (final line in held)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            line,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
          ),
        ),
      if (estimate != null && _estimateError == null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Semantics(
            liveRegion: true,
            child: Text(
              l.sendFeeQuiet(epicText(l, estimate.fee)),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
            ),
          ),
        ),
      if (_estimateError != null) ErrorText(_estimateError!),
      // Coins another linked device is spending: why the amount does not fit.
      if (_estimateError != null) ..._heldLines(context),
      if (!_maxUsed && AdvancedOptions.has(context, AdvancedFeature.sendOptions))
        _strategyPicker(context),
      const SizedBox(height: 12),
      Divider(color: t.line, height: 1),
      if (!_noteOpen && _note.text.isNotEmpty)
        ListTile(
          contentPadding: EdgeInsets.zero,
          minTileHeight: 56,
          title: Text(l.sendNoteLabel, style: theme.textTheme.bodyMedium),
          subtitle: Text(
            _note.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
          ),
          trailing: Icon(Icons.edit_outlined, color: t.dim),
          onTap: () {
            setState(() => _noteOpen = true);
            _noteFocus.requestFocus();
          },
        )
      else if (!_noteOpen)
        ListTile(
          contentPadding: EdgeInsets.zero,
          minTileHeight: 56,
          title: Text(l.sendAddNote, style: theme.textTheme.bodyMedium),
          trailing: Icon(Icons.expand_more, color: t.dim),
          onTap: () {
            setState(() => _noteOpen = true);
            _noteFocus.requestFocus();
          },
        )
      else
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: TextField(
            key: file ? sendFileNoteFieldKey : sendNoteFieldKey,
            controller: _note,
            focusNode: _noteFocus,
            // LEPIC signs at most this many bytes; the field stops there instead of cutting.
            inputFormatters: const [Utf8LengthLimiter(slateMessageMaxBytes)],
            onChanged: (_) => setState(() {}),
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => Text(
                  l.sendMessageCounter(
                    utf8Length(_note.text),
                    slateMessageMaxBytes,
                  ),
                  style: theme.textTheme.bodySmall,
                ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitAmount(file: file),
            decoration: InputDecoration(
              labelText: l.sendNoteLabel,
              helperText:
                  _activeRequest?.note != null &&
                      _note.text == _activeRequest?.note
                  ? l.sendNoteFromCodeHelper
                  : l.sendNoteHelper,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
    ];
  }

  void _submitAmount({required bool file}) {
    if (!_amountReady || _busy) return;
    if (file) {
      _createFile();
      return;
    }
    // A connection that waits for Tor, or needs it, goes no further than here.
    final way = _wayOf(
      sendRoute(parseRecipient(_recipient.text)),
      phoneTorState(ref.read(phoneTorProvider)),
    );
    if (!torGoes(way) || _block != NetBlock.none) return;
    _toReview();
  }

  List<Widget> _amountStep(BuildContext context) {
    final l = context.l10n;
    final address = parseRecipient(_recipient.text).address;
    final request = _activeRequest;
    return [
      _header(context, l.sendStepAmount, step: 2, onBack: _toRecipient),
      if (request != null)
        RequestBanner(
          open: _requestBanner,
          origin: _origin ?? CodeOrigin.qr,
          problems: request.problems,
          onDismiss: () => setState(() => _requestBanner = false),
        ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: _ToChip(
          address: address,
          name: _pairingTo == null ? _contactName(address) : _pairingNameOf(_pairingTo!),
        ),
      ),
      _TorNotice(
        way: _wayOf(sendRoute(parseRecipient(_recipient.text))),
        onion: parseRecipient(_recipient.text).kind == RecipientKind.tor,
      ),
      ..._payeeClaims(gapBefore: 12),
      const SizedBox(height: 20),
      ..._amountFields(context, file: false),
    ];
  }

  /// Continue to the review; it waits while the payment's connection waits for Tor.
  Widget _amountAction() {
    final way = _wayOf(sendRoute(parseRecipient(_recipient.text)));
    return BusyButton(
      label: way == TorWay.wait
          ? context.l10n.torWaiting
          : context.l10n.commonContinue,
      busy: _estimating,
      onPressed:
          _amountReady && !_busy && torGoes(way) && _block == NetBlock.none
          ? _toReview
          : null,
    );
  }

  List<Widget> _reviewStep(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = context.tokens;
    final estimate = _estimate!;
    final total = estimate.amount + estimate.fee;
    final spendable = ref.watch(
      homeProvider.select((home) => home.value?.summary.spendable),
    );
    final price = ref.watch(priceProvider).value;
    final currency =
        ref.watch(appSettingsProvider).value?.fiatCurrency ?? 'usd';
    final to = parseRecipient(_recipient.text);
    final pairing = _toPairing();
    final queued = _queues();
    final checks = ref.watch(sendPreflightProvider(_relay));
    final overTor = to.kind == RecipientKind.tor;
    final overHttp = to.kind == RecipientKind.http;
    final tor = overTor ? ref.watch(phoneTorProvider) : null;
    final torState = _torState;
    final way = _wayOf(sendRoute(to), torState);
    final String? failed;
    if (!_sendFailed) {
      failed = null;
    } else if (overHttp) {
      failed = l.sendHttpNotReached(sendTtlDays);
    } else if (overTor) {
      // Nothing stored: tor itself did not connect, for the reason it shows.
      failed = _nothingStored
          ? l.sendTorNothingSent(
              tor!.failure == null
                  ? l.torFailureNetwork
                  : torFailureText(l, tor.failure!),
            )
          // Tried twice by then (lepic_wallet_service.dart): Epicbox is the method for an
          // offline wallet; the method stays the user's choice.
          : '${l.sendTorNotReached(sendTtlDays)}\n${l.sendTorTryEpicbox}';
    } else {
      // The relay is named: a mistyped domain is the usual reason it never answers. A
      // pairing's mailbox is on the contact's own relay.
      final relayName = _pairingTo != null ? (_toPairing()?.homeRelay ?? '') : (_relay?.label ?? '');
      failed = _nothingStored
          ? l.sendRelayDown(relayName)
          : _undelivered == null
          ? l.sendRelayRefusedLost(relayName)
          : l.sendRelayRefused(sendTtlDays, relayName);
    }
    return [
      // After a failed send the payment exists: no way back to send it again.
      _header(
        context,
        l.sendStepReview,
        step: 3,
        onBack: _sendFailed ? null : _backToAmount,
      ),
      if (_activeOrigin case final origin?) ...[
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OriginPill(origin: origin),
        ),
        const SizedBox(height: 12),
      ],
      if (pairing != null) ...[
        // The mailbox is never shown as an address.
        PairingRecipientCard(pairing: pairing, name: _pairingNameOf(pairing.id)),
        const SizedBox(height: 8),
        SendPairingMailbox(
          pairing: pairing,
          name: _pairingNameOf(pairing.id),
          onCheck: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: pairing.id, recheck: true)),
          ),
        ),
      ] else
        RecipientCard(
          address: to.address,
          name: _contactName(to.address),
          host: _activeOrigin != null && to.kind != RecipientKind.epicbox
              ? directHostBesideOf(to.address)
              : null,
        ),
      ..._payeeClaims(gapBefore: 12),
      const SizedBox(height: 20),
      // Four decimals, as every shown amount (UD-027); the exact value on a tap.
      exactAmountTip(
        context,
        estimate.amount,
        hidden: false,
        child: Text(
          epicText(l, estimate.amount),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFamily: t.monoFamily,
            color: t.text,
          ),
        ),
      ),
      const SizedBox(height: 12),
      _Row(
        label: l.sendMethodLabel,
        value: switch (to.kind) {
          RecipientKind.epicbox || RecipientKind.http when way == TorWay.overTor =>
            '${recipientMethodWord(l, to.kind)} · ${l.sendOverTor}',
          RecipientKind.http
              when way == TorWay.clearnet && torState != TorState.off =>
            '${recipientMethodWord(l, to.kind)} · ${l.torNotOverTor}',
          _ => recipientMethodWord(l, to.kind),
        },
        mono: false,
      ),
      // What the recipient will read, as entered; the history keeps it as the private note.
      if (_noteText.isNotEmpty)
        Padding(
          key: sendReviewMessageKey,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.sendNoteLabel,
                style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
              ),
              const SizedBox(height: 2),
              Text(
                _noteText,
                style: theme.textTheme.bodyMedium?.copyWith(color: t.text),
              ),
              const SizedBox(height: 2),
              Text(
                l.sendReviewMessageKept,
                style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
              ),
            ],
          ),
        ),
      _Row(label: l.sendNetworkFee, value: epicText(l, estimate.fee)),
      // Strategy All is a consolidating send: its change is one output, never split.
      if (_sendOptions?.strategy == SelectionStrategy.all &&
          estimate.change > BigInt.zero)
        Text(
          l.sendUsesAllOutputs(estimate.inputCount),
          key: sendUsesAllOutputsKey,
          style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
        ),
      // The amount, then the fiat estimate dim under it, as the amount step and the list rows
      // show them (UP-005); the exact value on a tap (UD-027).
      _Row(
        label: l.sendReviewTotal,
        value: epicText(l, total),
        sub: price == null ? null : '≈ ${localDigits(l, fiatText(total, price, currency))}',
        exact: total,
        strong: true,
      ),
      // What stays after this send: the balance once it is out, and,
      // while the change confirms, only the outputs the send does not lock.
      if (spendable != null && spendable >= total) ...[
        _Row(label: l.sendBalanceAfter, value: epicText(l, spendable - total)),
        // The change locks outputs: only said where Outputs shows (Advanced).
        if (outputsShown(context, ref) &&
            estimate.locked > total &&
            estimate.locked <= spendable) ...[
          _Row(
            label: l.sendSpendableUntilChange,
            value: epicText(l, spendable - estimate.locked),
          ),
          Text(
            l.sendSpendableUntilChangeHint,
            style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
          ),
        ],
      ],
      const SizedBox(height: 8),
      Divider(color: t.line, height: 1),
      const SizedBox(height: 8),
      _ReadyLine(
        checks: checks,
        sending: _busy,
        failed: failed,
        tor: tor,
        http: overHttp,
        way: way,
        queued: queued,
      ),
      // An address whose relay the app does not know may be mistyped: a warning, not a block.
      if (checks.unknownRelay case final unknown? when !_sendFailed) ...[
        const SizedBox(height: 8),
        Row(
          key: sendUnknownRelayKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber, size: 18, color: t.warn),
            const SizedBox(width: 8),
            Expanded(child: Text(l.sendRelayUnknown(unknown.label))),
          ],
        ),
      ],
      // The cancel rule for this method, with the way to the Help topic (CancelNote). After a
      // failed delivery the actions below carry their own line, so this one steps aside.
      if (!_sendFailed) ...[
        const SizedBox(height: 4),
        CancelNote(
          text: to.kind == RecipientKind.epicbox
              ? l.sendCancelRuleEpicbox
              : l.sendCancelRuleDirect,
          anchor: HelpAnchor.sending,
        ),
      ],
      // Epicbox off: the mailbox payment waits in the outbox until it is on again.
      if (queued && !_sendFailed) ...[
        const SizedBox(height: 12),
        EdgeCard(
          key: sendQueuedCardKey,
          edge: t.info,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: t.info),
                const SizedBox(width: 10),
                Expanded(child: Text(l.sendQueuedEpicboxOff, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
      ],
    ];
  }

  Widget _reviewAction(BuildContext context) {
    final l = context.l10n;
    final checks = ref.watch(sendPreflightProvider(_relay));
    final relayDown = checks.relayOutcome == CheckOutcome.failed;
    // Without a node answer the send could not be built or posted, and a connection that
    // waits for Tor or needs it does not go.
    final way = _wayOf(sendRoute(parseRecipient(_recipient.text)));
    // A pairing whose keys changed meanwhile holds the send until the words are checked.
    final pairs = _pairingTo == null || (_toPairing()?.paysByMailbox ?? false);
    final canSend =
        checks.ready && !_busy && torGoes(way) && _block == NetBlock.none && pairs;
    final amount = epicText(l, _estimate!.amount);
    final quiet = TextButton.styleFrom(minimumSize: const Size.fromHeight(44));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The send failed and LEPIC holds the payment: never a second send from here.
        if (_sendFailed && _cancelFailed)
          BusyButton(label: l.commonDone, onPressed: _done)
        // Over Tor or HTTP the waiting payment is delivered again, or cancelled.
        else if (_sendFailed &&
            (_overTor || _overHttp) &&
            _undelivered != null) ...[
          BusyButton(
            key: sendTryAgainKey,
            label: l.sendTryAgain,
            busy: _busy,
            onPressed: _resendDirect,
          ),
          const SizedBox(height: 4),
          // The one destructive look (UP-012): gold says go, not stop.
          DangerButton(
            key: sendCancelPaymentKey,
            onPressed: _busy ? null : _cancelDirectSend,
            child: Text(l.sendCancelPayment),
          ),
        ] else if (_sendFailed && _overTor) ...[
          // Tor did not connect, nothing was sent: the same send again.
          BusyButton(
            key: sendTryAgainKey,
            label: l.sendTryAgain,
            busy: _busy,
            onPressed: _send,
          ),
          const SizedBox(height: 4),
          TextButton(
            style: quiet,
            onPressed: _busy ? null : _done,
            child: Text(l.commonDone),
          ),
        ] else if (_sendFailed && _undelivered != null) ...[
          BusyButton(
            label: l.sendCancelAndFile,
            busy: _busy,
            onPressed: _cancelAndFile,
          ),
          const SizedBox(height: 4),
          TextButton(
            style: quiet,
            onPressed: _busy ? null : _done,
            child: Text(l.sendLeaveIt),
          ),
        ] else if (_sendFailed && _nothingStored) ...[
          // Nothing is held, so a file is the one payment.
          BusyButton(
            label: l.sendPayWithFile,
            onPressed: _busy ? null : _toFileRoute,
          ),
          const SizedBox(height: 4),
          TextButton(
            style: quiet,
            onPressed: _busy ? null : _done,
            child: Text(l.commonDone),
          ),
        ] else if (_sendFailed)
          BusyButton(label: l.commonDone, onPressed: _done)
        // Their relay is down before any attempt: nothing is stored yet.
        else if (relayDown) ...[
          BusyButton(
            label: l.sendPayWithFile,
            onPressed: _busy ? null : _toFileRoute,
          ),
          const SizedBox(height: 4),
          TextButton(
            style: quiet,
            onPressed: canSend ? _send : null,
            child: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.sendAnyway),
          ),
        ] else ...[
          BusyButton(
            label: _queues() ? l.sendQueue : l.sendReviewSendButton(amount),
            busyLabel: l.sendSending,
            busy: _busy,
            onPressed: canSend ? _send : null,
          ),
          const SizedBox(height: 4),
          TextButton(
            style: quiet,
            onPressed: _busy ? null : _backToAmount,
            child: Text(l.sendReviewEdit),
          ),
        ],
      ],
    );
  }

  Widget _doneAction() =>
      BusyButton(label: context.l10n.commonDone, onPressed: _done);

  List<Widget> _trackerStep(BuildContext context, _Sent sent) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = context.tokens;
    final live =
        ref
            .watch(homeProvider)
            .value
            ?.transactions
            .where((tx) => tx.key == sent.tx.key)
            .firstOrNull ??
        sent.tx;
    final target = confirmationsTargetOf(ref);
    final tip = tipHeight(ref);
    final track = sendTrackerAt(live, tip, target: target);
    if (track == SendTrack.notPosted) {
      // Finished but not taken by the network: no way back to the form, so it cannot be
      // sent twice.
      return [NotPostedNotice(tx: live)];
    }
    final pairingId = sent.pairingId;
    final name = pairingId != null ? _pairingNameOf(pairingId) : _contactName(sent.to.address);
    final who = name ?? shortAddress(sent.to.address);
    final confirmations = txConfirmations(live, tip) ?? 0;
    final waiting = track == SendTrack.waitingRecipient;
    // The payment's own steps, as its detail lists them (A-03); the wallet waited on is the
    // current step's sub-line. Through a paired contact's mailbox, the mailbox steps; queued
    // while Epicbox is off, the send itself is the step under way.
    final steps =
        txTimeline(
          l,
          live,
          tip,
          target: target,
          mailbox: pairingId == null || name == null
              ? null
              : (
                  name: name,
                  relay: ref.watch(pairingByIdProvider(pairingId))?.homeRelay ?? '',
                  paused: ref.watch(pairNetProvider) == PairNet.epicboxOff,
                ),
          waiting: name == null ? l.sendTrackWaiting : l.sendTrackWaitingFor(name),
        ) ??
        const <TimelineStep>[];
    final unknown = name == null;
    // Over HTTP or Tor their wallet took it in the exchange itself: past cancelling, and
    // waiting only for a block.
    final delivered =
        sent.to.kind != RecipientKind.epicbox &&
        track == SendTrack.confirming &&
        confirmations == 0;
    return [
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: IconButton(
          tooltip: l.sendHowItWorks,
          icon: const Icon(Icons.info_outline),
          onPressed: () => showHandshakeSheet(context, flow: _howFlow),
        ),
      ),
      Center(
        child: Text(
          epicText(l, sent.amount),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFamily: t.monoFamily,
            color: t.text,
          ),
        ),
      ),
      Center(
        child: Text(
          l.sendTo(who),
          style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
        ),
      ),
      const SizedBox(height: 24),
      // Made while Epicbox was off: it waits in the outbox.
      if (sent.queued && name != null && waiting) ...[
        Semantics(
          liveRegion: true,
          child: Text(
            l.sendQueuedHeadline,
            key: sendQueuedHeadlineKey,
            style: theme.textTheme.titleMedium?.copyWith(color: t.text),
          ),
        ),
        const SizedBox(height: 4),
        Text(l.sendQueuedBody(name), style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
        const SizedBox(height: 16),
      ],
      if (delivered) ...[
        Semantics(
          liveRegion: true,
          child: Text(
            l.sendDeliveredWaitingBlock,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: t.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (track == SendTrack.cancelled)
        Semantics(
          liveRegion: true,
          child: Text(l.sendTrackCancelled, style: theme.textTheme.bodyLarge),
        )
      else
        RoundSteps(steps: steps),
      if (waiting)
        Text(
          l.sendTrackOffline(
            epicText(l, sent.amount + (live.fee ?? sent.tx.fee ?? BigInt.zero)),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
        ),
      if (sent.changedFee case final fee?) ...[
        const SizedBox(height: 8),
        Text(
          l.sendResultFeeChanged(
            epicText(l, fee),
            epicText(l, sent.reviewedFee!),
          ),
          style: theme.textTheme.bodyMedium,
        ),
      ],
      if (!sent.noteSaved) ...[
        const SizedBox(height: 8),
        Text(l.sendResultNoteNotSaved, style: theme.textTheme.bodyMedium),
      ],
      if (waiting) ...[
        const SizedBox(height: 8),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          shape: const Border(),
          title: Text(l.sendTrackIfNot, style: theme.textTheme.bodyMedium),
          children: [
            Text(
              l.sendResultAutoCancel(sendTtlDays),
              style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
            ),
            TextButton.icon(
              icon: const Icon(Icons.help_outline),
              label: Text(l.sendHelp),
              onPressed: () => openHelp(context, HelpId.send),
            ),
          ],
        ),
      ],
      if (unknown) ...[
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            icon: const Icon(Icons.person_add_alt),
            label: Text(l.sendSaveContact),
            onPressed: () => _saveContact(sent.to.address),
          ),
        ),
      ],
    ];
  }

  List<Widget> _fileAmountStep(BuildContext context) {
    final l = context.l10n;
    return [
      _header(
        context,
        _viaQr ? MethodIcons.fullName(l, MethodKind.directQr) : l.sendFileTitle,
        onBack: _toRecipient,
        // The file way has its own help; the QR way keeps the ⓘ.
        extra: _viaQr
            ? null
            : IconButton(
                tooltip: l.sendFileHelpTooltip,
                icon: const Icon(Icons.help_outline),
                onPressed: () => showFileExchangeHelp(
                  context,
                  role: FileExchangeRole.sender,
                ),
              ),
      ),
      ..._methodHead(context, _viaQr ? TransferMethod.qr : TransferMethod.file),
      ..._sealChoice(context),
      ..._amountFields(context, file: true),
      const SizedBox(height: 12),
      CancelNote(
        text: _viaQr ? l.sendCancelRuleQr : l.sendCancelRuleFile,
        anchor: HelpAnchor.sending,
      ),
    ];
  }

  Widget _fileAmountAction() => BusyButton(
    label: _viaQr ? context.l10n.sendMakeQr : context.l10n.sendMakeFile,
    busy: _busy,
    onPressed: _amountReady ? _createFile : null,
  );

  /// The file and QR ways' steps, the payment's own five as its detail lists them (A-03):
  /// waiting for the reply ([at] 1), or, once [posted], where that payment stands.
  Widget _fileSteps(
    BuildContext context,
    int at,
    BigInt amount, {
    TxEntry? posted,
  }) {
    final l = context.l10n;
    final target = confirmationsTargetOf(ref);
    final tip = tipHeight(ref);
    return RoundSteps(
      steps: switch (posted) {
        final tx? => txTimeline(l, tx, tip, target: target) ?? sendSteps(l, at),
        null => sendSteps(
          l,
          at,
          // The QR way has no file: its reply is a code.
          waiting: _viaQr ? l.pairAwaitReplyTitle : l.sendFileWaitingReply,
          held: l.sendFileOnHold(epicText(l, amount)),
        ),
      },
    );
  }

  List<Widget> _fileMadeStep(BuildContext context, Slate slate) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = context.tokens;
    final name = sendFileName(slate.slateId);
    if (_viaQr) {
      // The code has its own screen; this step is where the send waits for the reply.
      return [
        // Finished from the header: Scan their reply stays the one primary at the foot.
        _header(
          context,
          MethodIcons.fullName(l, MethodKind.directQr),
          extra: TextButton(onPressed: _busy ? null : _done, child: Text(l.commonDone)),
        ),
        _fileSteps(context, 1, _parsedAmount ?? BigInt.zero),
        Semantics(
          liveRegion: true,
          child: Text(
            l.sendQrHint,
            style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
          ),
        ),
        const SizedBox(height: 12),
        // Second to the primary at the foot (Scan their reply); Done is in the header.
        OutlinedButton.icon(
          key: sendShowQrKey,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.qr_code_2),
          label: Text(l.qrShow),
          onPressed: _busy ? null : () => _showQr(slate),
        ),
      ];
    }
    final sealed = _sealedText;
    final sealedFor = _sealedFor;
    if (sealed != null && sealedFor != null && _plainCopy == null) {
      return _sealedFileStep(context, slate, sealed, sealedFor);
    }
    return [
      // Done is in the header; one primary at a time (UP-008): Save to device until the file
      // is handed over, then Open response file at the foot.
      _header(
        context,
        l.sendFileTitle,
        extra: TextButton(onPressed: _busy ? null : _done, child: Text(l.commonDone)),
      ),
      _fileSteps(context, 1, _parsedAmount ?? BigInt.zero),
      Text(
        l.sendFileShareHint,
        style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
      ),
      const SizedBox(height: 12),
      SlateFileButtons(
        name: name,
        json: _plainCopy ?? slate.json,
        primary: !_fileHandedOver,
        onHandedOver: () {
          if (!_fileHandedOver) setState(() => _fileHandedOver = true);
        },
      ),
      const SizedBox(height: 8),
      // The text itself is a detail for those who copy it by hand.
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        shape: const Border(),
        title: Text(l.sendCopyPasteInstead, style: theme.textTheme.bodyMedium),
        children: [
          SlateBox(title: l.sendSlateBoxTitle, json: slate.json),
          const SizedBox(height: 16),
          SlateInput(
            key: sendReplyFieldKey,
            controller: _response,
            label: l.sendPasteResponseLabel,
          ),
          const SizedBox(height: 16),
          BusyButton(
            label: l.slateFinishPayment,
            busy: _busy,
            onPressed: _postBlock != NetBlock.none ? null : _finalizePasted,
          ),
          const SizedBox(height: 8),
        ],
      ),
    ];
  }

  /// The file route to a paired contact: "Sealed for Anna"; after a plain file
  /// went to it, "Seal this file?" with Sealed preselected; and after 90 days without a sealed
  /// message from it, a hint that offers Send plain.
  List<Widget> _sealChoice(BuildContext context) {
    final target = _fileSealTarget();
    if (target == null) return const [];
    final l = context.l10n;
    final name = pairingName(target, ref.watch(contactsProvider).value ?? const <Contact>[]);
    final quiet = target.lastSealedIn == null ||
        DateTime.now().difference(target.lastSealedIn!) > sealQuietFor;
    final degraded = target.seal == SealMode.degraded;
    return [
      if (degraded)
        PairCard(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.sendSealOrPlainTitle, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(l.sendSealOrPlainBody(name), style: TextStyle(color: context.tokens.dim)),
                ],
              ),
            ),
            RadioGroup<bool>(
              groupValue: _filePlain,
              onChanged: (v) => setState(() => _filePlain = v ?? false),
              child: Column(
                children: [
                  RadioListTile<bool>(
                    key: sendSealedOptionKey,
                    value: false,
                    title: Text(l.sendSealedOption),
                    subtitle: Text(l.sendSealedOptionHint(name)),
                  ),
                  RadioListTile<bool>(
                    key: sendPlainOptionKey,
                    value: true,
                    title: Text(l.sendPlainOption),
                    subtitle: Text(l.sendPlainOptionHint),
                  ),
                ],
              ),
            ),
          ],
        )
      else
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _filePlain ? EBadge(l.sendPlainOption) : SealedBadge(name: name),
        ),
      // The chooser asks the same question already.
      if (quiet && !_filePlain && !degraded) ...[
        const SizedBox(height: 8),
        PairEdgeNotice(
          tone: BadgeTone.info,
          title: l.sendNotHeardTitle(name),
          body: l.sendNotHeardBody(name),
          actions: [
            TextButton(
              key: sendPlainShortKey,
              onPressed: () => setState(() => _filePlain = true),
              child: Text(l.sendPlainShort),
            ),
          ],
        ),
      ],
      const SizedBox(height: 12),
    ];
  }

  /// The file sealed for [r]: the lock tile, "Sealed for Anna", the file and the
  /// amount, Save file and Share; then, for a contact whose wallet does not answer, "Send as
  /// plain instead", which asks first.
  List<Widget> _sealedFileStep(BuildContext context, Slate slate, String sealed, PairingRecord r) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final name = pairingName(r, ref.watch(contactsProvider).value ?? const <Contact>[]);
    final file = sealedFileName(slate.slateId);
    return [
      _header(context, l.sendFileTitle),
      _fileSteps(context, 1, _parsedAmount ?? BigInt.zero),
      Row(
        children: [
          GlyphTile(size: 48, child: Icon(EpicGlyphs.sealed, color: t.accentText)),
          const SizedBox(width: 12),
          Expanded(child: Text(l.sendSealedTitle(name), style: theme.textTheme.titleMedium)),
        ],
      ),
      const SizedBox(height: 8),
      Text(l.sendSealedBody(name), style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
      const SizedBox(height: 12),
      PairCard(
        children: [
          ListTile(title: Text(file, style: TextStyle(fontFamily: t.monoFamily)), leading: const Icon(Icons.description_outlined)),
          ListTile(title: Text(epicText(l, _parsedAmount ?? BigInt.zero)), leading: const Icon(Icons.north_east)),
        ],
      ),
      const SizedBox(height: 12),
      SlateFileButtons(name: file, json: sealed),
      const SizedBox(height: 16),
      PairEdgeNotice(
        tone: BadgeTone.warn,
        title: l.sendCantOpenTitle(name),
        body: l.sendCantOpenBody,
        actions: [
          OutlinedButton(
            key: sendAsPlainKey,
            onPressed: _busy ? null : () => _sendAsPlain(slate),
            child: Text(l.sendAsPlain),
          ),
        ],
      ),
      const SizedBox(height: 8),
      TextButton(
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: _done,
        child: Text(l.commonDone),
      ),
    ];
  }

  /// "Send as plain instead" (RFC 9.3): asks first, then hands over the same payment unsealed.
  Future<void> _sendAsPlain(Slate slate) async {
    final l = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.sendAsPlainTitle),
        content: Text(l.sendAsPlainBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.sendKeepSealed)),
          FilledButton(key: sendAsPlainConfirmKey, onPressed: () => Navigator.pop(context, true), child: Text(l.sendPlain)),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    await _run((session) async {
      final plain = await session.pairing.plainSlate('s:${slate.slateId}');
      if (mounted) setState(() => _plainCopy = plain);
    });
  }

  Widget _openReplyAction() {
    final l = context.l10n;
    final off = _busy || _postBlock != NetBlock.none;
    if (_viaQr) {
      return FilledButton.icon(
        key: sendScanReplyKey,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(l.qrScanReply),
        onPressed: off || !offersQrPayment(ref) ? null : _scanReply,
      );
    }
    // Outlined until the file is saved or shared, then the primary (UP-008).
    if (!_fileHandedOver) {
      return OutlinedButton(
        key: sendOpenReplyKey,
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: off ? null : _openReply,
        child: Text(l.sendOpenReply),
      );
    }
    return BusyButton(
      key: sendOpenReplyKey,
      label: l.sendOpenReply,
      onPressed: off ? null : _openReply,
    );
  }

  List<Widget> _fileSentStep(BuildContext context) {
    final l = context.l10n;
    final slate = _slate;
    final inHistory = slate == null
        ? null
        : ref
              .watch(homeProvider)
              .value
              ?.transactions
              .where((tx) => tx.key == 's:${slate.slateId}')
              .firstOrNull;
    // The wallet's own row follows the payment as it confirms; what the send returned is the
    // first look at it.
    final posted = _viaQr
        ? (inHistory ?? _filePosted)
        : (_filePosted ?? inHistory);
    if (posted != null && posted.repostable) {
      return [NotPostedNotice(tx: posted)];
    }
    return [
      _header(context, _viaQr ? MethodIcons.fullName(l, MethodKind.directQr) : l.sendFileTitle),
      _fileSteps(context, 3, _parsedAmount ?? BigInt.zero, posted: posted),
    ];
  }
}

/// The recipient as a person: their name or "New recipient", and the address with the ends
/// of its key strong and the middle dim, for checking with them. [onSave] offers to save a
/// new one as a contact.
class RecipientCard extends StatelessWidget {
  const RecipientCard({
    super.key,
    required this.address,
    this.name,
    this.onSave,
    this.host,
  });

  final String address;
  final String? name;
  final VoidCallback? onSave;

  /// The host of a Direct address that came from a code, on its own line above the address,
  /// so the place the payment goes is plain to see.
  final String? host;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = context.tokens;
    final name = this.name;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(t.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Initial(name: name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name ?? l.sendNewRecipient,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: t.text,
                            ),
                          ),
                        ),
                        if (torBuilt && isOnionAddress(address)) ...[
                          const SizedBox(width: 8),
                          const _TorPill(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (host case final host?) ...[
                      Text(
                        l.sendDirectHost,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: t.dim,
                        ),
                      ),
                      Text(
                        host,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: t.monoFamily,
                          color: t.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    AddressEnds(address: address),
                  ],
                ),
              ),
            ],
          ),
          if (onSave != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: Text(l.sendSaveContact),
                onPressed: onSave,
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// The address is an onion address, `<56 characters>.onion`, as [parseRecipient] gives it.
bool isOnionAddress(String address) => address.toLowerCase().endsWith('.onion');

/// An address in the mono face with the first and last 6 characters of its key strong and
/// the rest dim, and the relay on its own line; an onion keeps `.onion` dim at its end.
class AddressEnds extends StatelessWidget {
  const AddressEnds({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final base = Theme.of(context).textTheme.bodySmall
        ?.copyWith(fontFamily: t.monoFamily, color: t.dim, height: 1.45);
    final strong = base?.copyWith(color: t.text, fontWeight: FontWeight.w700);
    final onion = isOnionAddress(address);
    final at = onion ? -1 : address.indexOf('@');
    final key = onion
        ? address.substring(0, address.length - '.onion'.length)
        : at < 0
        ? address
        : address.substring(0, at);
    final relay = at < 0 ? null : address.substring(at);
    final spans = key.length <= 12
        ? [TextSpan(text: key, style: strong)]
        : [
            TextSpan(text: key.substring(0, 6), style: strong),
            TextSpan(text: key.substring(6, key.length - 6)),
            TextSpan(text: key.substring(key.length - 6), style: strong),
          ];
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          ...spans,
          if (onion) const TextSpan(text: '.onion'),
          if (relay != null) TextSpan(text: '\n$relay'),
        ],
      ),
    );
  }
}

/// "Direct address" / "Via Epicbox" beside the To label for 3 s after the address moved the
/// method: fades in over 120 ms and out over 200 ms (at once with reduced motion), and is read
/// out once as "Direct address. Method set to Direct."
/// How long the switch tag takes to fade out before it leaves the To label.
const Duration _switchTagFade = Duration(milliseconds: 200);

class _SwitchTag extends StatelessWidget {
  const _SwitchTag({required this.method, required this.shown});

  final TransferMethod? method;
  final bool shown;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final method = this.method;
    final still = MediaQuery.disableAnimationsOf(context);
    if (method == null) return const SizedBox.shrink();
    final (icon, text) = switch (method) {
      TransferMethod.direct => (MethodIcons.family(MethodFamily.link), l.sendSwitchedDirect),
      _ => (MethodIcons.of(MethodKind.epicbox), l.sendSwitchedEpicbox),
    };
    // The text field merges its label: [_SwitchAnnouncement] says it out loud.
    return ExcludeSemantics(
      child: AnimatedOpacity(
        key: sendSwitchedTagKey,
        opacity: shown ? 1 : 0,
        duration: still
            ? Duration.zero
            : shown
            ? const Duration(milliseconds: 120)
            : _switchTagFade,
        child: EBadge(text, icon: icon, tone: BadgeTone.gold),
      ),
    );
  }
}

/// "Direct address. Method set to Direct." read out once when the address moved the method:
/// its own live region under the To field, outside the field's merged label.
class _SwitchAnnouncement extends StatelessWidget {
  const _SwitchAnnouncement({required this.method});

  final TransferMethod method;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      container: true,
      liveRegion: true,
      label: switch (method) {
        TransferMethod.direct => l.sendSwitchedDirectAnnounce,
        _ => l.sendSwitchedEpicboxAnnounce,
      },
      child: const SizedBox(width: double.infinity, height: 1),
    );
  }
}

/// Beside the To label, from the Tor switch: "Over Tor" while the payment's connection goes
/// through Tor, "Not over Tor" for one that stays on the clearnet while Tor is on, "Waiting
/// for Tor" while Tor starts. Nothing with Tor off; [_TorNotice] covers needing and failing.
class _TorTag extends StatelessWidget {
  const _TorTag({required this.way});

  final TorWay way;

  /// Whether a tag shows for [way] with the switch at [state].
  static bool shows(TorWay way, TorState state) => switch (way) {
    TorWay.overTor || TorWay.wait => true,
    TorWay.clearnet => state != TorState.off,
    TorWay.needsTor || TorWay.blocked || TorWay.off => false,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = switch (way) {
      TorWay.overTor => l.sendOverTor,
      TorWay.wait => l.torWaiting,
      _ => l.torNotOverTor,
    };
    // Read with the field's label: "To, Over Tor".
    return KeyedSubtree(key: sendTorTagKey, child: EBadge.tor(text, way: way));
  }
}

/// Under To while the payment's connection cannot go: an onion address with Tor off ("Needs
/// Tor." with Turn on Tor, which keeps the form), or Tor on but not connected ("Tor is not
/// connected." with Retry and Turn Tor off). Nothing falls back to the clearnet.
class _TorNotice extends ConsumerWidget {
  const _TorNotice({required this.way, this.onion = false});

  final TorWay way;

  /// To holds an onion: a Link · Tor payment, whose own switch comes before Tor.
  final bool onion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    // Without Tor in the app the address's own error says so. A build with Tor whose tor
    // files are missing shows Tor as blocked: nothing goes around it.
    final available = torBuilt;
    // Plain http:// is off while Tor is on: the why (a Tor exit could take the payment)
    // sits behind the info icon.
    final plainOff = way == TorWay.off && !onion;
    if (!available || (way != TorWay.needsTor && way != TorWay.blocked && !plainOff)) {
      return const SizedBox.shrink();
    }
    // Offline: Tor never runs there; the form's Offline line gives the reason (LNX-12).
    if (watchNetBlock(context, ref).byMode) return const SizedBox.shrink();
    // Link · Tor switched off: the form's off line comes first, Tor alone would not send it.
    if (onion && watchNetBlock(context, ref, method: MethodKind.linkTor) == NetBlock.methodOff) return const SizedBox.shrink();
    final tor = ref.read(phoneTorProvider.notifier);
    final blocked = way == TorWay.blocked;
    final quiet = TextButton.styleFrom(minimumSize: const Size(48, 44));
    return Semantics(
      key: sendTorNoticeKey,
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    blocked || plainOff ? Icons.error_outline : torIcon,
                    size: 18,
                    color: blocked || plainOff ? t.risk : t.dim,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      plainOff
                          ? l.sendPlainHttpOffWithTor
                          : blocked
                          ? l.torNotConnectedNotice
                          : l.torNeeds,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  // The why, behind the info icon (the owner: no explanation on the screen).
                  if (plainOff)
                    InfoHint(
                      l.sendPlainHttpOffWithTorWhy,
                      key: sendPlainHttpOffInfoKey,
                      size: 32,
                      title: l.sendPlainHttpOffWithTor,
                      icon: Icons.error_outline,
                    ),
                ],
              ),
            ),
            if (blocked) ...[
              TextButton(
                style: quiet,
                onPressed: tor.retry,
                child: Text(l.commonRetry),
              ),
              TextButton(
                key: sendTurnOffTorKey,
                style: quiet,
                onPressed: () => tor.setReceiving(false),
                child: Text(l.torTurnOff),
              ),
            ] else if (plainOff)
              TextButton(
                key: sendTurnOffTorKey,
                style: quiet,
                onPressed: () => tor.setReceiving(false),
                child: Text(l.torTurnOff),
              )
            else
              TextButton(
                key: sendTurnOnTorKey,
                style: quiet,
                onPressed: () => tor.setReceiving(true),
                child: Text(l.torTurnOn),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Over Tor" beside a recipient whose address is an onion: the payment always goes over Tor.
class _TorPill extends StatelessWidget {
  const _TorPill();

  @override
  Widget build(BuildContext context) =>
      EBadge.tor(context.l10n.sendOverTor, way: TorWay.overTor);
}

/// A round tile with the contact's initial, or a person for a new recipient.
class _Initial extends StatelessWidget {
  const _Initial({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Its first letter: brackets, punctuation and emoji never show.
    final letter = nameInitials(name ?? '', count: 1);
    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.surfaceHi,
          shape: BoxShape.circle,
          border: Border.all(color: t.lineStrong),
        ),
        child: letter.isEmpty
            ? Icon(Icons.person_outline, size: 20, color: t.dim)
            : Text(
                letter,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: t.text),
              ),
      ),
    );
  }
}

/// "To Bob" above the amount.
class _ToChip extends StatelessWidget {
  const _ToChip({required this.address, this.name});

  final String address;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 14, 4),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(scale: 0.8, child: _Initial(name: name)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              context.l10n.sendTo(name ?? shortAddress(address)),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: t.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// One recent recipient: their name where known, else the short address.
class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.address, this.name, this.subtitle, required this.onTap});

  final String address;
  final String? name;

  /// Words in place of the short address (a contact paid through its pairing).
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 52,
      leading: _Initial(name: name),
      title: Text(
        name ?? shortAddress(address),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(color: t.text),
      ),
      subtitle: name == null
          ? null
          : subtitle != null
          ? Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: t.dim))
          : Text(
              shortAddress(address),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: t.dim,
                fontFamily: t.monoFamily,
              ),
            ),
      onTap: onTap,
    );
  }
}

/// The review's checks of [SendPreflight] as one quiet line: "Ready to send" when they
/// pass, else the one that matters most. Only the node blocks. Over Tor ([tor] given) the
/// line says what tor is doing instead of the epicbox checks: it connects when Send is
/// tapped, then reaches the other wallet, which can take a while.
class _ReadyLine extends ConsumerWidget {
  const _ReadyLine({
    required this.checks,
    required this.sending,
    required this.failed,
    this.tor,
    this.http = false,
    this.way = TorWay.clearnet,
    this.queued = false,
  });

  /// A mailbox payment waits in the outbox while Epicbox is off: the listener being down is
  /// expected then, and the review's card says what happens.
  final bool queued;

  /// How the payment's connection goes with the Tor switch as it is.
  final TorWay way;

  /// The payment goes straight to a wallet URL: no epicbox checks, and its own words while
  /// it is under way.
  final bool http;

  final SendPreflight checks;

  /// The send runs; with a relay that hangs it can take a quarter of a minute.
  final bool sending;

  /// What a send that failed at their relay left behind, in words; null when none failed.
  final String? failed;

  /// Tor's state when the payment goes over Tor; null for an epicbox payment.
  final PhoneTorState? tor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final relayDown = checks.relayOutcome == CheckOutcome.failed;
    final failed = this.failed;
    final spinner = MediaQuery.disableAnimationsOf(context)
        ? Icon(Icons.hourglass_empty, size: 18, color: t.dim)
        : const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
    // While the send runs the button turns (BusyButton), as every busy button in the app does:
    // the line keeps its words beside a still glyph, so one thing moves at a time.
    final still = Icon(Icons.hourglass_empty, size: 18, color: t.dim);
    final running =
        checks.node == CheckOutcome.running ||
        checks.relayOutcome == CheckOutcome.running;
    final tor = this.tor;
    void retryNode() => ref.invalidate(sendNodeCheckProvider);
    void retryTor() => ref.read(phoneTorProvider.notifier).retry();
    final (
      Widget icon,
      String text,
      Color color,
      VoidCallback? retry,
    ) = switch (()) {
      _ when sending && tor != null => (
        still,
        tor.canSend ? l.sendTorReaching : l.torStateStarting(tor.progress ?? 0),
        t.dim,
        null,
      ),
      _ when sending && http => (still, l.sendHttpReaching, t.dim, null),
      _ when sending => (still, l.sendSending, t.dim, null),
      _ when failed != null => (
        Icon(Icons.warning_amber, size: 18, color: t.warn),
        failed,
        t.text,
        null,
      ),
      _ when checks.node == CheckOutcome.failed => (
        Icon(Icons.error_outline, size: 18, color: t.risk),
        l.sendNodeDown,
        t.text,
        retryNode,
      ),
      _ when relayDown => (
        Icon(Icons.warning_amber, size: 18, color: t.warn),
        l.sendRelayDown(checks.relay?.label ?? ''),
        t.text,
        null,
      ),
      // A still icon under reduced motion, where a spinner would be an animation.
      _ when running => (spinner, l.sendChecking, t.dim, null),
      _ when way == TorWay.wait => (spinner, l.torWaiting, t.dim, null),
      _ when way == TorWay.blocked => (
        Icon(Icons.error_outline, size: 18, color: t.risk),
        l.torNotConnectedNotice,
        t.text,
        retryTor,
      ),
      _ when way == TorWay.needsTor => (
        Icon(torIcon, size: 18, color: t.dim),
        l.torNeeds,
        t.text,
        null,
      ),
      _ when tor != null => (
        Icon(Icons.check, size: 18, color: t.ok),
        l.sendTorReady,
        t.dim,
        null,
      ),
      _ when http => (
        Icon(Icons.check, size: 18, color: t.ok),
        l.sendReady,
        t.dim,
        null,
      ),
      _ when checks.listener == CheckOutcome.failed && !queued => (
        Icon(Icons.sync_problem, size: 18, color: t.warn),
        l.sendListenerDown,
        t.dim,
        () => ref.read(listenerProvider.notifier).restart(),
      ),
      _ => (Icon(Icons.check, size: 18, color: t.ok), l.sendReady, t.dim, null),
    };
    return Semantics(
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            ExcludeSemantics(
              child: SizedBox(width: 20, child: Center(child: icon)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
            if (retry != null)
              TextButton(onPressed: retry, child: Text(l.commonRetry)),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.sub,
    this.exact,
    this.strong = false,
    this.mono = true,
  });

  final String label;
  final String value;

  /// A dim second line under the value (the fiat estimate).
  final String? sub;

  /// The exact amount behind [value], shown on a tap.
  final BigInt? exact;

  final bool strong;

  /// The value is a figure, in the mono face; false for words.
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: strong ? t.text : t.dim,
      fontWeight: strong ? FontWeight.w600 : null,
    );
    Widget figure = Text(
      value,
      textAlign: TextAlign.end,
      style: mono ? style?.copyWith(fontFamily: t.monoFamily) : style,
    );
    if (exact case final exact?) {
      figure = exactAmountTip(context, exact, hidden: false, child: figure);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                figure,
                if (sub case final sub?)
                  Text(
                    sub,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
