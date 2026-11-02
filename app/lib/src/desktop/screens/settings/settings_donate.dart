// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../donate.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../wallet/contacts_screen.dart' show ContactsArgs;
import 'settings_frame.dart';

/// Settings › Donate (item 4): the donation address with Copy and QR, and BT Labs' contact,
/// opened in Contacts, while this wallet's Contacts hold it. Opening the page asks nothing on
/// the network.
class SettingsDonateScreen extends ConsumerWidget {
  const SettingsDonateScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ts = context.ts;
    final address = ref.watch(donateLinkProvider).address;
    final contacts = ref.watch(deskProvider.select((s) => s.contacts));
    final contact = donateContactIn(contacts ?? const [], address, (c) => c.epicbox);
    return SettingsFrame(
      route: DeskRoute.settingsDonate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.deskDonateLead, key: const ValueKey('donate-lead'), style: ts.bodyDim),
          SizedBox(height: Sp.x4),
          // No address in app-config.toml: the lead alone, nothing broken.
          if (address != null)
            ESetGroup(
              rows: [
                ESetRow(
                  title: l.deskDonateAddress,
                  stacked: true,
                  control: EQrReveal(
                    key: const ValueKey('donate-address'),
                    address: address,
                    form: QrRevealForm.compact,
                    title: l.deskDonateAddressQr,
                    copyLabel: l.deskDonateCopy,
                    method: 'donate',
                  ),
                ),
                if (contact != null)
                  ESetRow(
                    title: contact.name,
                    text: l.deskDonateInContacts,
                    control: ERowControl(
                      child: EButton(
                        key: const ValueKey('donate-contact'),
                        label: l.deskDonateOpen,
                        icon: EIcons.contacts,
                        size: EBtnSize.sm,
                        onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.contacts, ContactsArgs(selectedId: contact.id)),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
