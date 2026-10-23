import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../app_log.dart';
import '../amount.dart';
import '../contacts.dart';
import '../demo.dart' show demoModeProvider;
import '../errors.dart';
import '../l10n.dart';
import '../network.dart';
import '../phone_tor.dart';
import '../price.dart';
import '../providers.dart';
import '../send_preflight.dart';
import '../settings.dart';
import '../smart_outputs.dart' show planSessionSend;
import '../slate_files.dart';
import '../tor_phone.dart';
import '../tor_routes.dart';
import '../wallet_service.dart';
import 'centered_body.dart';
import 'common.dart';
import 'contacts_screen.dart';
import 'demo_screens.dart' show TestCoinsButton;
import 'file_exchange_help.dart';
import 'handshake.dart';
import 'help_screen.dart';
import 'method_strip.dart';
import 'pin.dart' show askPin;
import 'scan_screen.dart';
import 'shell_header.dart' show comingIn;
import 'send_tracker.dart';
import 'slate_file_screen.dart';
import 'theme/brand.dart';
import 'theme/protocol.dart' show TimelineState, TimelineStep;
import 'theme/tokens.dart';
import 'tor_ui.dart';

// Sending, in three steps: the recipient, the amount, a review with quiet checks; then a
// tracker that follows the payment as both wallets finish it. A method selector on top picks
// Epicbox, HTTP, Tor or File, and follows the kind of address given. A payment file is also
// the fallback when their relay does not answer.

/// The most EPIC that will ever exist, 21 million. Anything above is a typo.
final BigInt maxSendAtomic = BigInt.from(21000000) * atomicPerEpic;

/// Cleans a typed or pasted amount for parsing: removes spaces (also no-break and thin ones)
/// and apostrophes, a trailing unit such as "EPIC" or "USD", and thousands separators, and turns
/// a decimal comma into a dot.
///
/// Separators: when both `.` and `,` occur, the last one is the decimal separator
/// ("1,234.56", "1.234,56"). When only one kind occurs, more than one of it means thousands
/// ("1,234,567"). Thousands separators must group by exactly three after the first group, or
/// the amount is refused with a question ("1,234,5", "12,34.5"). A single one is the decimal
/// separator ("1,5", "0.25"). A single [groupSeparator], the one the app shows amounts with in
/// the reader's language (`,` in English, `.` in German), followed by exactly three digits
/// ("1,234") could be either, so it is refused with a question.
///
/// Throws a [LocalizedFormatException] for a negative or ambiguous amount.
String normalizeAmountText(
  String text, {
  required String unit,
  String groupSeparator = ',',
}) {
  var clean = text.replaceAll(RegExp(r"[\s\u00A0\u2009\u202F']"), '');
  final lower = clean.toLowerCase();
  if (lower.endsWith(unit.toLowerCase())) {
    clean = clean.substring(0, clean.length - unit.length);
  }
  if (clean.startsWith('-') || clean.startsWith('\u2212')) {
    throw LocalizedFormatException((l) => l.sendAmountNegative, text);
  }
  final dot = clean.lastIndexOf('.');
  final comma = clean.lastIndexOf(',');
  if (dot >= 0 && comma >= 0) {
    final decimal = dot > comma ? '.' : ',';
    final thousands = decimal == '.' ? ',' : '.';
    final at = clean.lastIndexOf(decimal);
    final whole = clean.substring(0, at);
    // One decimal separator, and the whole part grouped properly: "1,234.5", not "12,34.5"
    // or "1.2.3,4".
    if (whole.contains(decimal) || !_isGrouped(whole, thousands)) {
      throw _unclearAmount(text);
    }
    clean = '${whole.replaceAll(thousands, '')}.${clean.substring(at + 1)}';
  } else if (comma >= 0 || dot >= 0) {
    final sep = comma >= 0 ? ',' : '.';
    if (sep.allMatches(clean).length > 1) {
      // Several of one kind can only be thousands separators, so they must group by three:
      // "1,234,567", not "1,234,5".
      if (!_isGrouped(clean, sep)) throw _unclearAmount(text);
      clean = clean.replaceAll(sep, '');
    } else {
      final whole = clean.substring(0, clean.indexOf(sep));
      final fraction = clean.substring(clean.indexOf(sep) + 1);
      // "1,234" is 1.234 with a decimal comma but 1234 with a thousands comma, as the app
      // shows amounts in English ("1.234" in German). Guessing wrong sends 1000 times too much
      // or too little, so ask.
      if (sep == groupSeparator &&
          fraction.length == 3 &&
          RegExp(r'^[1-9]\d{0,2}$').hasMatch(whole)) {
        throw LocalizedFormatException(
          (l) => l.sendAmountAmbiguous(
            '$whole$fraction',
            localDecimal(l, '$whole.$fraction'),
          ),
          text,
        );
      }
      clean = clean.replaceAll(sep, '.');
    }
  }
  return clean;
}

