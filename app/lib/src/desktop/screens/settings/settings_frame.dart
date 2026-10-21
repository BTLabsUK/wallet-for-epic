import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'prefs.dart';

const List<(DeskRoute, String, IconData)?> _items = [
  (DeskRoute.settingsNode, 'Node', EIcons.node),
  (DeskRoute.settingsReceiving, 'Receiving', EIcons.antenna),
  (DeskRoute.settingsAppearance, 'Appearance', EIcons.palette),
  null,
  (DeskRoute.settingsAccount, 'This wallet', EIcons.wallet),
  if (DeskFeatures.multiWallet) (DeskRoute.settingsWallets, 'All wallets', EIcons.coins),
  (DeskRoute.settingsPhrase, 'Recovery phrase', EIcons.key),
  (DeskRoute.settingsRescan, 'Rescan', EIcons.scan),
  null,
  (DeskRoute.settingsAbout, 'About', EIcons.info),
  (DeskRoute.settingsHelp, 'Help', EIcons.help),
];

/// The Settings page: title, sub-navigation on the left (a scrolling strip below 1000 px)
/// and the page on the right.
class SettingsFrame extends ConsumerWidget {
  const SettingsFrame({super.key, required this.route, required this.child});

  final DeskRoute route;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.read(deskNavProvider.notifier);
    final wide = MediaQuery.sizeOf(context).width >= Bp.desktop;
    final content = ConstrainedBox(constraints: BoxConstraints(maxWidth: Ctl.narrow), child: child);
    return EPage(
      title: 'Settings',
      width: EPageWidth.full,
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 200.u,
                  child: Semantics(
                    label: 'Settings sections',
                    child: ESubnav(items: _items, current: route, onTap: (r) => nav.go(r as DeskRoute)),
                  ),
                ),
                SizedBox(width: Sp.x8),
                Expanded(child: content),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final i in _items.whereType<(DeskRoute, String, IconData)>())
                        Padding(
                          padding: EdgeInsets.only(right: Sp.x2),
                          child: _Chip(icon: i.$3, label: i.$2, selected: i.$1 == route, onTap: () => nav.go(i.$1)),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: Sp.x6),
                content,
              ],
            ),
    );
  }
}

String healthWord(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => 'Online',
  ServiceHealth.slow => 'Slow',
  ServiceHealth.down => 'Not responding',
  ServiceHealth.off => 'Off',
  ServiceHealth.checking => 'Checking…',
};

/// The node's state word (6.1.6 nodeBadge): Online, Syncing, Not responding.
String nodeWord(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => 'Online',
  ServiceHealth.slow => 'Syncing',
  ServiceHealth.down => 'Not responding',
  ServiceHealth.off => 'Off',
  ServiceHealth.checking => 'Connecting…',
};

/// The Epicbox listener's state word.
String epicboxWord(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => 'Listening',
  ServiceHealth.slow || ServiceHealth.checking => 'Connecting…',
  ServiceHealth.down => 'Not responding',
  ServiceHealth.off => 'Off',
};

/// 2914414 → "2,914,414".
String groupDigits(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// A section a sidebar status row jumps to: scrolled into view, flashed for 1.8 s, its
/// heading focused; again on every new jump to it ([SettingsPrefsController.jumpTo]).
class JumpSection extends ConsumerStatefulWidget {
  const JumpSection({super.key, required this.section, required this.child});

  final SettingsJump section;
  final Widget child;

  @override
  ConsumerState<JumpSection> createState() => _JumpSectionState();
}

/// The last jump handled, so a page opened later does not flash again.
int _jumpHandled = 0;

class _JumpSectionState extends ConsumerState<JumpSection> {
  final _focus = FocusNode(debugLabel: 'jump target');
  bool _flash = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybe(ref.read(settingsPrefsProvider).jump));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _maybe(JumpTo? j) {
    if (!mounted || j == null || j.section != widget.section || j.n <= _jumpHandled) return;
    _jumpHandled = j.n;
    final reduce = MediaQuery.of(context).disableAnimations;
    Scrollable.ensureVisible(context, duration: reduce ? Duration.zero : Dur.base, alignment: 0);
    _focus.requestFocus();
    setState(() => _flash = true);
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _flash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsPrefsProvider.select((p) => p.jump), (_, j) => WidgetsBinding.instance.addPostFrameCallback((_) => _maybe(j)));
    final c = context.dc;
    return Focus(
      focusNode: _focus,
      skipTraversal: true,
      child: AnimatedContainer(
        duration: Dur.base,
        decoration: BoxDecoration(
          color: _flash ? c.accentFaint : null,
          borderRadius: BorderRadius.circular(Rad.sm),
          boxShadow: _flash ? [BoxShadow(color: c.accent, spreadRadius: 1)] : null,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Health dot, word and latency: "Online · 84 ms".
class HealthLine extends StatelessWidget {
  const HealthLine(this.health, {super.key, this.latencyMs});

  final ServiceHealth health;
  final int? latencyMs;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EStatusDot(healthTone(health)),
        SizedBox(width: 6.u),
        Text(latencyMs == null ? healthWord(health) : '${healthWord(health)} · $latencyMs ms', style: ts.small),
      ],
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

String ago(DateTime? t) {
  if (t == null) return 'never';
  final d = _mockNow.difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

void copyLink(BuildContext context, String url) {
  Clipboard.setData(ClipboardData(text: url));
  showEToast(context, 'Link copied', text: url);
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
    );
  }
}
