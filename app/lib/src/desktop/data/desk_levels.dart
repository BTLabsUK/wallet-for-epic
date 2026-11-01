// SPDX-License-Identifier: Apache-2.0
/// Wallet levels on the desktop: the phone's model (`levels/`) bound to the desktop's settings.
/// The level is the same `app.level` key, read by [walletLevelProvider]; the matrix is
/// [LevelFeatures] with the desktop's stored Advanced prefs; [DeskLevelFeatures] adds the few
/// rows only the desktop has (Set up's server steps, the wallet switcher, the built-in node,
/// where Recheck balance and Hide amounts live). Presentation only: a level never changes
/// wallet data, and only an explicit pick writes a setting ([DeskLevelControl.setLevel]).
///
/// Names the UI uses: Shallow (1), Deeper (2), Deep end (3).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../advanced.dart';
import '../../levels/first_start.dart';
import '../../levels/level_features.dart';
import '../../levels/level_providers.dart';
import '../../levels/wallet_level.dart';
import '../../log.dart';
import '../../providers.dart' show secretStoreProvider;
import '../../secret_store_api.dart';
import 'desk_first_run_servers.dart';
import '../../tor_build.dart';
import 'state.dart';

/// The keys only a desktop install from before levels holds (`desk_store.dart`): any one
/// present settles the level to [existingInstallLevel], never asked.
const List<String> deskExistingInstallMarkers = [
  'desk.settings',
  'desk.prefs',
  'desk.nodes',
  'desk.window',
  'desk.tor_switch',
  'desk.autostart',
  'desk.wallet.mainnet',
  'desk.wallet.floonet',
  'desk.wallet.usernet',
];

/// New and additive: 'show' while an install that updated into levels has not dismissed the
/// one notice about them, 'seen' after.
const String deskLevelNewsKey = 'desk.level_news';

/// At launch, before the settings open and before any request ([holdUntilFirstStart] with the
/// desktop's markers). An existing install settling into levels now also gets the one notice.
Future<bool> deskHoldUntilFirstStart(SecretStore store) async {
  try {
    if (LevelChoice.decode(await store.read(levelKey)) == null) {
      for (final k in deskExistingInstallMarkers) {
        if (await store.read(k) != null) {
          await store.write(deskLevelNewsKey, 'show');
          break;
        }
      }
    }
  } on Object catch (e) {
    logWarn('levels', 'level news not read: ${e.runtimeType}');
  }
  return holdUntilFirstStart(store, markers: deskExistingInstallMarkers);
}

/// A level given at build time (`--dart-define=WFE_DESK_LEVEL=1|2|3`): the tour, screenshots
/// and the web preview show that level whatever is stored.
const int _forcedLevel = int.fromEnvironment('WFE_DESK_LEVEL');

/// The level the desktop shows: the stored one ([currentLevelProvider], Deep end while loading
/// or still to answer), or the build's [_forcedLevel]. Tests override it.
final deskLevelProvider = Provider<WalletLevel>(
  (ref) => WalletLevel.ofNumber(_forcedLevel) ?? ref.watch(currentLevelProvider),
);

/// The shared matrix row with the desktop's stored Advanced prefs.
final deskLevelFeaturesProvider = Provider<LevelFeatures>((ref) {
  final level = ref.watch(deskLevelProvider);
  final stored = ref.watch(deskProvider.select((s) => s.settings.advanced));
  return LevelFeatures.of(level, stored, torBuilt: torBuilt);
});

/// The desktop-only rows on top of [LevelFeatures].
final deskLevelUiProvider = Provider<DeskLevelFeatures>((ref) {
  final level = ref.watch(deskLevelProvider);
  final wallets = ref.watch(deskProvider.select((s) => s.wallets?.length ?? 0));
  final stored = ref.watch(deskProvider.select((s) => s.settings.advanced));
  return DeskLevelFeatures.of(level, prefs: stored, wallets: wallets);
});

/// What only the desktop decides per level (the decision page's "hides, keeps and moves").
class DeskLevelFeatures {
  const DeskLevelFeatures._({
    required this.level,
    required this.setupWizard,
    required this.walletSwitcher,
    required this.addWallet,
    required this.nodeSettings,
    required this.builtInNode,
    required this.recheckInSideList,
    required this.hideAmountsInHeader,
    required this.heroSentence,
    required this.casualWords,
    required this.sendReviewStep,
    required this.fileTransfer,
    required this.outputsPage,
    required this.invoicesPage,
    required this.pairingPages,
  });

