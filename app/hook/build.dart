// Builds rust/ (epic_wallet_core) through Dart native assets.
//
// The Android environment and C++ runtime bundling are adapted from
// cypherstack/flutter_libepiccash hook/build.dart (MIT, Copyright 2025 Cypher Stack LLC).
// epic-wallet pulls in C and C++ build scripts (RandomX via CMake, secp256k1-zkp, SQLite,
// LMDB, OpenSSL), which need the NDK compilers for the app's real minimum API, the NDK root for
// CMake, and libc++_shared.so shipped next to the library.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }
    final code = input.config.code;

    // Cargo's dep-info lists Rust sources but not these inputs.
    output.dependencies.addAll([
      for (final path in [
        'rust/Cargo.toml',
        'rust/Cargo.lock',
        'rust/rust-toolchain.toml',
      ])
        input.packageRoot.resolve(path),
    ]);

    await FlutterRustBridgeNativeAssetsBuilder(
      cratePath: 'rust',
      extraCargoBuildArgs: const ['--locked'],
      extraCargoEnvironmentVariables:
          code.targetOS == OS.android ? _androidCargoEnvironment(code) : const {},
    ).run(input: input, output: output);

    if (code.targetOS == OS.android) {
      await _bundleAndroidCxxRuntime(input, output);
    }
  });
}

Map<String, String> _androidCargoEnvironment(CodeConfig code) {
  final compiler = code.cCompiler;
  if (compiler == null) {
    throw StateError('Flutter did not provide an Android NDK compiler.');
  }
  final api = code.android.targetNdkApi;
  final target = _rustTarget(code);
  final envTarget = target.replaceAll('-', '_');
  final clangTarget =
      target == 'armv7-linux-androideabi' ? 'armv7a-linux-androideabi' : target;

  final binDir = File.fromUri(compiler.compiler).parent;
  final suffix = Platform.isWindows ? '.cmd' : '';
  final clang = '${binDir.path}/$clangTarget$api-clang$suffix';
  final clangPp = '${binDir.path}/$clangTarget$api-clang++$suffix';
  if (!File(clang).existsSync() || !File(clangPp).existsSync()) {
    throw StateError('The NDK has no API $api compiler wrappers for $target.');
  }

  final sysroot = binDir.parent.uri.resolve('sysroot/').toFilePath();
  final include = '${sysroot}usr/include/${_sysrootTarget(target)}';
  // <ndk>/toolchains/llvm/prebuilt/<host>/bin -> <ndk>
  var ndkRoot = binDir;
  for (var i = 0; i < 5; i++) {
    ndkRoot = ndkRoot.parent;
  }

  return {
    'CC_$envTarget': clang,
    'CXX_$envTarget': clangPp,
    'CARGO_TARGET_${envTarget.toUpperCase()}_LINKER': clang,
    'BINDGEN_EXTRA_CLANG_ARGS_$envTarget': "--sysroot='$sysroot' -I'$include'",
    'ANDROID_NDK_HOME': ndkRoot.path,
    'ANDROID_NDK_ROOT': ndkRoot.path,
  };
}

/// RandomX links libc++_shared (playground/patches/randomx-rust), so the APK must ship it.
Future<void> _bundleAndroidCxxRuntime(
  BuildInput input,
  BuildOutputBuilder output,
) async {
  final code = input.config.code;
  final binDir = File.fromUri(code.cCompiler!.compiler).parent;
  final source = File.fromUri(binDir.parent.uri.resolve(
    'sysroot/usr/lib/${_sysrootTarget(_rustTarget(code))}/libc++_shared.so',
  ));
  if (!source.existsSync()) {
    throw StateError('NDK C++ runtime not found: ${source.path}');
  }
  output.dependencies.add(source.uri);
  final bundled = File.fromUri(input.outputDirectory.resolve('libc++_shared.so'));
  await bundled.parent.create(recursive: true);
  await source.copy(bundled.path);
  output.assets.code.add(
    CodeAsset(
      package: input.packageName,
      name: 'libc++_shared.so',
      linkMode: DynamicLoadingBundled(),
      file: bundled.uri,
    ),
  );
}

String _sysrootTarget(String target) =>
    target == 'armv7-linux-androideabi' ? 'arm-linux-androideabi' : target;

String _rustTarget(CodeConfig code) => switch (code.targetArchitecture) {
      Architecture.arm => 'armv7-linux-androideabi',
      Architecture.arm64 => 'aarch64-linux-android',
      Architecture.x64 => 'x86_64-linux-android',
      _ => throw UnsupportedError(
          'Unsupported Android architecture: ${code.targetArchitecture}',
        ),
    };
