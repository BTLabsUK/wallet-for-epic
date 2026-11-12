// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_avatar.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// A payment in a list (HANDOFF 7.3, "Home lists"): a [KitAvatar] with the direction badge, a
/// [title] (a name, or a short address in the mono face), one state line under it, and the
/// amount at the end with its fiat value under it. The row is [Kit.rowList] tall at least and
/// grows when the text size does. A tap opens the payment; a long press labels it.
///
/// The row holds no data of its own: the caller says what the words are, so the same part serves
/// Home, the contact page and the Activity list.
class KitPaymentRow extends StatelessWidget {
  const KitPaymentRow({
    super.key,
    required this.avatar,
    required this.title,
    required this.state,
    required this.amount,
    this.fiat,
    this.amountColor,
    this.struck = false,
    this.onTap,
    this.onLongPress,
    this.longPressHint,
    this.semanticsLabel,
    this.semanticsId,
  });

  /// The [KitAvatar], with its direction.
  final Widget avatar;

  /// A name or an address; the caller styles an address in the mono face.
  final Widget title;

  /// The state line: date, step word, sealed mark. Built by the caller so it can colour a step.
  final Widget state;

  /// The signed amount, already shaped for the display settings (it may be hidden).
  final String amount;
  final String? fiat;
  final Color? amountColor;

  /// A cancelled payment's amount is struck through.
  final bool struck;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? longPressHint;

  /// One spoken sentence for the whole row; the pieces are hidden from a screen reader.
  final String? semanticsLabel;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Kit.rowList),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            ExcludeSemantics(child: avatar),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(child: title),
                  const SizedBox(height: 3),
                  ExcludeSemantics(child: state),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ExcludeSemantics(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: KitType.rowAmount.copyWith(
                        color: amountColor ?? t.text,
                        decoration: struck ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (fiat != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          fiat!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: KitType.rowSub.copyWith(color: t.dim),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return kitId(
      semanticsId,
      Semantics(
        button: onTap != null,
        label: semanticsLabel,
        onTap: onTap,
        onLongPress: onLongPress,
        onLongPressHint: longPressHint,
        excludeSemantics: semanticsLabel != null,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(onTap: onTap, onLongPress: onLongPress, child: body),
        ),
      ),
    );
  }
}
