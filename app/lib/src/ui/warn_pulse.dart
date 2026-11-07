/// A status dot that has been amber for a while starts to breathe, so a node that is behind
/// is not mistaken for a stuck payment. Shared by the phone's [StatusGlyph] and the desktop's
/// [EStatusGlyph].
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

/// How long a dot is continuously amber before it starts to pulse.
const Duration warnPulseDelay = Duration(seconds: 15);

/// The lowest opacity of the pulse: slight, the dot never disappears.
const double warnPulseLow = 0.55;

/// One slow breath, down or up.
const Duration warnPulseHalf = Duration(milliseconds: 1800);

/// How often the pulse moves. Ten steps a second look smooth on a dot this small, and each
/// one redraws the window: a running animation would redraw it on every frame for as long as
/// the dot is amber, and on the desktop drawing is what costs CPU.
const Duration warnPulseStep = Duration(milliseconds: 100);

/// [child] pulses gently once [active] (amber) has held for [warnPulseDelay], until [active]
/// ends; a fresh [active] stretch waits the delay again. Never pulses with reduced motion.
/// Unlike a busy dot's few breaths, it goes on while the state lasts: it is one dot, and the
/// state is one the user should notice.
class WarnPulse extends StatefulWidget {
  const WarnPulse({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<WarnPulse> createState() => _WarnPulseState();
}

class _WarnPulseState extends State<WarnPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, value: 1);
  Timer? _timer;
  Timer? _steps;
  bool _reduced = false;

  /// The pulse is running; until then the child is drawn bare, with no layer around it.
  bool _pulsing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    _sync(restart: false);
  }

  @override
  void didUpdateWidget(WarnPulse old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync(restart: true);
  }

  void _sync({required bool restart}) {
    if (!widget.active || _reduced) {
      _timer?.cancel();
      _timer = null;
      _steps?.cancel();
      _steps = null;
      _c.value = 1;
      _pulsing = false;
    } else if (restart || (_timer == null && _steps == null)) {
      _timer?.cancel();
      _timer = Timer(warnPulseDelay, () {
        _timer = null;
        if (!mounted) return;
        setState(() => _pulsing = true);
        _steps = Timer.periodic(warnPulseStep, _step);
      });
    }
  }

  void _step(Timer timer) {
    final phase = (timer.tick * warnPulseStep.inMicroseconds / warnPulseHalf.inMicroseconds) % 2;
    final down = Curves.easeInOut.transform(phase <= 1 ? phase : 2 - phase);
    _c.value = warnPulseLow + (1 - warnPulseLow) * (1 - down);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _steps?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _pulsing ? FadeTransition(opacity: _c, child: widget.child) : widget.child;
}
