import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo.dart';
import '../l10n.dart';
import 'common.dart';
import 'feedback_screen.dart';

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

typedef _Answer = ({String question, String answer});

_Answer _answer(AppLocalizations l, HelpTopic topic, int confirmations) {
  return switch (topic) {
    HelpTopic.waitingForRecipient => (
      question: l.helpWaitingQuestion,
      answer: l.helpWaitingAnswer(sendTtlDays),
    ),
    HelpTopic.cancelling => (
      question: l.helpCancellingQuestion,
      answer: l.helpCancellingAnswer(sendTtlDays),
    ),
    HelpTopic.receiving => (
      question: l.helpReceivingQuestion,
      answer: l.helpReceivingAnswer(sendTtlDays),
    ),
    HelpTopic.confirmations => (
      question: l.helpConfirmationsQuestion(confirmations),
      answer: l.helpConfirmationsAnswer(confirmations),
    ),
    HelpTopic.historyAfterRestore => (
      question: l.helpHistoryQuestion,
      answer: l.helpHistoryAnswer,
    ),
    HelpTopic.addressChanges => (
      question: l.helpAddressQuestion,
      answer: l.helpAddressAnswer,
    ),
    HelpTopic.recoveryPhrase => (
      question: l.helpPhraseQuestion,
      answer: l.helpPhraseAnswer,
    ),
    HelpTopic.fees => (question: l.helpFeesQuestion, answer: l.helpFeesAnswer),
    HelpTopic.node => (question: l.helpNodeQuestion, answer: l.helpNodeAnswer),
    HelpTopic.otherWaysToSend => (
      question: l.helpOtherWaysQuestion,
      answer: l.helpOtherWaysAnswer,
    ),
  };
}

/// Plain-language answers for people new to Epic Cash. With [topic], that question starts
/// open and in view.
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key, this.topic});

  final HelpTopic? topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final confirmations = confirmationsTargetOf(ref);
    return SlotScaffold(
      appBar: AppBar(title: Text(l.helpTitle)),
      body: ScreenBody(
        children: [
          for (final t in HelpTopic.values)
            _Question(answer: _answer(l, t, confirmations), open: t == topic),
          // The web demo has no feedback report until a feedback proxy exists.
          if (!ref.watch(demoModeProvider)) ...[
            const SizedBox(height: 24),
            Text(
              l.helpStillStuck,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l.helpTellUs),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.feedback_outlined),
                label: Text(l.helpSendFeedback),
                onPressed: () => openFeedback(context),
              ),
            ),
          ],
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
