// SPDX-License-Identifier: Apache-2.0
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../connection_state.dart';
import '../dev_networks.dart';
import '../epic1.dart' show PaymentMode;
import '../errors.dart';
import '../l10n.dart';
import '../network_gate.dart';
import '../payment_prefs.dart';
import '../phone_tor.dart';
import '../pairing_providers.dart' show invoicesShownProvider, pairingSupportedProvider;
import '../providers.dart';
import '../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../settings.dart';
import '../slate_files.dart';
import '../trust_ids.dart';
import '../wallet_service.dart';
import 'address_view.dart';
import 'common.dart';
import 'epic1/epic1_receive.dart';
import 'help_screen.dart';
import 'invoice_request_screen.dart' show InvoiceRequestScreen;
import '../levels/relay_switch_providers.dart' show relaySwitchResultProvider;
import 'kit/kit_button.dart';
import 'kit/kit_corner_marks.dart';
import 'kit/kit_group.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_help_sheet.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_row.dart';
import 'kit/kit_tokens.dart';
import 'levels/pay_arrival.dart' show NewAddressBadge, NewAddressLines, arrivingPayment;
import 'net_block.dart';
import 'tor_ui.dart';
import 'network_mode_phone.dart' show openNetworkSection;
import 'network_mode_text.dart';
import 'receive_arriving.dart';
import 'receive_other.dart';
import 'scan_screen.dart' show offersQrPayment;
import 'server_picker.dart' show showEpicboxPicker;
import 'slate_file_screen.dart';
import 'status.dart' show EpicboxState, offGlyphColor, relayLabel;
import 'qr_scan_screen.dart';
import 'relay_blocked.dart';
import 'status_icons.dart';
import 'theme/advanced.dart';
import 'theme/brand.dart';
import 'theme/logo_qr.dart';
import 'theme/protocol.dart';
import 'theme/tokens.dart';
import 'tour/tour_target.dart';
import 'kit/kit_qr_glyph.dart';

/// The ways Receive used to offer as tabs. The phone has one screen now, with the other ways
/// in a sheet; the choice stays so that places that point at a way (relay-down, the tour, the
/// status line) keep compiling, and it is not read.
enum ReceiveTab { epicbox, direct, qr, file }

/// Kept for the callers that point Receive at a way; the one-screen Receive does not read it.
final receiveTabProvider = NotifierProvider<ReceiveTabNotifier, ReceiveTab>(
  ReceiveTabNotifier.new,
);

class ReceiveTabNotifier extends Notifier<ReceiveTab> {
  @override
  ReceiveTab build() => ReceiveTab.epicbox;

  void choose(ReceiveTab tab) => state = tab;
}

/// Opens Receive as a full screen (from Home's Receive button).
Future<void> openReceive(BuildContext context) =>
    Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const ReceiveScreen()));

/// The Receive flow screen: close, title and "?" over [ReceiveView].
class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SlotScaffold(
      body: SafeArea(
        child: Column(
          children: [
            KitFlowHeader(
              title: l.phoneRecvTitle,
              onLeading: () => Navigator.of(context).maybePop(),
              leadingId: TrustIds.receiveClose,
              onHelp: () => showKitHelp(
                context,
                title: l.phoneRecvHelpTitle,
                lines: [l.phoneRecvHelp1, l.phoneRecvHelp2, l.phoneRecvHelp3],
                onMore: () => openHelp(context, HelpId.receive),
                sheetId: TrustIds.receiveHelpSheet,
                moreId: TrustIds.receiveHelpMore,
              ),
              helpId: TrustIds.receiveHelp,
            ),
            const Expanded(child: ReceiveView()),
          ],
        ),
      ),
    );
  }
}

/// Receiving: one screen. The epicbox address as a QR code and in words, with Copy and Share
/// and a line saying the wallet is listening; Ask for an amount (when the wallet handles
/// invoices) and Other ways to receive (a sheet: in person, with a file, Tor address). A
/// payment arriving opens its steps in a sheet over the screen. In epic1 mode the epic1 link
/// takes the place of the address.
class ReceiveView extends ConsumerStatefulWidget {
  const ReceiveView({super.key});

  @override
  ConsumerState<ReceiveView> createState() => _ReceiveViewState();
}

