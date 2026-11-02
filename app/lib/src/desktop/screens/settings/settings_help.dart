// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/tour.dart';
import '../../../l10n.dart' show appLanguages;
import '../../../ui/help_screen.dart' show helpWordStart;
import '../../../ui/language_flag.dart';
import '../../desk_l10n.dart';
import '../../widgets/help_art.dart';
import '../../widgets/kit.dart';
import '../../data/pairing_state.dart' show deskPairsProvider;
import 'help_pairing.dart';
import 'help_places.dart';
import 'help_sync.dart';
import '../../../ui/help/network_modes_diagram.dart';
import 'help_topics.dart';
import 'report_problem.dart';
import 'settings_frame.dart';
import 'settings_advanced.dart' show advancedOf;
import '../../data/desk_levels.dart' show deskLevelUiProvider;
import 'setting_ids.dart';

/// The query's words, lower case, longest first; none under two letters in all.
List<String> queryWords(String q) {
  final words = q.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet().toList();
  if (words.join().length < 2) return const [];
  return words..sort((a, b) => b.length - a.length);
}

/// Whether [w] starts a word somewhere in [low] ("tor" finds Tor, not restore).
bool _has(String low, String w) => helpWordStart(low, w) >= 0;

/// Matching topics, best first: a word in the title counts 100, in the answer 10, in the body 1.
/// Every word must start a word somewhere. [inBody]: a word matched the body (the topic opens).
List<({HelpTopic topic, bool inBody})> searchTopics(List<HelpTopic> topics, List<String> words) {
  final hits = <({HelpTopic topic, bool inBody, int score, int order})>[];
  for (var i = 0; i < topics.length; i++) {
    final t = topics[i];
    final title = t.title.toLowerCase(), short = t.short.toLowerCase(), body = t.bodyText.toLowerCase();
    if (!words.every((w) => _has(title, w) || _has(short, w) || _has(body, w))) continue;
    var score = 0;
    for (final w in words) {
      if (_has(title, w)) score += 100;
      if (_has(short, w)) score += 10;
      if (_has(body, w)) score += 1;
    }
    hits.add((topic: t, inBody: words.any((w) => _has(body, w)), score: score, order: i));
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
    var at = helpWordStart(low, w);
    while (at >= 0) {
      ranges.add((at, at + w.length));
      at = helpWordStart(low, w, at + w.length);
    }
  }
  ranges.sort((a, b) => a.$1 - b.$1);
  final c = context.dc;
  // Every hit neutral and bold: gold is for the brand and the main action, not for each word.
  final mark = style.copyWith(backgroundColor: c.lineStrong, color: c.text, fontWeight: FontWeight.w700);
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
  final _sectionKeys = {for (final s in [...helpSections.map((s) => s.id), pairingHelpSection]) s: GlobalKey(debugLabel: 'help $s')};
  final _endKey = GlobalKey(debugLabel: 'help end');

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    if (widget.arg == HelpDemo.bottom) WidgetsBinding.instance.addPostFrameCallback((_) => _show(_endKey, 1));
    if (widget.arg == HelpDemo.open) WidgetsBinding.instance.addPostFrameCallback((_) => _show(_sectionKeys['how']!));
    if (widget.arg case HelpAt(:final section) when _sectionKeys.containsKey(section)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _show(_sectionKeys[section]!));
    }
    if (widget.arg case HelpAt(:final id, :final anchor) when id.isNotEmpty) {
      // The topic opens with the page (initiallyOpen): its heading has a size at the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _show(anchor.isNotEmpty && _anchorKey.currentContext != null ? _anchorKey : _topicKey));
    }
  }

  /// The topic and the heading [HelpAt.topic] opens at.
  final _topicKey = GlobalKey(debugLabel: 'help topic');
  final _anchorKey = GlobalKey(debugLabel: 'help anchor');

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

  /// Whether [t] is the topic [HelpAt.topic] opens.
  bool _isTarget(HelpTopic t) => switch (widget.arg) {
    HelpAt(:final id) when id.isNotEmpty => t.id == id,
    _ => false,
  };

  /// The topic open at the start for the screenshots.
  bool _openAtStart(HelpTopic t, int index) => switch (widget.arg) {
    HelpDemo.open => t.handshake,
    HelpDemo.bottom => t.id == HelpId.tor,
    HelpAt(:final id) when id.isNotEmpty => t.id == id,
    HelpAt(:final section, :final topic) => t.section == section && index == topic,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final words = queryWords(_query.text);
    final searching = words.isNotEmpty;
    final confirmations = deskMinConfirmations(ref);
    final pairs = ref.watch(deskPairsProvider);
    final lang = deskHelpLanguage(ref);
    final lh = helpStrings(lang);
    // The topics of a part Advanced hides go with it (Outputs).
    final helpTopics = [...helpTopicsShown(helpTopicsFor(confirmations, lang: lang), advancedOf(ref)), if (pairs) ...helpTopicsShown(pairingHelpTopics(lh, platform: HelpPlatform.desktop), advancedOf(ref))];
    // The Pairing section goes before "When something goes wrong".
    final sections = <(HelpSection, Widget)>[
      for (final s in localizedHelpSections(lang, tor: DeskFeatures.tor)) ...[
        if (s.id == 'trouble' && pairs)
          ((id: pairingHelpSection, title: pairingHelpTitle(lh), lede: pairingHelpLede(lh), art: ''), PairingHelpMark(width: 120.u)),
        (s, HelpArt(s.art, width: 120.u)),
      ],
    ];
    final hits = searching ? searchTopics(helpTopics, words) : const <({HelpTopic topic, bool inBody})>[];
    return SettingsFrame(
      route: DeskRoute.settingsHelp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The tour's last step lights the search and the section chips.
          TourTarget(
            id: 'help-top',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: EField(
                        label: context.l10n.deskSetHelpSearch,
                        help: context.l10n.deskSetHelpSearchKeys,
                        child: CallbackShortcuts(
                          bindings: {const SingleActivator(LogicalKeyboardKey.escape): _clear},
                          child: ESearch(
                            controller: _query,
                            focusNode: _focus,
                            hint: context.l10n.deskSetHelpSearchHint,
                            label: context.l10n.deskSetHelpSearch,
                            clearLabel: context.l10n.deskSetHelpClear,
                            onChanged: (_) => setState(() {}),
                            onClear: _clear,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Sp.x4),
                    // Its own control (review 11, named "Help language" to a screen reader): it
                    // sets only the topics' language. Level with the field, above its hint.
                    Padding(
                      padding: EdgeInsets.only(bottom: 24.u),
                      child: _HelpLanguageSwitch(current: lang),
                    ),
                  ],
                ),
                if (!searching) ...[
                  SizedBox(height: Sp.x4),
                  // The section chips: each scrolls to its section.
                  Wrap(
                    spacing: Sp.x2,
                    runSpacing: Sp.x2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final (s, _) in sections) _Chip(s.title, onTap: () => _show(_sectionKeys[s.id]!)),
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
              child: Text(hits.isEmpty ? context.l10n.deskSetHelpNoMatchText(_query.text.trim()) : context.l10n.deskSetHelpFound(hits.length), style: ts.small),
            ),
            SizedBox(height: Sp.x3),
            if (hits.isEmpty)
              EEmpty(icon: EIcons.search, title: context.l10n.deskSetHelpNoMatch)
            else
              _Box(
                children: [
                  for (final (i, h) in hits.indexed)
                    _Topic(key: ValueKey('${h.topic.title}-${words.join(' ')}'), topic: h.topic, words: words, first: i == 0, initiallyOpen: h.inBody),
                ],
              ),
          ] else ...[
            SizedBox(height: Sp.x8),
            for (final (s, art) in sections)
              if (helpTopics.where((t) => t.section == s.id).toList() case final topics when topics.isNotEmpty)
                Padding(
                  key: _sectionKeys[s.id],
                  // Room between the sections (item 4).
                  padding: EdgeInsets.only(bottom: Sp.x8),
                  child: _Box(
                    children: [
                      _SectionHead(section: s, art: art, count: topics.length),
                      for (final (i, t) in topics.indexed)
                        _Topic(
                          key: _isTarget(t) ? _topicKey : ValueKey(t.title),
                          topic: t,
                          words: const [],
                          first: i == 0,
                          initiallyOpen: _openAtStart(t, i),
                          anchor: _isTarget(t) ? (widget.arg as HelpAt).anchor : '',
                          anchorKey: _anchorKey,
                        ),
                    ],
                  ),
                ),
          ],
          SizedBox(height: Sp.x4),
          KeyedSubtree(key: _endKey, child: const _SupportGroup()),
          const _StartAgainGroup(),
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
        // The interface's own language is the default, not a pin: Help then follows it.
        final ui = context.l10n.localeName;
        n.saveSettings(ref.read(deskProvider).settings.copyWith(helpLanguage: () => code == ui ? null : code));
      },
    ),
  );
}

