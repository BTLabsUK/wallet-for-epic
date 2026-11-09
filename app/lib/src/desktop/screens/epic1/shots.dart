// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shots.dart';
import '../../data/mock_wallet.dart' show MockDeskWallet;
import '../../widgets/kit.dart';
import '../settings/prefs.dart' show settingsPrefsProvider;
import '../settings/setting_ids.dart';
import '../settings/shots.dart' show tapShotKey;
import '../transfer/contact_picker.dart' show showContactPickerDialog;
import '../transfer/send_screen.dart' show SendArgs;
import '../wallet/contacts_screen.dart' show ContactsArgs;
import 'epic1_settings.dart' show askTurnOnEpic1;

const _link = 'epic:epic1qtestlink0000000000000000000000000000?amount=150000000';

/// epic1 payments: [stored] is the switch's value, [inUse] the mode the wallet opened in.
Future<void> Function(ProviderContainer) _epic1({bool stored = true, bool inUse = true}) => (c) async {
  final e1 = (c.read(deskApiProvider) as MockDeskWallet).epic1Fake;
  await e1.setStoredOn(inUse);
  e1.reopen();
  if (stored != inUse) await e1.setStoredOn(stored);
};

/// Settings › Transactions scrolled to the epic1 payments switch.
Future<void> _toSwitch(ProviderContainer c, BuildContext _) async => c.read(settingsPrefsProvider.notifier).jumpToRow(SetId.epic1Payments);

/// Screenshot tour entries for epic1 payments (see app/shots.dart).
final List<DeskShot> epic1Shots = [
  DeskShot(id: '60-e1-settings-off', title: 'Settings › Transactions, epic1 payments off (classic)', route: DeskRoute.settingsReceiving, prepare: _toSwitch),
  DeskShot(id: '60b-e1-turn-on', title: 'Turning epic1 payments on: the confirm', route: DeskRoute.settingsReceiving, prepare: _toSwitch, dialog: (ctx) => askTurnOnEpic1(ctx)),
  DeskShot(id: '60c-e1-settings-pending', title: 'epic1 payments on, Applies at next unlock', route: DeskRoute.settingsReceiving, before: _epic1(inUse: false), prepare: _toSwitch),
  DeskShot(id: '60d-e1-settings-on', title: 'Settings › Transactions in epic1 mode', route: DeskRoute.settingsReceiving, before: _epic1(), height: 1000),
  DeskShot(id: '60e-e1-settings-turning-off', title: 'epic1 payments turned off in epic1 mode, Applies at next unlock', route: DeskRoute.settingsReceiving, before: _epic1(stored: false), prepare: _toSwitch),
  DeskShot(id: '61-e1-receive', title: 'Receive in epic1 mode: the link card, QR covered', route: DeskRoute.receive, before: _epic1()),
  DeskShot(id: '61b-e1-receive-qr', title: 'Receive in epic1 mode: the QR shown', route: DeskRoute.receive, before: _epic1(), prepare: (_, ctx) async => tapShotKey(ctx, const ValueKey('rx-qr-epic1'))),
  DeskShot(id: '62-e1-send', title: 'Send in epic1 mode', route: DeskRoute.send, before: _epic1()),
  DeskShot(id: '62b-e1-send-review', title: 'Send in epic1 mode: review with the server', route: DeskRoute.send, arg: const SendArgs(code: _link), before: _epic1(), prepare: (_, ctx) async => tapShotKey(ctx, const ValueKey('e1-review'))),
  DeskShot(
    id: '62c-e1-send-waiting',
    title: 'Send in epic1 mode: waiting for the recipient',
    route: DeskRoute.send,
    arg: const SendArgs(code: _link),
    before: _epic1(),
    prepare: (_, ctx) async => tapShotKey(ctx, const ValueKey('e1-review')),
    after: (_, ctx) async => tapShotKey(ctx, const ValueKey('e1-send')),
  ),
  DeskShot(id: '63-e1-picker', title: 'Contact picker in epic1 mode: Classic only', route: DeskRoute.send, before: _epic1(), dialog: showContactPickerDialog),
  DeskShot(id: '63b-e1-contact', title: 'Contact page in epic1 mode: Classic only', route: DeskRoute.contacts, arg: const ContactsArgs(selectedId: 'c1'), before: _epic1()),
];
