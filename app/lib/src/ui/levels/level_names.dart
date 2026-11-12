// SPDX-License-Identifier: Apache-2.0
/// The names and one-liners of the three levels. The desktop's depth dial and its settings search
/// use them; the phone has no level (HANDOFF §8).
library;

import '../../l10n.dart';
import '../../levels/wallet_level.dart';

String levelStopName(AppLocalizations l, WalletLevel level) => switch (level) {
  WalletLevel.justSendReceive => l.lvPickStopOne,
  WalletLevel.casual => l.lvPickStopTwo,
  WalletLevel.everything => l.lvPickStopThree,
};

String levelLine(AppLocalizations l, WalletLevel level) => switch (level) {
  WalletLevel.justSendReceive => l.lvPickLineOne,
  WalletLevel.casual => l.lvPickLineTwo,
  WalletLevel.everything => l.lvPickLineThree,
};
