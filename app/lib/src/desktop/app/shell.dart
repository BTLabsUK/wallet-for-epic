// SPDX-License-Identifier: Apache-2.0
import '../../app_info.dart';
import '../../contact_check.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind, kBackMouseButton, kForwardMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pairing_text.dart' show InviteSource;
import '../../settings.dart' show clockProvider;
import '../../settings_file/host_settings.dart' show appConfig;
import '../../stale_open.dart';
import '../../trust_ids.dart';
import '../desk_l10n.dart';
import '../data/desk_node.dart' show nodeHost;
import '../data/desk_update.dart' show deskAppVersion, deskUpdateAutoProvider, deskUpdateProvider;
import '../../ui/notices.dart' show NoticeLevel;
import '../../notice_digest.dart' show DigestPlace, HeldNotice, NoticeDigest, raiseNotice;
import '../../notice_digest_text.dart';
import '../../ui/pairing/pairing_notices.dart' show heldKindOf, pairingEventOnScreen, pairingNoticeOf;
import '../../models.dart' show PairingCollectTrigger, PairingEventKind, PairingRecord;
import '../data/devices_state.dart' show deskDeviceServiceProvider;
import '../data/name_service_state.dart' show deskNameServiceProvider;
import '../../name_service/name_service_service.dart' show NameServiceSyncTrigger;
import '../../devices/device_service.dart' show DeviceSyncTrigger;
import '../../trust/profile_watch.dart';
import '../data/pairing_state.dart' show deskPairingsProvider, deskPairingName, deskContactKeysOf, deskPairingCall, deskInvoicesShownProvider, deskKeysBackProvider, deskPairRequestsProvider, deskNoticeDigestsProvider, deskPairingApiProvider, deskPairingEventsProvider, deskPairsProvider, deskContactsInFlightProvider;
import '../data/invoice_state.dart' show InvoiceNotice, InvoiceNoticeKind, deskInvoiceBadgeProvider, deskInvoiceNoticesProvider;
import '../screens/invoices/proto_panel.dart' show ProtoButton;
import '../screens/pairing/pair_screens.dart' show deskOpenPairingText, showDeskCheckWords, showDeskPairRequests;
import '../screens/pairing/relay_move_dialog.dart' show deskAskRelayMove;
import '../../relay_moves.dart' show relayMoveToAsk;
import '../../ui/invite_link_gate.dart';
import '../../scan/incoming_link.dart' show incomingLinkProvider, linkBusyProvider;
import '../../scan/scan_checks.dart' show CodeOrigin;
import '../screens/transfer/send_screen.dart' show SendArgs;
import '../../ui/pairing/invite_links.dart';
import '../../pairing_providers.dart' show requestFromContact;
import '../../models.dart' show PairingEvent, epicboxKey;
import '../data/desk_errors.dart' show deskErrorText;
import '../../levels/wallet_level.dart' show WalletLevel;
import '../data/desk_levels.dart';
import '../data/node_fit_facts.dart' show NodeFitFacts, nodeFitFactsProvider;
import '../screens/settings/history_conflicts.dart' show showHistoryConflicts;
import '../screens/settings/settings_advanced.dart' show advancedHas, AdvancedFeature;
import '../screens/settings/settings_frame.dart' show SettingsColumn, settingsTakeover;
import '../screens/settings/search/search_slot.dart' show SettingsSearchKeys, openSettingsSearch, settingsQueryProvider;
import '../screens/settings/search/settings_sections.dart' show settingsFallback, setViewProvider;
import '../widgets/kit.dart';
import 'desk_app.dart' show deskNavigatorKey;
import 'desk_failover.dart';
import 'rail.dart';
import 'screens.dart';
import 'close_guard.dart';
import 'last_session_offer.dart';
import 'now_slot.dart';
import 'update_strip.dart' show DeskUpdateStrip;
import 'old_app_offer.dart';
import 'title_bar.dart' show showDeskShortcuts;
import 'tour.dart';

export 'rail.dart' show ServiceRows;

/// The app version About, the title bar's tooltip and the support report show, with the
/// build's commit.
final String deskVersion = withBuildId(deskAppVersion);


