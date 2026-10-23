/// Help on the phone: the shared topics (`help/help_content.dart`, the same words as the
/// desktop's Settings › Help) in a phone-fit shape. The index lists the sections with their
/// topics and searches them; a topic opens as its own page, where a bold term is a term and a
/// place in the app is a link that goes there. Other screens open one topic directly with
/// [openHelp] or the small [HelpButton].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo.dart';
import '../help/help_content.dart';
import '../l10n.dart';
import '../phone_tor.dart';
import '../providers.dart';
import 'common.dart';
import 'feedback_screen.dart';
import 'handshake.dart';
import 'history_screen.dart';
import 'outputs_screen.dart';
import 'server_picker.dart';
import 'settings_screen.dart';
import 'theme/tokens.dart';
import 'tor_ui.dart';

export '../help/help_content.dart' show HelpId;

/// Days after which a send that was never completed cancels itself: the old core set a time
/// to live of 20160 blocks, at one block a minute. The Send tracker's copy still quotes it.
const int sendTtlDays = 14;

/// The key of the search field, for tests.
const Key helpSearchKey = ValueKey('help-search');

/// The topics this wallet shows: the shared set for the phone, the invoice topics when the
/// wallet supports invoices, Tor only when the phone has it.
List<HelpTopic> phoneHelpTopics(WidgetRef ref, AppLocalizations l) {
  final confirmations = confirmationsTargetOf(ref);
  final invoices = ref.watch(sessionProvider)?.supportsInvoices ?? false;
  final tor = ref.watch(phoneTorProvider.select(torShown));
  return [
    ...helpTopics(confirmations, platform: HelpPlatform.phone, tor: tor),
    if (invoices) ...invoiceHelpTopics(l, confirmations),
  ];
}

/// The sections in the order the index shows them: Invoices before "When something goes
/// wrong", and only when a topic uses it.
List<HelpSection> _sectionsFor(List<HelpTopic> topics, AppLocalizations l) {
  final used = topics.map((t) => t.section).toSet();
  final out = <HelpSection>[];
  for (final s in helpSections) {
    if (s.id == 'trouble' && used.contains(invoiceHelpSection)) {
      out.add((id: invoiceHelpSection, title: l.deskInvHelpTitle, lede: l.deskInvHelpLede, art: ''));
    }
    if (used.contains(s.id)) out.add(s);
  }
  return out;
}

/// The words of a search, lowercased, empty for a blank query.
List<String> helpQueryWords(String query) =>
    query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

/// Whether [topic] matches every word of [words] in its title, short line or body.
bool helpMatches(HelpTopic topic, List<String> words) {
  if (words.isEmpty) return true;
  final hay = '${topic.title}\n${topic.short}\n${topic.bodyText}'.toLowerCase();
  return words.every(hay.contains);
}

/// Opens Help: the index, or [topic]'s page straight away ([HelpId]).
Future<void> openHelp(BuildContext context, [String? topic]) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(builder: (_) => HelpScreen(topic: topic)),
);

/// A small help button for a screen's app bar or a label's row: opens [topic]'s page.
class HelpButton extends StatelessWidget {
  const HelpButton(this.topic, {super.key, this.size = 20});

  final String topic;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        tooltip: context.l10n.helpButton,
        icon: Icon(Icons.help_outline, size: size),
        padding: EdgeInsets.zero,
        onPressed: () => openHelp(context, topic),
      ),
    );
  }
}

