// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import '../help/help_content.dart' show HelpAnchor;
import '../trust_ids.dart';
import 'file_flow_pages.dart';
import 'kit/kit_amount.dart';
import 'kit/kit_avatar.dart';
import 'kit/kit_chip.dart';
import 'kit/kit_keypad.dart';
import 'kit/kit_button.dart';
import 'kit/kit_faces.dart';
import 'kit/kit_group.dart';
import 'kit/kit_row.dart';
import 'kit/kit_search_field.dart';
import 'kit/kit_sheet.dart';
import 'kit/kit_tokens.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_hero_amount.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_kv.dart';
import 'kit/kit_result_mark.dart';
import 'kit/kit_step_strip.dart';
import 'kit/kit_support.dart' show kitId;
import 'kit/kit_steps.dart';
import 'payment_progress.dart';
import 'send_help_sheet.dart';
import 'tx_details_screen.dart';
import 'app_dialog.dart';
import 'cancel_note.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../app_log.dart';
import '../amount.dart';
import '../cancel_final.dart' show relayCancelFirst;
import '../contacts.dart';
import '../name_service/link_open.dart' show LinkOpened;
import '../name_service/pins.dart' show NameServiceTrust;
import '../scan/incoming_link.dart' show linkClockProvider;
import '../trust/trust_providers.dart' show mailboxDefaultFor;
import 'link_send.dart';
import '../epic1.dart' show looksLikeEpic1Link;
import 'epic1/epic1_common.dart' show openEpic1Settings;
import 'epic1/epic1_send.dart';
import 'in_person/in_person_entry.dart' show openPayInPerson;
import 'theme/epic1_mark.dart';
import '../pairing_providers.dart'
    show PairNet, contactPairingProvider, pairNetProvider, pairingApiProvider, pairingByIdProvider, pairingName, pairingNameProvider, pairingSupportedProvider, pairingsProvider;
import '../errors.dart';
import '../initials.dart';
import '../name_service/payment_refusals.dart' show paymentRefusalsProvider;
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
import '../invite_links.dart' show parseInvite;
import '../scan/incoming_link.dart' show linkBusyProvider;
import '../scan/scan_checks.dart';
import '../scan/scan_router.dart';
import '../scan/scan_text.dart' show noteExpected, noteWarning;
import '../send_amount_gate.dart';
import '../send_reach.dart';
import '../send_route.dart';
import 'network_mode_phone.dart' show chooseNetworkMode;
import 'send_route_text.dart';
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
import 'devices/device_parts.dart' show phoneDevicesEpicboxOffProvider;
import 'centered_body.dart';
import '../address_field.dart';
import '../address_format.dart' show addressSpan;
import 'address_view.dart';
import 'common.dart';
import 'contacts_screen.dart';
import 'file_exchange_help.dart';
import 'handshake.dart';
import 'home_parts.dart' show outputsShown;
import 'help_screen.dart';
import 'method_strip.dart';
import 'pairing/pair_check.dart' show CheckWordsScreen;
import 'pairing/pairing_parts.dart';
import 'pairing/send_pairing.dart';
import '../pairing_file_seal.dart' show fileSealTarget, sealQuiet;
import '../pairing_text.dart' show sendRoutePairedLineOf;
import 'status_icons.dart';
import 'net_block.dart';
import 'payment_gate.dart';
import 'pin.dart' show showPinSheet, usesPassphrase;
import 'qr_scan_screen.dart';
import 'payment_code_ui.dart';
import 'qr_show_screen.dart';
import 'scan_route.dart';
import 'scan_screen.dart';
import 'shell_header.dart' show comingIn;
import 'send_tracker.dart';
import 'slate_file_screen.dart';
import 'theme/brand.dart';
import 'theme/advanced.dart';
import 'theme/tokens.dart';
import 'tor_ui.dart';
import 'tour/tour_target.dart';
import '../settings_file/host_settings.dart' show appConfig, hostSettings;
import 'settings_rows.dart' show RadioRow;
import 'inline_button.dart';
import 'kit/kit_qr_glyph.dart';

export '../utf8_limit.dart';

// Sending, in three steps: the recipient, the amount, a review with quiet checks; then a
// tracker that follows the payment as both wallets finish it. There is no method picker: the
// method follows the recipient field (an Epicbox address, an http(s) or onion address, or a
// contact's address), and one line under the field names it with the host as contacted
// (send_route.dart). Pay in person (QR) and Pay with a file are their own route, also the
// fallback when their relay does not answer.

/// The key of the Epicbox-not-connected card on the method step, for tests.
const Key sendEpicboxDownKey = ValueKey('send-epicbox-down');

/// Each step's fields have their own key, so a step never takes over another's text field:
/// on the web, Flutter keeps one DOM element per field and cannot turn the address's
/// multi-line one into a number input.
const Key sendRecipientFieldKey = ValueKey('send-recipient-field');
const Key sendAmountFieldKey = ValueKey('send-amount-field');

/// The amount page's Review button, for tests.
const Key sendReviewButtonKey = ValueKey('send-review-button');
const Key sendFileAmountFieldKey = ValueKey('send-file-amount-field');

/// "Not enough spendable EPIC…" under the amount, said on the keystroke.
const Key sendNotEnoughKey = ValueKey('send-not-enough');

/// The × in the filled To field, for tests.
const Key sendRecipientClearKey = ValueKey('send-recipient-clear');
const Key sendNoteFieldKey = ValueKey('send-note-field');
const Key sendNoteMissingKey = ValueKey('send-note-missing');
const Key sendReviewNoteMissingKey = ValueKey('send-review-note-missing');
const Key sendBelowMinimumKey = ValueKey('send-below-minimum');
const Key sendReviewBelowMinimumKey = ValueKey('send-review-below-minimum');

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

/// "Send to their public Epicbox address" on the review after a failed pairing send, for tests.
const Key sendPublicFallbackKey = ValueKey('send-public-fallback');

/// The review's card that a mailbox payment waits while Epicbox is off, and the tracker's
/// "Payment queued", for tests.
const Key sendQueuedCardKey = ValueKey('send-queued-card');
const Key sendQueuedHeadlineKey = ValueKey('send-queued-headline');

/// The off-note's Turn on button, under a Link method switched off.
const Key sendTurnOnMethodKey = ValueKey('send-turn-on-method');

/// The Smallest / All choice for this payment, shown with Advanced › Send options.
const Key sendStrategyKey = ValueKey('send-strategy');

/// The connection a payment to [to] takes, for the Tor switch ([torWay]). Plain `http://` to
/// another device is a route of its own: it never goes through a Tor exit.
TorRoute sendRoute(Recipient to) => switch (to.kind) {
  // An epic1 link is paid through the Epicbox servers it names.
  RecipientKind.epicbox || RecipientKind.epic1 => TorRoute.epicbox,
  RecipientKind.http when plainHttpToOtherDevice(to.address) => TorRoute.plainHttpDirect,
  RecipientKind.http => TorRoute.httpDirect,
  RecipientKind.tor => TorRoute.onionDirect,
};

/// Send's notice under To and the Tor buttons in it, for tests.
const Key sendTorNoticeKey = ValueKey('send-tor-notice');
const Key sendTurnOffTorKey = ValueKey('send-turn-off-tor');

/// The caption under Turn Tor off: it is the switch for every connection (D-05).
const Key sendTurnOffTorCaptionKey = ValueKey('send-turn-off-tor-caption');

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
  const SendView({super.key, required this.onDone, this.back});

  /// The payment is finished or handed to the network: the shell goes back to Wallet and
  /// starts a fresh form.
  final VoidCallback onDone;

  /// Where the shell asks the form to take the Android back.
  final SendBack? back;

  @override
  ConsumerState<SendView> createState() => _SendViewState();
}

/// The Android back on the Send tab: [stepBack] takes the step back the header's arrow takes
/// and says whether the form used it; otherwise the shell goes to Wallet.
class SendBack {
  bool Function()? _handler;

