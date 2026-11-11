// SPDX-License-Identifier: Apache-2.0
/// The visible message of the announcements feature (announcements spec §5, Layout): one row,
/// the same height with or without an image, plain text of at most two lines, one link as
/// `label · host`, and a × to dismiss. The card places nothing: a screen puts it where it
/// belongs (notice dock or Activity list) and decides what `onShown` and `onDismiss` do.
library;

import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, MissingPluginException;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../btlabs_public.dart' show Announcement, AnnouncementLink;
import '../desktop/data/files.dart' show openInBrowser;
import '../l10n.dart';
import '../network_gate.dart' show NetDial, NetGate;
import '../scan/incoming_link.dart' show incomingLinkProvider;
import '../ui/theme/tokens.dart';

/// Side of the image box, in logical pixels (the spec's 64×64 box).
const double announcementImageSize = 64;

/// What the link row calls the target of an `epic:` link: the app, not a host.
const String announcementEpicHost = 'Epic Cash';

/// Opens the https address of a card's link. The default is [openAnnouncementUrl]; tests
/// record the address instead.
final announcementOpenUrlProvider = Provider<Future<bool> Function(String url)>(
  (ref) => openAnnouncementUrl,
);

const MethodChannel _browserChannel = MethodChannel('epic_wallet/browser');

/// Opens the https address [url] in the system browser. Desktop: [openInBrowser]. Phone: the
/// `epic_wallet/browser` channel (method `open`, one string), which the native side answers
/// with a plain ACTION_VIEW / openURL; without that handler it returns false and nothing
/// opens. Both refuse what the network mode refuses (Node only, Kill switch: [NetGate]).
Future<bool> openAnnouncementUrl(String url) async {
  final u = Uri.tryParse(url);
  if (u == null || u.scheme != 'https' || u.host.isEmpty) return false;
  if (kIsWeb) return false;
  if (Platform.isAndroid || Platform.isIOS) {
    if (!NetGate.allows(NetDial.browser, u.host)) return false;
    try {
      return await _browserChannel.invokeMethod<bool>('open', url) ?? false;
    } on MissingPluginException {
      return false;
    }
  }
  return openInBrowser(url);
}

/// The host shown after the link label: the host of an https URL, [announcementEpicHost] for
/// an `epic:` URI. Empty when the URL has neither.
String announcementLinkHost(AnnouncementLink link) {
  final u = Uri.tryParse(link.url);
  if (u == null) return '';
  if (u.scheme == 'https') return u.host;
  if (u.scheme == 'epic') return announcementEpicHost;
  return '';
}

/// One announcement as a row. [onDismiss] runs when the × is pressed (or the card is swiped
/// away, with [swipeToDismiss]); [onShown] runs once after the first frame the card is on
/// screen (again if the card is given another message). [dense] is the desktop side panel:
/// a smaller type size and tighter padding, at the same 64 px image box.
class AnnouncementCard extends ConsumerStatefulWidget {
  /// Creates the card for [announcement].
  const AnnouncementCard(
    this.announcement, {
    super.key,
    this.onDismiss,
    this.onShown,
    this.dense = false,
    this.swipeToDismiss = false,
  });

  /// The message to show.
  final Announcement announcement;

  /// The × (and the swipe) was used. Null: no × is drawn.
  final VoidCallback? onDismiss;

  /// The card has been on screen: the caller marks the message seen.
  final VoidCallback? onShown;

  /// Smaller type and padding, for the desktop.
  final bool dense;

  /// Phone: a horizontal swipe dismisses, as the ×. Needs [onDismiss]; the caller must take
  /// the card out of the tree when it runs.
  final bool swipeToDismiss;

