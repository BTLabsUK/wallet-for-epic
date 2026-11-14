// SPDX-License-Identifier: Apache-2.0
/// The window's own title bar (the system's is hidden, desk_window.dart), 52 u tall above every
/// screen. The brand opens the app menu (Lock, Switch wallet, Help, Report a problem, Keyboard
/// shortcuts, About, Quit). Then the wallet's places as tabs, the wallet switcher, Hide
/// amounts, Lock and the window controls: Windows' three
/// on the right, round ones on Linux, the traffic lights' room on the left on macOS. Unlock and
/// the first-run screens keep only the brand and the controls. The services' status and the
/// network mode are in the status bar at the window's foot (status_bar.dart).
///
/// Any empty part of the bar moves the window; a double click maximises or restores it; a right
/// click opens the system's window menu (Windows). While a dialog is open its scrim covers the
/// bar too, but moving and the window controls keep working.
library;

import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart' show ResizeEdge;

import '../../amount.dart' show atomicPerEpic, epicUnit;
import '../../app_info.dart';
import '../../l10n.dart' show localDigits;
import '../../network_gate.dart' show NetGate;
import '../../price.dart' show fiatChoiceProvider, fiatText, priceProvider;
import '../../trust_ids.dart';
import '../data/desk_update.dart' show deskAppVersion;
import '../data/invoice_state.dart' show deskInvoiceBadgeProvider;
import '../../ui/theme/brand.dart' show EpicMark;
import '../../advanced.dart' show NetworkMode;
import '../../ui/network_mode_text.dart';
import '../data/net_mode_view.dart' show deskNetTor;
import '../data/node_view.dart' show digits;
import '../data/tor_view.dart' show TorState;
import '../desk_l10n.dart';
import '../screens/onboarding/onboarding_parts.dart' show deskLanguageItems, deskSystemLanguage, networkName;
import '../screens/onboarding/unlock_screen.dart' show UnlockPick;
import '../../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../screens/settings/prefs.dart';
import '../screens/settings/report_problem.dart' show showReportProblemDialog;
import '../screens/settings/settings_privacy.dart' show deskChooseNetworkMode, deskNetworkModes;
import '../widgets/kit.dart';
import 'close_guard.dart';
import 'desk_app.dart' show deskNavigatorKey;
import 'desk_window.dart';
import 'now_slot.dart';
import 'rail.dart';
import 'shell.dart' show deskVersion, deskKeys, deskSettingsHome, invoicesShown, lockWallet, deskLockingProvider, outputsShown;
import 'status_popover.dart';
import 'tour.dart' show TourTarget;

part 'status_bar.dart';

/// The bar's height before the interface scale.
const double deskBarHeight = 52;

/// Dialogs open on the app's navigator: the bar dims under their scrim.
class DeskModalWatch extends NavigatorObserver {
  final open = ValueNotifier(0);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) open.value++;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) open.value = (open.value - 1).clamp(0, 1 << 20);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => didPop(route, previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) didPop(oldRoute, null);
    if (newRoute != null) didPush(newRoute, null);
  }
}

/// One per app (per provider container), so a test's leftovers never count in the next app.
final deskModalWatchProvider = Provider<DeskModalWatch>((ref) {
  final w = DeskModalWatch();
  ref.onDispose(w.open.dispose);
  return w;
});

