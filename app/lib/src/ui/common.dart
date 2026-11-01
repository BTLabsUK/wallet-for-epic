// SPDX-License-Identifier: Apache-2.0
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show GestureBinding, PointerDownEvent, PointerEvent;
import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../address_format.dart' show displayCase;
import '../address_format.dart' as address_format show shortAddress;
import '../advanced.dart' show NetworkModeRestricted;
import '../amount.dart';
import '../devices/device_ending.dart';
import 'info_hint.dart' show InfoHint;
import '../contacts.dart' show contactNameFor, contactsProvider;
import '../l10n.dart';
import '../network_gate.dart' show NetGate;
import '../phrase_clipboard.dart' show copySecretToClipboard;
import '../pairing_providers.dart' show PairNet, pairNetProvider, pairingNameProvider, pairingSlateProvider, pairingSupportedProvider;
import '../price.dart';
import '../providers.dart';
import '../settings.dart';
import '../stall_retry.dart';
import '../text_join.dart';
import '../wallet_service.dart';
import 'home_screen.dart';
import 'launch_screen.dart';
import 'address_view.dart' show ShortAddressText;
import 'method_names.dart' show methodKindOfTransport;
import 'notices.dart';
import 'badge.dart';
import 'demo_screens.dart' show DemoStripe;
import 'finished_not_posted.dart' show isPostElsewhere;
import 'theme/brand.dart';
import 'theme/protocol.dart';
import 'theme/tokens.dart';
import 'tx_details_screen.dart';
import 'tx_label.dart';
import 'tip.dart';
import 'levels/payment_steps.dart' show paymentStepWord;
import '../levels/level_providers.dart' show levelFeaturesProvider;

export '../models.dart' show txAmount;
export '../text_join.dart';

export 'badge.dart';
export 'notices.dart';

/// Replaces the whole navigation stack with the shell of the open wallet, on its Wallet tab.
void goHome(BuildContext context) {
  ProviderScope.containerOf(
    context,
    listen: false,
  ).read(shellTabProvider.notifier).go(ShellTab.wallet);
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    (_) => false,
  );
}

/// Shows [tab] of the wallet shell and closes every screen over it. With [recipient] (a
/// scanned code, Send again), the Send form takes it as the recipient; with [pairingTo], the
/// paired contact with no address, paid through its mailbox.
void showShellTab(BuildContext context, ShellTab tab, {String? recipient, String? pairingTo}) {
  final container = ProviderScope.containerOf(context, listen: false);
  if (recipient != null) {
    container.read(sendRecipientProvider.notifier).hand(recipient);
  } else if (pairingTo != null) {
    container.read(sendRecipientProvider.notifier).handPairing(pairingTo);
  }
  container.read(shellTabProvider.notifier).go(tab);
  Navigator.of(context).popUntil((route) => route.isFirst);
}

/// Closes the wallet and returns to the unlock screen. [reason] is manual unless the auto-lock
/// locks it ([LockReason.timeout]), which lets the unlock screen start biometrics itself.
void lockWallet(
  BuildContext context,
  WidgetRef ref, {
  LockReason reason = LockReason.manual,
}) {
  ref.read(lockReasonProvider.notifier).set(reason);
  ref.read(sessionProvider.notifier).lock();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LaunchScreen()),
    (_) => false,
  );
}

/// Copies [text] and confirms with a success notice [notice], a whole sentence such as
/// `l.addressCopied` (never a noun with "copied" glued on: other languages inflect it).
/// Never use this for the recovery phrase.
Future<void> copyText(BuildContext context, String text, String notice) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ProviderScope.containerOf(
    context,
    listen: false,
  ).read(noticeProvider.notifier).show(notice, level: NoticeLevel.success);
}

/// [copyText] for secret text (a payment file, pairing words or a link): marked sensitive on
/// Android and cleared after [secretClipboardLifetime] ([copySecretToClipboard]).
Future<void> copySecretText(BuildContext context, String text, String notice) async {
  if (!await copySecretToClipboard(text)) {
    await Clipboard.setData(ClipboardData(text: text));
  }
  if (!context.mounted) return;
  ProviderScope.containerOf(
    context,
    listen: false,
  ).read(noticeProvider.notifier).show(notice, level: NoticeLevel.success);
}

/// The height of the line under the app bar that [SlotScaffold.idle] draws in.
const double progressSlotHeight = 2;

/// A 2 dp line under the app bar for a screen's own status, such as [SlotProgress]. It
/// reserves no more, so nothing moves when work starts or ends. Notices dock under it
/// ([NoticeDock]).
class ProgressSlot extends StatelessWidget {
  const ProgressSlot({super.key, this.idle});

  final Widget? idle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: progressSlotHeight,
      child: ClipRect(child: idle ?? const SizedBox.shrink()),
    );
  }
}

/// A thin progress bar under the app bar, for [SlotScaffold.idle]: work that runs while the
/// screen stays usable. Indeterminate when [value] is null.
class SlotProgress extends StatelessWidget {
  const SlotProgress({super.key, this.value, required this.label});

  final double? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: LinearProgressIndicator(
        minHeight: 2,
        value: value,
        semanticsLabel: label,
      ),
    );
  }
}

/// A [Scaffold] with a [ProgressSlot] under the app bar and the [NoticeDock] under that. With
/// [centered], [body] sits in the middle of the space left (and scrolls when it does not fit);
/// otherwise it starts right below the dock, which moves it down while a notice shows. [idle]
/// is what the slot shows, such as a [SlotProgress]. With [glow], the screen gets the lit
/// Protocol backdrop, its light at that point.
class SlotScaffold extends StatefulWidget {
  const SlotScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.centered = false,
    this.idle,
    this.glow,
    this.breathing = false,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool centered;
  final Widget? idle;
  final Alignment? glow;

  /// With [glow]: the light swells and fades slowly ([ProtocolBackdrop.breathing]).
  final bool breathing;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  State<SlotScaffold> createState() => _SlotScaffoldState();
}

class _SlotScaffoldState extends State<SlotScaffold> {
  final DockMeter _dock = DockMeter();

  @override
  Widget build(BuildContext context) {
    final body = widget.body;
    final scaffold = Scaffold(
      appBar: widget.appBar,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The web demo's stripe (B-05); nothing outside a running demo.
          const DemoStripe(),
          ProgressSlot(idle: widget.idle),
          MeasureDock(meter: _dock, child: const NoticeDock()),
          Expanded(
            child: StillUnderDock(
              meter: _dock,
              child: widget.centered ? CenteredScroll(child: body) : body,
            ),
          ),
        ],
      ),
    );
    final glow = widget.glow;
    return glow == null
        ? scaffold
        : ProtocolBackdrop(
            focus: glow,
            breathing: widget.breathing,
            child: scaffold,
          );
  }
}

/// Keeps a scrolling [child] still on screen while the [NoticeDock] above it opens or closes
/// for a passing notice: as the dock moves the body's top edge, the body scrolls by as much in
/// the same layout pass, so the row under the finger stays and a second tap lands where the
/// first did (android-02). A list too short to scroll that far has no room to do it, so while
/// the dock is open [DockSlack] gives the lists that read it ([ScreenBody], Settings) empty
/// room below their last row. The rows that slide under the card come back when it leaves a
/// few seconds later. A persistent notice (the update banner, there for minutes) instead
/// pushes the content down and takes its own space, with no slack, so nothing sits under it
/// (android-18). So does a passing notice that no finger led to: one after a tap in a dialog
/// or on another screen, or from the wallet by itself. Holding still would only slide the top
/// of the screen under the card (a status card's header, A-07), with no finger to keep still
/// for. The finger counts while the last press anywhere in the app was in this body, at most
/// [touchWindow] before the notice. A change at the bottom (the keyboard) is left alone.
/// [meter] reads the [NoticeDock]'s height, so the slack lasts exactly as long as it is open.
class StillUnderDock extends ConsumerStatefulWidget {
  const StillUnderDock({super.key, required this.child, this.meter});

  final Widget child;
  final DockMeter? meter;

  /// How long after a press in the body a notice still counts as led by it.
  static const Duration touchWindow = Duration(seconds: 3);

  @override
  ConsumerState<StillUnderDock> createState() => _StillUnderDockState();
}

/// The last press anywhere in the app: its pointer and when it went down.
int _lastPress = -1;
DateTime _lastPressAt = DateTime.fromMillisecondsSinceEpoch(0);
bool _pressRoute = false;

void _onAnyPointer(PointerEvent event) {
  if (event is! PointerDownEvent) return;
  _lastPress = event.pointer;
  _lastPressAt = DateTime.now();
}

class _StillUnderDockState extends ConsumerState<StillUnderDock> {
  final _use = SlackUse();
  ScrollPosition? _position;
  double? _dockBefore;
  bool _slack = false;

  /// Whether the dock's last change pushes the content: a persistent notice, or one no press
  /// in this body led to; opening for it, or closing after it. Otherwise the content stays.
  bool _push = false;

  /// The last press in this body.
  int _press = -2;

