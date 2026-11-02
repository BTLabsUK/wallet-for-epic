// SPDX-License-Identifier: Apache-2.0
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'status_icons.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../connection_state.dart';
import '../demo.dart';
import '../errors.dart';
import '../l10n.dart';
import '../network_gate.dart';
import '../payment_prefs.dart';
import '../phone_tor.dart';
import '../pairing_providers.dart' show invoicesOnProvider, invoicesShownProvider, pairingSupportedProvider;
import '../providers.dart';
import '../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../settings.dart';
import '../slate_files.dart';
import '../tor_phone.dart';
import '../tor_routes.dart';
import '../wallet_service.dart';
import 'address_view.dart';
import 'common.dart';
import 'demo_screens.dart' show TestCoinsButton;
import 'file_exchange_help.dart';
import 'handshake.dart';
import 'help_screen.dart';
import 'invoice_request_screen.dart' show InvoiceRequestScreen;
import 'levels/pay_arrival.dart';
import '../levels/level_providers.dart' show levelFeaturesProvider;
import '../levels/relay_switch_providers.dart' show relaySwitchResultProvider;
import 'method_strip.dart';
import 'payment_gate.dart';
import 'settings_screen.dart';
import 'network_mode_phone.dart' show openNetworkSection;
import 'network_mode_text.dart';
import 'status.dart' show EpicboxState, offGlyphColor, relayLabel;
import 'qr_scan_screen.dart';
import 'relay_blocked.dart';
import 'request_qr_screen.dart' show openQrRequest;
import 'scan_screen.dart' show offersQrPayment;
import 'server_picker.dart' show showEpicboxPicker;
import 'slate_file_screen.dart';
import 'net_block.dart';
import 'theme/advanced.dart';
import 'theme/brand.dart';
import 'theme/protocol.dart';
import 'theme/tokens.dart';
import 'tor_ui.dart';
import 'tour/tour_target.dart';

/// Receive's ways of receiving, one tab each: Epicbox first and by default, Link (the
/// Link · Tor onion address where the app has Tor, and the Link · HTTP address for this Wi-Fi
/// network), a code scanned from the phone next to this one (Direct · QR) and a payment file
/// (Direct · File).
enum ReceiveTab { epicbox, direct, qr, file }

/// Which of Receive's tabs shows. Kept while the app runs, across tab changes and rebuilds;
/// Epicbox at start.
final receiveTabProvider = NotifierProvider<ReceiveTabNotifier, ReceiveTab>(
  ReceiveTabNotifier.new,
);

class ReceiveTabNotifier extends Notifier<ReceiveTab> {
  @override
  ReceiveTab build() => ReceiveTab.epicbox;

  void choose(ReceiveTab tab) => state = tab;
}

/// The key of Receive's tab choice, for tests.
const Key receiveTabsKey = ValueKey('receive-tabs');

/// The QR code's side on Receive: at most [receiveQrMaxSize], and less when the Epicbox tab
/// would not fit the screen otherwise, down to [receiveQrMinSize]: 110 dp (17.5 mm) still scans
/// from a phone held close, and lets the tab fit a 360 x 800 dp phone. Below that the page
/// scrolls.
const double receiveQrMaxSize = 240, receiveQrMinSize = 110;

/// Receiving: epicbox payments arrive by themselves while connected; with Link · Tor and Tor
/// on, other wallets reach this one at its onion address while the app is open; with
/// Link · HTTP on, wallets on this Wi-Fi network reach it at its HTTP address; a payment file
/// or its text can still be accepted by hand.
///
/// The Receive tab's content: a choice at the top with Send's look, then on Epicbox the
/// address (tap to copy, Share inside), the epicbox line, the QR code, and the demo's test
/// coins and requesting a payment when the wallet handles invoices; on Link, stacked, the
/// onion address in the same card, Tor's state and the QR code (or with Tor off a Turn on
/// Tor) while Link · Tor is on (the phone receives nothing over Link · HTTP); on File the
/// file card. Help ends them all. The QR code takes the room
/// left, so the Epicbox tab fits a phone without scrolling.
/// Room on each side of a method tab's label.
const double _tabPad = 4;