/// Everything inside the window: the bar, the app under it, and on Linux the border and the
/// resize edges the system does not draw. Goes in `MaterialApp.builder`, above the navigator,
/// so dialogs never cover the window controls; its own overlay holds the bar's menus and
/// tooltips.
class DeskWindowFrame extends ConsumerWidget {
  const DeskWindowFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(deskWindowProvider);
    final width = MediaQuery.sizeOf(context).width;
    // The phone layout (the web build in a narrow tab) has its own top bar.
    if (!window.frameless && width < Bp.phone) return child;
    return ValueListenableBuilder(
      valueListenable: window.state,
      builder: (context, w, _) {
        final c = context.dc;
        final edges = window.drawsFrame && !w.maximized;
        Widget body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DeskTitleBar(),
            Expanded(
              child: Stack(
                children: [
                  // A semantics node of its own for the app under the bar: a route's barrier
                  // blocks the semantics of everything painted before it in its container, and
                  // without this node that was the bar, with the tabs in it.
                  Positioned.fill(child: Semantics(container: true, explicitChildNodes: true, child: child)),
                  // Unfocused: a light wash over the page, as the bar's glyphs fade.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: w.focused ? 0 : 1,
                        duration: Dur.base,
                        child: ColoredBox(color: c.bg.withValues(alpha: 0.18)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        if (edges) {
          body = Stack(
            children: [
              Positioned.fill(child: body),
              // The border on top of everything, never taking a click.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.lineStrong))),
                ),
              ),
              ..._resizeEdges(window),
            ],
          );
        } else if (window.frameless && !w.maximized && deskWindowStyle == DeskWindowStyle.windows) {
          // Windows keeps its side and bottom borders, but a hidden caption takes the top one
          // (window_manager adds none on Windows 11): the top edge and corners resize here.
          body = Stack(children: [Positioned.fill(child: body), ..._topEdge(window)]);
        }
        body = Stack(
          children: [
            Positioned.fill(child: body),
            if (ref.watch(deskClosingProvider)) const Positioned.fill(child: _Closing()),
          ],
        );
        // Above the navigator there is no Material: the bar's text takes the app's style here.
        return Overlay.wrap(child: Material(color: c.bg, child: body));
      },
    );
  }
}

/// Over the whole window while the app closes; nothing under it takes a click.
class _Closing extends StatelessWidget {
  const _Closing();

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return AbsorbPointer(
      child: ColoredBox(
        color: c.scrim,
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: context.l10n.deskBarClosing,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ESpinner(size: 28.u),
                SizedBox(height: Sp.x4),
                Text(context.l10n.deskBarClosing, style: context.ts.h3.copyWith(fontSize: Fs.lg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The top edge (5 px) and its corners (12 px), for Windows.
List<Widget> _topEdge(DeskWindow window) {
  const e = 5.0, k = 12.0;
  Widget edge(ResizeEdge at, MouseCursor cursor) => MouseRegion(
    cursor: cursor,
    child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => unawaited(window.startResizing(at))),
  );
  return [
    Positioned(left: k, right: k, top: 0, height: e, child: edge(ResizeEdge.top, SystemMouseCursors.resizeUp)),
    Positioned(left: 0, top: 0, width: k, height: e, child: edge(ResizeEdge.topLeft, SystemMouseCursors.resizeUpLeft)),
    Positioned(right: 0, top: 0, width: k, height: e, child: edge(ResizeEdge.topRight, SystemMouseCursors.resizeUpRight)),
  ];
}

/// 8 px edges and 16 px corners that resize the window (Linux, where the window has no frame).
List<Widget> _resizeEdges(DeskWindow window) {
  const e = 8.0, k = 16.0;
  Widget edge(ResizeEdge at, MouseCursor cursor) => MouseRegion(
    cursor: cursor,
    child: GestureDetector(behavior: HitTestBehavior.opaque, onPanStart: (_) => unawaited(window.startResizing(at))),
  );
  return [
    Positioned(left: k, right: k, top: 0, height: e, child: edge(ResizeEdge.top, SystemMouseCursors.resizeUp)),
    Positioned(left: k, right: k, bottom: 0, height: e, child: edge(ResizeEdge.bottom, SystemMouseCursors.resizeDown)),
    Positioned(top: k, bottom: k, left: 0, width: e, child: edge(ResizeEdge.left, SystemMouseCursors.resizeLeft)),
    Positioned(top: k, bottom: k, right: 0, width: e, child: edge(ResizeEdge.right, SystemMouseCursors.resizeRight)),
    Positioned(left: 0, top: 0, width: k, height: e, child: edge(ResizeEdge.topLeft, SystemMouseCursors.resizeUpLeft)),
    Positioned(left: 0, top: 0, width: e, height: k, child: edge(ResizeEdge.topLeft, SystemMouseCursors.resizeUpLeft)),
    Positioned(right: 0, top: 0, width: k, height: e, child: edge(ResizeEdge.topRight, SystemMouseCursors.resizeUpRight)),
    Positioned(right: 0, top: 0, width: e, height: k, child: edge(ResizeEdge.topRight, SystemMouseCursors.resizeUpRight)),
    Positioned(left: 0, bottom: 0, width: k, height: e, child: edge(ResizeEdge.bottomLeft, SystemMouseCursors.resizeDownLeft)),
    Positioned(left: 0, bottom: 0, width: e, height: k, child: edge(ResizeEdge.bottomLeft, SystemMouseCursors.resizeDownLeft)),
    Positioned(right: 0, bottom: 0, width: k, height: e, child: edge(ResizeEdge.bottomRight, SystemMouseCursors.resizeDownRight)),
    Positioned(right: 0, bottom: 0, width: e, height: k, child: edge(ResizeEdge.bottomRight, SystemMouseCursors.resizeDownRight)),
  ];
}

/// The bar. Its state comes from the window (maximised, focused), the place (an open wallet or
/// Unlock) and the width (below [Bp.desktop] the brand is its mark and the tabs their icons).
class DeskTitleBar extends ConsumerWidget {
  const DeskTitleBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final window = ref.watch(deskWindowProvider);
    final route = ref.watch(deskNavProvider.select((a) => a.route));
    final width = MediaQuery.sizeOf(context).width;
    final wallet = !route.bare;
    final compact = width < Bp.desktop;
    final style = deskWindowStyle;
    return ValueListenableBuilder(
      valueListenable: window.state,
      builder: (context, w, _) {
        final dim = !w.focused;
        final chrome = c.tint.a != 0;
        final controls = window.frameless ? _WindowControls(window: window, state: w, style: style) : null;
        final bar = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The traffic lights' room (the system draws them on macOS).
            if (style == DeskWindowStyle.mac && window.frameless) SizedBox(width: 78.u),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Sp.x1),
              child: Center(child: _Held(child: _Brand(menu: wallet, compact: compact && wallet, dim: dim))),
            ),
            if (wallet) ...[
              // The tabs take the room the bar has left; in a window too narrow for them they
              // scroll, so the wallet's name and Lock never leave the bar.
              Expanded(child: Align(alignment: AlignmentDirectional.centerStart, child: _Held(child: _Tabs(section: route.section, compact: compact)))),
              // Always some empty bar to move the window by, however many tabs there are.
              SizedBox(width: Sp.x6),
              _Held(child: _WalletChip(dim: dim, compact: compact)),
              _Held(child: _EyeButton(dim: dim)),
              _Held(child: _LockButton(dim: dim)),
              if (controls != null && style != DeskWindowStyle.mac)
                Container(
                  width: 1,
                  height: 16.u,
                  margin: EdgeInsetsDirectional.only(start: Sp.x2, end: 10.u),
                  color: c.lineStrong,
                )
              else
                SizedBox(width: Sp.x3),
            ] else ...[
              const Spacer(),
              // The first screen asks nothing before the language: it is changed right here.
              if (route == DeskRoute.welcome) ...[_Held(child: _LanguageButton(dim: dim)), SizedBox(width: Sp.x2)],
            ],
            ?controls,
          ],
        );
        return SizedBox(
          height: deskBarHeight.u,
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            label: appName,
            child: FocusTraversalGroup(
              child: Stack(
                children: [
                  // Under the buttons: the bar's own surface, which moves the window.
                  Positioned.fill(
                    child: _DragSurface(
                      window: window,
                      // One strip with a hairline over the page: white in light, the window's
                      // colour in dark. A Container, which fills the strip.
                      child: Container(decoration: BoxDecoration(color: chrome ? c.s1 : c.bg, border: Border(bottom: BorderSide(color: c.line)))),
                    ),
                  ),
                  Positioned.fill(child: bar),
                  // A dialog's scrim reaches over the bar; moving and the controls stay usable.
                  Positioned.fill(child: _ModalScrim(controlsWidth: controls == null ? 0 : _WindowControls.widthOf(style))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The empty parts of the bar: drag to move, double-click to maximise, right-click for the
/// window menu.
class _DragSurface extends StatelessWidget {
  const _DragSurface({required this.window, required this.child});

  final DeskWindow window;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!window.frameless) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => unawaited(window.startDragging()),
      onDoubleTap: () => unawaited(window.toggleMaximize()),
      onSecondaryTap: () => unawaited(window.systemMenu()),
      child: child,
    );
  }
}

/// The dialog scrim's part over the bar: paint only, so the bar still moves the window and its
/// controls still work ([_Held] keeps the app's own buttons out of reach meanwhile).
class _ModalScrim extends ConsumerWidget {
  const _ModalScrim({required this.controlsWidth});

  final double controlsWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    return IgnorePointer(
      child: ValueListenableBuilder(
        valueListenable: ref.watch(deskModalWatchProvider).open,
        builder: (context, open, _) => Row(
          children: [
            Expanded(child: AnimatedOpacity(opacity: open > 0 ? 1 : 0, duration: Dur.fast, child: ColoredBox(color: c.scrim))),
            SizedBox(
              width: controlsWidth,
              child: AnimatedOpacity(opacity: open > 0 ? 0.6 : 0, duration: Dur.fast, child: ColoredBox(color: c.scrim)),
            ),
          ],
        ),
      ),
    );
  }
}

/// An app control of the bar: out of reach (pointer and focus) while a dialog holds the app.
class _Held extends ConsumerWidget {
  const _Held({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ValueListenableBuilder(
    valueListenable: ref.watch(deskModalWatchProvider).open,
    child: child,
    builder: (context, open, child) => IgnorePointer(ignoring: open > 0, child: ExcludeFocus(excluding: open > 0, child: child!)),
  );
}

/// Hover and pressed backgrounds for the bars' own buttons (brand, wallet chip, status lights).
class _BarButton extends StatefulWidget {
  const _BarButton({super.key, required this.label, required this.onPressed, required this.child, this.open = false, this.tooltip, this.padding, this.height = 30, this.radius});

  final String label;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool open;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  /// Before the interface scale.
  final double height;

  /// The corners of the hover and pressed background; the kit's control radius when null.
  final double? radius;

  @override
  State<_BarButton> createState() => _BarButtonState();
}

class _BarButtonState extends State<_BarButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final enabled = widget.onPressed != null;
    Widget button = Semantics(
      button: true,
      label: widget.label,
      expanded: enabled ? widget.open : null,
      excludeSemantics: true,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed?.call())},
        child: Builder(
          builder: (context) {
            final face = FocusRing(
              focused: Focus.of(context).hasFocus,
              child: AnimatedContainer(
                duration: Dur.fast,
                height: widget.height.u,
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: !enabled
                      ? Colors.transparent
                      : widget.open || _down
                      ? c.press
                      : _hover
                      ? c.hover
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(widget.radius ?? Rad.sm),
                ),
                child: widget.child,
              ),
            );
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onPressed,
              onTapDown: enabled ? (_) => setState(() => _down = true) : null,
              onTapUp: enabled ? (_) => setState(() => _down = false) : null,
              onTapCancel: enabled ? () => setState(() => _down = false) : null,
              child: face,
            );
          },
        ),
      ),
    );
    if (widget.tooltip != null && !widget.open) button = ETip(widget.tooltip, child: button);
    return Center(widthFactor: 1, child: button);
  }
}

