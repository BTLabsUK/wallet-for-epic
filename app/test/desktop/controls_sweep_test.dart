// Every control of every desktop screen in the shots catalogue (screens/*/shots.dart) does
// something real: each enabled button, icon button, link, switch, checkbox, segment, select,
// nav item, choice card and row is pressed on a fresh app over the mock wallet, and the press
// must act on the wallet (an API call that is not a plain read), move the app (route, tour,
// settings), open a dialog or a folder, write the clipboard, or change what the screen shows.
// A press that does nothing, or only shows a toast, fails unless [_allowed] says why. A press
// that reaches an API method the real wallet (LepicDeskWallet) only stubs fails too.
import 'package:epic_wallet/src/desktop/app/desk_app.dart';
import 'package:epic_wallet/src/desktop/app/shell.dart';
import 'package:epic_wallet/src/desktop/app/tour.dart';
import 'package:epic_wallet/src/desktop/data/api.dart';
import 'package:epic_wallet/src/desktop/data/files.dart';
import 'package:epic_wallet/src/desktop/data/http_address.dart' show HttpReach;
import 'package:epic_wallet/src/desktop/data/invoices.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/pairing_api.dart' show PairingApi;
import 'package:epic_wallet/src/desktop/data/desk_node.dart';
import 'package:epic_wallet/src/desktop/screens/settings/local_node_dialogs.dart' show deskPickFolder;
import 'package:epic_wallet/src/desktop/screens/settings/prefs.dart';
import 'package:epic_wallet/src/desktop/screens/settings/shots.dart';
import 'package:epic_wallet/src/desktop/screens/transfer/shots.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/shots.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Controls that may only toast or change nothing visible here, matched on `<scope>|<label>`
/// (scope: the route's name, `shell`, or the shot id for a dialog shot), each with its reason.
final Map<RegExp, String> _allowed = {
  RegExp(r'^shell\|Overview$|^(settingsNode\|Node|settingsReceiving\|Transactions|settingsPrivacy\|Privacy|settingsAppearance\|Appearance|settingsAccount\|This wallet|settingsWallets\|All wallets|settingsPhrase\|Recovery phrase|settingsRescan\|Recheck balance|settingsAdvanced\|Advanced|settingsAbout\|About|settingsHelp\|Help)$'):
      'The place already shown: going there again adds nothing to the history (F16).',
  RegExp(r'^settingsAccount\|Open folder$'): 'The mock wallet folder is not on disk: says "Folder not found". A real one opens.',
  RegExp(r'^settingsWallets\|Show .* in its folder$'): 'The mock wallet folders are not on disk: says "Folder not opened". A real one opens.',
  RegExp(r'^settingsAbout\|Check now$'): 'Asks the update server again; in tests it answers as before, so the line stays.',
  RegExp(r'^settingsHelp\|Open log folder$'): 'In tests the log is in memory, with no folder: says so. The real log folder opens.',
  RegExp(r'^31b-dlg-my-node-error\|Save$'): 'Refuses the bad address; its error is on screen already.',
  RegExp(r'^receive\|[\u{E000}-\u{10FFFF}]*$', unicode: true):
      'The header\'s method icons scroll to their panel; on these shots every panel is in view (receive_test checks the jump).',
  RegExp(r'^outputs\|Smallest spends '): 'A help icon: its text shows on hover and, pressed, in a toast.',
  RegExp(r'^35[de]-dlg-tx-details-(add|edit)\|(Epicbox|Link|Link · HTTP|Link · Tor|Direct · File Transfer|Direct · File|File|Tor|Unknown)$'):
      'A method choice in the details dialog: only the segment\'s own look changes; tx_labels_test saves it.',
  RegExp(r'^settingsReceiving\|Direct · (File Transfer|QR Payment)$'):
      'The one method left on cannot be turned off: pressed, it says so in a toast (transactions_settings tests check it).',
  RegExp(r'^35-dlg-tx-proof\|Export$'): 'Behind DeskFeatures.paymentProofs (off): the dialog cannot be opened in the app.',
  RegExp(r'^settingsHelp\|(Getting started|How Epic Cash works|Keeping the wallet safe|Nodes and Epicbox|Pairing|When something goes wrong)$'):
      'A section chip scrolls to its section (help_test checks it); the sweep compares what is shown, not where.',
  RegExp(r'^21d-dlg-reuse-chain\|Use it$'): 'The mock lists a folder another program holds: its card is dimmed and says so, and cannot be picked.',
  RegExp(r'^25j-dlg-export-csv\|This year$'): 'Every mock payment is from this year, so the count stays; Last year changes it.',
};

