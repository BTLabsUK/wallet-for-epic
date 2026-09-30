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
  otherWaysToSend,
}

class _Answer {
  const _Answer(this.question, this.answer);

  final String question;
  final String answer;
}

final Map<HelpTopic, _Answer> _answers = {
  HelpTopic.waitingForRecipient: const _Answer(
    'Why does my payment say "Waiting for recipient"?',
    'An Epic Cash payment is built by both wallets together: yours starts it, '
        'the recipient\'s wallet signs it, then yours finishes it. Epicbox is a '
        'mailbox service that holds your payment until the recipient\'s wallet '
        'comes online and answers. Until then the amount stays locked in your '
        'wallet, so you cannot spend it twice.',
  ),
  HelpTopic.cancelling: const _Answer(
    'Should I cancel a payment?',
    'Cancel only a payment that still says "Waiting for recipient", for example '
        'when the recipient tells you they will never answer. Cancelling unlocks '
        'the amount in your wallet, and the payment can no longer complete, so '
        'you would have to send it again. A payment that is already confirming '
        'is on its way to the network and cannot be cancelled.',
  ),
  HelpTopic.receiving: const _Answer(
    'Why must I keep the app open to receive?',
    'Your wallet has to sign every incoming payment, and it can only do that '
        'while the app is open and connected to the epicbox relay. Payments sent '
        'while the app is closed wait at the relay and complete the next time '
        'you unlock. The sender\'s funds stay locked until then.',
  ),
  HelpTopic.confirmations: _Answer(
    'What are confirmations and why $minimumConfirmations?',
    'A confirmation is a new block added to the Epic Cash blockchain after the '
        'one that holds your transaction; a block arrives about once a minute. '
        'Each block makes it harder to undo the transaction. This wallet lets you '
        'spend received coins after $minimumConfirmations confirmations, about '
        '$minimumConfirmations minutes, which is the Epic wallet\'s standard.',
  ),
  HelpTopic.historyAfterRestore: const _Answer(
    'Why is my history missing after a restore?',
    'The recovery phrase brings back your balance: the wallet scans the '
        'blockchain for coins that belong to it. Who you paid, your notes and '
        'most dates are never stored on the blockchain, so a restore cannot find '
        'them. If you saved a history backup, import it in Settings, under '
        'Transaction history, to get them back.',
  ),
  HelpTopic.addressChanges: const _Answer(
    'Does my address ever change?',
    'Your address is made from your recovery phrase and the epicbox relay you '
        'use, and it looks like <address>@<relay>. It stays the same as long as '
        'you keep the same relay. If you pick another relay in network settings, '
        'your address changes, so give the new one to people who pay you.',
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
    'The fee goes to the miners who add your transaction to the blockchain. It '
        'is usually a small fraction of an EPIC and depends on how many coins '
        'your wallet combines to make the payment. You see the exact fee before '
        'you send.',
  ),
  HelpTopic.otherWaysToSend: const _Answer(
    'Are there other ways to send?',
    'For advanced users. If the recipient runs a wallet that listens on the '
        'internet, paste its address starting with http:// or https:// as the '
        'recipient, and the payment completes at once. Without epicbox, use '
        '"Send by transaction file" under "Other ways to send": you share a '
        'file, the recipient signs it and returns a .response file, and you open '
        'that file to finish.',
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
