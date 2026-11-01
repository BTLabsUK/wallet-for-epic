// SPDX-License-Identifier: Apache-2.0
/// The one block height every demo, mock and screenshot fixture treats as the network tip, on
/// the phone and the desktop, so the screens agree. Sample heights are written as this less a
/// distance, and no fixture names a height of its own.
library;

/// The demo network's tip.
const int demoTip = 3764975;

/// The node software version every demo node reports (the released one).
const String demoNodeVersion = '4.1.1';

/// The 24-hour uptime every demo node reports, as the status site gives it (99.7 %).
const double demoNodeUptime = 0.997;
