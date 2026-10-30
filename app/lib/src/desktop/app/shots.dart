// SPDX-License-Identifier: Apache-2.0
/// The screenshot tour's catalogue (`tool/desktop_tour_test.dart`): every screen, state and
/// dialog of the desktop UI with the id of its Electron reference shot.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes.dart';

class DeskShot {
  const DeskShot({
    required this.id,
    required this.title,
    required this.route,
    this.arg,
    this.dialog,
    this.prepare,
    this.before,
    this.width = 1280,
    this.height = 800,
  });

  /// File name without extension, e.g. `13-send`. Matches the Electron shot's id.
  final String id;
  final String title;

  /// Where to go first.
  final DeskRoute route;
  final Object? arg;

  /// When set, the tour opens this over the route (showEDialog / showEDrawer inside).
  final Future<void> Function(BuildContext context)? dialog;

  /// Runs after the route is shown and before the shot: tap, type, open a menu.
  /// Gets the tour's [WidgetRef]-like container and the root context.
  final Future<void> Function(ProviderContainer container, BuildContext context)? prepare;

  /// Runs on the fresh container before the route opens, for state the screen reads as it
  /// builds (a method switched on, a contact's address), unlike [prepare], which runs after.
  final Future<void> Function(ProviderContainer container)? before;

  final double width;
  final double height;
}
