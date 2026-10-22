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

  /// Opens the selected wallet; false on a wrong password.
  Future<bool> unlock(String password);
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
  Future<List<String>> createWallet({required String name, required String password});
  Future<bool> checkPhraseWord(String word);
  Future<void> restoreWallet({required String name, required String password, required List<String> phrase});

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
  Future<String> httpAddress();
  Future<String> torAddress();

  // Acting.
  Future<int> estimateFee(int amount);

  /// The largest amount that can be sent now and its fee (Send › All).
  Future<(int, int)> estimateMax();
  Future<SendResult> send(SendRequest request);
  Future<ReceivedFile> receiveFile(String fileName);
  Future<Tx> finalizeFile(String fileName);
  Future<void> cancelTx(int id);
  Future<String> exportProof(int id);
  Future<void> saveContact(Contact contact);
  Future<void> deleteContact(String id);
  Future<void> saveSettings(DeskSettings settings);
  Future<void> useNode(String url);
  Future<NodeServer> checkNode(String url);
  Future<void> addNode(NodeServer node);
  Future<void> useEpicbox(String domain);

  /// Starts or stops the receive listener (Epicbox, and HTTP when it is on).
  Future<void> setListening(bool on);
  /// Scans the chain again, with progress; the stream ends when the scan does.
  Stream<ScanStep> rescan();

  /// Fires when something the screens show changed in the background (a payment arrived, a
  /// sync finished, the listener connected). [DeskController] reloads on it.
  Stream<void> changes();
  Future<List<String>> revealPhrase(String password);
  /// Only when [DeskFeatures.changePassword].
  Future<void> changePassword(String current, String next);
}
