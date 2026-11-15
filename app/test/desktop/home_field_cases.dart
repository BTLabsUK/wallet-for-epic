// SPDX-License-Identifier: Apache-2.0
// The case table of Home's field: what is typed, and what Enter does with it. One source for the
// parser's unit test, the widget test of the hand-off and the live run in the desktop build
// (tool/home_field_table.dart prints it as the published table).
import 'package:epic_wallet/src/desktop/data/models.dart' show Contact;
import 'package:epic_wallet/src/desktop/screens/wallet/home_field_parse.dart';
import 'package:epic_wallet/src/send_route.dart' show RecipientInputKind;

const hfKey = 'esMASi45ub7Qe4ZE36UT5G6cU4ud8Fhhe4deS4F3cw9KTAb8dLcu';
const _kBtl = 'eskC7edhDQ7cn5d4gEYkbUrMWeWQLGsCmrG6dLaYyNoVKf58ZTBq';
const _kAk = 'esNAYT3j5qcdsyuMNmPfYetW5v6JXmj54omLidkuVKnRyjP2WPBg';
const _kAn = 'es8Y4ErK9pGSSxY6BVScJy9uUxcJnTPkyRFA6CAFjF1YveCHK1AT';
const _kR4 = 'esbQgdM9mwZgikp4WzxrxktcSSSS7XhS4D5EVB8Nf471dAb7Qg25';
const _kTom = 'esxEgRAhHPfQX88wYWXXL6A7pNpHXvmBa2EaQAmb2qaLix6mwHaQ';
const _kNw = 'esBPrFbbrZNhFgtsqwDtGuSptFDaYPo22sJXHDmfPVtoPQ6F7FXD';
const _kEx = 'esNEXgzgv1XiPti6vj8RsnqDXyCUshN6toSWSp6oBB92AezWtiAg';
const _kSt = 'esufXjPAcc921toi7ap9UxDuxE2HEKZGqeMHbTv94pPzWjeuzaTu';
const _kPast = 'esyZ9bAaZ2xVrCf1rtACAXgo8c4MkaacXsr7yc4GDJ3r7ZVc2qz5';
const _kPia = 'esVxcwrWVZweDCtZXhgsC7VLA6btymh3fSVipgiBg1va543DyGf2';
const hfEb = '$hfKey@epicbox.example.org';
const hfEmail = '$hfKey@epicmail.example.org';
const hfOnion = 'wfe7q3k2mz5xr4tbv6ld5yhnpjc7sgo2a3ue6iwq4fk7tr3mxzabcdid.onion';
const hfHttps = 'https://pay.example.net:3415';
const hfLan = 'http://192.168.1.24:3415';
const hfBtl = '$_kBtl@epicbox.btlabs.uk';
const hfPast = '$_kPast@epicbox.example.org';
const hfEpic1 = 'epic1qw508d6qejxtdg4y5r3zarvary0c5xw7kxw5r4tm8q9';
const hfEpic1Link = 'epic:$hfEpic1?server=https://pay.example.net';
const hfRequest = 'epic:$hfEb?amount=3&message=coffee';
const hfPhrase = 'abandon ability able about above absent absorb abstract absurd abuse access accident';

/// The contacts of the table (ids are what the cases name).
List<Contact> hfContacts() => [
  Contact(id: 'btl', name: 'BT Labs', epicbox: hfBtl, favourite: true),
  Contact(id: 'ak', name: 'Anna Kowalska', epicbox: '$_kAk@epicbox.example.org', favourite: true),
  Contact(id: 'an', name: 'Anna Nowak', epicbox: '$_kAn@epicbox.example.org'),
  Contact(id: 'room4', name: 'Room 4', epicbox: '$_kR4@epicbox.example.org'),
  Contact(id: 'tom', name: 'Tom', http: hfLan, epicbox: '$_kTom@epicbox.example.org'),
  Contact(id: 'nw', name: 'Northwind Exchange', epicbox: '$_kNw@epicbox.example.org'),
  Contact(id: 'ex', name: 'Exchange deposit', epicbox: '$_kEx@epicbox.example.org'),
  Contact(id: 'stars', name: 'All Stars', epicbox: '$_kSt@epicbox.example.org'),
  Contact(id: 'pia', name: 'Pia', epicbox: '$_kPia@epicbox.example.org'),
];

