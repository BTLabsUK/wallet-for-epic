import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/icons.dart';
import '../theme/tokens.dart';
import 'buttons.dart';
import 'data.dart';
import 'motion.dart';
import 'surfaces.dart';

/// The two forms of [EQrReveal]: [covered] keeps the 184 u box laid out under a blur (the
/// Epicbox hero); [compact] is a QR button in the address box and an expand under it.
enum QrRevealForm { covered, compact }

/// A QR code shown only on demand (spec 4.4): hidden whenever it is built, never remembered,
/// hidden again by the same control. [tag] ("Paused", "Starting", "Not reachable") sits on the
/// shown code, dimmed to 0.35.
class EQrReveal extends StatefulWidget {
  const EQrReveal({
    super.key,
    required this.address,
    required this.form,
    required this.title,
    this.tag,
    this.copyLabel,
    this.addressOpacity = 1,
    this.caption,
    this.method,
    this.initiallyShown = false,
  });

  final String address;
  final QrRevealForm form;

  /// What the code is of, lower case after "the": "Epicbox address", "HTTP address".
  final String title;
  final String? tag;

  /// Compact: the copy icon's label in the address box.
  final String? copyLabel;

  /// Compact: the address box's opacity (0.6 while the method is not on).
  final double addressOpacity;

  /// Compact: the caption under the address box, below the expanded code.
  final Widget? caption;

  /// For test keys: `rx-qr-<method>` on the control, `rx-qr-image-<method>` on the code.
  final String? method;

  /// The tour's revealed state; the app never sets it.
  final bool initiallyShown;

  @override
  State<EQrReveal> createState() => _EQrRevealState();
}

