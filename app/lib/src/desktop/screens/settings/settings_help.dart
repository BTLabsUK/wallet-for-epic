import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tour.dart';
import '../../../l10n.dart' show appLanguages;
import '../../../ui/language_flag.dart';
import '../../desk_l10n.dart';
import '../../widgets/help_art.dart';
import '../../widgets/kit.dart';
import 'help_invoices.dart';
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
    final title = t.title.toLowerCase(), short = t.short.toLowerCase(), body = t.bodyText.toLowerCase();
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

/// Start states of Help for the screenshots: a topic open, or the end of the page with Tor open.
enum HelpDemo { open, bottom }

class SettingsHelpScreen extends ConsumerStatefulWidget {
  const SettingsHelpScreen({super.key, this.arg});

  /// A search to start with (String), a [HelpDemo] or a [HelpAt].
  final Object? arg;

  @override
  ConsumerState<SettingsHelpScreen> createState() => _SettingsHelpScreenState();
}

class _SettingsHelpScreenState extends ConsumerState<SettingsHelpScreen> {
  late final _query = TextEditingController(text: widget.arg is String ? widget.arg as String : '');
  final _focus = FocusNode(debugLabel: 'help search');
  final _sectionKeys = {for (final s in [...helpSections.map((s) => s.id), invoiceHelpSection]) s: GlobalKey(debugLabel: 'help $s')};
  final _logsKey = GlobalKey(debugLabel: 'help logs');

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    if (widget.arg == HelpDemo.bottom) WidgetsBinding.instance.addPostFrameCallback((_) => _show(_logsKey, 1));
    if (widget.arg == HelpDemo.open) WidgetsBinding.instance.addPostFrameCallback((_) => _show(_sectionKeys['how']!));
    if (widget.arg case HelpAt(:final section) when _sectionKeys.containsKey(section)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _show(_sectionKeys[section]!));
    }
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

  void _show(GlobalKey key, [double alignment = 0]) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    final instant = MediaQuery.of(context).disableAnimations || widget.arg is HelpDemo || widget.arg is HelpAt;
    Scrollable.ensureVisible(ctx, alignment: alignment, duration: instant ? Duration.zero : Dur.slow, curve: Curves.easeOut);
  }

  /// The topic open at the start for the screenshots.
  bool _openAtStart(HelpTopic t, int index) => switch (widget.arg) {
    HelpDemo.open => t.handshake,
    HelpDemo.bottom => t.id == HelpId.tor,
    HelpAt(:final section, :final topic) => t.section == section && index == topic,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final words = queryWords(_query.text);
    final searching = words.isNotEmpty;
    final confirmations = deskMinConfirmations(ref);
    final invoices = ref.watch(deskApiProvider).supportsInvoices;
    final lang = deskHelpLanguage(ref);
    final lh = helpStrings(lang);
    final helpTopics = [...helpTopicsFor(confirmations, lang: lang), if (invoices) ...invoiceHelpTopics(lh, confirmations)];
    // The invoices section goes before "When something goes wrong".
    final sections = <(HelpSection, Widget)>[
      for (final s in localizedHelpSections(lang)) ...[
        if (s.id == 'trouble' && invoices)
          ((id: invoiceHelpSection, title: invoiceHelpTitle(lh), lede: invoiceHelpLede(lh), art: ''), InvoiceHelpMark(width: 120.u)),
        (s, HelpArt(s.art, width: 120.u)),
      ],
    ];
    final hits = searching ? searchTopics(helpTopics, words) : const <({HelpTopic topic, bool inBody})>[];
    return SettingsFrame(
      route: DeskRoute.settingsHelp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The tour's last step lights the support bar, the search and the section chips.
          TourTarget(
            id: 'help-top',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SupportBar(),
                SizedBox(height: Sp.x5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: EField(
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
                    ),
                    SizedBox(width: Sp.x3),
                    // Level with the field, above its one-line hint.
                    Padding(padding: EdgeInsets.only(bottom: 24.u), child: _HelpLanguageSwitch(current: lang)),
                  ],
                ),
                if (!searching) ...[
                  SizedBox(height: Sp.x3),
                  // The section chips, then the tour: it flows with them at every width.
                  Wrap(
                    spacing: Sp.x2,
                    runSpacing: Sp.x2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final (s, _) in sections) _Chip(s.title, onTap: () => _show(_sectionKeys[s.id]!)),
                      EButton.ghost(label: 'Show the tour again', icon: EIcons.restart, size: EBtnSize.inline, hit44: true, onPressed: () => startDeskTour(ref)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (searching) ...[
            SizedBox(height: Sp.x5),
            Semantics(
              liveRegion: true,
              child: Text(hits.isEmpty ? 'No topic matches “${_query.text.trim()}”. Try another word.' : 'Topics found: ${hits.length}', style: ts.small),
            ),
            SizedBox(height: Sp.x3),
            if (hits.isEmpty)
              const EEmpty(icon: EIcons.search, title: 'No topic matches')
            else
              _Box(
                children: [
                  for (final (i, h) in hits.indexed)
                    _Topic(key: ValueKey('${h.topic.title}-${words.join(' ')}'), topic: h.topic, words: words, first: i == 0, initiallyOpen: h.inBody),
                ],
              ),
          ] else ...[
            SizedBox(height: Sp.x6),
            for (final (s, art) in sections)
              if (helpTopics.where((t) => t.section == s.id).toList() case final topics when topics.isNotEmpty)
                Padding(
                  key: _sectionKeys[s.id],
                  padding: EdgeInsets.only(bottom: Sp.x5),
                  child: _Box(
                    children: [
                      _SectionHead(section: s, art: art, count: topics.length),
                      for (final (i, t) in topics.indexed) _Topic(key: ValueKey(t.title), topic: t, words: const [], first: i == 0, initiallyOpen: _openAtStart(t, i)),
                    ],
                  ),
                ),
          ],
          SizedBox(height: Sp.x2),
          LogsGroup(key: _logsKey),
        ],
      ),
    );
  }
}

