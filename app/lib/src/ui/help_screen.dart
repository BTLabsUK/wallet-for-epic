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
import '../help/help_i18n.dart';
import '../l10n.dart';
import '../phone_tor.dart';
import '../providers.dart';
import '../settings.dart';
import 'common.dart';
import 'feedback_screen.dart';
import 'handshake.dart';
import 'help_language_switch.dart';
import 'info_hint.dart';
import 'contacts_screen.dart';
import 'history_screen.dart';
import 'invoices_screen.dart';
import 'outputs_screen.dart';
import 'settings_screen.dart';
import 'theme/advanced.dart';
import 'theme/tokens.dart';
import 'tor_ui.dart';
import 'tour/phone_tour.dart';

export '../help/help_content.dart' show HelpId;

/// Days after which a send that was never completed cancels itself: the old core set a time
/// to live of 20160 blocks, at one block a minute. The Send tracker's copy still quotes it.
const int sendTtlDays = 14;

/// The key of the search field, for tests.
const Key helpSearchKey = ValueKey('help-search');

/// The topics this wallet shows in [lang], the help language: the shared set for the phone, the
/// Pairing topics when the wallet pairs, Tor only when the phone has it. A topic
/// [lang] has no translation of is English.
List<HelpTopic> phoneHelpTopics(BuildContext context, WidgetRef ref, String lang) {
  final confirmations = confirmationsTargetOf(ref);
  final pairs = ref.watch(sessionProvider)?.pairing.supported ?? false;
  final tor = ref.watch(phoneTorProvider.select(torShown));
  return [
    // The topics of a part Advanced hides go with it (Outputs).
    ...helpTopicsShown(
      localizedHelpTopics(lang, confirmations, platform: HelpPlatform.phone, tor: tor),
      AdvancedOptions.of(context),
    ),
    if (pairs) ...pairingHelpTopics(helpStrings(lang), platform: HelpPlatform.phone),
  ];
}

