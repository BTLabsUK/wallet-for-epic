// SPDX-License-Identifier: Apache-2.0
/// Amounts for tests.
library;

/// [value] EPIC in atomic units.
BigInt epic(num value) => BigInt.from((value * 100000000).round());