LocalizedFormatException _unclearAmount(String text) =>
    LocalizedFormatException((l) => l.sendAmountUnclear, text);

/// Whether [digits] is 1 to 3 digits, then groups of exactly three after each [sep].
bool _isGrouped(String digits, String sep) =>
    RegExp('^\\d{1,3}(${RegExp.escape(sep)}\\d{3})*\$').hasMatch(digits);

/// The key of the row under the amount with "Use USD" and "Max", for tests.
const Key amountSuffixKey = ValueKey('send-amount-suffix');

/// Each step's fields have their own key, so a step never takes over another's text field:
/// on the web, Flutter keeps one DOM element per field and cannot turn the address's
/// multi-line one into a number input.
const Key sendRecipientFieldKey = ValueKey('send-recipient-field');
const Key sendAmountFieldKey = ValueKey('send-amount-field');
const Key sendFileAmountFieldKey = ValueKey('send-file-amount-field');
const Key sendNoteFieldKey = ValueKey('send-note-field');

/// The review's "Uses all N outputs · change 1 output" line (strategy All).
const Key sendUsesAllOutputsKey = ValueKey('send-uses-all-outputs');
const Key sendFileNoteFieldKey = ValueKey('send-file-note-field');
const Key sendReplyFieldKey = ValueKey('send-reply-field');

/// Try again and Cancel payment on the review after a failed Tor send, for tests.
const Key sendTryAgainKey = ValueKey('send-try-again');
const Key sendCancelPaymentKey = ValueKey('send-cancel-payment');

/// Send's method selector, and the tag beside the To label after the method followed the
/// address, for tests.
const Key sendMethodsKey = ValueKey('send-methods');
const Key sendSwitchedTagKey = ValueKey('send-switched-tag');

/// The shape of an HTTP address, in the sentence about an incomplete one.
const String sendHttpShape = 'http://host:3415';

/// The shape of an address for [method], under the To field while it is empty.
String? sendAddressShape(AppLocalizations l, TransferMethod method) =>
    switch (method) {
      TransferMethod.epicbox => 'esXXXX…XXXX@epicbox.epiccash.com',
      TransferMethod.direct => l.methodDirectShape,
      TransferMethod.file => null,
    };

/// The method a recipient of [kind] is paid by: an http(s) or onion address is Direct.
TransferMethod methodForRecipient(RecipientKind kind) => switch (kind) {
  RecipientKind.epicbox => TransferMethod.epicbox,
  RecipientKind.http || RecipientKind.tor => TransferMethod.direct,
};

/// The connection a payment to [to] takes, for the Tor switch ([torWay]).
TorRoute sendRoute(Recipient to) => switch (to.kind) {
  RecipientKind.epicbox => TorRoute.epicbox,
  RecipientKind.http => TorRoute.httpDirect,
  RecipientKind.tor => TorRoute.onionDirect,
};

/// Send's notice under To and the Tor buttons in it, for tests.
const Key sendTorNoticeKey = ValueKey('send-tor-notice');
const Key sendTurnOnTorKey = ValueKey('send-turn-on-tor');
const Key sendTurnOffTorKey = ValueKey('send-turn-off-tor');

