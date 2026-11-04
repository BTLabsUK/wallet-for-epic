// SPDX-License-Identifier: Apache-2.0
/// The directory wire format (docs/design/directory-wire.md): the TLV codec of RFC 0002 3.3,
/// the listing card, the payment request and the directory payloads. Decoding checks structure
/// only (errors `checksum` and `malformed`); [verify.dart] checks network, signatures, expiry
/// and the rest, in the spec's order. Pure Dart: no I/O, no wallet.
library;

import 'dart:typed_data';

import 'base58.dart';

/// The named errors of the spec, as the vectors write them (`for_other` is [forOther]).
enum DirectoryError {
  checksum,
  malformed,
  network,
  signature,
  expired,
  forOther,
  bind,
  dkey;

  /// The name in the spec and the vectors.
  String get wireName => this == forOther ? 'for_other' : name;
}

class DirectoryException implements Exception {
  const DirectoryException(this.error);

  final DirectoryError error;

  @override
  String toString() => 'DirectoryException: ${error.wireName}';
}

Never _fail(DirectoryError e) => throw DirectoryException(e);

Never _malformed() => _fail(DirectoryError.malformed);

String toHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

Uint8List fromHex(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2) int.parse(hex.substring(i, i + 2), radix: 16),
]);

/// An unknown tag from `0x80` to `0xFE`: skipped by the decoder and covered by the signature.
class ExtraField {
  const ExtraField(this.tag, this.value);

  final int tag;
  final Uint8List value;
}

/// Tag of the signature field.
const int _sigTag = 0xff;

enum _Kind { u, b, ascii, label, card }

class _Field {
  const _Field(this.tag, this.name, this.kind, {this.size = 0, this.optional = false});

  final int tag;
  final String name;
  final _Kind kind;

  /// Bytes of a `u` or `b` field; for an `ascii` field the longest text.
  final int size;
  final bool optional;
}

const List<_Field> _cardSchema = [
  _Field(1, 'format', _Kind.u, size: 1),
  _Field(2, 'net', _Kind.u, size: 1),
  _Field(3, 'address', _Kind.ascii, size: 128),
  _Field(4, 'dkey', _Kind.b, size: 33),
  _Field(5, 'handle', _Kind.b, size: 16),
  _Field(6, 'seq', _Kind.u, size: 4),
  _Field(7, 'issued', _Kind.u, size: 8),
];

const List<_Field> _payreqSchema = [
  _Field(1, 'format', _Kind.u, size: 1),
  _Field(2, 'net', _Kind.u, size: 1),
  _Field(3, 'card', _Kind.card),
  _Field(4, 'amount', _Kind.u, size: 8),
  _Field(5, 'reqid', _Kind.b, size: 16),
  _Field(6, 'expires', _Kind.u, size: 8),
  _Field(7, 'kind', _Kind.u, size: 1),
  _Field(8, 'label', _Kind.label, optional: true),
  _Field(9, 'for', _Kind.b, size: 33, optional: true),
];

/// Payload type -> (fields after `01`, signed).
const Map<int, (List<_Field>, bool)> _payloadSchemas = {
  1: (
    [
      _Field(2, 'net', _Kind.u, size: 1),
      _Field(3, 'dkey', _Kind.b, size: 33),
      _Field(4, 'handle', _Kind.b, size: 16),
      _Field(5, 'bind', _Kind.b, size: 4),
      _Field(6, 'issued', _Kind.u, size: 8),
      _Field(7, 'flags', _Kind.u, size: 1, optional: true),
      _Field(8, 'label', _Kind.label, optional: true),
    ],
    true,
  ),
  2: ([_Field(2, 'card', _Kind.card)], false),
  3: (
    [
      _Field(2, 'net', _Kind.u, size: 1),
      _Field(3, 'address', _Kind.ascii, size: 128),
      _Field(4, 'dkey', _Kind.b, size: 33),
      _Field(5, 'handle', _Kind.b, size: 16),
      _Field(6, 'issued', _Kind.u, size: 8),
    ],
    true,
  ),
  4: (
    [
      _Field(2, 'dkey', _Kind.b, size: 33),
      _Field(3, 'handle', _Kind.b, size: 16),
      _Field(4, 'issued', _Kind.u, size: 8),
    ],
    false,
  ),
  5: (
    [
      _Field(2, 'reqid', _Kind.b, size: 16),
      _Field(3, 'stage', _Kind.u, size: 1),
      _Field(4, 'amount', _Kind.u, size: 8),
      _Field(5, 'at', _Kind.u, size: 8),
    ],
    false,
  ),
  6: (
    [
      _Field(2, 'net', _Kind.u, size: 1),
      _Field(3, 'old_address', _Kind.ascii, size: 128),
      _Field(4, 'card', _Kind.card),
    ],
    true,
  ),
};

