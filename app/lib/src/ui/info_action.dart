// SPDX-License-Identifier: Apache-2.0
/// A choice an explanation holds: the phone's info sheet (`info_hint.dart`) and the desktop's
/// popover (`desktop/widgets/popover.dart`) show it as a button under the text, and close
/// before it runs. The scan start's "Scan from the start" is one.
library;

import 'package:flutter/widgets.dart' show Key;

class InfoAction {
  const InfoAction(this.label, this.onPressed, {this.key, this.semanticsId});

  final String label;
  final void Function() onPressed;

  /// The button's key, for tests.
  final Key? key;

  /// The test drivers' stable name for the button (`TrustIds`).
  final String? semanticsId;
}
