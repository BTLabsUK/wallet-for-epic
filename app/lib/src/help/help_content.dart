/// Help content shared by the desktop and the phone: the topic structure ([HelpTopic],
/// [HelpBlock], [helpInline]), the sections and the topics themselves. The desktop renders
/// them in Settings › Help, the phone in its Help screen. One source, so the two apps
/// explain Epic Cash with the same words; where the device differs (a computer or a phone, a
/// password or a PIN, where a setting lives) the text takes the [HelpPlatform] into account.
library;

import '../../l10n/app_localizations.dart';
import '../advanced.dart';

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
    this.id = '',
  });

  final String section;
  final String title;
  final String short;
  final List<HelpBlock> body;

  /// The handshake stepper goes under the body.
  final bool handshake;

  /// A stable name other screens open the topic by; see [HelpId].
  final String id;

  /// The body as plain text, for search and its marks.
  String get bodyText => [for (final b in body) for (final p in helpInline(b.text)) p.text].join(' ');
}

typedef HelpSection = ({String id, String title, String lede, String art});

const helpSections = <HelpSection>[
  (id: 'start', title: 'Getting started', lede: 'Receive, send, and the file way.', art: 'help-start'),
  (id: 'how', title: 'How Epic Cash works', lede: 'Both wallets take part; confirmations, privacy, change and fees.', art: 'help-how'),
  (id: 'safety', title: 'Keeping the wallet safe', lede: 'The recovery phrase is the backup and the key.', art: 'help-safety'),
  (id: 'network', title: 'Nodes and Epicbox', lede: 'What the wallet connects to, and Tor.', art: 'help-network'),
  (id: 'trouble', title: 'When something goes wrong', lede: 'The usual causes, and what to do.', art: 'help-trouble'),
  (id: 'maintenance', title: 'Maintenance', lede: 'Old wallet folders, and the folders of earlier versions.', art: 'help-maintenance'),
];

/// Help › Pairing (RFC 0002): shown when the wallet pairs, before "When something goes wrong".
/// It holds the invoice topic too: invoices come only from paired contacts.
const pairingHelpSection = 'pairing';

/// The ids screens open Help by ([HelpTopic.id]).
/// The topics that explain a part Advanced hides, by id: Help lists and finds them only while
/// that switch is on, so a search never leads to a page the wallet does not show. The Outputs
/// topics and the experimental ones (the Pairing section goes with Pairing as a whole): the
/// File Transfer method is everyday use and keeps its topic.
const Map<String, AdvancedFeature> helpTopicFeature = {
  HelpId.strategy: AdvancedFeature.outputs,
  HelpId.split: AdvancedFeature.outputs,
  HelpId.invoices: AdvancedFeature.invoices,
};

