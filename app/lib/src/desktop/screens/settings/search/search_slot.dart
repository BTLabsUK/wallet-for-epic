// SPDX-License-Identifier: Apache-2.0
/// Settings search: the field in the Settings column, the query, the keys (/ and Ctrl+K focus
/// it, ↑ ↓ move through the results, Enter goes to one, Esc clears it, then leaves Settings)
/// and the results that replace the page while the query is not empty.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../levels/wallet_level.dart';
import '../../../data/desk_levels.dart' show deskLevelControlProvider;
import '../../../desk_l10n.dart';
import '../../../widgets/kit.dart';
import '../../../widgets/more_options.dart' show moreOptionsRevealProvider;
import '../help_pairing.dart' show HelpAt;
import '../help_topics.dart';
import '../prefs.dart' show settingsPrefsProvider;
import '../settings_advanced.dart' show advancedOf;
import '../settings_help.dart' show marked;
import 'inplace_controls.dart';
import 'settings_search.dart';
import 'settings_sections.dart';

/// What the search field holds; not empty means Settings shows [SettingsSearchResults].
final settingsQueryProvider = NotifierProvider<SettingsQuery, String>(SettingsQuery.new);

class SettingsQuery extends Notifier<String> {
  @override
  String build() {
    // Going to another place (a navigation entry, Back, a link) ends the search, as picking a
    // result does: its results stand in for every page, so a click seemed to do nothing.
    ref.listen(deskNavProvider, (from, to) {
      if (from?.route != to.route || from?.arg != to.arg) state = '';
    });
    return '';
  }

  void set(String q) {
    if (q == state) return;
    state = q;
  }

  void clear() => state = '';
}

/// Bumped to focus and select the search field (Ctrl+K, /).
final settingsSearchFocusProvider = NotifierProvider<SettingsSearchFocus, int>(SettingsSearchFocus.new);

class SettingsSearchFocus extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

/// The highlighted result (↑ ↓), an index into [SetSearch]'s walking order; back to the first
/// on every new query.
final settingsSearchCursorProvider = NotifierProvider<SettingsSearchCursor, int>(SettingsSearchCursor.new);

class SettingsSearchCursor extends Notifier<int> {
  @override
  int build() {
    ref.watch(settingsQueryProvider);
    return 0;
  }

  void set(int i) => state = i;
}

/// Ctrl+K from anywhere: Settings opens (Wallet when it is not open) with the search focused.
void openSettingsSearch(WidgetRef ref) {
  final nav = ref.read(deskNavProvider);
  if (nav.route.section != DeskSection.settings) ref.read(deskNavProvider.notifier).go(DeskRoute.settingsAccount);
  ref.read(settingsSearchFocusProvider.notifier).request();
}

/// The sections with results while searching (navigation entries outside it are dimmed and
/// read "No results"); null while not searching.
final settingsSearchRoutesProvider = Provider<Set<DeskRoute>?>((ref) {
  final q = ref.watch(settingsQueryProvider);
  // Recomputed when the language changes: the synonyms are the language's.
  ref.watch(deskProvider.select((s) => s.settings.language));
  final r = searchSettings(q, l: deskStrings, view: ref.watch(setViewProvider));
  return r.words.isEmpty ? null : r.routes;
});

/// The Help topics the user's Help lists (without the pairing ones).
List<HelpTopic> _topics(WidgetRef ref) => helpTopicsShown(helpTopicsFor(deskMinConfirmations(ref), lang: deskHelpLanguage(ref)), advancedOf(ref));

/// The search of the query, as the results show it.
SetSearch _search(BuildContext context, WidgetRef ref) =>
    searchSettings(ref.watch(settingsQueryProvider), l: context.l10n, view: ref.watch(setViewProvider), topics: _topics(ref));

/// One result in walking order: a setting shown here, a Help topic, a hidden setting.
sealed class _Item {}

class _Row extends _Item {
  _Row(this.hit);
  final SetHit hit;
}

class _Topic extends _Item {
  _Topic(this.topic);
  final HelpTopic topic;
}