/// Help: the search field over the sections and their topics. With [topic], that topic's page
/// opens over the index at once, so Back lands on the index.
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key, this.topic});

  /// The topic to open on arrival, by [HelpTopic.id].
  final String? topic;

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  final _query = TextEditingController();
  bool _opened = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _openTopic(HelpTopic topic, List<HelpTopic> all) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HelpTopicScreen(
          topic: topic,
          section: _sectionsFor(all, context.l10n).firstWhere((s) => s.id == topic.section),
          related: [for (final t in all) if (t.section == topic.section && t != topic) t],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final topics = phoneHelpTopics(ref, l);
    final sections = _sectionsFor(topics, l);
    if (!_opened && widget.topic != null) {
      // The topic's page goes over the index on arrival, so Back lands on the index.
      _opened = true;
      final t = topics.where((t) => t.id == widget.topic).firstOrNull;
      if (t != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openTopic(t, topics);
        });
      }
    }
    final words = helpQueryWords(_query.text);
    final searching = words.isNotEmpty;
    final hits = searching ? [for (final x in topics) if (helpMatches(x, words)) x] : topics;
    final english = Localizations.localeOf(context).languageCode != 'en';

    Widget row(HelpTopic topic, {bool section = false}) => _TopicRow(
      topic: topic,
      words: words,
      overline: section ? sections.firstWhere((s) => s.id == topic.section).title : null,
      onTap: () => _openTopic(topic, topics),
    );

    return SlotScaffold(
      appBar: AppBar(title: Text(l.helpTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    key: helpSearchKey,
                    controller: _query,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l.helpSearchHint,
                      isDense: true,
                      constraints: const BoxConstraints(minHeight: 44),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l.commonClose,
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(_query.clear),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      if (english)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(l.helpEnglishOnly, style: text.bodySmall?.copyWith(color: t.dim)),
                        ),
                      if (searching) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            hits.isEmpty ? l.helpNoMatch(_query.text.trim()) : l.helpMatchCount(hits.length),
                            style: text.bodyMedium?.copyWith(color: t.dim),
                          ),
                        ),
                        for (final x in hits) row(x, section: true),
                      ] else
                        for (final s in sections) ...[
                          _SectionHead(section: s),
                          for (final x in topics.where((x) => x.section == s.id)) row(x),
                          const SizedBox(height: 16),
                        ],
                      const _StillStuck(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.section});

  final HelpSection section;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.title, style: text.titleMedium),
            const SizedBox(height: 2),
            Text(section.lede, style: text.bodySmall?.copyWith(color: t.dim)),
          ],
        ),
      ),
    );
  }
}

/// One topic in the index: title, its one-line answer, a chevron; the search's words marked.
class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic, required this.words, required this.onTap, this.overline});

  final HelpTopic topic;
  final List<String> words;
  final VoidCallback onTap;
  final String? overline;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: topic.title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusSmall),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (overline != null)
                        Text(overline!, style: text.labelSmall?.copyWith(color: t.dim)),
                      Text.rich(markedSpan(topic.title, words, text.bodyLarge!, t)),
                      const SizedBox(height: 2),
                      Text.rich(
                        markedSpan(topic.short, words, text.bodySmall!.copyWith(color: t.dim), t),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: t.dim, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// [text] with every occurrence of [words] marked in the accent's soft colour.
TextSpan markedSpan(String text, List<String> words, TextStyle style, WalletTokens t) {
  if (words.isEmpty) return TextSpan(text: text, style: style);
  final low = text.toLowerCase();
  final hits = <(int, int)>[];
  for (final w in words) {
    var i = low.indexOf(w);
    while (i >= 0) {
      hits.add((i, i + w.length));
      i = low.indexOf(w, i + w.length);
    }
  }
  hits.sort((a, b) => a.$1.compareTo(b.$1));
  final spans = <TextSpan>[];
  var pos = 0;
  for (final (s, e) in hits) {
    if (s < pos) continue;
    if (s > pos) spans.add(TextSpan(text: text.substring(pos, s)));
    spans.add(TextSpan(
      text: text.substring(s, e),
      style: TextStyle(backgroundColor: t.accentSoft, color: t.text),
    ));
    pos = e;
  }
  if (pos < text.length) spans.add(TextSpan(text: text.substring(pos)));
  return TextSpan(style: style, children: spans);
}

/// Bottom of the index and of every topic: the way to say what was unclear.
class _StillStuck extends ConsumerWidget {
  const _StillStuck();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The web demo has no feedback report until a feedback proxy exists.
    if (ref.watch(demoModeProvider)) return const SizedBox.shrink();
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.helpStillStuck, style: text.titleMedium),
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
      ),
    );
  }
}

