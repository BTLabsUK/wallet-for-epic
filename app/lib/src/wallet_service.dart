// SPDX-License-Identifier: Apache-2.0
/// The boundary between the UI and the native wallet core.
///
/// UI code depends on [WalletService] and [WalletSession] only. [LepicWalletService]
/// (`lepic_wallet_service.dart`) runs them on LEPIC; tests use [FakeWalletService].
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'contact_label.dart';
import 'desktop/data/mock_hosts.dart' show fakeWalletOnion;
import 'name_service/base58.dart' show epicboxKeyText, netMainnet;
import 'name_service/pins.dart' show LinkMemory;
import 'name_service/link_payments.dart' show LinkPaymentRecords;
import 'name_service/verify.dart' show refusingVerifier;
import 'name_service/wire.dart' show Payreq;
import 'history/wallet_history.dart';
import 'models.dart';
import 'trust/policy.dart';
import 'finished_payment.dart' show readFinishedPayment;
import 'network_gate.dart' show NetGate;
import 'pairing_api.dart';
import 'pairing_fake.dart';
import 'settings_file/host_settings.dart' show hostSettings, hostSettingsLoaded;

export 'models.dart';
export 'pairing_api.dart';

/// Free functions of the native API plus the two ways to obtain an open wallet.
/// Whether the wallet core takes [WalletConfig.offline] (Kill switch sessions that refuse their
/// node and relay at once, LEPIC's ADR 0031): entering or leaving Kill switch opens the session
/// again. Tests of the app's own gate alone may turn it off.
bool walletOfflineSessions = true;

abstract interface class WalletService {
  bool validateMnemonic({required String phrase});

  /// The wallet's fingerprint for [mnemonic] on [chain]: 8 lowercase hex characters, the same
  /// value [WalletSession.fingerprint] gives for a wallet created, restored or imported
  /// (wallet.seed) with that phrase, so "is this wallet here already" has one answer. A phrase
  /// that is not one throws [WalletError] with [WalletErrorKind.invalidMnemonic].
  String walletFingerprint({required String mnemonic, required Chain chain});

  /// Reads a slate's id, amount, fee and step without touching a wallet. Throws [WalletError]
  /// with [WalletErrorKind.invalidSlate] for anything that is not a slate. LEPIC reads it on
  /// the chain of the last wallet config it saw.
  Future<SlateInfo> inspectSlate({required String json});

  /// The payment text [json] as the QR texts of an animated code: show them in a loop, in
  /// order, all with the same fragment size. [maxFragmentLen] is the bytes one part carries.
  /// Nothing is encrypted. Throws [WalletError] with [WalletErrorKind.invalidSlate] for text
  /// that is not JSON and [WalletErrorKind.qrCodeTooLarge] for a payment past the limits.
  Future<List<String>> encodeQrSlate({
    required String json,
    required int maxFragmentLen,
  });

  /// Reads the distinct texts scanned so far (any order and case; pass all of them each
  /// time). Throws [WalletError] with [WalletErrorKind.notQrSlate] or
  /// [WalletErrorKind.foreignQrCode] when a text is not a payment QR (leave it out and keep the
  /// others), [WalletErrorKind.mixedQrCodes] for parts of two payments (start over with the
  /// newest text), [WalletErrorKind.invalidQrCode] for a damaged code and
  /// [WalletErrorKind.qrCodeTooLarge] for one past the limits.
  Future<QrSlateProgress> decodeQrSlate({required List<String> parts});

  /// True for `<address>@<relay>[:port]` valid on the chain of the open wallet.
  bool validateEpicboxAddress({required String address});

  /// True for `<address>@<relay>[:port]` valid on the other chain (a floonet address while
  /// the wallet is on mainnet, or back): the key's version bytes tell the chains apart.
  bool epicboxAddressOtherChain({required String address});

  /// True for an onion v3 address: 56 characters, with or without `.onion`, an `http://`
  /// prefix, a port or a path, whose version and checksum hold.
  bool validateOnionAddress({required String address});

  /// Whether [der] (DER bytes) is the K3 signature of [message] under [domain] by the Epicbox key
  /// [publicKeyText] (LEPIC's `verifyAddressSignatureAt`). Needs no open wallet; false for
  /// anything malformed. A core with no LEPIC refuses everything.
  Future<bool> verifyListingSignature(
    String publicKeyText,
    String domain,
    Uint8List message,
    Uint8List der,
  );

  /// What the wallet has learned about the software behind [address] (an Epicbox address), or
  /// null when it knows nothing. Feeds the trust policy (lib/src/trust/policy.dart).
  Future<PeerCompat?> peerCompat(String address);

  Future<bool> walletExists({required WalletConfig config});

  /// The tip of the node [config] names with no wallet open: through the app's tor while that
  /// carries the app's requests, directly where the Tor switch is off. Throws [NetBlocked] when
  /// the switch is on and tor does not carry yet (nothing goes directly).
  Future<NodeTip> nodeTip({required WalletConfig config});

  /// Creates a wallet. With [mnemonic] it restores that seed; call [WalletSession.scan] next.
  /// [restoreFromHeight] is where the restore's scan starts (null or 0: block 0): the core
  /// records it, and a scan from there to the tip finishes the restore
  /// ([WalletSession.restoreScanRequired]).
  Future<WalletSession> create({
    required WalletConfig config,
    String? mnemonic,
    required String password,
    BigInt? restoreFromHeight,
  });

  /// Opens an existing wallet. A wrong password throws [WalletError] with
  /// [WalletErrorKind.wrongPassword].
  Future<WalletSession> open({
    required WalletConfig config,
    required String password,
  });

  /// Creates a wallet from the text of an `epic-wallet` `wallet.seed` (at most 4 KiB), which
  /// [seedPassword] decrypts; the new wallet gets [password]. The file is only read. Call
  /// [WalletSession.scan] next. A wrong [seedPassword] throws [WalletError] with
  /// [WalletErrorKind.wrongPassword]; text that is not a `wallet.seed`, or a [password] under
  /// eight characters, [WalletErrorKind.invalidArgument].
  Future<WalletSession> importWalletSeed({
    required WalletConfig config,
    required String seedFile,
    required String seedPassword,
    required String password,
  });

