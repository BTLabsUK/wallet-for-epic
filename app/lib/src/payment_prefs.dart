/// Settings › Transactions: which payment methods Send and Receive offer, and the one Send
/// starts on. One model for the phone (`AppSettings.payments`) and the desktop
/// (`DeskSettings.payments`), so the page reads the same on both.
///
/// Epicbox is always offered. On the desktop File is offered by default (an everyday method)
/// and QR never is. On the phone QR is offered by default and File is not (a switch behind
/// Advanced; a phone that had File keeps it). Direct is not offered by default (it needs Tor on
/// the phone, an HTTP listener on the desktop). A method in use is never hidden mid-way: a
/// pasted onion or http address still picks Direct for that send.
library;

/// A way to pay or be paid. [qr] is the phone's: two phones side by side, an animated QR code.
enum PayMethod { epicbox, direct, qr, file }

class PaymentPrefs {
  const PaymentPrefs({
    this.direct = false,
    this.file = true,
    this.qr = true,
    this.defaultMethod = PayMethod.epicbox,
  });

  /// Direct is offered on Send and Receive.
  final bool direct;

  /// File is offered on Send and Receive.
  final bool file;

  /// QR is offered on Send and Receive (the phone only; the desktop never reads it).
  final bool qr;

  /// The method Send starts on; Epicbox when the chosen one is not offered ([startMethod]).
  final PayMethod defaultMethod;

  /// The desktop's: File on, Direct off.
  static const PaymentPrefs defaults = PaymentPrefs();

  /// A new phone's: QR on, File off (a switch behind Advanced), Direct off.
  static const PaymentPrefs phoneDefaults = PaymentPrefs(file: false);

  bool offers(PayMethod m) => switch (m) {
    PayMethod.epicbox => true,
    PayMethod.direct => direct,
    PayMethod.qr => qr,
    PayMethod.file => file,
  };

  /// The method Send opens on.
  PayMethod get startMethod => offers(defaultMethod) ? defaultMethod : PayMethod.epicbox;

  PaymentPrefs copyWith({bool? direct, bool? file, bool? qr, PayMethod? defaultMethod}) => PaymentPrefs(
    direct: direct ?? this.direct,
    file: file ?? this.file,
    qr: qr ?? this.qr,
    defaultMethod: defaultMethod ?? this.defaultMethod,
  );

  /// `direct,file|epicbox`: the offered methods besides Epicbox, then the default. QR is on
  /// unless `noqr` stands among them, so a value stored before QR existed reads as on.
  String encode() =>
      '${[if (direct) 'direct', if (file) 'file', if (!qr) 'noqr'].join(',')}|${defaultMethod.name}';

  /// [raw] as stored; null (never saved) is the defaults ([phoneDefaults] on a [phone]), with
  /// Direct on when [legacyDirect] (the Advanced page's "Direct receiving" switch before
  /// 26.10.13 held it).
  static PaymentPrefs decode(String? raw, {bool legacyDirect = false, bool phone = false}) {
    if (raw == null || raw.isEmpty) {
      return (phone ? phoneDefaults : defaults).copyWith(direct: legacyDirect);
    }
    final parts = raw.split('|');
    final on = parts.first.split(',').toSet();
    return PaymentPrefs(
      direct: on.contains('direct'),
      file: on.contains('file'),
      qr: !on.contains('noqr'),
      defaultMethod: parts.length > 1
          ? PayMethod.values.where((m) => m.name == parts[1]).firstOrNull ?? PayMethod.epicbox
          : PayMethod.epicbox,
    );
  }

  Map<String, Object?> toJson() => {'direct': direct, 'file': file, 'qr': qr, 'default': defaultMethod.name};

  static PaymentPrefs fromJson(Object? j, {bool legacyDirect = false}) {
    if (j is! Map) return PaymentPrefs(direct: legacyDirect);
    final d = j['direct'], f = j['file'], q = j['qr'], m = j['default'];
    return PaymentPrefs(
      direct: d is bool ? d : legacyDirect,
      file: f is bool ? f : true,
      qr: q is bool ? q : true,
      defaultMethod: PayMethod.values.where((x) => x.name == m).firstOrNull ?? PayMethod.epicbox,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PaymentPrefs &&
      other.direct == direct &&
      other.file == file &&
      other.qr == qr &&
      other.defaultMethod == defaultMethod;

  @override
  int get hashCode => Object.hash(direct, file, qr, defaultMethod);
}
