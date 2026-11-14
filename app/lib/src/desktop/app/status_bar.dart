// SPDX-License-Identifier: Apache-2.0
part of 'title_bar.dart';

/// The status bar's height before the interface scale.
const double deskStatusBarHeight = 32;

/// The status bar at the window's foot, under every page of an open wallet: one light per
/// service (a click opens its popover, status_popover.dart), then what goes on
/// now (now_slot.dart, the first two and a `+N`), and at the end the EPIC price and the network
/// mode. A window narrower than [Bp.desktop] keeps the lights and drops the names and the price.
class DeskStatusBar extends ConsumerWidget {
  const DeskStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final wide = MediaQuery.sizeOf(context).width >= Bp.desktop;
    final now = nowItems(context, ref);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: context.l10n.deskBarStatus,
      child: Container(
        key: const ValueKey('status-bar'),
        height: deskStatusBarHeight.u,
        decoration: BoxDecoration(color: c.s1, border: Border(top: BorderSide(color: c.line))),
        child: FocusTraversalGroup(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // In a window too narrow for them the lights scroll; the mode keeps its place.
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ServiceRows(
                        builder: (context, items) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [for (final i in deskStatusShown(ref, items)) _StatusLight(item: i, words: wide)],
                        ),
                      ),
                      for (final n in now.take(2)) _NowLight(item: n),
                      if (now.length > 2)
                        _BarCell(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14.u),
                            child: Center(child: Text('+${now.length - 2}', style: context.ts.caption.copyWith(color: c.dim))), // l10n-ok: a count
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (wide) const _PriceCell(),
              const _ModeCell(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A mode in the status bar's mode menu: its glyph, its name, a tick on the chosen one.
class _ModeRow extends StatelessWidget {
  const _ModeRow({required this.mode, required this.chosen, required this.onTap});

  final NetworkMode mode;
  final bool chosen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final off = onTap == null;
    return Semantics(
      button: true,
      selected: chosen,
      enabled: !off,
      child: EInkWell(
        key: ValueKey('bar-mode-${mode.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(Rad.sm),
        hoverColor: c.hover,
        child: Container(
          height: Ctl.sm,
          padding: EdgeInsets.symmetric(horizontal: Sp.x2),
          decoration: BoxDecoration(color: chosen ? c.s3 : null, borderRadius: BorderRadius.circular(Rad.sm)),
          child: Row(
            children: [
              Icon(mode == NetworkMode.standard ? EIcons.network : networkModeGlyph(mode), size: Ctl.iconSm, color: off ? c.faint : c.dim),
              SizedBox(width: Sp.x3),
              Expanded(child: Text(networkModeName(context.l10n, mode), style: (chosen ? ts.strong : ts.body).copyWith(color: off ? c.faint : null))),
              if (chosen) ...[SizedBox(width: Sp.x3), Icon(EIcons.check, size: Ctl.iconSm, color: c.text)],
            ],
          ),
        ),
      ),
    );
  }
}

/// The status bar before a wallet is open (Welcome, Unlock, the first-run steps): the services'
/// lights, off, since nothing connects until a wallet is open, and the app's version at the end.
class DeskStartStatusBar extends StatelessWidget {
  const DeskStartStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    Widget light(String name, {IconData? icon}) => _BarCell(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.u),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Sp.x2,
          children: [
            EStateDot(EState.off, size: 8.u),
            if (icon != null) Icon(icon, size: 14.u, color: c.faint),
            Text(name, style: ts.caption.copyWith(color: c.faint)),
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l.deskBarStatus,
      child: Container(
        key: const ValueKey('start-status-bar'),
        height: deskStatusBarHeight.u,
        decoration: BoxDecoration(color: c.s1, border: Border(top: BorderSide(color: c.line))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    light(l.deskRailNode),
                    light('Epicbox', icon: EIcons.epicbox), // l10n-ok: product name
                    if (DeskFeatures.tor) light('Tor', icon: EIcons.tor), // l10n-ok: product name
                    light(l.methodDirectHttp, icon: EIcons.link),
                  ],
                ),
              ),
            ),
            _BarCell(
              end: true,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.u),
                child: Center(child: Text('$appName $deskVersion', key: const ValueKey('start-status-version'), style: ts.mono(size: Fs.xs, color: c.faint))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One cell of the bar with the hairline that parts it from the next ([end]: from the one before).
class _BarCell extends StatelessWidget {
  const _BarCell({required this.child, this.end = false});

  final Widget child;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(color: context.dc.line);
    return DecoratedBox(
      decoration: BoxDecoration(border: BorderDirectional(start: end ? side : BorderSide.none, end: end ? BorderSide.none : side)),
      child: child,
    );
  }
}

/// A service's light: the state dot, the glyph, the name, and for the node its height or what
/// is wrong. A click opens the service's popover; Enter or Space too, Esc closes it.
class _StatusLight extends ConsumerWidget {
  const _StatusLight({required this.item, required this.words});

  final RailItem item;

  /// The name beside the light; without it the glyph and the tooltip say which service.
  final bool words;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final tip = deskStatusTip(l, item);
    final node = item.jump == SettingsJump.node;
    final height = node && item.state == EState.ok ? ref.watch(deskProvider.select((s) => s.status?.nodeHeight)) : null;
    final detail = node ? (item.marker ?? (height == null ? null : digits(l, height))) : null;
    return _BarCell(
      child: _BarMenu(
        minWidth: 280.u,
        children: (context, m) => [DeskStatusPopover(item: item, close: m.close)],
        builder: (context, m, open) => _BarButton(
          key: ValueKey('bar-status-${item.jump.name}'),
          label: tip,
          tooltip: tip,
          open: open,
          height: deskStatusBarHeight,
          radius: 0,
          padding: EdgeInsets.symmetric(horizontal: 14.u),
          onPressed: () => _toggle(m),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: Sp.x2,
            children: [
              EStateDot(item.state, size: 8.u),
              if (!node) Icon(item.icon, size: 14.u, color: item.state == EState.off ? c.faint : c.dim),
              if (words || node) Text(item.name, maxLines: 1, style: ts.caption.copyWith(height: 1, fontWeight: FontWeight.w600, color: item.state == EState.off ? c.faint : c.text)),
              if (detail != null) Text(detail, maxLines: 1, style: ts.mono(size: Fs.xs, color: c.dim)),
            ],
          ),
        ),
      ),
    );
  }
}

/// One thing that goes on now: its tone's dot, its words, and what a click does.
class _NowLight extends StatelessWidget {
  const _NowLight({required this.item});