/// The fields of one record: values by the names of the spec's tables. A `u` field of 8 bytes is
/// a [BigInt], one of 1 or 4 bytes an `int`, a `b` field [Uint8List], an `ascii` field a
/// `String`, a `label` a `String?` and a `card` a [ListingCard].
class _Decoded {
  _Decoded(this.fields, this.extra, this.signature, this.signedBytes);

  final Map<String, Object?> fields;
  final List<ExtraField> extra;
  final Uint8List? signature;

  /// Every byte before the `FF` field, exactly as read: what the signature covers.
  final Uint8List signedBytes;
}

/// [(tag, value, offset)] with strictly increasing tags and no bytes after the last field.
List<(int, Uint8List, int)> _parseTlv(Uint8List raw) {
  final out = <(int, Uint8List, int)>[];
  var i = 0;
  var last = -1;
  while (i < raw.length) {
    if (i + 3 > raw.length) _malformed();
    final tag = raw[i];
    final n = raw[i + 1] << 8 | raw[i + 2];
    if (tag <= last || i + 3 + n > raw.length) _malformed();
    out.add((tag, Uint8List.sublistView(raw, i + 3, i + 3 + n), i));
    last = tag;
    i += 3 + n;
  }
  return out;
}

BigInt _bigOf(Uint8List v) {
  var n = BigInt.zero;
  for (final b in v) {
    n = (n << 8) | BigInt.from(b);
  }
  return n;
}

int _intOf(Uint8List v) {
  var n = 0;
  for (final b in v) {
    n = (n << 8) | b;
  }
  return n;
}

bool _labelOk(Uint8List v) {
  if (v.length < 2 || v.length > 33 || v[0] != 0x40) return false;
  return v.skip(1).every(
    (c) =>
        (c >= 0x30 && c <= 0x39) ||
        (c >= 0x41 && c <= 0x5a) ||
        (c >= 0x61 && c <= 0x7a) ||
        c == 0x5f,
  );
}

_Decoded _decodeStruct(Uint8List raw, List<_Field> schema, bool signed, {int? lead}) {
  final byTag = {for (final f in schema) f.tag: f};
  final fields = <String, Object?>{};
  final extra = <ExtraField>[];
  Uint8List? sig;
  var sigAt = raw.length;
  for (final (tag, val, start) in _parseTlv(raw)) {
    final f = byTag[tag];
    if (tag == _sigTag) {
      if (!signed || val.length < 8 || val.length > 72) _malformed();
      sig = val;
      sigAt = start;
    } else if (f != null) {
      switch (f.kind) {
        case _Kind.u:
          if (val.length != f.size) _malformed();
          fields[f.name] = f.size == 8 ? _bigOf(val) : _intOf(val);
        case _Kind.b:
          if (val.length != f.size) _malformed();
          fields[f.name] = Uint8List.fromList(val);
        case _Kind.ascii:
          if (val.isEmpty || val.length > f.size || val.any((c) => c >= 0x80)) _malformed();
          fields[f.name] = String.fromCharCodes(val);
        case _Kind.label:
          // A label that does not fit the rule is dropped, not an error.
          fields[f.name] = _labelOk(val) ? String.fromCharCodes(val) : null;
        case _Kind.card:
          fields[f.name] = ListingCard.decode(Uint8List.fromList(val));
      }
    } else if (tag == 1 && lead != null) {
      fields['type'] = lead;
    } else if (tag >= 0x80) {
      extra.add(ExtraField(tag, Uint8List.fromList(val)));
    } else {
      _malformed();
    }
  }
  if (signed && sig == null) _malformed();
  if (schema.any((f) => !f.optional && !fields.containsKey(f.name))) _malformed();
  return _Decoded(
    fields,
    extra,
    sig == null ? null : Uint8List.fromList(sig),
    Uint8List.fromList(raw.sublist(0, sigAt)),
  );
}

