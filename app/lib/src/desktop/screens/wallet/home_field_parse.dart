// SPDX-License-Identifier: Apache-2.0
/// Reads what is typed in Home's field: a name, an amount, an address or a payment code, in any
/// order and with the small words a person writes ("4 bt labs", "bt labs 4", "send 5 epic to bt
/// labs", "pay bt labs 5 for lunch", "request 5 from bt labs"). Pure Dart: the scan router and
/// the recipient reader are handed in, so the tests run without a wallet.
library;

import '../../../recipient.dart' show epic1Shaped;
import '../../../scan/scan_router.dart';
import '../../../send_route.dart' show RecipientInput, RecipientInputKind;
import '../../data/models.dart' show Contact;

/// What Enter opens.
enum HomeVerb { send, request }

/// What the field holds.
enum HomeKind {
  /// Nothing typed.
  blank,

  /// Nothing Send takes: no contact, no address, no code.
  none,

  /// An amount (or only a verb): Send or Request opens with it, the recipient still to pick.
  amount,

  /// One or more people (contacts, past recipients) the name stands for.
  person,

  /// An address of any kind, valid or not (the recipient says which).
  address,

  /// A payment link or request, a pairing link, a slate text or an epic1 link or code: all of it
  /// goes through Send's paste.
  code,
}

/// A contact, or an address paid before that no contact holds.
class HomePerson {
  const HomePerson.contact(Contact this.contact) : pastAddress = null, pastName = null;

  const HomePerson.past(String this.pastAddress, {this.pastName}) : contact = null;

  final Contact? contact;
  final String? pastAddress;
  final String? pastName;

  /// The name shown; a past recipient without a name shows its address.
  String get name => contact?.name ?? pastName ?? pastAddress ?? '';

  List<String> get addresses => contact?.addresses ?? [?pastAddress];

  bool get favourite => contact?.favourite ?? false;

  DateTime? get lastUsed => contact?.lastUsed;

  /// A stable id: the contact's, or the address of a past recipient.
  String get id => contact?.id ?? 'past:$pastAddress';
}

/// The amount typed: [text] as typed, or [max] for "max" and "all".
class HomeAmount {
  const HomeAmount(this.text, {this.max = false});

  final String text;
  final bool max;

  @override
  bool operator ==(Object other) => other is HomeAmount && other.text == text && other.max == max;

  @override
  int get hashCode => Object.hash(text, max);

  @override
  String toString() => max ? 'max' : text;
}

/// What Home's field holds and what Enter does with it.
class HomeRead {
  const HomeRead._(
    this.kind, {
    this.verb = HomeVerb.send,
    this.amount,
    this.message,
    this.matches = const [],
    this.address,
    this.recipient,
    this.code,
    this.classicRequest = false,
    this.wrongNetwork = false,
    this.query = '',
    this.nameStart = -1,
    this.nameEnd = -1,
  });

  static const blank = HomeRead._(HomeKind.blank);

  final HomeKind kind;
  final HomeVerb verb;
  final HomeAmount? amount;

  /// The text after "for".
  final String? message;

  /// For [HomeKind.person]: the people the name fits, best first. Enter takes the chosen one.
  final List<HomePerson> matches;

  /// For [HomeKind.address]: the address as typed; [recipient] is how Send reads it.
  final String? address;
  final RecipientInput? recipient;

  /// For [HomeKind.code]: the whole text.
  final String? code;

  /// For [HomeKind.code]: the code is a classic payment request (`epic:<key>@<relay>?…`).
  final bool classicRequest;

  /// For [HomeKind.address]: the address is one of the other network (Floonet on mainnet).
  final bool wrongNetwork;

  /// For [HomeKind.none]: what was typed, trimmed.
  final String query;

  /// Where the name stands in the trimmed text (for Tab); -1 when there is none.
  final int nameStart;
  final int nameEnd;

  /// The person Enter takes when none is chosen: the first.
  HomePerson? get first => matches.isEmpty ? null : matches.first;

  @override
  String toString() => 'HomeRead($kind, $verb, amount: $amount, message: $message, matches: ${matches.map((p) => p.id)}, address: $address)';
}

