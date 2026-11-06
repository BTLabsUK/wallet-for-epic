// SPDX-License-Identifier: Apache-2.0
/// The smart scan router: what a scanned, pasted or linked text is, and the `epic:` payment URI
///. Pure Dart: no I/O, no wallet, no
/// providers. Address checks come in as [AddressCheck], so the router never invents its own.
///
/// Nothing here pays or opens anything: it only says what the text is. Slates and pairing
/// links are recognised by their prefix and handed on untouched; their own decoders read them.
library;

import 'dart:convert';

import '../amount.dart' show atomicPerEpic, epicDecimals, formatEpic;
import '../bip39_words.dart';
import '../name_service/wire.dart' show NameServiceError, NameServiceException, Payreq;
import '../payment_method.dart' show MethodKind;
import '../recipient.dart';

/// Longest text the router reads; longer is not an Epic code. Leaves room for a 264-character
/// note in any script once percent-encoded.
const int maxScanLength = 4096;

/// Longest address in a payment URI.
const int maxUriAddressLength = 255;

/// Longest raw (still encoded) parameter value: a [maxNoteLength] note of four-byte
/// characters, each `%XX%XX%XX%XX`.
const int maxUriValueLength = maxNoteLength * 12;

/// Longest note (`message`) a code may carry, in characters, after cleaning.
const int maxNoteLength = 264;

/// Longest payee name (`label`), in characters, after cleaning.
const int maxLabelLength = 64;

/// The highest amount a code may ask for, in EPIC.
const int maxUriAmountEpic = 21000000000;

/// The scheme this wallet writes for a plain payment code: address, amount and note, read by
/// any Epic wallet. `epiccash:` is read the same way and is also this wallet's own: pairing and
/// `pay/1/` links live there, never under `epic:`.
const String epicUriScheme = 'epic';

/// What an address check says about an address.
enum AddressVerdict {
  /// The wallet can pay it.
  valid,

  /// A valid address of the other chain (mainnet against floonet).
  otherChain,

  /// Not an address the wallet can pay.
  invalid,
}

/// Checks [to] the way Send would; the app passes LEPIC's checks.
typedef AddressCheck = AddressVerdict Function(Recipient to);

/// Which Send method a payment code hints at.
enum MethodHint { epicbox, direct }

/// Parts of a payment code that were dropped, each told to the user once.
enum RequestProblem {
  /// The amount is not a valid amount (zero, more than 8 decimals, a sign, a comma).
  amountInvalid,

  /// The amount is above [maxUriAmountEpic].
  amountTooLarge,

  /// A part was longer than its limit.
  tooLong,

  /// The minimum is not a valid amount.
  minimumInvalid,
}

/// Which pairing link a text is (pairing RFC 0002).
enum PairingKind { invite, reply, confirm, contact }

/// Why a text is not an Epic code.
enum UnknownReason {
  /// Not something this wallet reads.
  notEpic,

  /// An `epic:` code whose address is not valid.
  badAddress,
}

/// What a scanned, pasted or linked text is.
sealed class ScannedCode {
  const ScannedCode();
}

/// A part of an animated payment QR (`ur:epic-slate/…`), for the QR Payment reader.
final class SlateFrames extends ScannedCode {
  const SlateFrames(this.text);

  /// The scanned text, untouched.
  final String text;
}

/// A pairing or contact link (`epiccash://pair/…`), for the pairing flow.
final class PairingLink extends ScannedCode {
  const PairingLink(this.kind, this.text);

  final PairingKind kind;

  /// The link, untouched.
  final String text;
}

/// A transaction file's text (slate JSON or a slatepack): the File flow's, not Send's.
final class SlateText extends ScannedCode {
  const SlateText(this.text);

  final String text;
}

/// A bare address: Send with the recipient filled.
final class ScannedAddress extends ScannedCode {
  const ScannedAddress(this.recipient);

  final Recipient recipient;
}

/// An `epic:` payment request: Send prefilled. Nothing in it is verified but the address.
final class PaymentRequest extends ScannedCode {
  const PaymentRequest({
    required this.recipient,
    this.amount,
    this.note,
    this.label,
    this.method,
    this.direct,
    this.noteRequired = false,
    this.minimum,
    this.problems = const {},
  });