/// The title bar's menus: the app's menu look (the theme's menuTheme: s4, lineStrong, the soft
/// shadow), a little tighter and at least [minWidth] wide, with the plain cursor between rows.
MenuStyle _menuStyle({double? minWidth}) => MenuStyle(
  padding: WidgetStatePropertyAll(EdgeInsets.all(6.u)),
  // The panel itself is no button (Flutter's default is the click cursor over all of it): the
  // rows and buttons inside show their own.
  mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.basic),
  minimumSize: WidgetStatePropertyAll(Size(minWidth ?? 240.u, 0)),
);

/// One menu row: icon (or a leading widget), label, and the shortcut on the right.
Widget _menuItem(
  BuildContext context, {
  Key? key,
  IconData? icon,
  Widget? leading,
  required String label,
  String? keys,
  Widget? trailing,
  VoidCallback? onPressed,
}) {
  final c = context.dc;
  final ts = context.ts;
  return MenuItemButton(
    key: key,
    onPressed: onPressed,
    style: ButtonStyle(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: WidgetStatePropertyAll(Size(0, 36.u)),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10.u)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.u))),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused) ? c.hover : null,
      ),
    ),
    leadingIcon: leading ?? (icon == null ? null : Icon(icon, size: 19.u, color: c.dim)),
    trailingIcon: keys != null
        ? Padding(padding: EdgeInsetsDirectional.only(start: Sp.x6), child: Text(keys, style: ts.caption.copyWith(fontSize: Fs.xs, color: c.faint)))
        : trailing,
    child: Padding(
      padding: EdgeInsetsDirectional.only(start: Sp.x1),
      child: Text(label, style: ts.body.copyWith(color: onPressed == null ? c.faint : c.text)),
    ),
  );
}