  @override
  void initState() {
    super.initState();
    if (!_pressRoute) {
      _pressRoute = true;
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onAnyPointer);
    }
  }

  /// Whether a finger in this body led to the notice arriving now.
  bool get _touched =>
      _press == _lastPress && DateTime.now().difference(_lastPressAt) <= StillUnderDock.touchWindow;

  double get _dockHeight => widget.meter?.height ?? 0;

  bool _onMetrics(ScrollMetricsNotification n) {
    if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
      _position = Scrollable.maybeOf(n.context)?.position;
    }
    return false;
  }

  /// In the body's layout, after the dock's: the body's top moved by as much as the dock grew.
  void _onLayout() {
    final height = _dockHeight;
    final before = _dockBefore;
    _dockBefore = height;
    if (_slack && height < 0.5 && ref.read(noticeProvider) == null) {
      _slack = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    final position = _position;
    if (before == null || position == null || !position.hasPixels) return;
    final moved = height - before;
    if (moved.abs() < 0.01 || _push) return;
    var to = math.max(position.pixels + moved, position.minScrollExtent);
    // Without slack to scroll into, the content moves by the rest.
    if (!_use.used) to = math.min(to, math.max(position.maxScrollExtent, position.pixels));
    position.correctBy(to - position.pixels);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Notice?>(noticeProvider, (previous, notice) {
      if (notice == null) return; // Closing goes the way it opened.
      // Decided as the dock opens; a notice replacing one keeps its way, unless persistent.
      _push = notice.persistent || (previous == null || previous.persistent ? !_touched : _push);
    });
    // Slack from the moment a notice arrives, before the dock has moved anything, and until
    // the dock is shut; none for a notice that pushes the content instead.
    final notice = ref.watch(noticeProvider);
    if (notice != null && notice.persistent) {
      _push = true;
    } else if (!_push && (notice != null || _dockHeight >= 0.5)) {
      _slack = true;
    }
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onMetrics,
      child: Listener(
        onPointerDown: (e) => _press = e.pointer,
        child: DockSlack(
          extra: _slack ? MediaQuery.sizeOf(context).height : 0,
          use: _use,
          child: _OnLayout(onLayout: _onLayout, child: widget.child),
        ),
      ),
    );
  }
}

/// The height the [NoticeDock] had in its last layout.
class DockMeter {
  double height = 0;
}

/// [child] with its height written to [meter] as it is laid out.
class MeasureDock extends SingleChildRenderObjectWidget {
  const MeasureDock({super.key, required this.meter, super.child});

  final DockMeter meter;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasureDock(meter);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderMeasureDock).meter = meter;
}

class _RenderMeasureDock extends RenderProxyBox {
  _RenderMeasureDock(this.meter);

  DockMeter meter;

  @override
  void performLayout() {
    super.performLayout();
    meter.height = size.height;
  }
}

/// Whether a list under a [DockSlack] reads it.
class SlackUse {
  bool used = false;
}

/// Runs [onLayout] in its own layout, before its child's.
class _OnLayout extends SingleChildRenderObjectWidget {
  const _OnLayout({required this.onLayout, super.child});

  final VoidCallback onLayout;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderOnLayout(onLayout);

  @override
  void updateRenderObject(BuildContext context, _RenderOnLayout renderObject) =>
      renderObject.onLayout = onLayout;
}

class _RenderOnLayout extends RenderProxyBox {
  _RenderOnLayout(this.onLayout);

  VoidCallback onLayout;

  @override
  void performLayout() {
    onLayout();
    super.performLayout();
  }
}

/// Empty room for a scrolling list under a docked notice ([StillUnderDock]): as tall as the
/// screen while the dock is open, else none. A list adds it to its bottom padding with [pad].
class DockSlack extends InheritedWidget {
  const DockSlack({super.key, required this.extra, required this.use, required super.child});

  final double extra;
  final SlackUse use;

  /// [base] with the slack under it.
  static EdgeInsets pad(BuildContext context, EdgeInsets base) {
    final slack = context.dependOnInheritedWidgetOfExactType<DockSlack>();
    if (slack == null) return base;
    slack.use.used = true;
    return slack.extra == 0 ? base : base.copyWith(bottom: base.bottom + slack.extra);
  }

  @override
  bool updateShouldNotify(DockSlack old) => old.extra != extra;
}

/// [child] in the middle of the space it gets, scrolling when it does not fit. For a short
/// body such as [CenteredBody], in a scaffold or a tab.
class CenteredScroll extends StatelessWidget {
  const CenteredScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// [atomic] as text with its unit after a no-break space, as a row shows it ([epicFor],
/// [AmountSurface.row]: four decimals, cut off, never rounded). The exact amount, for commit
/// surfaces, is [epicExact].
String epicText(AppLocalizations l, BigInt atomic) => epicFor(l, atomic);

/// [atomic] with every decimal and its unit ([AmountSurface.exact]): where money is committed
/// or inspected (the review, the payment's details, its QR code), the balance sheet.
String epicExact(AppLocalizations l, BigInt atomic) =>
    epicFor(l, atomic, surface: AmountSurface.exact);

/// What an amount shows while balances are hidden.
const String hiddenAmount = '•••••';

/// [base] in the data face every amount but the balance headline wears: JetBrains Mono with
/// tabular figures, so digits line up from row to row.
TextStyle amountStyle(BuildContext context, [TextStyle? base]) =>
    (base ?? const TextStyle()).copyWith(
      fontFamily: context.tokens.monoFamily,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

/// An amount's text ([epicFor], [epicText], [epicExact], [signedEpic]) in [amountStyle]: the
/// phone's one amount widget, the desktop's being `EMoney`.
class AmountText extends StatelessWidget {
  const AmountText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: amountStyle(context, style),
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
  );
}

/// The exact amount behind a headline figure, for its tooltip: a tap on the phone, a hover
/// with a mouse. None while amounts are hidden.
Widget exactAmountTip(
  BuildContext context,
  BigInt atomic, {
  required bool hidden,
  required Widget child,
}) {
  if (hidden) return child;
  // The desktop's screens may sit outside the phone's localizations (its tests do): English then.
  final l = Localizations.of<AppLocalizations>(context, AppLocalizations) ?? englishStrings;
  return Tip.value(l.balanceExactTip(epicExact(l, atomic)), child: child);
}

/// [epicText], or [epicExact] with [exact], or [hiddenAmount] when [hidden].
String shownEpic(
  AppLocalizations l,
  BigInt atomic, {
  required bool hidden,
  bool exact = false,
}) => hidden
    ? hiddenAmount
    : exact
    ? epicExact(l, atomic)
    : epicText(l, atomic);

/// An epicbox address short enough for a list or a title: the first and last 6 characters of
/// the key around an ellipsis, then `@relay`. With [ownServer] (the host of the wallet's own
/// epicbox server), `@relay` is dropped when it is that server, since it tells the user nothing.
/// URLs, and keys already short, come back as they are. Show the full address wherever the user
/// may need to check or copy it.
String shortAddress(String address, {String? ownServer, bool relay = true}) {
  // Scheme and host in lower case, as every address is shown; a key keeps its case.
  final text = displayCase(address.trim());
  final lower = text.toLowerCase();
  // A link: its host:port whole, without the scheme (address_format.dart's compact form);
  // a host is never cut inside, and the full link stays on the details.
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return address_format.shortAddress(text, compact: true);
  }
  // An onion: the ends of its 56 characters, then `.onion`, which says what it is.
  if (lower.endsWith('.onion')) {
    final name = text.substring(0, text.length - '.onion'.length);
    return name.length <= 14
        ? text
        : '${name.substring(0, 6)}…${name.substring(name.length - 6)}.onion';
  }
  final at = text.indexOf('@');
  final key = at < 0 ? text : text.substring(0, at);
  // Level 1 names no server ([LevelFeatures.serverNames]): the key alone ([relay] false).
  var server = at < 0 || !relay ? '' : text.substring(at);
  if (ownServer != null && server.isNotEmpty) {
    final host = server.substring(1).split(':').first.toLowerCase();
    if (host == ownServer.trim().toLowerCase()) server = '';
  }
  final shortKey = key.length <= 14
      ? key
      : '${key.substring(0, 6)}…${key.substring(key.length - 6)}';
  return '$shortKey$server';
}

/// `2,500,000`, with [l]'s thousands separator.
String groupDigits(AppLocalizations l, Object number) => localInt(l, number);

/// The display settings every amount depends on: hidden or not, and the fiat price.
({bool hidden, double? price, String currency}) amountDisplay(WidgetRef ref) {
  final settings = ref.watch(appSettingsProvider).value ?? const AppSettings();
  return (
    hidden: settings.hideBalances,
    // Price is off in Node only and Kill switch: the figure is hidden, never a stale one.
    price: settings.showFiat && !ref.watch(networkModeProvider).restricted ? ref.watch(priceProvider).value : null,
    currency: settings.fiatCurrency,
  );
}