Uint8List _encodeStruct(
  Map<String, Object?> fields,
  List<ExtraField> extra,
  Uint8List? signature,
  List<_Field> schema, {
  int? lead,
}) {
  final items = <(int, List<int>)>[
    if (lead != null) (1, [lead]),
  ];
  for (final f in schema) {
    final v = fields[f.name];
    if (v == null) continue;
    items.add((
      f.tag,
      switch (f.kind) {
        _Kind.u => _beBytes(v is BigInt ? v : BigInt.from(v as int), f.size),
        _Kind.b => v as Uint8List,
        _Kind.ascii || _Kind.label => (v as String).codeUnits,
        _Kind.card => (v as ListingCard).toBytes(),
      },
    ));
  }
  items.addAll([for (final e in extra) (e.tag, e.value)]);
  items.sort((a, b) => a.$1.compareTo(b.$1));
  if (signature != null) items.add((_sigTag, signature));
  final out = BytesBuilder();
  for (final (tag, value) in items) {
    out.add([tag, value.length >> 8, value.length & 0xff]);
    out.add(value);
  }
  return out.toBytes();
}

List<int> _beBytes(BigInt v, int size) => [
  for (var i = size - 1; i >= 0; i--) ((v >> (8 * i)) & BigInt.from(0xff)).toInt(),
];

/// A parsed record: its fields, the unknown tags it carries and its signature.
abstract class WireRecord {
  WireRecord._(_Decoded d) : _d = d;

  final _Decoded _d;

  /// The unknown `80`-`FE` tags, in order.
  List<ExtraField> get extra => _d.extra;

  /// The DER signature (`FF`), null for an unsigned record.
  Uint8List? get signature => _d.signature;

  /// Every byte before the `FF` field as it was read: the message that was signed. Never
  /// rebuilt from the fields, since a dropped label is still covered.
  Uint8List get signedBytes => _d.signedBytes;

  int _int(String name) => _d.fields[name]! as int;
  BigInt _big(String name) => _d.fields[name]! as BigInt;
  Uint8List _bytes(String name) => _d.fields[name]! as Uint8List;
  String _text(String name) => _d.fields[name]! as String;

  List<_Field> get _schema;
  int? get _lead => null;

  /// The record as bytes, re-encoded from its fields.
  Uint8List toBytes() => _encodeStruct(_d.fields, _d.extra, _d.signature, _schema, lead: _lead);

  /// The fields as the test vectors write them (hex strings, JSON numbers, nested records),
  /// for tests and logs. A u64 above 2^63 does not survive here.
  Map<String, Object?> toFields() {
    Object? plain(Object? v) => switch (v) {
      Uint8List() => toHex(v),
      BigInt() => v.toInt(),
      WireRecord() => v.toFields(),
      _ => v,
    };
    return {
      for (final e in _d.fields.entries) e.key: plain(e.value),
      if (_d.extra.isNotEmpty)
        'extra': [for (final e in _d.extra) {'tag': e.tag, 'hex': toHex(e.value)}],
      if (_d.signature != null) 'sig': toHex(_d.signature!),
    };
  }
}

