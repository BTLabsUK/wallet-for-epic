// The settings a history backup carries (backup_settings.dart): the planner's rule (a fresh
// install's value is taken, a value the user changed is asked about), the safety rules (a local
// node is never made the node in use, lists only grow, a less strict network mode is asked
// about), what is skipped, and the mapping between the phone and the desktop.
import 'dart:convert';

import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/backup_settings.dart';
import 'package:epic_wallet/src/payment_prefs.dart';
import 'package:epic_wallet/src/server_list.dart';
import 'package:flutter_test/flutter_test.dart';

const _chain = 'mainnet';
const _defaultNode = 'https://node.epiccash.com:3413';

/// A map as either app writes it; [over] replaces keys.
Map<String, Object?> _map(BackupPlatform from, [Map<String, Object?> over = const {}]) => {
  BackupKey.v: backupSettingsVersion,
  BackupKey.from: from.name,
  BackupKey.theme: from == BackupPlatform.mobile ? 'system' : 'dark',
  BackupKey.language: null,
  BackupKey.helpLanguage: null,
  BackupKey.hideBalances: false,
  BackupKey.statusSite: true,
  BackupKey.autoLock: 15,
  BackupKey.advanced: AdvancedPrefs.none.toJson(),
  BackupKey.payments: (from == BackupPlatform.mobile ? PaymentPrefs.phoneDefaults : PaymentPrefs.defaults).toJson(),
  BackupKey.sendStrategy: 'smallest',
  BackupKey.splitChange: true,
  if (from == BackupPlatform.mobile) BackupKey.fiat: 'usd',
  if (from == BackupPlatform.mobile) BackupKey.showFiat: true,
  BackupKey.node: {_chain: _defaultNode},
  BackupKey.relay: {_chain: 'epicbox.epiccash.com'},
  BackupKey.nodeList: {_chain: serverListJson(const ServerList(entries: [_defaultNode]))},
  BackupKey.relayList: {_chain: serverListJson(const ServerList(entries: ['epicbox.epiccash.com']))},
  BackupKey.tor: false,
  BackupKey.seenAs: '',
  if (from == BackupPlatform.desktop)
    BackupKey.desktop: {
      BackupKey.deskNodes: <Object?>[],
      BackupKey.invoiceExpiry: 86400,
      BackupKey.seedsDeleted: <Object?>[],
      BackupKey.ownRelay: null,
      BackupKey.epicboxAutostart: true,
    },
  ...over,
};