/// `≈ 1.23 USD` for [atomic], or null when there is no price or amounts are hidden.
///
/// With [short], as beside a balance or in a row, a value of 1,000 or more shows no cents:
/// [fiatText] rounds to cents, then the cents are dropped (`≈ 8,820,000 USD`), so 999.995
/// shows as `1,000`. It is an estimate either way.
String? approxFiat(
  AppLocalizations l,
  BigInt atomic,
  ({bool hidden, double? price, String currency}) display, {
  bool short = false,
}) {
  final price = display.price;
  if (price == null || display.hidden) return null;
  var text = fiatText(atomic, price, display.currency);
  if (short) {
    final dot = text.indexOf('.');
    if (dot >= 0 && text.substring(0, dot).contains(',')) {
      text = text.substring(0, dot) + text.substring(text.indexOf(noBreakSpace, dot));
    }
  }
  return approxText(localDigits(l, text));
}

// Dates.

DateTime localTime(int unixSeconds) =>
    DateTime.fromMillisecondsSinceEpoch(unixSeconds * 1000);

/// `21 Sep 2026, 14:05`.
String formatDateTime(AppLocalizations l, DateTime t) =>
    l.dateWithTime(localDay(l, t), localClock(l, t));

/// Whole days from [t]'s local date to [now]'s: 0 for today, 1 for yesterday.
int daysAgo(DateTime t, DateTime now) => DateTime(
  now.year,
  now.month,
  now.day,
).difference(DateTime(t.year, t.month, t.day)).inDays;

/// A short day with no clock, for a narrow cell: `Today`, `Yesterday`, `21 Sep`, and with the
/// year once it is another year's.
String shortDay(AppLocalizations l, DateTime t, DateTime now) =>
    switch (daysAgo(t, now)) {
      0 => l.dateToday,
      1 => l.dateYesterday,
      _ when t.year == now.year => localDayMonth(l, t),
      _ => localDay(l, t),
    };

/// A day heading: `Today`, `Yesterday`, else `21 Sep 2026`.
String dayLabel(AppLocalizations l, DateTime t, DateTime now) =>
    switch (daysAgo(t, now)) {
      0 => l.dateToday,
      1 => l.dateYesterday,
      _ => localDay(l, t),
    };

/// A short time for a list row: `14:05` for today (the day word adds nothing and the row is
/// narrow), `Yesterday, 14:05`, `21 Sep, 14:05`, and the year added for other years.
String shortDate(AppLocalizations l, DateTime t, DateTime now) {
  final time = localClock(l, t);
  return switch (daysAgo(t, now)) {
    0 => time,
    1 => l.dateWithTime(l.dateYesterday, time),
    _ when t.year == now.year => l.dateWithTime(localDayMonth(l, t), time),
    _ => localDay(l, t),
  };
}

// Transactions.

/// `+5.0000 EPIC`, `−1.0000 EPIC` (a true minus, [minusSign]), or [hiddenAmount]; by the
/// display rule, or with every decimal when [exact].
String signedEpic(
  AppLocalizations l,
  TxEntry tx, {
  required bool hidden,
  bool exact = false,
}) {
  if (hidden) return hiddenAmount;
  final (:amount, :outgoing) = txAmount(tx);
  final text = shownEpic(l, amount, hidden: false, exact: exact);
  return '${outgoing ? minusSign : '+'}$text';
}

bool _outgoingKind(TxEntry tx) =>
    tx.kind == TxKind.sent || tx.kind == TxKind.sentCancelled;

/// A payment's label as a title, or null when it has none.
String? _labelOf(TxEntry tx) {
  final label = tx.label?.trim();
  return label == null || label.isEmpty ? null : label;
}

/// The row title, the same style for every row: the user's label, else the contact's name,
/// else the other side's short address, else what kind of payment it is. The status is never
/// in the title, only in the second line.
String txTitle(
  AppLocalizations l,
  TxEntry tx, {
  String? contactName,
  String? ownServer,
  bool relay = true,
}) {
  if (_labelOf(tx) case final label?) return label;
  final counterparty = tx.counterparty;
  final special = _specialTitle(l, tx, hasCounterparty: counterparty != null);
  if (special != null) return special;
  return contactName ??
      (counterparty == null
          ? _directionNoun(l, tx)
          : shortAddress(counterparty, ownServer: ownServer, relay: relay));
}

/// What a labelled row's second line adds after the date, so the name or address the label
/// replaced is not lost: the contact's name, else the short address; null without a label or
/// when there is nothing to add.
String? txTitleAside(TxEntry tx, {String? contactName, String? ownServer, bool relay = true}) {
  if (_labelOf(tx) == null) return null;
  final counterparty = tx.counterparty;
  return contactName ??
      (counterparty == null
          ? null
          : shortAddress(counterparty, ownServer: ownServer, relay: relay));
}

/// The details title: the label, else the contact's name, else what kind of payment it is. The
/// address is in the "Sent to" / "Received from" row just below, in full.
String txHeading(AppLocalizations l, TxEntry tx, {String? contactName}) =>
    _labelOf(tx) ??
    _specialTitle(l, tx, hasCounterparty: false) ??
    contactName ??
    _directionNoun(l, tx);

/// Titles that describe where a payment came from rather than who: mining and a chain scan
/// (which knows no sender, unless the user typed one).
String? _specialTitle(
  AppLocalizations l,
  TxEntry tx, {
  required bool hasCounterparty,
}) {
  if (tx.origin == TxOrigin.linkedDevice) return l.txSentFromDevice(tx.deviceName ?? '');
  if (tx.kind == TxKind.coinbase) return l.txMiningReward;
  if (tx.origin == TxOrigin.otherWallet) {
    if (!_outgoingKind(tx)) return tx.deviceName != null ? l.txReceivedOnDevice(tx.deviceName!) : l.txReceivedByOtherWallet;
    return tx.unverified ? l.txSentFromOtherWalletUnverified : l.txSentFromOtherWallet;
  }
  if (tx.source == TxSource.restored && !hasCounterparty) {
    return l.txRestoredFunds;
  }
  return null;
}

String _directionNoun(AppLocalizations l, TxEntry tx) => _outgoingKind(tx)
    ? l.txOutgoingPayment
    : tx.isRequest
    ? l.txPaymentRequest
    : l.txIncomingPayment;

/// A pending record that came only from a history backup: this wallet has nothing of its own
/// to say how it ended, so it is neither pending nor done.
bool isFromBackupUnknown(TxEntry tx) =>
    tx.source == TxSource.imported &&
    (tx.status == TxStatus.awaitingRecipient ||
        tx.status == TxStatus.awaitingConfirmation);

/// Not final yet: waiting for the other side or for the chain.
bool isPending(TxEntry tx) =>
    !isFromBackupUnknown(tx) &&
    (tx.status == TxStatus.awaitingRecipient ||
        tx.status == TxStatus.awaitingConfirmation);

/// Blocks on top of the one holding [tx], counting that block, or null when either height is
/// unknown.
int? txConfirmations(TxEntry tx, BigInt? tip) {
  final height = tx.blockHeight;
  if (height == null || tip == null) return null;
  final n = tip - height + BigInt.one;
  return n.isNegative ? 0 : n.toInt();
}

/// Confirmations after which the list calls a transaction completed, when no balance says
/// otherwise. Screens pass [confirmationsTargetOf] as `target`: the balance's own count, as
/// LEPIC counts, in the web demo too.
final int confirmationsTarget = minimumConfirmations.toInt();

/// The confirmations a payment needs before its row says Completed: the count the balance
/// was worked out with ([WalletSummary.minimumConfirmations]), so a row never says Completed
/// while the balance still has its coins as confirming. LEPIC counts with its own number
/// whatever the app asks for. Before the first balance, [minimumConfirmationsProvider].
int confirmationsTargetOf(WidgetRef ref) =>
    ref.watch(countedConfirmationsProvider).toInt();

/// Where a transaction stands, in the words its status chip uses.
enum TxPhase {
  waitingRecipient,
  waitingSender,

  /// A request this wallet sent that the payer has not paid ([TxEntry.awaitingPayer]).
  waitingPayer,
  confirming,
  completed,
  cancelled,

  /// A pending record from a history backup that this wallet cannot follow up.
  fromBackup,
}

TxPhase txPhase(TxEntry tx, BigInt? tip, {int? target}) {
  if (isFromBackupUnknown(tx)) return TxPhase.fromBackup;
  final n = txConfirmations(tx, tip);
  final needed = target ?? confirmationsTarget;
  return switch (tx.status) {
    TxStatus.cancelled => TxPhase.cancelled,
    TxStatus.awaitingRecipient => TxPhase.waitingRecipient,
    TxStatus.awaitingConfirmation when tx.awaitingPayer => TxPhase.waitingPayer,
    // A paid request has arrived: it waits only for the chain.
    TxStatus.awaitingConfirmation when tx.isRequest => TxPhase.confirming,
    TxStatus.awaitingConfirmation
        when tx.blockHeight == null &&
            (tx.kind == TxKind.received ||
                tx.kind == TxKind.receivedCancelled) =>
      TxPhase.waitingSender,
    TxStatus.awaitingConfirmation => TxPhase.confirming,
    TxStatus.confirmed when n != null && n < needed => TxPhase.confirming,
    TxStatus.confirmed => TxPhase.completed,
  };
}