/// [topics] without those of a feature [prefs] keeps hidden.
List<HelpTopic> helpTopicsShown(List<HelpTopic> topics, AdvancedPrefs prefs) => [
  for (final t in topics)
    if (switch (helpTopicFeature[t.id]) {
      AdvancedFeature.invoices => prefs.invoicesOn,
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
  static const pairingWords = 'pairing-words';
  static const checkWords = 'check-words';
  static const invoices = 'invoices';
  static const pairingRestore = 'pairing-restore';
  static const cleanup = 'cleanup';
  static const importWarning = 'import-warning';
  static const cancel = 'cancel';
}

/// The headings of [HelpId.cancel] ("Cancelling a payment"), which the quiet line beside every
/// Cancel button opens the topic at ([HelpBlock.h]).
abstract final class HelpAnchor {
  static const sending = 'sending';
  static const receiving = 'receiving';
  static const requests = 'requests';
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
  final secret = phone ? 'your PIN' : 'the wallet password';
  final nodePlace = phone ? '[[Settings › Privacy & network › Node]]' : '[[Settings › Node]]';
  final epicboxPlace = phone ? '[[Settings › Privacy & network › Epicbox]]' : '[[Settings › Transactions › Epicbox]]';
  final torPlace = phone ? '[[Settings › Privacy & network › Tor Network]]' : '[[Settings › Privacy › Tor]]';
  final cancelPlace = phone ? '[[Activity]] (open the payment, then Cancel payment)' : '[[Activity › the transaction › Cancel]]';
  final historyBackupPlace = phone ? '[[Settings › Wallet › Export wallet data]]' : '[[Settings › This wallet › Export wallet data]]';
  final restorePlace = phone
      ? '**Restore from a phrase** (on the first screen, or under [[Settings › Wallet]])'
      : '**Restore from a phrase** (on the first screen, Unlock › Add a wallet, or [[Settings › All wallets]])';
  final recheckPlace = phone ? '[[Settings › Wallet › Recheck balance]]' : '[[Settings › Recheck balance]]';
  final phrasePlace = phone ? '[[Settings › Security › Back up recovery phrase]]' : '[[Settings › Recovery phrase]]';
  return <HelpTopic>[
    HelpTopic(
      'start',
      'Receive your first EPIC',
      'Open Receive, copy the Epicbox address and give it to the sender. The payment arrives by itself.',
      [
        const HelpBlock.p('The Epicbox address is a long code that ends in **@** and the name of the Epicbox server, for example **…@epicbox.epiccash.com**. It is safe to share: people need it to pay, and nobody can take anything with it.'),
        const HelpBlock.ol(['Open [[Receive]].', 'Copy the address (or show its QR code) and send it to the person who pays.', 'The payment shows up in Activity on its own. Nothing to press.']),
        if (phone)
          const HelpBlock.p('Receiving works while the app is open and the node is synced. A payment sent while the app is closed waits on the Epicbox server for about a week and arrives at the next unlock.')
        else
          const HelpBlock.p('Receiving starts by itself after unlock, once the node is synced. If the wallet is closed when someone pays, Epicbox holds the payment, and the wallet collects it at the next unlock.'),
        HelpBlock.p('A new payment first waits for the sender\'s wallet to finish it, then shows as confirming. After $confirmations confirmations, about $confirmations minutes, it can be spent.'),
      ],
      id: HelpId.receive,
    ),
    HelpTopic(
      'start',
      'Send to someone',
      'Open Send, paste their Epicbox address, enter the amount, check the fee and send.',
      [
        const HelpBlock.ol(['Open [[Send]] and paste the recipient\'s address, or pick a contact.', 'Enter the amount. The fee is shown before sending.', 'Press **Review send**, check, then **Send … EPIC**.']),
        const HelpBlock.p('Now the recipient\'s wallet has to answer (see "Why does a transaction need both sides?"). Over Epicbox they do not have to be online right now: the payment waits until their wallet opens. Meanwhile the outputs it uses are locked, so they cannot be spent twice.'),
        HelpBlock.p('When their answer comes back, the wallet finishes the transaction and posts it to the network by itself. It is final after $confirmations confirmations.'),
        HelpBlock.p('**No answer?** After a few minutes the status says "Waiting for the recipient". Ask them to open their wallet. If the answer never comes, cancel the send in $cancelPlace to unlock the outputs. A send nobody answers cancels by itself after about a day.'),
        if (phone)
          const HelpBlock.p('Sending needs a synced node. An Epicbox address also needs the Epicbox server to answer; a Link address (http or .onion) needs the recipient\'s wallet open and reachable at that moment.')
        else
          const HelpBlock.p('Sending needs a synced node. An Epicbox address also needs Epicbox receiving to be on; a Link address (http or .onion) needs the recipient\'s wallet open and reachable at that moment.'),
      ],
      id: HelpId.send,
    ),
    HelpTopic(
      'start',
      'Send with a file',
      'The manual way: save a transaction file, pass it to the recipient, then open the response file they send back.',
      [
        const HelpBlock.p('File Transfer does the same handshake as Epicbox, but the messages travel by hand, for example by email, chat or a USB stick. They work without Epicbox and without both wallets being online at the same time.'),
        if (phone)
          const HelpBlock.ol(['**Sender:** on Send, choose **Direct · File Transfer**, enter the amount and share the file (it ends in .tx). The outputs are locked from now on.', '**Recipient:** opens the file under [[Receive › Direct · File]]. Their wallet signs it and shares a response file (it ends in .response). They send that file back.', '**Sender:** opens the response file under [[Receive › Direct · File]]. The wallet finishes the transaction and posts it.'])
        else
          const HelpBlock.ol(['**Sender:** on Send, choose **Direct · File Transfer**, enter the amount and save the file (it ends in .tx). The outputs are locked from now on.', '**Recipient:** opens the file under [[Receive › Transaction files › Sign a transaction file]]. Their wallet signs it and saves a response file (it ends in .response). They send that file back.', '**Sender:** opens the response file under [[Receive › Transaction files › Finalize a response file]]. The wallet finishes the transaction and posts it.']),
        const HelpBlock.p('Other Epic Cash wallets have their own names for these steps. If the response file never comes, cancel the send in Activity to unlock the outputs.'),
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
          HelpBlock.ol(['**Sender:** on Send, choose **Direct · QR Payment**, enter the amount and tap **Show QR**. The code stays hidden until you show it, counts 3, 2, 1, and hides itself after 40 seconds.', '**Receiver:** on [[Receive › Direct · QR]], tap **Scan payment QR**, accept the payment, then show the reply the same way.', '**Sender:** taps **Scan their reply**. The wallet posts the payment and the tracker follows it.']),
          HelpBlock.p('Keep the code in the frame until every part is read: the ring and the count show how far it got. A code that is not a payment is said so and ignored. Screenshots are blocked on the code screen.'),
        ],
        id: HelpId.qr,
      ),
    HelpTopic(
      'start',
      'Payment methods and send defaults',
      'Every method is a switch; Epicbox is on by default. Send starts on the method you choose.',
      [
        const HelpBlock.p('The Transactions page in [[Settings › Transactions]] holds three things.'),
        HelpBlock.ul([
          '**Payment methods.** One switch each. **Epicbox** is on by default; off, the wallet connects to no relay, so no Epicbox payments, invoices or notifications, and Receive shows no Epicbox address (payments sent to it wait at the relay). **Link · HTTP** (to web addresses), **Link · Tor** (to .onion addresses${phone ? ', and a Tor address of this phone to be paid at' : ''}) and ${phone ? '**Direct · QR Payment** and ' : ''}**Direct · File Transfer** need no relay. A method that is off does not appear on Send and Receive.',
          '**Send starts on.** The method the Send screen opens with. You can still pick another on Send.',
          '**Send defaults.** Which outputs a send spends, Smallest or All, and whether its change is split. They show only while **Send options** is on in Advanced.',
        ]),
      ],
      id: HelpId.methods,
    ),
    if (phone)
      const HelpTopic(
        'start',
        'What an address looks like',
        'An Epicbox address starts with es and ends in @ and a server name. A Link address is a web address or ends in .onion.',
        [
          HelpBlock.ul([
            '**Epicbox**: about 52 characters starting with **es**, then **@** and the server, for example **esXXXX…XXXX@epicbox.epiccash.com**. The default; the recipient can be offline.',
            '**Link · HTTP** and **Link · Tor**: the recipient\'s own wallet, open right now. A web address such as **http://host:3415** goes by Link · HTTP; a Tor address of 56 characters ending in **.onion** goes by Link · Tor, over Tor.',
          ]),
          HelpBlock.p('Send picks the method from the address pasted into the To field. When reading an address out, compare the first six and the last six characters.'),
        ],
        id: HelpId.addresses,
      ),
    const HelpTopic(
      'how',
      'Why does a transaction need both sides?',
      'In Epic Cash the receiver wallet helps build every transaction, so both wallets must take part.',
      [
        HelpBlock.p('Epic Cash uses Mimblewimble. Instead of writing an address and an amount on the blockchain, the two wallets build each transaction together, like a handshake:'),
        HelpBlock.ol(['The sender\'s wallet starts it and locks the outputs being sent.', 'The receiver\'s wallet adds its part and signs.', 'The sender\'s wallet signs too, finishes the transaction and posts it to the network.']),
        HelpBlock.p('So something has to carry the messages between the two wallets. **Epicbox** does it: it holds the message while the other wallet is offline, so both need not be online at the same moment. **Link · HTTP** and **Link · Tor** go straight to the other wallet while it is open. **Direct · File Transfer** (a transaction file) is the manual way.'),
      ],
      handshake: true,
      id: HelpId.handshake,
    ),
    HelpTopic(
      'how',
      'Confirmations',
      'A transaction is final after $confirmations confirmations, usually about $confirmations minutes.',
      [
        const HelpBlock.p('When the network accepts a transaction, a miner puts it in a block. A new block comes about every minute. The block that holds the transaction is the first confirmation, and every block after it adds one more and makes the transaction harder to undo.'),
        HelpBlock.p('This wallet treats a transaction as final after **$confirmations confirmations**. Until then it shows as **Confirming**, and received outputs cannot be spent yet. The number is fixed.'),
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
        const HelpBlock.p('What is not hidden: the node and the Epicbox server see the wallet\'s IP address, and a public node can see which outputs the wallet asks about. Tor or a VPN hides the IP address.'),
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
        if (phone)
          const HelpBlock.p('The default is set under [[Settings › Transactions]], with Send options switched on in Advanced.')
        else
          const HelpBlock.p('The default is set under [[Outputs › Manage outputs]]; Send can change it for one send under **Send options**.'),
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
        HelpBlock.p('It shows as **Network fee** before sending. **All**, next to the amount, fills in the whole spendable balance minus the exact fee, so no change is left.'),
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
    HelpTopic(
      'safety',
      'Backups and restoring',
      'The recovery phrase is the backup. To restore a wallet, enter its words in Restore from a phrase.',
      [
        const HelpBlock.p('The recovery phrase brings back everything that is on the blockchain, which is the balance.'),
        HelpBlock.p('**To restore** on a new ${phone ? 'phone' : 'computer'} or after a loss: open $restorePlace, enter the words and choose ${phone ? 'a PIN' : 'a password'}. When the wallet opens, it scans the blockchain for its outputs. The balance appears after that first scan; the payments it finds are labelled **Restored**.'),
        HelpBlock.p('**What a restore cannot bring back:** what was never on the blockchain, such as who paid what, notes and labels, contacts, invoices, settings and wallet names. A wallet data file keeps them: $historyBackupPlace.${phone ? ' Keep the file outside the phone, for example in email or cloud storage.' : ''}'),
        const HelpBlock.p('**The wallet data file is not the recovery phrase.** It holds no words and cannot restore the wallet on its own. To restore: enter the recovery phrase first, then import the file; the wallet offers that right after the restore.'),
        HelpBlock.p('**Balance looks wrong?** Run $recheckPlace. It reads the whole blockchain again for this wallet\'s outputs.'),
        if (!phone)
          const HelpBlock.p('**The wallet\'s files** are in [[Settings › This wallet › Wallet folder]]. Keep the recovery phrase even with a copy of them: it works when the files are lost.'),
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
        const HelpBlock.p('The wallet needs a node to read the blockchain (the balance and confirmations) and to post transactions to the network.'),
        if (phone)
          const HelpBlock.p('A **public node** is one of the nodes others run. It works right away. Whoever runs it can see the wallet\'s IP address and which outputs it asks about; Tor hides the address.')
        else
          const HelpBlock.ul(['**Public node** (the default): one of the public nodes others run. It works right away. Whoever runs it can see the wallet\'s IP address and which outputs it asks about.', '**Local node**: runs on this computer. It first downloads the whole blockchain, which takes a while and needs disk space, and then it is yours. While it syncs, the wallet uses a public node.']),
        if (phone)
          HelpBlock.p('Change it by tapping the Node row on the Wallet tab, or under $nodePlace: the nodes are listed with their state. Tap one to switch to it at once, or type an address to filter the list or add a node. Sending needs a synced node; **Behind** or **Not responding** means pick another.')
        else
          HelpBlock.p('Change it in $nodePlace: the nodes are listed with their state. Click one to switch to it at once, or type an address to filter the list or add a node. Sending needs a synced node; if the node falls behind, the wallet offers another one.'),
      ],
      id: HelpId.node,
    ),
    HelpTopic(
      'network',
      'Epicbox',
      'Epicbox delivers transactions between wallets and holds them while the other wallet is offline.',
      [
        const HelpBlock.p('Both wallets take part in every transaction, so their messages need a meeting point. An Epicbox server is that meeting point: it holds a payment sent to this wallet until the wallet comes online, and carries the wallet\'s answer back. The messages are encrypted, and Epicbox cannot spend the coins.'),
        const HelpBlock.p('The Epicbox address is the wallet\'s public key, then **@** and the name of its Epicbox server.'),
        if (phone)
          HelpBlock.p('The server is set by tapping the Epicbox row on the Wallet tab, or under $epicboxPlace: the servers are listed with their state. Tap one and confirm, or type an address to filter the list or add a server. Choosing another server changes the part after @, so give the new address to the people who pay. Other Epic Cash wallets use Epicbox too; two wallets can use different servers.')
        else
          HelpBlock.p('The server is set under $epicboxPlace: the servers are listed with their state. Click one and confirm, or type an address to filter the list or add a server. Choosing another server changes the part after @, so give the new address to the people who pay. Other Epic Cash wallets use Epicbox too; two wallets can use different servers.'),
      ],
      id: HelpId.epicbox,
    ),
    if (tor && phone)
      HelpTopic(
        'network',
        'Tor',
        'One switch routes the wallet\'s connections through Tor and gives it a .onion address. Slower, more private. Off by default.',
        [
          HelpBlock.p('Tor hides the wallet\'s IP address from the servers it talks to. With the switch on, under $torPlace, the Epicbox connection goes through Tor, a send to a .onion address goes through Tor, and the wallet has a Tor address of its own (it ends in .onion) that other wallets can pay straight to.'),
          const HelpBlock.ul([
            'Nothing the wallet uses changes: the same node, the same Epicbox server, the same address.',
            'A Link send to an onion address goes through Tor. Send marks each send with how it goes.',
            'Push notifications are off while Tor is on.',
            'Slower than Epicbox without Tor. Tor is blocked in some countries; there it does not connect.',
            'Receiving at the .onion address works while the app is open; Epicbox keeps working beside it.',
            'With Tor only in Advanced the switch stays on and cannot be turned off.',
          ]),
          const HelpBlock.p('**Starting…** means Tor is connecting; the covered connections wait and never fall back. **Not connected** means it failed: Retry, or turn Tor off. Some wallets show a Tor address without .onion; both are the same address.'),
        ],
        id: HelpId.tor,
      )
    else if (tor)
      const HelpTopic(
        'network',
        'Tor',
        'Slower and more private: one switch routes the wallet\'s connections through Tor, with no ports to open. Off by default.',
        [
          HelpBlock.p('With Tor on, the connection to the Epicbox server goes through Tor, and the wallet has a Tor address (it ends in .onion) that other wallets can pay straight to, from anywhere, with nothing to forward on the router. Turning Tor on does not change the addresses you share.'),
          HelpBlock.ul([
            'Turn it on under [[Settings › Privacy › Tor]]. The Tor row in the sidebar shows its state.',
            'While Tor starts or is not connected, what goes over Tor waits; nothing goes around it. Retry, or turn Tor off.',
            'Link sends to an http(s) address do not go over Tor; Send says so.',
            'Link · HTTP receiving is off while Tor is on: payments straight from another wallet arrive at the Link · Tor address.',
            'Tor is blocked or not allowed in some countries; there it does not connect.',
            'With Tor only in Advanced the switch stays on and cannot be turned off.',
          ]),
          HelpBlock.p('Some wallets show the address without .onion; both are the same address.'),
        ],
        id: HelpId.tor,
      ),
    HelpTopic(
      'network',
      'Network modes',
      'Standard connects directly. Tor only never does. Offline uses nothing beyond $device and the local network.',
      [
        const HelpBlock.p('How the wallet reaches the network is one choice on the **Advanced** page in Settings, under Network.'),
        HelpBlock.ul([
          '**Standard**: connects directly. Tor is the switch under $torPlace.',
          '**Tor only**: Tor is always on and its switch is locked. Nothing goes over the open internet. While Tor starts or has failed, the wallet says **Waiting for Tor** and whatever needs the network waits, with the reason on the disabled action. ${phone ? 'Notifications are off, because signing up for them would reveal this phone.' : 'HTTP receiving is off, because a plain address would reveal this computer.'}',
          '**Offline**: no Epicbox, no Link beyond local addresses, ${phone ? 'no notifications' : 'no Tor'}, no status checks. The balance and history stay as last seen. ${phone ? '**Direct · QR Payment** and **Direct · File Transfer**' : '**Direct · File Transfer**'} still work: they use the node in use to read the chain and post, a public one too, and the screen says so. For the most privacy, use a node on ${phone ? 'the local network' : 'this computer or the local network'}: then the balance refreshes${phone ? '' : ', Link · HTTP receives over the local network with HTTP receiving set to **From the internet**,'} and Recheck balance runs as well.',
        ]),
        const HelpBlock.p('In Offline, give the node by its IP address, for example **10.100.10.20:3413**. Names are not looked up.'),
        if (!phone) const HelpBlock.p('The built-in node\'s own peers are the node\'s setting, not the mode\'s.'),
        HelpBlock.p('${phone ? 'Home' : 'The sidebar'} says when the wallet is offline or waiting for Tor. Setting the mode back to **Standard** brings everything back.'),
      ],
      id: HelpId.modes,
    ),
    HelpTopic(
      'network',
      'Advanced',
      'Off to begin with. Each switch adds one more part of the wallet, in the place it belongs.',
      [
        const HelpBlock.p('**Advanced** is a page in Settings for the parts most people never need. Everything on it is off to begin with, so the wallet stays simple. A switch adds its part where it belongs, and **Hide everything again** switches them all off.'),
        HelpBlock.ul([
          '**Outputs**: the Outputs page, with the coins the balance is made of and what you can do with them.',
          '**Technical details**: slate ID, kernel, commitments and block height on a ${phone ? 'payment\'s details' : 'transaction'}. Without it, the **More** link on a transaction shows them once.',
          if (phone)
            '**Send options**: Strategy and Split change, in [[Settings › Transactions]]: which outputs a send spends, and whether its change is split.'
          else
            '**Send options**: a fold on Send where one send chooses Smallest or All, and whether to split the change.',
          '**Server details**: hosts, latency, version and block height in the node and Epicbox lists and on the status card.',
          if (phone)
            '**Recheck from a height**: lets Recheck balance start from a block height or a date instead of the first block. Restore always offers the choice.'
          else
            '**Recheck from a height**: lets Recheck balance also drop unconfirmed transactions. Restore offers a start block to everyone.',
          if (!phone) '**Built-in node**: lets this computer run its own node: the This computer option under Node, and Start node on Overview.',
          if (!phone) '**Logs**: the Logs group in Help, to open the log folder or clear the logs. Report a problem attaches the log either way.',
        ]),
        HelpBlock.p('**Node failover** is on by default. When your node has not answered for 30 seconds, the wallet moves to the next working node in your list, for this session only: your own node stays saved, and the wallet is back on it at the next start, or as soon as you pick a node yourself. It never moves in Offline mode${phone ? '' : ' or away from a node on this computer'}, and with Tor only it moves only to a node reachable over Tor.'),
        const HelpBlock.p('**Experimental** holds **Pairing** and **Invoices**, both off to begin with. Pairing adds Pair and paired contacts; Invoices adds requests and invoices between paired contacts and needs Pairing. Off, they are hidden and nothing is checked for them; pairings already made stay saved and come back when the switch is on again.'),
        if (phone) const HelpBlock.p('**Notifications** (experimental) is the last switch on the page. It tells you when a payment or an invoice arrives while the app is closed, and it is off while Tor is on.'),
        const HelpBlock.p('The same page sets the network mode: see "Network modes".'),
      ],
      id: HelpId.advanced,
    ),
    HelpTopic(
      'trouble',
      'Troubleshooting',
      'Most problems are a node still syncing, a recipient who has not answered yet, or a busy port.',
      [
        if (phone)
          const HelpBlock.p('**"Node not synced": cannot send.** Sending opens when the node has caught up. Wait a little, or tap the Node row on the Wallet tab and choose another node.')
        else
          const HelpBlock.p('**"Node not synced": cannot send.** Sending opens when the node has caught up. Wait a little, or choose another node under [[Settings › Node]].'),
        if (phone)
          const HelpBlock.p('**"Epicbox not answering".** The wallet cannot reach its Epicbox server. Wait a moment; if it stays like this, check the connection or tap the Epicbox row on the Wallet tab and pick another server. Meanwhile Direct · File Transfer works.')
        else
          const HelpBlock.p('**"Epicbox not answering".** The wallet cannot reach its Epicbox server. Wait a moment; if it stays like this, check the connection or pick another server under [[Settings › Transactions]]. Meanwhile Direct · File Transfer works.'),
        const HelpBlock.p('**A send says "Waiting for the recipient".** Their wallet has not answered yet. Ask them to open it. If they never will, cancel the send in Activity to unlock the outputs.'),
        if (phone)
          const HelpBlock.p('**A payment has not arrived.** Check on the Wallet tab that the node is synced and Epicbox is online. After a change of Epicbox server, the sender needs the new address. The sender\'s wallet also has to finish the transaction; then a few minutes for the confirmations.')
        else
          const HelpBlock.p('**A payment has not arrived.** Check on Receive that receiving is on and the node is synced. After a change of Epicbox server, the sender needs the new address. The sender\'s wallet also has to finish the transaction; then a few minutes for the confirmations.'),
        if (phone)
          const HelpBlock.p('**Tor says "Not connected".** Tor could not reach its network. Press Retry under [[Settings › Privacy & network]], or turn Tor off; nothing goes out meanwhile.'),
        if (!phone) ...const [
          HelpBlock.p('**"Port 3415 is used by another program".** Another program, often another Epic wallet, uses the port for Link · HTTP payments. Close it, then press Try again on Receive. Epicbox, Link · Tor and Direct · File Transfer keep working meanwhile.'),
          HelpBlock.p('**"Another Epic program is using this folder".** Another Epic wallet or node has the same files open. Close it and try again.'),
        ],
        if (phone)
          const HelpBlock.p('**Forgotten PIN.** Delete the wallet on the unlock screen and restore it from its recovery phrase with a new PIN. Without the phrase the EPIC cannot be recovered.')
        else
          const HelpBlock.p('**"Wrong password".** Check Caps Lock and the keyboard layout. A forgotten password: restore the wallet from its recovery phrase and choose a new one.'),
        const HelpBlock.p('**An action is greyed out and says "Offline mode" or "Waiting for Tor".** Offline or Tor only is on in Advanced. Set the mode back to Standard there, or wait for Tor to connect.'),
        HelpBlock.p('**The balance looks wrong.** Run $recheckPlace.'),
      ],
      id: HelpId.trouble,
    ),
    HelpTopic(
      'trouble',
      'Cancelling a payment',
      'When Cancel is certain, when it is not, and what happens to the coins.',
      [
        const HelpBlock.h('Sending', anchor: HelpAnchor.sending),
        const HelpBlock.p('A payment you send waits for the other wallet to answer. While it waits, Cancel is certain: nothing can reach the network without your wallet, and the coins are yours again at once. The other wallet may still show the payment as waiting, but it cannot finish it.'),
        const HelpBlock.p('Once the answer is in, your wallet finishes the payment and posts it to the network in one step. A posted payment cannot be cancelled, undone or refunded; only the recipient can pay it back. If the network refused it, the wallet offers to post it again or to cancel. That cancel asks the network first and goes ahead only when the network does not have the payment.'),
        const HelpBlock.p('A payment that stays unanswered cancels by itself after about a day (1,440 blocks), and the coins are free again. This holds for Epicbox, Link and Direct payments alike: Cancel is certain until the other side\'s answer is in your wallet.'),
        HelpBlock.p('**A send looks stuck.** Usually the other wallet is offline. Wait, or cancel it in $cancelPlace and send again; a cancelled payment cannot go through later.'),
        const HelpBlock.h('Receiving', anchor: HelpAnchor.receiving),
        const HelpBlock.p('When a payment arrives, your wallet answers at once, and nothing of yours is locked. From then on the sender\'s wallet finishes and posts it, usually within minutes, so Cancel stays out of the way for 15 minutes, and longer while the sender reports it posted.'),
        const HelpBlock.p('After that, Cancel is a tidy-up for a payment the sender never posted. It is not certain: the wallet asks the network first and refuses when the payment is already there. A cancelled payment stays watched. If the sender posts it later, it arrives anyway and shows as received.'),
        const HelpBlock.h('Requests (experimental)', anchor: HelpAnchor.requests),
        const HelpBlock.p('A request you sent holds no coins until it is paid. Withdraw it any time before then: the payer can no longer pay it, and nothing moves. A request nobody pays expires after 24 hours. A request shown as a QR code can be paid once; a second scan is refused, so nothing is paid twice.'),
        if (phone)
          const HelpBlock.p('A request you paid is the other way round: the other side holds your signed payment and finishes it. Cancel comes once its time runs out, about a day after you paid, or sooner when the other side withdraws it. Cancelling frees the coins here, but the other side could still post the payment until these coins are spent again.')
        else
          const HelpBlock.p('A request you paid is the other way round: the other side holds your signed payment and finishes it. Cancel comes once its time runs out, about a day after you paid, or sooner when the other side withdraws it. Cancelling frees the coins here, but the other side could still post the payment until these coins are spent again. Sending them to yourself, offered with the cancel, makes it final.'),
      ],
      id: HelpId.cancel,
    ),
    if (!phone)
      const HelpTopic(
        'maintenance',
        'Clean up old wallet folders',
        'Remove from list keeps the wallet\'s folder on disk. Delete it by hand, with the recovery phrase written down or the wallet no longer needed.',
        [
          HelpBlock.p('**Remove from list** in [[Settings › All wallets]] takes a wallet off the list but leaves its folder on disk, and the page offers it again under **Removed from list**. To be rid of the folder, delete it by hand.'),
          HelpBlock.p('**Deleting a wallet folder without its recovery phrase loses the EPIC in it.** Check the words first, or make sure the wallet is empty and no longer needed.'),
          HelpBlock.ol([
            'Open the data folder: the **Open folder** button next to [[Settings › This wallet › App files]], or **.epic_cash_desktop** in your home folder (on Windows **C:\\Users\\<name>\\.epic_cash_desktop**).',
            'Open **wallets**. Each added wallet has a folder of its own, named by a long id; the first wallet\'s folder is named **mainnet**.',
            'To tell them apart, open an id folder, then its **mainnet** folder, and read **WALLET.txt**: it gives the wallet\'s name.',
            'Make sure you have that wallet\'s recovery phrase written down, or that it holds no EPIC you want to keep.',
            'Close Epic Cash Desktop.',
            'Delete that one id folder. Leave **mainnet**, **wallets.json** and everything else as it is.',
          ]),
          HelpBlock.p('**Folders of earlier versions.** Versions before 26.10.16 kept their data in **~/.local/share/com.blacktyger.epicwallet** on Linux and in **%APPDATA%\\com.blacktyger\\EpicWallet** on Windows. Once every wallet from there has been restored in this app and shows its balance, that old folder can go too.'),
        ],
        id: HelpId.cleanup,
      ),
  ];
}

/// Help › Pairing's five topics (SPEC 2.11). Localized, unlike the rest, as they were written
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
    HelpTopic(s, l.helpPairWhyTitle, l.helpPairWhyShort, [
      HelpBlock.p(t(l.helpPairWhyP1)),
      HelpBlock.p(t(l.helpPairWhyP2)),
      HelpBlock.p(t(l.helpPairWhyP3)),
      HelpBlock.p(t(l.helpPairWhyP4)),
    ], id: HelpId.checkWords),
    HelpTopic(s, l.helpPairWordsTitle, l.helpPairWordsShort, [
      HelpBlock.p(t(l.helpPairWordsP1)),
      HelpBlock.p(t(l.helpPairWordsP2)),
      HelpBlock.p(t(l.helpPairWordsP3)),
    ], id: HelpId.pairingWords),
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
    'Settings › Invoices' => link([l.settingsTitle, l.settingsSectionWallet, l.settingsInvoices], 'Settings › Wallet › Invoices'),
    _ => whole,
  };
}
