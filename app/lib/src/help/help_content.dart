// SPDX-License-Identifier: Apache-2.0
/// Help content shared by the desktop and the phone: the topic structure ([HelpTopic],
/// [HelpBlock], [helpInline]), the sections and the topics themselves. The desktop renders
/// them in Settings › Help, the phone in its Help screen. One source, so the two apps
/// explain Epic Cash with the same words; where the device differs (a computer or a phone, a
/// password or a PIN, where a setting lives) the text takes the [HelpPlatform] into account.
library;

import '../../l10n/app_localizations.dart';
import '../advanced.dart';
import 'help_devices.dart';
import 'help_name_service.dart';
import '../settings_file/host_settings.dart' show appConfig, hostSettings;

/// One block of a topic's body. Inline, `**bold**` marks a term and `[[Settings › Node]]` a
/// place in the app. A translation writes a place as `[[translated label|Settings › Node]]`: what
/// the reader sees, then the English place the link goes to.
class HelpBlock {
  const HelpBlock.p(String text) : kind = HelpBlockKind.p, items = const [], _text = text, anchor = '';
  const HelpBlock.ol(this.items) : kind = HelpBlockKind.ol, _text = null, anchor = '';
  const HelpBlock.ul(this.items) : kind = HelpBlockKind.ul, _text = null, anchor = '';

  /// A heading inside a long topic. [anchor] names it for links from other screens
  /// ([HelpAnchor]); a translation keeps the English anchor.
  const HelpBlock.h(String text, {required this.anchor}) : kind = HelpBlockKind.h, items = const [], _text = text;

  final HelpBlockKind kind;

  /// The heading's stable name, for a link that opens the topic at this heading; empty for the
  /// other blocks.
  final String anchor;

  /// The list items; empty for a paragraph.
  final List<String> items;
  final String? _text;

  /// The paragraph's text, or the list items one per line.
  String get text => _text ?? items.join('\n');
}

enum HelpBlockKind { p, ol, ul, h }

/// One piece of [helpInline]: the [text] to show, and for a place the [target], the English place
/// the link goes to (the text itself when the place has no `|`; empty for anything else).
typedef HelpPiece = ({String text, bool term, bool place, String target});

/// [text] in pieces: plain, a term (`**…**`) or a place (`[[…]]`, or `[[label|place]]`), markers
/// removed.
List<HelpPiece> helpInline(String text) {
  final out = <HelpPiece>[];
  var pos = 0;
  for (final m in RegExp(r'\*\*(.+?)\*\*|\[\[(.+?)\]\]').allMatches(text)) {
    if (m.start > pos) out.add((text: text.substring(pos, m.start), term: false, place: false, target: ''));
    final place = m.group(2);
    if (place != null) {
      final bar = place.indexOf('|');
      final label = bar < 0 ? place : place.substring(0, bar).trim();
      final target = bar < 0 ? place : place.substring(bar + 1).trim();
      out.add((text: label, term: false, place: true, target: target));
    } else {
      out.add((text: m.group(1)!, term: true, place: false, target: ''));
    }
    pos = m.end;
  }
  if (pos < text.length) out.add((text: text.substring(pos), term: false, place: false, target: ''));
  return out;
}

/// A help topic: its section, title, one-line answer and body. [id] names it for links from
/// other screens ([HelpId]); empty when nothing links to it.
class HelpTopic {
  const HelpTopic(
    this.section,
    this.title,
    this.short,
    this.body, {
    this.handshake = false,
    this.devices = false,
    this.id = '',
  });

  final String section;
  final String title;
  final String short;
  final List<HelpBlock> body;

  /// The handshake stepper goes under the body.
  final bool handshake;

  /// The linked devices topic: the picture of a sync goes between the answer and the body, the
  /// live status panel under the body (`ui/devices/sync_help.dart`).
  final bool devices;

  /// A stable name other screens open the topic by; see [HelpId].
  final String id;

  /// The body as plain text, for search and its marks.
  String get bodyText => [for (final b in body) for (final p in helpInline(b.text)) p.text].join(' ');
}

typedef HelpSection = ({String id, String title, String lede, String art});

const helpSections = <HelpSection>[
  (id: 'start', title: 'Getting started', lede: 'Receiving, sending and paying with a file.', art: 'help-start'),
  (id: 'how', title: 'How Epic Cash works', lede: 'Both wallets take part. Confirmations, privacy, change and fees.', art: 'help-how'),
  (id: 'safety', title: 'Keeping the wallet safe', lede: 'The recovery phrase is the backup and the key.', art: 'help-safety'),
  (id: 'network', title: 'Nodes and Epicbox', lede: 'What the wallet connects to, and Tor.', art: 'help-network'),
  (id: 'trouble', title: 'When something goes wrong', lede: 'The usual causes, and what to do.', art: 'help-trouble'),
  (id: 'maintenance', title: 'Maintenance', lede: 'Old wallet folders on disk, and the settings file.', art: 'help-maintenance'),
];

/// Help › Pairing (RFC 0002): shown when the wallet pairs, before "When something goes wrong".
/// It holds the invoice topic too: invoices come only from paired contacts.
const pairingHelpSection = 'pairing';

/// The ids screens open Help by ([HelpTopic.id]).
/// The topics that explain a part Advanced hides, by id: Help lists and finds them only while
/// that switch is on, so a search never leads to a page the wallet does not show. The Outputs
/// topics and the linked device ones (the Pairing section goes with Pairing as a whole): the
/// File Transfer method is everyday use and keeps its topic.
const Map<String, AdvancedFeature> helpTopicFeature = {
  HelpId.strategy: AdvancedFeature.outputs,
  HelpId.split: AdvancedFeature.outputs,
  HelpId.linkedDevices: AdvancedFeature.linkedDevices,
  HelpId.lostDevice: AdvancedFeature.linkedDevices,
  HelpId.heldCoins: AdvancedFeature.linkedDevices,
};

/// [topics] without those of a feature [prefs] keeps hidden.
List<HelpTopic> helpTopicsShown(List<HelpTopic> topics, AdvancedPrefs prefs) => [
  for (final t in topics)
    if (switch (helpTopicFeature[t.id]) {
      final f? => prefs.has(f),
      null => true,
    }) t,
];

abstract final class HelpId {
  static const receive = 'receive';
  static const send = 'send';
  static const file = 'file';
  static const qr = 'qr';
  static const addresses = 'addresses';
  static const handshake = 'handshake';
  static const confirmations = 'confirmations';
  static const privacy = 'privacy';
  static const locked = 'locked';
  static const strategy = 'strategy';
  static const split = 'split';
  static const fees = 'fees';
  static const phrase = 'phrase';
  static const backup = 'backup';
  static const node = 'node';
  static const epicbox = 'epicbox';
  static const tor = 'tor';
  static const advanced = 'advanced';
  static const modes = 'modes';
  static const methods = 'methods';
  static const trouble = 'trouble';
  static const pairing = 'pairing';
  static const pairingWays = 'pairing-ways';
  static const pairingRoute = 'pairing-route';
  static const checkWords = 'check-words';
  static const invoices = 'invoices';
  static const pairingRestore = 'pairing-restore';
  static const cleanup = 'cleanup';
  static const settingsFile = 'settings-file';
  static const importWarning = 'import-warning';
  static const cancel = 'cancel';
  static const otherWallet = 'other-wallet';
  static const linkedDevices = 'linked-devices';
  static const lostDevice = 'lost-device';
  static const heldCoins = 'held-coins';
  static const localNode = 'local-node';
  static const nodeFit = 'node-fit';
  static const passphrase = 'passphrase';
  static const paymentLinks = 'payment-links';
  static const linkLine = 'link-line';
  static const noPayments = 'no-payments';
  static const nameServices = 'name-services';
  static const nameServiceTell = 'name-service-tell';
  static const linkUnanswered = 'link-unanswered';
}

