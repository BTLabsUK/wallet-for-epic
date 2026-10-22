import '../../data/features.dart';

/// Help topics (English), ported from the Electron wallet's help/topics_en.js: titles and short
/// answers as there, bodies shortened.
class HelpTopic {
  const HelpTopic(this.section, this.title, this.short, this.body);

  final String section;
  final String title;
  final String short;
  final String body;
}

const helpSections = <(String, String)>[
  ('start', 'Getting started'),
  ('how', 'How Epic Cash works'),
  ('safety', 'Keeping the wallet safe'),
  ('network', 'Nodes and Epicbox'),
  ('trouble', 'When something goes wrong'),
];

/// The topics, with [confirmations] as the open wallet's balance counts them
/// (`deskMinConfirmations`).
List<HelpTopic> helpTopicsFor(int confirmations) => <HelpTopic>[
  HelpTopic(
    'start',
    'Receive your first EPIC',
    'Open Receive, copy the Epic address and give it to the sender. The payment arrives by itself.',
    'The Epic address ends in @ and the Epicbox server name. It is safe to share. The payment shows up in Activity on its own; after $confirmations confirmations, about $confirmations minutes, it can be spent. If the wallet is closed, Epicbox holds the payment until the next unlock.',
  ),
  HelpTopic(
    'start',
    'Send to someone',
    'Open Send, paste their Epic address, enter the amount, check the fee and send.',
    'The recipient wallet has to answer. Over Epicbox it does not have to be online right now; the payment waits. Meanwhile the coins used are locked. A send that never gets an answer is cancelled in Activity, never by itself.',
  ),
  HelpTopic(
    'start',
    'Send with a file',
    'The manual way: save a transaction file, pass it to the recipient, then open the response file they send back.',
    'Choose File on Send. The wallet saves a transaction file and locks the coins. The recipient opens it on Receive, signs and returns a response file. Open that file under Finalize to complete the send.',
  ),
  HelpTopic(
    'how',
    'Why does a transaction need both sides?',
    'In Epic Cash the receiver wallet helps build every transaction, so both wallets must take part.',
    'There are no public addresses on the chain. The two wallets exchange the transaction in steps: the sender starts, the receiver signs, the sender signs and posts it to the network.',
  ),
  HelpTopic(
    'how',
    'Confirmations',
    'A transaction is final after $confirmations confirmations, usually about $confirmations minutes.',
    'Each new block on top of the transaction is one confirmation. Until $confirmations, the amount shows as awaiting confirmation and cannot be spent.',
  ),
  HelpTopic(
    'how',
    'What the blockchain shows',
    'No addresses and no amounts: only coin records the network can check without seeing who or how much.',
    'An explorer lists kernels and outputs. Nothing on the chain ties them to a person or an amount.',
  ),
  HelpTopic(
    'how',
    'Locked amounts and change',
    'The balance is made of separate coins. A send spends whole coins and returns the rest as change.',
    'Locked is what unfinished sends hold. It is freed when the send completes or is cancelled. Change arrives back after the send confirms.',
  ),
  HelpTopic(
    'how',
    'Fees',
    'Every transaction pays a small network fee, shown before sending. It goes to the miners.',
    'The fee depends on how many coins the send uses, not on the amount.',
  ),
  HelpTopic(
    'safety',
    'Your recovery phrase',
    'These words are the only way to get the EPIC back. Write them on paper and never share them.',
    'Show the words in Settings › Recovery phrase. Keep the paper offline. Nobody legitimate asks for the words; anyone who has them can take the funds.',
  ),
  HelpTopic(
    'safety',
    'Backups and restoring',
    'The recovery phrase is the backup. To restore a wallet, enter its words in Restore from a phrase.',
    'The phrase restores coins, not contacts or the transaction notes. Restoring scans the chain, which takes a while.',
  ),
  HelpTopic(
    'network',
    'Nodes',
    'A node connects the wallet to the Epic Cash network. Any public node works.',
    'Choose the node in Settings › Node: pick one from the list or the node directory, or type an address.',
  ),
  HelpTopic(
    'network',
    'Epicbox',
    'Epicbox delivers transactions between wallets and holds them while the other wallet is offline.',
    'Pick the server in Settings › Receiving. Both wallets can use different servers.',
  ),
  if (DeskFeatures.tor)
    const HelpTopic(
      'network',
      'Tor',
      'Tor lets two wallets pay each other privately at a .onion address. Slower than Epicbox, more private, and no ports to open. Off by default.',
      'Turn it on in Settings › Receiving, for each wallet. Tor is blocked or not allowed in some countries; there it does not connect.',
    ),
  HelpTopic(
    'trouble',
    'Troubleshooting',
    'Most problems are a node still syncing or a recipient who has not answered yet.',
    'Check Settings › Node for the node state and Activity for a send waiting for a reply. If the balance looks wrong, run Rescan.',
  ),
];
