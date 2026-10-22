/// The one seam between the desktop UI and a wallet. Screens never call this directly: they
/// read [deskProvider] (`state.dart`) and call its actions. Today [MockDeskWallet] answers;
/// a LEPIC adapter over `WalletService` replaces it by overriding [deskApiProvider].
library;

import 'models.dart';

abstract interface class DeskWalletApi {
  // Wallets on this computer and opening one.
  /// The wallets of this network; [WalletEntry.current] is the one [unlock] opens.
  Future<List<WalletEntry>> wallets();

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
  Future<void> lock();

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
  /// Local only, `http://<this computer's LAN address>:<port>` when From the internet (the
  /// router forwards the port to it); empty while it is off. Only when [DeskFeatures.httpDirect].
  Future<String> httpAddress();
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

  /// The largest amount that can be sent now and its fee (Send › All).
  Future<(int, int)> estimateMax();
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
  Future<void> setListening(bool on);

  /// Starts or stops the HTTP listener alone, on [DeskSettings.httpPort], reachable as
  /// [DeskSettings.publicMode] says. A start that fails shows in [ServiceStatus.httpProblem].
  /// Only when [DeskFeatures.httpDirect].
  Future<void> setHttpListening(bool on);

  /// Turns Tor on or off for the open wallet, saved per wallet ([DeskSettings.tor]): on starts
  /// the wallet's tor now and at each unlock; off stops it. On again after a failure is Retry.
  /// Progress and failures show in [ServiceStatus.tor]. Only when [DeskFeatures.tor].
  Future<void> setTor(bool on);
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
  /// Only when [DeskFeatures.changePassword].
  Future<void> changePassword(String current, String next);
}
