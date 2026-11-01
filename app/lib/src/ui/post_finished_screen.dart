// SPDX-License-Identifier: Apache-2.0
/// "Post a finished payment": the online side of a Kill switch payment. A payment another device
/// finished under Kill switch comes as a file (`<id>.finished.tx`), an animated QR code or pasted
/// text; the screen reads it ([WalletSession.inspectFinished]: amount, fee, kernel), says what
/// posting does, and posts it to the node in use ([WalletSession.postFinished]). No PIN: posting
/// needs no key. Off in Kill switch, and while Tor only waits for Tor.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../l10n.dart';
import '../network_gate.dart';
import '../providers.dart';
import '../settings.dart' show autoLockHoldProvider;
import '../slate_files.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'net_block.dart';
import 'pairing/pairing_parts.dart' show PairCard;
import 'qr_scan_screen.dart';
import 'theme/tokens.dart';

/// The key of the Open file button, for tests.
const Key postFinishedOpenKey = ValueKey('post-finished-open');

/// The key of the Scan QR button, for tests.
const Key postFinishedScanKey = ValueKey('post-finished-scan');

/// The key of the Paste button, for tests.
const Key postFinishedPasteKey = ValueKey('post-finished-paste');

/// The key of the Post button, for tests.
const Key postFinishedPostKey = ValueKey('post-finished-post');

/// The key of the summary card, for tests.
const Key postFinishedSummaryKey = ValueKey('post-finished-summary');

/// The key of the error line, for tests.
const Key postFinishedErrorKey = ValueKey('post-finished-error');

/// The key of the "Posted" result, for tests.
const Key postFinishedDoneKey = ValueKey('post-finished-done');

/// Opens the Post a finished payment screen.
Future<void> openPostFinished(BuildContext context) =>
    Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const PostFinishedScreen()));

/// A kernel excess shortened to its ends for a summary row.
String shortKernel(String kernel) =>
    kernel.length <= 20 ? kernel : '${kernel.substring(0, 10)}…${kernel.substring(kernel.length - 8)}';

class PostFinishedScreen extends ConsumerStatefulWidget {
  const PostFinishedScreen({super.key});

  @override
  ConsumerState<PostFinishedScreen> createState() => _PostFinishedScreenState();
}

class _PostFinishedScreenState extends ConsumerState<PostFinishedScreen> {
  String? _text;
  FinishedPayment? _payment;
  String? _error;
  bool _busy = false;
  bool _posted = false;