/// The labels of a row of method tabs at one size: each on one line where it fits [width],
/// else broken at its " · " (family on one line, option on the next); when a line still does
/// not fit, one smaller size for all of them, never a size per tab.
({List<String> texts, double size}) fitTabLabels(
  BuildContext context,
  List<String> labels, {
  required double width,
  required TextStyle style,
}) {
  final scaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.of(context);
  double widthOf(String line) {
    final painter = TextPainter(
      text: TextSpan(text: line, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }

  var scale = 1.0;
  final texts = <String>[];
  for (final label in labels) {
    final lines = widthOf(label) > width && label.contains(' · ')
        ? label.split(' · ')
        : [label];
    texts.add(lines.join('\n'));
    for (final line in lines) {
      final w = widthOf(line);
      if (w > width && width > 0) scale = math.min(scale, width / w);
    }
  }
  return (texts: texts, size: (style.fontSize ?? 12) * scale);
}

/// Level 1's quiet link between QR Payment and the address.
const Key receiveQuietQrKey = ValueKey('receive-quiet-qr');

class ReceiveView extends ConsumerWidget {
  const ReceiveView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final torAvailable = ref.watch(phoneTorProvider.select(torShown));
    var tab = ref.watch(receiveTabProvider);
    final payments =
        ref.watch(appSettingsProvider.select((s) => s.value?.payments)) ??
        (ref.watch(phonePaymentsProvider)
            ? PaymentPrefs.phoneDefaults
            : PaymentPrefs.defaults);
    final filePending = hasPendingFileSend(
      ref.watch(homeProvider.select((h) => h.value?.transactions)),
    );
    final torState = phoneTorState(ref.watch(phoneTorProvider));
    // Level 1: no method tabs or strip; QR Payment is a quiet link.
    final quiet = !ref.watch(levelFeaturesProvider.select((f) => f.methodStrip));
    final relayMove = quiet ? ref.watch(relaySwitchResultProvider) : null;
    final arriving = quiet ? arrivingPayment(ref.watch(homeProvider.select((h) => h.value?.transactions)) ?? const []) : null;
    // Link: the Tor part where the app has Tor and Link · Tor is on. Link · HTTP only sends.
    // The Link tab keeps its page with Link · Tor off: it offers to turn it on.
    // Offline: the addresses stay to hand out, with a line that nothing arrives meanwhile.
    final offlineBlock = watchNetBlock(context, ref);
    final offline = offlineBlock.byMode;
    final offlineNote = NetBlockNote(offlineBlock, line: l.receiveLinkOffMode(networkModeName(l, ref.watch(networkModeProvider))));
    final address = ref.watch(addressProvider);
    // The Epicbox list of the settings file is empty: no server, so no address to hand out
    // (LEPIC's is on a placeholder server, lepic_wallet_service.dart's noEpicboxDomain).
    final noServer = ref.watch(hostSettingsProvider.select((h) => h.epicboxServers.isEmpty));
    final demo = ref.watch(demoModeProvider);
    // Requests go to paired contacts or into a file, both through pairing (RFC 0002).
    final invoices = ref.watch(invoicesShownProvider) && ref.watch(pairingSupportedProvider);
    final help = Center(
      child: TextButton.icon(
        icon: const Icon(Icons.help_outline),
        label: Text(l.receiveHelpButton),
        onPressed: () => openHelp(context, HelpId.receive),
      ),
    );
    ({ReceiveTab value, IconData icon, String label}) segment(ReceiveTab value, IconData icon, String label) =>
        (value: value, icon: icon, label: label);
    // With Epicbox alone there is nothing to choose: the strip names it.
    final tabSegments = <({ReceiveTab value, IconData icon, String label})>[
        // Epicbox off (Settings › Transactions): no address to hand out, no tab.
        if (payments.epicbox)
          segment(ReceiveTab.epicbox, MethodIcons.of(MethodKind.epicbox), MethodIcons.shortName(l, MethodKind.epicbox)),
        // Link is Link · Tor on the phone (Link · HTTP only sends): no tab without Tor. With
        // Tor, Link stays whatever Settings › Transactions says, so the strip never jumps:
        // with Link · Tor off its page offers to turn it on.
        if (!quiet && torAvailable)
          segment(ReceiveTab.direct, MethodIcons.family(MethodFamily.link), MethodIcons.familyName(l, MethodFamily.link)),
        // QR is the phone next to this one: offered where the camera works.
        if (tab == ReceiveTab.qr || ((payments.directQr || quiet) && offersQrPayment(ref)))
          segment(ReceiveTab.qr, MethodIcons.of(MethodKind.directQr), MethodIcons.shortName(l, MethodKind.directQr)),
        // The tab in use and a file send waiting for its reply keep File.
        if (!quiet && (tab == ReceiveTab.file || payments.directFile || filePending))
          segment(ReceiveTab.file, MethodIcons.of(MethodKind.directFile), MethodIcons.shortName(l, MethodKind.directFile)),
    ];
    // Every method off: nothing to show but the way to Settings.
    if (tabSegments.isEmpty) {
      return CenteredScroll(
        child: EmptyState(
          key: receiveNoMethodsKey,
          icon: const Icon(Icons.call_received),
          message: '${l.receiveNoMethods}. ${l.receiveNoMethodsBody}',
          action: FilledButton.tonal(
            onPressed: () => openSettingsSection(context, SettingsSection.transactions),
            child: Text(l.receiveNoMethodsButton),
          ),
        ),
      );
    }
    // The tab in use went off: the first that is on.
    if (!tabSegments.any((s) => s.value == tab)) tab = tabSegments.first.value;
    final Widget tabs = tabSegments.length == 1 || quiet
        ? const SizedBox.shrink()
        : LayoutBuilder(
            builder: (context, box) {
              // Icon above the label, every label at one size (PH-1): the selected tab changes
              // colour (the button's own, accent when selected) and weight, never size. Measured
              // at the heavier weight. Room per tab: its share, less the padding and dividers.
              final style = Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w600);
              // On a narrow phone the icons alone; the label stays in the tooltip and for
              // screen readers (UP-002).
              final iconOnly = box.maxWidth < 360;
              final fit = fitTabLabels(
                context,
                [for (final s in tabSegments) s.label],
                width: box.maxWidth / tabSegments.length - 2 * _tabPad - 2,
                style: style,
              );
              return SegmentedButton<ReceiveTab>(
                key: receiveTabsKey,
                segments: [
                  for (final (i, s) in tabSegments.indexed)
                    ButtonSegment(
                      value: s.value,
                      tooltip: s.label,
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(s.icon, size: 18, semanticLabel: iconOnly ? s.label : null),
                          if (!iconOnly) const SizedBox(height: 2),
                          if (!iconOnly)
                          Text(
                            fit.texts[i],
                            maxLines: 2,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            // No colour here: the button's selected and unselected colours.
                            style: TextStyle(
                              fontSize: fit.size,
                              fontWeight: s.value == tab ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                selected: {tab},
                showSelectedIcon: false,
                expandedInsets: EdgeInsets.zero,
                style: const ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(Size(0, 44)),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: _tabPad, vertical: 6),
                  ),
                ),
                onSelectionChanged: (selected) =>
                    ref.read(receiveTabProvider.notifier).choose(selected.first),
              );
            },
          );
    Widget column(List<Widget> children) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    // What the tab means, so the sender's side is plain: picture, title, one line.
    final strip = quiet ? const SizedBox.shrink() : Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DismissibleTip(
        id: receiveMethodTipId,
        child: MethodStrip(
          method: switch (tab) {
            ReceiveTab.epicbox => TransferMethod.epicbox,
            ReceiveTab.direct => TransferMethod.direct,
            ReceiveTab.qr => TransferMethod.qr,
            ReceiveTab.file => TransferMethod.file,
          },
          receiving: true,
          overTor:
              tab == ReceiveTab.epicbox &&
              torWay(TorRoute.epicbox, torState) == TorWay.overTor,
        ),
      ),
    );
    Widget caption(String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: context.tokens.dim),
      ),
    );
    final value = noServer ? null : address.value;
    // Level 1's quiet link: into QR Payment from the address, back out of it.
    Widget quietLink() {
      final toQr = tab != ReceiveTab.qr;
      if (toQr && !tabSegments.any((s) => s.value == ReceiveTab.qr)) return const SizedBox.shrink();
      return Center(
        child: TextButton(
          key: receiveQuietQrKey,
          style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
          onPressed: () => ref.read(receiveTabProvider.notifier).choose(toQr ? ReceiveTab.qr : ReceiveTab.epicbox),
          child: Text(toQr ? l.lvPaySendQrLink : l.lvPayReceiveBack),
        ),
      );
    }
    final Widget above;
    final Widget? code;
    final Widget below;
    if (tab == ReceiveTab.qr) {
      above = column([
        strip,
        const _QrCard(),
        const SizedBox(height: 8),
        if (quiet) quietLink(),
        help,
      ]);
      code = null;
      below = const SizedBox.shrink();
    } else if (tab == ReceiveTab.file) {
      above = column([
        strip,
        const _FileCard(),
        const SizedBox(height: 8),
        help,
      ]);
      code = null;
      below = const SizedBox.shrink();
    } else if (tab == ReceiveTab.direct && !payments.linkTor) {
      // Link · Tor off: say so and offer its switch (GP-024). The tab is there only with Tor.
      above = column([
        strip,
        _LinkOff(payments: payments),
        const SizedBox(height: 8),
        help,
      ]);
      code = null;
      below = const SizedBox.shrink();
    } else if (tab == ReceiveTab.direct && torState == TorState.off) {
      // No Link · Tor receiving without Tor, and no onion to hand out: Tor never runs in
      // Offline either.
      above = column([
        strip,
        _DirectNeedsTor(epicbox: payments.epicbox, offline: offline),
        if (offline) offlineNote,
        const SizedBox(height: 8),
      ]);
      code = null;
      below = column([
        const SizedBox(height: 8),
        help,
      ]);
    } else if (tab == ReceiveTab.direct) {
      final onion = ref.watch(phoneTorProvider.select((s) => s.onion));
      // The code stays, scannable and the same address, but dimmed until the address is
      // reachable: the state line under it says why.
      final reachable = ref.watch(
        phoneTorProvider.select((s) => s.phase == PhoneTorPhase.ready),
      );
      above = column([
        strip,
        if (onion != null) ...[
          AnimatedOpacity(
            opacity: reachable ? 1 : 0.6,
            duration: const Duration(milliseconds: 300),
            child: _AddressRow(
              address: onion,
              label: l.receiveTorAddressLabel,
              cardKey: receiveTorAddressKey,
            ),
          ),
          caption(l.receiveTorCaption),
          const SizedBox(height: 8),
        ] else
          const LinearProgressIndicator(),
        if (offline)
          offlineNote
        else
          TorStateLine(openSettings: () => openPrivacySettings(context)),
        const SizedBox(height: 4),
      ]);
      code = onion == null
          ? null
          : LayoutBuilder(
              builder: (context, room) => AnimatedOpacity(
                key: receiveTorQrKey,
                opacity: reachable ? 1 : 0.4,
                duration: const Duration(milliseconds: 300),
                child: _AddressQr(
                  address: onion,
                  semanticsLabel: l.receiveTorQrLabel,
                  size:
                      math
                          .min(room.maxWidth, room.maxHeight)
                          .clamp(
                            receiveQrMinSize + _AddressQr.frame,
                            receiveQrMaxSize + _AddressQr.frame,
                          ) -
                      _AddressQr.frame,
                ),
              ),
            );
      below = column([
        const SizedBox(height: 8),
        help,
      ]);
    } else {
      above = column([
        strip,
        if (noServer)
          EmptyState(
            key: const ValueKey('receive-no-epicbox'),
            icon: Icon(MethodIcons.of(MethodKind.epicbox)),
            message: '${l.deskSlNoEpicboxTitle}. ${l.deskSlNoEpicboxText}',
            action: FilledButton.tonal(onPressed: () => showEpicboxPicker(context), child: Text(l.slRelayField)),
          )
        else if (value != null) ...[
          if (relayMove != null) ...[const NewAddressBadge(), const SizedBox(height: 4)],
          PhoneTourTarget(
            id: 'tour-receive-address',
            child: _AddressRow(
              address: value,
              label: relayMove != null ? l.lvPayNewAddress : l.receiveAddressLabel,
              cardKey: receiveAddressKey,
            ),
          ),
          const SizedBox(height: 8),
          if (relayMove != null) ...[NewAddressLines(result: relayMove), const SizedBox(height: 8)],
          if (offline) _EpicboxOffByMode(mode: ref.watch(networkModeProvider)) else const _EpicboxLine(),
          if (demo) const _KeepTabOpenLine(),
          const SizedBox(height: 8),
        ] else if (address.hasError)
          ErrorText(describeError(l, address.error!))
        else
          const LinearProgressIndicator(),
      ]);
      code = value == null
          ? null
          : LayoutBuilder(
              builder: (context, room) => _AddressQr(
                address: value,
                size:
                    math
                        .min(room.maxWidth, room.maxHeight)
                        .clamp(
                          receiveQrMinSize + _AddressQr.frame,
                          receiveQrMaxSize + _AddressQr.frame,
                        ) -
                    _AddressQr.frame,
              ),
            );
      below = column([
        if (arriving != null) ...[const SizedBox(height: 8), ArrivalCard(tx: arriving)],
        if (quiet) quietLink(),
        if (demo || invoices) ...[
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, box) {
              // Both buttons on a narrow phone: the framework's tighter icon-button padding,
              // so they share one row instead of stacking (the tab then fits 360 x 800 dp).
              final tight = demo && value != null && invoices && box.maxWidth < 360;
              const padding = EdgeInsetsDirectional.fromSTEB(8, 0, 12, 0);
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (demo && value != null) TestCoinsButton(padding: tight ? padding : null),
                  if (invoices) _RequestButton(padding: tight ? padding : null),
                ],
              );
            },
          ),
        ],
        const SizedBox(height: 8),
        help,
      ]);
    }
    const padding = 16.0;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(padding),
                child: _ReceivePage(
                  height: math.max(0, viewport.maxHeight - 2 * padding),
                  leastCode: receiveQrMinSize + _AddressQr.frame,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: tabs,
                    ),
                    above,
                    ?code,
                    below,
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

