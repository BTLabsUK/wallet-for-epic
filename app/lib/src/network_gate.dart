/// The network mode at run time (Settings › Advanced): what may reach the network now, for the
/// screens (status lines, disabled buttons, the Tor switch) and for the code that makes the
/// calls. Pure Dart, also on the web.
///
/// - Standard: today's app; the Tor switch is the user's.
/// - Tor only: the Tor switch is on and stays on; nothing goes on the clearnet (a node on this
///   computer may stay direct). Covered routes wait for tor and never fall back.
/// - Offline: no Epicbox, no Link beyond local addresses, no Tor, no push, no status
///   calls, none of the app's own requests. Payments by transaction file and QR Payment stay
///   available: they need a node to read the chain and post, so they use the node in use, a
///   public one too (the screens say so, [offlineUsesNode]). With a local node in use (the
///   built-in one, any loopback or LAN node, `net/local_address.dart`) refresh, Recheck balance
///   and the HTTP listener run as well.
///
/// Any stored mode other than Tor only and Offline runs as Standard ([netModeOf]).
///
/// The method switches (Settings › Transactions, `PaymentPrefs`) are read here too, so Offline
/// and "off" are one gate: [netBlockFor] with `epicbox:` or `offered:` for the screens,
/// [NetGate.checkEpicbox] and [NetGate.checkMethod] for the code that connects. Epicbox off:
/// no relay connection, no listener, no Epicbox sends or invoices, no push. Link · HTTP or
/// Link · Tor off: no listener of that kind, no address on Receive, no send to such an
/// address. QR Payment and File Transfer off: not offered.
library;

import 'dart:async';

import 'advanced.dart';
import 'payment_prefs.dart';
import 'tor_routes.dart';

export 'net/local_address.dart' show isLocalAddressUrl;

/// Why network actions (Send over Epicbox/Direct, Recheck balance, starting a listener, checking a node) can't run now.
enum NetBlock {
  /// They can run.
  none,

  /// The Offline mode: nothing reaches the network until the mode changes.
  offline,

  /// Tor only, and tor is starting or failed: they wait for tor and never go direct.
  waitingForTor,

  /// Epicbox is off in Settings › Transactions: nothing over Epicbox until it is on again.
  epicboxOff,

  /// The method the action needs is off in Settings › Transactions (Link · HTTP, Link · Tor,
  /// QR Payment or File Transfer; Epicbox is [epicboxOff]). The screen names it.
  methodOff,
}

/// Why network actions can't run in [mode] with the Tor switch [tor] (`tor_view.dart`'s
/// `torStateOf` on the desktop, `phoneTorState` on the phone). [localNode]: the action reaches
/// only the node (Recheck balance, posting) or local addresses (a Direct send, which refuses a
/// non-local one itself), and the node in use is local ([isLocalAddressUrl]): Offline lets it run.
/// [epicbox]: false for an action over Epicbox while the Epicbox switch is off
/// ([NetBlock.epicboxOff]); [offered]: false for an action by another method whose switch
/// is off ([NetBlock.methodOff]). The mode's own answer comes first.
NetBlock netBlockFor(NetworkMode mode, TorState tor, {bool localNode = false, bool epicbox = true, bool offered = true}) =>
    switch (mode) {
      NetworkMode.offline => localNode ? NetBlock.none : NetBlock.offline,
      NetworkMode.torOnly when tor != TorState.on => NetBlock.waitingForTor,
      _ when !epicbox => NetBlock.epicboxOff,
      _ => offered ? NetBlock.none : NetBlock.methodOff,
    };

/// The mode the runtime follows for a stored one: Tor only and Offline as they are, anything
/// else (an older build's choice included) as Standard.
NetworkMode netModeOf(NetworkMode? mode) => switch (mode) {
  NetworkMode.torOnly => NetworkMode.torOnly,
  NetworkMode.offline => NetworkMode.offline,
  _ => NetworkMode.standard,
};

/// The transaction file and QR Payment methods use the node in use while Offline: LEPIC asks
/// it for its tip before it creates a send file, signs a received one or finalizes one (and
/// finalizing also posts). True when the node is not [localNode], so the screen says so (a
/// warning, never a block); false in the other modes, where the node is used anyway.
bool offlineUsesNode(NetworkMode mode, {required bool localNode}) =>
    netModeOf(mode) == NetworkMode.offline && !localNode;

/// What holds a payment that reaches only the node (making, signing, finalizing and posting a
/// transaction file or a QR Payment): Offline lets it use the node in use, local or not; Tor
/// only still waits for tor.
NetBlock paymentBlockFor(NetworkMode mode, TorState tor) => netBlockFor(mode, tor, localNode: true);