/// One topic as a page: the section as an overline, the title, the short answer, the body,
/// the handshake sheet for the handshake topic, then the section's other topics.
class HelpTopicScreen extends StatelessWidget {
  const HelpTopicScreen({super.key, required this.topic, required this.section, this.related = const []});

  final HelpTopic topic;
  final HelpSection section;
  final List<HelpTopic> related;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final body = text.bodyLarge!.copyWith(height: 1.45);
    return SlotScaffold(
      appBar: AppBar(title: Text(l.helpTitle)),
      body: ScreenBody(
        children: [
          Text(section.title, style: text.labelMedium?.copyWith(color: t.dim)),
          const SizedBox(height: 4),
          Semantics(header: true, child: Text(topic.title, style: text.headlineSmall)),
          const SizedBox(height: 8),
          Text(topic.short, style: text.bodyLarge?.copyWith(color: t.dim, height: 1.4)),
          const SizedBox(height: 12),
          Divider(height: 1, color: t.line),
          const SizedBox(height: 16),
          for (final b in topic.body) HelpBlockView(block: b, style: body),
          if (topic.handshake)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.play_circle_outline),
                label: Text(l.helpShowHandshake),
                onPressed: () => showHandshakeSheet(context),
              ),
            ),
          if (related.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(l.helpMoreInSection, style: text.titleMedium),
            const SizedBox(height: 4),
            for (final r in related)
              _TopicRow(
                topic: r,
                words: const [],
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => HelpTopicScreen(
                      topic: r,
                      section: section,
                      related: [topic, for (final x in related) if (x != r) x],
                    ),
                  ),
                ),
              ),
          ],
          const _StillStuck(),
        ],
      ),
    );
  }
}

/// A paragraph or a list of a topic's body. A term is bold; a place is a link that goes
/// there when the phone has that screen (see [openHelpPlace]), else it reads as a term.
class HelpBlockView extends StatelessWidget {
  const HelpBlockView({super.key, required this.block, required this.style});

  final HelpBlock block;
  final TextStyle style;

  TextSpan _rich(BuildContext context, String text) {
    final t = context.tokens;
    return TextSpan(
      style: style,
      children: [
        for (final p in helpInline(text))
          if (p.place && helpPlaceGoes(p.text))
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: _PlaceLink(text: p.text, style: style),
            )
          else
            TextSpan(
              text: p.text,
              style: p.term || p.place ? style.copyWith(color: t.text, fontWeight: FontWeight.w600) : null,
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = EdgeInsets.only(bottom: 12);
    if (block.kind == HelpBlockKind.p) {
      return Padding(padding: gap, child: Text.rich(_rich(context, block.text)));
    }
    final t = context.tokens;
    return Padding(
      padding: gap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, item) in block.items.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      block.kind == HelpBlockKind.ol ? '${i + 1}.' : '•',
                      style: style.copyWith(color: t.accentText, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                  Expanded(child: Text.rich(_rich(context, item))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaceLink extends StatelessWidget {
  const _PlaceLink({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      link: true,
      child: InkWell(
        onTap: () => openHelpPlace(context, text),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            text,
            style: style.copyWith(
              color: t.accentText,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              decorationColor: t.accentText.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// The screen a place's first word names: `Receive`, `Send`, `Activity`, `Outputs`,
/// `Settings`, `Node`, `Epicbox`.
String _placeRoot(String place) => place.split('›').first.trim();

/// Whether the phone can go to [place] from Help.
bool helpPlaceGoes(String place) => const {
  'Receive', 'Send', 'Activity', 'Outputs', 'Settings', 'Node', 'Epicbox',
}.contains(_placeRoot(place));

/// Goes to [place]: a shell tab closes Help; a screen opens over it; the node and Epicbox
/// pickers open as sheets.
void openHelpPlace(BuildContext context, String place) {
  switch (_placeRoot(place)) {
    case 'Receive':
      showShellTab(context, ShellTab.receive);
    case 'Send':
      showShellTab(context, ShellTab.send);
    case 'Activity':
      Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const HistoryScreen()));
    case 'Outputs':
      Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const OutputsScreen()));
    case 'Settings':
      Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    case 'Node':
      showNodePicker(context);
    case 'Epicbox':
      showEpicboxPicker(context);
  }
}