  /// Reads [text] as a finished payment and shows its summary, or says it is not one.
  Future<void> _read(String text) async {
    final l = context.l10n;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _payment = null;
      _text = null;
    });
    try {
      final payment = await session.inspectFinished(text.trim());
      if (!mounted) return;
      setState(() {
        _text = text.trim();
        _payment = payment;
      });
    } catch (error) {
      logWarn('post-finished', 'reading a finished payment failed: ${error.runtimeType}');
      if (mounted) setState(() => _error = l.postFinishedNotFinished);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openFile() async {
    final l = context.l10n;
    final files = ref.read(slateFilesProvider);
    final file = await ref.read(autoLockHoldProvider.notifier).during(() => files.pick(dialogTitle: l.slateOpenDialogTitle));
    if (file == null || !mounted) return;
    await _read(file.json);
  }

  Future<void> _scan() async {
    final result = await scanQrSlate(context, QrScanKind.finished);
    if (!mounted) return;
    if (result is QrScanned) await _read(result.json);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (!mounted) return;
    if (text == null || text.isEmpty) {
      setState(() => _error = context.l10n.postFinishedNotFinished);
      return;
    }
    await _read(text);
  }

  Future<void> _post() async {
    final l = context.l10n;
    final session = ref.read(sessionProvider);
    final text = _text;
    if (session == null || text == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.postFinished(text);
      ref.invalidate(homeProvider);
      if (mounted) setState(() => _posted = true);
    } on NetBlocked {
      if (mounted) setState(() => _error = NetGate.killSwitch ? l.postFinishedOffKill : l.postFinishedOffTor);
    } on WalletError catch (e) {
      logWarn('post-finished', 'posting failed: ${e.kind.name}');
      if (mounted) {
        setState(() => _error = switch (e.kind) {
          WalletErrorKind.invalidSlate => l.postFinishedNotFinished,
          WalletErrorKind.nodeUnreachable => l.postFinishedUnreachable,
          _ => l.postFinishedFailed,
        });
      }
    } catch (error) {
      logWarn('post-finished', 'posting failed: ${error.runtimeType}');
      if (mounted) setState(() => _error = l.postFinishedFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final block = watchNetBlock(context, ref, node: true);
    final blocked = block != NetBlock.none;
    final payment = _payment;
    final kernel = payment?.kernelExcess;
    final dim = theme.textTheme.bodyMedium?.copyWith(color: t.dim);
    final size = const Size.fromHeight(48);
    Widget button(Key key, IconData icon, String label, VoidCallback onTap) => OutlinedButton.icon(
      key: key,
      style: OutlinedButton.styleFrom(minimumSize: size),
      icon: Icon(icon),
      label: Text(label),
      onPressed: blocked || _busy ? null : onTap,
    );
    final List<Widget> children;
    if (_posted) {
      children = [
        Semantics(
          liveRegion: true,
          child: Row(
            key: postFinishedDoneKey,
            children: [
              Icon(Icons.check_circle_outline, color: t.ok, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(l.postFinishedDone, style: theme.textTheme.titleLarge)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(l.postFinishedDoneBody, style: theme.textTheme.bodyLarge),
      ];
    } else {
      children = [
        Text(l.postFinishedIntroOffline, style: dim),
        const SizedBox(height: 16),
        button(postFinishedOpenKey, Icons.folder_open, l.postFinishedOpenFile, _openFile),
        const SizedBox(height: 8),
        button(postFinishedScanKey, Icons.qr_code_scanner, l.postFinishedScanQr, _scan),
        const SizedBox(height: 8),
        button(postFinishedPasteKey, Icons.content_paste, l.postFinishedPaste, _paste),
        if (blocked) ...[
          const SizedBox(height: 12),
          NetBlockNote(block, line: block == NetBlock.killSwitch ? l.postFinishedOffKill : (block == NetBlock.waitingForTor ? l.postFinishedOffTor : null)),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(_error!, key: postFinishedErrorKey, style: theme.textTheme.bodyMedium?.copyWith(color: t.risk)),
          ),
        ],
        if (payment != null) ...[
          const SizedBox(height: 20),
          Semantics(header: true, child: Text(l.postFinishedSummary, style: theme.textTheme.titleMedium)),
          const SizedBox(height: 8),
          PairCard(
            key: postFinishedSummaryKey,
            children: [
              ListTile(title: Text(l.postFinishedAmount), trailing: Text(epicExact(l, payment.amount))),
              ListTile(title: Text(l.postFinishedFee), trailing: Text(epicExact(l, payment.fee))),
              if (kernel != null)
                ListTile(
                  title: Text(l.postFinishedKernel),
                  trailing: Text(shortKernel(kernel), style: TextStyle(fontFamily: t.monoFamily)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l.postFinishedNote, style: dim),
        ],
      ];
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.postFinishedTitle)),
      body: ScreenBody(
        bottom: _posted
            ? FilledButton(
                style: FilledButton.styleFrom(minimumSize: size),
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l.commonDone),
              )
            : payment == null
            ? null
            : FilledButton(
                key: postFinishedPostKey,
                style: FilledButton.styleFrom(minimumSize: size),
                onPressed: blocked || _busy ? null : _post,
                child: Text(_busy ? l.postFinishedPosting : l.postFinishedPost),
              ),
        children: children,
      ),
    );
  }
}