/// "Ctrl+L", or "⌘L" on macOS.
String deskKeys(String key) => defaultTargetPlatform == TargetPlatform.macOS ? '⌘$key' : 'Ctrl+$key';

/// The window title of each in-app place: `<page> · BT Wallet`.
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

  /// Overview was left before the tour opened by itself.
  bool _tourMissed = false;
  Timer? _ownAsk;
  Timer? _behindAsk;

  /// The foreground tick of RFC 8.4: the mailboxes of contacts with something pending.
  ContactCheck? _contactCheck;

  Timer? _linkRetry;

  /// Adds the open time to the local count the node's fit check reads (this computer only).
  Timer? _openCount;

  /// A payment link or code a browser opened (`epiccash://pay/1/…`): Send opens with it, read as
  /// a paste from a link. Over a dialog or the tour it waits, so nothing in progress is closed.
  void _openLink() {
    _linkRetry?.cancel();
    _linkRetry = null;
    if (!mounted || ref.read(linkBusyProvider) || ref.read(incomingLinkProvider) == null) return;
    if (_navHeld(ref)) {
      _linkRetry = Timer(const Duration(seconds: 2), _openLink);
      return;
    }
    final link = ref.read(incomingLinkProvider.notifier).take();
    if (link == null) return;
    ref.read(deskNavProvider.notifier).go(DeskRoute.send, SendArgs(code: link.text, codeOrigin: CodeOrigin.link));
  }

  /// What a collect reads besides the contacts. The listings are drained where the contacts'
  /// mailboxes are read, never in the background.
  Future<void> _sync(PairingCollectTrigger trigger) async {
    final t = switch (trigger) {
      PairingCollectTrigger.open => NameServiceSyncTrigger.open,
      _ => NameServiceSyncTrigger.tick,
    };
    await ref.read(deskNameServiceProvider)?.sync(t);
  }

  /// The check of every contact, for an open or a resume.
  Future<void> _open() async {
    final check = _contactCheck;
    if (check != null) return check.checkAll(PairingCollectTrigger.open);
    final api = ref.read(deskPairingApiProvider);
    if (api.supported) await api.collect(trigger: PairingCollectTrigger.open);
    await _sync(PairingCollectTrigger.open);
  }

  /// An incoming pair invite (a tapped link, a scheme open): the confirm dialog, never a
  /// pairing by itself.
  Future<void> _pairInvite(BuildContext _, InviteLink link) async {
    if (!mounted) return;
    // A core without pairing: says so, never the pairing calls (as the phone's sheet).
    if (!ref.read(deskPairingApiProvider).supported) {
      showEToast(context, context.l10n.scanPairingUnavailable, tone: ETone.warn);
      return;
    }
    await deskOpenPairingText(context, ref, link.invite, source: InviteSource.opened);
  }

  /// A request to pair: the list reads it again (and dismisses a stranger's once the address
  /// book is known); from a contact it is a toast that opens the requests. One that came
  /// before the book loaded waits for it.
  Future<void> _pairRequested(PairingEvent e) async {
    final contacts = await _contactsLoaded();
    if (!mounted) return;
    unawaited(ref.read(deskPairRequestsProvider.notifier).reload());
    final keys = deskContactKeysOf(contacts, closed: ref.read(deskProvider).status?.contactsClosed ?? false);
    if (!requestFromContact(keys, e)) return;
    final key = epicboxKey(e.sender!);
    final name = contacts!.where((c) => c.epicbox != null && epicboxKey(c.epicbox!) == key).firstOrNull?.name ?? e.name;
    showEToast(context, context.l10n.pairWantsToPair(name), tone: ETone.info, action: (label: context.l10n.noticeOpen, run: () => unawaited(showDeskPairRequests(context, ref))));
  }

  /// The address book once it is loaded (at once when it is).
  Future<List<Contact>?> _contactsLoaded() {
    final now = ref.read(deskProvider).contacts;
    if (now != null) return Future.value(now);
    final loaded = Completer<List<Contact>?>();
    late final ProviderSubscription<List<Contact>?> sub;
    sub = ref.listenManual(deskProvider.select((s) => s.contacts), (_, next) {
      if (next == null || loaded.isCompleted) return;
      loaded.complete(next);
      sub.close();
    });
    return loaded.future;
  }

  @override
  void initState() {
    super.initState();
    registerInviteHandler(InviteKind.pair, _pairInvite);
    // The user's own node is asked every 15 s (failover's way back, the syncing offer); the
    // timer lives with the shell, not in the provider, so a test's container keeps none.
    _ownAsk = Timer.periodic(ownAskBackEvery, (_) {
      if (mounted) unawaited(ref.read(deskFailoverWatchProvider.notifier).askOwn());
    });
    _behindAsk = Timer.periodic(behindAskEvery, (_) {
      if (mounted) unawaited(ref.read(deskFailoverWatchProvider.notifier).askBehind());
    });
    HardwareKeyboard.instance.addHandler(_onKey);
    // The shell shows once the wallet is unlocked: every mailbox, then the tick.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _open().ignore();
      // A link that came before the unlock.
      if (mounted) _openLink();
      // After unlock, once: the last session froze or crashed, its log can be sent.
      if (mounted) unawaited(offerDeskLastSessionReport(context, ref));
      // macOS: the app from before the rename is still installed; offer to move it to the Bin.
      if (mounted) unawaited(offerDeskOldAppRemoval(context, ref));
      // A wallet not opened for a while says so, once per open.
      final stale = mounted ? ref.read(staleOpenShownProvider.notifier).take(ref.read(clockProvider)()) : null;
      if (stale != null && mounted) {
        showEToast(context, context.l10n.contactsStaleOpened(stale), tone: ETone.info);
        // The check runs in the background; a contact it gets no answer from shows "Not answering".
        unawaited(deskPairingCall(ref, (api) => api.checkContacts()).then<void>((_) {}, onError: (Object _) {}));
      }
    });
    final boosts = ref.read(deskApiProvider).boosts;
    if (boosts != null) {
      _contactCheck = ContactCheck(
        boosts: boosts,
        collect: (trigger, {only}) async {
          final api = ref.read(deskPairingApiProvider);
          return api.supported ? collectCounting(api, trigger, only: only) : 0;
        },
        sync: _sync,
        inFlight: () => ref.read(deskContactsInFlightProvider),
        idleChecks: appConfig.contactsIdleChecks,
        inFlightEvery: appConfig.contactsInFlightCheck,
      )..start();
    }
    _openCount = Timer.periodic(NodeFitFacts.tick, (_) {
      if (mounted) unawaited(ref.read(nodeFitFactsProvider).addOpen(NodeFitFacts.tick).catchError((Object _) {}));
    });
    _maybeTour();
    // A paired contact that starts or stops taking payments, said once a day per direction.
    ref.listenManual(deskPairingsProvider, (_, next) {
      final records = next.value;
      if (records == null || !mounted) return;
      for (final c in _profiles.update(records)) {
        final l = context.l10n;
        final name = deskPairingName(c.record, ref.read(deskProvider).contacts, l: l);
        showEToast(context, c.takesPayments ? l.contactTakesPaymentsAgain(name) : l.contactNoPaymentsNamed(name), tone: ETone.info);
      }
      // A domain-backed contact's relay move not shown yet: asked once, as a dialog.
      final move = relayMoveToAsk(records);
      if (move != null) unawaited(_askMove(move));
    }, fireImmediately: true);
    // Update checks from the first unlock on, for the rest of the run (once).
    if (ref.read(deskUpdateAutoProvider)) ref.read(deskUpdateProvider.notifier).schedule();
    // The clipboard is never read here: a pairing link is pasted on the Pair page by a press.
    _focus = AppLifecycleListener(
      onResume: () {
        // The window came back to the front: the other devices are read at once.
        unawaited(ref.read(deskDeviceServiceProvider)?.sync(DeviceSyncTrigger.resume));
        unawaited(ref.read(deskNameServiceProvider)?.sync(NameServiceSyncTrigger.resume));
        // A node failover that waits longer each time tries again soon.
        ref.read(deskFailoverWatchProvider.notifier).resumed();
        // The contacts' mailboxes too, as the phone does on resume (the shell exists only
        // unlocked; the collect itself stays off in Node only, Kill switch and with Epicbox off).
        if (mounted) _open().ignore();
      },
    );
  }

  AppLifecycleListener? _focus;
  late final PeerProfileWatch _profiles = PeerProfileWatch(ref.read(clockProvider));

  /// The hidden Settings place last answered with a fallback toast (once per place).
  DeskLocation? _fellBack;

  /// Around the Settings takeover: Esc bubbles up to it from the page and the column.
  final _settingsFocus = FocusNode(debugLabel: 'settings takeover', skipTraversal: true);

  /// Esc in Settings goes back to the wallet page it came from: not while a text field or a
  /// menu has it (those take Esc first and stop it), a dialog or the tour is open, or a search
  /// is typed (Esc clears it first).
  bool _onSettingsEsc(KeyEvent e) {
    if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.escape || !mounted) return false;
    final hw = HardwareKeyboard.instance;
    if (hw.isShiftPressed || hw.isControlPressed || hw.isMetaPressed || hw.isAltPressed) return false;
    if (ref.read(deskNavProvider).route.section != DeskSection.settings) return false;
    if (deskTextFocused() || _navHeld(ref) || ref.read(settingsQueryProvider).trim().isNotEmpty) return false;
    ref.read(deskNavProvider.notifier).leaveSettings();
    return true;
  }

  /// Ctrl+L / ⌘L locks, Ctrl+Q / ⌘Q quits, wherever the focus is (6.1.6 app menu). Esc in
  /// Settings when nothing in it has the focus (the focus tree would not see the key).
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || !mounted) return false;
    if (_onQuestion(e)) return true;
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      final inside = _settingsFocus.hasFocus;
      return !inside && _onSettingsEsc(e);
    }
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
    // Ctrl+K from a wallet page: Settings with its search focused (inside Settings the
    // search's own keys take it).
    if (e.logicalKey == LogicalKeyboardKey.keyK && ref.read(deskNavProvider).route.section != DeskSection.settings && !_navHeld(ref)) {
      openSettingsSearch(ref);
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

  bool _askingMove = false;

  Future<void> _askMove(PairingRecord p) async {
    if (_askingMove) return;
    _askingMove = true;
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) await deskAskRelayMove(context, ref, p);
    } on Object catch (e) {
      if (mounted) showEToast(context, deskErrorText(e, context.l10n), tone: ETone.warn);
    } finally {
      _askingMove = false;
    }
  }

  @override
  void didUpdateWidget(DeskShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeTour();
  }

  @override
  void dispose() {
    unregisterInviteHandler(InviteKind.pair, _pairInvite);
    HardwareKeyboard.instance.removeHandler(_onKey);
    _tourTimer?.cancel();
    _ownAsk?.cancel();
    _behindAsk?.cancel();
    _linkRetry?.cancel();
    _contactCheck?.stop();
    _openCount?.cancel();
    _focus?.dispose();
    _settingsFocus.dispose();
    super.dispose();
  }

  /// The tour, once, shortly after the first unlock lands on Overview. Left before it opened
  /// (the user went to another page), it does not open later in this run; Help still has it.
  void _maybeTour() {
    if (!deskTourAuto || _tourMissed || ref.read(deskTourProvider).seen) return;
    if (widget.at.route != DeskRoute.overview) {
      if (_tourTimer != null) _tourMissed = true;
      _tourTimer?.cancel();
      return;
    }
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
    ref.listen(incomingLinkProvider, (_, link) {
      if (link != null) _openLink();
    });
    // What the wallet learned of invoices by itself, as a toast.
    ref.listen(deskInvoiceNoticesProvider, (_, next) {
      final n = next.value;
      if (n != null && mounted) _invoiceToast(context, n);
    });
    // What the pairing engine found (RFC 10.4), as a toast; the screens that wait open the
    // words check themselves, Pending invites keeps the rest.
    ref.listen(deskPairingEventsProvider, (_, next) {
      final e = next.value;
      if (e == null) return;
      // A pairing moved: the next check of every contact is the first wait away.
      _contactCheck?.reset();
      // A mailbox payment's answer was finalized: Activity shows it posted.
      if (e.kind == PairingEventKind.paymentFinalized) unawaited(ref.read(deskProvider.notifier).refresh());
      // A request to pair from someone not in Contacts is dropped unseen.
      if (e.kind == PairingEventKind.requested) return unawaited(_pairRequested(e));
      final n = pairingNoticeOf(context.l10n, e);
      if (n == null || !mounted || pairingEventOnScreen(e)) return;
      final id = e.pairingId;
      // An answer to an invite, on any screen: the toast opens the words check.
      final check = (e.kind == PairingEventKind.replied || e.kind == PairingEventKind.confirmed) && id != null
          ? (label: context.l10n.noticeCheckWords, run: () => unawaited(showDeskCheckWords(context, ref, id)))
          : null;
      void toast() {
        if (!mounted) return;
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
      }
      final held = heldKindOf(e.kind);
      if (held == null) return toast();
      raiseNotice(ref.read(deskApiProvider).messageChecks?.notices, HeldNotice(held, slateId: e.slateId, named: true, show: toast));
    });
    // The result of a run with several notices. Reloading keeps the last value: a digest shows
    // once.
    ref.listen(deskNoticeDigestsProvider, (_, next) {
      final digest = next.value;
      if (digest != null && !next.isLoading && mounted) _digestToast(context, ref, digest);
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
        final host = nodeHost(now.inUse);
        showEToast(context, now.behind ? context.l10n.deskNodeFailoverBehind(host) : context.l10n.deskNodeFailoverSwitched(host), tone: ETone.info);
      }
    });
    // The old wallet's history differs from details the user typed: the same per-field
    // "Details differ" choice as a history backup, Mine until they say otherwise.
    ref.listen(deskProvider.select((s) => s.oldHistory), (_, next) {
      if (next.isNotEmpty && mounted) unawaited(_askOldHistory(next));
    });
    // A place of a part switched off (Pairing, Invoices) or one the level hides reads as
    // Overview, or as the Settings landing for a Settings page.
    // A Settings page the view hides falls back to the first entry of its group, with a toast
    // that says what shows it (review 14).
    final DeskLocation shown;
    if (deskRouteShown(ref, at.route)) {
      shown = at;
    } else if (at.route.section == DeskSection.settings) {
      final back = settingsFallback(context.l10n, ref.watch(setViewProvider), at.route);
      shown = DeskLocation(deskRouteShown(ref, back.route) ? back.route : deskSettingsHome(ref));
      if (back.notice != null && _fellBack != at) {
        _fellBack = at;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showEToast(context, back.notice!, tone: ETone.info);
        });
      }
    } else {
      shown = const DeskLocation(DeskRoute.overview);
    }
    // A link opened over Send starts a new Send (its SendArgs is the key), as from any other page.
    // Otherwise the key stays a ValueKey<DeskRoute>: ValueKey equality compares the type too.
    final linked = shown.route == DeskRoute.send && shown.arg is SendArgs && (shown.arg as SendArgs).code != null;
    final page = KeyedSubtree(key: linked ? ValueKey<SendArgs>(shown.arg! as SendArgs) : ValueKey<DeskRoute>(shown.route), child: deskScreen(shown));
    // The page's text is selectable and copyable (selectable.dart); the sidebar is not.
    // The light backdrop sits under the page and stays put while the page scrolls.
    // The update strip (update_strip.dart) sits above the page in every frame and pushes it down.
    final main = Material(
      color: c.bg,
      child: DeskBackdrop(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [const DeskUpdateStrip(), Expanded(child: DeskSelectable(child: page))],
        ),
      ),
    );
    final tour = ref.watch(deskTourProvider.select((t) => t.open));
    final tourStart = ref.watch(deskTourProvider.select((t) => t.start));
    final Widget frame;
    if (width < Bp.phone) {
      frame = Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(child: Column(children: [_PhoneTopBar(section: shown.route.section), Expanded(child: FocusTraversalGroup(child: main))])),
        bottomNavigationBar: _PhoneNav(section: shown.route.section),
      );
    } else if (shown.route.section == DeskSection.settings && settingsTakeover(context)) {
      // Settings takes the sidebar's place (option 1): its column, then the page. Esc and
      // "← Wallet" go back to the wallet page it came from.
      final nav = ref.read(deskNavProvider.notifier);
      frame = Scaffold(
        backgroundColor: c.bg,
        // The search's keys first (Esc clears a query), then Esc back to the wallet.
        body: Focus(
          focusNode: _settingsFocus,
          skipTraversal: true,
          onKeyEvent: (_, e) => _onSettingsEsc(e) ? KeyEventResult.handled : KeyEventResult.ignored,
          child: SettingsSearchKeys(
            onLeave: nav.leaveSettings,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FocusTraversalGroup(child: SettingsColumn(route: shown.route)),
                Expanded(child: FocusTraversalGroup(child: main)),
              ],
            ),
          ),
        ),
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

