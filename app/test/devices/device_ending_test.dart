// The words for a linked device's payment that ended without spending its coins: every ending
// and every failure code has a line in all six languages, and the codes go over the wire as codes.
import 'package:epic_wallet/src/devices/device_ending.dart';
import 'package:epic_wallet/src/devices/device_wire.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/models.dart' show DeviceEnding;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final codes = [null, 'notDelivered', 'refused', 'inputsSpent', 'other'];

  test('the codes a failed payment carries are the ones the wire accepts', () {
    expect(noticeFailureCodes, {'notDelivered', 'refused', 'inputsSpent', 'other'});
    expect(codes.whereType<String>().toSet(), noticeFailureCodes);
  });

  test('English: a status and a line for each ending', () {
    final l = englishStrings;
    expect(deviceEndingLabel(l, DeviceEnding.releasedHere, 'Phone'), 'Released here · Phone may still send it');
    expect(deviceEndingLabel(l, DeviceEnding.cancelled, 'Phone'), 'Cancelled on Phone');
    expect(deviceEndingLabel(l, DeviceEnding.failed, 'Phone'), 'Failed on Phone');
    expect(deviceEndingLabel(l, DeviceEnding.expired, 'Phone'), 'Expired on Phone');
    expect(deviceEndingLine(l, DeviceEnding.releasedHere, 'Phone', null), isNull);
    expect(deviceEndingLine(l, DeviceEnding.cancelled, 'Phone', null), 'Phone cancelled this payment. Its coins are free again.');
    expect(deviceEndingLine(l, DeviceEnding.expired, 'Phone', null), contains('in time'));
    expect(deviceEndingLine(l, DeviceEnding.failed, 'Phone', 'notDelivered'), contains('could not deliver'));
    expect(deviceEndingLine(l, DeviceEnding.failed, 'Phone', 'refused'), contains('refused'));
    expect(deviceEndingLine(l, DeviceEnding.failed, 'Phone', 'inputsSpent'), contains('spent already'));
    expect(deviceEndingLine(l, DeviceEnding.failed, 'Phone', 'other'), contains('could not complete'));
    expect(deviceEndingLine(l, DeviceEnding.failed, 'Phone', 'never heard of'), contains('could not complete'));
  });

  test('every language words every ending and code with the device name', () {
    for (final lang in ['en', 'de', 'pl', 'ru', 'zh', 'th']) {
      final l = lookupAppLocalizations(Locale(lang));
      for (final e in DeviceEnding.values) {
        expect(deviceEndingLabel(l, e, 'Zed'), contains('Zed'), reason: '$lang $e');
        for (final code in codes) {
          final line = deviceEndingLine(l, e, 'Zed', code);
          expect(line == null || line.isNotEmpty, isTrue, reason: '$lang $e $code');
        }
      }
      for (final code in codes) {
        expect(deviceEndingLine(l, DeviceEnding.failed, 'Zed', code), isNotEmpty, reason: '$lang failed $code');
      }
    }
  });
}