  /// The address of the code, checked.
  final Recipient recipient;

  /// Atomic units, above zero; null when the code has none or it was dropped.
  final BigInt? amount;

  /// The payee's note (`message`), cleaned; not verified.
  final String? note;

  /// The payee's name (`label`), cleaned; not verified, never a contact by itself.
  final String? label;

  /// The method the code hints at; the address form wins over it.
  final MethodHint? method;

  /// A second, Direct address of the same payee, checked.
  final Recipient? direct;

  /// The code says a payment to this address needs a message (`require=message`): Send warns
  /// while its message is empty and lets the user send anyway.
  final bool noteRequired;

  /// Atomic units: the least the payee says it takes, above zero; null when the code has none
  /// or it was dropped. Send shows it and warns under it.
  final BigInt? minimum;

  final Set<RequestProblem> problems;

  /// The address Send should use, picked by method: the one the code prefers (its Direct
  /// one when it asks for Direct over an Epicbox address, else its own) when that method is
  /// [offered], else its other one when that method is, else the preferred one, so Send names
  /// the method that is off.
  Recipient recipientFor(bool Function(MethodKind) offered) {
    final second = direct;
    if (second == null) return recipient;
    final wantsDirect =
        method == MethodHint.direct && recipient.kind == RecipientKind.epicbox;
    final (first, other) =
        wantsDirect ? (second, recipient) : (recipient, second);
    if (offered(MethodKind.ofRecipient(first.kind))) return first;
    if (offered(MethodKind.ofRecipient(other.kind))) return other;
    return first;
  }
}

/// A valid address of the other chain (a floonet address in a mainnet wallet, or back).
final class WrongNetwork extends ScannedCode {
  const WrongNetwork(this.recipient);

  final Recipient recipient;
}

/// A recovery phrase (the backup screen's QR shows one). It keeps no words: nothing may show,
/// copy or log them.
final class RecoveryPhraseCode extends ScannedCode {
  const RecoveryPhraseCode();
}

/// Whether [text] is a recovery phrase: 12, 15, 18, 21 or 24 words apart by spaces or commas,
/// all but two at most in the word list (a typo still counts, so it is never shown).
bool looksLikeRecoveryPhrase(String text) {
  final words = text.trim().toLowerCase().split(RegExp(r'[\s,]+'));
  if (!const {12, 15, 18, 21, 24}.contains(words.length)) return false;
  if (!words.every(RegExp(r'^[a-z]+$').hasMatch)) return false;
  return words.where(bip39Words.contains).length >= words.length - 2;
}

/// A payment link (`epiccash://pay/1/<p>` or any text holding `p#1/<p>`): the request decoded
/// by structure, not verified (signatures, network, expiry and `for` are the Send screen's,
/// through `verifyPayreq`). A link that does not decode carries [error] (`checksum` or
/// `malformed`) and no request.
final class PaymentLink extends ScannedCode {
  const PaymentLink(this.text, {this.request, this.error});

  /// The link as read: the marker and what follows it, up to the first space.
  final String text;
  final Payreq? request;
  final NameServiceError? error;
}

/// Not an Epic code.
final class UnknownCode extends ScannedCode {
  const UnknownCode(this.text, {this.reason = UnknownReason.notEpic});

  /// The text as read (first line, trimmed), for Copy.
  final String text;
  final UnknownReason reason;
}

/// Whether [text] starts like a code the router reads by its scheme (`epic:`, `epiccash:`,
/// `ur:`), is a transaction file's text or a recovery phrase, as opposed to plain text typed or pasted into a
/// field.
bool looksLikeCode(String text) =>
    looksLikeRecoveryPhrase(text) ||
    RegExp(r'^\s*(epic|epiccash|ur):', caseSensitive: false).hasMatch(text) ||
    switch (classifyScan(text, check: (_) => AddressVerdict.invalid)) {
      SlateText() || PaymentLink() => true,
      _ => false,
    };

