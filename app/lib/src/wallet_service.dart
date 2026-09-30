/// The boundary between the UI and the native wallet core.
///
/// UI code depends on [WalletService] and [WalletSession] only. [RustWalletService] forwards to
/// the flutter_rust_bridge API; tests use [FakeWalletService].
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'rust/api/types.dart';
import 'rust/api/wallet.dart' as rust;

export 'rust/api/types.dart';

/// Free functions of the native API plus the two ways to obtain an open wallet.
abstract interface class WalletService {
  String generateMnemonic({required int wordCount});

  bool validateMnemonic({required String phrase});

  /// Reads a slate's id, amount, fee and step without touching a wallet. Throws [WalletError]
  /// with [WalletErrorKind.invalidSlate] for anything that is not a slate.
  SlateInfo inspectSlate({required String json});

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

  /// Deletes the wallet files in `config.dataDir`. Every session on it must be disposed first.
  /// Only the recovery phrase can bring the wallet back.
  Future<void> deleteWallet({required WalletConfig config});
}

/// An open wallet. Mirrors the methods of the native `EpicWallet`.
///
/// Call [dispose] when done. The core allows one chain per process, so every session must be
/// disposed before a wallet on another chain can be opened.
abstract interface class WalletSession {
  void dispose();

  Future<String> mnemonic({required String password});

  Future<void> cancelTransaction({required int txId});

  /// Posts a finalized send that never reached the chain again ([TxEntry.repostable]). Its
  /// inputs stay locked until it confirms.
  Future<void> repostTransaction({required String key});

  Future<Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
  });

  Future<String> epicboxAddress();

  Future<FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
  });

  Future<TxEntry> finalizeAndPost({required String slateJson});

  /// Sends to a wallet listening on HTTP and posts the transaction, in one call.
  Future<TxEntry> sendHttp({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String url,
  });

  /// Posts a send over epicbox. The listener finalizes it when the recipient answers.
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
  });

  /// Starts the epicbox listener and streams its events. It runs until [stopListener] or
  /// [dispose].
  Stream<ListenerEvent> startListener();

  Future<void> stopListener();

  Future<Slate> receiveSlate({required String slateJson});

  Stream<ScanProgress> scan({BigInt? startHeight});

  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  });

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
}

/// Production implementation backed by the Rust core. Requires `RustLib.init()` first.
class RustWalletService implements WalletService {
  const RustWalletService();

  @override
  String generateMnemonic({required int wordCount}) =>
      rust.generateMnemonic(wordCount: wordCount);

  @override
  bool validateMnemonic({required String phrase}) =>
      rust.validateMnemonic(phrase: phrase);

  @override
  SlateInfo inspectSlate({required String json}) =>
      rust.inspectSlate(json: json);

  @override
  bool validateEpicboxAddress({required String address}) =>
      rust.validateEpicboxAddress(address: address);

  @override
  Future<bool> walletExists({required WalletConfig config}) =>
      rust.walletExists(config: config);

  @override
  Future<NodeTip> nodeTip({required WalletConfig config}) =>
      rust.nodeTip(config: config);

  @override
  Future<WalletSession> create({
    required WalletConfig config,
    String? mnemonic,
    required String password,
  }) async => _RustWalletSession(
    await rust.EpicWallet.create(
      config: config,
      mnemonic: mnemonic,
      password: password,
    ),
  );

  @override
  Future<WalletSession> open({
    required WalletConfig config,
    required String password,
  }) async => _RustWalletSession(
    await rust.EpicWallet.open(config: config, password: password),
  );

  @override
  Future<void> deleteWallet({required WalletConfig config}) async {
    final dir = Directory(config.dataDir);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

class _RustWalletSession implements WalletSession {
  _RustWalletSession(this._wallet);

  final rust.EpicWallet _wallet;

  @override
  void dispose() {
    if (!_wallet.isDisposed) _wallet.dispose();
  }

  @override
  Future<String> mnemonic({required String password}) =>
      _wallet.mnemonic(password: password);

  @override
  Future<void> cancelTransaction({required int txId}) =>
      _wallet.cancelTransaction(txId: txId);

  @override
  Future<void> repostTransaction({required String key}) =>
      _wallet.repostTransaction(key: key);

  @override
  Future<Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
  }) => _wallet.createSendSlate(
    amount: amount,
    minimumConfirmations: minimumConfirmations,
  );

  @override
  Future<String> epicboxAddress() => _wallet.epicboxAddress();

