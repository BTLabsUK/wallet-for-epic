/// The phone's one owner of the Link · HTTP listener for the open wallet: wallets on the same
/// Wi-Fi network pay this one at `http://<this phone's LAN address>:3415`. It runs only while a
/// wallet is open, Link · HTTP is on (Settings › Transactions), the network mode allows it and
/// Tor is off; it stops on lock, and after the app comes back it starts again if it should run.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'advanced.dart' show NetworkMode;
import 'app_log.dart';
import 'phone_tor.dart';
import 'providers.dart';
import 'settings.dart' show appSettingsProvider, networkModeProvider;
import 'tor_phone.dart' show phoneTorState;
import 'tor_routes.dart';
import 'wallet_service.dart';

/// The phone's HTTP listener port: no setting, so every wallet on the network can guess it.
const int phoneHttpPort = 3415;

enum PhoneHttpPhase {
  /// Not running: locked, or Link · HTTP is off.
  off,

  /// Asked LEPIC to listen; no answer yet.
  starting,

  /// Listening on [PhoneHttpState.port] at [PhoneHttpState.address].
  listening,

  /// Another program holds the port. Retry starts it again.
  portInUse,

  /// The port could not be listened on, or the listener ended by itself. Retry starts it again.
  failed,

  /// Not run while Tor is on (and never in Tor only): it would answer at this phone's own
  /// address ([TorRoute.httpListener]).
  offWhileTor,

  /// Listening, but the phone is on no Wi-Fi or wired network: there is no address to hand out.
  noNetwork,

  /// Offline mode on a node that is not on this phone or the local network: a received payment
  /// is signed with the node's tip, so nothing listens.
  offline,
}

class PhoneHttpState {
  const PhoneHttpState({
    this.listener = PhoneHttpPhase.off,
    this.address,
    this.port = phoneHttpPort,
  });

  /// What the listener does; [phase] adds [PhoneHttpPhase.noNetwork] on top of it.
  final PhoneHttpPhase listener;

  /// `http://<ipv4>:<port>` on this phone's Wi-Fi or wired network, null on none.
  final String? address;

  final int port;

  PhoneHttpPhase get phase =>
      listener == PhoneHttpPhase.listening && address == null ? PhoneHttpPhase.noNetwork : listener;

  PhoneHttpState copyWith({
    PhoneHttpPhase? listener,
    String? Function()? address,
    int? port,
  }) => PhoneHttpState(
    listener: listener ?? this.listener,
    address: address == null ? this.address : address(),
    port: port ?? this.port,
  );

  @override
  int get hashCode => listener.hashCode ^ address.hashCode ^ port.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneHttpState && listener == other.listener && address == other.address && port == other.port;

  @override
  String toString() => 'PhoneHttpState(${phase.name}, $address, $port)';
}

/// Interface names of networks other wallets can share with this phone: Wi-Fi, wired, and
/// the phone's own hotspot. Mobile data (`rmnet…`, `ccmni…`), VPNs (`tun…`) and the rest are
/// not reachable from a neighbour.
const List<String> _lanPrefixes = ['wlan', 'eth', 'en', 'wl', 'swlan', 'ap'];

/// The first IPv4 address of a LAN interface in [interfaces] (name, address), Wi-Fi before
/// the rest in [_lanPrefixes]' order; null when there is none.
String? pickLanIpv4(List<({String name, String address})> interfaces) {
  for (final prefix in _lanPrefixes) {
    for (final i in interfaces) {
      if (!i.name.startsWith(prefix)) continue;
      final ip = InternetAddress.tryParse(i.address);
      if (ip == null || ip.type != InternetAddressType.IPv4 || ip.isLoopback || ip.isLinkLocal) continue;
      return i.address;
    }
  }
  return null;
}

/// This phone's LAN IPv4 address now ([pickLanIpv4]), null without one or on the web.
Future<String?> readLanIpv4() async {
  if (kIsWeb) return null;
  try {
    final list = await NetworkInterface.list(type: InternetAddressType.IPv4);
    return pickLanIpv4([
      for (final i in list)
        for (final a in i.addresses) (name: i.name, address: a.address),
    ]);
  } catch (e) {
    logWarn('http', 'network interfaces: ${e.runtimeType}');
    return null;
  }
}

