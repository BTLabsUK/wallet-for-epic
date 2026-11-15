// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n.dart';
import '../theme/tokens.dart';
import 'kit_icons.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The names a [KitKeypad] gives its keys for [KitKeypad.idFor]: '0'..'9', and these.
abstract final class KitKey {
  static const point = 'point';
  static const delete = 'delete';
  static const biometrics = 'biometrics';
}

/// A 3 × 4 keypad (HANDOFF 7.8, 7.7): 56 px keys of radius 16, Montserrat 26. The bottom-left
/// key is the decimal point when [decimal] is set, the biometrics key when [onBiometrics] is
/// set, else empty; the bottom-right key deletes. Each key gives a light tap. [idFor] names a
/// key for testers by its [KitKey] name or digit.
class KitKeypad extends StatelessWidget {
  const KitKeypad({super.key, required this.onDigit, required this.onDelete, this.onPoint, this.onBiometrics, this.idFor, this.onDeleteLong, this.inset = 23});

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onDeleteLong;

  /// Shows the "." key and calls this when it is pressed.
  final VoidCallback? onPoint;

  /// Shows the biometrics key (when [onPoint] is null) and calls this.
  final VoidCallback? onBiometrics;
  final String? Function(String key)? idFor;

  /// Space either side of the grid: the keys stand 5 further in, so 23 puts them 28 from the edge.
  final double inset;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    Widget cell(Widget? child) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: SizedBox(height: Kit.key, child: child),
      ),
    );
    Widget key(String id, Widget face, VoidCallback? onTap, String label, {VoidCallback? onLong}) => cell(
      kitId(
        idFor?.call(id),
        Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          onTap: onTap,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(Kit.rButton),
            child: InkWell(
              borderRadius: BorderRadius.circular(Kit.rButton),
              onTap: onTap == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onTap();
                    },
              onLongPress: onLong,
              child: Center(child: face),
            ),
          ),
        ),
      ),
    );
    Widget digit(String d) =>
        key(d, Text(d, style: KitType.keypad.copyWith(color: t.text), textScaler: TextScaler.noScaling), () => onDigit(d), d);
    final bottomLeft = onPoint != null
        ? key(KitKey.point, Text('.', style: KitType.keypad.copyWith(color: t.text), textScaler: TextScaler.noScaling), onPoint, '.')
        : onBiometrics != null
        ? key(KitKey.biometrics, Icon(KitIcons.fingerprint, size: 28, color: t.accentText), onBiometrics, l.pinUseBiometrics)
        : cell(null);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Padding(padding: const EdgeInsets.only(bottom: 2), child: Row(children: [for (final d in row) digit(d)])),
          Row(
            children: [
              bottomLeft,
              digit('0'),
              key(KitKey.delete, Icon(KitIcons.backspace, size: 26, color: t.text), onDelete, l.phoneKitDeleteDigit, onLong: onDeleteLong),
            ],
          ),
        ],
      ),
    );
  }
}

/// The PIN's six dots (HANDOFF 7.8): 14 px, 16 apart, an outline when empty and gold when
/// filled. [filled] counts the digits typed; [error] draws the outline in risk.
class KitPinDots extends StatelessWidget {
  const KitPinDots({super.key, required this.filled, this.total = 6, this.error = false});

  final int filled;
  final int total;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      label: context.l10n.phoneKitPinDigits(filled, total),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 120),
              width: Kit.pinDot,
              height: Kit.pinDot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? (error ? t.risk : t.accent) : Colors.transparent,
                border: Border.all(color: i < filled ? (error ? t.risk : t.accent) : (error ? t.risk : t.faint), width: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
