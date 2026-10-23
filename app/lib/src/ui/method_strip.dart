import 'package:flutter/material.dart';

import '../l10n.dart';
import 'method_art.dart';
import 'theme/tokens.dart';

export 'method_art.dart' show TransferMethod;

/// The key of the strip, for tests.
const Key methodStripKey = ValueKey('method-strip');

/// What a method means, under Send's selector and at the top of each Receive tab: its picture
/// on the left, a short title and one plain line on the right. [receiving] picks Receive's
/// words. A new method fades in over 160 ms; with reduced motion it swaps at once.
class MethodStrip extends StatelessWidget {
  const MethodStrip({super.key, required this.method, this.receiving = false});

  final TransferMethod method;
  final bool receiving;

  /// The title and the line for [method], on Send or on Receive.
  static (String title, String line) words(
    AppLocalizations l,
    TransferMethod method, {
    bool receiving = false,
  }) => receiving
      ? switch (method) {
          TransferMethod.epicbox => (
            l.methodReceiveEpicboxTitle,
            l.methodReceiveEpicboxLine,
          ),
          TransferMethod.tor => (
            l.methodReceiveTorTitle,
            l.methodReceiveTorLine,
          ),
          TransferMethod.file => (
            l.methodReceiveFileTitle,
            l.methodReceiveFileLine,
          ),
          // No HTTP receiving on the phone; the sender's words are the closest.
          TransferMethod.http => (l.methodSendHttpTitle, l.methodSendHttpLine),
        }
      : switch (method) {
          TransferMethod.epicbox => (
            l.methodSendEpicboxTitle,
            l.methodSendEpicboxLine,
          ),
          TransferMethod.http => (l.methodSendHttpTitle, l.methodSendHttpLine),
          TransferMethod.tor => (l.methodSendTorTitle, l.methodSendTorLine),
          TransferMethod.file => (l.methodSendFileTitle, l.methodSendFileLine),
        };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final (title, line) = words(context.l10n, method, receiving: receiving);
    final still = MediaQuery.disableAnimationsOf(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: t.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(line, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
      ],
    );
    return Container(
      key: methodStripKey,
      padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 12, 8),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(t.radiusSmall),
      ),
      child: AnimatedSwitcher(
        duration: still ? Duration.zero : const Duration(milliseconds: 160),
        // Large text gets the strip's whole width: the picture goes above the words.
        child: MediaQuery.textScalerOf(context).scale(1) > 1.3
            ? Column(
                key: ValueKey(method),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [MethodArt(method), const SizedBox(height: 4), text],
              )
            : Row(
                key: ValueKey(method),
                children: [
                  MethodArt(method),
                  const SizedBox(width: 12),
                  Expanded(child: text),
                ],
              ),
      ),
    );
  }
}
