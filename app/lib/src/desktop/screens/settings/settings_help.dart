import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'help_topics.dart';
import 'report_problem.dart';
import 'settings_frame.dart';
import 'settings_logs.dart';

/// The query's words, lower case, longest first; none under two letters in all.
List<String> queryWords(String q) {
  final words = q.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet().toList();
  if (words.join().length < 2) return const [];
  return words..sort((a, b) => b.length - a.length);
}

/// Matching topics, best first: a word in the title counts 100, in the answer 10, in the body 1.
/// Every word must appear somewhere. [inBody]: a word matched the body (the topic opens).
List<({HelpTopic topic, bool inBody})> searchTopics(List<HelpTopic> topics, List<String> words) {
  final hits = <({HelpTopic topic, bool inBody, int score, int order})>[];
  for (var i = 0; i < topics.length; i++) {
    final t = topics[i];
    final title = t.title.toLowerCase(), short = t.short.toLowerCase(), body = t.body.toLowerCase();
    if (!words.every((w) => title.contains(w) || short.contains(w) || body.contains(w))) continue;
    var score = 0;
    for (final w in words) {
      if (title.contains(w)) score += 100;
      if (short.contains(w)) score += 10;
      if (body.contains(w)) score += 1;
    }
    hits.add((topic: t, inBody: words.any(body.contains), score: score, order: i));
  }
  hits.sort((a, b) => b.score != a.score ? b.score - a.score : a.order - b.order);
  return [for (final h in hits) (topic: h.topic, inBody: h.inBody)];
}

/// [text] with every word of [words] marked.
TextSpan marked(BuildContext context, String text, List<String> words, TextStyle style) {
  if (words.isEmpty) return TextSpan(text: text, style: style);
  final low = text.toLowerCase();
  final ranges = <(int, int)>[];
  for (final w in words) {
    var at = low.indexOf(w);
    while (at >= 0) {
      ranges.add((at, at + w.length));
      at = low.indexOf(w, at + w.length);
    }
  }
  ranges.sort((a, b) => a.$1 - b.$1);
  final c = context.dc;
  final mark = style.copyWith(backgroundColor: c.accentSoft, color: c.text);
  final spans = <TextSpan>[];
  var pos = 0;
  for (final (a, b) in ranges) {
    if (a < pos) continue;
    if (a > pos) spans.add(TextSpan(text: text.substring(pos, a)));
    spans.add(TextSpan(text: text.substring(a, b), style: mark));
    pos = b;
  }
  if (pos < text.length) spans.add(TextSpan(text: text.substring(pos)));
  return TextSpan(style: style, children: spans);
}

class SettingsHelpScreen extends ConsumerStatefulWidget {
  const SettingsHelpScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsHelpScreen> createState() => _SettingsHelpScreenState();
}

