import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../errors.dart';
import '../l10n.dart';
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

  /// What went wrong, worded when shown: the file is checked from [initState], before the
  /// screen's strings can be read.
  String Function(AppLocalizations l)? _error;
  bool _busy = false;

  /// The signed answer, once made, so it can be handed over again. A repeat carries the answer
  /// given the first time.
  ReceivedSlate? _response;
  TxEntry? _posted;

  /// True until the core has read the file.
  bool _reading = true;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    SlateInfo? info;
    String Function(AppLocalizations l)? error;
    try {
      info = await ref
          .read(walletServiceProvider)
          .inspectSlate(json: widget.file.json);
      final expected = widget.expectedSlateId;
      if (expected != null && info.slateId != expected) {
        error = (l) => l.slateWrongPayment;
      } else if (info.stage == SlateStage.invoice) {
        error = (l) => l.slateInvoiceUnsupported;
      }
    } catch (e) {
      error = e is WalletError
          ? (l) => l.slateNotTransactionFile
          : (l) => describeError(l, e);
    }
    if (!mounted) return;
    setState(() {
      _reading = false;
      _info = info;
      _error = error;
    });
  }

  /// Runs one wallet action at a time, then refreshes home, even if this screen has closed,
  /// unless the action returns false because it changed nothing.
  Future<void> _run(Future<bool> Function(WalletSession session) action) async {
    if (_busy) return;
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (await action(session)) container.invalidate(homeProvider);
    } catch (error) {
      if (mounted) setState(() => _error = (l) => describeError(l, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sign() => _run((session) async {
    final response = await session.receiveSlate(slateJson: widget.file.json);
    if (mounted) setState(() => _response = response);
    return !response.repeated;
  });

  Future<void> _finalize() {
    final hold = ref.read(autoLockHoldProvider.notifier);
    return _run((session) async {
      final tx = await hold.during(
        () => session.finalizeAndPost(slateJson: widget.file.json),
      );
      if (mounted) setState(() => _posted = tx);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final info = _info;
    final theme = Theme.of(context);
    final List<Widget> body;
    if (_posted case final posted? when posted.repostable) {
      body = [
        NotPostedNotice(tx: posted),
        const SizedBox(height: 8),
        BusyButton(
          label: l.commonDone,
          onPressed: () => Navigator.pop(context, true),
        ),
      ];
    } else if (_posted != null) {
      body = [
        _Headline(
          icon: Icons.check_circle,
          text: l.slatePostedHeadline(epicText(l, info!.amount)),
        ),
        const SizedBox(height: 8),
        Text(l.slatePostedBody(confirmationsTarget)),
        const SizedBox(height: 24),
        BusyButton(
          label: l.commonDone,
          onPressed: () => Navigator.pop(context, true),
        ),
      ];
    } else if (_response case final response?) {
      final name = responseFileName(widget.file.name);
      body = [
        _Headline(
          icon: Icons.check_circle,
          text: response.repeated
              ? l.slateRepeatedHeadline(name)
              : l.slateAcceptedHeadline(name),
        ),
        const SizedBox(height: 8),
        Text(
          response.repeated
              ? l.slateRepeatedBody(epicText(l, info!.amount))
              : l.slateAcceptedBody(epicText(l, info!.amount)),
        ),
        const SizedBox(height: 24),
        SlateFileButtons(name: name, json: response.json),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.commonDone),
        ),
      ];
    } else if (_reading) {
      body = [
        Semantics(
          label: l.slateReading,
          child: const Center(child: CircularProgressIndicator()),
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
              ? l.slateIncomingSend(epicText(l, info.amount))
              : l.slateIncomingResponse(
                  epicText(l, info.amount),
                  epicText(l, info.fee),
                ),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(receiving ? l.slateIncomingSendHint : l.slateIncomingResponseHint),
        const SizedBox(height: 24),
        if (_error == null)
          BusyButton(
            label: receiving ? l.slateAcceptPayment : l.slateFinishPayment,
            busy: _busy,
            onPressed: receiving ? _sign : _finalize,
          ),
      ];
    }
    final error = _error;
    return SlotScaffold(
      appBar: AppBar(title: Text(l.slateFileTitle)),
      body: ScreenBody(
        children: [...body, if (error != null) ErrorText(error(l))],
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
    // Read now: the notice outlives this button if the screen closes meanwhile.
    final notice = ref.read(noticeProvider.notifier);
    final failed = context.l10n.slateHandOverFailed(name);
    try {
      final ok = await ref
          .read(autoLockHoldProvider.notifier)
          .during(() => action(files));
      if (ok && done != null) notice.show(done);
    } catch (error) {
      logWarn('files', 'handing over a transaction file failed: $error');
      notice.show(failed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final files = ref.watch(slateFilesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.save_alt),
          label: Text(l.slateSaveToDevice),
          onPressed: () => _out(
            context,
            ref,
            (f) => f.save(
              name: name,
              json: json,
              dialogTitle: l.slateSaveDialogTitle,
            ),
            done: l.slateSaved(name),
          ),
        ),
        if (files.canShare) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.share),
            label: Text(l.commonShare),
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

  /// The explanation under the headline.
  static String text(AppLocalizations l) => l.slateNotPostedBody;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
                  l.slateNotPostedTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(text(l), style: theme.textTheme.bodyLarge),
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
          child: Text(l.slateOpenPayment),
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

/// Picks a transaction file and opens it in [SlateFileScreen]. Shows a notice when the file
/// cannot be read. Returns true when the file was signed or finalized.
Future<bool> openSlateFile(
  BuildContext context,
  WidgetRef ref, {
  String? expectedSlateId,
}) async {
  // Read before the picker: the calling screen may be gone when it returns.
  final notice = ref.read(noticeProvider.notifier);
  final l = context.l10n;
  final SlateFile? file;
  try {
    file = await ref
        .read(autoLockHoldProvider.notifier)
        .during(
          () => ref
              .read(slateFilesProvider)
              .pick(dialogTitle: l.slateOpenDialogTitle),
        );
  } on FormatException catch (e) {
    notice.show(describeError(l, e));
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