class _ReceiveViewState extends ConsumerState<ReceiveView> {
  /// The payment whose sheet was opened last, so one payment opens one sheet.
  String? _announced;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _announce(arrivingPayment(ref.read(homeProvider).value?.transactions ?? const [])?.key);
    });
  }

  void _announce(String? key) {
    if (key == null || key == _announced) return;
    // Only the Receive in front: a Receive under another page or tab stays quiet.
    if (ModalRoute.of(context)?.isCurrent != true || !TickerMode.valuesOf(context).enabled) return;
    _announced = key;
    showReceiveArrival(context, key);
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(paymentModeProvider) == PaymentMode.epic1) return const Epic1ReceiveView();
    ref.listen(
      homeProvider.select((h) => arrivingPayment(h.value?.transactions ?? const [])?.key),
      (_, key) => _announce(key),
    );
    final l = context.l10n;
    final payments =
        ref.watch(appSettingsProvider.select((s) => s.value?.payments)) ??
        (ref.watch(phonePaymentsProvider) ? PaymentPrefs.phoneDefaults : PaymentPrefs.defaults);
    final torAvailable = ref.watch(phoneTorProvider.select(torShown));
    final offline = watchNetBlock(context, ref).byMode;
    final address = ref.watch(addressProvider);
    // The Epicbox list of the settings file is empty: no server, so no address to hand out
    // (LEPIC's is on a placeholder server, lepic_wallet_service.dart's noEpicboxDomain).
    final noServer = ref.watch(hostSettingsProvider.select((h) => h.epicboxServers.isEmpty));
    // Requests go to paired contacts or into a file, both through pairing (RFC 0002).
    final invoices = ref.watch(invoicesShownProvider) && ref.watch(pairingSupportedProvider);
    final relayMove = ref.watch(relaySwitchResultProvider);
    final ways = OtherWays(
      inPerson: payments.directQr && offersQrPayment(ref),
      file: true,
      tor: torAvailable,
    );
    final value = noServer ? null : address.value;
    final Widget top;
    if (!payments.epicbox) {
      top = const SizedBox.shrink();
    } else if (noServer) {
      top = EmptyState(
        key: const ValueKey('receive-no-epicbox'),
        icon: Icon(MethodIcons.of(MethodKind.epicbox)),
        message: '${l.deskSlNoEpicboxTitle}. ${l.deskSlNoEpicboxText}',
        action: FilledButton.tonal(onPressed: () => showEpicboxPicker(context), child: Text(l.slRelayField)),
      );
    } else if (value != null) {
      top = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (relayMove != null) ...[const NewAddressBadge(), const SizedBox(height: 12)],
          PhoneTourTarget(
            id: 'tour-receive-address',
            child: Column(
              children: [
                ReceiveQr(address: value),
                // Frame: the address 32 under the QR, in 40-wide side padding.
                const SizedBox(height: 18),
                ReceiveAddressBlock(
                  address: value,
                  label: relayMove != null ? l.lvPayNewAddress : l.receiveAddressLabel,
                  cardKey: receiveAddressKey,
                ),
              ],
            ),
          ),
          if (relayMove != null) ...[const SizedBox(height: 8), NewAddressLines(result: relayMove)],
          const SizedBox(height: 16),
          if (offline) _EpicboxOffByMode(mode: ref.watch(networkModeProvider)) else const _EpicboxLine(),
        ],
      );
    } else if (address.hasError) {
      top = ErrorText(describeError(l, address.error!));
    } else {
      top = const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: LinearProgressIndicator());
    }
    final rows = [
      // Without invoices the row still asks for an amount: the address with it, as a code.
      if (invoices || (payments.epicbox && value != null))
        KitRow(
          leading: KitIconWell(KitIcons.invoice, color: context.tokens.accentText),
          title: l.phoneRecvAsk,
          subtitle: l.phoneRecvAskLine,
          chevron: true,
          semanticsId: TrustIds.receiveAsk,
          key: receiveRequestKey,
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const InvoiceRequestScreen())),
        ),
      if (ways.any)
        KitRow(
          leading: KitIconWell.child(KitQrGlyph(color: context.tokens.accentText)),
          title: l.phoneRecvOther,
          subtitle: l.phoneRecvOtherLine,
          chevron: true,
          semanticsId: TrustIds.receiveOther,
          onTap: () => showOtherWays(context, ways: ways),
        ),
    ];
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              // Frame: the QR 34 under the header; its corner marks take the 14 above it.
              padding: const EdgeInsets.fromLTRB(Kit.gutter, 20, Kit.gutter, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  top,
                  if (rows.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    KitGroup(margin: EdgeInsets.zero, children: rows),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The address as a QR code with the mark in its centre, in the brand's corner marks. Always
/// shown, like the desktop Receive: no cover, no tap to hide. [semanticsLabel] is what a screen
/// reader calls it.
class ReceiveQr extends StatelessWidget {
  const ReceiveQr({super.key, required this.address, this.semanticsLabel, this.logo = QrLogo.bt});

  final String address;
  final String? semanticsLabel;
  final QrLogo logo;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    const pad = 12.0;
    return Center(
      heightFactor: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: KitCornerMarks(
          inset: 14,
          arm: 22,
          child: Container(
            width: Kit.qr,
            height: Kit.qr,
            padding: const EdgeInsets.all(pad),
            decoration: BoxDecoration(
              // Dark modules on white scan reliably in either theme.
              color: protocolLight.surface,
              borderRadius: BorderRadius.circular(Kit.rQr),
              boxShadow: [BoxShadow(color: t.accent.withValues(alpha: dark ? 0.13 : 0.12), blurRadius: dark ? 70 : 40)],
            ),
            child: Semantics(
              label: semanticsLabel ?? l.receiveQrLabel,
              image: true,
              child: LogoQr(data: address, size: Kit.qr - 2 * pad, logo: logo),
            ),
          ),
        ),
      ),
    );
  }
}

