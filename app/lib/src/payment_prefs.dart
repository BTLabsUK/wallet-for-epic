// SPDX-License-Identifier: Apache-2.0
/// Settings › Transactions: which payment methods Send and Receive offer, and the one Send
/// starts on. One model for the phone (`AppSettings.payments`) and the desktop
/// (`DeskSettings.payments`), so the page reads the same on both.
///
/// One switch per method ([MethodKind], `payment_method.dart`), grouped by family: Epicbox;
/// Link · HTTP and Link · Tor; Direct · QR Payment and Direct · File Transfer; and epic1
/// ([epic1], no [MethodKind]: an epic1 link is paid as a link, never picked as a route). Off means off
/// for each: no listener, no address on Receive, no option on Send (a payment half-way keeps
/// its method, the screens say so). At least one stays on ([canTurnOff]). Epicbox off is the
/// one setting behind every Epicbox connection (`network_gate.dart`, [NetGate]); the others
/// reach the gate the same way ([NetGate.offers]).
///
/// Defaults: Epicbox on everywhere. The desktop offers File Transfer (an everyday method) and
/// never QR Payment; the phone offers QR Payment and keeps File Transfer behind Advanced (a
/// phone that had it keeps it). Link · HTTP and Link · Tor are off until chosen: HTTP receiving
/// needs a listener (on the phone it reaches this network only), Tor receiving needs Tor.
/// epic1 is on everywhere, and a value stored before its switch existed reads as on.
library;

import 'payment_method.dart';
import 'tor_build.dart';

export 'payment_method.dart';

class PaymentPrefs {
  const PaymentPrefs({
    this.epicbox = true,
    this.linkHttp = false,
    bool linkTor = false,
    this.directQr = true,
    this.directFile = true,
    this.epic1 = true,
    this.defaultMethod = MethodKind.epicbox,
  }) : linkTor = torBuilt && linkTor;

  /// Epicbox is on: the listener runs, Send and Receive offer it, invoices and push work. Off
  /// is the one setting behind every Epicbox connection (`network_gate.dart`, [NetGate]).
  final bool epicbox;

  /// Link · HTTP: the HTTP listener runs (this network only on a phone) and Send offers
  /// http(s) addresses.
  final bool linkHttp;

  /// Link · Tor: the onion address is handed out while Tor runs and Send offers onions. Always
  /// off in the build without Tor ([torBuilt]), whatever was stored.
  final bool linkTor;

  /// Direct · QR Payment (the phone only; the desktop never reads it).
  final bool directQr;

  /// Direct · File Transfer.
  final bool directFile;

  /// epic1: epic1 links, in-person codes and epic1 files are paid and opened, and Receive
  /// offers an epic1 link among its other ways. It is no route of a classic payment, so it is
  /// not a [MethodKind] and does not count for [canTurnOff].
  final bool epic1;

  /// The method Send starts on; the first one on when the chosen one is off ([startMethod]).
  final MethodKind defaultMethod;

  /// The desktop's: File Transfer on, Link off, QR Payment never (the phone's method).
  static const PaymentPrefs defaults = PaymentPrefs(directQr: false);

  /// A new phone's: QR Payment on, File Transfer off (a switch behind Advanced), Link off.
  static const PaymentPrefs phoneDefaults = PaymentPrefs(directFile: false);

  bool offers(MethodKind m) => switch (m) {
    MethodKind.epicbox => epicbox,
    MethodKind.linkHttp => linkHttp,
    MethodKind.linkTor => linkTor,
    MethodKind.directQr => directQr,
    MethodKind.directFile => directFile,
  };

  /// Any method of [f] is on.
  bool offersFamily(MethodFamily f) => MethodKind.values.any((m) => m.family == f && offers(m));

  /// The methods that are on, in Epicbox, Link, Direct order.
  List<MethodKind> get on => [for (final m in MethodKind.values) if (offers(m)) m];

  /// [m] may be turned off: another method stays on. The last one on stays (Send and
  /// Receive always have a way; the screens say why).
  bool canTurnOff(MethodKind m) => !offers(m) || on.length > 1;

  /// The method Send opens on: the chosen one when it is on, else the first on in Epicbox,
  /// Link · HTTP, Link · Tor, QR Payment, File Transfer order; Epicbox when nothing is (Send
  /// then says it is off). A Link choice counts for the family: the address picks HTTP or Tor.
  MethodKind get startMethod {
    if (offers(defaultMethod)) return defaultMethod;
    if (defaultMethod.family == MethodFamily.link) {
      final link = on.where((m) => m.family == MethodFamily.link).firstOrNull;
      if (link != null) return link;
    }
    return on.firstOrNull ?? MethodKind.epicbox;
  }

  /// [m] turned [on] or off.
  PaymentPrefs withMethod(MethodKind m, bool on) => switch (m) {
    MethodKind.epicbox => copyWith(epicbox: on),
    MethodKind.linkHttp => copyWith(linkHttp: on),
    MethodKind.linkTor => copyWith(linkTor: on),
    MethodKind.directQr => copyWith(directQr: on),
    MethodKind.directFile => copyWith(directFile: on),
  };

