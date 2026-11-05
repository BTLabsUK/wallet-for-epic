// SPDX-License-Identifier: Apache-2.0
/// What one wallet keeps about the name services it paired with: the book of
/// `name_service_service.dart`, kept by `name_service_store.dart`. A name service is an ordinary contact
/// pairing whose peer sent a valid hello; nothing here knows which service it is.
library;

/// How long a retired listing is still read after Leave: payments sent to it before the
/// name service dropped it can still arrive.
const Duration listingDrainWindow = Duration(days: 7);

/// Where the wallet stands in one name service.
enum ListingState {
  /// Not listed: never joined, or left.
  notJoined,

  /// Listed: the name service has the card.
  joined,

  /// The name service sent `unlisted` for the current handle.
  unlisted,
}

/// A generation that is no longer listed, read until [drainUntil].
class RetiredListing {
  const RetiredListing({required this.generation, required this.address, required this.drainUntil});

  final int generation;
  final String address;
  final DateTime drainUntil;

  Map<String, Object?> toJson() => {'gen': generation, 'address': address, 'until': drainUntil.millisecondsSinceEpoch};

  static RetiredListing? fromJson(Object? j) {
    if (j is! Map || j['gen'] is! num || j['address'] is! String || j['until'] is! num) return null;
    return RetiredListing(
      generation: (j['gen'] as num).toInt(),
      address: j['address'] as String,
      drainUntil: DateTime.fromMillisecondsSinceEpoch((j['until'] as num).toInt()),
    );
  }
}

/// One name service contact. [serviceKey] and [handle] are hex (33 and 16 bytes).
class NameServiceEntry {
  const NameServiceEntry({
    required this.serviceKey,
    required this.pairingId,
    required this.handle,
    this.label = '',
    this.pinned = false,
    this.state = ListingState.notJoined,
    this.maxGeneration = -1,
    this.generation,
    this.seq = 0,
    this.joinedAt,
    this.address,
    this.retired = const [],
    this.paymentsKey,
    this.payAs,
    this.issued,
  });

  final String serviceKey;
  final String pairingId;
  final String handle;

  /// The name the pairing last showed, for readers with no pairing at hand.
  final String label;

  /// The user compared the code (They match): the serviceKey belongs to this contact.
  final bool pinned;
  final ListingState state;

  /// The highest generation ever used for [serviceKey], -1 for none: a new listing takes one above,
  /// so a Leave never reuses one.
  final int maxGeneration;

  /// The generation listed now, null unless [state] is joined.
  final int? generation;

  /// The sequence number of the card the name service has.
  final int seq;
  final DateTime? joinedAt;

  /// The listing address of [generation].
  final String? address;
  final List<RetiredListing> retired;

  /// The key part of the contact's Epicbox address (the pairing's proven one), kept so the
  /// address can be matched without reading the pairing. Null when the contact sent none.
  final String? paymentsKey;

  /// The user's own `@name` at this contact, from the last valid hello's `08 label`; null when
  /// that hello had none.
  final String? payAs;

  /// The `issued` of the last hello applied to this entry; a later hello counts only when its own
  /// is greater. Null on data from before it was kept: the next hello is accepted.
  final BigInt? issued;

  bool get joined => state == ListingState.joined;

  /// [payAs] as the "Pay me as" strings take it: the word `none` when there is no name.
  String get payAsArg => payAs ?? 'none';

  /// The generation a new listing takes.
  int get nextGeneration => maxGeneration + 1;