/// The tag beside To that says whether the payment goes over Tor, for tests.
const Key sendTorTagKey = ValueKey('send-tor-tag');

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
  });

  /// The payment as the send returned it; the tracker follows it in [homeProvider].
  final TxEntry tx;
  final BigInt amount;
  final Recipient to;

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

  /// The options a send goes out with: those reviewed, or LEPIC's send-all after Max.
  SendOptions? get _sendOptions => _maxUsed ? null : _options;

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
      strategy: settings?.sendStrategy ?? SelectionStrategy.smallest,
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

  /// The method the selector shows for the address way. File is its own route
  /// ([SendStage.fileAmount] and after), so this is never [TransferMethod.file].
  TransferMethod _method = TransferMethod.epicbox;

  /// The To text at the last change, to tell a paste (8 or more characters at once).
  String _lastTo = '';

  /// The method the address moved the selector to, and whether its tag still shows.
  TransferMethod? _switchedTo;
  bool _tagOn = false;
  Timer? _tagTimer;

  /// The user agreed to send over plain HTTP to another device, for this recipient.
  bool _plainHttpOk = false;

  /// Send's consent or PIN dialog is open.
  bool _asking = false;

  /// A recipient handed over while the tracker or a file screen shows, for the next form.
  String? _laterRecipient;

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
    if (handoff != null) {
      _handoff = handoff.id;
      final to = parseRecipient(handoff.text);
      _recipient.text = to.address;
      _lastTo = to.address;
      if (recipientShaped(to)) _method = methodForRecipient(to.kind);
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
    if (text.trim().isEmpty) return required ? l.sendAddressMissing : null;
    final to = parseRecipient(text);
    // A whole address of another kind has moved the method already; text that does not fit
    // the method chosen by hand gets that method's own sentence.
    if (_method == TransferMethod.direct && to.kind == RecipientKind.epicbox) {
      return l.sendDirectAddressShape;
    }
    if (to.kind == RecipientKind.http) {
      return httpAddressComplete(to.address)
          ? null
          : l.contactsUrlIncomplete(sendHttpShape);
    }
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
    _setRecipient(text);
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

  /// The method follows the address (desktop spec 8.4): a whole address of another kind, or
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
      if (mounted) setState(() => _tagOn = false);
    });
  }

  /// The selector: an address method keeps the To text; File opens the file route.
  void _chooseMethod(TransferMethod method) {
    if (_busy || _estimating) return;
    if (method == TransferMethod.file) {
      _toFileRoute();
      return;
    }
    _tagTimer?.cancel();
    setState(() {
      _method = method;
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
    if (text != null && mounted) _setRecipient(text);
  }

  Future<void> _pickContact() async {
    final contact = await Navigator.of(context).push<Contact>(
      MaterialPageRoute<Contact>(
        builder: (_) => const ContactsScreen(pick: true),
      ),
    );
    if (contact != null && mounted) _setRecipient(contact.address);
  }

  /// Fills the recipient and checks it at once, as after a paste.
  void _setRecipient(String text) {
    if (_stage == SendStage.sent ||
        _stage == SendStage.fileMade ||
        _stage == SendStage.fileSent ||
        _sendFailed) {
      // Not over a payment in progress, or one a refused send holds: the next form takes
      // it, so Send again cannot make a second payment meanwhile.
      _laterRecipient = text;
      return;
    }
    _recipient.text = parseRecipient(text).address;
    _plainHttpOk = false;
    if (_stage == SendStage.amount || _stage == SendStage.review) {
      _closeChecks();
      _stage = SendStage.recipient;
    }
    setState(() {
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

  void _toAmount() {
    final problem = _recipientProblem(_recipient.text, required: true);
    setState(() {
      _recipientError = problem;
      _error = null;
      if (problem == null) _stage = SendStage.amount;
    });
    if (problem == null) _amountFocus.requestFocus();
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
  void _toFileRoute() {
    _closeChecks();
    setState(() {
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
      // `normalizeAmountText` leaves only digits and one dot, so no NaN, Infinity or 1e400.
      if (!RegExp(r'^\d*\.?\d*$').hasMatch(clean) || clean == '.') {
        throw LocalizedFormatException(
          (l) => l.sendAmountEnterFiatExample,
          text,
        );
      }
      amount = BigInt.from((double.parse(clean) / price * 100000000).round());
    } else {
      amount = parseEpic(clean);
    }
    if (amount > maxSendAtomic) {
      throw LocalizedFormatException((l) => l.sendAmountTooLarge, text);
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

  EpicboxRelay? get _relay =>
      recipientRelay(parseRecipient(_recipient.text).address);

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
  Future<void> _run(Future<void> Function(WalletSession session) action) async {
    if (_busy) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(session);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(context.l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
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

  Future<void> _send() async {
    final reviewed = _estimate;
    // A second tap can land on the old button after the first send already finished.
    if (reviewed == null || _stage != SendStage.review) return;
    // A second tap while the first one's dialogs show opens no second set.
    if (_asking) return;
    final l = context.l10n;
    final to = parseRecipient(_recipient.text);
    _asking = true;
    try {
      // Plain HTTP to another device travels unencrypted: asked once per recipient, before
      // the PIN.
      if (to.kind == RecipientKind.http &&
          plainHttpToOtherDevice(to.address) &&
          !_plainHttpOk) {
        if (!await _askPlainHttp() || !mounted) return;
        _plainHttpOk = true;
      }
      if (!await _pinGate(l.sendPinReason(epicExact(l, reviewed.amount)))) {
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
    return _run((session) async {
      // What the wallet held before, to tell the payment a failed send leaves behind.
      final minimum = ref.read(countedConfirmationsProvider);
      final before = {
        for (final t in await session.transactions(refresh: false)) t.key,
      };
      final spendableBefore = (await session.summary(
        refresh: false,
        minimumConfirmations: minimum,
      )).spendable;
      final TxEntry tx;
      try {
        tx = await hold.during(
          () => session.sendEpicbox(
            amount: amount,
            minimumConfirmations: ref.read(countedConfirmationsProvider),
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
        final after = await session.transactions(refresh: false);
        final spendableAfter = (await session.summary(
          refresh: false,
          minimumConfirmations: minimum,
        )).spendable;
        final left =
            after
                .where(
                  (t) =>
                      !before.contains(t.key) &&
                      t.kind == TxKind.sent &&
                      t.status == TxStatus.awaitingRecipient &&
                      t.id != null &&
                      t.counterparty?.trim() == to.address &&
                      txAmount(t).amount == amount,
                )
                .toList()
              ..sort((a, b) => b.createdAtUnix.compareTo(a.createdAtUnix));
        if (mounted) {
          setState(() {
            _sendFailed = true;
            _undelivered = left.firstOrNull;
            _nothingStored =
                left.isEmpty &&
                spendableAfter == spendableBefore &&
                after.length == before.length &&
                after.every((t) => before.contains(t.key));
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
          );
          _stage = SendStage.sent;
        });
      }
    });
  }

  /// "Not encrypted. Send anyway?" before plain HTTP to another device. True to send.
  Future<bool> _askPlainHttp() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber),
        title: Text(l.sendPlainHttpTitle),
        content: Text(l.sendPlainHttpBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.sendAnyway),
          ),
        ],
      ),
    );
    return ok == true;
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
    return _run((session) async {
      final minimum = ref.read(countedConfirmationsProvider);
      final before = {
        for (final t in await session.transactions(refresh: false)) t.key,
      };
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
        final stuck = (await _waitingSendsLeft(
          session,
          before,
          to,
          amount,
        )).firstOrNull;
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

  /// Sends that were not in [before], to [to] for [amount], waiting for their wallet: what
  /// a failed Tor send left behind, newest first.
  Future<List<TxEntry>> _waitingSendsLeft(
    WalletSession session,
    Set<String> before,
    Recipient to,
    BigInt amount,
  ) async {
    final after = await session.transactions(refresh: false);
    final host = to.address.toLowerCase();
    return after
        .where(
          (t) =>
              !before.contains(t.key) &&
              t.kind == TxKind.sent &&
              t.status == TxStatus.awaitingRecipient &&
              t.id != null &&
              txAmount(t).amount == amount &&
              (t.counterparty == null ||
                  t.counterparty!.toLowerCase().contains(host)),
        )
        .toList()
      ..sort((a, b) => b.createdAtUnix.compareTo(a.createdAtUnix));
  }

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
    return _run((session) async {
      final minimum = ref.read(countedConfirmationsProvider);
      final before = {
        for (final t in await session.transactions(refresh: false)) t.key,
      };
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
        final left = await _waitingSendsLeft(session, before, to, amount);
        final stuck = left.firstOrNull;
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
    if (!await _pinGate(l.sendFilePinReason(epicExact(l, amount)))) return;
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
      container.invalidate(homeProvider);
      if (mounted) {
        setState(() {
          _slate = slate;
          _stage = SendStage.fileMade;
        });
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
    final slate = _slate;
    final container = ProviderScope.containerOf(context, listen: false);
    final hold = ref.read(autoLockHoldProvider.notifier);
    final service = ref.read(walletServiceProvider);
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
        if (mounted) setState(() => _error = context.l10n.slateWrongPayment);
        return;
      }
      final tx = await hold.during(
        () => session.finalizeAndPost(slateJson: json),
      );
      container.invalidate(homeProvider);
      if (mounted) {
        setState(() {
          _filePosted = tx;
          _stage = SendStage.fileSent;
        });
      }
    });
  }

  void _done() {
    ref.read(trackedSendProvider.notifier).track(null);
    final later = _laterRecipient;
    // The shell clears the handoff for a fresh form; one that came meanwhile goes to it.
    final handoff = ref.read(sendRecipientProvider.notifier);
    widget.onDone();
    if (later != null) {
      _laterRecipient = null;
      handoff.hand(later);
    }
  }

  // Build.

  @override
  Widget build(BuildContext context) {
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
      _setRecipient(handoff.text);
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
    return ScreenBody(
      bottom: bottom,
      children: [...children, if (_error != null) ErrorText(_error!)],
    );
  }

  Widget _emptyState(BuildContext context) {
    final demo = ref.watch(demoModeProvider);
    return CenteredScroll(
      child: CenteredBody(
        children: [
          EmptyState(
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
              child: Semantics(
                header: true,
                child: Text(title, style: theme.textTheme.titleLarge),
              ),
            ),
          ),
          if (step != null)
            Text(
              l.sendStepOf(step, 3),
              style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
            ),
          ?extra,
          IconButton(
            tooltip: l.sendHowItWorks,
            icon: const Icon(Icons.info_outline),
            onPressed: () => showHandshakeSheet(context),
          ),
        ],
      ),
    );
  }

  String? _contactName(String address) {
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    return contactNameFor(contacts, address);
  }

  /// Epicbox, Direct and File, one segment each, icon over label. Tor is not a method: the
  /// one Tor switch (Settings › Privacy) changes how Epicbox and Direct connect.
  Widget _methodSelector(BuildContext context, TransferMethod selected) {
    final l = context.l10n;
    final labelStyle = Theme.of(context).textTheme.labelMedium;
    ButtonSegment<TransferMethod> segment(
      TransferMethod value,
      IconData icon,
      String label,
    ) => ButtonSegment(
      value: value,
      tooltip: label,
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1, style: labelStyle),
          ),
        ],
      ),
    );
    return Semantics(
      label: l.sendMethodLabel,
      container: true,
      child: SegmentedButton<TransferMethod>(
        key: sendMethodsKey,
        segments: [
          segment(
            TransferMethod.epicbox,
            Icons.alternate_email,
            l.methodEpicbox,
          ),
          segment(TransferMethod.direct, Icons.link, l.methodDirect),
          segment(
            TransferMethod.file,
            Icons.description_outlined,
            l.methodFile,
          ),
        ],
        selected: {selected},
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
    );
  }

  /// The selector and, 12 dp under it, the strip that says what [method] means.
  List<Widget> _methodHead(BuildContext context, TransferMethod method) => [
    _methodSelector(context, method),
    const SizedBox(height: 12),
    DismissibleTip(
      id: sendMethodTipId,
      child: MethodStrip(method: method),
    ),
    const SizedBox(height: 16),
  ];

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
    return [
      _header(context, l.sendStepRecipient, step: 1),
      ..._methodHead(context, _method),
      TextField(
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
        onChanged: (text) => setState(() {
          _followAddress(text);
          _recipientError = null;
          _error = null;
          _plainHttpOk = false;
        }),
        decoration: InputDecoration(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.sendToLabel),
              const SizedBox(width: 8),
              Flexible(
                child: _SwitchTag(method: _switchedTo, shown: _tagOn),
              ),
              if (_TorTag.shows(way, _torState)) ...[
                const SizedBox(width: 8),
                Flexible(child: _TorTag(way: way)),
              ],
            ],
          ),
          hintText: l.sendToHint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          error: _recipientError == null
              ? null
              : LiveFieldError(_recipientError!),
          border: const OutlineInputBorder(),
        ),
      ),
      if (_tagOn && _switchedTo != null)
        _SwitchAnnouncement(method: _switchedTo!),
      _TorNotice(way: way),
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
      Wrap(
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
      ),
      if (valid) ...[
        const SizedBox(height: 8),
        RecipientCard(
          address: to.address,
          name: _contactName(to.address),
          onSave: _contactName(to.address) == null
              ? () => _saveContact(to.address)
              : null,
        ),
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
            address: contact.address,
            name: contact.name,
            onTap: () => _setRecipient(contact.address),
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
    ];
  }

  Widget _recipientAction() => BusyButton(
    label: context.l10n.commonContinue,
    onPressed: _recipient.text.trim().isEmpty ? null : _toAmount,
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
          ? '≈ ${epicExact(l, amount)}'
          : '≈ ${localDigits(l, fiatText(amount, price, currency))}';
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
          helperText: amountHelper,
          error: _amountError == null ? null : LiveFieldError(_amountError!),
        ),
      ),
      const SizedBox(height: 12),
      if (summary != null)
        Text(
          l.sendAvailable(epicExact(l, summary.spendable)),
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
      const SizedBox(height: 12),
      Wrap(
        key: amountSuffixKey,
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (price != null || _fiatEntry)
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
              onPressed: _toggleUnit,
              child: Text(
                l.sendUseUnit(_fiatEntry ? 'EPIC' : currency.toUpperCase()),
              ),
            ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: _busy ? null : _max,
            child: Text(l.sendMax),
          ),
        ],
      ),
      if (estimate != null && _estimateError == null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Semantics(
            liveRegion: true,
            child: Text(
              l.sendFeeQuiet(epicExact(l, estimate.fee)),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
            ),
          ),
        ),
      if (_estimateError != null) ErrorText(_estimateError!),
      const SizedBox(height: 12),
      Divider(color: t.line, height: 1),
      if (!_noteOpen)
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
              helperText: l.sendNoteHelper,
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
    if (!torGoes(way)) return;
    _toReview();
  }

  List<Widget> _amountStep(BuildContext context) {
    final l = context.l10n;
    final address = parseRecipient(_recipient.text).address;
    return [
      _header(context, l.sendStepAmount, step: 2, onBack: _toRecipient),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: _ToChip(address: address, name: _contactName(address)),
      ),
      _TorNotice(way: _wayOf(sendRoute(parseRecipient(_recipient.text)))),
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
      onPressed: _amountReady && !_busy && torGoes(way) ? _toReview : null,
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
          : l.sendTorNotReached(sendTtlDays);
    } else {
      failed = _nothingStored
          ? l.sendRelayDown
          : _undelivered == null
          ? l.sendRelayRefusedLost
          : l.sendRelayRefused(sendTtlDays);
    }
    return [
      // After a failed send the payment exists: no way back to send it again.
      _header(
        context,
        l.sendStepReview,
        step: 3,
        onBack: _sendFailed ? null : _backToAmount,
      ),
      RecipientCard(address: to.address, name: _contactName(to.address)),
      const SizedBox(height: 20),
      Text(
        epicExact(l, estimate.amount),
        style: theme.textTheme.headlineMedium?.copyWith(
          fontFamily: t.monoFamily,
          color: t.text,
        ),
      ),
      const SizedBox(height: 12),
      _Row(
        label: l.sendMethodLabel,
        value: switch (to.kind) {
          RecipientKind.epicbox when way == TorWay.overTor =>
            '${l.methodEpicbox} · ${l.sendOverTor}',
          RecipientKind.epicbox => l.methodEpicbox,
          RecipientKind.http
              when way == TorWay.clearnet && torState != TorState.off =>
            '${l.methodDirect} · ${l.torNotOverTor}',
          RecipientKind.http => l.methodDirect,
          RecipientKind.tor => '${l.methodDirect} · ${l.sendOverTor}',
        },
        mono: false,
      ),
      _Row(label: l.sendNetworkFee, value: epicExact(l, estimate.fee)),
      // Strategy All is a consolidating send: its change is one output, never split.
      if (_sendOptions?.strategy == SelectionStrategy.all &&
          estimate.change > BigInt.zero)
        Text(
          l.sendUsesAllOutputs(estimate.inputCount),
          key: sendUsesAllOutputsKey,
          style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
        ),
      _Row(
        label: l.sendReviewTotal,
        value: price == null
            ? epicExact(l, total)
            : l.sendReviewTotalWithFiat(
                epicExact(l, total),
                localDigits(l, fiatText(total, price, currency)),
              ),
        strong: true,
      ),
      // What stays after this send (outputs spec §4.6): the balance once it is out, and,
      // while the change confirms, only the outputs the send does not lock.
      if (spendable != null && spendable >= total) ...[
        _Row(label: l.sendBalanceAfter, value: epicExact(l, spendable - total)),
        if (estimate.locked > total && estimate.locked <= spendable) ...[
          _Row(
            label: l.sendSpendableUntilChange,
            value: epicExact(l, spendable - estimate.locked),
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
      ),
      const SizedBox(height: 4),
      Text(
        to.kind == RecipientKind.epicbox
            ? l.sendCancelRuleEpicbox
            : l.sendCancelRuleDirect,
        style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
      ),
    ];
  }

  Widget _reviewAction(BuildContext context) {
    final l = context.l10n;
    final checks = ref.watch(sendPreflightProvider(_relay));
    final relayDown = checks.relayOutcome == CheckOutcome.failed;
    // Without a node answer the send could not be built or posted, and a connection that
    // waits for Tor or needs it does not go.
    final way = _wayOf(sendRoute(parseRecipient(_recipient.text)));
    final canSend = checks.ready && !_busy && torGoes(way);
    final amount = epicExact(l, _estimate!.amount);
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
          TextButton(
            key: sendCancelPaymentKey,
            style: quiet,
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
            label: l.sendReviewSendButton(amount),
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
    final name = _contactName(sent.to.address);
    final who = name ?? shortAddress(sent.to.address);
    final at = sendTrackerStep(track);
    final confirmations = txConfirmations(live, tip) ?? 0;
    final labels = <(String done, String now)>[
      (
        name == null ? l.sendTrackSent : l.sendTrackSentTo(name),
        name == null ? l.sendTrackSent : l.sendTrackSentTo(name),
      ),
      (
        name == null ? l.sendTrackSigned : l.sendTrackSignedBy(name),
        name == null ? l.sendTrackWaiting : l.sendTrackWaitingFor(name),
      ),
      (l.sendTrackOnNetwork, l.sendTrackOnNetwork),
      (l.sendTrackConfirmed, l.txStatusConfirming(confirmations, target)),
    ];
    final steps = [
      for (final (i, (done, now)) in labels.indexed)
        TimelineStep(
          i == at ? now : done,
          i < at
              ? TimelineState.done
              : i == at
              ? TimelineState.current
              : TimelineState.todo,
        ),
    ];
    final waiting = track == SendTrack.waitingRecipient;
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
          onPressed: () => showHandshakeSheet(context),
        ),
      ),
      Center(
        child: Text(
          epicExact(l, sent.amount),
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
            epicExact(l, fee),
            epicExact(l, sent.reviewedFee!),
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
    final t = context.tokens;
    return [
      _header(
        context,
        l.sendFileTitle,
        onBack: _toRecipient,
        extra: IconButton(
          tooltip: l.sendFileHelpTooltip,
          icon: const Icon(Icons.help_outline),
          onPressed: () =>
              showFileExchangeHelp(context, role: FileExchangeRole.sender),
        ),
      ),
      ..._methodHead(context, TransferMethod.file),
      ..._amountFields(context, file: true),
      const SizedBox(height: 12),
      Text(
        l.sendCancelRuleFile,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.dim),
      ),
    ];
  }

  Widget _fileAmountAction() => BusyButton(
    label: context.l10n.sendMakeFile,
    busy: _busy,
    onPressed: _amountReady ? _createFile : null,
  );

  /// The file route's three steps, [at] the current one (3 when all are done).
  Widget _fileSteps(BuildContext context, int at, BigInt amount) {
    final l = context.l10n;
    final labels = [
      (l.sendFileMade, l.sendFileMade),
      (l.sendTrackSigned, l.sendFileWaitingReply),
      (l.sendTrackOnNetwork, l.sendTrackOnNetwork),
    ];
    return RoundSteps(
      steps: [
        for (final (i, (done, now)) in labels.indexed)
          TimelineStep(
            i == at ? now : done,
            i < at
                ? TimelineState.done
                : i == at
                ? TimelineState.current
                : TimelineState.todo,
            detail: i == 0 && at < 3
                ? l.sendFileOnHold(epicExact(l, amount))
                : null,
          ),
      ],
    );
  }

  List<Widget> _fileMadeStep(BuildContext context, Slate slate) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = context.tokens;
    final name = sendFileName(slate.slateId);
    return [
      _header(context, l.sendFileTitle),
      _fileSteps(context, 1, _parsedAmount ?? BigInt.zero),
      Text(
        l.sendFileShareHint,
        style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
      ),
      const SizedBox(height: 12),
      SlateFileButtons(name: name, json: slate.json),
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
            onPressed: _finalizePasted,
          ),
          const SizedBox(height: 8),
        ],
      ),
      TextButton(
        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: _done,
        child: Text(l.commonDone),
      ),
    ];
  }

  Widget _openReplyAction() => BusyButton(
    label: context.l10n.sendOpenReply,
    onPressed: _busy ? null : _openReply,
  );

  List<Widget> _fileSentStep(BuildContext context) {
    final l = context.l10n;
    final slate = _slate;
    final posted =
        _filePosted ??
        (slate == null
            ? null
            : ref
                  .watch(homeProvider)
                  .value
                  ?.transactions
                  .where((tx) => tx.key == 's:${slate.slateId}')
                  .firstOrNull);
    if (posted != null && posted.repostable) {
      return [NotPostedNotice(tx: posted)];
    }
    return [
      _header(context, l.sendFileTitle),
      _fileSteps(context, 3, _parsedAmount ?? BigInt.zero),
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
  });

  final String address;
  final String? name;
  final VoidCallback? onSave;

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
                        if (isOnionAddress(address)) ...[
                          const SizedBox(width: 8),
                          const _TorPill(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
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

/// A small rounded tag in the accent: [icon] and a short [text], cut short when the row is
/// narrow.
class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, this.muted = false});

  final IconData icon;
  final String text;

  /// Dim instead of the accent: a fact, not something the user gains.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final ink = muted ? t.dim : t.accentText;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 8, 2),
      decoration: BoxDecoration(
        color: muted ? t.surfaceHi : t.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ink),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Direct address" / "Via Epicbox" beside the To label for 3 s after the address moved the
