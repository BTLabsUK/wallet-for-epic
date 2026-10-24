/// Whether a WebSocket server answers: the handshake to a URL, then the socket closes at once.
/// Send uses it to check a recipient's relay that the status monitor does not list.
///
/// The phone and desktop use `dart:io`'s `WebSocket` (`ws_probe_io.dart`); the browser uses
/// its own `WebSocket` (`ws_probe_web.dart`). Both answer false when the handshake fails or
/// [probeTimeout] passes. Over Tor the probe goes the way the wallet's Epicbox connection does
/// (`TorNet`) and is given [torProbeTimeout]; with Tor not connected in time it throws
/// [ProbeNotRun] instead of answering false.
library;

export 'probe_not_run.dart';
export 'ws_probe_io.dart' if (dart.library.js_interop) 'ws_probe_web.dart';

/// How long a relay may take to answer the handshake.
const Duration probeTimeout = Duration(seconds: 6);

/// The same over Tor, where building a circuit alone can take longer than [probeTimeout].
const Duration torProbeTimeout = Duration(seconds: 45);
