// SPDX-License-Identifier: Apache-2.0
// The settings a history backup carries (backup_settings.dart): the planner's rule (a fresh
// install's value is taken, a value the user changed is asked about), settings.toml's lists and
// switches (in order; as they are where no other wallet shares them, one question where one
// does), the safety rules (a local node is never made the node in use, a less strict network
// mode is asked about), what is skipped, and the mapping between the phone and the desktop.
import 'dart:convert';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/backup_settings.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/server_list.dart';
import 'package:flutter_test/flutter_test.dart';

const _defaultNode = 'https://node.epic.invalid:3413';
const _defaultBox = 'box.epic.invalid';

/// The servers part of a map: [nodes] and [boxes] in order.
Map<String, Object?> _servers({List<String> nodes = const [_defaultNode], List<String> boxes = const [_defaultBox]}) => {
  BackupKey.servers: {BackupKey.node: nodes, BackupKey.epicbox: boxes},
};

/// The switches part of a map.
Map<String, Object?> _online({bool site = true, bool update = true, bool price = true}) => {
  BackupKey.online: {BackupKey.statusSite: site, BackupKey.updateCheck: update, BackupKey.price: price},
};

/// A map as either app writes it; [over] replaces keys.
Map<String, Object?> _map(BackupPlatform from, [Map<String, Object?> over = const {}]) => {
  BackupKey.v: backupSettingsVersion,
  BackupKey.from: from.name,
  BackupKey.theme: from == BackupPlatform.mobile ? 'system' : 'dark',
  BackupKey.language: null,
  BackupKey.helpLanguage: null,
  BackupKey.hideBalances: false,
  BackupKey.autoLock: 15,
  BackupKey.advanced: AdvancedPrefs.none.toJson(),
  BackupKey.payments: (from == BackupPlatform.mobile ? PaymentPrefs.phoneDefaults : PaymentPrefs.defaults).toJson(),
  BackupKey.sendStrategy: 'smallest',
  BackupKey.splitChange: true,
  if (from == BackupPlatform.mobile) BackupKey.fiat: 'usd',
  if (from == BackupPlatform.mobile) BackupKey.showFiat: true,
  BackupKey.tor: false,
  BackupKey.seenAs: '',
  ..._servers(),
  ..._online(),
  if (from == BackupPlatform.desktop)
    BackupKey.desktop: {
      BackupKey.invoiceExpiry: 86400,
      BackupKey.seedsDeleted: <Object?>[],
      BackupKey.epicboxAutostart: true,
    },
  ...over,
};

/// Plans [file] (JSON-encoded and read back, as the sealed file gives it) for [here].
BackupSettingsPlan _plan(
  Object? file, {
  BackupPlatform here = BackupPlatform.mobile,
  Map<String, Object?> mine = const {},
  bool shared = false,
  String? fileName,
  String? myName,
}) => planBackupSettings(
  here: here,
  mine: _map(here, mine),
  defaults: _map(here),
  file: file is Map ? jsonDecode(jsonEncode(file)) : file,
  sharedServers: shared,
  fileWalletName: fileName,
  myWalletName: myName,
);

Set<String> _keys(List<BackupSettingItem> items) => {for (final i in items) i.key};