/// method: fades in over 120 ms and out over 200 ms (at once with reduced motion), and is read
/// out once as "Direct address. Method set to Direct."
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
      TransferMethod.direct => (Icons.link, l.sendSwitchedDirect),
      _ => (Icons.alternate_email, l.sendSwitchedEpicbox),
    };
    // The text field merges its label: [_SwitchAnnouncement] says it out loud.
    return ExcludeSemantics(
      child: AnimatedOpacity(
        key: sendSwitchedTagKey,
        opacity: shown ? 1 : 0,
        duration: still
            ? Duration.zero
            : Duration(milliseconds: shown ? 120 : 200),
        child: _Pill(icon: icon, text: text),
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
    final (text, muted) = switch (way) {
      TorWay.overTor => (l.sendOverTor, false),
      TorWay.wait => (l.torWaiting, true),
      _ => (l.torNotOverTor, true),
    };
    // Read with the field's label: "To, Over Tor".
    return KeyedSubtree(
      key: sendTorTagKey,
      child: _Pill(icon: torIcon, text: text, muted: muted),
    );
  }
}

/// Under To while the payment's connection cannot go: an onion address with Tor off ("Needs
/// Tor." with Turn on Tor, which keeps the form), or Tor on but not connected ("Tor is not
/// connected." with Retry and Turn Tor off). Nothing falls back to the clearnet.
class _TorNotice extends ConsumerWidget {
  const _TorNotice({required this.way});

