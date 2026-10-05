/// The boundary between the UI and the native wallet core.
///
/// UI code depends on [WalletService] and [WalletSession] only. [LepicWalletService]
/// (`lepic_wallet_service.dart`) runs them on LEPIC; tests use [FakeWalletService].
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'history/wallet_history.dart';
import 'models.dart';

export 'models.dart';

/// Free functions of the native API plus the two ways to obtain an open wallet.
abstract interface class WalletService {
  bool validateMnemonic({required String phrase});

  /// Reads a slate's id, amount, fee and step without touching a wallet. Throws [WalletError]
  /// with [WalletErrorKind.invalidSlate] for anything that is not a slate. LEPIC reads it on
  /// the chain of the last wallet config it saw.
  Future<SlateInfo> inspectSlate({required String json});

  /// True for `<address>@<relay>[:port]` valid on the chain of the open wallet.
  bool validateEpicboxAddress({required String address});

  Future<bool> walletExists({required WalletConfig config});

  Future<NodeTip> nodeTip({required WalletConfig config});

  /// Creates a wallet. With [mnemonic] it restores that seed; call [WalletSession.scan] next.
  Future<WalletSession> create({
    required WalletConfig config,
    String? mnemonic,
    required String password,
  });

  /// Opens an existing wallet. A wrong password throws [WalletError] with
  /// [WalletErrorKind.wrongPassword].
  Future<WalletSession> open({
    required WalletConfig config,
    required String password,
  });

  /// Creates a wallet whose password the core generates and seals under [pin]; Dart only ever
  /// holds the sealed text. Store [PinWallet.sealedPassword] before showing the phrase: without
  /// it the wallet cannot be opened, only deleted and created again.
  Future<PinWallet> createWithPin({
    required WalletConfig config,
    String? mnemonic,
    required String pin,
  });

  /// Opens a wallet from [createWithPin]. A wrong PIN throws [WalletError] with
  /// [WalletErrorKind.wrongPassword]; the core counts it ([pinFailures]) and makes later tries
  /// wait ([pinDelay]).
  Future<WalletSession> openWithPin({
    required WalletConfig config,
    required String pin,
    required String sealedPassword,
  });

  /// Wrong PINs counted by the core since the last right one.
  Future<int> pinFailures({required WalletConfig config});

  /// Deletes the wallet files in `config.dataDir`. Every session on it must be disposed first.
  /// Only the recovery phrase can bring the wallet back.
  Future<void> deleteWallet({required WalletConfig config});
}

/// A wallet from [WalletService.createWithPin] and its password sealed under the PIN.
typedef PinWallet = ({WalletSession session, String sealedPassword});

/// PIN tries that never wait, LEPIC's `PinPolicy::DEFAULT` (`crates/lepic-ffi/src/pin.rs`).
const int freePinAttempts = 3;

/// The wait once [freePinAttempts] failures are counted; it doubles with each further one, up
/// to [maxPinDelay].
const Duration firstPinDelay = Duration(seconds: 30);
const Duration maxPinDelay = Duration(hours: 1);

/// How long the core waits before it tries a PIN after [failures] wrong ones.
Duration pinDelay(int failures) {
  if (failures < freePinAttempts) return Duration.zero;
  final doublings = failures - freePinAttempts;
  if (doublings >= 20) return maxPinDelay;
  final wait = firstPinDelay * (1 << doublings);
  return wait > maxPinDelay ? maxPinDelay : wait;
}

/// The error of a PIN call the old core does not have.
WalletError pinUnsupported(String call) => WalletError(
  kind: WalletErrorKind.other,
  message: '$call needs the LEPIC core',
);

/// An open wallet. Mirrors the methods of the native `EpicWallet`.
///
/// Call [dispose] when done. The core allows one chain per process, so every session must be
/// disposed before a wallet on another chain can be opened.
abstract interface class WalletSession {
  void dispose();

  Future<String> mnemonic({required String password});

  /// The recovery phrase of a wallet from [WalletService.createWithPin], for the backup screen.
  /// The PIN attempt counts as in [WalletService.openWithPin].
  Future<String> mnemonicWithPin({
    required String pin,
    required String sealedPassword,
  });

  /// Seals the wallet password under [newPin] and returns the new sealed text. [oldPin] must
  /// open [sealedPassword]; the attempt counts as in [WalletService.openWithPin]. Both texts
  /// open until [confirmPinChange], so store the new one first.
  Future<String> changePin({
    required String sealedPassword,
    required String oldPin,
    required String newPin,
  });

  /// Ends a [changePin] once its text is stored; then only that text opens.
  Future<void> confirmPinChange({required String sealedPassword});

  Future<void> cancelTransaction({required int txId});

  /// Posts a finalized send that never reached the chain again ([TxEntry.repostable]). Its
  /// inputs stay locked until it confirms.
  Future<void> repostTransaction({required String key});

  /// Unlocks the funds of a finished payment the network refused and that has not reached it
  /// for a day of blocks ([TxEntry.releasable]). Refuses with [WalletErrorKind.invalidArgument]
  /// when the node shows the payment on chain or in its pool.
  Future<void> releaseStuckSend({required String key});

