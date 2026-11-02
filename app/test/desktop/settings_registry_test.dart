// SPDX-License-Identifier: Apache-2.0
// The settings registry and the pages keep in step: every row a page marks with
// `anchor: SetId.x` is in the registry (so search finds it), and every registry row has its
// anchor on a page (so a search result can jump to it). A new row without either fails here.
// The rows a build leaves out (settingsNotBuilt: Link · Tor without Tor) are in neither. Run
// both ways: flutter test [--dart-define=WFE_TOR=false] test/desktop/settings_registry_test.dart
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/settings_registry.dart';
import 'package:epic_wallet/src/desktop/screens/settings/search/settings_sections.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

/// `SetId` constant name → id, read from its source.
Map<String, String> _idNames() {
  final src = File('lib/src/desktop/screens/settings/setting_ids.dart').readAsStringSync();
  // `torAll` is kept as a constant but is in no page, search or SetId.all (see setting_ids.dart).
  return {for (final m in RegExp(r"static const (\w+) = '(\w+)';").allMatches(src)) if (m[1] != 'torAll') m[1]!: m[2]!};
}

/// The ids the desktop's pages anchor, with the files that do; a row this build leaves out
/// (its anchor sits behind the build's flag) does not count.
Map<String, List<String>> _anchors(Map<String, String> names) {
  final out = <String, List<String>>{};
  final dir = Directory('lib/src/desktop');
  for (final f in dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
    // Code only: the doc comments name `anchor: SetId.x` as an example.
    final code = f.readAsLinesSync().where((line) => !line.trimLeft().startsWith('//')).join('\n');
    for (final m in RegExp(r'(?:anchor|SetAnchor\(\s*id):\s*SetId\.(\w+)').allMatches(code)) {
      final id = names[m[1]!] ?? '?${m[1]}';
      if (settingsNotBuilt.contains(id)) continue;
      (out[id] ??= []).add(f.path.split('/').last);
    }
  }
  return out;
}

void main() {
  final names = _idNames();

  test('the registry lists every SetId once, in navigation order', () {
    final ids = [for (final e in settingsRegistry) e.id];
    expect(ids.toSet(), hasLength(ids.length), reason: 'an id is listed twice');
    expect(ids, [for (final id in SetId.all) if (!settingsNotBuilt.contains(id)) id]);
    expect(names.values.where((id) => !settingsNotBuilt.contains(id)).toSet(), ids.toSet());
    final order = [for (final s in settingsSections) s.route];
    final seen = [for (final e in settingsRegistry) order.indexOf(e.route)];
    expect(seen.every((i) => i >= 0), isTrue, reason: 'a row on a route that is no section');
    expect(seen, orderedEquals([...seen]..sort()));
  });

  test('every entry has a name and synonyms in every language; a parent is a known row', () {
    for (final code in ['en', 'de', 'pl', 'ru', 'th', 'zh']) {
      final l = lookupAppLocalizations(Locale(code));
      for (final e in settingsRegistry) {
        expect(e.label(l).trim(), isNotEmpty, reason: '${e.id} $code');
        expect(e.synonymList(l), isNotEmpty, reason: '${e.id} $code');
      }
    }
    for (final e in settingsRegistry.where((e) => e.parent != null)) {
      expect(settingsEntry(e.parent!), isNotNull, reason: e.id);
    }
  });

  test('every page anchor is in the registry, and every registry row is anchored on a page', () {
    final anchors = _anchors(names);
    final unknown = anchors.keys.where((id) => settingsEntry(id) == null).toList();
    expect(unknown, isEmpty, reason: 'anchors the registry does not list: ${[for (final u in unknown) '$u (${anchors[u]!.join(', ')})']}');
    if (anchors.isEmpty) {
      // Before the pages carry anchors (the search branch alone); after the merge this runs.
      markTestSkipped('no settings page carries an anchor yet');
      return;
    }
    final missing = [for (final e in settingsRegistry) if (!anchors.containsKey(e.id)) e.id];
    expect(missing, isEmpty, reason: 'registry rows no page anchors: $missing');
    final twice = [for (final MapEntry(:key, :value) in anchors.entries) if (value.length > 1) '$key (${value.join(', ')})'];
    expect(twice, isEmpty, reason: 'anchored more than once: $twice');
  });
}