class _EQrRevealState extends State<EQrReveal> with SingleTickerProviderStateMixin {
  late bool _shown = widget.initiallyShown;
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.expand, reverseDuration: Motion.expand, value: _shown ? 1 : 0);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Motion.easeOut, reverseCurve: Motion.easeIn.flipped);
  // The Show QR button fades 40 ms behind the code.
  late final Animation<double> _btn = CurvedAnimation(
    parent: _c,
    curve: Interval(Motion.fadeLag / Motion.expand.inMilliseconds, 1, curve: Motion.easeOut),
    reverseCurve: Interval(Motion.fadeLag / Motion.expand.inMilliseconds, 1, curve: Motion.easeIn.flipped),
  );

  @override
  void didUpdateWidget(EQrReveal old) {
    super.didUpdateWidget(old);
    if (old.address != widget.address && _shown) _set(false, animate: false);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _set(bool shown, {bool animate = true}) {
    setState(() => _shown = shown);
    if (!animate || MediaQuery.disableAnimationsOf(context)) {
      _c.value = shown ? 1 : 0;
    } else if (shown) {
      _c.forward();
    } else {
      _c.reverse();
    }
  }

  Key? _key(String prefix) => widget.method == null ? null : ValueKey('$prefix-${widget.method}');

  String get _imageLabel => 'QR code of the ${widget.title}${widget.tag == null ? '' : ', ${widget.tag!.toLowerCase()}'}';

  Widget _code(double size) {
    final tag = widget.tag;
    return Semantics(
      key: _key('rx-qr-image'),
      image: true,
      label: _imageLabel,
      excludeSemantics: true,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: tag == null ? 1 : 0.35,
            child: EQr(widget.address, size: size),
          ),
          if (tag != null) _Tag(tag),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.form == QrRevealForm.covered ? _covered(context) : _compact(context);

  Widget _covered(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final size = 184.u;
    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (_, e) {
              if (_shown && e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
                _set(false);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: SizedBox(
              width: size,
              height: size,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final t = _t.value;
                  final sigma = 9 * (1 - t);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (t < 1)
                        Container(
                          decoration: BoxDecoration(
                            color: Color.lerp(c.s2, Colors.white, t),
                            borderRadius: BorderRadius.circular(Rad.sm),
                            border: Border.all(color: c.lineStrong),
                          ),
                        ),
                      if (t == 0)
                        // Hidden: a blur of a code, nothing scannable; no image in the tree.
                        ExcludeSemantics(
                          child: Opacity(
                            opacity: 0.16,
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                              child: EQr(widget.address, size: size),
                            ),
                          ),
                        )
                      else
                        Opacity(
                          opacity: 0.16 + 0.84 * t,
                          child: sigma < 0.01
                              ? _code(size)
                              : ImageFiltered(
                                  imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                                  child: _code(size),
                                ),
                        ),
                      IgnorePointer(
                        ignoring: _shown,
                        child: ExcludeSemantics(
                          excluding: _shown,
                          child: Opacity(
                            opacity: 1 - _btn.value,
                            child: Semantics(
                              key: _key('rx-qr'),
                              button: true,
                              toggled: false,
                              label: 'Show QR code of the ${widget.title}',
                              excludeSemantics: true,
                              onTap: () => _set(true),
                              child: ExcludeFocus(
                                excluding: _shown,
                                child: Tooltip(
                                  message: 'Show QR',
                                  child: EButton(label: 'Show QR', icon: EIcons.qr, size: EBtnSize.sm, onPressed: () => _set(true)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SizedBox(height: Sp.x2),
          SizedBox(
            height: 18.u,
            child: Center(
              child: _shown
                  ? Semantics(
                      button: true,
                      toggled: true,
                      label: 'Hide QR code',
                      excludeSemantics: true,
                      onTap: () => _set(false),
                      child: Tooltip(
                        message: 'Hide QR',
                        child: EButton.ghost(label: 'Hide QR', icon: Icons.expand_less, size: EBtnSize.inline, onPressed: () => _set(false)),
                      ),
                    )
                  : Text('QR code of the ${widget.title}', style: ts.caption, maxLines: 1, softWrap: false, overflow: TextOverflow.visible),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compact(BuildContext context) {
    final ts = context.ts;
    final button = _QrToggle(key: _key('rx-qr'), shown: _shown, title: widget.title, onPressed: () => _set(!_shown));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: widget.addressOpacity,
          child: EAddress(widget.address, large: true, copyLabel: widget.copyLabel ?? 'Copy', extra: button),
        ),
        ExpandFade(
          open: _shown,
          child: Padding(
            padding: EdgeInsets.only(top: Sp.x3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _code(184.u),
                SizedBox(height: Sp.x2),
                Text('QR code of the ${widget.title}', style: ts.caption, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        if (widget.caption != null) ...[SizedBox(height: Sp.x2), widget.caption!],
      ],
    );
  }
}

/// The compact QR button: same size and colour as the copy icon, pressed look while shown.
class _QrToggle extends StatefulWidget {
  const _QrToggle({super.key, required this.shown, required this.title, required this.onPressed});

  final bool shown;
  final String title;
  final VoidCallback onPressed;

  @override
  State<_QrToggle> createState() => _QrToggleState();
}

class _QrToggleState extends State<_QrToggle> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final fg = widget.shown ? c.accentText : (_hover ? c.text : c.dim);
    return Tooltip(
      message: widget.shown ? 'Hide QR' : 'Show QR',
      child: Semantics(
        button: true,
        toggled: widget.shown,
        label: widget.shown ? 'Hide QR code' : 'Show QR code of the ${widget.title}',
        excludeSemantics: true,
        onTap: widget.onPressed,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowHoverHighlight: (v) => setState(() => _hover = v),
          shortcuts: const {SingleActivator(LogicalKeyboardKey.escape): DismissIntent()},
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed()),
            DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) => widget.shown ? widget.onPressed() : null),
          },
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: widget.onPressed,
              child: FocusRing(
                focused: Focus.of(context).hasFocus,
                child: AnimatedContainer(
                  duration: Dur.fast,
                  width: Ctl.inline,
                  height: Ctl.inline,
                  decoration: BoxDecoration(
                    color: widget.shown ? c.accentSoft : (_hover ? c.hover : Colors.transparent),
                    borderRadius: BorderRadius.circular(Rad.sm),
                  ),
                  child: Icon(EIcons.qr, size: Ctl.iconSm, color: fg),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x1),
      decoration: BoxDecoration(
        color: c.s1,
        borderRadius: BorderRadius.circular(Rad.sm),
        border: Border.all(color: c.lineStrong),
      ),
      child: Text(
        text,
        style: context.ts.small.copyWith(color: c.text, fontWeight: FontWeight.w600),
      ),
    );
  }
}