  final TorWay way;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    // Without Tor in the app the address's own error says so.
    final available = ref.watch(
      phoneTorProvider.select((s) => s.phase != PhoneTorPhase.unavailable),
    );
    if (!available || (way != TorWay.needsTor && way != TorWay.blocked)) {
      return const SizedBox.shrink();
    }
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
                    blocked ? Icons.error_outline : torIcon,
                    size: 18,
                    color: blocked ? t.risk : t.dim,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      blocked ? l.torNotConnectedNotice : l.torNeeds,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
            ] else
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
      _Pill(icon: torIcon, text: context.l10n.sendOverTor);
}

/// A round tile with the contact's initial, or a person for a new recipient.
class _Initial extends StatelessWidget {
  const _Initial({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final name = this.name?.trim();
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
        child: name == null || name.isEmpty
            ? Icon(Icons.person_outline, size: 20, color: t.dim)
            : Text(
                name.characters.first.toUpperCase(),
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
  const _RecentRow({required this.address, this.name, required this.onTap});

  final String address;
  final String? name;
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
  });

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
        spinner,
        tor.canSend ? l.sendTorReaching : l.torStateStarting(tor.progress ?? 0),
        t.dim,
        null,
      ),
      _ when sending && http => (spinner, l.sendHttpReaching, t.dim, null),
      _ when sending => (spinner, l.sendSending, t.dim, null),
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
        l.sendRelayDown,
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
      _ when checks.listener == CheckOutcome.failed => (
        Icon(Icons.sync, size: 18, color: t.dim),
        l.sendListenerDown,
        t.dim,
        null,
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
    this.strong = false,
    this.mono = true,
  });

  final String label;
  final String value;
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: mono ? style?.copyWith(fontFamily: t.monoFamily) : style,
            ),
          ),
        ],
      ),
    );
  }
}

