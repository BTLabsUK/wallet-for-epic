// SPDX-License-Identifier: Apache-2.0
/// Settings the settings screens and the shell's status rows share: what 6.1.6 saves in its
/// config (start Epicbox / HTTP with the wallet, built-in node, sync in background), the HTTP
/// listener's run state, My nodes' labels and the wallet list edits. The saved part
/// ([SettingsPrefs.toJson]) goes to [DeskStore] on every change and comes back before the
/// first frame ([DeskBoot.prefs]).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../levels/level_features.dart' show AdvancedPageKind;
import '../../data/desk_levels.dart' show deskLevelFeaturesProvider;
import '../../data/desk_store.dart';
import '../../data/settings_registry.dart' show settingsEntry;
import '../../widgets/kit.dart';

/// The HTTP listener: off, starting or stopping, running, or failed to start
/// (`settings_http.dart` reads it from the status).
enum HttpRun { off, busy, on, failed }

/// The built-in node's address in the node field.
const String builtinNode = 'internal';

/// Where a jump into Settings lands: the node, a receiving group, or the Tor switch (Privacy).
enum SettingsJump { node, epicbox, http, tor, confirmations, network }

/// A jump request: [n] changes on every request so the same section flashes again. A jump to
/// a section names [section]; a jump to one row (search) names its [row] id instead.
@immutable
class JumpTo {
  const JumpTo(SettingsJump this.section, this.n) : row = null;
  const JumpTo.row(String this.row, this.n) : section = null;

  final SettingsJump? section;

  /// The row's id ([SetId]).
  final String? row;
  final int n;
}

@immutable
class SettingsPrefs {
  const SettingsPrefs({
    this.epicboxOnStart = true,
    this.nodeBackground = false,
    this.builtin = false,
    this.typedNode,
    this.nodeLabels = const {},
    this.removedNodes = const {},
    this.walletLabel,
    this.removedWallets = const {},
    this.mineNodes = const {},
    this.ownFallback = const {},
    this.plainHttpSeen = const {},
    this.updateSeen,
    this.jump,
  });

  final bool epicboxOnStart;
  final bool nodeBackground;

  /// The built-in node is in use instead of a remote one.
  final bool builtin;

  /// A remote node used by address that is in no list (the mock's status knows only listed ones).
  final NodeServer? typedNode;

  /// The old My nodes' labels: address → label (empty = none), shown as an own node's operator.
  final Map<String, String> nodeLabels;

  /// Nodes the old Settings › Node took out: they start removed in the node list
  /// (`server_lists.dart`), which keeps removals itself from then on.
  final Set<String> removedNodes;
  final String? walletLabel;

  /// Folders of wallets taken off the list.
  final Set<String> removedWallets;

  /// Listed nodes the user marked as their own ("Mine"): asked directly, owner access offered.
  final Set<String> mineNodes;

  /// An own node's answer to "Use a public node until it is synced?", by node URL.
  final Map<String, bool> ownFallback;

  /// Own nodes whose plain-http owner secret warning is not shown again.
  final Set<String> plainHttpSeen;

  /// The newest version whose update strip (`app/update_strip.dart`) was closed: the strip
  /// stays away for it and comes back for a newer one. The sidebar's slot shows regardless.
  final String? updateSeen;

  final JumpTo? jump;

  /// The part that is saved: choices, not run state.
  Map<String, Object?> toJson() => {
    'epicboxOnStart': epicboxOnStart,
    'nodeBackground': nodeBackground,
    'builtin': builtin,
    'nodeLabels': nodeLabels,
    'removedNodes': removedNodes.toList(),
    'walletLabel': walletLabel,
    'removedWallets': removedWallets.toList(),
    'mineNodes': mineNodes.toList(),
    'ownFallback': ownFallback,
    'plainHttpSeen': plainHttpSeen.toList(),
    'updateSeen': updateSeen,
  };

