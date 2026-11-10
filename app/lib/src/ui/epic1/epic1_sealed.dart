// SPDX-License-Identifier: Apache-2.0
/// The "Sealed with epic1" badge of a payment that went sealed between two wallets
/// ([TxEntry.sealed]), on the phone's and the desktop's history rows and details. It shows in
/// epic1 mode only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../epic1.dart' show PaymentMode;
import '../../l10n.dart';
import '../../models.dart' show TxEntry;
import '../../providers.dart' show paymentModeProvider;
import '../badge.dart';
import '../status_icons.dart' show EpicGlyphs;

/// The key of the badge, for tests.
const Key epic1SealedKey = ValueKey('epic1-sealed');

/// Whether the phone shows [tx] as sealed: epic1 mode is in use and it was sealed.
bool phoneShowsSealed(WidgetRef ref, TxEntry tx) =>
    tx.sealed && ref.watch(paymentModeProvider) == PaymentMode.epic1;

/// The badge: the lock in the neutral tone. [compact] is the lock alone for a list row, with
/// the words in its tooltip; the row's own spoken label says them, so it adds none.
class Epic1SealedBadge extends StatelessWidget {
  const Epic1SealedBadge({super.key = epic1SealedKey, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final words = context.l10n.deskE1Sealed;
    if (!compact) return EBadge(words, icon: EpicGlyphs.sealed, wrap: true);
    return ExcludeSemantics(
      child: EBadge(null, icon: EpicGlyphs.sealed, semanticsLabel: words, tooltip: words),
    );
  }
}