/// What [raw] is. Never throws; never reads more than [maxScanLength] characters of a line.
ScannedCode classifyScan(String raw, {required AddressCheck check}) {
  if (looksLikeRecoveryPhrase(raw)) return const RecoveryPhraseCode();
  try {
    return _classify(raw, check);
  } on Object {
    // The router never fails a scan; a text it cannot read is not an Epic code.
    return UnknownCode(_firstLine(raw));
  }
}

String _firstLine(String raw) {
  final trimmed = raw.trim();
  final end = trimmed.indexOf(RegExp(r'[\r\n]'));
  return (end < 0 ? trimmed : trimmed.substring(0, end)).trim();
}

final RegExp _controlChars = RegExp(r'[\u0000-\u001f\u007f-\u009f]');
final RegExp _scheme = RegExp(r'^(epic|epiccash):', caseSensitive: false);

/// A pairing link anywhere in a shared message ("Anna wants to pair…" with the link on its
/// own line, or the lines run together by a one-line field).
final RegExp _pairingInText = RegExp(
  r'epiccash://(pair|pair-reply|pair-confirm|contact)/[A-Za-z0-9_\-/=]+',
  caseSensitive: false,
);

ScannedCode _classify(String raw, AddressCheck check) {
  final whole = raw.trim();
  if (_isSlateText(whole)) return SlateText(whole);
  // A text that starts with our scheme is read by it: a payment code's note never makes it a
  // pairing link.
  final shared = _scheme.hasMatch(whole) ? null : _pairingInText.firstMatch(whole);
  if (shared != null) {
    final kind = switch (shared.group(1)!.toLowerCase()) {
      'pair' => PairingKind.invite,
      'pair-reply' => PairingKind.reply,
      'pair-confirm' => PairingKind.confirm,
      _ => PairingKind.contact,
    };
    return PairingLink(kind, shared.group(0)!);
  }
  final link = _paymentLink(whole);
  if (link != null) return link;
  final text = _firstLine(raw);
  if (text.isEmpty) return UnknownCode(text);
  final lower = text.toLowerCase();
  if (lower.startsWith('ur:epic-slate/')) return SlateFrames(text);
  if (lower.startsWith('ur:')) return UnknownCode(text);
  if (text.length > maxScanLength || _controlChars.hasMatch(text)) {
    return UnknownCode(text);
  }
  final scheme = _scheme.firstMatch(text);
  if (scheme == null) return _bare(text, check);
  var rest = text.substring(scheme.end);
  if (rest.startsWith('//')) {
    // A Linux second start hands the running window `scheme:///…` (GIO adds the empty host).
    rest = rest.substring(rest.startsWith('///') ? 3 : 2);
    if (scheme.group(1)!.toLowerCase() == epicUriScheme) return _payment(text, rest, check);
    final segment = rest.split('/').first.toLowerCase();
    final pairing = switch (segment) {
      'pair' => PairingKind.invite,
      'pair-reply' => PairingKind.reply,
      'pair-confirm' => PairingKind.confirm,
      'contact' => PairingKind.contact,
      _ => null,
    };
    // Pairing links are hierarchical: `epiccash://pair/…`. `epic://<address>` is tolerated
    // above, as a payment.
    if (pairing != null && rest.length > segment.length) {
      return PairingLink(pairing, text);
    }
  }
  return _payment(text, rest, check);
}

/// A payment link in [whole]: the last `pay/1/` (else `p#1/`) and the link text after it up to
/// the first space, so a shared message with the link in it reads. The host is never looked at.
/// An `epic:` code keeps its note, and `epiccash:` only a `pay/1/` link, whatever they hold.
PaymentLink? _paymentLink(String whole) {
  final lower = whole.toLowerCase();
  if (lower.startsWith('epic:')) return null;
  if (lower.startsWith('epiccash:') && !lower.startsWith('epiccash://pay/1/')) return null;
  for (final marker in const ['pay/1/', 'p#1/']) {
    final at = whole.lastIndexOf(marker);
    if (at < 0) continue;
    final end = whole.indexOf(RegExp(r'\s'), at);
    final link = whole.substring(at, end < 0 ? whole.length : end);
    if (link.length > maxScanLength) return null;
    try {
      return PaymentLink(link, request: Payreq.fromText(link));
    } on NameServiceException catch (e) {
      return PaymentLink(link, error: e.error);
    }
  }
  return null;
}