/// The key of the address, which copies on a tap, for tests.
const Key receiveAddressKey = ValueKey('receive-address');

/// The key of the onion address on the Tor page, for tests.
const Key receiveTorAddressKey = ValueKey('receive-tor-address');

/// The key of the Tor address's QR code (its opacity: dim until reachable), for tests.
const Key receiveTorQrKey = ValueKey('receive-tor-qr');

/// The key of Share under the address, for tests.
const Key receiveShareKey = ValueKey('receive-share');

/// The key of the epicbox line, for tests.
const Key receiveEpicboxKey = ValueKey('receive-epicbox');

/// An address in the middle of the screen, first and last six characters marked (a tap copies,
/// a long press selects), a line asking to check them with the payer, then Copy and, where the
/// device shares, Share. [label] names the kind of address for a screen reader: the same block
/// serves the epicbox and the Tor address.
class ReceiveAddressBlock extends ConsumerStatefulWidget {
  const ReceiveAddressBlock({
    super.key,
    required this.address,
    required this.label,
    required this.cardKey,
    this.copied,
  });

  final String address;
  final String label;

  /// The key of the address's tap target, for tests.
  final Key cardKey;

  /// The notice after a copy; the address-copied line by default.
  final String? copied;

  @override
  ConsumerState<ReceiveAddressBlock> createState() => _ReceiveAddressBlockState();
}

class _ReceiveAddressBlockState extends ConsumerState<ReceiveAddressBlock> {
  bool _sharing = false;

  void _copy() => copyText(context, widget.address, widget.copied ?? context.l10n.receiveAddressCopied);

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await shareAddress(context, ref, address: widget.address, chain: ref.read(walletConfigProvider)?.chain);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final files = ref.watch(slateFilesProvider);
    final canShare = files.canShare || files.canShareText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          // Frame: the address sits in 40-wide side padding; the buttons take the gutter.
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Semantics(
            key: widget.cardKey,
            container: true,
            button: true,
            label: widget.label,
            value: widget.address,
            onTapHint: l.commonCopy,
            onTap: _copy,
            excludeSemantics: true,
            child: InkWell(
              onTap: _copy,
              borderRadius: BorderRadius.circular(Kit.rButtonSmall),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: Kit.hitTarget),
                child: Center(
                  // Selectable for a long press; a tap copies. The server on its own line, shrunk
                  // rather than broken inside its name on a narrow phone at a large text size.
                  child: MarkedAddress(
                    widget.address,
                    center: true,
                    selectable: true,
                    flat: true,
                    // Frame .addr: mono 14 on 1.55; its glyph pitch measures 7.87 px (the line breaks after 39 characters).
                    style: const TextStyle(fontSize: 14, height: 1.55, letterSpacing: -0.55),
                    onTap: _copy,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: KitButton(
                label: l.commonCopy,
                kind: KitButtonKind.quiet,
                icon: KitIcons.copy,
                semanticsId: TrustIds.receiveCopy,
                onPressed: _copy,
              ),
            ),
            if (canShare) ...[
              const SizedBox(width: 10),
              Expanded(
                child: KitButton(
                  key: receiveShareKey,
                  label: l.commonShare,
                  icon: KitIcons.share,
                  semanticsId: TrustIds.receiveShare,
                  onPressed: _sharing ? null : _share,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// The Epicbox line while Node only or Kill switch turns Epicbox off: the status word reads Off
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
              Flexible(child: Text(statusOffByModeWord(l, mode), style: KitType.rowSub.copyWith(color: t.dim))),
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

/// Where the epicbox listener stands, in one quiet line under the address: a green dot and
/// "Listening for payments". Offline or stopped, it says what that means for receiving and offers
/// Retry, which restarts the listener. Blocked by this network, it says so and offers another
/// relay in one tap ([RelayBlockedNote]).
class _EpicboxLine extends ConsumerWidget {
  const _EpicboxLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    // As the header shows it: offline only once it lasts; a stopped listener (null) at once.
    final epicbox = ref.watch(walletStatusProvider.select((s) => s.epicbox));
    final offline = epicbox == null || epicbox == EpicboxState.offline;
    final blocked = epicbox == EpicboxState.blocked;
    final config = ref.watch(walletConfigProvider);
    // The server is named only with Advanced server details on.
    final host = config == null || !AdvancedOptions.has(context, AdvancedFeature.serverDetails) ? null : relayLabel(config);
    final (String word, Color color) = epicbox == EpicboxState.online
        ? (host != null ? l.receiveEpicboxConnected(host) : l.phoneRecvListening, t.ok)
        : blocked
        ? (l.statusEpicboxBlocked, t.risk)
        : offline
        ? (host == null ? l.statusEpicboxOffline : l.receiveEpicboxNotConnected(host), t.risk)
        : (l.statusEpicboxConnecting, t.dim);
    return Column(
      key: receiveEpicboxKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrustId(
          TrustIds.receiveListening,
          child: Semantics(
          liveRegion: true,
          container: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withValues(alpha: .16), spreadRadius: 3)],
                  ),
                ),
              ),
              const SizedBox(width: 9),
              // Frame: the dot carries the state's colour, the words stay dim.
              Flexible(child: Text(word, style: KitType.rowSub.copyWith(color: epicbox == EpicboxState.online ? t.dim : color))),
            ],
          ),
        )),
        if (config != null)
          Advanced(
            feature: AdvancedFeature.serverDetails,
            child: Center(child: Readout(l.statusRelay('${config.epicboxDomain}:${config.epicboxPort}'))),
          ),
        if (offline) ...[
          const SizedBox(height: 4),
          Text(
            l.receiveEpicboxOfflineBody,
            textAlign: TextAlign.center,
            style: KitType.rowSub.copyWith(color: t.dim),
          ),
          const SizedBox(height: 8),
          Center(
            child: KitButton(
              label: l.commonRetry,
              kind: KitButtonKind.quiet,
              expand: false,
              icon: KitIcons.refresh,
              onPressed: () => ref.read(listenerProvider.notifier).restart(),
              semanticsId: TrustIds.receiveRetry,
            ),
          ),
        ],
        if (blocked) ...[const SizedBox(height: 4), const RelayBlockedNote()],
      ],
    );
  }
}