/// What the real wallet only stubs (throws UnsupportedError); a visible control must not reach them.
const Set<String> _stubbed = {'exportProof', 'changePassword', 'newPhrase'};

/// Reads: a control whose only effect is one of these did nothing the user can see.
const Set<String> _reads = {
  'wallets',
  'account',
  'balance',
  'transactions',
  'outputs',
  'contacts',
  'status',
  'nodes',
  'epicboxes',
  'settings',
  'epicboxAddress',
  'httpAddress',
  'torAddress',
  'isOnionAddress',
  'isEpicboxAddress',
  'epicboxAddressOtherChain',
  'estimateFee',
  'estimateMax',
  'findRemoved',
  'checkPhrase',
  'walletWithPhrase',
  'changes',
  'historyBackupState',
};

/// The mock wallet, with every call recorded by name.
class _Recorder implements DeskWalletApi, MockBacked {
  _Recorder();

  final _m = MockDeskWallet(delay: Duration.zero);

  @override
  MockDeskWallet get mock => _m;
  final List<String> calls = [];

  @override
  Future<void> useNodeForSession(String url) => _r('useNodeForSession', () => _m.useNodeForSession(url));

  T _r<T>(String name, T Function() f) {
    calls.add(name);
    return f();
  }

  @override
  Future<List<WalletEntry>> wallets() => _r('wallets', _m.wallets);
  @override
  Future<bool> setupPending(String id) => _m.setupPending(id);
  @override
  Future<void> setSetupPending(String id, bool pending) => _m.setSetupPending(id, pending);
  @override
  Future<bool> setupRestored(String id) => _m.setupRestored(id);
  @override
  Future<void> setSetupRestored(String id) => _r('setSetupRestored', () => _m.setSetupRestored(id));
  @override
  Future<void> selectWallet(String id) => _r('selectWallet', () => _m.selectWallet(id));
  @override
  Future<bool> unlock(String password, {bool remember = false}) => _r('unlock', () => _m.unlock(password, remember: remember));
  @override
  Future<bool> unlockRemembered() => _r('unlockRemembered', _m.unlockRemembered);
  @override
  Future<bool> isRemembered(String id) => _m.isRemembered(id);
  @override
  Future<void> forgetRemembered(String id) => _r('forgetRemembered', () => _m.forgetRemembered(id));
  @override
  bool get notRemembered => _m.notRemembered;
  @override
  bool get busy => _m.busy;
  @override
  bool get openedRemembered => _m.openedRemembered;
  @override
  Future<bool> checkPassword(String password) => _r('checkPassword', () => _m.checkPassword(password));
  @override
  Future<void> lock() => _r('lock', _m.lock);
  @override
  Future<void> renameWallet(String id, String label) => _r('renameWallet', () => _m.renameWallet(id, label));
  @override
  Future<void> removeWallet(String id, WalletRemoval mode, {String? password}) => _r('removeWallet', () => _m.removeWallet(id, mode, password: password));
  @override
  Future<List<WalletEntry>> findRemoved() => _r('findRemoved', _m.findRemoved);
  @override
  Future<void> addBack(String id) => _r('addBack', () => _m.addBack(id));
  @override
  Future<List<String>> newPhrase({int words = 24}) => _r('newPhrase', () => _m.newPhrase(words: words));
  @override
  Future<List<String>> createWallet({String name = '', required String password}) =>
      _r('createWallet', () => _m.createWallet(name: name, password: password));
  @override
  bool checkPhrase(List<String> words) => _r('checkPhrase', () => _m.checkPhrase(words));
  @override
  Future<WalletEntry?> walletWithPhrase(List<String> words) => _r('walletWithPhrase', () => _m.walletWithPhrase(words));
  @override
  Future<void> restoreWallet({String name = '', required String password, required List<String> phrase, BigInt? startHeight}) =>
      _r('restoreWallet', () => _m.restoreWallet(name: name, password: password, phrase: phrase, startHeight: startHeight));
  @override
  Future<List<OldWallet>> findOldWallets() => _r('findOldWallets', _m.findOldWallets);
  @override
  Future<FolderFind?> pickFolder() => _r('pickFolder', _m.pickFolder);
  @override
  Future<OldWalletUse> checkOldWallet(String id) => _r('checkOldWallet', () => _m.checkOldWallet(id));
  @override
  Future<ImportedWallet> importOldWallet(String id, {required String oldPassword, String? newPassword}) =>
      _r('importOldWallet', () => _m.importOldWallet(id, oldPassword: oldPassword, newPassword: newPassword));
  @override
  Future<void> cancelImport() => _r('cancelImport', _m.cancelImport);
  @override
  Future<WalletAccount> account() => _r('account', _m.account);
  @override
  Future<Balance> balance() => _r('balance', _m.balance);
  @override
  Future<List<Tx>> transactions() => _r('transactions', _m.transactions);
  @override
  Future<List<Output>> outputs() => _r('outputs', _m.outputs);
  @override
  Future<List<Contact>> contacts() => _r('contacts', _m.contacts);
  @override
  Future<ServiceStatus> status() => _r('status', _m.status);
  @override
  Future<List<NodeServer>> nodes() => _r('nodes', _m.nodes);
  @override
  Future<List<EpicboxServer>> epicboxes() => _r('epicboxes', _m.epicboxes);
  @override
  Future<DeskSettings> settings() => _r('settings', _m.settings);
  @override
  Future<String> epicboxAddress() => _r('epicboxAddress', _m.epicboxAddress);
  @override
  Future<String> httpAddress() => _r('httpAddress', _m.httpAddress);
  @override
  Future<HttpReach?> httpReach({bool recheck = false}) => _r('httpReach', () => _m.httpReach(recheck: recheck));
  @override
  Future<String> torAddress() => _r('torAddress', _m.torAddress);
  @override
  bool isOnionAddress(String to) => _r('isOnionAddress', () => _m.isOnionAddress(to));

