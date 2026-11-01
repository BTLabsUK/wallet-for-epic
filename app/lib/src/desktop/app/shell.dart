// SPDX-License-Identifier: Apache-2.0
import '../../app_info.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind, kBackMouseButton, kForwardMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/theme/brand.dart' show BrandLockup, BrandVariant;
import '../desk_l10n.dart';
import '../data/desk_node.dart' show nodeHost;
import '../data/desk_update.dart' show deskAppVersion, deskUpdateAutoProvider, deskUpdateProvider;
import '../../ui/notices.dart' show NoticeLevel;
import '../../ui/pairing/pairing_notices.dart' show pairingEventOnScreen, pairingNoticeOf;
import '../../models.dart' show PairingCollectTrigger, PairingEventKind;
import '../data/devices_state.dart' show deskDeviceServiceProvider, deskLinkedDevicesOnProvider;
import '../../devices/device_service.dart' show DeviceSyncTrigger;
import '../data/pairing_state.dart' show deskInvoicesShownProvider, deskKeysBackProvider, deskPairingApiProvider, deskPairingEventsProvider, deskPairsProvider;
import '../data/invoice_state.dart' show InvoiceNotice, InvoiceNoticeKind, deskInvoiceBadgeProvider, deskInvoiceNoticesProvider;
import '../screens/invoices/proto_panel.dart' show ProtoButton;
import '../screens/pairing/pair_screens.dart' show showDeskCheckWords;
import '../../ui/invite_link_gate.dart';
import '../data/desk_errors.dart' show deskErrorText;
import '../../levels/wallet_level.dart' show WalletLevel;
import '../data/desk_levels.dart';
import '../screens/settings/history_conflicts.dart' show showHistoryConflicts;
import '../screens/settings/settings_advanced.dart' show advancedHas, AdvancedFeature;
import '../widgets/kit.dart';
import 'desk_app.dart' show deskNavigatorKey;
import 'desk_failover.dart';
import 'rail.dart';
import 'screens.dart';
import 'close_guard.dart';
import 'last_session_offer.dart';
import 'now_slot.dart';
import 'title_bar.dart' show showDeskShortcuts;
import 'tour.dart';

export 'rail.dart' show ServiceRows;

/// The app version the sidebar, About and the support report show, with the build's commit.
final String deskVersion = withBuildId(deskAppVersion);


/// "Ctrl+L", or "⌘L" on macOS.
String deskKeys(String key) => defaultTargetPlatform == TargetPlatform.macOS ? '⌘$key' : 'Ctrl+$key';

