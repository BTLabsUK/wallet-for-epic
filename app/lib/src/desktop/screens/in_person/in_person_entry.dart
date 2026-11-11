// SPDX-License-Identifier: Apache-2.0
/// The desktop's ways into epic1 in-person payments (spec D5). Receive, Send and file opening
/// call these; the screens behind them live in this folder. The desktop has no scanner: it
/// shows codes and takes pasted ones.
library;

import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../epic1.dart';
import '../../../ui/in_person/in_person_logic.dart';
import '../../../camera/camera_presence.dart';
import '../../../ui/in_person/in_person_scan.dart' show InPersonScanned;
import '../../data/api.dart' show DeskWalletApi;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../scan/desk_scan.dart';
import 'in_person_reader.dart';
import 'in_person_dialogs.dart';

/// Receive › "Request in person": amount and message, then the code and the check.
Future<void> openDeskRequestInPerson(BuildContext context) => showEDialog<void>(
  context,
  dismissible: false,
  builder: (_) => const DeskInPersonCodeDialog(stage: InPersonStage.request),
);

/// Send › "Pay in person": amount, then the send code and the check.
Future<void> openDeskPayInPerson(BuildContext context) => showEDialog<void>(
  context,
  dismissible: false,
  builder: (_) => const DeskInPersonCodeDialog(stage: InPersonStage.send),
);

/// Pasted or opened [text] that may be an in-person code or answer. Handles it and returns
/// true, or returns false when it is neither.
Future<bool> openDeskInPersonText(BuildContext context, String text) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final api = container.read(deskApiProvider);
  final wallet = api.epic1;
  if (wallet == null) return false;
  switch (readInPersonText(wallet, text)) {
    case null:
      return false;
    case InPersonArmored(:final bytes):
      return _openAnswer(context, wallet, bytes);
    case InPersonBytes(:final bytes, :final fromQr):
      return _openBytes(context, api, wallet, bytes, fromQr);
    case InPersonPart(:final part):
      // One part of an animated code: only a camera reads the rest.
      final presence = await container.read(cameraPresenceProvider.notifier).recheck();
      if (!presence.offersScan || !context.mounted) return false;
      final got = await deskScanParts(context, title: context.l10n.scanQrTitle, hint: context.l10n.deskIpScanAim, reader: DeskInPersonReader(wallet, first: part));
      if (got is! DeskScanned<InPersonScanned> || !context.mounted) return got is DeskScanned;
      final bytes = got.value.bytes;
      return bytes != null && await _openBytes(context, api, wallet, bytes, true);
  }
}

/// A whole code's [bytes], read from text or the camera: its review, or an answer's check.
Future<bool> _openBytes(BuildContext context, DeskWalletApi api, Epic1Wallet wallet, Uint8List bytes, bool fromQr) async {
  final InPersonCodeInfo info;
  try {
    info = await wallet.inPersonRead(bytes, minimumConfirmations: BigInt.from(await api.minimumConfirmations()));
  } on Object catch (e) {
    if (!context.mounted) return true;
    if (deskInPersonExpired(e)) {
      await showEDialog<void>(context, builder: (_) => const DeskInPersonExpiredDialog());
      return true;
    }
    return fromQr && await _openAnswer(context, wallet, bytes);
  }
  if (!context.mounted) return true;
  await showEDialog<void>(context, dismissible: false, builder: (_) => DeskInPersonReviewDialog(code: bytes, info: info));
  return true;
}

/// An answer to a code this wallet showed, pasted outside the code's dialog: the check.
Future<bool> _openAnswer(BuildContext context, Epic1Wallet wallet, Uint8List bytes) async {
  final InPersonTaken taken;
  try {
    taken = await wallet.inPersonTake(bytes);
  } on Object {
    return false;
  }
  if (!context.mounted) return true;
  await showEDialog<void>(
    context,
    dismissible: false,
    builder: (_) => DeskInPersonCodeDialog(stage: taken.stage, watch: InPersonCodeWatch.answered(wallet: wallet, taken: taken)),
  );
  return true;
}