  bool stepBack() => _handler?.call() ?? false;
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
    this.linkLabel,
  });

  /// The payment as the send returned it; the tracker follows it in [homeProvider].
  final TxEntry tx;
  final BigInt amount;
  final Recipient to;

  /// Sent through the mailbox of this pairing (a contact with no address; [to] is empty).
  final String? pairingId;

  /// Made while Epicbox was off: it waits in the outbox until Epicbox is on again.
  final bool queued;

  /// The payee's `@name` from the payment link this was sent from, for Save as contact.
  final String? linkLabel;

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
  final _recipient = AddressFieldController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _response = TextEditingController();
  final _recipientFocus = FocusNode();
  final _amountFocus = FocusNode(skipTraversal: true);
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
  /// When the payment file was first shown, for its "made 18:12" line.
  DateTime? _fileMadeAt;

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

  /// The review's "More details" is open.
  bool _reviewMore = false;

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

  /// The method the address way sends by, from the To field: Link for an http(s) or onion
  /// address, else Epicbox (also for a pairing's mailbox). File and QR are their own route
  /// ([SendStage.fileAmount] and after), so this is never [TransferMethod.file] or
  /// [TransferMethod.qr].
  TransferMethod get _method => _pairingTo == null && _read.isLink ? TransferMethod.direct : TransferMethod.epicbox;

  /// [text] read as Send's recipient ([readRecipient]).
  RecipientInput _readOf(String text) =>
      readRecipient(text, defaultRelay: hostSettings.epicboxUse, listenPort: appConfig.httpListenPort);

  /// The To field read as a recipient.
  RecipientInput get _read => _readOf(_recipient.text);

  /// The file route is the QR way: the payment is shown as an animated code to the phone next
  /// to this one, and the reply is scanned.
  bool _viaQr = false;

  /// The To text at the last change, to tell a paste (8 or more characters at once).
  String _lastTo = '';

  /// The field was left, pasted into or submitted: its errors show and a Link address is
  /// asked once whether a wallet answers. Typing clears it.
  bool _touched = false;

  /// The contact picked (Contacts, a name match, Recent): To shows its chip and holds the
  /// address in use, one of [Contact.addresses]; Change picks another.
  Contact? _contact;

  /// The reach check's answers, per clean address; asked once each, again on Try again.
  final Map<String, ReachResult> _reach = {};

  /// Addresses being asked now, and those with no answer after [_reachSlowAfter].
  final Set<String> _reachAsking = {};
  final Set<String> _reachSlow = {};

  /// The check running per address, for Review to wait on.
  final Map<String, Future<void>> _reachRuns = {};
  static const Duration _reachSlowAfter = Duration(milliseconds: 1500);

  /// Send's PIN dialog is open.
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

  /// The payment link that filled this form; it holds while To keeps its address
  /// ([_requestAddress]), as a payment code does.
  LinkOpened? _link;

  /// A payment link handed over meanwhile, for the next form.
  ({LinkOpened link, CodeOrigin origin})? _laterLink;

  /// [_link] while the To field still holds its address, else null.
  LinkOpened? get _activeLink {
    final link = _link;
    if (link == null) return null;
    return parseRecipient(_recipient.text).address == _requestAddress ? link : null;
  }

  /// [_request] while the To field still holds its address, else null.
  PaymentRequest? get _activeRequest {
    final request = _request;
    if (request == null) return null;
    return parseRecipient(_recipient.text).address == _requestAddress
        ? request
        : null;
  }

  /// Why the amount step and the review warn that the message is empty, or null. The user may
  /// send anyway.
  String? _noteWarning(AppLocalizations l) =>
      noteWarning(l, _read.isAddress ? _read.address : _recipient.text.trim(), _note.text, codeAsks: _activeRequest?.noteRequired ?? false);

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
    final link = _link;
    if (link != null) {
      final amount = link.request.amount;
      if (amount > BigInt.zero && _parsedAmount == amount && !_fiatEntry) {
        _amount.clear();
        _parsedAmount = null;
        _estimate = null;
      }
    }
    _link = null;
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

  /// A note that is written and left becomes the chip again (Send-2's "Tickets").
  void _noteFocusChanged() {
    if (!mounted || _noteFocus.hasFocus || !_noteOpen || _note.text.trim().isEmpty) return;
    setState(() => _noteOpen = false);
  }

  @override
  void initState() {
    super.initState();
    widget.back?._handler = _stepBack;
    _recipientFocus.addListener(_recipientFocusChanged);
    _noteFocus.addListener(_noteFocusChanged);
    final handoff = ref.read(sendRecipientProvider);
    if (handoff != null && handoff.pairingId != null) {
      _handoff = handoff.id;
      _pairingTo = handoff.pairingId;
    } else if (handoff != null && handoff.link != null) {
      _handoff = handoff.id;
      final link = handoff.link!;
      final to = parseRecipient(link.request.card.address);
      _recipient.text = to.address;
      _lastTo = to.address;
      _origin = handoff.origin;
      _requestAddress = to.address;
      _link = link;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fillFromLink(link);
      });
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
      if (request != null) {
        // The amount is written in the user's number format, which needs the locale.
        final origin = handoff.origin ?? CodeOrigin.qr;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _applyRequest(request, origin);
        });
      } else {
        _origin = handoff.origin;
        _requestAddress = handoff.origin == null ? null : to.address;
        // An address handed over whole is as settled as one pasted: it shows in its box.
        _touched = recipientShaped(to);
        // A saved contact's address (Send from the contact): the same state as picking its
        // face on Send, the chip in To and the amount next.
        final saved = handoff.origin == null ? contactFor(ref.read(contactsProvider).value ?? const <Contact>[], to.address) : null;
        if (saved != null) {
          _contact = saved;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _toAmount();
          });
        }
      }
    }
    ref.listenManual(
      appSettingsProvider.select((s) => s.value?.payments),
      (_, payments) => _paymentsChanged(payments),
    );
    // Settings › Transactions: which methods are on. A recipient handed over wins; the
    // settings load on their own, so a form still untouched takes them when they arrive.
    if (handoff == null || (handoff.pairingId == null && !recipientShaped(parseRecipient(handoff.text)))) {
      _startOn(_phoneStart(ref.read(appSettingsProvider).value?.payments));
      if (!_startApplied) {
        ref.listenManual(
          appSettingsProvider.select((s) => _phoneStart(s.value?.payments)),
          (_, start) {
            if (start == null || _startApplied || !mounted) return;
            if (_stage != SendStage.recipient ||
                _recipient.text.isNotEmpty ||
                _pairingTo != null) {
              return;
            }
            setState(() => _startOn(start));
          },
        );
      }
    }
  }

  bool _startApplied = false;

  /// Where the phone's Send starts: the recipient step, whatever Default method an older
  /// install stored (the phone has no setting for it; the value stays stored for the desktop and
  /// is never read here). Only with no address method on does it open on the first one that is
  /// (QR Payment, then File Transfer), else on the recipient step, which says Epicbox is off.
  MethodKind? _phoneStart(PaymentPrefs? payments) {
    if (payments == null) return null;
    if (payments.epicbox || payments.linkHttp || payments.linkTor) return MethodKind.epicbox;
    return payments.on.firstOrNull ?? MethodKind.epicbox;
  }

  /// A method switched off in Settings › Transactions while Send is open: an idle form moves to
  /// the method Send starts on now, as after a restart. An address in To keeps its method,
  /// with the note that it is off.
  void _paymentsChanged(PaymentPrefs? payments) {
    if (payments == null || !mounted || _holdsPayment || _formOffered(payments)) return;
    setState(() {
      _stage = SendStage.recipient;
      _viaQr = false;
      _error = null;
      _startOn(_phoneStart(payments));
    });
  }

  /// Whether the route the idle form shows is still on in [payments]. The recipient step has
  /// no method of its own: an address in To keeps its method, with the note that it is off.
  bool _formOffered(PaymentPrefs payments) {
    if (_stage == SendStage.fileAmount) {
      return payments.offers(_viaQr ? MethodKind.directQr : MethodKind.directFile);
    }
    return true;
  }

  /// Opens the form on [start], the method Settings › Transactions chose (null: not loaded).
  /// Epicbox and Link start on the recipient step, whose field picks the method.
  void _startOn(MethodKind? start) {
    if (start == null) return;
    _startApplied = true;
    switch (start) {
      case MethodKind.directFile:
        _stage = SendStage.fileAmount;
      case MethodKind.directQr:
        _stage = SendStage.fileAmount;
        _viaQr = true;
      case MethodKind.epicbox || MethodKind.linkHttp || MethodKind.linkTor:
        break;
    }
  }

  @override
  void dispose() {
    if (widget.back?._handler == _stepBack) widget.back?._handler = null;
    _debounce?.cancel();
    _checks?.close();
    _recipient.dispose();
    _amount.dispose();
    _note.dispose();
    _response.dispose();
    _recipientFocus.dispose();
    _amountFocus.dispose();
    _noteFocus.dispose();
    sendHoldsPayment(this, false);
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
    if (_pairingTo != null) return _noPaymentsProblem(pairingId: _pairingTo);
    if (text.trim().isEmpty) return required ? l.sendAddressMissing : null;
    // An epic1 address alone names no server and cannot be paid. A link opens the epic1 flow
    // while epic1 is on; off, the switch is in Settings (button under the field).
    if (epic1AddressOnly(text)) return l.epic1AddressAlone;
    if (looksLikeEpic1Link(text)) return ref.read(epic1OnProvider) ? null : _epic1OffLine;
    final read = _readOf(text);
    switch (read.kind) {
      case RecipientInputKind.empty:
        return required ? l.sendAddressMissing : null;
      // A transaction text: its own notice offers to open it, never an error.
      case RecipientInputKind.slate:
        return null;
      // Words: a contact's name while one matches.
      case RecipientInputKind.text:
        return _nameMatches(text, watch: false).isNotEmpty ? null : l.sendProblemNotAddress;
      case RecipientInputKind.invalid:
        return sendProblemText(l, read.problem ?? RecipientProblem.incomplete);
      case RecipientInputKind.https || RecipientInputKind.http:
        return httpAddressComplete(read.address) ? null : l.sendProblemIncomplete;
      case RecipientInputKind.onion:
        if (!torBuilt) return l.sendTorNotInVersion;
        if (ref.read(phoneTorProvider).phase == PhoneTorPhase.unavailable) return l.sendTorUnavailable;
        // An onion with a typo: the check's own sentence says so.
        return ref.read(walletServiceProvider).validateOnionAddress(address: read.address) ? null : l.sendOnionIncomplete;
      case RecipientInputKind.epicbox:
        if (_isOwnAddress(read)) return l.sendProblemOwn;
        if (_noPaymentsProblem(address: read.address) case final stop?) return stop;
        return ref.read(walletServiceProvider).validateEpicboxAddress(address: read.address)
            ? null
            : (read.key ?? '').length < 52
            ? l.sendAddressIncomplete
            : l.sendAddressNotEpic;
    }
  }

  /// The stop for a contact that takes no payments, by its pairing or its Epicbox address:
  /// "‹name› takes no payments." under To, and Continue stays off.
  String? _noPaymentsProblem({String? pairingId, String? address}) {
    final refusals = ref.read(paymentRefusalsProvider);
    return refusals.refusesPayments(pairingId: pairingId, address: address)
        ? context.l10n.contactNoPaymentsNamed(refusals.refusedName(pairingId: pairingId, address: address) ?? '')
        : null;
  }

  /// [to] is this wallet's own Epicbox address: the key the same (case counts) and the relay
  /// this wallet's.
  bool _isOwnAddress(RecipientInput to) {
    final own = ref.read(addressProvider).value;
    if (own == null || own.isEmpty || to.kind != RecipientInputKind.epicbox) return false;
    final mine = _readOf(own);
    return mine.key == to.key && mine.host == to.host;
  }

  /// The field was left: errors show now. The field keeps what was given; the method line shows
  /// the address as it will be contacted.
  void _recipientFocusChanged() {
    if (_recipientFocus.hasFocus || _stage != SendStage.recipient) return;
    if (_contact != null || _recipient.text.trim().isEmpty) return;
    setState(() {
      _settleRecipient();
      _recipientError = _recipientProblem(_recipient.text);
    });
  }

  /// To is settled: the reach check may ask. The text stays as given (the parser reads its
  /// clean form). Call inside setState.
  void _settleRecipient() => _touched = true;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    _openText(text, CodeOrigin.paste);
  }

  /// A scanned or pasted text: a payment code fills the form, an address the To field (as
  /// given), and anything the router knows elsewhere goes
  /// there. A transaction text lands in the field with its "Open it" notice unless [open] (that
  /// button). Plain text that is none of these (a name, half an address) lands in the To field,
  /// where its own check speaks. [typedOver] is the To text before the code was typed or pasted
  /// into the field: a code that opens a sheet puts it back, so the field never keeps the code
  /// behind the sheet.
  void _openText(String text, CodeOrigin origin, {String? typedOver, bool open = false}) {
    final l = context.l10n;
    // An invite page's link (the inviter's QR, Share invite) is read as the bare invite, as
    // Home's scan reads it.
    final invite = parseInvite(text);
    if (invite != null) text = invite.invite;
    if (looksLikeEpic1Link(text)) {
      unawaited(_openEpic1(text, typedOver: typedOver));
      return;
    }
    final code = classifyFor(ref.read(walletServiceProvider), text);
    final read = _readOf(text);
    switch (code) {
      case PaymentRequest() when requestCarriesMore(code):
        _applyRequest(code, origin);
      case PaymentRequest(:final recipient) || ScannedAddress(:final recipient):
        // A code with a second address fills the one whose method is on.
        final to = code is PaymentRequest ? _requestRecipient(code) : recipient;
        _setRecipient(to.address, origin: origin, given: code is ScannedAddress ? text : null);
      case PaymentLink():
        unawaited(_openLink(code, origin, typedOver: typedOver));
      case SlateText() when !open && origin == CodeOrigin.paste:
        _setRecipient(text);
      // An address in text around it, or written another way: Send's own reader takes it.
      case UnknownCode() when read.isAddress && origin != CodeOrigin.link:
        _setRecipient(read.address, origin: origin == CodeOrigin.paste ? null : origin, given: text);
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

  /// The connection a payment to [to] takes, for the Tor switch: Epicbox's, an onion's, an
  /// https address's; null for plain http, which never goes over Tor (the mode holds it or it
  /// goes direct, [sendHoldFor]) and for anything that is no address.
  TorRoute? _routeOf(RecipientInput to) => switch (to.kind) {
    RecipientInputKind.epicbox => TorRoute.epicbox,
    RecipientInputKind.onion => TorRoute.onionDirect,
    RecipientInputKind.https => TorRoute.httpDirect,
    _ => null,
  };

  /// The connection the To text takes; Epicbox for a pairing's mailbox.
  TorRoute? get _toRoute => _pairingTo != null ? TorRoute.epicbox : _routeOf(_read);

  /// An onion with Tor off still goes: Send starts Tor for it ([PhoneTor.whileSending]).
  static bool _goes(TorWay way) => torGoes(way) || way == TorWay.needsTor;

  /// The Tor switch's state, watched: for build only.
  TorState get _torState => phoneTorState(ref.watch(phoneTorProvider));

  /// How [route] goes with the Tor switch at [state] (now, watched, by default); clearnet for
  /// no route.
  TorWay _wayOf(TorRoute? route, [TorState? state]) =>
      route == null ? TorWay.clearnet : torWay(route, state ?? _torState);

  /// The way a connection problem leaves: Pay in person (a QR Payment, where this phone
  /// offers it) and Pay with a file, each while its method is on.
  bool get _qrOffered => _watchedPayments.directQr && offersQrPayment(ref);

  bool get _fileOffered =>
      _watchedPayments.directFile || hasPendingFileSend(ref.watch(homeProvider.select((h) => h.value?.transactions)));

  Future<void> _scan() async {
    final text = await ref.read(qrScannerProvider).scanCode(context);
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
      _laterLink = null;
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

  /// Fills the form from an opened payment link: the listing address (Epicbox) and the amount,
  /// which stays editable; a link with no amount leaves it to the payer. Nothing is sent.
  void _applyLink(LinkOpened link, CodeOrigin origin) {
    if (_holdsPayment) {
      _laterLink = (link: link, origin: origin);
      _laterRequest = null;
      _laterRecipient = null;
      _laterPairing = null;
      return;
    }
    if (_stage == SendStage.fileAmount) {
      _viaQr = false;
      _stage = SendStage.recipient;
    }
    _setRecipient(link.request.card.address, origin: origin);
    _link = link;
    _requestAddress = parseRecipient(link.request.card.address).address;
    _fillFromLink(link);
  }

  /// The amount from [link]; then on to the amount step, as a payment code does.
  void _fillFromLink(LinkOpened link) {
    setState(() {
      _requestBanner = false;
      _fiatEntry = false;
      _maxUsed = false;
      final amount = link.request.amount;
      _amount.text = amount > BigInt.zero ? localDecimal(context.l10n, formatEpic(amount)) : '';
      _parsedAmount = amount > BigInt.zero ? amount : null;
      _amountError = null;
      _estimate = null;
    });
    if (_amount.text.isNotEmpty) _onAmountChanged(_amount.text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _link != link) return;
      if (_stage == SendStage.recipient && _recipientError == null && _block == NetBlock.none) {
        _toAmount(focus: false);
      }
    });
  }

  /// A payment link from a scan or paste inside Send: checked, then it fills the form.
  Future<void> _openLink(PaymentLink code, CodeOrigin origin, {String? typedOver}) async {
    if (typedOver != null) {
      _recipient.text = typedOver;
      _lastTo = typedOver;
    }
    final link = await openPaymentLink(context, ref, code);
    if (link != null && mounted) _applyLink(link, origin);
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

  /// The pairing a contact with no address is paid through, when the wallet pairs.
  PairingRecord? _pairingOnly(Contact contact, {bool watch = false}) {
    if (contact.addresses.isNotEmpty) return null;
    if (!(watch ? ref.watch(pairingSupportedProvider) : ref.read(pairingSupportedProvider))) return null;
    return watch ? ref.watch(contactPairingProvider(contact.id)) : ref.read(contactPairingProvider(contact.id));
  }

  /// What holds a send to [to] now: the network mode ([sendHoldFor]). Read in a build.
  SendHold? _holdOf(RecipientInput to) => sendHoldFor(
    to,
    mode: AdvancedOptions.of(context).networkMode,
    torOn: ref.watch(phoneTorProvider.select((s) => s.receiving)),
  );

  /// [to] cannot be paid now: the mode holds it, or its method is off in Settings ›
  /// Transactions. For a contact's addresses.
  bool _heldNow(RecipientInput to, {bool watch = true}) {
    final mode = AdvancedOptions.of(context).networkMode;
    final torOn = watch ? ref.watch(phoneTorProvider.select((s) => s.receiving)) : ref.read(phoneTorProvider).receiving;
    if (sendHoldFor(to, mode: mode, torOn: torOn) != null) return true;
    final kind = sendMethodKind(to);
    return kind != null && !(watch ? _watchedPayments : _payments.copyWith(linkHttp: true)).offers(kind);
  }

  /// The index in [contact]'s addresses Send uses first: the one last paid successfully
  /// ([lastPaidAddress]) when it can be paid now, else the best by method ([bestAddressIndex]).
  int _bestIndex(Contact contact, {bool watch = true}) {
    final txs = (watch ? ref.watch(homeProvider) : ref.read(homeProvider)).value?.transactions ?? const <TxEntry>[];
    final paid = contact.addresses.length > 1 ? lastPaidAddress(contact, txs) : null;
    if (paid != null) {
      final i = contact.addresses.indexOf(paid);
      final to = _readOf(paid);
      if (i >= 0 && to.isAddress && !_heldNow(to, watch: watch)) return i;
    }
    return bestAddressIndex(contact.addresses, read: _readOf, held: (to) => _heldNow(to, watch: watch));
  }

  /// "epic1 is off in the payment settings.", the line under To for an epic1 link while the
  /// switch is off.
  String get _epic1OffLine => context.l10n.netBlockMethodOff(context.l10n.deskE1SetSwitch);

  /// To holds an epic1 link that names a server and epic1 is on: Continue pays it through the
  /// epic1 flow.
  bool get _epic1LinkInTo {
    final text = _recipient.text;
    return _pairingTo == null && looksLikeEpic1Link(text) && !epic1AddressOnly(text) && ref.read(epic1OnProvider);
  }

  /// An epic1 link typed, pasted or scanned into Send: epic1 on, the epic1 pay flow opens (the
  /// field goes back to what it held and is cleared after a payment); an address alone or
  /// epic1 off, the text stays in To with its line.
  Future<void> _openEpic1(String text, {String? typedOver}) async {
    if (typedOver != null) {
      _recipient.text = typedOver;
      _lastTo = typedOver;
    }
    if (epic1AddressOnly(text)) {
      _pastedWithError(text, context.l10n.epic1AddressAlone);
      return;
    }
    if (!ref.read(epic1OnProvider)) {
      _pastedWithError(text, _epic1OffLine);
      return;
    }
    final done = await openEpic1LinkSend(context, text);
    if (done && mounted) {
      setState(() {
        _recipient.clear();
        _lastTo = '';
        _recipientError = null;
      });
    }
  }

  /// [contact] as the recipient: its chip in To and its first address that can be paid now,
  /// or its pairing. [address], one of its addresses, is used instead when given (Recent).
  void _useContact(Contact contact, {String? address}) {
    if (_pairingOnly(contact) case final pairing?) {
      _setPairing(pairing.id);
      return;
    }
    final i = _bestIndex(contact, watch: false);
    final use = address ?? (i < 0 ? contact.address : contact.addresses[i]);
    _setRecipient(_readOf(use).isAddress ? _readOf(use).address : use, contact: contact);
  }

  /// Change on the method line: another of the contact's addresses. Only the method line
  /// follows.
  void _pickAddress(String address) {
    final contact = _contact;
    if (contact == null) return;
    _setRecipient(_readOf(address).isAddress ? _readOf(address).address : address, contact: contact);
  }

  /// The recipient is the pairing [id], a contact with no address: its card takes the To
  /// field's place and the payment goes through its mailbox. Over a payment in progress, the
  /// next form takes it.
  void _setPairing(String id) {
    if (_holdsPayment) {
      _laterPairing = id;
      _laterRecipient = null;
      _laterRequest = null;
      _laterLink = null;
      return;
    }
    _closeChecks();
    setState(() {
      _recipient.clear();
      _lastTo = '';
      _leaveRequest();
      _pairingTo = id;
      _contact = null;
      _touched = false;
      _viaMailboxChoice = null;
      _viaQr = false;
      // Not held (above): the amount, the review or the file route go back to the recipient.
      _stage = SendStage.recipient;
      _recipientError = null;
      _error = null;
    });
  }

  /// × on the filled To field, the contact chip or the pairing card. Leaving Send keeps the
  /// draft (people switch tabs to check the balance), so a filled recipient always has this
  /// way out: the recipient goes with everything that followed from it (a code's untouched
  /// amount and note, the warnings), back to step 1's empty start. Amount and note typed by
  /// hand stay.
  void _clearRecipient() {
    _closeChecks();
    setState(() {
      _recipient.clear();
      _lastTo = '';
      _leaveRequest();
      _pairingTo = null;
      _contact = null;
      _touched = false;
      _viaMailboxChoice = null;
      _recipientError = null;
      _error = null;
      _viaQr = false;
      _stage = SendStage.recipient;
      _startOn(_phoneStart(_payments));
    });
  }

  /// Fills the recipient and checks it at once, as after a paste. An address stays as given
  /// ([given], the text as pasted or scanned); the method line shows its clean form. [contact]
  /// puts its chip in To.
  void _setRecipient(String text, {CodeOrigin? origin, String? given, Contact? contact}) {
    if (_holdsPayment) {
      // Not over a payment in progress, or one a refused send holds: the next form takes
      // it, so Send again cannot make a second payment meanwhile.
      _laterRecipient = text;
      _laterOrigin = origin;
      _laterRequest = null;
      _laterLink = null;
      _laterPairing = null;
      return;
    }
    final read = _readOf(text);
    final clean = read.isAddress ? read.address : (read.kind == RecipientInputKind.slate ? text : text.trim());
    // The field keeps what was given; a contact's address is its own.
    final shown = contact != null || read.kind == RecipientInputKind.slate ? clean : (given ?? text).trim();
    _pairingTo = null;
    _recipient.text = shown;
    _lastTo = shown;
    if (_stage == SendStage.amount || _stage == SendStage.review) {
      _closeChecks();
      _stage = SendStage.recipient;
    }
    setState(() {
      _leaveRequest();
      if (origin != null) {
        _origin = origin;
        _requestAddress = clean;
      }
      _contact = contact;
      _touched = true;
      _viaMailboxChoice = null;
      _recipientError = _recipientProblem(_recipient.text);
      _error = null;
    });
  }

  void _saveContact(String address, {String? name}) => Navigator.of(context).push<Contact>(
    MaterialPageRoute<Contact>(
      builder: (_) => ContactEditScreen(address: address, name: name),
    ),
  );

  /// On to the amount; [focus] puts the cursor there (not for a code, whose amount is read
  /// first, with the keyboard down). A hold of the mode keeps the step.
  void _toAmount({bool focus = true}) {
    if (_epic1LinkInTo) {
      unawaited(_openEpic1(_recipient.text.trim()));
      return;
    }
    if (_contact == null && _pairingTo == null) setState(_settleRecipient);
    final problem = _recipientProblem(_recipient.text, required: true);
    final read = _read;
    final held = _pairingTo == null && read.isAddress && _heldNow(read, watch: false);
    setState(() {
      _recipientError = problem;
      _error = null;
      if (problem == null && !held && (_pairingTo != null || read.isAddress)) _stage = SendStage.amount;
    });
  }

  /// The Android back: the step the header's arrow goes to, held like the arrow while the
  /// fee is worked out or the payment is sent. False where the step has no arrow.
  bool _stepBack() {
    final VoidCallback? back = switch (_stage) {
      SendStage.amount || SendStage.fileAmount => _toRecipient,
      SendStage.review when !_sendFailed => _backToAmount,
      _ => null,
    };
    if (back == null) return false;
    if (!_busy && !_estimating) back();
    return true;
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
    // More than can be spent: said at once, and no estimate is asked for it.
    if (valid != null && !_gate.notEnough) {
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
    // The estimate was made for the other strategy: the confirm waits for the new one.
    setState(() {
      _strategyOverride = strategy;
      if (!_maxUsed) _estimate = null;
    });
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

  /// The Max button: a second tap puts Max away, and the amount goes with it.
  Future<void> _max() async {
    if (_maxUsed) {
      _setAmountText('');
      return;
    }
    await _fillMax();
  }

  /// Fills in the largest amount that can be sent now, with its fee (also again when the
  /// balance changed under a Max).
  Future<void> _fillMax() async {
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

  /// The amount against the spendable balance and the estimate made for it
  /// ([SendAmountGate]): Continue, Make payment file and Make payment QR wait for it.
  SendAmountGate get _gate => _gateWith(_estimate);

  SendAmountGate _gateWith(FeeEstimate? estimate) => SendAmountGate.check(
    amount: _parsedAmount?.toInt(),
    spendable: ref.read(homeProvider).value?.summary.spendable.toInt(),
    estimate: estimate == null
        ? null
        : (amount: estimate.amount.toInt(), fee: estimate.fee.toInt()),
    estimateFailed: _estimateError != null,
  );

  bool get _amountReady => _gate.ready && !_estimating;

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
    // The tap asks again: an amount above the spendable balance goes no further.
    if (_gate.notEnough) {
      setState(() {});
      return;
    }
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
      // The wallet at the address must have answered: the amount and review can be reached before the check ends.
      if (!await _reachSettled()) {
        _closeChecks();
        if (mounted) setState(() => _stage = SendStage.recipient);
        return;
      }
      final minimum = ref.read(countedConfirmationsProvider);
      final plan = _maxUsed
          ? (
              estimate: await session.estimateMax(minimumConfirmations: minimum),
              options: null,
            )
          : await _plan(session, amount, minimum);
      final estimate = plan.estimate;
      if (!mounted) return;
      // The fresh estimate must fit what can be spent now, or the review does not open (Max
      // asked for what fits).
      if (!_maxUsed && !_gateWith(estimate).ready) {
        _closeChecks();
        setState(() {
          _estimate = estimate;
          _options = plan.options;
          _estimateError = null;
        });
        return;
      }
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
              l.sendHeldByDevice(epicFor(l, e.value, unit: false), view.nameOf(e.key)),
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

  /// True while the PIN sheet asks: the review sheet and its dim hide under it (Start-5).
  bool _pinShowing = false;

  /// Every send asks the PIN right before money moves (the desktop asks the password). True
  /// once it checked out; false when the user cancelled or the wallet is gone.
  Future<bool> _pinGate(String reason) async {
    final session = ref.read(sessionProvider);
    final config = ref.read(walletConfigProvider);
    if (session == null || config == null) return false;
    final vault = ref.read(vaultProvider);
    // Start-5: the PIN sheet stands alone over the dimmed amount; the review sheet steps aside.
    setState(() => _pinShowing = true);
    final bool? ok;
    try {
      ok = await showPinSheet<bool>(
        context,
        reason: reason,
        action: (pin) async {
          await vault.checkPin(session, config, pin);
          return true;
        },
      );
    } finally {
      if (mounted) setState(() => _pinShowing = false);
    }
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
    // Asked again on the tap: the reviewed amount and its fee must fit what can be spent now.
    if (!_gateWith(reviewed).ready) {
      setState(() {});
      return;
    }
    final l = context.l10n;
    final to = parseRecipient(_recipient.text);
    final link = _activeLink;
    _asking = true;
    try {
      // A listing that now points to another wallet: one more yes, before the PIN.
      if (link != null && link.standing.trust == NameServiceTrust.changedWallet) {
        if (!await confirmChangedWallet(context, link) || !mounted) return;
      }
      final amountText = epicText(l, reviewed.amount);
      if (!await _pinGate(usesPassphrase(ref) ? l.sendPassphraseReason(amountText) : l.phoneSendPinReason(amountText, _toName(l)))) {
        return;
      }
    } finally {
      _asking = false;
    }
    if (!mounted || _stage != SendStage.review || _busy) return;
    // The balance may have moved while the PIN was asked.
    if (!_gateWith(reviewed).ready) {
      setState(() {});
      return;
    }
    if (to.kind == RecipientKind.tor) return _sendTor(reviewed, to);
    if (to.kind == RecipientKind.http) return _sendHttp(reviewed, to);
    // Captured now: after the await the screen may be gone, and home must still refresh.
    final container = ProviderScope.containerOf(context, listen: false);
    // A slow send must not lock the wallet under the user and lose the tracker.
    final hold = ref.read(autoLockHoldProvider.notifier);
    final amount = reviewed.amount;
    final options = _sendOptions;
    final note = _noteText;
    // Through the pairing, sealed (RFC 9.1): a contact with no address, or one whose switch
    // is on (the rule's default, or the user's choice). Read now: the screen may be gone
    // after the await.
    final pairingTo = _pairingTo;
    final mailbox = pairingTo != null ? _toPairing(watch: false) : _addressMailbox(watch: false);
    if (pairingTo != null && mailbox == null) return;
    final pairingApi = ref.read(pairingApiProvider);
    final queued = _queues(watch: false);
    final minimum = ref.read(countedConfirmationsProvider);
    final linkNow = ref.read(linkClockProvider);
    // The payment link, when the address sent to is still the one it filled in.
    final paidLink = link != null && parseRecipient(link.request.card.address).address == to.address ? link : null;
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
            _failedViaMailbox = pairingTo == null && mailbox != null;
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
      // The pin and the paid request id of a link: what "paid before" and "changed wallet" read.
      if (paidLink != null) {
        try {
          await session.recordLinkPayment(paidLink.request, linkNow().millisecondsSinceEpoch ~/ 1000, txId: tx.slateId);
        } catch (error) {
          logWarn('send', 'recording the link payment failed: ${describeError(englishStrings, error)}');
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
            linkLabel: paidLink?.payeeLabel,
            to: to,
            reviewedFee: reviewed.fee,
            noteSaved: noteSaved,
            pairingId: mailbox?.id,
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

  /// After a failed pairing send: the same amount and note to the contact's public Epicbox
  /// address, the one in To. A payment LEPIC holds is cancelled first; the switch goes off
  /// for this recipient, and the send asks for the PIN again.
  Future<void> _sendPublicFallback() async {
    if (_busy || _pairingTo != null) return;
    if (_undelivered != null) {
      await _cancelUndelivered(then: SendStage.review);
      // The cancel failed, or their reply came first: its own buttons say what is next.
      if (!mounted || _undelivered != null || _stage != SendStage.review) return;
      _checks ??= ref.listenManual(sendPreflightProvider(_relay), (_, _) {});
    }
    setState(() {
      _viaMailboxChoice = false;
      _sendFailed = false;
      _failedViaMailbox = false;
      _nothingStored = false;
      _error = null;
    });
    await _send();
  }

  /// Cancels the payment of the file made here (the foot of the made page): its coins are free
  /// again and the file route asks for the amount once more. A file already handed over is
  /// dead then: the other wallet's reply no longer finishes it.
  Future<void> _cancelFile() async {
    final slate = _slate;
    final session = ref.read(sessionProvider);
    if (slate == null || session == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    TxEntry? made;
    try {
      made = (await session.transactions(refresh: true)).where((t) => t.key == 's:${slate.slateId}').firstOrNull;
    } catch (error) {
      if (mounted) setState(() => _error = describeError(context.l10n, error));
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (made == null) return;
    _undelivered = made;
    await _cancelUndelivered(then: SendStage.fileAmount);
    if (!mounted) return;
    if (_stage != SendStage.fileAmount) {
      // Not cancelled (the cancel failed or their reply came first): the made page stays.
      if (_undelivered != null) setState(() => _undelivered = null);
      return;
    }
    setState(() {
      _slate = null;
      _sealedText = null;
      _sealedFor = null;
      _plainCopy = null;
      _fileHandedOver = false;
      _fileMadeAt = null;
    });
  }

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
      await relayCancelFirst(session, stuck);
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
      await _fillMax();
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
    // Asked again on the tap: nothing is built for an amount that does not fit, or before its
    // estimate has come.
    if (!_amountReady) {
      setState(() {});
      return;
    }
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
    // The amount, the balance or the estimate may have moved while the PIN was asked.
    if (_parsedAmount != amount || !_amountReady) {
      setState(() {});
      return;
    }
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
    final laterLink = _laterLink;
    final laterPairing = _laterPairing;
    // The shell clears the handoff for a fresh form; one that came meanwhile goes to it.
    final handoff = ref.read(sendRecipientProvider.notifier);
    widget.onDone();
    if (laterPairing != null) {
      _laterPairing = null;
      handoff.handPairing(laterPairing);
    } else if (laterLink != null) {
      _laterLink = null;
      _laterRecipient = null;
      handoff.handLink(laterLink.link, laterLink.origin);
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

  /// What it allows the File method: Offline stops making a file too (it asks the node),
  /// unless the node is local.
  /// What the network mode allows finishing and posting a file or QR Payment, which reach
  /// only the node: Tor only waits for tor; Offline lets them use the node in use. Making a
  /// file waits for nothing (LEPIC asks the node for its tip, which Offline allows too).
  NetBlock _postBlock = NetBlock.none;

  /// Offline on a node that is not local: the file steps carry [OfflineNodeNote].
  bool _offlineNode = false;

  /// The user's choice on the pairing switch under an address in To: send through the paired
  /// contact's pairing instead of its public Epicbox address (RFC 9.1). Null follows the
  /// rule's default ([mailboxDefaultFor]); a tap holds until the recipient changes.
  bool? _viaMailboxChoice;

  /// The failed send went through the pairing to a contact whose address is in To: the
  /// review offers the same payment to the public Epicbox address.
  bool _failedViaMailbox = false;

  /// The pairing the address in To is paid through now: the contact's, when the rule offers
  /// it for the Epicbox method and the switch is on. Null for the public Epicbox address.
  PairingRecord? _addressMailbox({bool watch = true}) {
    if (_pairingTo != null || _method != TransferMethod.epicbox) return null;
    final address = _read.isAddress ? _read.address : _recipient.text.trim();
    final pairing = sendPairingFor(ref, address, watch: watch);
    if (pairing == null) return null;
    final contacts = (watch ? ref.watch(contactsProvider) : ref.read(contactsProvider)).value ?? const <Contact>[];
    final contact = contactFor(contacts, address);
    if (contact == null) return null;
    final d = mailboxDefaultFor(ref, contact, pairing, watch: watch);
    return d.offered && (_viaMailboxChoice ?? d.on) ? pairing : null;
  }

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
    final r = _pairingTo != null ? _toPairing(watch: watch) : sendPairingFor(ref, _read.isAddress ? _read.address : _recipient.text.trim(), watch: watch);
    return fileSealTarget(r);
  }

  /// The payment method the form sends by now: Epicbox, or for a Link send the Link method
  /// the address picks (Link · HTTP or Link · Tor); null while a Link send has no address yet,
  /// and for the file routes (their gate is [_postBlock]).
  MethodKind? get _sendMethod {
    if (_pairingTo != null) return MethodKind.epicbox;
    final read = _read;
    // No address yet: nothing to hold. An http(s) address sends with no switch on the phone:
    // only the network mode holds it.
    if (!read.isAddress || read.isUrl) return null;
    // No Tor in this build: an onion has no method to turn on, its own error says so.
    if (read.kind == RecipientInputKind.onion && !torBuilt) return null;
    return sendMethodKind(read);
  }

  /// Settings › Transactions, watched: the build follows a switch (the defaults until it loads).
  /// Link · HTTP counts as on: the phone sends to an http(s) address with no switch.
  PaymentPrefs get _watchedPayments =>
      (ref.watch(appSettingsProvider.select((s) => s.value?.payments)) ??
              (ref.watch(phonePaymentsProvider) ? PaymentPrefs.phoneDefaults : PaymentPrefs.defaults))
          .copyWith(linkHttp: true);

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
    // whose method is on. One of another kind is not either: the address in To decides.
    if (contact == null || contact.methodKinds.length != 1 || MethodKind.ofRecipient(contact.methodKinds.single) != m) return reason;
    final name = contact.name;
    final only = m == MethodKind.epicbox
        ? l.sendContactOnlyEpicbox(name)
        : l.sendContactOnlyMethod(name, MethodIcons.fullName(l, m));
    return '$reason $only';
  }

  @override
  Widget build(BuildContext context) {
    _bar = null;
    // A method off in Settings › Transactions holds the send too: Epicbox, or the Link method
    // the address picks (a pasted onion with Link · Tor off says so, never a silent refusal).
    // A pairing recipient's payment waits in the outbox while Epicbox is off ("Queue
    // payment"); Offline and Tor still hold it.
    _block = watchNetBlock(context, ref, method: _pairingTo != null ? null : _sendMethod);
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
      // After Max the amount is the old balance's maximum; ask for the new one. An amount
      // above the new balance needs no estimate: the gate says so.
      if (_maxUsed) {
        _fillMax();
      } else if (!_gate.notEnough) {
        _estimateFee(amount);
      }
    });
    // A recipient handed over while the tab is kept alive fills the form in place.
    ref.listen(sendRecipientProvider, (_, handoff) {
      if (handoff == null || handoff.id == _handoff) return;
      _handoff = handoff.id;
      final request = handoff.request;
      if (handoff.pairingId case final id?) {
        _setPairing(id);
      } else if (handoff.link case final link?) {
        _applyLink(link, handoff.origin ?? CodeOrigin.qr);
      } else if (request != null) {
        _applyRequest(request, handoff.origin ?? CodeOrigin.qr);
      } else {
        // A saved contact's address (Send from the contact, Send again): its chip, so Change
        // offers the contact's other addresses.
        final saved = handoff.origin == null
            ? contactFor(ref.read(contactsProvider).value ?? const <Contact>[], handoff.text)
            : null;
        _setRecipient(handoff.text, origin: handoff.origin, contact: saved);
        // As picking the contact's face does: on to the amount.
        if (saved != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _contact == saved) _toAmount();
          });
        }
      }
    });

    // The shell leaves this Send open while a payment is sent or being sent.
    sendHoldsPayment(this, _holdsPayment);
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
      // The same bar as the other steps: the close is the way out (the tab has no other).
      _header(context, context.l10n.homeSendButton, onClose: _done);
      return _page(_emptyState(context));
    }

    final (children, bottom) = switch (_stage) {
      SendStage.recipient => (_recipientStep(context), _recipientAction()),
      SendStage.amount => (_amountStep(context), _amountAction()),
      SendStage.review => (_reviewStep(context), _reviewAction(context)),
      SendStage.sent => (_trackerStep(context, _sent!), _sentAction(_sent!)),
      SendStage.fileAmount => (_fileAmountStep(context), _fileAmountAction()),
      SendStage.fileMade => (
        _fileMadeStep(context, _slate!),
        _openReplyAction(),
      ),
      SendStage.fileSent => (_fileSentStep(context), _doneAction()),
    };
    // The reason sits above the button that waits for the network (not after a send). A hold
    // the recipient step shows under the field is not said twice.
    final note = switch (_stage) {
      SendStage.recipient when _holdShown && _block.byMode => NetBlock.none,
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
    final bottomWithNotes = note != NetBlock.none || noPeers || offlineNode
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
                  KitButton(
                    key: sendTurnOnMethodKey,
                    kind: KitButtonKind.quiet,
                    label: context.l10n.sendTurnOnMethod(MethodIcons.fullName(context.l10n, m)),
                    onPressed: () => _turnOn(m),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              ?bottom,
            ],
          )
        : bottom;
    final problem = _error != null
        ? ErrorText(_error!)
        // The reviewed payment no longer fits: Send is off, and this says why.
        : _stage == SendStage.review && !_sendFailed && _gate.notEnough
        ? ErrorText(context.l10n.errorNotEnoughFunds)
        : null;
    if (_stage == SendStage.review) {
      return _reviewPage(context, [...children, ?problem], bottomWithNotes!);
    }
    // The Who step has no button until an address is in: its list is the way on (Send-1).
    final foot = _stage == SendStage.recipient && !_hasRecipient && _pairingTo == null && note == NetBlock.none ? null : bottomWithNotes;
    return _page(_FlowBody(bottom: foot, children: [...children, ?problem]));
  }

  /// The review (HANDOFF 9, Send-3): a sheet over the amount page, which shows dimmed under it.
  /// A tap on the dim, or the Android back, returns to the amount unless the payment is made or
  /// being sent. [body] is the sheet's content, [actions] its buttons.
  Widget _reviewPage(BuildContext context, List<Widget> body, Widget actions) {
    final l = context.l10n;
    final t = context.tokens;
    final unit = _fiatEntry ? (ref.watch(appSettingsProvider).value?.fiatCurrency ?? 'usd').toUpperCase() : epicUnit;
    _header(context, l.sendTo(_toName(l)), avatar: _toAvatar(small: true));
    final canLeave = !_sendFailed && !_busy;
    final height = MediaQuery.sizeOf(context).height;
    return Stack(
      children: [
        // What the sheet covers: the amount's header and figure, inert.
        ExcludeSemantics(
          child: IgnorePointer(
            child: _page(
              _FlowBody(
                children: [
                  // Send-3's `.big` stands 58 under the bar.
                  const SizedBox(height: 44),
                  KitAmountDisplay(amount: _amount.text, unit: unit),
                ],
              ),
            ),
          ),
        ),
        // The dim is a touch target only; the system back is the way out for a screen reader.
        Positioned.fill(
          child: Offstage(
            offstage: _pinShowing,
            child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canLeave ? _backToAmount : null,
              child: ColoredBox(color: t.scrim),
            ),
          ),
          ),
        ),
        Offstage(
          offstage: _pinShowing,
          child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600, maxHeight: height * 0.94),
            child: Material(
              color: t.sheet,
              clipBehavior: Clip.antiAlias,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Kit.rSheetTop))),
              child: KitSheet(
                title: l.phoneSendReviewTitle,
                titleGap: 0,
                primary: actions,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: body),
              ),
            ),
          ),
          ),
        ),
      ],
    );
  }

  /// [body] under the step's top bar. The bar sits at the page's top edge: the shell draws no
  /// second header over it.
  Widget _page(Widget body) => Column(
    children: [
      SafeArea(bottom: false, child: _bar ?? const SizedBox.shrink()),
      // The host leaves Send's insets to it: the review's sheet runs to the screen's edge, and
      // each body keeps the bottom inset clear itself.
      Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: body)),
    ],
  );

  Widget _emptyState(BuildContext context) {
    final request = _activeRequest;
    return SafeArea(child: CenteredScroll(
      child: CenteredBody(
        children: [
          // A code or link that came in still shows it did; the form takes it once coins arrive.
          if (request != null && request.problems.isNotEmpty)
            RequestBanner(
              open: _requestBanner,
              origin: _origin ?? CodeOrigin.qr,
              problems: request.problems,
              onDismiss: () => setState(() => _requestBanner = false),
            ),
          PhoneTourTarget(
            id: 'tour-send-empty',
            child: EmptyState(
            icon: const Icon(KitIcons.send),
            message: context.l10n.sendNoCoins,
            // Never a dead end: the next step is the Receive tab.
            action: TextButton(
              onPressed: () => ref
                  .read(shellFlowProvider.notifier)
                  .open(ShellFlow.receive),
              child: Text(context.l10n.homeReceiveButton),
            ),
          ),
          ),
        ],
      ),
    ));
  }

  /// The page's top bar, set by the step being built ([_header]) and drawn by [build] above the
  /// step, outside the scrolling body.
  Widget? _bar;

  /// Sets the top bar of the step: [onBack] a back arrow, else [onClose] a ×, else no button.
  /// [onHelp] is the "?"; by default the payment's "How it works".
  Widget _header(
    BuildContext context,
    String title, {
    VoidCallback? onBack,
    VoidCallback? onClose,
    VoidCallback? onHelp,
    bool help = true,
    Widget? avatar,
    Widget? strip,
  }) {
    final busy = _busy || _estimating;
    final leading = onBack ?? onClose;
    final bar = KitFlowHeader(
      title: title,
      avatar: avatar,
      showLeading: leading != null,
      back: onBack != null,
      onLeading: leading == null || busy ? null : leading,
      leadingId: onBack != null ? TrustIds.sendBack : TrustIds.sendClose,
      onHelp: !help ? null : (onHelp ?? _showHowItWorks),
      helpId: TrustIds.sendHelp,
    );
    // A step strip sits under the bar, on the page's own gutter (not the body's).
    _bar = strip == null ? bar : Column(mainAxisSize: MainAxisSize.min, children: [bar, strip]);
    return const SizedBox.shrink();
  }

  /// The "?" of Send: the frame's help sheet for the payment way; the file, QR and direct ways
  /// keep the animated hand-over of their own.
  void _showHowItWorks() {
    if (_howFlow != HandshakeFlow.payment) {
      showHandshakeSheet(context, flow: _howFlow);
      return;
    }
    showSendHelpSheet(
      context,
      onNeverFinishes: () => _ifNotSheet(context),
      onMore: () => openHelp(context, HelpId.send),
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

  /// What the network mode holds the To field's address with, watched; none for a pairing,
  /// whose mailbox the bottom note speaks for.
  SendHold? get _hold => _pairingTo == null ? _holdOf(_read) : null;

  /// A hold shows under the field: the bottom note does not say it again.
  bool get _holdShown => _stage == SendStage.recipient && _hold != null;

  /// Saved contacts whose name holds [text], for "Address or contact": at most three.
  List<Contact> _nameMatches(String text, {bool watch = true}) {
    final query = text.trim().toLowerCase();
    if (query.length < 2 || _readOf(query).isAddress) return const [];
    final contacts = (watch ? ref.watch(contactsProvider) : ref.read(contactsProvider)).value ?? const <Contact>[];
    return contacts.where((c) => c.name.toLowerCase().contains(query)).take(3).toList();
  }

  // The reach check.

  /// The Link address the reach check asks about now: complete in To (pasted, left, or a
  /// contact's), not held, in a mode that lets it ask. Null otherwise.
  RecipientInput? _reachTarget(RecipientInput read, SendHold? hold, {bool force = false}) {
    if (!read.isLink || hold != null) return null;
    if (!force && !_touched && _contact == null) return null;
    if (!reachCheckApplies(read, mode: AdvancedOptions.of(context).networkMode)) return null;
    if (_recipientProblem(read.address) != null) return null;
    return read;
  }

  /// Asks [to] once, in the background; "Checking…" only after [_reachSlowAfter].
  void _askReach(RecipientInput to) {
    final key = to.address;
    if (_reach.containsKey(key) || _reachAsking.contains(key)) return;
    _reachAsking.add(key);
    final mode = AdvancedOptions.of(context).networkMode;
    Timer(_reachSlowAfter, () {
      if (mounted && _reachAsking.contains(key)) setState(() => _reachSlow.add(key));
    });
    _reachRuns[key] = checkWalletAnswers(to, mode: mode).then((result) async {
      // No wallet answers as typed: the listener's port, or plain http://, is asked once ([reachFallback]).
      final plain = reachFallbackApplies(result, to) ? await reachFallback(to, mode: mode, listenPort: appConfig.httpListenPort) : null;
      if (!mounted) return;
      setState(() {
        _reachAsking.remove(key);
        _reachSlow.remove(key);
        _reach[key] = result;
        if (plain != null) {
          _reach[plain.address] = ReachResult.answers;
          // To shows the address that answered, while it still holds the one asked.
          if (_read.address == key) {
            _recipient.text = plain.address;
            _lastTo = plain.address;
          }
        }
      });
    }).whenComplete(() {
      _reachRuns.remove(key);
    });
  }

  /// Whether Review may open: the Link address in To is asked (once, as the field does) and
  /// waited for, and a wallet answers there. A failed or pending check ends on To, whose
  /// notice says it. Nothing to wait for when the check does not apply.
  Future<bool> _reachSettled() async {
    for (var i = 0; i < 3; i++) {
      final read = _read;
      final to = _reachTarget(read, _hold, force: true);
      if (to == null) return true;
      _askReach(to);
      await _reachRuns[to.address];
      if (!mounted) return false;
      // To changed while it was asked (typed again, or the address that answered): ask that one.
      if (_read.address != to.address) continue;
      return _reach[to.address] == ReachResult.answers;
    }
    return false;
  }

  /// Try again on the reach notice: the one way to ask an address again.
  void _retryReach(RecipientInput to) {
    if (_reachAsking.contains(to.address)) return;
    setState(() => _reach.remove(to.address));
    _askReach(to);
  }

  /// The one action of a hold's notice: Normal mode, or the Tor switch off; a toast after.
  Future<void> _fixHold(SendHold hold) async {
    final l = context.l10n;
    final notices = ref.read(noticeProvider.notifier);
    switch (hold.fix) {
      case SendHoldFix.normalMode:
        if (await chooseNetworkMode(context, ref, NetworkMode.standard)) {
          notices.show(l.sendHeldModeNormal, level: NoticeLevel.success);
        }
      case SendHoldFix.torOff:
        await ref.read(phoneTorProvider.notifier).setReceiving(false);
        notices.show(l.sendHeldTorIsOff, level: NoticeLevel.success);
    }
  }

  // The recipient step.

  List<Widget> _recipientStep(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = context.tokens;
    final scan = offersQrScan(ref);
    final text = _recipient.text.trim();
    final read = _read;
    final contact = _contact;
    // Kept alive while the step shows: the own-address check reads it.
    ref.watch(addressProvider);
    final pairing = _toPairing();
    final stepTitle = l.homeSendButton;
    if (pairing != null) {
      final name = _pairingNameOf(pairing.id);
      return [
        _header(context, stepTitle, onClose: _done),
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
      ];
    }
    final hold = _hold;
    final valid = read.isAddress && _recipientProblem(_recipient.text) == null;
    final transactions = ref.watch(homeProvider).value?.transactions ?? const <TxEntry>[];
    final recent = recentRecipients(transactions);
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final matches = contact == null && read.kind == RecipientInputKind.text ? _nameMatches(text) : const <Contact>[];
    final target = _reachTarget(read, hold);
    if (target != null) _askReach(target);
    final reach = target == null ? null : _reach[target.address];
    final reachLines = reach == null ? null : sendReachLines(l, target!, reach);
    final epicboxState = ref.watch(walletStatusProvider.select((s) => s.epicbox));
    final epicboxDown = hold == null &&
        read.kind == RecipientInputKind.epicbox &&
        (epicboxState == null || epicboxState == EpicboxState.offline);
    // An http(s) address names its method from the scheme on, while the host is still typed.
    final routeShown = read.isAddress || read.typing != null;
    final saveable = valid && contact == null && _contactName(read.address) == null;
    // A complete address, pasted, scanned or left: shown whole in its box (Send-5).
    final settled = valid && _touched && contact == null;
    // The settled address shows its first and last six in gold and its server faint (`.addr em`, `i`).
    _recipient
      ..mark = settled ? TextStyle(color: t.accentText) : null
      ..quiet = settled ? TextStyle(color: t.faint) : null;
    final empty = text.isEmpty && contact == null;
    final ownServer = ownEpicboxServer(ref);
    const indent = EdgeInsetsDirectional.only(start: 42);
    return [
      _header(context, stepTitle, onClose: _done),
      if (contact != null)
        _contactChip(context, contact)
      else if (settled)
        KitAddressBox(
          onClear: _clearRecipient,
          clearId: TrustIds.sendClear,
          clearKey: sendRecipientClearKey,
          child: TrustId(
            TrustIds.sendTo,
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
              style: KitType.address.copyWith(color: t.text),
              cursorColor: t.accent,
              onChanged: _recipientChanged,
              decoration: const InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        )
      else
        PhoneTourTarget(
          id: 'tour-send-recipient',
          child: KitAddressField(
            controller: _recipient,
            focusNode: _recipientFocus,
            hint: l.phoneSendSearchHint,
            fieldKey: sendRecipientFieldKey,
            semanticsId: TrustIds.sendTo,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            onChanged: _recipientChanged,
            onSubmitted: (_) => _toAmount(),
            onPaste: _paste,
            onScan: scan ? _scan : null,
            pasteId: TrustIds.sendPaste,
            scanId: TrustIds.sendScan,
          ),
        ),
      if (_recipientError != null)
        Padding(padding: const EdgeInsets.only(top: 8), child: LiveFieldError(_recipientError!)),
      if (_recipientError != null && _recipientError == _epic1OffLine)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(key: epic1FieldSettingsKey, onPressed: () => openEpic1Settings(context), child: Text(l.deskE1PhSettings)),
        ),
      // A transaction text: open it where it belongs, no error.
      if (read.kind == RecipientInputKind.slate) ...[
        const SizedBox(height: 8),
        InlineNotice(
          level: NoticeLevel.info,
          icon: Icons.notes,
          text: l.sendIsSlateText,
          below: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton(
                onPressed: () => _openText(_recipient.text, CodeOrigin.paste, typedOver: '', open: true),
                child: Text(l.sendOpenSlateText),
              ),
            ),
          ),
        ),
      ],
      if (routeShown || saveable) ...[
        const SizedBox(height: 14),
        KitGroup(
          margin: EdgeInsets.zero,
          children: [
            if (routeShown) _routeRow(context, read, contact: contact, known: contact != null || _contactName(read.address) != null, hold: hold, complete: valid),
            if (saveable)
              KitRow(
                // No well, the gold glyph alone, on a 54 row (`.av.n` with no background).
                leading: SizedBox.square(dimension: 40, child: Icon(KitIcons.addContact, size: 20, color: t.accentText)),
                minHeight: 54,
                title: l.phoneSendAddContact,
                titleColor: t.accentText,
                onTap: () => _saveContact(read.address),
                semanticsId: TrustIds.sendAddcontact,
              ),
          ],
        ),
      ],
      if (settled)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: KitHint(l.phoneSendAddressCheck, inset: 4),
        ),
      // A saved contact, paired: its trust and the seal, and the mailbox switch.
      if (valid)
        SendPairingLine(
          address: read.address,
          epicbox: _method == TransferMethod.epicbox,
          viaMailbox: _viaMailboxChoice,
          onViaMailbox: (on) => setState(() => _viaMailboxChoice = on),
          showVia: false,
          onAddress: _pickAddress,
        ),
      if (hold != null) ...[
        const SizedBox(height: 8),
        _holdNotice(context, hold),
        if (hold.offersDirect) ?_directWays(context, lead: l.sendWithoutConnection),
      ] else if (reachLines != null) ...[
        const SizedBox(height: 8),
        _reachNotice(context, target!, reach!, reachLines),
      ] else if (target != null && _reachSlow.contains(target.address))
        Padding(
          padding: indent.add(const EdgeInsets.only(top: 6)),
          child: Semantics(
            liveRegion: true,
            child: Row(
              children: [
                if (!MediaQuery.disableAnimationsOf(context))
                  const Padding(
                    padding: EdgeInsetsDirectional.only(end: 8),
                    child: SizedBox.square(dimension: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
                  ),
                Text(l.sendReachChecking, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
              ],
            ),
          ),
        ),
      // Epicbox chosen while its listener is down: say so and offer Retry (UP-038).
      if (epicboxDown) ...[
        const SizedBox(height: 8),
        InlineNotice(
          key: sendEpicboxDownKey,
          level: NoticeLevel.warning,
          icon: Icons.cloud_off,
          text: l.statusEpicboxOffline,
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l.commonRetry),
              onPressed: () => ref.read(listenerProvider.notifier).restart(),
            ),
          ],
        ),
      ],
      _TorNotice(way: _wayOf(_toRoute)),
      if (matches.isNotEmpty) ...[
        KitGroupLabel(l.sendContactsButton, inset: 4),
        KitGroup(
          margin: EdgeInsets.zero,
          children: [
            for (final c in matches)
              _WhoRow(
                address: _contactRowAddress(c),
                name: c.name,
                // A contact with no address: through its pairing, never an empty address.
                subtitle: _pairingOnly(c, watch: true) == null ? null : l.sendRecipientPairing(c.name, l.sendRoutePairedInline),
                onTap: () => _useContact(c),
              ),
          ],
        ),
      ],
      if (empty) ...[
        ..._faces(context, contacts, recent),
        if (recent.isNotEmpty) ...[
          KitSectionHead(l.sendRecent, top: 26, inset: 0),
          KitGroup(
            margin: EdgeInsets.zero,
            children: [
              for (final address in recent.take(5)) _recentRow(l, address, transactions, contacts, ownServer),
            ],
          ),
        ],
        if (_qrOffered || _fileOffered || ref.watch(epic1OnProvider)) ...[
          const SizedBox(height: 12),
          KitGroup(
            margin: EdgeInsets.zero,
            children: [
              KitRow(
                leading: KitIconWell.child(KitQrGlyph(color: t.accentText)),
                title: l.sendNoAddress,
                subtitle: l.phoneSendNoAddressSub,
                chevron: true,
                onTap: _busy || _estimating ? null : () => _noAddressSheet(context),
                semanticsId: TrustIds.sendNoaddress,
              ),
            ],
          ),
        ],
      ],
    ];
  }

  /// One Recent row. Its name is the one Activity gives the newest payment to [address]
  /// ([txPartyName]: a saved contact, else the pairing the payment went through); a named row
  /// opens that contact and has no "Not saved" line.
  Widget _recentRow(AppLocalizations l, String address, List<TxEntry> transactions, List<Contact> contacts, String? ownServer) {
    final tx = _lastPaidTx(transactions, address);
    final saved = contactFor(contacts, address);
    final name = _contactName(address) ?? (tx == null ? null : txPartyName(ref, tx));
    Contact? contact = saved;
    if (contact == null && name != null && tx != null) {
      final slate = tx.slateId;
      final pairingId = tx.pairingId ?? (slate == null ? null : ref.watch(paidInvoiceProvider(slate)).value?.pairingId);
      final contactId = pairingId == null ? null : ref.watch(pairingByIdProvider(pairingId))?.contactId;
      contact = contactId == null ? null : contacts.where((c) => c.id == contactId).firstOrNull;
    }
    return _WhoRow(
      address: address,
      ownServer: ownServer,
      name: name,
      subtitle: name != null ? null : l.phoneSendNotSavedPaid(shortDay(l, localTime(tx?.timeUnix ?? 0), ref.read(clockProvider)())),
      onTap: () {
        if (contact != null) {
          _useContact(contact, address: saved == null ? null : address);
        } else {
          _setRecipient(address);
        }
        _toAmount();
      },
    );
  }

  /// The newest payment to [address].
  TxEntry? _lastPaidTx(List<TxEntry> transactions, String address) {
    TxEntry? newest;
    for (final tx in transactions) {
      if (tx.kind == TxKind.sent && tx.counterparty?.trim() == address.trim() && (newest == null || tx.timeUnix > newest.timeUnix)) newest = tx;
    }
    return newest;
  }

  /// The faces under the Who field: people paid lately, then the other contacts.
  List<Widget> _faces(BuildContext context, List<Contact> contacts, List<String> recent) {
    final seen = <String>{};
    final people = <Contact>[];
    for (final address in recent) {
      final c = contactFor(contacts, address);
      if (c != null && seen.add(c.id)) people.add(c);
    }
    for (final c in [...contacts]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()))) {
      if (seen.add(c.id)) people.add(c);
    }
    if (people.isEmpty) return const [];
    return [
      const SizedBox(height: 22),
      KitFacesStrip(
        bleed: Kit.gutter,
        faces: [
          for (final c in people.take(10))
            KitFace(
              label: c.name,
              // The frame draws the first name under the face.
              caption: c.name.trim().split(RegExp(r'\s+')).first,
              initials: nameInitials(c.name, phone: true),
              semanticsId: TrustIds.sendFace,
              onTap: () {
                _useContact(c);
                if (_pairingTo == null) _toAmount();
              },
            ),
        ],
      ),
    ];
  }

  /// "No address?": pay in person (a code) or with a file, today's two ways.
  Future<void> _noAddressSheet(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return showKitSheet<void>(
      context: context,
      builder: (sheet) => KitSheet(
        title: l.phoneSendNoAddressTitle,
        titleGap: 8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(l.phoneSendNoAddressBody, style: KitType.body.copyWith(fontSize: 13, height: 1.45, color: t.dim)),
            ),
            const SizedBox(height: 16),
            KitGroup(
              onSheet: true,
              dividerInset: Kit.dividerInsetList,
              children: [
                if (_qrOffered)
                  KitRow(
                    leading: KitIconWell.child(KitQrGlyph(color: t.accent), size: 40),
                    minHeight: 72,
                    title: l.phoneSendInPerson,
                    // Beside the epic1 row, each says its method.
                    subtitle: ref.read(epic1OnProvider) ? '${l.methodQr} · ${l.phoneSendInPersonSub}' : l.phoneSendInPersonSub,
                    chevron: true,
                    onTap: () {
                      Navigator.of(sheet).pop();
                      _toFileRoute(qr: true);
                    },
                    semanticsId: TrustIds.sendNoaddressPerson,
                  ),
                if (ref.read(epic1OnProvider))
                  KitRow(
                    key: epic1PayInPersonKey,
                    leading: KitIconWell.child(Epic1Glyph(size: 22, color: t.accent), size: 40),
                    minHeight: 72,
                    title: l.deskE1PhPayInPerson,
                    subtitle: _qrOffered ? '${l.deskE1SetSwitch} · ${l.phoneSendInPersonSub}' : l.phoneSendInPersonSub,
                    chevron: true,
                    onTap: () {
                      Navigator.of(sheet).pop();
                      openPayInPerson(context);
                    },
                    semanticsId: TrustIds.sendNoaddressEpic1Person,
                  ),
                if (_fileOffered)
                  KitRow(
                    leading: KitIconWell(KitIcons.fileDown, color: t.accent, size: 40, iconSize: 20),
                    minHeight: 72,
                    title: l.phoneSendWithFile,
                    subtitle: l.phoneSendWithFileSub,
                    chevron: true,
                    onTap: () {
                      Navigator.of(sheet).pop();
                      _toFileRoute();
                    },
                    semanticsId: TrustIds.sendNoaddressFile,
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: kitId(
                TrustIds.sendNoAddressCancel,
                TextButton(
                  style: _ghostStyle(context),
                  onPressed: () => Navigator.of(sheet).pop(),
                  child: Text(l.commonCancel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The address a contact row shows: the one Send would use.
  String _contactRowAddress(Contact c) {
    final i = _bestIndex(c);
    return i < 0 ? c.address : c.addresses[i];
  }

  /// A keystroke, or a paste into the field: a jump of 8 or more characters is read at once,
  /// as the Paste button does; typing only clears what the last reading said.
  void _recipientChanged(String text) {
    final jump = text.length - _lastTo.length >= 8;
    if (jump && (looksLikeCode(text) || looksLikeEpic1Link(text))) {
      final before = _lastTo;
      _lastTo = text;
      _openText(text.trim(), CodeOrigin.paste, typedOver: before);
      return;
    }
    if (jump && _readOf(text).isAddress) {
      _setRecipient(text, given: text);
      return;
    }
    setState(() {
      _lastTo = text;
      _touched = false;
      _viaMailboxChoice = null;
      _recipientError = null;
      _error = null;
      _leaveRequest();
    });
  }

  /// To with a contact picked: their avatar and name, × to clear.
  Widget _contactChip(BuildContext context, Contact contact) {
    final l = context.l10n;
    return Semantics(
      container: true,
      label: l.sendToLabel,
      child: KitAddressBox(
        onClear: _clearRecipient,
        clearId: TrustIds.sendClear,
        clearKey: sendRecipientClearKey,
        child: Row(
          children: [
            KitAvatar(initials: nameInitials(contact.name, phone: true)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(contact.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: KitType.rowTitle.copyWith(color: context.tokens.text)),
            ),
          ],
        ),
      ),
    );
  }

  /// The name Review and Amount show after "To": the contact, the pairing, else the short address.
  String _toName(AppLocalizations l) {
    if (_pairingTo != null) return _pairingNameOf(_pairingTo!);
    final contact = _contact;
    if (contact != null) return contact.name;
    final address = _read.address;
    return _contactName(address) ?? shortAddress(address);
  }

  Widget _toAvatar({bool small = false}) {
    final named = _pairingTo != null || _contact != null || _contactName(_read.address) != null;
    return named ? KitAvatar(small: small, initials: nameInitials(_toName(context.l10n), phone: true)) : KitAvatar(small: small, icon: KitIcons.contact, neutral: true);
  }

  /// The method row under To: the method's icon and name, whether their wallet can be offline,
  /// the host exactly as it will be contacted, and the way it goes (this phone, your network,
  /// over Tor). A contact with more than one address gets a chevron: a sheet of them.
  Widget _routeRow(BuildContext context, RecipientInput to, {Contact? contact, bool known = false, SendHold? hold, bool complete = true}) {
    final l = context.l10n;
    final t = context.tokens;
    final mode = AdvancedOptions.of(context).networkMode;
    final torOn = ref.watch(phoneTorProvider.select((s) => s.receiving));
    final overTor = sendOverTor(to, mode: mode, torOn: torOn);
    final tag = sendRouteTag(l, to, phone: true, overTor: overTor);
    final name = sendMethodName(l, to);
    final kind = sendMethodKind(to)!;
    final torStarts = torBuilt && to.kind == RecipientInputKind.onion && !torOn && mode != NetworkMode.torOnly && hold == null && _watchedPayments.linkTor;
    final dim = TextStyle(color: t.dim);
    final strong = TextStyle(color: t.text, fontWeight: FontWeight.w600);
    final epicbox = to.kind == RecipientInputKind.epicbox;
    final where = switch (to.urlKind ?? to.kind) {
      RecipientInputKind.https || RecipientInputKind.http => TextSpan(
        children: [
          TextSpan(text: '${to.urlKind == RecipientInputKind.https ? 'https' : 'http'}://', style: dim),
          TextSpan(text: to.hostShown, style: strong),
          TextSpan(text: '${to.portShown}${to.path}', style: dim),
        ],
      ),
      RecipientInputKind.onion => addressSpan(
        to.host,
        style: TextStyle(color: t.text),
        mark: TextStyle(color: t.accentText, fontWeight: FontWeight.w600),
        quiet: dim,
      ),
      _ => null,
    };
    final line = metaLine([
      // "New to you" is said of a whole address, not of one still being typed, and never of a
      // saved contact's (picked, or typed in full).
      if (contact == null && !known && complete) l.phoneSendNewToYou,
      epicbox ? l.phoneSendTheirOffline : l.phoneSendTheirOnline,
      if (torStarts) l.sendRouteTorStarts,
    ]);
    final several = contact != null && contact.addresses.length > 1;
    final row = KitRow(
      leading: KitIconWell(MethodIcons.of(kind), color: t.accentText),
      title: epicbox ? l.phoneSendRouteEpicbox : name,
      subtitle: where == null ? line : null,
      subtitleLines: 2,
      subtitleWidget: where == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line, style: KitType.rowSub.copyWith(color: t.dim), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text.rich(where, style: KitType.address.copyWith(color: t.dim), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
      trailing: tag == null ? null : (overTor ? EBadge.tor(tag, way: TorWay.overTor) : EBadge(tag)),
      chevron: several,
      onTap: several ? () => _addressesSheet(context, contact, to) : null,
      semanticsId: several ? TrustIds.sendRoute : null,
      semanticsLabel: several ? metaLine([l.sendRouteSemantics(name, sendContactedText(to)), l.sendRouteChange]) : l.sendRouteChange,
    );
    if (several) return row;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: metaLine([l.sendRouteSemantics(name, sendContactedText(to)), ?tag, if (torStarts) l.sendRouteTorStarts]),
      child: row,
    );
  }

  /// The contact's addresses in a picker: each with its method and short form, the one in use
  /// ticked, those the mode holds greyed with the reason (the row is not offered then).
  Future<void> _addressesSheet(BuildContext context, Contact contact, RecipientInput current, {bool review = false}) {
    final l = context.l10n;
    final first = contact.name.trim().split(RegExp(r'\s+')).first;
    final choices = <KitChoice<String>>[];
    var index = 0;
    for (final address in contact.addresses) {
      final to = _readOf(address);
      if (!to.isAddress) continue;
      final hold = _holdOf(to);
      final kind = sendMethodKind(to)!;
      final off = hold == null && !_watchedPayments.offers(kind);
      final reason = hold != null ? sendHoldReason(l, hold) : (off ? methodOffReason(l, kind) : null);
      final short = to.isUrl ? to.address : shortAddress(to.address);
      choices.add(KitChoice<String>(
        value: to.address,
        title: sendMethodName(l, to),
        subtitle: reason ?? short,
        leading: KitIconWell(MethodIcons.of(kind)),
        // Each choice has its own key; the trust id (no driver taps it yet) is the first one's.
        key: ValueKey('send-address-$index'),
        semanticsId: index == 0 ? TrustIds.sendAddressPick : null,
        enabled: reason == null,
      ));
      index++;
    }
    return KitPickerSheet.show<String>(
      context: context,
      title: l.sendRouteAddressesOf(first),
      choices: choices,
      selected: current.address,
      // From the review the other address takes the form back to the amount: the fee and the
      // way it goes are worked out again for it.
      onSelected: review
          ? (address) {
              _pickAddress(address);
              _toAmount(focus: false);
            }
          : _pickAddress,
    );
  }

  /// A hold's notice: what holds it, the one action that lifts it, and that the action is
  /// the app's, not this payment's.
  Widget _holdNotice(BuildContext context, SendHold hold) {
    final l = context.l10n;
    final t = context.tokens;
    return InlineNotice(
      level: NoticeLevel.info,
      icon: Icons.block,
      liveRegion: true,
      text: sendHoldText(l, hold),
      below: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton(
              key: hold.fix == SendHoldFix.torOff ? sendTurnOffTorKey : null,
              onPressed: () => _fixHold(hold),
              child: Text(sendHoldAction(l, hold)),
            ),
            const SizedBox(height: 6),
            Text(
              l.torTurnOffCaption,
              key: hold.fix == SendHoldFix.torOff ? sendTurnOffTorCaptionKey : null,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.dim),
            ),
          ],
        ),
      ),
    );
  }

  /// No wallet answers at a Link address, or something else does: a warning, Continue stays.
  Widget _reachNotice(BuildContext context, RecipientInput to, ReachResult reach, (String, String) lines) {
    final l = context.l10n;
    final t = context.tokens;
    return InlineNotice(
      level: NoticeLevel.warning,
      liveRegion: true,
      text: lines.$1,
      below: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lines.$2, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.dim)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (reach == ReachResult.noAnswer)
                  OutlinedButton(onPressed: () => _retryReach(to), child: Text(l.sendReachTryAgain)),
                if (_fileOffered)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: t.dim),
                    icon: const Icon(MethodIcons.file, size: 18),
                    label: Text(l.sendPayByFile),
                    onPressed: _toFileRoute,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pay in person and Pay with a file, after [lead]; null when neither is offered.
  Widget? _directWays(BuildContext context, {required String lead}) {
    final l = context.l10n;
    final t = context.tokens;
    final qr = _qrOffered;
    final file = _fileOffered;
    if (!qr && !file) return null;
    final quiet = TextButton.styleFrom(foregroundColor: t.dim, minimumSize: const Size(48, 44));
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: Text(lead, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.dim)),
          ),
          Wrap(
            spacing: 4,
            children: [
              if (qr)
                TextButton.icon(
                  style: quiet,
                  icon: const Icon(MethodIcons.qr, size: 20),
                  label: Text(l.sendPayInPerson),
                  onPressed: _busy || _estimating ? null : () => _toFileRoute(qr: true),
                ),
              if (file)
                TextButton.icon(
                  style: quiet,
                  icon: const Icon(MethodIcons.file, size: 20),
                  label: Text(l.sendPayByFile),
                  onPressed: _busy || _estimating ? null : _toFileRoute,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// A pairing recipient can be paid while paired or verified and its wallet opens sealed
  /// messages; keys that changed meanwhile hold Continue until the words are checked.
  bool get _hasRecipient => _pairingTo != null
      ? _toPairing()?.paysByMailbox ?? false
      : _read.isAddress || _epic1LinkInTo;

  Widget _recipientAction() => BusyButton(
    kit: true,
    semanticsId: TrustIds.commonContinue,
    label: context.l10n.commonContinue,
    onPressed: !_hasRecipient || _block != NetBlock.none || _hold != null
        ? null
        : _toAmount,
  );

  /// The decimal mark the keypad writes: the language's, as Max and the unit switch write it.
  String _point(AppLocalizations l) => localDecimal(l, '.');

  void _setAmountText(String text) {
    _amount.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    _onAmountChanged(text);
  }

  /// Where the decimal mark stands in [text]: the language's or the plain point, whichever
  /// is there (an amount can come in either, from a paste or a code).
  int _pointAt(String text, AppLocalizations l) {
    final at = text.indexOf(_point(l));
    return at >= 0 ? at : text.indexOf('.');
  }

  void _keyDigit(String digit) {
    if (_busy) return;
    final l = context.l10n;
    // A digit after Max starts a new amount; it is not added to the maximum.
    final text = _maxUsed ? '' : _amount.text;
    final at = _pointAt(text, l);
    // EPIC has eight decimals, a currency two; the field never holds more.
    if (at >= 0 && text.length - at - 1 >= (_fiatEntry ? 2 : 8)) return;
    if (text.length >= 16) return;
    _setAmountText(text == '0' ? digit : text + digit);
  }

  void _keyPoint() {
    if (_busy) return;
    final l = context.l10n;
    final text = _maxUsed ? '' : _amount.text;
    final mark = _point(l);
    if (_pointAt(text, l) >= 0) return;
    _setAmountText(text.isEmpty ? '0$mark' : text + mark);
  }

  static final _digitKeys = <LogicalKeyboardKey, String>{
    LogicalKeyboardKey.digit0: '0',
    LogicalKeyboardKey.digit1: '1',
    LogicalKeyboardKey.digit2: '2',
    LogicalKeyboardKey.digit3: '3',
    LogicalKeyboardKey.digit4: '4',
    LogicalKeyboardKey.digit5: '5',
    LogicalKeyboardKey.digit6: '6',
    LogicalKeyboardKey.digit7: '7',
    LogicalKeyboardKey.digit8: '8',
    LogicalKeyboardKey.digit9: '9',
    LogicalKeyboardKey.numpad0: '0',
    LogicalKeyboardKey.numpad1: '1',
    LogicalKeyboardKey.numpad2: '2',
    LogicalKeyboardKey.numpad3: '3',
    LogicalKeyboardKey.numpad4: '4',
    LogicalKeyboardKey.numpad5: '5',
    LogicalKeyboardKey.numpad6: '6',
    LogicalKeyboardKey.numpad7: '7',
    LogicalKeyboardKey.numpad8: '8',
    LogicalKeyboardKey.numpad9: '9',
  };

  /// The hardware keyboard on the amount page: digits, the decimal point ('.' or ','),
  /// Backspace, and a pasted number (Ctrl or Cmd with V). The page's keypad does the same by touch.
  KeyEventResult _amountKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    if (key == LogicalKeyboardKey.keyV && (keyboard.isControlPressed || keyboard.isMetaPressed)) {
      _pasteAmount();
      return KeyEventResult.handled;
    }
    if (keyboard.isControlPressed || keyboard.isMetaPressed || keyboard.isAltPressed) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.backspace) {
      _keyDelete();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.period || key == LogicalKeyboardKey.comma || key == LogicalKeyboardKey.numpadDecimal) {
      _keyPoint();
      return KeyEventResult.handled;
    }
    final c = event.character;
    final digit = _digitKeys[key] ?? (c != null && c.length == 1 && c.compareTo('0') >= 0 && c.compareTo('9') <= 0 ? c : null);
    if (digit != null) {
      _keyDigit(digit);
      return KeyEventResult.handled;
    }
    if (c == '.' || c == ',') {
      _keyPoint();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// A number from the clipboard becomes the amount when it reads as one (digits and at most one
  /// point or comma, within the field's limits); anything else is left alone.
  Future<void> _pasteAmount() async {
    if (_busy) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = (data?.text ?? '').replaceAll(RegExp(r'\s'), '');
    final match = RegExp(r'^(\d*)(?:[.,](\d*))?$').firstMatch(text);
    if (match == null || text.isEmpty || text == '.' || text == ',') return;
    final whole = (match.group(1) ?? '').isEmpty ? '0' : match.group(1)!;
    final fraction = match.group(2);
    final room = _fiatEntry ? 2 : 8;
    final shown = fraction == null ? whole : '$whole${_point(context.l10n)}${fraction.length > room ? fraction.substring(0, room) : fraction}';
    if (shown.length > 16) return;
    _setAmountText(shown);
  }

  void _keyDelete() {
    if (_busy) return;
    final text = _amount.text;
    if (text.isEmpty) return;
    _setAmountText(text.substring(0, text.length - 1));
  }

  /// The amount page's body (HANDOFF 9, Send): the figure, what is left, the Available bar with
  /// Max, the note, and the notices that hold the payment. The keypad and the button are
  /// [_amountKeys]. The real text field sits hidden: a hardware keyboard, a paste and the tests
  /// type into it, and the keypad edits the same controller.
  List<Widget> _amountBody(BuildContext context, {required bool file}) {
    final noteOpen = _noteOpen ||
        (!file &&
            _note.text.isEmpty &&
            noteExpected(
              _read.isAddress ? _read.address : _recipient.text.trim(),
              codeNote: _activeRequest?.noteRequired ?? false,
            ));
    final l = context.l10n;
    final t = context.tokens;
    final summary = ref.watch(homeProvider).value?.summary;
    final price = ref.watch(priceProvider).value;
    final currency = ref.watch(appSettingsProvider).value?.fiatCurrency ?? 'usd';
    final amount = _parsedAmount;
    final estimate = _estimate;
    final gate = _gate;
    // The other unit under the figure.
    String? fiat;
    if (price != null) {
      // With nothing typed yet the line still shows (at zero), so the unit can be switched first.
      final shown = amount ?? BigInt.zero;
      fiat = _fiatEntry ? approxText(epicText(l, shown)) : phoneFiat(l, shown, (hidden: false, price: price, currency: currency), approx: true) ?? '';
    }
    // A code's amount: "Requested by the code" while the field holds it, what it asked for once
    // changed; and its minimum.
    final asked = file ? null : _activeRequest?.amount;
    final fromCode = asked != null && amount == asked;
    final markers = [
      if (asked != null) fromCode ? l.sendAmountFromCode : l.sendAmountCodeAsked(epicText(l, asked)),
      if (!file && _activeRequest?.minimum != null) l.sendMinimumAmount(epicText(l, _activeRequest!.minimum!)),
    ];
    final minimum = file ? null : _activeRequest?.minimum;
    final held = [
      if (summary != null && summary.spendable == BigInt.zero) ...[
        if (summary.locked > BigInt.zero) l.balanceLineOnHold(epicText(l, summary.locked)),
        if (comingIn(summary) > BigInt.zero) l.balanceLineComingIn(epicText(l, comingIn(summary))),
      ],
    ];
    // What is left, or why not: the line under the figure.
    Widget? status;
    if (_estimateError != null) {
      status = ErrorText(_estimateError!);
    } else if (gate.notEnough && summary != null) {
      final need = (estimate != null && estimate.amount == amount ? estimate.amount + estimate.fee : amount) ?? BigInt.zero;
      final over = need - summary.spendable;
      status = over > BigInt.zero
          ? KitAfterLine(
              line: l.phoneSendOver(KitAfterLine.first),
              figures: [epicFor(l, over, unit: false)],
              bad: true,
              oneLine: true,
              textKey: sendNotEnoughKey,
            )
          : KitAfterLine(line: l.errorNotEnoughFunds, bad: true, textKey: sendNotEnoughKey);
    } else if (estimate != null && amount != null && summary != null) {
      // The fee is the one of this Max estimate; with none for this amount the line names no figure.
      status = _maxUsed
          ? KitAfterLine(
              line: estimate.amount == amount ? l.phoneSendMaxNote(epicFor(l, estimate.fee, unit: false)) : l.phoneSendMaxNoteNoFee,
              live: true,
            )
          : KitLeavesLine(
              amount: epicFor(l, summary.spendable - estimate.amount - estimate.fee, unit: false),
              fee: epicFor(l, estimate.fee, unit: false),
            );
    } else if (_amountError != null && !_amount.text.endsWith(_point(l))) {
      status = Padding(
        padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
        child: LiveFieldError(_amountError!),
      );
    }
    final unit = _fiatEntry ? currency.toUpperCase() : epicUnit;
    final noteText = _note.text.trim();
    return [
      // `.big`: 44 under the bar (the list's own 14 is part of it).
      // A long figure (50) sits 8 lower than the 68 one, as the frame's margin says.
      SizedBox(height: _amount.text.length > 8 ? 38 : 30),
      Focus(
        autofocus: true,
        onKeyEvent: _amountKey,
        child: Stack(
        alignment: Alignment.topCenter,
        children: [
          KitAmountDisplay(
            amount: _amount.text,
            unit: unit,
            fiat: fiat,
            dimFraction: _maxUsed && !gate.notEnough,
            point: _point(l),
            swapReachBelow: Kit.hitTarget - 14 - 18,
            onSwap: price != null || _fiatEntry ? _toggleUnit : null,
            swapId: file ? null : TrustIds.sendSwap,
            semanticsId: file ? null : TrustIds.sendAmount,
          ),
          // The real field: hidden, out of the layout and never focused; the tests and the
          // drivers write to it. The hardware keyboard is [_amountKey], on the page's Focus.
          Positioned(
            left: 0,
            top: 0,
            child: ExcludeSemantics(
              child: SizedBox(
                width: 1,
                height: 1,
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    key: file ? sendFileAmountFieldKey : sendAmountFieldKey,
                    controller: _amount,
                    focusNode: _amountFocus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: _onAmountChanged,
                    onSubmitted: (_) => _submitAmount(file: file),
                    decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
      // `.avail`, 24 under the fiat line (the swap target takes 16 of it, the bar's slot 1).
      SizedBox(height: fiat != null ? 7 : 15),
      if (summary != null)
        KitAvailableBar(
          available: epicFor(l, summary.spendable, unit: false),
          over: gate.notEnough,
          maxOn: _maxUsed,
          onMax: _busy ? null : _max,
          maxId: TrustIds.sendMax,
          margin: EdgeInsets.zero,
        ),
      if (status != null) Padding(padding: const EdgeInsets.only(top: 10), child: status),
      if (!file)
        if (_activeLink case final link? when amountEdited(link, _parsedAmount))
          const Padding(padding: EdgeInsets.only(top: 8), child: Align(alignment: AlignmentDirectional.centerStart, child: LinkAmountNote())),
      for (final line in markers)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(line, textAlign: TextAlign.center, style: KitType.rowSub.copyWith(color: fromCode && line == markers.first ? t.info : t.dim)),
        ),
      if (minimum != null && amount != null && amount < minimum) ...[
        const SizedBox(height: 8),
        InlineNotice(key: sendBelowMinimumKey, level: NoticeLevel.warning, text: l.sendBelowMinimum(epicText(l, minimum))),
      ],
      for (final line in held)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(line, textAlign: TextAlign.center, style: KitType.rowSub.copyWith(color: t.dim)),
        ),
      // Coins another linked device is spending: why the amount does not fit.
      if (_estimateError != null || gate.notEnough) ..._heldLines(context),
      // A device is linked and nothing goes over Epicbox: it does not see this payment.
      if (ref.watch(phoneDevices.view)?.book.linked case final linked? when ref.watch(phoneDevicesEpicboxOffProvider))
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(l.devicesEpicboxOff(linked.name), key: const ValueKey('send-devices-epicbox-off'), style: KitType.rowSub.copyWith(color: t.warn)),
        ),
      if (!_maxUsed && AdvancedOptions.has(context, AdvancedFeature.sendOptions)) _strategyPicker(context),
      if (!file)
        if (_noteWarning(l) case final warning?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InlineNotice(key: sendNoteMissingKey, level: NoticeLevel.warning, text: warning),
          ),
      if (!noteOpen)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Center(
            child: KitChip(
              noteText.isEmpty ? l.sendAddNote : noteText,
              large: true,
              icon: noteText.isEmpty ? KitIcons.add : KitIcons.message,
              semanticsId: file ? null : TrustIds.sendNote,
              onTap: () {
                setState(() => _noteOpen = true);
                _noteFocus.requestFocus();
              },
            ),
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: TextField(
            key: file ? sendFileNoteFieldKey : sendNoteFieldKey,
            controller: _note,
            focusNode: _noteFocus,
            // LEPIC signs at most this many bytes; the field stops there instead of cutting.
            inputFormatters: const [Utf8LengthLimiter(slateMessageMaxBytes)],
            // The field stays open under the fingers, however it came open.
            onChanged: (_) => setState(() => _noteOpen = true),
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => Text(
              l.sendMessageCounter(utf8Length(_note.text), slateMessageMaxBytes),
              style: KitType.rowSub.copyWith(color: t.dim),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitAmount(file: file),
            decoration: InputDecoration(
              labelText: l.sendNoteLabel,
              helperText: _activeRequest?.note != null && _note.text == _activeRequest?.note
                  ? _activeRequest!.noteRequired ? l.sendNoteRequiredHelper : l.sendNoteFromCodeHelper
                  : l.sendNoteHelper,
              helperMaxLines: 2,
            ),
          ),
        ),
    ];
  }

  /// The keypad and the page's button, pinned under the body.
  Widget _amountKeys(BuildContext context, {required Widget button}) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitKeypad(
        onDigit: _keyDigit,
        onDelete: _keyDelete,
        onDeleteLong: () {
          if (_busy) return;
          _setAmountText('');
        },
        onPoint: _keyPoint,
        idFor: sendKeyId,
        // The foot has its own 16 on each side: the keys stand 28 from the edge.
        inset: 7,
      ),
      // `.keys` end 104 above the bottom, the button's foot 34.
      const SizedBox(height: 18),
      button,
    ],
  );

  void _submitAmount({required bool file}) {
    if (!_amountReady || _busy) return;
    if (file) {
      _createFile();
      return;
    }
    // A connection that waits for Tor, or needs it, goes no further than here.
    final way = _wayOf(_toRoute, phoneTorState(ref.read(phoneTorProvider)));
    final read = _read;
    final held = _pairingTo == null && read.isAddress && _heldNow(read, watch: false);
    if (!_goes(way) || _block != NetBlock.none || held) return;
    _toReview();
  }

  List<Widget> _amountStep(BuildContext context) {
    final l = context.l10n;
    final request = _activeRequest;
    return [
      _header(context, l.sendTo(_toName(l)), onBack: _toRecipient, avatar: _toAvatar(small: true)),
      if (request != null && request.problems.isNotEmpty)
        RequestBanner(
          open: _requestBanner,
          origin: _origin ?? CodeOrigin.qr,
          problems: request.problems,
          onDismiss: () => setState(() => _requestBanner = false),
        ),
      if (_activeLink case final link?) LinkTrustLine(link: link),
      _TorNotice(way: _wayOf(_toRoute)),
      ..._amountBody(context, file: false),
    ];
  }

  /// Review, which waits while the payment's connection waits for Tor.
  Widget _amountAction() {
    final way = _wayOf(_toRoute);
    return _amountKeys(
      context,
      button: KitButton(
        key: sendReviewButtonKey,
        semanticsId: TrustIds.sendReview,
        label: way == TorWay.wait ? context.l10n.torWaiting : context.l10n.phoneSendReviewTitle,
        busy: _estimating,
        onPressed: _amountReady && !_busy && _goes(way) && _block == NetBlock.none && _hold == null ? _toReview : null,
      ),
    );
  }


  /// The review's content (HANDOFF 9, Send-3), the inside of the sheet over the amount: who it
  /// goes to, the sums, the notes, the way it goes. The buttons are [_reviewAction].
  List<Widget> _reviewStep(BuildContext context) {
    final l = context.l10n;
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
    final way = _wayOf(_toRoute, torState);
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
      final relayName = _pairingTo != null
          ? (_toPairing()?.homeRelay ?? '')
          : _failedViaMailbox
          ? (sendPairingFor(ref, to.address)?.homeRelay ?? _relay?.label ?? '')
          : (_relay?.label ?? '');
      failed = _nothingStored
          ? l.sendRelayDown(relayName)
          : _undelivered == null
          ? l.sendRelayRefusedLost(relayName)
          : l.sendRelayRefused(sendTtlDays, relayName);
    }
    return [
      if (_activeOrigin case final origin?) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(alignment: AlignmentDirectional.centerStart, child: OriginPill(origin: origin)),
        ),
        const SizedBox(height: 12),
      ],
      if (_activeLink case final link?) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LinkTrustLine(link: link),
        ),
        if (amountEdited(link, estimate.amount))
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: LinkAmountNote()),
        const SizedBox(height: 8),
      ],
      _reviewTo(context, pairing),
      // Keys changed, or no mailbox yet: the words say why this is not sealed.
      if (pairing != null && !pairing.paysByMailbox)
        Padding(
          padding: const EdgeInsets.fromLTRB(Kit.gutter, 0, Kit.gutter, 12),
          child: SendPairingMailbox(
            pairing: pairing,
            name: _pairingNameOf(pairing.id),
            onCheck: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: pairing.id, recheck: true)),
            ),
          ),
        ),
      KitGroup(
        onSheet: true,
        dividerInset: Kit.dividerInsetPlain,
        children: [
          KitKv(label: l.sendStepAmount, value: epicExact(l, estimate.amount)),
          KitKv(label: l.sendNetworkFee, value: epicExact(l, estimate.fee)),
          // The amount, then the fiat estimate of the total (fee included) under it.
          KitKv(
            label: l.sendReviewTotal,
            labelStrong: true,
            value: epicExact(l, total),
            valueWeight: FontWeight.w500,
            sub: phoneFiat(l, total, (hidden: false, price: price, currency: currency), approx: true),
          ),
          // What the recipient will read, as entered; the history keeps it as the private note.
          if (_noteText.isNotEmpty) KitKv(key: sendReviewMessageKey, label: l.phoneSendNoteLabel, valueText: _noteText),
          TrustId(
            TrustIds.sendReviewMore,
            child: KitKv(
              label: l.phoneSendMoreDetails,
              chevron: !_reviewMore,
              onTap: () => setState(() => _reviewMore = !_reviewMore),
            ),
          ),
          if (_reviewMore) ..._reviewMoreRows(
            context,
            way: way,
            torState: torState,
            balanceAfter: spendable != null && spendable >= total ? spendable - total : null,
            locked: spendable != null &&
                    spendable >= total &&
                    outputsShown(context, ref) &&
                    estimate.locked > total &&
                    estimate.locked <= spendable
                ? spendable - estimate.locked
                : null,
            mailbox: pairing ?? _addressMailbox(),
            cancelNote: !_sendFailed,
          ),
        ],
      ),
      // Strategy All is a consolidating send: its change is one output, never split.
      if (_sendOptions?.strategy == SelectionStrategy.all && estimate.change > BigInt.zero)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            l.sendUsesAllOutputs(estimate.inputCount),
            key: sendUsesAllOutputsKey,
            style: KitType.rowSub.copyWith(color: t.dim),
          ),
        ),
      // The message the code or the address expects is empty: a warning, the user may send.
      if (_noteWarning(l) case final warning? when !_sendFailed) ...[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
          child: InlineNotice(key: sendReviewNoteMissingKey, level: NoticeLevel.warning, text: warning),
        ),
      ],
      // Under a code's minimum, as Max may land: a warning, the payee decides what it credits.
      if (_activeRequest?.minimum case final minimum? when estimate.amount < minimum && !_sendFailed) ...[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
          child: InlineNotice(key: sendReviewBelowMinimumKey, level: NoticeLevel.warning, text: l.sendBelowMinimum(epicText(l, minimum))),
        ),
      ],
      const SizedBox(height: 14),
      _ReadyLine(
        checks: checks,
        sending: _busy,
        failed: failed,
        tor: tor,
        http: overHttp,
        way: way,
        queued: queued,
        // The frame's line in place of "Ready to send": whether their wallet can be offline.
        ready: KitHint(
          to.kind == RecipientKind.epicbox || pairing != null
              // A raw address is no name: without one the line says "their".
              ? (_pairingTo != null || _contact != null || _contactName(_read.address) != null
                    ? l.phoneSendReviewHintOffline(_toName(l))
                    : l.phoneSendReviewHintOfflineNoName)
              : l.sendFactOnline,
        ),
      ),
      // An address whose relay the app does not know may be mistyped: a warning, not a block.
      if (checks.unknownRelay case final unknown? when !_sendFailed) ...[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
          child: InlineNotice(key: sendUnknownRelayKey, level: NoticeLevel.warning, text: l.sendRelayUnknown(unknown.label)),
        ),
      ],
      // Epicbox off: the mailbox payment waits in the outbox until it is on again.
      if (queued && !_sendFailed) ...[
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
          child: InlineNotice(key: sendQueuedCardKey, level: NoticeLevel.info, text: l.sendQueuedEpicboxOff),
        ),
      ],
    ];
  }

  /// Who it goes to (Send-3): the face, the name, the short address with its ends in gold, and
  /// the Sealed chip when the payment goes through a pairing's mailbox. A contact with more than
  /// one address gets a sheet of them behind the row.
  Widget _reviewTo(BuildContext context, PairingRecord? pairing) {
    final l = context.l10n;
    final to = _read;
    final t = context.tokens;
    final contact = _contact;
    final name = _toName(l);
    final sealedBy = pairing ?? _addressMailbox();
    final sealed = sealedBy != null && sealedBy.paysByMailbox;
    final ownServer = ownEpicboxServer(ref);
    final short = to.isUrl ? to.address : shortAddress(to.address, ownServer: ownServer);
    final mono = KitType.address.copyWith(color: t.text, fontSize: 12.5);
    final several = contact != null && contact.addresses.length > 1 && !_sendFailed && !_busy;
    // A pairing with no address of its own (paid through its mailbox) names none; a short address
    // that is already the name (with or without the own server cut) is not said twice.
    final nameless = _pairingTo != null || name == short || (!to.isUrl && name == shortAddress(to.address));
    Widget address() {
      if (nameless) return const SizedBox.shrink();
      final cut = short.indexOf('…');
      if (cut < 0) return Text(short, style: mono, maxLines: 1, overflow: TextOverflow.ellipsis);
      final at = short.indexOf('@', cut);
      final gold = TextStyle(color: t.accentText);
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text.rich(
          TextSpan(
            style: mono,
            children: [
              TextSpan(text: short.substring(0, cut), style: gold),
              const TextSpan(text: ' … '),
              TextSpan(text: short.substring(cut + 1, at < 0 ? short.length : at), style: gold),
              if (at >= 0) TextSpan(text: short.substring(at), style: TextStyle(color: t.dim)),
            ],
          ),
          maxLines: 1,
          softWrap: false,
        ),
      );
    }

    final row = Padding(
      // `.row` with padding 14 20 12.
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        children: [
          _toAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: KitType.rowTitle.copyWith(color: t.text)),
                if (!nameless) ...[const SizedBox(height: 3), address()],
              ],
            ),
          ),
          if (sealed) ...[
            const SizedBox(width: 12),
            KitChip(l.trustSealed, bright: true, leading: Icon(EpicGlyphs.sealed, size: 12, color: t.accentText)),
          ],
          if (several) ...[
            const SizedBox(width: 8),
            Icon(KitIcons.chevron, size: 22, color: t.faint),
          ],
        ],
      ),
    );
    return TrustId(
      TrustIds.sendReviewTo,
      child: several
          ? Semantics(
              button: true,
              label: l.sendRouteChange,
              child: InkWell(onTap: () => _addressesSheet(context, contact, to, review: true), child: row),
            )
          : row,
    );
  }

  /// The rows "More details" opens: the method (with what it asks of their wallet), the host as
  /// contacted, a plain http connection, Tor to start, and what stays after this send.
  List<Widget> _reviewMoreRows(
    BuildContext context, {
    required TorWay way,
    required TorState torState,
    BigInt? balanceAfter,
    BigInt? locked,
    PairingRecord? mailbox,
    bool cancelNote = false,
  }) {
    final l = context.l10n;
    final read = _pairingTo != null ? null : _read;
    final epicbox = read == null || read.kind == RecipientInputKind.epicbox;
    final mode = AdvancedOptions.of(context).networkMode;
    final name = read == null ? l.methodEpicbox : sendMethodName(l, read);
    Widget fact(String label, String value, {String? sub, bool mono = false}) =>
        KitKv(label: label, value: mono ? value : null, valueText: mono ? null : value, sub: sub);
    return [
      fact(
        l.sendFactVia,
        way == TorWay.overTor && read?.kind != RecipientInputKind.onion ? metaLine([name, l.sendRouteOverTor]) : name,
        sub: epicbox ? l.sendFactOffline : l.sendFactOnline,
      ),
      // The pairing's mailbox: where it goes and whether it is paused.
      if (mailbox != null && mailbox.paysByMailbox)
        fact(
          l.sendRoutePaired,
          ref.watch(pairNetProvider) == PairNet.epicboxOff ? l.contactPausedEpicboxOff : sendRoutePairedLineOf(l, mailbox),
        ),
      if (_noteText.isNotEmpty) fact(l.phoneSendNoteLabel, l.sendReviewMessageKept),
      if (read != null && read.isUrl) fact(l.sendFactHost, read.contacted, mono: true),
      if (read != null && read.plainHttpToOther) fact(l.sendFactConnection, l.sendFactNotEncrypted),
      if (torBuilt && read?.kind == RecipientInputKind.onion && torState == TorState.off && mode != NetworkMode.torOnly)
        fact(l.sendFactTor, l.sendFactTorStarts),
      if (balanceAfter != null) fact(l.sendBalanceAfter, epicExact(l, balanceAfter), mono: true),
      if (locked != null) fact(l.sendAvailableWhileConfirms, epicExact(l, locked), sub: l.sendSpendableUntilChangeHint, mono: true),
      // The cancel rule for this method, with the way to the Help topic (CancelNote).
      if (cancelNote)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 13),
          child: CancelNote(
            text: epicbox ? l.sendCancelRuleEpicbox : l.sendCancelRuleDirect,
            anchor: HelpAnchor.sending,
          ),
        ),
    ];
  }

  Widget _reviewAction(BuildContext context) {
    final l = context.l10n;
    final checks = ref.watch(sendPreflightProvider(_relay));
    final relayDown = checks.relayOutcome == CheckOutcome.failed;
    // Without a node answer the send could not be built or posted, and a connection that
    // waits for Tor does not go; an onion with Tor off starts it on the tap.
    final way = _wayOf(_toRoute);
    // A pairing whose keys changed meanwhile holds the send until the words are checked.
    final pairs = _pairingTo == null || (_toPairing()?.paysByMailbox ?? false);
    final canSend =
        checks.ready &&
        !_busy &&
        _goes(way) &&
        _block == NetBlock.none &&
        _hold == null &&
        pairs &&
        _gate.ready;
    // The Send button names the exact amount, as the review above it (a commit surface).
    final amount = epicExact(l, _estimate!.amount);
    final quiet = _ghostStyle(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The send failed and LEPIC holds the payment: never a second send from here.
        if (_sendFailed && _cancelFailed)
          BusyButton(kit: true, semanticsId: TrustIds.commonDone, label: l.commonDone, onPressed: _done)
        // Over Tor or HTTP the waiting payment is delivered again, or cancelled.
        else if (_sendFailed &&
            (_overTor || _overHttp) &&
            _undelivered != null) ...[
          BusyButton(
            kit: true,
            key: sendTryAgainKey,
            label: l.sendTryAgain,
            busy: _busy,
            onPressed: _resendDirect,
          ),
          const SizedBox(height: 6),
          // The one destructive look (UP-012): gold says go, not stop.
          DangerButton(
            key: sendCancelPaymentKey,
            onPressed: _busy ? null : _cancelDirectSend,
            child: Text(l.sendCancelPayment),
          ),
        ] else if (_sendFailed && _overTor) ...[
          // Tor did not connect, nothing was sent: the same send again.
          BusyButton(
            kit: true,
            key: sendTryAgainKey,
            label: l.sendTryAgain,
            busy: _busy,
            onPressed: _send,
          ),
          const SizedBox(height: 6),
          TextButton(
            style: quiet,
            onPressed: _busy ? null : _done,
            child: TrustId(TrustIds.commonDone, child: Text(l.commonDone)),
          ),
        ] else if (_sendFailed && _failedViaMailbox && _pairingTo == null) ...[
          // The pairing's relay did not take it: the same payment to the contact's public
          // Epicbox address, the one in To. A held payment is cancelled first.
          BusyButton(
            kit: true,
            key: sendPublicFallbackKey,
            label: l.sendPublicFallback,
            busy: _busy,
            onPressed: _sendPublicFallback,
          ),
          const SizedBox(height: 6),
          if (_undelivered != null)
            TextButton(
              style: quiet,
              onPressed: _busy ? null : _cancelAndFile,
              child: Text(l.sendCancelAndFile),
            )
          else if (_nothingStored)
            TextButton(
              style: quiet,
              onPressed: _busy ? null : _toFileRoute,
              child: Text(l.sendPayWithFile),
            ),
          TextButton(
            style: quiet,
            onPressed: _busy ? null : _done,
            child: Text(_undelivered != null ? l.sendLeaveIt : l.commonDone),
          ),
        ] else if (_sendFailed && _undelivered != null) ...[
          BusyButton(
            kit: true,
            label: l.sendCancelAndFile,
            busy: _busy,
            onPressed: _cancelAndFile,
          ),
          const SizedBox(height: 6),
          TextButton(
            style: quiet,
            onPressed: _busy ? null : _done,
            child: Text(l.sendLeaveIt),
          ),
        ] else if (_sendFailed && _nothingStored) ...[
          // Nothing is held, so a file is the one payment.
          BusyButton(
            kit: true,
            label: l.sendPayWithFile,
            onPressed: _busy ? null : _toFileRoute,
          ),
          const SizedBox(height: 6),
          TextButton(
            style: quiet,
            onPressed: _busy ? null : _done,
            child: TrustId(TrustIds.commonDone, child: Text(l.commonDone)),
          ),
        ] else if (_sendFailed)
          BusyButton(kit: true, semanticsId: TrustIds.commonDone, label: l.commonDone, onPressed: _done)
        // Their relay is down before any attempt: nothing is stored yet.
        else if (relayDown) ...[
          BusyButton(
            kit: true,
            label: l.sendPayWithFile,
            onPressed: _busy ? null : _toFileRoute,
          ),
          const SizedBox(height: 6),
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
            kit: true,
            semanticsId: TrustIds.sendConfirm,
            label: _queues() ? l.sendQueue : l.sendReviewSendButton(amount),
            busyLabel: l.sendSending,
            busy: _busy,
            onPressed: canSend ? _send : null,
          ),
          const SizedBox(height: 6),
          TextButton(
            style: quiet,
            onPressed: _busy ? null : _backToAmount,
            child: TrustId(TrustIds.sendReviewEdit, child: Text(l.sendReviewEdit)),
          ),
        ],
      ],
    );
  }

  Widget _doneAction() =>
      BusyButton(kit: true, semanticsId: TrustIds.commonDone, label: context.l10n.commonDone, onPressed: _done);

  /// The Sent page (HANDOFF 9, Send-4): "On its way to Tom", the payment's own steps as the
  /// payment page lists them, and what to do when it does not finish.
  List<Widget> _trackerStep(BuildContext context, _Sent sent) {
    final l = context.l10n;
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
      _header(context, '', onClose: _done);
      return [NotPostedNotice(tx: live)];
    }
    final pairingId = sent.pairingId;
    final name = pairingId != null ? _pairingNameOf(pairingId) : _contactName(sent.to.address);
    final who = name ?? shortAddress(sent.to.address);
    final confirmations = txConfirmations(live, tip) ?? 0;
    final waiting = track == SendTrack.waitingRecipient;
    // The payment's own steps; the wallet waited on is the current step's line. Queued while
    // Epicbox is off, the send itself is the step under way.
    final fee = live.fee ?? sent.tx.fee ?? BigInt.zero;
    final progress = paymentProgress(
      l,
      live,
      tip,
      now: ref.read(clockProvider)(),
      who: name,
      target: target,
      reserved: epicText(l, sent.amount + fee),
      paused: pairingId != null && ref.watch(pairNetProvider) == PairNet.epicboxOff,
      killSwitch: NetGate.killSwitch,
    );
    final unknown = name == null;
    // Over HTTP or Tor their wallet took it in the exchange itself: past cancelling, and
    // waiting only for a block.
    final delivered =
        sent.to.kind != RecipientKind.epicbox &&
        track == SendTrack.confirming &&
        !live.posting &&
        confirmations == 0;
    final declined = track == SendTrack.cancelled && receiverDeclined(live);
    final cancelled = track == SendTrack.cancelled;
    final noteText = _noteText;
    _header(context, '', onClose: _done);
    return [
      // Send-4: the ring 36 under the bar (the body's 14 is part of it), the title 28 under it.
      const SizedBox(height: 22),
      Center(child: KitResultMark(ok: !cancelled)),
      const SizedBox(height: 28),
      Semantics(
        header: true,
        liveRegion: true,
        child: Text(
          declined
              ? l.txStatusReceiverDeclined
              : cancelled
              ? l.sendTrackCancelled
              : l.phoneSendOnItsWayTo(who),
          textAlign: TextAlign.center,
          style: KitType.pageTitle.copyWith(fontSize: 26, letterSpacing: -0.52, color: t.text),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        declined
            ? l.txDetailsReceiverDeclined
            : metaLine([epicText(l, sent.amount), if (noteText.isNotEmpty) noteText]),
        textAlign: TextAlign.center,
        style: (declined ? KitType.body : KitType.address.copyWith(fontSize: 17)).copyWith(color: t.dim),
      ),
      const SizedBox(height: 32),
      // Made while Epicbox was off: it waits in the outbox.
      if (sent.queued && name != null && waiting) ...[
        Semantics(
          liveRegion: true,
          child: Text(
            l.sendQueuedHeadline,
            key: sendQueuedHeadlineKey,
            style: KitType.rowTitle.copyWith(color: t.text),
          ),
        ),
        const SizedBox(height: 4),
        Text(l.sendQueuedBody(name), style: KitType.rowSub.copyWith(color: t.dim)),
        const SizedBox(height: 16),
      ],
      if (delivered) ...[
        Semantics(
          liveRegion: true,
          child: Text(l.sendDeliveredWaitingBlock, style: KitType.rowTitle.copyWith(color: t.text)),
        ),
        const SizedBox(height: 12),
      ],
      if (!cancelled && progress != null) KitSteps(steps: progress.steps, margin: EdgeInsets.zero),
      if (sent.changedFee case final fee?) ...[
        const SizedBox(height: 12),
        Text(
          l.sendResultFeeChanged(epicText(l, fee), epicText(l, sent.reviewedFee!)),
          style: KitType.rowSub.copyWith(color: t.dim),
        ),
      ],
      if (!sent.noteSaved) ...[
        const SizedBox(height: 12),
        Text(l.sendResultNoteNotSaved, style: KitType.rowSub.copyWith(color: t.dim)),
      ],
      if (waiting || unknown) ...[
        const SizedBox(height: 12),
        KitGroup(
          margin: EdgeInsets.zero,
          dividerInset: Kit.dividerInsetPlain,
          children: [
            // Send-4-Sent: this row's title is regular weight.
            if (waiting) KitRow(title: l.sendTrackIfNot, titleStyle: const TextStyle(fontWeight: FontWeight.w400), chevron: true, onTap: () => _ifNotSheet(context), semanticsId: TrustIds.sendTrackIfNot),
            if (unknown)
              KitRow(
                title: l.phoneSendAddContact,
                leading: KitIconWell(KitIcons.add, color: t.accentText),
                chevron: true,
                onTap: () => _saveContact(sent.to.address, name: sent.linkLabel),
                semanticsId: TrustIds.sendTrackAddContact,
              ),
          ],
        ),
      ],
    ];
  }

  /// "What if it never finishes?": the payment is cancelled by itself after a while, and the help
  /// topic says more.
  Future<void> _ifNotSheet(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return showKitSheet<void>(
      context: context,
      builder: (sheet) => KitSheet(
        title: l.sendTrackIfNot,
        primaryLabel: l.sendHelp,
        onPrimary: () {
          Navigator.of(sheet).pop();
          openHelp(context, HelpId.send);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(l.sendResultAutoCancel(sendTtlDays), style: KitType.body.copyWith(color: t.dim)),
        ),
      ),
    );
  }

  /// `.btn.ghost` at the frames' 44: dim text, weight 500, no ground.
  ButtonStyle _ghostStyle(BuildContext context) => TextButton.styleFrom(
    foregroundColor: context.tokens.dim,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    minimumSize: const Size.fromHeight(44),
    textStyle: KitType.button.copyWith(fontWeight: FontWeight.w500),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Kit.rButton)),
  );

  /// Done, and a quiet way to the payment's own page.
  Widget _sentAction(_Sent sent) {
    final l = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BusyButton(kit: true, semanticsId: TrustIds.commonDone, label: l.commonDone, onPressed: _done),
        const SizedBox(height: 6),
        TextButton(
          style: _ghostStyle(context),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => TxDetailsScreen(txKey: sent.tx.key)),
          ),
          child: TrustId(TrustIds.sendViewpayment, child: Text(l.phoneSendViewPayment)),
        ),
      ],
    );
  }

  List<Widget> _fileAmountStep(BuildContext context) {
    final l = context.l10n;
    return [
      _header(
        context,
        _viaQr ? MethodIcons.fullName(l, MethodKind.directQr) : l.sendFileTitle,
        onBack: _toRecipient,
        // The file way has its own help; the QR way keeps the "How it works".
        onHelp: _viaQr ? null : () => showFileExchangeHelp(context, role: FileExchangeRole.sender),
      ),
      // The strip that says what the way means; no method selector: the back arrow goes to
      // the recipient, whose field picks the method.
      ..._sealChoice(context),
      ..._amountBody(context, file: true),
      const SizedBox(height: 12),
      CancelNote(
        text: _viaQr ? l.sendCancelRuleQr : l.sendCancelRuleFile,
        anchor: HelpAnchor.sending,
      ),
    ];
  }

  Widget _fileAmountAction() => _amountKeys(
    context,
    button: KitButton(
      label: _viaQr ? context.l10n.sendMakeQr : context.l10n.sendMakeFile,
      busy: _estimating,
      onPressed: _amountReady && !_busy ? _createFile : null,
    ),
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
        _header(context, MethodIcons.fullName(l, MethodKind.directQr), onClose: _done),
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
    final amountText = epicExact(l, _parsedAmount ?? BigInt.zero);
    // What waits for the reply is the amount and its fee, as the frame writes it (12.508).
    final estimate = _estimate;
    final heldText = estimate != null && estimate.amount == _parsedAmount
        ? epicExact(l, estimate.amount + estimate.fee)
        : amountText;
    return [
      // Back leaves, as on the frame; Share file is the one primary until the file is handed
      // over, then Open their reply (a row, not a foot button) is the way on.
      _header(
        context,
        l.sendPayByFile,
        onBack: _done,
        strip: KitStepStrip(labels: [l.phoneStepPayFileSend, l.phoneStepPayFileReply, l.commonDone], current: _fileHandedOver ? 1 : 0),
      ),
      // The body's own 16 above, then to the frame's 22 under the strip.
      const SizedBox(height: 8),
      KitHeroAmount(amount: epicFor(l, _parsedAmount ?? BigInt.zero, surface: AmountSurface.exact, unit: false), unit: epicUnit),
      const SizedBox(height: 28),
      FileCard(
        title: l.phoneFilePayCard,
        sub: l.phoneFileMadeSub(amountText, fileMadeTime(context, _fileMadeAt ??= ref.read(clockProvider)())),
      ),
      const SizedBox(height: 12),
      SlateFileButtons(
        name: name,
        json: _plainCopy ?? slate.json,
        primary: !_fileHandedOver,
        framed: true,
        saveApart: true,
        hint: FileInfoLine(l.phoneFileSendHint),
        onHandedOver: () {
          if (!_fileHandedOver) setState(() => _fileHandedOver = true);
        },
      ),
      const SizedBox(height: 26),
      FileNextLabel(l.phoneFileWhenReply),
      KitGroup(
        margin: EdgeInsets.zero,
        children: [
          KitRow(
            key: sendOpenReplyKey,
            title: l.phoneStepPayFileReply,
            subtitle: l.phoneFileOpenReplySub,
            leading: const KitIconWell(KitIcons.fileUp, iconSize: 20),
            chevron: true,
            semanticsId: TrustIds.fileReply,
            onTap: _busy || _postBlock != NetBlock.none ? null : _openReply,
          ),
        ],
      ),
      // `.note`: 8 under the group.
      const SizedBox(height: 8),
      FileInfoLine(l.phoneFileHeld(heldText), bare: true),
      // Save to device under the frame's last line: its frame has no room above.
      SlateFileButtons(name: name, json: _plainCopy ?? slate.json, framed: true, saveOnly: true),
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
      const SizedBox(height: 8),
      // The frame ends on the one danger action: the payment is held until a reply comes.
      KitButton(
        key: sendCancelPaymentKey,
        label: l.sendCancelPayment,
        kind: KitButtonKind.danger,
        semanticsId: TrustIds.fileCancel,
        busy: _busy,
        onPressed: _busy ? null : _cancelFile,
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
    final quiet = sealQuiet(target, DateTime.now());
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
            // The rows are list tiles: they paint their ink on a Material, not on the card's box.
            RadioGroup<bool>(
              groupValue: _filePlain,
              onChanged: (v) => setState(() => _filePlain = v ?? false),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    RadioRow<bool>(
                      key: sendSealedOptionKey,
                      value: false,
                      title: l.sendSealedOption,
                      subtitle: l.sendSealedOptionHint(name),
                    ),
                    RadioRow<bool>(
                      key: sendPlainOptionKey,
                      value: true,
                      title: l.sendPlainOption,
                      subtitle: l.sendPlainOptionHint,
                    ),
                  ],
                ),
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
    final file = sealedFileName(slate.slateId, text: sealed);
    return [
      _header(context, l.sendFileTitle, onClose: _done),
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
        child: TrustId(TrustIds.commonDone, child: Text(l.commonDone)),
      ),
    ];
  }

  /// "Send as plain instead" (RFC 9.3): asks first, then hands over the same payment unsealed.
  Future<void> _sendAsPlain(Slate slate) async {
    final l = context.l10n;
    final sure = await confirmAppDialog(
      context,
      title: l.sendAsPlainTitle,
      icon: Icons.lock_open_outlined,
      tone: DialogTone.warn,
      description: l.sendAsPlainBody,
      cancelLabel: l.sendKeepSealed,
      confirmLabel: l.sendPlain,
      confirmKey: sendAsPlainConfirmKey,
    );
    if (!sure || !mounted) return;
    await _run((session) async {
      final plain = await session.pairing.plainSlate('s:${slate.slateId}');
      if (mounted) setState(() => _plainCopy = plain);
    });
  }

  /// The foot of the file-made step. The plain file route has none: Open their reply is a row
  /// on the page.
  Widget? _openReplyAction() {
    final l = context.l10n;
    final off = _busy || _postBlock != NetBlock.none;
    if (!_viaQr && !(_sealedText != null && _sealedFor != null && _plainCopy == null)) return null;
    if (_viaQr) {
      return KitButton(
        key: sendScanReplyKey,
        icon: KitIcons.scan,
        label: l.qrScanReply,
        semanticsId: TrustIds.fileReply,
        onPressed: off || !offersQrPayment(ref) ? null : _scanReply,
      );
    }
    // Quiet until the file is saved or shared, then the primary (UP-008).
    return KitButton(
      key: sendOpenReplyKey,
      label: l.sendOpenReply,
      kind: _fileHandedOver ? KitButtonKind.gold : KitButtonKind.quiet,
      semanticsId: TrustIds.fileReply,
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
      _header(context, _viaQr ? MethodIcons.fullName(l, MethodKind.directQr) : l.sendFileTitle, onClose: _done),
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
                      HostText(host, style: theme.textTheme.titleMedium),
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
              child: InlineTextButton(
                icon: const Icon(Icons.person_add_alt, size: 18),
                onPressed: onSave,
                child: Text(l.sendSaveContact),
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

/// An address on the recipient card: [MarkedAddress] at the card's small size.
class AddressEnds extends StatelessWidget {
  const AddressEnds({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context) => MarkedAddress(
    address,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
  );
}

/// Under To while Tor is on but not connected, for a payment that goes over it: "Tor is not
/// connected." with Retry. Nothing falls back to the clearnet. An onion with Tor off needs no
/// notice (Tor starts on the tap), and plain http with Tor on is a hold of its own.
class _TorNotice extends ConsumerWidget {
  const _TorNotice({required this.way});

  final TorWay way;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    // Without Tor in the app the address's own error says so.
    if (!torBuilt || way != TorWay.blocked) return const SizedBox.shrink();
    // Offline: Tor never runs there; the form's Offline line gives the reason (LNX-12).
    if (watchNetBlock(context, ref).byMode) return const SizedBox.shrink();
    final tor = ref.read(phoneTorProvider.notifier);
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
                  Icon(Icons.error_outline, size: 18, color: t.risk),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(l.torNotConnectedNotice, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
            // Retry only (D-05): turning Tor off is never the fix an error offers.
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
              onPressed: tor.retry,
              child: Text(l.commonRetry),
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

/// The contact's avatar ([PairAvatar], as in Contacts and on the contact page), or a person
/// in the same tile for a new recipient.
/// The trust id of a key of the amount keypad (digits, [KitKey.point], [KitKey.delete]).
String? sendKeyId(String key) => switch (key) {
  '0' => TrustIds.sendKey0,
  '1' => TrustIds.sendKey1,
  '2' => TrustIds.sendKey2,
  '3' => TrustIds.sendKey3,
  '4' => TrustIds.sendKey4,
  '5' => TrustIds.sendKey5,
  '6' => TrustIds.sendKey6,
  '7' => TrustIds.sendKey7,
  '8' => TrustIds.sendKey8,
  '9' => TrustIds.sendKey9,
  KitKey.point => TrustIds.sendKeyPoint,
  KitKey.delete => TrustIds.sendKeyDelete,
  _ => null,
};

class _Initial extends StatelessWidget {
  const _Initial({this.name});

  final String? name;
  static const double size = 40;

  @override
  Widget build(BuildContext context) {
    final name = this.name;
    // Brackets, punctuation and emoji never show: a name without letters gets the person.
    final named = name != null && nameInitials(name, phone: true).isNotEmpty;
    return ExcludeSemantics(
      child: named
          ? PairAvatar(name: name, size: size)
          : GlyphTile(size: size, child: Icon(Icons.person_outline, size: size / 2, color: context.tokens.dim)),
    );
  }
}

/// The body of a step of the flow (wallet.css `.field` to `.foot`): the steps' own 16 beside
/// the content, the first 14 under the bar, and the button at the foot with no rule above it,
/// 6 from the notes over it, clear of the keyboard and the home bar.
class _FlowBody extends StatelessWidget {
  const _FlowBody({required this.children, this.bottom});

  final List<Widget> children;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final bottom = this.bottom;
    final list = ListView(padding: DockSlack.pad(context, const EdgeInsets.fromLTRB(16, 14, 16, 16)), children: children);
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          // One Column whether or not a footer follows: the list keeps its place in the tree, so
          // a text field in it keeps its focus and the keyboard when the footer appears (an
          // address typed by hand turns valid and the way on shows).
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: list),
              if (bottom != null) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: bottom),
            ],
          ),
        ),
      ),
    );
  }
}

