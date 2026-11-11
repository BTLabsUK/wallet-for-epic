// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_icons.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// A boxed row with a tick box and a [label] (HANDOFF 7.8, Forgot PIN): a tap anywhere on it
/// flips [value]. Read by a screen reader as a check box.
class KitCheckRow extends StatelessWidget {
  const KitCheckRow({super.key, required this.label, required this.value, required this.onChanged, this.semanticsId});

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticsId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final row = Semantics(
      checked: value,
      label: label,
      excludeSemantics: true,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: KitPress(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        radius: Kit.rGroup,
        button: false,
        child: Container(
          constraints: const BoxConstraints(minHeight: Kit.rowSheet + 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: t.fill,
            border: Border.all(color: t.hair),
            borderRadius: BorderRadius.circular(Kit.rGroup),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value ? t.text : Colors.transparent,
                  border: Border.all(color: value ? t.text : t.faint, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: value ? Icon(KitIcons.check, size: 18, color: t.bg) : null,
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: KitType.rowTitle.copyWith(color: t.text, fontSize: 16))),
            ],
          ),
        ),
      ),
    );
    return kitId(semanticsId, row);
  }
}