  @override
  bool isEpicboxAddress(String to) => _r('isEpicboxAddress', () => _m.isEpicboxAddress(to));
  @override
  bool epicboxAddressOtherChain(String to) =>
      _r('epicboxAddressOtherChain', () => _m.epicboxAddressOtherChain(to));
  @override
  Future<int> estimateFee(int amount) => _r('estimateFee', () => _m.estimateFee(amount));
  @override
  Future<SendEstimate> estimateMax() => _r('estimateMax', _m.estimateMax);
  @override
  Future<SendEstimate> estimateSend(int amount, {SendOptions? options}) => _r('estimateSend', () => _m.estimateSend(amount, options: options));
  @override
  Future<OutputPrefs> outputPrefs() => _r('outputPrefs', _m.outputPrefs);
  @override
  Future<void> saveOutputPrefs(OutputPrefs prefs) => _r('saveOutputPrefs', () => _m.saveOutputPrefs(prefs));
  @override
  Future<void> repostTx(int id) => _r('repostTx', () => _m.repostTx(id));
  @override
  Future<void> resendTx(int id) => _r('resendTx', () => _m.resendTx(id));

  @override
  Future<SendEstimate> estimateSplit(int outputs) => _r('estimateSplit', () => _m.estimateSplit(outputs));
  @override
  Future<SelfSend> splitOutputs(int outputs) => _r('splitOutputs', () => _m.splitOutputs(outputs));
  @override
  Future<SendEstimate> estimateConsolidate() => _r('estimateConsolidate', _m.estimateConsolidate);
  @override
  Future<SelfSend> consolidateOutputs() => _r('consolidateOutputs', _m.consolidateOutputs);
  @override
  Future<SendResult> send(SendRequest request) => _r('send', () => _m.send(request));
  @override
  Future<ReceivedFile> receiveFile(String fileName) => _r('receiveFile', () => _m.receiveFile(fileName));
  @override
  Future<ReceivedFile> receiveText(String text) => _r('receiveText', () => _m.receiveText(text));
  @override
  String get network => _m.network;
  @override
  Future<void> useNetwork(String network) => _r('useNetwork', () => _m.useNetwork(network));
  @override
  Future<Tx> finalizeFile(String fileName) => _r('finalizeFile', () => _m.finalizeFile(fileName));
  @override
  Future<bool> isResponseText(String text) => _r('isResponseText', () => _m.isResponseText(text));
  @override
  Future<Tx> finalizeText(String text) => _r('finalizeText', () => _m.finalizeText(text));
  @override
  Future<void> cancelTx(int id) => _r('cancelTx', () => _m.cancelTx(id));
  @override
  Future<String> exportProof(int id) => _r('exportProof', () => _m.exportProof(id));
  @override
  Future<String> saveContact(Contact contact) => _r('saveContact', () => _m.saveContact(contact));
  @override
  Future<void> deleteContact(String id) => _r('deleteContact', () => _m.deleteContact(id));
  @override
  Future<void> saveSettings(DeskSettings settings) => _r('saveSettings', () => _m.saveSettings(settings));
  @override
  Future<void> useNode(String url) => _r('useNode', () => _m.useNode(url));
  @override
  Future<void> useBuiltInNode(bool on) => _r('useBuiltInNode', () => _m.useBuiltInNode(on));
  @override
  Future<NodeServer> checkNode(String url) => _r('checkNode', () => _m.checkNode(url));
  @override
  Future<void> addNode(NodeServer node) => _r('addNode', () => _m.addNode(node));
  @override
  Future<void> useEpicbox(String domain) => _r('useEpicbox', () => _m.useEpicbox(domain));
  @override
  Future<void> setListening(bool on) => _r('setListening', () => _m.setListening(on));
  @override
  Future<void> setEpicboxListening(bool on) => _r('setEpicboxListening', () => _m.setEpicboxListening(on));
  @override
  Future<void> startAutostart() => _r('startAutostart', _m.startAutostart);
  @override
  Future<void> setHttpListening(bool on) => _r('setHttpListening', () => _m.setHttpListening(on));
  @override
  Future<void> setTor(bool on) => _r('setTor', () => _m.setTor(on));

