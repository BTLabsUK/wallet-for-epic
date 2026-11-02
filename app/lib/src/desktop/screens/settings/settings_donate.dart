// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../donate.dart';
import '../../../network_gate.dart' show NetGate;
import '../../../ui/network_mode_text.dart' show networkModeName;
import '../../data/files.dart' show deskOpenUrlProvider;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'settings_frame.dart';

/// Start states of Settings › Donate (tests, shots).
enum DonateDemo { noAnswer }

/// Settings › Donate (item 4): the donation page of `settings.toml` opens in the browser after
/// one check that it answers; when it does not, or no page is set, or the network mode lets
/// nothing connect, the donation address with Copy and QR, and the contact page.
class SettingsDonateScreen extends ConsumerStatefulWidget {
  const SettingsDonateScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsDonateScreen> createState() => _SettingsDonateScreenState();
}

class _SettingsDonateScreenState extends ConsumerState<SettingsDonateScreen> {
  /// The last check's answer; null before Open.
  late DonateCheck? _check = widget.arg == DonateDemo.noAnswer ? DonateCheck.noAnswer : null;
  bool _checking = false;

  Future<void> _open(DonateLink link) async {
    setState(() => _checking = true);
    final check = await ref.read(donateCheckProvider)(link);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _check = check;
    });
    if (check == DonateCheck.answers) {
      final opened = await ref.read(deskOpenUrlProvider)(link.page.toString());
      if (!opened && mounted) setState(() => _check = DonateCheck.noAnswer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final link = ref.watch(donateLinkProvider);
    // Node only and Kill switch: nothing is asked and the browser is not opened from here.
    final restricted = NetGate.restricted;
    final fallback = restricted || link.page == null || (_check != null && _check != DonateCheck.answers);
    final page = link.page;
    final contact = link.contact;
    final address = link.address;
    return SettingsFrame(
      route: DeskRoute.settingsDonate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.deskDonateLead, key: const ValueKey('donate-lead'), style: ts.bodyDim),
          SizedBox(height: Sp.x4),
          if (fallback && (page != null || restricted)) ...[
            ENotice(
              key: const ValueKey('donate-fallback'),
              icon: EIcons.info,
              title: restricted ? l.deskDonateOffInMode(networkModeName(l, NetGate.mode)) : l.deskDonateNoAnswer,
              text: address == null ? null : l.deskDonateNoAnswerText,
              actions: [
                if (contact != null && !restricted)
                  EButton(
                    key: const ValueKey('donate-contact'),
                    label: l.deskDonateContact,
                    icon: EIcons.external,
                    size: EBtnSize.sm,
                    onPressed: () => unawaited(ref.read(deskOpenUrlProvider)(contact.toString())),
                  ),
              ],
            ),
            SizedBox(height: Sp.x4),
          ],
          ESetGroup(
            rows: [
              if (page != null && !fallback)
                ESetRow(
                  title: l.deskDonatePage,
                  text: page.host,
                  control: ERowControl(
                    child: EButton.primary(
                      key: const ValueKey('donate-open'),
                      label: l.deskDonateOpen,
                      icon: EIcons.external,
                      size: EBtnSize.sm,
                      busy: _checking,
                      onPressed: _checking ? null : () => unawaited(_open(link)),
                    ),
                  ),
                ),
              if (page == null && contact != null && !restricted)
                ESetRow(
                  title: l.deskDonateContact,
                  text: contact.host,
                  control: ERowControl(
                    child: EButton(
                      key: const ValueKey('donate-contact-row'),
                      label: l.deskDonateOpen,
                      icon: EIcons.external,
                      size: EBtnSize.sm,
                      onPressed: () => unawaited(ref.read(deskOpenUrlProvider)(contact.toString())),
                    ),
                  ),
                ),
              if (address != null)
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
            ],
          ),
        ],
      ),
    );
  }
}
