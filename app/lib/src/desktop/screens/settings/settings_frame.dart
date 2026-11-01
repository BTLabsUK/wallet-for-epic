// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../log.dart';
import '../../widgets/kit.dart';
import '../../app/tour.dart';
import '../../desk_l10n.dart';
import '../../../l10n.dart' show localInt;
import '../../../ui/network_mode_text.dart' show networkSummary;
import 'prefs.dart';
import '../../data/desk_levels.dart';
import '../../data/pairing_state.dart' show deskInvoicesShownProvider;

/// The sections; [invoices] adds Invoices below Transactions (wallets that take invoices), its label
/// in the app's language. Linked devices has no entry of its own: it belongs to one wallet, so it
/// opens from This wallet (as on the phone) and that entry stays raised on its page.
/// Shallow lists six: Appearance, This wallet, Recovery phrase, Advanced, About, Help
/// (Recheck balance opens from This wallet there).
List<(DeskRoute, String, IconData)?> _itemsFor(AppLocalizations l, {required bool invoices, required DeskLevelFeatures ui}) => [
  if (!deskLevelHides(ui, DeskRoute.settingsNode)) (DeskRoute.settingsNode, l.deskSetFrameNode, EIcons.node),
  if (!deskLevelHides(ui, DeskRoute.settingsReceiving)) (DeskRoute.settingsReceiving, l.deskSetFrameTransactions, EIcons.antenna),
  if (!deskLevelHides(ui, DeskRoute.settingsPrivacy)) (DeskRoute.settingsPrivacy, l.settingsSectionNetworkPrivacy, EIcons.network),
  if (invoices && ui.invoicesPage) (DeskRoute.settingsInvoices, l.deskInvSetTitle, EIcons.invoice),
  (DeskRoute.settingsAppearance, l.deskSetFrameAppearance, EIcons.palette),
  null,
  (DeskRoute.settingsAccount, l.deskSetFrameThisWallet, EIcons.wallet),
  if (!deskLevelHides(ui, DeskRoute.settingsWallets)) (DeskRoute.settingsWallets, l.deskSetFrameAllWallets, EIcons.coins),
  (DeskRoute.settingsPhrase, l.deskSetFramePhrase, EIcons.key),
  if (ui.recheckInSideList) (DeskRoute.settingsRescan, l.deskSetFrameRescan, EIcons.scan),
  null,
  (DeskRoute.settingsAdvanced, l.deskSetFrameAdvanced, EIcons.tune),
  null,
  (DeskRoute.settingsAbout, l.deskSetFrameAbout, EIcons.info),
  (DeskRoute.settingsHelp, l.deskSetFrameHelp, EIcons.help),
];

/// How far a Settings page grows on a big screen. Every page grows with the window up to a
/// measure for its content: [form] pages (rows of words and controls, text) up to [Ctl.mid], so
/// a row's words and its control stay together and text lines stay short (a row's text is
/// capped at 560 u anyway); a page with [wide] content (the node panel's facts, tiles, charts
/// and peers table) takes the room up to [settingsWideMax], its panel laying status and
/// details side by side. Below those widths both fill the column, down to a narrow window.
enum SettingsWidth { form, wide }

/// The widest a [SettingsWidth.wide] page gets (a 4K window still reads as one panel).
double get settingsWideMax => 1760.u;

/// The Settings page: title, sub-navigation on the left (a scrolling strip while the page is narrower than Lay.xl)
/// and the page on the right.
class SettingsFrame extends ConsumerWidget {
  const SettingsFrame({super.key, required this.route, required this.child, this.width = SettingsWidth.form});

  final DeskRoute route;
  final Widget child;
  final SettingsWidth width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(deskNavProvider.notifier);
    final l = context.l10n;
    final ui = ref.watch(deskLevelUiProvider);
    final items = _itemsFor(l, invoices: ref.watch(deskInvoicesShownProvider), ui: ui);
    // Network & privacy says how the wallet connects under its entry, as the phone's hub row.
    final net = ref.watch(deskProvider.select((s) => (s.settings.advanced.networkMode, s.settings.tor, s.status?.torIncluded ?? true)));
    final details = <Object, String>{
      DeskRoute.settingsPrivacy: networkSummary(l, net.$1, torOn: net.$2, tor: DeskFeatures.tor && net.$3),
    };
    // Linked devices is a page of This wallet, and so is Recheck balance at Shallow; Change
    // level is Advanced's.
    final current = route == DeskRoute.settingsDevices || (route == DeskRoute.settingsRescan && !ui.recheckInSideList)
        ? DeskRoute.settingsAccount
        : route == DeskRoute.settingsLevel
        ? DeskRoute.settingsAdvanced
        : route;
    // A big window centres the capped column instead of leaving it at the left.
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: width == SettingsWidth.wide ? settingsWideMax : Ctl.mid), child: child),
    );
    // The section list goes beside the page only when the page itself (the room EPage leaves
    // inside its gutters) is Lay.xl wide; a 1000 px window with the sidebar gets the strip.
    return LayoutBuilder(builder: (context, box) {
    final wide = box.maxWidth - 2 * Sp.x8 >= Lay.xl;
    return EPage(
      title: l.deskSetFrameTitle,
      width: EPageWidth.full,
      // Wide: the section list stays in view while the page scrolls (a Help topic far down
      // keeps Help selected beside it).
      scroll: !wide,
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 232.u,
                  // Its own scroll: a short window holds more sections than fit.
                  child: SingleChildScrollView(
                  child: Semantics(
                    label: l.deskSetFrameSections,
                    child: ESubnav(
                      items: items,
                      current: current,
                      details: details,
                      onTap: (r) => nav.go(r as DeskRoute),
                      wrap: (r, w) => TourTarget(id: 'subnav-${(r as DeskRoute).name}', child: w),
                    ),
                  ),
                  ),
                ),
                SizedBox(width: Sp.x8),
                Expanded(child: SingleChildScrollView(child: content)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionStrip(
                  items: [for (final i in items.whereType<(DeskRoute, String, IconData)>()) i],
                  current: current,
                  onTap: nav.go,
                ),
                SizedBox(height: Sp.x6),
                content,
              ],
            ),
    );
    });
  }
}

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
  const _Chip({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
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
    );
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
        children: [for (final i in items) _Chip(icon: i.$3, label: i.$2, selected: i.$1 == current, onTap: () => onTap(i.$1))],
      );
    });
  }
}
