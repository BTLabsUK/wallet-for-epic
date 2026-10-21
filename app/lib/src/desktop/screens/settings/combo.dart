import 'package:flutter/material.dart';

import '../../widgets/kit.dart';
import 'settings_frame.dart';

/// One option of [ServiceCombo].
class ComboOption {
  const ComboOption({required this.value, required this.title, required this.host, required this.health, this.latencyMs, this.group});

  final String value;
  final String title;

  /// Shown in mono under the title.
  final String host;
  final ServiceHealth health;
  final int? latencyMs;
  final String? group;
}

/// The combobox of Settings › Node and Receiving: label, host in mono, health dot and word,
/// latency; groups; footer actions. [openInitially] opens the list after the first frame.
class ServiceCombo extends StatefulWidget {
  const ServiceCombo({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.label,
    this.footerActions = const [],
    this.openInitially = false,
  });

  final List<ComboOption> options;
  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  /// (label, icon, action) shown under a divider.
  final List<(String, IconData, VoidCallback)> footerActions;
  final bool openInitially;

  @override
  State<ServiceCombo> createState() => _ServiceComboState();
}

class _ServiceComboState extends State<ServiceCombo> {
  final _menu = MenuController();

  @override
  void initState() {
    super.initState();
    if (widget.openInitially) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _menu.open();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final current = widget.options.where((o) => o.value == widget.value).firstOrNull;
    return LayoutBuilder(
      builder: (context, box) {
        String? lastGroup;
        final children = <Widget>[];
        final w = box.maxWidth;
        for (final o in widget.options) {
          if (o.group != null && o.group != lastGroup) {
            children.add(Padding(
              padding: const EdgeInsets.fromLTRB(Sp.x3, Sp.x2, Sp.x3, Sp.x1),
              child: Text(o.group!.toUpperCase(), style: ts.caption.copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w600)),
            ));
          }
          lastGroup = o.group;
          final selected = o.value == widget.value;
          children.add(MenuItemButton(
            onPressed: () => widget.onChanged(o.value),
            style: ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size(w - Sp.x4, 52)),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: Sp.x3)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
              backgroundColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused) || selected ? c.s3 : null,
              ),
            ),
            child: SizedBox(
              width: w - Sp.x4 - Sp.x6,
              child: Row(
                children: [
                  SizedBox(
                    width: Ctl.iconSm,
                    child: selected ? Icon(EIcons.check, size: Ctl.iconSm, color: c.accentText) : null,
                  ),
                  const SizedBox(width: Sp.x2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(o.title, style: ts.body, overflow: TextOverflow.ellipsis),
                        Text(o.host, style: ts.mono(size: Fs.xs, color: c.faint), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: Sp.x2),
                  HealthLine(o.health, latencyMs: o.latencyMs),
                ],
              ),
            ),
          ));
        }
        for (var i = 0; i < widget.footerActions.length; i++) {
          final (label, icon, run) = widget.footerActions[i];
          if (i == 0) children.add(Divider(height: Sp.x3, color: c.line));
          children.add(MenuItemButton(
            onPressed: run,
            leadingIcon: Icon(icon, size: Ctl.iconSm, color: c.accentText),
            style: ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size(w - Sp.x4, 40)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            ),
            child: Text(label, style: ts.body.copyWith(color: c.accentText)),
          ));
        }
        return MenuAnchor(
          controller: _menu,
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(c.s4),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            padding: const WidgetStatePropertyAll(EdgeInsets.all(Sp.x2)),
            minimumSize: WidgetStatePropertyAll(Size(w, 0)),
            maximumSize: WidgetStatePropertyAll(Size(w, 460)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rad.sm), side: BorderSide(color: c.lineStrong)),
            ),
          ),
          menuChildren: children,
          builder: (context, controller, _) => Semantics(
            button: true,
            label: widget.label,
            value: current?.title,
            child: InkWell(
              onTap: () => controller.isOpen ? controller.close() : controller.open(),
              borderRadius: BorderRadius.circular(Rad.sm),
              child: Container(
                height: Ctl.md,
                padding: const EdgeInsets.only(left: Sp.x3, right: Sp.x2),
                decoration: BoxDecoration(
                  color: c.s2,
                  borderRadius: BorderRadius.circular(Rad.sm),
                  border: Border.all(color: controller.isOpen ? c.accent : c.lineField),
                ),
                child: Row(
                  children: [
                    if (current != null) ...[EStatusDot(healthTone(current.health)), const SizedBox(width: Sp.x3)],
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: current?.title ?? '', style: ts.body),
                          if (current != null) TextSpan(text: '   ${current.host}', style: ts.mono(size: Fs.sm, color: c.faint)),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(EIcons.chevronDown, size: Ctl.icon, color: c.dim),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
