/// Settings › Transactions: which payment methods Send and Receive offer, and the one Send
/// starts on. One model for the phone (`AppSettings.payments`) and the desktop
/// (`DeskSettings.payments`), so the page reads the same on both.
///
/// Epicbox is always offered. File is offered by default (an everyday method); Direct is not
/// (it needs Tor on the phone, an HTTP listener on the desktop). A method in use is never hidden
/// mid-way: a pasted onion or http address still picks Direct for that send.
library;

/// A way to pay or be paid.
enum PayMethod { epicbox, direct, file }

class PaymentPrefs {
  const PaymentPrefs({this.direct = false, this.file = true, this.defaultMethod = PayMethod.epicbox});

  /// Direct is offered on Send and Receive.
  final bool direct;

  /// File is offered on Send and Receive.
  final bool file;

  /// The method Send starts on; Epicbox when the chosen one is not offered ([startMethod]).
  final PayMethod defaultMethod;

  static const PaymentPrefs defaults = PaymentPrefs();

  bool offers(PayMethod m) => switch (m) {
    PayMethod.epicbox => true,
    PayMethod.direct => direct,
    PayMethod.file => file,
  };

  /// The method Send opens on.
  PayMethod get startMethod => offers(defaultMethod) ? defaultMethod : PayMethod.epicbox;

  PaymentPrefs copyWith({bool? direct, bool? file, PayMethod? defaultMethod}) => PaymentPrefs(
    direct: direct ?? this.direct,
    file: file ?? this.file,
    defaultMethod: defaultMethod ?? this.defaultMethod,
  );

  /// `direct,file|epicbox`: the offered methods besides Epicbox, then the default.
  String encode() => '${[if (direct) 'direct', if (file) 'file'].join(',')}|${defaultMethod.name}';

  /// [raw] as stored; null (never saved) is the defaults, with Direct on when [legacyDirect]
  /// (the Advanced page's "Direct receiving" switch before 26.10.13 held it).
  static PaymentPrefs decode(String? raw, {bool legacyDirect = false}) {
    if (raw == null || raw.isEmpty) return PaymentPrefs(direct: legacyDirect);
    final parts = raw.split('|');
    final on = parts.first.split(',').toSet();
    return PaymentPrefs(
      direct: on.contains('direct'),
      file: on.contains('file'),
      defaultMethod: parts.length > 1
          ? PayMethod.values.where((m) => m.name == parts[1]).firstOrNull ?? PayMethod.epicbox
          : PayMethod.epicbox,
    );
  }

  Map<String, Object?> toJson() => {'direct': direct, 'file': file, 'default': defaultMethod.name};

  static PaymentPrefs fromJson(Object? j, {bool legacyDirect = false}) {
    if (j is! Map) return PaymentPrefs(direct: legacyDirect);
    final d = j['direct'], f = j['file'], m = j['default'];
    return PaymentPrefs(
      direct: d is bool ? d : legacyDirect,
      file: f is bool ? f : true,
      defaultMethod: PayMethod.values.where((x) => x.name == m).firstOrNull ?? PayMethod.epicbox,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PaymentPrefs && other.direct == direct && other.file == file && other.defaultMethod == defaultMethod;

  @override
  int get hashCode => Object.hash(direct, file, defaultMethod);
}
