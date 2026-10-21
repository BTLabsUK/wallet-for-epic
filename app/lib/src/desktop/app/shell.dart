import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/theme/brand.dart' show EpicMark;
import '../widgets/kit.dart';
import 'screens.dart';

/// The app version the sidebar shows.
const String deskVersion = '1.7.1';

/// The frame of every in-app page. Three layouts by width:
///  - desktop (≥ 1000): the 224 px sidebar with labels, statuses and the account;
///  - narrow (600–1000): a 72 px icon rail;
///  - phone (< 600): a top bar with the statuses and a bottom bar with the five places.
class DeskShell extends ConsumerWidget {
  const DeskShell({super.key, required this.at});

  final DeskLocation at;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final width = MediaQuery.sizeOf(context).width;
    final page = KeyedSubtree(key: ValueKey(at.route), child: deskScreen(at));
    final main = Material(color: c.bg, child: page);
    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyL, control: true): () => lockWallet(ref),
    };
    if (width < Bp.phone) {
      return CallbackShortcuts(
        bindings: shortcuts,
        child: Scaffold(
          backgroundColor: c.bg,
          body: SafeArea(child: Column(children: [const _PhoneTopBar(), Expanded(child: main)])),
          bottomNavigationBar: _PhoneNav(section: at.route.section),
        ),
      );
    }
    final compact = width < Bp.desktop;
    return CallbackShortcuts(
      bindings: shortcuts,
      child: Scaffold(
        backgroundColor: c.bg,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(section: at.route.section, compact: compact),
            Expanded(child: main),
          ],
        ),
      ),
    );
  }
}

