// SPDX-License-Identifier: Apache-2.0
/// The app's strings on desktop screens: `context.l10n`, in the language Settings › Appearance
/// picked (DeskApp installs the delegates). A screen pumped on its own (widget tests) has no
/// AppLocalizations above it, so it reads English instead of failing.
library;

import 'package:flutter/widgets.dart';

import '../l10n.dart' show AppLocalizations, englishStrings;

export '../l10n.dart' show AppLocalizations, englishStrings, percentText;

/// The strings of the language the window shows, for text the data layer keeps to show later
/// (a notice, a failure reason, the Tor problem) where no BuildContext is at hand. DeskApp sets
/// it each time it builds; tests that pump no DeskApp read English. Text stored before a
/// language switch stays in the old language until it is made again.
AppLocalizations deskStrings = englishStrings;

extension DeskL10n on BuildContext {
  AppLocalizations get l10n => Localizations.of<AppLocalizations>(this, AppLocalizations) ?? englishStrings;
}
