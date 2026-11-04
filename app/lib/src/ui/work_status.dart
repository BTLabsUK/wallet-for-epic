// SPDX-License-Identifier: Apache-2.0
/// A quiet line under a long wait that says which step runs ([WorkStatus]), and the frames
/// that keep a wait moving on screen while Flutter believes the app is away ([FrameKeeper]).
library;

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'theme/tokens.dart';

/// Keeps the screen drawing while a wait is on it, even when Flutter believes the app is away.
/// Android can leave the app on screen with its lifecycle paused: on 2026-11-04 the phone
/// counted as locked (the Keystore refused the PIN key) while the app stayed in view. Flutter
/// draws no frames then, only on a size or inset change (the keyboard), so a finished delete
/// stayed on its spinner and the next screen came only once the app was opened again. While
/// held, for [linger] after, and for [afterTouch] after a touch, a frame is forced whenever
/// frames are off. With frames on nothing is done.
abstract final class FrameKeeper {
  /// Frames go on this long after the last hold ends: the next screen slides in.
  static const Duration linger = Duration(seconds: 1);

  /// A touch while frames are off shows the app is in front: its answer is drawn.
  static const Duration afterTouch = Duration(seconds: 3);

  static const Duration _every = Duration(milliseconds: 50);

  static int _holds = 0;
  static Timer? _after;
  static Duration _afterLength = Duration.zero;
  static final Stopwatch _afterRun = Stopwatch();
  static Timer? _ticker;
  static bool _installed = false;

  static void hold() {
    _holds++;
    _start();
  }

  static void release() {
    if (_holds > 0) _holds--;
    _extend(linger);
  }

  /// Touches and lifecycle changes; once, at start.
  static void install() {
    if (_installed) return;
    _installed = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute((event) {
      if (event is PointerDownEvent || event is PointerUpEvent) _extend(afterTouch);
    });
    WidgetsBinding.instance.addObserver(_Lifecycle());
  }

  static bool get _wanted => _holds > 0 || _after != null;

  /// Frames for at least [by] from now, when frames are off (with them on, nothing to keep).
  static void _extend(Duration by) {
    if (SchedulerBinding.instance.framesEnabled) return;
    if (_after == null || by > _afterLength - _afterRun.elapsed) {
      _after?.cancel();
      _afterLength = by;
      _afterRun
        ..reset()
        ..start();
      _after = Timer(by, () => _after = null);
    }
    _start();
  }

  static void _start() {
    if (_ticker != null || !_wanted || SchedulerBinding.instance.framesEnabled) return;
    _ticker = Timer.periodic(_every, (_) => _tick());
    _tick();
  }

  static void _tick() {
    final binding = SchedulerBinding.instance;
    if (!_wanted || binding.framesEnabled) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    binding.scheduleForcedFrame();
  }
}

class _Lifecycle with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => FrameKeeper._start();
}

/// The line under a long wait (a delete, an unlock, a restore): [text], the step that runs
/// now, or else [lines] one after another every [every], staying on the last. Each change
/// fades in. Shown after [showAfter], so a quick wait shows nothing. While on screen it keeps
/// the screen drawing ([FrameKeeper]).
class WorkStatus extends StatefulWidget {
  const WorkStatus({
    super.key,
    this.text,
    this.lines = const [],
    this.every = const Duration(seconds: 2),
    this.showAfter = Duration.zero,
    this.style,
  });

  final String? text;
  final List<String> lines;
  final Duration every;
  final Duration showAfter;

  /// The desktop's own; the phone's small dim text when null.
  final TextStyle? style;

  @override
  State<WorkStatus> createState() => _WorkStatusState();
}

class _WorkStatusState extends State<WorkStatus> {
  bool _shown = false;
  int _index = 0;
  Timer? _show;
  Timer? _next;

  @override
  void initState() {
    super.initState();
    FrameKeeper.hold();
    if (widget.showAfter == Duration.zero) {
      _shown = true;
    } else {
      _show = Timer(widget.showAfter, () {
        if (mounted) setState(() => _shown = true);
      });
    }
    if (widget.lines.length > 1) {
      _next = Timer.periodic(widget.every, (timer) {
        if (!mounted) return;
        setState(() => _index++);
        if (_index >= widget.lines.length - 1) timer.cancel();
      });
    }
  }

  @override
  void dispose() {
    _show?.cancel();
    _next?.cancel();
    FrameKeeper.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.lines;
    final text = widget.text ?? (lines.isEmpty ? null : lines[_index.clamp(0, lines.length - 1)]);
    final line = _shown && text != null ? text : '';
    final style =
        widget.style ?? Theme.of(context).textTheme.bodySmall?.copyWith(color: context.tokens.dim);
    return Semantics(
      liveRegion: true,
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        child: Text(line, key: ValueKey(line), style: style, textAlign: TextAlign.center),
      ),
    );
  }
}
