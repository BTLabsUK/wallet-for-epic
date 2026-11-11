// SPDX-License-Identifier: Apache-2.0
/// Reads an in-person code's camera parts for the desktop scan dialog, as the phone's scanner
/// does: text that is not `ur:` is the answer itself, `ur:` parts add up until the code is whole.
library;

import '../../../epic1.dart';
import '../../../ui/in_person/in_person_scan.dart' show InPersonScanned;
import '../scan/desk_scan.dart';

class DeskInPersonReader implements DeskPartReader<InPersonScanned> {
  /// [first] is a part read already (a pasted or scanned `ur:` part the screen got first).
  DeskInPersonReader(this.wallet, {String? first}) {
    if (first != null) _parts.add(first.trim());
  }

  final Epic1Wallet wallet;
  final List<String> _parts = [];
  int _received = 0;
  int _total = 0;

  @override
  DeskPartStep<InPersonScanned> read(String text) {
    final t = text.trim();
    if (t.isEmpty) return DeskPartWaiting(_received, _total);
    if (!t.toLowerCase().startsWith('ur:')) return DeskPartDone(InPersonScanned(text: t));
    if (_parts.contains(t) && _parts.length > 1) return DeskPartWaiting(_received, _total);
    try {
      final progress = wallet.qrRead([..._parts.where((p) => p != t), t]);
      if (!_parts.contains(t)) _parts.add(t);
      final bytes = progress.bytes;
      if (progress.complete && bytes != null) return DeskPartDone(InPersonScanned(bytes: bytes));
      _received = progress.received;
      _total = progress.total;
    } on Object {
      // A part of another code, or not one: the camera goes on.
    }
    return DeskPartWaiting(_received, _total);
  }
}
