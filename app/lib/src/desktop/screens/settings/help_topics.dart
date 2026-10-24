/// The desktop's help topics: the content lives in `lib/src/help/help_content.dart`, shared
/// with the phone, and this file keeps the desktop's names.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../help/help_content.dart';
import '../../../help/help_i18n.dart';
import '../../data/features.dart';
import '../../data/state.dart' show deskProvider;

export '../../../help/help_content.dart';
export '../../../help/help_i18n.dart' show helpStrings, localizedHelpSections;

/// The topics in [lang] (English unless given), with [confirmations] as the open wallet's
/// balance counts them (`deskMinConfirmations`).
List<HelpTopic> helpTopicsFor(int confirmations, {String lang = 'en'}) =>
    localizedHelpTopics(lang, confirmations, platform: HelpPlatform.desktop, tor: DeskFeatures.tor);

/// The language Help shows its topics in: the choice in its switch, else the computer's first
/// language the app has, else English. The interface itself stays as Settings says.
String deskHelpLanguage(WidgetRef ref) {
  final chosen = ref.watch(deskProvider.select((s) => s.settings.helpLanguage));
  return chosen ?? systemHelpLanguage(WidgetsBinding.instance.platformDispatcher.locales);
}
