// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

import 'kit/kit_sheet.dart' show KitGrabber;
import 'kit/kit_tokens.dart' show Kit;

/// `showModalBottomSheet` for the phone screens: the sheet's content stays clear of the bottom
/// system inset (the navigation bar on an edge-to-edge Android), so its last button is never
/// half under it. `useSafeArea` only keeps the top inset. With the keyboard open the inset is
/// already zero, and a sheet that pads for the keyboard itself keeps doing so. [showDragHandle]
/// draws the redesign's [KitGrabber] (`.sheet` 10 + `.grab` 5 + 16) instead of Material's 48 band.
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
  showDragHandle: false,
  isDismissible: isDismissible,
  enableDrag: enableDrag,
  backgroundColor: backgroundColor,
  shape: shape,
  constraints: constraints,
  builder: (context) => SafeArea(
    top: false,
    // The sheet's own bottom padding is the inset alone (34 on the frames); without an inset,
    // the last button keeps [Kit.groupGap] from the screen's edge.
    minimum: const EdgeInsets.only(bottom: Kit.groupGap),
    child: showDragHandle
      ? Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [const KitGrabber(), Flexible(child: builder(context))],
        )
      : builder(context),
  ),
);