/// Receive's page: the tabs at the top, then the rest right under them on every tab, so
/// switching tabs never moves the content's start (a centred tab left a band of empty page
/// above it). With
/// four children the third is the QR code, which gets the room the others leave, at least
/// [leastCode]: the page is [height] tall, or taller and scrolled when even the least code
/// does not fit.
class _ReceivePage extends MultiChildRenderObjectWidget {
  const _ReceivePage({
    required this.height,
    required this.leastCode,
    required super.children,
  });

  final double height;
  final double leastCode;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReceivePage(height, leastCode);

  @override
  void updateRenderObject(BuildContext context, _RenderReceivePage render) {
    render
      ..height = height
      ..leastCode = leastCode;
  }
}

class _ReceivePageData extends ContainerBoxParentData<RenderBox> {}

class _RenderReceivePage extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ReceivePageData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ReceivePageData> {
  _RenderReceivePage(this._height, this._leastCode);

  double _height;
  set height(double value) {
    if (value == _height) return;
    _height = value;
    markNeedsLayout();
  }

  double _leastCode;
  set leastCode(double value) {
    if (value == _leastCode) return;
    _leastCode = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ReceivePageData) {
      child.parentData = _ReceivePageData();
    }
  }

  @override
  double computeMinIntrinsicHeight(double width) => _height;

  @override
  double computeMaxIntrinsicHeight(double width) => _height;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.constrain(Size(constraints.maxWidth, _height));

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final children = getChildrenAsList();
    final loose = BoxConstraints(maxWidth: width);
    final tight = BoxConstraints.tightFor(width: width);
    // The tabs, the part above the code and the part below it: as tall as they are.
    final rest = [
      for (final (i, child) in children.indexed)
        if (children.length < 4 || i != 2) child,
    ];
    var used = 0.0;
    for (final child in rest) {
      child.layout(tight, parentUsesSize: true);
      used += child.size.height;
    }
    if (children.length == 4) {
      final code = children[2];
      code.layout(
        loose.copyWith(maxHeight: math.max(_height - used, _leastCode)),
        parentUsesSize: true,
      );
      used += code.size.height;
    }
    size = constraints.constrain(Size(width, math.max(_height, used)));
    // The tabs stay at the top; the rest starts right under them, centred across.
    final head = children.first;
    var y = head.size.height;
    (head.parentData! as _ReceivePageData).offset = Offset.zero;
    for (final child in children.skip(1)) {
      (child.parentData! as _ReceivePageData).offset = Offset(
        (width - child.size.width) / 2,
        y,
      );
      y += child.size.height;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

/// The key of the address card, which copies on a tap, for tests.
const Key receiveAddressKey = ValueKey('receive-address');

/// The key of the onion address card on the Direct tab, for tests.
const Key receiveTorAddressKey = ValueKey('receive-tor-address');

/// The key of the Tor address's QR code (its opacity: dim until reachable), for tests.
const Key receiveTorQrKey = ValueKey('receive-tor-qr');

/// The key of Share inside the address card, for tests.
const Key receiveShareKey = ValueKey('receive-share');

/// The key of the epicbox line, for tests.
const Key receiveEpicboxKey = ValueKey('receive-epicbox');

/// The full address in a full-width card that copies on a tap anywhere on it, with the copy
/// icon and, where the device shares, Share stacked on its right. [label] names the kind of
/// address above it: the same card for the epicbox and the Tor address.
class _AddressRow extends ConsumerStatefulWidget {
  const _AddressRow({
    required this.address,
    required this.label,
    required this.cardKey,
  });

  final String address;
  final String label;

  /// The key of the card's tap target, for tests.
  final Key cardKey;

  @override
  ConsumerState<_AddressRow> createState() => _AddressRowState();
}

class _AddressRowState extends ConsumerState<_AddressRow> {
  bool _sharing = false;

  void _copy() =>
      copyText(context, widget.address, context.l10n.receiveAddressCopied);

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await shareAddress(
        context,
        ref,
        address: widget.address,
        chain: ref.read(walletConfigProvider)?.chain,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final files = ref.watch(slateFilesProvider);
    final address = widget.address;
    // The web demo has no share card.
    final canShare =
        !ref.watch(demoModeProvider) && (files.canShare || files.canShareText);
    // A 48 dp box for each icon, stacked on the card's right: copy above share.
    const icon = 48.0;
    const inset = 4.0;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Semantics(
            key: widget.cardKey,
            container: true,
            button: true,
            label: widget.label,
            value: address,
            onTapHint: l.commonCopy,
            onTap: _copy,
            excludeSemantics: true,
            child: InkWell(
              onTap: _copy,
              child: ConstrainedBox(
                // Room for both icons, however short the address.
                constraints: BoxConstraints(
                  minHeight: canShare ? 2 * icon + 2 * inset : 0,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    16,
                    inset,
                    inset,
                    inset,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.label,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: t.dim,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Selectable for a long press; a tap copies, like the card.
                              // The server on its own line, shrunk rather than broken inside
                              // its name on a narrow phone at a large text size (UP-033).
                              MarkedAddress(address, selectable: true, onTap: _copy),
                            ],
                          ),
                        ),
                      ),
                      SizedBox.square(
                        dimension: icon,
                        child: Icon(Icons.copy, size: 20, color: t.accentText),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (canShare)
            PositionedDirectional(
              top: inset + icon,
              end: inset,
              child: IconButton(
                key: receiveShareKey,
                tooltip: l.commonShare,
                constraints: const BoxConstraints.tightFor(
                  width: icon,
                  height: icon,
                ),
                padding: EdgeInsets.zero,
                onPressed: _sharing ? null : _share,
                // Through the button, so it greys while a share is under way.
                color: t.accentText,
                icon: const Icon(Icons.share, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

/// The Epicbox tab while Node only or Kill switch turns Epicbox off: the status word reads Off
/// ({mode}), and the address stays shown and copyable above; payments to it wait on the Epicbox
/// server and arrive when the mode is left.
class _EpicboxOffByMode extends StatelessWidget {
  const _EpicboxOffByMode({required this.mode});

  final NetworkMode mode;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final name = networkModeName(l, mode);
    return Column(
      key: receiveEpicboxOffModeKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          container: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(EpicGlyphs.epicbox, size: 16, color: offGlyphColor(t)),
              const SizedBox(width: 6),
              Flexible(child: Text(statusOffByModeWord(l, mode), style: theme.textTheme.labelMedium?.copyWith(color: t.dim))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.receiveEpicboxOffMode(name),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          l.receiveEpicboxOffModeBody(name),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
        ),
        Center(
          child: TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
            onPressed: () => openNetworkSection(context),
            child: Text(l.netChangeLink),
          ),
        ),
      ],
    );
  }
}

/// The key of the Epicbox-off-by-mode notice on Receive, for tests.
const Key receiveEpicboxOffModeKey = ValueKey('receive-epicbox-off-mode');

/// Where the epicbox listener stands, in one quiet line. Offline or stopped, it says what that
/// means for receiving and offers Retry, which restarts the listener. Blocked by this network,
/// it says so and offers another relay in one tap ([RelayBlockedNote]).
class _EpicboxLine extends ConsumerWidget {
  const _EpicboxLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    // As the header shows it: offline only once it lasts; a stopped listener (null) at once.
    final epicbox = ref.watch(walletStatusProvider.select((s) => s.epicbox));
    final offline = epicbox == null || epicbox == EpicboxState.offline;
    final blocked = epicbox == EpicboxState.blocked;
    final config = ref.watch(walletConfigProvider);
    // State first, then the server (GP-021): the server matters after a switch, as the
    // address changes with it. Level 1 names no server: the state alone.
    final hosts = ref.watch(levelFeaturesProvider.select((f) => f.serverNames));
    final host = config == null || !hosts ? null : relayLabel(config);
    final (IconData icon, String word, Color color) =
        epicbox == EpicboxState.online
        ? (EpicGlyphs.epicbox, host != null ? l.receiveEpicboxConnected(host) : hosts ? l.statusEpicboxOnline : l.lvShellBoxListening, t.ok)
        : blocked
        ? (EpicGlyphs.epicbox, l.statusEpicboxBlocked, t.risk)
        : offline
        ? (EpicGlyphs.epicbox, host == null ? l.statusEpicboxOffline : l.receiveEpicboxNotConnected(host), t.risk)
        : (EpicGlyphs.epicbox, l.statusEpicboxConnecting, t.dim);
    return Column(
      key: receiveEpicboxKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          container: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  word,
                  style: theme.textTheme.labelMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
        if (config != null)
          Advanced(
            feature: AdvancedFeature.serverDetails,
            child: Center(
              child: Readout(
                l.statusRelay('${config.epicboxDomain}:${config.epicboxPort}'),
              ),
            ),
          ),
        if (offline) ...[
          const SizedBox(height: 4),
          Text(
            l.receiveEpicboxOfflineBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
          ),
          Center(
            child: TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.refresh),
              label: Text(l.commonRetry),
              onPressed: () => ref.read(listenerProvider.notifier).restart(),
            ),
          ),
        ],
        if (blocked) ...[
          const SizedBox(height: 4),
          const RelayBlockedNote(),
        ],
      ],
    );
  }
}