/// A transaction file's text: slate JSON or an armored slatepack.
bool _isSlateText(String text) {
  if (text.startsWith('{') &&
      (text.contains('"version_info"') || text.contains('"ver"'))) {
    return true;
  }
  return text
      .substring(0, text.length < 64 ? text.length : 64)
      .replaceAll(RegExp(r'\s'), '')
      .toUpperCase()
      .startsWith('BEGINSLATEPACK');
}

/// A bare address, after the junk other wallets put around it.
ScannedCode _bare(String text, AddressCheck check) {
  if (RegExp(r'\s').hasMatch(text) || text.length > maxUriAddressLength) {
    return UnknownCode(text);
  }
  final to = _recipientOf(_unwrap(text));
  if (to == null) return UnknownCode(text);
  return switch (check(to)) {
    AddressVerdict.valid => ScannedAddress(to),
    AddressVerdict.otherChain => WrongNetwork(to),
    AddressVerdict.invalid => UnknownCode(text),
  };
}

/// Strips `mailto:`, an `http(s)://` in front of an Epicbox address and a `/` after it
/// (Stack Wallet's `formatEpicCashAddress`).
String _unwrap(String text) {
  var t = text;
  if (t.toLowerCase().startsWith('mailto:')) t = t.substring(7);
  if (t.contains('@') && t.endsWith('/')) t = t.substring(0, t.length - 1);
  final m = RegExp(r'^https?://', caseSensitive: false).firstMatch(t);
  if (m != null) {
    final after = t.substring(m.end);
    if (RegExp(r'^[1-9A-HJ-NP-Za-km-z]{40,}@[^@/]+$').hasMatch(after)) {
      return after;
    }
  }
  return t;
}

/// [text] as a recipient of the kind its form says, or null when it has no address form, a
/// host that is not plain ASCII (a look-alike letter could pass for another host), whitespace
/// (an address is taken verbatim, never mended) or, for a URL, not a [_directUrl].
Recipient? _recipientOf(String text) {
  if (text.isEmpty || text.contains('%') || RegExp(r'\s').hasMatch(text)) {
    return null;
  }
  final to = parseRecipient(text);
  if (!recipientShaped(to)) return null;
  if (!RegExp(r'^[\x21-\x7e]+$').hasMatch(to.address)) return null;
  if (to.kind == RecipientKind.http && !_directUrl(to.address)) return null;
  if (to.kind == RecipientKind.epicbox && !to.address.contains('@')) {
    return null;
  }
  return to;
}

/// Whether [url] is a whole Direct URL Send takes, with none of what could hide its host: no
/// query or fragment, no `@` (a user part, even an empty one), no IPv6 literal (Send takes
/// none; `[::ffff:203.0.113.4]` would pass its name check) and no empty port (`host:`).
bool _directUrl(String url) {
  if (!httpAddressComplete(url) || url.contains(RegExp('[?#@]'))) return false;
  if (Uri.parse(url).host.contains(':')) return false;
  return !RegExp(r'^https?://[^/]*:(/|$)', caseSensitive: false).hasMatch(url);
}