/// One person or address in the Who lists: the name where known, else the short address, a
/// round avatar before it, a chevron after.
class _WhoRow extends StatelessWidget {
  const _WhoRow({required this.address, this.name, this.subtitle, required this.onTap, this.ownServer});

  final String address;
  final String? name;

  /// Words in place of the short address (a contact paid through its pairing, "Not saved").
  final String? subtitle;
  final VoidCallback onTap;

  /// The wallet's own relay, which a row leaves out of the address.
  final String? ownServer;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // `.rt .mono`: 12.5 under a name; the title of a row with no name is the address, 14.
    final mono = KitType.address.copyWith(color: t.dim, fontSize: 12.5);
    return KitRow(
      leading: name == null ? const KitAvatar(icon: KitIcons.contact, neutral: true) : KitAvatar(initials: nameInitials(name!, phone: true)),
      title: name ?? shortAddress(address, ownServer: ownServer),
      titleStyle: name == null ? KitType.address.copyWith(fontSize: 14) : null,
      subtitle: subtitle,
      subtitleWidget: name != null && subtitle == null ? ShortAddressText(address, style: mono, ownServer: ownServer) : null,
      chevron: true,
      onTap: onTap,
      semanticsId: TrustIds.sendRecent,
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
    this.ready,
  });

  /// Shown in place of the "Ready to send" line when the checks pass (Send-3's hint).
  final Widget? ready;

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
    final ready = this.ready;
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
      // An onion with Tor off: Tor starts on the tap (the Tor row says so).
      _ when tor != null => (
        Icon(Icons.check, size: 18, color: t.ok),
        l.sendTorReady,
        t.dim,
        null,
      ),
      _ when http && ready != null => (const SizedBox.shrink(), '', t.dim, null),
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
      _ when ready != null => (const SizedBox.shrink(), '', t.dim, null),
      _ => (Icon(Icons.check, size: 18, color: t.ok), l.sendReady, t.dim, null),
    };
    if (text.isEmpty && ready != null) return Semantics(liveRegion: true, child: ready);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Semantics(
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
    ),
    );
  }
}
