/// The one seam between the desktop UI and a wallet. Screens never call this directly: they
/// read [deskProvider] (`state.dart`) and call its actions. Today [MockDeskWallet] answers;
/// a LEPIC adapter over `WalletService` replaces it by overriding [deskApiProvider].
library;

import 'dart:typed_data';

import 'http_address.dart';
import 'invoices.dart';
import 'models.dart';

abstract interface class DeskWalletApi {
  // Wallets on this computer and opening one.
  /// The wallets of this network; [WalletEntry.current] is the one [unlock] opens.
  Future<List<WalletEntry>> wallets();

  /// Whether the first-run setup (Node, Epicbox, Review) of wallet [id] is still to be done:
  /// set when the wallet is created or restored, cleared by the setup's Save. Unlock of such a
  /// wallet goes to the setup first, also after the app was closed halfway.
  Future<bool> setupPending(String id);
  Future<void> setSetupPending(String id, bool pending);

  /// Picks the wallet [unlock] opens next (Unlock's Wallet select). The open one stays open.
  Future<void> selectWallet(String id);

  /// Opens the selected wallet; false on a wrong password. [remember] keeps the password on
  /// this computer for that wallet (`remember.dart`); off forgets one kept before.
  Future<bool> unlock(String password, {bool remember = false});

  /// Opens the selected wallet with the password remembered on this computer; false when
  /// none is kept, it expired, or it no longer opens the wallet (then it is forgotten).
  Future<bool> unlockRemembered();

  /// Whether a password is remembered on this computer for the wallet [id].
  Future<bool> isRemembered(String id);

  /// "Forget this computer": drops the remembered password of the wallet [id].
  Future<void> forgetRemembered(String id);

  /// Whether the last [unlock] with remember on opened the wallet but could not keep the
  /// password (the OS store refused).
  bool get notRemembered;

  /// Whether the open wallet was opened with the remembered password. Sends ask the password
  /// either way.
  bool get openedRemembered;

  /// Whether [password] is the open wallet's password.
  Future<bool> checkPassword(String password);

  /// Closes the open wallet. A send, finalize, split or consolidate under way finishes first
  /// ([busy]): the lock waits for it, never ends it mid-way.
  Future<void> lock();

  /// Whether a call that changes the wallet runs now (a send, a file received or finalized, a
  /// split, a consolidate, a repost or a cancel): [lock] waits for it.
  bool get busy;

  /// Renames the wallet [id] (1 to 32 characters).
  Future<void> renameWallet(String id, String label);

  /// Removes the wallet [id]: from the list only, or its keys and database too
  /// ([WalletRemoval]). The open wallet is locked first, and needs its [password]. Only the
  /// recovery phrase brings a deleted wallet back.
  Future<void> removeWallet(String id, WalletRemoval mode, {String? password});

  /// Wallet folders of this app that the list lost (removed from the list only); none in the
  /// mock. Pass one to [addBack].
  Future<List<WalletEntry>> findRemoved();
  Future<void> addBack(String id);

  // First run.
  /// A phrase to show before a wallet exists (the screenshot tour only; a real wallet's phrase
  /// comes from [createWallet]).
  Future<List<String>> newPhrase({int words = 24});

  /// Makes a wallet with a new recovery phrase and returns the phrase, for the backup step:
  /// the first one on this computer, or one more in the list,
  /// which becomes the selected one. Passwords under [minPasswordLength] are refused.
  Future<List<String>> createWallet({String name = '', required String password});

  /// Whether [words] is a recovery phrase: 12, 15, 18, 21 or 24 words of the list whose check
  /// bits match. Answers at once; the restore grid calls it after every change.
  bool checkPhrase(List<String> words);

  /// The listed wallet of this network that [words] is the recovery phrase of, by the
  /// fingerprint the app kept when it made the wallet; null when none, or when [words] is not
  /// a phrase. Wallets made before the app kept fingerprints are never matched. Restore asks
  /// before the password step, so a phrase already here opens that wallet instead.
  Future<WalletEntry?> walletWithPhrase(List<String> words);

  /// Restores a wallet from [phrase]. A phrase [walletWithPhrase] knows throws a [DeskError]
  /// with [DeskError.sameWallet] set and makes nothing.
  Future<void> restoreWallet({String name = '', required String password, required List<String> phrase});

