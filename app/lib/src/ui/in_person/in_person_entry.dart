// SPDX-License-Identifier: Apache-2.0
/// The phone's ways into epic1 in-person payments (spec D5, P3, P5, P6). Receive, Send and the
/// scanner call these; the screens behind them live in this folder.
library;

import 'package:flutter/widgets.dart';

/// Receive › "Request in person": amount and message, then the code and the check.
Future<void> openRequestInPerson(BuildContext context) async {}

/// Send › "Pay in person": amount, then the send code and the check.
Future<void> openPayInPerson(BuildContext context) async {}

/// Scanned, pasted or opened [text] that may be an in-person code or answer. Handles it and
/// returns true, or returns false when it is neither.
Future<bool> openInPersonText(BuildContext context, String text) async => false;
