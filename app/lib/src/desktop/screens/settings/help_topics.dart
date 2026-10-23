import '../../data/features.dart';

/// One block of a topic's body. Inline, `**bold**` marks a term and `[[Settings › Node]]` a
/// place in the app.
class HelpBlock {
  const HelpBlock.p(String text) : kind = HelpBlockKind.p, items = const [], _text = text;
  const HelpBlock.ol(this.items) : kind = HelpBlockKind.ol, _text = null;
  const HelpBlock.ul(this.items) : kind = HelpBlockKind.ul, _text = null;

  final HelpBlockKind kind;

  /// The list items; empty for a paragraph.
  final List<String> items;
  final String? _text;

  /// The paragraph's text, or the list items one per line.
  String get text => _text ?? items.join('\n');
}

enum HelpBlockKind { p, ol, ul }

/// [text] in pieces: plain, a term (`**…**`) or a place (`[[…]]`), markers removed.
List<({String text, bool term, bool place})> helpInline(String text) {
  final out = <({String text, bool term, bool place})>[];
  var pos = 0;
  for (final m in RegExp(r'\*\*(.+?)\*\*|\[\[(.+?)\]\]').allMatches(text)) {
    if (m.start > pos) out.add((text: text.substring(pos, m.start), term: false, place: false));
    out.add((text: m.group(1) ?? m.group(2)!, term: m.group(1) != null, place: m.group(2) != null));
    pos = m.end;
  }
  if (pos < text.length) out.add((text: text.substring(pos), term: false, place: false));
  return out;
}

/// Help topics (English): the GUI 6.1.6 topic set, as the settings design words them.
class HelpTopic {
  const HelpTopic(this.section, this.title, this.short, this.body, {this.handshake = false, this.invoiceFlow = false});

  final String section;
  final String title;
  final String short;
  final List<HelpBlock> body;

  /// The handshake stepper goes under the body.
  final bool handshake;

  /// The invoice flow diagram goes under the body.
  final bool invoiceFlow;

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
];

