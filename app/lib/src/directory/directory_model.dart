// SPDX-License-Identifier: Apache-2.0
/// What one wallet keeps about the directories it paired with: the book of
/// `directory_service.dart`, kept by `directory_store.dart`. A directory is an ordinary contact
/// pairing whose peer sent a valid hello; nothing here knows which service it is.
library;

/// How long a retired listing is still read after Leave: payments sent to it before the
/// directory dropped it can still arrive.
const Duration listingDrainWindow = Duration(days: 7);

/// Where the wallet stands in one directory.
enum ListingState {
  /// Not listed: never joined, or left.
  notJoined,

  /// Listed: the directory has the card.
  joined,

  /// The directory sent `unlisted` for the current handle.
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

/// One directory contact. [dkey] and [handle] are hex (33 and 16 bytes).
class DirectoryEntry {
  const DirectoryEntry({
    required this.dkey,
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
  });

  final String dkey;
  final String pairingId;
  final String handle;

  /// The name the pairing last showed, for readers with no pairing at hand.
  final String label;

  /// The user compared the code (They match): the dkey belongs to this contact.
  final bool pinned;
  final ListingState state;

  /// The highest generation ever used for [dkey], -1 for none: a new listing takes one above,
  /// so a Leave never reuses one.
  final int maxGeneration;

  /// The generation listed now, null unless [state] is joined.
  final int? generation;

  /// The sequence number of the card the directory has.
  final int seq;
  final DateTime? joinedAt;

  /// The listing address of [generation].
  final String? address;
  final List<RetiredListing> retired;

  bool get joined => state == ListingState.joined;

  /// The generation a new listing takes.
  int get nextGeneration => maxGeneration + 1;

  DirectoryEntry copyWith({
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
  }) => DirectoryEntry(
    dkey: dkey,
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
  );

  /// The listings to read now: the joined one and the retired ones within their window.
  List<({int generation, String? address})> live(DateTime now) => [
    if (joined && generation != null) (generation: generation!, address: address),
    for (final r in retired)
      if (now.isBefore(r.drainUntil)) (generation: r.generation, address: r.address),
  ];

  Map<String, Object?> toJson() => {
    'dkey': dkey,
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
  };

  static DirectoryEntry? fromJson(Object? j) {
    if (j is! Map || j['dkey'] is! String || j['pairing'] is! String || j['handle'] is! String) return null;
    return DirectoryEntry(
      dkey: j['dkey'] as String,
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
    );
  }
}

/// The directories of one wallet, by dkey.
class DirectoryBook {
  const DirectoryBook([this.entries = const {}]);

  final Map<String, DirectoryEntry> entries;

  DirectoryEntry? byDkey(String dkey) => entries[dkey];

  DirectoryEntry? byPairing(String pairingId) =>
      entries.values.where((e) => e.pairingId == pairingId).firstOrNull;

  DirectoryBook put(DirectoryEntry e) => DirectoryBook({...entries, e.dkey: e});

  DirectoryBook remove(String dkey) => DirectoryBook({...entries}..remove(dkey));

  Map<String, Object?> toJson() => {'v': 1, 'entries': [for (final e in entries.values) e.toJson()]};

  static DirectoryBook? fromJson(Object? j) {
    if (j is! Map || j['v'] != 1) return null;
    final list = [for (final e in (j['entries'] as List? ?? const [])) ?DirectoryEntry.fromJson(e)];
    return DirectoryBook({for (final e in list) e.dkey: e});
  }
}