Widget _menuDivider(DeskColors c) => Padding(
  padding: EdgeInsets.symmetric(vertical: 6.u, horizontal: Sp.x1),
  child: Divider(height: 1, thickness: 1, color: c.line),
);

/// A menu that opens below its button (above it from the status bar, where no room is below) and
/// closes on Esc.
class _BarMenu extends StatefulWidget {
  const _BarMenu({required this.children, required this.builder, this.minWidth, this.f10 = false});

  /// F10 opens this one (the app menu).
  final bool f10;

  final List<Widget> Function(BuildContext context, MenuController menu) children;
  final Widget Function(BuildContext context, MenuController menu, bool open) builder;
  final double? minWidth;

  @override
  State<_BarMenu> createState() => _BarMenuState();
}

class _BarMenuState extends State<_BarMenu> {
  final _menu = MenuController();
  bool _open = false;

  // Esc closes the open menu wherever the focus is (the bar is outside the page's focus); F10
  // opens the app menu, the keyboard's way into the bar.
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    if (e.logicalKey == LogicalKeyboardKey.f10 && widget.f10 && !_menu.isOpen && ProviderScope.containerOf(context, listen: false).read(deskModalWatchProvider).open.value == 0) {
      _menu.open();
      WidgetsBinding.instance.addPostFrameCallback((_) => _first.requestFocus());
      return true;
    }
    if (e.logicalKey != LogicalKeyboardKey.escape || !_menu.isOpen) return false;
    _menu.close();
    return true;
  }

  final _first = FocusNode(debugLabel: 'bar-menu-first');

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _first.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menu,
      consumeOutsideTap: true,
      style: _menuStyle(minWidth: widget.minWidth),
      alignmentOffset: Offset(0, 4.u),
      onOpen: () {
        deskMenuOpened();
        setState(() => _open = true);
      },
      onClose: () {
        deskMenuClosed();
        if (mounted) setState(() => _open = false);
      },
      menuChildren: [
        for (final (n, child) in widget.children(context, _menu).indexed) n == 0 && widget.f10 ? Focus(focusNode: _first, skipTraversal: true, child: child) : child,
      ],
      builder: (context, menu, _) => CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): menu.close},
        child: widget.builder(context, menu, _open),
      ),
    );
  }
}

void _toggle(MenuController m) => m.isOpen ? m.close() : m.open();

/// The language of the app, on Welcome's bar: its name and a chevron; the list holds the
/// computer's language and each translation, the chosen one ticked.
class _LanguageButton extends ConsumerWidget {
  const _LanguageButton({required this.dim});

  final bool dim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final settings = ref.watch(deskProvider.select((s) => s.settings));
    final value = settings.language ?? deskSystemLanguage;
    final items = deskLanguageItems(l);
    final current = items.where((i) => i.value == value).firstOrNull ?? items.first;
    return _BarMenu(
      minWidth: 220.u,
      children: (context, m) => [
        for (final i in items)
          _menuItem(
            context,
            key: ValueKey('bar-language-${i.value.isEmpty ? 'system' : i.value}'),
            leading: i.leading,
            label: i.title,
            trailing: i.value == value ? Icon(EIcons.check, size: Ctl.iconSm, color: c.text) : null,
            onPressed: () {
              m.close();
              final n = ref.read(deskProvider.notifier);
              unawaited(n.saveSettings(ref.read(deskProvider).settings.copyWith(language: () => i.value == deskSystemLanguage ? null : i.value)));
            },
          ),
      ],
      builder: (context, m, open) => _BarButton(
        key: const ValueKey('bar-language'),
        label: l.deskSetAppearLanguage,
        tooltip: l.deskSetAppearLanguage,
        open: open,
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: Sp.x3),
        onPressed: () => _toggle(m),
        child: AnimatedOpacity(
          opacity: dim ? 0.7 : 1,
          duration: Dur.base,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: Sp.x2,
            children: [
              Icon(EIcons.translate, size: Ctl.iconSm, color: c.dim),
              Text(current.title, style: ts.strong.copyWith(fontSize: ts.small.fontSize)),
              Icon(EIcons.chevronDown, size: Ctl.iconSm, color: c.dim),
            ],
          ),
        ),
      ),
    );
  }
}

/// The title bar's logo (canvas/handoff/LOGO.md): the mask in
/// one flat brand colour and "BT Wallet" as text on one line; in a narrow window the
/// mark alone. In an open wallet it opens the app menu (hover and pressed fills say so); its
/// tooltip names the build.
class _Brand extends ConsumerWidget {
  const _Brand({required this.menu, required this.compact, required this.dim});

