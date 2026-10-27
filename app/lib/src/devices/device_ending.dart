/// The words for a linked device's payment that ended without spending its coins
/// ([DeviceEnding]): the row's status and one short line for its details. Shared by the phone
/// and the desktop; the codes a failed payment carries are worded here, in the app's language.
library;

import '../l10n.dart' show AppLocalizations;
import '../models.dart' show DeviceEnding;

/// The row's status: "Released here · Phone may still send it", "Cancelled on Phone", "Failed on
/// Phone", "Expired on Phone".
String deviceEndingLabel(AppLocalizations l, DeviceEnding ending, String name) => switch (ending) {
  DeviceEnding.releasedHere => l.devicesReleasedRow(name),
  DeviceEnding.cancelled => l.devicesEndCancelled(name),
  DeviceEnding.failed => l.devicesEndFailed(name),
  DeviceEnding.expired => l.devicesEndExpired(name),
};

/// The details' line for the ending, the other device's reason in a sentence; null when the
/// status says it all (released here). [why] is the code a failed payment carried.
String? deviceEndingLine(AppLocalizations l, DeviceEnding ending, String name, String? why) => switch (ending) {
  DeviceEnding.releasedHere => null,
  DeviceEnding.cancelled => l.devicesEndLineCancelled(name),
  DeviceEnding.expired => l.devicesEndLineExpired(name),
  DeviceEnding.failed => switch (why) {
    'notDelivered' => l.devicesWhyNotDelivered(name),
    'refused' => l.devicesWhyRefused,
    'inputsSpent' => l.devicesWhyInputsSpent,
    _ => l.devicesWhyOther(name),
  },
};
