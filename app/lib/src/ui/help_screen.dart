import 'package:flutter/material.dart';

import '../providers.dart' show minimumConfirmations;
import 'common.dart';

/// Questions the help page answers. Other screens open it on one of these.
enum HelpTopic {
  waitingForRecipient,
  cancelling,
  receiving,
  confirmations,
  historyAfterRestore,
  addressChanges,
  recoveryPhrase,
  fees,
  node,
  otherWaysToSend,
}

/// Days after which a send that was never completed cancels itself: the core sets a time to
/// live of 20160 blocks, at one block a minute.
const int sendTtlDays = 14;

class _Answer {
  const _Answer(this.question, this.answer);

  final String question;
  final String answer;
}

final Map<HelpTopic, _Answer> _answers = {
  HelpTopic.waitingForRecipient: const _Answer(
    'Why does my payment say "Waiting for recipient"?',
    'An Epic Cash payment is built by both wallets together: yours starts it, '
        'the recipient\'s wallet accepts it, then yours finishes it. Epic\'s '
        'epicbox service holds your payment for about a week, until '
        'the recipient\'s wallet comes online and answers. Until then the '
        'amount stays locked in your wallet, so you cannot spend it twice. If '
        'the payment is not completed, your wallet cancels it by itself after '
        '$sendTtlDays days and unlocks the amount.',
  ),
  HelpTopic.cancelling: const _Answer(
    'Should I cancel a payment?',
    'Usually you do not need to: a payment that is not completed cancels '
        'itself after $sendTtlDays days and unlocks the amount. To stop one '
        'sooner, for example when the recipient says they will never answer, '
        'open it while it still says "Waiting for recipient" and tap Cancel '
        'payment; you would then have to send it again. A payment that is '
        'already confirming cannot be cancelled. Payments made with older '
        'versions of this app do not cancel themselves: if one has waited more '
        'than two weeks, cancel it and send again.',
  ),
  HelpTopic.receiving: const _Answer(
    'Why must I keep the app open to receive?',
    'Your wallet has to accept every incoming payment, and it can only do that '
        'while the app is open and connected to epicbox. A payment sent while '
        'the app is closed waits in epicbox for about a week and arrives the '
        'next time you unlock. After that epicbox deletes it; if the sender '
        'uses this app, their wallet cancels it by itself after $sendTtlDays '
        'days, and they can send it again. Once your wallet accepts a payment, the sender\'s wallet must '
        'finish it; until then it shows as Waiting for sender.',
  ),
  HelpTopic.confirmations: _Answer(
    'What are confirmations and why $minimumConfirmations?',
    'A confirmation is a new block added to the Epic Cash blockchain after the '
        'one that holds your payment; a block arrives about once a minute. Each '
        'block makes it harder to undo the payment. After $minimumConfirmations '
        'confirmations, about $minimumConfirmations minutes, a payment shows as '
        'Completed and received coins can be spent; that is the Epic wallet\'s '
        'standard.',
  ),
  HelpTopic.historyAfterRestore: const _Answer(
    'Why is my history missing after a restore?',
    'The recovery phrase brings back your balance: the wallet scans the '
        'blockchain for coins that belong to it. Who you paid, your notes and '
        'most dates are never stored on the blockchain, so a restore cannot find '
        'them. If you saved a history backup, import it in Settings, under '
        'Payment history, Import history backup, to get them back. The backup '
        'must be a copy you kept outside the lost phone, for example in email or '
        'cloud storage.',
  ),
  HelpTopic.addressChanges: const _Answer(
    'Does my address ever change?',
    'Your address is made from your recovery phrase and the epicbox server you '
        'use, and it ends in @ and that server\'s name. It stays the same as long '
        'as you keep the same epicbox server. If you pick another one in network '
        'settings, your address changes, so give the new one to people who pay '
        'you.',
  ),
  HelpTopic.recoveryPhrase: const _Answer(
    'What is the recovery phrase and who can see it?',
    'The recovery phrase is a list of words that is the key to your money: '
        'anyone who has it can take your coins, and with it you can restore '
        'your wallet on a new phone. The app shows it only after you enter your '
        'PIN, and it never sends it anywhere. Write it on paper, keep it '
        'somewhere safe, and never share it or type it into a website.',
  ),
  HelpTopic.fees: const _Answer(
    'What does the fee pay for?',
    'The fee goes to the miners who add your payment to the blockchain. It is '
        'usually a small fraction of an EPIC and depends on how many coins your '
        'wallet combines to make the payment. You see the exact fee before you '
        'send.',
  ),
  HelpTopic.node: const _Answer(
    'What is a node?',
    'A node is a computer that keeps a copy of the Epic Cash blockchain. The '
        'wallet asks a node for your balance and sends your payments to the '
        'network through it. The node sees your IP address and which coins the '
        'wallet asks about, so pick one you trust in network settings.',
  ),
  HelpTopic.otherWaysToSend: const _Answer(
    'Are there other ways to send?',
    'For advanced users. If the recipient runs a wallet that listens on the '
        'internet, paste its address starting with http:// or https:// as the '
        'recipient, and the payment goes straight to it. Without epicbox, '
        'use "Send by transaction file" under "Other ways to send": you share a '
        'file, the recipient accepts it and returns a .response file, and you '
        'open that file to finish.',
  ),
};

/// Plain-language answers for people new to Epic Cash. With [topic], that question starts
/// open and in view.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, this.topic});

  final HelpTopic? topic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: ScreenBody(
        children: [
          for (final t in HelpTopic.values)
            _Question(answer: _answers[t]!, open: t == topic),
        ],
      ),
    );
  }
}

class _Question extends StatefulWidget {
  const _Question({required this.answer, required this.open});

  final _Answer answer;
  final bool open;

  @override
  State<_Question> createState() => _QuestionState();
}

class _QuestionState extends State<_Question> {
  @override
  void initState() {
    super.initState();
    if (widget.open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Scrollable.ensureVisible(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: widget.open,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 16),
      expandedAlignment: Alignment.centerLeft,
      title: Text(widget.answer.question),
      children: [
        Text(
          widget.answer.answer,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

/// Opens [HelpScreen] on [topic].
Future<void> openHelp(BuildContext context, [HelpTopic? topic]) => Navigator.of(
  context,
).push<void>(MaterialPageRoute<void>(builder: (_) => HelpScreen(topic: topic)));