/// `Waiting for recipient`, `Confirming 1/3`, `Completed`, …; `Waiting for Anna` for a
/// payment to or from the paired contact [pairedWith] through its mailbox ([txMailboxName]),
/// and for a send to it while Epicbox is off ([paused]) that it waits in the outbox.
String txStatusLabel(
  AppLocalizations l,
  TxEntry tx,
  BigInt? tip, {
  int? target,
  DateTime? now,
  String? pairedWith,
  bool paused = false,
}) => switch (txPhase(tx, tip, target: target)) {
  TxPhase.waitingRecipient when tx.undelivered => l.txStatusNotDelivered,
  TxPhase.waitingRecipient when now != null && invoicePaymentStalled(tx, now) =>
    l.txStatusStalled,
  TxPhase.waitingRecipient when pairedWith != null && paused => l.contactPausedEpicboxOff,
  TxPhase.waitingRecipient when pairedWith != null => l.txStatusWaitingFor(pairedWith),
  TxPhase.waitingRecipient => l.txStatusWaitingRecipient,
  // The sender's word: the wallet clears it by itself (sender_cancel.dart).
  TxPhase.waitingSender when senderCancelled(tx) => l.txStatusSenderCancelled,
  // The sender's word, not the chain's: never Received before a block.
  TxPhase.waitingSender when now != null && senderReportsPosted(tx, now: now) =>
    l.txStatusSenderPosted,
  // Through the sender's pairing: its wallet finalizes by itself, so it is the one awaited.
  TxPhase.waitingSender when pairedWith != null => l.txStatusWaitingFor(pairedWith),
  TxPhase.waitingSender => l.txStatusWaitingSender,
  TxPhase.waitingPayer => l.txStatusWaitingPayer,
  // Finished under Kill switch: a device that is online posts it.
  TxPhase.confirming when isPostElsewhere(tx) => l.txPostElsewhere,
  // Finished, but the node refused it: not on the network until it is posted again.
  TxPhase.confirming when tx.repostable => l.txStatusNotPosted,
  // Finished moments ago and its post may still be under way: no warning yet.
  TxPhase.confirming when tx.posting => l.postFinishedPosting,
  TxPhase.confirming when NetGate.killSwitch => l.lastKnownConfirming(
    l.txStatusConfirming(txConfirmations(tx, tip) ?? 0, target ?? confirmationsTarget),
  ),
  TxPhase.confirming => l.txStatusConfirming(
    txConfirmations(tx, tip) ?? 0,
    target ?? confirmationsTarget,
  ),
  // A completed row says which way the money went, as the desktop does.
  TxPhase.completed => _outgoingKind(tx) ? l.txStatusSent : l.txStatusReceived,
  // Another linked device's payment whose coins this device released: it may still send it.
  TxPhase.cancelled when tx.origin == TxOrigin.linkedDevice =>
    deviceEndingLabel(l, tx.deviceEnding ?? DeviceEnding.releasedHere, tx.deviceName ?? ''),
  TxPhase.cancelled when senderCancelled(tx) => l.txStatusSenderCancelled,
  TxPhase.cancelled => l.txStatusCancelled,
  TxPhase.fromBackup => l.txStatusFromBackup,
};

/// The mark before a status word: a check for a completed payment, the timelapse glyph while
/// confirming, an hourglass while waiting for the other side, an empty ring otherwise.
(IconData, Color) txStatusMark(BuildContext context, TxPhase phase) {
  final t = context.tokens;
  return switch (phase) {
    TxPhase.completed => (Icons.check_circle_outline, t.ok),
    TxPhase.confirming => (Icons.timelapse, t.info),
    // Waiting for the other side is work under way, so the in-progress blue.
    TxPhase.waitingRecipient ||
    TxPhase.waitingSender ||
    TxPhase.waitingPayer => (Icons.hourglass_empty, t.info),
    TxPhase.cancelled ||
    TxPhase.fromBackup => (Icons.radio_button_unchecked, t.dim),
  };
}

/// The short method name a finished row shows after its status (UP-032), as the desktop's
/// Activity rows do: Epicbox, Link · HTTP, Link · Tor, Direct · File; a payment through a
/// paired contact's [mailbox] went by Epicbox. Null for a reward, another wallet's or a
/// restored payment, and for a transport the app does not name.
String? txRowMethod(AppLocalizations l, TxEntry tx, {String? mailbox}) {
  if (tx.kind == TxKind.coinbase ||
      tx.origin == TxOrigin.otherWallet ||
      tx.source == TxSource.restored) {
    return null;
  }
  if (mailbox != null) return MethodIcons.shortName(l, MethodKind.epicbox);
  final kind = methodKindOfTransport(tx.transport);
  return kind == null ? null : MethodIcons.shortName(l, kind);
}

/// The second line of a payment row: the status word with its mark (the word in
/// [WalletTokens.info] while under way, dim otherwise), the short method name on a finished
/// row, then the time, dim; two lines when one is not enough. Replaces the chip in lists.
class TxStatusLine extends ConsumerWidget {
  const TxStatusLine({
    super.key,
    required this.tx,
    required this.tip,
    required this.date,
    this.aside,
  });

  final TxEntry tx;
  final BigInt? tip;
  final String date;

  /// A name after the date, on a row whose label took the title ([txTitleAside]).
  final String? aside;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final target = confirmationsTargetOf(ref);
    final phase = txPhase(tx, tip, target: target);
    final now = ref.watch(clockProvider)();
    // The sender reports it posted: still waiting, but under way, so in the info colour.
    final reported = phase == TxPhase.waitingSender && senderReportsPosted(tx, now: now);
    final (markIcon, mark) = txStatusMark(context, phase);
    // Finished under Kill switch waits for another device: the hourglass, as for any wait.
    final icon = isPostElsewhere(tx) ? Icons.hourglass_empty : markIcon;
    final color = reported ? t.info : mark;
    // Under way (confirming, or waiting for the other side) is the in-progress blue on the
    // words too, as the detail's dot (UP-039).
    final inProgress = reported ||
        switch (phase) {
          TxPhase.confirming ||
          TxPhase.waitingRecipient ||
          TxPhase.waitingSender ||
          TxPhase.waitingPayer => true,
          TxPhase.completed || TxPhase.cancelled || TxPhase.fromBackup => false,
        };
    final base = theme.textTheme.bodySmall?.copyWith(
      color: t.dim,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final mailbox = txMailboxName(ref, tx);
    final method = isPending(tx) ? null : txRowMethod(context.l10n, tx, mailbox: mailbox);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // On the first line's middle.
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 5),
        // One text, so the time, status and method share the line; the time comes first, so
        // a long status or method never cuts it off (A-04): it is how two like payments tell
        // apart. When they do not fit the line wraps after a dot ([metaSpans]), never cutting
        // the time (UP-001).
        Flexible(
          flex: 3,
          child: Text.rich(
            TextSpan(
              children: metaSpans([
                TextSpan(text: date, style: base),
                TextSpan(
                  text: paymentStepWord(
                    context.l10n,
                    tx,
                    tip,
                    style: ref.watch(levelFeaturesProvider.select((f) => f.timeline)),
                    target: target,
                    now: now,
                    who: txPartyName(ref, tx),
                    pairedWith: mailbox,
                    paused: ref.watch(pairNetProvider) == PairNet.epicboxOff,
                  ),
                  style: inProgress ? base?.copyWith(color: t.info) : base,
                ),
                if (method != null) TextSpan(text: method, style: base),
                if (aside != null) TextSpan(text: aside, style: base),
              ], dot: base),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: base,
          ),
        ),
        if (tx.manualFields.isNotEmpty) ...[
          const SizedBox(width: 6),
          ManualTag(editedAtUnix: tx.manualEditedAtUnix, compact: true),
        ],
      ],
    );
  }
}

