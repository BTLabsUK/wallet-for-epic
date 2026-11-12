// SPDX-License-Identifier: Apache-2.0
library;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kit_icons.dart';
import 'kit_support.dart';
import 'kit_tokens.dart';

/// The Scan button of the [KitTabBar], for tests.
const Key kitScanButtonKey = ValueKey('kit-tab-scan');

/// One tab of the [KitTabBar]: its two glyphs (the filled one when selected), its word, an
/// optional count badge, and the id the test drivers know it by.
class KitTabItem {
  const KitTabItem({
    required this.icon,
    required this.iconOn,
    required this.label,
    this.badge = 0,
    this.semanticsId,
  });

  final IconData icon;
  final IconData iconOn;
  final String label;

  /// A gold count over the glyph; nothing at 0.
  final int badge;
  final String? semanticsId;
}

/// The bottom bar of the phone shell (HANDOFF 9, "Shell and tabs"): two tabs, the raised Scan
/// button, two tabs. [items] holds the four tabs left to right; [selected] indexes them. The
/// selected tab is gold, the others dim. Scan opens a flow, so it is a button with no selected
/// state. The bar is [Kit.tabBar] tall on a phone with no gesture inset and grows when the inset is over 24.
class KitTabBar extends StatelessWidget {
  const KitTabBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.onScan,
    required this.scanLabel,
    this.scanId,
  }) : assert(items.length == 4);

  final List<KitTabItem> items;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;
  final String scanLabel;
  final String? scanId;

  static const double _inset = 24;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final scan = kitId(
      scanId,
      Semantics(
        button: true,
        label: scanLabel,
        excludeSemantics: true,
        onTap: onScan,
        child: Center(
          key: kitScanButtonKey,
          child: KitPress(
            onTap: onScan,
            radius: Kit.rButton,
            button: false,
            child: Container(
              width: Kit.scanButton,
              height: Kit.scanButton,
              decoration: BoxDecoration(color: t.raised, borderRadius: BorderRadius.circular(Kit.rButton)),
              child: Icon(KitIcons.scan, size: 26, color: t.accent),
            ),
          ),
        ),
      ),
    );
    Widget tab(int i) => Expanded(
      child: _Tab(item: items[i], selected: i == selected, onTap: () => onSelect(i)),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(top: BorderSide(color: t.hair)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom > _inset ? bottom : _inset),
        child: SizedBox(
          height: Kit.tabBar - _inset,
          child: Row(
            children: [
              tab(0),
              tab(1),
              Expanded(child: scan),
              tab(2),
              tab(3),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.selected, required this.onTap});

  final KitTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = selected ? t.accent : t.dim;
    final glyph = Icon(selected ? item.iconOn : item.icon, size: 24, color: color);
    final label = item.badge > 0 ? '${item.label}, ${item.badge}' : item.label;
    return kitId(
      item.semanticsId,
      Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: InkResponse(
          onTap: onTap,
          radius: 36,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  glyph,
                  if (item.badge > 0)
                    PositionedDirectional(
                      top: -4,
                      end: -9,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(Kit.rPill)),
                        child: Text(
                          '${item.badge}',
                          style: KitType.tag.copyWith(fontSize: 10.5, color: t.accentInk, height: 1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: KitType.tag.copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