bool _compressed(Uint8List key) => key[0] == 2 || key[0] == 3;

/// `key@relay[:port]`: the key text and its network, or null when the text is not that form.
({String keyText, int net, Uint8List key})? parseListingAddress(String text) {
  final at = text.indexOf('@');
  if (at <= 0) return null;
  final relay = text.substring(at + 1);
  final colon = relay.lastIndexOf(':');
  final host = colon < 0 ? relay : relay.substring(0, colon);
  if (!RegExp(r'^[A-Za-z0-9.\-]+$').hasMatch(host)) return null;
  if (colon >= 0) {
    final port = relay.substring(colon + 1);
    if (!RegExp(r'^[0-9]{1,5}$').hasMatch(port)) return null;
    final n = int.parse(port);
    if (n < 1 || n > 65535) return null;
  }
  final keyText = text.substring(0, at);
  final parsed = parseEpicboxKeyText(keyText);
  if (parsed == null) return null;
  return (keyText: keyText, net: parsed.$1, key: parsed.$2);
}

/// A listing card (domain `epic-listing/1`, signed by the key in its address).
class ListingCard extends WireRecord {
  ListingCard._(super.d) : super._();

  /// Reads a card. Throws [DirectoryException] `malformed`.
  factory ListingCard.decode(Uint8List raw) {
    final d = _decodeStruct(raw, _cardSchema, true);
    final f = d.fields;
    if (f['format'] != 1 || (f['net'] != 0 && f['net'] != 1) || !_compressed(f['dkey']! as Uint8List)) {
      _malformed();
    }
    if (parseListingAddress(f['address']! as String) == null) _malformed();
    return ListingCard._(d);
  }

  @override
  List<_Field> get _schema => _cardSchema;

  int get format => _int('format');
  int get net => _int('net');

  /// `key@relay[:port]`.
  String get address => _text('address');

  /// The directory this card is for (33 bytes).
  Uint8List get dkey => _bytes('dkey');
  Uint8List get handle => _bytes('handle');
  int get seq => _int('seq');
  BigInt get issued => _big('issued');

  /// The key text, network and key of [address].
  ({String keyText, int net, Uint8List key}) get listing => parseListingAddress(address)!;

  /// The listing key (33 bytes).
  Uint8List get listingKey => listing.key;
}

/// The two kinds of a payment request.
const int kindPayerMade = 1;
const int kindPayeeRequest = 2;

/// A payment request (domain `epic-payreq/1`, signed by the card's `dkey`).
class Payreq extends WireRecord {
  Payreq._(super.d) : super._();

  /// Reads a request. Throws `malformed`.
  factory Payreq.decode(Uint8List raw) {
    final d = _decodeStruct(raw, _payreqSchema, true);
    final f = d.fields;
    if (f['format'] != 1 ||
        (f['kind'] != kindPayerMade && f['kind'] != kindPayeeRequest) ||
        (f['net'] != 0 && f['net'] != 1) ||
        (f['for'] != null && !_compressed(f['for']! as Uint8List))) {
      _malformed();
    }
    return Payreq._(d);
  }

  /// Reads the text form of a link: `epiccash://pay/1/<p>` or `https://<any>/p#1/<p>`. Throws
  /// `checksum` or `malformed`.
  factory Payreq.fromText(String text) => Payreq.decode(payreqBytesOfText(text));

  @override
  List<_Field> get _schema => _payreqSchema;

  int get format => _int('format');
  int get net => _int('net');

  /// The listing card, verbatim.
  ListingCard get card => _d.fields['card']! as ListingCard;

  /// Smallest unit; zero means the payer chooses.
  BigInt get amount => _big('amount');
  Uint8List get reqid => _bytes('reqid');

  /// Unix seconds.
  BigInt get expires => _big('expires');
  int get kind => _int('kind');