  // Import (only when [DeskFeatures.importWizard]). Old folders are only read.
  /// Looks where older Epic Wallets and the epic program kept wallets, and starts a new import
  /// run (see [cancelImport]). Wallets the app holds already have [OldWallet.sameAs] set.
  Future<List<OldWallet>> findOldWallets();

  /// Asks for a folder with the system dialog and lists the wallets in it; null when the
  /// dialog was closed.
  Future<FolderFind?> pickFolder();

  /// Whether a running program uses the wallet [id] ([OldWallet.id]).
  Future<OldWalletUse> checkOldWallet(String id);

  /// Makes a new wallet from the old wallet's wallet.seed, opened once with [oldPassword]. The
  /// new wallet's password is [newPassword], else [oldPassword] when it has
  /// [minPasswordLength] characters ([DeskError.newPasswordNeeded] otherwise). A wrong
  /// [oldPassword] throws [DeskError.wrongPassword] and makes nothing.
  Future<ImportedWallet> importOldWallet(String id, {required String oldPassword, String? newPassword});

  /// Deletes the wallets this run imported. Old folders are unchanged.
  Future<void> cancelImport();

  // Reading.
  Future<WalletAccount> account();
  Future<Balance> balance();
  Future<List<Tx>> transactions();
  Future<List<Output>> outputs();
  Future<List<Contact>> contacts();
  Future<ServiceStatus> status();
  Future<List<NodeServer>> nodes();
  Future<List<EpicboxServer>> epicboxes();
  Future<DeskSettings> settings();
  Future<String> epicboxAddress();
  /// The address senders use for the running HTTP listener: `http://127.0.0.1:<port>` when
  /// Local only, `http://<the router's public IP>:<port>` when From the internet ([httpReach];
  /// the LAN address when the public IP cannot be found); empty while it is off. Only when
  /// [DeskFeatures.httpDirect].
  Future<String> httpAddress();
  /// From the internet with the listener on: the public IP, the LAN address and whether the
  /// internet reaches the port, asked over HTTPS and kept 2 minutes, or asked again on
  /// [recheck] or a network change. Null when Local only, off, or Tor is on (nothing is asked
  /// over the clearnet then).
  Future<HttpReach?> httpReach({bool recheck = false});
  /// This wallet's onion, `http://<56 characters>.onion`, the address senders use over Tor.
  /// Known before tor runs; screens show it only while [DeskSettings.tor] is on. Only when
  /// [DeskFeatures.tor].
  Future<String> torAddress();

  /// Whether [to] is an onion v3 address (version and checksum), for Send's Direct.
  bool isOnionAddress(String to);

  /// An Epicbox address whose key and checksum hold on this wallet's chain; with or without
  /// `@server`.
  bool isEpicboxAddress(String to);

  // Acting.
  Future<int> estimateFee(int amount);

  /// The largest amount that can be sent now, with its fee and lock figures (Send › All).
  /// Send it with `SendOptions(strategy: SelectionStrategy.all)`.
  Future<SendEstimate> estimateMax();

  /// What a send of [amount] with [options] would spend, pay and get back now (F11's summary,
  /// F12's SmartOutputs: `planSend` in `smart_outputs.dart`); nothing is locked. Null
  /// [options] is the wallet's default. A split the coins cannot build throws a [DeskError]
  /// with [DeskError.unbuildable].
  Future<SendEstimate> estimateSend(int amount, {SendOptions? options});

  /// The open wallet's Outputs choices: default strategy and SmartOutputs (F13, D-5).
  Future<OutputPrefs> outputPrefs();

  /// Keeps the open wallet's Outputs choices; Send uses them from its next estimate.
  Future<void> saveOutputPrefs(OutputPrefs prefs);

  // Outputs (F13, the Outputs page). A split and a consolidate are normal
  // network transactions to the wallet itself; each spends every spendable output, so the
  // whole balance is locked until it confirms.

  /// The fee and inputs of splitting the spendable balance into [outputs] outputs (2 to 10).
  Future<SendEstimate> estimateSplit(int outputs);
  Future<SelfSend> splitOutputs(int outputs);

  /// The fee and inputs of merging every spendable output into one.
  Future<SendEstimate> estimateConsolidate();
  Future<SelfSend> consolidateOutputs();

  /// Posts again a split or consolidate the node did not take ([DeskError.notPostedTx]).
  /// Throws a [DeskError] when the node refuses it again.
  Future<void> repostTx(int id);