  factory SettingsPrefs.fromJson(Map<String, dynamic> j) {
    const d = SettingsPrefs();
    bool flag(String k, bool fallback) => j[k] is bool ? j[k] as bool : fallback;
    Set<String> names(String k) => {for (final v in (j[k] is List ? j[k] as List : const [])) '$v'};
    final labels = j['nodeLabels'];
    final fallback = j['ownFallback'];
    return SettingsPrefs(
      epicboxOnStart: flag('epicboxOnStart', d.epicboxOnStart),
      nodeBackground: flag('nodeBackground', d.nodeBackground),
      builtin: flag('builtin', d.builtin),
      nodeLabels: labels is Map ? {for (final e in labels.entries) '${e.key}': '${e.value}'} : const {},
      removedNodes: names('removedNodes'),
      walletLabel: j['walletLabel'] is String ? j['walletLabel'] as String : null,
      removedWallets: names('removedWallets'),
      mineNodes: names('mineNodes'),
      ownFallback: fallback is Map ? {for (final e in fallback.entries) if (e.value is bool) '${e.key}': e.value as bool} : const {},
      plainHttpSeen: names('plainHttpSeen'),
      updateSeen: j['updateSeen'] is String ? j['updateSeen'] as String : null,
    );
  }

  SettingsPrefs copyWith({
    bool? epicboxOnStart,
    bool? nodeBackground,
    bool? builtin,
    NodeServer? typedNode,
    bool clearTyped = false,
    Map<String, String>? nodeLabels,
    Set<String>? removedNodes,
    String? walletLabel,
    Set<String>? removedWallets,
    Set<String>? mineNodes,
    Map<String, bool>? ownFallback,
    Set<String>? plainHttpSeen,
    String? updateSeen,
    JumpTo? jump,
  }) => SettingsPrefs(
    epicboxOnStart: epicboxOnStart ?? this.epicboxOnStart,
    nodeBackground: nodeBackground ?? this.nodeBackground,
    builtin: builtin ?? this.builtin,
    typedNode: clearTyped ? null : (typedNode ?? this.typedNode),
    nodeLabels: nodeLabels ?? this.nodeLabels,
    removedNodes: removedNodes ?? this.removedNodes,
    walletLabel: walletLabel ?? this.walletLabel,
    removedWallets: removedWallets ?? this.removedWallets,
    mineNodes: mineNodes ?? this.mineNodes,
    ownFallback: ownFallback ?? this.ownFallback,
    plainHttpSeen: plainHttpSeen ?? this.plainHttpSeen,
    updateSeen: updateSeen ?? this.updateSeen,
    jump: jump ?? this.jump,
  );
}

class SettingsPrefsController extends Notifier<SettingsPrefs> {
  @override
  SettingsPrefs build() {
    listenSelf((prev, next) {
      final store = ref.read(deskStoreProvider);
      if (store == null || prev == null) return;
      final json = next.toJson();
      if (jsonEncode(json) == jsonEncode(prev.toJson())) return;
      unawaited(store.savePrefs(json));
    });
    final saved = ref.read(deskBootProvider).prefs;
    return saved == null ? const SettingsPrefs() : SettingsPrefs.fromJson(saved);
  }

  void set(SettingsPrefs p) => state = p;

  void removeWallet(String folder) => state = state.copyWith(removedWallets: {...state.removedWallets, folder});

  /// The update strip was closed for [version]: not again until a newer one.
  void hideUpdateStrip(String version) => state = state.copyWith(updateSeen: version);

  /// Opens the page of row [id] ([SetId]) and shows the row there: scrolled into view, its
  /// control focused, the gold outline fading ([ESetAnchors]). A row that sits under another
  /// and is not on the page now (Receiving while Epicbox is off) shows that one instead. A row
  /// the registry does not know opens nothing.
  void jumpToRow(String id) {
    final e = settingsEntry(id);
    if (e == null) return;
    state = state.copyWith(jump: JumpTo.row(id, (state.jump?.n ?? 0) + 1));
    ref.read(deskNavProvider.notifier).go(e.route);
    unawaited(ESetAnchors.jump(id, fallback: e.parent));
  }

  /// Opens a settings section, scrolled to and flashed, also when it is open already.
  void jumpTo(SettingsJump section) {
    state = state.copyWith(jump: JumpTo(section, (state.jump?.n ?? 0) + 1));
    ref.read(deskNavProvider.notifier).go(switch (section) {
      SettingsJump.node => DeskRoute.settingsNode,
      SettingsJump.tor => DeskRoute.settingsPrivacy,
      // The mode is on Network & privacy; at Shallow (no mode there) Advanced, the way out.
      SettingsJump.network =>
        ref.read(deskLevelFeaturesProvider).advancedPage == AdvancedPageKind.full ? DeskRoute.settingsPrivacy : DeskRoute.settingsAdvanced,
      SettingsJump.confirmations => DeskRoute.settingsAdvanced,
      _ => DeskRoute.settingsReceiving,
    });
  }
}

final settingsPrefsProvider = NotifierProvider<SettingsPrefsController, SettingsPrefs>(SettingsPrefsController.new);
