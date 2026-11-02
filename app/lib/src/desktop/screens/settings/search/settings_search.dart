// SPDX-License-Identifier: Apache-2.0
/// Settings search, without widgets: Help's rules (every word of the query starts a word
/// somewhere, "tor" finds Tor and not restore; Chinese, Japanese and Thai match anywhere; at
/// least two letters in all) over each row's name, its other words (synonyms), its explanation
/// and its page and group. A word in the name counts most, then a synonym, then the
/// explanation. Results the view or an Advanced switch hides come apart, with what shows
/// them; the best four Help topics come along.
library;

import '../../../../advanced.dart' show AdvancedFeature;
import '../../../../ui/help_screen.dart' show helpWordStart;
import '../../../data/settings_registry.dart';
import '../../../desk_l10n.dart';
import '../../../widgets/kit.dart' show DeskRoute;
import '../help_topics.dart' show HelpTopic;
import '../settings_help.dart' show queryWords, searchTopics;
import 'settings_sections.dart';

export '../settings_help.dart' show queryWords;

/// How much a word counts in each part of a row; a whole word counts double, the start of one
/// one and a half.
const _wLabel = 6.0, _wSynonym = 4.0, _wHint = 2.0, _wInfo = 1.0, _wPlace = 1.0;

/// Help topics listed with the settings at most.
const settingsSearchHelpMax = 4;

final _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// How [w] occurs in [low]: 2 a whole word, 1.5 the start of a word, 0 not at a word start.
double _fit(String low, String w) {
  var i = helpWordStart(low, w);
  var best = 0.0;
  while (i >= 0) {
    final end = i + w.length;
    final whole = end >= low.length || !_letterOrDigit.hasMatch(low[end]);
    if (whole) return 2;
    best = 1.5;
    i = helpWordStart(low, w, i + 1);
  }
  return best;
}

/// One matching row.
class SetHit {
  const SetHit({required this.entry, required this.score, this.via, this.reasons = const [], this.level, this.features = const []});

  final SetEntry entry;
  final double score;

  /// The synonym that found the row when its name alone does not ("Matches “seed”").
  final String? via;

  /// Empty for a row shown here; else what shows it ("Deep end view", "Advanced › Logs").
  final List<String> reasons;

  /// For a hidden row: the view to change to (null when the view shows it) and the switches to
  /// turn on.
  final int? level;
  final List<AdvancedFeature> features;

  bool get hidden => reasons.isNotEmpty;
}

/// What a search found.
class SetSearch {
  const SetSearch({required this.words, required this.shown, required this.hidden, required this.help});

  static const empty = SetSearch(words: [], shown: [], hidden: [], help: []);

  /// The query's words ([queryWords]); empty for a query under two letters.
  final List<String> words;

  /// Rows shown here: sections in navigation order, the best match first within each.
  final List<SetHit> shown;

  /// Rows the view or an Advanced switch hides, in navigation order.
  final List<SetHit> hidden;
  final List<HelpTopic> help;

  /// Everything listed: settings shown and hidden, and Help topics (review 12).
  int get count => shown.length + hidden.length + help.length;

  bool get isEmpty => count == 0;

  /// The navigation entries with a result (a sub-page's result counts for its parent).
  Set<DeskRoute> get routes => {for (final h in [...shown, ...hidden]) setNavRouteOf(h.entry.route)};

  /// The order the arrow keys walk: shown rows, Help topics, hidden rows.
  int get flatLength => count;
}

/// Scores [e] for [words]: null when a word starts no word of the row.
SetHit? matchEntry(SetEntry e, List<String> words, AppLocalizations l) {
  if (words.isEmpty) return null;
  final label = e.label(l).toLowerCase();
  final syns = e.synonymList(l);
  final synLow = [for (final s in syns) s.toLowerCase()];
  final hint = (e.hint?.call(l) ?? '').toLowerCase();
  final info = (e.info?.call(l) ?? '').toLowerCase();
  final place = '${settingsSectionLabel(l, e.route)}\n${e.section.parent == null ? '' : settingsSectionLabel(l, e.section.parent!)}\n${e.group?.call(l) ?? ''}'.toLowerCase();
  var total = 0.0;
  String? via;
  var allInLabel = true;
  for (final w in words) {
    final inLabel = _fit(label, w);
    if (inLabel == 0) allInLabel = false;
    var best = inLabel * _wLabel;
    var bestSyn = -1;
    for (var i = 0; i < synLow.length; i++) {
      final s = _fit(synLow[i], w) * _wSynonym;
      if (s > best) {
        best = s;
        bestSyn = i;
      }
    }
    final h = _fit(hint, w) * _wHint;
    if (h > best) {
      best = h;
      bestSyn = -1;
    }
    final inf = _fit(info, w) * _wInfo;
    if (inf > best) best = inf;
    final pl = _fit(place, w) * _wPlace;
    if (pl > best) best = pl;
    if (best == 0) return null;
    // The synonym that found a word the name lacks.
    if (inLabel == 0 && via == null) {
      final k = bestSyn >= 0 ? bestSyn : synLow.indexWhere((s) => _fit(s, w) > 0);
      if (k >= 0) via = syns[k];
    }
    total += best;
  }
  return SetHit(entry: e, score: total, via: allInLabel ? null : via);
}

/// Searches [registry] (every row) and [topics] (Help, as the user's Help shows them) for
/// [query] in the app's language [l], as [view] shows Settings.
SetSearch searchSettings(String query, {required AppLocalizations l, required SetView view, List<SetEntry>? registry, List<HelpTopic> topics = const []}) {
  final words = queryWords(query);
  if (words.isEmpty) return SetSearch.empty;
  final shown = <SetHit>[], hidden = <SetHit>[];
  final order = {for (final (i, s) in settingsSections.indexed) s.route: i};
  final rows = registry ?? settingsRegistry;
  for (final e in rows) {
    final m = matchEntry(e, words, l);
    if (m == null) continue;
    final gate = e.fullGate;
    if (gate.open(view)) {
      shown.add(m);
    } else {
      hidden.add(SetHit(
        entry: e,
        score: m.score,
        via: m.via,
        reasons: setGateReasons(l, gate, view),
        level: gate.levelOpen(view) ? null : gate.minLevel,
        features: gate.featuresOff(view),
      ));
    }
  }
  int sec(SetHit h) => order[h.entry.route] ?? 999;
  final pos = {for (final (i, e) in rows.indexed) e.id: i};
  shown.sort((a, b) => sec(a) != sec(b) ? sec(a) - sec(b) : (b.score != a.score ? b.score.compareTo(a.score) : pos[a.entry.id]! - pos[b.entry.id]!));
  final help = [for (final h in searchTopics(topics, words).take(settingsSearchHelpMax)) h.topic];
  return SetSearch(words: words, shown: shown, hidden: hidden, help: help);
}
