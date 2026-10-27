/// Screenshot tour entries of the linked devices (see app/shots.dart): Settings › Linked devices
/// with no device, with a phone linked and one of its payments held, the link flow (code, paste,
/// pictures, done, failed), the other device's payments in Activity, Outputs and Send, and the
/// quiet link offers. The phone is a [MockPhone] over the mock wallet's fake pairing engine.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../devices/device_service.dart';
import '../../app/shots.dart';
import '../../data/devices_state.dart';
import '../../data/mock_devices.dart';
import '../../data/mock_wallet.dart';
import '../../widgets/kit.dart';
import '../../../help/help_content.dart' show HelpId;
import '../settings/backup.dart' show HistoryImportOfferDialog;
import '../settings/help_pairing.dart' show HelpAt;
import '../transfer/send_screen.dart' show SendArgs, SendStep;
import 'link_flow.dart';

/// The mock wallet and this computer's service, loaded.
Future<(MockDeskWallet, DeviceService)> _desk(ProviderContainer c) async {
  final wallet = c.read(deskApiProvider) as MockDeskWallet;
  final desk = c.read(deskDeviceServiceProvider)!;
  await desk.load();
  return (wallet, desk);
}

/// A phone linked to this computer; with [pay], paying [commitment] (7.5 EPIC) as it does.
Future<MockPhone> _linked(ProviderContainer c, {bool pay = false, bool ended = false, String? message}) async {
  final (wallet, desk) = await _desk(c);
  final phone = await MockPhone.create(wallet);
  await phone.link(desk);
  if (pay) await phone.makePayment(desk, commitment: mockCommitment(6), message: message ?? 'Rent for November');
  if (ended) await phone.end(desk, commitment: mockCommitment(6));
  await c.read(deskProvider.notifier).refresh();
  return phone;
}

Future<void> _linkedHeld(ProviderContainer c) async {
  await _linked(c, pay: true);
}

/// The link flow stopped at the four pictures, this computer showing the code.
Future<void> _checking(ProviderContainer c) async {
  final (wallet, desk) = await _desk(c);
  final phone = await MockPhone.create(wallet);
  await desk.startShowing(const ['epicbox.epiccash.com', 'epicbox.stackwallet.com']);
  await phone.scan(desk);
}

/// A device link this computer cannot read, answered.
Future<void> _failed(ProviderContainer c) async {
  final (_, desk) = await _desk(c);
  await desk.startScanned('epiccash://device-link/1/AAAA');
}

/// A server change waiting for the phone to accept.
Future<void> _proposal(ProviderContainer c) async {
  final (_, desk) = await _desk(c);
  await _linked(c);
  await desk.proposeServers(const ['epicbox.epiccash.com', 'flooepicbox.btlabs.uk']);
}

final List<DeskShot> deviceShots = [
  // Help › How linked devices work: the sync picture over the body, the live status panel under it
  // with the linked phone and the servers.
  DeskShot(id: '30h-settings-help-linked-devices', title: 'Help › How linked devices work: the sync picture, the body, the live status', route: DeskRoute.settingsHelp, arg: HelpAt.topic(HelpId.linkedDevices), height: 1700, prepare: (c, _) => _linked(c)),
  const DeskShot(id: '44a-devices-none', title: 'Settings › Linked devices, none linked', route: DeskRoute.settingsDevices),
  DeskShot(id: '44b-devices-linked', title: 'Settings › Linked devices, a phone and a held payment', route: DeskRoute.settingsDevices, height: 1100, prepare: (c, _) => _linkedHeld(c)),
  DeskShot(
    id: '44b-devices-linked-2474',
    title: 'Settings › Linked devices at 2474x1338',
    route: DeskRoute.settingsDevices,
    width: 2474,
    height: 1338,
    prepare: (c, _) => _linkedHeld(c),
  ),
  DeskShot(id: '44c-devices-servers-waiting', title: 'Linked devices, a server change waiting for the phone', route: DeskRoute.settingsDevices, prepare: (c, _) => _proposal(c)),
  DeskShot(id: '44d-link-show', title: 'Link a device, the code', route: DeskRoute.settingsDevices, dialog: (ctx) => showDeskLinkDevice(ctx)),
  DeskShot(id: '44e-link-paste', title: 'Link a device, paste a code', route: DeskRoute.settingsDevices, dialog: (ctx) => showDeskLinkDevice(ctx, paste: true)),
  DeskShot(id: '44f-link-check', title: 'Link a device, the four pictures', route: DeskRoute.settingsDevices, prepare: (c, _) => _checking(c), dialog: (ctx) => showDeskLinkDevice(ctx)),
  DeskShot(
    id: '44g-link-done',
    title: 'Link a device, linked',
    route: DeskRoute.settingsDevices,
    prepare: (c, _) async {
      await _linked(c);
    },
    dialog: (ctx) => showDeskLinkDevice(ctx),
  ),
  DeskShot(id: '44h-link-failed', title: 'Link a device, not a device code', route: DeskRoute.settingsDevices, prepare: (c, _) => _failed(c), dialog: (ctx) => showDeskLinkDevice(ctx, paste: true)),
  DeskShot(id: '44i-activity-device-row', title: 'Activity, a payment of the phone under way', route: DeskRoute.activity, prepare: (c, _) => _linkedHeld(c)),
  DeskShot(id: '44j-tx-device-details', title: 'Activity, details of the phone’s payment', route: DeskRoute.activity, arg: -100, prepare: (c, _) => _linkedHeld(c)),
  DeskShot(id: '44k-outputs-held', title: 'Outputs, a coin the phone’s payment holds', route: DeskRoute.outputs, prepare: (c, _) => _linkedHeld(c)),
  DeskShot(
    id: '44l-send-held',
    title: 'Send, the amount is held by the phone’s payment',
    route: DeskRoute.send,
    arg: const SendArgs(recipient: 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com', amount: '1280', step: SendStep.errors),
    prepare: (c, _) => _linkedHeld(c),
  ),
  DeskShot(
    id: '44m-activity-device-ended',
    title: 'Activity, the phone cancelled its payment',
    route: DeskRoute.activity,
    arg: -100,
    prepare: (c, _) async {
      await _linked(c, pay: true, ended: true);
    },
  ),
  DeskShot(id: '44n-history-offer', title: 'History offer after a restore, with the link offer', route: DeskRoute.overview, dialog: (ctx) => showEDialog<void>(ctx, builder: (_) => const HistoryImportOfferDialog())),
  const DeskShot(id: '44o-other-wallet-offer', title: 'Sent from another wallet, the details end with the link offer', route: DeskRoute.activity, arg: 107),
  const DeskShot(id: '44p-other-wallet-offer-in', title: 'Received by another wallet, the details end with the link offer', route: DeskRoute.activity, arg: 108),
];
