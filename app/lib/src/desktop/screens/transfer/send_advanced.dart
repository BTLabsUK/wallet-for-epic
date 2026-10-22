/// Send › Advanced (F11, F12, D-5; design spec §4.4): the strategy and Split change for this
/// send only. The defaults live on the Outputs page; nothing here is stored.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/kit.dart';

/// The disclosure's subtitle: "· Smallest outputs", with ", change not split" when off.
String advancedSubtitle(SelectionStrategy strategy, {required bool split}) =>
    '· ${strategy == SelectionStrategy.all ? 'All' : 'Smallest'} outputs${split ? '' : ', change not split'}';

class SendAdvanced extends StatelessWidget {
  const SendAdvanced({
    super.key,
    required this.strategy,
    required this.defaultStrategy,
    required this.split,
    required this.onStrategy,
    required this.onSplit,
    required this.onOutputs,
    this.sendAll = false,
    this.initiallyOpen = false,
  });

  /// What this send uses (the override, else the default).
  final SelectionStrategy strategy;
  final SelectionStrategy defaultStrategy;
  final bool split;
  final ValueChanged<SelectionStrategy> onStrategy;
  final ValueChanged<bool> onSplit;

  /// Opens the Outputs page (the defaults).
  final VoidCallback onOutputs;

  /// Sending everything spends every output: the strategy rows are off.
  final bool sendAll;
  final bool initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    Widget radio(SelectionStrategy s, String title, String text) => ERadioRow(
      selected: (sendAll ? SelectionStrategy.all : strategy) == s,
      title: title,
      tag: s == defaultStrategy ? 'default' : null,
      text: text,
      onSelected: sendAll ? null : () => onStrategy(s),
    );
    return EDetails(
      title: 'Advanced',
      subtitle: advancedSubtitle(sendAll ? SelectionStrategy.all : strategy, split: split),
      initiallyOpen: initiallyOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: 'Strategy for this send',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                radio(SelectionStrategy.smallest, 'Smallest', 'Spends the fewest small outputs; the rest of the balance stays spendable while the change confirms.'),
                radio(SelectionStrategy.all, 'All', 'Spends every spendable output and returns one change output. Everything is locked until it confirms; fewer, larger outputs afterwards.'),
              ],
            ),
          ),
          if (sendAll) Padding(padding: EdgeInsets.only(left: 30.u, bottom: Sp.x2), child: Text('Sending everything spends every output.', style: ts.caption)),
          ESetRow(
            title: 'Split change',
            text: 'Returns the change as several outputs when few would be left, so the next send does not wait.',
            control: ESwitch(value: split, semanticLabel: 'Split change', onChanged: onSplit),
          ),
          SizedBox(height: Sp.x2),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('For this send only. Defaults: ', style: ts.caption.copyWith(color: c.dim)),
              ELink(label: 'Outputs', onPressed: onOutputs),
            ],
          ),
        ],
      ),
    );
  }
}

/// A radio choice as a row: an 18 u circle, a title (with an optional tag) and one line of
/// text; the whole row selects it. Arrow keys move between rows as Tab does.
class ERadioRow extends StatefulWidget {
  const ERadioRow({super.key, required this.selected, required this.title, required this.text, this.tag, this.onSelected});

  final bool selected;
  final String title;
  final String text;
  final String? tag;

  /// Null: disabled.
  final VoidCallback? onSelected;

  @override
  State<ERadioRow> createState() => _ERadioRowState();
}

class _ERadioRowState extends State<ERadioRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final on = widget.onSelected != null;
    final ring = widget.selected ? c.accent : (on ? c.lineStrong : c.line);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: widget.selected,
      enabled: on,
      label: '${widget.title}${widget.tag == null ? '' : ', ${widget.tag}'}. ${widget.text}',
      excludeSemantics: true,
      onTap: widget.onSelected,
      child: FocusableActionDetector(
        enabled: on,
        mouseCursor: on ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (v) => setState(() => _hover = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
        },
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onSelected?.call())},
        child: Builder(
          builder: (context) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onSelected,
            child: FocusRing(
              focused: Focus.of(context).hasFocus,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: Sp.x2, horizontal: Sp.x1),
                decoration: BoxDecoration(color: _hover && on ? c.hover : Colors.transparent, borderRadius: BorderRadius.circular(Rad.sm)),
                child: Opacity(
                  opacity: on ? 1 : 0.5,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18.u,
                        height: 18.u,
                        margin: EdgeInsets.only(top: 2.u),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring, width: 1.5)),
                        alignment: Alignment.center,
                        child: widget.selected
                            ? Container(width: 8.u, height: 8.u, decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent))
                            : null,
                      ),
                      SizedBox(width: Sp.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(child: Text(widget.title, style: ts.strong)),
                                if (widget.tag != null) ...[SizedBox(width: Sp.x2), ETag(widget.tag!)],
                              ],
                            ),
                            Text(widget.text, style: ts.small),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