ScannedCode _payment(String text, String rest, AddressCheck check) {
  var body = rest;
  final hash = body.indexOf('#');
  if (hash >= 0) body = body.substring(0, hash);
  final q = body.indexOf('?');
  var address = q < 0 ? body : body.substring(0, q);
  final query = q < 0 ? '' : body.substring(q + 1);
  // `epic://<address>` handed on by the system comes back with a `/` after the host.
  if (address.contains('@') && address.endsWith('/')) {
    address = address.substring(0, address.length - 1);
  }
  if (address.isEmpty) return UnknownCode(text);
  final params = _params(query);
  if (params == null) return UnknownCode(text);
  if (address.length > maxUriAddressLength) {
    return UnknownCode(text, reason: UnknownReason.badAddress);
  }
  final to = _recipientOf(address);
  if (to == null) return UnknownCode(text, reason: UnknownReason.badAddress);
  switch (check(to)) {
    case AddressVerdict.valid:
      break;
    case AddressVerdict.otherChain:
      return WrongNetwork(to);
    case AddressVerdict.invalid:
      return UnknownCode(text, reason: UnknownReason.badAddress);
  }

  final problems = <RequestProblem>{};
  BigInt? amount;
  String? note;
  String? label;
  MethodHint? method;
  Recipient? direct;
  var noteRequired = false;
  BigInt? minimum;
  final noteName = _noteNames.where((n) => params[n]?.isNotEmpty ?? false).firstOrNull;
  for (final MapEntry(key: name, value: raw) in params.entries) {
    if (raw.length > maxUriValueLength) {
      problems.add(RequestProblem.tooLong);
      continue;
    }
    final value = _decodeOnce(raw);
    if (value == null) continue;
    switch (name) {
      case 'amount':
        final (atomic, problem) = parseUriAmount(value);
        if (problem != null) problems.add(problem);
        amount = atomic;
      case 'message' || 'note' || 'memo':
        if (name != noteName) break;
        final clean = cleanUntrustedText(value);
        if (clean == null) break;
        if (clean.runes.length > maxNoteLength) {
          problems.add(RequestProblem.tooLong);
        } else {
          note = clean;
        }
      case 'label':
        final clean = cleanUntrustedText(value);
        if (clean == null) break;
        if (clean.runes.length > maxLabelLength) {
          problems.add(RequestProblem.tooLong);
        } else {
          label = clean;
        }
      case 'method':
        method = switch (value.toLowerCase()) {
          'epicbox' => MethodHint.epicbox,
          'direct' => MethodHint.direct,
          _ => null,
        };
      case 'direct':
        final second = _recipientOf(value);
        if (second != null &&
            second.kind != RecipientKind.epicbox &&
            check(second) == AddressVerdict.valid) {
          direct = second;
        }
      case 'require':
        noteRequired = _noteNames.contains(value.toLowerCase());
      case 'min':
        final (atomic, problem) = parseUriAmount(value);
        if (problem != null) problems.add(RequestProblem.minimumInvalid);
        minimum = atomic;
    }
  }
  return PaymentRequest(
    recipient: to,
    amount: amount,
    note: note,
    label: label,
    method: method,
    direct: direct,
    noteRequired: noteRequired,
    minimum: minimum,
    problems: problems,
  );
}

/// The spellings of a code's note, the one this wallet writes first: with more than one in a
/// code, the first that holds something is read.
const List<String> _noteNames = ['message', 'note', 'memo'];

const Set<String> _known = {
  'amount',
  ..._noteNames,
  'label',
  'method',
  'direct',
  'require',
  'min',
};

/// The query's parameters this wallet knows, by lowercase name, raw values; null when the URI
/// must be refused: a known name twice. A parameter it does not know is left out, however many.
Map<String, String>? _params(String query) {
  final out = <String, String>{};
  if (query.isEmpty) return out;
  for (final piece in query.split('&').where((p) => p.isNotEmpty)) {
    final eq = piece.indexOf('=');
    final name = (eq < 0 ? piece : piece.substring(0, eq)).toLowerCase();
    final value = eq < 0 ? '' : piece.substring(eq + 1);
    if (!_known.contains(name)) continue;
    // Two amounts must never be a guess: a known name twice refuses the whole code.
    if (out.containsKey(name)) return null;
    out[name] = value;
  }
  return out;
}

final RegExp _hexPair = RegExp(r'^[0-9A-Fa-f]{2}$');

/// Percent-decodes [raw] exactly once, `+` as a space, as strict UTF-8; null for a bad escape
/// or bytes that are not UTF-8.
String? _decodeOnce(String raw) {
  final bytes = <int>[];
  for (var i = 0; i < raw.length; i++) {
    final c = raw.codeUnitAt(i);
    if (c == 0x2b) {
      bytes.add(0x20);
    } else if (c == 0x25) {
      if (i + 2 >= raw.length) return null;
      final pair = raw.substring(i + 1, i + 3);
      if (!_hexPair.hasMatch(pair)) return null;
      bytes.add(int.parse(pair, radix: 16));
      i += 2;
    } else {
      // A run at a time, so a character outside the BMP keeps its surrogate pair.
      var end = i + 1;
      while (end < raw.length &&
          raw.codeUnitAt(end) != 0x25 &&
          raw.codeUnitAt(end) != 0x2b) {
        end++;
      }
      bytes.addAll(utf8.encode(raw.substring(i, end)));
      i = end - 1;
    }
  }
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return null;
  }
}