  /// Creates a wallet whose password the core generates and seals under [pin]; Dart only ever
  /// holds the sealed text. Store [PinWallet.sealedPassword] before showing the phrase: without
  /// it the wallet cannot be opened, only deleted and created again. [restoreFromHeight] as
  /// in [create].
  Future<PinWallet> createWithPin({
    required WalletConfig config,
    String? mnemonic,
    required String pin,
    BigInt? restoreFromHeight,
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

  /// The copy step of a first open after the update that encrypts the wallet's records:
  /// events arrive while an open ([open], [openWithPin]) copies the plain database into the
  /// encrypted store, and none otherwise. Broadcast; listen before the open starts.
  Stream<StoreMigrationProgress> get storeMigrationProgress;

  /// Deletes the wallet files in `config.dataDir`. Every session on it must be disposed first.
  /// Only the recovery phrase can bring the wallet back.
  Future<void> deleteWallet({required WalletConfig config});

  /// A forgotten password: [mnemonic] must be this wallet's own recovery phrase (the core
  /// checks it against the wallet's database first, [WalletErrorKind.phraseMismatch] for
  /// another wallet's), then only the encrypted seed is written again under [newPassword]. The
  /// history, notes and labels stay, and nothing is scanned again. The wallet must be closed
  /// ([WalletErrorKind.walletBusy] otherwise); a password under eight characters is
  /// [WalletErrorKind.invalidArgument]; a wallet that never had a database is
  /// [WalletErrorKind.walletNotFound] (delete and restore it instead).
  Future<void> resetPassword({
    required WalletConfig config,
    required String mnemonic,
    required String newPassword,
  });
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

/// An open wallet. Mirrors the methods of the native `EpicWallet`.
///
/// Call [dispose] when done. The core allows one chain per process, so every session must be
/// disposed before a wallet on another chain can be opened.
abstract interface class WalletSession {
  void dispose();

  /// How this session's open found the wallet's records: encrypted, encrypted by this open, or
  /// left plain for now because the copy did not go through ([StoreOpenOutcome]).
  StoreOpenOutcome get storeOpen;

  /// False while the shared address book is closed to this wallet (it has no key to it yet):
  /// [contacts] is then not the book's contents, and saving a contact is refused.
  bool get contactsAvailable;

  /// When the wallet last synced (UTC), read as this session opened it, before its first refresh
  /// replaced the record; null when there is none (a new or restored wallet).
  DateTime? get lastActivityAtOpen;

  Future<String> mnemonic({required String password});

  /// Whether [password] opens this wallet, for an action that asks for it again. The attempt
  /// counts as an unlock's does; the recovery phrase is not read.
  Future<bool> checkPassword({required String password});

  /// Re-encrypts the wallet under [newPassword]; then only it opens the wallet. A wrong
  /// [currentPassword] throws [WalletErrorKind.wrongPassword], counted and delayed like a wrong
  /// unlock; a [newPassword] under eight characters [WalletErrorKind.invalidArgument]. A wallet
  /// from [WalletService.createWithPin] has no password to change: use [changePin].
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// The recovery phrase of a wallet from [WalletService.createWithPin], for the backup screen.
  /// The PIN attempt counts as in [WalletService.openWithPin].
  Future<String> mnemonicWithPin({
    required String pin,
    required String sealedPassword,
  });

  /// Checks [pin] against [sealedPassword] of a wallet from [WalletService.createWithPin],
  /// before an action that asks for it again. The attempt counts as in
  /// [WalletService.openWithPin]; nothing else changes.
  Future<void> checkPin({
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

  /// Drops what the wallet learned about Epicbox keys it has not heard from for [olderThan]
  /// (the rows behind [WalletService.peerCompat]). Called on every open.
  Future<void> forgetPeers({required Duration olderThan});

  /// Posts a finalized send that never reached the chain again ([TxEntry.repostable]). Its
  /// inputs stay locked until it confirms.
  Future<void> repostTransaction({required String key});

  /// The finished payment [txId] (a send finalized here and not posted, [toPostElsewhere]) as
  /// text to post from a device that is online: a file's or a QR's contents.
  /// `invalidArgument` for a transaction that is not one.
  Future<String> finishedPaymentText({required int txId});

  /// Reads a finished payment's [text] (from [finishedPaymentText], of any wallet) without
  /// posting it. `invalidSlate` when it is not one.
  Future<FinishedPayment> inspectFinished(String text);

  /// Posts the finished payment [text] through the node in use: Node only lets it, Kill switch
  /// refuses it (`NetBlocked`).
  Future<void> postFinished(String text);

  /// Delivers the slate of the Epicbox send [key] again, to the address it was sent to
  /// ([TxEntry.undelivered]). `invalidArgument` for a send that is not an Epicbox send waiting
  /// for its answer; `transportFailed` when the relay refuses again.
  Future<void> resendEpicbox({required String key});

  /// Unlocks the funds of a finished payment the network refused and that has not reached it
  /// for a day of blocks ([TxEntry.releasable]). Refuses with [WalletErrorKind.invalidArgument]
  /// when the node shows the payment on chain or in its pool.
  Future<void> releaseStuckSend({required String key});

  /// [message], when set, is signed into the slate for the recipient to see; LEPIC cuts it
  /// to [slateMessageMaxBytes]. [options] choose the inputs and change; without them a send
  /// of the amount [estimateMax] last returned takes every output into one change output,
  /// any other [SendOptions.standard].
  Future<Slate> createSendSlate({
    required BigInt amount,
    required BigInt minimumConfirmations,
    String? message,
    SendOptions? options,
  });

  Future<String> epicboxAddress();

  /// This wallet's fingerprint ([WalletService.walletFingerprint] of its phrase and chain).
  Future<String> fingerprint();

  /// What a send of [amount] with [options] would spend, pay and get back now, with nothing
  /// locked. Pass the [options] the send will get.
  Future<FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
    SendOptions? options,
  });

  Future<TxEntry> finalizeAndPost({required String slateJson});

  /// Posts a send over epicbox. The listener finalizes it when the recipient answers.
  /// [message] and [options] as for [createSendSlate].
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
    SendOptions? options,
  });

  /// Starts the epicbox listener and streams its events. It runs until [stopListener] or
  /// [dispose].
  Stream<ListenerEvent> startListener();

  /// Moves the open wallet to the node and relay of [config], keeping it unlocked. Calls running
  /// when it starts end first; calls made meanwhile wait for it. A running listener moves to a
  /// new relay once the payment in hand is answered (at most 30 s) and its stream goes on. A new
  /// relay changes [epicboxAddress] to `<key>@<new relay>`. [config] must name the wallet's own
  /// data directory and chain: another chain is another wallet. A node URL or relay that is not
  /// one throws [WalletErrorKind.invalidArgument] and keeps the servers in use.
  Future<void> setServers({required WalletConfig config});

  /// The tip of the node [config] names (only its node URL and secret count), asked as the
  /// open wallet asks its own node: over Tor while the wallet's Tor routes node requests, else
  /// directly, and a node on this computer always directly. Use it instead of
  /// [WalletService.nodeTip], which has no wallet's Tor, while a wallet is open. Throws
  /// [WalletErrorKind.nodeUnreachable] when the node does not answer.
  Future<NodeTip> nodeTipFor({required WalletConfig config});

  Future<void> stopListener();

  /// Sends to the wallet listening at [url], `http(s)://host[:port][/path]`, then finalizes
  /// its answer and posts. Plain `http` to another computer needs [allowPlainHttp], set only
  /// after the user agreed to send unencrypted. Throws [WalletErrorKind.httpUrlInvalid] or
  /// [WalletErrorKind.plainHttpNotAllowed], storing nothing; [WalletErrorKind.transportFailed]
  /// when the other wallet did not answer, with the send stored as waiting and its inputs
  /// locked: [resendHttp] or [cancelTransaction] it. [message] and [options] as for
  /// [createSendSlate].
  Future<HttpSent> sendHttp({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String url,
    required bool allowPlainHttp,
    String? message,
    SendOptions? options,
  });

  /// Delivers send [txId] again over HTTP, to [url] (the same or another address), then
  /// finalizes and posts as [sendHttp]. A wallet that answered before answers the same way.
  Future<HttpSent> resendHttp({
    required int txId,
    required String url,
    required bool allowPlainHttp,
  });

  /// Starts the HTTP listener on [port] and streams what it does until [stopHttpListener],
  /// lock or [dispose]. The first event is `started`, `portInUse` or `bindFailed`; after a
  /// start the last is `stopped`. Start it only on the user's choice, and [HttpExposure.internet]
  /// only after they chose it.
  Stream<HttpListenerEvent> startHttpListener({
    required HttpExposure exposure,
    required int port,
  });

  Future<void> stopHttpListener();

  /// This wallet's onion, `<56 characters>.onion`, known before tor runs.
  Future<String> onionAddress();

  /// Signs a device-link [transcript] with the wallet's device-link key (LEPIC's
  /// `device_link_sign`, under its own tag, a key of the phrase made for nothing else) and
  /// returns the 64-byte signature in hex. Every device holding this wallet's phrase makes a
  /// signature the other takes, which is how linked devices prove they hold one wallet.
  Future<String> signDeviceLink(List<int> transcript);

  /// Whether [signature] is [signDeviceLink] of [transcript] by a wallet of this wallet's
  /// phrase. False for anything malformed.
  Future<bool> verifyDeviceLink({required List<int> transcript, required String signature});

  /// Notices over Epicbox for a slate this wallet holds nothing of (a payer's posted or
  /// cancelled, an invoice declined or withdrawn): another device on this phrase may hold it,
  /// so they go to the linked device as they are. Nothing verified them: never shown or acted
  /// on here.
  Stream<UnmatchedNotice> unmatchedNotices();

  /// Applies a notice the linked device passed on ([unmatchedNotices] there) under the rules of
  /// one received here: only from its slate's counterparty, once. Raises the same events.
  /// Whether it was taken; one for a slate this wallet does not hold either is dropped.
  Future<bool> applyForwardedNotice({required String sender, required String notice});

  /// Starts the wallet's own tor from [torBinary] (the bundled Tor Expert Bundle) and streams
  /// what it does until [stopTor], lock or [dispose]; [libDir] goes on the library path
  /// (Linux), null elsewhere. The events go `starting`, `bootstrapped`, `publishing`,
  /// `ready`; the last is `stopped`. A second start gets a stream that ends at once.
  Stream<TorEvent> startTor({required String torBinary, String? libDir});

  /// Stops tor, then its listener; [startTor]'s stream ends with `stopped`.
  Future<void> stopTor();

  /// Epicbox over Tor: while on and the wallet's tor runs or starts, the relay connection goes
  /// through tor and never directly; a listener connection that would now go another way is
  /// replaced once what is in flight on it is acknowledged. On when the wallet opens.
  Future<void> setEpicboxOverTor(bool on);

  /// [startTor] follows: until it does, relay connections wait for tor instead of going
  /// directly. Call it before [startListener] when tor is about to start with the wallet, and
  /// before [stopTor] when restarting tor, so that stop keeps the connection waiting. A
  /// [stopTor] without it, or lock, lets the connection go direct again.
  Future<void> expectTor();

  /// Whether Epicbox over Tor is on ([setEpicboxOverTor]).
  Future<bool> epicboxOverTor();

  /// Node requests and HTTP sends through the wallet's tor while it runs ([on], as the wallet
  /// opens) or directly ([on] false): Tor for payments only, where tor runs for the onion
  /// (receiving there, sends to onions) and the rest keeps the user's network choice. Sends
  /// to onions always go through tor.
  Future<void> setNodeAndHttpOverTor(bool on);

  /// The TLS hosts reached at an onion through tor, replacing LEPIC's built-in list from the
  /// next connection. Throws `invalidArgument`, changing nothing, for an invalid entry.
  Future<void> setOnionRoutes(List<TorOnionRoute> routes);

  Future<TorStatus> torStatus();

  /// Wakes a running tor after the app was paused, and after a network change
  /// ([networkChanged]) drops its connections and builds new ones; the onion stays the same.
  /// Throws [WalletErrorKind.torNotRunning] when no tor runs or tor no longer answers (its
  /// stream then ends with `failed` and `stopped`).
  Future<void> refreshTor({required bool networkChanged});

  /// The device lost its network: a running tor turns its network off until the next
  /// [refreshTor], so it makes no attempt that would fail meanwhile and count the relays it
  /// enters the Tor network through as unreachable (android-04). Does nothing when no tor
  /// runs or while it starts.
  Future<void> torNetworkLost();

  /// Sends to the wallet at [onion] over Tor, then finalizes its answer and posts, as
  /// [sendHttp]. Needs tor connected, else [WalletErrorKind.torNotRunning] and nothing is
  /// stored. Reaching an onion that is not online takes up to about 150 seconds, and is tried
  /// once more after `[tor] onion_retry_s`, before [WalletErrorKind.onionUnreachable]; that, `torNotRunning`
  /// after the start and
  /// `transportFailed` leave the send stored as waiting: [resendTor] or cancel it.
  Future<HttpSent> sendTor({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String onion,
    String? message,
    SendOptions? options,
  });

  /// Delivers send [txId] again over Tor, to [onion], then finalizes and posts.
  Future<HttpSent> resendTor({required int txId, required String onion});

  /// Signs an incoming send. The same slate again returns the answer given the first time with
  /// [ReceivedSlate.repeated] set; nothing is stored or signed again.
  Future<ReceivedSlate> receiveSlate({required String slateJson});

  /// Scans the chain from [startHeight] (the wallet's birth when null). With
  /// [deleteUnconfirmed], a scan that completes also cancels unconfirmed transactions,
  /// deleting their outputs, and unlocks locked outputs found on chain. A stopped scan resumes
  /// when started again with the same start and flag.
  Stream<ScanProgress> scan({BigInt? startHeight, bool deleteUnconfirmed = false});

  /// Stops a running [scan] at its next page; its stream then ends without a `finished`
  /// event. Pages stored so far stay. Nothing happens when no scan runs.
  void cancelScan();

  /// Whether the wallet was rebuilt from its phrase and the scan from the restore's start has
  /// not finished ([WalletErrorKind.restoreScanRequired]). The start is the height the restore
  /// recorded ([WalletService.create]'s restoreFromHeight), block 0 for a rebuilt database or a
  /// restore by an older version. While true, [scan] with no start height scans from that
  /// start, resuming a stopped one; a scan from the start or earlier that reaches the tip
  /// clears it, one from a later height leaves it.
  Future<bool> restoreScanRequired();

  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  });

  /// The confirmations a received or change output needs before the wallet counts it as
  /// spendable and may spend it: this wallet's stored setting (the core keeps it per wallet,
  /// 1–30, default [defaultMinimumConfirmations]). [WalletSummary.minimumConfirmations]
  /// reports the same number.
  Future<int> minimumConfirmations();

  /// Stores [count] (1–30) as this wallet's minimum confirmations and re-splits the balance
  /// at once; the next summary reports it. Out of range throws a [WalletError] with
  /// [WalletErrorKind.invalidArgument].
  Future<void> setMinimumConfirmations(int count);

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

  /// Sets the label of the transaction with [TxEntry.key], at most [txLabelMaxLength]
  /// characters; null or blank removes it. Any transaction may have one.
  Future<void> setTxLabel({required String key, String? label});

  /// Sets what the user knows of a transaction a scan restored ([TxSource.restored]): who paid
  /// ([counterparty], an address), how ([transport]: `epicbox`, `http`, `tor` or `file`) and a
  /// [note]. Each null or blank clears that field. Refused with
  /// [WalletErrorKind.invalidArgument] for any other row. Never reaches LEPIC.
  Future<void> setTxDetails({
    required String key,
    String? counterparty,
    String? transport,
    String? note,
  });

  /// Address book, sorted by name.
  Future<List<Contact>> contacts();

  /// Adds a contact (empty `id`) or replaces the one with that id. Returns it as stored.
  Future<Contact> saveContact({required Contact contact});

  Future<void> deleteContact({required String id});

  /// Ids of the contacts this wallet starred. The address book is shared; the star is this
  /// wallet's, kept in its own archive.
  Future<List<String>> favouriteContacts();

  /// Stars ([favourite] true) or unstars the contact [id] in this wallet.
  Future<void> setFavouriteContact({required String id, required bool favourite});

  /// The chain of the open wallet.
  Chain get chain;

  /// What this wallet remembered of payments made from payment links: listing pins and paid
  /// request ids. Deleting the history deletes them.
  LinkMemory linkMemory();

  /// Records that the user paid [request] from its link at [paidAt] (unix seconds).
  Future<void> recordLinkPayment(Payreq request, int paidAt, {String? txId});

  /// The records of payments made from links ([recordLinkPayment]); [onChange] runs after one
  /// changes.
  LinkPaymentRecords linkPaymentRecords({void Function()? onChange});

  /// Encrypted history file that only a wallet with the same recovery phrase can import. It
  /// carries what the phrase and a scan cannot give back; the app adds the wallet's
  /// [walletName] where it names wallets, and its [settings] (`backup_settings.dart`).
  Future<Uint8List> exportHistory({String? walletName, Map<String, Object?>? settings});

  /// The transaction list as CSV. Not encrypted, not importable.
  Future<String> exportHistoryCsv();

  /// Merges a file from [exportHistory]. A second import of the same file changes nothing. A
  /// file from another wallet throws [WalletError] with [WalletErrorKind.invalidArgument].
  ///
  /// Per field, what the user entered here wins; the file fills only empty fields. Where the
  /// file has another value ([ImportReport.conflicts]) and [useBackup] is null, nothing is
  /// written and the report has `applied: false`. Called again with [useBackup], by
  /// [ImportConflict.id]: true takes the file's value, false or missing keeps the user's, and
  /// a kept value is remembered so the same file never asks again.
  Future<ImportReport> importHistory({
    required Uint8List data,
    Map<String, bool>? useBackup,
  });

  /// Brings across the transaction history of the epic-wallet wallet (GUI or CLI) in
  /// [sourceDir], the folder holding `wallet_data`, that this wallet was made from. Nothing in
  /// [sourceDir] is written. A history that cannot be imported is a status, not an error.
  ///
  /// Where the old wallet records another sender or method than the user typed for a payment
  /// ([LegacyHistoryImport.conflicts]) and [useOldWallet] is null, the report has `applied:
  /// false` and the typed values stay as they are. Called again with [useOldWallet] (by
  /// [ImportConflict.id]: true takes the old wallet's value, false or missing keeps the user's,
  /// remembered so the same value never asks again).
  Future<LegacyHistoryImport> importLegacyHistory({
    required String sourceDir,
    Map<String, bool>? useOldWallet,
  });

  /// Largest amount that can be sent now, with its fee.
  Future<FeeEstimate> estimateMax({required BigInt minimumConfirmations});

  /// Coins another linked device is spending (`devices/`, LEPIC `SendOptions.exclude_outputs`):
  /// every send, estimate and Send all of this session leaves these commitments out until the
  /// set changes. Empty by default.
  Set<String> get heldOutputs;
  set heldOutputs(Set<String> commitments);

  /// Where the node's chain holds the kernel with excess [excessHex] (66 hex characters),
  /// looked up from [minHeight] (the core keeps it between one and the tip) to the tip; null
  /// when the chain does not hold it. Read only: for the payments a linked device makes with
  /// this wallet's coins (`devices/`). Throws when the node cannot be asked (offline, Kill
  /// switch, a core without the call): the answer is unknown, not "absent".
  Future<KernelLocation?> kernelOnChain(String excessHex, {int? minHeight});

  // Outputs. A split and a consolidate are normal network transactions to the wallet
  // itself, never through its Epicbox address; each spends every output with
  // [minimumConfirmations], so the whole balance is locked until it confirms.

  /// Every output of the wallet, spent ones included, ordered by commitment, from the
  /// wallet's database alone; refresh [summary] first for the node's view.
  Future<List<WalletOutput>> outputs();

  /// The fee and inputs of [splitOutputs] into [outputs] outputs now, with nothing locked.
  Future<FeeEstimate> estimateSplit({
    required int outputs,
    required BigInt minimumConfirmations,
  });

  /// Splits the wallet's funds into [outputs] outputs of nearly equal value,
  /// [minSplitOutputs] to [maxSplitOutputs]. [WalletErrorKind.invalidArgument] for a count
  /// outside that, [WalletErrorKind.notEnoughFunds] when the outputs cannot pay the fee.
  Future<SelfSentTx> splitOutputs({
    required int outputs,
    required BigInt minimumConfirmations,
  });

  /// The fee and inputs of [consolidateOutputs] now, with nothing locked.
  Future<FeeEstimate> estimateConsolidate({required BigInt minimumConfirmations});

  /// Merges every output with [minimumConfirmations] (up to 500) into one.
  Future<SelfSentTx> consolidateOutputs({required BigInt minimumConfirmations});

  /// Spends exactly the outputs [commitments] names (`WalletOutput.commitment`) into [outputs]
  /// outputs of this wallet (1 to 10, the amount less the fee in nearly equal parts), locking
  /// nothing else. It makes a cancelled payment final: the other wallet may hold a signed copy
  /// that spends them until they are spent here. [WalletErrorKind.invalidArgument] for an empty
  /// list, an output that is unknown, not spendable or named twice, or a count outside 1–10;
  /// [WalletErrorKind.notEnoughFunds] when the fee takes it all.
  Future<SelfSentTx> spendOutputsToSelf({
    required List<String> commitments,
    required BigInt minimumConfirmations,
    int outputs = 1,
  });

  // Invoices over epicbox. Since RFC 0002 an invoice comes only from a paired contact the user
  // allows ([PairingRecord.allowInvoices], verified), sealed and signed in that contact's
  // mailbox; each one waits for the user. Every call below throws [invoicesUnsupported] when
  // this is false.

  /// True when this core handles invoices over epicbox.
  bool get supportsInvoices;

  /// True when this core handles payment requests as files, both ways: it issues one for
  /// anyone ([PairingApi.requestFile]), pays one ([payRequestFile]) and finishes the answer
  /// with [finalizeAndPost]. The screens hide "Save as file" and refuse request files when
  /// this is false.
  bool get supportsRequestFiles;

  /// Pays the payment request (I1) in [slateJson] and returns the answer (I2) to hand back to
  /// whoever asked, who finishes and posts it. The file is untrusted: call it only after the
  /// user approved [amount] behind the PIN or biometric gate. [amount] must equal the amount
  /// the request asks ([WalletErrorKind.amountMismatch] otherwise); the fee comes on top.
  /// [WalletErrorKind.invalidSlate] for text that is not a request,
  /// [WalletErrorKind.invoiceAlreadyPaid] for one this wallet paid before,
  /// [WalletErrorKind.paymentExpired] once its time ran out, and
  /// [WalletErrorKind.invoiceLockedAboveTip], [WalletErrorKind.notEnoughFunds] and
  /// [WalletErrorKind.nodeUnreachable]; nothing is stored then. Throws
  /// [invoicesUnsupported] when [supportsRequestFiles] is false.
  Future<PaidRequestFile> payRequestFile({required String slateJson, required BigInt amount});

  /// Pairing (RFC 0002): [PairingApi.supported] says whether this core pairs.
  PairingApi get pairing;

  /// Collects what waits in the paired contacts' mailboxes (an open collect) and expires
  /// what ran out: invoices from contacts the user allows are parked, notices applied,
  /// everything else dropped unread.
  Future<InvoiceCollectReport> collectInvoices();

  /// Parked invoices not yet answered or expired, oldest first.
  Future<List<PendingInvoice>> pendingInvoices();

  /// Pays a pending invoice and sends the reply to the contact's mailbox.
  /// [amount] must equal the invoiced amount ([WalletErrorKind.amountMismatch] otherwise).
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

  /// Invoices parked, receipts and withdrawals applied, expiries, as collects and answers find
  /// them. Informational: no event pays or cancels anything.
  Stream<InvoiceEvent> invoiceEvents();

  // Issued invoices (I-05): the user asked someone to pay them, a paired contact through
  // [PairingApi.requestPayment] or anyone with a file ([PairingApi.requestFile]). The payment
  // comes back to [epicboxAddress], where the listener or [drainPayments] finalizes and posts
  // it. Nothing here spends from this wallet, so no call needs the PIN. Every call throws
  // [invoicesUnsupported] when [supportsInvoices] is false.

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

  /// What happened to issued invoices, as collects, drains, the listener and sweeps find it.
  Stream<IssuerEvent> issuerEvents();
}