/// The help language: its flag and own name, and a menu of the app's languages. It changes only
/// the language of the topics, and is remembered.
class _HelpLanguageSwitch extends ConsumerWidget {
  const _HelpLanguageSwitch({required this.current});

  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    width: 168.u,
    child: ESelect<String>(
      size: EBtnSize.sm,
      semanticLabel: context.l10n.helpLanguageLabel,
      value: current,
      items: [for (final a in appLanguages) ESelectItem(a.code, a.name, leading: LanguageFlag(a.code, height: 14))],
      onChanged: (code) {
        final n = ref.read(deskProvider.notifier);
        n.saveSettings(ref.read(deskProvider).settings.copyWith(helpLanguage: () => code));
      },
    ),
  );
}

/// Report a problem, first on the page.
class _SupportBar extends StatelessWidget {
  const _SupportBar();

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: 14.u),
      decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
      child: Row(
        children: [
          HelpArt('help-support', width: 112.u),
          SizedBox(width: Sp.x5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text('Report a problem', style: ts.strong)),
                SizedBox(height: 2.u),
                Text(
                  'Describe what went wrong. The app log can go with it, cleaned of secrets and encrypted to the developer. '
                  'Save to file keeps a copy to send by hand.',
                  style: ts.small,
                ),
              ],
            ),
          ),
          SizedBox(width: Sp.x5),
          EButton(label: 'Report a problem', icon: EIcons.bug, size: EBtnSize.sm, onPressed: () => showReportProblemDialog(context)),
        ],
      ),
    );
  }
}

/// A section chip: scrolls to its section; not a filter.
class _Chip extends StatelessWidget {
  const _Chip(this.label, {required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final radius = BorderRadius.circular(14.u);
    return Semantics(
      button: true,
      child: Material(
        color: c.s1,
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: c.lineStrong)),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            height: 28.u,
            padding: EdgeInsets.symmetric(horizontal: 10.u),
            child: Center(widthFactor: 1, child: Text(label, style: TextStyle(fontSize: 12.5.u, fontWeight: FontWeight.w500, color: c.dim))),
          ),
        ),
      ),
    );
  }
}

/// A section's box, or the box of search hits.
class _Box extends StatelessWidget {
  const _Box({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.section, required this.art, required this.count});

  final HelpSection section;
  final Widget art;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x4),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          art,
          SizedBox(width: Sp.x5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(section.title, style: ts.h3)),
                SizedBox(height: 2.u),
                Text(section.lede, style: ts.small),
              ],
            ),
          ),
          SizedBox(width: Sp.x4),
          Text('$count ${count == 1 ? 'topic' : 'topics'}', style: ts.mono(size: Fs.xs, color: c.faint)),
        ],
      ),
    );
  }
}