/// The Tor switch can't be turned off: Tor only keeps it on.
bool torSwitchLocked(NetworkMode mode) => netModeOf(mode) == NetworkMode.torOnly;

/// The Tor switch does nothing: Offline starts no tor.
bool torSwitchDisabled(NetworkMode mode) => netModeOf(mode) == NetworkMode.offline;

/// Push notifications register with the Epicbox relay over the clearnet: off in Tor only and
/// Offline, and with the Epicbox switch off ([epicbox]).
bool pushAllowed(NetworkMode mode, {bool epicbox = true}) => netModeOf(mode) == NetworkMode.standard && epicbox;

/// A network action refused by the mode: [what] is for the log, [mode] says why (Offline, or
/// Tor only refusing a clearnet connection). [notLocal]: Offline refused a Direct send to an
/// address that is not local ("Offline: only local addresses."). [epicboxOff]: the Epicbox
/// switch refused an Epicbox action (the mode is then whatever it is); [methodOff] names the
/// method whose switch refused it (Epicbox included).
class NetBlocked implements Exception {
  const NetBlocked(this.mode, this.what, {this.notLocal = false, this.epicboxOff = false, this.methodOff});

  final NetworkMode mode;
  final String what;
  final bool notLocal;
  final bool epicboxOff;
  final MethodKind? methodOff;

  @override
  String toString() => methodOff != null ? 'NetBlocked(${methodOff!.name} off): $what' : 'NetBlocked(${mode.name}): $what';
}

/// The current mode for code without a Riverpod ref (the app's own HTTP, the wallet adapters).
/// The phone's settings and the desktop's store set it at launch, before any request, and on
/// every change; [changes] lets a long-lived owner (the desktop wallet) resume or stop.
abstract final class NetGate {
  static NetworkMode _mode = NetworkMode.standard;
  static PaymentPrefs _payments = PaymentPrefs.defaults;
  static final StreamController<NetworkMode> _changes = StreamController.broadcast(sync: true);

  static NetworkMode get mode => _mode;

  static bool get offline => _mode == NetworkMode.offline;

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

  /// Nothing over Epicbox now: Offline, or the Epicbox switch is off.
  static bool get epicboxOff => offline || !epicbox;

  static bool get torOnly => _mode == NetworkMode.torOnly;

  /// The experimental switches (Settings › Advanced › Experimental), for the wallet adapters:
  /// off, nothing collects the pairing or contact mailboxes ([pairing]) or drains invoices
  /// ([invoices]). The phone's settings and the desktop's store set them at launch, before a
  /// wallet opens, and on every change; on until then, so a core test without settings pairs.
  static bool _pairing = true;
  static bool _invoices = true;
  static bool _linkedDevices = true;

  static bool get pairing => _pairing;

  static bool get invoices => _invoices && _pairing;

  /// Linked devices: their private pairings are collected and posted to ([linkedDevices]), with
  /// the contact mailboxes left alone while [pairing] is off.
  static bool get linkedDevices => _linkedDevices;

  static void setExperimental(AdvancedPrefs prefs) {
    _pairing = prefs.pairingOn;
    _invoices = prefs.invoicesOn;
    _linkedDevices = prefs.linkedDevicesOn;
  }

  /// Every change of [mode], after it is set.
  static Stream<NetworkMode> get changes => _changes.stream;

  static void set(NetworkMode? mode) {
    final next = netModeOf(mode);
    if (next == _mode) return;
    _mode = next;
    _changes.add(next);
  }

  /// Throws [NetBlocked] in Offline: for every call that would reach the network. [local]: the
  /// call reaches only this computer or the local network (a local node), which Offline allows.
  static void check(String what, {bool local = false}) {
    if (offline && !local) throw NetBlocked(NetworkMode.offline, what);
  }

  /// Throws [NetBlocked] for a call over Epicbox (the listener, a send, an invoice, push):
  /// in Offline as [check], and with the Epicbox switch off with `epicboxOff`.
  static void checkEpicbox(String what) {
    check(what);
    if (!epicbox) throw NetBlocked(_mode, what, epicboxOff: true, methodOff: MethodKind.epicbox);
  }

  /// Throws [NetBlocked] for an action by method [m] (a listener, a send, an address handed
  /// out): in Offline as [check] (with [local] for a Link send to a local address), and with
  /// the method's switch off with `methodOff`.
  static void checkMethod(MethodKind m, String what, {bool local = false}) {
    check(what, local: local);
    if (!offers(m)) throw NetBlocked(_mode, what, epicboxOff: m == MethodKind.epicbox, methodOff: m);
  }
}