/// The headings of [HelpId.cancel] ("Cancelling a payment"), which the quiet line beside every
/// Cancel button opens the topic at ([HelpBlock.h]).
abstract final class HelpAnchor {
  static const sending = 'sending';
  static const receiving = 'receiving';
  static const requests = 'requests';

  /// Move coins back or Unlock coins: the two ways where the other side could still finish.
  static const twoWays = 'two-ways';

  /// The headings of [HelpId.modes] ("Network modes").
  static const ownNode = 'own-node';
  static const coldStorage = 'cold-storage';

  /// The headings of [HelpId.linkedDevices] ("How linked devices work").
  static const security = 'security';
  static const limits = 'limits';
}

/// Which app shows the help: the words differ where the device does.
enum HelpPlatform { desktop, phone }

/// The topics for [platform], with [confirmations] as the open wallet's balance counts them.
/// [tor] leaves the Tor topic out of a build without Tor. The desktop's text is the GUI 6.1.6
/// topic set, as the settings design words them; the phone says the same with its own
/// places and a PIN instead of a password.
List<HelpTopic> helpTopics(int confirmations, {required HelpPlatform platform, bool tor = true}) {
  final phone = platform == HelpPlatform.phone;
  // The words that differ between a computer and a phone.
  final device = phone ? 'this phone' : 'this computer';
  final secret = phone ? 'your PIN or passphrase' : 'the wallet password';
  final nodePlace = phone ? '[[Settings › Network & privacy › Node]]' : '[[Settings › Node]]';
  final epicboxPlace = phone ? '[[Settings › Network & privacy › Epicbox]]' : '[[Settings › Payments › Epicbox]]';
  final torPlace = phone ? '[[Settings › Network & privacy › Tor only]]' : '[[Settings › Network & privacy › Tor only]]';
  final netPlace = '[[Settings › Network & privacy]]';
  final cancelPlace = phone ? '[[Activity]] (open the payment, then Cancel payment)' : '[[Activity › the transaction › Cancel]]';
  final historyBackupPlace = phone ? '[[Settings › This wallet › Export wallet data]]' : '[[Settings › Wallet › Export wallet data]]';
  final restorePlace = phone
      ? '**Restore from phrase** (on the first screen, or under [[Settings › This wallet]])'
      : '**Restore from phrase** (on the first screen, Unlock › Add a wallet, or [[Settings › Wallets]])';
  final recheckPlace = phone ? '[[Settings › This wallet › Recheck balance]]' : '[[Settings › Wallet › Recheck balance]]';
  final payPlace = phone ? '[[Settings › Transactions]]' : '[[Settings › Payments]]';
  final filesPlace = '[[Settings › Files & logs]]';
  final phrasePlace = phone ? '[[Settings › Security › Back up recovery phrase]]' : '[[Settings › Security › Recovery phrase]]';
  return <HelpTopic>[
    HelpTopic(
      'start',
      'Receive your first EPIC',
      'Open Receive, copy the Epicbox address and give it to the sender. The payment arrives by itself.',
      [
        HelpBlock.p('The Epicbox address is a long code that ends in **@** and the name of the Epicbox server, for example **…@${hostSettings.epicboxUse}**. It is safe to share: people need it to pay, and nobody can take anything with it.'),
        const HelpBlock.ol(['Open [[Receive]].', 'Copy the address (or show its QR code) and send it to the person who pays.', 'The payment shows up in Activity on its own.']),
        if (phone)
          const HelpBlock.p('Receiving works while the app is open and the node is synced. A payment sent while the app is closed waits on the Epicbox server, like a post-office box, and arrives at the next unlock.')
        else
          const HelpBlock.p('Receiving starts by itself after unlock, once the node is synced. If the wallet is closed when someone pays, Epicbox holds the payment, and the wallet collects it at the next unlock.'),
        HelpBlock.p('A new payment first waits for the sender’s wallet to finish it, then shows as confirming. After $confirmations confirmations it can be spent.'),
      ],
      id: HelpId.receive,
    ),
    HelpTopic(
      'start',
      'Send to someone',
      'Open Send, paste their Epicbox address, enter the amount, check the fee and send.',
      [
        HelpBlock.ol(['Open [[Send]] and paste the recipient’s address, or pick a contact.', 'Enter the amount. The fee is shown before sending.', phone ? 'Tap **Continue**, check, then **Send … EPIC**.' : 'Press **Review**, check, then **Send … EPIC**.']),
        const HelpBlock.p('A paired contact has two options on Send, explained in “Payments after pairing”; a payment to the paired option is sealed. Any other contact gets the payment at their public Epicbox address.'),
        const HelpBlock.p('Now the recipient’s wallet has to answer (see "Why does a transaction need both sides?"). Over Epicbox they do not have to be online right now: the payment waits until their wallet opens. Meanwhile the coins it uses are locked, so they cannot be spent twice.'),
        HelpBlock.p('When their answer comes back, the wallet finishes the payment and posts it to the network by itself. It is final after $confirmations confirmations.'),
        HelpBlock.p('**No answer?** After a few minutes the status says "Waiting for recipient". Ask them to open their wallet. If the answer never comes, cancel the payment in $cancelPlace to unlock the coins. A payment nobody answers cancels by itself after about a day.'),
        if (phone)
          HelpBlock.p('Sending needs a synced node. An Epicbox address also needs the Epicbox server to answer; a Link address (${tor ? 'http or .onion' : 'http'}) needs the recipient’s wallet open and reachable at that moment.')
        else
          HelpBlock.p('Sending needs a synced node. An Epicbox address also needs Epicbox receiving to be on; a Link address (${tor ? 'http or .onion' : 'http'}) needs the recipient’s wallet open and reachable at that moment.'),
      ],
      id: HelpId.send,
    ),
    HelpTopic(
      'start',
      'Send with a file',
      'The manual way: save a transaction file, pass it to the recipient, then open the response file they send back.',
      [
        const HelpBlock.p('Direct · File Transfer does the same handshake as Epicbox, but the messages travel by hand, for example by chat or a USB stick. It works without Epicbox and without both wallets being online at the same time.'),
        if (phone)
          const HelpBlock.ol(['**Sender:** on Send, choose **Direct · File Transfer**, enter the amount and share the file (it ends in .tx). The coins are locked from now on.', '**Recipient:** opens the file under [[Receive › Direct · File]]. Their wallet signs it and shares a response file (it ends in .response). They send that file back.', '**Sender:** opens the response file under [[Receive › Direct · File]]. The wallet finishes the payment and posts it.'])
        else
          const HelpBlock.ol(['**Sender:** on Send, choose **Direct · File Transfer**, enter the amount and save the file (it ends in .tx). The coins are locked from now on.', '**Recipient:** opens the file under [[Receive › Transaction files › Sign a transaction file]]. Their wallet signs it and saves a response file (it ends in .response). They send that file back.', '**Sender:** opens the response file under [[Receive › Transaction files › Finalize a response file]]. The wallet finishes the payment and posts it.']),
        const HelpBlock.p('Other Epic Cash wallets have their own names for these steps. If the response file never comes, cancel the payment in Activity to unlock the coins.'),
      ],
      id: HelpId.file,
    ),
    if (phone)
      const HelpTopic(
        'start',
        'Pay in person: Direct · QR Payment',
        'Two phones next to each other pay with an animated QR code, no connection between them.',
        [
          HelpBlock.p('The payment travels as an animated QR code that the other phone scans with its camera. Nothing is encrypted, so show the code only to the person you pay.'),
          HelpBlock.ol(['**Sender:** on Send, choose **Direct · QR Payment**, enter the amount, tap **Make payment QR**, then **Show QR**. The code stays hidden until you show it, counts 3, 2, 1, and hides itself after 40 seconds.', '**Receiver:** on [[Receive › Direct · QR]], tap **Scan payment QR**, accept the payment, then show the reply the same way.', '**Sender:** taps **Scan their reply**. The wallet posts the payment and the tracker follows it.']),
          HelpBlock.p('Keep the code in the frame until every part is read: the ring and the count show how far it got. A code that is not a payment QR is ignored, with a note. Screenshots are blocked on the code screen.'),
        ],
        id: HelpId.qr,
      ),
    HelpTopic(
      'start',
      'Payment methods and send defaults',
      'Every method is a switch; Epicbox is on by default. Send opens on the default method.',
      [
        HelpBlock.p('The ${phone ? 'Transactions' : 'Payments'} page in $payPlace holds three things.'),
        HelpBlock.ul([
          '**Payment methods.** One switch each. **Epicbox** is on by default; off, the wallet connects to no server, so no Epicbox payments or invoices, and Receive shows no Epicbox address (payments sent to it wait on the server). ${tor ? "**Link · HTTP** (to web addresses), **Link · Tor** (to .onion addresses${phone ? ', and a Tor address of this phone to be paid at' : ''}) and ${phone ? '**Direct · QR Payment** and ' : ''}**Direct · File Transfer**" : "**Link · HTTP** (to web addresses)${phone ? ', **Direct · QR Payment**' : ''} and **Direct · File Transfer**"} need no Epicbox server. A method that is off does not appear on Send and Receive.${phone ? ' On a phone, **Link · HTTP** has no switch: it only sends, to any http(s) address you paste.' : ''}',
          '**Default method.** The method the Send screen opens with; another can be picked on Send.',
          '**Send defaults.** Which outputs a send spends, Smallest or All, and whether its change is split. They show only while **Send options** is on in Advanced.',
        ]),
      ],
      id: HelpId.methods,
    ),
    HelpTopic(
        'start',
        'What an address looks like',
        tor
            ? 'An Epicbox address starts with es and ends in @ and a server name. A Link address is a web address or ends in .onion.'
            : 'An Epicbox address starts with es and ends in @ and a server name. A Link address is a web address.',
        [
          HelpBlock.ul([
            '**Epicbox**: about 52 characters starting with **es**, then **@** and the server, for example **esXXXX…XXXX@${hostSettings.epicboxUse}**. The default; the recipient can be offline.',
            if (tor)
              '**Link · HTTP** and **Link · Tor**: the recipient’s own wallet, open right now. A web address such as **http://host:${appConfig.httpListenPort}** goes by Link · HTTP; a Tor address of 56 characters ending in **.onion** goes by Link · Tor, over Tor.'
            else
              '**Link · HTTP**: the recipient’s own wallet, open right now. A web address such as **http://host:${appConfig.httpListenPort}** goes by Link · HTTP.',
          ]),
          HelpBlock.p('Send picks the method from the address pasted into the To field. When reading an address out, compare the first six and the last six characters.'),
        ],
        id: HelpId.addresses,
      ),
    HelpTopic(
      'how',
      'Why does a transaction need both sides?',
      'In Epic Cash the recipient’s wallet helps build every transaction, so both wallets must take part.',
      [
        HelpBlock.p('Epic Cash uses Mimblewimble. Instead of writing an address and an amount on the chain, the two wallets build each transaction together, like a handshake:'),
        HelpBlock.ol(['The sender’s wallet starts it and locks the outputs being sent.', 'The recipient’s wallet adds its part and signs.', 'The sender’s wallet signs too, finishes the transaction and posts it to the network.']),
        HelpBlock.p('Something has to carry the messages between the two wallets. **Epicbox** holds each message while the other wallet is offline, so both need not be online at once. ${tor ? '**Link · HTTP** and **Link · Tor** go straight' : '**Link · HTTP** goes straight'} to the other wallet while it is open. **Direct · File Transfer**, with a transaction file, is the manual way.'),
      ],
      handshake: true,
      id: HelpId.handshake,
    ),
    HelpTopic(
      'how',
      'Confirmations',
      'A payment is final after $confirmations confirmations.',
      [
        const HelpBlock.p('When the network accepts a transaction, a miner puts it in a block. The block that holds the transaction is the first confirmation, and every block after it adds one more and makes the transaction harder to undo.'),
        HelpBlock.p('This wallet treats a transaction as final after **$confirmations confirmations**. Until then it shows as **Confirming**, and received outputs cannot be spent yet. The number is a setting: 6 by default, any count from 1 to 30. Fewer confirmations are faster but less safe: now and then the chain replaces its newest blocks (a reorganisation), and a payment with few confirmations can be undone by it.'),
        const HelpBlock.ul(['**Waiting**: both wallets have to sign the payment. Over Epicbox this happens by itself.', '**Confirming**: the payment is on the chain and collects confirmations.', '**Spendable**: the confirmations are in, and the coins can be spent.']),
        const HelpBlock.p('Taking longer than usual? The wallet sees new blocks only through its node: check that the node is synced.'),
      ],
      id: HelpId.confirmations,
    ),
    HelpTopic(
      'how',
      'What the blockchain shows',
      'No addresses and no amounts: only coin records the network can check without seeing who or how much.',
      [
        const HelpBlock.p('On many blockchains anyone can look up an address and see its balance and history. Epic Cash is different:'),
        HelpBlock.ul(['**No addresses on the blockchain.** The Epicbox address only tells Epicbox where to deliver messages. It is never written on the blockchain.', '**No amounts on the blockchain.** Amounts are hidden with cryptography, and the network can still check that no coins were created out of nothing.', '**Notes stay off the blockchain.** A message added to a send goes only to the other wallet. Contacts and wallet names stay on $device.']),
        HelpBlock.p('What is not hidden: the node and the Epicbox server see the wallet’s IP address, and a public node can see which outputs the wallet asks about. ${tor ? 'With **Tor only**, the wallet connects to the node and the Epicbox server through Tor. ' : ''}A VPN hides the IP address.'),
      ],
      id: HelpId.privacy,
    ),
    HelpTopic(
      'how',
      'Locked amounts and change',
      'The balance is made of separate outputs. A send spends whole outputs and returns the rest as change.',
      [
        const HelpBlock.p('The balance is a set of outputs. To send 3 EPIC from a 5 EPIC output, the wallet spends the whole output: 3 EPIC go to the recipient, a small fee goes to the miners, and the rest comes back as a new output, the **change**.'),
        const HelpBlock.p('That is why part of the balance can be unavailable for a few minutes after a send:'),
        HelpBlock.ul(['**Locked**: outputs in a send that is not finished yet. They are unlocked if the send is cancelled.', '**Awaiting finalization**: a transaction still waiting for the other wallet.', '**Confirming**: outputs in a block with fewer than $confirmations confirmations, including the change.']),
        const HelpBlock.p('The outputs are listed under [[Outputs]].'),
      ],
      id: HelpId.locked,
    ),
    HelpTopic(
      'how',
      'Smallest or All: which outputs a send spends',
      'Smallest (the default) uses the fewest small outputs and leaves the rest spendable. All uses every output.',
      [
        const HelpBlock.p('**Smallest** sorts the spendable outputs by value and takes the smallest ones until the amount and fee are covered. Only those are locked while the send confirms; the rest can be sent right away.'),
        HelpBlock.p('**All** spends every spendable output and returns one change output. Everything is locked for $confirmations blocks, the wallet ends up with fewer, larger outputs, and the fee is a little higher because each input costs. Sending the whole balance always uses All.'),
        HelpBlock.p('The default is set under $payPlace, with Send options switched on in Advanced.'),
      ],
      id: HelpId.strategy,
    ),
    HelpTopic(
      'how',
      'Split and consolidate',
      'Split makes more outputs so sends can follow each other; Consolidate merges them into one.',
      [
        HelpBlock.p('Both are normal network transactions from this wallet to itself, confirmed after $confirmations blocks like any send, and both lock every spendable output until then.'),
        const HelpBlock.ul(['**Split** takes the spendable balance and makes 2 to 10 outputs of nearly equal value.', '**Consolidate** takes every spendable output and makes one.', '**Split change** (on by default) does the same inside an ordinary send when few outputs would be left, for 0.004 EPIC per extra output.']),
        const HelpBlock.p('Activity shows each as two entries, a send and a receive, both with this wallet. Both are under [[Outputs › Manage outputs]].'),
      ],
      id: HelpId.split,
    ),
    const HelpTopic(
      'how',
      'Fees',
      'Every transaction pays a small network fee, shown before sending. It goes to the miners.',
      [
        HelpBlock.p('The fee depends on how many outputs the transaction spends and creates, not on the amount. It is usually a small fraction of one EPIC.'),
        HelpBlock.p('It shows as **Network fee** before sending. **Max**, next to the amount, fills in the whole spendable balance minus the exact fee, so no change is left.'),
      ],
      id: HelpId.fees,
    ),
    HelpTopic(
      'safety',
      'Your recovery phrase',
      'These words are the only way to get the EPIC back. Write them on paper and never share them.',
      [
        HelpBlock.p('The recovery phrase (24 words for a new wallet) is the key to the money. With it the wallet can be restored on any ${phone ? 'phone or computer' : 'computer'}, and anyone else who has it can take the EPIC.'),
        const HelpBlock.ul(['Write the words on paper, in this order, and keep the paper somewhere safe and offline.', 'Never keep them as a photo, screenshot or file. Never type them into a website or a chat.', 'Nobody from Epic Cash or this wallet will ever ask for them.']),
        if (phone)
          HelpBlock.p('To see the words again, open $phrasePlace and enter $secret. The app never sends them anywhere. Better not to copy them: if copied, the wallet clears the clipboard after 60 seconds, and when the wallet locks or closes.')
        else
          HelpBlock.p('To see the words again, open $phrasePlace and enter $secret. Better not to copy them: if copied, the wallet clears the clipboard after 60 seconds, and when the wallet locks or closes.'),
      ],
      id: HelpId.phrase,
    ),
    if (phone)
      const HelpTopic(
        'safety',
        'PIN or passphrase',
        'The PIN or a passphrase unlocks this wallet on this phone. Only the recovery phrase restores the coins.',
        [
          HelpBlock.p('The PIN or a passphrase unlocks this wallet on this phone; only the recovery phrase restores the coins. A passphrase is longer and harder to guess: at least 10 characters, not only digits. Turn it on under [[Settings › Security]].'),
          HelpBlock.p('The time to crack shown while choosing a passphrase is an estimate on this phone.'),
          HelpBlock.p('**Forgot it?** Restore the wallet from its recovery phrase and choose a new one.'),
        ],
        id: HelpId.passphrase,
      ),
    HelpTopic(
      'safety',
      'Backups and restoring',
      'The recovery phrase is the backup. To restore a wallet, enter its words in Restore from phrase.',
      [
        const HelpBlock.p('The recovery phrase brings back everything that is on the chain, which is the balance.'),
        HelpBlock.p('**To restore** on a new ${phone ? 'phone' : 'computer'} or after a loss: open $restorePlace, enter the words and choose ${phone ? 'a PIN' : 'a password'}. When the wallet opens, it scans the chain for its outputs. The balance appears after that first scan; the payments it finds are labelled **Restored**.'),
        HelpBlock.p('**What a restore cannot bring back:** what was never on the chain, such as who paid what, notes and labels, contacts, invoices, settings and wallet names. A wallet data file keeps them: $historyBackupPlace.${phone ? ' Keep the file outside the phone, for example in cloud storage or on a USB stick.' : ''}'),
        const HelpBlock.p('**The wallet data file is not the recovery phrase.** It holds no words and cannot restore the wallet on its own. To restore: enter the recovery phrase first, then import the file; the wallet offers that right after the restore.'),
        HelpBlock.p('**Balance looks wrong?** Run $recheckPlace. It reads the whole chain again for this wallet’s outputs.'),
        if (!phone)
          const HelpBlock.p('**Export CSV** saves the payment list as a spreadsheet file named **epic-payments-<wallet>-<date>.csv**, with the columns date, type, status, amount, fee, counterparty, note, slate ID, kernel and block height. It is not encrypted: anyone with the file can read amounts, dates, addresses and notes. It cannot be imported again; **Export wallet data** is for that.'),
        if (!phone)
          const HelpBlock.p('**The wallet’s files** are in [[Settings › Files & logs › Wallet folder]]. Keep the recovery phrase even with a copy of them: it works when the files are lost.'),
      ],
      id: HelpId.backup,
    ),
    const HelpTopic(
      'safety',
      'Before you import',
      'The import only reads older wallets and files. Have a backup of every wallet first; you import at your own risk.',
      [
        HelpBlock.p('This is an early version of a new app.'),
        HelpBlock.p('The import only reads your old wallets and files and never deletes or changes them.'),
        HelpBlock.p('Before you continue, make sure you have a backup of every wallet: its recovery phrase, and its wallet files if you keep them.'),
        HelpBlock.p('You import at your own risk; no responsibility is taken for any loss.'),
      ],
      id: HelpId.importWarning,
    ),
    HelpTopic(
      'network',
      phone ? 'Nodes' : 'Nodes: a public one or a local one',
      phone
          ? 'A node connects the wallet to the Epic Cash network. The wallet uses a public one; pick another when it falls behind.'
          : 'A node connects the wallet to the Epic Cash network. A public node is quickest; a local one is your own.',
      [
        const HelpBlock.p('The wallet needs a node to read the chain (the balance and confirmations) and to post transactions to the network.'),
        if (phone)
          HelpBlock.p('A **public node** is one of the nodes others run. It works right away. Whoever runs it can see the wallet’s IP address and which outputs it asks about${tor ? '; with **Tor only**, the wallet reaches it through Tor' : ''}.')
        else
          const HelpBlock.ul(['**Public node** (the default): one of the public nodes others run. It works right away. Whoever runs it can see the wallet’s IP address and which outputs it asks about.', '**Local node**: runs on this computer as a separate program that starts and stops with the app. It first downloads the whole chain (about 4 GB the first time, then a little every day), which takes a while; on disk it takes about 5 GB and grows slowly. While it syncs, the wallet shows its progress and uses a public node. See "Running the local node".']),
        if (phone)
          HelpBlock.p('Change it by tapping the node icon on the Wallet tab, or under $nodePlace: the nodes are listed with their state. Tap one to switch to it at once, or type an address to filter the list or add a node. Sending needs a synced node; **{n} behind** or **Not answering** means pick another.')
        else
          HelpBlock.p('Change it in $nodePlace: the nodes are listed with their state. Click one to switch to it at once, or type an address to filter the list or add a node. Sending needs a synced node; if the node falls behind, the wallet offers another one.'),
      ],
      id: HelpId.node,
    ),
    if (!phone)
      HelpTopic(
        'network',
        'Running the local node',
        'Ports, peers, chain data and owner access of the node that runs on this computer.',
        [
          HelpBlock.p('The local node is a separate program that comes with the app. It keeps its own copy of the chain, so the wallet asks nobody else. It takes about 5 GB of disk and grows slowly; the first download is about 4 GB, then a little every day. Until it is synced, nothing can be sent or received through it, and the wallet can use a public node meanwhile.'),
          HelpBlock.ul([
            '**Start with the app** starts the node at launch and keeps it syncing while the app is open. It stops when the app closes.',
            '**Ports.** The API port (3413) is what the wallet talks to; the P2P port (3414) is how other nodes reach this one. Change them only when another node on this computer or network already uses them. The node restarts with the new ports.',
            '**Peers.** The node finds peers by itself. Preferred peers are added first. Max incoming and Max outgoing take a number from 8 to 500. Peers can be banned and unbanned on the Peers tab.',
            '**Chain data.** **Reuse existing** lets the node read chain data another Epic node left on this computer, instead of downloading it; nothing is copied, and Delete chain data is off for that folder. **Delete** removes this node’s chain data; the whole chain downloads again on the next start. Keys and history stay.',
            '**Owner access.** Sync stage and peers come from the node’s owner API. Its secret is the first line of the file **.api_secret** in the node’s data folder. The wallet keeps the secret in this computer’s keyring, never in the settings or in the wallet data file. For a node on another computer the secret travels over plain http, readable on that network: use a VPN or https on a shared network.',
          ]),
        ],
        id: HelpId.localNode,
      ),
    if (!phone)
      HelpTopic(
        'network',
        'Should this computer run a node?',
        'A local node suits a wallet that stays open for hours. A public node suits short visits.',
        [
          HelpBlock.p('The local node is in sync only while the app is open. After a break it first catches up on the blocks it missed, so the longer the wallet stays open, the more of that time the node is in sync, keeps lookups private and passes blocks on to other nodes.'),
          HelpBlock.ul([
            '**Most of the day.** A good fit: the node is in sync almost all the time.',
            '**An hour or two.** It works, with a catch-up at the start of each visit.',
            '**A few minutes.** Most of each visit goes to catching up. A public node is faster.',
            '**Metered connection.** The first sync downloads the whole chain, about 5 GB. Start it on a connection without a data limit.',
          ]),
          HelpBlock.p('The fit check asks these two questions when the local node is picked in $nodePlace. It suggests an answer from how long the wallet was open over the last days, counted on this computer only and never sent anywhere. On Windows it also reads whether the connection is metered.'),
        ],
        id: HelpId.nodeFit,
      ),
    HelpTopic(
      'network',
      'Epicbox',
      'Epicbox delivers transactions between wallets and holds them while the other wallet is offline.',
      [
        const HelpBlock.p('Both wallets take part in every transaction, so their messages need a meeting point. An Epicbox server is that meeting point: it holds a payment sent to this wallet until the wallet comes online, and carries the wallet’s answer back. The messages are encrypted, and Epicbox cannot spend the coins.'),
        const HelpBlock.p('The Epicbox address is the wallet’s public key, then **@** and the name of its Epicbox server.'),
        if (phone)
          HelpBlock.p('The server is set by tapping the Epicbox icon on the Wallet tab, or under $epicboxPlace: the servers are listed with their state. Tap one and confirm, or type an address to filter the list or add a server. Choosing another server changes the part after @, so give the new address to the people who pay. Other Epic Cash wallets use Epicbox too; two wallets can use different servers.')
        else
          HelpBlock.p('The server is set under $epicboxPlace: the servers are listed with their state. Click one and confirm, or type an address to filter the list or add a server. Choosing another server changes the part after @, so give the new address to the people who pay. Other Epic Cash wallets use Epicbox too; two wallets can use different servers.'),
      ],
      id: HelpId.epicbox,
    ),
    if (tor && phone)
      HelpTopic(
        'network',
        'Tor',
        'The network mode Tor only routes the wallet’s connections through Tor and gives it a .onion address. Slower. Off by default.',
        [
          HelpBlock.p('With $torPlace, the Epicbox connection goes through Tor, a payment to a .onion address goes through Tor, and the wallet has a Tor address of its own (it ends in .onion) that other wallets can pay straight to.'),
          const HelpBlock.ul([
            'The node, the Epicbox server and the addresses stay the same.',
            'A Link payment to an onion address goes through Tor; Send shows whether a payment goes over Tor.',
            'Slower than without Tor. Tor is blocked in some countries; there it does not connect.',
            'Receiving at the .onion address works while the app is open; Epicbox keeps working beside it.',
          ]),
          const HelpBlock.p('**Starting…** means Tor is connecting; the covered connections wait and never fall back. **Not connected** means it failed: Retry, or turn Tor off. Some wallets show a Tor address without .onion; both are the same address.'),
        ],
        id: HelpId.tor,
      )
    else if (tor)
      const HelpTopic(
        'network',
        'Tor',
        'The network mode Tor only routes the wallet’s connections through Tor, with no ports to open. Slower. Off by default.',
        [
          HelpBlock.p('With Tor on, the connection to the Epicbox server goes through Tor, and the wallet has a Tor address (it ends in .onion) that other wallets can pay straight to, from anywhere, with nothing to forward on the router. Turning Tor on does not change the addresses you share.'),
          HelpBlock.ul([
            'Turn it on with [[Settings › Network & privacy › Tor only]]. The Tor row in the sidebar shows its state.',
            'While Tor starts or is not connected, what goes over Tor waits; nothing goes around it. Retry, or turn Tor off.',
            'Link sends to an http(s) address do not go over Tor; Send says so.',
            'Link · HTTP receiving is off while Tor is on: payments straight from another wallet arrive at the Link · Tor address.',
            'Tor is blocked or not allowed in some countries; there it does not connect.',
          ]),
          HelpBlock.p('Some wallets show the address without .onion; both are the same address.'),
        ],
        id: HelpId.tor,
      ),
    HelpTopic(
      'network',
      'Network modes',
      tor
          ? 'Normal, Tor only, Node only or Kill switch: what each one connects to, and how to pay from a wallet that never goes online.'
          : 'Normal, Node only or Kill switch: what each one connects to, and how to pay from a wallet that never goes online.',
      [
        HelpBlock.p('How much of the internet the wallet uses is one choice under $netPlace, and the wallet remembers it. Off **Normal**, a mark on ${phone ? 'Home' : 'the title bar'} names the mode; tap it to change it.'),
        HelpBlock.ul([
          tor
              ? '**Normal**: everything the wallet is set up for: the node, Epicbox, Link, the status site, price and update checks.'
              : '**Normal**: everything the wallet is set up for: the node, Epicbox, Link, the status site, price and update checks.',
          if (tor)
            '**Tor only**: every connection goes through Tor, the node and Epicbox included. Until Tor is ready nothing connects, and the status icons say **Waiting for Tor**. Link · HTTP receiving stays off.',
          '**Node only**: the wallet talks only to the node in use, the first in your node list. Epicbox, Link, the status site, price, update checks, explorer links, problem reports, pairing and linked devices are off. ${phone ? '**Direct · QR Payment** and **Direct · File Transfer**' : '**Direct · File Transfer**'} work.${tor ? ' With Tor on, the node is reached over Tor.' : ''}',
          '**Kill switch**: nothing connects, the node included. The wallet opens with the last known balance and history. You can make, sign and finish payments by ${phone ? '**Direct · File Transfer** and **Direct · QR Payment**' : '**Direct · File Transfer**'}, show your address, back up and export. Sends waiting for a recipient pause and continue when you leave.',
        ]),
        const HelpBlock.h('Why your own node for Node only', anchor: HelpAnchor.ownNode),
        HelpBlock.p('The node in use sees every request the wallet makes. A node on ${phone ? 'this phone or your network' : 'this computer or your network'} keeps that to yourself and answers fast. Any node works. Pick it under $nodePlace.'),
        const HelpBlock.h('Paying from Kill switch', anchor: HelpAnchor.coldStorage),
        HelpBlock.ol([
          'Make the payment by ${phone ? '**Direct · File Transfer** or **Direct · QR Payment**' : '**Direct · File Transfer**'} as usual, and finish it when the reply comes back.',
          'The wallet says **Finished, not posted**: it is complete, but only a device that is online can post it.',
          '**Save file** or ${phone ? '**Show QR**' : '**Copy** the text'}, and take it to a device that is online.',
          'There, ${phone ? 'open the Activity menu and choose **Post a finished payment**' : 'open Receive, then Transaction files, and choose **Post a finished payment**'}, load the file${phone ? ' or scan the code' : ' or paste the text'} and press **Post**. Any Epic Cash wallet can do this; it needs no key.',
          'Back here the payment shows **To be posted elsewhere**, then **Confirming** once the wallet sees it on chain after you leave Kill switch.',
        ]),
        HelpBlock.p('Services a mode turns off show as **Off (Node only)** in grey: that is the mode, not an error. Nothing is cancelled when you switch; a send waiting for its recipient over Epicbox continues when you leave${tor ? ' (or switch to Tor only)' : ''}.'),
        HelpBlock.p('**Node failover** is on by default. When your node has not answered for 30 seconds, the wallet moves to the next working node in your list, for this session only: your own node stays saved, and the wallet is back on it at the next start, or as soon as you pick a node yourself. It never moves in Node only or Kill switch${phone ? '' : ', or away from a node on this computer'}${tor ? ', and with Tor only it moves only to a node reachable over Tor' : ''}.'),
      ],
      id: HelpId.modes,
    ),
    HelpTopic(
      'network',
      'Advanced',
      'Off to begin with. Each switch shows one more part of the wallet, where it belongs.',
      [
        const HelpBlock.p('**Advanced** is a page in Settings for the parts most people never need. Everything on it is off to begin with, so the wallet stays simple. A switch adds its part where it belongs, and **Hide everything again** switches them all off.'),
        HelpBlock.ul([
          '**Outputs**: the Outputs page, with the coins the balance is made of and what you can do with them.',
          '**Technical details**: slate ID, kernel, commitments and block height on a ${phone ? 'payment’s details' : 'transaction'}. Without it, the **More** link on a transaction shows them once.',
          if (phone)
            '**Send options**: Strategy and Split change, in $payPlace: which outputs a send spends, and whether its change is split.'
          else
            '**Send options**: a fold on Send where one send chooses Smallest or All, and whether to split the change.',
          '**Server details**: hosts, latency, version and block height in the node and Epicbox lists and on the status card.',
          if (phone)
            '**Recheck from a height**: lets Recheck balance start from a block height or a date instead of the first block. Restore always offers the choice.'
          else
            '**Recheck from a height**: lets Recheck balance also drop unconfirmed transactions. Restore offers a start block to everyone.',
          if (!phone) '**Local node**: lets this computer run its own node, under $nodePlace.',
          if (!phone) '**Logs**: the Logs group under $filesPlace, to open the log folder or clear the logs. Report a problem attaches the log either way.',
        ]),
        HelpBlock.p('**Confirmations** sets how many blocks a received payment waits before its outputs can be spent: 6 by default, any count from 1 to 30. Fewer confirmations are faster but less safe.${phone ? '' : ' It is set under $payPlace.'}'),
        HelpBlock.p(phone ? 'The network mode and **Node failover** are under $netPlace: see "Network modes".' : 'The network mode is under $netPlace: see "Network modes". **Switch node automatically** is under $nodePlace.'),
      ],
      id: HelpId.advanced,
    ),
    HelpTopic(
      'trouble',
      'Troubleshooting',
      phone
          ? 'Most problems are a node still syncing or a recipient who has not answered yet.'
          : 'Most problems are a node still syncing, a recipient who has not answered yet, or a busy port.',
      [
        if (phone)
          const HelpBlock.p('**"Node not synced": cannot send.** Sending opens when the node has caught up. Wait a little, or tap the node icon on the Wallet tab and choose another node.')
        else
          const HelpBlock.p('**"Node not synced": cannot send.** Sending opens when the node has caught up. Wait a little, or choose another node under [[Settings › Node]].'),
        if (phone)
          const HelpBlock.p('**"Epicbox not answering".** The wallet cannot reach its Epicbox server. Wait a moment; if it stays like this, check the connection or tap the Epicbox icon on the Wallet tab and pick another server. Meanwhile Direct · File Transfer works.')
        else
          HelpBlock.p('**"Epicbox not answering".** The wallet cannot reach its Epicbox server. Wait a moment; if it stays like this, check the connection or pick another server under $payPlace. Meanwhile Direct · File Transfer works.'),
        const HelpBlock.p('**A send says "Waiting for recipient".** Their wallet has not answered yet. Ask them to open it. If they never will, cancel the payment in Activity to unlock the coins.'),
        if (phone)
          const HelpBlock.p('**A payment has not arrived.** Check the status icons on the Wallet tab: the node synced, Epicbox connected. After a change of Epicbox server, the sender needs the new address. The sender’s wallet also has to finish the transaction; then a few minutes for the confirmations.')
        else
          const HelpBlock.p('**A payment has not arrived.** Check on Receive that receiving is on and the node is synced. After a change of Epicbox server, the sender needs the new address. The sender’s wallet also has to finish the transaction; then a few minutes for the confirmations.'),
        if (phone && tor)
          const HelpBlock.p('**Tor says "Not connected".** Tor could not reach its network. Press Retry under [[Settings › Network & privacy]], or turn Tor off; nothing goes out meanwhile.'),
        if (!phone) ...[
          HelpBlock.p('**"Port ${appConfig.httpListenPort} is in use by another program".** Another program, often another Epic wallet, uses the port for Link · HTTP payments. Close it, then press Try again on Receive. ${tor ? 'Epicbox, Link · Tor and Direct · File Transfer keep' : 'Epicbox and Direct · File Transfer keep'} working meanwhile.'),
          const HelpBlock.p('**"Another Epic program is using this folder".** Another Epic wallet or node has the same files open. Close it and try again.'),
        ],
        if (phone)
          const HelpBlock.p('**Forgotten PIN.** Delete the wallet on the unlock screen and restore it from its recovery phrase with a new PIN. Without the phrase the EPIC cannot be recovered.')
        else
          const HelpBlock.p('**"Wrong password".** Check Caps Lock and the keyboard layout. A forgotten password: restore the wallet from its recovery phrase and choose a new one.'),
        HelpBlock.p(tor
            ? '**An action is greyed out and names a mode, or says "Waiting for Tor".** Tor only, Node only or Kill switch is on under $netPlace. Set the mode back to Normal there, or wait for Tor to connect.'
            : '**An action is greyed out and names a mode.** Node only or Kill switch is on under $netPlace. Set the mode back to Normal there.'),
        HelpBlock.p('**The balance looks wrong.** Run $recheckPlace.'),
      ],
      id: HelpId.trouble,
    ),
    const HelpTopic(
      'trouble',
      'Payments by another wallet',
      'Payments this wallet did not make or receive itself: the same recovery phrase is in use in another wallet.',
      [
        HelpBlock.p('A row called **Sent from another device** or **Received by another device** is a payment of another wallet that uses the same recovery phrase. The chain shows these coins spent or received, so this wallet lists it.'),
        HelpBlock.p('The amount is what left this wallet after the change that came back, or what arrived. The other side and the fee are not known here.'),
        HelpBlock.p('**If you use no other wallet with this phrase**, ask another node first: switch to another node and use Recheck balance. A node that leaves coins out of its answers can make them look spent. If they still show spent, someone else may have the recovery phrase: move the EPIC to a new wallet with a new phrase.'),
        HelpBlock.p('**A send that fails with "The node shows these coins already spent, and this wallet did not spend them. Most likely another wallet using your recovery phrase did."** was released. The wallet refreshes; send again once the balance is right.'),
      ],
      id: HelpId.otherWallet,
    ),
    HelpTopic(
      'trouble',
      'Cancelling a payment',
      'When Cancel is certain, when it is not, and what happens to the coins.',
      [
        const HelpBlock.p('Cancel stops a payment that has not gone through yet. Whether it is certain depends on one thing: whether the other side already has what it needs to finish the payment. If not, Cancel is certain: the payment cannot go through without this wallet, and cancelling is free. If so, the other side could still finish the payment, and the wallet offers two ways to cancel.'),
        const HelpBlock.h('Move coins back, or unlock them', anchor: HelpAnchor.twoWays),
        const HelpBlock.p('**Move coins back** moves the coins back to this wallet first, for the normal network fee; after that the old payment can never go through. **Unlock coins** is free and moves nothing: the coins are spendable again, and the payment is left as it is. If the other side still finishes it, it shows as paid; if not, nothing happens.'),
        const HelpBlock.h('Sending', anchor: HelpAnchor.sending),
        const HelpBlock.p('A payment sent from this wallet first waits for the other side’s answer. While it waits, Cancel is certain: nothing can go through without this wallet, and the coins are unlocked at once. No fee. The other wallet may still show the payment as waiting, but it cannot finish it.'),
        HelpBlock.p('Once the answer is in, this wallet finishes the payment and posts it to the network in one step. A payment that reached the network cannot be cancelled, undone or refunded; only the recipient can pay it back. If the network does not take it, the payment is complete all the same and could still go through later. ${phone ? 'After about a day the wallet offers Release coins, with the same two ways: Move coins back moves the coins back to this wallet, for the normal network fee; Unlock coins is free.' : 'The wallet offers to post it again, or to cancel. That Cancel checks the network first and refuses when the network already has the payment. Otherwise it offers the same two ways: Move coins back moves the coins back to this wallet, for the normal network fee; Unlock coins is free.'}'),
        const HelpBlock.p('A payment nobody answers cancels by itself after about a day (1,440 blocks), and the coins are unlocked. This holds for Epicbox, Link and Direct payments alike: Cancel is certain until the other side’s answer is in this wallet.'),
        HelpBlock.p('**A send looks stuck.** Usually the other wallet is offline. Wait, or cancel it in $cancelPlace and send again. A cancelled payment cannot go through later.'),
        const HelpBlock.p('**Declined by the receiver**: the receiver’s wallet refused the payment. The send is cancelled and its coins are free to spend again.'),
        const HelpBlock.h('Receiving', anchor: HelpAnchor.receiving),
        const HelpBlock.p('When a payment arrives, this wallet answers at once, and none of its coins are locked. From then on the sender’s wallet finishes and posts the payment, usually within minutes. Cancel is unavailable for 15 minutes, and longer while the sender reports it posted.'),
        const HelpBlock.p('After that, Cancel clears a payment the sender never posted. It is not certain: the wallet checks the network first and refuses when the payment is already there. A cancelled payment stays watched. If the sender posts it later, it arrives anyway and shows as received.'),
        const HelpBlock.h('Invoices', anchor: HelpAnchor.requests),
        const HelpBlock.p('An invoice sent from this wallet holds no coins until it is paid. It can be withdrawn any time before then: the payer can no longer pay it, and no coins move. An invoice nobody pays expires after 24 hours. An invoice shown as a QR code can be paid once; a second scan is refused, so nothing is paid twice.'),
        const HelpBlock.p('An invoice paid from this wallet is the other way round: the other side already has what it needs to finish the payment. Cancel appears once the invoice’s time runs out, about a day after it was paid, or sooner when the other side withdraws it. It offers the same two ways: Move coins back moves the coins back to this wallet, for the normal network fee, so the old payment can no longer go through; Unlock coins is free and leaves it to the other side. If the coins cannot be moved back at once, the wallet tries again while it is open. Until then the other side could still finish the payment, and if it does, it shows as paid.'),
      ],
      id: HelpId.cancel,
    ),
    if (!phone)
      const HelpTopic(
        'maintenance',
        'Clean up old wallet folders',
        'Remove from list keeps a wallet’s folder on disk. Deleting the folder is done by hand, with the recovery phrase written down or the wallet empty.',
        [
          HelpBlock.ul([
            '**Remove from list** in [[Settings › Wallets]] takes a wallet off the list. Its folder stays on disk, and the page offers it again under **Removed from list**.',
            '**Deleting a wallet folder without its recovery phrase loses the EPIC in it.** Delete only a wallet whose phrase is written down, or one that is empty and no longer needed.',
            'The folders sit under **wallets** in the data folder (**Open folder** next to [[Settings › Files & logs › App files]]), one per wallet, named by its ID; **WALLET.txt** inside gives the wallet’s name. With BT Wallet closed, delete that one ID folder and leave the rest as it is.',
          ]),
        ],
        id: HelpId.cleanup,
      ),
    HelpTopic(
      'maintenance',
      'The settings file',
      'One file holds your Node and Epicbox lists. A mistake in it never costs the last good settings.',
      [
        if (phone) ...[
          HelpBlock.p(
            'The app keeps a file of your Node and Epicbox lists and three switches: the status site, the update check and prices. Everything else comes with the app. The file is changed in the app, for example under $nodePlace and $epicboxPlace, not by hand.',
          ),
          HelpBlock.ul([
            '**The first server of each list is the one in use.** Picking a server moves it to the top; reordering the list changes the one in use. When the first node does not answer, the next one is tried.',
            '**The first Epicbox server is in the Epicbox address of every wallet.** Moving another one to the top gives each wallet a new address; payments sent to an old address do not arrive.',
            '**A file that cannot be read:** the last good settings stay in use. Before the app writes a new file, it saves the old one as **settings.toml.bad-<time>**.',
            'A deleted file is written again.',
          ]),
        ] else ...[
          HelpBlock.p(
            'The file **settings.toml** holds your Node and Epicbox lists and three switches: the status site, the update check and prices. Everything else comes with the app. It sits in the data folder: **~/.epic_cash_desktop/settings.toml** on Linux and macOS, **%USERPROFILE%\\.epic_cash_desktop\\settings.toml** on Windows (**Open folder** next to [[Settings › Files & logs › App files]]).',
          ),
          HelpBlock.ul([
            'A change in the app is written to the file at once. A change you save in the file applies while the app runs, within a moment.',
            '**The first server of each list is the one in use.** Picking a server moves it to the top; reordering the list changes the one in use. When the first node does not answer, the next one is tried.',
            '**The first Epicbox server is in the Epicbox address of every wallet.** Moving another one to the top gives each wallet a new address; payments sent to an old address do not arrive.',
            '**An error in the file:** the last good settings stay in use, a notice names the line, and a broken file is never overwritten.',
            'If the app has to write while the file has errors, it first saves the file as **settings.toml.bad-<time>**, then writes a good one.',
            'A deleted file is written again.',
          ]),
        ],
      ],
      id: HelpId.settingsFile,
    ),
    ...deviceHelpTopics('en', phone: phone),
    ...nameServiceHelpTopics('en', phone: phone),
  ];
}

