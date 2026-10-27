/// The desktop UI's saved state: settings, the settings screens' choices, own nodes and the
/// wallet's name. Not secret, but kept in the app's [SecretStore], as the phone keeps its
/// preferences (`settings.dart`), so the app needs no preferences dependency.
library;

import '../../advanced.dart';
import '../../payment_prefs.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../log.dart';
import '../../l10n.dart' show appLanguages;
import '../../secret_store_api.dart';
import '../../server_list.dart' show ServerKind, ServerList;
import '../../settings.dart' show autoLockChoice;
import 'models.dart';

class DeskStore {
  const DeskStore(this._secrets);

  final SecretStore _secrets;

  static const settingsKey = 'desk.settings';
  static const prefsKey = 'desk.prefs';
  static const nodesKey = 'desk.nodes';
  static const favouritesKey = 'desk.favourites';

  /// The wallet of [chain]: name, creation time, whether a scan is due. The first wallet's
  /// key; a wallet added later has [walletMetaKey].
  static String walletKey(String chain) => 'desk.wallet.$chain';

  /// [walletKey] of the wallet with registry [walletId]: unchanged for the first wallet (null).
  static String walletMetaKey(String chain, String? walletId) =>
      walletId == null ? walletKey(chain) : 'desk.wallet.$chain.$walletId';

  /// [favouritesKey] of the wallet with registry [walletId]: unchanged for the first wallet.
  static String favouritesKeyOf(String? walletId) => walletId == null ? favouritesKey : '$favouritesKey.$walletId';

  /// The HTTP listener's settings of the wallet with registry [walletId]: reach, port and
  /// Start with the wallet. The first wallet (null) keeps them where 0.1.0 wrote them
  /// ([settingsKey], [prefsKey]); an added wallet has its own key.
  static const httpKey = 'desk.http';
  static String httpKeyOf(String? walletId) => '$httpKey.$walletId';

  /// Whether Tor is on for the wallet with registry [walletId]; off unless set. The first
  /// wallet (null) has [torKey], an added one its own key.
  static const torKey = 'desk.tor';
  static String torKeyOf(String? walletId) => walletId == null ? torKey : '$torKey.$walletId';

  Future<bool> torOn(String? walletId) async {
    final j = await readJson(torKeyOf(walletId));
    return j is Map<String, dynamic> && j['on'] == true;
  }

  Future<void> saveTorOn(String? walletId, bool on) => writeJson(torKeyOf(walletId), {'on': on});

  /// The one Tor switch (Settings › Privacy), app-wide: every wallet opens with it. Null until
  /// first set; a wallet then keeps its own older choice ([autostart]'s `tor`).
  static const torSwitchKey = 'desk.tor_switch';

  Future<bool?> torSwitch() async {
    final j = await readJson(torSwitchKey);
    return j is Map<String, dynamic> && j['on'] is bool ? j['on'] as bool : null;
  }

  Future<void> saveTorSwitch(bool on) => writeJson(torSwitchKey, {'on': on});

  /// The Outputs choices of the wallet with registry [walletId] (strategy, SmartOutputs);
  /// [OutputPrefs]' defaults unless set. The first wallet (null) has [outputsKey].
  static const outputsKey = 'desk.outputs';
  static String outputsKeyOf(String? walletId) => walletId == null ? outputsKey : '$outputsKey.$walletId';

  Future<OutputPrefs> outputPrefs(String? walletId) async {
    const d = OutputPrefs();
    final j = await readJson(outputsKeyOf(walletId));
    if (j is! Map<String, dynamic>) return d;
    final strategy = SelectionStrategy.values.asNameMap()[j['strategy']];
    final smart = j['smartOutputs'];
    return OutputPrefs(strategy: strategy ?? d.strategy, smartOutputs: smart is bool ? smart : d.smartOutputs);
  }

  Future<void> saveOutputPrefs(String? walletId, OutputPrefs p) =>
      writeJson(outputsKeyOf(walletId), {'strategy': p.strategy.name, 'smartOutputs': p.smartOutputs});