/// A payment's progress for [StatusTimeline], or null where a timeline would add nothing to
/// the status text: cancelled payments, backup records, mining rewards, restored or imported
/// rows. The current step names what the wallet waits for ("Waiting for recipient").
///
/// A payment through a paired contact's [mailbox] names it (DESIGN 1.2): "Sent through Anna's
/// mailbox" with its relay (or, paused while Epicbox is off, still current: it waits in the
/// outbox), then "Answer from Anna", "Checking Anna's mailbox" while it is awaited.
///
/// The Send trackers show the same steps ([sendSteps]); [waiting] is their sub-line under the
/// current "Recipient signed" step ("Waiting for Anna's wallet"), [held] under the done first
/// step while the coins wait locked.
List<TimelineStep>? txTimeline(
  AppLocalizations l,
  TxEntry tx,
  BigInt? tip, {
  int? target,
  DateTime? now,
  ({String name, String relay, bool paused})? mailbox,
  String? waiting,
  String? held,
}) {
  // Another wallet made it: this wallet saw only the coins move, so there are no steps.
  if (tx.source != TxSource.wallet || tx.kind == TxKind.coinbase || tx.origin == TxOrigin.otherWallet) return null;
  final phase = txPhase(tx, tip, target: target);
  final confirming = l.txStatusConfirming(
    txConfirmations(tx, tip) ?? 0,
    target ?? confirmationsTarget,
  );
  // Each step: label once done, label while current, label before it is reached. The same
  // five names in every state, as the desktop lists them (GP2-001): the status card above
  // says what the wallet waits for; the current Confirming step carries its count.
  final List<(String, String, String)> steps;
  final int? at;
  if (_outgoingKind(tx)) {
    steps = _sendLabels(l, confirming);
    at = switch (phase) {
      TxPhase.waitingRecipient => 1,
      TxPhase.confirming when tx.repostable || tx.posting => 2,
      TxPhase.confirming => 3,
      TxPhase.completed => steps.length,
      _ => null,
    };
  } else if (tx.isRequest) {
    // Nothing arrives before the payer pays.
    steps = [
      (l.txStepRequested, l.txStepRequested, l.txStepRequested),
      (l.txStepPaid, l.txStepPaid, l.txStepPaid),
      (l.txStepConfirmed, confirming, l.txStepConfirming),
      (l.txStatusCompleted, l.txStatusCompleted, l.txStatusCompleted),
    ];
    at = switch (phase) {
      TxPhase.waitingPayer => 1,
      TxPhase.confirming => 2,
      TxPhase.completed => steps.length,
      _ => null,
    };
  } else {
    final reported = now != null && senderReportsPosted(tx, now: now);
    steps = [
      (l.txStepArrived, l.txStepArrived, l.txStepArrived),
      (l.txStepSenderFinished, l.txStepSenderFinished, l.txStepSenderFinished),
      // The sender's wallet posts it; this wallet only hears so from the sender.
      (l.txStepPosted, l.txStepPosted, l.txStepPosted),
      (l.txStepConfirmed, confirming, l.txStepConfirming),
      (l.txStatusCompleted, l.txStatusCompleted, l.txStatusCompleted),
    ];
    at = switch (phase) {
      // Its sender cancelled it: no step comes next.
      TxPhase.waitingSender when senderCancelled(tx) => null,
      TxPhase.waitingSender => reported ? 2 : 1,
      TxPhase.confirming => 3,
      TxPhase.completed => steps.length,
      _ => null,
    };
  }
  if (at == null) return null;
  if (mailbox != null && _outgoingKind(tx)) {
    final (:name, :relay, :paused) = mailbox;
    final queued = paused && at == 1;
    final answer = l.txStepAnswerFrom(name);
    return [
      TimelineStep(
        l.txStepSentMailbox(name),
        queued ? TimelineState.current : TimelineState.done,
        detail: queued ? l.contactPausedEpicboxOff : (relay.isEmpty ? null : l.contactDeliveredVia(relay)),
      ),
      if (queued)
        TimelineStep(answer, TimelineState.todo)
      else if (at == 1)
        TimelineStep(answer, TimelineState.current, detail: l.txStepCollecting(name))
      else
        TimelineStep(answer, TimelineState.done),
      ..._stepsAt(steps, at).skip(2),
    ];
  }
  if (_outgoingKind(tx)) return sendSteps(l, at, confirming: confirming, waiting: waiting, held: held);
  return _stepsAt(steps, at);
}

/// An outgoing payment's five steps, the same for every method and screen (A-03): Payment
/// started, Recipient signed, Posted to the network, Confirming, Completed. [at] is the current
/// step (5 when all are done); [confirming] the Confirming step's words while current ("2 of 6
/// confirmations"). [waiting] is the sub-line of a current "Recipient signed", [held] that of
/// the first step until the payment is posted.
List<TimelineStep> sendSteps(
  AppLocalizations l,
  int at, {
  String? confirming,
  String? waiting,
  String? held,
}) => [
  for (final (i, step) in _stepsAt(_sendLabels(l, confirming ?? l.txStepConfirming), at).indexed)
    switch (i) {
      0 when held != null && at < 3 => TimelineStep(step.label, step.state, detail: held),
      1 when waiting != null && at == 1 => TimelineStep(step.label, step.state, detail: waiting),
      _ => step,
    },
];

/// The outgoing steps' labels once done, while current, before reached.
List<(String, String, String)> _sendLabels(AppLocalizations l, String confirming) => [
  (l.txStepStarted, l.txStepStarted, l.txStepStarted),
  (l.txStepAccepted, l.txStepAccepted, l.txStepAccepted),
  (l.txStepPosted, l.txStepPosted, l.txStepPosted),
  (l.txStepConfirmed, confirming, l.txStepConfirming),
  (l.txStatusCompleted, l.txStatusCompleted, l.txStatusCompleted),
];

List<TimelineStep> _stepsAt(List<(String, String, String)> steps, int at) => [
  for (final (i, (done, now, todo)) in steps.indexed)
    i < at
        ? TimelineStep(done, TimelineState.done)
        : i == at
        ? TimelineStep(now, TimelineState.current)
        : TimelineStep(todo, TimelineState.todo),
];

/// Pending transactions first, then the rest, each newest first.
List<TxEntry> pendingFirst(Iterable<TxEntry> txs) {
  int newest(TxEntry a, TxEntry b) => b.timeUnix.compareTo(a.timeUnix);
  return [
    ...txs.where(isPending).toList()..sort(newest),
    ...txs.where((t) => !isPending(t)).toList()..sort(newest),
  ];
}

/// The height payments count their confirmations at: the one the balance was worked out at
/// ([WalletSummary.lastConfirmedHeight]), which arrives with the list in one refresh, so rows
/// and balance always agree. The node's own tip, which a status check may have read a block
/// or more later, only until the wallet has a balance.
BigInt? tipHeight(WidgetRef ref) {
  final counted = ref.watch(
    homeProvider.select((h) => h.value?.summary.lastConfirmedHeight),
  );
  if (counted != null && counted > BigInt.zero) return counted;
  return ref.watch(nodeTipProvider).value?.height;
}

/// The host of the open wallet's epicbox server, for [shortAddress].
String? ownEpicboxServer(WidgetRef ref) =>
    ref.watch(walletConfigProvider.select((c) => c?.epicboxDomain));

/// The name saved for [address] in the address book, when there is one.
String? contactName(WidgetRef ref, String? address) {
  final contacts = ref.watch(contactsProvider).value;
  return contacts == null ? null : contactNameFor(contacts, address);
}

/// The name of [tx]'s other side: the saved contact of its address, else the pairing it was
/// exchanged with ([TxEntry.pairingId]: a payment through a contact's mailbox has no address,
/// and a request's counterparty is the contact's mailbox, which no address-book entry holds),
/// else, for a payment of a paired contact's request, that pairing's name.
String? txPartyName(WidgetRef ref, TxEntry tx) {
  final saved = contactName(ref, tx.counterparty);
  if (saved != null) return saved;
  final linked = txPairingName(ref, tx);
  final slate = tx.slateId;
  if (linked != null || slate == null || !txAmount(tx).outgoing) return linked;
  if (tx.flow != TxFlow.invoice) return txMailboxName(ref, tx);
  final pairingId = ref.watch(paidInvoiceProvider(slate)).value?.pairingId;
  if (pairingId == null) return null;
  final name = ref.watch(pairingNameProvider(pairingId));
  return name.isEmpty ? null : name;
}

/// The name of the pairing [tx] was exchanged with ([TxEntry.pairingId]), or null; nothing
/// while Pairing is off.
String? txPairingName(WidgetRef ref, TxEntry tx) {
  final id = tx.pairingId;
  if (id == null || !ref.watch(pairingSupportedProvider)) return null;
  final name = ref.watch(pairingNameProvider(id));
  return name.isEmpty ? null : name;
}

/// The paired contact a payment went to or came from through its mailbox (RFC 9.1, a payment
/// with no address), by name, or null. LEPIC's link ([TxEntry.pairingId]) names it at every
/// state, both ways; without one (a core that does not tell), lists ask only for a send still
/// waiting for its answer, as each ask reads the wallet's payments, and [any] asks for any
/// such send (one detail page).
String? txMailboxName(WidgetRef ref, TxEntry tx, {bool any = false}) {
  if (tx.pairingId != null) return txPairingName(ref, tx);
  final slate = tx.slateId;
  if (slate == null || tx.counterparty != null || tx.kind != TxKind.sent) return null;
  if (!any && tx.status != TxStatus.awaitingRecipient) return null;
  if (!ref.watch(pairingSupportedProvider)) return null;
  final pairingId = ref.watch(pairingSlateProvider(slate)).value?.pairingId;
  if (pairingId == null) return null;
  final name = ref.watch(pairingNameProvider(pairingId));
  return name.isEmpty ? null : name;
}

/// The badge with a transaction's status: warn while it waits for the other side, info while
/// it confirms or its sender reports it posted (the icon beside it shows the progress, so no
/// spinner), neutral once it is over (completed, from a backup, cancelled).
class TxStatusChip extends ConsumerWidget {
  const TxStatusChip({super.key, required this.tx, required this.tip});

