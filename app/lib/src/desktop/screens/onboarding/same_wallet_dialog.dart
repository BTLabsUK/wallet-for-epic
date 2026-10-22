import 'package:flutter/material.dart';

import '../../widgets/kit.dart';

/// "This wallet is already here" (O1): the restore phrase belongs to [wallet], which is in the
/// list, so nothing was made. True when the user chose to open it; false for Cancel.
Future<bool> showSameWalletDialog(BuildContext context, WalletEntry wallet) async =>
    await showEDialog<bool>(context, builder: (_) => SameWalletDialog(wallet)) ?? false;

class SameWalletDialog extends StatelessWidget {
  const SameWalletDialog(this.wallet, {super.key});

  final WalletEntry wallet;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return EDialog(
      title: 'This wallet is already here',
      description: 'The phrase belongs to a wallet in the list. Nothing was added.',
      icon: EIcons.wallet,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'Wallet',
            container: true,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x3),
              decoration: BoxDecoration(
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(Rad.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.u),
                    child: Icon(EIcons.wallet, size: Ctl.iconSm, color: c.dim),
                  ),
                  SizedBox(width: Sp.x2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(wallet.name, style: ts.body),
                        SizedBox(height: 2.u),
                        Text(wallet.folder, style: ts.mono().copyWith(color: c.faint)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: Sp.x3),
          Text('Open it asks for that wallet\'s password. Cancel keeps the phrase on the grid.', style: ts.small),
        ],
      ),
      actions: [
        EButton.ghost(label: 'Cancel', onPressed: () => Navigator.pop(context, false)),
        EButton.primary(label: 'Open it', onPressed: () => Navigator.pop(context, true)),
      ],
    );
  }
}
