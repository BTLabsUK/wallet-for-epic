// SPDX-License-Identifier: Apache-2.0
/// `last_session.dart` in the browser: a page keeps no log between loads, so there is no last
/// session to offer.
library;

import 'last_session_types.dart';

/// Never set on the web.
const LastSessionSource? lastSession = null;