/// A card's header row: `[art | words | actions]`. Art and actions keep their size and the words
/// get the rest; when the words would get under 240 u the actions go under them as a [Wrap],
/// and when the words still get under [Lay.xs] the art goes above them too.
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({this.art, required this.words, required this.actions, this.gap});

  final Widget? art;
  final Widget words;
  final List<Widget> actions;
  final double? gap;

  @override
  Widget build(BuildContext context) {
    final gap = this.gap ?? Sp.x5;
    return LayoutBuilder(
      builder: (context, box) {
        final artW = art == null ? 0.0 : 112.u + gap;
        // An action is at most a small button with its label.
        final actionsW = actions.length * 160.u + gap;
        final beside = box.maxWidth - artW - actionsW >= 240.u;
        if (beside) {
          return Row(
            children: [
              if (art != null) ...[art!, SizedBox(width: gap)],
              Expanded(child: words),
              SizedBox(width: gap),
              ...actions,
            ],
          );
        }
        final stackArt = art != null && box.maxWidth - artW < Lay.xs;
        final underWords = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [words, SizedBox(height: Sp.x3), Wrap(spacing: Sp.x2, runSpacing: Sp.x2, children: actions)],
        );
        if (stackArt) {
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [art!, SizedBox(height: Sp.x3), underWords]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (art != null) ...[art!, SizedBox(width: gap)],
            Expanded(child: underWords),
          ],
        );
      },
    );
  }
}

