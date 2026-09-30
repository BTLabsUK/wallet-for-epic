import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../providers.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../wallet_service.dart';
import 'common.dart';

/// One transaction file: shows what it is, then signs it (a send to us) or finalizes it (the
/// answer to our send). Opened from Receive, from Send's second step, and from files other apps
/// hand to the wallet.
class SlateFileScreen extends ConsumerStatefulWidget {
  const SlateFileScreen({super.key, required this.file, this.expectedSlateId});

  final SlateFile file;

  /// When finalizing our own send, the id the response must carry.
  final String? expectedSlateId;

  @override
  ConsumerState<SlateFileScreen> createState() => _SlateFileScreenState();
}

class _SlateFileScreenState extends ConsumerState<SlateFileScreen> {
  SlateInfo? _info;
  String? _error;
  bool _busy = false;

  /// The signed answer, once made, so it can be handed over again.
  Slate? _response;
  TxEntry? _posted;

  @override
  void initState() {
    super.initState();
    try {
      final info = ref
          .read(walletServiceProvider)
          .inspectSlate(json: widget.file.json);
      final expected = widget.expectedSlateId;
      if (expected != null && info.slateId != expected) {
        _error =
            'This response is for a different transaction. Open the file the '
            'recipient returned for this send.';
      } else if (info.stage == SlateStage.invoice) {
        _error = 'Payment requests (invoices) are not supported yet.';
      }
      _info = info;
    } catch (error) {
      _error = error is WalletError
          ? 'That file is not a transaction file.'
          : describeError(error);
    }
  }

  Future<void> _run(Future<void> Function(WalletSession session) action) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(session);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sign() => _run((session) async {
    final response = await session.receiveSlate(slateJson: widget.file.json);
    if (!mounted) return;
    setState(() => _response = response);
    await _shareResponse();
    ref.invalidate(homeProvider);
  });

  Future<void> _shareResponse() async {
    final response = _response;
    if (response == null) return;
    await ref
        .read(autoLockHoldProvider.notifier)
        .during(
          () => ref
              .read(slateFilesProvider)
              .export(
                name: responseFileName(widget.file.name),
                json: response.json,
              ),
        );
  }

  Future<void> _finalize() => _run((session) async {
    final tx = await session.finalizeAndPost(slateJson: widget.file.json);
    if (!mounted) return;
    setState(() => _posted = tx);
    ref.invalidate(homeProvider);
  });

  @override
  Widget build(BuildContext context) {
    final info = _info;
    final theme = Theme.of(context);
    final List<Widget> body;
    if (_posted != null) {
      body = [
        _Headline(
          icon: Icons.check_circle,
          text: 'Transaction of ${epicText(info!.amount)} posted.',
        ),
        const SizedBox(height: 8),
        const Text('It shows as confirmed once it is mined.'),
        const SizedBox(height: 24),
        BusyButton(
          label: 'Done',
          onPressed: () => Navigator.pop(context, true),
        ),
      ];
    } else if (_response != null) {
      final name = responseFileName(widget.file.name);
      body = [
        _Headline(
          icon: Icons.check_circle,
          text: 'Signed. Return $name to the sender.',
        ),
        const SizedBox(height: 8),
        Text(
          'The ${epicText(info!.amount)} arrive once the sender finalizes '
          'this file and the transaction is mined.',
        ),
        const SizedBox(height: 24),
        BusyButton(label: 'Share $name again', onPressed: _shareResponse),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Done'),
        ),
      ];
    } else if (info == null) {
      body = [];
    } else {
      final receiving = info.stage == SlateStage.send;
      body = [
        Text(widget.file.name, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          receiving
              ? 'Someone is sending you ${epicText(info.amount)}.'
              : 'The recipient\'s answer to your send of '
                    '${epicText(info.amount)} (fee ${epicText(info.fee)}).',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          receiving
              ? 'Sign it, then return the response file to the sender.'
              : 'Finalize it to post the transaction to the network.',
        ),
        const SizedBox(height: 24),
        if (_error == null)
          BusyButton(
            label: receiving ? 'Sign and share response' : 'Finalize and post',
            busy: _busy,
            onPressed: receiving ? _sign : _finalize,
          ),
      ];
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction file')),
      body: ScreenBody(
        children: [...body, if (_error != null) ErrorText(_error!)],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

/// Picks a transaction file and opens it in [SlateFileScreen]. Shows a snack bar when the file
/// cannot be read. Returns true when the file was signed or finalized.
Future<bool> openSlateFile(
  BuildContext context,
  WidgetRef ref, {
  String? expectedSlateId,
}) async {
  final SlateFile? file;
  try {
    file = await ref
        .read(autoLockHoldProvider.notifier)
        .during(() => ref.read(slateFilesProvider).pick());
  } on FormatException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
    return false;
  }
  if (file == null || !context.mounted) return false;
  final done = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) =>
          SlateFileScreen(file: file!, expectedSlateId: expectedSlateId),
    ),
  );
  return done ?? false;
}