/// The key of Turn on Tor on Receive's Link tab, for tests.
/// The Turn on button of Receive › Link while Link · Tor is off, for tests.
const Key receiveTurnOnLinkTorKey = ValueKey('receive-turn-on-link-tor');

const Key receiveTurnOnTorKey = ValueKey('receive-turn-on-tor');

/// Receive's Link tab with Link · Tor on and Tor off: Link · Tor receiving needs Tor, the
/// Epicbox address works meanwhile (while [epicbox] is on), and Turn on Tor (the one switch,
/// as in Settings › Privacy).
/// Receive › Link with Link · Tor off: the reason and its Turn on.
class _LinkOff extends ConsumerWidget {
  const _LinkOff({required this.payments});

  final PaymentPrefs payments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.netBlockMethodOff(MethodIcons.fullName(l, MethodKind.linkTor)),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: context.tokens.dim),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          key: receiveTurnOnLinkTorKey,
          style: FilledButton.styleFrom(minimumSize: const Size(48, 44)),
          icon: Icon(MethodIcons.of(MethodKind.linkTor)),
          label: Text(l.sendTurnOnMethod(MethodIcons.fullName(l, MethodKind.linkTor))),
          onPressed: () => ref.read(appSettingsProvider.notifier).setPayments(payments.withMethod(MethodKind.linkTor, true)),
        ),
      ],
    );
  }
}