  final bool menu;
  final bool compact;
  final bool dim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    // A colour makes EpicMark's gradient run from it to itself: flat.
    final mark = EpicMark(size: 20.u, color: dim ? c.accentDeep : c.accent);
    final size = (ts.h3.fontSize ?? Fs.h3) * Fs.lg / Fs.h3;
    Widget faded(Widget w) => AnimatedOpacity(opacity: dim ? 0.7 : 1, duration: Dur.base, child: w);
    final lockup = faded(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: Sp.x2),
          Text(
            appName, // l10n-ok: the product's name, never translated
            maxLines: 1,
            softWrap: false,
            style: ts.h3.copyWith(fontSize: size, height: 1, letterSpacing: size * -0.02, color: c.text),
          ),
        ],
      ),
    );
    if (!menu) return Semantics(label: appName, excludeSemantics: true, child: Padding(padding: EdgeInsetsDirectional.only(start: Sp.x3), child: lockup));
    // A narrow window: the mark alone, the build in its tooltip; Copy build info is in the menu.
    if (compact) return _appMenu(context, ref, Center(widthFactor: 1, child: faded(mark)), tooltip: '$appName ${deskBuildLabel()}');
    // The build in the tooltip.
    return _appMenu(context, ref, lockup, tooltip: '$appName ${deskBuildLabel()}');
  }

  Widget _appMenu(BuildContext context, WidgetRef ref, Widget child, {String? tooltip}) {
    final c = context.dc;
    final l = context.l10n;
    final locking = ref.watch(deskLockingProvider);
    final wallets = ref.watch(deskProvider.select((s) => s.wallets));
    final canSwitch = (wallets ?? const []).length > 1;
    return _BarMenu(
      f10: true,
      children: (context, m) => [
        if (!deskNoLock) _menuItem(context, key: const ValueKey('bar-menu-lock'), icon: EIcons.lock, label: l.deskBarLock, keys: deskKeys('L'), onPressed: locking ? null : () => lockWallet(ref)),
        if (canSwitch && !deskNoLock) _menuItem(context, icon: EIcons.swap, label: l.deskShellSwitchWallet, onPressed: locking ? null : () => lockWallet(ref)),
        _menuDivider(c),
        _menuItem(context, key: const ValueKey('bar-menu-help'), icon: EIcons.help, label: l.deskSlotHelp, onPressed: () => _go(ref, DeskRoute.settingsHelp)),
        _menuItem(context, key: const ValueKey('bar-menu-report'), icon: EIcons.bug, label: l.deskSetReportTitle, onPressed: _reportProblem),
        _menuItem(context, icon: EIcons.keyboard, label: l.deskBarShortcuts, keys: '?', onPressed: () => showDeskShortcuts()), // l10n-ok: the key
        _menuItem(context, icon: EIcons.info, label: l.deskBarAbout(appName), onPressed: () => _go(ref, DeskRoute.settingsAbout)),
        _menuItem(context, key: const ValueKey('bar-menu-build'), icon: EIcons.copy, label: l.deskBarCopyBuild, onPressed: () => unawaited(copyBuildInfo())),
        _menuDivider(c),
        _menuItem(context, key: const ValueKey('bar-menu-quit'), icon: EIcons.logout, label: l.deskBarQuit, keys: deskKeys('Q'), onPressed: () => deskClose(ref)),
      ],
      builder: (context, m, open) => _BarButton(
        key: const ValueKey('bar-brand'),
        label: l.deskBarMenu(appName),
        tooltip: tooltip,
        open: open,
        height: 36,
        padding: compact ? EdgeInsets.symmetric(horizontal: Sp.x2) : EdgeInsets.symmetric(horizontal: Sp.x3),
        onPressed: () => _toggle(m),
        child: child,
      ),
    );
  }
}

/// The running build in a few characters: `26.10.16 · r2 · 810de1e`; the version alone in a
/// build without a commit (development).
String deskBuildLabel() =>
    metaLine([deskAppVersion, if (appBuildTag.isNotEmpty) appBuildTag, if (appBuildId.isNotEmpty) appBuildId.substring(0, appBuildId.length.clamp(0, 7))]);

/// What Copy build info puts on the clipboard: the build, the core and the system.
String deskBuildInfo() =>
    '$appName ${versionLine(deskAppVersion)}${appBuildTag.isEmpty ? '' : ' $appBuildTag'} · ${deskSystemName()}';

/// The system in a few words: "Windows 11", "Ubuntu 25.10", "macOS 15.1".
String deskSystemName() {
  if (kIsWeb) return 'web'; // l10n-ok: system name
  try {
    if (Platform.isWindows) {
      // "Windows 10 Pro" 10.0 (Build 22631): Windows 11 is build 22000 and up.
      final build = int.tryParse(RegExp(r'Build (\d+)').firstMatch(Platform.operatingSystemVersion)?.group(1) ?? '') ?? 0;
      return build >= 22000 ? 'Windows 11' : 'Windows 10'; // l10n-ok: system name
    }
    if (Platform.isMacOS) return 'macOS ${RegExp(r'[\d.]+').firstMatch(Platform.operatingSystemVersion)?.group(0) ?? ''}'.trim(); // l10n-ok: system name
    if (Platform.isLinux) {
      final release = File('/etc/os-release');
      final pretty = release.existsSync() ? RegExp(r'^PRETTY_NAME="?([^"\n]*)', multiLine: true).firstMatch(release.readAsStringSync())?.group(1) : null;
      final kernel = RegExp(r'^\S+ (\d+\.\d+)').firstMatch(Platform.operatingSystemVersion)?.group(1);
      return pretty ?? 'Linux ${kernel ?? ''}'.trim(); // l10n-ok: system name
    }
  } on Object {
    // A name only; the version line above says the rest.
  }
  return Platform.operatingSystem;
}

/// Copies [deskBuildInfo] and says so.
Future<void> copyBuildInfo() async {
  final info = deskBuildInfo();
  await Clipboard.setData(ClipboardData(text: info));
  final shown = deskNavigatorKey.currentContext;
  if (shown != null && shown.mounted) showEToast(shown, shown.l10n.deskBarBuildCopied, text: info, tone: ETone.ok);
}

/// A place in the app; an open dialog is closed first (the bar is above it).
void _go(WidgetRef ref, DeskRoute route) {
  deskNavigatorKey.currentState?.popUntil((r) => r.isFirst);
  ref.read(deskNavProvider.notifier).go(route);
}

/// The open wallet's name; a click lists the wallets on this computer.
class _WalletChip extends ConsumerWidget {
  const _WalletChip({required this.dim, required this.compact});

  final bool dim;

