// SPDX-License-Identifier: Apache-2.0
// No network for dart:io's HttpClient, in the test that asks for it: every connection is
// refused at once (cable out: what the OS answers with no route) or never answers (packets
// dropped: dead Wi-Fi, captive network). Nothing leaves the machine either way.
import 'dart:async';
import 'dart:io';

enum NetCut { refuse, drop }

class NoNetwork extends HttpOverrides {
  NoNetwork(this.cut);

  NetCut cut;

  /// Connections asked for, by host.
  final List<String> asked = [];

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory = (uri, proxyHost, proxyPort) {
      asked.add(uri.host);
      return switch (cut) {
        NetCut.refuse => Future<ConnectionTask<Socket>>.error(
          const SocketException('Network is unreachable', osError: OSError('Network is unreachable', 101)),
        ),
        // Never completes: only the caller's own timeout ends the wait.
        NetCut.drop => Completer<ConnectionTask<Socket>>().future,
      };
    };
    return client;
  }
}

/// Runs [body] with no network of kind [cut]; the [NoNetwork] it used is passed in.
Future<T> withoutNetwork<T>(NetCut cut, Future<T> Function(NoNetwork net) body) {
  final net = NoNetwork(cut);
  return HttpOverrides.runWithHttpOverrides(() => body(net), net);
}

/// How long [f] took and what it gave (or threw).
Future<({Duration took, Object? value, Object? error})> timed(Future<Object?> Function() f) async {
  final w = Stopwatch()..start();
  try {
    final v = await f();
    return (took: w.elapsed, value: v, error: null);
  } on Object catch (e) {
    return (took: w.elapsed, value: null, error: e);
  }
}
