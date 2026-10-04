/// Transaction files, the way epic-wallet's CLI exchanges them: the sender writes a slate file
/// (`send -m file`), the recipient answers with `<same name>.response` (`receive -i`), and the
/// sender finalizes that (`finalize -i`). The contents are slate JSON.
///
/// Files go out through the system save dialog, or on phones through the share sheet.
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'app_log.dart';
import 'l10n.dart' show LocalizedFormatException;

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
    throw LocalizedFormatException((l) => l.slateFileTooLarge);
  }
  final String text;
  try {
    text = utf8.decode(bytes).trim();
  } on FormatException {
    throw LocalizedFormatException((l) => l.slateNotTransactionFile);
  }
  if (!text.startsWith('{')) {
    throw LocalizedFormatException((l) => l.slateNotTransactionFile);
  }
  return text;
}

/// Whether this platform has a share sheet that takes files.
bool get canShareFiles =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Lets the user choose where to save [bytes] as [name]: the system save dialog, which on
/// Android is the Storage Access Framework (Downloads, Drive, a USB stick). Returns false if the
/// user cancelled. Also used for history backups.
Future<bool> saveBytesToDevice({
  required String name,
  required Uint8List bytes,
  required String dialogTitle,
}) async {
  final saved = await FilePicker.saveFile(
    fileName: name,
    bytes: bytes,
    dialogTitle: dialogTitle,
  );
  return saved != null;
}

/// Hands [bytes] to another app through the share sheet, as a file called [name]. Returns
/// false if the user dismissed it. Only where [canShareFiles].
///
/// The share sheet needs a real file. It is written to `<tmp>/shared` and deleted as soon as the
/// sheet returns: on Android share_plus has copied it into its own cache by then, and on iOS the
/// receiving app has read it. [mimeType] tells the receiving app what it is; [text] goes along
/// as the message, where the app takes one. [share] and [tempDir] are for tests.
Future<bool> shareBytes({
  required String name,
  required Uint8List bytes,
  String mimeType = 'application/octet-stream',
  String? text,
  @visibleForTesting Future<ShareResult> Function(ShareParams params)? share,
  @visibleForTesting Directory? tempDir,
}) async {
  final tmp = tempDir ?? await getTemporaryDirectory();
  final dir = Directory('${tmp.path}${Platform.pathSeparator}$_sharedDir');
  await dir.create(recursive: true);
  final file = File('${dir.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(bytes, flush: true);
  try {
    final result = await (share ?? SharePlus.instance.share)(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        fileNameOverrides: [name],
        // A message app shows the subject as text too; with a message, that is enough.
        subject: text == null ? name : null,
        text: text,
      ),
    );
    return result.status != ShareResultStatus.dismissed;
  } finally {
    if (await file.exists()) await file.delete();
  }
}

const String _sharedDir = 'shared';

/// Cache folders that can hold copies of shared files: ours, share_plus's own copy on Android
/// (`<cache>/share_plus`, cleared by the plugin only at the next share), and the folder older
/// versions of this app used for transaction files.
const List<String> _shareCaches = [_sharedDir, 'share_plus', 'slates'];

/// Deletes every leftover copy of a shared file (transaction files, history backups, CSV). Call
/// it when the wallet is deleted. [tempDir] is for tests.
Future<void> clearSharedFiles({@visibleForTesting Directory? tempDir}) async {
  final tmp = tempDir ?? await getTemporaryDirectory();
  for (final name in _shareCaches) {
    final dir = Directory('${tmp.path}${Platform.pathSeparator}$name');
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

abstract interface class SlateFiles {
  /// Saves [json] as a file called [name] where the user chooses, in a system dialog titled
  /// [dialogTitle]. Returns false if they cancelled.
  Future<bool> save({
    required String name,
    required String json,
    required String dialogTitle,
  });

  /// Whether [share] works here. Many phones' share sheets have no "save to files" target, so
  /// [save] comes first and sharing is the second option.
  bool get canShare;

  /// Hands [json] over as a file called [name] through the share sheet. Returns false if the
  /// user dismissed it.
  Future<bool> share({required String name, required String json});

  /// Lets the user pick a transaction file in a system dialog titled [dialogTitle], or returns
  /// null if they cancelled.
  Future<SlateFile?> pick({required String dialogTitle});

  /// Whether [shareText] opens a share sheet on this platform.
  bool get canShareText;

  /// Shares plain [text], such as the wallet's address, through the share sheet.
  Future<void> shareText(String text);

  /// Shares a PNG [png] called [name] with [text] as its message, through the share sheet, so
  /// a chat shows the picture and the text stays copyable. Only where [canShare].
  Future<void> shareImage({
    required String name,
    required Uint8List png,
    required String text,
  });
}

class PlatformSlateFiles implements SlateFiles {
  const PlatformSlateFiles();

  @override
  Future<bool> save({
    required String name,
    required String json,
    required String dialogTitle,
  }) => saveBytesToDevice(
    name: name,
    bytes: Uint8List.fromList(utf8.encode(json)),
    dialogTitle: dialogTitle,
  );

  @override
  bool get canShare => canShareFiles;

  @override
  Future<bool> share({required String name, required String json}) =>
      shareBytes(name: name, bytes: Uint8List.fromList(utf8.encode(json)));

  @override
  Future<SlateFile?> pick({required String dialogTitle}) async {
    final file = await FilePicker.pickFile(dialogTitle: dialogTitle);
    if (file == null) return null;
    final length = await file.length();
    if (length != null && length > maxSlateFileBytes) {
      throw LocalizedFormatException((l) => l.slateFileTooLarge);
    }
    return SlateFile(
      name: file.name,
      json: decodeSlateFile(await file.readAsBytes()),
    );
  }

  @override
  bool get canShareText =>
      canShareFiles ||
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Future<void> shareImage({
    required String name,
    required Uint8List png,
    required String text,
  }) => shareBytes(name: name, bytes: png, mimeType: 'image/png', text: text);
}

/// An image handed to [SlateFiles.shareImage], as [FakeSlateFiles] records it.
typedef SharedImage = ({String name, Uint8List png, String text});

/// Records saves and shares and hands out queued picks, for widget tests.
class FakeSlateFiles implements SlateFiles {
  final List<SlateFile> saved = [];
  final List<SlateFile> shared = [];
  final List<SlateFile?> picks = [];
  final List<String> sharedTexts = [];
  final List<SharedImage> sharedImages = [];

  @override
  bool canShare = true;

  @override
  bool get canShareText => true;

  @override
  Future<void> shareText(String text) async => sharedTexts.add(text);

  @override
  Future<void> shareImage({
    required String name,
    required Uint8List png,
    required String text,
  }) async => sharedImages.add((name: name, png: png, text: text));

  @override
  Future<bool> save({
    required String name,
    required String json,
    required String dialogTitle,
  }) async {
    saved.add(SlateFile(name: name, json: json));
    return true;
  }

  @override
  Future<bool> share({required String name, required String json}) async {
    shared.add(SlateFile(name: name, json: json));
    return true;
  }

  @override
  Future<SlateFile?> pick({required String dialogTitle}) async =>
      picks.isEmpty ? null : picks.removeAt(0);
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
    _channel.invokeMethod<Object?>('takePending').then(_accept).catchError((
      Object error,
    ) {
      // No native side (desktop, tests): nothing can have been shared in.
      if (error is! MissingPluginException) {
        logWarn('files', 'no pending shared file: $error');
      }
    });
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