/// A session that can read this wallet's address on a relay other than its own: after the
/// user moved the wallet to another relay, payments sent to the old address wait there
/// (`levels/relay_switch.dart`). Optional, so the fakes need nothing: [DrainEpicboxAt.drainEpicboxAt] answers null for a session without it.
abstract interface class EpicboxDrainAt {
  /// Reads the messages stored for this wallet's address on [domain]:[port] once, answering
  /// each through that relay (signs payments to it, finalizes and posts its own sends' answers),
  /// as [WalletSession.drainPayments] does on the relay in use. Null when the core cannot.
  Future<PaymentsDrainReport?> drainEpicboxAt({required String domain, required int port});
}

extension DrainEpicboxAt on WalletSession {
  /// [EpicboxDrainAt.drainEpicboxAt], or null (unsupported) for a session without it.
  Future<PaymentsDrainReport?> drainEpicboxAt({required String domain, required int port}) async {
    // A pattern, not `is`: EpicboxDrainAt is no WalletSession, so `is` does not promote and the
    // call came back here (26.11.0 froze the UI thread until a StackOverflowError).
    if (this case final EpicboxDrainAt core) return core.drainEpicboxAt(domain: domain, port: port);
    return null;
  }
}

/// A session that holds the wallet's listing keys: one Epicbox address per (name service key,
/// generation), derived from the phrase alone, signing under the listing domains and drained
/// like the wallet's own address. Optional, so a core without them answers null through
/// [ListingKeysOf.listingKeys].
abstract interface class ListingKeys {
  /// The listing address (`<key>@<domain>[:port]`) of [serviceKeyHex] (33 bytes, hex) at [generation],
  /// on the wallet's home Epicbox server.
  Future<String> listingAddress(String serviceKeyHex, int generation);

  /// The DER signature of [message] under [domain] by that listing key.
  Future<Uint8List> signWithListing(String serviceKeyHex, int generation, String domain, Uint8List message);

  /// Reads what is stored for that listing address once, answering as the own address does.
  Future<PaymentsDrainReport> drainListing(String serviceKeyHex, int generation);
}

extension ListingKeysOf on WalletSession {
  /// The listing keys of this session, or null for one without them.
  ListingKeys? get listingKeys {
    // A pattern, not `is`, as in [DrainEpicboxAt].
    if (this case final ListingKeys keys) return keys;
    return null;
  }
}

/// Listing keys of made-up keys, for the fakes: a real key text (so it parses) on the home
/// server, and a hash for a signature.
class FakeListingKeys implements ListingKeys {
  /// The listings drained: (serviceKey hex, generation) in call order.
  final List<(String, int)> drains = [];

  @override
  Future<String> listingAddress(String serviceKeyHex, int generation) async {
    final key = sha256.convert(utf8.encode('listing $serviceKeyHex $generation')).bytes;
    final host = hostSettingsLoaded ? hostSettings.epicboxUse : 'relay.example.invalid';
    return '${epicboxKeyText([2, ...key], netMainnet)}@$host';
  }

  @override
  Future<Uint8List> signWithListing(String serviceKeyHex, int generation, String domain, Uint8List message) async =>
      Uint8List.fromList(sha256.convert([...utf8.encode('$serviceKeyHex $generation $domain '), ...message]).bytes);

  @override
  Future<PaymentsDrainReport> drainListing(String serviceKeyHex, int generation) async {
    drains.add((serviceKeyHex, generation));
    return const PaymentsDrainReport();
  }
}

/// The error of an invoice call on a core without them.
WalletError invoicesUnsupported(String call) => WalletError(
  kind: WalletErrorKind.other,
  message: '$call needs LEPIC with invoices over epicbox (UP-14)',
);

/// What the fakes accept as an epicbox address, as LEPIC requires it: key `@` relay.
bool fakeEpicboxAddress(String address) =>
    RegExp(r'^[1-9A-HJ-NP-Za-km-z]{52}@[a-z0-9.]+(:\d+)?$').hasMatch(address);

/// The syntax of an onion v3 address, as LEPIC reads it: optional `http://`, 56 base32
/// characters ending in the version `d`, optional `.onion`, port and path. The checksum is
/// LEPIC's to check.
bool onionAddressFormat(String address) => RegExp(
  r'^(?:http://)?[a-z2-7]{55}d(?:\.onion)?(?::\d+)?(?:/.*)?$',
  caseSensitive: false,
).hasMatch(address.trim());

/// The host part of an onion address, `<56 characters>.onion`, in lower case.
String onionHost(String address) {
  final m = RegExp(r'[a-z2-7]{56}', caseSensitive: false).firstMatch(address);
  return m == null ? address.trim() : '${m[0]!.toLowerCase()}.onion';
}