  final TxEntry tx;
  final BigInt? tip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = confirmationsTargetOf(ref);
    final now = ref.watch(clockProvider)();
    final tone = switch (txPhase(tx, tip, target: target)) {
      // Its sender cancelled it: over, as a cancelled payment, though not cleared yet.
      TxPhase.waitingSender when senderCancelled(tx) => BadgeTone.neutral,
      TxPhase.waitingSender when senderReportsPosted(tx, now: now) => BadgeTone.info,
      // Waiting for the other side is work under way, not a warning.
      TxPhase.waitingRecipient ||
      TxPhase.waitingSender ||
      TxPhase.waitingPayer => BadgeTone.info,
      TxPhase.confirming => BadgeTone.info,
      // Cancelled is over, not wrong: the same neutral badge as a completed payment.
      TxPhase.completed || TxPhase.fromBackup || TxPhase.cancelled => BadgeTone.neutral,
    };
    final badge = EBadge(
      txStatusLabel(
        context.l10n,
        tx,
        tip,
        target: target,
        now: now,
        pairedWith: txMailboxName(ref, tx),
        paused: ref.watch(pairNetProvider) == PairNet.epicboxOff,
      ),
      tone: tone,
    );
    // A status another device told, not yet the chain's: the mark says so.
    if (tx.origin != TxOrigin.linkedDevice || tx.blockHeight != null) return badge;
    final name = tx.deviceName ?? '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        InfoHint(context.l10n.devicesStatusInfo(name), size: InfoHint.inRow, title: context.l10n.txSentFromDevice(name)),
      ],
    );
  }
}

/// The direction of [tx] in a rounded square whose edge shows its progress: green in, red
/// out, grey when cancelled ([WalletTokens.txSent] and kin). See [TxProgressSquare] for the edge.
class TxIcon extends ConsumerWidget {
  const TxIcon({super.key, required this.tx, required this.tip});

  final TxEntry tx;

  /// The node's tip, for the confirmations a confirming payment has.
  final BigInt? tip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;
    final (IconData icon, Color fg, String label) = switch (tx.kind) {
      _ when tx.status == TxStatus.cancelled => (
        Icons.block,
        t.txCancelled,
        l.txIconCancelled,
      ),
      // A reward is money in, so green like a receipt; the bolt tells it apart.
      TxKind.coinbase => (Icons.bolt, t.txReceived, l.txMiningReward),
      TxKind.received ||
      TxKind.receivedCancelled => (
        Icons.south_west,
        t.txReceived,
        l.txIconIncoming,
      ),
      TxKind.sent ||
      TxKind.sentCancelled => (Icons.north_east, t.txSent, l.txIconOutgoing),
    };
    final target = confirmationsTargetOf(ref);
    final phase = txPhase(tx, tip, target: target);
    return TxProgressSquare(
      payment: tx.key,
      phase: phase,
      fraction: phase == TxPhase.confirming
          ? txConfirmedShare(txConfirmations(tx, tip) ?? 0, target)
          : 0,
      child: Icon(icon, size: 20, color: fg, semanticLabel: label),
    );
  }
}

/// [confirmations] of [target] as a share of the tile's edge, 0 to 1.
double txConfirmedShare(int confirmations, int target) =>
    target <= 0 ? 1 : (confirmations / target).clamp(0.0, 1.0);

/// What a payment tile's edge does in a [TxPhase].
enum TxEdgeKind {
  /// Final or not followed: the 1 dp hairline only.
  hairline,

  /// Confirming: the current mark's line fills clockwise to the confirmations' share.
  fill,

  /// Waiting for the other side: a short run of the line travels round the square.
  run,
}

TxEdgeKind txEdgeKind(TxPhase phase) => switch (phase) {
  TxPhase.confirming => TxEdgeKind.fill,
  // Waiting shows in the status line (the hourglass), not on the tile: a moving fragment on
  // a static square read as a glitch (UP-022). The run stays for a determinate use.
  TxPhase.waitingRecipient ||
  TxPhase.waitingSender ||
  TxPhase.waitingPayer ||
  TxPhase.completed ||
  TxPhase.cancelled ||
  TxPhase.fromBackup => TxEdgeKind.hairline,
};

/// The tile's side.
const double txTileSize = 40;

/// The halo round a live tile, outside its square.
const double txTileHalo = 3;

/// The share of the edge the waiting run covers.
const double txEdgeRunShare = 0.16;

/// One lap of the waiting run; twice as long for a send waiting on its recipient, which may
/// take hours.
Duration txEdgeLap(TxPhase phase) => phase == TxPhase.waitingRecipient
    ? const Duration(milliseconds: 4800)
    : const Duration(milliseconds: 2400);

/// Laps the waiting run travels before it rests at the top centre, where each lap starts: a
/// payment can wait for hours, and a run that never stops redraws the list all that time. A
/// new phase or payment in the tile laps again.
const int txEdgeRunLaps = 5;

/// Whether a waiting tile's run travels. Widget tests turn it off in
/// `test/flutter_test_config.dart`, since a loop never lets `pumpAndSettle` settle; the tile
/// then shows the full current mark, as with reduced motion. The loader's own tests turn it on.
@visibleForTesting
bool txEdgeRunMoves = true;

/// How long the fill takes to reach a new confirmation count.
const Duration txEdgeFillDuration = Duration(milliseconds: 900);

/// How long a landed payment's tile stays closed in [doneMarkEdge] before it is a hairline.
const Duration txEdgeLandDuration = Duration(milliseconds: 1300);

/// The landing halo's opacity, of [doneMarkEdge].
const double txEdgeLandHaloAlpha = 0.22;

/// The 40 dp rounded square of a payment tile, as a loader. Pending, its edge is the
/// timeline's current mark ([currentMarkEdge] line, [currentMarkHalo] halo): filling to
/// [fraction] while confirming, a run travelling round it while waiting. When it goes from
/// confirming to completed while shown, the edge closes in [doneMarkEdge] for
/// [txEdgeLandDuration], then it is the hairline. Final, cancelled and backup rows keep the
/// hairline. With reduced motion nothing moves: waiting shows the full mark, the fill cuts
/// and a landing cuts to the hairline. The square never changes size; it adds no semantics.
class TxProgressSquare extends StatefulWidget {
  const TxProgressSquare({
    super.key,
    required this.payment,
    required this.phase,
    required this.fraction,
    required this.child,
  });

  /// The payment shown ([TxEntry.key]). A tile built anew for the same payment, as a list
  /// does when it reorders, still sees the payment land.
  final String payment;

  final TxPhase phase;

  /// The confirmed share of the edge while [phase] is [TxPhase.confirming], 0 to 1.
  final double fraction;

  /// The glyph in the middle.
  final Widget child;

  @override
  State<TxProgressSquare> createState() => _TxProgressSquareState();
}

/// The phase each payment's tiles showed in the last frame, kept while a tile shows the
/// payment. A list that moves a payment drops its old tile and builds a new one in the same
/// frame, and two tiles may show one payment, so what a frame shows is written after it, in
/// a microtask, and a payment no tile holds is forgotten then.
abstract final class _TxEdgeMemory {
  static final Map<String, TxPhase> _phases = {};
  static final Map<String, TxPhase> _shown = {};
  static final Map<String, int> _holders = {};
  static bool _queued = false;

  static TxPhase? phaseOf(String payment) => _phases[payment];

  static void hold(String payment) =>
      _holders[payment] = (_holders[payment] ?? 0) + 1;

  static void show(String payment, TxPhase phase) {
    _shown[payment] = phase;
    _commitLater();
  }

  static void release(String payment) {
    final left = (_holders[payment] ?? 1) - 1;
    if (left > 0) {
      _holders[payment] = left;
    } else {
      _holders.remove(payment);
      _commitLater();
    }
  }

  static void _commitLater() {
    if (_queued) return;
    _queued = true;
    scheduleMicrotask(() {
      _queued = false;
      _phases.addAll(_shown);
      _shown.clear();
      _phases.removeWhere((payment, _) => !_holders.containsKey(payment));
    });
  }
}