  @override
  Future<void> setEpicboxOverTor(bool on) => _r('setEpicboxOverTor', () => _m.setEpicboxOverTor(on));
  @override
  Future<void> syncNow() => _r('syncNow', _m.syncNow);
  @override
  Stream<ScanStep> rescan({bool deleteUnconfirmed = false, BigInt? startHeight}) => _r('rescan', () => _m.rescan(deleteUnconfirmed: deleteUnconfirmed, startHeight: startHeight));
  @override
  Future<void> stopRescan() => _r('stopRescan', _m.stopRescan);
  @override
  Stream<void> changes() => _m.changes();
  @override
  Future<List<String>> revealPhrase(String password) => _r('revealPhrase', () => _m.revealPhrase(password));
  @override
  Future<void> changePassword(String current, String next) => _r('changePassword', () => _m.changePassword(current, next));
  @override
  Future<HistoryBackupState> historyBackupState() => _r('historyBackupState', _m.historyBackupState);
  @override
  Future<Uint8List> exportHistory() => _r('exportHistory', _m.exportHistory);
  @override
  Future<String> exportHistoryCsv({DateTime? from, DateTime? to}) => _r('exportHistoryCsv', () => _m.exportHistoryCsv(from: from, to: to));
  @override
  Future<HistoryImport> importHistory(Uint8List data, {Map<String, bool>? useBackup}) => _r('importHistory', () => _m.importHistory(data, useBackup: useBackup));
  @override
  List<ImportConflict> get oldHistoryConflicts => _m.oldHistoryConflicts;
  @override
  Future<void> resolveOldHistory(Map<String, bool>? useOldWallet) => _r('resolveOldHistory', () => _m.resolveOldHistory(useOldWallet));
  @override
  Future<void> setTxLabel(String key, String? label) => _r('setTxLabel', () => _m.setTxLabel(key, label));
  @override
  Future<void> setTxDetails(String key, {String? counterparty, String? transport, String? note}) =>
      _r('setTxDetails', () => _m.setTxDetails(key, counterparty: counterparty, transport: transport, note: note));
  @override
  Future<void> markHistoryExported(DateTime when) => _r('markHistoryExported', () => _m.markHistoryExported(when));
  @override
  Future<void> dismissHistoryReminder(DateTime when) => _r('dismissHistoryReminder', () => _m.dismissHistoryReminder(when));

  // Invoices: hidden in the sweep (the prototype's screens have their own shots).
  @override
  bool get supportsInvoices => false;

  @override
  bool get supportsRequestFiles => false;