/// The fakes' [WalletService.walletFingerprint]: 8 hex characters of an FNV-1a hash of the
/// chain and the phrase (the core's own value is derived from the seed).
String fakeWalletFingerprint(String mnemonic, Chain chain) {
  var h = 0x811c9dc5;
  for (final b in utf8.encode('${chain.name} $mnemonic')) {
    h = ((h ^ b) * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
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
       session = session ?? FakeWalletSession() {
    this.session.node ??= this;
  }

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

  /// When set, [deleteWallet] throws it and deletes nothing.
  WalletError? deleteError;

  /// Data directories whose wallet files are there but whose vault the secret store no longer
  /// holds (keychain entries removed): [open] fails as LEPIC's does, and [resetPassword] seals a
  /// new vault from the phrase.
  final Set<String> lostVaults = {};

  @override
  bool validateMnemonic({required String phrase}) => phrase == this.phrase;

  @override
  String walletFingerprint({required String mnemonic, required Chain chain}) {
    if (!validateMnemonic(phrase: mnemonic)) {
      throw const WalletError(kind: WalletErrorKind.invalidMnemonic, message: 'not a phrase');
    }
    return fakeWalletFingerprint(mnemonic, chain);
  }

  /// Slates [inspectSlate] recognises, by JSON text.
  final Map<String, SlateInfo> slateInfos = {};

  /// When set, [inspectSlate] waits for it, so tests see the file screen while it reads.
  Completer<void>? inspectGate;

  /// What [peerCompat] returns, by address.
  final Map<String, PeerCompat> peerCompats = {};

  @override
  Future<PeerCompat?> peerCompat(String address) async => peerCompats[address];

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

  /// The fake's QR text of a payment: `UR:EPIC-SLATE/<part>-<count>/<digest>/<hex>`. Parts
  /// past `count` repeat the plain ones, like the extra parts of the real code.
  @override
  Future<List<String>> encodeQrSlate({
    required String json,
    required int maxFragmentLen,
  }) async {
    if (json.trim().isEmpty || !json.trimLeft().startsWith('{')) {
      throw const WalletError(
        kind: WalletErrorKind.invalidSlate,
        message: 'not a slate',
      );
    }
    final bytes = utf8.encode(json);
    final count = (bytes.length / maxFragmentLen).ceil();
    final digest = bytes.fold<int>(7, (h, b) => (h * 31 + b) & 0xffffffff);
    final tag = digest.toRadixString(16).padLeft(8, '0');
    String part(int index) {
      final from = (index % count) * maxFragmentLen;
      final chunk = bytes.sublist(
        from,
        from + maxFragmentLen > bytes.length ? bytes.length : from + maxFragmentLen,
      );
      final hex = chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      return 'UR:EPIC-SLATE/${index + 1}-$count/$tag/$hex'.toUpperCase();
    }

    return [for (var i = 0; i < count + (count > 1 ? 2 : 0); i++) part(i)];
  }

  @override
  Future<QrSlateProgress> decodeQrSlate({required List<String> parts}) async {
    final byIndex = <int, List<int>>{};
    int? count;
    String? tag;
    for (final raw in parts) {
      final text = raw.trim().toUpperCase();
      final m = RegExp(
        r'^UR:EPIC-SLATE/(\d+)-(\d+)/([0-9A-F]{8})/([0-9A-F]*)$',
      ).firstMatch(text);
      if (m == null) {
        throw WalletError(
          kind: text.startsWith('UR:')
              ? WalletErrorKind.foreignQrCode
              : WalletErrorKind.notQrSlate,
          message: 'not a payment QR',
        );
      }
      if (count != null && (count != int.parse(m[2]!) || tag != m[3])) {
        throw const WalletError(
          kind: WalletErrorKind.mixedQrCodes,
          message: 'two payments',
        );
      }
      count = int.parse(m[2]!);
      tag = m[3];
      final hex = m[4]!;
      byIndex[(int.parse(m[1]!) - 1) % count] = [
        for (var i = 0; i < hex.length; i += 2)
          int.parse(hex.substring(i, i + 2), radix: 16),
      ];
    }
    if (count == null) {
      return const QrSlateProgress(complete: false, received: 0, count: 0);
    }
    final complete = byIndex.length == count;
    return QrSlateProgress(
      complete: complete,
      received: byIndex.length,
      count: count,
      json: complete
          ? utf8.decode([for (var i = 0; i < count; i++) ...byIndex[i]!])
          : null,
    );
  }

  @override
  bool validateEpicboxAddress({required String address}) =>
      fakeEpicboxAddress(address);

  @override
  bool epicboxAddressOtherChain({required String address}) => false;

  @override
  Future<bool> verifyListingSignature(
    String publicKeyText,
    String domain,
    Uint8List message,
    Uint8List der,
  ) => refusingVerifier(publicKeyText, domain, message, der);

  @override
  bool validateOnionAddress({required String address}) =>
      onionAddressFormat(address);

  @override
  Future<bool> walletExists({required WalletConfig config}) async =>
      existingWallets.contains(config.dataDir);

  @override
  Future<NodeTip> nodeTip({required WalletConfig config}) async {
    nodeTipCalls++;
    final fail = nodeTipFails;
    if (fail != null) throw fail;
    return nodeAnswer(config);
  }

  /// What the fake node answers, asked directly ([nodeTip]) or through an open wallet
  /// ([WalletSession.nodeTipFor]). Tests override it to delay or fail the node.
  Future<NodeTip> nodeAnswer(WalletConfig config) async => nodeTipValue;

  /// How often [nodeTip] was asked: the direct call, outside any wallet's Tor.
  int nodeTipCalls = 0;

  /// When set, [nodeTip] throws it: for tests where a direct node request is a leak.
  Object? nodeTipFails;

  /// What [nodeTip] answers. Tests and the web preview set it.
  NodeTip nodeTipValue = NodeTip(height: BigInt.from(2500000), nodeVersion: '3.6.0');

  @override
  Future<WalletSession> create({
    required WalletConfig config,
    String? mnemonic,
    required String password,
    BigInt? restoreFromHeight,
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
    _restored(mnemonic, restoreFromHeight);
    phraseOf[config.dataDir] = mnemonic ?? phrase;
    openWallets.add(config.dataDir);
    session.openedConfig = config;
    return session..owner = this;
  }

  /// The restoreFromHeight of the last [create] or [createWithPin] (null: none, or block 0).
  BigInt? createdRestoreFrom;

  /// A restore leaves the core's flag set at its start, as LEPIC does; a new wallet has none.
  void _restored(String? mnemonic, BigInt? from) {
    createdRestoreFrom = from;
    if (mnemonic == null) return;
    session
      ..restoreScanPending = true
      ..restoreFrom = from ?? BigInt.zero;
  }

  /// The recovery phrase of each wallet [create] made, by data directory; [phrase] otherwise.
  final Map<String, String> phraseOf = {};

  /// Data directories with an undisposed session, as the core counts them for
  /// [resetPassword] and [deleteWallet].
  final Set<String> openWallets = {};

  /// The data directories [resetPassword] changed the password of.
  final List<String> passwordResets = [];

  @override
  Future<void> resetPassword({
    required WalletConfig config,
    required String mnemonic,
    required String newPassword,
  }) async {
    if (!existingWallets.contains(config.dataDir)) {
      throw const WalletError(kind: WalletErrorKind.walletNotFound, message: 'no wallet');
    }
    if (openWallets.contains(config.dataDir)) {
      throw const WalletError(kind: WalletErrorKind.walletBusy, message: 'the wallet is open');
    }
    if (newPassword.runes.length < 8) {
      throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'password too short');
    }
    if (!validateMnemonic(phrase: mnemonic)) {
      throw const WalletError(kind: WalletErrorKind.invalidMnemonic, message: 'not a phrase');
    }
    if ((phraseOf[config.dataDir] ?? phrase) != mnemonic) {
      throw const WalletError(kind: WalletErrorKind.phraseMismatch, message: 'phrase of another wallet');
    }
    password = newPassword;
    lostVaults.remove(config.dataDir);
    passwordResets.add(config.dataDir);
  }

  /// The seed text and its password [importWalletSeed] was given last.
  String? importedSeedFile;
  String? importedSeedPassword;

  /// The only seed password [importWalletSeed] accepts; any other is wrong.
  String seedFilePassword = 'old password';

  /// The phrase behind the seed file [importWalletSeed] takes; null: one of the seed file's own.
  String? seedFilePhrase;

  @override
  Future<WalletSession> importWalletSeed({
    required WalletConfig config,
    required String seedFile,
    required String seedPassword,
    required String password,
  }) async {
    if (existingWallets.contains(config.dataDir)) {
      throw const WalletError(
        kind: WalletErrorKind.walletAlreadyExists,
        message: 'wallet exists',
      );
    }
    if (seedPassword != seedFilePassword) {
      throw const WalletError(
        kind: WalletErrorKind.wrongPassword,
        message: 'wrong password',
      );
    }
    existingWallets.add(config.dataDir);
    this.password = password;
    createdConfig = config;
    importedSeedFile = seedFile;
    importedSeedPassword = seedPassword;
    // Each seed file its own wallet unless a test names its phrase.
    phraseOf[config.dataDir] = seedFilePhrase ?? 'seed file $seedFile';
    session.openedConfig = config;
    return session..owner = this;
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
    if (lostVaults.contains(config.dataDir)) {
      throw const WalletError(kind: WalletErrorKind.walletNotFound, message: "the app's store holds no vault");
    }
    if (password != this.password) {
      throw const WalletError(
        kind: WalletErrorKind.wrongPassword,
        message: 'wrong password',
      );
    }
    await _openStore();
    openWallets.add(config.dataDir);
    session.openedConfig = config;
    return session..owner = this;
  }

  @override
  Future<void> deleteWallet({required WalletConfig config}) async {
    if (deleteError case final error?) throw error;
    existingWallets.remove(config.dataDir);
    phraseOf.remove(config.dataDir);
    deletedWallets.add(config.dataDir);
    pinFailureCount = 0;
  }

  /// Wrong PINs since the last right one, as LEPIC counts them. The fake never waits.
  int pinFailureCount = 0;

  /// When set, reading [pinFailureCount] throws it, as a Keystore that does not answer now.
  Object? pinFailuresError;

  /// When set, the next [openWithPin] throws it before the PIN is checked, as a Keystore that
  /// does not release the PIN key.
  Object? nextOpenError;

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
    BigInt? restoreFromHeight,
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
    _restored(mnemonic, restoreFromHeight);
    createdPin = pin;
    pinFailureCount = 0;
    session.owner = this;
    session.openedConfig = config;
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
    if (nextOpenError case final error?) {
      nextOpenError = null;
      throw error;
    }
    _checkPin(pin, sealedPassword);
    await _openStore();
    if (damageOnNextOpen) {
      // The core sets the damaged database aside; the next open rebuilds it with the flag set.
      damageOnNextOpen = false;
      session
        ..restoreScanPending = true
        ..restoreFrom = BigInt.zero;
      throw const WalletError(kind: WalletErrorKind.damagedDatabase, message: 'database damaged');
    }
    session.owner = this;
    session.openedConfig = config;
    return session;
  }

  /// When set, the next [openWithPin] reports a damaged database once, as the core does
  /// before it rebuilds one.
  bool damageOnNextOpen = false;

  /// How the next opens find the records ([WalletSession.storeOpen]).
  StoreOpenOutcome storeOutcome = StoreOpenOutcome.encrypted;

  /// Copy-step events each open emits on [storeMigrationProgress] before it returns, as a
  /// first open after the update does. Empty: an open with nothing to copy.
  List<StoreMigrationProgress> migrationSteps = const [];

  /// When set, an open that emits [migrationSteps] waits for it after the first one, so a test
  /// sees the copy step on screen.
  Completer<void>? migrationGate;

  /// When set, opens refuse with [WalletErrorKind.wrongKey], as the core does when the key
  /// check beside the encrypted store does not match. Nothing changes.
  bool wrongKey = false;

  final StreamController<StoreMigrationProgress> _migration = StreamController<StoreMigrationProgress>.broadcast();

  @override
  Stream<StoreMigrationProgress> get storeMigrationProgress => _migration.stream;

  /// The store step of every open: the key check, then the copy events.
  Future<void> _openStore() async {
    if (wrongKey) {
      throw const WalletError(kind: WalletErrorKind.wrongKey, message: 'the store key check does not match');
    }
    for (final (i, step) in migrationSteps.indexed) {
      _migration.add(step);
      if (i == 0) await migrationGate?.future;
    }
    session.storeOpenValue = storeOutcome;
  }

  @override
  Future<int> pinFailures({required WalletConfig config}) async {
    if (pinFailuresError case final error?) throw error;
    return pinFailureCount;
  }
}

/// The sealed text [FakeWalletService] hands out for [pin]. Not encryption.
String fakeSealedPassword(String pin) => 'fake-sealed|$pin';

/// The fakes' stand-in for the device-link signature of [message] by the wallet with payments key
/// [key], 64 bytes in hex as LEPIC's: deterministic, and another key never makes it.
String fakeAddressSignature(String key, List<int> message) =>
    '${sha512.convert([...utf8.encode('fake-address-signature/$key/'), ...message])}';

/// Scripted open wallet for tests. Mutate the public fields to shape each scenario.
class FakeWalletSession implements WalletSession, ListingKeys {
  FakeWalletSession({
    WalletSummary? summary,
    List<TxEntry>? transactions,
    WalletHistory? invoiceHistory,
  }) : summaryValue = summary ?? emptySummary,
       transactionsValue = transactions ?? <TxEntry>[],
       invoiceHistory = invoiceHistory ?? WalletHistory.memory();

  static final WalletSummary emptySummary = WalletSummary(
    lastConfirmedHeight: BigInt.zero,
    minimumConfirmations: BigInt.from(defaultMinimumConfirmations),
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

  /// The pairing engine's fake, both sides in memory (`pairing_fake.dart`).
  @override
  late final FakePairing pairing = FakePairing(this);
  /// On the settings' Epicbox server in use (the test settings' in tests).
  late String address = 'esFakeAddress1234567890@${hostSettingsLoaded ? hostSettings.epicboxUse : 'relay.example.invalid'}';
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

  /// Every [forgetPeers] call's age limit.
  final List<Duration> forgetPeersCalls = [];

  @override
  Future<void> forgetPeers({required Duration olderThan}) async => forgetPeersCalls.add(olderThan);

  /// Thrown by [cancelTransaction] after it records the id, while set: LEPIC refusing a payment
  /// the network has (`invalidArgument`), or a node it cannot reach.
  WalletError? cancelError;
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
  void dispose() {
    disposeCalls++;
    owner?.openWallets.remove(openedConfig?.dataDir);
  }

  /// What [storeOpen] answers; [FakeWalletService] sets it at each open.
  StoreOpenOutcome storeOpenValue = StoreOpenOutcome.encrypted;

  @override
  StoreOpenOutcome get storeOpen => storeOpenValue;

  /// What [contactsAvailable] answers: false shows the address book closed.
  bool contactsAvailableValue = true;

  @override
  bool get contactsAvailable => contactsAvailableValue;

  /// What [lastActivityAtOpen] answers.
  DateTime? lastActivityAtOpenValue;

  @override
  DateTime? get lastActivityAtOpen => lastActivityAtOpenValue;

  @override
  Future<String> mnemonic({required String password}) async => phrase;

  /// Any password, as [mnemonic] takes any.
  @override
  Future<bool> checkPassword({required String password}) async => true;

  /// The [changePassword] calls, in order.
  final List<({String current, String next})> passwordChanges = [];

  /// Checks [currentPassword] against the owner's [FakeWalletService.password] when there is
  /// an owner, and sets the new one there.
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 8) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'password has fewer than 8 characters',
      );
    }
    final o = owner;
    if (o != null && o.password != currentPassword) {
      throw const WalletError(
        kind: WalletErrorKind.wrongPassword,
        message: 'wrong password',
      );
    }
    passwordChanges.add((current: currentPassword, next: newPassword));
    o?.password = newPassword;
  }

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
  Future<void> checkPin({
    required String pin,
    required String sealedPassword,
  }) async => _owner._checkPin(pin, sealedPassword);

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
    if (cancelError case final error?) throw error;
    // A receive its sender cancelled ends here as in LEPIC, keeping the sender's report.
    final r = transactionsValue.indexWhere((t) => t.id == txId && senderCancelPending(t));
    if (r >= 0) {
      final tx = transactionsValue[r];
      transactionsValue[r] = fakeTx(
        id: tx.id,
        slateId: tx.slateId,
        kind: TxKind.receivedCancelled,
        status: TxStatus.cancelled,
        createdAtUnix: tx.createdAtUnix,
        amountCredited: tx.amountCredited,
        counterparty: tx.counterparty,
        transport: tx.transport,
        senderReportedCancelledAtUnix: tx.senderReportedCancelledAtUnix,
      );
      return;
    }
    // A payment a failed send left behind: cancelling it frees its coins, as in LEPIC.
    final i = transactionsValue.indexWhere(
      (t) => t.id == txId && _undelivered.contains(txId),
    );
    if (i < 0) return;
    final tx = transactionsValue[i];
    _undelivered.remove(txId);
    transactionsValue[i] = fakeTx(
      id: tx.id,
      slateId: tx.slateId,
      kind: TxKind.sentCancelled,
      status: TxStatus.cancelled,
      createdAtUnix: tx.createdAtUnix,
      amountDebited: tx.amountDebited,
      fee: tx.fee,
      numInputs: tx.numInputs,
      counterparty: tx.counterparty,
      messages: tx.messages,
    );
    _lock(-tx.amountDebited);
  }

  /// Ids of sends that failed with [WalletErrorKind.transportFailed]: stored, inputs locked.
  final Set<int> _undelivered = {};

  /// Moves [amount] from spendable to locked (back, when negative).
  void _lock(BigInt amount) {
    final s = summaryValue;
    summaryValue = WalletSummary(
      lastConfirmedHeight: s.lastConfirmedHeight,
      minimumConfirmations: s.minimumConfirmations,
      total: s.total,
      spendable: s.spendable - amount,
      awaitingConfirmation: s.awaitingConfirmation,
      awaitingFinalization: s.awaitingFinalization,
      immature: s.immature,
      locked: s.locked + amount,
      validatedWithNode: s.validatedWithNode,
    );
  }

  /// Keys passed to [repostTransaction].
  final List<String> repostedKeys = [];

  /// Texts passed to [postFinished].
  final List<String> postedFinished = [];

  /// A finished payment's text as LEPIC writes it (a final slate), for [txId].
  static String fakeFinishedText(int txId) => jsonEncode({
    'id': 'fake-finished-$txId',
    'amount': '1000000000',
    'fee': '8000000',
    'tx': {
      'offset': '00',
      'body': {
        'inputs': <Object>[],
        'outputs': <Object>[],
        'kernels': [
          {'features': 'Plain', 'fee': '8000000', 'lock_height': '0', 'excess': '08ab', 'excess_sig': 'cd01'},
        ],
      },
    },
  });

  @override
  Future<String> finishedPaymentText({required int txId}) async => fakeFinishedText(txId);

  @override
  Future<FinishedPayment> inspectFinished(String text) async => readFinishedPayment(text).payment;

  @override
  Future<void> postFinished(String text) async {
    NetGate.checkNode('post finished');
    readFinishedPayment(text);
    postedFinished.add(text);
  }

  /// When set, [repostTransaction] throws it.
  WalletError? repostError;

  /// The next this many [repostTransaction] calls fail with `transportFailed`.
  int repostFailures = 0;

  @override
  Future<void> repostTransaction({required String key}) async {
    if (repostError != null) throw repostError!;
    if (repostFailures > 0) {
      repostFailures--;
      throw const WalletError(
        kind: WalletErrorKind.transportFailed,
        message: 'node refused',
      );
    }
    final tx = transactionsValue.where((t) => t.key == key).firstOrNull;
    // As LEPIC: a finalized one the node refused, or a posted one not in a block yet.
    final posted =
        tx != null &&
        tx.kernelExcess != null &&
        tx.status == TxStatus.awaitingConfirmation &&
        tx.blockHeight == null;
    if (tx == null || !(tx.repostable || posted)) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message:
            'only a finalized send that is not confirmed can be posted again',
      );
    }
    repostedKeys.add(key);
  }

  /// Keys passed to [resendEpicbox].
  final List<String> resentEpicboxKeys = [];

  /// When set, [resendEpicbox] throws it.
  WalletError? resendEpicboxError;

  @override
  Future<void> resendEpicbox({required String key}) async {
    if (resendEpicboxError != null) throw resendEpicboxError!;
    final tx = transactionsValue.where((t) => t.key == key).firstOrNull;
    if (tx == null || !(tx.undelivered || _undelivered.contains(tx.id))) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'not an epicbox send waiting for its answer',
      );
    }
    resentEpicboxKeys.add(key);
    _delivered(tx);
  }

  void _delivered(TxEntry tx) {
    _undelivered.remove(tx.id);
    transactionsValue
      ..remove(tx)
      ..add(copyTx(tx, note: tx.note, undelivered: false));
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
    SendOptions? options,
  }) async {
    _checkFunds(amount);
    sentAmounts.add(amount);
    sentMessages.add(message);
    sentOptions.add(options);
    return sendSlate;
  }

  @override
  Future<String> epicboxAddress() async => address;

  /// [fingerprint]'s answer; null: [fakeWalletFingerprint] of the phrase its service made it with.
  String? fingerprintValue;

  @override
  Future<String> fingerprint() async {
    final dir = openedConfig?.dataDir;
    return fingerprintValue ??
        fakeWalletFingerprint(
          owner?.phraseOf[dir] ?? owner?.phrase ?? '',
          openedConfig?.chain ?? Chain.mainnet,
        );
  }

  @override
  Future<FeeEstimate> estimateFee({
    required BigInt amount,
    required BigInt minimumConfirmations,
    SendOptions? options,
  }) async {
    estimateOptions.add(options);
    if (outputsValue.isNotEmpty) {
      return _select(amount, options ?? SendOptions.standard);
    }
    _checkFunds(amount);
    return FeeEstimate(amount: amount, fee: fee);
  }

  @override
  Future<TxEntry> finalizeAndPost({required String slateJson}) async {
    // The answer to a request, as LEPIC dispatches an I2: finished when this wallet issued it.
    if (node?.slateInfos[slateJson] case SlateInfo(stage: SlateStage.requestAnswer, :final slateId)) {
      return _finishRequest(slateId);
    }
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

  TxEntry _pendingSend(
    BigInt amount, {
    String? to,
    String? message,
    bool repostable = false,
  }) => fakeTx(
    id: 100 + epicboxSends.length + httpSends.length + torSends.length,
    slateId: 'send-${epicboxSends.length + httpSends.length + torSends.length}',
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
    repostable: repostable,
  );

  @override
  Future<TxEntry> sendEpicbox({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String address,
    String? message,
    SendOptions? options,
  }) async {
    final error = sendError;
    if (error != null && error.kind != WalletErrorKind.transportFailed) {
      throw error;
    }
    _checkFunds(amount);
    epicboxSends.add((amount: amount, to: address));
    sentMessages.add(message);
    sentOptions.add(options);
    final tx = _pendingSend(amount, to: address, message: message);
    if (error != null) {
      // Like LEPIC: the payment is built and stored with its inputs locked before the relay
      // refuses it, so the error leaves a waiting payment behind.
      transactionsValue.add(tx);
      _undelivered.add(tx.id!);
      _lock(amount + fee);
      throw error;
    }
    return tx;
  }

  @override
  Stream<ListenerEvent> startListener() {
    listenerStarts++;
    routeLog.add('listener');
    return listenerEvents.stream;
  }

  /// The calls that decide how the Epicbox connection goes, in order: `listener`,
  /// `expectTor`, `startTor`, `stopTor`, `epicboxOverTor:<on>`.
  final List<String> routeLog = [];

  @override
  Future<void> stopListener() async => listenerStops++;

  /// Every [nodeTipFor] call, in order.
  final List<WalletConfig> nodeTipsFor = [];

  /// The fake node [nodeTipFor] asks ([FakeWalletService.nodeAnswer]): the first service made
  /// with this session.
  FakeWalletService? node;

  /// Called at each [nodeTipFor], before it answers.
  void Function()? onNodeTipFor;

  @override
  Future<NodeTip> nodeTipFor({required WalletConfig config}) async {
    nodeTipsFor.add(config);
    onNodeTipFor?.call();
    final o = node;
    if (o != null) return o.nodeAnswer(config);
    return NodeTip(height: BigInt.from(2500000), nodeVersion: '3.6.0');
  }

  /// Every [setServers] call, in order.
  final List<WalletConfig> serverSwitches = [];

  /// The config the wallet was opened with, set by [FakeWalletService]; [setServers] refuses
  /// another directory or chain, as LEPIC does.
  WalletConfig? openedConfig;

  /// When set, [setServers] waits for it before switching, as a switch waits for calls running.
  Completer<void>? serverSwitchGate;

  @override
  Future<void> setServers({required WalletConfig config}) async {
    final opened = openedConfig;
    if (opened != null &&
        (opened.dataDir != config.dataDir || opened.chain != config.chain)) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'servers are switched for the open wallet only',
      );
    }
    final uri = Uri.tryParse(config.nodeUrl);
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        config.epicboxDomain.isEmpty ||
        config.epicboxDomain.contains(RegExp(r'[\s/@:]'))) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'not a node url or a relay',
      );
    }
    await serverSwitchGate?.future;
    serverSwitches.add(config);
    openedConfig = config;
    final port = config.epicboxPort == 443 ? '' : ':${config.epicboxPort}';
    address = '${address.split('@').first}@${config.epicboxDomain}$port';
  }

  /// Every [sendHttp] and [resendHttp] call that passed the URL checks.
  final List<({BigInt? amount, int? txId, String url, bool allowPlainHttp})>
  httpSends = [];

  /// When false, a send that reached the other wallet comes back unposted.
  bool httpPosted = true;

  /// When true, a [sendError] of any kind comes after the send is stored and its inputs locked
  /// (a failure at delivery or finalize), not only `transportFailed`.
  bool storeBeforeError = false;

  /// Events the HTTP listener emits; tests add to them. [stopHttpListener] adds `stopped`.
  final StreamController<HttpListenerEvent> httpListenerEvents =
      StreamController<HttpListenerEvent>.broadcast();
  final List<({HttpExposure exposure, int port})> httpListenerStarts = [];
  int httpListenerStops = 0;

  /// LEPIC's URL rule: `http(s)://host[:port][/path]`, no `.onion`, and plain `http` only to
  /// this computer unless [allowPlainHttp].
  void _checkHttpUrl(String url, bool allowPlainHttp) {
    final uri = Uri.tryParse(url.trim());
    final scheme = uri?.scheme.toLowerCase();
    if (uri == null ||
        (scheme != 'http' && scheme != 'https') ||
        uri.host.isEmpty ||
        uri.host.toLowerCase().endsWith('.onion')) {
      throw const WalletError(
        kind: WalletErrorKind.httpUrlInvalid,
        message: 'not an http(s) address',
      );
    }
    final local = {'localhost', '127.0.0.1', '::1'}.contains(uri.host);
    if (scheme == 'http' && !local && !allowPlainHttp) {
      throw const WalletError(
        kind: WalletErrorKind.plainHttpNotAllowed,
        message: 'plain http to another computer',
      );
    }
  }

  @override
  Future<HttpSent> sendHttp({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String url,
    required bool allowPlainHttp,
    String? message,
    SendOptions? options,
  }) async {
    _checkHttpUrl(url, allowPlainHttp);
    sentOptions.add(options);
    final error = sendError;
    if (error != null &&
        error.kind != WalletErrorKind.transportFailed &&
        !storeBeforeError) {
      throw error;
    }
    _checkFunds(amount);
    httpSends.add((
      amount: amount,
      txId: null,
      url: url,
      allowPlainHttp: allowPlainHttp,
    ));
    sentMessages.add(message);
    final pending = _pendingSend(
      amount,
      to: url,
      message: message,
      repostable: !httpPosted,
    );
    transactionsValue.add(pending);
    _lock(amount + fee);
    if (error != null) {
      _undelivered.add(pending.id!);
      throw error;
    }
    return HttpSent(
      txId: pending.id!,
      slateId: pending.slateId!,
      posted: httpPosted,
    );
  }

  @override
  Future<HttpSent> resendHttp({
    required int txId,
    required String url,
    required bool allowPlainHttp,
  }) async {
    _checkHttpUrl(url, allowPlainHttp);
    final tx = transactionsValue.where((t) => t.id == txId).firstOrNull;
    if (tx == null || !(tx.undelivered || _undelivered.contains(txId))) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'not a send waiting for its answer',
      );
    }
    httpSends.add((
      amount: null,
      txId: txId,
      url: url,
      allowPlainHttp: allowPlainHttp,
    ));
    final error = sendError;
    if (error != null) throw error;
    _delivered(tx);
    return HttpSent(txId: txId, slateId: tx.slateId!, posted: httpPosted);
  }

  @override
  Stream<HttpListenerEvent> startHttpListener({
    required HttpExposure exposure,
    required int port,
  }) {
    httpListenerStarts.add((exposure: exposure, port: port));
    return httpListenerEvents.stream;
  }

  @override
  Future<void> stopHttpListener() async {
    httpListenerStops++;
    httpListenerEvents.add(
      const HttpListenerEvent(kind: HttpListenerEventKind.stopped),
    );
  }

  /// What [onionAddress] answers.
  String onion = fakeWalletOnion;

  /// Events tor emits; tests add to them. [stopTor] adds `stopped`.
  final StreamController<TorEvent> torEvents =
      StreamController<TorEvent>.broadcast();
  final List<({String torBinary, String? libDir})> torStarts = [];
  int torStops = 0;

  /// What [torStatus] answers; tests set it. [stopTor] sets it off.
  TorStatus torStatusValue = TorStatus.off;

  /// Every [sendTor] and [resendTor] call that passed the address check.
  final List<({BigInt? amount, int? txId, String onion})> torSends = [];

  /// Holds [sendTor] until completed, as a send that takes a while over Tor.
  Completer<void>? torSendGate;

  /// A deterministic stand-in for the device-link signature: a hash of the payments key of
  /// [address] and the transcript, so only a session with the same address makes it.
  @override
  Future<String> signDeviceLink(List<int> transcript) async => fakeAddressSignature(epicboxKey(address), transcript);

  @override
  Future<bool> verifyDeviceLink({required List<int> transcript, required String signature}) async =>
      signature == fakeAddressSignature(epicboxKey(address), transcript);

  /// The listing keys of the fake: a test reads [FakeListingKeys.drains].
  final FakeListingKeys fakeListing = FakeListingKeys();

  @override
  Future<String> listingAddress(String serviceKeyHex, int generation) => fakeListing.listingAddress(serviceKeyHex, generation);

  @override
  Future<Uint8List> signWithListing(String serviceKeyHex, int generation, String domain, Uint8List message) =>
      fakeListing.signWithListing(serviceKeyHex, generation, domain, message);

  @override
  Future<PaymentsDrainReport> drainListing(String serviceKeyHex, int generation) => fakeListing.drainListing(serviceKeyHex, generation);

  /// What [unmatchedNotices] streams; a test adds to it as LEPIC's event would.
  final StreamController<UnmatchedNotice> unmatchedController = StreamController<UnmatchedNotice>.broadcast();

  /// The notices [applyForwardedNotice] was given, in order.
  final List<({String sender, String notice})> forwardedNotices = [];

  /// What [applyForwardedNotice] answers.
  bool forwardedNoticeTaken = true;

  @override
  Stream<UnmatchedNotice> unmatchedNotices() => unmatchedController.stream;

  @override
  Future<bool> applyForwardedNotice({required String sender, required String notice}) async {
    forwardedNotices.add((sender: sender, notice: notice));
    return forwardedNoticeTaken;
  }

  @override
  Future<String> onionAddress() async => onion;

  @override
  Stream<TorEvent> startTor({required String torBinary, String? libDir}) {
    torStarts.add((torBinary: torBinary, libDir: libDir));
    routeLog.add('startTor');
    return torEvents.stream;
  }

  /// Holds [stopTor] until completed, as LEPIC taking a while to stop tor.
  Completer<void>? torStopGate;

  @override
  Future<void> stopTor() async {
    routeLog.add('stopTor');
    await torStopGate?.future;
    torStops++;
    torStatusValue = TorStatus.off;
    torEvents.add(const TorEvent(kind: TorEventKind.stopped));
  }

  @override
  Future<TorStatus> torStatus() async => torStatusValue;

  /// The last [setEpicboxOverTor], or null before any.
  bool? epicboxOverTorValue;

  @override
  Future<void> setEpicboxOverTor(bool on) async {
    epicboxOverTorValue = on;
    routeLog.add('epicboxOverTor:$on');
  }

  @override
  Future<void> expectTor() async => routeLog.add('expectTor');

  @override
  Future<bool> epicboxOverTor() async => epicboxOverTorValue ?? true;

  /// The last [setNodeAndHttpOverTor], or null before any.
  bool? nodeAndHttpOverTorValue;

  @override
  Future<void> setNodeAndHttpOverTor(bool on) async {
    nodeAndHttpOverTorValue = on;
    routeLog.add('nodeAndHttpOverTor:$on');
  }

  /// The last [setOnionRoutes], or null before any.
  List<TorOnionRoute>? onionRoutes;

  @override
  Future<void> setOnionRoutes(List<TorOnionRoute> routes) async {
    onionRoutes = routes;
    routeLog.add('onionRoutes:${routes.length}');
  }

  /// Every [refreshTor] call, by `networkChanged`.
  final List<bool> torRefreshes = [];

  /// Holds [refreshTor] until completed; it then answers by [torStatusValue] as it is then.
  Completer<void>? torRefreshGate;

  /// How many times [torNetworkLost] was called.
  int torNetworkLosses = 0;

  @override
  Future<void> torNetworkLost() async => torNetworkLosses++;

  @override
  Future<void> refreshTor({required bool networkChanged}) async {
    torRefreshes.add(networkChanged);
    await torRefreshGate?.future;
    if (torStatusValue.kind == TorStatusKind.off) {
      throw const WalletError(
        kind: WalletErrorKind.torNotRunning,
        message: 'tor is not running',
      );
    }
  }

  void _checkOnion(String onion) {
    if (!onionAddressFormat(onion)) {
      throw const WalletError(
        kind: WalletErrorKind.onionAddressInvalid,
        message: 'not an onion address',
      );
    }
  }

  bool get _torUp => const {
    TorStatusKind.bootstrapped,
    TorStatusKind.publishing,
    TorStatusKind.ready,
  }.contains(torStatusValue.kind);

  @override
  Future<HttpSent> sendTor({
    required BigInt amount,
    required BigInt minimumConfirmations,
    required String onion,
    String? message,
    SendOptions? options,
  }) async {
    _checkOnion(onion);
    if (!_torUp) {
      throw const WalletError(
        kind: WalletErrorKind.torNotRunning,
        message: 'tor is not running',
      );
    }
    final error = sendError;
    // Like LEPIC: only a failure at delivery leaves the send stored.
    const stores = {
      WalletErrorKind.onionUnreachable,
      WalletErrorKind.transportFailed,
      WalletErrorKind.torNotRunning,
    };
    if (error != null && !stores.contains(error.kind) && !storeBeforeError) {
      throw error;
    }
    _checkFunds(amount);
    torSends.add((amount: amount, txId: null, onion: onion));
    sentMessages.add(message);
    final pending = _pendingSend(
      amount,
      to: 'http://${onionHost(onion)}',
      message: message,
      repostable: !httpPosted,
    );
    transactionsValue.add(pending);
    _lock(amount + fee);
    torEvents.add(const TorEvent(kind: TorEventKind.sending));
    await torSendGate?.future;
    if (error != null) {
      _undelivered.add(pending.id!);
      throw error;
    }
    return HttpSent(
      txId: pending.id!,
      slateId: pending.slateId!,
      posted: httpPosted,
    );
  }

  @override
  Future<HttpSent> resendTor({required int txId, required String onion}) async {
    _checkOnion(onion);
    final tx = transactionsValue.where((t) => t.id == txId).firstOrNull;
    if (tx == null || !(tx.undelivered || _undelivered.contains(txId))) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'not a send waiting for its answer',
      );
    }
    torSends.add((amount: null, txId: txId, onion: onion));
    final error = sendError;
    if (error != null) throw error;
    _delivered(tx);
    return HttpSent(txId: txId, slateId: tx.slateId!, posted: httpPosted);
  }

  /// When set, [scan] answers this stream instead of [scanEvents].
  Stream<ScanProgress>? scanStream;

  /// How often [cancelScan] was called.
  int scanCancels = 0;

  /// [scan]'s last deleteUnconfirmed.
  bool? scanDeleteUnconfirmed;

  @override
  Stream<ScanProgress> scan({BigInt? startHeight, bool deleteUnconfirmed = false}) {
    scanCalls++;
    scanStarts.add(startHeight);
    scanDeleteUnconfirmed = deleteUnconfirmed;
    return scanStream ?? _scripted(startHeight);
  }

  Stream<ScanProgress> _scripted(BigInt? startHeight) async* {
    // No start height: the restore's own start while it is due, as the core does.
    final from = startHeight ?? BigInt.zero;
    for (final event in scanEvents) {
      if (event.finished && from <= restoreFrom && !event.message.startsWith('Scan failed:')) {
        restoreScanPending = false;
      }
      yield event;
    }
  }

  @override
  void cancelScan() => scanCancels++;

  /// [restoreScanRequired]'s answer. A scan of [scanEvents] that finishes clears it, as the
  /// core does, when it starts at [restoreFrom] or earlier (no start height: at [restoreFrom]).
  bool restoreScanPending = false;

  /// The height the restore recorded ([FakeWalletService.create]'s restoreFromHeight); 0 for
  /// a rebuilt database or an older restore.
  BigInt restoreFrom = BigInt.zero;

  /// The start height of every [scan] call, in order.
  final List<BigInt?> scanStarts = [];

  @override
  Future<bool> restoreScanRequired() async => restoreScanPending;

  @override
  Future<WalletSummary> summary({
    required bool refresh,
    required BigInt minimumConfirmations,
  }) async => summaryValue;

  /// What [setMinimumConfirmations] stored, or the default.
  int minimumConfirmationsValue = defaultMinimumConfirmations;

  /// Every count [setMinimumConfirmations] was asked to store, in order.
  final List<int> minimumConfirmationsSets = [];

  /// When set, [setMinimumConfirmations] throws it and stores nothing.
  Object? setMinimumConfirmationsError;

  /// The count [summaryValue] reports, as LEPIC answers from its stored setting.
  @override
  Future<int> minimumConfirmations() async => summaryValue.minimumConfirmations.toInt();

  @override
  Future<void> setMinimumConfirmations(int count) async {
    minimumConfirmationsSets.add(count);
    final error = setMinimumConfirmationsError;
    if (error != null) throw error;
    if (count < minMinimumConfirmations || count > maxMinimumConfirmations) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'minimum confirmations must be 1–30',
      );
    }
    minimumConfirmationsValue = count;
    summaryValue = summaryValue.copyWith(minimumConfirmations: BigInt.from(count));
  }

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

  /// Labels by transaction key, as [setTxLabel] stores them.
  final Map<String, String> labels = {};

  /// What [setTxDetails] stored, by transaction key.
  final Map<String, ({String? counterparty, String? transport, String? note})>
  details = {};

  /// The conflicts the next [importHistory] without `useBackup` reports (then stops).
  List<ImportConflict> importConflicts = const [];

  /// The `useBackup` of the last [importHistory] call.
  Map<String, bool>? lastUseBackup;

  TxEntry _withNote(TxEntry tx) {
    final note = notes[tx.key];
    final label = labels[tx.key];
    final d = details[tx.key];
    if (note == null && label == null && d == null) return tx;
    final manual = {
      if (label != null) ManualField.label,
      if (d?.counterparty != null) ManualField.counterparty,
      if (d?.transport != null) ManualField.transport,
      if (d?.note != null) ManualField.note,
    };
    return copyTx(
      tx,
      note: d?.note ?? note ?? tx.note,
      label: label,
      counterparty: tx.counterparty ?? d?.counterparty,
      transport: tx.transport ?? d?.transport,
      manualFields: manual,
      manualEditedAtUnix: manual.isEmpty ? null : 1790000000,
    );
  }

  @override
  Future<void> setTxLabel({required String key, String? label}) async {
    final text = label?.trim() ?? '';
    if (text.isEmpty) {
      labels.remove(key);
    } else {
      labels[key] = text.length > txLabelMaxLength
          ? text.substring(0, txLabelMaxLength)
          : text;
    }
  }

  @override
  Future<void> setTxDetails({
    required String key,
    String? counterparty,
    String? transport,
    String? note,
  }) async {
    final row = transactionsValue.where((t) => t.key == key).firstOrNull;
    if (row == null || row.source != TxSource.restored) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'only a restored transaction takes details',
      );
    }
    String? some(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    final d = (
      counterparty: some(counterparty),
      transport: some(transport),
      note: some(note),
    );
    if (d.counterparty == null && d.transport == null && d.note == null) {
      details.remove(key);
    } else {
      details[key] = d;
    }
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
  Future<List<Contact>> contacts() async => !contactsAvailableValue
      ? <Contact>[]
      : ([...contactsValue]
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));

  @override
  Future<Contact> saveContact({required Contact contact}) async {
    if (!contactsAvailableValue) {
      throw const WalletError(kind: WalletErrorKind.io, message: 'the address book is closed');
    }
    // As the wallet's book: a name is required, an address not (a contact a pairing pays).
    if (contact.name.trim().isEmpty) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'the contact needs a name',
      );
    }
    final stored = Contact(
      id: contact.id.isEmpty ? 'contact-${++_contactSeq}' : contact.id,
      name: contact.name.trim(),
      epicbox: contact.epicbox?.trim(),
      http: contact.http?.trim(),
      tor: contact.tor?.trim(),
      note: (contact.note?.trim().isEmpty ?? true)
          ? null
          : contact.note!.trim(),
      label: contact.label,
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
  Future<void> deleteContact({required String id}) async {
    contactsValue.removeWhere((c) => c.id == id);
    favourites.remove(id);
  }

  /// Starred contact ids, as [setFavouriteContact] stores them.
  final Set<String> favourites = {};

  @override
  Future<List<String>> favouriteContacts() async => [...favourites];

  @override
  Future<void> setFavouriteContact({required String id, required bool favourite}) async {
    favourite ? favourites.add(id) : favourites.remove(id);
  }

  @override
  Chain get chain => openedConfig?.chain ?? Chain.mainnet;

  @override
  LinkMemory linkMemory() => invoiceHistory.linkMemory();

  @override
  Future<void> recordLinkPayment(Payreq request, int paidAt, {String? txId}) =>
      invoiceHistory.recordLinkPayment(request, paidAt, txId: txId);

  @override
  LinkPaymentRecords linkPaymentRecords({void Function()? onChange}) => invoiceHistory.linkPaymentRecords(onChange: onChange);

  static const _exportMagic = 'FAKE-WFEH';

  /// A readable stand-in for the encrypted file: notes and contacts as JSON.
  @override
  Future<Uint8List> exportHistory({String? walletName, Map<String, Object?>? settings}) async => Uint8List.fromList(
    utf8.encode(
      '$_exportMagic${jsonEncode({
        'notes': notes,
        'walletName': ?walletName,
        'settings': ?settings,
        'pairings': pairing.exportBackup(),
        'contacts': [
          for (final c in contactsValue)
            {'id': c.id, 'name': c.name, 'epicbox': c.epicbox, 'http': c.http, 'tor': c.tor, 'note': c.note, 'label': ?c.label.stored},
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

  /// The folders [importLegacyHistory] was given, and what it answers.
  final List<String> legacyImports = [];
  LegacyHistoryImport legacyImport = const LegacyHistoryImport(
    status: LegacyHistoryStatus.noHistory,
  );

  @override
  Future<LegacyHistoryImport> importLegacyHistory({
    required String sourceDir,
    Map<String, bool>? useOldWallet,
  }) async {
    legacyImports.add(sourceDir);
    lastUseOldWallet = useOldWallet;
    final waiting = legacyImport.conflicts;
    if (useOldWallet == null && waiting.isNotEmpty) {
      return LegacyHistoryImport(
        status: legacyImport.status,
        transactions: legacyImport.transactions,
        conflicts: waiting,
        applied: false,
      );
    }
    return LegacyHistoryImport(
      status: legacyImport.status,
      transactions: legacyImport.transactions,
      linked: legacyImport.linked,
      skipped: legacyImport.skipped,
      replaced: useOldWallet?.values.where((v) => v).length ?? 0,
    );
  }

  /// Whether a history import treats the file's pairings as used on another device (RFC 9.5).
  bool importPairingsFromOtherDevice = true;

  /// The `useOldWallet` of the last [importLegacyHistory] call.
  Map<String, bool>? lastUseOldWallet;

  @override
  Future<ImportReport> importHistory({
    required Uint8List data,
    Map<String, bool>? useBackup,
  }) async {
    if (importError != null) throw importError!;
    lastUseBackup = useBackup;
    if (useBackup == null && importConflicts.isNotEmpty) {
      return ImportReport(
        merged: 0,
        added: 0,
        skipped: 0,
        contactsAdded: 0,
        conflicts: importConflicts,
        applied: false,
      );
    }
    final replaced = useBackup?.values.where((v) => v).length ?? 0;
    importConflicts = const [];
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
      final contact = Contact(
        id: c['id'] as String,
        name: c['name'] as String,
        address: c['address'] as String?,
        epicbox: c['epicbox'] as String?,
        http: c['http'] as String?,
        tor: c['tor'] as String?,
        note: c['note'] as String?,
        label: ContactLabel.fromStored(c['label']),
      );
      if (contactsValue.any((e) => e.addresses.any(contact.addresses.contains))) {
        continue;
      }
      contactsValue.add(contact);
      contactsAdded++;
    }
    final pairings = pairing.importBackup(
      decoded['pairings'] as Map<String, Object?>?,
      otherDevice: importPairingsFromOtherDevice,
    );
    return ImportReport(
      merged: 0,
      added: added,
      skipped: skipped,
      contactsAdded: contactsAdded,
      replaced: replaced,
      pairingsAdded: pairings,
      pairingsOtherDevice: importPairingsFromOtherDevice ? pairings : 0,
      walletName: decoded['walletName'] as String?,
      settings: decoded['settings'] as Map<String, Object?>?,
    );
  }

  @override
  Future<FeeEstimate> estimateMax({
    required BigInt minimumConfirmations,
  }) async {
    final spendable = summaryValue.spendable - _heldSpendable;
    if (spendable <= fee) {
      throw const WalletError(
        kind: WalletErrorKind.notEnoughFunds,
        message: 'not enough funds',
      );
    }
    return FeeEstimate(
      amount: spendable - fee,
      fee: fee,
      locked: spendable,
      inputCount: 1,
    );
  }

  void _checkFunds(BigInt amount) {
    if (amount + fee > summaryValue.spendable - _heldSpendable) {
      throw const WalletError(
        kind: WalletErrorKind.notEnoughFunds,
        message: 'not enough funds',
      );
    }
  }

  // Outputs. With [outputsValue] set, estimates choose inputs from its spendable outputs as
  // LEPIC does: smallest first until amount and fee are covered, or all of them; each change
  // output past the first adds [changeOutputFee].

  /// The wallet's outputs; empty keeps the estimates as they were (fee only).
  List<WalletOutput> outputsValue = [];

  @override
  Set<String> heldOutputs = const {};

  /// The kernels the fake chain holds: excess → where ([kernelOnChain]).
  Map<String, KernelLocation> kernelsOnChain = {};

  /// False: [kernelOnChain] fails as a node that cannot be asked does.
  bool kernelLookupWorks = true;

  /// Every [kernelOnChain] call: the excess and the lowest height asked from.
  final List<(String, int?)> kernelLookups = [];

  @override
  Future<KernelLocation?> kernelOnChain(String excessHex, {int? minHeight}) async {
    kernelLookups.add((excessHex, minHeight));
    if (!kernelLookupWorks) throw const WalletError(kind: WalletErrorKind.nodeUnreachable, message: 'node not reached');
    final k = kernelsOnChain[excessHex];
    return k == null || (minHeight != null && k.height < minHeight) ? null : k;
  }

  /// What [heldOutputs] takes from the spendable balance: the held coins among [outputsValue].
  BigInt get _heldSpendable => outputsValue
      .where((o) => o.category == OutputCategory.spendable && heldOutputs.contains(o.commitment))
      .fold(BigInt.zero, (a, o) => a + o.value);

  /// What one change or split output past the first adds to [fee].
  BigInt changeOutputFee = BigInt.from(400000);

  /// The options of every [estimateFee] call, and of every send, null when none were given.
  final List<SendOptions?> estimateOptions = [];
  final List<SendOptions?> sentOptions = [];

  /// The output count of every [splitOutputs] call, and the number of [consolidateOutputs]
  /// calls.
  final List<int> splits = [];
  int consolidations = 0;

  @override
  Future<List<WalletOutput>> outputs() async => List.unmodifiable(outputsValue);

  List<WalletOutput> get _spendableOutputs =>
      outputsValue.where((o) => o.category == OutputCategory.spendable && !heldOutputs.contains(o.commitment)).toList()
        ..sort((a, b) => a.value.compareTo(b.value));

  static const WalletError _notEnough = WalletError(
    kind: WalletErrorKind.notEnoughFunds,
    message: 'not enough funds',
  );

  FeeEstimate _select(BigInt amount, SendOptions options) {
    final n = options.changeOutputs;
    if (n < minChangeOutputs || n > maxChangeOutputs) {
      throw WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'change outputs $n outside 1..=10',
      );
    }
    final all = _spendableOutputs;
    final extra = changeOutputFee * BigInt.from(n - 1);
    final need = amount + fee + extra;
    var sum = BigInt.zero;
    var count = 0;
    for (final o in all) {
      if (options.strategy == SelectionStrategy.smallest && sum >= need) break;
      sum += o.value;
      count++;
    }
    // Inputs that pay amount and fee exactly make no change output, and no split fee.
    if (sum == amount + fee) {
      return FeeEstimate(
        amount: amount,
        fee: fee,
        inputCount: count,
        locked: sum,
      );
    }
    if (sum < need) throw _notEnough;
    final change = sum - need;
    if (change > BigInt.zero && change < BigInt.from(n)) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: sendUnbuildable,
      );
    }
    return FeeEstimate(
      amount: amount,
      fee: fee + extra,
      inputCount: count,
      change: change,
      locked: sum,
      changeOutputs: change == BigInt.zero ? 0 : n,
    );
  }

  FeeEstimate _selfSend(int outputs) {
    final all = _spendableOutputs;
    final sum = all.fold(BigInt.zero, (a, o) => a + o.value);
    final total = fee + changeOutputFee * BigInt.from(outputs - 1);
    if (all.isEmpty || sum < total + BigInt.from(outputs)) throw _notEnough;
    return FeeEstimate(
      amount: (sum - total) ~/ BigInt.from(outputs),
      fee: total,
      inputCount: all.length,
      change: sum - total - (sum - total) ~/ BigInt.from(outputs),
      locked: sum,
      changeOutputs: outputs - 1,
    );
  }

  void _checkSplit(int outputs) {
    if (outputs < minSplitOutputs || outputs > maxSplitOutputs) {
      throw WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'outputs $outputs outside 2..=10',
      );
    }
  }

  /// Locks the spendable outputs and adds [count] unconfirmed ones sharing their value less
  /// the fee, as a posted self-send leaves the wallet.
  SelfSentTx _postSelf(FeeEstimate e, int count) {
    final inputs = _spendableOutputs;
    final id = 500 + splits.length + consolidations;
    final made = <WalletOutput>[];
    final total = e.locked - e.fee;
    for (var i = 0; i < count; i++) {
      final part = total ~/ BigInt.from(count);
      made.add(
        WalletOutput(
          commitment: 'self-$id-$i',
          value: i == count - 1 ? total - part * BigInt.from(count - 1) : part,
          status: WalletOutputStatus.unconfirmed,
          category: OutputCategory.awaitingConfirmation,
          isCoinbase: false,
          height: summaryValue.lastConfirmedHeight,
          lockHeight: BigInt.zero,
          confirmations: BigInt.zero,
          txId: id,
        ),
      );
    }
    outputsValue = [
      for (final o in outputsValue)
        if (inputs.contains(o))
          WalletOutput(
            commitment: o.commitment,
            value: o.value,
            status: WalletOutputStatus.locked,
            category: OutputCategory.locked,
            isCoinbase: o.isCoinbase,
            height: o.height,
            lockHeight: o.lockHeight,
            mmrIndex: o.mmrIndex,
            confirmations: o.confirmations,
            txId: id,
          )
        else
          o,
      ...made,
    ];
    return SelfSentTx(
      txId: id,
      receivedTxId: id + 1,
      amount: e.amount,
      fee: e.fee,
      inputCount: e.inputCount,
      outputCount: count,
    );
  }

  @override
  Future<FeeEstimate> estimateSplit({
    required int outputs,
    required BigInt minimumConfirmations,
  }) async {
    _checkSplit(outputs);
    return _selfSend(outputs);
  }

  @override
  Future<SelfSentTx> splitOutputs({
    required int outputs,
    required BigInt minimumConfirmations,
  }) async {
    _checkSplit(outputs);
    final e = _selfSend(outputs);
    final tx = _postSelf(e, outputs);
    splits.add(outputs);
    return tx;
  }

  @override
  Future<FeeEstimate> estimateConsolidate({
    required BigInt minimumConfirmations,
  }) async => _selfSend(1);

  @override
  Future<SelfSentTx> consolidateOutputs({
    required BigInt minimumConfirmations,
  }) async {
    final e = _selfSend(1);
    final tx = _postSelf(e, 1);
    consolidations++;
    return tx;
  }

  /// The commitments of every [spendOutputsToSelf] call.
  final List<List<String>> spentToSelf = [];

  /// The output count of every [spendOutputsToSelf] call.
  final List<int> spentToSelfOutputs = [];

  /// When set, [spendOutputsToSelf] throws it after recording the call.
  WalletError? spendToSelfError;

  @override
  Future<SelfSentTx> spendOutputsToSelf({
    required List<String> commitments,
    required BigInt minimumConfirmations,
    int outputs = 1,
  }) async {
    if (commitments.isEmpty || commitments.toSet().length != commitments.length || outputs < 1 || outputs > 10) {
      throw const WalletError(
        kind: WalletErrorKind.invalidArgument,
        message: 'name each output once',
      );
    }
    spentToSelf.add([...commitments]);
    spentToSelfOutputs.add(outputs);
    if (spendToSelfError case final error?) throw error;
    return _postSelf(_selfSend(1), 1);
  }

  // Invoices. The fake plays the wallet's half: an invoice parks only from a sender the
  // wallet allows (a verified paired contact with Allow invoices on, [FakePairing]), and issued invoices' states live in [invoiceHistory], as the LEPIC session
  // keeps them. Tests and the tour drive it with [relayInvoice], [relayNotice], [clock] and
  // [replyError]; [collectInvoices] picks up what was relayed.

  /// When false, every invoice call throws [invoicesUnsupported], as on a core without them.
  bool invoicesSupported = true;

  /// Issued invoices' states; a test passes one on a file to check a reopen.
  WalletHistory invoiceHistory;

  /// Now, for expiry. Tests move it forward.
  DateTime Function() clock = DateTime.now;


  /// Waiting at the relay until the next [collectInvoices].
  final List<_Relayed> _relay = [];

  /// Messages [collectInvoices] dropped unread: invoices from anyone but an allowed paired
  /// contact, notices from anyone but the invoice's contact.
  int droppedInvoiceMessages = 0;

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

  /// An invoice from [from] waiting at the relay. Parked by the next collect only if [from]'s
  /// key is a verified paired contact's with Allow invoices on and [expiresIn] is at most [maxInvoiceExpiry]; dropped
  /// otherwise.
  void relayInvoice({
    required String from,
    required String slateId,
    required BigInt amount,
    String? message,
    String? reference,
    Duration expiresIn = const Duration(hours: 24),
  }) => _relay.add(
    _Relayed(
      from: from,
      slateId: slateId,
      amount: amount,
      message: message,
      reference: reference,
      expiresIn: expiresIn,
    ),
  );

  /// A notice from [from] waiting at the relay: [InvoiceEventKind.posted] (with
  /// [kernelExcess]) or [InvoiceEventKind.withdrawn]. Applied by the next collect only when
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

  /// The sender of the waiting incoming payment [slateId] reports it posted, as LEPIC raises
  /// it: the row records the report (at [clock]) and [InvoiceEventKind.paymentPosted] goes out.
  void reportPosted({required String slateId, String? kernelExcess}) {
    final i = transactionsValue.indexWhere((t) => t.slateId == slateId);
    if (i >= 0) {
      final tx = transactionsValue[i];
      transactionsValue[i] = copyTx(
        tx,
        note: tx.note,
        senderReportedPostedAtUnix: clock().millisecondsSinceEpoch ~/ 1000,
      );
    }
    _emit(InvoiceEventKind.paymentPosted, slateId, kernelExcess: kernelExcess);
  }

  /// The sender of the incoming payment [slateId] this wallet answered reports it cancelled, as
  /// LEPIC raises it: the row records the report (at [clock]) and
  /// [InvoiceEventKind.paymentCancelled] goes out. Nothing is cancelled here.
  void reportCancelled({required String slateId}) {
    final i = transactionsValue.indexWhere((t) => t.slateId == slateId);
    if (i >= 0) {
      final tx = transactionsValue[i];
      transactionsValue[i] = copyTx(
        tx,
        note: tx.note,
        senderReportedCancelledAtUnix: clock().millisecondsSinceEpoch ~/ 1000,
      );
    }
    _emit(InvoiceEventKind.paymentCancelled, slateId);
  }

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

  /// A request parks only from a verified paired contact with Allow invoices on (RFC 11.1),
  /// as LEPIC's contact invoices do.
  bool _trusted(String from) {
    final r = pairing.recordFor(from);
    return r != null && r.state == PairingState.verified && r.allowInvoices;
  }

  @override
  bool get supportsInvoices => invoicesSupported;

  /// Off: requests go to paired contacts only, as on LEPIC.
  bool requestFilesSupported = true;

  @override
  bool get supportsRequestFiles => invoicesSupported && requestFilesSupported;

  /// Request files [payRequestFile] paid, by slate id, as LEPIC refuses a second payment.
  final Map<String, PaidRequestFile> paidRequestFiles = {};

  /// When set, [payRequestFile] throws it and pays nothing.
  WalletError? payRequestFileError;

  @override
  Future<PaidRequestFile> payRequestFile({required String slateJson, required BigInt amount}) async {
    if (!supportsRequestFiles) throw invoicesUnsupported('payRequestFile');
    final info = node?.slateInfos[slateJson];
    if (info == null || info.stage != SlateStage.request) {
      throw const WalletError(kind: WalletErrorKind.invalidSlate, message: 'not a payment request');
    }
    if (paidRequestFiles.containsKey(info.slateId)) {
      throw const WalletError(kind: WalletErrorKind.invoiceAlreadyPaid, message: 'already paid');
    }
    if (amount != info.amount) {
      throw const WalletError(kind: WalletErrorKind.amountMismatch, message: 'the amount does not match the request');
    }
    if (payRequestFileError != null) throw payRequestFileError!;
    _checkFunds(amount);
    final txId = 400 + paidRequestFiles.length;
    transactionsValue.add(
      fakeTx(
        id: txId,
        slateId: info.slateId,
        kind: TxKind.sent,
        status: TxStatus.awaitingRecipient,
        createdAtUnix: clock().millisecondsSinceEpoch ~/ 1000,
        amountDebited: amount + fee,
        fee: fee,
        numInputs: 1,
        cancellable: true,
        flow: TxFlow.invoice,
      ),
    );
    final json = jsonEncode({'fake_invoice_answer': info.slateId, 'amount': '$amount'});
    // Another fake wallet that issued it finishes it from this text.
    node?.slateInfos[json] = SlateInfo(slateId: info.slateId, amount: amount, fee: fee, stage: SlateStage.requestAnswer);
    return paidRequestFiles[info.slateId] = PaidRequestFile(txId: txId, slateId: info.slateId, amount: amount, fee: fee, json: json);
  }

  /// Finishes the answer to the request [slateId], as LEPIC refuses one it no longer waits for.
  Future<TxEntry> _finishRequest(String slateId) async {
    final issued = _request(slateId);
    if (issued == null) {
      throw const WalletError(kind: WalletErrorKind.invoiceNotFound, message: 'no such request');
    }
    if (issued.state == IssuedInvoiceState.paid) {
      throw const WalletError(kind: WalletErrorKind.invoiceAlreadyPaid, message: 'already paid');
    }
    if (!issued.withdrawable) {
      throw const WalletError(kind: WalletErrorKind.paymentExpired, message: 'the request ended');
    }
    await payIssued(slateId);
    finalizedSlates.add(slateId);
    return transactionsValue.firstWhere((t) => t.slateId == slateId);
  }

  @override
  Future<InvoiceCollectReport> collectInvoices() async {
    _requireInvoices('collectInvoices');
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
          pairingId: pairing.recordFor(m.from)?.id,
          reference: m.reference,
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
    droppedInvoiceMessages += dropped;
    return InvoiceCollectReport(parked: parked, notices: notices);
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
        kind: WalletErrorKind.invoiceNotFound,
        message: 'no pending invoice with that id',
      );
    }
    if (amount != invoice.amount) {
      throw const WalletError(
        kind: WalletErrorKind.amountMismatch,
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
        // As LEPIC marks an invoice payment.
        flow: TxFlow.invoice,
      ),
    );
    final paid = PaidInvoice(
      slateId: slateId,
      senderAddress: invoice.senderAddress,
      pairingId: invoice.pairingId,
      reference: invoice.reference,
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
    if (paid.status != InvoiceStatus.replyFailed &&
        paid.status != InvoiceStatus.replied) {
      return paid;
    }
    if (replyError != null) throw replyError!;
    return _deliver(paid);
  }

  @override
  Future<void> declineInvoice({required String slateId}) async {
    _requireInvoices('declineInvoice');
    if (pendingInvoicesValue.remove(slateId) == null) {
      throw const WalletError(
        kind: WalletErrorKind.invoiceNotFound,
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

  /// When set, [issueToContact] throws it and records nothing, as LEPIC does when the relay
  /// does not take the request.
  WalletError? issueError;

  /// Every request that got past its checks, with what it sent.
  final List<({BigInt amount, String to, String? message})> issuedRequests = [];

  /// Number of [drainPayments] calls.
  int drainPaymentCalls = 0;

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

  /// A request to the paired contact whose payments address is [address]
  /// ([FakePairing.requestPayment]): kept as an incoming invoice waiting for its payer.
  Future<IssuedInvoice> issueToContact({
    required BigInt amount,
    required String address,
    String? message,
  }) async {
    _requireInvoices('requestPayment');
    final to = address.trim();
    // Its own addresses first: the fake's are not valid epicbox addresses.
    final own = [this.address];
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

  /// A request kept as a file ([FakePairing.requestFile]): an incoming invoice waiting for
  /// its payer, with no address to send it to.
  Future<IssuedInvoice> issueRequestFile({required BigInt amount, String? message}) async {
    _requireInvoices('requestFile');
    final text = cutMessage(message);
    issuedRequests.add((amount: amount, to: '', message: text));
    final n = issuedRequests.length;
    final slateId = 'issued-$n';
    transactionsValue.add(
      fakeTx(
        id: 300 + n,
        slateId: slateId,
        kind: TxKind.received,
        status: TxStatus.awaitingConfirmation,
        createdAtUnix: clock().millisecondsSinceEpoch ~/ 1000,
        amountCredited: amount,
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
    cancelledTxIds.add(issued.txId!);
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

  /// The payer paid [slateId]; the wallet finalized and posted it.
  Future<void> payIssued(String slateId) =>
      _settleIssued(slateId, IssuedInvoiceState.paid);

  /// The payer declined [slateId]; the wallet withdraws it, as the LEPIC session does.
  Future<void> declineIssued(String slateId) =>
      _endIssued(slateId, IssuedInvoiceState.declined);

  /// The wallet's sweep cancelled [slateId] unpaid.
  Future<void> expireIssued(String slateId) =>
      _settleIssued(slateId, IssuedInvoiceState.expired);

  /// The payer's wallet sent [slateId] back unpaid: the wallet withdraws it once, as the
  /// LEPIC session does. Call it again for a bounce LEPIC delivers twice.
  Future<void> bounceIssued(String slateId) => _endIssued(slateId, IssuedInvoiceState.bounced);

  Future<void> _endIssued(String slateId, IssuedInvoiceState state) async {
    final issued = _request(slateId);
    if (issued == null || !issued.withdrawable) return;
    cancelledTxIds.add(issued.txId!);
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
    this.reference,
  });

  final String from;
  final String slateId;
  final BigInt? amount;
  final String? message;
  final String? reference;
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
  String? transport,
  String? note,
  String? label,
  Set<ManualField> manualFields = const {},
  int? manualEditedAtUnix,
  List<SlateMessage> messages = const [],
  BigInt? ttlCutoffHeight,
  bool cancellable = false,
  bool repostable = false,
  bool undelivered = false,
  String? statusDetail,
  bool releasable = false,
  int? finalizedAtUnix,
  CancelReason? cancelReason,
  TxFlow flow = TxFlow.payment,
  int? senderReportedPostedAtUnix,
  int? senderReportedCancelledAtUnix,
  String? pairingId,
  TxOrigin origin = TxOrigin.thisWallet,
  List<String> spentCommits = const [],
  bool unverified = false,
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
    transport: transport,
    note: note,
    label: label,
    manualFields: manualFields,
    manualEditedAtUnix: manualEditedAtUnix,
    messages: messages,
    ttlCutoffHeight: ttlCutoffHeight,
    cancellable: cancellable,
    repostable: repostable,
    undelivered: undelivered,
    statusDetail: statusDetail,
    releasable: releasable,
    finalizedAtUnix: finalizedAtUnix,
    cancelReason: cancelReason,
    flow: flow,
    senderReportedPostedAtUnix: senderReportedPostedAtUnix,
    senderReportedCancelledAtUnix: senderReportedCancelledAtUnix,
    pairingId: pairingId,
    origin: origin,
    spentCommits: spentCommits,
    unverified: unverified,
  );
}

/// [tx] with [note] replaced, and [undelivered], [label], [counterparty], [transport],
/// [manualFields], [manualEditedAtUnix], [senderReportedPostedAtUnix] and
/// [senderReportedCancelledAtUnix] when given.
TxEntry copyTx(
  TxEntry tx, {
  String? note,
  bool? undelivered,
  int? senderReportedPostedAtUnix,
  int? senderReportedCancelledAtUnix,
  String? label,
  String? counterparty,
  String? transport,
  Set<ManualField>? manualFields,
  int? manualEditedAtUnix,
}) => TxEntry(
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
  counterparty: counterparty ?? tx.counterparty,
  transport: transport ?? tx.transport,
  note: note,
  label: label ?? tx.label,
  manualFields: manualFields ?? tx.manualFields,
  manualEditedAtUnix: manualEditedAtUnix ?? tx.manualEditedAtUnix,
  messages: tx.messages,
  ttlCutoffHeight: tx.ttlCutoffHeight,
  cancellable: tx.cancellable,
  repostable: tx.repostable,
  undelivered: undelivered ?? tx.undelivered,
  statusDetail: tx.statusDetail,
  releasable: tx.releasable,
  finalizedAtUnix: tx.finalizedAtUnix,
  cancelReason: tx.cancelReason,
  flow: tx.flow,
  foundDuring: tx.foundDuring,
  datedByBlock: tx.datedByBlock,
  senderReportedPostedAtUnix:
      senderReportedPostedAtUnix ?? tx.senderReportedPostedAtUnix,
  senderReportedCancelledAtUnix:
      senderReportedCancelledAtUnix ?? tx.senderReportedCancelledAtUnix,
  origin: tx.origin,
  spentCommits: tx.spentCommits,
  unverified: tx.unverified,
);
