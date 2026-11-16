// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shots.dart';
import '../../widgets/kit.dart';
import '../settings/prefs.dart' show settingsPrefsProvider;
import '../settings/setting_ids.dart';
import '../settings/shots.dart' show tapShotKey;
import '../transfer/contact_picker.dart' show showContactPickerDialog;
import '../transfer/send_screen.dart' show SendArgs;
import '../wallet/contacts_screen.dart' show ContactsArgs;

const _link = 'epic:epic1qtestlink0000000000000000000000000000?amount=150000000';

/// The epic1 payment method switch, set through the payment settings (on by default).
Future<void> Function(ProviderContainer) _epic1({bool on = true}) => (c) async {
  final n = c.read(deskProvider.notifier);
  final s = c.read(deskProvider).settings;
  await n.saveSettings(s.copyWith(payments: s.payments.copyWith(epic1: on)));
};

/// Settings › Transactions scrolled to the epic1 method row.
Future<void> _toSwitch(ProviderContainer c, BuildContext _) async => c.read(settingsPrefsProvider.notifier).jumpToRow(SetId.epic1Payments);

/// Screenshot tour entries for epic1 payments (see app/shots.dart).
final List<DeskShot> epic1Shots = [
  DeskShot(id: '60-e1-settings-off', title: 'Settings › Transactions, epic1 off', route: DeskRoute.settingsReceiving, before: _epic1(on: false), prepare: _toSwitch),
  DeskShot(id: '60d-e1-settings-on', title: 'Settings › Transactions, epic1 on beside the other methods', route: DeskRoute.settingsReceiving, before: _epic1(), prepare: _toSwitch),
  DeskShot(id: '61-e1-receive', title: 'Receive: the classic address, the epic1 panel closed among the other ways', route: DeskRoute.receive, before: _epic1()),
  DeskShot(id: '61b-e1-receive-link', title: 'Receive: the epic1 link made', route: DeskRoute.receive, before: _epic1(), prepare: (_, ctx) async => tapShotKey(ctx, const ValueKey('e1-open-link'))),
  DeskShot(id: '62-e1-send', title: 'Send: the classic form, epic1 on', route: DeskRoute.send, before: _epic1()),
  DeskShot(id: '62a-e1-send-link', title: 'Send an epic1 link: the link read', route: DeskRoute.send, arg: const SendArgs(code: _link), before: _epic1()),
  DeskShot(id: '62b-e1-send-review', title: 'Send an epic1 link: review with the server', route: DeskRoute.send, arg: const SendArgs(code: _link), before: _epic1(), prepare: (_, ctx) async => tapShotKey(ctx, const ValueKey('e1-review'))),
  DeskShot(
    id: '62c-e1-send-waiting',
    title: 'Send an epic1 link: Payment sent, the page waiting under it',
    route: DeskRoute.send,
    arg: const SendArgs(code: _link),
    before: _epic1(),
    prepare: (_, ctx) async => tapShotKey(ctx, const ValueKey('e1-review')),
    after: (_, ctx) async => tapShotKey(ctx, const ValueKey('e1-send')),
  ),
  DeskShot(id: '62d-e1-send-off', title: 'Send an epic1 link with epic1 off: the stop', route: DeskRoute.send, arg: const SendArgs(code: _link), before: _epic1(on: false)),
  DeskShot(id: '63-e1-picker', title: 'Contact picker, epic1 on', route: DeskRoute.send, before: _epic1(), dialog: showContactPickerDialog),
  DeskShot(id: '63b-e1-contact', title: 'Contact page, epic1 on', route: DeskRoute.contacts, arg: const ContactsArgs(selectedId: 'c1'), before: _epic1()),
];