/// Help › Support: Report a problem.
class _SupportGroup extends StatelessWidget {
  const _SupportGroup();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ESetGroup(
      title: l.deskSetHelpSupportHead,
      rows: [
        ESetRow(
          anchor: SetId.report,
          title: l.deskSetReportTitle,
          hint: l.deskSetHelpReportText,
          control: ERowControl(child: EButton(label: l.deskSetHelpReportButton, icon: EIcons.bug, size: EBtnSize.sm, onPressed: () => showReportProblemDialog(context))),
        ),
      ],
    );
  }
}

/// Help › Start again: the tour, and Set up (Deeper and up; Shallow has no Set up).
class _StartAgainGroup extends ConsumerWidget {
  const _StartAgainGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final setup = ref.watch(deskLevelUiProvider).setupWizard;
    final setupRow = ESetRow(
      anchor: SetId.setup,
      advancedBy: setup ? null : advancedByView(l, 2),
      title: l.deskSetHelpSetupAgain,
      hint: l.deskSetHelpSetupHint,
      control: ERowControl(child: EButton(label: l.deskSetAcctRunSetup, icon: EIcons.restart, size: EBtnSize.sm, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.setup))),
    );
    return ESetGroup(
      title: l.deskSetHelpStartAgain,
      rows: [
        ESetRow(
          anchor: SetId.tour,
          title: l.deskSetHelpTourAgain,
          control: ERowControl(child: EButton(label: l.deskSetHelpTourStart, icon: EIcons.restart, size: EBtnSize.sm, onPressed: () => startDeskTour(ref))),
        ),
        if (setup) setupRow,
      ],
      hidden: [if (!setup) setupRow],
      revealKey: 'help-again',
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
        child: EInkWell(
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
      child: _HeaderRow(
        art: art,
        words: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: Text(section.title, style: ts.h3)),
            SizedBox(height: 2.u),
            Text(section.lede, style: ts.small),
          ],
        ),
        actions: [Text(context.l10n.deskSetHelpTopics(count), style: ts.mono(size: Fs.xs, color: c.faint))],
        gap: Sp.x4,
      ),
    );
  }
}