  NameServiceEntry copyWith({
    String? pairingId,
    String? handle,
    String? label,
    bool? pinned,
    ListingState? state,
    int? maxGeneration,
    int? Function()? generation,
    int? seq,
    DateTime? Function()? joinedAt,
    String? Function()? address,
    List<RetiredListing>? retired,
    String? Function()? paymentsKey,
    String? Function()? payAs,
    BigInt? issued,
  }) => NameServiceEntry(
    serviceKey: serviceKey,
    pairingId: pairingId ?? this.pairingId,
    handle: handle ?? this.handle,
    label: label ?? this.label,
    pinned: pinned ?? this.pinned,
    state: state ?? this.state,
    maxGeneration: maxGeneration ?? this.maxGeneration,
    generation: generation == null ? this.generation : generation(),
    seq: seq ?? this.seq,
    joinedAt: joinedAt == null ? this.joinedAt : joinedAt(),
    address: address == null ? this.address : address(),
    retired: retired ?? this.retired,
    paymentsKey: paymentsKey == null ? this.paymentsKey : paymentsKey(),
    payAs: payAs == null ? this.payAs : payAs(),
    issued: issued ?? this.issued,
  );

  /// The listings to read now: the joined one and the retired ones within their window.
  List<({int generation, String? address})> live(DateTime now) => [
    if (joined && generation != null) (generation: generation!, address: address),
    for (final r in retired)
      if (now.isBefore(r.drainUntil)) (generation: r.generation, address: r.address),
  ];

  Map<String, Object?> toJson() => {
    'dkey': serviceKey,
    'pairing': pairingId,
    'handle': handle,
    'label': label,
    'pinned': pinned,
    'state': state.name,
    'maxGen': maxGeneration,
    'gen': generation,
    'seq': seq,
    'joinedAt': joinedAt?.millisecondsSinceEpoch,
    'address': address,
    'retired': [for (final r in retired) r.toJson()],
    'paymentsKey': paymentsKey,
    'payAs': payAs,
    'issued': issued?.toString(),
  };

  static NameServiceEntry? fromJson(Object? j) {
    if (j is! Map || j['dkey'] is! String || j['pairing'] is! String || j['handle'] is! String) return null;
    return NameServiceEntry(
      serviceKey: j['dkey'] as String,
      pairingId: j['pairing'] as String,
      handle: j['handle'] as String,
      label: j['label'] as String? ?? '',
      pinned: j['pinned'] == true,
      state: ListingState.values.where((s) => s.name == j['state']).firstOrNull ?? ListingState.notJoined,
      maxGeneration: (j['maxGen'] as num?)?.toInt() ?? -1,
      generation: (j['gen'] as num?)?.toInt(),
      seq: (j['seq'] as num?)?.toInt() ?? 0,
      joinedAt: j['joinedAt'] is num ? DateTime.fromMillisecondsSinceEpoch((j['joinedAt'] as num).toInt()) : null,
      address: j['address'] as String?,
      retired: [for (final r in (j['retired'] as List? ?? const [])) ?RetiredListing.fromJson(r)],
      paymentsKey: j['paymentsKey'] as String?,
      payAs: j['payAs'] as String?,
      issued: BigInt.tryParse('${j['issued']}'),
    );
  }
}

/// The name services of one wallet, by serviceKey.
class NameServiceBook {
  const NameServiceBook([this.entries = const {}]);

  final Map<String, NameServiceEntry> entries;

  NameServiceEntry? byServiceKey(String serviceKey) => entries[serviceKey];

  NameServiceEntry? byPairing(String pairingId) =>
      entries.values.where((e) => e.pairingId == pairingId).firstOrNull;

  NameServiceBook put(NameServiceEntry e) => NameServiceBook({...entries, e.serviceKey: e});

  NameServiceBook remove(String serviceKey) => NameServiceBook({...entries}..remove(serviceKey));

  Map<String, Object?> toJson() => {'v': 1, 'entries': [for (final e in entries.values) e.toJson()]};

  static NameServiceBook? fromJson(Object? j) {
    if (j is! Map || j['v'] != 1) return null;
    final list = [for (final e in (j['entries'] as List? ?? const [])) ?NameServiceEntry.fromJson(e)];
    return NameServiceBook({for (final e in list) e.serviceKey: e});
  }
}
