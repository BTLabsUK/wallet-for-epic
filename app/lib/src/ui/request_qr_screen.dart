// SPDX-License-Identifier: Apache-2.0
/// A payment request shown as a QR code to a phone next to this one (Direct · QR Payment): the
/// payer scans it, approves it and shows the answer back; scanning that answer finishes the
/// request and posts it. No pairing, no Epicbox: only this wallet's node posts.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../errors.dart';
import '../l10n.dart';
import '../models.dart';
import '../network_gate.dart' show NetBlock;
import '../providers.dart';
import '../settings.dart';
import '../slate_files.dart' show sendFileName;
import '../trust_ids.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'invoice_request_screen.dart';
import 'invoice_review_screen.dart' show ReviewAmount, requestFileRefusal;
import 'kit/kit_button.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_tokens.dart';
import 'net_block.dart';
import 'qr_scan_screen.dart';
import 'qr_show_screen.dart';
import 'receive_code.dart';
import 'slate_file_screen.dart' show NotPostedNotice, openSlateFile;
import 'theme/tokens.dart';

/// The keys of the request QR screen, for tests.
const Key requestQrScanKey = ValueKey('request-qr-scan');
const Key requestQrErrorKey = ValueKey('request-qr-error');
const Key requestQrPaidKey = ValueKey('request-qr-paid');
const Key requestQrNewKey = ValueKey('request-qr-new');

/// Opens the request form set to show the request as a QR (Receive › Direct · QR). Receive
/// offers it only while Invoices is on.
Future<void> openQrRequest(BuildContext context) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(builder: (_) => const InvoiceRequestScreen(asQr: true)),
);

/// The request made for a QR (Gap-1): its code stands on the page with Copy and Share; scanning
/// the payer's answer finishes and posts it, and the screen turns into the receipt. New request
/// opens the form again, for the next payer.
class RequestQrScreen extends ConsumerStatefulWidget {
  const RequestQrScreen({super.key, required this.slate, required this.amount, this.message});

  /// The request (I1).
  final Slate slate;
  final BigInt amount;

  /// The message signed into it, as typed.
  final String? message;

  @override
  ConsumerState<RequestQrScreen> createState() => _RequestQrScreenState();
}

class _RequestQrScreenState extends ConsumerState<RequestQrScreen> {
  /// Why the last answer was not taken.
  String Function(AppLocalizations l)? _error;

  /// The finished request, once posted (or finished but not taken by the node).
  TxEntry? _posted;

  bool _busy = false;

  bool get _canPost => watchNetBlock(context, ref, node: true) == NetBlock.none;

  Future<void> _scan() async {
    final result = await scanQrSlate(context, QrScanKind.reply, finish: _finish);
    if (!mounted) return;
    if (result is QrScanOpenFile) await _openFile();
  }

  Future<void> _openFile() async {
    await openSlateFile(context, ref, expectedSlateId: widget.slate.slateId);
    if (mounted) ref.invalidate(homeProvider);
  }

  /// Finishes the request with the payer's answer [json] and posts it. True once posted; else
  /// the reason shows on this screen.
  Future<bool> _finish(String json) async {
    final session = ref.read(sessionProvider);
    if (session == null) return false;
    final container = ProviderScope.containerOf(context, listen: false);
    final hold = ref.read(autoLockHoldProvider.notifier);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final SlateInfo info;
      try {
        info = await ref.read(walletServiceProvider).inspectSlate(json: json);
      } on WalletError {
        _say((l) => l.qrScanNotReply);
        return false;
      }
      if (info.slateId != widget.slate.slateId) {
        _say((l) => l.reqQrWrongReply);
        return false;
      }
      if (info.stage != SlateStage.requestAnswer) {
        _say((l) => l.qrScanNotReply);
        return false;
      }
      final TxEntry tx;
      try {
        tx = await hold.during(() => session.finalizeAndPost(slateJson: json));
      } catch (error) {
        logWarn('invoices', 'QR request answer refused: ${describeError(englishStrings, error)}');
        _say(switch (error) {
          // Another payer's answer was finished first: this one never posts.
          WalletError(kind: WalletErrorKind.invoiceAlreadyPaid) => (l) => l.reqQrAlreadyPaid,
          _ => requestFileRefusal(error) ?? (l) => describeError(l, error),
        });
        return false;
      }
      logInfo('invoices', 'QR request finished');
      container
        ..invalidate(issuedInvoicesProvider)
        ..invalidate(homeProvider);
      if (mounted) setState(() => _posted = tx);
      return !tx.repostable;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String Function(AppLocalizations l) error) {
    if (mounted) setState(() => _error = error);
  }

  void _newRequest() => Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => InvoiceRequestScreen(asQr: true, message: widget.message)),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final posted = _posted;
    final canPost = _canPost;
    final message = widget.message;

    if (posted != null && posted.repostable) {
      return RequestPlainPage(
        title: l.qrShowTitleRequest,
        bottom: [KitButton(label: l.commonDone, onPressed: () => Navigator.pop(context), semanticsId: TrustIds.receiveCodeDone)],
        children: [NotPostedNotice(tx: posted)],
      );
    }

    if (posted != null) {
      // The receipt: where the payment stands, from the wallet's history.
      final tx =
          ref.watch(homeProvider.select((h) => h.value?.transactions))?.where((x) => x.slateId == widget.slate.slateId).firstOrNull ?? posted;
      final status = qrShowStatus(
        l,
        reply: false,
        role: QrShowRole.request,
        phase: QrShowPhase.hidden,
        tx: tx,
        tip: tipHeight(ref),
        target: confirmationsTargetOf(ref),
      );
      return RequestPlainPage(
        title: l.reqQrPaidTitle,
        bottom: [
          KitButton(key: requestQrNewKey, label: l.reqQrNew, icon: KitIcons.add, onPressed: _newRequest),
          KitButton(label: l.commonDone, kind: KitButtonKind.quiet, onPressed: () => Navigator.pop(context), semanticsId: TrustIds.receiveCodeDone),
        ],
        children: [
          Row(
            key: requestQrPaidKey,
            children: [
              Icon(KitIcons.check, color: t.ok, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(l.reqQrPaidHeadline(epicExact(l, widget.amount)), style: KitType.rowTitle.copyWith(color: t.text)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ReviewAmount(amount: widget.amount),
          if (message != null && message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis, style: KitType.body.copyWith(color: t.text)),
            ),
          const SizedBox(height: 16),
          RequestStatusLine(text: status.text, ok: status.tone == QrStatusTone.ok),
        ],
      );
    }

    final error = _error;
    return RequestCodePage(
      amount: widget.amount,
      message: message,
      json: widget.slate.json,
      fileName: sendFileName(widget.slate.slateId),
      busy: _busy,
      onDone: () => Navigator.pop(context),
      status: const RequestStatusLine(),
      // On the receive side the code is never hidden (Gap-1): it stands on the page.
      card: RequestQrCard(json: widget.slate.json, label: l.deskKitQrOf(l.qrShowTitleRequest)),
      actions: [
        KitButton(
          key: requestQrScanKey,
          label: l.qrScanReply,
          kind: KitButtonKind.quiet,
          icon: KitIcons.scan,
          onPressed: _busy || !canPost ? null : _scan,
        ),
        if (!canPost) NetBlockNote(watchNetBlock(context, ref, node: true)),
        if (error != null) InlineNotice(key: requestQrErrorKey, level: NoticeLevel.error, text: error(l), liveRegion: true),
      ],
    );
  }
}
