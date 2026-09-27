/// The boundary between the UI and the native wallet core.
///
/// UI code depends on [WalletService] and [WalletSession] only. [RustWalletService] forwards to
/// the flutter_rust_bridge API; tests use [FakeWalletService].
library;

import 'dart:async';

import 'rust/api/types.dart';
import 'rust/api/wallet.dart' as rust;

export 'rust/api/types.dart';

/// Free functions of the native API plus the two ways to obtain an open wallet.
abstract interface class WalletService {
  String generateMnemonic({required int wordCount});

  bool validateMnemonic({required String phrase});

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
}

/// An open wallet. Mirrors the methods of the native `EpicWallet`.
abstract interface class WalletSession {
  Future<void> cancelTransaction({required int txId});

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

  Future<Slate> receiveSlate({required String slateJson});

  Stream<ScanProgress> scan({BigInt? startHeight});

  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  });

  Future<List<TxEntry>> transactions({required bool refresh});
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
}

class _RustWalletSession implements WalletSession {
  _RustWalletSession(this._wallet);

  final rust.EpicWallet _wallet;

  @override
  Future<void> cancelTransaction({required int txId}) =>
      _wallet.cancelTransaction(txId: txId);

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

  @override
  String generateMnemonic({required int wordCount}) => phrase;

  @override
  bool validateMnemonic({required String phrase}) => phrase == this.phrase;

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

  final List<int> cancelledTxIds = [];
  final List<BigInt> sentAmounts = [];
  final List<String> finalizedSlates = [];
  final List<String> receivedSlates = [];
  int scanCalls = 0;

  @override
  Future<void> cancelTransaction({required int txId}) async {
    cancelledTxIds.add(txId);
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
    return TxEntry(
      id: 99,
      slateId: responseSlate.slateId,
      kind: TxKind.sent,
      createdAtUnix: 1790000000,
      confirmed: false,
      amountCredited: BigInt.zero,
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
  Future<List<TxEntry>> transactions({required bool refresh}) async =>
      transactionsValue;

  void _checkFunds(BigInt amount) {
    if (amount + fee > summaryValue.spendable) {
      throw const WalletError(
        kind: WalletErrorKind.notEnoughFunds,
        message: 'not enough funds',
      );
    }
  }
}
