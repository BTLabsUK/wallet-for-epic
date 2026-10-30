// SPDX-License-Identifier: Apache-2.0
/// "Finished, not posted": what a send finalized under Kill switch shows. The payment is
/// complete but this phone can't post it, so the screen offers the finished payment as a file
/// (`<first 8 of the id>.finished.tx`, LEPIC's final slate) and as an animated QR code, for a
/// device that is online to post (Activity › Post a finished payment). Calm blue hourglass, not
/// a failure. The same buttons sit in the payment's details.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../l10n.dart';
import '../models.dart';
import '../network_gate.dart' show NetGate;
import '../settings.dart' show autoLockHoldProvider;
import '../providers.dart';
import '../slate_files.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'qr_show_screen.dart';
import 'theme/tokens.dart';

/// The file a finished payment is saved as.
String finishedFileName(String slateId) => '${shortSlateId(slateId)}.finished.tx';

/// The payments seen finished under Kill switch in this run: after Kill switch is left they are
/// still the ones another device may have posted, so the details say so and offer Post now.
/// (LEPIC keeps no flag for it yet; after a restart a payment reads as a plain unposted send.)
final Set<String> finishedUnderKillKeys = {};

/// [tx] is "to be posted elsewhere" now (finished while Kill switch holds every connection);
/// remembers it for [finishedUnderKillKeys].
bool isPostElsewhere(TxEntry tx) {
  final yes = toPostElsewhere(tx, killSwitch: NetGate.killSwitch);
  if (yes) finishedUnderKillKeys.add(tx.key);
  return yes;
}

/// The key of the Save file button, for tests.
const Key finishedSaveKey = ValueKey('finished-save');

/// The key of the Show QR button, for tests.
const Key finishedQrKey = ValueKey('finished-qr');

/// The key of the title, for tests.
const Key finishedTitleKey = ValueKey('finished-title');

/// Save file and Show QR for the finished payment [tx], under the auto-lock hold since they
/// open another app. A core that can't write the text yet says so in a line under the buttons.
class FinishedPaymentButtons extends ConsumerStatefulWidget {
  const FinishedPaymentButtons({super.key, required this.tx, this.primarySave = true});

  final TxEntry tx;

  /// Whether Save file is the filled button.
  final bool primarySave;

  @override
  ConsumerState<FinishedPaymentButtons> createState() => _FinishedPaymentButtonsState();
}

class _FinishedPaymentButtonsState extends ConsumerState<FinishedPaymentButtons> {
  bool _busy = false;
  String? _error;

  Future<String?> _text() async {
    final l = context.l10n;
    final session = ref.read(sessionProvider);
    final id = widget.tx.id;
    if (session == null || id == null) return null;
    try {
      return await session.finishedPaymentText(txId: id);
    } on WalletError catch (e) {
      logWarn('finished', 'finished payment text failed: ${e.kind.name}');
      if (mounted) setState(() => _error = e.message.contains('newer LEPIC') ? l.finishedUnavailable : l.finishedFailed);
      return null;
    }
  }

  Future<void> _save() async {
    final l = context.l10n;
    final notice = ref.read(noticeProvider.notifier);
    final files = ref.read(slateFilesProvider);
    final tx = widget.tx;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final text = await _text();
      if (text == null) return;
      final name = finishedFileName(tx.slateId ?? tx.key);
      final ok = await ref
          .read(autoLockHoldProvider.notifier)
          .during(() => files.save(name: name, json: text, dialogTitle: l.slateSaveDialogTitle));
      if (ok) notice.show(l.finishedSaved(name), level: NoticeLevel.success);
    } catch (error) {
      logWarn('finished', 'saving a finished payment failed: $error');
      if (mounted) setState(() => _error = l.finishedFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showQr() async {
    final tx = widget.tx;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final text = await _text();
      if (text == null || !mounted) return;
      await showFinishedQr(context, json: text, amount: txAmount(tx).amount, slateId: tx.slateId);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    const size = Size.fromHeight(48);
    final save = widget.primarySave
        ? FilledButton.icon(
            key: finishedSaveKey,
            style: FilledButton.styleFrom(minimumSize: size),
            icon: const Icon(Icons.save_alt),
            label: Text(l.finishedSaveFile),
            onPressed: _busy ? null : _save,
          )
        : OutlinedButton.icon(
            key: finishedSaveKey,
            style: OutlinedButton.styleFrom(minimumSize: size),
            icon: const Icon(Icons.save_alt),
            label: Text(l.finishedSaveFile),
            onPressed: _busy ? null : _save,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        save,
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: finishedQrKey,
          style: OutlinedButton.styleFrom(minimumSize: size),
          icon: const Icon(Icons.qr_code_2),
          label: Text(l.finishedShowQr),
          onPressed: _busy ? null : _showQr,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(_error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: t.dim)),
            ),
          ),
      ],
    );
  }
}

/// The result screen after finalizing under Kill switch: "Finished, not posted", what to do
/// with it and the two buttons.
class FinishedNotPosted extends StatelessWidget {
  const FinishedNotPosted({super.key, required this.tx});

  final TxEntry tx;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Icon(Icons.hourglass_empty, color: t.info, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(l.finalizeNotPostedTitle, key: finishedTitleKey, style: theme.textTheme.titleLarge)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(l.finalizeNotPostedBody(epicExact(l, txAmount(tx).amount)), style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        FinishedPaymentButtons(tx: tx),
      ],
    );
  }
}