  /// [message], when set, is signed into the slate for the recipient to see; LEPIC cuts it
  /// to [slateMessageMaxBytes].
  Future<Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
  });

  Future<String> epicboxAddress();

  Future<FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
  });

  Future<TxEntry> finalizeAndPost({required String slateJson});

  /// Posts a send over epicbox. The listener finalizes it when the recipient answers.
  /// [message] as for [createSendSlate].
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
  });

  /// Starts the epicbox listener and streams its events. It runs until [stopListener] or
  /// [dispose].
  Stream<ListenerEvent> startListener();

  Future<void> stopListener();

  /// Signs an incoming send. The same slate again returns the answer given the first time with
  /// [ReceivedSlate.repeated] set; nothing is stored or signed again.
  Future<ReceivedSlate> receiveSlate({required String slateJson});

  Stream<ScanProgress> scan({BigInt? startHeight});

  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  });

  /// `summary(refresh: true)` with progress. Percentages never fall; the last event has
  /// [RefreshProgress.summary] set and `percent` 100. A failure ends the stream with the error.
  Stream<RefreshProgress> refresh({required BigInt minimumConfirmations});

  /// epic-wallet's log merged with the history archive, newest first by `timeUnix`.
  Future<List<TxEntry>> transactions({required bool refresh});

  /// Fills in block heights and times and settles imported pending records, with at most 25
  /// node calls and no output refresh. Returns how many rows changed; reload [transactions]
  /// only when it is above 0.
  Future<int> enrichHistory();

  /// Sets the note of the transaction with [TxEntry.key]; null or blank clears it.
  Future<void> setTxNote({required String key, String? note});

  /// Address book, sorted by name.
  Future<List<Contact>> contacts();

  /// Adds a contact (empty `id`) or replaces the one with that id. Returns it as stored.
  Future<Contact> saveContact({required Contact contact});

  Future<void> deleteContact({required String id});

  /// Encrypted history file that only a wallet with the same recovery phrase can import.
  Future<Uint8List> exportHistory();

  /// The transaction list as CSV. Not encrypted, not importable.
  Future<String> exportHistoryCsv();

  /// Merges a file from [exportHistory]. A second import of the same file changes nothing. A
  /// file from another wallet throws [WalletError] with [WalletErrorKind.invalidArgument].
  Future<ImportReport> importHistory({required Uint8List data});

  /// Largest amount that can be sent now, with its fee.
  Future<FeeEstimate> estimateMax({required BigInt minimumConfirmations});

  // Invoices over epicbox (I-01). Trusted services bill the user at a separate invoice
  // address; each invoice waits for the user. Capabilities, not LEPIC's names: I-04 adapts
  // them to the binding. Every call below throws [invoicesUnsupported] when this is false.

  /// True when this core handles invoices over epicbox.
  bool get supportsInvoices;

  /// The address the user gives services, apart from [epicboxAddress], which keeps taking
  /// payments from anyone.
  Future<String> invoiceAddress();

  /// Moves to a new invoice address and abandons the old one for good. Services must be given
  /// the new one. Returns it.
  Future<String> rotateInvoiceAddress();

  /// Services allowed to send invoices, with the user's labels.
  Future<List<TrustedService>> trustedServices();

  /// Allows the service at [address] (a full epicbox address, validated as one) under
  /// [label]. Adding one already listed, by key, replaces its address and label.
  Future<TrustedService> addTrustedService({
    required String address,
    required String label,
  });

  /// Stops the service at [address] from reaching the wallet. Its pending invoices stay until
  /// answered or expired.
  Future<void> removeTrustedService({required String address});

  /// Fetches what waits at the invoice address: invoices from trusted services are parked,
  /// notices applied, everything else dropped unread. Runs on demand only.
  Future<InvoiceDrainReport> drainInvoices();

  /// Parked invoices not yet answered or expired, oldest first.
  Future<List<PendingInvoice>> pendingInvoices();

  /// Pays a pending invoice and sends the reply to the service's address on the list.
  /// [amount] must equal the invoiced amount ([WalletErrorKind.invalidArgument] otherwise).
  /// Call it only after the user approved behind the PIN or biometric gate.
  ///
  /// A reply that cannot be delivered does not undo the payment: the result has status
  /// [InvoiceStatus.replyFailed], and [resendInvoiceReply] delivers it later.
  Future<PaidInvoice> payInvoice({
    required String slateId,
    required BigInt amount,
  });

  /// Sends the stored reply of a paid invoice again. Signs nothing; the user's approval
  /// stands. Throws [WalletErrorKind.transportFailed] when it fails again.
  Future<PaidInvoice> resendInvoiceReply({required String slateId});

  /// Declines a pending invoice and tells the service.
  Future<void> declineInvoice({required String slateId});

  /// The invoice behind the transaction with [slateId], once paid, or null.
  Future<PaidInvoice?> paidInvoice({required String slateId});

  /// Invoices parked, receipts and withdrawals applied, expiries, as drains and answers find
  /// them. Informational: no event pays or cancels anything.
  Stream<InvoiceEvent> invoiceEvents();

  // Issuing invoices (I-05): the user asks someone to pay them. The request goes to the
  // payer's invoice address; the payment comes back to [epicboxAddress], where the listener
  // or [drainPayments] finalizes and posts it. Nothing here spends from this wallet, so no
  // call needs the PIN. Every call throws [invoicesUnsupported] when [supportsInvoices] is
  // false.

  /// Sends the payer at [address], their invoice address, a request for [amount].
  /// [message] is cut with [cutMessage] and signed into it. Throws
  /// [WalletErrorKind.invalidArgument] for an address that is not an epicbox address on this
  /// chain or is one of this wallet's own, and [WalletErrorKind.transportFailed] when the
  /// relay did not take it, in which case nothing stays behind.
  Future<IssuedInvoice> issueInvoice({
    required BigInt amount,
    required String address,
    String? message,
  });

  /// Invoices this wallet issued, newest first, with their current state.
  Future<List<IssuedInvoice>> issuedInvoices();

  /// The invoice this wallet issued under [slateId], or null.
  Future<IssuedInvoice?> issuedInvoice({required String slateId});

  /// Withdraws a waiting invoice: the wallet cancels it, and a LEPIC payer is told. Throws
  /// [WalletErrorKind.invalidArgument] when it is not waiting.
  Future<IssuedInvoice> withdrawInvoice({required String slateId});

  /// Reads the payments address once, finalizing and posting what payers sent, then sweeps
  /// expired invoices. Run it when the wallet opens and on every resume, beside the listener,
  /// so an issuer that was away finalizes on return. Each request a payer sent back is
  /// withdrawn and raises one [IssuerEventKind.bounced] event, however often it comes back.
  Future<PaymentsDrainReport> drainPayments();

  /// What happened to issued invoices, as drains, the listener and sweeps find it.
  Stream<IssuerEvent> issuerEvents();

  /// What this wallet learned about the payer at [address] from their own messages, for a
  /// warning before a request: [PeerCapability.noInvoices] once one sent a request back.
  Future<PeerCapability> peerCapability({required String address});
}

/// The error of an invoice call on a core without them.
WalletError invoicesUnsupported(String call) => WalletError(
  kind: WalletErrorKind.other,
  message: '$call needs LEPIC with invoices over epicbox (UP-14)',
);

/// What the fakes accept as an epicbox address, as LEPIC requires it: key `@` relay.
bool fakeEpicboxAddress(String address) =>
    RegExp(r'^[1-9A-HJ-NP-Za-km-z]{52}@[a-z0-9.]+(:\d+)?$').hasMatch(address);

/// In-memory wallet for widget tests. Holds at most one wallet per data directory.
///
/// Nothing here touches disk, the network or the native library.
class FakeWalletService implements WalletService {
  FakeWalletService({
    this.phrase = _defaultPhrase,
    Set<String>? existingWallets,
    this.password = 'correct horse',
    FakeWalletSession? session,
  }) : existingWallets = existingWallets ?? <String>{},
       session = session ?? FakeWalletSession();

  static const String _defaultPhrase =
      'alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima '
      'mike november oscar papa quebec romeo sierra tango uniform victor whiskey xray';

  /// Phrase accepted by [validateMnemonic].
  final String phrase;