/// One topic: title and answer always shown; Read more opens the body under them.
class _Topic extends ConsumerStatefulWidget {
  const _Topic({super.key, required this.topic, required this.words, required this.first, this.initiallyOpen = false});

  final HelpTopic topic;
  final List<String> words;

  /// The first row of its box: no line above it.
  final bool first;
  final bool initiallyOpen;

  @override
  ConsumerState<_Topic> createState() => _TopicState();
}

class _TopicState extends ConsumerState<_Topic> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final t = widget.topic;
    final instant = MediaQuery.of(context).disableAnimations;
    final answer = ts.bodyDim.copyWith(fontSize: 13.5.u);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: 14.u),
      decoration: BoxDecoration(border: widget.first ? null : Border(top: BorderSide(color: c.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text.rich(marked(context, t.title, widget.words, ts.strong))),
                    SizedBox(height: 2.u),
                    Text.rich(marked(context, t.short, widget.words, answer)),
                  ],
                ),
              ),
              SizedBox(width: Sp.x4),
              Semantics(
                button: true,
                expanded: _open,
                child: InkWell(
                  onTap: () => setState(() => _open = !_open),
                  borderRadius: BorderRadius.circular(Rad.xs),
                  child: Container(
                    height: Ctl.inline,
                    padding: EdgeInsets.symmetric(horizontal: Sp.x1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedRotation(
                          turns: _open ? 0.25 : 0,
                          duration: instant ? Duration.zero : Dur.base,
                          child: Icon(EIcons.chevronRight, size: 14.u, color: c.accentText),
                        ),
                        SizedBox(width: Sp.x1),
                        Text(_open ? 'Show less' : 'Read more', style: TextStyle(fontSize: 12.5.u, fontWeight: FontWeight.w500, color: c.accentText)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          ExpandFade(
            open: _open,
            child: Padding(
              padding: EdgeInsets.only(top: 10.u),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 680.u),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final b in t.body) _Block(block: b, words: widget.words, style: answer),
                      if (t.handshake) ...[SizedBox(height: Sp.x2), const HelpHandshake()],
                      if (t.invoiceFlow) ...[SizedBox(height: Sp.x2), InvoiceFlowDiagram(confirmations: deskMinConfirmations(ref))],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A paragraph or a list of a topic's body, with its terms, places and search marks.
class _Block extends StatelessWidget {
  const _Block({required this.block, required this.words, required this.style});

  final HelpBlock block;
  final List<String> words;
  final TextStyle style;

  TextSpan _rich(BuildContext context, String text) {
    final c = context.dc;
    return TextSpan(
      style: style,
      children: [
        for (final p in helpInline(text))
          marked(
            context,
            p.text,
            words,
            p.term
                ? style.copyWith(color: c.text, fontWeight: FontWeight.w600)
                : p.place
                ? style.copyWith(color: c.accentText, fontWeight: FontWeight.w500)
                : style,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gap = EdgeInsets.only(bottom: Sp.x2);
    if (block.kind == HelpBlockKind.p) return Padding(padding: gap, child: Text.rich(_rich(context, block.text)));
    return Padding(
      padding: gap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, item) in block.items.indexed)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.u),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 22.u, child: Text(block.kind == HelpBlockKind.ol ? '${i + 1}.' : '•', style: style)),
                  Expanded(child: Text.rich(_rich(context, item))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

List<String> _epicboxSteps(int confirmations) => [
  'The sending wallet passes the payment to Epicbox and locks the outputs.',
  'Epicbox delivers it when the receiving wallet is online. That wallet adds its part and signs.',
  'The receiving wallet sends it back to Epicbox.',
  'Epicbox passes it back to the sending wallet.',
  'The sending wallet signs too, finishes the transaction and posts it to the network.',
  'The network puts it in a block. After $confirmations confirmations it is final.',
];

List<String> _fileSteps(int confirmations) => [
  'The sending wallet saves a transaction file and locks the outputs. The file goes to the recipient by any means.',
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
                ETag(names[k], icon: at[_i] == k ? EIcons.chevronRight : null),
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