class _DirectNeedsTor extends ConsumerWidget {
  const _DirectNeedsTor({required this.epicbox, this.offline = false});

  final bool epicbox;

  /// Offline mode: Tor does not run and nothing arrives, so no way to turn it on here and no
  /// pointer to the Epicbox address; the offline line follows.
  final bool offline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Text(
          l.receiveDirectNeedsTor,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        if (epicbox && !offline) ...[
          const SizedBox(height: 4),
          Text(
            l.receiveDirectMeanwhile,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: context.tokens.dim),
          ),
        ],
        if (!offline) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            key: receiveTurnOnTorKey,
            style: FilledButton.styleFrom(minimumSize: const Size(48, 44)),
            icon: const Icon(torIcon),
            label: Text(l.torTurnOn),
            onPressed: () =>
                ref.read(phoneTorProvider.notifier).setReceiving(true),
          ),
        ] else
          const SizedBox(height: 8),
      ],
    );
  }
}

/// The web demo's one rule for receiving, under the epicbox line: payments arrive only while
/// this browser tab is open.
class _KeepTabOpenLine extends StatelessWidget {
  const _KeepTabOpenLine();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(
      context.l10n.demoReceiveKeepOpen,
      key: receiveKeepOpenKey,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: context.tokens.dim),
    ),
  );
}