  /// Data directories that already hold a wallet.
  final Set<String> existingWallets;

  /// Password accepted by [open] and set by [create].
  String password;

  /// The session handed out by [create] and [open].
  final FakeWalletSession session;

  /// Arguments of the last [create] call.
  WalletConfig? createdConfig;
  String? createdMnemonic;

  /// When set, [create] waits for it, so tests can act while a wallet is being created.
  Completer<void>? createGate;

  /// Data directories passed to [deleteWallet].
  final List<String> deletedWallets = [];

  @override
  bool validateMnemonic({required String phrase}) => phrase == this.phrase;

  /// Slates [inspectSlate] recognises, by JSON text.
  final Map<String, SlateInfo> slateInfos = {};

  /// When set, [inspectSlate] waits for it, so tests see the file screen while it reads.
  Completer<void>? inspectGate;

  @override
  Future<SlateInfo> inspectSlate({required String json}) async {
    await inspectGate?.future;
    final info = slateInfos[json];
    if (info == null) {
      throw const WalletError(
        kind: WalletErrorKind.invalidSlate,
        message: 'not a slate',
      );
    }
    return info;
  }

  @override
  bool validateEpicboxAddress({required String address}) =>
      fakeEpicboxAddress(address);

  @override
  Future<bool> walletExists({required WalletConfig config}) async =>
      existingWallets.contains(config.dataDir);

  @override
  Future<NodeTip> nodeTip({required WalletConfig config}) async =>
      NodeTip(height: BigInt.from(2500000), nodeVersion: '3.6.0');

  @override
  Future<WalletSession> create({
    required WalletConfig config,
    String? mnemonic,
    required String password,
  }) async {
    if (existingWallets.contains(config.dataDir)) {
      throw const WalletError(
        kind: WalletErrorKind.walletAlreadyExists,
        message: 'wallet exists',
      );
    }
    await createGate?.future;
    existingWallets.add(config.dataDir);
    this.password = password;
    createdConfig = config;
    createdMnemonic = mnemonic;
    return session;
  }

  @override
  Future<WalletSession> open({
    required WalletConfig config,
    required String password,
  }) async {
    if (!existingWallets.contains(config.dataDir)) {
      throw const WalletError(
        kind: WalletErrorKind.walletNotFound,
        message: 'no wallet',
      );
    }
    if (password != this.password) {
      throw const WalletError(
        kind: WalletErrorKind.wrongPassword,
        message: 'wrong password',
      );
    }
    return session;
  }

  @override
  Future<void> deleteWallet({required WalletConfig config}) async {
    existingWallets.remove(config.dataDir);
    deletedWallets.add(config.dataDir);
    pinFailureCount = 0;
  }

  /// Wrong PINs since the last right one, as LEPIC counts them. The fake never waits.
  int pinFailureCount = 0;

  /// The PIN of the last [createWithPin].
  String? createdPin;

  /// Sealed texts passed to [FakeWalletSession.confirmPinChange].
  final List<String> confirmedPinChanges = [];

  /// Opens [sealed] with [pin], counting the attempt as LEPIC does.
  void _checkPin(String pin, String sealed) {
    pinFailureCount++;
    if (sealed != fakeSealedPassword(pin)) {
      throw const WalletError(
        kind: WalletErrorKind.wrongPassword,
        message: 'pin did not open the sealed text',
      );
    }
    pinFailureCount = 0;
  }

  @override
  Future<PinWallet> createWithPin({
    required WalletConfig config,
    String? mnemonic,
    required String pin,
  }) async {
    if (existingWallets.contains(config.dataDir)) {
      throw const WalletError(
        kind: WalletErrorKind.walletAlreadyExists,
        message: 'wallet exists',
      );
    }
    await createGate?.future;
    existingWallets.add(config.dataDir);
    createdConfig = config;
    createdMnemonic = mnemonic;
    createdPin = pin;
    pinFailureCount = 0;
    session.owner = this;
    return (session: session, sealedPassword: fakeSealedPassword(pin));
  }

  @override
  Future<WalletSession> openWithPin({
    required WalletConfig config,
    required String pin,
    required String sealedPassword,
  }) async {
    if (!existingWallets.contains(config.dataDir)) {
      throw const WalletError(
        kind: WalletErrorKind.walletNotFound,
        message: 'no wallet',
      );
    }
    _checkPin(pin, sealedPassword);
    session.owner = this;
    return session;
  }

  @override
  Future<int> pinFailures({required WalletConfig config}) async =>
      pinFailureCount;
}

/// The sealed text [FakeWalletService] hands out for [pin]. Not encryption.
String fakeSealedPassword(String pin) => 'fake-sealed|$pin';

/// Scripted open wallet for tests. Mutate the public fields to shape each scenario.
class FakeWalletSession implements WalletSession {
  FakeWalletSession({
    WalletSummary? summary,
    List<TxEntry>? transactions,
    WalletHistory? invoiceHistory,
  }) : summaryValue = summary ?? emptySummary,
       transactionsValue = transactions ?? <TxEntry>[],
       invoiceHistory = invoiceHistory ?? WalletHistory.memory();

  static final WalletSummary emptySummary = WalletSummary(
    lastConfirmedHeight: BigInt.zero,
    minimumConfirmations: BigInt.from(10),
    total: BigInt.zero,
    spendable: BigInt.zero,
    awaitingConfirmation: BigInt.zero,
    awaitingFinalization: BigInt.zero,
    immature: BigInt.zero,
    locked: BigInt.zero,
    validatedWithNode: true,
  );

  WalletSummary summaryValue;
  List<TxEntry> transactionsValue;
  String address = 'esFakeAddress1234567890@epicbox.epiccash.com';
  BigInt fee = BigInt.from(800000);
  Slate sendSlate = const Slate(slateId: 'slate-1', json: '{"id":"slate-1"}');
  Slate responseSlate = const Slate(
    slateId: 'slate-2',
    json: '{"id":"slate-2","step":"response"}',
  );

  /// Progress events emitted by [scan], in order.
  List<ScanProgress> scanEvents = const [
    ScanProgress(percent: 50, message: 'Scanning', finished: false),
    ScanProgress(percent: 100, message: 'Done', finished: true),
  ];

  /// Number of [dispose] calls. The fake keeps working after dispose, so one instance can be
  /// handed out again by a later [FakeWalletService.open].
  int disposeCalls = 0;
  String phrase = FakeWalletService._defaultPhrase;
  final List<int> cancelledTxIds = [];
  final List<BigInt> sentAmounts = [];

  /// The message of every [createSendSlate] and [sendEpicbox] call, null when none was given.
  final List<String?> sentMessages = [];
  final List<String> finalizedSlates = [];
  final List<String> receivedSlates = [];
  int scanCalls = 0;
  final List<({BigInt amount, String to})> epicboxSends = [];

