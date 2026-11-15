// SPDX-License-Identifier: Apache-2.0
/// One motion system for the phone: how screens, tabs and sheets move.
///
/// Each platform keeps its own grammar. Android: Material 3 (a forward push fades and slides in
/// from the right by a quarter of the width, the screen below shifts left; the system back
/// gesture previews the screen underneath). iOS: Cupertino (a push slides in from the right
/// with the screen below in parallax, and the edge swipe pulls it back under the finger). Both
/// are the platform's own transitions, only shortened to [PhoneMotion.push] so none is slow.
///
/// Peers (the four bottom tabs) slide sideways with the finger, as a swipe moves them. Send and
/// Receive, which have a close button and no back, rise from the bottom as a modal does. Sheets
/// share one entry and exit. With the system's reduce-motion setting (`disableAnimations`) every
/// duration here is zero: a screen is there at once. Nothing blocks input while it moves.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Durations and curves of the phone's motion.
abstract final class PhoneMotion {
  /// A screen pushed over another, and a modal rising.
  static const Duration push = Duration(milliseconds: 300);

  /// A screen leaving. Leaving is quicker than arriving.
  static const Duration pop = Duration(milliseconds: 250);

  /// A tab, after a tap on the bar.
  static const Duration tab = Duration(milliseconds: 280);

  /// A sheet rising, and leaving.
  static const Duration sheetIn = Duration(milliseconds: 300);
  static const Duration sheetOut = Duration(milliseconds: 220);

  /// Material 3's emphasized decelerate: a fast start that settles softly.
  static const Curve enter = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Material 3's emphasized accelerate: a leaving element speeds up.
  static const Curve exit = Cubic(0.3, 0.0, 0.8, 0.15);

  /// The system's reduce-motion setting, read where no widget context is at hand: a route's
  /// duration is read when it is pushed. Widgets use `MediaQuery.disableAnimationsOf`.
  static bool get reduced => WidgetsBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .disableAnimations;

  /// [d], or zero with reduced motion.
  static Duration of(Duration d) => reduced ? Duration.zero : d;
}

/// A platform's page transition, at the phone's durations and none with reduced motion. The
/// drawing and the back gesture are [inner]'s: Material 3 with the Android predictive back, or
/// Cupertino with the edge swipe.
class PhoneTransitionsBuilder extends PageTransitionsBuilder {
  const PhoneTransitionsBuilder(this.inner);

  final PageTransitionsBuilder inner;

  @override
  Duration get transitionDuration => PhoneMotion.of(PhoneMotion.push);

  @override
  Duration get reverseTransitionDuration => PhoneMotion.of(PhoneMotion.pop);

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      inner.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => inner.buildTransitions<T>(
    route,
    context,
    animation,
    secondaryAnimation,
    child,
  );
}

/// The transitions of [ThemeData.pageTransitionsTheme] for the phone: Android and iOS only; the
/// other platforms (a desktop build, the dev host) keep Flutter's own.
const PageTransitionsTheme phonePageTransitions = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: PhoneTransitionsBuilder(
      PredictiveBackPageTransitionsBuilder(),
    ),
    TargetPlatform.iOS: PhoneTransitionsBuilder(
      CupertinoPageTransitionsBuilder(),
    ),
  },
);

/// A full-screen modal: Send and Receive rise from the bottom over the shell and sink back
/// down. The screen below stays where it is. Back (the system's, or the close button) pops it.
class PhoneModalRoute<T> extends PageRoute<T> {
  PhoneModalRoute({super.settings, required this.builder})
    : super(fullscreenDialog: true);

  final WidgetBuilder builder;

  @override
  Duration get transitionDuration => PhoneMotion.of(PhoneMotion.push);

  @override
  Duration get reverseTransitionDuration => PhoneMotion.of(PhoneMotion.pop);

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: builder(context),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slide = CurvedAnimation(
      parent: animation,
      curve: PhoneMotion.enter,
      reverseCurve: PhoneMotion.exit,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(slide),
      child: child,
    );
  }
}

/// The sheet animation of every phone sheet: [PhoneMotion.sheetIn] and [PhoneMotion.sheetOut],
/// none with reduced motion.
AnimationStyle phoneSheetAnimation() => AnimationStyle(
  curve: PhoneMotion.enter,
  reverseCurve: PhoneMotion.exit,
  duration: PhoneMotion.of(PhoneMotion.sheetIn),
  reverseDuration: PhoneMotion.of(PhoneMotion.sheetOut),
);
