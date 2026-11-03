// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../log.dart';
import '../../../trust_ids.dart';
import '../../widgets/kit.dart';
import '../../app/tour.dart';
import '../../desk_l10n.dart';
import '../../../l10n.dart' show localInt;
import 'prefs.dart';
import '../../data/desk_levels.dart';
import '../../data/pairing_state.dart' show deskInvoicesShownProvider;
import '../../app/now_slot.dart' show NowSlot;
import 'search/search_slot.dart';
import 'search/settings_sections.dart';
import '../../../advanced.dart' show AdvancedFeature;

/// The Settings navigation for the view: the sections of [settingsSections] in their four
/// groups (the open wallet, under its name; App; This computer; Help), each entry its icon and
/// name. A section the view hides ([deskLevelHides]) has no entry, Invoices needs a wallet that
/// takes them, and an empty group has no heading. Sub-pages have no entry of their own.
List<ESubnavGroup> settingsNavGroups(AppLocalizations l, {required String? walletName, required bool invoices, required DeskLevelFeatures ui}) => [
  for (final nav in SetNav.values)
    if ([
      for (final s in settingsSections)
        if (s.nav == nav && s.parent == null && !deskLevelHides(ui, s.route) && (s.route != DeskRoute.settingsInvoices || invoices))
          (s.route as Object, settingsSectionLabel(l, s.route), s.icon),
    ] case final items when items.isNotEmpty)
      ESubnavGroup(heading: settingsNavLabel(l, nav, walletName: walletName == null || walletName.isEmpty ? null : walletName), items: items),
];

/// The page a sub-page belongs to: its entry stays selected and the page shows "‹ Parent".
DeskRoute? settingsParent(DeskRoute route) => setSectionOf(route)?.parent;

/// The name of a Settings page, as its title and its entry say it.
String settingsPageTitle(AppLocalizations l, DeskRoute route) =>
    settingsSectionLabel(l, route == DeskRoute.settingsLevel ? DeskRoute.settingsAdvanced : route);

/// Whether the window shows the Settings column in place of the sidebar (the sidebar's own
/// desktop width); narrower, the page keeps the section strip.
bool settingsTakeover(BuildContext context) => MediaQuery.sizeOf(context).width >= Bp.desktop;

/// The entry a page raises: its own, or its parent's for a sub-page.
DeskRoute settingsCurrent(DeskRoute route) => route == DeskRoute.settingsLevel ? DeskRoute.settingsAdvanced : setNavRouteOf(route);

/// The Settings column (option 1, the takeover): "← Wallet" and "Settings", the search field,
/// the grouped navigation, and at its foot what runs now and the Esc hint. It stands where the
/// sidebar is while a Settings page is open.
class SettingsColumn extends ConsumerWidget {
  const SettingsColumn({super.key, required this.route});