/// A digest as one toast that counts the updates and unfolds into one line per kind, each a
/// way to the place that lists what it counts. It outlives a change of screen.
void _digestToast(BuildContext context, WidgetRef ref, NoticeDigest digest) {
  final l = context.l10n;
  (DeskRoute, Object?) routeOf(DigestPlace place) => switch (place) {
    DigestPlace.invoices => (DeskRoute.invoices, InvoicesTab.pay),
    DigestPlace.sentInvoices => (DeskRoute.invoices, InvoicesTab.issue),
    DigestPlace.activity => (DeskRoute.activity, null),
  };
  showEToast(
    context,
    noticeDigestText(l, digest),
    tone: ETone.info,
    stay: true,
    items: [
      for (final item in noticeDigestItems(l, digest))
        (
          label: item.text,
          run: () {
            final (route, arg) = routeOf(item.place);
            ref.read(deskNavProvider.notifier).go(route, arg);
          },
        ),
    ],
  );
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
  if (deskNoLock) return;
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
      child: TrustId(TrustIds.nav, child: Container(
        width: compact ? Ctl.rail : Ctl.sidebar,
        // Light: the white column stands off the warm page with a visible divider.
        decoration: BoxDecoration(color: c.s1, border: Border(right: BorderSide(color: c.tint.a == 0 ? c.line : c.lineStrong))),
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
                          semanticsId: TrustIds.shellNav(s.name),
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
                        semanticsId: TrustIds.navSettings,
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
      )),
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
          // The brand is in the title bar above.
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
          if (deskNoLock)
            const SizedBox.shrink()
          else if (locking)
            SizedBox.square(dimension: Ctl.sm, child: Center(child: ESpinner(size: Ctl.iconSm)))
          else
            EIconButton(icon: EIcons.lock, label: context.l10n.deskShellLockWallet(deskKeys('L')), onPressed: () => lockWallet(ref)),
        ],
      ),
    );
  }
}