  /// A narrow window: the name gets half the room.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final account = ref.watch(deskProvider.select((s) => s.account));
    final label = ref.watch(settingsPrefsProvider.select((p) => p.walletLabel));
    final wallets = ref.watch(deskProvider.select((s) => s.wallets)) ?? const <WalletEntry>[];
    final locking = ref.watch(deskLockingProvider);
    final name = account?.id != null || (label ?? '').isEmpty ? (account?.name ?? '') : label!;
    final current = wallets.where((w) => w.current).firstOrNull?.id ?? account?.id;
    final chip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EAvatar(name, size: 21.u),
        SizedBox(width: Sp.x2),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 120.u : 240.u),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ts.body.copyWith(fontWeight: FontWeight.w500, height: 1, color: dim ? c.dim : c.text),
            ),
          ),
        ),
        SizedBox(width: Sp.x2),
        Icon(EIcons.chevronDown, size: 16.u, color: c.faint),
      ],
    );
    return _BarMenu(
      minWidth: 260.u,
      children: (context, m) => [
        Padding(
          padding: EdgeInsets.fromLTRB(10.u, 6.u, 10.u, 4.u),
          child: Text(l.deskBarWalletsHere, style: ts.caption.copyWith(color: c.faint)),
        ),
        for (final w in wallets.isEmpty ? [WalletEntry(id: current ?? '', name: name, folder: '', network: account?.network ?? 'mainnet', current: true)] : wallets)
          _menuItem(
            context,
            leading: EAvatar(w.id == current ? name : w.name, size: 24.u),
            label: w.id == current ? name : w.name,
            trailing: w.id == current
                ? Icon(EIcons.check, size: 17.u, color: c.ok)
                : w.network != 'mainnet' && DeskFeatures.testNetworks
                ? EBadge(networkName(w.network), tone: ETone.warn)
                : null,
            // The open one only closes the menu.
            onPressed: w.id == current ? () {} : locking ? null : () => lockWallet(ref, then: UnlockPick(w.id, switched: true)),
          ),
        _menuDivider(c),
        _menuItem(context, icon: EIcons.plus, label: l.deskBarAddWallet, onPressed: () => _go(ref, DeskRoute.settingsWallets)),
        _menuItem(context, icon: EIcons.settings, label: l.deskBarWalletSettings, onPressed: () => _go(ref, DeskRoute.settingsAccount)),
      ],
      builder: (context, m, open) => _BarButton(
        key: const ValueKey('bar-wallet'),
        label: l.deskShellOpenWalletSettingsNamed(name),
        tooltip: l.deskShellSwitchWallet,
        open: open,
        padding: EdgeInsetsDirectional.only(start: 5.u, end: Sp.x2),
        onPressed: () => _toggle(m),
        child: chip,
      ),
    );
  }
}

/// The wallet's places as tabs: Home, Activity, Contacts, Invoices, Outputs and Settings, with
/// the counts and the tour targets. Send and Receive start on Home.
class _Tabs extends ConsumerWidget {
  const _Tabs({required this.section, required this.compact});

  final DeskSection? section;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final pending = ref.watch(deskProvider.select((s) => s.pendingFiles));
    final invoices = invoicesShown(ref);
    final outputs = outputsShown(ref);
    final toPay = ref.watch(deskInvoiceBadgeProvider);
    final tabs = [
      for (final (s, route, icon) in deskNav)
        if (s != DeskSection.send && s != DeskSection.receive && (s != DeskSection.invoices || invoices) && (s != DeskSection.outputs || outputs))
          (
            id: 'nav-${s.name}',
            trust: TrustIds.shellNav(s.name),
            icon: icon,
            label: deskNavLabel(l, s),
            selected: section == s,
            count: switch (s) {
              DeskSection.activity => pending,
              DeskSection.invoices => toPay,
              _ => 0,
            },
            go: () => _go(ref, route),
          ),
      (id: 'nav-settings', trust: TrustIds.navSettings, icon: EIcons.settings, label: l.deskShellNavSettings, selected: section == DeskSection.settings, count: 0, go: () => _go(ref, deskSettingsHome(ref))),
    ];
    return Semantics(
      container: true,
      label: l.deskShellMainNav,
      child: TrustId(TrustIds.nav, child: LayoutBuilder(
        builder: (context, box) {
          // Icons alone (the selected tab keeps its label) in a narrow window, and in any window
          // where the labels of this language do not all fit.
          final icons = compact || ETab.widthOf(context, [for (final t in tabs) (t.label, t.count)]) > box.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: ETab.gap,
              children: [
                for (final t in tabs)
                  TourTarget(
                    id: t.id,
                    child: ETab(semanticsId: t.trust, icon: t.icon, label: t.label, selected: t.selected, compact: icons, count: t.count, onTap: t.go),
                  ),
              ],
            ),
          );
        },
      )),
    );
  }
}

/// Report a problem, from the app menu, over whatever page is open.
void _reportProblem() {
  final shown = deskNavigatorKey.currentContext;
  if (shown != null) unawaited(showReportProblemDialog(shown));
}

/// Hide amounts, on every page.
class _EyeButton extends ConsumerWidget {
  const _EyeButton({required this.dim});

  final bool dim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final l = context.l10n;
    final hidden = ref.watch(deskProvider.select((s) => s.settings.hideAmounts));
    return Center(
      child: EIconButton(
        key: const ValueKey('bar-eye'),
        icon: hidden ? EIcons.eyeOff : EIcons.eye,
        label: hidden ? l.deskOvShowAmounts : l.deskOvHideAmounts,
        selected: hidden,
        size: EBtnSize.inline,
        color: dim ? c.faint : null,
        onPressed: () {
          final s = ref.read(deskProvider).settings;
          ref.read(deskProvider.notifier).saveSettings(s.copyWith(hideAmounts: !hidden));
        },
      ),
    );
  }
}

/// Lock, with Ctrl+L in its tooltip; mid-send it says it waits for the payment.
class _LockButton extends ConsumerWidget {
  const _LockButton({required this.dim});