  final DeskRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final nav = ref.read(deskNavProvider.notifier);
    final ui = ref.watch(deskLevelUiProvider);
    final name = ref.watch(deskProvider.select((s) => s.account?.name));
    final groups = settingsNavGroups(l, walletName: name, invoices: ref.watch(deskInvoicesShownProvider), ui: ui);
    final matches = ref.watch(settingsSearchRoutesProvider);
    return Semantics(
      container: true,
      label: l.deskSetFrameSections,
      child: Container(
        width: Ctl.settingsNav,
        decoration: BoxDecoration(color: c.s1, border: Border(right: BorderSide(color: c.line))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(Sp.x3, Sp.x3, Sp.x3, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: EButton.ghost(
                  key: settingsBackKey,
                  label: l.deskSetFrameBack,
                  icon: EIcons.arrowLeft,
                  tooltip: l.deskSetFrameBackTip,
                  hit44: true,
                  onPressed: nav.leaveSettings,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Sp.x4, Sp.x2, Sp.x4, Sp.x3),
              // The tour lights it as the place it shows (the sidebar's Settings entry is gone here).
              child: TourTarget(
                id: 'nav-settings',
                child: Semantics(header: true, child: Text(l.deskSetFrameTitle, style: ts.h2, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ),
            ),
            Padding(padding: EdgeInsets.symmetric(horizontal: Sp.x3), child: const SettingsSearchSlot()),
            Expanded(
              // Its own scroll: a short window holds more entries than fit.
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(Sp.x3, Sp.x3, Sp.x3, Sp.x3),
                child: ESubnav(
                  groups: groups,
                  current: settingsCurrent(route),
                  matches: matches,
                  noMatchLabel: l.deskSetSearchNoResults,
                  onTap: (r) => nav.go(r as DeskRoute),
                  idOf: (r) => TrustIds.settingsSection((r as DeskRoute).name),
                  wrap: (r, w) => TourTarget(id: 'subnav-${(r as DeskRoute).name}', child: w),
                ),
              ),
            ),
            // What goes on now (a scan, a payment, an update), as the sidebar's slot says it.
            const NowSlot(compact: false, resting: false),
            Container(
              padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: Row(
                children: [
                  _Kbd(l.deskSetFrameEscKey),
                  SizedBox(width: Sp.x2),
                  Flexible(child: Text(l.deskSetFrameEscHint, style: ts.caption.copyWith(color: c.dim), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Settings column's "← Wallet", for tests.
const settingsBackKey = ValueKey('settings-back');

/// A key as the keyboard shows it.
class _Kbd extends StatelessWidget {
  const _Kbd(this.keys);

  final String keys;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.u, vertical: 1.u),
      decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.xs), border: Border.all(color: c.lineStrong)),
      child: Text(keys, style: context.ts.mono(size: Fs.xs, color: c.text)),
    );
  }
}

/// How far a Settings page grows on a big screen. Every page grows with the window up to a
/// measure for its content: [form] pages (rows of words and controls, text) up to [Ctl.mid], so
/// a row's words and its control stay together and text lines stay short (a row's text is
/// capped at 560 u anyway); a page with [wide] content (the node panel's facts, tiles, charts
/// and peers table) takes the room up to [settingsWideMax], its panel laying status and
/// details side by side. Below those widths both fill the column, down to a narrow window.
enum SettingsWidth { form, wide }

/// The widest a [SettingsWidth.wide] page gets (a 4K window still reads as one panel).
double get settingsWideMax => 1760.u;

/// A Settings page: its title (with "‹ Parent" above it on a sub-page) and the page, centred
/// up to its measure. Beside the Settings column ([settingsTakeover]) the page has the room to
/// itself; in a narrower window the title is "Settings" and the sections are a strip of chips
/// over the page. While the Settings search has a query, its results stand in for the page.
class SettingsFrame extends ConsumerWidget {
  const SettingsFrame({super.key, required this.route, required this.child, this.width = SettingsWidth.form, this.fill = false});

  final DeskRoute route;
  final Widget child;
  final SettingsWidth width;

  /// [child] gets the page's height instead of scrolling in it, so it can keep parts of its own
  /// in view ([EPhraseLayout]: only the words scroll). With less room than [fillMinHeight] it
  /// scrolls.
  final bool fill;

  /// The room [fill] needs: the Recovery phrase heading, actions and warning, and two rows of
  /// words.
  static double get fillMinHeight => 320.u;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(deskNavProvider.notifier);
    final l = context.l10n;
    final takeover = settingsTakeover(context);
    final searching = ref.watch(settingsQueryProvider).trim().isNotEmpty;
    final parent = settingsParent(route);
    final back = parent == null || searching
        ? null
        : Padding(
            padding: EdgeInsets.only(bottom: Sp.x3),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: EButton.ghost(
                key: settingsParentKey,
                label: settingsPageTitle(l, parent),
                icon: EIcons.chevronLeft,
                size: EBtnSize.inline,
                hit44: true,
                tooltip: l.deskSetFrameBackTo(settingsPageTitle(l, parent)),
                onPressed: () => nav.go(parent),
              ),
            ),
          );
    final fills = fill && !searching;
    Widget page() => fills
        ? LayoutBuilder(
            builder: (context, box) => box.maxHeight < fillMinHeight ? SingleChildScrollView(child: child) : child,
          )
        : (searching ? const SettingsSearchResults() : child);
    // A big window centres the capped column instead of leaving it at the left.
    Widget measure(Widget w) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: width == SettingsWidth.wide ? settingsWideMax : Ctl.mid), child: w),
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: fills ? MainAxisSize.max : MainAxisSize.min,
      children: [?back, if (fills) Expanded(child: page()) else page()],
    );
    final title = searching ? l.deskSetFrameTitle : settingsPageTitle(l, route);
    // Linked devices is an experiment at every view (item 10): the tag and its ⓘ by the title.
    final tag = route == DeskRoute.settingsDevices && !searching
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              EBadge(l.deskSetFrameExperiment, key: const ValueKey('settings-experiment-tag')),
              SizedBox(width: Sp.x1),
              EInfoHint(l.expLinkedDevicesHint, title: l.expLinkedDevices, icon: EIcons.devices),
            ],
          )
        : null;
    if (takeover) {
      return EPage(
        title: title,
        titleTrailing: tag,
        width: EPageWidth.full,
        scroll: !fills,
        child: measure(body),
      );
    }
    final ui = ref.watch(deskLevelUiProvider);
    final name = ref.watch(deskProvider.select((s) => s.account?.name));
    final groups = settingsNavGroups(l, walletName: name, invoices: ref.watch(deskInvoicesShownProvider), ui: ui);
    return EPage(
      title: l.deskSetFrameTitle,
      width: EPageWidth.full,
      scroll: !fills,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: fills ? MainAxisSize.max : MainAxisSize.min,
        children: [
          const SettingsSearchSlot(),
          _SectionStrip(
            items: [for (final g in groups) ...g.items.map((i) => (i.$1 as DeskRoute, i.$2, i.$3))],
            current: settingsCurrent(route),
            onTap: nav.go,
          ),
          SizedBox(height: Sp.x6),
          if (tag != null) Padding(padding: EdgeInsets.only(bottom: Sp.x3), child: Align(alignment: AlignmentDirectional.centerStart, child: tag)),
          if (fills) Expanded(child: measure(body)) else measure(body),
        ],
      ),
    );
  }
}