  factory DeskLevelFeatures.of(WalletLevel level, {required AdvancedPrefs prefs, int wallets = 1}) {
    final shallow = level == WalletLevel.justSendReceive;
    final deep = level == WalletLevel.everything;
    return DeskLevelFeatures._(
      level: level,
      setupWizard: !shallow,
      walletSwitcher: !shallow || wallets > 1,
      addWallet: !shallow,
      nodeSettings: !shallow,
      builtInNode: deep,
      recheckInSideList: !shallow,
      hideAmountsInHeader: !shallow,
      heroSentence: shallow,
      casualWords: level == WalletLevel.casual,
      sendReviewStep: !shallow,
      fileTransfer: !shallow,
      outputsPage: deep && prefs.has(AdvancedFeature.outputs),
      invoicesPage: deep && prefs.invoicesOn,
      pairingPages: deep,
    );
  }

  final WalletLevel level;

  bool get shallow => level == WalletLevel.justSendReceive;

  /// Set up (Preferences · Node · Epicbox · Review) after the recovery phrase. Shallow skips it
  /// and saves its defaults: the node and Epicbox are automatic, the language was on Welcome.
  final bool setupWizard;

  /// The title bar's wallet menu (chevron, other wallets). Shallow shows the name alone,
  /// unless a second wallet already exists (made at a deeper level).
  final bool walletSwitcher;

  /// Add a wallet, Settings › All wallets, Unlock's Add a wallet.
  final bool addWallet;

  /// Settings › Node (the node picker and the failover line). Shallow: automatic.
  final bool nodeSettings;

  /// The built-in (local) node: Deep end only, as today behind its Advanced switch.
  final bool builtInNode;

  /// Recheck balance in the Settings side list; Shallow has it as a row in This wallet.
  final bool recheckInSideList;

  /// The hide-amounts eye in the page header; Shallow has it under Appearance.
  final bool hideAmountsInHeader;

  /// Overview's hero is one number and one sentence, no tiles.
  final bool heroSentence;

  /// Deeper's casual words on tiles, methods, file rows and steps.
  final bool casualWords;

  /// Send has its Review step; Shallow's Summary button is the Send.
  final bool sendReviewStep;

  /// File Transfer (Send's Direct · File, Receive's payment files, its switch).
  final bool fileTransfer;

  /// Outputs on the rail: Deep end with its switch.
  final bool outputsPage;

  /// Invoices on the rail and in Settings: Deep end with its switch.
  final bool invoicesPage;

  /// Pairing rows and Pair flows in Contacts: Deep end with its switch.
  final bool pairingPages;
}

/// The level's writes: an explicit pick, the first-start answer, the one notice.
final deskLevelControlProvider = Provider<DeskLevelControl>(DeskLevelControl.new);

class DeskLevelControl {
  DeskLevelControl(this._ref);

  final Ref _ref;

  /// The user picked [level] (Welcome's dial, Change level): stored, then its preset applied to
  /// the desktop's Advanced prefs when it changes them (Deep end turns the shown features on).
  Future<void> setLevel(WalletLevel level) async {
    await _ref.read(walletLevelProvider.notifier).store(level);
    final desk = _ref.read(deskProvider.notifier);
    final s = _ref.read(deskProvider).settings;
    final preset = levelPreset(level, s.advanced);
    if (preset != s.advanced) await desk.saveSettings(s.copyWith(advanced: preset));
  }

  /// Welcome's dial answered (Create, Import or Restore pressed): the level, Tor only when
  /// [undercover] (Tor builds), and only then the gate opens.
  Future<void> completeFirstStart(WalletLevel level, {bool undercover = false}) =>
      _ref.read(firstStartProvider.notifier).completeWith(
        level: level,
        undercover: undercover,
        torOnly: () async {
          final s = _ref.read(deskProvider).settings;
          await _ref.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: s.advanced.withMode(NetworkMode.torOnly)));
        },
        setLevel: setLevel,
        pickServers: () => deskFirstRunServers(_ref),
      );
}

/// Whether the one notice about levels shows (an install that updated into them).
final deskLevelNewsProvider = AsyncNotifierProvider<DeskLevelNews, bool>(DeskLevelNews.new);

class DeskLevelNews extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      return await ref.read(secretStoreProvider).read(deskLevelNewsKey) == 'show';
    } on Object {
      return false;
    }
  }

  /// Have a look or OK: never again.
  Future<void> dismiss() async {
    state = const AsyncData(false);
    try {
      await ref.read(secretStoreProvider).write(deskLevelNewsKey, 'seen');
    } on Object catch (e) {
      logWarn('levels', 'level news not saved: ${e.runtimeType}');
    }
  }
}