List<_Item> _walk(SetSearch r) => [for (final h in r.shown) _Row(h), for (final t in r.help) _Topic(t), for (final h in r.hidden) _Row(h)];

/// Goes to result [item]: its row (scrolled to, focused, flashed), its Help topic; a hidden row
/// first gets its view or switch (review 2).
Future<void> _go(BuildContext context, WidgetRef ref, _Item item) async {
  final l = context.l10n;
  final query = ref.read(settingsQueryProvider.notifier);
  switch (item) {
    case _Topic(:final topic):
      query.clear();
      ref.read(deskNavProvider.notifier).go(DeskRoute.settingsHelp, HelpAt.topic(topic.id));
    case _Row(:final hit):
      if (hit.hidden) {
        final notices = <String>[];
        if (hit.level case final lv?) {
          await ref.read(deskLevelControlProvider).setLevel(WalletLevel.ofNumber(lv)!);
          ref.read(moreOptionsRevealProvider.notifier).clear();
          notices.add(l.deskSetSearchViewApplied(setViewName(l, lv)));
        }
        // Deep end may have turned the switch on already.
        final s = ref.read(deskProvider).settings;
        var adv = s.advanced;
        for (final f in hit.features) {
          if (adv.has(f)) continue;
          adv = adv.withFeature(f, true);
          notices.add(l.deskSetSearchFeatApplied(setFeatureName(l, f)));
        }
        if (adv != s.advanced) await ref.read(deskProvider.notifier).saveSettings(s.copyWith(advanced: adv));
        if (context.mounted && notices.isNotEmpty) showEToast(context, notices.join(' · '), tone: ETone.ok);
      }
      query.clear();
      ref.read(settingsPrefsProvider.notifier).jumpToRow(hit.entry.id);
  }
}

/// A key cap: "Ctrl K", "Esc", or an arrow key's glyph.
class _Kbd extends StatelessWidget {
  const _Kbd(this.text, {this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.u, vertical: 1.u),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Rad.xs),
        border: Border.all(color: c.lineStrong),
      ),
      child: icon != null ? Icon(icon, size: 12.u, color: c.dim) : Text(text, style: context.ts.caption.copyWith(color: c.dim)),
    );
  }
}

/// The search field, under the Settings title in the Settings column.
class SettingsSearchSlot extends ConsumerStatefulWidget {
  const SettingsSearchSlot({super.key});

  /// The field itself, for tests.
  static const fieldKey = ValueKey('settings-search-field');

  @override
  ConsumerState<SettingsSearchSlot> createState() => _SettingsSearchSlotState();
}

/// The last focus request handled, so a field built later does not take the focus again.
int _focusHandled = 0;

class _SettingsSearchSlotState extends ConsumerState<SettingsSearchSlot> {
  late final _text = TextEditingController(text: ref.read(settingsQueryProvider));
  final _focus = FocusNode(debugLabel: 'settings search');

  @override
  void initState() {
    super.initState();
    _text.addListener(() => ref.read(settingsQueryProvider.notifier).set(_text.text));
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFocus(ref.read(settingsSearchFocusProvider)));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _maybeFocus(int n) {
    if (!mounted || n <= _focusHandled) return;
    _focusHandled = n;
    _focus.requestFocus();
    _text.selection = TextSelection(baseOffset: 0, extentOffset: _text.text.length);
  }

  void _move(int by) {
    final r = _search(context, ref);
    if (r.isEmpty) return;
    final cur = ref.read(settingsSearchCursorProvider.notifier);
    cur.set((ref.read(settingsSearchCursorProvider) + by).clamp(0, r.count - 1));
  }