  /// Start with the wallet for Epicbox and Tor, per wallet (W4 §3.2). The first wallet (null)
  /// has [autostartKey], an added one its own key.
  static const autostartKey = 'desk.autostart';
  static String autostartKeyOf(String? walletId) => walletId == null ? autostartKey : '$autostartKey.$walletId';

  /// The wallet's Epicbox and Tor autostart. Never saved yet: Epicbox takes the 0.1.0 app-wide
  /// `epicboxOnStart` choice (on unless turned off) and Tor the wallet's [torOn] (a wallet
  /// that had Tor on keeps starting it), and that is saved so the choice is the wallet's own
  /// from then on.
  Future<AutostartPrefs> autostart(String? walletId) async {
    final j = await readJson(autostartKeyOf(walletId));
    if (j is Map<String, dynamic>) {
      return AutostartPrefs(
        epicbox: j['epicbox'] is bool ? j['epicbox'] as bool : true,
        tor: j['tor'] is bool ? j['tor'] as bool : false,
      );
    }
    final prefs = await readJson(prefsKey);
    final onStart = prefs is Map<String, dynamic> ? prefs['epicboxOnStart'] : null;
    final migrated = AutostartPrefs(epicbox: onStart is bool ? onStart : true, tor: await torOn(walletId));
    await saveAutostart(walletId, migrated);
    return migrated;
  }

  Future<void> saveAutostart(String? walletId, AutostartPrefs p) =>
      writeJson(autostartKeyOf(walletId), {'epicbox': p.epicbox, 'tor': p.tor});

  Future<HttpPrefs> httpPrefs(String? walletId) async {
    const d = HttpPrefs();
    if (walletId != null) {
      final j = await readJson(httpKeyOf(walletId));
      return j is Map<String, dynamic> ? _httpPrefsFromJson(j, d) : d;
    }
    final settings = await readJson(settingsKey);
    final prefs = await readJson(prefsKey);
    final fromSettings = settings is Map<String, dynamic>
        ? _httpPrefsFromJson(settings, d)
        : d;
    final autostart = prefs is Map<String, dynamic>
        ? prefs['httpAutostart']
        : null;
    return HttpPrefs(
      publicMode: fromSettings.publicMode,
      port: fromSettings.port,
      autostart: autostart is bool ? autostart : d.autostart,
    );
  }

  Future<void> saveHttpPrefs(String? walletId, HttpPrefs p) async {
    if (walletId != null) {
      return writeJson(httpKeyOf(walletId), {
        'publicMode': p.publicMode,
        'httpPort': p.port,
        'autostart': p.autostart,
      });
    }
    final settings = await readJson(settingsKey);
    final prefs = await readJson(prefsKey);
    await writeJson(settingsKey, {
      ...?(settings is Map<String, dynamic> ? settings : null),
      'publicMode': p.publicMode,
      'httpPort': p.port,
    });
    await writeJson(prefsKey, {
      ...?(prefs is Map<String, dynamic> ? prefs : null),
      'httpAutostart': p.autostart,
    });
  }

  /// The Node or Epicbox list ([ServerList]) of [chain], as `ServerList.encode()` writes it;
  /// null before its first use (the panel seeds it then).
  static String serverListKey(ServerKind kind, String chain) => 'desk.serverList.${kind.name}.$chain';

  Future<ServerList?> serverList(ServerKind kind, String chain) async => ServerList.decode(await _secrets.read(serverListKey(kind, chain)));

  Future<void> saveServerList(ServerKind kind, String chain, ServerList list) => _secrets.write(serverListKey(kind, chain), list.encode());

