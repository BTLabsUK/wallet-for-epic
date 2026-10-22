import '../../app_info.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind, kBackMouseButton, kForwardMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/theme/brand.dart' show EpicMark;
import '../data/desk_update.dart' show deskAppVersion;
import '../screens/settings/prefs.dart';
import '../screens/settings/settings_frame.dart' show epicboxWord, groupDigits, nodeWord;
import '../screens/settings/settings_node.dart' show hostOf;
import '../screens/settings/settings_http.dart' show httpRun;
import '../widgets/kit.dart';
import 'desk_app.dart' show deskNavigatorKey;
import 'screens.dart';
import 'tour.dart';

/// The app version the sidebar, About and the support report show, with the build's commit.
final String deskVersion = withBuildId(deskAppVersion);


/// "Ctrl+L", or "⌘L" on macOS.
String deskKeys(String key) => defaultTargetPlatform == TargetPlatform.macOS ? '⌘$key' : 'Ctrl+$key';

/// The window title of each in-app place: `<page> · Epic Wallet`.
String deskPageTitle(DeskRoute r) {
  final page = switch (r.section) {
    DeskSection.overview => 'Overview',
    DeskSection.activity => 'Activity',
    DeskSection.send => 'Send',
    DeskSection.receive => switch (r) {
      DeskRoute.importTx => 'Import transaction',
      DeskRoute.finalize => 'Finalize transaction',
      _ => 'Receive',
    },
    DeskSection.outputs => 'Outputs',
    DeskSection.contacts => 'Contacts',
    DeskSection.settings => 'Settings',
    null => '',
  };
  return page.isEmpty ? appName : '$page · $appName';
}

/// The frame of every in-app page. Three layouts by width:
///  - desktop (≥ 1000): the 224 px sidebar with labels, statuses and the account;
///  - narrow (600–1000): a 72 px icon rail;
///  - phone (< 600): a top bar with the statuses and a bottom bar with the five places.
/// Ctrl+L locks, Ctrl+Q quits (⌘ on macOS). The tour opens over it.
class DeskShell extends ConsumerStatefulWidget {
  const DeskShell({super.key, required this.at});

  final DeskLocation at;

  @override
  ConsumerState<DeskShell> createState() => _DeskShellState();
}

class _DeskShellState extends ConsumerState<DeskShell> {
  Timer? _tourTimer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _maybeTour();
  }

  /// Ctrl+L / ⌘L locks, Ctrl+Q / ⌘Q quits, wherever the focus is (6.1.6 app menu).
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || !mounted) return false;
    final hw = HardwareKeyboard.instance;
    if (!(hw.isControlPressed || hw.isMetaPressed) || hw.isShiftPressed || hw.isAltPressed) return false;
    if (e.logicalKey == LogicalKeyboardKey.keyL) {
      lockWallet(ref);
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyQ) {
      quitWallet(context, ref);
      return true;
    }
    return false;
  }

  @override
  void didUpdateWidget(DeskShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeTour();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _tourTimer?.cancel();
    super.dispose();
  }

  /// The tour, once, shortly after the first unlock lands on Overview.
  void _maybeTour() {
    if (!deskTourAuto || widget.at.route != DeskRoute.overview || ref.read(deskTourProvider).seen) return;
    _tourTimer?.cancel();
    _tourTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted && ref.read(deskNavProvider).route == DeskRoute.overview && !ref.read(deskTourProvider).seen) {
        ref.read(deskTourProvider.notifier).open();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final at = widget.at;
    final width = MediaQuery.sizeOf(context).width;
    final page = KeyedSubtree(key: ValueKey(at.route), child: deskScreen(at));
    final main = Material(color: c.bg, child: page);
    final tour = ref.watch(deskTourProvider.select((t) => t.open));
    final tourStart = ref.watch(deskTourProvider.select((t) => t.start));
    final Widget frame;
    if (width < Bp.phone) {
      frame = Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(child: Column(children: [_PhoneTopBar(section: at.route.section), Expanded(child: FocusTraversalGroup(child: main))])),
        bottomNavigationBar: _PhoneNav(section: at.route.section),
      );
    } else {
      final compact = width < Bp.desktop;
      frame = Scaffold(
        backgroundColor: c.bg,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Two groups: Tab finishes the page before it moves to the sidebar.
            FocusTraversalGroup(child: _Sidebar(section: at.route.section, compact: compact)),
            Expanded(child: FocusTraversalGroup(child: main)),
          ],
        ),
      );
    }
    return Title(
      title: deskPageTitle(at.route),
      color: c.accent,
      child: Stack(
        children: [
          Positioned.fill(child: ExcludeFocus(excluding: tour, child: frame)),
          if (tour) Positioned.fill(child: DeskTourOverlay(key: ValueKey(tourStart), startAt: tourStart)),
        ],
      ),
    );
  }
}

