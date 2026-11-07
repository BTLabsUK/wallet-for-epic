// SPDX-License-Identifier: Apache-2.0
/// The network mode at run time (Settings › Network & privacy): what may reach the network
/// now, for the screens (status lines, disabled buttons, the Tor switch) and for the code that
/// makes the calls. Pure Dart, also on the web.
///
/// - Normal (`standard`): today's app; the Tor switch is the user's.
/// - Tor only: the Tor switch is on and stays on; nothing goes on the clearnet (a node on this
///   computer may stay direct). Covered routes wait for tor and never fall back.
/// - Node only: the wallet reaches the node in use (the first of the node list) and nothing
///   else: no Epicbox, no Link, no status site, price, update check, explorer, support report,
///   reach check, pairing or linked devices. QR Payment and File Transfer work through the
///   node. The node goes over Tor while the user's Tor switch is on. No node failover.
/// - Kill switch: no connection at all, the node and loopback included; Tor and the built-in
///   node never start, nothing refreshes. File and QR payments are made, signed and finalized
///   without a node and posted elsewhere.
///
/// Every outbound connection of the app's own code goes through [NetGate.dial] first
/// (`docs/network-modes.md` lists them; `test/net_gate_scan_test.dart` fails a raw network
/// call outside the gated files). This is the one gate: LEPIC keeps no mode. The wallet
/// adapters stop or never start LEPIC's own connections (listeners, tor, refresh) by it, and a
/// Kill switch session is an offline one ([WalletConfig.offline], `walletOfflineSessions`).
///
/// The method switches (Settings › Transactions, `PaymentPrefs`) are read here too, so the
/// mode and "off" are one gate: [netBlockFor] with `epicbox:` or `offered:` for the screens,
/// [NetGate.checkEpicbox] and [NetGate.checkMethod] for the code that connects. Epicbox off:
/// no relay connection, no listener, no Epicbox sends or invoices, no push. Link · HTTP or
/// Link · Tor off: no listener of that kind, no address on Receive, no send to such an
/// address. QR Payment and File Transfer off: not offered.
library;

import 'dart:async';

import 'advanced.dart';
import 'payment_prefs.dart';
import 'net/tor_switch.dart';
import 'settings_file/host_settings.dart' show hostSettings, hostSettingsLoaded;
import 'tor_routes.dart';

import 'net/local_address.dart' show isLocalAddressUrl;

export 'net/local_address.dart' show isLocalAddressUrl;

/// Why network actions (Send over Epicbox/Direct, Recheck balance, starting a listener, checking a node) can't run now.
enum NetBlock {
  /// They can run.
  none,

  /// Node only: nothing but the node in use until the mode changes.
  nodeOnly,

  /// Kill switch: nothing reaches the network, not even the node.
  killSwitch,

  /// Tor only, and tor is starting or failed: they wait for tor and never go direct.
  waitingForTor,

  /// Epicbox is off in Settings › Transactions: nothing over Epicbox until it is on again.
  epicboxOff,

  /// The method the action needs is off in Settings › Transactions (Link · HTTP, Link · Tor,
  /// QR Payment or File Transfer; Epicbox is [epicboxOff]). The screen names it.
  methodOff,
}

extension NetBlockByMode on NetBlock {
  /// Held by the network mode itself (Node only or Kill switch), not by tor or a switch.
  bool get byMode => this == NetBlock.nodeOnly || this == NetBlock.killSwitch;
}

/// Why network actions can't run in [mode] with the Tor switch [tor] (`tor_view.dart`'s
/// `torStateOf` on the desktop, `phoneTorState` on the phone). [node]: the action reaches only
/// the node in use (Recheck balance, posting, a node check), which Node only lets run.
/// [epicbox]: false for an action over Epicbox while the Epicbox switch is off
/// ([NetBlock.epicboxOff]); [offered]: false for an action by another method whose switch
/// is off ([NetBlock.methodOff]). The mode's own answer comes first.
NetBlock netBlockFor(NetworkMode mode, TorState tor, {bool node = false, bool epicbox = true, bool offered = true}) =>
    switch (mode) {
      NetworkMode.killSwitch => NetBlock.killSwitch,
      NetworkMode.nodeOnly => node ? NetBlock.none : NetBlock.nodeOnly,
      NetworkMode.torOnly when tor != TorState.on => NetBlock.waitingForTor,
      _ when !epicbox => NetBlock.epicboxOff,
      _ => offered ? NetBlock.none : NetBlock.methodOff,
    };