/// Help › Pairing's six topics. Localized, unlike the rest, as they were written
/// for all six languages with the screens. The strings name the desktop's places; on the phone
/// [_phonePairingPlace] gives each the phone's own.
List<HelpTopic> pairingHelpTopics(AppLocalizations l, {HelpPlatform platform = HelpPlatform.desktop}) {
  String t(String text) => platform == HelpPlatform.phone
      ? text.replaceAllMapped(RegExp(r'\[\[(.+?)\]\]'), (m) => _phonePairingPlace(l, m.group(1)!, m.group(0)!))
      : text;
  const s = pairingHelpSection;
  final phone = platform == HelpPlatform.phone;
  return [
    HelpTopic(s, l.helpPairWhatTitle, l.helpPairWhatShort, [
      HelpBlock.p(t(l.helpPairWhatP1)),
      HelpBlock.p(t(l.helpPairWhatP2)),
      HelpBlock.ol([t(l.helpPairWhatStep1), t(l.helpPairWhatStep2), t(l.helpPairWhatStep3)]),
      HelpBlock.p(t(l.helpPairWhatP3)),
    ], id: HelpId.pairing),
    HelpTopic(s, l.helpPairRouteTitle, l.helpPairRouteShort(l.sendRoutePaired), [
      HelpBlock.p(t(l.helpPairRouteP1(l.sendRoutePaired))),
      HelpBlock.p(t(l.helpPairRouteP2)),
      HelpBlock.p(t(l.helpPairRouteP3(l.sendRoutePaired))),
      HelpBlock.p(t(l.helpPairRouteP4(l.sendRoutePaired))),
      HelpBlock.p(t(l.helpPairRouteP5)),
    ], id: HelpId.pairingRoute),
    HelpTopic(s, l.helpPairTwoWaysTitle, l.helpPairTwoWaysShort, [
      HelpBlock.p(t(l.helpPairTwoWaysP1)),
      HelpBlock.p(t(l.helpPairTwoWaysP2)),
      HelpBlock.p(t(l.helpPairTwoWaysP3)),
    ], id: HelpId.pairingWays),
    HelpTopic(s, l.helpPairWhyTitle2, l.helpPairWhyShort2, [
      HelpBlock.p(t(l.helpPairWhyP1b)),
      HelpBlock.p(t(l.helpPairWhyP2b)),
      HelpBlock.p(t(l.helpPairWhyP3b)),
      HelpBlock.p(t(l.helpPairWhyP4b)),
    ], id: HelpId.checkWords),
    // The desktop pays with the wallet password, the phone with a PIN.
    HelpTopic(s, l.helpPairInvTitle, phone ? l.helpPairInvShort : l.helpPairInvShortDesktop, [
      HelpBlock.p(t(l.helpPairInvP1)),
      HelpBlock.p(t(phone ? l.helpPairInvP2 : l.helpPairInvP2Desktop)),
      HelpBlock.p(t(l.helpPairInvP3)),
      HelpBlock.p(t(l.helpPairInvP4)),
    ], id: HelpId.invoices),
    HelpTopic(s, l.helpPairRestoreTitle, l.helpPairRestoreShort, [
      HelpBlock.p(t(l.helpPairRestoreP1)),
      HelpBlock.p(t(l.helpPairRestoreP2)),
      HelpBlock.p(t(l.helpPairRestoreP3)),
      HelpBlock.p(t(l.helpPairRestoreP4)),
    ], id: HelpId.pairingRestore),
  ];
}

/// The phone's place for one of the pairing strings' desktop places [inner] (the text between
/// `[[` and `]]`; [whole] with them).
String _phonePairingPlace(AppLocalizations l, String inner, String whole) {
  final bar = inner.indexOf('|');
  final target = bar < 0 ? inner : inner.substring(bar + 1).trim();
  // The phone's own words, whatever label the desktop's place carries.
  String link(List<String> words, String place) => '[[${words.join(' › ')}|$place]]';
  return switch (target) {
    'Invoices › Pay' => link([l.invoicesTitle, l.invoicesToPaySection], 'Invoices › To pay'),
    'Settings › Invoices' => link([l.settingsTitle, l.settingsSectionWallet, l.settingsInvoices], 'Settings › This wallet › Invoices'),
    _ => whole,
  };
}
