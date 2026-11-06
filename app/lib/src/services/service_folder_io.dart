// SPDX-License-Identifier: Apache-2.0
/// `service_folder.dart` off the web.
library;

import 'dart:io';

import '../data_folder.dart';
import '../log.dart';
import 'service_loader.dart';
import 'service_rules.dart';

/// The folder `services` in the data folder on the desktop, read at start and never written.
/// Phones read the bundled files alone.
Future<List<ServiceSource>> droppedServices() async {
  if (!(Platform.isLinux || Platform.isWindows || Platform.isMacOS)) return const [];
  final data = await appDataDirectory();
  return [DroppedServices(Directory('${data.path}${Platform.pathSeparator}services'))];
}

/// The `.json` files directly in [folder]. No folder: none.
final class DroppedServices implements ServiceSource {
  const DroppedServices(this.folder);
  final Directory folder;

  @override
  String get label => 'dropped';

  @override
  Future<List<ServiceBytes>> read() async {
    if (!await folder.exists()) return const [];
    final files = await folder.list(followLinks: false).where((e) => e is File && e.path.endsWith('.json')).cast<File>().toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    if (files.length > maxServiceFiles) logWarn('services', 'dropped: more than $maxServiceFiles files');
    final read = <ServiceBytes>[];
    for (final file in files.take(maxServiceFiles)) {
      final name = file.uri.pathSegments.last;
      try {
        // One byte past the limit is enough for the loader to refuse it, however large it is.
        read.add(ServiceBytes(name, await file.openRead(0, maxServiceFileBytes + 1).expand((b) => b).toList()));
      } on FileSystemException catch (e) {
        logWarn('services', 'dropped $name: not read: ${e.message}');
      }
    }
    return read;
  }
}