  void _enter() {
    final items = _walk(_search(context, ref));
    if (items.isEmpty) return;
    unawaited(_go(context, ref, items[ref.read(settingsSearchCursorProvider).clamp(0, items.length - 1)]));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    ref.listen(settingsSearchFocusProvider, (_, n) => WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFocus(n)));
    // Cleared elsewhere (Esc, a result picked): the field follows.
    ref.listen(settingsQueryProvider, (_, q) {
      if (q != _text.text) _text.text = q;
    });
    final searching = ref.watch(settingsQueryProvider).isNotEmpty;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
        const SingleActivator(LogicalKeyboardKey.enter): _enter,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _enter,
      },
      child: EInput(
        key: SettingsSearchSlot.fieldKey,
        controller: _text,
        focusNode: _focus,
        line: true,
        leading: EIcons.search,
        hint: l.deskSetSearchHint,
        semanticLabel: l.deskSetSearchHint,
        trailing: searching
            ? EIconButton(icon: EIcons.close, label: l.deskSetSearchClear, size: EBtnSize.inline, onPressed: () {
                ref.read(settingsQueryProvider.notifier).clear();
                _focus.requestFocus();
              })
            : ExcludeSemantics(child: Padding(padding: EdgeInsets.only(right: Sp.x1), child: _Kbd(l.deskSetSearchKeyHint))),
      ),
    );
  }
}

/// Around the whole Settings takeover (column and page): / and Ctrl+K focus and select the
/// search; Esc clears it, and with nothing to clear in the search field calls [onLeave] (back
/// to the wallet; elsewhere the shell's own Esc does that). On
/// Help, / stays Help's own search (review 11). Nothing happens while a dialog or popover is
/// open over Settings.
class SettingsSearchKeys extends ConsumerStatefulWidget {
  const SettingsSearchKeys({super.key, required this.onLeave, required this.child});

  final VoidCallback onLeave;
  final Widget child;

  @override
  ConsumerState<SettingsSearchKeys> createState() => _SettingsSearchKeysState();
}

class _SettingsSearchKeysState extends ConsumerState<SettingsSearchKeys> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || !mounted) return false;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    final hw = HardwareKeyboard.instance;
    final ctrl = hw.isControlPressed || hw.isMetaPressed;
    final typing = FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null;
    final onHelp = ref.read(deskNavProvider).route == DeskRoute.settingsHelp;
    if ((e.logicalKey == LogicalKeyboardKey.keyK && ctrl && !hw.isAltPressed) ||
        (e.logicalKey == LogicalKeyboardKey.slash && !ctrl && !typing && !onHelp)) {
      ref.read(settingsSearchFocusProvider.notifier).request();
      return true;
    }
    return false;
  }

  /// Esc anywhere in Settings while searching clears the search (the field takes the focus
  /// back). With nothing to clear it passes on, to the shell's own Esc, except in the search
  /// field itself (the shell leaves text fields alone): there it calls [onLeave].
  KeyEventResult _onEsc(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.escape) return KeyEventResult.ignored;
    final hw = HardwareKeyboard.instance;
    if (hw.isShiftPressed || hw.isControlPressed || hw.isMetaPressed || hw.isAltPressed) return KeyEventResult.ignored;
    if (ref.read(settingsQueryProvider).isNotEmpty) {
      ref.read(settingsQueryProvider.notifier).clear();
      ref.read(settingsSearchFocusProvider.notifier).request();
      return KeyEventResult.handled;
    }
    if (_inField()) {
      widget.onLeave();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  bool _inField() {
    var inside = false;
    FocusManager.instance.primaryFocus?.context?.visitAncestorElements((e) {
      if (e.widget is SettingsSearchSlot) inside = true;
      return !inside;
    });
    return inside;
  }

  @override
  Widget build(BuildContext context) => Focus(canRequestFocus: false, skipTraversal: true, onKeyEvent: _onEsc, child: widget.child);
}