  /// The directory's claim, `@` and up to 32 of `[A-Za-z0-9_]`, or null when absent or not
  /// of that form. Show it only when the wallet can match it.
  String? get label => _d.fields['label'] as String?;

  /// The payer's listing key when the link was made for one payer.
  Uint8List? get forKey => _d.fields['for'] as Uint8List?;

  /// The `epiccash://pay/1/<p>` form, or with [host] the `https://<host>/p#1/<p>` one.
  String toText({String? host}) {
    final p = _payreqPart(toBytes());
    return host == null ? 'epiccash://pay/1/$p' : 'https://$host/p#1/$p';
  }
}

/// Anything the wallet receives over a directory pairing, by its type. Decode with
/// [DirectoryPayload.decode].
sealed class DirectoryPayload extends WireRecord {
  DirectoryPayload._(super.d) : super._();

  int get type;

  @override
  int? get _lead => type;

  /// Reads a payload. A type that is not in the table gives [DroppedPayload]: acknowledged,
  /// not parsed. Throws `malformed`.
  static DirectoryPayload decode(Uint8List raw) {
    final items = _parseTlv(raw);
    if (items.isEmpty || items.first.$1 != 1 || items.first.$2.length != 1) _malformed();
    final t = items.first.$2[0];
    final schema = _payloadSchemas[t];
    if (schema == null) {
      return DroppedPayload._(_Decoded({'type': t}, const [], null, raw), t);
    }
    final d = _decodeStruct(raw, schema.$1, schema.$2, lead: t);
    final f = d.fields;
    final net = f['net'];
    if (net != null && net != 0 && net != 1) _malformed();
    if (t == 1 && ((f['flags'] as int?) ?? 0) & ~dirHelloNoPayments != 0) _malformed();
    if (t == 5 && f['stage'] != 1 && f['stage'] != 2) _malformed();
    for (final name in const ['dkey']) {
      final k = f[name];
      if (k != null && !_compressed(k as Uint8List)) _malformed();
    }
    if (t == 3 && parseListingAddress(f['address']! as String) == null) _malformed();
    if (t == 6 && parseListingAddress(f['old_address']! as String) == null) _malformed();
    return switch (t) {
      1 => DirHello._(d),
      2 => ListingPayload._(d),
      3 => UnlistPayload._(d),
      4 => UnlistedPayload._(d),
      5 => ReceiptPayload._(d),
      _ => MovedPayload._(d),
    };
  }
}

/// Flags bit 0 of a hello: the contact takes no payments. Any other bit is `malformed`.
const int dirHelloNoPayments = 0x01;

/// Type 1, directory to wallet, signed by `dkey` under `epic-dir-hello/1`.
final class DirHello extends DirectoryPayload {
  DirHello._(super.d) : super._();

  @override
  int get type => 1;
  @override
  List<_Field> get _schema => _payloadSchemas[1]!.$1;

  int get net => _int('net');
  Uint8List get dkey => _bytes('dkey');
  Uint8List get handle => _bytes('handle');

  /// The four SAS-table indexes the directory computed for this pairing.
  Uint8List get bind => _bytes('bind');
  BigInt get issued => _big('issued');

  /// The flags byte; 0 when absent.
  int get flags => (_d.fields['flags'] as int?) ?? 0;

  /// This contact takes no payments (flags bit 0).
  bool get takesNoPayments => flags & dirHelloNoPayments != 0;

  /// The user's own name at this contact, `@` and up to 32 of `[A-Za-z0-9_]`: what people pay
  /// the user as. Null when absent or not of that form (the hello still verifies).
  String? get label => _d.fields['label'] as String?;
}

/// Type 2, wallet to directory: a card, signed by its own key.
final class ListingPayload extends DirectoryPayload {
  ListingPayload._(super.d) : super._();

  @override
  int get type => 2;
  @override
  List<_Field> get _schema => _payloadSchemas[2]!.$1;

  ListingCard get card => _d.fields['card']! as ListingCard;
}