/// The window title of each in-app place: `<page> · Epic Cash Desktop`.
String deskPageTitle(AppLocalizations l, DeskRoute r) {
  final page = switch (r.section) {
    DeskSection.receive => switch (r) {
      DeskRoute.importTx => l.deskShellTitleImportTx,
      DeskRoute.finalize => l.deskShellTitleFinalizeTx,
      _ => l.deskShellNavReceive,
    },
    final s? => deskNavLabel(l, s),
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
  Timer? _ownAsk;

  /// The foreground tick of RFC 8.4: the mailboxes of contacts with something pending.
  Timer? _collectTimer;

  void _collect(PairingCollectTrigger trigger) {
    final api = ref.read(deskPairingApiProvider);
    if (api.supported) api.collect(trigger: trigger).ignore();
  }

  @override
  void initState() {
    super.initState();
    // The user's own node is asked every 15 s (failover's way back, the syncing offer); the
    // timer lives with the shell, not in the provider, so a test's container keeps none.
    _ownAsk = Timer.periodic(ownAskBackEvery, (_) {
      if (mounted) unawaited(ref.read(deskFailoverWatchProvider.notifier).askOwn());
    });
    HardwareKeyboard.instance.addHandler(_onKey);
    // The shell shows once the wallet is unlocked: every mailbox, then the tick.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _collect(PairingCollectTrigger.open);
      // After unlock, once: the last session froze or crashed, its log can be sent.
      if (mounted) unawaited(offerDeskLastSessionReport(context, ref));
    });
    _collectTimer = Timer.periodic(const Duration(seconds: 45), (_) => _collect(PairingCollectTrigger.foreground));
    _maybeTour();
    // Update checks from the first unlock on, for the rest of the run (once).
    if (ref.read(deskUpdateAutoProvider)) ref.read(deskUpdateProvider.notifier).schedule();
    // The clipboard is never read here: a pairing link is pasted on the Pair page by a press.
    _focus = AppLifecycleListener(
      onResume: () {
        // The window came back to the front: the other devices are read at once.
        unawaited(ref.read(deskDeviceServiceProvider)?.sync(DeviceSyncTrigger.resume));
        // A node failover that waits longer each time tries again soon.
        ref.read(deskFailoverWatchProvider.notifier).resumed();
      },
    );
  }

  AppLifecycleListener? _focus;

  /// Ctrl+L / ⌘L locks, Ctrl+Q / ⌘Q quits, wherever the focus is (6.1.6 app menu).
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || !mounted) return false;
    if (_onQuestion(e)) return true;
    final hw = HardwareKeyboard.instance;
    if (!(hw.isControlPressed || hw.isMetaPressed) || hw.isShiftPressed || hw.isAltPressed) return false;
    if (e.logicalKey == LogicalKeyboardKey.keyL) {
      lockWallet(ref);
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.keyQ) {
      unawaited(deskClose(ref));
      return true;
    }
    return false;
  }

  /// ? outside a text field lists the keyboard shortcuts.
  bool _onQuestion(KeyEvent e) {
    if (e.character != '?') return false;
    final hw = HardwareKeyboard.instance;
    if (hw.isControlPressed || hw.isMetaPressed || hw.isAltPressed || deskTextFocused() || ref.read(deskTourProvider).open) return false;
    unawaited(showDeskShortcuts());
    return true;
  }

  bool _askingOld = false;

  Future<void> _askOldHistory(List<ImportConflict> conflicts) async {
    if (_askingOld) return;
    _askingOld = true;
    try {
      final choices = await showHistoryConflicts(context, conflicts, oldWallet: true);
      if (!mounted) return;
      await ref.read(deskProvider.notifier).resolveOldHistory(choices);
    } on Object catch (e) {
      if (mounted) showEToast(context, deskErrorText(e, context.l10n), tone: ETone.warn);
    } finally {
      _askingOld = false;
    }
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
    _ownAsk?.cancel();
    _collectTimer?.cancel();
    _focus?.dispose();
    super.dispose();
  }

  /// The tour, once, shortly after the first unlock lands on Overview.
  void _maybeTour() {
    if (!deskTourAuto || widget.at.route != DeskRoute.overview || ref.read(deskTourProvider).seen) return;
    _tourTimer?.cancel();
    _tourTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted && ref.read(deskNavProvider).route == DeskRoute.overview) {
        unawaited(ref.read(deskTourProvider.notifier).openIfUnseen());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final at = widget.at;
    final width = MediaQuery.sizeOf(context).width;
    // What the wallet learned of invoices by itself, as a toast.
    ref.listen(deskInvoiceNoticesProvider, (_, next) {
      final n = next.value;
      if (n != null && mounted) _invoiceToast(context, n);
    });
    // What the pairing engine found (RFC 10.4), as a toast; the screens that wait open the
    // words check themselves, Pending invites keeps the rest.
    ref.listen(deskPairingEventsProvider, (_, next) {
      final e = next.value;
      // A mailbox payment's answer was finalized: Activity shows it posted.
      if (e?.kind == PairingEventKind.paymentFinalized) unawaited(ref.read(deskProvider.notifier).refresh());
      final n = e == null ? null : pairingNoticeOf(context.l10n, e);
      if (n == null || !mounted || pairingEventOnScreen(e!)) return;
      final id = e.pairingId;
      // An answer to an invite, on any screen: the toast opens the words check.
      final check = (e.kind == PairingEventKind.replied || e.kind == PairingEventKind.confirmed) && id != null
          ? (label: context.l10n.noticeCheckWords, run: () => unawaited(showDeskCheckWords(context, ref, id)))
          : null;
      showEToast(
        context,
        n.text,
        tone: switch (n.level) {
          NoticeLevel.success => ETone.ok,
          NoticeLevel.info => ETone.info,
          NoticeLevel.warning => ETone.warn,
          NoticeLevel.error => ETone.risk,
        },
        action: check,
      );
    });
    // Linked devices: the service lives while the shell is up (it reads the channel every 5 s,
    // minimized too).
    ref.watch(deskDeviceServiceProvider);
    // Node failover moved the wallet to another node for this session: said wherever the
    // user is, never asked.
    ref.listen(deskFailoverWatchProvider, (_, _) {});
    // A contact whose keys came back docks the notice on its page, whenever that opens.
    ref.listen(deskKeysBackProvider, (_, _) {});
    ref.listen(deskFailoverProvider, (before, now) {
      if (now != null && now != before && mounted) {
        showEToast(context, context.l10n.deskNodeFailoverSwitched(nodeHost(now.inUse)), tone: ETone.info);
      }
    });
    // The old wallet's history differs from details the user typed: the same per-field
    // "Details differ" choice as a history backup, Mine until they say otherwise.
    ref.listen(deskProvider.select((s) => s.oldHistory), (_, next) {
      if (next.isNotEmpty && mounted) unawaited(_askOldHistory(next));
    });
    // A place of a part switched off (Pairing, Invoices) or one the level hides reads as
    // Overview, or as the Settings landing for a Settings page.
    final shown = deskRouteShown(ref, at.route)
        ? at
        : DeskLocation(at.route.section == DeskSection.settings ? deskSettingsHome(ref) : DeskRoute.overview);
    final page = KeyedSubtree(key: ValueKey(shown.route), child: deskScreen(shown));
    // The page's text is selectable and copyable (selectable.dart); the sidebar is not.
    final main = Material(color: c.bg, child: DeskSelectable(child: page));
    final tour = ref.watch(deskTourProvider.select((t) => t.open));
    final tourStart = ref.watch(deskTourProvider.select((t) => t.start));
    final Widget frame;
    if (width < Bp.phone) {
      frame = Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(child: Column(children: [_PhoneTopBar(section: shown.route.section), Expanded(child: FocusTraversalGroup(child: main))])),
        bottomNavigationBar: _PhoneNav(section: shown.route.section),
      );
    } else {
      final compact = width < Bp.desktop;
      frame = Scaffold(
        backgroundColor: c.bg,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Two groups: Tab finishes the page before it moves to the sidebar.
            FocusTraversalGroup(child: _Sidebar(section: shown.route.section, compact: compact)),
            Expanded(child: FocusTraversalGroup(child: main)),
          ],
        ),
      );
    }
    // Invites a browser opened (pairing, device link) go to their feature's confirm dialog.
    return InviteLinkGate(
      onUnreadable: (context) => showEToast(context, context.l10n.inviteLinkUnreadable, tone: ETone.warn),
      onNoHandler: (context, kind) => showEToast(context, inviteNoHandlerText(context.l10n, kind), tone: ETone.info),
      child: Title(
        title: deskPageTitle(context.l10n, shown.route),
        color: c.accent,
        child: Stack(
          children: [
            Positioned.fill(child: ExcludeFocus(excluding: tour, child: frame)),
            if (tour) Positioned.fill(child: DeskTourOverlay(key: ValueKey(tourStart), startAt: tourStart)),
            // The clickable prototype (web build on the mock): plays the other side of invoices.
            if (kIsWeb && !tour) const ProtoButton(),
          ],
        ),
      ),
    );
  }
}