  final NowItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final detail = item.detail;
    return _BarCell(
      child: _BarButton(
        key: ValueKey('now-${item.id}'),
        label: item.words,
        tooltip: item.hint,
        height: deskStatusBarHeight,
        radius: 0,
        padding: EdgeInsets.symmetric(horizontal: 14.u),
        onPressed: item.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Sp.x2,
          children: [
            EStatusDot(item.tone, size: 8.u),
            Text(item.title, maxLines: 1, style: ts.caption.copyWith(height: 1, color: c.text)),
            if (detail != null) Text(detail, maxLines: 1, style: ts.caption.copyWith(height: 1, fontWeight: item.act ? FontWeight.w600 : null, color: item.act ? c.accentText : c.dim)),
          ],
        ),
      ),
    );
  }
}

/// What one EPIC costs in the chosen currency; nothing while there is no price.
class _PriceCell extends ConsumerWidget {
  const _PriceCell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (NetGate.restricted || !ref.watch(hostSettingsProvider.select((h) => h.priceEnabled))) return const SizedBox.shrink();
    final price = ref.watch(priceProvider).value;
    final currency = ref.watch(fiatChoiceProvider).value?.currency ?? '';
    if (price == null || currency.isEmpty) return const SizedBox.shrink();
    final c = context.dc;
    final ts = context.ts;
    return _BarCell(
      end: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.u),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Sp.x2,
          children: [
            Text(epicUnit, style: ts.caption.copyWith(height: 1, fontWeight: FontWeight.w600, color: c.text)),
            Text(localDigits(context.l10n, fiatText(atomicPerEpic, price, currency)), key: const ValueKey('bar-price'), style: ts.mono(size: Fs.xs, color: c.dim)),
          ],
        ),
      ),
    );
  }
}

/// The connection mode, always in words: a mode is a choice, not a service, so it wears no state
/// dot. A click opens the list of modes, the chosen one ticked: a pick switches the wallet here
/// (asking first when it would pause a waiting send), and Settings opens Network and privacy.
class _ModeCell extends ConsumerWidget {
  const _ModeCell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(deskProvider.select((s) => s.settings.advanced.networkMode));
    final torIncluded = ref.watch(deskProvider.select((s) => s.status?.torIncluded ?? true));
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final name = networkModeName(l, mode);
    final waiting = mode == NetworkMode.torOnly && deskNetTor(ref.watch(deskProvider)) != TorState.on;
    final line = networkModeMarkLine(l, mode, waitingForTor: waiting);
    return _BarCell(
      end: true,
      child: _BarMenu(
        minWidth: 280.u,
        children: (menu, m) => [
          Padding(
            padding: EdgeInsets.all(Sp.x2),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 280.u),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final x in deskNetworkModes())
                    _ModeRow(
                      mode: x,
                      chosen: x == mode,
                      // Tor only in a build without Tor: listed, not offered.
                      onTap: x == NetworkMode.torOnly && !torIncluded
                          ? null
                          : () {
                              m.close();
                              // The cell's own context: the menu's goes with it.
                              unawaited(deskChooseNetworkMode(context, ref, x));
                            },
                    ),
                  if (line.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(Sp.x2, Sp.x2, Sp.x2, 0),
                      child: Text(line, style: ts.small.copyWith(color: c.dim)),
                    ),
                  Divider(height: Sp.x4, color: c.line),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: EButton.ghost(
                      key: const ValueKey('bar-mode-change'),
                      label: l.deskRecvSettings,
                      icon: EIcons.settings,
                      size: EBtnSize.sm,
                      onPressed: () {
                        m.close();
                        deskNavigatorKey.currentState?.popUntil((r) => r.isFirst);
                        ProviderScope.containerOf(menu, listen: false).read(settingsPrefsProvider.notifier).jumpTo(SettingsJump.network);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        builder: (context, m, open) => _BarButton(
          key: const ValueKey('bar-net-mode'),
          label: l.netMarkSemanticsDesk(name),
          tooltip: line.isEmpty ? null : line,
          open: open,
          height: deskStatusBarHeight,
          radius: 0,
          padding: EdgeInsets.symmetric(horizontal: 14.u),
          onPressed: () => _toggle(m),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: Sp.x1,
            children: [
              Text(name, maxLines: 1, style: ts.caption.copyWith(height: 1, color: mode == NetworkMode.standard ? c.dim : c.text)),
              Icon(EIcons.chevronDown, size: 14.u, color: c.faint),
            ],
          ),
        ),
      ),
    );
  }
}
