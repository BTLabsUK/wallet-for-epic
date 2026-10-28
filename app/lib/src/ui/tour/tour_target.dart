// SPDX-License-Identifier: Apache-2.0
/// What a tour step lights: screens wrap the widget in a [PhoneTourTarget] with an id the step
/// names. Kept apart from the tour itself so a screen imports nothing but this.
///
/// A target registers its context by id instead of holding a global key: two screens may
/// hold the same id for a moment (a new Home pushed over the old one while it slides in).
library;

import 'package:flutter/widgets.dart';

final Map<String, List<BuildContext>> _targets = {};

/// The context of the newest mounted target with [id], or null when none is on screen.
BuildContext? phoneTourContext(String id) {
  final list = _targets[id];
  if (list == null) return null;
  for (final context in list.reversed) {
    if (context.mounted) return context;
  }
  return null;
}

/// Marks [child] as what a tour step lights.
class PhoneTourTarget extends StatefulWidget {
  const PhoneTourTarget({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  State<PhoneTourTarget> createState() => _PhoneTourTargetState();
}

class _PhoneTourTargetState extends State<PhoneTourTarget> {
  late String _id = widget.id;

  @override
  void initState() {
    super.initState();
    (_targets[_id] ??= []).add(context);
  }

  @override
  void didUpdateWidget(PhoneTourTarget old) {
    super.didUpdateWidget(old);
    if (widget.id != _id) {
      _targets[_id]?.remove(context);
      _id = widget.id;
      (_targets[_id] ??= []).add(context);
    }
  }

  @override
  void dispose() {
    _targets[_id]?.remove(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