/// Reads the LAN address; tests override it.
final lanAddressReaderProvider = Provider<Future<String?> Function()>((ref) => readLanIpv4);

/// The Link · HTTP listener of the open wallet. `app.dart` keeps it alive for the app's life.
final phoneHttpProvider = NotifierProvider<PhoneHttp, PhoneHttpState>(PhoneHttp.new);

class PhoneHttp extends Notifier<PhoneHttpState> {
  /// Bumped on every build (unlock, lock, another wallet): work of an older one stops.
  int _generation = 0;
  WalletSession? _session;
  StreamSubscription<HttpListenerEvent>? _http;

  /// A [_stop] waiting on LEPIC; a start waits for it, or the second start's stream would end
  /// at once.
  Future<void>? _stopping;

  @override
  PhoneHttpState build() {
    final session = ref.watch(sessionProvider);
    final generation = ++_generation;
    _session = session;
    _http = null;
    _stopping = null;
    // A plain observer, as in PhoneTor: a lock on `paused` rebuilds this during dispatch.
    final lifecycle = _LifecycleObserver((s) {
      if (s == AppLifecycleState.resumed && _current(generation)) unawaited(_resumed());
    });
    WidgetsBinding.instance.addObserver(lifecycle);
    // The address comes a moment after the network: read now and once it has settled.
    Timer? settle;
    final network = ref.watch(networkChangesProvider).listen((_) {
      if (!_current(generation)) return;
      unawaited(_readAddress());
      settle?.cancel();
      settle = Timer(const Duration(seconds: 3), () {
        if (_current(generation)) unawaited(_readAddress());
      });
    });
    ref.onDispose(() {
      // LEPIC stops the listener when the session is disposed (lock); only our side ends here.
      final sub = _http;
      _http = null;
      unawaited(sub?.cancel());
      settle?.cancel();
      WidgetsBinding.instance.removeObserver(lifecycle);
      unawaited(network.cancel());
    });
    if (session == null) return const PhoneHttpState();
    // After the change has reached every provider: in a listener, one that depends on the
    // changed one (the network mode on the settings) still reads its old value.
    void later() => scheduleMicrotask(() {
      if (_current(generation)) _apply();
    });
    ref.listen(appSettingsProvider.select((s) => s.value?.payments.linkHttp), (_, _) => later());
    ref.listen(networkModeProvider, (_, _) => later());
    ref.listen(localNodeProvider, (_, _) => later());
    ref.listen(phoneTorProvider.select((s) => (s.settled, phoneTorState(s))), (_, _) => later());
    Future.microtask(() {
      if (_current(generation)) {
        _apply();
        unawaited(_readAddress());
      }
    });
    return const PhoneHttpState();
  }

  bool _current(int generation) => generation == _generation && ref.mounted;

  bool get _running => _http != null;

  /// Why it must not run now, as the phase to show; null when it should run.
  PhoneHttpPhase? get _blocked {
    if (_session == null) return PhoneHttpPhase.off;
    if (ref.read(appSettingsProvider).value?.payments.linkHttp != true) return PhoneHttpPhase.off;
    final mode = ref.read(networkModeProvider);
    if (mode == NetworkMode.torOnly) return PhoneHttpPhase.offWhileTor;
    if (mode == NetworkMode.offline && !ref.read(localNodeProvider)) return PhoneHttpPhase.offline;
    final tor = ref.read(phoneTorProvider);
    // Until the wallet's Tor switch is read it may be on: never listen in the clearnet first.
    if (!tor.settled) return PhoneHttpPhase.off;
    if (torWay(TorRoute.httpListener, phoneTorState(tor)) != TorWay.clearnet) return PhoneHttpPhase.offWhileTor;
    return null;
  }

  /// Starts or stops the listener to match the conditions. A listener that failed waits for
  /// [retry] or a resume, unless it was stopped meanwhile.
  void _apply() {
    if (!ref.mounted) return;
    final blocked = _blocked;
    if (blocked != null) {
      if (_running) unawaited(_stop());
      if (state.listener != blocked) state = state.copyWith(listener: blocked);
      return;
    }
    if (_running) return;
    if (state.listener == PhoneHttpPhase.portInUse || state.listener == PhoneHttpPhase.failed) return;
    _start();
  }