  /// Events the listener emits; tests add to it.
  final StreamController<ListenerEvent> listenerEvents =
      StreamController<ListenerEvent>.broadcast();
  int listenerStarts = 0;
  int listenerStops = 0;

  /// When set, sends throw it.
  WalletError? sendError;

  @override
  void dispose() => disposeCalls++;

  @override
  Future<String> mnemonic({required String password}) async => phrase;

  /// The service that last handed this session out, which holds the PIN state.
  FakeWalletService? owner;

  FakeWalletService get _owner =>
      owner ?? (throw StateError('session not opened by a FakeWalletService'));

  @override
  Future<String> mnemonicWithPin({
    required String pin,
    required String sealedPassword,
  }) async {
    _owner._checkPin(pin, sealedPassword);
    return phrase;
  }

  @override
  Future<String> changePin({
    required String sealedPassword,
    required String oldPin,
    required String newPin,
  }) async {
    if (newPin.length < 4) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'pin has fewer than 4 characters',
      );
    }
    _owner._checkPin(oldPin, sealedPassword);
    return fakeSealedPassword(newPin);
  }

  @override
  Future<void> confirmPinChange({required String sealedPassword}) async =>
      _owner.confirmedPinChanges.add(sealedPassword);

  @override
  Future<void> cancelTransaction({required int txId}) async {
    cancelledTxIds.add(txId);
  }

  /// Keys passed to [repostTransaction].
  final List<String> repostedKeys = [];

  /// When set, [repostTransaction] throws it.
  WalletError? repostError;

  @override
  Future<void> repostTransaction({required String key}) async {
    if (repostError != null) throw repostError!;
    final tx = transactionsValue.where((t) => t.key == key).firstOrNull;
    if (tx == null || !tx.repostable) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message:
            'only a finalized send that is not confirmed can be posted again',
      );
    }
    repostedKeys.add(key);
  }

  /// Keys passed to [releaseStuckSend].
  final List<String> releasedKeys = [];

  @override
  Future<void> releaseStuckSend({required String key}) async {
    final tx = transactionsValue.where((t) => t.key == key).firstOrNull;
    if (tx == null || !tx.releasable) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'only a payment the network refused can be released',
      );
    }
    releasedKeys.add(key);
  }

  @override
  Future<Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
  }) async {
    _checkFunds(amount);
    sentAmounts.add(amount);
    sentMessages.add(message);
    return sendSlate;
  }

  @override
  Future<String> epicboxAddress() async => address;

  @override
  Future<FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
  }) async {
    _checkFunds(amount);
    return FeeEstimate(amount: amount, fee: fee);
  }

  @override
  Future<TxEntry> finalizeAndPost({required String slateJson}) async {
    if (slateJson != responseSlate.json) {
      throw const WalletError(
        kind: WalletErrorKind.invalidSlate,
        message: 'bad slate',
      );
    }
    finalizedSlates.add(slateJson);
    return fakeTx(
      id: 99,
      slateId: responseSlate.slateId,
      kind: TxKind.sent,
      status: TxStatus.awaitingConfirmation,
      createdAtUnix: 1790000000,
      amountDebited: sentAmounts.isEmpty ? BigInt.zero : sentAmounts.last + fee,
      fee: fee,
      numInputs: 1,
      numOutputs: 1,
    );
  }

  /// Like LEPIC, a slate received before gets the same answer, marked as a repeat.
  @override
  Future<ReceivedSlate> receiveSlate({required String slateJson}) async {
    final repeated = receivedSlates.contains(slateJson);
    receivedSlates.add(slateJson);
    return ReceivedSlate(
      slateId: responseSlate.slateId,
      json: responseSlate.json,
      repeated: repeated,
    );
  }

  TxEntry _pendingSend(BigInt amount, {String? to, String? message}) => fakeTx(
    id: 100 + epicboxSends.length,
    slateId: 'send-${epicboxSends.length}',
    kind: TxKind.sent,
    status: TxStatus.awaitingRecipient,
    createdAtUnix: 1790000200,
    amountDebited: amount + fee,
    fee: fee,
    numInputs: 1,
    numOutputs: 0,
    counterparty: to,
    messages: [
      if (message != null) SlateMessage(role: SlateRole.sender, text: message),
    ],
    cancellable: true,
  );

  @override
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
  }) async {
    if (sendError != null) throw sendError!;
    _checkFunds(amount);
    epicboxSends.add((amount: amount, to: address));
    sentMessages.add(message);
    return _pendingSend(amount, to: address, message: message);
  }

  @override
  Stream<ListenerEvent> startListener() {
    listenerStarts++;
    return listenerEvents.stream;
  }

  @override
  Future<void> stopListener() async => listenerStops++;

  @override
  Stream<ScanProgress> scan({BigInt? startHeight}) {
    scanCalls++;
    return Stream.fromIterable(scanEvents);
  }

  @override
  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  }) async => summaryValue;

  /// Percentages [refresh] emits before its last event, which carries [summaryValue].
  List<int> refreshSteps = const [5, 15, 60];

  /// When set, [refresh] emits the steps, then ends with this error.
  WalletError? refreshError;

  /// Number of [refresh] calls.
  int refreshCalls = 0;

  @override
  Stream<RefreshProgress> refresh({
    required BigInt minimumConfirmations,
  }) async* {
    refreshCalls++;
    for (final percent in refreshSteps) {
      yield RefreshProgress(percent: percent, message: 'Checking your funds');
    }
    final error = refreshError;
    if (error != null) throw error;
    yield RefreshProgress(
      percent: 100,
      message: summaryValue.validatedWithNode
          ? 'Up to date'
          : 'Could not reach the node',
      summary: summaryValue,
    );
  }

  /// Number of [transactions] calls, so a test can tell whether home reloaded.
  int transactionsCalls = 0;

  @override
  Future<List<TxEntry>> transactions({required bool refresh}) async {
    transactionsCalls++;
    return [for (final tx in transactionsValue) _withNote(tx)];
  }

  /// Rows [enrichHistory] reports as changed on its next call (then 0 again).
  int enrichChanges = 0;

  /// Number of [enrichHistory] calls.
  int enrichCalls = 0;

  @override
  Future<int> enrichHistory() async {
    enrichCalls++;
    final n = enrichChanges;
    enrichChanges = 0;
    return n;
  }

  /// Notes by transaction key, as [setTxNote] stores them.
  final Map<String, String> notes = {};

  /// Address book, as [saveContact] stores it.
  final List<Contact> contactsValue = [];
  int _contactSeq = 0;

  /// When set, [importHistory] throws it (for example a wrong-wallet error).
  WalletError? importError;

  TxEntry _withNote(TxEntry tx) {
    final note = notes[tx.key];
    if (note == null) return tx;
    return copyTx(tx, note: note);
  }

  @override
  Future<void> setTxNote({required String key, String? note}) async {
    final text = note?.trim() ?? '';
    if (text.isEmpty) {
      notes.remove(key);
    } else {
      notes[key] = text;
    }
  }

  @override
  Future<List<Contact>> contacts() async =>
      [...contactsValue]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  @override
  Future<Contact> saveContact({required Contact contact}) async {
    if (contact.name.trim().isEmpty || contact.address.trim().isEmpty) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'the contact needs a name and an address',
      );
    }
    final stored = Contact(
      id: contact.id.isEmpty ? 'contact-${++_contactSeq}' : contact.id,
      name: contact.name.trim(),
      address: contact.address.trim(),
      note: (contact.note?.trim().isEmpty ?? true)
          ? null
          : contact.note!.trim(),
    );
    final index = contactsValue.indexWhere((c) => c.id == stored.id);
    if (index >= 0) {
      contactsValue[index] = stored;
    } else {
      contactsValue.add(stored);
    }
    return stored;
  }

  @override
  Future<void> deleteContact({required String id}) async =>
      contactsValue.removeWhere((c) => c.id == id);

  static const _exportMagic = 'FAKE-WFEH';

  /// A readable stand-in for the encrypted file: notes and contacts as JSON.
  @override
  Future<Uint8List> exportHistory() async => Uint8List.fromList(
    utf8.encode(
      '$_exportMagic${jsonEncode({
        'notes': notes,
        'contacts': [
          for (final c in contactsValue) {'id': c.id, 'name': c.name, 'address': c.address, 'note': c.note},
        ],
      })}',
    ),
  );

  @override
  Future<String> exportHistoryCsv() async {
    final rows = [
      'date,type,status,amount_epic,fee_epic,counterparty,note,slate_id,kernel,block_height',
      for (final tx in await transactions(refresh: false))
        [
          DateTime.fromMillisecondsSinceEpoch(
            tx.timeUnix * 1000,
            isUtc: true,
          ).toIso8601String(),
          switch (tx.kind) {
            TxKind.coinbase => 'Mining reward',
            TxKind.received || TxKind.receivedCancelled => 'Received',
            TxKind.sent || TxKind.sentCancelled => 'Sent',
          },
          switch (tx.status) {
            TxStatus.confirmed => 'Completed',
            TxStatus.cancelled => 'Cancelled',
            TxStatus.awaitingRecipient => 'Waiting for recipient',
            TxStatus.awaitingConfirmation => 'Confirming',
          },
          tx.amountCredited - tx.amountDebited,
          tx.fee ?? '',
          tx.counterparty ?? '',
          tx.note ?? '',
          tx.slateId ?? '',
          tx.kernelExcess ?? '',
          tx.blockHeight ?? '',
        ].map((v) => '"${'$v'.replaceAll('"', '""')}"').join(','),
    ];
    return '${rows.join('\n')}\n';
  }

  @override
  Future<ImportReport> importHistory({required Uint8List data}) async {
    if (importError != null) throw importError!;
    final text = utf8.decode(data, allowMalformed: true);
    if (!text.startsWith(_exportMagic)) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'This is not a history file',
      );
    }
    final decoded =
        jsonDecode(text.substring(_exportMagic.length)) as Map<String, dynamic>;
    var added = 0;
    var skipped = 0;
    (decoded['notes'] as Map<String, dynamic>).forEach((key, value) {
      if (notes[key] == value) {
        skipped++;
      } else {
        notes[key] = value as String;
        added++;
      }
    });
    var contactsAdded = 0;
    for (final raw in decoded['contacts'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      if (contactsValue.any((e) => e.address == c['address'])) continue;
      contactsValue.add(
        Contact(
          id: c['id'] as String,
          name: c['name'] as String,
          address: c['address'] as String,
          note: c['note'] as String?,
        ),
      );
      contactsAdded++;
    }
    return ImportReport(
      merged: 0,
      added: added,
      skipped: skipped,
      contactsAdded: contactsAdded,
    );
  }

  @override
  Future<FeeEstimate> estimateMax({
    required BigInt minimumConfirmations,
  }) async {
    if (summaryValue.spendable <= fee) {
      throw const WalletError(
        kind: WalletErrorKind.notEnoughFunds,
        message: 'not enough funds',
      );
    }
    return FeeEstimate(amount: summaryValue.spendable - fee, fee: fee);
  }

  void _checkFunds(BigInt amount) {
    if (amount + fee > summaryValue.spendable) {
      throw const WalletError(
        kind: WalletErrorKind.notEnoughFunds,
        message: 'not enough funds',
      );
    }
  }

  // Invoices. The fake plays the wallet's half as UP-14 describes it: the allowlist and the
  // parked invoices are the wallet's, labels and the invoice index live in [invoiceHistory],
  // as the LEPIC session will keep them. Tests and the tour drive it with [relayInvoice],
  // [relayNotice], [clock] and [replyError]; [drainInvoices] picks up what was relayed.

  /// When false, every invoice call throws [invoicesUnsupported], as on a core without them.
  bool invoicesSupported = true;

  /// Labels and the invoice index; a test passes one on a file to check a reopen.
  WalletHistory invoiceHistory;

  /// Now, for expiry. Tests move it forward.
  DateTime Function() clock = DateTime.now;

  /// The wallet's allowlist: full epicbox addresses.
  final List<String> allowlist = [];

  /// Waiting at the relay until the next [drainInvoices].
  final List<_Relayed> _relay = [];

  /// Parked invoices by slate id, in arrival order.
  final Map<String, PendingInvoice> pendingInvoicesValue = {};

  /// Approved invoices by slate id.
  final Map<String, PaidInvoice> paidInvoicesValue = {};

  /// Every [payInvoice] that got past its checks, so a test can prove nothing paid.
  int invoicePayments = 0;

  /// Slate ids whose reply reached the relay, once per delivery.
  final List<String> deliveredReplies = [];

  /// Slate ids declined, in order.
  final List<String> declinedInvoices = [];

  /// When set, delivering an invoice reply fails with it, after the payment is stored.
  WalletError? replyError;

  final StreamController<InvoiceEvent> invoiceEventsController =
      StreamController<InvoiceEvent>.broadcast();

  /// The invoice address at [index].
  static String fakeInvoiceAddress(int index) =>
      'esFakeInvoice$index@epicbox.epiccash.com';

  /// An invoice from [from] waiting at the relay. Parked by the next drain only if [from]'s
  /// key is on the allowlist and [expiresIn] is at most [maxInvoiceExpiry]; dropped
  /// otherwise.
  void relayInvoice({
    required String from,
    required String slateId,
    required BigInt amount,
    String? message,
    Duration expiresIn = const Duration(hours: 24),
  }) => _relay.add(
    _Relayed(
      from: from,
      slateId: slateId,
      amount: amount,
      message: message,
      expiresIn: expiresIn,
    ),
  );

  /// A notice from [from] waiting at the relay: [InvoiceEventKind.posted] (with
  /// [kernelExcess]) or [InvoiceEventKind.withdrawn]. Applied by the next drain only when
  /// [from] is the service of that invoice; dropped otherwise.
  void relayNotice({
    required String from,
    required InvoiceEventKind kind,
    required String slateId,
    String? kernelExcess,
  }) => _relay.add(
    _Relayed(
      from: from,
      slateId: slateId,
      notice: kind,
      kernelExcess: kernelExcess,
    ),
  );

  void _requireInvoices(String call) {
    if (!invoicesSupported) throw invoicesUnsupported(call);
  }

  void _emit(InvoiceEventKind kind, String slateId, {String? kernelExcess}) =>
      invoiceEventsController.add(
        InvoiceEvent(kind: kind, slateId: slateId, kernelExcess: kernelExcess),
      );

  /// Drops the invoices whose time ran out.
  void _sweepExpired() {
    final now = clock();
    final gone = [
      for (final i in pendingInvoicesValue.values)
        if (i.isExpiredAt(now)) i.slateId,
    ];
    for (final id in gone) {
      pendingInvoicesValue.remove(id);
      _emit(InvoiceEventKind.expired, id);
    }
  }

  bool _trusted(String from) =>
      allowlist.any((a) => epicboxKey(a) == epicboxKey(from));

  @override
  bool get supportsInvoices => invoicesSupported;

  @override
  Future<String> invoiceAddress() async {
    _requireInvoices('invoiceAddress');
    return fakeInvoiceAddress(invoiceHistory.invoiceIndex);
  }

  @override
  Future<String> rotateInvoiceAddress() async {
    _requireInvoices('rotateInvoiceAddress');
    final next = invoiceHistory.invoiceIndex + 1;
    await invoiceHistory.setInvoiceIndex(next);
    return fakeInvoiceAddress(next);
  }

  @override
  Future<List<TrustedService>> trustedServices() async {
    _requireInvoices('trustedServices');
    return invoiceHistory.trustedServices(allowlist);
  }

  @override
  Future<TrustedService> addTrustedService({
    required String address,
    required String label,
  }) async {
    _requireInvoices('addTrustedService');
    final a = address.trim();
    if (!fakeEpicboxAddress(a)) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'not an epicbox address',
      );
    }
    final own = [this.address, fakeInvoiceAddress(invoiceHistory.invoiceIndex)];
    if (own.any((o) => epicboxKey(o) == epicboxKey(a))) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'this is one of your own addresses',
      );
    }
    await invoiceHistory.setServiceLabel(a, label);
    final i = allowlist.indexWhere((e) => epicboxKey(e) == epicboxKey(a));
    if (i >= 0) {
      if (allowlist[i] != a) {
        await invoiceHistory.removeServiceLabel(allowlist[i]);
      }
      allowlist[i] = a;
    } else {
      allowlist.add(a);
    }
    return TrustedService(address: a, label: label.trim());
  }

  @override
  Future<void> removeTrustedService({required String address}) async {
    _requireInvoices('removeTrustedService');
    final key = epicboxKey(address);
    for (final a in allowlist.where((e) => epicboxKey(e) == key).toList()) {
      allowlist.remove(a);
      await invoiceHistory.removeServiceLabel(a);
    }
  }

  @override
  Future<InvoiceDrainReport> drainInvoices() async {
    _requireInvoices('drainInvoices');
    var parked = 0, dropped = 0, notices = 0;
    final batch = [..._relay];
    _relay.clear();
    for (final m in batch) {
      final notice = m.notice;
      if (notice == null) {
        if (!_trusted(m.from) || m.expiresIn > maxInvoiceExpiry) {
          dropped++;
          continue;
        }
        // A second copy of a known invoice is acknowledged and changes nothing.
        if (pendingInvoicesValue.containsKey(m.slateId) ||
            paidInvoicesValue.containsKey(m.slateId)) {
          continue;
        }
        final now = clock();
        pendingInvoicesValue[m.slateId] = PendingInvoice(
          slateId: m.slateId,
          senderAddress: m.from,
          amount: m.amount!,
          message: m.message,
          receivedAt: now,
          expiresAt: now.add(m.expiresIn),
        );
        parked++;
        _emit(InvoiceEventKind.received, m.slateId);
        continue;
      }
      // A notice counts only from the service of that invoice.
      final pending = pendingInvoicesValue[m.slateId];
      final paid = paidInvoicesValue[m.slateId];
      final sender = pending?.senderAddress ?? paid?.senderAddress;
      if (sender == null || epicboxKey(sender) != epicboxKey(m.from)) {
        dropped++;
        continue;
      }
      switch (notice) {
        case InvoiceEventKind.posted when paid != null:
          paidInvoicesValue[m.slateId] = paid.withStatus(
            InvoiceStatus.posted,
            kernelExcess: m.kernelExcess,
          );
          _emit(
            InvoiceEventKind.posted,
            m.slateId,
            kernelExcess: m.kernelExcess,
          );
        case InvoiceEventKind.withdrawn when pending != null:
          pendingInvoicesValue.remove(m.slateId);
          _emit(InvoiceEventKind.withdrawn, m.slateId);
        case InvoiceEventKind.withdrawn when paid != null:
          paidInvoicesValue[m.slateId] = paid.withStatus(
            InvoiceStatus.withdrawn,
          );
          _emit(InvoiceEventKind.withdrawn, m.slateId);
        default:
          dropped++;
          continue;
      }
      notices++;
    }
    _sweepExpired();
    return InvoiceDrainReport(
      parked: parked,
      dropped: dropped,
      notices: notices,
    );
  }

  @override
  Future<List<PendingInvoice>> pendingInvoices() async {
    _requireInvoices('pendingInvoices');
    _sweepExpired();
    return [...pendingInvoicesValue.values];
  }

  @override
  Future<PaidInvoice> payInvoice({
    required String slateId,
    required BigInt amount,
  }) async {
    _requireInvoices('payInvoice');
    _sweepExpired();
    final invoice = pendingInvoicesValue[slateId];
    if (invoice == null) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'no pending invoice with that id',
      );
    }
    if (amount != invoice.amount) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'the amount does not match the invoice',
      );
    }
    _checkFunds(amount);
    invoicePayments++;
    pendingInvoicesValue.remove(slateId);
    final txId = 200 + invoicePayments;
    transactionsValue.add(
      fakeTx(
        id: txId,
        slateId: slateId,
        kind: TxKind.sent,
        status: TxStatus.awaitingRecipient,
        createdAtUnix: clock().millisecondsSinceEpoch ~/ 1000,
        amountDebited: amount + fee,
        fee: fee,
        numInputs: 1,
        counterparty: invoice.senderAddress,
        cancellable: true,
      ),
    );
    final paid = PaidInvoice(
      slateId: slateId,
      senderAddress: invoice.senderAddress,
      amount: amount,
      message: invoice.message,
      status: InvoiceStatus.replyFailed,
      txId: txId,
    );
    paidInvoicesValue[slateId] = paid;
    if (replyError != null) return paid;
    return _deliver(paid);
  }

  PaidInvoice _deliver(PaidInvoice paid) {
    deliveredReplies.add(paid.slateId);
    return paidInvoicesValue[paid.slateId] = paid.withStatus(
      InvoiceStatus.replied,
    );
  }

  @override
  Future<PaidInvoice> resendInvoiceReply({required String slateId}) async {
    _requireInvoices('resendInvoiceReply');
    final paid = paidInvoicesValue[slateId];
    if (paid == null) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'no paid invoice with that id',
      );
    }
    if (paid.status != InvoiceStatus.replyFailed) return paid;
    if (replyError != null) throw replyError!;
    return _deliver(paid);
  }

  @override
  Future<void> declineInvoice({required String slateId}) async {
    _requireInvoices('declineInvoice');
    if (pendingInvoicesValue.remove(slateId) == null) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'no pending invoice with that id',
      );
    }
    declinedInvoices.add(slateId);
    _emit(InvoiceEventKind.declined, slateId);
  }

  @override
  Future<PaidInvoice?> paidInvoice({required String slateId}) async {
    _requireInvoices('paidInvoice');
    return paidInvoicesValue[slateId];
  }

  @override
  Stream<InvoiceEvent> invoiceEvents() {
    _requireInvoices('invoiceEvents');
    return invoiceEventsController.stream;
  }

  // Issuing. Requests are transactions in [transactionsValue] with `flow` invoice and their
  // states in [invoiceHistory], as the LEPIC session keeps them; the payer's side is played
  // by [payIssued], [declineIssued], [expireIssued] and [bounceIssued].

  /// When set, [issueInvoice] throws it and records nothing, as LEPIC does when the relay
  /// does not take the invoice.
  WalletError? issueError;

  /// Every [issueInvoice] that got past its checks, with what it sent.
  final List<({BigInt amount, String to, String? message})> issuedRequests = [];

  /// Number of [drainPayments] calls.
  int drainPaymentCalls = 0;

  /// What [peerCapability] answers, by epicbox key; [PeerCapability.unknown] otherwise.
  /// [bounceIssued] sets [PeerCapability.noInvoices], as LEPIC does.
  final Map<String, PeerCapability> peerCapabilities = {};

  final StreamController<IssuerEvent> issuerEventsController =
      StreamController<IssuerEvent>.broadcast();

  List<IssuedInvoice> _requests() =>
      requestsOf(transactionsValue, invoiceHistory.issuedInvoiceState);

  IssuedInvoice? _request(String slateId) =>
      _requests().where((i) => i.slateId == slateId).firstOrNull;

  IssuedInvoice _requireIssued(String slateId) =>
      _request(slateId) ??
      (throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'no issued invoice with that id',
      ));

  /// Moves the request [slateId] to [state] once, with its transaction as LEPIC moves it:
  /// paid stays incoming, any other end is cancelled.
  Future<void> _settleIssued(String slateId, IssuedInvoiceState state) async {
    final kind = issuerEventFor(state);
    final issued = _request(slateId);
    if (kind == null || issued == null) return;
    if (!await invoiceHistory.settleIssuedInvoice(slateId, state)) return;
    final i = transactionsValue.indexWhere((t) => t.slateId == slateId);
    final t = transactionsValue[i];
    final paid = state == IssuedInvoiceState.paid;
    transactionsValue[i] = fakeTx(
      id: t.id,
      slateId: slateId,
      kind: paid ? TxKind.received : TxKind.receivedCancelled,
      status: paid ? TxStatus.awaitingConfirmation : TxStatus.cancelled,
      createdAtUnix: t.createdAtUnix,
      amountCredited: t.amountCredited,
      counterparty: t.counterparty,
      messages: t.messages,
      flow: TxFlow.invoice,
    );
    issuerEventsController.add(
      IssuerEvent(
        kind: kind,
        slateId: slateId,
        payerAddress: issued.payerAddress,
      ),
    );
  }

  @override
  Future<IssuedInvoice> issueInvoice({
    required BigInt amount,
    required String address,
    String? message,
  }) async {
    _requireInvoices('issueInvoice');
    final to = address.trim();
    // Its own addresses first: the fake's are not valid epicbox addresses.
    final own = [this.address, fakeInvoiceAddress(invoiceHistory.invoiceIndex)];
    if (own.any((o) => epicboxKey(o) == epicboxKey(to))) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'this is one of your own addresses',
      );
    }
    if (!fakeEpicboxAddress(to)) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'not an epicbox address',
      );
    }
    if (amount <= BigInt.zero) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'the amount must be above zero',
      );
    }
    if (issueError != null) throw issueError!;
    final text = cutMessage(message);
    issuedRequests.add((amount: amount, to: to, message: text));
    final n = issuedRequests.length;
    final slateId = 'issued-$n';
    // LEPIC keeps it as an incoming invoice waiting for the payer, times to the second.
    transactionsValue.add(
      fakeTx(
        id: 300 + n,
        slateId: slateId,
        kind: TxKind.received,
        status: TxStatus.awaitingConfirmation,
        createdAtUnix: clock().millisecondsSinceEpoch ~/ 1000,
        amountCredited: amount,
        counterparty: to,
        messages: [
          if (text != null) SlateMessage(role: SlateRole.receiver, text: text),
        ],
        cancellable: true,
        flow: TxFlow.invoice,
      ),
    );
    await invoiceHistory.putIssuedInvoice(slateId);
    return _requireIssued(slateId);
  }

  @override
  Future<List<IssuedInvoice>> issuedInvoices() async {
    _requireInvoices('issuedInvoices');
    return _requests();
  }

  @override
  Future<IssuedInvoice?> issuedInvoice({required String slateId}) async {
    _requireInvoices('issuedInvoice');
    return _request(slateId);
  }

  @override
  Future<IssuedInvoice> withdrawInvoice({required String slateId}) async {
    _requireInvoices('withdrawInvoice');
    final issued = _requireIssued(slateId);
    if (!issued.withdrawable) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'only a waiting invoice can be withdrawn',
      );
    }
    cancelledTxIds.add(issued.txId);
    await _settleIssued(slateId, IssuedInvoiceState.withdrawn);
    return _requireIssued(slateId);
  }

  @override
  Future<PaymentsDrainReport> drainPayments() async {
    _requireInvoices('drainPayments');
    drainPaymentCalls++;
    // The sweep: waiting invoices past their time are cancelled.
    final now = clock();
    for (final i in _requests()) {
      if (i.withdrawable && !now.isBefore(i.expiresAt)) {
        await _settleIssued(i.slateId, IssuedInvoiceState.expired);
      }
    }
    return const PaymentsDrainReport();
  }

  @override
  Stream<IssuerEvent> issuerEvents() {
    _requireInvoices('issuerEvents');
    return issuerEventsController.stream;
  }

  @override
  Future<PeerCapability> peerCapability({required String address}) async {
    _requireInvoices('peerCapability');
    return peerCapabilities[epicboxKey(address.trim())] ??
        PeerCapability.unknown;
  }

  /// The payer paid [slateId]; the wallet finalized and posted it.
  Future<void> payIssued(String slateId) =>
      _settleIssued(slateId, IssuedInvoiceState.paid);

  /// The payer declined [slateId]; the wallet withdraws it, as the LEPIC session does.
  Future<void> declineIssued(String slateId) =>
      _endIssued(slateId, IssuedInvoiceState.declined);

  /// The wallet's sweep cancelled [slateId] unpaid.
  Future<void> expireIssued(String slateId) =>
      _settleIssued(slateId, IssuedInvoiceState.expired);

  /// The payer's wallet sent [slateId] back unpaid: the wallet withdraws it once and learns
  /// that payer cannot pay invoices, as the LEPIC session does. Call it again for a bounce
  /// LEPIC delivers twice.
  Future<void> bounceIssued(String slateId) async {
    final payer = _request(slateId)?.payerAddress;
    if (payer != null) {
      peerCapabilities[epicboxKey(payer)] = PeerCapability.noInvoices;
    }
    await _endIssued(slateId, IssuedInvoiceState.bounced);
  }

  Future<void> _endIssued(String slateId, IssuedInvoiceState state) async {
    final issued = _request(slateId);
    if (issued == null || !issued.withdrawable) return;
    cancelledTxIds.add(issued.txId);
    await _settleIssued(slateId, state);
  }
}

