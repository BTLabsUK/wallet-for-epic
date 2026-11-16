// SPDX-License-Identifier: Apache-2.0
/// The fonts the pairing screenshots tests load, so their pictures show real text.
library;

import 'dart:io';

import 'package:flutter/services.dart';

/// Roboto, the bundled Inter, Montserrat and JetBrains Mono, and the icon fonts, for the screenshots.
Future<void> loadShotFonts() async {
  final dir = '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async => ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final roboto = FontLoader('Roboto');
  for (final face in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']) {
    roboto.addFont(read('$dir/$face'));
  }
  await roboto.load();
  final inter = FontLoader('Inter');
  for (final face in ['Regular', 'Medium', 'SemiBold']) {
    inter.addFont(read('assets/fonts/Inter-$face.ttf'));
  }
  await inter.load();
  for (final (family, file) in [
    ('Lucide', 'assets/fonts/Lucide.ttf'),
    ('EpicStatusIcons', 'assets/fonts/EpicStatusIcons.ttf'),
    ('Montserrat', 'assets/fonts/Montserrat-SemiBold.ttf'),
    ('JetBrainsMonoNL', 'assets/fonts/JetBrainsMonoNL-Regular.ttf'),
    ('MaterialIcons', '$dir/MaterialIcons-Regular.otf'),
  ]) {
    await (FontLoader(family)..addFont(read(file))).load();
  }
}
