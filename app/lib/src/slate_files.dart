/// Transaction files, the way epic-wallet's CLI exchanges them: the sender writes a slate file
/// (`send -m file`), the recipient answers with `<same name>.response` (`receive -i`), and the
/// sender finalizes that (`finalize -i`). The contents are slate JSON.
///
/// Phones hand files over through the share sheet; desktops through a save dialog.
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Slate files are a few kilobytes; anything far larger is not one.
const int maxSlateFileBytes = 1 << 20;

/// A transaction file read from disk.
class SlateFile {
  const SlateFile({required this.name, required this.json});

  final String name;
  final String json;
}

/// The file name for a new send, `<slate id>.tx`, as the CLI examples use.
String sendFileName(String slateId) => '$slateId.tx';

/// The CLI's answer name: the incoming file's name plus `.response`.
String responseFileName(String incomingName) => '$incomingName.response';

/// Reads a picked file's bytes as slate JSON, refusing files that cannot be one.
String decodeSlateFile(List<int> bytes) {
  if (bytes.length > maxSlateFileBytes) {
    throw const FormatException(
      'That file is too large to be a transaction file.',
    );
  }
  final String text;
  try {
    text = utf8.decode(bytes).trim();
  } on FormatException {
    throw const FormatException('That file is not a transaction file.');
  }
  if (!text.startsWith('{')) {
    throw const FormatException('That file is not a transaction file.');
  }
  return text;
}

abstract interface class SlateFiles {
  /// Hands [json] over as a file called [name]. Returns false if the user cancelled.
  Future<bool> export({required String name, required String json});

  /// Lets the user pick a transaction file, or returns null if they cancelled.
  Future<SlateFile?> pick();
}

class PlatformSlateFiles implements SlateFiles {
  const PlatformSlateFiles();

  static bool get _mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<bool> export({required String name, required String json}) async {
    final bytes = Uint8List.fromList(utf8.encode(json));
    if (!_mobile) {
      final saved = await FilePicker.saveFile(
        fileName: name,
        bytes: bytes,
        dialogTitle: 'Save transaction file',
      );
      return saved != null;
    }
    // The share sheet needs a real file; it lives in the cache and is replaced next time.
    final dir = Directory(
      '${(await getTemporaryDirectory()).path}${Platform.pathSeparator}slates',
    );
    await dir.create(recursive: true);
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes, flush: true);
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/octet-stream')],
        fileNameOverrides: [name],
        subject: name,
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  }

  @override
  Future<SlateFile?> pick() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Open transaction file',
    );
    if (file == null) return null;
    final length = await file.length();
    if (length != null && length > maxSlateFileBytes) {
      throw const FormatException(
        'That file is too large to be a transaction file.',
      );
    }
    return SlateFile(
      name: file.name,
      json: decodeSlateFile(await file.readAsBytes()),
    );
  }
}

/// Records exports and hands out queued picks, for widget tests.
class FakeSlateFiles implements SlateFiles {
  final List<SlateFile> exported = [];
  final List<SlateFile?> picks = [];

  @override
  Future<bool> export({required String name, required String json}) async {
    exported.add(SlateFile(name: name, json: json));
    return true;
  }

  @override
  Future<SlateFile?> pick() async => picks.isEmpty ? null : picks.removeAt(0);
}

final slateFilesProvider = Provider<SlateFiles>(
  (ref) => const PlatformSlateFiles(),
);

/// Transaction files other apps hand to the wallet (Android VIEW and SEND intents), waiting
/// until a wallet is open to handle them.
final incomingSlateProvider =
    NotifierProvider<IncomingSlateNotifier, SlateFile?>(
      IncomingSlateNotifier.new,
    );

class IncomingSlateNotifier extends Notifier<SlateFile?> {
  static const MethodChannel _channel = MethodChannel(
    'epic_wallet/incoming_slate',
  );

  @override
  SlateFile? build() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'incoming') throw MissingPluginException();
      _accept(call.arguments);
    });
    ref.onDispose(() => _channel.setMethodCallHandler(null));
    _channel
        .invokeMethod<Object?>('takePending')
        .then(_accept)
        .catchError((Object _) {});
    return null;
  }

  void _accept(Object? arguments) {
    if (arguments is! Map) return;
    final name = arguments['name'];
    final text = arguments['text'];
    if (name is! String || text is! String) return;
    state = SlateFile(name: name, json: text.trim());
  }

  /// Hands the waiting file over and forgets it.
  SlateFile? take() {
    final file = state;
    state = null;
    return file;
  }

  /// For tests.
  void deliver(SlateFile file) => state = file;
}
