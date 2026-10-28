import 'package:flutter/material.dart';

import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// What the user chose in [SameWalletDialog].
enum SameWalletChoice { cancel, open, newPassword }

/// "This wallet is already here": the restore phrase belongs to [wallet], which is in the
/// list, so nothing was made. Open it, set a new password with this phrase, or Cancel.
Future<SameWalletChoice> showSameWalletDialog(BuildContext context, WalletEntry wallet) async =>
    await showEDialog<SameWalletChoice>(context, builder: (_) => SameWalletDialog(wallet)) ?? SameWalletChoice.cancel;

class SameWalletDialog extends StatelessWidget {
  const SameWalletDialog(this.wallet, {super.key});

  final WalletEntry wallet;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    return EDialog(
      title: l.deskOnbSameTitle,
      description: l.deskOnbSameBody,
      icon: EIcons.wallet,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: l.deskOnbSameWallet,
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
          Text(l.deskOnbSameNote, style: ts.small),
        ],
      ),
      actions: [
        EButton.ghost(label: l.commonCancel, onPressed: () => Navigator.pop(context, SameWalletChoice.cancel)),
        EButton(key: const ValueKey('same-wallet-new-password'), label: l.deskOnbSameNewPassword, onPressed: () => Navigator.pop(context, SameWalletChoice.newPassword)),
        EButton.primary(label: l.deskOnbSameOpen, onPressed: () => Navigator.pop(context, SameWalletChoice.open)),
      ],
    );
  }
}