/// One topic: title and answer always shown; Read more opens the body under them.
class _Topic extends ConsumerStatefulWidget {
  const _Topic({super.key, required this.topic, required this.words, required this.first, this.initiallyOpen = false, this.anchor = '', this.anchorKey});

  final HelpTopic topic;
  final List<String> words;

  /// The heading [anchorKey] goes on, for the screen to scroll to ([HelpAt.anchor]).
  final String anchor;
  final GlobalKey? anchorKey;

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
          _HeaderRow(
            gap: Sp.x4,
            words: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text.rich(marked(context, t.title, widget.words, ts.strong))),
                SizedBox(height: 2.u),
                Text.rich(marked(context, t.short, widget.words, answer)),
              ],
            ),
            actions: [
              Semantics(
                button: true,
                expanded: _open,
                child: EInkWell(
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
                        NoSelect(child: Text(_open ? context.l10n.deskSetHelpShowLess : context.l10n.deskSetHelpReadMore, style: TextStyle(fontSize: 12.5.u, fontWeight: FontWeight.w500, color: c.accentText))),
                      ],
                    ),
                  ),
                ),
              )
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
                      if (t.devices) ...[const DeskSyncDiagram(), SizedBox(height: Sp.x4)],
                      // Network modes: the picture of what each mode lets out, at the wallet's own mode.
                      if (t.id == HelpId.modes) ...[
                        Consumer(
                          builder: (context, ref, _) => NetworkModesDiagram(
                            initial: ref.watch(deskProvider.select((s) => s.settings.advanced.networkMode)),
                            tor: DeskFeatures.tor,
                          ),
                        ),
                        SizedBox(height: Sp.x6),
                      ],
                      for (final b in t.body) _Block(key: b.anchor.isNotEmpty && b.anchor == widget.anchor ? widget.anchorKey : null, block: b, words: widget.words, style: answer),
                      if (t.devices) ...[SizedBox(height: Sp.x2), const DeskSyncStatus()],
                      if (t.handshake) ...[SizedBox(height: Sp.x2), const HelpHandshake()],
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

/// A paragraph or a list of a topic's body, with its terms, places and search marks. A place is
/// a link to its page (see [openDeskHelpPlace]).
class _Block extends ConsumerWidget {
  const _Block({super.key, required this.block, required this.words, required this.style});

  final HelpBlock block;
  final List<String> words;
  final TextStyle style;

