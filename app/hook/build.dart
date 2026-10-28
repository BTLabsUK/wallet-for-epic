// Bundles the lepic-ffi library into macOS builds. package:lepic's own hook bundles it for
// Android, iOS, Linux and Windows but not macOS, so the app adds it here until the binding does.
// Flutter makes `liblepic_ffi.dylib` into `lepic_ffi.framework/lepic_ffi` in Contents/Frameworks
// (one per architecture, joined with lipo), the name flutter_rust_bridge opens on macOS, so
// initLepic needs no path.
//
// The libraries come from `tools/build-apple.sh`, in the binding's own layout:
// `third_party/lepic-flutter/native/<rust target>/liblepic_ffi.dylib` beside a `SHA256SUMS`.
// Every other system gets nothing from this hook.

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }
    final code = input.config.code;
    if (code.targetOS != OS.macOS) {
      return;
    }
    final target = switch (code.targetArchitecture) {
      Architecture.arm64 => 'aarch64-apple-darwin',
      Architecture.x64 => 'x86_64-apple-darwin',
      final arch => throw UnsupportedError('LEPIC has no macOS $arch build.'),
    };
    final dir = input.packageRoot.resolve('third_party/lepic-flutter/native/$target/');
    final library = File.fromUri(dir.resolve('liblepic_ffi.dylib'));
    final manifest = File.fromUri(dir.resolve('SHA256SUMS'));
    if (!library.existsSync() || !manifest.existsSync()) {
      throw StateError(
        'No $target library and SHA256SUMS in ${dir.toFilePath()}. '
        'Run tools/build-apple.sh lepic on the Mac.',
      );
    }
    final recorded = manifest
        .readAsLinesSync()
        .map((line) => line.split(RegExp(r' [ *]')))
        .where((parts) => parts.length == 2 && parts[1] == 'liblepic_ffi.dylib')
        .map((parts) => parts[0])
        .toList();
    final actual = sha256.convert(library.readAsBytesSync()).toString();
    if (recorded.length != 1 || recorded.single != actual) {
      throw StateError(
        '${library.path} does not match its SHA-256 in ${manifest.path}. '
        'Run tools/build-apple.sh lepic again.',
      );
    }
    output.dependencies
      ..add(library.uri)
      ..add(manifest.uri);
    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: 'lepic_ffi',
        linkMode: DynamicLoadingBundled(),
        file: library.uri,
      ),
    );
  });
}