/// Back: an open dialog or the tour holds it (Esc closes those); then the screen's inner step
/// ([DeskStepBack]); then the previous place, until Overview.
void deskBack(WidgetRef ref) {
  if (_navHeld(ref)) return;
  if (DeskStepBack.tryStepBack()) return;
  ref.read(deskNavProvider.notifier).back();
}

void deskForward(WidgetRef ref) {
  if (_navHeld(ref)) return;
  ref.read(deskNavProvider.notifier).forward();
}

bool _navHeld(WidgetRef ref) => (deskNavigatorKey.currentState?.canPop() ?? false) || ref.read(deskTourProvider).open;

/// The app-wide Back, Forward and Esc keys, around every screen (bare and in the shell); the
/// rules are in keyboard.dart. Mouse Back/Forward (buttons 8/16), Alt+Left/Right, Backspace
/// outside a text field; Esc first closes a visible tooltip.
class DeskNavKeys extends ConsumerStatefulWidget {
  const DeskNavKeys({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeskNavKeys> createState() => _DeskNavKeysState();
}

class _DeskNavKeysState extends ConsumerState<DeskNavKeys> {
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
    final hw = HardwareKeyboard.instance;
    final key = e.logicalKey;
    // A tooltip is the top-most thing: one Esc closes it, the next one what is under it.
    if (key == LogicalKeyboardKey.escape) return !hw.isShiftPressed && Tooltip.dismissAllToolTips();
    if (hw.isControlPressed || hw.isMetaPressed || hw.isShiftPressed) return false;
    // The keyboard's own Back / Forward keys.
    if (key == LogicalKeyboardKey.browserBack || key == LogicalKeyboardKey.browserForward) {
      if (_navHeld(ref)) return false;
      key == LogicalKeyboardKey.browserBack ? deskBack(ref) : deskForward(ref);
      return true;
    }
    if (hw.isAltPressed) {
      if (key != LogicalKeyboardKey.arrowLeft && key != LogicalKeyboardKey.arrowRight) return false;
      // Alt+arrow moves by word in a text field (Option on macOS); a half-typed form stays.
      if (deskTextFocused()) return false;
      if (_navHeld(ref)) return false;
      key == LogicalKeyboardKey.arrowLeft ? deskBack(ref) : deskForward(ref);
      return true;
    }
    if (key == LogicalKeyboardKey.backspace && !deskTextFocused() && !_navHeld(ref)) {
      deskBack(ref);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) {
      if (e.kind != PointerDeviceKind.mouse) return;
      if (e.buttons & kBackMouseButton != 0) deskBack(ref);
      if (e.buttons & kForwardMouseButton != 0) deskForward(ref);
    },
    child: widget.child,
  );
}

/// True while the wallet locks (the lock button spins, Ctrl+L waits).
class DeskLocking extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}

final deskLockingProvider = NotifierProvider<DeskLocking, bool>(DeskLocking.new);