class _TxProgressSquareState extends State<TxProgressSquare>
    with TickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: txEdgeFillDuration,
    value: 1,
  );
  late final AnimationController _run = AnimationController(vsync: this)
    // The laps end where they start: a frame that lands past the last one could leave the run
    // part way round.
    ..addStatusListener((status) {
      if (!_run.isAnimating && status == AnimationStatus.completed) _run.value = 0;
    });

  /// The payment and phase the run lapped for (or is lapping for).
  (String, TxPhase)? _lapped;
  late final AnimationController _land = AnimationController(
    vsync: this,
    duration: txEdgeLandDuration,
  )..addStatusListener(_landed);
  late final Listenable _motion = Listenable.merge([_fill, _run, _land]);

  /// The fill tweens from [_from] to [_to] as [_fill] runs.
  late double _from = widget.fraction;
  late double _to = widget.fraction;
  bool _landing = false;
  bool _still = false;
  bool _seen = false;

  double get _filled =>
      _from + (_to - _from) * Curves.easeOutCubic.transform(_fill.value);

  @override
  void initState() {
    super.initState();
    _TxEdgeMemory.hold(widget.payment);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    if (_still) {
      _settle(_to);
      _endLanding();
    }
    if (!_seen) {
      _seen = true;
      _follow(_TxEdgeMemory.phaseOf(widget.payment));
    }
    _syncRun();
  }

  @override
  void didUpdateWidget(TxProgressSquare old) {
    super.didUpdateWidget(old);
    if (old.payment != widget.payment) {
      // Another payment in this place: start from what it shows, without a tween.
      _TxEdgeMemory.release(old.payment);
      _TxEdgeMemory.hold(widget.payment);
      _endLanding();
      _settle(widget.fraction);
      _follow(_TxEdgeMemory.phaseOf(widget.payment));
    } else {
      _follow(old.phase);
    }
    _syncRun();
  }

  /// Moves the edge from [before], the phase last shown for this payment, to the widget's.
  void _follow(TxPhase? before) {
    final phase = widget.phase;
    _TxEdgeMemory.show(widget.payment, phase);
    if (before == TxPhase.confirming && phase == TxPhase.completed) {
      if (_still) return;
      // Close the edge, then hold it in the done colour.
      _from = _filled;
      _to = 1;
      _fill.forward(from: 0);
      _landing = true;
      _land.forward(from: 0);
      return;
    }
    if (_landing && phase == TxPhase.completed) return;
    _endLanding();
    if (phase != TxPhase.confirming || before != TxPhase.confirming) {
      // A new phase starts where it is, without a tween.
      _settle(widget.fraction);
    } else if (widget.fraction != _to) {
      if (_still) {
        _settle(widget.fraction);
      } else {
        _from = _filled;
        _to = widget.fraction;
        _fill.forward(from: 0);
      }
    }
  }

  /// Shows [fraction] at once.
  void _settle(double fraction) {
    _from = _to = fraction;
    if (_fill.value != 1) _fill.value = 1;
  }

  void _landed(AnimationStatus status) {
    if (status == AnimationStatus.completed) setState(_endLanding);
  }

  void _endLanding() {
    _landing = false;
    if (_land.isAnimating) _land.stop();
  }

  bool get _runMoves => !_still && txEdgeRunMoves;

  void _syncRun() {
    final run = txEdgeKind(widget.phase) == TxEdgeKind.run && _runMoves;
    if (!run) {
      if (_run.isAnimating) _run.stop();
      _lapped = null;
      return;
    }
    final lapping = (widget.payment, widget.phase);
    if (_lapped == lapping) return;
    _lapped = lapping;
    _run
      ..duration = txEdgeLap(widget.phase)
      ..value = 0
      ..repeat(count: txEdgeRunLaps);
  }

  @override
  void dispose() {
    _TxEdgeMemory.release(widget.payment);
    _fill.dispose();
    _run.dispose();
    _land.dispose();
    super.dispose();
  }

  TxEdgePainter _painter(WalletTokens t) {
    final radius = t.radiusSmall;
    if (_landing) {
      // Held, then fading out over the last quarter.
      final fade = 1 - ((_land.value - 0.75) / 0.25).clamp(0.0, 1.0);
      final done = doneMarkEdge(t);
      return TxEdgePainter(
        radius: radius,
        hairline: t.lineStrong,
        edge: done.withValues(alpha: done.a * fade),
        halo: done.withValues(alpha: txEdgeLandHaloAlpha * fade),
        extent: _filled,
      );
    }
    return switch (txEdgeKind(widget.phase)) {
      TxEdgeKind.hairline => TxEdgePainter(
        radius: radius,
        hairline: t.lineStrong,
      ),
      TxEdgeKind.fill => TxEdgePainter(
        radius: radius,
        hairline: t.lineStrong,
        edge: currentMarkEdge(t),
        halo: currentMarkHalo(t),
        extent: _filled,
      ),
      TxEdgeKind.run => TxEdgePainter(
        radius: radius,
        hairline: t.lineStrong,
        edge: currentMarkEdge(t),
        halo: currentMarkHalo(t),
        start: _runMoves ? _run.value : 0,
        extent: _runMoves ? txEdgeRunShare : 1,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Its own layer: a moving edge repaints the tile, not the list.
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: txTileSize,
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, child) =>
              CustomPaint(painter: _painter(t), child: child),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

/// A payment tile's square: the [halo] outside it, the 1 dp [hairline] on it, and over that
/// the current mark's [currentMarkStroke] line in [edge], from [start] for [extent] of the
/// edge (shares of the perimeter, clockwise from the top centre).
class TxEdgePainter extends CustomPainter {
  const TxEdgePainter({
    required this.radius,
    required this.hairline,
    this.edge,
    this.halo,
    this.start = 0,
    this.extent = 0,
  });

  final double radius;
  final Color hairline;
  final Color? edge;
  final Color? halo;
  final double start;
  final double extent;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    if (halo case final halo?) {
      canvas.drawDRRect(
        RRect.fromRectAndRadius(
          box.inflate(txTileHalo),
          Radius.circular(radius + txTileHalo),
        ),
        RRect.fromRectAndRadius(box, Radius.circular(radius)),
        Paint()..color = halo,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(box.deflate(0.5), Radius.circular(radius - 0.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = hairline,
    );
    if (edge case final edge? when extent > 0) {
      const w = currentMarkStroke;
      canvas.drawPath(
        txEdgePath(box.deflate(w / 2), radius - w / 2, start, extent),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = extent >= 1 ? StrokeCap.butt : StrokeCap.round
          ..color = edge,
      );
    }
  }

  @override
  bool shouldRepaint(TxEdgePainter old) =>
      old.radius != radius ||
      old.hairline != hairline ||
      old.edge != edge ||
      old.halo != halo ||
      old.start != start ||
      old.extent != extent;
}

/// The part of [rect]'s edge, corners rounded by [radius], from [start] for [extent], both
/// shares of the perimeter measured clockwise from the top centre. A part that passes the top
/// centre wraps round; an [extent] of 1 or more is the whole closed edge.
Path txEdgePath(Rect rect, double radius, double start, double extent) {
  final r = Radius.circular(radius);
  final loop = Path()
    ..moveTo(rect.center.dx, rect.top)
    ..lineTo(rect.right - radius, rect.top)
    ..arcToPoint(Offset(rect.right, rect.top + radius), radius: r)
    ..lineTo(rect.right, rect.bottom - radius)
    ..arcToPoint(Offset(rect.right - radius, rect.bottom), radius: r)
    ..lineTo(rect.left + radius, rect.bottom)
    ..arcToPoint(Offset(rect.left, rect.bottom - radius), radius: r)
    ..lineTo(rect.left, rect.top + radius)
    ..arcToPoint(Offset(rect.left + radius, rect.top), radius: r)
    ..close();
  if (extent >= 1) return loop;
  final metric = loop.computeMetrics().first;
  final length = metric.length;
  final from = (start % 1) * length;
  final to = from + extent.clamp(0.0, 1.0) * length;
  final part = metric.extractPath(from, math.min(to, length));
  if (to > length) {
    part.addPath(metric.extractPath(0, to - length), Offset.zero);
  }
  return part;
}

/// What a screen reader says for a payment row, as one sentence:
/// "Received 10 EPIC from Alice, completed, Today, 10:01".
/// [who] is the contact name or short address, [date] the row's date text. A [label] the user
/// gave the payment is said first.
String txSpokenLabel(
  AppLocalizations l,
  TxEntry tx, {
  required String? who,
  required String date,
  required String status,
  required bool hidden,
  String? label,
}) {
  final amount = hidden
      ? l.txSpokenHiddenAmount
      : epicText(l, txAmount(tx).amount);
  final out = _outgoingKind(tx);
  final String what;
  if (tx.kind == TxKind.coinbase) {
    what = l.txSpokenMiningReward(amount);
  } else if (tx.origin == TxOrigin.otherWallet) {
    what = out
        ? l.txSpokenSentFromOtherWallet(amount)
        : tx.deviceName != null
        ? l.txSpokenReceivedOnDevice(tx.deviceName!, amount)
        : l.txSpokenReceivedByOtherWallet(amount);
  } else if (tx.source == TxSource.restored) {
    what = l.txSpokenRestoredFunds(amount);
  } else {
    final cancelled = tx.status == TxStatus.cancelled;
    final pending = !cancelled && isPending(tx);
    what = switch ((out, who)) {
      (true, null) when cancelled => l.txSpokenCancelledSend(amount),
      (true, final w?) when cancelled => l.txSpokenCancelledSendTo(amount, w),
      (false, null) when cancelled => l.txSpokenCancelledReceive(amount),
      (false, final w?) when cancelled => l.txSpokenCancelledReceiveFrom(
        amount,
        w,
      ),
      (false, null) when tx.awaitingPayer => l.txSpokenRequesting(amount),
      (false, final w?) when tx.awaitingPayer => l.txSpokenRequestingFrom(
        amount,
        w,
      ),
      (true, null) when pending => l.txSpokenSending(amount),
      (true, final w?) when pending => l.txSpokenSendingTo(amount, w),
      (false, null) when pending => l.txSpokenReceiving(amount),
      (false, final w?) when pending => l.txSpokenReceivingFrom(amount, w),
      (true, null) => l.txSpokenSent(amount),
      (true, final w?) => l.txSpokenSentTo(amount, w),
      (false, null) => l.txSpokenReceived(amount),
      (false, final w?) => l.txSpokenReceivedFrom(amount, w),
    };
  }
  // English lower-cases the chip's word mid-sentence; other languages keep it, since German
  // nouns stay capitalised and Chinese has no case.
  // Only the first letter: a name in it keeps its case ("waiting for Anna").
  final spokenStatus = l.localeName == 'en' && status.isNotEmpty ? status[0].toLowerCase() + status.substring(1) : status;
  final sentence = l.txSpokenRow(what, spokenStatus, date);
  final named = label?.trim() ?? '';
  return named.isEmpty ? sentence : l.txSpokenLabelled(named, sentence);
}

/// One transaction in a list. Tapping it opens its details, where cancel lives.
class TxTile extends ConsumerWidget {
  const TxTile({super.key, required this.tx});

  final TxEntry tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final display = amountDisplay(ref);
    final tip = tipHeight(ref);
    final now = ref.watch(clockProvider)();
    final (:amount, :outgoing) = txAmount(tx);
    // A cancelled payment moved nothing, so it has no value to show.
    final fiat = tx.status == TxStatus.cancelled
        ? null
        : approxFiat(l, amount, display, short: true);
    final theme = Theme.of(context);
    final name = txPartyName(ref, tx);
    // Level 1 names no server: an address is its key alone.
    final relay = ref.watch(levelFeaturesProvider.select((f) => f.serverNames));
    final title = txTitle(
      l,
      tx,
      contactName: name,
      ownServer: ownEpicboxServer(ref),
      relay: relay,
    );
    final date = shortDate(l, localTime(tx.timeUnix), now);
    final signed = signedEpic(l, tx, hidden: display.hidden);
    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TxDetailsScreen(txKey: tx.key)),
    );
    final counterparty = tx.counterparty;
    // No label and no name: the title is the short address.
    final addressTitle = counterparty != null &&
        name == null &&
        title == shortAddress(counterparty, ownServer: ownEpicboxServer(ref), relay: relay);
    final aside = txTitleAside(
      tx,
      contactName: name,
      ownServer: ownEpicboxServer(ref),
      relay: relay,
    );
    // The row's label field opens from a long press; the builder below hands its opener out.
    VoidCallback? edit;
    // One sentence for screen readers instead of the pieces (title, chip, date, amount, fiat),
    // so the status is said once and in order. It sits under the row, which is on top of it
    // only where there is something to read.
    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            key: ValueKey('tx-${tx.key}'),
            button: true,
            label: txSpokenLabel(
              l,
              tx,
              who:
                  name ??
                  (counterparty == null
                      ? null
                      : shortAddress(
                          counterparty,
                          ownServer: ownEpicboxServer(ref),
                          relay: relay,
                        )),
              date: date,
              // Said as the row shows it: the level's step word (today's label at level 3).
              status: paymentStepWord(
                l,
                tx,
                tip,
                style: ref.watch(levelFeaturesProvider.select((f) => f.timeline)),
                target: confirmationsTargetOf(ref),
                now: now,
                who: name,
                pairedWith: txMailboxName(ref, tx),
                paused: ref.watch(pairNetProvider) == PairNet.epicboxOff,
              ),
              hidden: display.hidden,
              label: tx.label,
            ),
            onTap: open,
            // A long press labels the payment in place; the pen left the row. Screen
            // readers offer it as the row's long-press action, named Add or Edit label.
            onLongPress: tx.origin == TxOrigin.linkedDevice ? null : () => edit?.call(),
            onLongPressHint: tx.origin == TxOrigin.linkedDevice
                ? null
                : (tx.label == null ? l.txLabelAdd : l.txLabelEdit),
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: open,
              onLongPress: () => edit?.call(),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IgnorePointer(
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: TxIcon(tx: tx, tip: tip),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The pen's target is 48 dp tall around a 24 dp line; the second line is
                  // drawn up into the room above and below the title.
                  SizedBox(
                    height: 48,
                    child: TxLabelEditor(
                      tx: tx,
                      style: theme.textTheme.bodyLarge,
                      // Short enough to leave the second line clear.
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      idle: (context, startEdit) {
                        // Another linked device's payment has no record here to label.
                        edit = tx.origin == TxOrigin.linkedDevice ? null : startEdit;
                        return IgnorePointer(
                          child: ExcludeSemantics(
                            // An address for a title is in the mono face, shrunk, never cut.
                            child: addressTitle
                                ? ShortAddressText(counterparty, ownServer: ownEpicboxServer(ref), relay: relay, style: theme.textTheme.bodyMedium)
                                : Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: TxStatusLine(
                          tx: tx,
                          tip: tip,
                          date: date,
                          aside: aside,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // At most 40 % of the row, so a long title keeps some room.
            IgnorePointer(
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Amounts are data, so the mono face.
                        AmountText(
                          signed,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 14.5,
                            // The amount wears the direction, like the icon: green in, red
                            // out; a cancelled one is struck through in grey.
                            color: tx.status == TxStatus.cancelled
                                ? context.tokens.txCancelled
                                : outgoing
                                ? context.tokens.txSent
                                : context.tokens.txReceived,
                            decoration: tx.status == TxStatus.cancelled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (fiat != null)
                          Text(
                            fiat,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// An error sentence, announced to screen readers when it appears.
class ErrorText extends StatelessWidget {
  const ErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: color,
              semanticLabel: context.l10n.commonError,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: color))),
          ],
        ),
      ),
    );
  }
}

/// A primary button that shows a spinner beside its words and ignores taps while [busy];
/// [busyLabel] replaces the words then ("Sending…"), so the state stays readable.
class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: busy
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Under reduced motion a still glyph: a spinner that does not turn is a dot.
                MediaQuery.disableAnimationsOf(context)
                    ? const Icon(Icons.hourglass_empty, size: 18)
                    : const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                const SizedBox(width: 10),
                Text(busyLabel ?? label),
              ],
            )
          : Text(label),
    );
  }
}

