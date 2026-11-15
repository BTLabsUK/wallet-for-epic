// SPDX-License-Identifier: Apache-2.0
/// What the phone's epic1 screens share: the stop for an epic1 thing while epic1 is off, and
/// the wallet's own relay for links.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../../models.dart' show Contact, PairingRecord;
import '../../net/local_address.dart';
import '../../network.dart' show EpicboxRelay;
import '../../providers.dart';
import '../app_dialog.dart';
import '../phone_sheet.dart';
import '../settings_sections.dart';

/// Opens Settings › Transactions, where the epic1 switch is.
Future<void> openEpic1Settings(BuildContext context) => openSettingsSection(context, SettingsSection.transactions);

/// An epic1 link, code or file while epic1 is off: "epic1 is off" in a sheet with Settings and
/// Close.
Future<void> showEpic1OffSheet(BuildContext context) async {
  final settings = await showPhoneSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l = context.l10n;
      final line = l.netBlockMethodOff(l.deskE1SetSwitch);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(line, key: epic1ModeLineKey, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  DialogButton.secondary(label: l.commonClose, onPressed: () => Navigator.pop(context, false)),
                  DialogButton.primary(
                    key: epic1ModeSettingsKey,
                    label: l.deskE1PhSettings,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  if (settings == true && context.mounted) await openEpic1Settings(context);
}

/// The keys of the stop's sheet, for tests.
const Key epic1ModeLineKey = ValueKey('epic1-mode-line');
const Key epic1ModeSettingsKey = ValueKey('epic1-mode-settings');

/// Whether [contact] can be paid the classic way: an address of a method, or a pairing that
/// pays through its mailbox. A contact with only an epic1 link has none: it is paid by the link
/// while epic1 is on, and cannot be paid while it is off.
bool contactHasClassicWay(Contact contact, PairingRecord? pairing) =>
    contact.methodKinds.isNotEmpty || (pairing?.paysByMailbox ?? false);

/// The wallet's Epicbox server, as a link names it.
EpicboxRelay? epic1OwnRelay(WidgetRef ref) {
  final config = ref.read(walletConfigProvider);
  return config == null ? null : EpicboxRelay(host: config.epicboxDomain, port: config.epicboxPort);
}

/// Where the wallet's Epicbox server is, for links (spec decision 12).
enum Epic1RelayPlace {
  /// On this device: refused for links (`deskE1ErrOwnRelayLocal`).
  thisDevice,

  /// On the local network: allowed after a prompt.
  localNetwork,

  /// Anywhere else.
  internet,
}

/// Where [host] is, for links.
Epic1RelayPlace epic1RelayPlace(String host) {
  final h = host.trim().toLowerCase();
  if (h == 'localhost' || isLoopbackIp(h)) return Epic1RelayPlace.thisDevice;
  if (hostKind(h) == HostKind.local || isLocalNetworkName(h) || isCgnatIp(h)) return Epic1RelayPlace.localNetwork;
  return Epic1RelayPlace.internet;
}

/// A two-button question: [yes] (primary) or Cancel. True on [yes].
Future<bool> askEpic1(
  BuildContext context, {
  required String title,
  required String body,
  required String yes,
  String? no,
  IconData? icon,
  DialogTone tone = DialogTone.neutral,
  Key? yesKey,
}) async {
  final l = context.l10n;
  final answer = await showAppDialog<bool>(
    context,
    builder: (context) => AppDialog(
      title: title,
      icon: icon,
      tone: tone,
      description: body,
      actions: [
        DialogButton.secondary(label: no ?? l.commonCancel, onPressed: () => Navigator.pop(context, false)),
        DialogButton.primary(key: yesKey, label: yes, onPressed: () => Navigator.pop(context, true)),
      ],
    ),
  );
  return answer == true;
}
