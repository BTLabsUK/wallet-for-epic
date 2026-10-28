// SPDX-License-Identifier: Apache-2.0
/// Help in a chosen language: the English topics and sections of help_content.dart, each replaced
/// by its translation (help_de.dart, help_pl.dart, help_ru.dart, help_zh.dart, help_th.dart) with
/// the same id when the language has it. A topic or section the language lacks stays English, so
/// a half-translated language still shows a whole Help.
library;

import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../l10n.dart' show appLanguages;
import 'help_content.dart';
import 'help_de.dart';
import 'help_pl.dart';
import 'help_ru.dart';
import 'help_th.dart';
import 'help_zh.dart';

/// [code] when it is one of the app's languages, else English.
String _known(String code) =>
    appLanguages.any((a) => a.code == code) ? code : 'en';

List<HelpSection> _translatedSections(String lang) => switch (lang) {
  'de' => helpSectionsDe,
  'pl' => helpSectionsPl,
  'ru' => helpSectionsRu,
  'zh' => helpSectionsZh,
  'th' => helpSectionsTh,
  _ => const [],
};

List<HelpTopic> _translatedTopics(
  String lang,
  int confirmations,
  HelpPlatform platform,
  bool tor,
) => switch (lang) {
  'de' => helpTopicsDe(confirmations, platform: platform, tor: tor),
  'pl' => helpTopicsPl(confirmations, platform: platform, tor: tor),
  'ru' => helpTopicsRu(confirmations, platform: platform, tor: tor),
  'zh' => helpTopicsZh(confirmations, platform: platform, tor: tor),
  'th' => helpTopicsTh(confirmations, platform: platform, tor: tor),
  _ => const [],
};

/// [english] with each section replaced by the one in [translated] with the same id.
List<HelpSection> mergeHelpSections(
  List<HelpSection> english,
  List<HelpSection> translated,
) {
  final byId = {for (final s in translated) s.id: s};
  return [for (final s in english) byId[s.id] ?? s];
}

/// [english] with each topic replaced by the one in [translated] with the same id. A topic
/// without an id cannot be matched and stays English; so does one [translated] lacks.
List<HelpTopic> mergeHelpTopics(
  List<HelpTopic> english,
  List<HelpTopic> translated,
) {
  final byId = {
    for (final t in translated)
      if (t.id.isNotEmpty) t.id: t,
  };
  return [for (final t in english) t.id.isEmpty ? t : byId[t.id] ?? t];
}

/// The five sections in [lang] (a code from `appLanguages`): English for those it has not
/// translated. [tor] false words the network section without Tor.
List<HelpSection> localizedHelpSections(String lang, {bool tor = true}) {
  final sections = mergeHelpSections(helpSections, _translatedSections(_known(lang)));
  if (tor) return sections;
  return [
    for (final s in sections)
      if (s.id == 'network') (id: s.id, title: s.title, lede: _networkLedeNoTor[_known(lang)]!, art: s.art) else s,
  ];
}

/// The Nodes and Epicbox section's line in a build without Tor: the usual one minus "and Tor".
const _networkLedeNoTor = {
  'en': 'What the wallet connects to.',
  'de': 'Womit sich die Wallet verbindet.',
  'pl': 'Z czym łączy się portfel.',
  'ru': 'К чему подключается кошелёк.',
  'zh': '钱包连接到什么。',
  'th': 'กระเป๋าเงินเชื่อมต่อกับอะไรบ้าง',
};

/// The topics for [platform] in [lang], with [confirmations] as the open wallet's balance counts
/// them: the English list, each topic replaced by the translation with the same id.
List<HelpTopic> localizedHelpTopics(
  String lang,
  int confirmations, {
  required HelpPlatform platform,
  bool tor = true,
}) {
  final english = helpTopics(confirmations, platform: platform, tor: tor);
  final code = _known(lang);
  if (code == 'en') return english;
  return mergeHelpTopics(
    english,
    _translatedTopics(code, confirmations, platform, tor),
  );
}

/// Whether Help has any text in [lang]: English always, another language once a translator has
/// written a topic.
bool helpTranslated(String lang) {
  final code = _known(lang);
  return code == 'en' ||
      _translatedSections(code).isNotEmpty ||
      _translatedTopics(code, 3, HelpPlatform.phone, true).isNotEmpty;
}

/// The strings Help takes from the ARB (the invoice topics and their section) in [lang].
AppLocalizations helpStrings(String lang) =>
    lookupAppLocalizations(Locale(_known(lang)));

/// The help language when nothing was chosen: the first of [systemLocales] the app has, else
/// English. The phone follows the app's own language instead; the desktop UI is English, so
/// its help follows the system.
String systemHelpLanguage(Iterable<Locale> systemLocales) {
  for (final l in systemLocales) {
    for (final a in appLanguages) {
      if (a.code == l.languageCode) return a.code;
    }
  }
  return 'en';
}
