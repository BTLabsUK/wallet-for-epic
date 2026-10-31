import 'package:flutter/material.dart';

/// `showModalBottomSheet` for the phone screens: the sheet's content stays clear of the bottom
/// system inset (the navigation bar on an edge-to-edge Android), so its last button is never
/// half under it. `useSafeArea` only keeps the top inset. With the keyboard open the inset is
/// already zero, and a sheet that pads for the keyboard itself keeps doing so.
Future<T?> showPhoneSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool showDragHandle = false,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  BoxConstraints? constraints,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  useSafeArea: useSafeArea,
  showDragHandle: showDragHandle,
  isDismissible: isDismissible,
  enableDrag: enableDrag,
  backgroundColor: backgroundColor,
  shape: shape,
  constraints: constraints,
  builder: (context) => SafeArea(top: false, child: builder(context)),
);