final RegExp _token = RegExp(r'\S+');
final RegExp _ws = RegExp(r'\s+');
final RegExp _invisible = RegExp(r'[\u200B\u200C\u200D\u2060\uFEFF\u00AD]');
final RegExp _amountShape = RegExp(r'^(\d[\d.,]*|[.,]\d[\d.,]*)$');
final RegExp _ipv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');

/// Whether [t] is an amount as typed: digits with `.` or `,` ("4", "4.5", "4,5", ".5",
/// "1,000.5", "12."), never an IPv4 address ("192.168.1.5").
bool homeAmountShaped(String t) => _amountShape.hasMatch(t) && !_ipv4.hasMatch(t);

/// [typed] as the reader sees it: invisible characters dropped, trimmed. [HomeRead.nameStart]
/// and [HomeRead.nameEnd] index this text.
String homeClean(String typed) => typed.replaceAll(_invisible, '').trim();

class _Tok {
  const _Tok(this.text, this.start, this.end);

  final String text;
  final int start;
  final int end;

  String get low => text.toLowerCase();
}

/// An amount in one token: a number with a unit stuck on ("4epic"), "max" or "all".
HomeAmount? _amountOf(String t) {
  final low = t.toLowerCase();
  if (low == 'max' || low == 'all') return const HomeAmount('', max: true);
  var n = t;
  if (n.length > 4 && low.endsWith('epic')) n = n.substring(0, n.length - 4);
  return homeAmountShaped(n) ? HomeAmount(n) : null;
}

bool _isUnit(_Tok t) => t.low == 'epic';
bool _isFiller(_Tok t) => t.low == 'to' || t.low == 'from';

/// One cut of the words: an [amount] if one was found, and the words left for the name.
class _Cut {
  const _Cut(this.name, this.amount);

  final List<_Tok> name;
  final HomeAmount? amount;
}

List<_Tok> _dropFiller(List<_Tok> w) => w.isNotEmpty && _isFiller(w.first) ? w.sublist(1) : w;

/// The ways to read [w] as a name and an amount: the words whole, an amount in front (with a
/// unit and "to" after it), an amount behind (with a unit after it), and "to" in front.
List<_Cut> _cuts(List<_Tok> w) {
  if (w.isEmpty) return const [];
  final out = <_Cut>[_Cut(w, null)];
  if (_isFiller(w.first) && w.length > 1) out.add(_Cut(w.sublist(1), null));
  final front = _amountOf(w.first.text);
  if (front != null) {
    final rest = w.sublist(1);
    // An amount alone, with its unit maybe: "4", "4 epic", "max".
    if (rest.isEmpty || (rest.length == 1 && _isUnit(rest.first) && !front.max)) {
      out.add(_Cut(const [], front));
    } else {
      // "4 epic bt labs" drops the unit; a contact called "Epic Fund" is the second try.
      if (_isUnit(rest.first) && !front.max && rest.length > 1) out.add(_Cut(_dropFiller(rest.sublist(1)), front));
      out.add(_Cut(_dropFiller(rest), front));
    }
  }
  if (w.length > 1) {
    final back = _amountOf(w.last.text);
    if (back != null) {
      out.add(_Cut(w.sublist(0, w.length - 1), back));
    } else if (_isUnit(w.last) && w.length > 2) {
      final n = _amountOf(w[w.length - 2].text);
      if (n != null && !n.max) out.add(_Cut(w.sublist(0, w.length - 2), n));
    }
  }
  return out;
}

String _norm(String s) => s.toLowerCase().split(_ws).where((x) => x.isNotEmpty).join(' ');

/// Whether the squashed [q] is the initials of [words]: successive starts of successive words
/// ("bl", "btl" for "bt labs").
bool _initials(String q, List<String> words, [int w = 0]) {
  if (q.isEmpty) return true;
  for (var i = w; i < words.length; i++) {
    final word = words[i];
    for (var n = 1; n <= word.length && n <= q.length; n++) {
      if (word.startsWith(q.substring(0, n)) && _initials(q.substring(n), words, i + 1)) return true;
    }
  }
  return false;
}

/// One edit apart (insert, delete, change, swap of two neighbours).
bool _oneOff(String a, String b) {
  if (a == b) return true;
  if ((a.length - b.length).abs() > 1) return false;
  var i = 0;
  while (i < a.length && i < b.length && a[i] == b[i]) {
    i++;
  }
  if (a.length == b.length) {
    if (a.substring(i + 1) == b.substring(i + 1)) return true;
    return i + 1 < a.length && a[i] == b[i + 1] && a[i + 1] == b[i] && a.substring(i + 2) == b.substring(i + 2);
  }
  final (s, l) = a.length < b.length ? (a, b) : (b, a);
  return s.substring(i) == l.substring(i + 1);
}