  @override
  ConsumerState<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends ConsumerState<AnnouncementCard> {
  @override
  void initState() {
    super.initState();
    _announceShown();
  }

  @override
  void didUpdateWidget(AnnouncementCard old) {
    super.didUpdateWidget(old);
    if (old.announcement.id != widget.announcement.id) _announceShown();
  }

  void _announceShown() {
    final id = widget.announcement.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.announcement.id != id) return;
      widget.onShown?.call();
    });
  }

  Future<void> _open(AnnouncementLink link) async {
    final url = link.url;
    if (url.startsWith('https://')) {
      await ref.read(announcementOpenUrlProvider)(url);
    } else if (url.startsWith('epic:')) {
      ref.read(incomingLinkProvider.notifier).deliver(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dense = widget.dense;
    final a = widget.announcement;
    final t = context.tokens;
    final l = context.l10n;
    final scaler = MediaQuery.textScalerOf(context);
    final fontSize = dense ? 13.0 : 14.0;
    final lineHeight = dense ? 18.0 : 20.0;
    const metaHeight = 24.0;
    // The body is the image's height; a larger system text size grows it, with or without an
    // image alike.
    final scaledLine = scaler.scale(lineHeight);
    final bodyHeight = _max(
      announcementImageSize,
      2 * scaledLine + _max(metaHeight, scaler.scale(lineHeight)),
    );
    final textStyle = TextStyle(
      color: t.text,
      fontSize: fontSize,
      height: lineHeight / fontSize,
    );
    final link = a.link;
    final hasImage = a.imagePng != null;
    final dismiss = widget.onDismiss;
    final closeSize = dense ? 32.0 : 44.0;

    Widget card = Padding(
      padding: EdgeInsets.fromLTRB(12, 12, dense ? 4 : 2, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage) ...[
            _ImageBox(bytes: a.imagePng!),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: bodyHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    a.text,
                    key: const ValueKey('announcement-text'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                  if (link != null)
                    _LinkRow(
                      link: link,
                      fontSize: fontSize,
                      height: metaHeight,
                      opensInBrowser: l.announcementOpensInBrowser,
                      onTap: () => _open(link),
                    )
                  else
                    const SizedBox(height: metaHeight),
                ],
              ),
            ),
          ),
          if (dismiss != null)
            SizedBox(
              width: closeSize,
              height: closeSize,
              child: IconButton(
                key: const ValueKey('announcement-dismiss'),
                tooltip: l.announcementDismiss,
                onPressed: dismiss,
                padding: EdgeInsets.zero,
                icon: Icon(Icons.close, size: 20, color: t.dim),
              ),
            ),
        ],
      ),
    );

    if (widget.swipeToDismiss && dismiss != null) {
      card = Dismissible(
        key: ValueKey('announcement-swipe-${a.id}'),
        onDismissed: (_) => dismiss(),
        child: card,
      );
    }
    return card;
  }
}

double _max(double a, double b) => a > b ? a : b;

/// The 64×64 box. A PNG that does not decode leaves the same empty box in the surface colour,
/// so the height and the text position do not move.
class _ImageBox extends StatelessWidget {
  const _ImageBox({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final empty = SizedBox.square(dimension: announcementImageSize, child: ColoredBox(color: t.surfaceHi));
    return Container(
      key: const ValueKey('announcement-image'),
      width: announcementImageSize,
      height: announcementImageSize,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.surfaceHi,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: t.line),
      ),
      child: ExcludeSemantics(
        child: Image.memory(
          bytes,
          width: announcementImageSize,
          height: announcementImageSize,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => empty,
        ),
      ),
    );
  }
}

/// `label · host` and, for https, the small external-link glyph. A text link, not a button.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.link,
    required this.fontSize,
    required this.height,
    required this.opensInBrowser,
    required this.onTap,
  });

  final AnnouncementLink link;
  final double fontSize;
  final double height;
  final String opensInBrowser;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final host = announcementLinkHost(link);
    final https = link.url.startsWith('https://');
    final spoken = [link.label, if (host.isNotEmpty) host, if (https) opensInBrowser].join(', ');
    return Semantics(
      link: true,
      label: spoken,
      excludeSemantics: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          key: const ValueKey('announcement-link'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: link.label,
                          style: TextStyle(color: t.accentText, fontWeight: FontWeight.w600),
                        ),
                        if (host.isNotEmpty) TextSpan(text: ' · $host', style: TextStyle(color: t.dim)),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
                if (https) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.open_in_new, size: 14, color: t.dim),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