/// Plans [file] (JSON-encoded and read back, as the sealed file gives it) for [here].
BackupSettingsPlan _plan(
  Object? file, {
  BackupPlatform here = BackupPlatform.mobile,
  Map<String, Object?> mine = const {},
  String? fileName,
  String? myName,
}) => planBackupSettings(
  here: here,
  chain: _chain,
  mine: _map(here, mine),
  defaults: _map(here),
  file: file is Map ? jsonDecode(jsonEncode(file)) : file,
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
      final other = _plan(_map(BackupPlatform.mobile, mode(NetworkMode.torOnly)), mine: mode(NetworkMode.offline));
      expect(_keys(other.conflicts), {BackupItem.networkMode});
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

  group('servers', () {
    test('a node on this computer, the local network or a tailnet is never made the node in use; its list entry stays', () {
      for (final url in ['http://127.0.0.1:3413', 'http://10.0.1.24:3413', 'http://100.101.2.3:3413', 'http://node.lan:3413', 'http://localhost:3413']) {
        final plan = _plan(_map(BackupPlatform.mobile, {
          BackupKey.node: {_chain: url},
          BackupKey.nodeList: {_chain: serverListJson(ServerList(entries: [_defaultNode, url]))},
        }));
        expect(_keys(plan.refused), {BackupItem.node}, reason: url);
        expect(plan.values(takeConflicts: true).containsKey(BackupItem.node), isFalse, reason: url);
        final list = serverListFromJson(ServerKind.node, plan.values(takeConflicts: false)[BackupItem.nodeList])!;
        expect(list.entries, [_defaultNode, url], reason: url);
      }
    });

    test('a public node and relay are taken over the defaults', () {
      final plan = _plan(_map(BackupPlatform.mobile, {
        BackupKey.node: {_chain: 'https://node.btlabs.uk'},
        BackupKey.relay: {_chain: 'epicbox.stackwallet.com'},
      }));
      expect(plan.values(takeConflicts: false), {BackupItem.node: 'https://node.btlabs.uk', BackupItem.relay: 'epicbox.stackwallet.com'});
      expect(plan.refused, isEmpty);
    });

    test('another chain\'s servers are not read', () {
      final plan = _plan(_map(BackupPlatform.mobile, {
        BackupKey.node: {'floonet': 'https://floo-node.btlabs.uk'},
      }));
      expect(plan.isEmpty, isTrue);
    });

    test('lists merge: the file\'s new entries and removals join, nothing here is dropped', () {
      final mine = ServerList(entries: const ['https://a.example', 'https://b.example'], removed: {serverKeyOf(ServerKind.node, 'https://c.example')});
      final file = ServerList(
        entries: const ['https://b.example', 'https://d.example', 'https://c.example'],
        removed: {serverKeyOf(ServerKind.node, 'https://a.example'), serverKeyOf(ServerKind.node, 'https://e.example')},
      );
      final merged = mergeServerLists(ServerKind.node, mine, file);
      expect(merged.entries, ['https://a.example', 'https://b.example', 'https://d.example']);
      expect(merged.removed, {serverKeyOf(ServerKind.node, 'https://c.example'), serverKeyOf(ServerKind.node, 'https://e.example')});
      final plan = _plan(
        _map(BackupPlatform.mobile, {BackupKey.nodeList: {_chain: serverListJson(file)}}),
        mine: {BackupKey.nodeList: {_chain: serverListJson(mine)}},
      );
      expect(plan.conflicts, isEmpty, reason: 'a list never asks');
      expect(serverListFromJson(ServerKind.node, plan.take.single.backup), merged);
    });

    test('list entries that are no server address are dropped', () {
      final list = serverListFromJson(ServerKind.relay, {
        'entries': ['epicbox.epicnet.us', 'not a server', 42, 'wss://epicbox.stackwallet.com/'],
        'removed': ['x'],
      });
      expect(list!.entries, ['epicbox.epicnet.us', 'epicbox.stackwallet.com']);
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
        BackupKey.node: {_chain: 'ftp://node.example'},
        BackupKey.seenAs: 'x' * 49,
        BackupKey.advanced: 'torOnly',
      }));
      expect(plan.isEmpty, isTrue);
      expect(plan.skipped, containsAll(['push', 'httpPort', BackupKey.theme, BackupKey.language, BackupKey.autoLock, BackupKey.hideBalances, BackupKey.payments, BackupKey.node, BackupKey.seenAs, BackupKey.advanced]));
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
      expect(_plan({...changed, BackupKey.v: 2}).skipped, [BackupKey.v]);
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

    test('the desktop items: own nodes and deleted seeds merge, expiry and the own relay follow the rule', () {
      final file = _map(BackupPlatform.desktop, {
        BackupKey.desktop: {
          BackupKey.deskNodes: [
            {'url': 'https://mine.example:3413', 'label': 'mine'},
            {'url': 'not a url', 'label': 'bad'},
          ],
          BackupKey.invoiceExpiry: 999999,
          BackupKey.seedsDeleted: ['btlabs'],
          BackupKey.ownRelay: 'epicbox.epicnet.us',
          BackupKey.epicboxAutostart: false,
          'publicMode': true,
        },
      });
      final plan = _plan(file, here: BackupPlatform.desktop, mine: {
        BackupKey.desktop: {
          BackupKey.deskNodes: [
            {'url': 'https://home.example', 'label': 'home'},
          ],
          BackupKey.invoiceExpiry: 86400,
          BackupKey.seedsDeleted: <Object?>[],
          BackupKey.ownRelay: null,
          BackupKey.epicboxAutostart: true,
        },
      });
      expect(plan.conflicts, isEmpty);
      final v = plan.values(takeConflicts: false);
      expect(v[BackupItem.deskNodes], [
        {'url': 'https://home.example', 'label': 'home'},
        {'url': 'https://mine.example:3413', 'label': 'mine'},
      ]);
      expect(v[BackupItem.invoiceExpiry], maxBackupInvoiceExpirySecs);
      expect(v[BackupItem.seedsDeleted], ['btlabs']);
      expect(v[BackupItem.ownRelay], 'epicbox.epicnet.us');
      expect(v[BackupItem.epicboxAutostart], isFalse);
      expect(plan.skipped, contains('desktop.publicMode'));
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
