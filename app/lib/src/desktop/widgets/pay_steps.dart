// SPDX-License-Identifier: Apache-2.0
/// A payment's live steps on the desktop (wallet levels): started → signed → posted →
/// confirming → done, in the level's words. Overview's in-flight card, Send after the send,
/// Receive's arrival card and the payment dialog show it.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart' show Tx;

class DeskPaymentSteps extends ConsumerWidget {
  const DeskPaymentSteps({super.key, required this.tx, this.dense = false});

  final Tx tx;

  /// Fewer lines: the in-flight card and the arrival card.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
