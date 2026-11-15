// SPDX-License-Identifier: Apache-2.0
/// Where a scanned, pasted or linked text goes on the phone, after the scan router
/// ([classifyScan]) said what it is: Send prefilled, the QR Payment reader, the File flow, or
/// a sheet saying why not. Nothing here pays: the review and the PIN stay the only way.
library;

import '../invite_links.dart' show InviteKind, inviteHandler, parseInvite;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../devices/device_link_code.dart';
import '../errors.dart';
import '../l10n.dart';
import '../pairing_providers.dart' show pairingSupportedProvider;
import '../pairing_text.dart' show inviteSourceOf;
import '../payment_prefs.dart';
import '../providers.dart';
import '../scan/scan_checks.dart';
import '../scan/scan_router.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../epic1.dart' show Epic1Wallet, looksLikeEpic1Link, looksLikeEpictx;
import 'devices/device_parts.dart' show openLinkDevice;
import 'common.dart' show popToShell;
import 'epic1/epic1_common.dart' show showEpic1OffSheet;
import 'epic1/epic1_send.dart' show openEpic1LinkSend;
import 'in_person/in_person_entry.dart' show openInPersonText;
import 'in_person/in_person_logic.dart' show InPersonBytes, readInPersonText;
import 'link_send.dart' show openPaymentLink;
import 'notices.dart';
import 'pairing/pair_incoming.dart' show openPairingLink;
import 'receive_screen.dart' show scanSlateQr;
import 'scan_result_sheet.dart';
import 'scan_screen.dart' show offersQrPayment;
import 'slate_file_screen.dart';

/// The methods on in Settings › Transactions, which pick the address a code or a contact
/// fills in.
PaymentPrefs sendPayments(WidgetRef ref) =>
    (ref.read(appSettingsProvider).value?.payments ??
            (ref.read(phonePaymentsProvider) ? PaymentPrefs.phoneDefaults : PaymentPrefs.defaults))
        // The phone sends to an http(s) address at every level, with no switch: only the
        // network mode holds it.
        .copyWith(linkHttp: true);

/// Whether [request] carries more than its address: an amount, a note, a name, a minimum, or a
/// part that was dropped. A bare `epic:<address>` is handled as the address alone.
bool requestCarriesMore(PaymentRequest request) =>
    request.amount != null ||
    request.note != null ||
    request.label != null ||
    request.minimum != null ||
    request.noteRequired ||
    request.problems.isNotEmpty;

/// Opens [text] from Home's scan or a link: a payment code or an address goes to Send, the
/// rest where it belongs. [scanAgain] reopens the scanner the text came from. An invite (its
/// https link or the bare `epiccash://` one) goes to the handler its feature registered
/// (invite_links.dart), else to today's pairing and device-link routes as the bare invite; a
/// pairing invite scanned or pasted always takes the pairing route.
Future<void> openScannedText(
  BuildContext context,
  WidgetRef ref,
  String text, {
  required CodeOrigin origin,
  Future<void> Function()? scanAgain,
}) async {
  // An epic1 thing is paid or opened, or says epic1 is off, with Settings.
  if (await openEpic1Text(context, ref, text)) return;
  if (!context.mounted) return;
  final invite = parseInvite(text);
  if (invite != null) {
    final handler = inviteHandler(invite.kind);
    // A pairing invite scanned or pasted opens its sheet below: the handler's level-1 notice is
    // for one handed to the app.
    final asked = invite.kind == InviteKind.pair && origin != CodeOrigin.link;
    if (handler != null && !asked) return handler(context, invite);
    text = invite.invite;
  }
  return isDeviceLinkText(text)
      ? openDeviceLinkText(context, ref, text)
      : openScannedCode(
          context,
          ref,
          classifyFor(ref.read(walletServiceProvider), text),
          origin: origin,
          scanAgain: scanAgain,
        );
}