/// The key of the demo's "keep this tab open" line on Receive, for tests.
const Key receiveKeepOpenKey = ValueKey('receive-keep-open');

/// The address as a QR code of [size] with the mark, framed by corner ticks. Covered until
/// Show QR is tapped (the QR rule: never shown on open, the box keeps its size so nothing
/// moves); a tap on the shown code covers it again. Never remembered: a new visit starts
/// covered.
class _AddressQr extends StatefulWidget {
  const _AddressQr({
    required this.address,
    required this.size,
    this.semanticsLabel,
  });

  final String address;
  final double size;

  /// What a screen reader calls it; the epicbox address's code without it.
  final String? semanticsLabel;

  /// What the frame adds to the code's side: the ticks' and the white margin's padding.
  static const double frame = 2 * 12 + 2 * 16;

  @override
  State<_AddressQr> createState() => _AddressQrState();
}

class _AddressQrState extends State<_AddressQr> {
  bool _shown = false;

  @override
  void didUpdateWidget(_AddressQr old) {
    super.didUpdateWidget(old);
    if (old.address != widget.address) _shown = false;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final code = MarkedQr(data: widget.address, size: widget.size);
    return Center(
      // As tall as the code, so the page stacks it with the rest.
      heightFactor: 1,
      // The corner ticks frame the code as the screen's one object.
      child: CustomPaint(
        foregroundPainter: CornerTicksPainter(t.tick, length: 16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Dark modules on white scan reliably in either theme.
              color: protocolLight.surface,
              borderRadius: BorderRadius.circular(t.radiusSmall),
              boxShadow: [
                BoxShadow(
                  color: t.accent.withValues(alpha: dark ? 0.22 : 0.12),
                  blurRadius: 40,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _shown
                  ? Semantics(
                      key: const ValueKey('shown'),
                      label: widget.semanticsLabel ?? l.receiveQrLabel,
                      image: true,
                      onTapHint: l.receiveHttpHideQr,
                      child: GestureDetector(
                        onTap: () => setState(() => _shown = false),
                        child: code,
                      ),
                    )
                  : Stack(
                      key: receiveShowQrKey,
                      alignment: Alignment.center,
                      children: [
                        Semantics(
                          label: widget.semanticsLabel ?? l.receiveQrLabel,
                          image: true,
                          child: ExcludeSemantics(
                            child: ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                              child: Opacity(opacity: 0.35, child: code),
                            ),
                          ),
                        ),
                        // Over the code, never wider: the smallest code is narrower than the
                        // button in some languages.
                        Positioned.fill(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: FilledButton.tonalIcon(
                                // The white box stays white in both themes: the button takes
                                // the light theme's colours with it.
                                style: FilledButton.styleFrom(
                                  backgroundColor: protocolLight.surfaceHi,
                                  foregroundColor: protocolLight.text,
                                ),
                                icon: const Icon(Icons.qr_code_2, size: 18),
                                label: Text(l.receiveHttpShowQr),
                                onPressed: () => setState(() => _shown = true),
                              ),
                            ),
                          ),
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

/// The key of Show QR on the covered address code, for tests.
const Key receiveShowQrKey = ValueKey('receive-show-qr');

/// Receiving by QR: the sender's phone shows the payment, this one scans it, accepts and shows
/// its reply. A title, one line and the camera button.
class _QrCard extends ConsumerWidget {
  const _QrCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    // Scanning a payment asks the node to sign, like opening a file: Offline lets it use the
    // node in use, and says so when that node is not local.
    final offlineNode = watchOfflineUsesNode(context, ref);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l.receiveQrTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.sendHowItWorks,
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => showHandshakeSheet(
                    context,
                    flow: HandshakeFlow.qrReceive,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l.receiveQrBody,
              style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: receiveScanQrKey,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l.qrScanPayment),
              onPressed: () => scanSlateQr(context, ref),
            ),
            // Asking for an amount: a request shown as a QR (only while Invoices is on).
            if (ref.watch(invoicesOnProvider) &&
                ref.watch(sessionProvider.select((s) => s?.supportsRequestFiles ?? false))) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: receiveQrRequestKey,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.request_quote_outlined),
                label: Text(l.receiveQrRequest),
                onPressed: () => openQrRequest(context),
              ),
            ],
            if (offlineNode)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: OfflineNodeNote(),
              ),
          ],
        ),
      ),
    );
  }
}