/// A notice about an invoice, in the app's language. A paid one is the only good news; none
/// says money came in for an invoice this wallet pays.
void _invoiceToast(BuildContext context, InvoiceNotice n) {
  final l = context.l10n;
  final (text, tone) = switch (n.kind) {
    InvoiceNoticeKind.paid => (l.deskInvNoticePaid(n.who, formatEpicL(l, n.amount)), ETone.ok),
    InvoiceNoticeKind.declined => (l.deskInvNoticeDeclined(n.who), ETone.warn),
    InvoiceNoticeKind.issuedExpired => (l.deskInvNoticeIssuedExpired, ETone.neutral),
    InvoiceNoticeKind.bounced => (l.deskInvIssuerBounced(n.who), ETone.warn),
    InvoiceNoticeKind.withdrawn => (l.deskInvNoticeWithdrawn(n.who), ETone.neutral),
    InvoiceNoticeKind.expired => (l.deskInvNoticeExpired, ETone.neutral),
    InvoiceNoticeKind.unknownPayment => (l.deskInvNoticeUnknownPayment, ETone.warn),
    InvoiceNoticeKind.unknownAnswer => (l.deskInvNoticeUnknownAnswer, ETone.warn),
    InvoiceNoticeKind.receiveSuperseded => (l.deskInvNoticeReceiveSuperseded, ETone.neutral),
    InvoiceNoticeKind.requestOnDevice => (l.devicesForwardedInvoice(n.who), ETone.neutral),
  };
  showEToast(context, text, tone: tone);
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

/// Lock: back to the unlock screen, the wallet closed. [then] is Unlock's argument (an
/// `UnlockPick` to have another wallet selected).
Future<void> lockWallet(WidgetRef ref, {Object? then}) async {
  if (ref.read(deskLockingProvider)) return;
  ref.read(deskLockingProvider.notifier).set(true);
  // A payment under way is never ended by the lock: the lock waits for it.
  final shown = deskNavigatorKey.currentContext;
  if (ref.read(deskApiProvider).busy && shown != null) showEToast(shown, shown.l10n.deskShellLocksAfterSend, tone: ETone.neutral);
  try {
    await ref.read(deskProvider.notifier).lock();
  } finally {
    ref.read(deskLockingProvider.notifier).set(false);
  }
  // Nothing of the wallet stays over the unlock screen: open dialogs and the tour go.
  deskNavigatorKey.currentState?.popUntil((r) => r.isFirst);
  ref.read(deskTourProvider.notifier).close();
  ref.read(deskNavProvider.notifier).reset(DeskRoute.unlock, then);
}

/// Quit (Ctrl+Q, the app menu): the one close rule of close_guard.dart.
Future<void> quitWallet(WidgetRef ref) => deskClose(ref);

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.section, required this.compact});

  final DeskSection? section;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final nav = ref.read(deskNavProvider.notifier);
    final pending = ref.watch(deskProvider.select((s) => s.pendingFiles));
    final invoices = invoicesShown(ref);
    final toPay = ref.watch(deskInvoiceBadgeProvider);
    final l = context.l10n;
    return Semantics(
      container: true,
      label: l.deskShellMainNav,
      child: Container(
        width: compact ? Ctl.rail : Ctl.sidebar,
        decoration: BoxDecoration(color: c.s1, border: Border(right: BorderSide(color: c.line))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The brand is in the title bar's part above (title_bar.dart).
            SizedBox(height: Sp.x2),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (s, route, icon) in deskNav)
                      if ((s != DeskSection.invoices || invoices) &&
                          (s != DeskSection.outputs || outputsShown(ref)))
                      TourTarget(
                        id: 'nav-${s.name}',
                        child: ENavItem(
                          icon: icon,
                          label: deskNavLabel(l, s),
                          selected: section == s,
                          compact: compact,
                          count: switch (s) {
                            DeskSection.activity => pending,
                            DeskSection.invoices => toPay,
                            _ => null,
                          },
                          onTap: () => nav.go(route),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: Sp.x2),
                      child: Divider(height: 1, color: c.line),
                    ),
                    TourTarget(
                      id: 'nav-settings',
                      child: ENavItem(
                        icon: EIcons.settings,
                        label: l.deskShellNavSettings,
                        selected: section == DeskSection.settings,
                        compact: compact,
                        onTap: () => nav.go(deskSettingsHome(ref)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // What goes on now, else Help · Report a problem (now_slot.dart). The wallet, the
            // status and Lock are in the title bar.
            NowSlot(compact: compact),
          ],
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
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: BrandLockup(variant: BrandVariant.desktop, size: 24.u, textRatio: 0.58),
            ),
          ),
          const Spacer(),
          const ServiceRows(compact: true, horizontal: true),
          TourTarget(
            id: 'nav-settings',
            child: EIconButton(
              icon: EIcons.settings,
              label: context.l10n.deskShellNavSettings,
              color: section == DeskSection.settings ? c.accentText : null,
              onPressed: () => ref.read(deskNavProvider.notifier).go(deskSettingsHome(ref)),
            ),
          ),
          locking
              ? SizedBox.square(dimension: Ctl.sm, child: Center(child: ESpinner(size: Ctl.iconSm)))
              : EIconButton(icon: EIcons.lock, label: context.l10n.deskShellLockWallet(deskKeys('L')), onPressed: () => lockWallet(ref)),
        ],
      ),
    );
  }
}