/// An epic1 thing in [text]: with epic1 on an epic1 link is paid and an in-person code opened;
/// with it off, an epic1 link, file or in-person code stops with the line that says epic1 is
/// off. Classic text is left to the caller, whichever way epic1 is. True when [text] was taken
/// here.
Future<bool> openEpic1Text(BuildContext context, WidgetRef ref, String text) async {
  if (ref.read(epic1Provider) == null) return false;
  if (!ref.read(epic1OnProvider)) {
    if (!looksLikeEpic1Link(text) && !looksLikeEpictx(text) && !_isInPersonQr(ref.read(epic1Provider), text)) return false;
    await showEpic1OffSheet(context);
    return true;
  }
  if (looksLikeEpic1Link(text)) {
    final container = ProviderScope.containerOf(context, listen: false);
    if (await openEpic1LinkSend(context, text.trim())) container.invalidate(homeProvider);
    return true;
  }
  // A classic animated code shares the in-person QR type: the reader hands it back (false) and
  // the classic route reads it.
  return openInPersonText(context, text);
}

/// Whether [text] is a whole in-person QR code. Its parts share the animated payment QR's
/// type; [Epic1Wallet.qrRead] refuses a payment's parts, so only a complete in-person code is
/// taken and a classic animated QR still reaches the QR Payment reader.
bool _isInPersonQr(Epic1Wallet? wallet, String text) {
  if (wallet == null || !text.trim().toLowerCase().startsWith('ur:')) return false;
  return switch (readInPersonText(wallet, text)) {
    InPersonBytes(fromQr: true) => true,
    _ => false,
  };
}

/// A device invite from a scan or a paste: Link a device answers it.
Future<void> openDeviceLinkText(BuildContext context, WidgetRef ref, String text) => openLinkDevice(context, ref, code: text);

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
    // A payment link is checked first: a refusal says why, an opened one fills Send.
    case PaymentLink():
      final link = await openPaymentLink(context, ref, code, scanAgain: scanAgain);
      if (link != null && context.mounted) {
        ref.read(sendRecipientProvider.notifier).handLink(link, origin);
        showSendTab(context, ref);
      }
    case SlateText(:final text):
      await _showSlateText(context, text);
    case PairingLink(:final text) when ref.read(pairingSupportedProvider):
      await openPairingLink(
        context,
        ref,
        text,
        byCamera: origin == CodeOrigin.qr,
        source: inviteSourceOf(origin),
      );
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
    // Never shown: one line that it is a recovery phrase.
    case RecoveryPhraseCode():
      await showRecoveryPhraseFound(context, pasted: origin == CodeOrigin.paste);
    case UnknownCode(:final text) when isDeviceLinkText(text):
      await openDeviceLinkText(context, ref, text);
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

/// The fallback for a pairing link on a wallet that does not pair (its core has no pairing
/// yet): says so, with Copy. A wallet that pairs opens the link ([openPairingLink]).
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

/// The Send flow over the shell, with every screen over the shell closed first.
void showSendTab(BuildContext context, WidgetRef ref) {
  ref.read(shellFlowProvider.notifier).open(ShellFlow.send);
  popToShell(Navigator.of(context));
}

/// A payment link came while another screen is open: nothing closes; Open in the notice
/// closes the screens and opens the link. Dismissed, the link is dropped. A [pairing] link
/// says so, not "Payment link".
void showLinkWaiting(WidgetRef ref, AppLocalizations l, VoidCallback open, {bool pairing = false}) {
  ref
      .read(noticeProvider.notifier)
      .show(
        pairing ? l.linkWaitingPairingNotice : l.linkWaitingNotice,
        level: NoticeLevel.info,
        action: NoticeAction(l.commonOpen, open),
      );
}

/// A payment link came while Send asks for the PIN or sends: it was dropped.
void showLinkBusy(WidgetRef ref, AppLocalizations l) => ref
    .read(noticeProvider.notifier)
    .show(l.linkFinishCurrentFirst, level: NoticeLevel.warning);