/// The one destructive look: an outlined button in the risk colour, for the action
/// that cancels, removes or deletes, on screens and as a dialog's confirm. The safe choice
/// beside it is a neutral [OutlinedButton].
class DangerButton extends StatelessWidget {
  const DangerButton({super.key, required this.onPressed, required this.child}) : icon = null, label = null;

  const DangerButton.icon({super.key, required this.onPressed, required Widget this.icon, required Widget this.label}) : child = null;

  final VoidCallback? onPressed;
  final Widget? child;
  final Widget? icon;
  final Widget? label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // The outlined risk style; disabled, the one disabled recipe (theme/tokens.dart).
    final style = OutlinedButton.styleFrom(
      foregroundColor: t.risk,
      disabledForegroundColor: t.faint,
      minimumSize: Size(48, t.controlHeight),
    ).copyWith(
      side: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? BorderSide.none : BorderSide(color: t.risk),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? disabledButtonFill(t) : null,
      ),
    );
    if (icon != null) return OutlinedButton.icon(style: style, icon: icon, label: label!, onPressed: onPressed);
    return OutlinedButton(style: style, onPressed: onPressed, child: child!);
  }
}

/// A password input with a show/hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          tooltip: _obscure
              ? context.l10n.passwordShow
              : context.l10n.passwordHide,
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

/// Slate JSON in a scrollable monospace box with a copy button.
class SlateBox extends StatelessWidget {
  const SlateBox({super.key, required this.title, required this.json});

  final String title;
  final String json;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                IconButton(
                  tooltip: context.l10n.slateCopyTooltip,
                  icon: const Icon(Icons.copy),
                  onPressed: () =>
                      copySecretText(context, json, context.l10n.slateCopied),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: SelectableText(
                  json,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-line field for pasting slate JSON.
class SlateInput extends StatelessWidget {
  const SlateInput({
    super.key,
    required this.controller,
    required this.label,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 3,
      maxLines: 8,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.multiline,
      onChanged: onChanged,
      style: const TextStyle(fontFamily: 'monospace'),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        suffixIcon: IconButton(
          tooltip: context.l10n.commonPaste,
          icon: const Icon(Icons.content_paste),
          onPressed: () async {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            final text = data?.text;
            if (text == null) return;
            controller.text = text;
            onChanged?.call(text);
          },
        ),
      ),
    );
  }
}

/// Body padding and a width cap, so screens stay readable on tablets and desktop. [bottom] is
/// the screen's main action, held at the foot of the screen (above the keyboard when it is
/// open) instead of wherever the form happens to end.
class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key, required this.children, this.bottom});

  final List<Widget> children;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final bottom = this.bottom;
    final list = ListView(
      padding: DockSlack.pad(context, const EdgeInsets.all(16)),
      children: children,
    );
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: bottom == null
              ? list
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: list),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: context.tokens.line),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: bottom,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