class _SettingsHelpScreenState extends ConsumerState<SettingsHelpScreen> {
  late final _query = TextEditingController(text: widget.arg is String ? widget.arg as String : '');
  final _focus = FocusNode(debugLabel: 'help search');

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// "/" (when not typing) and Ctrl/Cmd+F focus and select the search.
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || !mounted) return false;
    final hw = HardwareKeyboard.instance;
    final typing = FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;
    final slash = e.logicalKey == LogicalKeyboardKey.slash && !typing && !hw.isControlPressed && !hw.isMetaPressed;
    final find = e.logicalKey == LogicalKeyboardKey.keyF && (hw.isControlPressed || hw.isMetaPressed) && !hw.isAltPressed;
    if (!slash && !find) return false;
    _focus.requestFocus();
    _query.selection = TextSelection(baseOffset: 0, extentOffset: _query.text.length);
    return true;
  }

  void _clear() {
    setState(_query.clear);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final words = queryWords(_query.text);
    final searching = words.isNotEmpty;
    final helpTopics = helpTopicsFor(deskMinConfirmations(ref));
    final hits = searching ? searchTopics(helpTopics, words) : const <({HelpTopic topic, bool inBody})>[];
    Widget list(Iterable<({HelpTopic topic, bool inBody})> topics) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final h in topics)
          Padding(
            padding: EdgeInsets.only(bottom: Sp.x2),
            child: _Topic(key: ValueKey('${h.topic.title}-${words.join(' ')}'), topic: h.topic, words: words, initiallyOpen: h.inBody),
          ),
      ],
    );
    return SettingsFrame(
      route: DeskRoute.settingsHelp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ESectionHead('Help and FAQ', top: 0),
          Text('Short answers to common questions. Search, or open a topic.', style: ts.bodyDim),
          SizedBox(height: Sp.x4),
          ESetGroup(
            title: 'Support',
            rows: [
              ESetRow(
                title: 'Report a problem',
                text: 'Describe what went wrong. The app log can go with it, cleaned of secrets and encrypted to the developer.',
                control: EButton(label: 'Report a problem', icon: EIcons.bug, size: EBtnSize.sm, onPressed: () => showReportProblemDialog(context)),
              ),
            ],
          ),
          SizedBox(height: Sp.x5),
          EField(
            label: 'Search help',
            help: 'Press / to search. Esc clears the search.',
            child: CallbackShortcuts(
              bindings: {const SingleActivator(LogicalKeyboardKey.escape): _clear},
              child: EInput(
                controller: _query,
                focusNode: _focus,
                hint: 'For example: file, confirmations, phrase',
                leading: EIcons.search,
                semanticLabel: 'Search help',
                onChanged: (_) => setState(() {}),
                trailing: _query.text.isEmpty ? null : EIconButton(icon: EIcons.close, label: 'Clear search', onPressed: _clear),
              ),
            ),
          ),
          SizedBox(height: Sp.x5),
          if (searching) ...[
            Semantics(
              liveRegion: true,
              child: Text(hits.isEmpty ? 'No topic matches “${_query.text.trim()}”. Try another word.' : 'Topics found: ${hits.length}', style: ts.small),
            ),
            SizedBox(height: Sp.x3),
            if (hits.isEmpty) const EEmpty(icon: EIcons.search, title: 'No topic matches') else list(hits),
          ] else
            for (final (id, name) in helpSections) ...[
              Padding(
                padding: EdgeInsets.only(bottom: Sp.x2, top: Sp.x2),
                child: Semantics(header: true, child: Text(name.toUpperCase(), style: ts.caption.copyWith(letterSpacing: 0.9, fontWeight: FontWeight.w600, color: c.faint))),
              ),
              list([for (final t in helpTopics.where((t) => t.section == id)) (topic: t, inBody: false)]),
              SizedBox(height: Sp.x4),
            ],
          SizedBox(height: Sp.x2),
          const LogsGroup(),
        ],
      ),
    );
  }
}

/// One topic: title and answer always shown; Read more opens the detail.
class _Topic extends StatefulWidget {
  const _Topic({super.key, required this.topic, required this.words, this.initiallyOpen = false});

  final HelpTopic topic;
  final List<String> words;
  final bool initiallyOpen;

  @override
  State<_Topic> createState() => _TopicState();
}