  PaymentPrefs copyWith({
    bool? epicbox,
    bool? linkHttp,
    bool? linkTor,
    bool? directQr,
    bool? directFile,
    bool? epic1,
    MethodKind? defaultMethod,
  }) => PaymentPrefs(
    epicbox: epicbox ?? this.epicbox,
    linkHttp: linkHttp ?? this.linkHttp,
    linkTor: linkTor ?? this.linkTor,
    directQr: directQr ?? this.directQr,
    directFile: directFile ?? this.directFile,
    epic1: epic1 ?? this.epic1,
    defaultMethod: defaultMethod ?? this.defaultMethod,
  );

  /// `v2,http,tor,file|epicbox`: the methods on besides Epicbox and QR, then the default. QR
  /// Epicbox and epic1 are on unless `noqr`, `noepicbox` or `noepic1` stands among them, so a
  /// value stored before any of these switches existed reads as on. `v2` marks the per-method form; a value
  /// without it comes from the one Link switch ([decode]).
  String encode() =>
      '${['v2', if (linkHttp) 'http', if (linkTor) 'tor', if (directFile) 'file', if (!directQr) 'noqr', if (!epicbox) 'noepicbox', if (!epic1) 'noepic1'].join(',')}|${defaultMethod.name}';

  /// [raw] as stored; null (never saved) is the defaults ([phoneDefaults] on a [phone]), with
  /// Link on when [legacyDirect] (the Advanced page's "Direct receiving" switch before
  /// 26.10.13 held it). A value from the one Link switch (`direct`, before 26.10.16) turns on
  /// both Link methods: that switch sent to web and onion addresses alike (HTTP sending stays,
  /// as asked), and showed the HTTP card and the Tor address.
  static PaymentPrefs decode(String? raw, {bool legacyDirect = false, bool phone = false}) {
    if (raw == null || raw.isEmpty) {
      return _legacyLink(phone ? phoneDefaults : defaults, legacyDirect, phone: phone);
    }
    final parts = raw.split('|');
    final on = parts.first.split(',').toSet();
    final v2 = on.contains('v2');
    final prefs = PaymentPrefs(
      epicbox: !on.contains('noepicbox'),
      linkHttp: on.contains('http'),
      linkTor: on.contains('tor'),
      directFile: on.contains('file'),
      directQr: !on.contains('noqr'),
      epic1: !on.contains('noepic1'),
      defaultMethod: parts.length > 1 ? _method(parts[1]) : MethodKind.epicbox,
    );
    return v2 ? prefs : _legacyLink(prefs, on.contains('direct'), phone: phone);
  }

  static PaymentPrefs _legacyLink(PaymentPrefs p, bool direct, {required bool phone}) =>
      direct ? p.copyWith(linkTor: true, linkHttp: true) : p;

  /// A stored method name: today's, or the names before the split (`direct` was Link, `qr`
  /// and `file` the Direct methods).
  static MethodKind _method(String name) => switch (name) {
    'direct' => MethodKind.linkHttp,
    'qr' => MethodKind.directQr,
    'file' => MethodKind.directFile,
    _ => MethodKind.values.where((m) => m.name == name).firstOrNull ?? MethodKind.epicbox,
  };

  Map<String, Object?> toJson() => {
    'epicbox': epicbox,
    'linkHttp': linkHttp,
    'linkTor': linkTor,
    'directQr': directQr,
    'directFile': directFile,
    'epic1': epic1,
    'default': defaultMethod.name,
  };

  /// The desktop's stored form; the keys before the split (`direct`, `file`, `qr`) read as
  /// [decode] reads them, QR Payment off unless saved on (the desktop never offers it).
  static PaymentPrefs fromJson(Object? j, {bool legacyDirect = false}) {
    if (j is! Map) return _legacyLink(defaults, legacyDirect, phone: false);
    bool flag(String key, bool fallback) => j[key] is bool ? j[key] as bool : fallback;
    final legacy = !j.containsKey('linkHttp') && !j.containsKey('linkTor');
    final prefs = PaymentPrefs(
      epicbox: flag('epicbox', true),
      linkHttp: flag('linkHttp', false),
      linkTor: flag('linkTor', false),
      directQr: flag('directQr', flag('qr', false)),
      directFile: flag('directFile', flag('file', true)),
      epic1: flag('epic1', true),
      defaultMethod: _method('${j['default']}'),
    );
    return legacy ? _legacyLink(prefs, flag('direct', legacyDirect), phone: false) : prefs;
  }

  @override
  bool operator ==(Object other) =>
      other is PaymentPrefs &&
      other.epicbox == epicbox &&
      other.linkHttp == linkHttp &&
      other.linkTor == linkTor &&
      other.directQr == directQr &&
      other.directFile == directFile &&
      other.epic1 == epic1 &&
      other.defaultMethod == defaultMethod;

  @override
  int get hashCode => Object.hash(epicbox, linkHttp, linkTor, directQr, directFile, epic1, defaultMethod);

  @override
  String toString() => 'PaymentPrefs(${encode()})';
}
