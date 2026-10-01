import 'package:flutter/material.dart';

import 'tokens.dart';

/// Whether Advanced options is on. One sits above the navigator (`MaterialApp.builder`), fed
/// from `AppSettings.advancedOptions`.
class AdvancedOptions extends InheritedWidget {
  const AdvancedOptions({
    super.key,
    required this.enabled,
    required super.child,
  });

  final bool enabled;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdvancedOptions>()?.enabled ??
      false;

  @override
  bool updateShouldNotify(AdvancedOptions oldWidget) =>
      oldWidget.enabled != enabled;
}

/// Shows [child] only with Advanced options on. Block heights, node and relay names, transport
/// choices, atomic units, transaction files and logs go in one, so the simple path never has to
/// know they exist.
class Advanced extends StatelessWidget {
  const Advanced({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      AdvancedOptions.of(context) ? child : const SizedBox.shrink();
}

/// A technical line in the mono face, for Advanced readouts. Never prose.
class Readout extends StatelessWidget {
  const Readout(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(
      text,
      style: TextStyle(
        fontFamily: t.monoFamily,
        fontSize: 12,
        height: 1.6,
        color: t.dim,
      ),
    );
  }
}