/// The length of [text] in UTF-8 bytes, as LEPIC counts a slate message.
int utf8Length(String text) => utf8.encode(text).length;

/// Keeps a field's text within [maxBytes] UTF-8 bytes. An edit that would pass it keeps the
/// text around the edit and as many whole characters of what was typed or pasted as fit, with
/// the cursor after them, so a long paste is cut, never refused, and nothing already written
/// is lost.
class Utf8LengthLimiter extends TextInputFormatter {
  const Utf8LengthLimiter(this.maxBytes);

  final int maxBytes;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (utf8Length(newValue.text) <= maxBytes) return newValue;
    final old = oldValue.text;
    final edited = oldValue.selection;
    // The edit replaced the old selection with the inserted text, when it reads that way.
    if (edited.isValid && edited.start >= 0 && edited.end <= old.length) {
      final before = old.substring(0, edited.start);
      final after = old.substring(edited.end);
      final text = newValue.text;
      if (text.length >= before.length + after.length &&
          text.startsWith(before) &&
          text.endsWith(after)) {
        final inserted = text.substring(
          before.length,
          text.length - after.length,
        );
        final room = maxBytes - utf8Length(before) - utf8Length(after);
        final kept = _fit(inserted, room);
        return TextEditingValue(
          text: '$before$kept$after',
          selection: TextSelection.collapsed(
            offset: before.length + kept.length,
          ),
        );
      }
    }
    final kept = _fit(newValue.text, maxBytes);
    return TextEditingValue(
      text: kept,
      selection: TextSelection.collapsed(offset: kept.length),
    );
  }

  /// The longest run of whole characters from the start of [text] within [room] bytes.
  static String _fit(String text, int room) {
    final kept = StringBuffer();
    var bytes = 0;
    for (final c in text.characters) {
      final n = utf8Length(c);
      if (bytes + n > room) break;
      kept.write(c);
      bytes += n;
    }
    return kept.toString();
  }
}