  /// Sends the undelivered send [id] again over its method ([Tx.undelivered]): to the same
  /// Epicbox address, URL or onion. Throws a [DeskError] when it fails again.
  Future<void> resendTx(int id);
  Future<SendResult> send(SendRequest request);
  Future<ReceivedFile> receiveFile(String fileName);
  Future<Tx> finalizeFile(String fileName);
  Future<void> cancelTx(int id);
  Future<String> exportProof(int id);
  /// Adds (empty id) or replaces [contact] and returns its id. Only stores: an address is never checked over the network.
  Future<String> saveContact(Contact contact);
  Future<void> deleteContact(String id);
  Future<void> saveSettings(DeskSettings settings);
  Future<void> useNode(String url);

  /// Turns the built-in node on (starts it and moves the wallet to it) or off (moves the wallet
  /// back to the node used before, then stops it). Only when [DeskFeatures.builtInNode].
  Future<void> useBuiltInNode(bool on);
  Future<NodeServer> checkNode(String url);
  Future<void> addNode(NodeServer node);
  Future<void> useEpicbox(String domain);

  /// Starts or stops the receive listener (Epicbox, and HTTP when [DeskSettings.directHttp]).
  /// Transitional: the screens move to [setEpicboxListening] and [startAutostart] (W4 §3.1),
  /// then this goes.
  Future<void> setListening(bool on);

  /// Starts or stops Epicbox receiving alone (HTTP and Tor untouched). Progress and failures
  /// show in [ServiceStatus.epicboxHealth].
  Future<void> setEpicboxListening(bool on);

  /// At unlock: starts every method whose Start with the wallet is on
  /// ([DeskSettings.epicboxAutostart], [DeskSettings.httpAutostart], [DeskSettings.torAutostart]).
  /// Each method that does not start shows it in [status]; nothing throws.
  Future<void> startAutostart();

  /// Starts or stops the HTTP listener alone, on [DeskSettings.httpPort], reachable as
  /// [DeskSettings.publicMode] says. A start that fails shows in [ServiceStatus.httpProblem].
  /// Only when [DeskFeatures.httpDirect].
  Future<void> setHttpListening(bool on);

  /// Turns Tor on or off for the open wallet now, saved per wallet ([DeskSettings.tor]); whether
  /// it starts at unlock is [DeskSettings.torAutostart]. On again after a failure is Retry.
  /// Progress and failures show in [ServiceStatus.tor]. Only when [DeskFeatures.tor].
  Future<void> setTor(bool on);

  /// Epicbox over Tor for the open wallet and the ones opened later, not saved here: while on
  /// and Tor is on, the Epicbox connection goes through Tor and never directly, waiting while
  /// tor starts ([ServiceStatus.epicboxViaTor]). On until set. Applies at once.
  Future<void> setEpicboxOverTor(bool on);
  /// Refresh (Overview, Activity): brings the balance and history up to date with the node
  /// now and returns when that is done. Throws a [DeskError] when the node did not answer.
  Future<void> syncNow();

  /// Scans the chain again, with progress; the stream ends when the scan does, after the
  /// balance is brought up to date. [deleteUnconfirmed] also cancels unconfirmed
  /// transactions and unlocks their coins (only when [DeskFeatures.rescanRepair]).
  Stream<ScanStep> rescan({bool deleteUnconfirmed = false});

  /// Ends a running [rescan] at the core's next page; its stream then ends without a
  /// finished step.
  Future<void> stopRescan();

  /// Fires when something the screens show changed in the background (a payment arrived, a
  /// sync finished, the listener connected). [DeskController] reloads on it.
  Stream<void> changes();
  Future<List<String>> revealPhrase(String password);
  /// Re-encrypts the open wallet under [next] and forgets its remembered password. A wrong
  /// [current] throws a [DeskError] with `wrongPassword`. Only when [DeskFeatures.changePassword].
  Future<void> changePassword(String current, String next);

  // History backup (F34) and its reminder (F33).
  /// The open wallet's history backup record. Notes the first time there was something to
  /// remind of (the start of the reminder's 30 days).
  Future<HistoryBackupState> historyBackupState();

  /// The sealed `.wfeh` bytes of the open wallet's history: only a wallet with the same
  /// recovery phrase opens them.
  Future<Uint8List> exportHistory();

  /// The payments as CSV, newest first; with [from]/[to] only those on those local days
  /// (inclusive).
  Future<String> exportHistoryCsv({DateTime? from, DateTime? to});