void main() {
  group('the rule', () {
    test('a fresh install takes every setting the file changed, without asking', () {
      final plan = _plan(_map(BackupPlatform.mobile, {
        BackupKey.theme: 'dark',
        BackupKey.language: 'pl',
        BackupKey.autoLock: BackupKey.never,
        BackupKey.payments: PaymentPrefs.phoneDefaults.copyWith(linkTor: true).toJson(),
        BackupKey.sendStrategy: 'all',
        BackupKey.seenAs: 'Alice',
        BackupKey.tor: true,
      }));
      expect(plan.conflicts, isEmpty);
      expect(_keys(plan.take), {
        BackupItem.theme,
        BackupItem.language,
        BackupItem.autoLock,
        BackupItem.payments,
        BackupItem.sendStrategy,
        BackupItem.seenAs,
        BackupItem.tor,
      });
      final v = plan.values(takeConflicts: false);
      expect(v[BackupItem.autoLock], BackupKey.never);
      expect(PaymentPrefs.fromJson(v[BackupItem.payments]).linkTor, isTrue);
    });

    test('a setting the user changed and the file has otherwise is a conflict; the same value is nothing', () {
      final file = _map(BackupPlatform.mobile, {BackupKey.theme: 'dark', BackupKey.hideBalances: true});
      final plan = _plan(file, mine: {BackupKey.theme: 'light', BackupKey.hideBalances: true});
      expect(_keys(plan.conflicts), {BackupItem.theme});
      expect(plan.take, isEmpty);
      expect(plan.values(takeConflicts: false), isEmpty);
      expect(plan.values(takeConflicts: true), {BackupItem.theme: 'dark'});
      expect(plan.conflicts.single.mine, 'light');
    });

    test('a file that changes nothing plans nothing', () {
      expect(_plan(_map(BackupPlatform.mobile)).isEmpty, isTrue);
    });

    test('the network mode: a less strict mode than the user\'s is asked about, a stricter one over the default is taken', () {
      Map<String, Object?> mode(NetworkMode m) => {BackupKey.advanced: AdvancedPrefs.none.withMode(m).toJson()};
      final relax = _plan(_map(BackupPlatform.mobile, mode(NetworkMode.standard)), mine: mode(NetworkMode.torOnly));
      expect(_keys(relax.conflicts), {BackupItem.networkMode});
      expect(relax.values(takeConflicts: false), isEmpty);
      final stricter = _plan(_map(BackupPlatform.mobile, mode(NetworkMode.torOnly)));
      expect(stricter.values(takeConflicts: false), {BackupItem.networkMode: 'torOnly'});
      final other = _plan(_map(BackupPlatform.mobile, mode(NetworkMode.torOnly)), mine: mode(NetworkMode.nodeOnly));
      expect(_keys(other.conflicts), {BackupItem.networkMode});
    });

    test('an older file\'s Offline is Node only; Kill switch and Node only travel as they are', () {
      final old = _plan(_map(BackupPlatform.mobile, {BackupKey.advanced: {'features': <String>[], 'networkMode': 'offline'}}));
      expect(old.values(takeConflicts: false), {BackupItem.networkMode: 'nodeOnly'});
      expect(advancedFromBackup(AdvancedPrefs.none, old.values(takeConflicts: false)).networkMode, NetworkMode.nodeOnly);
      for (final m in [NetworkMode.nodeOnly, NetworkMode.killSwitch]) {
        final plan = _plan(_map(BackupPlatform.desktop, {BackupKey.advanced: AdvancedPrefs.none.withMode(m).toJson()}));
        expect(advancedFromBackup(AdvancedPrefs.none, plan.values(takeConflicts: false)).networkMode, m);
      }
    });

    test('the Advanced parts are planned apart: a feature conflict does not hold back the mode', () {
      final file = _map(BackupPlatform.mobile, {
        BackupKey.advanced: AdvancedPrefs(features: {AdvancedFeature.logs}, networkMode: NetworkMode.torOnly).toJson(),
      });
      final plan = _plan(file, mine: {BackupKey.advanced: AdvancedPrefs(features: {AdvancedFeature.outputs}).toJson()});
      expect(_keys(plan.conflicts), {BackupItem.features});
      expect(_keys(plan.take), {BackupItem.networkMode});
      final next = advancedFromBackup(AdvancedPrefs(features: {AdvancedFeature.outputs}), plan.values(takeConflicts: false));
      expect(next, AdvancedPrefs(features: {AdvancedFeature.outputs}, networkMode: NetworkMode.torOnly));
      // Linked devices stays as this install has it (on by default).
      expect(advancedFromBackup(AdvancedPrefs.none, plan.values(takeConflicts: true)).features, {AdvancedFeature.logs, AdvancedFeature.linkedDevices});
    });
  });

  group('servers and switches', () {
    const lab = 'https://node.lab.invalid';
    const net = 'https://node.net.invalid:3413';

    test('no other wallet here: the file\'s lists and switches are taken as they are', () {
      final plan = _plan(_map(BackupPlatform.mobile, {
        ..._servers(nodes: [lab, _defaultNode], boxes: ['box.stack.invalid', _defaultBox]),
        ..._online(site: false, price: false),
      }));
      expect(plan.conflicts, isEmpty);
      expect(plan.servers, isEmpty);
      expect(plan.values(takeConflicts: false), {
        BackupItem.nodeServers: [lab, _defaultNode],
        BackupItem.epicboxServers: ['box.stack.invalid', _defaultBox],
        BackupItem.statusSite: false,
        BackupItem.price: false,
      });
      // A switch the user changed here is taken too: the fresh-install rule.
      final changed = _plan(_map(BackupPlatform.mobile, _online(site: true)), mine: _online(site: false));
      expect(changed.values(takeConflicts: false), {BackupItem.statusSite: true});
    });

    test('lists compare in order: the same servers in another order are a change, the same order is none', () {
      final reordered = _plan(_map(BackupPlatform.mobile, _servers(nodes: [lab, _defaultNode])), mine: _servers(nodes: [_defaultNode, lab]));
      expect(reordered.values(takeConflicts: false), {BackupItem.nodeServers: [lab, _defaultNode]});
      expect(_plan(_map(BackupPlatform.mobile, _servers(nodes: [lab, _defaultNode])), mine: _servers(nodes: [lab, _defaultNode])).isEmpty, isTrue);
    });

    test('other wallets here: lists that differ ask once, the switches follow the rule', () {
      final file = _map(BackupPlatform.desktop, {
        ..._servers(nodes: [net, lab], boxes: ['box.net.invalid']),
        ..._online(update: false),
      });
      final plan = _plan(file, here: BackupPlatform.desktop, shared: true);
      expect(plan.asksServers, isTrue);
      expect(_keys(plan.servers), {BackupItem.nodeServers, BackupItem.epicboxServers});
      expect(plan.values(takeConflicts: false), {BackupItem.updateCheck: false}, reason: 'at its default here: taken');
      expect(plan.values(takeConflicts: false, takeServers: true), {
        BackupItem.updateCheck: false,
        BackupItem.nodeServers: [net, lab],
        BackupItem.epicboxServers: ['box.net.invalid'],
      });
      final asked = _plan(_map(BackupPlatform.desktop, _online(price: true)), here: BackupPlatform.desktop, shared: true, mine: _online(price: false));
      expect(_keys(asked.conflicts), {BackupItem.price});
      // The same lists: no question.
      expect(_plan(_map(BackupPlatform.desktop), here: BackupPlatform.desktop, shared: true).isEmpty, isTrue);
    });

    test('a node on this computer, the local network or a tailnet is never made the node in use; it stays in the list', () {
      for (final url in ['http://127.0.0.1:3413', 'http://10.0.1.24:3413', 'http://100.101.2.3:3413', 'http://node.lan:3413', 'http://localhost:3413']) {
        final plan = _plan(_map(BackupPlatform.mobile, _servers(nodes: [url, lab, _defaultNode])));
        expect(_keys(plan.refused), {BackupItem.nodeServers}, reason: url);
        expect(plan.values(takeConflicts: true)[BackupItem.nodeServers], [lab, url, _defaultNode], reason: url);
        // Only such nodes: the list is not taken.
        final only = _plan(_map(BackupPlatform.mobile, _servers(nodes: [url])));
        expect(only.values(takeConflicts: true, takeServers: true), isEmpty, reason: url);
        expect(_keys(only.refused), {BackupItem.nodeServers}, reason: url);
      }
    });

    test('entries that are no server address, repeats and empty lists are dropped', () {
      expect(serverValuesFromJson(ServerKind.relay, ['box.lab.invalid', 'not a server', 42, 'wss://box.stack.invalid/', 'box.lab.invalid']), [
        'box.lab.invalid',
        'box.stack.invalid',
      ]);
      expect(serverValuesFromJson(ServerKind.node, 'x'), isNull);
      final plan = _plan(_map(BackupPlatform.mobile, _servers(nodes: const [], boxes: const ['not a server'])));
      expect(plan.isEmpty, isTrue);
      expect(plan.skipped, containsAll(['servers.node', 'servers.epicbox']));
    });

    test('a version 1 file: its per-chain servers and keyed lists are unknown keys, the rest is read', () {
      final plan = _plan({
        BackupKey.v: 1,
        BackupKey.from: 'mobile',
        BackupKey.theme: 'dark',
        'node': {'mainnet': lab},
        'nodeList': {
          'mainnet': {'entries': [lab], 'removed': <Object?>[]},
        },
        'statusSite': false,
      });
      expect(plan.values(takeConflicts: false), {BackupItem.theme: 'dark'});
      expect(plan.skipped, containsAll(['node', 'nodeList', 'statusSite']));
    });
  });

  group('what is skipped, never thrown', () {
    test('unknown keys and bad values', () {
      final plan = _plan(_map(BackupPlatform.mobile, {
        'push': true,
        'httpPort': 3415,
        BackupKey.theme: 'purple',
        BackupKey.language: 'xx',
        BackupKey.autoLock: 'soon',
        BackupKey.hideBalances: 'yes',
        BackupKey.payments: {'epicbox': false, 'linkHttp': false, 'linkTor': false, 'directQr': false, 'directFile': false},
        BackupKey.online: {BackupKey.statusSite: 'no', 'tor': true},
        BackupKey.seenAs: 'x' * 49,
        BackupKey.advanced: 'torOnly',
      }));
      expect(plan.isEmpty, isTrue);
      expect(plan.skipped, containsAll(['push', 'httpPort', BackupKey.theme, BackupKey.language, BackupKey.autoLock, BackupKey.hideBalances, BackupKey.payments, 'online.status_site', 'online.tor', BackupKey.seenAs, BackupKey.advanced]));
    });

    test('a newer version, no version, an unknown app or no map: nothing is planned', () {
      final changed = _map(BackupPlatform.mobile, {BackupKey.theme: 'dark'});
      for (final file in <Object?>[
        {...changed, BackupKey.v: backupSettingsVersion + 1},
        {...changed}..remove(BackupKey.v),
        {...changed, BackupKey.from: 'watch'},
        null,
        'settings',
        [1, 2],
      ]) {
        final plan = _plan(file);
        expect(plan.isEmpty, isTrue, reason: '$file');
      }
      expect(_plan({...changed, BackupKey.v: backupSettingsVersion + 1}).skipped, [BackupKey.v]);
    });

    test('an auto-lock off the choices becomes the nearest', () {
      expect(_plan(_map(BackupPlatform.mobile, {BackupKey.autoLock: 7})).values(takeConflicts: false), {BackupItem.autoLock: 10});
    });
  });

  group('phone and desktop', () {
    test('a desktop file on the phone: the desktop\'s defaults are no choice, QR Payment and the phone\'s File switch stay', () {
      final file = _map(BackupPlatform.desktop, {
        BackupKey.payments: PaymentPrefs.defaults.copyWith(linkTor: true).toJson(),
        BackupKey.advanced: AdvancedPrefs(features: {AdvancedFeature.outputs, AdvancedFeature.builtInNode}).toJson(),
        BackupKey.autoLock: BackupKey.never,
      });
      final plan = _plan(file, mine: {
        BackupKey.advanced: AdvancedPrefs(features: {AdvancedFeature.transactionFiles}).toJson(),
      });
      final v = plan.values(takeConflicts: true);
      expect(v.containsKey(BackupItem.theme), isFalse, reason: 'dark is the desktop\'s default');
      expect(PaymentPrefs.fromJson(v[BackupItem.payments]), PaymentPrefs.phoneDefaults.copyWith(linkTor: true));
      expect(v[BackupItem.features], ['outputs', 'transactionFiles']);
      expect(v[BackupItem.autoLock], BackupKey.never);
      expect(plan.skipped, contains(BackupKey.desktop), reason: 'the phone has no desktop items');
    });

    test('a phone file on the desktop: no fiat, File only when the phone had it on, a chosen theme', () {
      final file = _map(BackupPlatform.mobile, {
        BackupKey.theme: 'light',
        BackupKey.fiat: 'eur',
        BackupKey.payments: PaymentPrefs.phoneDefaults.copyWith(defaultMethod: MethodKind.directQr, epicbox: false).toJson(),
        BackupKey.splitChange: false,
      });
      final plan = _plan(file, here: BackupPlatform.desktop);
      final v = plan.values(takeConflicts: true);
      expect(v[BackupItem.theme], 'light');
      expect(v.containsKey(BackupItem.fiat), isFalse);
      expect(plan.skipped, containsAll([BackupKey.fiat, BackupKey.showFiat]));
      expect(PaymentPrefs.fromJson(v[BackupItem.payments]), PaymentPrefs.defaults.copyWith(epicbox: false));
      expect(v[BackupItem.splitChange], isFalse);
      expect(_plan(_map(BackupPlatform.mobile), here: BackupPlatform.desktop).isEmpty, isTrue, reason: 'a phone at its defaults changes nothing');
    });

    test('the desktop items: deleted seeds merge, expiry follows the rule; old own nodes and relay are skipped', () {
      final file = _map(BackupPlatform.desktop, {
        BackupKey.desktop: {
          'nodes': [
            {'url': 'https://mine.example:3413', 'label': 'mine'},
          ],
          BackupKey.invoiceExpiry: 999999,
          BackupKey.seedsDeleted: ['btlabs'],
          'ownRelay': 'box.lab.invalid',
          BackupKey.epicboxAutostart: false,
          'publicMode': true,
        },
      });
      final plan = _plan(file, here: BackupPlatform.desktop);
      expect(plan.conflicts, isEmpty);
      final v = plan.values(takeConflicts: false);
      expect(v, {
        BackupItem.invoiceExpiry: maxBackupInvoiceExpirySecs,
        BackupItem.seedsDeleted: ['btlabs'],
        BackupItem.epicboxAutostart: false,
      });
      expect(plan.skipped, containsAll(['desktop.publicMode', 'desktop.nodes', 'desktop.ownRelay']));
    });

    test('the wallet\'s name: replaces one the app gave, is asked about over the user\'s; a given name in the file is none', () {
      expect(_plan(null, here: BackupPlatform.desktop, fileName: 'Savings', myName: 'Wallet 2').values(takeConflicts: false), {BackupItem.walletName: 'Savings'});
      expect(_plan(null, here: BackupPlatform.desktop, fileName: 'Savings', myName: 'Main wallet').take, hasLength(1));
      expect(_keys(_plan(null, here: BackupPlatform.desktop, fileName: 'Savings', myName: 'Daily').conflicts), {BackupItem.walletName});
      expect(_plan(null, here: BackupPlatform.desktop, fileName: 'Wallet 1', myName: 'Daily').isEmpty, isTrue);
      expect(_plan(null, here: BackupPlatform.desktop, fileName: 'Savings', myName: 'Savings').isEmpty, isTrue);
      expect(isDefaultWalletName('Wallet 12'), isTrue);
      expect(isDefaultWalletName('Wallet twelve'), isFalse);
    });
  });
}
