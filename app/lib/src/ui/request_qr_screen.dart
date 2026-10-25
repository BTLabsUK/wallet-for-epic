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
import '../wallet_service.dart';
import 'common.dart';
import 'invoice_request_screen.dart';
import 'invoice_review_screen.dart' show ReviewAmount, requestFileRefusal;
import 'net_block.dart';
import 'qr_scan_screen.dart';
import 'qr_show_screen.dart';
import 'slate_file_screen.dart' show NotPostedNotice, openSlateFile;
import 'theme/brand.dart' show GlyphTile;
import 'theme/protocol.dart';
import 'theme/tokens.dart';

/// The keys of the request QR screen, for tests.
const Key requestQrShowKey = ValueKey('request-qr-show');
const Key requestQrScanKey = ValueKey('request-qr-scan');
const Key requestQrErrorKey = ValueKey('request-qr-error');
const Key requestQrPaidKey = ValueKey('request-qr-paid');
const Key requestQrNewKey = ValueKey('request-qr-new');

/// Opens the request form set to show the request as a QR (Receive › Direct · QR). Receive
/// offers it only while Invoices is on.
Future<void> openQrRequest(BuildContext context) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(builder: (_) => const InvoiceRequestScreen(asQr: true)),
);

/// The request made for a QR: its code opens at once; scanning the payer's answer from there
/// (or from here) finishes and posts it, and the screen turns into the receipt. New request
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

  @override
  void initState() {
    super.initState();
    // The payer stands next to the screen: the code comes first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_show());
    });
  }

  bool get _canPost => watchNetBlock(context, ref, localNode: true) == NetBlock.none;

  Future<void> _show() async {
    final result = await showRequestQr(
      context,
      json: widget.slate.json,
      amount: widget.amount,
      slateId: widget.slate.slateId,
      scanEnabled: _canPost,
      finish: _finish,
    );
    if (!mounted) return;
    if (result is QrShowOpenFile) await _openFile();
  }

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
    final theme = Theme.of(context);
    final posted = _posted;
    final canPost = _canPost;
    final message = widget.message;
    final noteRow = message == null || message.isEmpty
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge),
          );

    if (posted != null && posted.repostable) {
      return SlotScaffold(
        appBar: AppBar(title: Text(l.qrShowTitleRequest)),
        body: ScreenBody(
          children: [
            NotPostedNotice(tx: posted),
            const SizedBox(height: 8),
            BusyButton(label: l.commonDone, onPressed: () => Navigator.pop(context)),
          ],
        ),
      );
    }

    if (posted != null) {
      // The receipt: where the payment stands, from the wallet's history.
      final tx =
          ref
              .watch(homeProvider.select((h) => h.value?.transactions))
              ?.where((x) => x.slateId == widget.slate.slateId)
              .firstOrNull ??
          posted;
      final status = qrShowStatus(
        l,
        reply: false,
        role: QrShowRole.request,
        phase: QrShowPhase.hidden,
        tx: tx,
        tip: tipHeight(ref),
        target: confirmationsTargetOf(ref),
      );
      return SlotScaffold(
        appBar: AppBar(title: Text(l.reqQrPaidTitle)),
        body: ScreenBody(
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                key: requestQrNewKey,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.add),
                label: Text(l.reqQrNew),
                onPressed: _newRequest,
              ),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => Navigator.pop(context),
                child: Text(l.commonDone),
              ),
            ],
          ),
          children: [
            Row(
              key: requestQrPaidKey,
              children: [
                GlyphTile(size: 48, child: Icon(Icons.check_circle_outline, color: t.ok)),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(
                      l.reqQrPaidHeadline(epicExact(l, widget.amount)),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ReviewAmount(amount: widget.amount),
            ?noteRow,
            const SizedBox(height: 16),
            Semantics(
              liveRegion: true,
              child: Text(
                status.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: status.tone == QrStatusTone.ok ? t.ok : t.info,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final error = _error;
    return SlotScaffold(
      appBar: AppBar(title: Text(l.qrShowTitleRequest)),
      idle: _busy ? SlotProgress(label: l.qrShowTitleRequest) : null,
      body: ScreenBody(
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: requestQrShowKey,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.qr_code_2),
              label: Text(l.qrShow),
              onPressed: _busy ? null : _show,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: requestQrScanKey,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l.qrScanReply),
              onPressed: _busy || !canPost ? null : _scan,
            ),
          ],
        ),
        children: [
          Row(
            children: [
              GlyphTile(size: 48, child: Icon(Icons.qr_code_2, color: t.accentText)),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l.qrShowSubRequest(epicExact(l, widget.amount)), style: theme.textTheme.titleMedium),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ReviewAmount(amount: widget.amount),
          ?noteRow,
          const SizedBox(height: 16),
          Text(l.qrStatusRequestShowing, style: theme.textTheme.bodyLarge?.copyWith(color: t.dim)),
          const SizedBox(height: 4),
          Text(l.reqQrOpenNote, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
          if (!canPost) ...[const SizedBox(height: 12), NetBlockNote(watchNetBlock(context, ref, localNode: true))],
          if (error != null) ...[
            const SizedBox(height: 16),
            EdgeCard(
              key: requestQrErrorKey,
              edge: t.risk,
              child: Padding(padding: const EdgeInsets.all(16), child: Text(error(l))),
            ),
          ],
        ],
      ),
    );
  }
}