/// The topics, with [confirmations] as the open wallet's balance counts them
/// (`deskMinConfirmations`).
List<HelpTopic> helpTopicsFor(int confirmations) => <HelpTopic>[
  HelpTopic(
    'start',
    'Receive your first EPIC',
    'Open Receive, copy the Epicbox address and give it to the sender. The payment arrives by itself.',
    [
      HelpBlock.p('The Epicbox address is a long code that ends in **@** and the name of the Epicbox server, for example **…@epicbox.epiccash.com**. It is safe to share: people need it to pay, and nobody can take anything with it.'),
      HelpBlock.ol(['Open [[Receive]].', 'Copy the address (or show its QR code) and send it to the person who pays.', 'The payment shows up in Activity on its own. Nothing to press.']),
      HelpBlock.p('Receiving starts by itself after unlock, once the node is synced. If the wallet is closed when someone pays, Epicbox holds the payment, and the wallet collects it at the next unlock.'),
      HelpBlock.p('A new payment first waits for the sender\'s wallet to finish it, then shows as confirming. After $confirmations confirmations, about $confirmations minutes, it can be spent.'),
    ],
  ),
  HelpTopic(
    'start',
    'Send to someone',
    'Open Send, paste their Epicbox address, enter the amount, check the fee and send.',
    [
      HelpBlock.ol(['Open [[Send]] and paste the recipient\'s address, or pick a contact.', 'Enter the amount. The fee is shown before sending.', 'Press **Review send**, check, then **Send … EPIC**.']),
      HelpBlock.p('Now the recipient\'s wallet has to answer (see "Why does a transaction need both sides?"). Over Epicbox they do not have to be online right now: the payment waits until their wallet opens. Meanwhile the outputs it uses are locked, so they cannot be spent twice.'),
      HelpBlock.p('When their answer comes back, the wallet finishes the transaction and posts it to the network by itself. It is final after $confirmations confirmations.'),
      HelpBlock.p('**No answer?** After a few minutes the status says "Waiting for the recipient". Ask them to open their wallet. If the answer never comes, cancel the send in [[Activity › the transaction › Cancel]] to unlock the outputs. A send is never cancelled by itself.'),
      HelpBlock.p('Sending needs a synced node. An Epicbox address also needs Epicbox receiving to be on; HTTP and Tor addresses need the recipient\'s wallet open and reachable at that moment.'),
    ],
  ),
  HelpTopic(
    'start',
    'Send with a file',
    'The manual way: save a transaction file, pass it to the recipient, then open the response file they send back.',
    [
      HelpBlock.p('Files do the same handshake as Epicbox, but the messages travel by hand, for example by email, chat or a USB stick. They work without Epicbox and without both wallets being online at the same time.'),
      HelpBlock.ol(['**Sender:** on Send, choose **File**, enter the amount and save the file (it ends in .tx). The outputs are locked from now on.', '**Recipient:** opens the file under [[Receive › Transaction files › Sign a transaction file]]. Their wallet signs it and saves a response file (its name starts with finalize_). They send that file back.', '**Sender:** opens the response file under [[Receive › Transaction files › Finalize a response file]]. The wallet finishes the transaction and posts it.']),
      HelpBlock.p('Other Epic Cash wallets have their own names for these steps. If the response file never comes, cancel the send in Activity to unlock the outputs.'),
    ],
  ),
  HelpTopic(
    'how',
    'Why does a transaction need both sides?',
    'In Epic Cash the receiver wallet helps build every transaction, so both wallets must take part.',
    [
      HelpBlock.p('Epic Cash uses Mimblewimble. Instead of writing an address and an amount on the blockchain, the two wallets build each transaction together, like a handshake:'),
      HelpBlock.ol(['The sender\'s wallet starts it and locks the outputs being sent.', 'The receiver\'s wallet adds its part and signs.', 'The sender\'s wallet signs too, finishes the transaction and posts it to the network.']),
      HelpBlock.p('So something has to carry the messages between the two wallets. **Epicbox** does it: it holds the message while the other wallet is offline, so both need not be online at the same moment. **HTTP** and **Tor** go straight to the other wallet while it is open. A **transaction file** is the manual way.'),
    ],
    handshake: true,
  ),
  HelpTopic(
    'how',
    'Confirmations',
    'A transaction is final after $confirmations confirmations, usually about $confirmations minutes.',
    [
      HelpBlock.p('When the network accepts a transaction, a miner puts it in a block. A new block comes about every minute. The block that holds the transaction is the first confirmation, and every block after it adds one more and makes the transaction harder to undo.'),
      HelpBlock.p('This wallet treats a transaction as final after **$confirmations confirmations**. Until then it shows as **Confirming**, and received outputs cannot be spent yet. The number is fixed.'),
      HelpBlock.p('Taking longer than usual? The wallet sees new blocks only through its node: check that the node is synced.'),
    ],
  ),
  HelpTopic(
    'how',
    'What the blockchain shows',
    'No addresses and no amounts: only coin records the network can check without seeing who or how much.',
    [
      HelpBlock.p('On many blockchains anyone can look up an address and see its balance and history. Epic Cash is different:'),
      HelpBlock.ul(['**No addresses on the blockchain.** The Epicbox address only tells Epicbox where to deliver messages. It is never written on the blockchain.', '**No amounts on the blockchain.** Amounts are hidden with cryptography, and the network can still check that no coins were created out of nothing.', '**Notes stay off the blockchain.** A message added to a send goes only to the other wallet. Contacts and wallet names stay on this computer.']),
      HelpBlock.p('What is not hidden: the node and the Epicbox server see the wallet\'s IP address, and a public node can see which outputs the wallet asks about. Tor or a VPN hides the IP address.'),
    ],
  ),
  HelpTopic(
    'how',
    'Locked amounts and change',
    'The balance is made of separate outputs. A send spends whole outputs and returns the rest as change.',
    [
      HelpBlock.p('The balance is a set of outputs. To send 3 EPIC from a 5 EPIC output, the wallet spends the whole output: 3 EPIC go to the recipient, a small fee goes to the miners, and the rest comes back as a new output, the **change**.'),
      HelpBlock.p('That is why part of the balance can be unavailable for a few minutes after a send:'),
      HelpBlock.ul(['**Locked**: outputs in a send that is not finished yet. They are unlocked if the send is cancelled.', '**Awaiting finalization**: a transaction still waiting for the other wallet.', '**Confirming**: outputs in a block with fewer than $confirmations confirmations, including the change.']),
      HelpBlock.p('The outputs are listed under [[Outputs]].'),
    ],
  ),
  HelpTopic(
    'how',
    'Smallest or All: which outputs a send spends',
    'Smallest (the default) uses the fewest small outputs and leaves the rest spendable. All uses every output.',
    [
      HelpBlock.p('**Smallest** sorts the spendable outputs by value and takes the smallest ones until the amount and fee are covered. Only those are locked while the send confirms; the rest can be sent right away.'),
      HelpBlock.p('**All** spends every spendable output and returns one change output. Everything is locked for $confirmations blocks, the wallet ends up with fewer, larger outputs, and the fee is a little higher because each input costs. Sending the whole balance always uses All.'),
      HelpBlock.p('The default is set under [[Outputs]]; Send can change it for one send under **Advanced**.'),
    ],
  ),
  HelpTopic(
    'how',
    'Split and consolidate',
    'Split makes more outputs so sends can follow each other; Consolidate merges them into one.',
    [
      HelpBlock.p('Both are normal network transactions from this wallet to itself, confirmed after $confirmations blocks like any send, and both lock every spendable output until then.'),
      HelpBlock.ul(['**Split** takes the spendable balance and makes 2 to 10 outputs of nearly equal value.', '**Consolidate** takes every spendable output and makes one.', '**Split change** (on by default) does the same inside an ordinary send when few outputs would be left, for 0.004 EPIC per extra output.']),
      HelpBlock.p('Activity shows each as two entries, a send and a receive, both with this wallet. Both are under [[Outputs]].'),
    ],
  ),
  HelpTopic(
    'how',
    'Fees',
    'Every transaction pays a small network fee, shown before sending. It goes to the miners.',
    [
      HelpBlock.p('The fee depends on how many outputs the transaction spends and creates, not on the amount. It is usually a small fraction of one EPIC.'),
      HelpBlock.p('It shows as **Network fee** before sending. **All**, next to the amount, fills in the whole spendable balance minus the exact fee, so no change is left.'),
    ],
  ),
  HelpTopic(
    'safety',
    'Your recovery phrase',
    'These words are the only way to get the EPIC back. Write them on paper and never share them.',
    [
      HelpBlock.p('The recovery phrase (24 words for a new wallet) is the key to the money. With it the wallet can be restored on any computer, and anyone else who has it can take the EPIC.'),
      HelpBlock.ul(['Write the words on paper, in this order, and keep the paper somewhere safe and offline.', 'Never keep them as a photo, screenshot or file. Never type them into a website or a chat.', 'Nobody from Epic Cash or this wallet will ever ask for them.']),
      HelpBlock.p('To see the words again, open [[Settings › Recovery phrase]] and enter the wallet password. Better not to copy them: if copied, the wallet clears the clipboard after 60 seconds, and when the wallet locks or closes.'),
    ],
  ),
  HelpTopic(
    'safety',
    'Backups and restoring',
    'The recovery phrase is the backup. To restore a wallet, enter its words in Restore from a phrase.',
    [
      HelpBlock.p('The recovery phrase brings back everything that is on the blockchain, which is the balance.'),
      HelpBlock.p('**To restore** on a new computer or after a loss: open [[Restore from a recovery phrase]] (on the first screen, Unlock › Add a wallet, or Settings › All wallets), enter the words and choose a password. When the wallet opens, it scans the blockchain for its outputs. The balance appears after that first scan; the payments it finds are labelled **Restored**.'),
      HelpBlock.p('**What a restore cannot bring back:** what was never on the blockchain, such as who paid what, transaction messages, contacts and wallet names. A history backup keeps the payment details and contacts: [[Settings › This wallet › Export history backup]].'),
      HelpBlock.p('**Balance looks wrong?** Run [[Settings › Recheck balance]]. It reads the whole blockchain again for this wallet\'s outputs.'),
      HelpBlock.p('**The wallet\'s files** are in [[Settings › This wallet › Wallet folder]]. Keep the recovery phrase even with a copy of them: it works when the files are lost.'),
    ],
  ),
  HelpTopic(
    'network',
    'Nodes: a public one or a local one',
    'A node connects the wallet to the Epic Cash network. A public node is quickest; a local one is your own.',
    [
      HelpBlock.p('The wallet needs a node to read the blockchain (the balance and confirmations) and to post transactions to the network.'),
      HelpBlock.ul(['**Public node** (the default): one of the public nodes others run. It works right away. Whoever runs it can see the wallet\'s IP address and which outputs it asks about.', '**Local node**: runs on this computer. It first downloads the whole blockchain, which takes a while and needs disk space, and then it is yours. While it syncs, the wallet uses a public node.']),
      HelpBlock.p('Change it in [[Settings › Node]]: pick one of the public nodes, which are listed with their state, or type a node\'s address. Sending needs a synced node; if the node falls behind, the wallet offers another one.'),
    ],
  ),
  HelpTopic(
    'network',
    'Epicbox',
    'Epicbox delivers transactions between wallets and holds them while the other wallet is offline.',
    [
      HelpBlock.p('Both wallets take part in every transaction, so their messages need a meeting point. An Epicbox server is that meeting point: it holds a payment sent to this wallet until the wallet comes online, and carries the wallet\'s answer back. The messages are encrypted, and Epicbox cannot spend the coins.'),
      HelpBlock.p('The Epicbox address is the wallet\'s public key, then **@** and the name of its Epicbox server.'),
      HelpBlock.p('The server is set under [[Settings › Receiving › Epicbox receiving]]: pick one of the public servers, listed with their state, or type one. Choosing another server changes the part after @, so give the new address to the people who pay. Other Epic Cash wallets use Epicbox too; two wallets can use different servers.'),
    ],
  ),
  if (DeskFeatures.tor)
  HelpTopic(
    'network',
    'Tor',
    'Tor lets two wallets pay each other privately at a .onion address. Slower, more private, no ports to open. Off by default.',
    [
      HelpBlock.p('With Tor receiving on, the wallet has a Tor address (it ends in .onion) that other wallets can pay straight to, from anywhere, with nothing to forward on the router. Sends to a Tor address go over Tor too.'),
      HelpBlock.ul(['Turn it on under [[Settings › Receiving › Tor receiving]], per wallet.', 'Slower than Epicbox and HTTP; more private: the other wallet does not see this computer\'s IP address.', 'Tor is blocked or not allowed in some countries; there it does not connect.', 'The wallet must be open to receive over Tor; Epicbox keeps working beside it.']),
      HelpBlock.p('Some wallets show the address without .onion; both are the same address.'),
    ],
  ),
  HelpTopic(
    'trouble',
    'Troubleshooting',
    'Most problems are a node still syncing, a recipient who has not answered yet, or a busy port.',
    [
      HelpBlock.p('**"Node not synced": cannot send.** Sending opens when the node has caught up. Wait a little, or choose another node under Settings › Node.'),
      HelpBlock.p('**"Epicbox not answering".** The wallet cannot reach its Epicbox server. Wait a moment; if it stays like this, check the connection or pick another server under Settings › Receiving. Meanwhile a file works.'),
      HelpBlock.p('**A send says "Waiting for the recipient".** Their wallet has not answered yet. Ask them to open it. If they never will, cancel the send in Activity to unlock the outputs.'),
      HelpBlock.p('**A payment has not arrived.** Check on Receive that receiving is on and the node is synced. After a change of Epicbox server, the sender needs the new address. The sender\'s wallet also has to finish the transaction; then a few minutes for the confirmations.'),
      HelpBlock.p('**"Port 3415 is used by another program".** Another program, often another Epic wallet, uses the port for HTTP payments. Close it, then press Try again on Receive. Epicbox, Tor and files keep working meanwhile.'),
      HelpBlock.p('**"Another Epic program is using this folder".** Another Epic wallet or node has the same files open. Close it and try again.'),
      HelpBlock.p('**"Wrong password".** Check Caps Lock and the keyboard layout. A forgotten password: restore the wallet from its recovery phrase and choose a new one.'),
      HelpBlock.p('**The balance looks wrong.** Run Settings › Recheck balance.'),
    ],
  ),
];