  @override
  int get sessionRevision => 0;
  @override
  Stream<InvoiceNotice> invoiceNotices() => const Stream.empty();
  @override
  Future<InvoiceBook> invoices() => _r('invoices', _m.invoices);
  @override
  Future<InvoiceBook> checkInvoices() => _r('checkInvoices', _m.checkInvoices);
  @override
  Future<IssuedRequest> requestPayment(PaymentRequestDraft draft) => _r('requestPayment', () => _m.requestPayment(draft));
  @override
  Future<RequestFileMade> requestFile({required int amount, String? message}) => _r('requestFile', () => _m.requestFile(amount: amount, message: message));
  @override
  Future<RequestFile?> readRequestFile(String path) => _r('readRequestFile', () => _m.readRequestFile(path));
  @override
  Future<RequestFile?> readRequestText(String text) => _r('readRequestText', () => _m.readRequestText(text));
  @override
  Future<ReceivedFile> payRequestFile(RequestFile file, {required String password}) => _r('payRequestFile', () => _m.payRequestFile(file, password: password));
  @override
  Future<void> withdrawRequest(String slateId) => _r('withdrawRequest', () => _m.withdrawRequest(slateId));
  @override
  Future<void> cancelRequestPayment(String slateId) => _r('cancelRequestPayment', () => _m.cancelRequestPayment(slateId));
  @override
  Future<void> repostRequest(String slateId) => _r('repostRequest', () => _m.repostRequest(slateId));
  @override
  Future<IncomingInvoice> payInvoice(String slateId, {required int amount, required String password}) =>
      _r('payInvoice', () => _m.payInvoice(slateId, amount: amount, password: password));
  @override
  Future<IncomingInvoice> retryInvoiceReply(String slateId) => _r('retryInvoiceReply', () => _m.retryInvoiceReply(slateId));
  @override
  Future<void> declineInvoice(String slateId) => _r('declineInvoice', () => _m.declineInvoice(slateId));
  @override
  Future<void> cancelInvoicePayment(String slateId) => _r('cancelInvoicePayment', () => _m.cancelInvoicePayment(slateId));
  @override
  Future<SelfSend> spendCancelledToSelf(String slateId) => _r('spendCancelledToSelf', () => _m.spendCancelledToSelf(slateId));
  // Pairing calls go to the pairing API, not through the recorder.
  @override
  PairingApi get pairing => _m.pairing;
  @override
  Future<void> setInvoiceExpiry(Duration expiry) => _r('setInvoiceExpiry', () => _m.setInvoiceExpiry(expiry));
}

/// One pressable control: its kind and label, found again by them on a fresh app.
class _Control {
  _Control(this.kind, this.label, this.press);

  final String kind;
  final String label;
  final void Function() press;
}

/// The enabled controls under [scope], in tree order. Text fields and copy buttons are left out
/// (typing is not a press; copying is checked in surfaces' own tests).
List<_Control> _controls(Finder scope) {
  Iterable<Widget> under(Type t) => find.descendant(of: scope, matching: find.byType(t)).evaluate().map((e) => e.widget);
  Iterable<Widget> underG(bool Function(Widget) test) => find.descendant(of: scope, matching: find.byWidgetPredicate(test)).evaluate().map((e) => e.widget);
  final out = <_Control>[];
  for (final w in under(EButton).cast<EButton>()) {
    if (w.onPressed != null) out.add(_Control('button', w.label, w.onPressed!));
  }
  for (final w in under(EIconButton).cast<EIconButton>()) {
    if (w.onPressed != null) out.add(_Control('icon', w.label, w.onPressed!));
  }
  for (final w in under(ELink).cast<ELink>()) {
    if (w.onPressed != null) out.add(_Control('link', w.label, w.onPressed!));
  }
  for (final w in under(ESwitch).cast<ESwitch>()) {
    final f = w.onChanged;
    if (f != null) out.add(_Control('switch', w.semanticLabel ?? w.label ?? '?', () => f(!w.value)));
  }
  for (final w in under(ECheckbox).cast<ECheckbox>()) {
    out.add(_Control('checkbox', w.label, () => w.onChanged(!w.value)));
  }
  for (final w in underG((w) => w is ESegmented)) {
    final s = w as dynamic;
    for (final seg in (s.segments as List)) {
      final v = (seg as dynamic).value;
      if (v != s.value) out.add(_Control('segment', seg.label as String, () => (s.onChanged as Function)(v)));
    }
  }
  for (final w in underG((w) => w is ESelect)) {
    final s = w as dynamic;
    final other = (s.items as List).map((i) => (i as dynamic).value).where((v) => v != s.value).firstOrNull;
    if (other != null) out.add(_Control('select', (s.semanticLabel as String?) ?? '?', () => (s.onChanged as Function)(other)));
  }
  for (final w in under(ENavItem).cast<ENavItem>()) {
    out.add(_Control('nav', w.label, w.onTap));
  }
  for (final w in under(EChoiceCard).cast<EChoiceCard>()) {
    if (!w.selected) out.add(_Control('choice', w.title, w.onTap));
  }
  for (final e in find.descendant(of: scope, matching: find.byType(InkWell)).evaluate()) {
    final w = e.widget as InkWell;
    if (w.onTap == null) continue;
    final texts = find.descendant(of: find.byWidget(w), matching: find.byType(RichText)).evaluate();
    final label = texts.isEmpty ? '?' : (texts.first.widget as RichText).text.toPlainText();
    out.add(_Control('row', label, w.onTap!));
  }
  return out;
}

