// SPDX-License-Identifier: Apache-2.0
// Settings search's engine: Help's word-start rule, synonyms, ranking (name over synonym over
// explanation), the split into shown here and hidden by the view or an Advanced switch, Help
// topics, and the other languages.
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/desktop/data/settings_registry.dart';
import 'package:epic_wallet/src/desktop/screens/settings/help_topics.dart';
import 'package:epic_wallet/src/desktop/screens/settings/search/settings_search.dart';
import 'package:epic_wallet/src/desktop/screens/settings/search/settings_sections.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart' show DeskRoute;
import 'package:epic_wallet/src/l10n.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  // Deep end with every switch on: everything shows.
  final all = SetView(3, AdvancedFeature.values.toSet());
  const shallow = SetView(1, {});
  SetSearch find(String q, {SetView? view, List<HelpTopic> topics = const [], AppLocalizations? l}) =>
      searchSettings(q, l: l ?? en, view: view ?? all, topics: topics);
  List<String> ids(List<SetHit> hits) => [for (final h in hits) h.entry.id];

  test('a word matches at a word start only: tor finds Tor, not restore', () {
    final r = find('tor');
    expect(ids(r.shown), containsAll([SetId.torPay, SetId.torAll]));
    // "Restore from phrase" and "Import wallet data" (synonym "restore") stay out.
    expect(ids(r.shown), isNot(contains(SetId.restoreWallet)));
    expect(ids(r.shown), isNot(contains(SetId.importData)));
    expect(find('estore').shown, isEmpty);
  });

  test('under two letters searches nothing; every word must match', () {
    expect(find('t').words, isEmpty);
    expect(find('t').isEmpty, isTrue);
    expect(ids(find('tor all').shown), contains(SetId.torAll));
    expect(find('tor zebra').shown, isEmpty);
  });

  test('a synonym finds a row and says so; a name match does not', () {
    final r = find('seed');
    final phrase = r.shown.firstWhere((h) => h.entry.id == SetId.phraseGo);
    expect(phrase.via, 'seed');
    expect(en.deskSetSearchMatches(phrase.via!), 'Matches “seed”');
    final name = find('recovery').shown.firstWhere((h) => h.entry.id == SetId.phraseGo);
    expect(name.via, isNull);
  });

  test('ranking: a word in the name beats a synonym, a synonym beats the explanation', () {
    double score(String q, String id) => find(q).shown.firstWhere((h) => h.entry.id == id).score;
    // "password": the Password row's name, Remembered's synonym.
    expect(score('password', SetId.password), greaterThan(score('password', SetId.remembered)));
    // "outputs": Outputs' name; Split change's synonym; Send options' explanation has it too.
    expect(score('outputs', SetId.advOutputs), greaterThan(score('outputs', SetId.splitChange)));
    expect(score('change', SetId.splitChange), greaterThan(score('change', SetId.advSendopts)));
    // Within a section, the best first.
    final adv = find('outputs').shown.where((h) => h.entry.route == DeskRoute.settingsAdvanced).toList();
    expect(adv.first.entry.id, SetId.advOutputs);
  });

  test('sections come in navigation order', () {
    final r = find('tor');
    final order = [for (final s in settingsSections) s.route];
    final seen = [for (final h in r.shown) order.indexOf(h.entry.route)];
    expect(seen, orderedEquals([...seen]..sort()));
    // Payments (this wallet) before Network & privacy (app).
    expect(ids(r.shown).indexOf(SetId.torPay), lessThan(ids(r.shown).indexOf(SetId.torAll)));
  });

  test('hidden by the view or a switch: listed apart, with what shows them', () {
    // Shallow: Payments and Network & privacy are Deeper's.
    final r = find('tor', view: shallow);
    expect(r.shown, isEmpty);
    final pay = r.hidden.firstWhere((h) => h.entry.id == SetId.torPay);
    expect(pay.reasons, ['Deeper view']);
    expect(pay.level, 2);
    expect(pay.features, isEmpty);
    // Deeper without the Logs switch: the logs rows want Advanced › Logs.
    final logs = find('log level', view: const SetView(2, {})).hidden.single;
    expect(logs.entry.id, SetId.logLevel);
    expect(logs.level, isNull);
    expect(logs.features, [AdvancedFeature.logs]);
    expect(logs.reasons, ['Advanced › Logs']);
    // Both at once, every one named (review 13).
    final strategy = find('coin selection', view: const SetView(2, {})).hidden.single;
    expect(strategy.reasons, ['Deep end view', 'Advanced › Send options']);
    expect(setJoinReasons(en, strategy.reasons), 'Deep end view and Advanced › Send options');
    // The count counts everything listed (review 12), never 0 above results.
    expect(r.count, r.shown.length + r.hidden.length + r.help.length);
    expect(r.count, greaterThan(0));
  });

  test('the navigation entries with results include a sub-page’s parent', () {
    final r = find('unconfirmed');
    expect(ids(r.shown), contains(SetId.recheckDrop));
    expect(r.routes, contains(DeskRoute.settingsAccount));
    expect(r.routes, isNot(contains(DeskRoute.settingsRescan)));
  });

  test('Help topics come along, four at most', () {
    final topics = helpTopicsFor(3);
    final r = find('tor', topics: topics);
    expect(r.help, isNotEmpty);
    expect(r.help.length, lessThanOrEqualTo(settingsSearchHelpMax));
    expect(find('fee', topics: topics).help.length, lessThanOrEqualTo(4));
  });

  test('the noisy synonym is gone: "backup" does not find node failover', () {
    expect(ids(find('backup').shown), isNot(contains(SetId.failover)));
    expect(ids(find('backup').shown), containsAll([SetId.exportData, SetId.phraseGo]));
  });

  test('other languages: their names and synonyms', () {
    final de = lookupAppLocalizations(const Locale('de'));
    expect(ids(find('passwort', l: de).shown), contains(SetId.password));
    final zh = lookupAppLocalizations(const Locale('zh'));
    // Han matches anywhere in a word.
    final label = settingsEntry(SetId.password)!.label(zh);
    expect(ids(find(label.characters2, l: zh).shown), contains(SetId.password));
    final th = lookupAppLocalizations(const Locale('th'));
    expect(find(settingsEntry(SetId.theme)!.label(th), l: th).shown, isNotEmpty);
  });

  test('fallback: a page the view hides opens its group’s first page, saying which view shows it', () {
    final f = settingsFallback(en, shallow, DeskRoute.settingsNode);
    expect(f.route, DeskRoute.settingsAppearance);
    expect(f.notice, 'Node shows in the Deeper view.');
    final inv = settingsFallback(en, const SetView(3, {}), DeskRoute.settingsInvoices);
    expect(inv.route, DeskRoute.settingsAccount);
    expect(inv.notice, 'Invoices shows with Advanced › Invoices.');
    expect(settingsFallback(en, all, DeskRoute.settingsNode), (route: DeskRoute.settingsNode, notice: null));
  });
}

extension on String {
  /// The first two characters (a Han word).
  String get characters2 => length < 2 ? this : substring(0, 2);
}
