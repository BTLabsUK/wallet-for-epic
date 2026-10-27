/// The app's clipboard for the pairing offer ([ClipboardProbe]): on Android the clip's stamp
/// comes from MainActivity's `epic_wallet/clipboard` channel, so a clip is read once; the
/// desktop reads silently; the web reads nothing (the browser would ask every time).
library;

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pairing_clipboard.dart';

class PlatformClipboardProbe implements ClipboardProbe {
  const PlatformClipboardProbe();

  static const _channel = MethodChannel('epic_wallet/clipboard');

  static bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  bool get silent => !_android;

  @override
  Future<ClipStamp?> stamp() async {
    if (kIsWeb) return null;
    if (!_android) return const ClipStamp(hasText: true);
    final m = await _channel.invokeMapMethod<String, Object?>('clipStamp');
    if (m == null) return null;
    final time = m['time'];
    return ClipStamp(time: time is int ? time : null, hasText: m['hasText'] == true);
  }

  @override
  Future<String?> read() async => (await Clipboard.getData(Clipboard.kTextPlain))?.text;
}

/// The clipboard the pairing offer reads; tests override it.
final pairingClipProbeProvider = Provider<ClipboardProbe>((ref) => const PlatformClipboardProbe());

/// One reader per app, so a clip is read once whichever screen looks.
final pairingClipReaderProvider = Provider<PairingClipReader>((ref) => PairingClipReader(ref.watch(pairingClipProbeProvider)));
