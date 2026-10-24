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

import '../../data/desk_store.dart';
import '../../widgets/kit.dart';

/// The HTTP listener: off, starting or stopping, running, or failed to start
/// (`settings_http.dart` reads it from the status).
enum HttpRun { off, busy, on, failed }

/// The built-in node's address in the node field.
const String builtinNode = 'internal';

/// Where a jump into Settings lands: the node, a receiving group, or the Tor switch (Privacy).
enum SettingsJump { node, epicbox, http, tor }

/// A jump request: [n] changes on every request so the same section flashes again.
@immutable
class JumpTo {
  const JumpTo(this.section, this.n);

  final SettingsJump section;
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
  };

  factory SettingsPrefs.fromJson(Map<String, dynamic> j) {
    const d = SettingsPrefs();
    bool flag(String k, bool fallback) => j[k] is bool ? j[k] as bool : fallback;
    Set<String> names(String k) => {for (final v in (j[k] is List ? j[k] as List : const [])) '$v'};
    final labels = j['nodeLabels'];
    return SettingsPrefs(
      epicboxOnStart: flag('epicboxOnStart', d.epicboxOnStart),
      nodeBackground: flag('nodeBackground', d.nodeBackground),
      builtin: DeskFeatures.builtInNode && flag('builtin', d.builtin),
      nodeLabels: labels is Map ? {for (final e in labels.entries) '${e.key}': '${e.value}'} : const {},
      removedNodes: names('removedNodes'),
      walletLabel: j['walletLabel'] is String ? j['walletLabel'] as String : null,
      removedWallets: names('removedWallets'),
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

  /// Opens a settings section, scrolled to and flashed, also when it is open already.
  void jumpTo(SettingsJump section) {
    state = state.copyWith(jump: JumpTo(section, (state.jump?.n ?? 0) + 1));
    ref.read(deskNavProvider.notifier).go(switch (section) {
      SettingsJump.node => DeskRoute.settingsNode,
      SettingsJump.tor => DeskRoute.settingsPrivacy,
      _ => DeskRoute.settingsReceiving,
    });
  }
}

final settingsPrefsProvider = NotifierProvider<SettingsPrefsController, SettingsPrefs>(SettingsPrefsController.new);