/// Type 3, wallet to directory, signed by the listing key under `epic-unlist/1`.
final class UnlistPayload extends DirectoryPayload {
  UnlistPayload._(super.d) : super._();

  @override
  int get type => 3;
  @override
  List<_Field> get _schema => _payloadSchemas[3]!.$1;

  int get net => _int('net');
  String get address => _text('address');
  Uint8List get dkey => _bytes('dkey');
  Uint8List get handle => _bytes('handle');
  BigInt get issued => _big('issued');
}

/// Type 4, directory to wallet. Unsigned: the pairing authenticates it.
final class UnlistedPayload extends DirectoryPayload {
  UnlistedPayload._(super.d) : super._();

  @override
  int get type => 4;
  @override
  List<_Field> get _schema => _payloadSchemas[4]!.$1;

  Uint8List get dkey => _bytes('dkey');
  Uint8List get handle => _bytes('handle');
  BigInt get issued => _big('issued');
}

/// Type 5, wallet to directory. Unsigned.
final class ReceiptPayload extends DirectoryPayload {
  ReceiptPayload._(super.d) : super._();

  @override
  int get type => 5;
  @override
  List<_Field> get _schema => _payloadSchemas[5]!.$1;

  /// The bytes of a receipt: [reqid] (16 bytes), [stage] `1` sent or `2` posted, [amount] in
  /// the smallest unit and [at] unix seconds. Nothing else goes in: no kernel, tx id or address.
  static Uint8List encode({
    required Uint8List reqid,
    required int stage,
    required BigInt amount,
    required int at,
  }) {
    if (reqid.length != 16 || (stage != 1 && stage != 2)) _malformed();
    return _encodeStruct(
      {'reqid': reqid, 'stage': stage, 'amount': amount, 'at': at},
      const [],
      null,
      _payloadSchemas[5]!.$1,
      lead: 5,
    );
  }

  Uint8List get reqid => _bytes('reqid');

  /// `1` sent, `2` posted.
  int get stage => _int('stage');
  BigInt get amount => _big('amount');
  BigInt get at => _big('at');
}

/// Type 6, wallet to directory, signed by the old listing key under `epic-listing-moved/1`.
final class MovedPayload extends DirectoryPayload {
  MovedPayload._(super.d) : super._();

  @override
  int get type => 6;
  @override
  List<_Field> get _schema => _payloadSchemas[6]!.$1;

  int get net => _int('net');
  String get oldAddress => _text('old_address');
  ListingCard get card => _d.fields['card']! as ListingCard;
}

/// A payload of a type this wallet does not know: acknowledged and dropped.
final class DroppedPayload extends DirectoryPayload {
  DroppedPayload._(super.d, this.type) : super._();

  @override
  final int type;
  @override
  List<_Field> get _schema => const [];

  @override
  Uint8List toBytes() => _d.signedBytes;
}

// ---------------------------------------------------------------- encoders

/// The bytes of a card before its signature: exactly the message `epic-listing/1` signs. Sign
/// them, then [withSignature].
Uint8List listingCardUnsigned({
  required int net,
  required String address,
  required Uint8List dkey,
  required Uint8List handle,
  required int seq,
  required int issued,
}) => _encodeStruct(
  {'format': 1, 'net': net, 'address': address, 'dkey': dkey, 'handle': handle, 'seq': seq, 'issued': issued},
  const [],
  null,
  _cardSchema,
);

/// The bytes of an unlist payload before its signature: the message `epic-unlist/1` signs.
Uint8List unlistPayloadUnsigned({
  required int net,
  required String address,
  required Uint8List dkey,
  required Uint8List handle,
  required int issued,
}) => _encodeStruct(
  {'net': net, 'address': address, 'dkey': dkey, 'handle': handle, 'issued': issued},
  const [],
  null,
  _payloadSchemas[3]!.$1,
  lead: 3,
);