/// The results, in place of the page while the query is not empty: a count, the settings in
/// navigation order by section (the match marked, why it matched, the control where it works
/// here, else Open), Help topics, then what the view or an Advanced switch hides here.
class SettingsSearchResults extends ConsumerWidget {
  const SettingsSearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ts = context.ts;
    final r = _search(context, ref);
    final q = ref.watch(settingsQueryProvider).trim();
    final cursor = ref.watch(settingsSearchCursorProvider);
    if (r.isEmpty) return _Empty(query: q);
    final wallet = ref.watch(deskProvider.select((s) => s.account?.name));
    var i = 0;
    final blocks = <Widget>[];
    // Settings shown here, one block per section.
    for (var k = 0; k < r.shown.length;) {
      final route = r.shown[k].entry.route;
      final list = <SetHit>[];
      while (k < r.shown.length && r.shown[k].entry.route == route) {
        list.add(r.shown[k++]);
      }
      final sec = setSectionOf(route)!;
      blocks.add(_Block(
        icon: sec.icon,
        title: [if (sec.parent != null) settingsSectionLabel(l, sec.parent!), settingsSectionLabel(l, route)].join(' › '),
        aside: settingsNavLabel(l, sec.nav, walletName: wallet),
        children: [
          for (final h in list)
            _ResultRow(
              index: i,
              selected: cursor == i++,
              title: h.entry.label(l),
              text: h.entry.hint?.call(l),
              why: [if (h.via != null) l.deskSetSearchMatches(h.via!), ?h.entry.group?.call(l)].join(' · '),
              words: r.words,
              control: settingsInPlaceControl(context, ref, h.entry.id) ?? _OpenButton(label: l.deskSetSearchOpen, onPressed: () => _go(context, ref, _Row(h))),
              onTap: () => _go(context, ref, _Row(h)),
            ),
        ],
      ));
    }
    if (r.help.isNotEmpty) {
      blocks.add(_Block(
        icon: EIcons.help,
        title: l.deskSetSearchHelpTopics,
        children: [
          for (final t in r.help)
            _ResultRow(
              index: i,
              selected: cursor == i++,
              title: t.title,
              text: t.short,
              words: r.words,
              control: _OpenButton(label: l.deskSetSearchRead, onPressed: () => _go(context, ref, _Topic(t))),
              onTap: () => _go(context, ref, _Topic(t)),
            ),
        ],
      ));
    }
    if (r.hidden.isNotEmpty) {
      blocks.add(_Block(
        icon: EIcons.tune,
        title: l.deskSetSearchHidden,
        aside: l.deskSetSearchHiddenLine,
        children: [
          for (final h in r.hidden)
            _ResultRow(
              index: i,
              selected: cursor == i++,
              title: h.entry.label(l),
              text: h.entry.hint?.call(l),
              why: [settingsSectionLabel(l, h.entry.route), ?h.entry.group?.call(l)].join(' · '),
              tag: setJoinReasons(l, h.reasons),
              words: r.words,
              control: _OpenButton(
                label: h.level != null ? l.deskSetSearchShowIn(setViewName(l, h.level!)) : l.deskSetSearchTurnOn,
                onPressed: () => _go(context, ref, _Row(h)),
                chevron: false,
              ),
              onTap: () => _go(context, ref, _Row(h)),
            ),
        ],
      ));
    }
    return Semantics(
      container: true,
      label: l.deskSetSearchResults,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: Sp.x3,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Semantics(liveRegion: true, header: true, child: Text(l.deskSetSearchCount(r.count), style: ts.h2)),
              Padding(padding: EdgeInsets.only(bottom: 3.u), child: Text(l.deskSetSearchFor(q), style: ts.small)),
            ],
          ),
          SizedBox(height: Sp.x2),
          ExcludeSemantics(
            child: Wrap(
              spacing: Sp.x4,
              runSpacing: Sp.x1,
              children: [
                _keys(context, const ['', ''], l.deskSetSearchKeysMove, icons: const [EIcons.arrowUp, EIcons.arrowDown]),
                _keys(context, [l.deskSetSearchKeyEnter], l.deskSetSearchKeysGo),
                _keys(context, [l.deskSetSearchKeyEsc], l.deskSetSearchKeysClear),
              ],
            ),
          ),
          SizedBox(height: Sp.x6),
          ...blocks,
          // Room under the last block (the frame's page has its own padding).
        ],
      ),
    );
  }

  Widget _keys(BuildContext context, List<String> caps, String what, {List<IconData>? icons}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (i, k) in caps.indexed) ...[_Kbd(k, icon: icons?[i]), SizedBox(width: Sp.x1)],
      Text(what, style: context.ts.caption.copyWith(color: context.dc.dim)),
    ],
  );
}

