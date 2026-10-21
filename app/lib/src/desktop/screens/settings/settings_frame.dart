import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';

const List<(DeskRoute, String, IconData)?> _items = [
  (DeskRoute.settingsNode, 'Node', EIcons.node),
  (DeskRoute.settingsReceiving, 'Receiving', EIcons.antenna),
  (DeskRoute.settingsAppearance, 'Appearance', EIcons.palette),
  null,
  (DeskRoute.settingsAccount, 'Wallet', EIcons.wallet),
  (DeskRoute.settingsWallets, 'Wallets', EIcons.coins),
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
    final content = ConstrainedBox(constraints: const BoxConstraints(maxWidth: Ctl.narrow), child: child);
    return EPage(
      title: 'Settings',
      width: EPageWidth.full,
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 200,
                  child: Semantics(
                    label: 'Settings sections',
                    child: ESubnav(items: _items, current: route, onTap: (r) => nav.go(r as DeskRoute)),
                  ),
                ),
                const SizedBox(width: Sp.x8),
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
                          padding: const EdgeInsets.only(right: Sp.x2),
                          child: _Chip(icon: i.$3, label: i.$2, selected: i.$1 == route, onTap: () => nav.go(i.$1)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.x6),
                content,
              ],
            ),
    );
  }
}

String healthWord(ServiceHealth h) => switch (h) {
  ServiceHealth.ok => 'Online',
  ServiceHealth.slow => 'Slow',
  ServiceHealth.down => 'Offline',
  ServiceHealth.off => 'Off',
  ServiceHealth.checking => 'Checking',
};

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
        const SizedBox(width: 6),
        Text(latencyMs == null ? healthWord(health) : '${healthWord(health)} · $latencyMs ms', style: ts.small),
      ],
    );
  }
}

/// A page-sized placeholder while the wallet snapshot loads.
class SettingsLoading extends StatelessWidget {
  const SettingsLoading({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: Sp.x16),
    child: Center(child: ESpinner(size: 24)),
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
          padding: const EdgeInsets.symmetric(horizontal: Sp.x3),
          decoration: BoxDecoration(
            color: selected ? c.s3 : null,
            borderRadius: BorderRadius.circular(Rad.sm),
            border: Border.all(color: selected ? c.lineStrong : c.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: Ctl.iconSm, color: selected ? c.accentText : c.dim),
              const SizedBox(width: Sp.x2),
              Text(label, style: context.ts.body.copyWith(color: selected ? c.text : c.dim)),
            ],
          ),
        ),
      ),
    );
  }
}
