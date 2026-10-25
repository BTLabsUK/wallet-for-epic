import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tor_routes.dart';
import '../../app/shots.dart';
import '../../widgets/kit.dart';
import 'contact_picker.dart';
import 'finalize_screen.dart';
import 'import_tx_screen.dart';
import 'receive_screen.dart';
import 'send_code.dart' show CodeOrigin;
import 'send_screen.dart';

const _onion = 'http://wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid.onion';
const _anna = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';
// No saved contact has it.
const _payee = 'esTk4wRm8Nq2Vx7Lc5Bh9Jd3Fg6Hs1Ka8Pz4Yu2Wn7Ec5Rt9Q@epicbox.epiccash.com';
const _request = 'epic:$_payee?amount=12.5&message=Table%204%2C%20lunch%20for%20two&label=Corner%20Caf%C3%A9';

/// Screenshot tour entries of this group (see app/shots.dart). Ids match the Electron
/// reference shots.
final List<DeskShot> transferShots = [
  const DeskShot(id: '13-send', title: 'Send', route: DeskRoute.send),
  DeskShot(id: '13-send-narrow', title: 'Send at 1000x700', route: DeskRoute.send, width: 1000, height: 700),
  const DeskShot(id: '13b-send-node-syncing', title: 'Send, node not synced', route: DeskRoute.send, arg: SendArgs(nodeSync: 0.62, recipient: _anna, amount: '12.5')),
  const DeskShot(id: '13c-send-epicbox-off', title: 'Send, Epicbox not connected', route: DeskRoute.send, arg: SendArgs(epicboxHealth: ServiceHealth.off)),
  const DeskShot(id: '13d-send-epicbox-down', title: 'Send, Epicbox down', route: DeskRoute.send, arg: SendArgs(epicboxHealth: ServiceHealth.down)),
  const DeskShot(id: '13e-send-privacy', title: 'Send, privacy open', route: DeskRoute.send, arg: SendArgs(privacyOpen: true, recipient: _anna, amount: '12.5')),
  const DeskShot(id: '13f-send-suggestions', title: 'Send, matching contacts', route: DeskRoute.send, arg: SendArgs(recipient: 'an', suggest: true)),
  DeskShot(id: '13g-send-http', title: 'Send, Link · HTTP', route: DeskRoute.send, arg: const SendArgs(method: TxMethod.http, recipient: 'http://10.0.1.24:3415', amount: '5'), prepare: (c, _) => _linkOn(c)),
  DeskShot(id: '13u-send-http-off', title: 'Send, Link · HTTP off, a contact with only that address', route: DeskRoute.send, arg: const SendArgs(method: TxMethod.http, recipient: 'http://10.0.1.24:3415', amount: '5'), prepare: (c, _) => _linkOff(c)),
  const DeskShot(id: '13j-send-summary', title: 'Send, summary with what stays spendable', route: DeskRoute.send, arg: SendArgs(recipient: _anna, amount: '25'), height: 900),
  const DeskShot(id: '13k-send-advanced', title: 'Send, Advanced open', route: DeskRoute.send, arg: SendArgs(recipient: _anna, amount: '25', advancedOpen: true), height: 1000),
  const DeskShot(
    id: '13l-send-all-strategy',
    title: 'Send, strategy All for this send',
    route: DeskRoute.send,
    arg: SendArgs(recipient: _anna, amount: '25', strategy: SelectionStrategy.all, advancedOpen: true),
    height: 1000,
  ),
  const DeskShot(id: '13n-review-lock', title: 'Send, review with the lock', route: DeskRoute.send, arg: SendArgs(recipient: _anna, amount: '25', step: SendStep.review)),
  const DeskShot(id: '13h-send-tor-off', title: 'Send, onion with Tor off', route: DeskRoute.send, arg: SendArgs(method: TxMethod.http, recipient: _onion, amount: '5')),
  const DeskShot(id: '13o-send-tor-starting', title: 'Send, Tor starting', route: DeskRoute.send, arg: SendArgs(recipient: _anna, amount: '12.5', tor: TorState.starting)),
  const DeskShot(id: '13p-send-tor-failed', title: 'Send, Tor not connected', route: DeskRoute.send, arg: SendArgs(method: TxMethod.http, recipient: _onion, amount: '5', tor: TorState.failed)),
  DeskShot(id: '13q-send-http-tor-on', title: 'Send, Link · HTTP with Tor on', route: DeskRoute.send, arg: const SendArgs(method: TxMethod.http, recipient: 'https://pay.example.org:3415', amount: '5', tor: TorState.on), prepare: (c, _) => _linkOn(c)),
  DeskShot(id: '13r-send-onion-tor-on', title: 'Send, Link · Tor over Tor', route: DeskRoute.send, arg: const SendArgs(method: TxMethod.http, recipient: _onion, amount: '5', tor: TorState.on), prepare: (c, _) => _linkOn(c)),
  const DeskShot(
    id: '13i-send-switched',
    title: 'Send, Direct set by a pasted onion',
    route: DeskRoute.send,
    arg: SendArgs(recipient: 'http://WFE7Q3K2MZ5XR4TBV6LD5YHNPJC7SGO2A3UE6IWQ4FK7TR3MXZABCDID.ONION/', switched: true),
  ),
  const DeskShot(id: '15-send-file', title: 'Send, file', route: DeskRoute.send, arg: SendArgs(method: TxMethod.file, amount: '12.5')),
  const DeskShot(id: '15b-send-errors', title: 'Send, validation errors', route: DeskRoute.send, arg: SendArgs(step: SendStep.errors, recipient: 'not an address', amount: '0.123456789')),
  const DeskShot(id: '16-send-review', title: 'Send, review', route: DeskRoute.send, arg: SendArgs(step: SendStep.review, recipient: _anna, amount: '12.5', message: 'Invoice 0042')),
  const DeskShot(id: '16b-send-sending', title: 'Send, sending', route: DeskRoute.send, arg: SendArgs(step: SendStep.sending, recipient: _anna, amount: '12.5', message: 'Invoice 0042')),
  const DeskShot(id: '16c-send-done', title: 'Send, done', route: DeskRoute.send, arg: SendArgs(step: SendStep.done, recipient: _anna, amount: '12.5')),
  const DeskShot(id: '16d-send-file-ready', title: 'Send, file ready', route: DeskRoute.send, arg: SendArgs(step: SendStep.fileReady, amount: '12.5')),
  // A pasted `epic:` payment request (epic-uri ui.md §2–§5).
  const DeskShot(id: '13s-send-code', title: 'Send, pasted payment request', route: DeskRoute.send, arg: SendArgs(code: _request, codeOrigin: CodeOrigin.paste)),
  const DeskShot(
    id: '13t-send-code-problems',
    title: 'Send, payment request with a dropped amount',
    route: DeskRoute.send,
    arg: SendArgs(code: 'epic:$_payee?amount=0&message=Table%204%2C%20lunch%20for%20two', codeOrigin: CodeOrigin.paste),
  ),
  // The review waits for the estimate: a moment of real time before the shot.
  DeskShot(
    id: '16e-send-review-code',
    title: 'Send, review of a pasted request',
    route: DeskRoute.send,
    arg: const SendArgs(step: SendStep.review, code: _request, codeOrigin: CodeOrigin.paste),
    height: 1000,
    prepare: (_, _) => Future<void>.delayed(const Duration(milliseconds: 800)),
  ),
  DeskShot(
    id: '16f-send-review-code-direct',
    title: 'Send, review of a Link request from a link',
    route: DeskRoute.send,
    arg: const SendArgs(step: SendStep.review, code: 'epic:https://pay.example.org:3415?amount=5&label=Corner%20Caf%C3%A9'),
    height: 1000,
    prepare: (_, _) => Future<void>.delayed(const Duration(milliseconds: 800)),
  ),
  const DeskShot(id: '16e-send-failed', title: 'Send, failed', route: DeskRoute.send, arg: SendArgs(step: SendStep.failed, recipient: 'esNffxine9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9r@epicbox.offline.example', amount: '3')),
  // The Epicbox switch (Settings › Transactions) off: no relay connection, no address on
  // Receive, Send says a contact has only an Epicbox address.
  DeskShot(id: '16f-send-epicbox-off', title: 'Send, Epicbox off, a contact with only an Epicbox address', route: DeskRoute.send, arg: const SendArgs(recipient: _anna, amount: '12.5'), prepare: (c, _) => _epicboxOff(c)),
  DeskShot(id: '16g-receive-epicbox-off', title: 'Receive, Epicbox off', route: DeskRoute.receive, prepare: (c, _) => _epicboxOff(c)),
  DeskShot(id: '16h-transactions-epicbox-off', title: 'Settings › Transactions, Epicbox off', route: DeskRoute.settingsReceiving, prepare: (c, _) => _epicboxOff(c)),
  const DeskShot(id: '17-receive', title: 'Receive', route: DeskRoute.receive, arg: ReceiveArgs()),
  const DeskShot(id: '17b-receive-all-off', title: 'Receive, all off', route: DeskRoute.receive, arg: ReceiveArgs(epicbox: RxEpicbox.off)),
  const DeskShot(id: '17c-receive-http-tor-on', title: 'Receive, HTTP and Tor on', route: DeskRoute.receive, arg: ReceiveArgs(http: RxHttp.on, tor: RxTor.on)),
  const DeskShot(id: '17d-receive-connecting', title: 'Receive, connecting', route: DeskRoute.receive, arg: ReceiveArgs(http: RxHttp.starting, tor: RxTor.connecting)),
  const DeskShot(
    id: '17e-receive-errors',
    title: 'Receive, errors',
    route: DeskRoute.receive,
    arg: ReceiveArgs(epicbox: RxEpicbox.down, http: RxHttp.failed, tor: RxTor.failed),
  ),
  const DeskShot(id: '17f-receive-wide', title: 'Receive at 1440x900', route: DeskRoute.receive, arg: ReceiveArgs(http: RxHttp.on, tor: RxTor.on), width: 1440, height: 900),
  const DeskShot(id: '17g-receive-qr-epicbox', title: 'Receive, Epicbox QR shown', route: DeskRoute.receive, arg: ReceiveArgs(qr: RxQr.epicbox), width: 1440, height: 900),
  const DeskShot(id: '17h-receive-qr-http', title: 'Receive, HTTP QR shown', route: DeskRoute.receive, arg: ReceiveArgs(http: RxHttp.on, qr: RxQr.http), width: 1280, height: 900),
  DeskShot(
    id: '19-import',
    title: 'Sign a transaction file',
    route: DeskRoute.importTx,
    // The Receive shots turned HTTP on: put the methods back as the wallet opens.
    prepare: (c, _) async {
      final n = c.read(deskProvider.notifier);
      await n.setHttp(false);
      await n.setTor(false);
      await n.setEpicboxListening(true);
    },
  ),
  const DeskShot(id: '19b-import-done', title: 'Response saved', route: DeskRoute.importTx, arg: ImportArgs(done: true)),
  const DeskShot(id: '19c-import-error', title: 'Sign, wrong file', route: DeskRoute.importTx, arg: ImportArgs(error: ImportError.wrongType)),
  const DeskShot(id: '20-finalize', title: 'Finalize a response file', route: DeskRoute.finalize),
  const DeskShot(id: '20b-finalize-done', title: 'Transaction posted', route: DeskRoute.finalize, arg: FinalizeArgs(done: true)),
  const DeskShot(id: '20c-finalize-error', title: 'Finalize, not posted', route: DeskRoute.finalize, arg: FinalizeArgs(error: FinalizeError.notPosted)),
  DeskShot(id: '36-dlg-contact-picker', title: 'Choose contact', route: DeskRoute.send, dialog: showContactPickerDialog),
];

/// Both Link methods on (Settings › Transactions) for a shot of a Link send; [_linkOff] back.
Future<void> _linkOn(ProviderContainer c) async {
  final n = c.read(deskProvider.notifier);
  final s = c.read(deskProvider).settings;
  await n.saveSettings(s.copyWith(payments: s.payments.copyWith(linkHttp: true, linkTor: true)));
}

Future<void> _linkOff(ProviderContainer c) async {
  final n = c.read(deskProvider.notifier);
  final s = c.read(deskProvider).settings;
  await n.saveSettings(s.copyWith(payments: s.payments.copyWith(linkHttp: false, linkTor: false)));
}

/// Turns the Epicbox switch off for a shot.
Future<void> _epicboxOff(ProviderContainer c) async {
  final n = c.read(deskProvider.notifier);
  final s = c.read(deskProvider).settings;
  await n.saveSettings(s.copyWith(payments: s.payments.copyWith(epicbox: false)));
}
