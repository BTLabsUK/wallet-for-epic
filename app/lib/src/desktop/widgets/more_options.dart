// SPDX-License-Identifier: Apache-2.0
/// The one "more options" control (⇕): a quiet 28 px icon in a 44 px hit area at the end of a
/// heading (a page title, a group's heading, a navigation group's heading). It says how many
/// options the view or an Advanced switch hides there and what shows them ("2 more options ·
/// shown with Deep end view and Advanced › Invoices"); pressed, they show in place, marked, for
/// this session only (nothing is stored). Its reveal state is keyed by [EMoreOptions.revealKey]
/// in [moreOptionsRevealProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../desk_l10n.dart';
import '../screens/settings/search/settings_sections.dart' show setJoinReasons;
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'buttons.dart' show FocusRing;
import 'tip.dart';

/// The keys of the "more options" controls the user opened, for the session.
final moreOptionsRevealProvider = NotifierProvider<MoreOptionsReveal, Set<String>>(MoreOptionsReveal.new);

class MoreOptionsReveal extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  bool isOpen(String key) => state.contains(key);

  void toggle(String key) => state = isOpen(key) ? ({...state}..remove(key)) : {...state, key};

  void open(String key) {
    if (!isOpen(key)) state = {...state, key};
  }

  /// Everything folded again (a new view).
  void clear() => state = const {};
}

/// Whether the hidden options under [key] are shown.
bool moreOptionsOpen(WidgetRef ref, String? key) => key != null && ref.watch(moreOptionsRevealProvider.select((s) => s.contains(key)));

/// The ⇕ control for [count] hidden options; [reasons] names what shows each ("Deep end view",
/// "Advanced › Invoices"), repeats allowed: every distinct one is named.
class EMoreOptions extends ConsumerStatefulWidget {
  const EMoreOptions({super.key, required this.revealKey, required this.count, required this.reasons});

  final String revealKey;
  final int count;
  final List<String> reasons;

  @override
  ConsumerState<EMoreOptions> createState() => _EMoreOptionsState();
}

class _EMoreOptionsState extends ConsumerState<EMoreOptions> {
  bool _hover = false;

  void _toggle() => ref.read(moreOptionsRevealProvider.notifier).toggle(widget.revealKey);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final open = moreOptionsOpen(ref, widget.revealKey);
    final tip = open ? l.deskSetSearchLess(widget.count) : l.deskSetSearchMore(widget.count, setJoinReasons(l, widget.reasons));
    return ETip(
      tip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        expanded: open,
        label: tip,
        excludeSemantics: true,
        onTap: _toggle,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowHoverHighlight: (v) => setState(() => _hover = v),
          actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _toggle())},
          child: Builder(
            builder: (context) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              // 44 px to hit, 28 px to see.
              child: SizedBox.square(
                dimension: Ctl.md,
                child: Center(
                  child: FocusRing(
                    focused: Focus.of(context).hasFocus,
                    child: AnimatedContainer(
                      duration: Dur.fast,
                      width: Ctl.inline,
                      height: Ctl.inline,
                      decoration: BoxDecoration(
                        color: _hover ? c.hover : (open ? c.s3 : Colors.transparent),
                        borderRadius: BorderRadius.circular(Rad.sm),
                      ),
                      child: Icon(open ? EIcons.unfoldLess : EIcons.unfoldMore, size: 18.u, color: _hover || open ? c.text : c.dim),
                    ),
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