/// A hello before its signature, as a directory makes it. A wallet only reads hellos; this is
/// for the fakes and the tests of the wallet side.
Uint8List dirHelloUnsigned({
  required int net,
  required Uint8List dkey,
  required Uint8List handle,
  required Uint8List bind,
  required int issued,
  int flags = 0,
  String? label,
}) => _encodeStruct(
  {
    'net': net,
    'dkey': dkey,
    'handle': handle,
    'bind': bind,
    'issued': issued,
    if (flags != 0) 'flags': flags,
    'label': ?label,
  },
  const [],
  null,
  _payloadSchemas[1]!.$1,
  lead: 1,
);

/// A type 4 payload (the directory no longer lists the wallet under [handle]); for the fakes
/// and the tests, as [dirHelloUnsigned].
Uint8List unlistedPayloadBytes({required Uint8List dkey, required Uint8List handle, required int issued}) =>
    _encodeStruct({'dkey': dkey, 'handle': handle, 'issued': issued}, const [], null, _payloadSchemas[4]!.$1, lead: 4);

/// [unsigned] with the `FF` signature field after it: the DER [signature] as LEPIC returns it.
Uint8List withSignature(Uint8List unsigned, Uint8List signature) => Uint8List.fromList([
  ...unsigned,
  _sigTag,
  signature.length >> 8,
  signature.length & 0xff,
  ...signature,
]);

/// A type 2 payload carrying [signedCard] (a card with its signature).
Uint8List listingPayloadBytes(Uint8List signedCard) =>
    _encodeStruct({'card': ListingCard.decode(signedCard)}, const [], null, _payloadSchemas[2]!.$1, lead: 2);

// ---------------------------------------------------------------- text forms

final RegExp _base64urlOnly = RegExp(r'^[A-Za-z0-9_\-]*$');
const String _b64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

String _payreqPart(Uint8List request) {
  final raw = [...request, ...doubleSha256Check(request)];
  final out = StringBuffer();
  for (var i = 0; i < raw.length; i += 3) {
    final n = raw.length - i;
    final v = raw[i] << 16 | (n > 1 ? raw[i + 1] << 8 : 0) | (n > 2 ? raw[i + 2] : 0);
    out.write(_b64[v >> 18 & 63]);
    out.write(_b64[v >> 12 & 63]);
    if (n > 1) out.write(_b64[v >> 6 & 63]);
    if (n > 2) out.write(_b64[v & 63]);
  }
  return out.toString();
}

/// The request bytes of a link [text]: `pay/1/<p>` or `p#1/<p>` anywhere (the last occurrence,
/// `pay/1/` first), the host never looked at, the text trimmed. No marker is `malformed`; a
/// `<p>` outside the base64url alphabet (padding included), of an impossible length or whose
/// 4-byte check fails is `checksum`.
Uint8List payreqBytesOfText(String text) {
  final t = text.trim();
  final String p;
  if (t.contains('pay/1/')) {
    p = t.substring(t.lastIndexOf('pay/1/') + 6);
  } else if (t.contains('p#1/')) {
    p = t.substring(t.lastIndexOf('p#1/') + 4);
  } else {
    _malformed();
  }
  if (!_base64urlOnly.hasMatch(p) || p.length % 4 == 1) _fail(DirectoryError.checksum);
  final raw = <int>[];
  var acc = 0;
  var bits = 0;
  for (final c in p.codeUnits) {
    acc = (acc << 6) | _b64.indexOf(String.fromCharCode(c));
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      raw.add((acc >> bits) & 0xff);
      acc &= (1 << bits) - 1;
    }
  }
  if (raw.length < 5) _fail(DirectoryError.checksum);
  final body = Uint8List.fromList(raw.sublist(0, raw.length - 4));
  final check = doubleSha256Check(body);
  for (var i = 0; i < 4; i++) {
    if (raw[raw.length - 4 + i] != check[i]) _fail(DirectoryError.checksum);
  }
  return body;
}