/// Receiving by payment file, for everyone: Open file, Paste, and a ? for the explainer.
class _FileCard extends ConsumerWidget {
  const _FileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    // Opening or pasting a file asks the node: Offline lets it use the node in use, and says
    // so when that node is not local.
    final offlineNode = watchOfflineUsesNode(context, ref);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l.receiveFileTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.fileHelpTitle,
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => showFileExchangeHelp(
                    context,
                    role: FileExchangeRole.receiver,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                l.receiveFileBody,
                style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.file_open_outlined),
                      label: Text(l.receiveFileOpen),
                      onPressed: () => openSlateFile(context, ref),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.content_paste),
                      label: Text(l.commonPaste),
                      onPressed: () => pasteSlate(context, ref),
                    ),
                  ),
                ],
              ),
            ),
            if (offlineNode)
              const Padding(
                padding: EdgeInsets.only(top: 4, right: 12),
                child: OfflineNodeNote(),
              ),
          ],
        ),
      ),
    );
  }
}

/// The key of the Scan payment QR button of Receive's file card, for tests.
const Key receiveScanQrKey = ValueKey('receive-scan-qr');
const Key receiveQrRequestKey = ValueKey('receive-qr-request');

/// The key of Receive's empty state when every method is off, for tests.
const Key receiveNoMethodsKey = ValueKey('receive-no-methods');

/// The key of Receive's request button, for tests.
const Key receiveRequestKey = ValueKey('receive-request');

/// Asking someone to pay this wallet, when the wallet handles invoices: the button to the
/// request form.
class _RequestButton extends StatelessWidget {
  const _RequestButton({this.padding});

  /// The side padding where its row is short of room; the theme's when null.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: receiveRequestKey,
    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48), padding: padding),
    icon: const Icon(Icons.request_quote_outlined),
    label: Text(context.l10n.receiveRequestTitle),
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const InvoiceRequestScreen()),
    ),
  );
}

/// Reads payment text from the clipboard and opens it in [SlateFileScreen], as a file would
/// be. Says so in a notice when the clipboard holds nothing that can be one.
Future<void> pasteSlate(BuildContext context, WidgetRef ref) async {
  final notice = ref.read(noticeProvider.notifier);
  final l = context.l10n;
  final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
  if (text == null || text.isEmpty) {
    notice.show(l.receivePasteEmpty, level: NoticeLevel.info);
    return;
  }
  final String json;
  try {
    json = decodeSlateFile(utf8.encode(text));
  } on FormatException catch (error) {
    notice.show(describeError(l, error), level: NoticeLevel.error);
    return;
  }
  if (!context.mounted) return;
  await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => SlateFileScreen(
        file: SlateFile(name: pastedSlateName, json: json),
        pasted: true,
      ),
    ),
  );
}