/// A sub-page's "‹ Parent", for tests.
const settingsParentKey = ValueKey('settings-parent');

/// 2914414 → "2,914,414".
String groupDigits(AppLocalizations l, int n) => localInt(l, n);

/// A section a sidebar status row jumps to: scrolled into view, its heading focused and a thin
/// gold outline that fades out over a second (none with reduced motion); again on every new
/// jump to it ([SettingsPrefsController.jumpTo]). Opening the page any other way shows nothing.
class JumpSection extends ConsumerStatefulWidget {
  const JumpSection({super.key, required this.section, required this.child});

  final SettingsJump section;
  final Widget child;

  @override
  ConsumerState<JumpSection> createState() => _JumpSectionState();
}

/// The last jump handled, so a page opened later does not flash again.
int _jumpHandled = 0;

class _JumpSectionState extends ConsumerState<JumpSection> with SingleTickerProviderStateMixin {
  final _focus = FocusNode(debugLabel: 'jump target');
  // 1 → 0: the outline's strength. Held a moment, then eased out.
  late final _cue = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000), value: 0);
  late final _fade = CurvedAnimation(parent: _cue, curve: const Interval(0, 0.75, curve: Curves.easeInCubic));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybe(ref.read(settingsPrefsProvider).jump));
  }

  @override
  void dispose() {
    _fade.dispose();
    _cue.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _maybe(JumpTo? j) {
    if (!mounted || j == null || j.section != widget.section || j.n <= _jumpHandled) return;
    _jumpHandled = j.n;
    final reduce = MediaQuery.of(context).disableAnimations;
    Scrollable.ensureVisible(context, duration: reduce ? Duration.zero : Dur.base, alignment: 0);
    _focus.requestFocus();
    if (!reduce) _cue.reverse(from: 1);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsPrefsProvider.select((p) => p.jump), (_, j) => WidgetsBinding.instance.addPostFrameCallback((_) => _maybe(j)));
    final c = context.dc;
    return Focus(
      focusNode: _focus,
      skipTraversal: true,
      child: AnimatedBuilder(
        animation: _fade,
        builder: (_, child) => DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: _fade.value == 0
              ? const BoxDecoration()
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(Rad.sm),
                  border: Border.all(color: c.accent.withValues(alpha: c.accent.a * 0.8 * _fade.value), width: 1.5),
                ),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// A page-sized placeholder while the wallet snapshot loads.
class SettingsLoading extends StatelessWidget {
  const SettingsLoading({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: Sp.x16),
    child: Center(child: ESpinner(size: 24.u)),
  );
}

/// The mock's clock (its times are anchored here).
final _mockNow = DateTime(2026, 10, 21, 14, 30);

String ago(AppLocalizations l, DateTime? t) {
  if (t == null) return l.deskSetFrameNever;
  final d = _mockNow.difference(t);
  if (d.inMinutes < 1) return l.deskSetFrameJustNow;
  if (d.inMinutes < 60) return l.deskSetFrameMinAgo(d.inMinutes);
  if (d.inHours < 24) return l.deskSetFrameHoursAgo(d.inHours);
  return l.deskSetFrameDaysAgo(d.inDays);
}

/// Copies [url]; false when the clipboard refused it twice. On Windows another program can
/// hold the clipboard for a moment (PlatformException), so a refusal is tried once more.
Future<bool> copyLink(String url) async {
  for (var attempt = 1; ; attempt++) {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      return true;
    } on PlatformException catch (e) {
      logWarn('desk', 'copy refused (attempt $attempt): ${e.code}');
      if (attempt == 2) return false;
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }
}

/// A strip entry for the narrow layout.
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.selected, required this.onTap, this.semanticsId});

  final String? semanticsId;

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return TrustId(semanticsId, child: Semantics(
      button: true,
      selected: selected,
      child: EInkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Rad.sm),
        child: NoSelect(
        child: Container(
          height: Ctl.sm,
          padding: EdgeInsets.symmetric(horizontal: Sp.x3),
          decoration: BoxDecoration(
            color: selected ? c.s3 : null,
            borderRadius: BorderRadius.circular(Rad.sm),
            border: Border.all(color: selected ? c.lineStrong : c.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: Ctl.iconSm, color: selected ? c.accentText : c.dim),
              SizedBox(width: Sp.x2),
              Text(label, style: context.ts.body.copyWith(color: selected ? c.text : c.dim)),
            ],
          ),
        ),
        ),
      ),
    ));
  }
}

