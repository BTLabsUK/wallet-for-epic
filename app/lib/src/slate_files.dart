/// Transaction files, the way epic-wallet's CLI exchanges them: the sender writes a slate file
/// (`send -m file`), the recipient answers with `<same name>.response` (`receive -i`), and the
/// sender finalizes that (`finalize -i`). The contents are slate JSON.
///
/// Files go out through the system save dialog, or on phones through the share sheet. In the
/// browser a save is a download (`slate_files_web.dart`).
library;

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'app_log.dart';
import 'l10n.dart' show LocalizedFormatException;
import 'slate_files_io.dart'
    if (dart.library.js_interop) 'slate_files_web.dart';

export 'slate_files_io.dart'
    if (dart.library.js_interop) 'slate_files_web.dart'
    show saveBytesToDevice, shareBytes, clearSharedFiles;

/// Slate files are a few kilobytes; anything far larger is not one.
const int maxSlateFileBytes = 1 << 20;

/// A transaction file read from disk.
class SlateFile {
  const SlateFile({required this.name, required this.json});

  final String name;
  final String json;
}

/// The first 8 characters of a slate id: short enough that a phone shows a file's whole name,
/// ending included.
String shortSlateId(String slateId) =>
    slateId.length <= 8 ? slateId : slateId.substring(0, 8);

/// The file name for a new send, `<first 8 of the slate id>.tx`.
String sendFileName(String slateId) => '${shortSlateId(slateId)}.tx';

/// A payment file sealed for a paired contact (RFC 3.5), `<first 8 of the slate id>.epicsealed`.
String sealedFileName(String slateId) => '${shortSlateId(slateId)}.epicsealed';

/// Sealed text (RFC 3.5): armored, `BEGINEPICSEALED` after optional whitespace.
bool isSealedText(String text) => text.trimLeft().startsWith('BEGINEPICSEALED');

/// The recipient's answer, `<first 8 of the slate id>.response`.
String responseFileName(String slateId) =>
    '${shortSlateId(slateId)}.response';

/// The answer to a payment read from the file [loaded] (its name, without folders):
/// `<loaded>.response`, so the sender sees at once which answer is for which file (a pool's
/// `Abc-123.tx` gets `Abc-123.tx.response`, #108). A file with this app's own name for the
/// slate (`ab12cd34.tx`, also `ab12cd34-2.tx`), pasted text and a scan keep
/// [responseFileName].
String replyFileName(String slateId, {String? loaded}) {
  final own = RegExp('^${RegExp.escape(shortSlateId(slateId))}(-[0-9]+)?\\.tx\$');
  if (loaded == null || loaded.trim().isEmpty || own.hasMatch(loaded)) return responseFileName(slateId);
  return '$loaded.response';
}

/// [name] if [taken] says it is free, else `-2`, `-3`, ... before the suffix
/// (`ab12cd34-2.response`). Reading never depends on names; this only keeps a save from
/// overwriting another file.
String uniqueFileName(String name, bool Function(String candidate) taken) {
  if (!taken(name)) return name;
  final dot = name.lastIndexOf('.');
  final stem = dot <= 0 ? name : name.substring(0, dot);
  final suffix = dot <= 0 ? '' : name.substring(dot);
  for (var n = 2;; n++) {
    final candidate = '$stem-$n$suffix';
    if (!taken(candidate)) return candidate;
  }
}

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
  // A sealed file holds armored text, opened by the pairing engine (RFC 3.5).
  if (!text.startsWith('{') && !isSealedText(text)) {
    throw LocalizedFormatException((l) => l.slateNotTransactionFile);
  }
  return text;
}

/// Whether this platform has a share sheet that takes files.
bool get canShareFiles =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

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
