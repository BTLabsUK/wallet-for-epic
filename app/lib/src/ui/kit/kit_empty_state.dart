// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_button.dart';
import 'kit_tokens.dart';

/// An empty list or an unavailable thing (HANDOFF 7.11): a 72 px icon well, a [title], one dim
/// line and one button. Centred in the room it is given, scrolls when the room is small.
class KitEmptyState extends StatelessWidget {
  const KitEmptyState({super.key, required this.icon, required this.title, this.message, this.actionLabel, this.onAction, this.actionId, this.actionKind = KitButtonKind.quiet});

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? actionId;
  final KitButtonKind actionKind;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.hasBoundedHeight ? box.maxHeight : 0),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: Kit.emptyWell,
                    height: Kit.emptyWell,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: t.fill, borderRadius: BorderRadius.circular(Kit.rGroup)),
                    child: ExcludeSemantics(child: Icon(icon, size: 32, color: t.dim)),
                  ),
                  const SizedBox(height: 18),
                  Semantics(
                    header: true,
                    child: Text(title, style: KitType.sheetTitle.copyWith(color: t.text), textAlign: TextAlign.center),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 8),
                    Text(message!, style: KitType.body.copyWith(color: t.dim), textAlign: TextAlign.center),
                  ],
                  if (actionLabel != null) ...[
                    const SizedBox(height: 22),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: KitButton(label: actionLabel!, onPressed: onAction, kind: actionKind, semanticsId: actionId),
                    ),
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