/// The narrow window's section chips: they wrap onto a second row; where two rows are not
/// enough, a dropdown lists every section, so none hides behind an edge.
class _SectionStrip extends StatelessWidget {
  const _SectionStrip({required this.items, required this.current, required this.onTap});

  final List<(DeskRoute, String, IconData)> items;
  final DeskRoute current;
  final void Function(DeskRoute) onTap;

  int _rows(BuildContext context, double room) {
    final style = context.ts.body;
    var rows = 1;
    var used = 0.0;
    for (final i in items) {
      final tp = TextPainter(
        text: TextSpan(text: i.$2, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final w = 2 * Sp.x3 + Ctl.iconSm + Sp.x2 + tp.width + 2 + Sp.x2;
      tp.dispose();
      if (used > 0 && used + w - Sp.x2 > room) {
        rows++;
        used = 0;
      }
      used += w;
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth.isFinite && _rows(context, box.maxWidth) > 2) {
        return ESelect<DeskRoute>(
          items: [for (final i in items) ESelectItem<DeskRoute>(i.$1, i.$2, leading: Icon(i.$3, size: Ctl.iconSm))],
          value: items.any((i) => i.$1 == current) ? current : items.first.$1,
          onChanged: onTap,
        );
      }
      return Wrap(
        spacing: Sp.x2,
        runSpacing: Sp.x2,
        children: [for (final i in items) _Chip(semanticsId: TrustIds.settingsSection(i.$1.name), icon: i.$3, label: i.$2, selected: i.$1 == current, onTap: () => onTap(i.$1))],
      );
    });
  }
}

/// What shows a row hidden here, as its marker and the ⇕ control say it: "Advanced › Logs".
String advancedByFeature(AppLocalizations l, AdvancedFeature f) => l.deskSetSearchFeatGate(setFeatureName(l, f));

/// "Deep end view", "Deeper view" (1 Shallow, 2 Deeper, 3 Deep end).
String advancedByView(AppLocalizations l, int level) => l.deskSetSearchViewGate(setViewName(l, level));
