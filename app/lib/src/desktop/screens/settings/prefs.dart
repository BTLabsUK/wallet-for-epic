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

/// The HTTP listener: off, starting or stopping, running, or failed to start.
enum HttpRun { off, busy, on, failed }

/// Why the HTTP listener did not start.
enum HttpFail { portInUse, node, error }

/// The built-in node's address in the node field.
const String builtinNode = 'internal';

/// Where a jump into Settings lands: the node or the receiving section.
enum SettingsJump { node, epicbox }

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
    this.httpAutostart = false,
    this.nodeBackground = false,
    this.builtin = false,
    this.typedNode,
    this.http = HttpRun.off,
    this.httpFail,
    this.nodeLabels = const {},
    this.removedNodes = const {},
    this.walletLabel,
    this.removedWallets = const {},
    this.jump,
  });

  final bool epicboxOnStart;
  final bool httpAutostart;
  final bool nodeBackground;

  /// The built-in node is in use instead of a remote one.
  final bool builtin;

  /// A remote node used by address that is in no list (the mock's status knows only listed ones).
  final NodeServer? typedNode;
  final HttpRun http;
  final HttpFail? httpFail;

  /// My nodes: address → label (empty = none).
  final Map<String, String> nodeLabels;
  final Set<String> removedNodes;
  final String? walletLabel;

  /// Folders of wallets taken off the list.
  final Set<String> removedWallets;
  final JumpTo? jump;

  /// The part that is saved: choices, not run state.
  Map<String, Object?> toJson() => {
    'epicboxOnStart': epicboxOnStart,
    'httpAutostart': httpAutostart,
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
      httpAutostart: flag('httpAutostart', d.httpAutostart),
      nodeBackground: flag('nodeBackground', d.nodeBackground),
      builtin: DeskFeatures.builtInNode && flag('builtin', d.builtin),
      nodeLabels: labels is Map ? {for (final e in labels.entries) '${e.key}': '${e.value}'} : const {},
      removedNodes: names('removedNodes'),
      walletLabel: j['walletLabel'] as String?,
      removedWallets: names('removedWallets'),
    );
  }

  SettingsPrefs copyWith({
    bool? epicboxOnStart,
    bool? httpAutostart,
    bool? nodeBackground,
    bool? builtin,
    NodeServer? typedNode,
    bool clearTyped = false,
    HttpRun? http,
    HttpFail? httpFail,
    bool clearFail = false,
    Map<String, String>? nodeLabels,
    Set<String>? removedNodes,
    String? walletLabel,
    Set<String>? removedWallets,
    JumpTo? jump,
  }) => SettingsPrefs(
    epicboxOnStart: epicboxOnStart ?? this.epicboxOnStart,
    httpAutostart: httpAutostart ?? this.httpAutostart,
    nodeBackground: nodeBackground ?? this.nodeBackground,
    builtin: builtin ?? this.builtin,
    typedNode: clearTyped ? null : (typedNode ?? this.typedNode),
    http: http ?? this.http,
    httpFail: clearFail ? null : (httpFail ?? this.httpFail),
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
      unawaited(store.writeJson(DeskStore.prefsKey, json));
    });
    final saved = ref.read(deskBootProvider).prefs;
    return saved == null ? const SettingsPrefs() : SettingsPrefs.fromJson(saved);
  }

  void set(SettingsPrefs p) => state = p;

  /// Starts or stops the HTTP listener (the mock takes a moment). [fail] makes the start fail.
  Future<void> setHttp(bool on, {HttpFail? fail}) async {
    state = state.copyWith(http: HttpRun.busy, clearFail: true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final desk = ref.read(deskProvider.notifier);
    final s = ref.read(deskProvider).settings;
    if (on && fail != null) {
      state = state.copyWith(http: HttpRun.failed, httpFail: fail);
      return;
    }
    state = state.copyWith(http: on ? HttpRun.on : HttpRun.off);
    await desk.saveSettings(s.copyWith(directHttp: on));
  }

  void label(String address, String label) => state = state.copyWith(nodeLabels: {...state.nodeLabels, address: label});

  void forgetNode(String address) => state = state.copyWith(removedNodes: {...state.removedNodes, address});

  void restoreNode(String address) => state = state.copyWith(removedNodes: {...state.removedNodes}..remove(address));

  void removeWallet(String folder) => state = state.copyWith(removedWallets: {...state.removedWallets, folder});

  /// Opens a settings section, scrolled to and flashed, also when it is open already.
  void jumpTo(SettingsJump section) {
    state = state.copyWith(jump: JumpTo(section, (state.jump?.n ?? 0) + 1));
    ref.read(deskNavProvider.notifier).go(section == SettingsJump.node ? DeskRoute.settingsNode : DeskRoute.settingsReceiving);
  }
}

final settingsPrefsProvider = NotifierProvider<SettingsPrefsController, SettingsPrefs>(SettingsPrefsController.new);
