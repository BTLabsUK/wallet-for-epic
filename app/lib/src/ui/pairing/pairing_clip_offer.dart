// SPDX-License-Identifier: Apache-2.0
/// What the phone's pairing screens share around the three messages of Invite by message: the
/// steps on screen and the share sheet. The clipboard is read on a press only (Paste reply,
/// Paste finish link, Paste link, the field's paste icon), never by itself.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../../slate_files.dart';
import '../common.dart';

/// The pairings whose message step is up (the inviter's wait for the reply, the joiner's reply
/// and wait for the finish link), each with whether it is the screen on top: a link for one on
/// top, pasted, leaves the next screen to that step, which moves on by itself.
final Map<String, bool Function()> pairingStepsOnScreen = {};

/// Shares one of the three messages ([text]) on the share sheet, or copies it with [copy] or
/// where there is none.
Future<void> sharePairingMessage(BuildContext context, WidgetRef ref, String text, {bool copy = false}) async {
  final l = context.l10n;
  final files = ref.read(slateFilesProvider);
  if (copy || !files.canShareText) {
    await copySecretText(context, text, l.pairMessageCopied);
  } else {
    await files.shareText(text);
  }
}
