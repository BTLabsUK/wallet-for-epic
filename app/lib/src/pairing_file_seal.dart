// SPDX-License-Identifier: Apache-2.0
// When a payment file is sealed for a paired contact (RFC 9.2), shared by the phone and the
// desktop Send.
import 'models.dart' show PairingRecord;

/// How long without a sealed message from a contact before Send says so.
const Duration sealQuietFor = Duration(days: 90);

/// The paired contact a payment file to [r] is sealed for, or null: no pairing, not paired,
/// paused, Seal payments off, or a wallet that does not open sealed files.
PairingRecord? fileSealTarget(PairingRecord? r) => r != null && r.seals ? r : null;

/// No sealed message from [r] for [sealQuietFor] at [now]: Send offers a plain file.
bool sealQuiet(PairingRecord r, DateTime now) {
  final last = r.lastSealedIn;
  return last == null || now.difference(last) > sealQuietFor;
}
