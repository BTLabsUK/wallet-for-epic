// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../desk_l10n.dart';
import '../../password_estimate.dart';
import '../../password_lists.dart';
import '../theme/icons.dart';
import '../theme/tokens.dart';

/// The estimator while a screen with a [PasswordHint] is open; released after it closes.
/// Loading until the lists are ranked (a fraction of a second, in the background).
final passwordEstimatorProvider = FutureProvider.autoDispose<PasswordEstimator>((ref) => loadPasswordEstimator());


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

/// The info icon whose note says how the time is estimated. A click opens the note and a
/// second click, Esc, an outside click or leaving the field closes it; hovering 400 ms opens it
/// too, until the pointer leaves. Not a Tab stop (a screen reader reads the note from the
/// icon's tooltip); a click on it never takes focus from the password field.
class _EstimateInfo extends StatefulWidget {
  const _EstimateInfo();

  @override
  State<_EstimateInfo> createState() => _EstimateInfoState();
}

class _EstimateInfoState extends State<_EstimateInfo> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  Timer? _hoverTimer;

  /// Opened by a click: stays until a click, Esc or an outside click.
  bool _pinned = false;

  bool get _open => _portal.isShowing;

  void _show({required bool pin}) {
    _hoverTimer?.cancel();
    if (pin) _pinned = true;
    if (!_portal.isShowing) {
      _portal.show();
      HardwareKeyboard.instance.addHandler(_onKey);
    }
    if (mounted) setState(() {});
  }

  void _hide() {
    _hoverTimer?.cancel();
    _pinned = false;
    if (_portal.isShowing) {
      _portal.hide();
      HardwareKeyboard.instance.removeHandler(_onKey);
    }
    if (mounted) setState(() {});
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      _hide();
      return true;
    }
    return false;
  }

  void _toggle() => _open && _pinned ? _hide() : _show(pin: true);

  @override
  void dispose() {
    _hoverTimer?.cancel();
    if (_portal.isShowing) HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  Widget _note(BuildContext context) {
    final tip = TooltipTheme.of(context);
    return CompositedTransformFollower(
      link: _link,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: Offset(0, Sp.x1),
      showWhenUnlinked: false,
      child: Align(
        alignment: Alignment.topLeft,
        child: TapRegion(
          groupId: _EstimateInfo,
          child: TextFieldTapRegion(
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                key: const ValueKey('password-hint-note'),
                constraints: BoxConstraints(maxWidth: 320.u),
                padding: tip.padding ?? EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
                decoration: tip.decoration,
                child: Text(context.l10n.deskKitPasswordNote, style: tip.textStyle),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return TextFieldTapRegion(
      child: TapRegion(
        groupId: _EstimateInfo,
        onTapOutside: (_) {
          if (_open) _hide();
        },
        child: CompositedTransformTarget(
          link: _link,
          child: OverlayPortal(
            controller: _portal,
            overlayChildBuilder: _note,
            child: MouseRegion(
              cursor: SystemMouseCursors.help,
              onEnter: (_) {
                _hoverTimer?.cancel();
                _hoverTimer = Timer(TooltipTheme.of(context).waitDuration ?? const Duration(milliseconds: 400), () {
                  if (mounted) _show(pin: false);
                });
              },
              onExit: (_) {
                _hoverTimer?.cancel();
                if (!_pinned) _hide();
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggle,
                child: Semantics(
                  button: true,
                  label: context.l10n.deskKitPasswordNoteLabel,
                  tooltip: context.l10n.deskKitPasswordNote,
                  excludeSemantics: true,
                  onTap: _toggle,
                  child: SizedBox.square(
                    dimension: Ctl.inline,
                    child: Icon(EIcons.info, size: Ctl.iconSm, color: _open ? c.text : c.dim),
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
