/// Settings the mock keeps for the settings screens and the shell's status rows only: what
/// 6.1.6 saves in its config (start Epicbox / HTTP with the wallet, built-in node, sync in
/// background), the HTTP listener's run state, My nodes' labels and the wallet list edits.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  SettingsPrefs build() => const SettingsPrefs();

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