/// Lock: back to the unlock screen, the wallet closed.
Future<void> lockWallet(WidgetRef ref) async {
  if (ref.read(deskLockingProvider)) return;
  ref.read(deskLockingProvider.notifier).set(true);
  // A payment under way is never ended by the lock: the lock waits for it.
  final shown = deskNavigatorKey.currentContext;
  if (ref.read(deskApiProvider).busy && shown != null) showEToast(shown, 'Locks when the payment is sent', tone: ETone.neutral);
  try {
    await ref.read(deskProvider.notifier).lock();
  } finally {
    ref.read(deskLockingProvider.notifier).set(false);
  }
  // Nothing of the wallet stays over the unlock screen: open dialogs and the tour go.
  deskNavigatorKey.currentState?.popUntil((r) => r.isFirst);
  ref.read(deskTourProvider.notifier).close();
  ref.read(deskNavProvider.notifier).reset(DeskRoute.unlock);
}

/// Quit (the app menu's Ctrl+Q): locks, then closes the app. The mock only locks.
Future<void> quitWallet(BuildContext context, WidgetRef ref) async {
  final quit = ref.read(deskQuitProvider);
  // Quitting mid-send would leave the payment's outcome unknown.
  if (ref.read(deskProvider.notifier).sending > 0) {
    showEToast(context, 'Not quit', text: 'A send is in progress. Quit again once it finishes.');
    return;
  }
  if (quit == null) showEToast(context, 'Wallet locked', text: 'Quit closes the app once the wallet core is connected.');
  await lockWallet(ref);
  await quit?.call();
}

/// Switch wallet: locks, then the unlock screen offers the other wallets.
Future<void> switchWallet(WidgetRef ref) => lockWallet(ref);

