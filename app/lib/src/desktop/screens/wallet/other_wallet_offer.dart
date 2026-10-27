/// The end of the details of a payment another wallet on this recovery phrase made ("Sent from
/// another wallet", "Received by another wallet"): the quiet offer to link this computer with
/// the other wallet. It shows while Linked devices is on, and not once the user switched it off.
library;

import 'package:flutter/widgets.dart';

import '../../desk_l10n.dart';
import '../devices/link_offer.dart';

class DeskSentFromOtherWalletOffer extends StatelessWidget {
  const DeskSentFromOtherWalletOffer({super.key, this.incoming = false});

  /// The row is a payment another wallet received, not one it sent.
  final bool incoming;

  @override
  Widget build(BuildContext context) =>
      DeskLinkOffer(text: incoming ? context.l10n.deskDevOfferReceived : context.l10n.offerLinkOtherWallet);
}
