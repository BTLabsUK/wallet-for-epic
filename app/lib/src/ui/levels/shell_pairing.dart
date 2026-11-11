// SPDX-License-Identifier: Apache-2.0
/// A pairing request at level 1 ([LevelFeatures.incomingPairingPrompt] without the pairing
/// screens): an invite link handed to the app becomes a notice, "Anna wants to pair with this
/// wallet.", with See request (today's Accept / Not now sheet, [showIncomingInvite]) and Not
/// now, instead of opening the sheet over whatever is on screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../../pairing_text.dart' show InviteSource;
import '../../levels/level_providers.dart';
import '../../pairing_api.dart' show PairingLinkKind, pairingLinkIn, pairingLinkKind;
import '../../pairing_providers.dart';
import '../notices.dart';
import '../pairing/pair_incoming.dart' show showIncomingInvite;

/// The tag of the request's notice.
const String pairRequestNoticeTag = 'pair-request';

/// Shows [text]'s invite as a notice when the level asks for one. False when it does not
/// (another level, not an invite, an invite that does not open): the caller opens [text] as
/// today, which also says why an invite does not open.
Future<bool> offerPairRequest(BuildContext context, WidgetRef ref, String text) async {
  final f = ref.read(levelFeaturesProvider);
  if (f.pairingSetupScreens || !f.incomingPairingPrompt) return false;
  if (pairingLinkKind(text) != PairingLinkKind.invite) return false;
  final api = ref.read(pairingApiProvider);
  if (!api.supported) return false;
  final l = context.l10n;
  final notices = ref.read(noticeProvider.notifier);
  try {
    final preview = await api.openInvite(pairingLinkIn(text)!);
    if (!context.mounted) return true;
    notices.show(
      l.lvShellPairNotice(preview.name),
      level: NoticeLevel.info,
      persistent: true,
      tag: pairRequestNoticeTag,
      action: NoticeAction(l.lvShellSeeRequest, () {
        if (context.mounted) showIncomingInvite(context, ref, preview, source: InviteSource.opened);
      }),
      secondary: NoticeAction(l.pairNotNow, () {}),
    );
    return true;
  } on Object {
    return false;
  }
}
