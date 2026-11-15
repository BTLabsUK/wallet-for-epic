// SPDX-License-Identifier: Apache-2.0
/// Reads an in-person code's camera parts for the desktop scan dialog, as the phone's scanner
/// does: text that is not `ur:` is the answer itself, `ur:` parts add up until the code is whole.
/// A classic payment's animated code shares the type and tells itself apart only once whole;
/// it ends the scan as [DeskClassicScanned].
library;

import 'dart:async';

import '../../../epic1.dart';
import '../../../wallet_service.dart' show QrSlateProgress;
import '../../../ui/in_person/in_person_scan.dart' show InPersonScanned;
import '../scan/desk_scan.dart';

/// A whole classic payment code the in-person reader ended on: its transaction text, for the
/// screen that reads it.
class DeskClassicScanned extends InPersonScanned {
  const DeskClassicScanned(this.json) : super(classic: true);

  final String json;
}

class DeskInPersonReader implements DeskPartReader<InPersonScanned> {
  /// [first] is a part read already (a pasted or scanned `ur:` part the screen got first).
  /// [classic] is the payment decoder: with it a whole classic payment code ends the scan as
  /// [InPersonScanned.classic].
  DeskInPersonReader(this.wallet, {String? first, this.classic}) {
    if (first != null) _parts.add(first.trim());
  }

  final Epic1Wallet wallet;
  final Future<QrSlateProgress> Function(List<String> parts)? classic;
  final List<String> _parts = [];
  int _received = 0;
  int _total = 0;

  @override
  FutureOr<DeskPartStep<InPersonScanned>> read(String text) {
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
      // A part of another code, or not one: the camera goes on, unless it was the last part
      // of a classic payment's code.
      final decode = classic;
      if (decode != null) return _classic(decode, [..._parts.where((p) => p != t), t]);
    }
    return DeskPartWaiting(_received, _total);
  }

  Future<DeskPartStep<InPersonScanned>> _classic(Future<QrSlateProgress> Function(List<String>) decode, List<String> parts) async {
    try {
      final read = await decode(parts);
      if (read.complete && read.json != null) return DeskPartDone(DeskClassicScanned(read.json!));
    } on Object {
      // Not a payment either.
    }
    return DeskPartWaiting(_received, _total);
  }
}
