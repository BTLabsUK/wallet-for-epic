import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../wallet_service.dart';
import 'centered_body.dart';
import 'common.dart';
import 'file_exchange_help.dart';
import 'help_screen.dart';
import 'slate_file_screen.dart';
import 'theme/advanced.dart';
import 'theme/brand.dart';
import 'theme/protocol.dart';
import 'theme/tokens.dart';

/// Receiving: epicbox payments arrive by themselves while connected; a payment file or its
/// text can still be accepted by hand. There is no HTTP receive, because a phone cannot
/// accept connections.
///
/// The Receive tab's content, top to bottom: the address (tap to copy, Share inside), the
/// epicbox line, the QR code, receiving by file, and help.
class ReceiveView extends ConsumerWidget {
  const ReceiveView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final address = ref.watch(addressProvider);
    return CenteredScroll(
      child: CenteredBody(
        children: [
          ...switch (address) {
            AsyncData(:final value) => [
              _AddressRow(address: value),
              const SizedBox(height: 8),
              const _EpicboxLine(),
              const SizedBox(height: 16),
              _AddressQr(address: value),
            ],
            AsyncError(:final error) => [ErrorText(describeError(l, error))],
            _ => [const LinearProgressIndicator()],
          },
          const SizedBox(height: 24),
          const _FileCard(),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.help_outline),
              label: Text(l.receiveHelpButton),
              onPressed: () => openHelp(context, HelpTopic.receiving),
            ),
          ),
        ],
      ),
    );
  }
}

/// The key of the address card, which copies on a tap, for tests.
const Key receiveAddressKey = ValueKey('receive-address');

/// The key of Share inside the address card, for tests.
const Key receiveShareKey = ValueKey('receive-share');

/// The key of the epicbox line, for tests.
const Key receiveEpicboxKey = ValueKey('receive-epicbox');

/// The full address in a full-width card that copies on a tap anywhere on it, with the copy
/// icon and, where the device shares, Share stacked on its right.
class _AddressRow extends ConsumerStatefulWidget {
  const _AddressRow({required this.address});

  final String address;

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
    final canShare = files.canShare || files.canShareText;
    // A 48 dp box for each icon, stacked on the card's right: copy above share.
    const icon = 48.0;
    const inset = 4.0;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Semantics(
            key: receiveAddressKey,
            container: true,
            button: true,
            label: l.receiveAddressLabel,
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
                                l.receiveAddressLabel,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: t.dim,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Selectable for a long press; a tap copies, like the card.
                              SelectableText(
                                address,
                                onTap: _copy,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontFamily: t.monoFamily,
                                ),
                              ),
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

/// Where the epicbox listener stands, in one quiet line. Offline or stopped, it says what that
/// means for receiving and offers Retry, which restarts the listener.
class _EpicboxLine extends ConsumerWidget {
  const _EpicboxLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final listener = ref.watch(listenerProvider);
    final offline = !listener.connected && (listener.lost || listener.stopped);
    final (IconData icon, String word, Color color) = listener.connected
        ? (Icons.mark_email_read_outlined, l.statusEpicboxOnline, t.ok)
        : offline
        ? (Icons.unsubscribe_outlined, l.statusEpicboxOffline, t.risk)
        : (Icons.mail_outline, l.statusEpicboxConnecting, t.dim);
    final config = ref.watch(walletConfigProvider);
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
      ],
    );
  }
}

/// The address as a QR code with the mark, framed like Home's balance.
class _AddressQr extends StatelessWidget {
  const _AddressQr({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      // The corner ticks frame the code as the screen's one object, like Home's balance.
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
            child: Semantics(
              label: context.l10n.receiveQrLabel,
              image: true,
              child: MarkedQr(data: address, size: 240),
            ),
          ),
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
          ],
        ),
      ),
    );
  }
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
    network: chain == null || chain == Chain.mainnet
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
                Text(
                  address,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: t.monoFamily,
                    color: t.text,
                    height: 1.35,
                  ),
                ),
                if (network != null) ...[
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: t.accentSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        network,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: t.accentText,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
