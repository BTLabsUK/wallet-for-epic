// SPDX-License-Identifier: Apache-2.0
/// What the phone's epic1 screens share (spec sections 3 and 4): the mode lines' sheet, the
/// "Classic only" check of a contact, and the wallet's own relay for links.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contacts.dart' show contactsProvider;
import '../../epic1.dart';
import '../../l10n.dart';
import '../../models.dart' show PairingRecord;
import '../../net/local_address.dart';
import '../../network.dart' show EpicboxRelay;
import '../../pairing_providers.dart';
import '../../providers.dart';
import '../app_dialog.dart';
import '../phone_sheet.dart';
import '../settings_sections.dart';
import '../theme/tokens.dart';

/// Opens Settings › Transactions, where the epic1 switch is.
Future<void> openEpic1Settings(BuildContext context) => openSettingsSection(context, SettingsSection.transactions);

/// A text, code or file of the other mode: [line] (a `deskE1Mode…` string) in a sheet with
/// [Settings] and [Close].
Future<void> showEpic1ModeSheet(BuildContext context, String line) async {
  final settings = await showPhoneSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l = context.l10n;
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

/// The keys of the mode sheet, for tests.
const Key epic1ModeLineKey = ValueKey('epic1-mode-line');
const Key epic1ModeSettingsKey = ValueKey('epic1-mode-settings');

/// Whether [pairing] cannot be paid in epic1 mode: no pairing, or one that takes classic
/// slates only.
bool classicOnlyPairing(PairingRecord? pairing) => pairing == null || !pairing.nativeSlates;

/// The contact [contactId] is "Classic only" now: epic1 mode is in use and it has neither a
/// pairing that takes epic1 payments (spec D3, D7) nor an epic1 link.
final classicOnlyProvider = Provider.family<bool, String>((ref, contactId) {
  if (ref.watch(paymentModeProvider) != PaymentMode.epic1) return false;
  final contact = ref.watch(contactsProvider).value?.where((c) => c.id == contactId).firstOrNull;
  if (contact?.epic1 != null) return false;
  return classicOnlyPairing(ref.watch(contactPairingProvider(contactId)));
});

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

/// A muted "Classic only" line, as the picker and the contact page show it.
class ClassicOnlyText extends StatelessWidget {
  const ClassicOnlyText({super.key, this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(
    context.l10n.deskE1ClassicOnly,
    key: classicOnlyKey,
    style: (style ?? Theme.of(context).textTheme.bodySmall)?.copyWith(color: context.tokens.dim),
  );
}

/// The key of a "Classic only" line, for tests.
const Key classicOnlyKey = ValueKey('epic1-classic-only');

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
