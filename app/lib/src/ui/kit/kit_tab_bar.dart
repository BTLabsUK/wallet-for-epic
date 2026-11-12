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

  static const double _inset = 34;

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
        child: Align(
          alignment: Alignment.topCenter,
          key: kitScanButtonKey,
          child: KitPress(
            onTap: onScan,
            radius: Kit.rButton,
            button: false,
            child: Container(
              margin: const EdgeInsets.only(top: 7),
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
    // `.tabs`: 86 tall with the home-indicator zone, 9 above the tabs, the bar a hair darker than the ground.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bg.withValues(alpha: 0.84),
        border: Border(top: BorderSide(color: t.hair)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom > _inset ? bottom : _inset, left: 6, right: 6),
        // At a large text size the labels grow the bar, they are not cut.
        child: SizedBox(
          height: Kit.tabBar - _inset - 1 + (MediaQuery.textScalerOf(context).scale(13) - 13).clamp(0, 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tab(0),
              tab(1),
              // `.tabs .scan`: 50 x 50 with a 10 px margin each side, 2 up from the tabs' line.
              SizedBox(width: Kit.scanButton + 20, child: scan),
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
    final color = selected ? t.accent : t.faint;
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
          child: Stack(
            clipBehavior: Clip.none,
            // `.tab` centres its content in the cell (the stack would pin it to the start).
            alignment: Alignment.topCenter,
            children: [
              // `.tab`: gap 4, the 9 px of the bar's padding above.
              Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    glyph,
                    const SizedBox(height: 4),
                    Text(item.label, style: KitType.tabLabel.copyWith(color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // `.tab .bdg`: 17 tall, left edge 6 right of the tab's centre, top -3 of the tab (which starts 9 down).
              if (item.badge > 0)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Transform.translate(
                      offset: const Offset(6, 6),
                      child: FractionalTranslation(
                        translation: const Offset(0.5, 0),
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 17),
                          height: 17,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(9)),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              '${item.badge}',
                              style: KitType.tabLabel.copyWith(fontWeight: FontWeight.w600, color: t.accentInk, height: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