/// Past recipients of Activity that no contact holds.
const hfPastRecipients = [hfPast];

class HomeCase {
  const HomeCase(
    this.id,
    this.group,
    this.typed,
    this.kind,
    this.shows, {
    this.verb = HomeVerb.send,
    this.to,
    this.amount,
    this.max = false,
    this.message,
    this.list,
    this.recipient,
    this.enters = true,
    this.line,
    this.epic1 = false,
  });

  final String id;
  final String group;

  /// What is typed (the field is cleared first).
  final String typed;
  final HomeKind kind;

  /// What Enter opens, in the words of the table.
  final String shows;
  final HomeVerb verb;

  /// The contact id or the address Enter takes.
  final String? to;
  final String? amount;
  final bool max;
  final String? message;

  /// The ids listed, best first (a person); null when the list is not part of the case.
  final List<String>? list;

  /// For an address: how Send reads it.
  final RecipientInputKind? recipient;

  /// Whether Enter opens anything.
  final bool enters;

  /// The line under the field, when the case names it.
  final String? line;

  /// The row is for epic1 payment mode (Settings: epic1 payments on); the others for classic.
  final bool epic1;
}

const homeCases = <HomeCase>[
  // Names
  HomeCase('N01', 'name', 'bt labs', HomeKind.person, 'Send · To BT Labs', to: 'btl', list: ['btl']),
  HomeCase('N02', 'name', 'BT LABS', HomeKind.person, 'Send · To BT Labs', to: 'btl', list: ['btl']),
  HomeCase('N03', 'name', 'Bt LaBs', HomeKind.person, 'Send · To BT Labs', to: 'btl', list: ['btl']),
  HomeCase('N04', 'name', 'labs', HomeKind.person, 'Send · To BT Labs', to: 'btl', list: ['btl']),
  HomeCase('N05', 'name', 'bt', HomeKind.person, 'Send · To BT Labs', to: 'btl', list: ['btl']),
  HomeCase('N06', 'name', 'anna', HomeKind.person, 'Send · To Anna Kowalska (favourite first); Anna Nowak listed', to: 'ak', list: ['ak', 'an']),
  HomeCase('N07', 'name', 'anna n', HomeKind.person, 'Send · To Anna Nowak', to: 'an', list: ['an']),
  HomeCase('N08', 'name', 'kowalska', HomeKind.person, 'Send · To Anna Kowalska', to: 'ak', list: ['ak']),
  HomeCase('N09', 'name', 'exchange', HomeKind.person, 'Send · To Exchange deposit (name starts with it); Northwind Exchange listed', to: 'ex', list: ['ex', 'nw']),
  HomeCase('N10', 'name', 'room 4', HomeKind.person, 'Send · To Room 4 (the 4 is part of the name)', to: 'room4', list: ['room4']),
  HomeCase('N11', 'name', 'all stars', HomeKind.person, 'Send · To All Stars (the whole name beats "all")', to: 'stars', list: ['stars']),
  HomeCase('N12', 'name', 'btl', HomeKind.person, 'Send · To BT Labs (initials)', to: 'btl', list: ['btl']),
  HomeCase('N13', 'name', 'bl', HomeKind.person, 'Send · To BT Labs (initials)', to: 'btl', list: ['btl']),
  HomeCase('N14', 'name', 'bt lbas', HomeKind.person, 'Send · To BT Labs (one typo)', to: 'btl', list: ['btl']),
  HomeCase('N15', 'name', '  bt labs  ', HomeKind.person, 'Send · To BT Labs (spaces around)', to: 'btl', list: ['btl']),
  HomeCase('N16', 'name', 'tom', HomeKind.person, 'Send · To Tom', to: 'tom', list: ['tom']),
  // Amounts alone
  HomeCase('A01', 'amount', '4', HomeKind.amount, 'Send · Amount 4, To empty', amount: '4'),
  HomeCase('A02', 'amount', '4.5', HomeKind.amount, 'Send · Amount 4.5, To empty', amount: '4.5'),
  HomeCase('A03', 'amount', '4,5', HomeKind.amount, 'Send · Amount 4,5, To empty', amount: '4,5'),
  HomeCase('A04', 'amount', '.5', HomeKind.amount, 'Send · Amount .5, To empty', amount: '.5'),
  HomeCase('A05', 'amount', '1,000.5', HomeKind.amount, 'Send · Amount 1,000.5, To empty', amount: '1,000.5'),
  HomeCase('A06', 'amount', '4 epic', HomeKind.amount, 'Send · Amount 4, To empty', amount: '4'),
  HomeCase('A07', 'amount', '4 EPIC', HomeKind.amount, 'Send · Amount 4, To empty', amount: '4'),
  HomeCase('A08', 'amount', 'max', HomeKind.amount, 'Send · Amount spendable minus fee, To empty', max: true),
  HomeCase('A09', 'amount', 'all', HomeKind.amount, 'Send · Amount spendable minus fee, To empty', max: true),
  // Amount and name, any order
  HomeCase('M01', 'amount+name', '4 bt labs', HomeKind.person, 'Send · To BT Labs · Amount 4', to: 'btl', amount: '4'),
  HomeCase('M02', 'amount+name', 'bt labs 4', HomeKind.person, 'Send · To BT Labs · Amount 4', to: 'btl', amount: '4'),
  HomeCase('M03', 'amount+name', '4 to bt labs', HomeKind.person, 'Send · To BT Labs · Amount 4', to: 'btl', amount: '4'),
  HomeCase('M04', 'amount+name', '4.5 epic bt labs', HomeKind.person, 'Send · To BT Labs · Amount 4.5', to: 'btl', amount: '4.5'),
  HomeCase('M05', 'amount+name', 'send 5 epic to bt labs', HomeKind.person, 'Send · To BT Labs · Amount 5', to: 'btl', amount: '5'),
  HomeCase('M06', 'amount+name', 'pay bt labs 5', HomeKind.person, 'Send · To BT Labs · Amount 5', to: 'btl', amount: '5'),
  HomeCase('M07', 'amount+name', 'bt labs 4,5', HomeKind.person, 'Send · To BT Labs · Amount 4,5', to: 'btl', amount: '4,5'),
  HomeCase('M08', 'amount+name', 'bt labs 1,000.5', HomeKind.person, 'Send · To BT Labs · Amount 1,000.5', to: 'btl', amount: '1,000.5'),
  HomeCase('M09', 'amount+name', '4 anna', HomeKind.person, 'Send · To Anna Kowalska · Amount 4 (Anna Nowak listed)', to: 'ak', amount: '4', list: ['ak', 'an']),
  HomeCase('M10', 'amount+name', 'room 4 5', HomeKind.person, 'Send · To Room 4 · Amount 5', to: 'room4', amount: '5'),
  HomeCase('M11', 'amount+name', '5 room 4', HomeKind.person, 'Send · To Room 4 · Amount 5', to: 'room4', amount: '5'),
  HomeCase('M12', 'amount+name', 'bt labz 5', HomeKind.person, 'Send · To BT Labs · Amount 5 (one typo)', to: 'btl', amount: '5'),
  HomeCase('M13', 'amount+name', 'max bt labs', HomeKind.person, 'Send · To BT Labs · Amount spendable minus fee', to: 'btl', max: true),
  HomeCase('M14', 'amount+name', 'send all to bt labs', HomeKind.person, 'Send · To BT Labs · Amount spendable minus fee', to: 'btl', max: true),
  // Message
  HomeCase('G01', 'message', 'bt labs 5 for concert tickets', HomeKind.person, 'Send · To BT Labs · Amount 5 · Message "concert tickets"', to: 'btl', amount: '5', message: 'concert tickets'),
  HomeCase('G02', 'message', '5 to bt labs for lunch', HomeKind.person, 'Send · To BT Labs · Amount 5 · Message "lunch"', to: 'btl', amount: '5', message: 'lunch'),
  HomeCase('G03', 'message', 'bt labs for lunch', HomeKind.person, 'Send · To BT Labs · Message "lunch"', to: 'btl', message: 'lunch'),
  // Addresses
  HomeCase('D01', 'address', hfEb, HomeKind.address, 'Send · To (Epicbox, epicbox.example.org)', to: hfEb, recipient: RecipientInputKind.epicbox),
  HomeCase('D02', 'address', hfEmail, HomeKind.address, 'Send · To (Epicbox, epicmail.example.org)', to: hfEmail, recipient: RecipientInputKind.epicbox),
  HomeCase('D03', 'address', hfKey, HomeKind.address, 'Send · To (Epicbox on the default relay)', to: hfEb, recipient: RecipientInputKind.epicbox),
  HomeCase('D04', 'address', '$hfKey@', HomeKind.address, 'Send · To (Epicbox on the default relay, as Send reads a key with "@")', to: hfEb, recipient: RecipientInputKind.epicbox),
  HomeCase('D05', 'address', hfOnion, HomeKind.address, 'Send · To (Link · Tor)', to: hfOnion, recipient: RecipientInputKind.onion),
  HomeCase('D06', 'address', hfHttps, HomeKind.address, 'Send · To (Link · HTTP, https, pay.example.net)', to: hfHttps, recipient: RecipientInputKind.https),
  HomeCase('D07', 'address', '192.168.1.5:3415', HomeKind.address, 'Send · To (Link · HTTP, 192.168.1.5)', to: 'http://192.168.1.5:3415', recipient: RecipientInputKind.http),
  HomeCase('D08', 'address', '4 $hfEb', HomeKind.address, 'Send · To (Epicbox) · Amount 4', to: hfEb, amount: '4', recipient: RecipientInputKind.epicbox),
  HomeCase('D09', 'address', '$hfEb 4', HomeKind.address, 'Send · To (Epicbox) · Amount 4', to: hfEb, amount: '4', recipient: RecipientInputKind.epicbox),
  HomeCase('D10', 'address', '4 to $hfEb', HomeKind.address, 'Send · To (Epicbox) · Amount 4', to: hfEb, amount: '4', recipient: RecipientInputKind.epicbox),
  HomeCase('D11', 'address', 'send 4 to $hfHttps', HomeKind.address, 'Send · To (https) · Amount 4', to: hfHttps, amount: '4', recipient: RecipientInputKind.https),
  HomeCase('D12', 'address', hfBtl, HomeKind.person, 'Send · To BT Labs (the address is the contact\'s)', to: 'btl', list: ['btl']),
  HomeCase('D13', 'address', hfLan, HomeKind.person, 'Send · To Tom (the address is the contact\'s)', to: 'tom', list: ['tom']),
  HomeCase('D14', 'address', 'esyZ9b', HomeKind.person, 'Send · To a past recipient, by the start of its address', to: 'past:$hfPast', list: ['past:$hfPast']),
  HomeCase('D15', 'address', hfPast, HomeKind.person, 'Send · To the past recipient (address known from Activity)', to: 'past:$hfPast', list: ['past:$hfPast']),
  HomeCase('D16', 'address', 'esMASi45ub7Qe4ZE', HomeKind.address, 'Nothing opens · line says the address is incomplete', to: 'esMASi45ub7Qe4ZE', recipient: RecipientInputKind.invalid, enters: false),
  HomeCase('D17', 'address', 'http://192.168.1.', HomeKind.address, 'Nothing opens · line says the address is incomplete', to: 'http://192.168.1.', recipient: RecipientInputKind.invalid, enters: false),
  HomeCase('D18', 'address', 'ftp://files.example.net', HomeKind.address, 'Nothing opens · line says only http, https and epicbox are paid', to: 'ftp://files.example.net', recipient: RecipientInputKind.invalid, enters: false),
  // An epic1 code with an amount, any order (epic1 mode opens Send's epic1 page with both; classic mode says what Send says)
  HomeCase('E01', 'epic1', '10000 $hfEpic1Link', HomeKind.address, 'epic1 mode: Send · epic1 page, code and Amount 10000 · classic mode: nothing opens', to: hfEpic1Link, amount: '10000', recipient: RecipientInputKind.text),
  HomeCase('E02', 'epic1', '$hfEpic1Link 10000', HomeKind.address, 'epic1 mode: Send · epic1 page, code and Amount 10000 · classic mode: nothing opens', to: hfEpic1Link, amount: '10000', recipient: RecipientInputKind.text),
  HomeCase('E03', 'epic1', 'send 5 to $hfEpic1Link', HomeKind.address, 'epic1 mode: Send · epic1 page, code and Amount 5 · classic mode: nothing opens', to: hfEpic1Link, amount: '5', recipient: RecipientInputKind.text),
  // A bare epic1 address (with or without an amount) is refused in both modes, as Send refuses it
  HomeCase('E04', 'epic1', '10000 $hfEpic1', HomeKind.address, 'Nothing opens · "An epic1 address alone cannot be paid. Paste the epic1 link."', to: hfEpic1, amount: '10000', recipient: RecipientInputKind.text, enters: false, line: 'An epic1 address alone cannot be paid. Paste the epic1 link.'),
  HomeCase('E05', 'epic1', '$hfEpic1 10', HomeKind.address, 'Nothing opens · "An epic1 address alone cannot be paid. Paste the epic1 link."', to: hfEpic1, amount: '10', recipient: RecipientInputKind.text, enters: false, line: 'An epic1 address alone cannot be paid. Paste the epic1 link.'),
  // Codes
  HomeCase('C01', 'code', hfRequest, HomeKind.code, 'Send · filled from the payment request (To, Amount 3, Message "coffee")'),
  HomeCase('C02', 'code', hfEpic1, HomeKind.code, 'Nothing opens · "An epic1 address alone cannot be paid. Paste the epic1 link."', enters: false, line: 'An epic1 address alone cannot be paid. Paste the epic1 link.'),
  HomeCase('C03', 'code', hfEpic1Link, HomeKind.code, 'Send · the epic1 link goes through Send\'s paste'),
  HomeCase('C05', 'code', hfRequest, HomeKind.code, 'epic1 mode: nothing opens · "Classic address. Turn off epic1 payments to pay it."', enters: false, epic1: true, line: 'Classic address. Turn off epic1 payments to pay it.'),
  HomeCase('C04', 'code', hfPhrase, HomeKind.none, 'Nothing opens · the phrase is not echoed', enters: false),
  // Nothing
  HomeCase('X01', 'none', 'xyz', HomeKind.none, 'Nothing opens · "No contact or address matches \'xyz\'"', enters: false),
  HomeCase('X02', 'none', 'zzz 5', HomeKind.none, 'Nothing opens · "No contact or address matches \'zzz 5\'"', enters: false),
  HomeCase('X03', 'none', '', HomeKind.blank, 'Nothing opens · no line', enters: false),
  HomeCase('X04', 'none', '   ', HomeKind.blank, 'Nothing opens · no line', enters: false),
  // Request
  HomeCase('R01', 'request', 'request 5 from pia', HomeKind.person, 'Request · From Pia · Amount 5', verb: HomeVerb.request, to: 'pia', amount: '5'),
  HomeCase('R02', 'request', 'request pia 5 for rent', HomeKind.person, 'Request · From Pia · Amount 5 · Message "rent"', verb: HomeVerb.request, to: 'pia', amount: '5', message: 'rent'),
  HomeCase('R03', 'request', 'request 5', HomeKind.amount, 'Request · Amount 5, payer to pick', verb: HomeVerb.request, amount: '5'),
  // Amount problems (the line, from Send's own amount check)
  HomeCase('V01', 'amount', '1000 bt labs', HomeKind.person, 'Nothing opens · "More than spendable" (spendable is 100)', to: 'btl', amount: '1000', enters: false),
  HomeCase('V02', 'amount', '0 bt labs', HomeKind.person, 'Nothing opens · the amount must be more than 0', to: 'btl', amount: '0', enters: false),
  HomeCase('V03', 'amount', '1.123456789 bt labs', HomeKind.person, 'Nothing opens · too many decimals', to: 'btl', amount: '1.123456789', enters: false),
];
