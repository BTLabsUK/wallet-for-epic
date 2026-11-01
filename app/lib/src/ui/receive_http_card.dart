// SPDX-License-Identifier: Apache-2.0
import '../state_language.dart' show ShownState;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo.dart';
import '../l10n.dart';
import '../network_gate.dart';
import '../phone_http.dart';
import '../providers.dart';
import '../slate_files.dart';
import 'address_view.dart';
import 'common.dart';
import 'info_hint.dart' show InfoHint;
import 'net_block.dart';
import 'network_mode_text.dart' show networkModeName;
import 'receive_screen.dart' show shareAddress;
import 'theme/brand.dart';
import 'theme/tokens.dart';

/// The key of the Link · HTTP address card, for tests.
const Key receiveHttpCardKey = ValueKey('receive-http-card');

/// The key of the card's address text, for tests.
const Key receiveHttpAddressKey = ValueKey('receive-http-address');

/// The key of the card's Show QR / Hide QR button, for tests.
const Key receiveHttpQrButtonKey = ValueKey('receive-http-qr-button');

/// The key of the card's QR code once shown, for tests.
const Key receiveHttpQrKey = ValueKey('receive-http-qr');

/// The key of the card's "Trust this network" button, for tests.
const Key receiveHttpTrustKey = ValueKey('receive-http-trust');

/// The key of the info icon beside "Off on this network", for tests.
const Key receiveHttpNotTrustedInfoKey = ValueKey('receive-http-not-trusted-info');

/// The Link · HTTP address card on the phone's Receive › Link tab: the address wallets on
/// this Wi-Fi network can pay (`phone_http.dart` runs the listener), its state (starting,
/// listening, port in use, off while Tor is on, no network) and Retry. Shown only while
/// Link · HTTP is on (Settings › Transactions). The QR code stays hidden until asked for.
class ReceiveHttpCard extends ConsumerWidget {
  const ReceiveHttpCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final http = ref.watch(phoneHttpProvider);
    final phase = http.phase;
    if (phase == PhoneHttpPhase.off) return const SizedBox.shrink();
    final dim = theme.textTheme.bodySmall?.copyWith(color: t.dim);
    final retry = TextButton.icon(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      icon: const Icon(Icons.refresh),
      label: Text(l.commonRetry),
      onPressed: () => ref.read(phoneHttpProvider.notifier).retry(),
    );
    Widget line(String text, {Color? color}) => Semantics(
      liveRegion: true,
      container: true,
      child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: color ?? t.dim)),
    );
    final body = switch (phase) {
      PhoneHttpPhase.listening when http.address != null => _Address(address: http.address!),
      PhoneHttpPhase.starting => Semantics(
        liveRegion: true,
        container: true,
        child: Row(
          children: [
            const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
            Flexible(child: Text(ShownState.starting.word(l), style: theme.textTheme.bodyMedium?.copyWith(color: t.dim))),
          ],
        ),
      ),
      PhoneHttpPhase.portInUse => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [line(l.receiveHttpPortInUse('${http.port}'), color: t.risk), retry],
      ),
      PhoneHttpPhase.failed => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [line(l.receiveHttpFailed, color: t.risk), retry],
      ),
      PhoneHttpPhase.offWhileTor => line(l.receiveHttpOffWhileTor),
      // Paused, not broken: the state in one line, why behind the info icon, and the one
      // action as a tonal button so it reads as the way on, not as a warning to dismiss.
      PhoneHttpPhase.notTrusted => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: Icon(Icons.pause_circle_outline, size: 18, color: t.dim)),
              const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  container: true,
                  child: Text(l.receiveHttpNotTrustedTitle, style: theme.textTheme.bodyMedium),
                ),
              ),
              InfoHint(l.receiveHttpNotTrusted, key: receiveHttpNotTrustedInfoKey, title: l.receiveHttpNotTrustedTitle, icon: Icons.pause_circle_outline),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              key: receiveHttpTrustKey,
              style: FilledButton.styleFrom(minimumSize: const Size(48, 44)),
              icon: const Icon(Icons.home_outlined, size: 18),
              onPressed: () => ref.read(phoneHttpProvider.notifier).trust(),
              label: Text(l.receiveHttpTrust),
            ),
          ),
        ],
      ),
      PhoneHttpPhase.offline => NetBlockNote(
        NetGate.killSwitch ? NetBlock.killSwitch : NetBlock.nodeOnly,
        line: l.receiveLinkOffMode(networkModeName(l, NetGate.mode)),
      ),
      _ => line(l.receiveHttpNoNetwork),
    };
    return Card(
      key: receiveHttpCardKey,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(MethodIcons.of(MethodKind.linkHttp), size: 18, color: t.accentText),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.receiveHttpTitle,
                      style: theme.textTheme.labelMedium?.copyWith(color: t.dim),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            body,
            if (phase == PhoneHttpPhase.listening || phase == PhoneHttpPhase.noNetwork) ...[
              const SizedBox(height: 4),
              Text(l.receiveHttpLanLine, style: dim),
            ],
          ],
        ),
      ),
    );
  }
}

/// The address in full, selectable, with Copy, Share where the device shares, and Show QR.
class _Address extends ConsumerStatefulWidget {
  const _Address({required this.address});

  final String address;

  @override
  ConsumerState<_Address> createState() => _AddressState();
}

class _AddressState extends ConsumerState<_Address> {
  bool _qr = false;
  bool _sharing = false;

  void _copy() => copyText(context, widget.address, context.l10n.receiveAddressCopied);

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
    final files = ref.watch(slateFilesProvider);
    final canShare = !ref.watch(demoModeProvider) && (files.canShare || files.canShareText);
    final reduce = MediaQuery.of(context).disableAnimations;
    const button = Size(48, 48);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selectable for a long press; a tap copies.
        MarkedAddress(widget.address, key: receiveHttpAddressKey, selectable: true, onTap: _copy),
        Wrap(
          spacing: 4,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(minimumSize: button),
              icon: const Icon(Icons.copy, size: 18),
              label: Text(l.commonCopy),
              onPressed: _copy,
            ),
            if (canShare)
              TextButton.icon(
                style: TextButton.styleFrom(minimumSize: button),
                icon: const Icon(Icons.share, size: 18),
                label: Text(l.commonShare),
                onPressed: _sharing ? null : _share,
              ),
            TextButton.icon(
              key: receiveHttpQrButtonKey,
              style: TextButton.styleFrom(minimumSize: button),
              icon: Icon(_qr ? Icons.visibility_off_outlined : Icons.qr_code_2, size: 18),
              label: Text(_qr ? l.receiveHttpHideQr : l.receiveHttpShowQr),
              onPressed: () => setState(() => _qr = !_qr),
            ),
          ],
        ),
        // Expands and collapses alike: size and fade, instant with reduced motion.
        AnimatedSize(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
          curve: _qr ? Curves.easeOut : Curves.easeIn,
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            opacity: _qr ? 1 : 0,
            duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
            child: !_qr
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: LayoutBuilder(
                      builder: (context, room) => Center(
                        child: Container(
                          key: receiveHttpQrKey,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // Dark modules on white scan reliably in either theme.
                            color: protocolLight.surface,
                            borderRadius: BorderRadius.circular(t.radiusSmall),
                          ),
                          // Its own node: merged into the card, the label read as part of
                          // the card's whole text.
                          child: Semantics(
                            container: true,
                            label: l.receiveHttpQrLabel,
                            image: true,
                            child: MarkedQr(
                              data: widget.address,
                              size: (room.maxWidth - 24).clamp(120.0, 200.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
