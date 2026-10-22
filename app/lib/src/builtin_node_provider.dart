/// Riverpod wiring for the opt-in built-in node (desktop only). Nothing here starts a node by
/// itself: with the setting off (the default) no provider is read and behaviour is unchanged.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'builtin_node.dart';
import 'models.dart' show Chain;
import 'providers.dart';

/// Whether the platform can have a built-in node at all: desktop only, never phones.
bool get builtInNodeSupported =>
    Platform.isLinux || Platform.isWindows || Platform.isMacOS;

/// [builtInNodeSupported] as a provider, so tests can stand in for a phone.
final builtInNodeSupportedProvider = Provider<bool>(
  (ref) => builtInNodeSupported,
);

/// Where the node's folders and the bundled binary are. Tests and the desktop shell override it.
class BuiltInNodeLocation {
  const BuiltInNodeLocation({required this.root, required this.binary});

  final String root;
  final String binary;
}

/// `<app support>/node` and the `epic` binary shipped next to the app: `bin/epic` beside the
/// executable on Linux and Windows (`epic.exe`), `Contents/Resources/bin/epic` on macOS.
final builtInNodeLocationProvider = FutureProvider<BuiltInNodeLocation>((
  ref,
) async {
  final support = await getApplicationSupportDirectory();
  final sep = Platform.pathSeparator;
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  final name = Platform.isWindows ? 'epic.exe' : 'epic';
  final binary = Platform.isMacOS
      ? '${Directory(exeDir).parent.path}${sep}Resources${sep}bin$sep$name'
      : '$exeDir${sep}bin$sep$name';
  return BuiltInNodeLocation(root: '${support.path}${sep}node', binary: binary);
});

/// Whether the user turned the built-in node on for a chain (`node.builtin.<chain>`). False
/// unless set, and always false where it is not supported.
final builtInNodeEnabledProvider =
    AsyncNotifierProvider.family<BuiltInNodeEnabledNotifier, bool, Chain>(
      BuiltInNodeEnabledNotifier.new,
    );

class BuiltInNodeEnabledNotifier extends AsyncNotifier<bool> {
  BuiltInNodeEnabledNotifier(this.chain);

  final Chain chain;

  @override
  Future<bool> build() async {
    if (!builtInNodeSupported) return false;
    final raw = await ref
        .watch(secretStoreProvider)
        .read(builtInNodeSettingKey(chain));
    return raw == 'true';
  }

  Future<void> set(bool on) async {
    if (!builtInNodeSupported) return;
    await ref
        .read(secretStoreProvider)
        .write(builtInNodeSettingKey(chain), '$on');
    state = AsyncData(on);
  }
}

/// The node object of a chain. Reading it starts nothing; call `start()` (and `stop()`). Throws
/// [UnsupportedError] where there is no built-in node (phones). When the provider is disposed the
/// node is stopped, but a dispose callback cannot be awaited: the app's exit hook should await
/// [stopAllBuiltInNodes] (`AppLifecycleListener(onExitRequested: ...)`).
final builtInNodeProvider = FutureProvider.family<BuiltInNode, Chain>((
  ref,
  chain,
) async {
  if (!ref.watch(builtInNodeSupportedProvider)) {
    throw UnsupportedError('The built-in node is only available on desktop');
  }
  final where = await ref.watch(builtInNodeLocationProvider.future);
  final node = BuiltInNode(
    root: where.root,
    binary: where.binary,
    chain: chain,
  );
  ref.onDispose(() => unawaited(node.dispose()));
  return node;
});

/// The node's state as it changes.
final builtInNodeStateProvider = StreamProvider.family<BuiltInNodeState, Chain>(
  (ref, chain) async* {
    final node = await ref.watch(builtInNodeProvider(chain).future);
    yield node.state;
    yield* node.states;
  },
);