  final bool dim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (deskNoLock) return const SizedBox.shrink();
    final l = context.l10n;
    final c = context.dc;
    if (ref.watch(deskLockingProvider)) {
      return SizedBox.square(dimension: Ctl.inline, child: Center(child: ESpinner(size: Ctl.iconSm)));
    }
    final sending = ref.watch(deskSendingProvider) > 0;
    return Center(
      child: EIconButton(
        key: const ValueKey('bar-lock'),
        icon: EIcons.lock,
        label: sending ? '${l.deskShellLocksAfterSend} (${deskKeys('L')})' : l.deskShellLockWallet(deskKeys('L')),
        size: EBtnSize.inline,
        color: dim ? c.faint : null,
        onPressed: () => lockWallet(ref),
      ),
    );
  }
}

/// Minimise, maximise or restore, close, in the platform's look.
class _WindowControls extends ConsumerWidget {
  const _WindowControls({required this.window, required this.state, required this.style});

  final DeskWindow window;
  final DeskWindowState state;
  final DeskWindowStyle style;

  /// How much of the bar's end they take (for the dialog scrim).
  static double widthOf(DeskWindowStyle style) => switch (style) {
    DeskWindowStyle.windows => 3 * 46.u,
    DeskWindowStyle.linux => 3 * 26.u + 2 * Sp.x2 + 10.u,
    DeskWindowStyle.mac => 0,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final closeAfter = ref.watch(deskCloseAfterSendProvider);
    final maxLabel = state.maximized ? l.deskBarRestore : l.deskBarMaximise;
    final closeLabel = closeAfter ? l.deskBarClosesAfterSend : l.deskBarClose;
    void close() => unawaited(deskCloseWindow(ref));
    switch (style) {
      case DeskWindowStyle.mac:
        return const SizedBox.shrink();
      case DeskWindowStyle.windows:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _WinButton(key: const ValueKey('bar-min'), label: l.deskBarMinimise, glyph: _Glyph.min, dim: !state.focused, onPressed: () => unawaited(window.minimize())),
            _WinButton(
              key: const ValueKey('bar-max'),
              label: maxLabel,
              glyph: state.maximized ? _Glyph.restore : _Glyph.max,
              dim: !state.focused,
              snap: window,
              onPressed: () => unawaited(window.toggleMaximize()),
            ),
            _WinButton(key: const ValueKey('bar-close'), label: closeLabel, glyph: _Glyph.close, dim: !state.focused, close: true, pending: closeAfter, onPressed: close),
          ],
        );
      case DeskWindowStyle.linux:
        return Padding(
          padding: EdgeInsetsDirectional.only(start: 2.u, end: Sp.x2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RoundButton(key: const ValueKey('bar-min'), label: l.deskBarMinimise, glyph: _Glyph.min, dim: !state.focused, onPressed: () => unawaited(window.minimize())),
              SizedBox(width: Sp.x2),
              _RoundButton(
                key: const ValueKey('bar-max'),
                label: maxLabel,
                glyph: state.maximized ? _Glyph.restore : _Glyph.max,
                dim: !state.focused,
                onPressed: () => unawaited(window.toggleMaximize()),
              ),
              SizedBox(width: Sp.x2),
              _RoundButton(key: const ValueKey('bar-close'), label: closeLabel, glyph: _Glyph.close, dim: !state.focused, pending: closeAfter, onPressed: close),
            ],
          ),
        );
    }
  }
}

enum _Glyph { min, max, restore, close }

/// Windows 11's caption button: 46 × 40, a 10 px glyph of 1 px lines; Close turns the system's
/// red. Maximise also answers the snap layouts flyout ([DeskWindow.maximizeButtonAt]).
class _WinButton extends StatefulWidget {
  const _WinButton({
    super.key,
    required this.label,
    required this.glyph,
    required this.onPressed,
    required this.dim,
    this.close = false,
    this.pending = false,
    this.snap,
  });

  final String label;
  final _Glyph glyph;
  final VoidCallback onPressed;
  final bool dim;
  final bool close;
  final bool pending;
  final DeskWindow? snap;

  /// The system's close colours, not tokens: users expect them.
  static const closeHover = Color(0xFFC42B1C);
  static const closePress = Color(0xFFB22A1B);

  @override
  State<_WinButton> createState() => _WinButtonState();
}

