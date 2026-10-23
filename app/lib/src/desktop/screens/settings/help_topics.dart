/// The desktop's help topics: the content lives in `lib/src/help/help_content.dart`, shared
/// with the phone, and this file keeps the desktop's names.
library;

import '../../../help/help_content.dart';
import '../../data/features.dart';

export '../../../help/help_content.dart';

/// The topics, with [confirmations] as the open wallet's balance counts them
/// (`deskMinConfirmations`).
List<HelpTopic> helpTopicsFor(int confirmations) =>
    helpTopics(confirmations, platform: HelpPlatform.desktop, tor: DeskFeatures.tor);
