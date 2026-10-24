/// Where a scanned, pasted or linked text goes on the phone, after the scan router
/// ([classifyScan]) said what it is: Send prefilled, the QR Payment reader, the File flow, or
/// a sheet saying why not. Nothing here pays: the review and the PIN stay the only way.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../qr_slate.dart';
import '../scan/scan_checks.dart';
import '../scan/scan_router.dart';
import '../slate_files.dart';
import 'receive_screen.dart' show scanSlateQr;
import 'scan_screen.dart' show offersQrPayment;
import 'slate_file_screen.dart';

/// Whether [text] starts like a code the router reads by its scheme (`epic:`, `epiccash:`,
/// `ur:`), as opposed to plain text typed or pasted into a field.
bool looksLikeCode(String text) => RegExp(
  r'^\s*(epic|epiccash|ur):',
  caseSensitive: false,
).hasMatch(text);

/// Opens [text] from Home's scan or a link: a payment code or an address goes to Send, the
/// rest where it belongs. [scanAgain] reopens the camera from the "not an Epic code" sheet.
Future<void> openScannedText(
  BuildContext context,
  WidgetRef ref,
  String text, {
  required CodeOrigin origin,
  Future<void> Function()? scanAgain,
}) => openScannedCode(
  context,
  ref,
  classifyFor(ref.read(walletServiceProvider), text),
  origin: origin,
  scanAgain: scanAgain,
);

/// Opens [code], what the router made of a text.
Future<void> openScannedCode(
  BuildContext context,
  WidgetRef ref,
  ScannedCode code, {
  required CodeOrigin origin,
  Future<void> Function()? scanAgain,
}) async {
  switch (code) {
    case PaymentRequest():
      ref.read(sendRecipientProvider.notifier).handRequest(code, origin);
      showSendTab(context, ref);
    case ScannedAddress(:final recipient):
      ref.read(sendRecipientProvider.notifier).hand(recipient.address);
      showSendTab(context, ref);
    case SlateFrames(:final text):
      await _openSlateFrames(context, ref, text, origin: origin);
    case SlateText(:final text):
      await showSlateTextSheet(context, ref, text);
    case PairingLink():
      await showPairingSheet(context, code);
    case WrongNetwork():
      await showWrongNetworkSheet(context, code);
    case UnknownCode():
      await showUnknownCodeSheet(context, code, scanAgain: scanAgain);
  }
}

/// The Send tab, with every screen over the shell closed.
void showSendTab(BuildContext context, WidgetRef ref) {
  ref.read(shellTabProvider.notifier).go(ShellTab.send);
  Navigator.of(context).popUntil((route) => route.isFirst);
}

/// A QR Payment part. From the camera, the QR Payment reader takes over and reads the rest of
/// the looping code. Pasted or linked, a payment that fits one part opens at once.
Future<void> _openSlateFrames(
  BuildContext context,
  WidgetRef ref,
  String text, {
  required CodeOrigin origin,
}) async {
  if (origin == CodeOrigin.qr && offersQrPayment(ref)) {
    await scanSlateQr(context, ref, first: text);
    return;
  }
  final reader = QrSlateReader(ref.read(walletServiceProvider));
  QrRead? read;
  try {
    read = await reader.feed(text);
  } catch (_) {
    read = null;
  }
  if (!context.mounted) return;
  final json = read?.json;
  if (read?.kind == QrReadKind.complete && json != null) {
    await _openSlateJson(context, json, scanned: true);
    return;
  }
  await showQrPartSheet(context);
}

/// Opens slate text in [SlateFileScreen], as a pasted file.
Future<void> _openSlateJson(
  BuildContext context,
  String text, {
  bool scanned = false,
}) async {
  final String json;
  try {
    json = decodeSlateFile(utf8.encode(text));
  } on FormatException {
    await showUnknownCodeSheet(context, UnknownCode(text));
    return;
  }
  if (!context.mounted) return;
  await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => SlateFileScreen(
        file: SlateFile(
          name: scanned ? scannedSlateName : pastedSlateName,
          json: json,
        ),
        pasted: true,
        scanned: scanned,
      ),
    ),
  );
}

// Sheets. Provisional; the designed versions replace them.

Future<void> showSlateTextSheet(
  BuildContext context,
  WidgetRef ref,
  String text,
) async {
  final open = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) => _CodeSheet(
      title: 'That is a transaction file',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Open'),
        ),
      ],
    ),
  );
  if (open == true && context.mounted) await _openSlateJson(context, text);
}

Future<void> showPairingSheet(BuildContext context, PairingLink link) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          _CodeSheet(title: 'Pairing is not available', code: link.text),
    );

Future<void> showWrongNetworkSheet(BuildContext context, WrongNetwork code) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _CodeSheet(
        title: 'This code is for another network',
        code: code.recipient.address,
      ),
    );

Future<void> showUnknownCodeSheet(
  BuildContext context,
  UnknownCode code, {
  Future<void> Function()? scanAgain,
}) async {
  final again = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) => _CodeSheet(
      title: code.reason == UnknownReason.badAddress
          ? 'This is not a valid Epic address.'
          : 'Not an Epic code',
      code: code.text,
      actions: [
        if (scanAgain != null)
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Scan again'),
          ),
      ],
    ),
  );
  if (again == true && scanAgain != null) await scanAgain();
}

Future<void> showQrPartSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) =>
      const _CodeSheet(title: 'Scan the QR Payment code with the camera'),
);

class _CodeSheet extends StatelessWidget {
  const _CodeSheet({required this.title, this.code, this.actions = const []});

  final String title;
  final String? code;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final code = this.code;
    final shown = code == null || code.length <= 80
        ? code
        : '${code.substring(0, 80)}…';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (shown != null) ...[
              const SizedBox(height: 12),
              SelectableText(shown, style: const TextStyle(fontFamily: 'monospace')),
            ],
            const SizedBox(height: 12),
            Wrap(alignment: WrapAlignment.end, spacing: 8, children: actions),
          ],
        ),
      ),
    );
  }
}

/// A payment link came while another screen is open: Open closes the screens and opens it.
void showLinkWaiting(BuildContext context, VoidCallback open) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Payment link waiting'),
      action: SnackBarAction(label: 'Open', onPressed: open),
    ),
  );
}

/// A payment link came while Send asks for the PIN or sends: it was dropped.
void showLinkBusy(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Finish the current payment first')),
  );
}