/// The sections in [lang], in the order the index shows them: Pairing before "When something
/// goes wrong", and only when a topic uses it.
List<HelpSection> _sectionsFor(List<HelpTopic> topics, String lang) {
  final l = helpStrings(lang);
  final used = topics.map((t) => t.section).toSet();
  final out = <HelpSection>[];
  for (final s in localizedHelpSections(lang)) {
    if (s.id == 'trouble' && used.contains(pairingHelpSection)) {
      out.add((id: pairingHelpSection, title: l.helpPairingSection, lede: l.helpPairingLede, art: ''));
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

  void _openTopic(HelpTopic topic, List<HelpTopic> all, String lang) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HelpTopicScreen(
          topic: topic,
          section: _sectionsFor(all, lang).firstWhere((s) => s.id == topic.section),
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
    final lang = phoneHelpLanguage(ref, context);
    final topics = phoneHelpTopics(context, ref, lang);
    final sections = _sectionsFor(topics, lang);
    if (!_opened && widget.topic != null) {
      // The topic's page goes over the index on arrival, so Back lands on the index.
      _opened = true;
      final t = topics.where((t) => t.id == widget.topic).firstOrNull;
      if (t != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openTopic(t, topics, lang);
        });
      }
    }
    final words = helpQueryWords(_query.text);
    final searching = words.isNotEmpty;
    final hits = searching ? [for (final x in topics) if (helpMatches(x, words)) x] : topics;
    // Nobody has written the help in this language yet: it shows in English.
    final english = !helpTranslated(lang);

    Widget row(HelpTopic topic, {bool section = false}) => _TopicRow(
      topic: topic,
      words: words,
      overline: section ? sections.firstWhere((s) => s.id == topic.section).title : null,
      onTap: () => _openTopic(topic, topics, lang),
    );

    return SlotScaffold(
      appBar: AppBar(
        title: Text(l.helpTitle),
        actions: [
          HelpLanguageSwitch(current: lang),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Send feedback first, above the topics and the search: the one thing a
                // stuck user needs most, one tap from Settings.
                const PhoneTourTarget(id: 'tour-help-feedback', child: _FeedbackRow()),
                PhoneTourTarget(
                  id: 'tour-help-search',
                  child: Padding(
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
                      if (!searching) const _ShowTipsAgain(),
                      if (!searching) const _ShowTourAgain(),
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

/// The key of the Send feedback row at the top of Help, for tests.
const Key helpFeedbackKey = ValueKey('help-feedback');

/// The key of the Show tips again row, for tests.
const Key helpShowTipsKey = ValueKey('help-show-tips');

/// Send feedback at the top of Help: a row with the explanation behind its info icon and a
/// hairline under it. Not in the web demo, which has no feedback report.
class _FeedbackRow extends ConsumerWidget {
  const _FeedbackRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(demoModeProvider)) return const SizedBox.shrink();
    final l = context.l10n;
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
      child: ListTile(
        key: helpFeedbackKey,
        leading: Icon(Icons.feedback_outlined, color: t.accentText),
        title: TitleWithHint(
          l.settingsSendFeedback,
          hint: l.settingsSendFeedbackHint,
          icon: Icons.feedback_outlined,
        ),
        trailing: Icon(Icons.chevron_right, color: t.dim),
        onTap: () => openFeedback(context),
      ),
    );
  }
}

/// The key of the Show the tour again row, for tests.
const Key helpShowTourKey = ValueKey('help-show-tour');

/// Show the tour again: opens the first-unlock tour from its first step.
class _ShowTourAgain extends ConsumerWidget {
  const _ShowTourAgain();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    key: helpShowTourKey,
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.tour_outlined),
    title: Text(context.l10n.tourPhoneShowAgain),
    onTap: () => startPhoneTour(ref),
  );
}

/// Show tips again: brings back every inline guide closed with its X. Off while none is
/// hidden.
class _ShowTipsAgain extends ConsumerWidget {
  const _ShowTipsAgain();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final hidden = ref.watch(tipsHiddenProvider);
    return ListTile(
      key: helpShowTipsKey,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.lightbulb_outline),
      title: Text(l.settingsShowTipsAgain),
      enabled: hidden,
      onTap: hidden
          ? () async {
              await ref.read(appSettingsProvider.notifier).showTipsAgain();
              ref.read(noticeProvider.notifier).show(l.settingsShowTipsAgainDone, level: NoticeLevel.success);
            }
          : null,
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
          if (p.place && helpPlaceGoes(p.target, prefs: AdvancedOptions.of(context)))
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: _PlaceLink(text: p.text, target: p.target, style: style),
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
  const _PlaceLink({required this.text, required this.target, required this.style});

  /// What the link says, and the English place it goes to.
  final String text;
  final String target;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      link: true,
      child: InkWell(
        onTap: () => openHelpPlace(context, target),
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

/// Where a place in Help goes on the phone.
enum HelpPhonePlace { receive, send, activity, outputs, contacts, invoices, settings, security, privacyNetwork, wallet, transactions, display, about }

/// The rows of each Settings page that Help names: `Settings › Wallet › Recheck balance`.
const _settingsPlaces = <String, (HelpPhonePlace, Set<String>)>{
  'Security': (HelpPhonePlace.security, {'Back up recovery phrase'}),
  'Privacy & network': (HelpPhonePlace.privacyNetwork, {'Tor Network', 'Node', 'Epicbox'}),
  'Wallet': (HelpPhonePlace.wallet, {'Export history backup', 'Recheck balance', 'Invoices'}),
  'Transactions': (HelpPhonePlace.transactions, {'Send defaults'}),
  'Display': (HelpPhonePlace.display, <String>{}),
  'About': (HelpPhonePlace.about, <String>{}),
};

/// The sub-places of the screens Help names, under their first word.
const _screenPlaces = <String, (HelpPhonePlace, Set<String>)>{
  'Receive': (HelpPhonePlace.receive, {'Direct · File', 'Direct · QR'}),
  'Send': (HelpPhonePlace.send, <String>{}),
  'Activity': (HelpPhonePlace.activity, <String>{}),
  'Outputs': (HelpPhonePlace.outputs, {'Manage outputs'}),
  'Contacts': (HelpPhonePlace.contacts, <String>{}),
  'Invoices': (HelpPhonePlace.invoices, {'To pay', 'Requests you sent'}),
};

/// The screen the phone shows for [place] (the English place a help link carries), or null when
/// it has none: such a place must not be written as a link.
HelpPhonePlace? helpPlaceDestination(String place) {
  final parts = [for (final p in place.split('›')) p.trim()];
  final root = parts.first;
  if (root == 'Settings') {
    if (parts.length == 1) return HelpPhonePlace.settings;
    final page = _settingsPlaces[parts[1]];
    if (page == null || parts.length > 3) return null;
    if (parts.length == 3 && !page.$2.contains(parts[2])) return null;
    return page.$1;
  }
  final screen = _screenPlaces[root];
  if (screen == null || parts.length > 2) return null;
  if (parts.length == 2 && !screen.$2.contains(parts[1])) return null;
  return screen.$1;
}

/// Whether the phone can go to [place] from Help: it has the screen, and Advanced ([prefs],
/// everything when not given) shows it: Outputs needs the Outputs switch. A place of a hidden
/// part reads as a term instead of a link.
bool helpPlaceGoes(String place, {AdvancedPrefs? prefs}) {
  final to = helpPlaceDestination(place);
  if (to == null) return false;
  if (prefs == null) return true;
  return to != HelpPhonePlace.outputs || prefs.has(AdvancedFeature.outputs);
}

/// Goes to [place]: a shell tab closes Help; a screen or a Settings page opens over it.
void openHelpPlace(BuildContext context, String place) {
  final navigator = Navigator.of(context);
  switch (helpPlaceDestination(place)) {
    case null:
      return;
    case HelpPhonePlace.receive:
      showShellTab(context, ShellTab.receive);
    case HelpPhonePlace.send:
      showShellTab(context, ShellTab.send);
    case HelpPhonePlace.activity:
      navigator.push<void>(MaterialPageRoute<void>(builder: (_) => const HistoryScreen()));
    case HelpPhonePlace.outputs:
      navigator.push<void>(MaterialPageRoute<void>(builder: (_) => const OutputsScreen()));
    case HelpPhonePlace.contacts:
      navigator.push<void>(MaterialPageRoute<void>(builder: (_) => const ContactsScreen()));
    case HelpPhonePlace.invoices:
      navigator.push<void>(MaterialPageRoute<void>(builder: (_) => const InvoicesScreen()));
    case HelpPhonePlace.settings:
      navigator.push<void>(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    case HelpPhonePlace.security:
      openSettingsSection(context, SettingsSection.security);
    case HelpPhonePlace.privacyNetwork:
      openSettingsSection(context, SettingsSection.privacyNetwork);
    case HelpPhonePlace.wallet:
      openSettingsSection(context, SettingsSection.wallet);
    case HelpPhonePlace.transactions:
      openSettingsSection(context, SettingsSection.transactions);
    case HelpPhonePlace.display:
      openSettingsSection(context, SettingsSection.display);
    case HelpPhonePlace.about:
      openSettingsSection(context, SettingsSection.about);
  }
}
