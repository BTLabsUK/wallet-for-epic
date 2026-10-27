import 'package:epic_wallet/src/help/help_content.dart';
import 'package:epic_wallet/src/help/help_i18n.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// In a build without Tor, Help says nothing about Tor: no topic in any language, on either
/// platform, and no section line. The brand name is matched as a word (with the endings Polish
/// gives it), so "history" or "Monitor" do not count.
void main() {
  final torWord = RegExp(r'(?<![A-Za-z])Tor(?:a|em|u|ze)?(?![A-Za-z])|onion', caseSensitive: false);

  for (final a in appLanguages) {
    for (final platform in HelpPlatform.values) {
      test('${a.code} ${platform.name}: no Tor in a build without Tor', () {
        final topics = localizedHelpTopics(a.code, 3, platform: platform, tor: false);
        for (final t in topics) {
          final text = [t.title, t.short, for (final b in t.body) b.text].join('\n');
          expect(torWord.hasMatch(text), isFalse, reason: '${t.id.isEmpty ? t.title : t.id}: ${torWord.firstMatch(text)?.group(0)}');
          expect(t.id, isNot(HelpId.tor));
        }
        for (final s in localizedHelpSections(a.code, tor: false)) {
          expect(torWord.hasMatch('${s.title} ${s.lede}'), isFalse, reason: '${s.id} section');
        }
      });

      test('${a.code} ${platform.name}: the Tor topic is there with Tor', () {
        final topics = localizedHelpTopics(a.code, 3, platform: platform);
        expect(topics.any((t) => t.id == HelpId.tor), isTrue);
        expect(localizedHelpSections(a.code).firstWhere((s) => s.id == 'network').lede, contains('Tor'));
      });
    }
  }
}