class _WinButtonState extends State<_WinButton> {
  bool _hover = false;
  bool _down = false;
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.snap?.snapHover.addListener(_snapHover);
  }

  @override
  void dispose() {
    widget.snap?.snapHover.removeListener(_snapHover);
    super.dispose();
  }

  void _snapHover() => setState(() => _hover = widget.snap!.snapHover.value);

  /// Tells the window where this button is, after each layout.
  void _report() {
    final snap = widget.snap;
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (snap == null || box == null || !box.attached || !mounted) return;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final at = box.localToGlobal(Offset.zero);
    snap.maximizeButtonAt(Rect.fromLTWH(at.dx * dpr, at.dy * dpr, box.size.width * dpr, box.size.height * dpr));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    if (widget.snap != null) WidgetsBinding.instance.addPostFrameCallback((_) => _report());
    final red = widget.close && (_hover || _down);
    final bg = widget.close
        ? (_down ? _WinButton.closePress : _hover ? _WinButton.closeHover : Colors.transparent)
        : (_down ? c.press : _hover ? c.hover : Colors.transparent);
    final fg = red ? (_down ? Colors.white70 : Colors.white) : (widget.dim ? c.faint : c.text);
    return ETip(
      widget.label,
      child: Semantics(
        button: true,
        label: widget.label,
        excludeSemantics: true,
        onTap: widget.onPressed,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() {
            _hover = false;
            _down = false;
          }),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _down = true),
            onTapUp: (_) => setState(() => _down = false),
            onTapCancel: () => setState(() => _down = false),
            onTap: widget.onPressed,
            child: AnimatedContainer(
              key: _key,
              duration: Dur.fast,
              width: 46.u,
              height: deskBarHeight.u,
              color: bg,
              child: Stack(
                children: [
                  Center(child: CustomPaint(size: Size.square(10.u), painter: _GlyphPainter(widget.glyph, fg, stroke: 1, round: false))),
                  if (widget.pending)
                    PositionedDirectional(
                      end: 11.u,
                      top: 9.u,
                      child: Container(width: 6.u, height: 6.u, decoration: BoxDecoration(shape: BoxShape.circle, color: c.warn)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// GNOME's round header-bar button: 26 px, a 16 px symbolic glyph, a light wash on hover.
class _RoundButton extends StatefulWidget {
  const _RoundButton({super.key, required this.label, required this.glyph, required this.onPressed, required this.dim, this.pending = false});

  final String label;
  final _Glyph glyph;
  final VoidCallback onPressed;
  final bool dim;
  final bool pending;

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Center(
      child: ETip(
        widget.label,
        child: Semantics(
          button: true,
          label: widget.label,
          excludeSemantics: true,
          onTap: widget.onPressed,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() {
              _hover = false;
              _down = false;
            }),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _down = true),
              onTapUp: (_) => setState(() => _down = false),
              onTapCancel: () => setState(() => _down = false),
              onTap: widget.onPressed,
              child: AnimatedContainer(
                duration: Dur.fast,
                width: 26.u,
                height: 26.u,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _down
                      ? c.text.withValues(alpha: 0.16)
                      : _hover
                      ? c.text.withValues(alpha: 0.10)
                      : Colors.transparent,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(child: CustomPaint(size: Size.square(16.u), painter: _GlyphPainter(widget.glyph, widget.dim ? c.faint : c.text, stroke: 1.5, round: true))),
                    if (widget.pending)
                      PositionedDirectional(
                        end: -1,
                        top: -1,
                        child: Container(
                          width: 7.u,
                          height: 7.u,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: c.warn, border: Border.all(color: c.bg, width: 2)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The controls' glyphs, as thin lines (Windows: 10 px box, 1 px; GNOME: 16 px box, 1.5 px).
class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color, {required this.stroke, required this.round});

  final _Glyph glyph;
  final Color color;
  final double stroke;
  final bool round;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = round ? StrokeCap.round : StrokeCap.butt
      ..strokeJoin = round ? StrokeJoin.round : StrokeJoin.miter
      ..isAntiAlias = true;
    final s = size.width;
    // GNOME's glyphs sit in the middle half of their 16 px box.
    final inset = round ? s * 0.25 : 0.0;
    final a = inset, b = s - inset;
    switch (glyph) {
      case _Glyph.min:
        final y = round ? s * 0.72 : s * 0.55;
        canvas.drawLine(Offset(a, y), Offset(b, y), paint);
      case _Glyph.max:
        final r = RRect.fromRectAndRadius(Rect.fromLTRB(a + stroke / 2, a + stroke / 2, b - stroke / 2, b - stroke / 2), Radius.circular(round ? s * 0.03 : s * 0.12));
        canvas.drawRRect(r, paint);
      case _Glyph.restore:
        final w = b - a;
        final back = Path()
          ..moveTo(a + w * 0.25, a + w * 0.2)
          ..lineTo(a + w * 0.25, a + stroke / 2)
          ..lineTo(b - stroke / 2, a + stroke / 2)
          ..lineTo(b - stroke / 2, b - w * 0.25)
          ..lineTo(b - w * 0.2, b - w * 0.25);
        canvas.drawPath(back, paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(a + stroke / 2, a + w * 0.25, b - w * 0.25, b - stroke / 2), Radius.circular(round ? s * 0.03 : s * 0.1)),
          paint,
        );
      case _Glyph.close:
        canvas.drawLine(Offset(a, a), Offset(b, b), paint);
        canvas.drawLine(Offset(b, a), Offset(a, b), paint);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph || old.color != color || old.stroke != stroke;
}

/// The keyboard shortcuts of the whole app, in a dialog (the app menu, or ? outside a field).
Future<void> showDeskShortcuts() async {
  final context = deskNavigatorKey.currentContext;
  if (context == null) return;
  // Not twice on top of itself.
  if (ProviderScope.containerOf(context, listen: false).read(deskModalWatchProvider).open.value > 0) return;
  await showEDialog<void>(context, builder: (_) => const _ShortcutsDialog());
}

class _ShortcutsDialog extends StatelessWidget {
  const _ShortcutsDialog();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    final alt = mac ? '⌥' : 'Alt+'; // l10n-ok: key name
    final rows = [
      (l.deskBarLock, deskKeys('L')),
      (l.deskBarQuit, deskKeys('Q')),
      // From any page; / only inside Settings, out of a text field (on Help, Help's search).
      (l.deskBarKeySearch, deskKeys('K')),
      (l.deskBarKeySearchHere, '/'), // l10n-ok: the key
      (l.deskBarKeyBack, '$alt←'),
      (l.deskBarKeyForward, '$alt→'),
      (l.deskBarKeyClose, 'Esc'), // l10n-ok: key name
      (l.deskBarKeySubmit, deskKeys('Enter')), // l10n-ok: key name
      (l.deskBarKeyMenu, 'F10'), // l10n-ok: key name
      (l.deskBarKeyList, '?'), // l10n-ok: key name
    ];
    return EDialog(
      icon: EIcons.keyboard,
      title: l.deskBarShortcuts,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (what, keys) in rows)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6.u),
              child: Row(
                children: [
                  Expanded(child: Text(what, style: ts.body)),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.u, vertical: 2.u),
                    decoration: BoxDecoration(
                      color: c.s1,
                      borderRadius: BorderRadius.circular(Rad.xs),
                      border: Border.all(color: c.lineStrong),
                    ),
                    child: Text(keys, style: ts.mono(size: Fs.xs, color: c.text)),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [EButton(label: l.commonClose, onPressed: () => Navigator.of(context).pop())],
    );
  }
}