final RegExp _amountShape = RegExp(r'^(0|[1-9][0-9]*)(\.[0-9]{1,8})?$');

/// A code's amount in atomic units, or the problem with it. Integer arithmetic only.
(BigInt?, RequestProblem?) parseUriAmount(String text) {
  if (text.length > 64 || !_amountShape.hasMatch(text)) {
    // Digits only, just too many: too large rather than malformed.
    return RegExp(r'^[1-9][0-9]{12,}$').hasMatch(text)
        ? (null, RequestProblem.amountTooLarge)
        : (null, RequestProblem.amountInvalid);
  }
  final dot = text.indexOf('.');
  final whole = BigInt.parse(dot < 0 ? text : text.substring(0, dot));
  final fraction = dot < 0 ? '' : text.substring(dot + 1);
  final atomic =
      whole * atomicPerEpic +
      (fraction.isEmpty
          ? BigInt.zero
          : BigInt.parse(fraction.padRight(epicDecimals, '0')));
  if (atomic == BigInt.zero) return (null, RequestProblem.amountInvalid);
  if (atomic > BigInt.from(maxUriAmountEpic) * atomicPerEpic) {
    return (null, RequestProblem.amountTooLarge);
  }
  return (atomic, null);
}

/// Characters never shown from an outside text: controls, line and paragraph separators,
/// zero-width and direction marks (the Arabic letter mark too), embeddings, overrides,
/// isolates, word joiners and the BOM. The union of the app's cleaners (relay operators, wallet
/// labels, the public lists).
final RegExp untrustedTextForbidden = RegExp(
  r'[\p{Cc}\u061C\u2028\u2029\u200B-\u200F\u202A-\u202E\u2060-\u2064\u2066-\u2069\uFEFF]',
  unicode: true,
);

/// [text] from outside (a code's note or name) as plain text safe to show: line breaks and
/// tabs made spaces (so two lines do not run into one word), forbidden characters removed,
/// whitespace collapsed to single spaces, trimmed; null when nothing is left.
String? cleanUntrustedText(String text) {
  final clean = text
      .replaceAll(RegExp('[\t\n\v\f\r\u0085\u2028\u2029]'), ' ')
      .replaceAll(untrustedTextForbidden, '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return clean.isEmpty ? null : clean;
}

/// Builds `epic:` payment URIs, the form Stack Wallet and Epic Pay read.
abstract final class EpicUri {
  /// `epic:<address>`, then `amount`, `message`, `label`, `method`, `direct` when given.
  static String build(
    String address, {
    BigInt? amount,
    String? note,
    String? label,
    MethodHint? method,
    String? direct,
  }) {
    final params = <String>[
      if (amount != null && amount > BigInt.zero)
        'amount=${formatEpic(amount)}',
      if (note != null && note.isNotEmpty) 'message=${encodeUriValue(note)}',
      if (label != null && label.isNotEmpty) 'label=${encodeUriValue(label)}',
      if (method != null) 'method=${method.name}',
      if (direct != null && direct.isNotEmpty)
        'direct=${encodeUriValue(direct)}',
    ];
    return params.isEmpty
        ? '$epicUriScheme:$address'
        : '$epicUriScheme:$address?${params.join('&')}';
  }
}

/// [value] percent-encoded as UTF-8, uppercase hex, `A-Za-z0-9-._~` as is.
String encodeUriValue(String value) {
  final out = StringBuffer();
  for (final b in utf8.encode(value)) {
    final unreserved =
        (b >= 0x41 && b <= 0x5a) ||
        (b >= 0x61 && b <= 0x7a) ||
        (b >= 0x30 && b <= 0x39) ||
        b == 0x2d ||
        b == 0x2e ||
        b == 0x5f ||
        b == 0x7e;
    out.write(
      unreserved
          ? String.fromCharCode(b)
          : '%${b.toRadixString(16).toUpperCase().padLeft(2, '0')}',
    );
  }
  return out.toString();
}