/// The mode the runtime follows for a stored one: anything unknown as Normal.
NetworkMode netModeOf(NetworkMode? mode) => mode ?? NetworkMode.standard;

/// The transaction file and QR Payment methods use the node in use while Node only: LEPIC asks
/// it for its tip before it creates a send file, signs a received one or finalizes one (and
/// finalizing also posts). True when the node is not [localNode], so the screen says so (a
/// note, never a block); false in the other modes.
bool nodeOnlyUsesNode(NetworkMode mode, {required bool localNode}) =>
    netModeOf(mode) == NetworkMode.nodeOnly && !localNode;

/// What holds a payment that reaches only the node (making, signing, finalizing and posting a
/// transaction file or a QR Payment): Node only lets it use the node in use; Tor only still
/// waits for tor; Kill switch makes, signs and finalizes without a node and holds only the
/// posting ([NetBlock.killSwitch], the screen offers "post elsewhere").
NetBlock paymentBlockFor(NetworkMode mode, TorState tor) => netBlockFor(mode, tor, node: true);

/// The Tor switch can't be turned off: Tor only keeps it on.
bool torSwitchLocked(NetworkMode mode) => netModeOf(mode) == NetworkMode.torOnly;

/// The Tor switch does nothing: Kill switch starts no tor. In Node only it is the user's and
/// carries the node.
bool torSwitchDisabled(NetworkMode mode) => netModeOf(mode) == NetworkMode.killSwitch;

/// Whether Tor only waits for its tor now: nothing may reach a relay before tor carries it.
bool get torOnlyWaiting => NetGate.torOnly && !TorSwitch.carried;

/// Throws [NetBlocked] (Tor only) for [what] while [torOnlyWaiting].
void checkTorReady(String what) {
  if (torOnlyWaiting) throw NetBlocked(NetworkMode.torOnly, what);
}

/// A network action refused by the mode: [what] is for the log, [mode] says why (Node only,
/// Kill switch, or Tor only refusing a clearnet connection). [epicboxOff]: the Epicbox switch
/// refused an Epicbox action (the mode is then whatever it is); [methodOff] names the method
/// whose switch refused it (Epicbox included).
class NetBlocked implements Exception {
  const NetBlocked(this.mode, this.what, {this.epicboxOff = false, this.methodOff});

  final NetworkMode mode;
  final String what;
  final bool epicboxOff;
  final MethodKind? methodOff;

  @override
  String toString() => methodOff != null ? 'NetBlocked(${methodOff!.name} off): $what' : 'NetBlocked(${mode.name}): $what';
}

/// Plain `http://` to another device is off while the Tor switch is on, in Tor only too
/// ([TorRoute.plainHttpDirect] is in [torStops]): the wallet's connections go through Tor then,
/// and a Tor exit could answer the slate and take the payment. https and onions still go.
bool get plainHttpOffNow => TorSwitch.on || NetGate.torOnly;

/// A send or resend over plain `http://` to another device refused while [plainHttpOffNow].
/// Nothing reached the wallet; the user reads `sendPlainHttpOffWithTor`.
class PlainHttpOffWithTor implements Exception {
  const PlainHttpOffWithTor(this.what);

  /// For the log: a send or a resend.
  final String what;

  @override
  String toString() => 'PlainHttpOffWithTor: $what';
}

/// The kinds of outbound connection the app's own code makes, for [NetGate.dial].
enum NetDial {
  /// An HTTP(S) request: `http_io.dart`, `http_web.dart`, the node client, update downloads.
  http,

  /// A WebSocket (the Epicbox relay probes).
  webSocket,

  /// A host name looked up by this computer's resolver.
  lookup,

  /// The loopback relay passing LEPIC's requests on to a node on the local network.
  nodeRelay,

  /// Starting tor (the phone's, the desktop's bundle) or connecting to its SOCKS port.
  tor,

  /// Starting the built-in node (desktop): its API is the node in use, its peers its own.
  builtInNode,

  /// Opening an address in the system browser (explorer, help, download pages).
  browser,
}

