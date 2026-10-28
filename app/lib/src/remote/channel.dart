// SPDX-License-Identifier: Apache-2.0
/// The transport under the wallet protocol: text frames in, text frames out.
library;

import 'dart:async';

/// One end of a connection that carries JSON text frames.
///
/// [incoming] is single-subscription and ends when the connection closes, from either side.
/// [send] after the end is ignored.
abstract interface class RpcChannel {
  Stream<String> get incoming;

  void send(String frame);

  /// Closes both directions. [incoming] ends on both ends.
  Future<void> close();
}

/// Two connected in-memory ends, for tests and for running client and server in one process.
/// Frames are delivered asynchronously and in order.
(RpcChannel, RpcChannel) loopbackPair() {
  final a = _LoopbackEnd();
  final b = _LoopbackEnd();
  a._peer = b;
  b._peer = a;
  return (a, b);
}

class _LoopbackEnd implements RpcChannel {
  final StreamController<String> _in = StreamController<String>();
  late final _LoopbackEnd _peer;

  @override
  Stream<String> get incoming => _in.stream;

  @override
  void send(String frame) {
    if (_peer._in.isClosed) return;
    _peer._in.add(frame);
  }

  @override
  Future<void> close() async {
    if (!_in.isClosed) unawaited(_in.close());
    if (!_peer._in.isClosed) unawaited(_peer._in.close());
  }
}
