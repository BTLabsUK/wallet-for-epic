import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../password_estimate.dart';
import '../../password_lists.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'buttons.dart' show FocusRing;

/// The estimator while a screen with a [PasswordHint] is open; released after it closes.
/// Loading until the lists are ranked (a fraction of a second, in the background).
final passwordEstimatorProvider = FutureProvider.autoDispose<PasswordEstimator>((ref) => loadPasswordEstimator());

/// How the time is estimated: the tooltip behind the info icon.
const passwordHintNote =
    'Estimated on this device from the length and from common words, names and patterns, for an '
    'attacker with fast hardware trying 100,000 guesses a second against this wallet\'s file. '
    'A guide, not a guarantee.';

/// The small print under a new password: "14 characters · about 300 years to crack".
///
/// The count follows every keystroke; the time comes [estimateDelay] after typing stops.
/// It only informs: nothing here blocks the form. Screen readers hear the time in a live
/// region, [announceDelay] after typing stops and only when it changed. The password and the
/// estimate never leave this widget.
class PasswordHint extends ConsumerStatefulWidget {
  const PasswordHint({super.key, required this.controller});

  final TextEditingController controller;

  static const estimateDelay = Duration(milliseconds: 150);
  static const announceDelay = Duration(seconds: 1);

  @override
  ConsumerState<PasswordHint> createState() => _PasswordHintState();
}

class _PasswordHintState extends ConsumerState<PasswordHint> {
  Timer? _estimateTimer;
  Timer? _announceTimer;
  int _count = 0;
  String? _time;
  String _announced = '';

  @override
  void initState() {
    super.initState();
    _count = widget.controller.text.characters.length;
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(PasswordHint old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
      _changed();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _estimateTimer?.cancel();
    _announceTimer?.cancel();
    super.dispose();
  }

  void _changed() {
    final count = widget.controller.text.characters.length;
    _estimateTimer?.cancel();
    _announceTimer?.cancel();
    if (count == 0) {
      setState(() {
        _count = 0;
        _time = null;
        _announced = '';
      });
      return;
    }
    if (count != _count) setState(() => _count = count);
    _estimateTimer = Timer(PasswordHint.estimateDelay, _estimate);
  }

  void _estimate() {
    final estimator = ref.read(passwordEstimatorProvider).value;
    final text = widget.controller.text;
    if (!mounted || estimator == null || text.isEmpty) return;
    setState(() => _time = estimator.crackTime(text));
    _announceTimer = Timer(PasswordHint.announceDelay - PasswordHint.estimateDelay, () {
      if (mounted && _time != null && _time != _announced) setState(() => _announced = _time!);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Estimate as soon as the lists are ready, if typing came first.
    ref.listen(passwordEstimatorProvider, (_, next) {
      if (next.hasValue && widget.controller.text.isNotEmpty && _estimateTimer?.isActive != true) _estimate();
    });
    final c = context.dc;
    final line = _count == 0 ? '' : [characterCount(_count), ?_time].join(' · ');
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: Ctl.inline),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Semantics(
              liveRegion: true,
              label: _announced,
              child: ExcludeSemantics(
                child: Text(line, key: const ValueKey('password-hint'), style: context.ts.caption.copyWith(color: c.dim)),
              ),
            ),
          ),
          if (_count > 0) ...[SizedBox(width: Sp.x1), const _EstimateInfo()],
        ],
      ),
    );
  }
}

/// The info icon whose tooltip says how the time is estimated. Focusable; the tooltip also
/// opens on focus and on Enter or Space, and screen readers read it with the label.
class _EstimateInfo extends StatefulWidget {
  const _EstimateInfo();

  @override
  State<_EstimateInfo> createState() => _EstimateInfoState();
}

class _EstimateInfoState extends State<_EstimateInfo> {
  final _tip = GlobalKey<TooltipState>();
  bool _focused = false;

  void _show() => _tip.currentState?.ensureTooltipVisible();

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Tooltip(
      key: _tip,
      message: passwordHintNote,
      excludeFromSemantics: true,
      triggerMode: TooltipTriggerMode.tap,
      constraints: BoxConstraints(maxWidth: 320.u),
      child: Semantics(
        button: true,
        label: 'How the time is estimated',
        tooltip: passwordHintNote,
        excludeSemantics: true,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.help,
          onFocusChange: (v) {
            setState(() => _focused = v);
            if (v) {
              _show();
            } else {
              Tooltip.dismissAllToolTips();
            }
          },
          actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _show())},
          child: FocusRing(
            focused: _focused,
            child: SizedBox.square(
              dimension: Ctl.inline,
              child: Icon(EIcons.info, size: Ctl.iconSm, color: c.dim),
            ),
          ),
        ),
      ),
    );
  }
}