  Future<Object?> readJson(String key) async {
    final text = await _secrets.read(key);
    if (text == null) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      logWarn('desk', 'saved $key is not JSON; using defaults');
      return null;
    }
  }

  Future<void> writeJson(String key, Object? value) => _secrets.write(key, jsonEncode(value));

  Future<void> delete(String key) => _secrets.delete(key);

  Future<DeskSettings> settings() async {
    final json = await readJson(settingsKey);
    return json is Map<String, dynamic> ? deskSettingsFromJson(json) : const DeskSettings();
  }

  /// The app-wide settings. The HTTP reach and port belong to the open wallet ([saveHttpPrefs]),
  /// so what is saved for the first wallet stays as it is. [DeskSettings.tourSeen], once saved,
  /// stays: Show the tour opens it without clearing the flag, so a false here is a stale copy.
  Future<void> saveSettings(DeskSettings s) async {
    final saved = await settings();
    if (saved.tourSeen && !s.tourSeen) logDebug('desk', 'settings save kept tourSeen=true over a stale false');
    await writeJson(
      settingsKey,
      deskSettingsToJson(
        s.copyWith(
          publicMode: saved.publicMode,
          httpPort: saved.httpPort,
          tourSeen: s.tourSeen || saved.tourSeen,
          importWarningSeen: s.importWarningSeen || saved.importWarningSeen,
        ),
      ),
    );
  }

  /// Saves [DeskSettings.tourSeen] alone, over what is stored now.
  Future<void> saveTourSeen() => _saveFlag('tourSeen');

  /// Saves [DeskSettings.importWarningSeen] alone, over what is stored now.
  Future<void> saveImportWarningSeen() => _saveFlag('importWarningSeen');

  Future<void> _saveFlag(String key) async {
    final json = await readJson(settingsKey);
    await writeJson(settingsKey, {...?(json is Map<String, dynamic> ? json : null), key: true});
  }

  /// The settings screens' choices ([SettingsPrefs.toJson]); Start HTTP with the wallet is the
  /// open wallet's ([saveHttpPrefs]), so the saved one stays.
  Future<void> savePrefs(Map<String, Object?> json) async {
    final saved = await readJson(prefsKey);
    final autostart = saved is Map<String, dynamic> ? saved['httpAutostart'] : null;
    await writeJson(prefsKey, {...json, 'httpAutostart': ?autostart});
  }
}

/// A wallet's Start with the wallet for Epicbox and Tor (HTTP's is in [HttpPrefs]).
@immutable
class AutostartPrefs {
  const AutostartPrefs({this.epicbox = true, this.tor = false});

  final bool epicbox;
  final bool tor;

  @override
  bool operator ==(Object other) => other is AutostartPrefs && other.epicbox == epicbox && other.tor == tor;

  @override
  int get hashCode => Object.hash(epicbox, tor);
}

/// A wallet's HTTP listener settings.
@immutable
class HttpPrefs {
  const HttpPrefs({this.publicMode = false, this.port = 3415, this.autostart = false});

  final bool publicMode;
  final int port;
  final bool autostart;

  @override
  bool operator ==(Object other) => other is HttpPrefs && other.publicMode == publicMode && other.port == port && other.autostart == autostart;

  @override
  int get hashCode => Object.hash(publicMode, port, autostart);
}

HttpPrefs _httpPrefsFromJson(Map<String, dynamic> j, HttpPrefs d) {
  final port = j['httpPort'];
  final public = j['publicMode'];
  final auto = j['autostart'];
  return HttpPrefs(
    publicMode: public is bool ? public : d.publicMode,
    port: port is int && port > 0 && port < 65536 ? port : d.port,
    autostart: auto is bool ? auto : d.autostart,
  );
}

Map<String, Object?> deskSettingsToJson(DeskSettings s) => {
  'theme': s.theme.name,
  'scale': s.scale,
  'language': s.language,
  'helpLanguage': s.helpLanguage,
  'hideAmounts': s.hideAmounts,
  'newLookSeen': s.newLookSeen,
  'internetGuideSeen': s.internetGuideSeen,
  'tourSeen': s.tourSeen,
  'importWarningSeen': s.importWarningSeen,
  'useStatusSite': s.useStatusSite,
  'autoLock': s.autoLockMinutes,
  'autoLockOn': s.autoLockOn,
  'publicMode': s.publicMode,
  'httpPort': s.httpPort,
  'advanced': s.advanced.toJson(),
  'payments': s.payments.toJson(),
  if (s.pairingSeenAs.isNotEmpty) 'pairingSeenAs': s.pairingSeenAs,
  if (s.pairingClipSeen.isNotEmpty) 'pairingClipSeen': s.pairingClipSeen,
};