/// Nothing found: the query, then a few words to try.
class _Empty extends ConsumerWidget {
  const _Empty({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final words = [for (final w in (DeskFeatures.tor ? l.deskSetSearchTryWords : l.deskNoTorSetSearchTryWords).split(',')) if (w.trim().isNotEmpty) w.trim()];
    return Semantics(
      liveRegion: true,
      child: EEmpty(
        icon: EIcons.search,
        title: l.deskSetSearchNone(query),
        text: l.deskSetSearchTry,
        actions: [
          for (final w in words)
            EButton(
              label: w,
              size: EBtnSize.sm,
              hit44: true,
              onPressed: () {
                ref.read(settingsQueryProvider.notifier).set(w);
                ref.read(settingsSearchFocusProvider.notifier).request();
              },
            ),
        ],
      ),
    );
  }
}

/// A block of results: the section's icon and name (and its navigation group), then the rows
/// in one enclosure, as a settings group looks.
class _Block extends StatelessWidget {
  const _Block({required this.icon, required this.title, this.aside, required this.children});

  final IconData icon;
  final String title;
  final String? aside;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Padding(
      padding: EdgeInsets.only(bottom: Sp.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: Sp.x2),
            child: Row(
              children: [
                Icon(icon, size: Ctl.iconSm, color: c.dim),
                SizedBox(width: Sp.x2),
                Flexible(child: Semantics(header: true, child: Text(title, style: ts.label))),
                // The navigation group, unless it says the same (Help › Help).
                if (aside != null && aside != title) ...[
                  SizedBox(width: Sp.x3),
                  Flexible(child: Text(aside!, style: ts.caption, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A result's Open (Read, Show in…, Turn on) button.
class _OpenButton extends StatelessWidget {
  const _OpenButton({required this.label, required this.onPressed, this.chevron = true});

  final String label;
  final VoidCallback onPressed;
  final bool chevron;

  @override
  Widget build(BuildContext context) =>
      EButton(label: label, icon: chevron ? EIcons.chevronRight : null, size: EBtnSize.sm, hit44: true, onPressed: onPressed);
}

/// One result: a settings row's look with the query's words marked (bold on a neutral
/// background, as Help marks them), why it matched, and its control. The highlighted one
/// (↑ ↓) is raised and kept in view; a click on the row goes to it.
class _ResultRow extends StatefulWidget {
  const _ResultRow({
    required this.index,
    required this.selected,
    required this.title,
    required this.words,
    required this.control,
    required this.onTap,
    this.text,
    this.why = '',
    this.tag,
  });

  final int index;
  final bool selected;
  final String title;
  final String? text;
  final String why;
  final String? tag;
  final List<String> words;
  final Widget control;
  final VoidCallback onTap;

  @override
  State<_ResultRow> createState() => _ResultRowState();
}

class _ResultRowState extends State<_ResultRow> {
  bool _hover = false;

  @override
  void didUpdateWidget(_ResultRow old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Scrollable.ensureVisible(context, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
        Scrollable.ensureVisible(context, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: Sp.x2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text.rich(marked(context, widget.title, widget.words, ts.strong)),
            if (widget.tag != null && widget.tag!.isNotEmpty) EReasonTag(widget.tag!),
          ],
        ),
        if (widget.text != null && widget.text!.isNotEmpty) ...[
          const SizedBox(height: 2),
          ConstrainedBox(constraints: BoxConstraints(maxWidth: 560.u), child: Text.rich(marked(context, widget.text!, widget.words, ts.small))),
        ],
        if (widget.why.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(widget.why, style: ts.caption),
        ],
      ],
    );
    return Semantics(
      selected: widget.selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Dur.fast,
            decoration: BoxDecoration(
              color: widget.selected ? c.s3 : (_hover ? c.hover : Colors.transparent),
              border: BorderDirectional(start: BorderSide(color: widget.selected ? c.lineStrong : Colors.transparent, width: 2)),
            ),
            padding: EdgeInsets.symmetric(horizontal: Sp.panel, vertical: Sp.x3),
            child: EBesideOrUnder(words: words, control: widget.control),
          ),
        ),
      ),
    );
  }
}
