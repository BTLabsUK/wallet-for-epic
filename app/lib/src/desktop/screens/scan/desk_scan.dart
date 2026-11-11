// SPDX-License-Identifier: Apache-2.0
/// The desktop's QR scan: one dialog over the screen that asked, reading a code with the
/// computer's camera, or several parts of an animated one. Every problem shows in place with
/// Paste, so the code can always come in as text. Nothing here retries by itself or touches the
/// system's camera settings.
///
/// The API every desktop screen uses:
/// - [deskScanQr]: one code's text.
/// - [deskScanParts]: an animated code, read by a [DeskPartReader].
/// - [DeskScanButton]: Scan, greyed out while [cameraPresenceProvider] finds no camera.
/// - [DeskNoCameraLine]: the one quiet line beside paste when there is none.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../camera/camera_presence.dart';
import '../../../scan/scan_router.dart' show looksLikeRecoveryPhrase;
import '../../../ui/qr_camera.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// What a scan gave: a code the camera read, or the text pasted in its place.
sealed class DeskScanResult<T> {
  const DeskScanResult();
}

/// The camera read it: [value] is the reader's result (the text, for [deskScanQr]).
final class DeskScanned<T> extends DeskScanResult<T> {
  const DeskScanned(this.value);
  final T value;
}

/// The user pasted [text] instead; the caller opens it as any pasted text (origin paste).
final class DeskPasted<T> extends DeskScanResult<T> {
  const DeskPasted(this.text);
  final String text;
}

/// Where an animated code's reading stands.
sealed class DeskPartStep<T> {
  const DeskPartStep();
}

/// More parts to read: [received] of [total] (total 0 until the first part says it).
final class DeskPartWaiting<T> extends DeskPartStep<T> {
  const DeskPartWaiting(this.received, this.total);
  final int received;
  final int total;
}

/// The whole code is in.
final class DeskPartDone<T> extends DeskPartStep<T> {
  const DeskPartDone(this.value);
  final T value;
}

/// A text the reader does not take (another code in view): [message] says so in the dialog; the
/// scan goes on.
final class DeskPartRefused<T> extends DeskPartStep<T> {
  const DeskPartRefused(this.message);
  final String Function(AppLocalizations l) message;
}

/// Reads the texts of one scan, repeats included, into a [T].
abstract class DeskPartReader<T> {
  DeskPartStep<T> read(String text);
}

/// A reader done on the first text it takes. A recovery phrase is refused unless [phrase].
class DeskSingleReader implements DeskPartReader<String> {
  const DeskSingleReader({this.phrase = false});

  /// The restore screen reads a phrase; nowhere else does.
  final bool phrase;

  @override
  DeskPartStep<String> read(String text) {
    final t = text.trim();
    if (t.isEmpty) return const DeskPartWaiting(0, 0);
    if (!phrase && looksLikeRecoveryPhrase(t)) return DeskPartRefused((l) => l.scanPhraseFoundQr);
    return DeskPartDone(t);
  }
}

/// One code's text, or the pasted text, or null when closed.
Future<DeskScanResult<String>?> deskScanQr(BuildContext context, {required String title, String? hint, bool phrase = false}) =>
    deskScanParts(context, title: title, hint: hint, reader: DeskSingleReader(phrase: phrase));

/// An animated code read by [reader], or the pasted text, or null when closed.
Future<DeskScanResult<T>?> deskScanParts<T>(BuildContext context, {required String title, String? hint, required DeskPartReader<T> reader}) =>
    showEDialog<DeskScanResult<T>>(context, builder: (_) => DeskScanDialog<T>(title: title, hint: hint, reader: reader));

/// The scan dialog. Skeleton: the design pass gives it its states.
class DeskScanDialog<T> extends ConsumerStatefulWidget {
  const DeskScanDialog({super.key, required this.title, this.hint, required this.reader});

  final String title;
  final String? hint;
  final DeskPartReader<T> reader;

  @override
  ConsumerState<DeskScanDialog<T>> createState() => _DeskScanDialogState<T>();
}

class _DeskScanDialogState<T> extends ConsumerState<DeskScanDialog<T>> {
  late final QrCamera _camera = ref.read(qrCameraFactoryProvider)();

  @override
  void initState() {
    super.initState();
    _camera.codes.listen(_onCode);
    _camera.start();
  }

  void _onCode(String text) {
    if (!mounted) return;
    if (widget.reader.read(text) case DeskPartDone<T>(:final value)) Navigator.of(context).pop(DeskScanned<T>(value));
  }

  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    Navigator.of(context).pop(DeskPasted<T>(text));
  }

  @override
  void dispose() {
    _camera.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EDialog(
      title: widget.title,
      description: widget.hint,
      icon: EIcons.camera,
      body: SizedBox(height: 240, child: _camera.preview(context)),
      actions: [
        EButton(label: l.commonPaste, onPressed: _paste),
        EButton(label: l.commonClose, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}

/// Scan, beside a field's paste: offered while a camera is found, greyed out otherwise. It
/// checks again when it first shows.
class DeskScanButton extends ConsumerStatefulWidget {
  const DeskScanButton({super.key, required this.onScan, this.size = EBtnSize.inline});

  final VoidCallback onScan;
  final EBtnSize size;

  @override
  ConsumerState<DeskScanButton> createState() => _DeskScanButtonState();
}

class _DeskScanButtonState extends ConsumerState<DeskScanButton> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(cameraPresenceProvider.notifier).recheck());
  }

  @override
  Widget build(BuildContext context) {
    final on = ref.watch(cameraPresenceProvider).offersScan;
    return EIconButton(icon: EIcons.camera, label: context.l10n.scanQrTitle, size: widget.size, onPressed: on ? widget.onScan : null);
  }
}

/// The one quiet line when this computer has no camera to scan with; nothing otherwise.
class DeskNoCameraLine extends ConsumerWidget {
  const DeskNoCameraLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(cameraPresenceProvider)) {
    // Skeleton: the design pass gives it its words and look.
    CameraPresence.none || CameraPresence.unsupported => const SizedBox.shrink(),
    _ => const SizedBox.shrink(),
  };
}