/// A message waiting at the fake relay: an invoice, or a notice when [notice] is set.
class _Relayed {
  _Relayed({
    required this.from,
    required this.slateId,
    this.amount,
    this.message,
    this.expiresIn = Duration.zero,
    this.notice,
    this.kernelExcess,
  });

  final String from;
  final String slateId;
  final BigInt? amount;
  final String? message;
  final Duration expiresIn;
  final InvoiceEventKind? notice;
  final String? kernelExcess;
}

/// A [TxEntry] for tests, with the fields most tests do not care about filled in. [key] defaults
/// to `s:<slateId>`, else `l:<id>`.
TxEntry fakeTx({
  String? key,
  int? id,
  String? slateId,
  TxKind kind = TxKind.received,
  TxStatus? status,
  TxSource source = TxSource.wallet,
  int createdAtUnix = 1790000000,
  int? timeUnix,
  bool? confirmed,
  BigInt? blockHeight,
  int? blockTimeUnix,
  BigInt? amountCredited,
  BigInt? amountDebited,
  BigInt? fee,
  int numInputs = 0,
  int numOutputs = 1,
  String? kernelExcess,
  List<String> outputCommits = const [],
  String? counterparty,
  String? note,
  List<SlateMessage> messages = const [],
  BigInt? ttlCutoffHeight,
  bool cancellable = false,
  bool repostable = false,
  String? statusDetail,
  bool releasable = false,
  int? finalizedAtUnix,
  CancelReason? cancelReason,
  TxFlow flow = TxFlow.payment,
}) {
  final resolvedStatus =
      status ??
      ((confirmed ?? false)
          ? TxStatus.confirmed
          : TxStatus.awaitingConfirmation);
  return TxEntry(
    key:
        key ??
        (slateId != null
            ? 's:$slateId'
            : id != null
            ? 'l:$id'
            : 'x:$createdAtUnix'),
    id: id,
    slateId: slateId,
    kind: kind,
    status: resolvedStatus,
    source: source,
    createdAtUnix: createdAtUnix,
    timeUnix: timeUnix ?? createdAtUnix,
    confirmed: confirmed ?? resolvedStatus == TxStatus.confirmed,
    blockHeight: blockHeight,
    blockTimeUnix: blockTimeUnix,
    amountCredited: amountCredited ?? BigInt.zero,
    amountDebited: amountDebited ?? BigInt.zero,
    fee: fee,
    numInputs: numInputs,
    numOutputs: numOutputs,
    kernelExcess: kernelExcess,
    outputCommits: outputCommits,
    counterparty: counterparty,
    note: note,
    messages: messages,
    ttlCutoffHeight: ttlCutoffHeight,
    cancellable: cancellable,
    repostable: repostable,
    statusDetail: statusDetail,
    releasable: releasable,
    finalizedAtUnix: finalizedAtUnix,
    cancelReason: cancelReason,
    flow: flow,
  );
}

/// [tx] with [note] replaced.
TxEntry copyTx(TxEntry tx, {String? note}) => TxEntry(
  key: tx.key,
  id: tx.id,
  slateId: tx.slateId,
  kind: tx.kind,
  status: tx.status,
  source: tx.source,
  createdAtUnix: tx.createdAtUnix,
  timeUnix: tx.timeUnix,
  confirmed: tx.confirmed,
  blockHeight: tx.blockHeight,
  blockTimeUnix: tx.blockTimeUnix,
  amountCredited: tx.amountCredited,
  amountDebited: tx.amountDebited,
  fee: tx.fee,
  numInputs: tx.numInputs,
  numOutputs: tx.numOutputs,
  kernelExcess: tx.kernelExcess,
  outputCommits: tx.outputCommits,
  counterparty: tx.counterparty,
  note: note,
  messages: tx.messages,
  ttlCutoffHeight: tx.ttlCutoffHeight,
  cancellable: tx.cancellable,
  repostable: tx.repostable,
  statusDetail: tx.statusDetail,
  releasable: tx.releasable,
  finalizedAtUnix: tx.finalizedAtUnix,
  cancelReason: tx.cancelReason,
  flow: tx.flow,
);
