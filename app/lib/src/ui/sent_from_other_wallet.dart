// SPDX-License-Identifier: Apache-2.0
/// The end of the details of a payment another wallet on this recovery phrase made ("Sent from
/// another wallet", "Received by another wallet"): the quiet offer to link this device with the
/// other wallet.
library;

import 'package:flutter/widgets.dart';

import '../l10n.dart';
import 'devices/device_parts.dart';

class SentFromOtherWalletOffer extends StatelessWidget {
  const SentFromOtherWalletOffer({super.key});

  @override
  Widget build(BuildContext context) => LinkDeviceOffer(text: context.l10n.offerLinkOtherWallet);
}
