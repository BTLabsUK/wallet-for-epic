// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import 'motion_switches.dart';
import 'phone_motion.dart';

/// The shell's four tab screens as peers: a swipe moves them with the finger, a tap on the bar
/// slides to the tab (a tab two or three over passes no screen in between). [selected] is the
/// tab the bar shows; [onSelect] is told when a swipe has passed the middle, so the bar follows
/// the finger. Only the screens on view are built, as before, so a tab's state and its loads
/// start when it comes on screen.
///
/// With reduced motion (and in widget tests) there is no pager: the selected screen is the
/// child at once, and a quick sideways flick still moves to the next tab, with no motion.
class PhoneTabPager extends StatefulWidget {
  const PhoneTabPager({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.children,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final List<Widget> children;

  @override
  State<PhoneTabPager> createState() => _PhoneTabPagerState();
}

class _PhoneTabPagerState extends State<PhoneTabPager>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: widget.children.length,
    initialIndex: widget.selected,
    vsync: this,
    animationDuration: PhoneMotion.tab,
  );

  /// Set when a swipe made [onSelect] ask for a tab: the controller is already on its way there.
  int? _fromSwipe;

  @override
  void initState() {
    super.initState();
    _controller.animation!.addListener(_follow);
  }

  void _follow() {
    // A slide to a tab the bar asked for is not the finger's.
    if (_controller.indexIsChanging) return;
    final near = _controller.animation!.value.round();
    if (near == widget.selected) return;
    _fromSwipe = near;
    widget.onSelect(near);
  }

  @override
  void didUpdateWidget(PhoneTabPager old) {
    super.didUpdateWidget(old);
    final target = widget.selected;
    if (target == _fromSwipe) {
      _fromSwipe = null;
      return;
    }
    if (target == _controller.index && !_controller.indexIsChanging) return;
    _controller.animateTo(target, duration: PhoneMotion.of(PhoneMotion.tab));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TabBarView(
    controller: _controller,
    // Tabs are peers: no overscroll glow or bounce past the first and the last.
    physics: const ClampingScrollPhysics(),
    children: widget.children,
  );
}

/// The shell's tabs: [PhoneTabPager], or [flat] where motion is off.
class PhoneTabs extends StatelessWidget {
  const PhoneTabs({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.children,
    required this.flat,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final List<Widget> children;

  /// Wraps the selected screen when there is no pager: the shell's flick between tabs.
  final Widget Function(Widget screen) flat;

  @override
  Widget build(BuildContext context) {
    if (!phoneTabsSlide || MediaQuery.disableAnimationsOf(context)) {
      return flat(children[selected]);
    }
    return PhoneTabPager(
      selected: selected,
      onSelect: onSelect,
      children: children,
    );
  }
}
