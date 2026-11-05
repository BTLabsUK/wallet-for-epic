// SPDX-License-Identifier: Apache-2.0
/// The one seam between the desktop UI and a wallet. Screens never call this directly: they
/// read [deskProvider] (`state.dart`) and call its actions. Today [MockDeskWallet] answers;
/// a LEPIC adapter over `WalletService` replaces it by overriding [deskApiProvider].
library;

import 'dart:typed_data';

import '../../devices/device_model.dart' show DeviceBook;
import '../../cancel_final.dart' show CancelResult;
import '../../models.dart' show FinishedPayment, InvoiceEvent, StoreMigrationProgress;
import '../../devices/device_service.dart' show DeviceHost, ForwardedNotice;
import '../../name_service/name_service_service.dart' show NameServiceHost;
import '../../name_service/receipts.dart' show LinkPaymentRecords;
import '../../name_service/name_service.dart' show NameServiceMembership, LinkOutcome, Payreq;
import '../../pairing_api.dart';
import '../../scan/scan_router.dart' show PaymentLink;
import '../../trust/policy.dart' show PeerCompat;

import 'backup_settings_desk.dart' show DeskBackupSettings;
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

  /// Whether wallet [id]'s pending setup came from a restore: a setup resumed after a restart
  /// says "Wallet restored." again, not "New wallet added." (WIN-2).
  Future<bool> setupRestored(String id);
  Future<void> setSetupRestored(String id);

  /// Picks the wallet [unlock] opens next (Unlock's Wallet select). The open one stays open.
  Future<void> selectWallet(String id);

  /// Opens the selected wallet; false on a wrong password. [remember] keeps the password on
  /// this computer for that wallet (`remember.dart`); off forgets one kept before.
  Future<bool> unlock(String password, {bool remember = false});

  /// Opens the selected wallet with the password remembered on this computer; false when
  /// none is kept, it expired, or it no longer opens the wallet (then it is forgotten).
  Future<bool> unlockRemembered();

  /// The copy step of a first unlock after the update that encrypts the wallet's records:
  /// events while [unlock] or [unlockRemembered] copies, none otherwise. Broadcast.
  Stream<StoreMigrationProgress> get storeMigration;

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

  /// A payment link's checks against the open wallet's network, pins and paid requests
  /// ([openLink]): the refusal, or the link opened with its standing.
  Future<LinkOutcome> openPaymentLink(PaymentLink link, {required NameServiceMembership membership, required int nowSeconds});

  /// Records a payment made from a link: the listing pin and the request id.
  Future<void> recordLinkPayment(Payreq request, int paidAt, {String? txId});

  /// The records of payments made from links; [onChange] runs after one changes.
  LinkPaymentRecords linkPaymentRecords({void Function()? onChange});

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

  /// The network wallets are listed, made and restored on (`mainnet`, `floonet`, `usernet`):
  /// mainnet, unless a build with [DeskFeatures.testNetworks] chose another on Welcome.
  String get network;

  /// Welcome › Advanced › Network ([DeskFeatures.testNetworks]): lists, makes and restores
  /// wallets of [network] from now on, with its node and Epicbox defaults, and starts on it
  /// next time. Only while no wallet is open.
  Future<void> useNetwork(String network);

  /// Whether [words] is a recovery phrase: 12, 15, 18, 21 or 24 words of the list whose check
  /// bits match. Answers at once; the restore grid calls it after every change.
  bool checkPhrase(List<String> words);

  /// The listed wallet of this network that [words] is the recovery phrase of, by the
  /// fingerprint the app kept when it made the wallet; null when none, or when [words] is not
  /// a phrase. Wallets made before the app kept fingerprints are never matched. Restore asks
  /// before the password step, so a phrase already here opens that wallet instead.
  Future<WalletEntry?> walletWithPhrase(List<String> words);

  /// Forgot password: [phrase] must be wallet [id]'s own recovery phrase; then its
  /// password becomes [newPassword]. The history, notes and labels stay, and nothing is scanned
  /// again. An open [id] is locked first (the core changes only a closed wallet). Another
  /// wallet's phrase throws a [DeskError] and changes nothing; a remembered password of [id]
  /// is forgotten.
  Future<void> resetPassword(String id, {required List<String> phrase, required String newPassword});

  /// Whether [phrase] is wallet [id]'s, by the fingerprint the list keeps; null when the list
  /// has none for it (the core decides at [resetPassword]). Forgot password asks before the
  /// password step.
  Future<bool?> phraseIsOf(String id, List<String> phrase);

  /// Restores a wallet from [phrase]. A phrase [walletWithPhrase] knows throws a [DeskError]
  /// with [DeskError.sameWallet] set and makes nothing.
  Future<void> restoreWallet({String name = '', required String password, required List<String> phrase, BigInt? startHeight});

  // Import. Old folders are only read.
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

  /// Whether the wallet [id] this run imported keeps the older app's Epicbox server
  /// ([ImportedWallet.oldRelay]) as its own, which keeps its address; it does from the import
  /// on. Keep puts the server in the Epicbox list; false goes back to the app's server (a new
  /// address) and takes the server out of the list again when the import put it there. The
  /// app's own server and list defaults never change.
  Future<void> keepOldRelay(String id, {required bool keep});

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
  /// The running HTTP listener's local address, `http://127.0.0.1:<port>`, Local only and
  /// From the internet alike (0.0.0.0 answers on this computer too); empty while it is off.
  /// The public address is [httpReach]'s [HttpReach.publicAddress], never the LAN address.
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

  /// An Epicbox address of the other chain (a floonet address in a mainnet wallet, or back):
  /// the scan router's WrongNetwork. Needs `@server`.
  bool epicboxAddressOtherChain(String to);

  // Acting.
  Future<int> estimateFee(int amount);

  /// The largest amount that can be sent now, with its fee and lock figures (Send › All).
  /// Send it with `SendOptions(strategy: SelectionStrategy.all)`.
  Future<SendEstimate> estimateMax();

  /// What a send of [amount] with [options] would spend, pay and get back now (the summary,
  /// SmartOutputs: `planSend` in `smart_outputs.dart`); nothing is locked. Null
  /// [options] is the wallet's default. A split the coins cannot build throws a [DeskError]
  /// with [DeskError.unbuildable].
  Future<SendEstimate> estimateSend(int amount, {SendOptions? options});

  /// The open wallet's Outputs choices: default strategy and SmartOutputs.
  Future<OutputPrefs> outputPrefs();

  /// Keeps the open wallet's Outputs choices; Send uses them from its next estimate.
  Future<void> saveOutputPrefs(OutputPrefs prefs);

  /// The open wallet's minimum confirmations: blocks a received or change output waits before
  /// it counts as spendable (1–30, default [defaultMinimumConfirmations]); the core keeps it
  /// per wallet.
  Future<int> minimumConfirmations();

  /// Stores [count] (1–30) as the open wallet's minimum confirmations. The balance, outputs and
  /// transactions are counted again at once and [changes] fires; out of range throws a
  /// [DeskError].
  Future<void> setMinimumConfirmations(int count);

  // Outputs (the Outputs page). A split and a consolidate are normal
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

  /// The finished payment [id] (finalized, not posted: [Tx.notPosted] in Kill switch) as text
  /// to post from a device that is online (a file's or a QR's contents).
  Future<String> finishedPayment(int id);

  /// Reads a finished payment's [text] without posting it. Throws a [DeskError] when it is not one.
  Future<FinishedPayment> inspectFinished(String text);

  /// Posts the finished payment [text] through the node in use; Kill switch refuses it.
  Future<void> postFinished(String text);

  /// Sends the undelivered send [id] again over its method ([Tx.undelivered]): to the same
  /// Epicbox address, URL or onion. Throws a [DeskError] when it fails again.
  Future<void> resendTx(int id);
  Future<SendResult> send(SendRequest request);
  Future<ReceivedFile> receiveFile(String fileName);

  /// Signs a transaction file's [text] pasted into Send (slate JSON or a slatepack), as
  /// [receiveFile] does a file; the answer goes into the app's files folder.
  Future<ReceivedFile> receiveText(String text);
  Future<Tx> finalizeFile(String fileName);

  /// What the transaction file at [path] holds when it is a payment request for this wallet
  /// to pay (DESIGN §3.3), read without touching the wallet; null for any other file, which
  /// [receiveFile] signs as before. Throws as [receiveFile] does when it cannot be read.
  Future<RequestFile?> readRequestFile(String path);

  /// [readRequestFile] for a transaction file's [text] pasted into Send.
  Future<RequestFile?> readRequestText(String text);

  /// Pays the payment request [file] after checking [password] (the only caller is its
  /// Review's Approve) for its own amount, and writes the answer beside the file, or in the
  /// app's files folder. Throws an [InvoiceError] as [payInvoice] does.
  Future<ReceivedFile> payRequestFile(RequestFile file, {required String password});

  /// A transaction file's [text] pasted into Send is an answer to one of this wallet's sends
  /// (the response to finalize), not a send to sign. False when it cannot be read.
  Future<bool> isResponseText(String text);

  /// Finalizes and posts the answer [text] pasted into Send, as [finalizeFile] does a file.
  Future<Tx> finalizeText(String text);
  /// Cancels a payment; one the other side could still finish also has its coins spent back
  /// to this wallet (cancel_final.dart), which the result tells; with [spendBack] false (the
  /// free "Stop waiting") only cancelled.
  Future<CancelResult> cancelTx(int id, {bool spendBack = true});
  Future<String> exportProof(int id);
  /// Adds (empty id) or replaces [contact] and returns its id. Only stores: an address is never checked over the network.
  Future<String> saveContact(Contact contact);
  Future<void> deleteContact(String id);
  Future<void> saveSettings(DeskSettings settings);
  Future<void> useNode(String url);

  /// Moves the open wallet onto [url] for this session only (node failover,
  /// `desk_failover.dart`): the chosen node stays saved and the next unlock opens on it.
  /// Locked: nothing happens. Payments and scans under way end first, as for [useNode].
  Future<void> useNodeForSession(String url);

  /// Turns the built-in node on (starts it and moves the wallet to it) or off (moves the wallet
  /// back to the node used before, then stops it).
  Future<void> useBuiltInNode(bool on);

  /// The built-in node's address changed (its ports were set and it restarted): the wallet
  /// moves to the new address when it is on the built-in node, else nothing happens.
  Future<void> followBuiltInNode();
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
  Future<void> setHttpListening(bool on);

  /// Turns Tor on or off for the open wallet now, saved per wallet ([DeskSettings.tor]); whether
  /// it starts at unlock is [DeskSettings.torAutostart]. On again after a failure is Retry.
  /// Progress and failures show in [ServiceStatus.tor]. Only when [DeskFeatures.tor].
  Future<void> setTor(bool on);

  /// Epicbox over Tor for the open wallet and the ones opened later, not saved here: while on
  /// and Tor is on, the Epicbox connection goes through Tor and never directly, waiting while
  /// tor starts ([ServiceStatus.epicboxViaTor]). On until set. Applies at once.
  Future<void> setEpicboxOverTor(bool on);

  /// Starts tor for payments again after it failed (Link · Tor's Retry). Tor for payments
  /// itself follows [DeskSettings.payments]' Link · Tor, saved with [saveSettings]: it runs
  /// while that switch is on outside Node only and Kill switch, for the onion listener and
  /// sends to onions only; the Tor switch ([setTor]) still decides every other connection.
  Future<void> retryTorPay();
  /// Refresh (Overview, Activity): brings the balance and history up to date with the node
  /// now and returns when that is done. Throws a [DeskError] when the node did not answer.
  Future<void> syncNow();

  /// Scans the chain again, with progress; the stream ends when the scan does, after the
  /// balance is brought up to date. [deleteUnconfirmed] also cancels unconfirmed
  /// transactions and unlocks their coins.
  /// [startHeight]: from that block (0: the whole chain); null from a little before the last
  /// scan's end, or from block 0 while a restore's scan is owed ([ServiceStatus.restoreScan]).
  Stream<ScanStep> rescan({bool deleteUnconfirmed = false, BigInt? startHeight});

  /// Ends a running [rescan] at the core's next page; its stream then ends without a
  /// finished step.
  Future<void> stopRescan();

  /// Fires when something the screens show changed in the background (a payment arrived, a
  /// sync finished, the listener connected). [DeskController] reloads on it.
  Stream<void> changes();
  Future<List<String>> revealPhrase(String password);
  /// Re-encrypts the open wallet under [next] and forgets its remembered password. A wrong
  /// [current] throws a [DeskError] with `wrongPassword`.
  Future<void> changePassword(String current, String next);

  // History backup and its reminder.
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

  /// Fields where the old wallet's history, brought across after the user had described the
  /// payments, records another sender or method. Empty when nothing waits. The shell shows
  /// "Details differ" for them and answers with [resolveOldHistory].
  List<ImportConflict> get oldHistoryConflicts;

  /// Applies the user's choices for [oldHistoryConflicts] (by [ImportConflict.id]: true takes the
  /// old wallet's value, false keeps the user's), or postpones them when null (Cancel).
  Future<void> resolveOldHistory(Map<String, bool>? useOldWallet);

  /// Names the payment [key] ([Tx.key]), or removes the name when [label] is null or blank.
  /// At most [txLabelMaxLength] characters. Any payment takes a label.
  Future<void> setTxLabel(String key, String? label);

  /// Sets what the user knows of a payment a scan found ([Tx.restored]): who paid
  /// ([counterparty], never verified), how it came ([transport], one of [txTransports]) and a
  /// [note]. Each null or blank value clears that field. Throws a [DeskError] for any other row.
  Future<void> setTxDetails(String key, {String? counterparty, String? transport, String? note});

  /// The open wallet's settings for its history backup, now and as a fresh install has them,
  /// in the backup map's form (`backup_settings_desk.dart`); [exportHistory] seals `mine`.
  Future<DeskBackupSettings> backupSettings();

  /// After a history import: the open wallet's own items from the backup. The seed contacts in
  /// [seedsDeleted] are recorded as deleted, and one still as the app wrote it is deleted again.
  /// (The servers are `settings.toml`'s, written by the glue.)
  Future<void> restoreBackupItems({List<String>? seedsDeleted});

  /// Records an export saved at [when], with what it held.
  Future<void> markHistoryExported(DateTime when);

  /// "Not now" on the reminder, at [when].
  Future<void> dismissHistoryReminder(DateTime when);

  /// "Not now" on the restored wallet's import offer ([HistoryBackupState.importOffer]); an
  /// import that went in answers it too.
  Future<void> dismissHistoryImportOffer();

  // Invoices over Epicbox.
  // Everything shows only when [supportsInvoices].
  bool get supportsInvoices;

  /// A request can be saved as a payment file (the session's `supportsRequestFiles`).
  bool get supportsRequestFiles;

  /// Moves on every wallet session that opens: an unlock, and a node or Epicbox change, which
  /// reopens the wallet. What holds on to the session's parts ([pairing]) follows it.
  int get sessionRevision;

  /// What the wallet learned of invoices by itself (paid, declined, expired, sent back,
  /// withdrawn), for a notice; the open wallet's only.
  Stream<InvoiceNotice> invoiceNotices();

  /// Requests sent and invoices received, as stored.
  Future<InvoiceBook> invoices();

  /// Collects the paired contacts' mailboxes (invoices from contacts the user allows are
  /// parked, others dropped unread) and the payments address (payments for requests are finalized and posted), then
  /// sweeps expired ones. Throws a [DeskError] when the relay could not be reached; the stored
  /// lists stay as they were.
  Future<InvoiceBook> checkInvoices();

  /// Sends the paired contact [PaymentRequestDraft.pairingId] a request through its mailbox.
  /// Nothing leaves the wallet, so no password. A request the relay did not take is cancelled at
  /// once and throws a [DeskError]: nothing was sent.
  Future<IssuedRequest> requestPayment(PaymentRequestDraft draft);

  /// Saves a request for [amount] as a payment file for anyone (DESIGN §3.2): the request
  /// waits in Requests sent, and the answer file comes back through Finalize. Nothing leaves
  /// the wallet, so no password. Only when [supportsRequestFiles].
  Future<RequestFileMade> requestFile({required int amount, String? message});

  /// Withdraws a waiting request; a LEPIC payer is told.
  Future<void> withdrawRequest(String slateId);

  /// Posts a finalized request's payment again (the node refused it or was unreachable).
  Future<void> repostRequest(String slateId);

  /// Cancels the payment of a paid request that was never posted ([RequestState.notPosted]):
  /// the core asks the node first and refuses one in the pool or on chain ([InvoiceError]
  /// onItsWay, or cannotCheck when the node cannot be asked).
  Future<void> cancelRequestPayment(String slateId);

  /// Pays a waiting invoice: checks [password], signs for the invoice's own [amount] and sends
  /// the reply to the contact's mailbox. The only caller is Review's Approve. A reply
  /// that did not reach the relay comes back as [PayState.notDelivered], stored and locked.
  Future<IncomingInvoice> payInvoice(String slateId, {required int amount, required String password});

  /// Sends the stored reply of a [PayState.notDelivered] payment again; signs nothing.
  Future<IncomingInvoice> retryInvoiceReply(String slateId);

  /// Declines a waiting invoice and tells the sender when its wallet can hear it.
  Future<void> declineInvoice(String slateId);

  /// Cancels an invoice's payment once the node says it is neither in the pool nor on the
  /// chain, and spends the coins it had locked back to this wallet, so the service's signed
  /// copy can never complete (a network fee; cancel_final.dart). Throws a [DeskError] when the
  /// network has it, or when the node cannot be asked. With [spendBack] false only cancelled.
  Future<CancelResult> cancelInvoicePayment(String slateId, {bool spendBack = true});

  Future<void> setInvoiceExpiry(Duration expiry);

  /// Pairing (RFC 0002) of the open wallet: [PairingApi.supported] false while locked or on a
  /// core without it. The types are the core's (`models.dart`), shared with the phone.
  PairingApi get pairing;

  /// What the wallet has learned about the software behind [address] (an Epicbox address), or
  /// null when it knows nothing. Feeds the trust policy (`trust/policy.dart`).
  Future<PeerCompat?> peerCompat(String address);

  /// Drops what the wallet learned about Epicbox keys silent for [olderThan]; called on open.
  Future<void> forgetPeers({required Duration olderThan});

  /// What linked devices (`devices/`) need from the open wallet: its pairing engine, outputs,
  /// history and the coins every send leaves out; null while locked. [online] says whether the
  /// channel may reach the servers now.
  DeviceHost? deviceHost({required bool Function() online});

  /// What the name services (`name_service/`) need from the open wallet: its pairing engine, listing
  /// keys and signature check; null while locked. [online] says whether the channel may reach
  /// the servers now.
  NameServiceHost? nameServiceHost({required bool Function() online});

  /// Where the wallet reads the book of linked devices from, or null for none: the history
  /// merges the other devices' payments ([mergeDeviceHistory]) and the balance and the outputs
  /// show the coins they hold as locked. [DeskController.reloadWallet] reads them again.
  void useDevices(DeviceBook? Function()? book);

  /// Where the wallet hands the notices that reached this device only, for the linked device
  /// (a payer's `posted` or `cancelled` report, a contact's request to pay); null for none.
  set noticeForwarder(void Function(InvoiceEvent e)? forward);

  /// A notice the linked device passed on ([DeviceService.forwarded]): the lists are read
  /// again, a request to pay is announced.
  Future<void> applyForwarded(ForwardedNotice notice);
}
