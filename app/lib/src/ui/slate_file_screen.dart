import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../providers.dart';
import '../settings.dart';
import '../slate_files.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'tx_details_screen.dart';

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
            'This response is for a different payment. Open the file the '
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

  /// Runs one wallet action at a time, then refreshes home, even if this screen has closed.
  Future<void> _run(Future<void> Function(WalletSession session) action) async {
    if (_busy) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(session);
      container.invalidate(homeProvider);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sign() => _run((session) async {
    final response = await session.receiveSlate(slateJson: widget.file.json);
    if (mounted) setState(() => _response = response);
  });

  Future<void> _finalize() {
    final hold = ref.read(autoLockHoldProvider.notifier);
    return _run((session) async {
      final tx = await hold.during(
        () => session.finalizeAndPost(slateJson: widget.file.json),
      );
      if (mounted) setState(() => _posted = tx);
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    final theme = Theme.of(context);
    final List<Widget> body;
    if (_posted case final posted? when posted.repostable) {
      body = [
        NotPostedNotice(tx: posted),
        const SizedBox(height: 8),
        BusyButton(
          label: 'Done',
          onPressed: () => Navigator.pop(context, true),
        ),
      ];
    } else if (_posted != null) {
      body = [
        _Headline(
          icon: Icons.check_circle,
          text: 'Payment of ${epicText(info!.amount)} sent to the network.',
        ),
        const SizedBox(height: 8),
        Text(
          'It shows as Completed after $minimumConfirmations confirmations.',
        ),
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
          text: 'Accepted. Return $name to the sender.',
        ),
        const SizedBox(height: 8),
        Text(
          'The ${epicText(info!.amount)} arrive once the sender finishes '
          'the payment and it is on the chain.',
        ),
        const SizedBox(height: 24),
        SlateFileButtons(name: name, json: _response!.json),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
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
              ? 'Accept it, then return the response file to the sender.'
              : 'Finish it to send the payment to the network.',
        ),
        const SizedBox(height: 24),
        if (_error == null)
          BusyButton(
            label: receiving ? 'Accept payment' : 'Finish payment',
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

/// "Save to device" first, then "Share" where the platform has a share sheet for files. Many
/// phones' share sheets have no "save to files" target, so saving must not depend on it. Both
/// run under the auto-lock hold, since they open another app.
class SlateFileButtons extends ConsumerWidget {
  const SlateFileButtons({super.key, required this.name, required this.json});

  final String name;
  final String json;

  Future<void> _out(
    BuildContext context,
    WidgetRef ref,
    Future<bool> Function(SlateFiles files) action, {
    String? done,
  }) async {
    final files = ref.read(slateFilesProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await ref
          .read(autoLockHoldProvider.notifier)
          .during(() => action(files));
      if (ok && done != null) {
        messenger.showSnackBar(SnackBar(content: Text(done)));
      }
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not hand over $name. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(slateFilesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.save_alt),
          label: const Text('Save to device'),
          onPressed: () => _out(
            context,
            ref,
            (f) => f.save(name: name, json: json),
            done: 'Saved $name',
          ),
        ),
        if (files.canShare) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            onPressed: () =>
                _out(context, ref, (f) => f.share(name: name, json: json)),
          ),
        ],
      ],
    );
  }
}

/// A send that is finished (finalized) but that the network has not taken yet. The wallet will
/// broadcast it again from the payment; sending again would pay twice.
class NotPostedNotice extends StatelessWidget {
  const NotPostedNotice({super.key, required this.tx});

  final TxEntry tx;

  static const String text =
      'The payment is finished but the network has not taken it yet. It will '
      'be broadcast again from the payment. Do not send it again.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: theme.colorScheme.error, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Not on the network yet',
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(text, style: theme.textTheme.bodyLarge),
        if (tx.statusDetail case final detail? when detail.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(detail, style: theme.textTheme.bodySmall),
          ),
        const SizedBox(height: 16),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => TxDetailsScreen(txKey: tx.key),
            ),
          ),
          child: const Text('Open the payment'),
        ),
      ],
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
