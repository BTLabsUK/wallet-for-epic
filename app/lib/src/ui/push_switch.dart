/// The payment-notifications switch: a row at the bottom of Settings › Advanced, marked
/// Experimental. Turning it on asks once, and moves the wallet to the BT Labs Epicbox first
/// when it is on another relay (only that relay can push).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../demo.dart';
import '../l10n.dart';
import '../network.dart';
import '../phone_tor.dart';
import '../providers.dart';
import '../push.dart';
import '../push_controller.dart';
import '../push_registration.dart';
import '../server_switch.dart';
import '../settings.dart';
import '../tor_phone.dart';
import '../tor_routes.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'info_hint.dart';

/// The key of the push notifications switch, for tests.
const Key settingsPushKey = ValueKey('settings-push');

/// The Notifications row's state line, only when there is a state to say: paused by Tor, or
/// why the switch went back off.
String? pushStateLine(
  AppLocalizations l,
  PushState push,
  AppSettings settings,
  TorState tor,
) {
  if (torWay(TorRoute.push, tor) == TorWay.off) {
    return settings.pushNotifications ? l.settingsPushPaused : null;
  }
  return push.blocked
      ? l.settingsPushBlocked
      : push.unavailable
      ? l.settingsPushUnavailable
      : null;
}

/// On: one confirm, then the registration. Only the BT Labs relay can push, so a wallet on
/// another relay is told so, and that its Epicbox address changes, and is moved there live
/// first. Off never moves the relay back.
Future<void> setPushNotifications(
  BuildContext context,
  WidgetRef ref,
  bool on,
) async {
  final push = ref.read(pushControllerProvider.notifier);
  if (!on) return push.turnOff();
  final l = context.l10n;
  final config = ref.read(walletConfigProvider);
  final moveRelay =
      config != null && config.epicboxDomain != PushRegistration.relayHost;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.pushConfirmTitle),
      content: moveRelay
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.pushConfirmRelayBody),
                const SizedBox(height: 12),
                Text(l.pushConfirmRelayAddress),
              ],
            )
          : Text(l.pushConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l.pushConfirmAction),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  if (moveRelay) {
    try {
      await switchServersLive(
        ref,
        nodeUrl: config.nodeUrl,
        nodeApiSecret: config.nodeApiSecret,
        relay: const EpicboxRelay(host: PushRegistration.relayHost),
      );
    } on WalletError catch (e) {
      logWarn('push', 'relay switch refused: ${e.kind.name}');
      if (context.mounted) {
        ref
            .read(noticeProvider.notifier)
            .show(l.pushRelaySwitchFailed, level: NoticeLevel.error);
      }
      return;
    }
    if (!context.mounted) return;
  }
  await push.turnOn();
}

/// The Notifications row of Advanced, nothing where the phone cannot push (the demo, a build
/// without a notification service). Tor on pauses them (a registration would show this
/// phone's address): turning them off still works, turning them on is not offered.
class PushNotificationsTile extends ConsumerWidget {
  const PushNotificationsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offered =
        !ref.watch(demoModeProvider) &&
        (ref.watch(pushConfiguredProvider).value ?? false);
    if (!offered) return const SizedBox.shrink();
    final l = context.l10n;
    final s = ref.watch(appSettingsProvider).value ?? const AppSettings();
    final torState = phoneTorState(ref.watch(phoneTorProvider));
    final state = pushStateLine(l, ref.watch(pushProvider), s, torState);
    return HintSwitchTile(
      key: settingsPushKey,
      icon: Icons.notifications_outlined,
      title: l.settingsNotifications,
      hint: l.settingsNotificationsHint,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [EBadge(l.advExperimental)]),
          ),
          if (state != null) Text(state),
        ],
      ),
      value: s.pushNotifications,
      onChanged:
          torWay(TorRoute.push, torState) == TorWay.off &&
              !s.pushNotifications
          ? null
          : (on) => setPushNotifications(context, ref, on),
    );
  }
}