/// Whether the wallet's tor publishes its onion, with the Link listener behind it (LEPIC's
/// `startTor(publishOnion:)`): not in Node only, where tor only carries the node, nor in Kill
/// switch, which starts no tor.
bool get torPublishesOnion => !NetGate.mode.restricted;

/// The current mode for code without a Riverpod ref (the app's own HTTP, the wallet adapters).
/// Both apps set it at launch right after the settings file opens, before any request, and on
/// every change; [changes] lets a long-lived owner (a wallet adapter) resume or stop.
abstract final class NetGate {
  static NetworkMode _mode = NetworkMode.standard;
  static bool _firstStartHold = false;
  static PaymentPrefs _payments = PaymentPrefs.defaults;
  static final StreamController<NetworkMode> _changes = StreamController.broadcast(sync: true);

  /// The mode the gate enforces: the stored one, or Kill switch while [firstStartHold].
  static NetworkMode get mode => _firstStartHold ? NetworkMode.killSwitch : _mode;

  /// A fresh install has not answered the first-start step (`levels/first_start.dart`): no
  /// connection of any kind, as Kill switch, whatever mode is stored. The stored mode (Tor only
  /// when the user picks Undercover) is set underneath and takes over at [releaseFirstStart],
  /// so the first connection is already made in it.
  static bool get firstStartHold => _firstStartHold;

  /// Holds every connection until [releaseFirstStart]. Set at launch before any request.
  static void holdFirstStart() {
    if (_firstStartHold) return;
    _firstStartHold = true;
    _changes.add(mode);
  }

  /// Ends [holdFirstStart]: the stored mode applies from now on.
  static void releaseFirstStart() {
    if (!_firstStartHold) return;
    _firstStartHold = false;
    _changes.add(mode);
  }

  /// Node only.
  static bool get nodeOnly => mode == NetworkMode.nodeOnly;

  /// Kill switch: nothing connects, the node included.
  static bool get killSwitch => mode == NetworkMode.killSwitch;

  /// Nothing but the node in use reaches the network (Node only), or nothing at all (Kill
  /// switch): no Epicbox, Link, pairing, status site, price, updates or reach checks.
  static bool get restricted => nodeOnly || killSwitch;

  /// The node in use, for [dial] in Node only: the first of the settings file's node list.
  /// Tests replace it.
  static String Function() nodeInUse = () => hostSettingsLoaded ? hostSettings.nodeUse : '';

  /// The hosts [dial] lets through in Node only: the node in use's, and its loopback
  /// spellings when it is on this computer.
  static Set<String> get nodeHosts {
    final host = _hostOf(nodeInUse());
    if (host.isEmpty) return const {};
    return _isLoopbackHost(host) ? const {'localhost', '127.0.0.1', '::1'} : {host};
  }

  /// The method switches (Settings › Transactions). The phone's settings and the desktop's
  /// store set them at launch and on every change, as [set] for the mode.
  static PaymentPrefs get payments => _payments;

  static void setPayments(PaymentPrefs p) => _payments = p;

  /// The Epicbox switch: on by default.
  static bool get epicbox => _payments.epicbox;

  /// The Epicbox switch alone, for code that holds no [PaymentPrefs].
  static void setEpicbox(bool on) => _payments = _payments.copyWith(epicbox: on);

  /// [m] is on in Settings › Transactions.
  static bool offers(MethodKind m) => _payments.offers(m);

  /// Nothing over Epicbox now: the mode refuses it, or the Epicbox switch is off.
  static bool get epicboxOff => restricted || !epicbox;

  static bool get torOnly => mode == NetworkMode.torOnly;

  /// Linked devices, for the wallet adapters. The phone's settings and the desktop's store set
  /// it at launch, before a wallet opens, and on every change; on until then, so a core test
  /// without settings pairs.
  static bool _linkedDevices = true;

  /// Pairing is on for everyone; the stored switch value is ignored.
  static bool get pairing => true;

  /// Linked devices: their private pairings are collected and posted to ([linkedDevices]), with
  /// the contact mailboxes left alone while [pairing] is off.
  static bool get linkedDevices => _linkedDevices;

  static void setExperimental(AdvancedPrefs prefs) {
    _linkedDevices = prefs.linkedDevicesOn;
  }