/// Whether [route] is shown: the pairing places need Pairing, the invoice places Invoices
/// (Settings › Advanced › Experimental), and the level may hide the page ([deskLevelHides]).
bool deskRouteShown(WidgetRef ref, DeskRoute route) {
  if (route == DeskRoute.outputs) return outputsShown(ref);
  if (deskLevelHides(ref.watch(deskLevelUiProvider), route)) return false;
  return switch (route) {
    DeskRoute.pair || DeskRoute.pairPending => ref.watch(deskPairsProvider),
    DeskRoute.invoices || DeskRoute.invoiceIssue || DeskRoute.invoiceReview || DeskRoute.settingsInvoices =>
      ref.watch(deskInvoicesShownProvider),
    DeskRoute.settingsDevices => ref.watch(deskLinkedDevicesOnProvider),
    _ => true,
  };
}

/// Where Settings opens: Node, or Appearance at a level without the node page.
DeskRoute deskSettingsHome(WidgetRef ref) =>
    ref.watch(deskLevelUiProvider).nodeSettings ? DeskRoute.settingsNode : DeskRoute.settingsAppearance;

/// Advanced › Outputs at Deep end, or a split or consolidation the node did not take yet at any
/// level (never hide what is in use: its Broadcast again and Cancel live there).
bool outputsShown(WidgetRef ref) =>
    (ref.watch(deskLevelUiProvider).level == WalletLevel.everything && advancedHas(ref, AdvancedFeature.outputs)) ||
    (ref.watch(deskProvider).txs?.any((t) => t.notPosted) ?? false);

/// Invoices on the rail: Deep end with Invoices on and a wallet that takes them.
bool invoicesShown(WidgetRef ref) => ref.watch(deskLevelUiProvider).invoicesPage && ref.watch(deskInvoicesShownProvider);

class _PhoneNav extends ConsumerWidget {
  const _PhoneNav({required this.section});

  final DeskSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final invoices = invoicesShown(ref);
    final items = [
      for (final n in deskNav)
        if ((n.$1 != DeskSection.invoices || invoices) && (n.$1 != DeskSection.outputs || outputsShown(ref))) n,
    ];
    final index = items.indexWhere((n) => n.$1 == section);
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
        onDestinationSelected: (i) => ref.read(deskNavProvider.notifier).go(items[i].$2),
        destinations: [
          for (final (s, _, icon) in items)
            NavigationDestination(icon: Icon(icon), label: deskNavLabel(context.l10n, s)),
        ],
      ),
    );
  }
}