/// Lock: back to the unlock screen, the wallet closed.
Future<void> lockWallet(WidgetRef ref) async {
  await ref.read(deskApiProvider).lock();
  ref.read(deskNavProvider.notifier).reset(DeskRoute.unlock);
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.section, required this.compact});

  final DeskSection? section;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final nav = ref.read(deskNavProvider.notifier);
    final pending = ref.watch(deskProvider.select((s) => s.pendingFiles));
    final account = ref.watch(deskProvider.select((s) => s.account));
    return Semantics(
      container: true,
      label: 'Main navigation',
      child: Container(
        width: compact ? Ctl.rail : Ctl.sidebar,
        decoration: BoxDecoration(color: c.s1, border: Border(right: BorderSide(color: c.line))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: Ctl.topbar,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 0 : Sp.x5),
                child: Row(
                  mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    EpicMark(size: 24, color: c.accent),
                    if (!compact) ...[
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Epic Cash', style: ts.h3.copyWith(fontSize: 15, letterSpacing: -0.15)),
                          Text('Wallet $deskVersion', style: ts.caption),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: compact ? Sp.x3 : Sp.x3, vertical: Sp.x2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (s, route, label, icon) in deskNav)
                      ENavItem(
                        icon: icon,
                        label: label,
                        selected: section == s,
                        compact: compact,
                        count: s == DeskSection.activity ? pending : null,
                        onTap: () => nav.go(route),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Sp.x2),
                      child: Divider(height: 1, color: c.line),
                    ),
                    ENavItem(
                      icon: EIcons.settings,
                      label: 'Settings',
                      selected: section == DeskSection.settings,
                      compact: compact,
                      onTap: () => nav.go(DeskRoute.settingsNode),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(Sp.x3),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ServiceRows(compact: compact),
                  const SizedBox(height: Sp.x2),
                  if (compact)
                    Center(
                      child: EIconButton(icon: EIcons.lock, label: 'Lock (Ctrl+L)', onPressed: () => lockWallet(ref)),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Tooltip(
                            message: 'Wallet settings',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(Rad.sm),
                              onTap: () => nav.go(DeskRoute.settingsAccount),
                              child: Padding(
                                padding: const EdgeInsets.all(Sp.x1),
                                child: Row(
                                  children: [
                                    EAvatar(account?.name ?? ''),
                                    const SizedBox(width: Sp.x3),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(account?.name ?? '', style: ts.body.copyWith(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                          Text(account?.network ?? '', style: ts.caption),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        EIconButton(
                          icon: EIcons.swap,
                          label: 'Switch wallet',
                          size: EBtnSize.inline,
                          onPressed: () => nav.go(DeskRoute.settingsWallets),
                        ),
                        const SizedBox(width: Sp.x1),
                        EIconButton(
                          icon: EIcons.lock,
                          label: 'Lock (Ctrl+L)',
                          size: EBtnSize.inline,
                          onPressed: () => lockWallet(ref),
                        ),
                      ],
                    ),
                  if (!compact) ...[
                    const SizedBox(height: Sp.x2),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Wallet by '),
                          TextSpan(text: 'Johannes Hahn', style: TextStyle(color: c.dim)),
                          const TextSpan(text: '\nTheme by '),
                          TextSpan(text: 'BT Labs', style: TextStyle(color: c.dim)),
                        ],
                      ),
                      style: ts.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Connection status in the sidebar: Node and Receiving, one word each; details on hover;
/// a click opens that service's settings.
class ServiceRows extends ConsumerWidget {
  const ServiceRows({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(deskProvider.select((s) => s.status));
    final settings = ref.watch(deskProvider.select((s) => s.settings));
    final nav = ref.read(deskNavProvider.notifier);
    if (status == null) return const SizedBox.shrink();
    final receiving = status.epicboxHealth;
    return Column(
      children: [
        _ServiceRow(
          icon: EIcons.node,
          name: 'Node',
          health: status.nodeHealth,
          compact: compact,
          details: [
            ('Node', status.node.label),
            ('Address', status.node.url),
            ('Height', '${status.nodeHeight}'),
            if (status.node.latencyMs != null) ('Answer', '${status.node.latencyMs} ms'),
            ('Failover', settings.nodeFailover ? 'On' : 'Off'),
          ],
          onTap: () => nav.go(DeskRoute.settingsNode),
        ),
        _ServiceRow(
          icon: EIcons.epicbox,
          name: 'Receiving',
          health: receiving,
          compact: compact,
          details: [
            ('Epicbox', status.epicbox.domain),
            ('Direct HTTP', healthWord(status.httpListener)),
            ('Tor', healthWord(status.tor)),
          ],
          onTap: () => nav.go(DeskRoute.settingsReceiving),
        ),
      ],
    );
  }
}

class _ServiceRow extends StatefulWidget {
  const _ServiceRow({
    required this.icon,
    required this.name,
    required this.health,
    required this.details,
    required this.onTap,
    required this.compact,
  });

  final IconData icon;
  final String name;
  final ServiceHealth health;
  final List<(String, String)> details;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_ServiceRow> createState() => _ServiceRowState();
}

class _ServiceRowState extends State<_ServiceRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final tone = healthTone(widget.health);
    final wordColor = switch (tone) {
      ETone.ok => c.ok,
      ETone.warn => c.warn,
      ETone.risk => c.risk,
      _ => c.faint,
    };
    final glyph = Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(widget.icon, size: Ctl.iconSm, color: c.dim),
        Positioned(right: -3, bottom: -2, child: EStatusDot(tone, size: 7)),
      ],
    );
    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (k, v) in widget.details)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 84, child: Text(k, style: ts.small)),
                Text(v, style: ts.mono(size: Fs.xs)),
              ],
            ),
          ),
        const SizedBox(height: Sp.x2),
        Text('Open settings', style: ts.caption.copyWith(color: c.accentText)),
      ],
    );
    return Tooltip(
      richMessage: WidgetSpan(child: card),
      preferBelow: false,
      verticalOffset: 18,
      child: Semantics(
        button: true,
        label: '${widget.name}: ${healthWord(widget.health)}',
        excludeSemantics: true,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (v) => setState(() => _hover = v),
          borderRadius: BorderRadius.circular(Rad.sm),
          child: Container(
            height: 32,
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 0 : Sp.x2),
            decoration: BoxDecoration(
              color: _hover ? c.hover : null,
              borderRadius: BorderRadius.circular(Rad.sm),
            ),
            child: widget.compact
                ? Center(child: glyph)
                : Row(
                    children: [
                      glyph,
                      const SizedBox(width: Sp.x3),
                      Expanded(child: Text(widget.name, style: ts.small.copyWith(color: c.text, fontWeight: FontWeight.w600))),
                      Text(healthWord(widget.health), style: ts.caption.copyWith(color: wordColor)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _PhoneTopBar extends ConsumerWidget {
  const _PhoneTopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: Sp.x4),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          EpicMark(size: 20, color: c.accent),
          const SizedBox(width: Sp.x2),
          Text('Epic Cash', style: context.ts.h3.copyWith(fontSize: 15)),
          const Spacer(),
          const SizedBox(width: 150, child: ServiceRows(compact: true)),
          EIconButton(
            icon: EIcons.settings,
            label: 'Settings',
            onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsNode),
          ),
          EIconButton(icon: EIcons.lock, label: 'Lock', onPressed: () => lockWallet(ref)),
        ],
      ),
    );
  }
}

class _PhoneNav extends ConsumerWidget {
  const _PhoneNav({required this.section});

  final DeskSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final index = deskNav.indexWhere((n) => n.$1 == section);
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: c.s1,
        indicatorColor: c.s3,
        height: 64,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: Fs.xs, color: c.dim)),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(size: Ctl.icon, color: s.contains(WidgetState.selected) ? c.accentText : c.faint),
        ),
      ),
      child: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => ref.read(deskNavProvider.notifier).go(deskNav[i].$2),
        destinations: [for (final (_, _, label, icon) in deskNav) NavigationDestination(icon: Icon(icon), label: label)],
      ),
    );
  }
}
