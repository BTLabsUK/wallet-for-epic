// SPDX-License-Identifier: Apache-2.0
/// Why a relay probe says nothing instead of "no".
library;

/// The probe could not be tried: Tor is on but did not connect in time, so nothing was opened
/// (and nothing went direct). The relay was never asked, so it is not a relay that does not
/// answer; the send itself waits for Tor the same way.
class ProbeNotRun implements Exception {
  const ProbeNotRun();

  @override
  String toString() => 'ProbeNotRun: Tor is not connected';
}