  @override
  Future<FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
  }) => _wallet.estimateFee(
    amount: amount,
    minimumConfirmations: minimumConfirmations,
  );

  @override
  Future<TxEntry> finalizeAndPost({required String slateJson}) =>
      _wallet.finalizeAndPost(slateJson: slateJson);

  @override
  Future<Slate> receiveSlate({required String slateJson}) =>
      _wallet.receiveSlate(slateJson: slateJson);

  @override
  Future<TxEntry> sendHttp({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String url,
  }) => _wallet.sendHttp(
    amount: amount,
    minimumConfirmations: minimumConfirmations,
    url: url,
  );

  @override
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
  }) => _wallet.sendEpicbox(
    amount: amount,
    minimumConfirmations: minimumConfirmations,
    address: address,
  );

  @override
  Stream<ListenerEvent> startListener() => _wallet.startListener();

  @override
  Future<void> stopListener() async {
    if (!_wallet.isDisposed) await _wallet.stopListener();
  }

  @override
  Stream<ScanProgress> scan({BigInt? startHeight}) =>
      _wallet.scan(startHeight: startHeight);

  @override
  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  }) => _wallet.summary(
    refresh: refresh,
    minimumConfirmations: minimumConfirmations,
  );

  @override
  Future<List<TxEntry>> transactions({required bool refresh}) =>
      _wallet.transactions(refresh: refresh);

  @override
  Future<int> enrichHistory() => _wallet.enrichHistory();

  @override
  Future<void> setTxNote({required String key, String? note}) =>
      _wallet.setTxNote(key: key, note: note);

  @override
  Future<List<Contact>> contacts() => _wallet.contacts();

  @override
  Future<Contact> saveContact({required Contact contact}) =>
      _wallet.saveContact(contact: contact);

  @override
  Future<void> deleteContact({required String id}) =>
      _wallet.deleteContact(id: id);

  @override
  Future<Uint8List> exportHistory() => _wallet.exportHistory();

  @override
  Future<String> exportHistoryCsv() => _wallet.exportHistoryCsv();

  @override
  Future<ImportReport> importHistory({required Uint8List data}) =>
      _wallet.importHistory(data: data);

  @override
  Future<FeeEstimate> estimateMax({required BigInt minimumConfirmations}) =>
      _wallet.estimateMax(minimumConfirmations: minimumConfirmations);
}

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

  /// Phrase returned by [generateMnemonic] and accepted by [validateMnemonic].
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
  String generateMnemonic({required int wordCount}) => phrase;

  @override
  bool validateMnemonic({required String phrase}) => phrase == this.phrase;

  /// Slates [inspectSlate] recognises, by JSON text.
  final Map<String, SlateInfo> slateInfos = {};

  @override
  SlateInfo inspectSlate({required String json}) {
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
      RegExp(r'^[1-9A-HJ-NP-Za-km-z]{52}@[a-z0-9.]+(:\d+)?$').hasMatch(address);

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
  }
}

/// Scripted open wallet for tests. Mutate the public fields to shape each scenario.
class FakeWalletSession implements WalletSession {
  FakeWalletSession({WalletSummary? summary, List<TxEntry>? transactions})
    : summaryValue = summary ?? emptySummary,
      transactionsValue = transactions ?? <TxEntry>[];

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
  final List<String> finalizedSlates = [];
  final List<String> receivedSlates = [];
  int scanCalls = 0;
  final List<({BigInt amount, String to})> httpSends = [];
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

  @override
  Future<Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
  }) async {
    _checkFunds(amount);
    sentAmounts.add(amount);
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

  @override
  Future<Slate> receiveSlate({required String slateJson}) async {
    receivedSlates.add(slateJson);
    return responseSlate;
  }

  TxEntry _pendingSend(BigInt amount, {required bool posted, String? to}) =>
      fakeTx(
        id: 100 + httpSends.length + epicboxSends.length,
        slateId: 'send-${httpSends.length + epicboxSends.length}',
        kind: TxKind.sent,
        status: posted
            ? TxStatus.awaitingConfirmation
            : TxStatus.awaitingRecipient,
        createdAtUnix: 1790000200,
        amountDebited: amount + fee,
        fee: fee,
        numInputs: 1,
        numOutputs: posted ? 1 : 0,
        counterparty: to,
        cancellable: !posted,
      );

  @override
  Future<TxEntry> sendHttp({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String url,
  }) async {
    if (sendError != null) throw sendError!;
    _checkFunds(amount);
    httpSends.add((amount: amount, to: url));
    return _pendingSend(amount, posted: true, to: url);
  }

  @override
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
  }) async {
    if (sendError != null) throw sendError!;
    _checkFunds(amount);
    epicboxSends.add((amount: amount, to: address));
    return _pendingSend(amount, posted: false, to: address);
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

  @override
  Future<List<TxEntry>> transactions({required bool refresh}) async => [
    for (final tx in transactionsValue) _withNote(tx),
  ];

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
  BigInt? ttlCutoffHeight,
  bool cancellable = false,
  bool repostable = false,
  String? statusDetail,
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
    ttlCutoffHeight: ttlCutoffHeight,
    cancellable: cancellable,
    repostable: repostable,
    statusDetail: statusDetail,
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
  ttlCutoffHeight: tx.ttlCutoffHeight,
  cancellable: tx.cancellable,
  repostable: tx.repostable,
  statusDetail: tx.statusDetail,
);
