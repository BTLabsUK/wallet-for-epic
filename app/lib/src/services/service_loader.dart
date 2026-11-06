// SPDX-License-Identifier: Apache-2.0
/// Reads the service files at start. Each source is a list of files; a new source (a signed
/// list, say) is one more [ServiceSource] with the same format. Nothing here can stop the app:
/// a bad file is skipped and logged, the others still load, and no files at all means no hints.
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import '../log.dart';
import 'service_folder.dart';
import 'service_rules.dart';

/// One file of a source. [bytes] may stop just past [maxServiceFileBytes].
final class ServiceBytes {
  const ServiceBytes(this.name, this.bytes);
  final String name;
  final List<int> bytes;
}

/// Where service files come from.
abstract interface class ServiceSource {
  /// For the log.
  String get label;

  /// At most [maxServiceFiles] files, in name order.
  Future<List<ServiceBytes>> read();
}

/// The folder of bundled files: every `.json` directly in it, whatever else it holds.
const String bundledServicesFolder = 'assets/services/';

/// The files shipped with the app.
final class BundledServices implements ServiceSource {
  const BundledServices(this.bundle);
  final AssetBundle bundle;

  @override
  String get label => 'bundled';

  @override
  Future<List<ServiceBytes>> read() async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final paths = manifest.listAssets().where(_isServiceFile).toList()..sort();
    if (paths.length > maxServiceFiles) logWarn('services', 'bundled: more than $maxServiceFiles files');
    return [
      for (final path in paths.take(maxServiceFiles))
        ServiceBytes(path.substring(bundledServicesFolder.length), (await bundle.load(path)).buffer.asUint8List()),
    ];
  }

  bool _isServiceFile(String path) =>
      path.startsWith(bundledServicesFolder) && path.endsWith('.json') && !path.substring(bundledServicesFolder.length).contains('/');
}

/// The rules of [sources], read in order. A file whose id an earlier one holds is skipped, so a
/// later source can add rules and never replace one; and rules only add ([ServiceRules]).
Future<ServiceRules> loadServices(List<ServiceSource> sources) async {
  final files = <String, ServiceFile>{};
  for (final source in sources) {
    try {
      for (final item in await source.read()) {
        final file = _read(source, item);
        if (file == null) continue;
        if (files.containsKey(file.id)) {
          logWarn('services', '${source.label} ${item.name}: id ${file.id} is taken, skipped');
          continue;
        }
        files[file.id] = file;
      }
    } catch (e) {
      logWarn('services', '${source.label}: not read: $e');
    }
  }
  return ServiceRules.from(files.values);
}

ServiceFile? _read(ServiceSource source, ServiceBytes item) {
  try {
    if (item.bytes.length > maxServiceFileBytes) throw const ServiceFileRefused('too large');
    final file = parseServiceFile(utf8.decode(item.bytes));
    for (final why in file.skipped) {
      logWarn('services', '${source.label} ${item.name}: $why');
    }
    return file;
  } catch (e) {
    logWarn('services', '${source.label} ${item.name}: skipped: $e');
    return null;
  }
}

/// Reads the service files for this run into [serviceRules]: the bundled ones, and on the
/// desktop the folder `services` in the data folder.
Future<void> startServices({AssetBundle? bundle}) async {
  serviceRules = await loadServices([BundledServices(bundle ?? rootBundle), ...await droppedServices()]);
}
