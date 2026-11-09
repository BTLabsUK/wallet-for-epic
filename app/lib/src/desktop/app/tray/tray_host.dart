// SPDX-License-Identifier: Apache-2.0
/// The system tray, behind one interface: Linux's StatusNotifierItem (tray_linux.dart), the
/// Windows runner's notification icon (tray_windows.dart), and none elsewhere. desk_tray.dart
/// decides what it shows; a host only draws it and passes the clicks back.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tray_menu.dart';

/// A picture for the tray: straight (not premultiplied) RGBA, top row first, and the same as a
/// PNG (Linux menus take PNG).
@immutable
class TrayImage {
  const TrayImage({required this.width, required this.height, required this.rgba, required this.png});

  final int width;
  final int height;
  final Uint8List rgba;
  final Uint8List png;
}

/// What the tray shows: [icons] in the sizes the host asked for, the hover text, the menu with a
/// picture per mark, and [attention] when the icon carries the problem mark.
@immutable
class TrayView {
  const TrayView({required this.icons, required this.title, required this.tooltip, required this.attention, required this.items, required this.marks});

  final List<TrayImage> icons;
  final String title;
  final String tooltip;
  final bool attention;
  final List<TrayItem> items;
  final Map<TrayMark, TrayImage> marks;
}

/// The tray of this desktop.
abstract class TrayHost {
  /// Whether a tray is there to come back by, as last known; Settings › Node reads it.
  ValueListenable<bool> get available;

  /// Asks again now: the panel may have gone or come since.
  Future<bool> check();

  /// The icon sizes to draw, in physical pixels, and the menu pictures' size.
  Future<({List<int> icons, int menu})> sizes();

  /// Puts the icon in the tray, or updates it.
  Future<void> show(TrayView view);

  /// Takes the icon out of the tray; nothing when it is not there.
  Future<void> remove();

  /// The icon was clicked.
  void Function()? onClick;

  /// A menu item with an id was chosen.
  void Function(String id)? onActivate;
}

/// No tray: macOS for now, the web build, the tests and the tour.
class NoTray extends TrayHost {
  static final _no = ValueNotifier(false);

  @override
  ValueListenable<bool> get available => _no;

  @override
  Future<bool> check() async => false;

  @override
  Future<({List<int> icons, int menu})> sizes() async => (icons: const <int>[], menu: 0);

  @override
  Future<void> show(TrayView view) async {}

  @override
  Future<void> remove() async {}
}

/// The tray main_desktop.dart found for this desktop.
final deskTrayHostProvider = Provider<TrayHost>((ref) => NoTray());
