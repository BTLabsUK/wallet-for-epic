import 'package:epic_wallet/src/help/help_content.dart';
import 'package:epic_wallet/src/help/help_i18n.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every translated Help mirrors help_content.dart: the same topics in the same order, the same
/// blocks, the same bold terms and the same places to go, on both platforms, with and without
/// Tor, for any confirmation count. A translation that drifts from the English fails here
/// instead of showing a half-different Help.
void main() {
  final languages = [for (final a in appLanguages) if (a.code != 'en') a.code];

  /// The English place each `[[…]]` goes to, in order.
  List<String> places(HelpTopic t) => [
    for (final b in t.body)
      for (final line in b.kind == HelpBlockKind.p ? [b.text] : b.items)
        for (final p in helpInline(line))
          if (p.place) p.target,
  ];
  int terms(HelpTopic t) => [
    for (final b in t.body)
      for (final line in b.kind == HelpBlockKind.p ? [b.text] : b.items)
        for (final p in helpInline(line))
          if (p.term) p,
  ].length;

  for (final lang in languages) {
    test('$lang: every section is translated', () {
      final english = helpSections;
      final sections = localizedHelpSections(lang);
      expect([for (final s in sections) s.id], [for (final s in english) s.id]);
      expect([for (final s in sections) s.art], [for (final s in english) s.art]);
      for (final (i, s) in sections.indexed) {
        expect(s.lede, isNot(english[i].lede), reason: '${s.id} lede');
      }
    });

    for (final platform in HelpPlatform.values) {
      for (final tor in [true, false]) {
        for (final confirmations in [1, 3, 10]) {
          test('$lang ${platform.name} tor:$tor confirmations:$confirmations mirrors English', () {
            final english = helpTopics(confirmations, platform: platform, tor: tor);
            final topics = localizedHelpTopics(lang, confirmations, platform: platform, tor: tor);
            expect([for (final t in topics) t.id], [for (final t in english) t.id]);
            for (final (i, t) in topics.indexed) {
              final e = english[i];
              final where = t.id;
              expect(t.bodyText, isNot(e.bodyText), reason: '$where is not translated');
              expect(t.section, e.section, reason: where);
              expect(t.handshake, e.handshake, reason: where);
              expect([for (final b in t.body) b.kind], [for (final b in e.body) b.kind], reason: where);
              expect([for (final b in t.body) b.items.length], [for (final b in e.body) b.items.length], reason: where);
              expect(places(t), places(e), reason: '$where places');
              expect(terms(t), terms(e), reason: '$where bold terms');
            }
          });
        }
      }
    }
  }
}