  /// Stops the listener if it runs and starts it again now, when it should run.
  Future<void> retry() async {
    if (_blocked != null) {
      _apply();
      return;
    }
    await _stop();
    if (!ref.mounted) return;
    state = state.copyWith(listener: PhoneHttpPhase.off);
    unawaited(_readAddress());
    _apply();
  }

  Future<void> _resumed() async {
    await _readAddress();
    if (!ref.mounted) return;
    // A listener that failed while away gets one more go now.
    if (!_running && (state.listener == PhoneHttpPhase.failed || state.listener == PhoneHttpPhase.portInUse)) {
      state = state.copyWith(listener: PhoneHttpPhase.off);
    }
    _apply();
  }

  Future<void> _readAddress() async {
    final generation = _generation;
    final ip = await ref.read(lanAddressReaderProvider)();
    if (!_current(generation)) return;
    final address = ip == null ? null : 'http://$ip:${state.port}';
    if (address != state.address) {
      logInfo('http', address == null ? 'no LAN address' : 'LAN address changed');
      state = state.copyWith(address: () => address);
    }
  }

  void _start() {
    final session = _session;
    if (session == null || _running) return;
    final generation = _generation;
    state = state.copyWith(listener: PhoneHttpPhase.starting, port: phoneHttpPort);
    final stopping = _stopping;
    if (stopping != null) {
      unawaited(
        stopping.whenComplete(() {
          if (_current(generation) && !_running) {
            state = state.copyWith(listener: PhoneHttpPhase.off);
            _apply();
          }
        }),
      );
      return;
    }
    logInfo('http', 'listener start');
    late final StreamSubscription<HttpListenerEvent> sub;
    void ended(PhoneHttpPhase phase) {
      if (_http != sub || !_current(generation)) return;
      _http = null;
      state = state.copyWith(listener: phase);
    }

    // Every interface: on a phone 127.0.0.1 reaches nobody. Behind the router's NAT (or the
    // carrier's) the internet cannot reach it anyway; the LAN can.
    sub = session
        .startHttpListener(exposure: HttpExposure.internet, port: phoneHttpPort)
        .listen(
          (e) {
            if (_http != sub || !_current(generation)) return;
            switch (e.kind) {
              case HttpListenerEventKind.started:
                state = state.copyWith(listener: PhoneHttpPhase.listening, port: e.port ?? phoneHttpPort);
              case HttpListenerEventKind.portInUse:
                logInfo('http', 'port in use');
                ended(PhoneHttpPhase.portInUse);
              case HttpListenerEventKind.bindFailed:
                logInfo('http', 'bind failed');
                ended(PhoneHttpPhase.failed);
              case HttpListenerEventKind.received:
                if (!e.repeated) ref.invalidate(homeProvider);
              case HttpListenerEventKind.refused:
                // Never the sender or its address: only that a payment was refused, and why.
                logInfo('http', 'listener refused: ${e.refusal?.name ?? '?'}');
              case HttpListenerEventKind.stopped:
                // Not by us ([_stop] lets go first): it should still run, so Retry.
                ended(PhoneHttpPhase.failed);
            }
          },
          onError: (Object e) {
            logWarn('http', 'listener ended: ${e is WalletError ? e.kind.name : e.runtimeType}');
            ended(PhoneHttpPhase.failed);
          },
          onDone: () {
            // A second start gets a stream that ends at once.
            ended(state.listener == PhoneHttpPhase.listening ? PhoneHttpPhase.failed : state.listener);
          },
        );
    _http = sub;
  }

  Future<void> _stop() async {
    final sub = _http;
    if (sub == null) return _stopping;
    _http = null;
    logInfo('http', 'listener stop');
    final stopping = () async {
      try {
        await _session?.stopHttpListener();
      } on WalletError catch (e) {
        logWarn('http', 'stop: ${e.kind.name}');
      }
      await sub.cancel();
    }();
    _stopping = stopping;
    await stopping;
    if (identical(_stopping, stopping)) _stopping = null;
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  _LifecycleObserver(this.onChange);

  final void Function(AppLifecycleState state) onChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => onChange(state);
}