class _TopicState extends State<_Topic> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final t = widget.topic;
    return Container(
      padding: EdgeInsets.fromLTRB(Sp.x4, Sp.x3, Sp.x4, Sp.x2),
      decoration: BoxDecoration(
        color: c.s1,
        border: Border.all(color: _open ? c.lineStrong : c.line),
        borderRadius: BorderRadius.circular(Rad.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text.rich(marked(context, t.title, widget.words, ts.strong))),
          SizedBox(height: Sp.x1),
          Text.rich(marked(context, t.short, widget.words, ts.bodyDim)),
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              borderRadius: BorderRadius.circular(Rad.sm),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6.u),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      turns: _open ? 0.25 : 0,
                      duration: MediaQuery.of(context).disableAnimations ? Duration.zero : Dur.base,
                      child: Icon(EIcons.chevronRight, size: Ctl.iconSm, color: c.accentText),
                    ),
                    SizedBox(width: Sp.x1),
                    Text(_open ? 'Show less' : 'Read more', style: ts.small.copyWith(color: c.accentText)),
                  ],
                ),
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: EdgeInsets.only(bottom: Sp.x2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text.rich(marked(context, t.body, widget.words, ts.bodyDim)),
                  if (t.title.startsWith('Why does a transaction need both sides')) ...[
                    SizedBox(height: Sp.x4),
                    const HelpHandshake(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

List<String> _epicboxSteps(int confirmations) => [
  'The sending wallet passes the payment to Epicbox and locks the coins.',
  'Epicbox delivers it when the receiving wallet is online. That wallet adds its part and signs.',
  'The receiving wallet sends it back to Epicbox.',
  'Epicbox passes it back to the sending wallet.',
  'The sending wallet signs too, finishes the transaction and posts it to the network.',
  'The network puts it in a block. After $confirmations confirmations it is final.',
];

List<String> _fileSteps(int confirmations) => [
  'The sending wallet saves a transaction file and locks the coins. The file goes to the recipient by any means.',
  'The recipient opens it. Their wallet adds its part, signs and saves a response file.',
  'The response file comes back to the sender.',
  'The sender opens the response file under Finalize.',
  'The sending wallet signs too, finishes the transaction and posts it to the network.',
  'The network puts it in a block. After $confirmations confirmations it is final.',
];

/// "How a transaction travels": the steps over Epicbox or with a file, one at a time.
class HelpHandshake extends ConsumerStatefulWidget {
  const HelpHandshake({super.key});

  @override
  ConsumerState<HelpHandshake> createState() => _HelpHandshakeState();
}

class _HelpHandshakeState extends ConsumerState<HelpHandshake> {
  bool _file = false;
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final confirmations = deskMinConfirmations(ref);
    final steps = _file ? _fileSteps(confirmations) : _epicboxSteps(confirmations);
    // Who holds the slate at each step: 0 sender, 1 middle (Epicbox / file), 2 recipient, 3 network.
    const at = [1, 2, 1, 0, 3, 3];
    final names = ['Sender', _file ? 'File' : 'Epicbox', 'Recipient', 'Network'];
    return Container(
      padding: EdgeInsets.all(Sp.x4),
      decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Sp.x3,
            runSpacing: Sp.x2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('How a transaction travels', style: ts.label),
              ESegmented<bool>(
                segments: const [ESegment(false, 'Over Epicbox'), ESegment(true, 'With a file')],
                value: _file,
                onChanged: (v) => setState(() {
                  _file = v;
                  _i = 0;
                }),
              ),
            ],
          ),
          SizedBox(height: Sp.x4),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              for (var k = 0; k < names.length; k++)
                ETag(names[k], tone: at[_i] == k ? ETone.gold : ETone.neutral, icon: at[_i] == k ? EIcons.chevronRight : null),
            ],
          ),
          SizedBox(height: Sp.x3),
          Semantics(liveRegion: true, child: Text(steps[_i], style: ts.body)),
          SizedBox(height: Sp.x3),
          Row(
            children: [
              Text('Step ${_i + 1} of ${steps.length}', style: ts.mono(size: Fs.xs, color: c.faint)),
              const Spacer(),
              EIconButton(icon: EIcons.chevronLeft, label: 'Previous step', size: EBtnSize.inline, onPressed: _i == 0 ? null : () => setState(() => _i--)),
              SizedBox(width: Sp.x1),
              EIconButton(icon: EIcons.chevronRight, label: 'Next step', size: EBtnSize.inline, onPressed: _i == steps.length - 1 ? null : () => setState(() => _i++)),
            ],
          ),
        ],
      ),
    );
  }
}
