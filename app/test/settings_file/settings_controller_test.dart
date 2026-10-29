// SPDX-License-Identifier: Apache-2.0
import 'dart:io';

import 'package:epic_wallet/src/secret_store_api.dart';
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

void main() {
  late Directory dir;
  late File file;
  final shippedText = testSettingsText();
  final shipped = HostSettings.fromText(shippedText);
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

  Future<SettingsFileController> open({bool watch = false, String? shippedOverride, DateTime Function()? clock}) async {
    final c = await SettingsFileController.open(
      backend: FileSettingsBackend(dir),
      shippedText: shippedOverride ?? shippedText,
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

  test('the first start writes the shipped file byte for byte; later starts read it', () async {
    final c = await open();
    expect(await file.readAsString(), shippedText);
    expect(c.settings, shipped);
    expect(c.notices, isEmpty);
    await c.close();
    opened.clear();

    await handEdit('use = "https://node.lab.example.invalid"', 'use = "https://node.net.example.invalid:3413"');
    final again = await open();
    expect(again.settings.nodeUse, 'https://node.net.example.invalid:3413');
    expect(again.notices, isEmpty);
  });

  test('an app change edits the file in place: comments, unknown keys and order stay', () async {
    await file.writeAsString(
      shippedText
          .replaceFirst('[epicbox]\n', '[epicbox]\n# my own note\nmine = "kept"\n')
          .replaceFirst('[[node.servers]]\nurl = "http://192.0.2.10:3413"', '# my LAN node\n[[node.servers]]\nurl = "http://192.0.2.10:3413"'),
    );
    final c = await open();
    expect(c.notices.single.kind, SettingsNoticeKind.unknownKey);
    final before = await file.readAsString();
    final uses = <UseChange>[];
    c.useChanges.listen(uses.add);

    final servers = c.settings.nodeServers.reversed.toList();
    await c.setAll({
      'epicbox.use': 'epicbox.stack.example.invalid',
      'node.use': 'http://192.0.2.10:3413',
      'node.servers': servers,
    });
    final after = await file.readAsString();
    expect(after, contains('# my own note\nmine = "kept"\n'));
    expect(after, contains('# my LAN node\n[[node.servers]]\nurl = "http://192.0.2.10:3413"'));
    expect(after, contains('use = "epicbox.stack.example.invalid"'));
    expect(c.settings.nodeServers, servers);
    expect(c.settings.epicboxUse, 'epicbox.stack.example.invalid');
    expect(uses.map((u) => '${u.key} ${u.fromApp}'), ['node.use true', 'epicbox.use true']);
    // Only the lines of what changed moved: the rest of the file is the same text.
    final untouched = before.substring(before.indexOf('[pairing]'));
    expect(after, endsWith(untouched));
    expect(c.notices, hasLength(1), reason: 'the unknown key is named once');
  });

  test('an older file is brought up to the shipped version on open', () async {
    await file.writeAsString(shippedText.replaceFirst('\n# Whether the wallet looks for updates.\ncheck = true\n', '\n'));
    final newer = shippedText
        .replaceFirst('version = 1', 'version = 2')
        .replaceFirst(
          '[[epicbox.servers]]\nhost = "epicbox.pool.example.invalid"\noperator = "Iniaku pool"',
          '[[epicbox.servers]]\nhost = "epicbox.pool.example.invalid"\noperator = "Iniaku pool"\n\n'
              '[[epicbox.servers]]\nhost = "new.example.invalid"\noperator = "New"',
        );
    final c = await open(shippedOverride: newer);
    final text = await file.readAsString();
    expect(text, contains('version = 2'));
    expect(text, contains('# Whether the wallet looks for updates.\ncheck = true\n'));
    expect(c.settings.epicboxServers.last.host, 'new.example.invalid');
    expect(c.settings.updatesCheck, isTrue);
  });

  group('per-key merge with hand edits', () {
    test('only the app changed: the app value is written', () async {
      final c = await open();
      await c.set('status.enabled', false);
      expect(await file.readAsString(), contains('enabled = false'));
      expect(c.notices, isEmpty);
    });

    test('only the file changed: its value stays next to the app change', () async {
      final c = await open();
      await handEdit('fallback = "https://node.epic.example.invalid:3413"', 'fallback = "https://node.net.example.invalid:3413"');
      await c.set('status.enabled', false);
      final text = await file.readAsString();
      expect(text, contains('fallback = "https://node.net.example.invalid:3413"'));
      expect(text, contains('enabled = false'));
      expect(c.settings.nodeFallback, 'https://node.net.example.invalid:3413');
      expect(c.notices, isEmpty);
    });

    test('both changed one key: the file wins and a notice says so', () async {
      final c = await open();
      final uses = <UseChange>[];
      c.useChanges.listen(uses.add);
      await handEdit('use = "https://node.lab.example.invalid"', 'use = "https://node.net.example.invalid:3413"');
      await c.set('node.use', 'https://node.epic.example.invalid:3413');
      expect(await file.readAsString(), contains('use = "https://node.net.example.invalid:3413"'));
      expect(c.settings.nodeUse, 'https://node.net.example.invalid:3413');
      expect(c.notices.single, const SettingsNotice(SettingsNoticeKind.conflict, file: 'settings.toml', key: 'node.use'));
      expect(settingsNoticeText(AppLocalizationsEn(), c.notices.single), 'settings.toml was edited at the same time; its value for node.use is kept.');
      expect(uses.single.fromApp, isFalse);
    });
  });

  group('the desktop watcher', () {
    test('reloads a hand edit after the quiet time; ignores its own writes', () async {
      final c = await open(watch: true);
      final changes = <SettingsChange>[];
      final uses = <UseChange>[];
      c.changes.listen(changes.add);
      c.useChanges.listen(uses.add);

      await c.set('epicbox.use', 'epicbox.stack.example.invalid');
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      expect(changes, hasLength(1), reason: 'the own write is not read back as an edit');
      expect(changes.single.appKeys, {'epicbox.use'});

      // An editor saving by rename, in two steps.
      final tmp = File('${dir.path}/settings.toml.swp');
      final edited = (await file.readAsString()).replaceFirst(
        'use = "epicbox.stack.example.invalid"',
        'use = "epicbox.net.example.invalid"',
      );
      await tmp.writeAsString(edited.substring(0, 10));
      await tmp.writeAsString(edited);
      await tmp.rename(file.path);
      await _until(() => c.settings.epicboxUse == 'epicbox.net.example.invalid');
      expect(changes, hasLength(2));
      expect(changes.last.appKeys, isEmpty);
      expect(uses.map((u) => '${u.to} ${u.fromApp}'), [
        'epicbox.stack.example.invalid true',
        'epicbox.net.example.invalid false',
      ]);
    });
  });

  group('a broken file', () {
    test('is never rewritten; the last good settings stay; a write saves it aside first', () async {
      final at = DateTime(2026, 10, 29, 14, 15, 0);
      final c = await open(clock: () => at);
      final good = c.settings;
      final text = await file.readAsString();
      final broken = text.replaceFirst('[status]', '[status');
      await file.writeAsString(broken);
      await c.reload();
      expect(c.settings, good);
      expect(c.notices.single.kind, SettingsNoticeKind.syntaxError);
      expect(c.notices.single.line, lineOf(broken, '[status'));
      expect(await file.readAsString(), broken);
      expect(dir.listSync().map((e) => e.uri.pathSegments.last), isNot(contains(startsWith('settings.toml.bad'))));
      await c.reload();
      expect(c.notices, hasLength(1), reason: 'the same broken text is named once');

      await c.set('status.enabled', false);
      final saved = File('${dir.path}/settings.toml.bad-20261029-141500');
      expect(await saved.readAsString(), broken);
      final now = await file.readAsString();
      expect(now, text.replaceFirst('enabled = true', 'enabled = false'));
      expect(c.notices.last, const SettingsNotice(SettingsNoticeKind.brokenSaved, file: 'settings.toml', backup: 'settings.toml.bad-20261029-141500'));
      expect(
        settingsNoticeText(AppLocalizationsEn(), c.notices.last),
        'settings.toml had errors. It was saved as settings.toml.bad-20261029-141500 and written again.',
      );
    });

    test('a bad value is skipped with its line; the last good value stays', () async {
      final c = await open();
      await handEdit('use = "https://node.lab.example.invalid"', 'use = "node.lab.example.invalid"');
      await c.reload();
      final text = await file.readAsString();
      expect(c.settings.nodeUse, 'https://node.lab.example.invalid');
      final n = c.notices.single;
      expect((n.kind, n.key, n.problem, n.line), (
        SettingsNoticeKind.badValue,
        'node.use',
        ValueProblem.notNodeAddress,
        lineOf(text, 'use = "node.lab'),
      ));
      expect(
        settingsNoticeText(AppLocalizationsEn(), n),
        'settings.toml, line ${n.line}: not a node address. The last good value is in use.',
      );
    });
  });

  test('an unknown key is kept and named once per run', () async {
    final c = await open();
    await handEdit('[epicbox]\n', '[epicbox]\ndefualt = "epicbox.epic.example.invalid"\n');
    await c.reload();
    await handEdit('removed = []', 'removed = ["a.example.invalid:443"]');
    await c.reload();
    expect(c.notices.single.kind, SettingsNoticeKind.unknownKey);
    expect(c.notices.single.key, 'epicbox.defualt');
    await c.set('status.enabled', false);
    expect(await file.readAsString(), contains('defualt = "epicbox.epic.example.invalid"'));
    expect(c.notices, hasLength(1));
  });

  test('a deleted file is written again from the settings in use', () async {
    final c = await open();
    await c.set('node.use', 'http://192.0.2.10:3413');
    final text = await file.readAsString();
    await file.delete();
    await c.reload();
    expect(await file.readAsString(), text);
    expect(c.notices.single.kind, SettingsNoticeKind.recreated);
    expect(c.settings.nodeUse, 'http://192.0.2.10:3413');
  });

  test('two controllers on one folder do not undo each other', () async {
    final a = await open();
    final b = await open();
    await Future.wait([
      a.set('node.use', 'http://192.0.2.10:3413'),
      b.set('epicbox.use', 'epicbox.stack.example.invalid'),
      a.set('status.enabled', false),
      b.set('updates.check', false),
    ]);
    final text = await file.readAsString();
    expect(text, contains('use = "http://192.0.2.10:3413"'));
    expect(text, contains('use = "epicbox.stack.example.invalid"'));
    expect(text, contains('enabled = false'));
    expect(text, contains('check = false'));
    expect(a.notices, isEmpty);
    expect(b.notices, isEmpty);
    expect(b.settings.nodeUse, 'http://192.0.2.10:3413', reason: 'B read what A wrote before writing');
  });

  group('the web store', () {
    test('keeps the shipped file until the first change, then the edited text', () async {
      final store = MemorySecretStore();
      final c = await SettingsFileController.open(backend: StoreSettingsBackend(store), shippedText: shippedText);
      opened.add(c);
      expect(store.values, isEmpty);
      expect(c.settings, shipped);
      await c.set('status.enabled', false);
      expect(store.values['app.settingsToml'], shippedText.replaceFirst('enabled = true', 'enabled = false'));
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

      await container.read(hostSettingsProvider.notifier).set('epicbox.use', 'epicbox.stack.example.invalid');
      expect(container.read(hostSettingsProvider).epicboxUse, 'epicbox.stack.example.invalid');

      await handEdit('use = "epicbox.stack.example.invalid"', 'use = "x y"');
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