/// Whether [route] is shown: the pairing places need Pairing, the invoice places a wallet that
/// takes invoices, and the level may hide the page ([deskLevelHides]).
bool deskRouteShown(WidgetRef ref, DeskRoute route) {
  if (route == DeskRoute.outputs) return outputsShown(ref);
  if (route == DeskRoute.invoices || route == DeskRoute.invoiceReview) return invoicesShown(ref);
  if (deskLevelHides(ref.watch(deskLevelUiProvider), route)) return false;
  return switch (route) {
    DeskRoute.pair => ref.watch(deskPairsProvider),
    DeskRoute.invoiceIssue || DeskRoute.settingsInvoices => ref.watch(deskInvoicesShownProvider),
    _ => true,
  };
}

/// Where Settings opens: Wallet, its first entry, at every view.
DeskRoute deskSettingsHome(WidgetRef ref) => DeskRoute.settingsAccount;

/// Advanced › Outputs at Deep end, or a split or consolidation the node did not take yet at any
/// level (never hide what is in use: its Broadcast again and Cancel live there).
bool outputsShown(WidgetRef ref) =>
    (ref.watch(deskLevelUiProvider).level == WalletLevel.everything && advancedHas(ref, AdvancedFeature.outputs)) ||
    (ref.watch(deskProvider).txs?.any((t) => t.notPosted) ?? false);

/// Invoices on the rail: Deep end with a wallet that takes them, or an invoice to answer at any
/// view (never hide what is in use: a contact's Allow invoices brings them at every view).
bool invoicesShown(WidgetRef ref) =>
    ref.watch(deskInvoicesShownProvider) || (ref.watch(deskApiProvider).supportsInvoices && ref.watch(deskInvoiceBadgeProvider) > 0);

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