/// Reads an animated payment QR with the camera and opens what it carried in
/// [SlateFileScreen], as pasted text would be. "Open a file instead" on the camera screen
/// runs the file picker. [first] is a part Home's scan already read.
Future<void> scanSlateQr(
  BuildContext context,
  WidgetRef ref, {
  String? first,
}) async {
  final notice = ref.read(noticeProvider.notifier);
  final l = context.l10n;
  final result = await scanQrSlate(context, QrScanKind.payment, first: first);
  if (!context.mounted) return;
  switch (result) {
    case QrScanned(:final json):
      final String text;
      try {
        text = decodeSlateFile(utf8.encode(json));
      } on FormatException catch (error) {
        notice.show(describeError(l, error), level: NoticeLevel.error);
        return;
      }
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => SlateFileScreen(
            file: SlateFile(name: scannedSlateName, json: text),
            pasted: true,
            scanned: true,
          ),
        ),
      );
    case QrScanOpenFile():
      await openSlateFile(context, ref);
    case null:
      break;
  }
}

/// The share card's size in logical pixels, and the pixel ratio it is rendered at: a
/// 1080 x 1800 PNG.
const Size shareCardSize = Size(360, 600);
const double shareCardPixelRatio = 3;

/// The name of the shared card image.
const String shareCardFileName = 'epic-cash-address.png';

/// Shares [address]: as a [ShareCard] image with the address as its text where files can be
/// shared, else as the address alone. Holds auto-lock while the share sheet is open.
Future<void> shareAddress(
  BuildContext context,
  WidgetRef ref, {
  required String address,
  Chain? chain,
}) async {
  final files = ref.read(slateFilesProvider);
  final hold = ref.read(autoLockHoldProvider.notifier);
  if (!files.canShare) {
    await hold.during(() => files.shareText(address));
    return;
  }
  Uint8List? png;
  try {
    png = await renderShareCard(context, address: address, chain: chain);
  } catch (error) {
    // The address alone still gets it across.
    logWarn(
      'share',
      'rendering the address card failed: '
          '${describeError(englishStrings, error)}',
    );
  }
  if (png == null) {
    await hold.during(() => files.shareText(address));
    return;
  }
  final image = png;
  await hold.during(
    () => files.shareImage(name: shareCardFileName, png: image, text: address),
  );
}

/// Renders the [ShareCard] for [address] to a PNG of [shareCardSize] at
/// [shareCardPixelRatio], in the light theme, offscreen. Words come from [context]'s language.
Future<Uint8List> renderShareCard(
  BuildContext context, {
  required String address,
  Chain? chain,
}) {
  final l = context.l10n;
  final card = ShareCard(
    address: address,
    headline: l.receiveShareCardHeadline,
    network: chain == null || chain == Chain.mainnet || !devNetworksOf(context)
        ? null
        : chainName(l, chain),
  );
  return renderOffscreen(
    view: View.of(context),
    size: shareCardSize,
    pixelRatio: shareCardPixelRatio,
    textDirection: Directionality.of(context),
    child: Theme(
      data: buildWalletTheme(protocolLight, Brightness.light),
      child: card,
    ),
  );
}

/// Lays out and paints [child] in a tree of its own, never on screen, and returns it as a PNG
/// of [size] times [pixelRatio]. [child] sees no providers, localizations or inherited theme:
/// give it what it needs.
Future<Uint8List> renderOffscreen({
  required ui.FlutterView view,
  required Size size,
  required double pixelRatio,
  required TextDirection textDirection,
  required Widget child,
}) async {
  final boundary = RenderRepaintBoundary();
  final renderView = RenderView(
    view: view,
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(size),
      physicalConstraints: BoxConstraints.tight(size * pixelRatio),
      devicePixelRatio: pixelRatio,
    ),
    child: RenderPositionedBox(child: boundary),
  );
  final pipeline = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();
  final focus = FocusManager();
  final build = BuildOwner(focusManager: focus);
  final root = RenderObjectToWidgetAdapter<RenderBox>(
    container: boundary,
    child: MediaQuery(
      data: MediaQueryData(size: size, devicePixelRatio: pixelRatio),
      child: Directionality(
        textDirection: textDirection,
        child: SizedBox.fromSize(size: size, child: child),
      ),
    ),
  ).attachToRenderTree(build);
  try {
    build.buildScope(root);
    build.finalizeTree();
    pipeline
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    // Unmounts the tree, so its elements and render objects are released.
    RenderObjectToWidgetAdapter<RenderBox>(container: boundary)
        .attachToRenderTree(build, root);
    build.finalizeTree();
    focus.dispose();
  }
}

/// The picture Share sends: the mark, [headline], the QR code with the mark, the full
/// [address], and the [network] name off mainnet. Built for [shareCardSize] in the light
/// theme; it reads its colours from the theme's tokens.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.address,
    required this.headline,
    this.network,
  });

  final String address;
  final String headline;
  final String? network;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final network = this.network;
    return Material(
      color: t.bg,
      child: Padding(
        // The ticks sit inside the edge, so a chat's rounded crop does not cut them.
        padding: const EdgeInsets.all(14),
        child: CustomPaint(
          foregroundPainter: CornerTicksPainter(t.tick, length: 18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: EpicMark(size: 48)),
                const SizedBox(height: 16),
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: t.headFamily,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: t.surface,
                      border: Border.all(color: t.line),
                      borderRadius: BorderRadius.circular(t.radiusSmall),
                    ),
                    child: MarkedQr(data: address, size: 232),
                  ),
                ),
                const SizedBox(height: 20),
                // As on the card in the app: the ends marked, the server whole on its own line.
                MarkedAddress(
                  address,
                  center: true,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                if (network != null) ...[
                  const SizedBox(height: 14),
                  Center(child: EBadge(network, tone: BadgeTone.warn)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