  /// Every change of [mode], after it is set.
  static Stream<NetworkMode> get changes => _changes.stream;

  static void set(NetworkMode? mode) {
    final next = netModeOf(mode);
    if (next == _mode) return;
    _mode = next;
    // Held, the gate stays shut: the new mode applies at [releaseFirstStart].
    if (!_firstStartHold) _changes.add(next);
  }

  /// Throws [NetBlocked] in Node only and Kill switch: for every call that would reach the
  /// network beyond the node. [node]: the call reaches only the node in use, which Node only
  /// allows (Kill switch refuses it too).
  static void check(String what, {bool node = false}) {
    if (killSwitch || (nodeOnly && !node)) throw NetBlocked(mode, what);
  }

  /// [check] for a call to the node in use only.
  static void checkNode(String what) => check(what, node: true);

  /// Throws [NetBlocked] for a call over Epicbox (the listener, a send, an invoice, push):
  /// refused by the mode as [check], and with the Epicbox switch off with `epicboxOff`.
  static void checkEpicbox(String what) {
    check(what);
    if (!epicbox) throw NetBlocked(mode, what, epicboxOff: true, methodOff: MethodKind.epicbox);
  }

  /// Throws [NetBlocked] for an action by method [m] (a listener, a send, an address handed
  /// out): refused by the mode as [check] (File Transfer and QR Payment reach only the node,
  /// so Node only lets them through), and with the method's switch off with `methodOff`.
  static void checkMethod(MethodKind m, String what) {
    check(what, node: m == MethodKind.directFile || m == MethodKind.directQr);
    if (!offers(m)) throw NetBlocked(mode, what, epicboxOff: m == MethodKind.epicbox, methodOff: m);
  }

  /// Whether a connection of [kind] to [host] may be opened now (see [dial]).
  static bool allows(NetDial kind, String host) {
    switch (mode) {
      case NetworkMode.standard:
        return true;
      case NetworkMode.torOnly:
        // Tor only's own rule lives where the connection is made (`TorNet`): through tor, or
        // waiting for it, never direct. The system browser can't be put through the app's
        // tor, so it stays shut.
        return kind != NetDial.browser;
      case NetworkMode.killSwitch:
        return false;
      case NetworkMode.nodeOnly:
        return switch (kind) {
          // The user's Tor switch carries the node.
          NetDial.tor => true,
          NetDial.browser => false,
          NetDial.http || NetDial.webSocket || NetDial.lookup || NetDial.nodeRelay || NetDial.builtInNode =>
            nodeHosts.contains(_normHost(host)),
        };
    }
  }

  /// The one check before every outbound connection of the app's own code: throws
  /// [NetBlocked] when the mode refuses a connection of [kind] to [host] (a host name, an
  /// address or a URL). Normal and Tor only let everything through here (Tor only routes in
  /// `TorNet`); Node only only the node in use's host (and starting tor while the Tor switch is
  /// on); Kill switch nothing, loopback included.
  static void dial(NetDial kind, String host) {
    if (!allows(kind, host)) throw NetBlocked(mode, '${kind.name} ${_normHost(host)}');
  }

  /// [dial] for a connection that can only go direct, never through tor (LEPIC's node tip
  /// asked with no wallet open, which has no tor): Tor only refuses it unless [url] is on this
  /// computer or the local network ([isLocalAddressUrl]).
  static void dialDirect(NetDial kind, String url) {
    dial(kind, url);
    if (torOnly && !isLocalAddressUrl(url)) throw NetBlocked(mode, 'direct ${kind.name} ${_hostOf(url)}');
  }
}

String _hostOf(String url) {
  final u = Uri.tryParse(url.trim());
  return u == null ? '' : _normHost(u.host);
}

String _normHost(String host) {
  var h = host.trim().toLowerCase();
  if (h.contains('://')) h = Uri.tryParse(h)?.host.toLowerCase() ?? h;
  if (h.startsWith('[') && h.endsWith(']')) h = h.substring(1, h.length - 1);
  if (_isLoopbackHost(h)) return h == 'localhost' ? h : (h.contains(':') ? '::1' : '127.0.0.1');
  return h;
}

bool _isLoopbackHost(String h) => h == 'localhost' || h == '::1' || h == '[::1]' || h.startsWith('127.');