/// The key of the Turn on button of Receive › Tor address while Link · Tor is off, for tests.
const Key receiveTurnOnLinkTorKey = ValueKey('receive-turn-on-link-tor');

/// The key of the Turn on Tor button of Receive › Tor address, for tests.
const Key receiveTurnOnTorKey = ValueKey('receive-turn-on-tor');

/// The key of the Scan payment QR button on In person, for tests.
const Key receiveScanQrKey = ValueKey('receive-scan-qr');
const Key receiveQrRequestKey = ValueKey('receive-qr-request');


/// The key of the Ask for an amount row, for tests.
const Key receiveRequestKey = ValueKey('receive-request');

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
  // A payment read opens over the scanner (InPerson-3); the scanner closes once it is taken.
  final result = await scanQrSlate(context, QrScanKind.payment, first: first, open: openScannedPayment);
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
/// shared, else as the address alone. [logo] is the QR code's: the epic1 mark for an epic1
/// link. Holds auto-lock while the share sheet is open.
Future<void> shareAddress(
  BuildContext context,
  WidgetRef ref, {
  required String address,
  Chain? chain,
  QrLogo logo = QrLogo.bt,
}) async {
  final files = ref.read(slateFilesProvider);
  final hold = ref.read(autoLockHoldProvider.notifier);
  if (!files.canShare) {
    await hold.during(() => files.shareText(address));
    return;
  }
  Uint8List? png;
  try {
    png = await renderShareCard(context, address: address, chain: chain, logo: logo);
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
  QrLogo logo = QrLogo.bt,
}) {
  final l = context.l10n;
  final card = ShareCard(
    address: address,
    logo: logo,
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

/// The picture Share sends: the mark, [headline], the QR code of [address] with [logo] in it,
/// the full [address], and the [network] name off mainnet. Built for [shareCardSize] in the light
/// theme; it reads its colours from the theme's tokens.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.address,
    required this.headline,
    this.network,
    this.logo = QrLogo.bt,
  });

  final String address;
  final String headline;
  final String? network;
  final QrLogo logo;

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
                    child: LogoQr(data: address, size: 232, logo: logo),
                  ),
                ),
                const SizedBox(height: 20),
                // As on the card in the app: the ends marked, the server whole on its own line.
                // An epic1 link is one long run with no key to mark: it wraps, in full.
                if (logo == QrLogo.epic1)
                  Text(
                    address,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35, fontFamily: t.monoFamily, color: t.text),
                  )
                else
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
