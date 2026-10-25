/// Where a scanned, pasted or linked text goes on the phone, after the scan router
/// ([classifyScan]) said what it is: Send prefilled, the QR Payment reader, the File flow, or
/// a sheet saying why not. Nothing here pays: the review and the PIN stay the only way.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../payment_prefs.dart';
import '../providers.dart';
import '../scan/scan_checks.dart';
import '../scan/scan_router.dart';
import '../settings.dart';
import '../slate_files.dart';
import 'notices.dart';
import 'receive_screen.dart' show scanSlateQr;
import 'scan_result_sheet.dart';
import 'scan_screen.dart' show offersQrPayment;
import 'slate_file_screen.dart';

/// Whether [text] starts like a code the router reads by its scheme (`epic:`, `epiccash:`,
/// `ur:`) or is a transaction file's text, as opposed to plain text typed or pasted into a
/// field.
bool looksLikeCode(String text) =>
    RegExp(r'^\s*(epic|epiccash|ur):', caseSensitive: false).hasMatch(text) ||
    classifyScan(text, check: (_) => AddressVerdict.invalid) is SlateText;

/// Whether [request] carries more than its address: an amount, a note, a name, or a part that
/// was dropped. A bare `epic:<address>` is handled as the address alone.
/// The methods on in Settings › Transactions, which pick the address a code or a contact
/// fills in.
PaymentPrefs sendPayments(WidgetRef ref) =>
    ref.read(appSettingsProvider).value?.payments ??
    (ref.read(phonePaymentsProvider)
        ? PaymentPrefs.phoneDefaults
        : PaymentPrefs.defaults);

bool requestCarriesMore(PaymentRequest request) =>
    request.amount != null ||
    request.note != null ||
    request.label != null ||
    request.problems.isNotEmpty;

/// Opens [text] from Home's scan or a link: a payment code or an address goes to Send, the
/// rest where it belongs. [scanAgain] reopens the scanner the text came from.
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
    case PaymentRequest() when requestCarriesMore(code):
      ref.read(sendRecipientProvider.notifier).handRequest(code, origin);
      showSendTab(context, ref);
    case PaymentRequest(:final recipient) || ScannedAddress(:final recipient):
      // A code with a second address fills the one whose method is on.
      final to = code is PaymentRequest
          ? code.recipientFor(sendPayments(ref).offers)
          : recipient;
      ref
          .read(sendRecipientProvider.notifier)
          .hand(to.address, origin: origin);
      showSendTab(context, ref);
    case SlateFrames(:final text):
      if (origin == CodeOrigin.qr && offersQrPayment(ref)) {
        await scanSlateQr(context, ref, first: text);
      } else {
        // A link never carries a QR Payment part, and pasting one is near impossible.
        await _showUnknown(context, UnknownCode(text), origin, scanAgain);
      }
    case SlateText(:final text):
      await _showSlateText(context, text);
    case PairingLink(:final text):
      await showPairingSheet(context, text, origin: origin);
    case WrongNetwork(:final recipient):
      final again = await showScanResultSheet(
        context,
        icon: Icons.public_off,
        title: context.l10n.scanWrongNetworkTitle,
        text: context.l10n.scanWrongNetworkBody,
        preview: recipient.address,
        previewWhole: true,
        copy: origin == CodeOrigin.paste ? null : recipient.address,
        primary: _primaryLabel(context, scanAgain),
      );
      if (again && scanAgain != null) await scanAgain();
    case UnknownCode():
      await _showUnknown(context, code, origin, scanAgain);
  }
}

String _primaryLabel(
  BuildContext context,
  Future<void> Function()? scanAgain,
) => scanAgain != null ? context.l10n.qrScanAgain : context.l10n.commonClose;

Future<void> _showUnknown(
  BuildContext context,
  UnknownCode code,
  CodeOrigin origin,
  Future<void> Function()? scanAgain,
) async {
  final l = context.l10n;
  final again = await showScanResultSheet(
    context,
    icon: Icons.qr_code_scanner,
    title: l.scanNotEpicTitle,
    text: code.reason == UnknownReason.badAddress
        ? l.scanBadAddress
        : l.scanNotEpicBody,
    preview: code.text,
    // A pasted text is in the clipboard already.
    copy: origin == CodeOrigin.paste ? null : code.text,
    primary: _primaryLabel(context, scanAgain),
  );
  if (again && scanAgain != null) await scanAgain();
}

/// The fallback for a pairing link while this version has no pairing: says so, with Copy.
/// The pairing flow replaces it when it lands.
Future<void> showPairingSheet(
  BuildContext context,
  String text, {
  required CodeOrigin origin,
}) => showScanResultSheet(
  context,
  icon: Icons.handshake_outlined,
  title: context.l10n.scanPairingTitle,
  text: context.l10n.scanPairingUnavailable,
  preview: text,
  copy: origin == CodeOrigin.paste ? null : text,
  primary: context.l10n.commonClose,
);

/// A transaction file's text: Open takes it to the File flow, as pasted text.
Future<void> _showSlateText(BuildContext context, String text) async {
  final l = context.l10n;
  final open = await showScanResultSheet(
    context,
    icon: Icons.description_outlined,
    title: l.slateFileTitle,
    text: l.scanSlateTextBody,
    secondary: l.commonCancel,
    primary: l.commonOpen,
  );
  if (!open || !context.mounted) return;
  final String json;
  try {
    json = decodeSlateFile(utf8.encode(text));
  } on FormatException catch (error) {
    if (!context.mounted) return;
    ProviderScope.containerOf(context, listen: false)
        .read(noticeProvider.notifier)
        .show(describeError(l, error), level: NoticeLevel.error);
    return;
  }
  if (!context.mounted) return;
  await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => SlateFileScreen(
        file: SlateFile(name: pastedSlateName, json: json),
        pasted: true,
      ),
    ),
  );
}

/// The Send tab, with every screen over the shell closed.
void showSendTab(BuildContext context, WidgetRef ref) {
  ref.read(shellTabProvider.notifier).go(ShellTab.send);
  Navigator.of(context).popUntil((route) => route.isFirst);
}

/// A payment link came while another screen is open: nothing closes; Open in the notice
/// closes the screens and opens the link. Dismissed, the link is dropped.
void showLinkWaiting(WidgetRef ref, AppLocalizations l, VoidCallback open) {
  ref
      .read(noticeProvider.notifier)
      .show(
        l.linkWaitingNotice,
        level: NoticeLevel.info,
        action: NoticeAction(l.commonOpen, open),
      );
}

/// A payment link came while Send asks for the PIN or sends: it was dropped.
void showLinkBusy(WidgetRef ref, AppLocalizations l) => ref
    .read(noticeProvider.notifier)
    .show(l.linkFinishCurrentFirst, level: NoticeLevel.warning);
