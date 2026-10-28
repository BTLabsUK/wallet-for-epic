// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

/// The body of a short screen in `SlotScaffold(centered: true)`: [children] in a column as
/// wide as [ScreenBody]'s (at most 600 dp, 16 dp padding), sized to its content so the
/// scaffold can centre it. [ScreenBody] is a list view and cannot be centred.
class CenteredBody extends StatelessWidget {
  const CenteredBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