/// How well [p] fits the name [q]: 0 exact, 1 prefix, 2 each word starts a word, 3 each word
/// inside the name, 4 initials, 5 one typo, 6 the start of an address; null for no fit.
int? _fit(HomePerson p, String q) {
  final name = _norm(p.name);
  if (name.isEmpty && p.addresses.isEmpty) return null;
  final words = q.split(' ');
  final nameWords = name.split(' ');
  if (name == q) return 0;
  if (name.startsWith(q)) return 1;
  if (words.every((w) => nameWords.any((n) => n.startsWith(w)))) return 2;
  if (words.every((w) => w.length >= 3 && name.contains(w))) return 3;
  final squashed = q.replaceAll(' ', '');
  if (squashed.length >= 2 && _initials(squashed, nameWords)) return 4;
  if (squashed.length >= 4) {
    if (_oneOff(squashed, name.replaceAll(' ', ''))) return 5;
    if (words.length == 1 && nameWords.any((n) => n.length >= 4 && _oneOff(squashed, n))) return 5;
  }
  if (words.length == 1 && q.length >= 4 && p.addresses.any((a) => a.toLowerCase().startsWith(q))) return 6;
  return null;
}

/// The people [q] names, best first: by fit, then favourites, then last used, then name. A typo
/// only counts when nothing fits better.
List<HomePerson> _named(List<HomePerson> all, String q) {
  final key = _norm(q);
  if (key.isEmpty) return const [];
  final fits = <HomePerson, int>{};
  for (final p in all) {
    final f = _fit(p, key);
    if (f != null) fits[p] = f;
  }
  final best = fits.values.isEmpty ? 0 : fits.values.reduce((a, b) => a < b ? a : b);
  if (best == 5) {
    fits.removeWhere((_, f) => f != 5);
  } else {
    fits.removeWhere((_, f) => f == 5);
  }
  final hits = fits.keys.toList()
    ..sort((a, b) {
      final f = fits[a]!.compareTo(fits[b]!);
      if (f != 0) return f;
      if (a.favourite != b.favourite) return a.favourite ? -1 : 1;
      final la = a.lastUsed, lb = b.lastUsed;
      if (la != null || lb != null) {
        if (la == null) return 1;
        if (lb == null) return -1;
        final t = lb.compareTo(la);
        if (t != 0) return t;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  return hits;
}

/// The person whose address is [text] (a contact's own address wins over a past one).
HomePerson? _byAddress(List<HomePerson> all, String text) {
  final t = text.trim();
  HomePerson? past;
  for (final p in all) {
    if (p.addresses.any((a) => a == t)) {
      if (p.contact != null) return p;
      past ??= p;
    }
  }
  return past;
}

/// The address as Send holds it: cleaned when it is one, as typed otherwise.
String _clean(RecipientInput r, String typed) => r.isAddress && r.address.isNotEmpty ? r.address : typed;

bool _isAddress(String word, RecipientInput Function(String) read) {
  if (homeAmountShaped(word)) return false;
  if (epic1Shaped(word)) return true;
  return switch (read(word).kind) {
    RecipientInputKind.empty || RecipientInputKind.text || RecipientInputKind.slate => false,
    _ => true,
  };
}

const _sendVerbs = {'send', 'pay'};
const _requestVerbs = {'request'};

/// Reads [typed]. [classify] is the scan router (with the wallet's address check), [read] Send's
/// recipient reader (an address is what Send's To calls one). [people] are the contacts and
/// past recipients.
HomeRead readHomeField(
  String typed, {
  required List<HomePerson> people,
  required ScannedCode Function(String text) classify,
  required RecipientInput Function(String text) read,
}) {
  final text = homeClean(typed);
  if (text.isEmpty) return HomeRead.blank;
  // A recovery phrase is never handed on, nor echoed.
  if (looksLikeRecoveryPhrase(text)) return const HomeRead._(HomeKind.none);

  final all = [for (final m in _token.allMatches(text)) _Tok(m.group(0)!, m.start, m.end)];
  var verb = HomeVerb.send;
  var body = all;
  if (all.isNotEmpty && (_sendVerbs.contains(all.first.low) || _requestVerbs.contains(all.first.low))) {
    verb = _requestVerbs.contains(all.first.low) ? HomeVerb.request : HomeVerb.send;
    body = all.sublist(1);
  }
  final stripped = body.length != all.length;

  // A code: the whole text (after a verb), by the scan router.
  final codeText = body.isEmpty ? text : text.substring(body.first.start);
  final scanned = classify(codeText);
  switch (scanned) {
    case PaymentRequest():
      return HomeRead._(HomeKind.code, verb: verb, code: codeText, classicRequest: true);
    case PaymentLink() || PairingLink() || SlateText() || SlateFrames():
      return HomeRead._(HomeKind.code, verb: verb, code: codeText);
    case ScannedAddress() || WrongNetwork():
      // A number is no address ("4.5" reads as a host); the words below take it as an amount.
      if (body.length == 1 && homeAmountShaped(codeText)) break;
      final known = _byAddress(people, codeText);
      if (known != null) {
        return HomeRead._(HomeKind.person, verb: verb, matches: [known], nameStart: body.isEmpty ? 0 : body.first.start, nameEnd: text.length);
      }
      final r = read(codeText);
      return HomeRead._(HomeKind.address, verb: verb, address: _clean(r, codeText), recipient: r, wrongNetwork: scanned is WrongNetwork);
    default:
      if (body.length == 1 && epic1Shaped(codeText)) return HomeRead._(HomeKind.code, verb: verb, code: codeText);
  }

  // The readings, best first: after the verb or whole, with or without the text after "for".
  final variants = <(HomeVerb, List<_Tok>, String?)>[];
  void variant(HomeVerb v, List<_Tok> w) {
    final f = w.indexWhere((t) => t.low == 'for');
    if (f > 0 && f < w.length - 1) variants.add((v, w.sublist(0, f), text.substring(w[f + 1].start).trim()));
    variants.add((v, w, null));
  }

  variant(verb, body);
  if (stripped) variant(HomeVerb.send, all);

  if (body.isEmpty) {
    // A verb alone opens that screen empty, unless a contact has that very name.
    final same = _named(people, text).where((p) => _norm(p.name) == _norm(text)).toList();
    if (same.isNotEmpty) return HomeRead._(HomeKind.person, matches: same, nameStart: 0, nameEnd: text.length);
    return HomeRead._(HomeKind.amount, verb: verb);
  }

  // Pass 1 takes an exact name, a known address or an address; pass 2 a name that fits.
  for (final fuzzy in [false, true]) {
    for (final (v, words, msg) in variants) {
      for (final cut in _cuts(words)) {
        final name = cut.name;
        if (name.isEmpty) {
          if (!fuzzy && cut.amount != null) return HomeRead._(HomeKind.amount, verb: v, amount: cut.amount, message: msg);
          continue;
        }
        final q = text.substring(name.first.start, name.last.end);
        if (!fuzzy) {
          if (name.length == 1) {
            final known = _byAddress(people, q);
            if (known != null) {
              return HomeRead._(HomeKind.person, verb: v, amount: cut.amount, message: msg, matches: [known], nameStart: name.first.start, nameEnd: name.last.end);
            }
            if (_isAddress(q, read)) {
              return HomeRead._(HomeKind.address, verb: v, amount: cut.amount, message: msg, address: _clean(read(q), q), recipient: read(q), nameStart: name.first.start, nameEnd: name.last.end);
            }
          }
          final exact = _named(people, q).where((p) => _norm(p.name) == _norm(q)).toList();
          if (exact.isNotEmpty) {
            return HomeRead._(HomeKind.person, verb: v, amount: cut.amount, message: msg, matches: _named(people, q), nameStart: name.first.start, nameEnd: name.last.end);
          }
        } else {
          final hits = _named(people, q);
          if (hits.isNotEmpty) {
            return HomeRead._(HomeKind.person, verb: v, amount: cut.amount, message: msg, matches: hits, nameStart: name.first.start, nameEnd: name.last.end);
          }
        }
      }
    }
  }
  return HomeRead._(HomeKind.none, verb: verb, query: text);
}
