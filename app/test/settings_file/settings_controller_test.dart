// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/server_list.dart' show ServerKind;
import 'package:epic_wallet/src/server_list_file.dart' show useServerValues;
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/settings_file/settings_backend.dart';
import 'package:epic_wallet/src/settings_file/settings_backend_io.dart';
import 'package:epic_wallet/src/settings_file/settings_controller.dart';
import 'package:epic_wallet/src/settings_file/settings_layout.dart';
import 'package:epic_wallet/src/settings_file/settings_notice.dart';
import 'package:epic_wallet/src/settings_file/settings_notice_text.dart';
import 'package:epic_wallet/src/settings_file/settings_providers.dart';
import 'package:epic_wallet/l10n/app_localizations_en.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_settings.dart';

const _lab = 'https://node.lab.invalid';
const _net = 'https://node.net.invalid:3413';
const _lan = 'http://192.0.2.10:3413';

void main() {
  late Directory dir;
  late File file;
  final shippedText = testSettingsText();
  final config = testConfig();
  final shipped = HostSettings.fromText(shippedText, config: config);
  final opened = <SettingsFileController>[];

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('settings_file_test');
    file = File('${dir.path}/settings.toml');
  });

  tearDown(() async {
    for (final c in opened) {
      await c.close();
    }
    opened.clear();
    await dir.delete(recursive: true);
  });

  Future<SettingsFileController> open({bool watch = false, DateTime Function()? clock}) async {
    final c = await SettingsFileController.open(
      backend: FileSettingsBackend(dir),
      shippedText: shippedText,
      config: config,
      watch: watch,
      clock: clock ?? DateTime.now,
    );
    opened.add(c);
    return c;
  }

  /// A hand edit: [from] replaced by [to] in the file's text.
  Future<void> handEdit(String from, String to) async {
    final text = await file.readAsString();
    expect(text, contains(from));
    await file.writeAsString(text.replaceFirst(from, to));
  }

  int lineOf(String text, String needle) => text.substring(0, text.indexOf(needle)).split('\n').length;

  test('the first start writes the default copy byte for byte; later starts read it, unmerged', () async {
    final c = await open();
    expect(await file.readAsString(), shippedText);
    expect(c.settings, shipped);
    expect(c.notices, isEmpty);
    await c.close();
    opened.clear();

    // A hand-made short list stays short: no default server joins it.
    await file.writeAsString('[node]\nservers = ["$_net"]\n');
    final again = await open();
    expect(again.settings.nodeUrls, [_net]);
    expect(again.settings.epicboxServers, shipped.epicboxServers, reason: 'a missing key reads as the default copy');
    expect(await file.readAsString(), '[node]\nservers = ["$_net"]\n', reason: 'nothing is written on open');
    expect(again.notices, isEmpty);
  });

  test('a pick moves the server to the top in place: comments, unknown keys and order stay', () async {
    await file.writeAsString(shippedText.replaceFirst('[epicbox]\n', '[epicbox]\n# my own note\nmine = "kept"\n'));
    final c = await open();
    expect(c.notices.single.kind, SettingsNoticeKind.unknownKey);
    final uses = <UseChange>[];
    c.useChanges.listen(uses.add);

    await c.setAll(useServerValues(c.settings, node: _lan, relay: 'box.stack.invalid'));
    final after = await file.readAsString();
    expect(after, contains('# my own note\nmine = "kept"\n'));
    expect(c.settings.nodeUse, _lan);
    expect(c.settings.nodeUrls.length, shipped.nodeUrls.length, reason: 'moved, not added');
    expect(c.settings.epicboxUse, 'box.stack.invalid');
    expect(uses.map((u) => '${u.key} ${u.fromApp}'), ['${UseChange.node} true', '${UseChange.epicbox} true']);
    expect(after, endsWith(shippedText.substring(shippedText.indexOf('[online]'))), reason: 'only the lists moved');
    expect(c.notices, hasLength(1), reason: 'the unknown key is named once');
  });

  test('a picked server not in the list joins it at the top', () {
    final v = useServerValues(shipped, node: 'https://new.example.invalid');
    expect((v['node.servers']! as List).first, 'https://new.example.invalid');
    expect((v['node.servers']! as List).length, shipped.nodeUrls.length + 1);
    expect(ServerKind.values, contains(ServerKind.relay));
  });

  group('per-key merge with hand edits', () {
    test('only the app changed: the app value is written', () async {
      final c = await open();
      await c.set('online.status_site', false);
      expect(await file.readAsString(), contains('status_site = false'));
      expect(c.notices, isEmpty);
    });

    test('only the file changed: its value stays next to the app change', () async {
      final c = await open();
      await handEdit('  "$_lab",\n', '');
      await c.set('online.status_site', false);
      final text = await file.readAsString();
      expect(text, isNot(contains('"$_lab"')));
      expect(text, contains('status_site = false'));
      expect(c.settings.nodeUse, 'https://node.epic.invalid:3413', reason: 'the next node is in use');
      expect(c.notices, isEmpty);
    });

    test('both changed one key: the file wins and a notice says so', () async {
      final c = await open();
      final uses = <UseChange>[];
      c.useChanges.listen(uses.add);
      await handEdit('"$_lab"', '"$_net"');
      await c.setAll(useServerValues(c.settings, node: _lan));
      expect(c.settings.nodeUse, _net);
      expect(c.notices.single, const SettingsNotice(SettingsNoticeKind.conflict, file: 'settings.toml', key: 'node.servers'));
      expect(settingsNoticeText(AppLocalizationsEn(), c.notices.single), 'settings.toml was edited at the same time; its value for node.servers is kept.');
      expect(uses.single.fromApp, isFalse);
    });
  });

  group('the desktop watcher', () {
    test('reloads a hand reorder after the quiet time; ignores its own writes', () async {
      final c = await open(watch: true);
      final changes = <SettingsChange>[];
      final uses = <UseChange>[];
      c.changes.listen(changes.add);
      c.useChanges.listen(uses.add);

      await c.setAll(useServerValues(c.settings, relay: 'box.stack.invalid'));
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      expect(changes, hasLength(1), reason: 'the own write is not read back as an edit');
      expect(changes.single.appKeys, {'epicbox.servers'});
      expect(changes.single.epicboxUseChanged, isTrue);

      // An editor saving by rename, in two steps: box.net.invalid moved to the top.
      final tmp = File('${dir.path}/settings.toml.swp');
      final now = await file.readAsString();
      final edited = now
          .replaceFirst('"box.stack.invalid"', '"swap"')
          .replaceFirst('"box.net.invalid"', '"box.stack.invalid"')
          .replaceFirst('"swap"', '"box.net.invalid"');
      await tmp.writeAsString(edited.substring(0, 10));
      await tmp.writeAsString(edited);
      await tmp.rename(file.path);
      await _until(() => c.settings.epicboxUse == 'box.net.invalid');
      expect(changes, hasLength(2));
      expect(changes.last.appKeys, isEmpty);
      expect(uses.map((u) => '${u.to} ${u.fromApp}'), [
        'box.stack.invalid true',
        'box.net.invalid false',
      ]);
    });
  });

  group('a broken file', () {
    test('is never rewritten; the last good settings stay; a write saves it aside first', () async {
      final at = DateTime(2026, 10, 29, 14, 15, 0);
      final c = await open(clock: () => at);
      final good = c.settings;
      final text = await file.readAsString();
      final broken = text.replaceFirst('[online]', '[online');
      await file.writeAsString(broken);
      await c.reload();
      expect(c.settings, good);
      expect(c.notices.single.kind, SettingsNoticeKind.syntaxError);
      expect(c.notices.single.line, lineOf(broken, '[online'));
      expect(await file.readAsString(), broken);
      expect(dir.listSync().map((e) => e.uri.pathSegments.last), isNot(contains(startsWith('settings.toml.bad'))));
      await c.reload();
      expect(c.notices, hasLength(1), reason: 'the same broken text is named once');

      await c.set('online.status_site', false);
      final saved = File('${dir.path}/settings.toml.bad-20261029-141500');
      expect(await saved.readAsString(), broken);
      expect(await file.readAsString(), text.replaceFirst('status_site = true', 'status_site = false'));
      expect(c.notices.last, const SettingsNotice(SettingsNoticeKind.brokenSaved, file: 'settings.toml', backup: 'settings.toml.bad-20261029-141500'));
      expect(
        settingsNoticeText(AppLocalizationsEn(), c.notices.last),
        'settings.toml had errors. It was saved as settings.toml.bad-20261029-141500 and written again.',
      );
    });

    test('a bad value is skipped with its line; the last good value stays', () async {
      final c = await open();
      await handEdit('"$_lab"', '"node.lab.invalid"');
      await c.reload();
      final text = await file.readAsString();
      expect(c.settings.nodeUse, _lab);
      final n = c.notices.single;
      expect((n.kind, n.key, n.problem, n.line), (
        SettingsNoticeKind.badValue,
        'node.servers',
        ValueProblem.notNodeAddress,
        lineOf(text, 'servers = ['),
      ));
      expect(
        settingsNoticeText(AppLocalizationsEn(), n),
        'settings.toml, line ${n.line}: not a node address. The last good value is in use.',
      );
    });
  });

  test('an unknown key is kept and named once per run', () async {
    final c = await open();
    await handEdit('[epicbox]\n', '[epicbox]\nuse = "box.epic.invalid"\n');
    await c.reload();
    await handEdit('price = true', 'price = false');
    await c.reload();
    expect(c.notices.single.kind, SettingsNoticeKind.unknownKey);
    expect(c.notices.single.key, 'epicbox.use');
    await c.set('online.status_site', false);
    expect(await file.readAsString(), contains('use = "box.epic.invalid"'));
    expect(c.notices, hasLength(1));
  });

  test('a deleted file is written again from the settings in use', () async {
    final c = await open();
    await c.setAll(useServerValues(c.settings, node: _lan));
    final text = await file.readAsString();
    await file.delete();
    await c.reload();
    expect(await file.readAsString(), text);
    expect(c.notices.single.kind, SettingsNoticeKind.recreated);
    expect(c.settings.nodeUse, _lan);
  });

  test('empty lists are taken: none configured, no crash', () async {
    final c = await open();
    await c.setAll({'node.servers': const <String>[], 'epicbox.servers': const <String>[]});
    expect(c.settings.hasNode, isFalse);
    expect(c.settings.hasEpicbox, isFalse);
    expect(await file.readAsString(), contains('servers = []'));
  });

  test('two controllers on one folder do not undo each other', () async {
    final a = await open();
    final b = await open();
    await Future.wait([
      a.setAll(useServerValues(a.settings, node: _lan)),
      b.setAll(useServerValues(b.settings, relay: 'box.stack.invalid')),
      a.set('online.status_site', false),
      b.set('online.update_check', false),
    ]);
    final text = await file.readAsString();
    expect(text, contains('status_site = false'));
    expect(text, contains('update_check = false'));
    await b.reload();
    expect(b.settings.nodeUse, _lan, reason: 'B read what A wrote');
    expect(b.settings.epicboxUse, 'box.stack.invalid');
    expect(a.notices, isEmpty);
    expect(b.notices, isEmpty);
  });

  group('the web store', () {
    test('keeps the default copy until the first change, then the edited text', () async {
      final store = MemorySecretStore();
      final c = await SettingsFileController.open(backend: StoreSettingsBackend(store), shippedText: shippedText, config: config);
      opened.add(c);
      expect(store.values, isEmpty);
      expect(c.settings, shipped);
      await c.set('online.status_site', false);
      expect(store.values['app.settingsToml'], shippedText.replaceFirst('status_site = true', 'status_site = false'));
    });
  });

  group('providers', () {
    test('hostSettingsProvider follows the controller; notices are listed and dismissed', () async {
      final c = await open();
      final container = ProviderContainer(overrides: [settingsFileProvider.overrideWithValue(c)]);
      addTearDown(container.dispose);
      final sub = container.listen(hostSettingsProvider, (_, _) {});
      addTearDown(sub.close);
      container.listen(settingsNoticesProvider, (_, _) {});

      await container.read(hostSettingsProvider.notifier).setAll(useServerValues(c.settings, relay: 'box.stack.invalid'));
      expect(container.read(hostSettingsProvider).epicboxUse, 'box.stack.invalid');

      await handEdit('"box.stack.invalid"', '"x y"');
      await c.reload();
      final notices = container.read(settingsNoticesProvider);
      expect(notices.single.problem, ValueProblem.notEpicboxServer);
      container.read(settingsNoticesProvider.notifier).dismiss(notices.single);
      expect(container.read(settingsNoticesProvider), isEmpty);
    });

    test('without a controller the provider starts from the process-wide test settings', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(hostSettingsProvider).nodeUse, testSettings().nodeUse);
    });
  });
}

Future<void> _until(bool Function() done, {Duration timeout = const Duration(seconds: 5)}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) fail('timed out');
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}