const Map<DeskSection, String> _tourIds = {
  DeskSection.send: 'send',
  DeskSection.receive: 'receive',
  DeskSection.activity: 'activity',
};

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
    final label = ref.watch(settingsPrefsProvider.select((p) => p.walletLabel));
    final wallets = ref.watch(deskProvider.select((s) => s.wallets));
    final locking = ref.watch(deskLockingProvider);
    final canSwitch = DeskFeatures.multiWallet && (wallets ?? const []).length > 1;
    final name = account?.id != null || (label ?? '').isEmpty ? (account?.name ?? '') : label!;
    final lockLabel = 'Lock wallet (${deskKeys('L')})';
    final lockButton = locking
        ? SizedBox.square(dimension: Ctl.inline, child: Center(child: ESpinner(size: Ctl.iconSm)))
        : EIconButton(icon: EIcons.lock, label: lockLabel, size: compact ? EBtnSize.sm : EBtnSize.inline, onPressed: () => lockWallet(ref));
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
                    EpicMark(size: 24.u, color: c.accent),
                    if (!compact) ...[
                      SizedBox(width: 10.u),
                      Flexible(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appName, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.h3.copyWith(fontSize: 15, letterSpacing: -0.15)),
                          Text('Version $deskVersion', style: ts.caption),
                        ],
                      ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (s, route, label, icon) in deskNav)
                      _tourWrap(
                        _tourIds[s],
                        ENavItem(
                          icon: icon,
                          label: label,
                          selected: section == s,
                          compact: compact,
                          count: s == DeskSection.activity ? pending : null,
                          onTap: () => nav.go(route),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: Sp.x2),
                      child: Divider(height: 1, color: c.line),
                    ),
                    TourTarget(
                      id: 'settings',
                      child: ENavItem(
                        icon: EIcons.settings,
                        label: 'Settings',
                        selected: section == DeskSection.settings,
                        compact: compact,
                        onTap: () => nav.go(DeskRoute.settingsNode),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(Sp.x3),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ServiceRows(compact: compact),
                  SizedBox(height: Sp.x2),
                  if (compact) ...[
                    Center(child: lockButton),
                    SizedBox(height: Sp.x2),
                    _RailVersion(),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: Tooltip(
                            message: 'Open wallet settings',
                            child: Semantics(
                              button: true,
                              label: 'Open wallet settings: $name',
                              excludeSemantics: true,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(Rad.sm),
                                onTap: () => nav.go(DeskRoute.settingsAccount),
                                child: Padding(
                                  padding: EdgeInsets.all(Sp.x1),
                                  child: Row(
                                    children: [
                                      EAvatar(name),
                                      SizedBox(width: Sp.x3),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: ts.body.copyWith(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
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
                        ),
                        if (canSwitch)
                          EIconButton(
                            icon: EIcons.swap,
                            label: 'Switch wallet',
                            size: EBtnSize.inline,
                            onPressed: locking ? null : () => switchWallet(ref),
                          ),
                        SizedBox(width: Sp.x1),
                        lockButton,
                      ],
                    ),
                  if (!compact) ...[
                    SizedBox(height: Sp.x2),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Wallet by '),
                          TextSpan(text: 'BT Labs', style: TextStyle(color: c.dim)),
                        ],
                      ),
                      style: ts.caption,
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

Widget _tourWrap(String? id, Widget child) => id == null ? child : TourTarget(id: id, child: child);

/// Connection status in the sidebar: Node and Receiving, one word each; the details in a
/// hover card; a click opens that service's settings section.
class ServiceRows extends ConsumerWidget {
  const ServiceRows({super.key, this.compact = false, this.horizontal = false});

  final bool compact;

  /// Side by side (the phone's top bar).
  final bool horizontal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(deskProvider.select((s) => s.status));
    final settings = ref.watch(deskProvider.select((s) => s.settings));
    final prefs = ref.watch(settingsPrefsProvider);
    final p = ref.read(settingsPrefsProvider.notifier);
    if (status == null) return const SizedBox.shrink();

    final node = prefs.typedNode ?? status.node;
    final nodeHealth = status.nodeHealth;
    final nodeLines = [
      [prefs.builtin ? 'Built-in node' : hostOf(node.url), if (nodeHealth != ServiceHealth.down) groupDigits(status.nodeHeight)].join(' · '),
      if (nodeHealth == ServiceHealth.down) 'The node is not answering.',
      if (nodeHealth == ServiceHealth.slow) 'Behind the network; catching up.',
    ];

    final eb = status.epicboxHealth;
    final http = httpRun(status);
    final ebLine = eb == ServiceHealth.off ? 'Epicbox off' : 'Epicbox · ${status.epicbox.domain} · ${epicboxWord(eb)}';
    final httpLine = switch (http) {
      HttpRun.on => 'HTTP receiving on',
      HttpRun.busy => 'HTTP receiving starting',
      HttpRun.failed => status.httpProblem == null ? 'HTTP receiving didn’t start' : 'HTTP receiving: ${status.httpProblem}',
      _ => 'HTTP receiving off',
    };
    var rcvHealth = eb;
    var rcvWord = eb == ServiceHealth.ok ? 'On' : epicboxWord(eb);
    if (eb == ServiceHealth.off && http == HttpRun.on) {
      rcvHealth = ServiceHealth.ok;
      rcvWord = 'HTTP only';
    }
    if (eb == ServiceHealth.ok && http == HttpRun.failed) rcvHealth = ServiceHealth.slow;

    final rows = [
        _ServiceRow(
          icon: EIcons.node,
          name: 'Node',
          health: nodeHealth,
          word: nodeWord(nodeHealth),
          compact: compact,
          lines: nodeLines,
          open: 'Open node settings',
          onTap: () => p.jumpTo(SettingsJump.node),
        ),
        _ServiceRow(
          icon: EIcons.epicbox,
          name: 'Receiving',
          health: rcvHealth,
          word: rcvWord,
          compact: compact,
          lines: [ebLine, if (DeskFeatures.httpDirect) httpLine, if (DeskFeatures.tor && settings.tor) 'Tor: ${torStatusLine(status)}'],
          open: 'Open Receiving settings',
          onTap: () => p.jumpTo(SettingsJump.epicbox),
        ),
    ];
    if (horizontal) return Row(mainAxisSize: MainAxisSize.min, children: [for (final r in rows) SizedBox(width: Ctl.sm, child: r)]);
    return Column(children: rows);
  }
}

class _ServiceRow extends StatefulWidget {
  const _ServiceRow({
    required this.icon,
    required this.name,
    required this.health,
    required this.word,
    required this.lines,
    required this.open,
    required this.onTap,
    required this.compact,
  });

  final IconData icon;
  final String name;
  final ServiceHealth health;
  final String word;
  final List<String> lines;

  /// The card's last line: where a click goes.
  final String open;
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
        Positioned(right: -3.u, bottom: -2, child: EStatusDot(tone, size: 7.u)),
      ],
    );
    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EStatusDot(tone),
            SizedBox(width: Sp.x2),
            Text('${widget.name} · ${widget.word}', style: ts.small.copyWith(color: c.text, fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: Sp.x1),
        for (final l in widget.lines)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 1),
            child: Text(l, style: ts.mono(size: Fs.xs, color: c.dim)),
          ),
        SizedBox(height: Sp.x2),
        Text(widget.open, style: ts.caption.copyWith(color: c.accentText)),
      ],
    );
    return Tooltip(
      richMessage: WidgetSpan(child: card),
      preferBelow: false,
      verticalOffset: 18.u,
      child: Semantics(
        button: true,
        label: '${widget.open}: ${widget.word}',
        hint: widget.lines.join('. '),
        excludeSemantics: true,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (v) => setState(() => _hover = v),
          borderRadius: BorderRadius.circular(Rad.sm),
          child: Container(
            height: 32.u,
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
                      SizedBox(width: Sp.x3),
                      Expanded(child: Text(widget.name, style: ts.small.copyWith(color: c.text, fontWeight: FontWeight.w600))),
                      Text(widget.word, style: ts.caption.copyWith(color: wordColor)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _PhoneTopBar extends ConsumerWidget {
  const _PhoneTopBar({required this.section});

  final DeskSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final locking = ref.watch(deskLockingProvider);
    return Container(
      height: 52.u,
      padding: EdgeInsets.symmetric(horizontal: Sp.x4),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          EpicMark(size: 20.u, color: c.accent),
          SizedBox(width: Sp.x2),
          Flexible(child: Text(appName, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.ts.h3.copyWith(fontSize: 15))),
          const Spacer(),
          const ServiceRows(compact: true, horizontal: true),
          TourTarget(
            id: 'settings',
            child: EIconButton(
              icon: EIcons.settings,
              label: 'Settings',
              color: section == DeskSection.settings ? c.accentText : null,
              onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsNode),
            ),
          ),
          locking
              ? SizedBox.square(dimension: Ctl.sm, child: Center(child: ESpinner(size: Ctl.iconSm)))
              : EIconButton(icon: EIcons.lock, label: 'Lock wallet (${deskKeys('L')})', onPressed: () => lockWallet(ref)),
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
        indicatorColor: index < 0 ? Colors.transparent : c.s3,
        height: 64.u,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: Fs.xs, color: c.dim)),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(size: Ctl.icon, color: index >= 0 && s.contains(WidgetState.selected) ? c.accentText : c.faint),
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

/// The version and build under the compact rail's lock button, on two lines to fit its width.
class _RailVersion extends StatelessWidget {
  const _RailVersion();

  @override
  Widget build(BuildContext context) {
    final style = context.ts.caption.copyWith(fontSize: 10.u, height: 1.2);
    return Semantics(
      container: true,
      label: 'Version $deskVersion',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(deskAppVersion, style: style, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          if (appBuildId.isNotEmpty) Text(appBuildId, style: style, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
