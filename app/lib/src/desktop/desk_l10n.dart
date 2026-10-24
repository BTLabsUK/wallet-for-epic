/// The app's strings on desktop screens: `context.l10n`, in the language Settings › Appearance
/// picked (DeskApp installs the delegates). A screen pumped on its own (widget tests) has no
/// AppLocalizations above it, so it reads English instead of failing.
library;

import 'package:flutter/widgets.dart';

import '../l10n.dart' show AppLocalizations, englishStrings;

export '../l10n.dart' show AppLocalizations, englishStrings;

extension DeskL10n on BuildContext {
  AppLocalizations get l10n => Localizations.of<AppLocalizations>(this, AppLocalizations) ?? englishStrings;
}