  TextSpan _rich(BuildContext context, WidgetRef ref, String text) {
    final c = context.dc;
    return TextSpan(
      style: style,
      children: [
        for (final p in helpInline(text))
          if (p.place && deskHelpPlaceShown(ref, p.target))
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: _PlaceLink(
                label: marked(context, p.text, words, style.copyWith(color: c.accentText, fontWeight: FontWeight.w500)),
                onPressed: () => openDeskHelpPlace(ref, p.target),
              ),
            )
          else
            marked(
              context,
              p.text,
              words,
              p.term || p.place ? style.copyWith(color: c.text, fontWeight: FontWeight.w600) : style,
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gap = EdgeInsets.only(bottom: Sp.x2);
    if (block.kind == HelpBlockKind.h) {
      return Padding(
        padding: EdgeInsets.only(top: Sp.x2, bottom: Sp.x2),
        child: Semantics(header: true, child: Text.rich(marked(context, block.text, words, context.ts.strong))),
      );
    }
    if (block.kind == HelpBlockKind.p) return Padding(padding: gap, child: Text.rich(_rich(context, ref, block.text)));
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
                  Expanded(child: Text.rich(_rich(context, ref, item))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A place in a topic's text: underlined, keyboard reachable, going to its page.
class _PlaceLink extends StatefulWidget {
  const _PlaceLink({required this.label, required this.onPressed});

  final TextSpan label;
  final VoidCallback onPressed;

  @override
  State<_PlaceLink> createState() => _PlaceLinkState();
}

class _PlaceLinkState extends State<_PlaceLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.label.style?.color;
    return Semantics(
      link: true,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed())},
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: widget.onPressed,
            child: FocusRing(
              focused: Focus.of(context).hasFocus,
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationColor: color == null ? null : (_hover ? color : color.withValues(alpha: 0.45)),
                  ),
                  children: [widget.label],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<String> _epicboxSteps(AppLocalizations l, int confirmations) => [
  l.deskSetHelpEb1,
  l.deskSetHelpEb2,
  l.deskSetHelpEb3,
  l.deskSetHelpEb4,
  l.deskSetHelpSigns,
  l.deskSetHelpFinal(confirmations),
];

List<String> _fileSteps(AppLocalizations l, int confirmations) => [
  l.deskSetHelpFile1,
  l.deskSetHelpFile2,
  l.deskSetHelpFile3,
  l.deskSetHelpFile4,
  l.deskSetHelpSigns,
  l.deskSetHelpFinal(confirmations),
];

/// A Link payment goes straight to their wallet: no Epicbox, no file.
List<String> _linkSteps(AppLocalizations l, int confirmations) => [
  DeskFeatures.tor ? l.handshakeLink1 : l.handshakeLink1NoTor,
  l.handshakeLink2,
  l.handshakeFinish,
  l.deskSetHelpFinal(confirmations),
];

/// "How a transaction travels": the steps over Epicbox or with a file, one at a time.
class HelpHandshake extends ConsumerStatefulWidget {
  const HelpHandshake({super.key});

  @override
  ConsumerState<HelpHandshake> createState() => _HelpHandshakeState();
}

enum _Way { epicbox, link, file }

class _HelpHandshakeState extends ConsumerState<HelpHandshake> {
  _Way _way = _Way.epicbox;
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final confirmations = deskMinConfirmations(ref);
    final l = context.l10n;
    final steps = switch (_way) {
      _Way.epicbox => _epicboxSteps(l, confirmations),
      _Way.link => _linkSteps(l, confirmations),
      _Way.file => _fileSteps(l, confirmations),
    };
    // Who holds the slate at each step: 0 sender, 1 middle (Epicbox / file), 2 recipient, 3 network.
    // A Link payment has no middle: the slate goes straight across.
    final at = _way == _Way.link ? const [2, 2, 0, 3] : const [1, 2, 1, 0, 3, 3];
    final held = _way == _Way.link ? const [0, 2, 3] : const [0, 1, 2, 3];
    final names = [l.deskSetHelpSender, if (_way != _Way.link) _way == _Way.file ? l.deskSetHelpFile : 'Epicbox', l.deskSetHelpRecipient, l.deskSetHelpNetwork]; // l10n-ok: Epicbox is a name
    return Container(
      padding: EdgeInsets.all(Sp.x4),
      decoration: c.well,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Sp.x3,
            runSpacing: Sp.x2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l.deskSetHelpTravels, style: ts.label),
              // On a line of its own when the label leaves no room; narrower than the card
              // (a phone-wide window at big text), it scales down rather than overflow.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: ESegmented<_Way>(
                  segments: [ESegment(_Way.epicbox, l.deskSetHelpOverEpicbox), ESegment(_Way.link, l.receiveTabDirect), ESegment(_Way.file, l.deskSetHelpWithFile)],
                  value: _way,
                  onChanged: (v) => setState(() {
                    _way = v;
                    _i = 0;
                  }),
                ),
              ),
            ],
          ),
          SizedBox(height: Sp.x4),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              for (var k = 0; k < names.length; k++)
                EBadge(names[k], icon: at[_i] == held[k] ? EIcons.chevronRight : null),
            ],
          ),
          SizedBox(height: Sp.x3),
          Semantics(liveRegion: true, child: Text(steps[_i], style: ts.body)),
          SizedBox(height: Sp.x3),
          Row(
            children: [
              Text(l.deskSetHelpStep(_i + 1, steps.length), style: ts.mono(size: Fs.xs, color: c.faint)),
              const Spacer(),
              EIconButton(icon: EIcons.chevronLeft, label: l.handshakePrevious, size: EBtnSize.inline, onPressed: _i == 0 ? null : () => setState(() => _i--)),
              SizedBox(width: Sp.x1),
              EIconButton(icon: EIcons.chevronRight, label: l.handshakeNext, size: EBtnSize.inline, onPressed: _i == steps.length - 1 ? null : () => setState(() => _i++)),
            ],
          ),
        ],
      ),
    );
  }
}
