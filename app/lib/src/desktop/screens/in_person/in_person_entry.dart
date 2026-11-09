// SPDX-License-Identifier: Apache-2.0
/// The desktop's ways into epic1 in-person payments (spec D5). Receive, Send and file opening
/// call these; the screens behind them live in this folder. The desktop has no scanner: it
/// shows codes and takes pasted ones.
library;

import 'package:flutter/widgets.dart';

/// Receive › "Request in person": amount and message, then the code and the check.
Future<void> openDeskRequestInPerson(BuildContext context) async {}

/// Send › "Pay in person": amount, then the send code and the check.
Future<void> openDeskPayInPerson(BuildContext context) async {}

/// Pasted or opened [text] that may be an in-person code or answer. Handles it and returns
/// true, or returns false when it is neither.
Future<bool> openDeskInPersonText(BuildContext context, String text) async => false;
