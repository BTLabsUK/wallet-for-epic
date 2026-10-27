/// What Help › How linked devices work shows of the desktop's devices (`help_sync.dart`). The
/// desktop's device layer (`data/devices_state.dart`, branch feat/dl-devices-desk) is not in
/// this tree yet: until it lands there is no view, so the status panel shows its empty state,
/// and no Link a device. Once it lands, [deskHelpDeviceViewProvider] reads
/// `deskDeviceViewProvider` and [deskHelpLinkProvider] opens the Linked devices page
/// (`DeskRoute.settingsDevices`); the tour's override of the view for its shot goes too.
library;

import 'package:flutter/widgets.dart' show VoidCallback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/device_providers.dart';

/// The devices as the open wallet's service sees them; null while there is none.
final deskHelpDeviceViewProvider = Provider<DeviceView?>((ref) => null);

/// Opens Link a device; null while the desktop has no page for it.
final deskHelpLinkProvider = Provider<VoidCallback?>((ref) => null);