/// What the screen shows, toasts left out.
String _shown() {
  final toast = find.descendant(of: find.byType(SnackBar), matching: find.byType(RichText)).evaluate().toSet();
  final b = StringBuffer();
  for (final e in find.byType(RichText).evaluate()) {
    if (!toast.contains(e)) b.writeln((e.widget as RichText).text.toPlainText());
  }
  for (final e in find.byType(EditableText).evaluate()) {
    b.writeln('field ${(e.widget as EditableText).controller.text}');
  }
  for (final e in find.byType(ESwitch).evaluate()) {
    b.writeln('switch ${(e.widget as ESwitch).value}');
  }
  for (final e in find.byType(ECheckbox).evaluate()) {
    b.writeln('check ${(e.widget as ECheckbox).value}');
  }
  for (final e in find.byType(EChoiceCard).evaluate()) {
    b.writeln('choice ${(e.widget as EChoiceCard).title} ${(e.widget as EChoiceCard).selected}');
  }
  b.writeln('busy ${find.byType(ESpinner).evaluate().length}');
  return b.toString();
}

/// Controls already pressed, by scope, kind and label: a sidebar item is pressed once.
final Set<String> _pressed = {};

void main() {
  // Onboarding (Welcome, Create, Restore, Import, Setup, Unlock) is left to its own tests: its
  // presses run whole wallet flows that end in another app start.
  final shots = [...walletShots, ...transferShots, ...settingsShots];
  final failures = <String>[];
  // The OS folder picker answers with a folder, as a user would pick one.
  setUpAll(() => deskPickFolder = () async => '/media/data/epic');

  tearDownAll(() {
    // One list at the end, as well as each shot's own failure.
    if (failures.isNotEmpty) debugPrint('Dead controls:\n${failures.join('\n')}');
  });

  for (final shot in shots) {
    testWidgets('controls of ${shot.id} act', (tester) async {
      tester.view.physicalSize = Size(shot.width, shot.height);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final clipboard = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') clipboard.add('${(call.arguments as Map)['text']}');
        if (call.method == 'Clipboard.getData') return {'text': 'esYpasted0address@epicbox.epiccash.com'};
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      Future<void> settle() async {
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 60));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
        }
      }

      // A fresh app on the shot: its recorder, opened folders and the scope its controls are in.
      Future<(_Recorder, List<String>, ProviderContainer, Finder, String)> open() async {
        final api = _Recorder();
        final folders = <String>[];
        final container = ProviderContainer(
          overrides: [
            deskApiProvider.overrideWithValue(api),
            deskOpenFolderProvider.overrideWithValue((dir) async {
              folders.add(dir);
              return true;
            }),
            deskOpenUrlProvider.overrideWithValue((url) async {
              folders.add(url);
              return true;
            }),
          ],
          retry: (_, _) => null,
        );
        addTearDown(container.dispose);
        await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
        // Arrived from Overview, as a user would: Back has somewhere to go.
        container.read(deskNavProvider.notifier)
          ..reset(DeskRoute.overview)
          ..go(shot.route, shot.arg);
        // Nothing of the previous app carries over (the navigator's key is global).
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const DeskApp()));
        await settle();
        final ctx = tester.element(find.byType(DeskRoot));
        if (shot.prepare != null) {
          await tester.runAsync(() => shot.prepare!(container, ctx));
          await settle();
        }
        var scope = find.byKey(ValueKey(shot.route));
        var name = shot.route.name;
        if (shot.dialog != null) {
          shot.dialog!(ctx);
          await settle();
          final top = find.byWidgetPredicate((w) => w is EDialog || w is EDrawer);
          if (top.evaluate().isNotEmpty) {
            scope = top.last;
            name = shot.id;
          }
        } else if (container.read(deskTourProvider).open) {
          scope = find.byType(DeskTourOverlay);
          name = shot.id;
        }
        api.calls.clear();
        return (api, folders, container, scope, name);
      }

      final (_, _, _, pageScope, pageName) = await open();
      final scopes = [(pageScope, pageName), if (pageName == shot.route.name && !shot.route.bare) (find.byType(DeskShell), 'shell')];
      final pageIds = <String>{};
      final todo = <(String, String, String, int)>[]; // scope name, kind, label, nth of that kind+label
      for (final (scope, name) in scopes) {
        final seen = <String, int>{};
        for (final c in _controls(scope)) {
          final id = '${c.kind}|${c.label}';
          final n = seen[id] = (seen[id] ?? -1) + 1;
          // The page sits inside the shell: its controls count once, as the page's.
          if (name != 'shell') {
            pageIds.add(id);
          } else if (pageIds.contains(id)) {
            continue;
          }
          if (_pressed.add('$name|$id|$n')) todo.add((name, c.kind, c.label, n));
        }
      }

      final dead = <String>[];
      for (final (name, kind, label, n) in todo) {
        final (api, folders, container, scope, _) = await open();
        final search = name == 'shell' ? find.byType(DeskShell) : scope;
        final matches = _controls(search).where((c) => c.kind == kind && c.label == label).toList();
        if (matches.length <= n) continue; // Gone on a fresh open (a timed state).
        final before = _shown();
        final at = container.read(deskNavProvider);
        final tour = container.read(deskTourProvider);
        final settings = container.read(deskProvider).settings;
        final prefs = container.read(settingsPrefsProvider);
        final routes = <Route<dynamic>>[];
        deskNavigatorKey.currentState?.popUntil((r) {
          routes.add(r);
          return true;
        });
        final copies = clipboard.length;
        final node = container.read(deskNodeProvider);
        final nodeCalls = node is MockDeskNode ? node.calls.length : 0;

        // Not awaited: a press that opens a dialog completes when it closes.
        matches[n].press();
        await settle();

        final acts = api.calls.where((c) => !_reads.contains(c)).toSet();
        final stub = acts.intersection(_stubbed);
        final toasted = find.byType(SnackBar).evaluate().isNotEmpty;
        if (toasted) ScaffoldMessenger.of(tester.element(find.byType(SnackBar).first)).clearSnackBars();
        await settle();
        final top = <Route<dynamic>>[];
        deskNavigatorKey.currentState?.popUntil((r) {
          top.add(r);
          return true;
        });
        final changed =
            acts.isNotEmpty ||
            (node is MockDeskNode && node.calls.length != nodeCalls) ||
            container.read(deskNavProvider) != at ||
            container.read(deskTourProvider) != tour ||
            container.read(deskProvider).settings != settings ||
            container.read(settingsPrefsProvider) != prefs ||
            folders.isNotEmpty ||
            clipboard.length != copies ||
            top.length != routes.length ||
            _shown() != before;
        final key = '$name|$label';
        final what = '${shot.id}: $kind "$label" ($key)';
        if (_allowed.keys.any((r) => r.hasMatch(key))) {
          // Allowed, with its reason.
        } else if (stub.isNotEmpty) {
          dead.add('$what reaches ${stub.join(', ')}, which the real wallet does not implement');
        } else if (!changed) {
          dead.add('$what ${toasted ? 'only shows a toast' : 'does nothing'}');
        }
        // Toasts and mock timers end before the next fresh app.
        await tester.pump(const Duration(seconds: 6));
      }
      failures.addAll(dead);
      expect(dead, isEmpty, reason: dead.join('\n'));
      await tester.pumpWidget(const SizedBox());
      // Copy phrase clears the clipboard after 30 s.
      await tester.pump(const Duration(seconds: 40));
    });
  }
}