  /// Merges a `.wfeh` of this wallet. A refused file throws a [HistoryFileError]. When the file
  /// disagrees with details the user typed, nothing is written and the answer has
  /// [HistoryImport.applied] false with the [HistoryImport.conflicts]; call again with
  /// [useBackup] (by [ImportConflict.id]: true takes the file's value, false or missing keeps
  /// the user's).
  Future<HistoryImport> importHistory(Uint8List data, {Map<String, bool>? useBackup});

  /// Names the payment [key] ([Tx.key]), or removes the name when [label] is null or blank.
  /// At most [txLabelMaxLength] characters. Any payment takes a label.
  Future<void> setTxLabel(String key, String? label);

  /// Sets what the user knows of a payment a scan found ([Tx.restored]): who paid
  /// ([counterparty], never verified), how it came ([transport], one of [txTransports]) and a
  /// [note]. Each null or blank value clears that field. Throws a [DeskError] for any other row.
  Future<void> setTxDetails(String key, {String? counterparty, String? transport, String? note});

  /// Records an export saved at [when], with what it held.
  Future<void> markHistoryExported(DateTime when);

  /// "Not now" on the reminder, at [when].
  Future<void> dismissHistoryReminder(DateTime when);

  // Invoices over Epicbox (docs/invoices/flow.md on plan/invoices; types in invoices.dart).
  // Everything shows only when [supportsInvoices].
  bool get supportsInvoices;

  /// What the wallet learned of invoices by itself (paid, declined, expired, sent back,
  /// withdrawn), for a notice; the open wallet's only.
  Stream<InvoiceNotice> invoiceNotices();

  /// Requests sent, invoices received, the invoice address and the trusted list, as stored.
  Future<InvoiceBook> invoices();

  /// Drains the invoice address (invoices from trusted senders are parked, others ignored
  /// unread) and the payments address (payments for requests are finalized and posted), then
  /// sweeps expired ones. Throws a [DeskError] when the relay could not be reached; the stored
  /// lists stay as they were.
  Future<InvoiceBook> checkInvoices();

  /// Sends the payer at [PaymentRequestDraft.payerAddress] (their invoice address) a request.
  /// Nothing leaves the wallet, so no password. A request the relay did not take is cancelled at
  /// once and throws a [DeskError]: nothing was sent.
  Future<IssuedRequest> requestPayment(PaymentRequestDraft draft);

  /// Withdraws a waiting request; a LEPIC payer is told.
  Future<void> withdrawRequest(String slateId);

  /// Posts a finalized request's payment again (the node refused it or was unreachable).
  Future<void> repostRequest(String slateId);

  /// Cancels the payment of a paid request that was never posted ([RequestState.notPosted]):
  /// the core asks the node first and refuses one in the pool or on chain ([InvoiceError]
  /// onItsWay, or cannotCheck when the node cannot be asked).
  Future<void> cancelRequestPayment(String slateId);

  /// Pays a waiting invoice: checks [password], signs for the invoice's own [amount] and sends
  /// the reply to the sender's stored address. The only caller is Review's Approve. A reply
  /// that did not reach the relay comes back as [PayState.notDelivered], stored and locked.
  Future<IncomingInvoice> payInvoice(String slateId, {required int amount, required String password});

  /// Sends the stored reply of a [PayState.notDelivered] payment again; signs nothing.
  Future<IncomingInvoice> retryInvoiceReply(String slateId);

  /// Declines a waiting invoice and tells the sender when its wallet can hear it.
  Future<void> declineInvoice(String slateId);

  /// Cancels an invoice's payment once the node says it is neither in the pool nor on the
  /// chain; throws a [DeskError] when it is, or when the node cannot be asked.
  Future<void> cancelInvoicePayment(String slateId);

  /// After [cancelInvoicePayment]: spends the coins that payment had locked to this wallet
  /// itself (D-2), so the service's signed copy can never complete. Costs a fee; asks no
  /// password, as a consolidate does. Throws a [DeskError] when it did not go out.
  Future<SelfSend> spendCancelledToSelf(String slateId);

  /// Moves to the next invoice address; senders holding the old one can no longer bill.
  Future<String> rotateInvoiceAddress();

  /// Lets the payments address [address] send invoices, under [label].
  Future<void> trustSender(String address, String label, {String? contactId});

  /// Stops [address] (matched on the key) from sending invoices. Waiting ones stay.
  Future<void> untrustSender(String address);

  Future<void> setInvoiceExpiry(Duration expiry);

  /// What the wallet learned of the payer at [address].
  Future<PeerCapability> peerCapability(String address);
}