/// Each value of the wrong type falls back to its default, so bad saved data cannot block
/// startup.
DeskSettings deskSettingsFromJson(Map<String, dynamic> j) {
  const d = DeskSettings();
  final scale = j['scale'];
  final hide = j['hideAmounts'];
  final language = j['language'];
  final helpLanguage = j['helpLanguage'];
  final seen = j['newLookSeen'];
  final guide = j['internetGuideSeen'];
  final tour = j['tourSeen'];
  final importWarned = j['importWarningSeen'];
  final site = j['useStatusSite'];
  // The key before 26.10.13 held a value nothing read: it is not taken over.
  final lock = j['autoLock'];
  final lockOn = j['autoLockOn'];
  final public = j['publicMode'];
  final port = j['httpPort'];
  final seenAs = j['pairingSeenAs'];
  final clipSeen = j['pairingClipSeen'];
  return DeskSettings(
    pairingSeenAs: seenAs is String ? seenAs.trim() : d.pairingSeenAs,
    pairingClipSeen: clipSeen is String ? clipSeen : d.pairingClipSeen,
    theme: ThemeChoice.values.where((t) => t.name == j['theme']).firstOrNull ?? d.theme,
    scale: scale is int && deskScales.contains(scale) ? scale : d.scale,
    language: language is String && appLanguages.any((a) => a.code == language) ? language : null,
    helpLanguage: helpLanguage is String && appLanguages.any((a) => a.code == helpLanguage) ? helpLanguage : null,
    hideAmounts: hide is bool ? hide : d.hideAmounts,
    newLookSeen: seen is bool ? seen : d.newLookSeen,
    internetGuideSeen: guide is bool ? guide : d.internetGuideSeen,
    tourSeen: tour is bool ? tour : d.tourSeen,
    importWarningSeen: importWarned is bool ? importWarned : d.importWarningSeen,
    useStatusSite: site is bool ? site : d.useStatusSite,
    publicMode: public is bool ? public : d.publicMode,
    advanced: AdvancedPrefs.fromJson(j['advanced']),
    // Direct was Advanced's "Direct receiving" switch before 26.10.13.
    payments: PaymentPrefs.fromJson(
      j['payments'],
      legacyDirect: switch (j['advanced']) {
        {'features': final List<Object?> f} => f.contains('directReceiving'),
        _ => false,
      },
    ),
    httpPort: port is int && port > 0 && port < 65536 ? port : d.httpPort,
    autoLockMinutes: lock is int ? autoLockChoice(lock) : d.autoLockMinutes,
    autoLockOn: lockOn is bool ? lockOn : d.autoLockOn,
  );
}

/// What the app read before its first frame, so theme and scale apply on the first screen.
@immutable
class DeskBoot {
  const DeskBoot({this.settings = const DeskSettings(), this.prefs});

  final DeskSettings settings;

  /// The settings screens' saved choices (`prefs.dart`), as JSON.
  final Map<String, dynamic>? prefs;

  static Future<DeskBoot> load(DeskStore store) async {
    final prefs = await store.readJson(DeskStore.prefsKey);
    final settings = await store.settings();
    logDebug('desk', 'settings read at start: tourSeen=${settings.tourSeen}');
    return DeskBoot(settings: settings, prefs: prefs is Map<String, dynamic> ? prefs : null);
  }
}

/// Where the desktop UI saves; null (the mock, the tests) saves nothing.
final deskStoreProvider = Provider<DeskStore?>((ref) => null);

final deskBootProvider = Provider<DeskBoot>((ref) => const DeskBoot());
