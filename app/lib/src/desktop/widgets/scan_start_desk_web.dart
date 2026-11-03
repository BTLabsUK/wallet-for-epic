// SPDX-License-Identifier: Apache-2.0
/// The web build's stand-in for scan_start_desk.dart: the browser shows the phone's screens, so
/// the block keeps the phone's layout there.
library;

import 'package:flutter/widgets.dart';

import '../../ui/scan_start.dart';

Widget deskScanStart(BuildContext context, ScanStart s) => s.phone(context);
