import '../../app/shots.dart';
import '../../widgets/kit.dart';
import 'contact_picker.dart';
import 'finalize_screen.dart';
import 'import_tx_screen.dart';
import 'receive_screen.dart';
import 'send_screen.dart';

const _anna = 'esYb3kq9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@epicbox.epiccash.com';

/// Screenshot tour entries of this group (see app/shots.dart). Ids match the Electron
/// reference shots.
final List<DeskShot> transferShots = [
  const DeskShot(id: '13-send', title: 'Send', route: DeskRoute.send),
  const DeskShot(id: '13-send-narrow', title: 'Send at 1000x700', route: DeskRoute.send, width: 1000, height: 700),
  const DeskShot(id: '14-send-direct', title: 'Send, direct HTTP', route: DeskRoute.send, arg: SendArgs(method: TxMethod.http, recipient: 'http://10.0.1.24:3415', amount: '5')),
  const DeskShot(id: '14b-send-direct-tor', title: 'Send, direct Tor', route: DeskRoute.send, arg: SendArgs(method: TxMethod.tor)),
  const DeskShot(id: '15-send-file', title: 'Send, file', route: DeskRoute.send, arg: SendArgs(method: TxMethod.file, amount: '12.5')),
  const DeskShot(id: '15b-send-errors', title: 'Send, validation errors', route: DeskRoute.send, arg: SendArgs(step: SendStep.errors, recipient: 'not an address', amount: '0.123456789')),
  const DeskShot(id: '16-send-review', title: 'Send, review', route: DeskRoute.send, arg: SendArgs(step: SendStep.review, recipient: _anna, amount: '12.5', message: 'Invoice 0042')),
  const DeskShot(id: '16b-send-sending', title: 'Send, sending', route: DeskRoute.send, arg: SendArgs(step: SendStep.sending, recipient: _anna, amount: '12.5', message: 'Invoice 0042')),
  const DeskShot(id: '16c-send-done', title: 'Send, done', route: DeskRoute.send, arg: SendArgs(step: SendStep.done, recipient: _anna, amount: '12.5')),
  const DeskShot(id: '16d-send-file-ready', title: 'Send, file ready', route: DeskRoute.send, arg: SendArgs(step: SendStep.fileReady, amount: '12.5')),
  const DeskShot(id: '16e-send-failed', title: 'Send, failed', route: DeskRoute.send, arg: SendArgs(step: SendStep.failed, recipient: 'esOffline9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9r@epicbox.offline.example', amount: '3')),
  const DeskShot(id: '17-receive', title: 'Receive', route: DeskRoute.receive),
  const DeskShot(id: '18-receive-internet', title: 'Receive from internet', route: DeskRoute.receive, arg: ReceiveArgs(internet: true), height: 900),
  const DeskShot(id: '19-import', title: 'Sign a transaction file', route: DeskRoute.importTx),
  const DeskShot(id: '19b-import-done', title: 'Response saved', route: DeskRoute.importTx, arg: ImportArgs(done: true)),
  const DeskShot(id: '20-finalize', title: 'Finalize a response file', route: DeskRoute.finalize),
  const DeskShot(id: '20b-finalize-done', title: 'Transaction posted', route: DeskRoute.finalize, arg: FinalizeArgs(done: true)),
  DeskShot(id: '36-dlg-contact-picker', title: 'Choose contact', route: DeskRoute.send, dialog: showContactPickerDialog),
];
