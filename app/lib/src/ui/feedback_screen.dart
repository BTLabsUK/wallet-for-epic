import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../errors.dart';
import '../feedback.dart';
import '../l10n.dart';
import '../network.dart';
import '../providers.dart';
import '../settings.dart';
import 'common.dart';
import 'contacts_screen.dart' show LiveFieldError;
import 'settings_screen.dart' show appVersionProvider;

/// `android 14 (…)`: the OS and its version, as Dart reports them. Tests pin it.
final feedbackPlatformProvider = Provider<String>(
  (ref) => '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
);

/// Plain words for what the wallet is doing, for a feedback report. English, like the rest of
/// the report. Reads only providers that are already running, so asking never starts a
/// refresh or a listener.
String describeSyncState(WidgetRef ref) {
  if (ref.read(sessionProvider) == null) return 'Wallet locked';
  final parts = <String>[];
  final scan = ref.read(scanProvider);
  final progress = ref.read(syncProgressProvider);
  if (scan.running) {
    parts.add('Scanning, ${scan.percent ?? 0}%');
  } else if (progress != null) {
    parts.add('Syncing, $progress%');
  } else if (ref.exists(homeProvider)) {
    final home = ref.read(homeProvider);
    final data = home.value;
    parts.add(
      home.hasError
          ? 'Last sync failed: ${describeError(englishStrings, home.error!)}'
          : data == null
          ? 'Loading'
          : data.syncing
          ? 'Syncing'
          : data.summary.validatedWithNode
          ? 'Up to date at height ${data.summary.lastConfirmedHeight}'
          : 'Node not reached',
    );
  }
  if (ref.exists(listenerProvider)) {
    final listener = ref.read(listenerProvider);
    parts.add(
      listener.connected
          ? 'epicbox connected'
          : listener.lost
          ? 'epicbox reconnecting'
          : 'epicbox not connected',
    );
  }
  return parts.isEmpty ? 'Wallet open' : parts.join(', ');
}

/// "Send feedback": a message, an optional email, and the diagnostic log unless turned off.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

enum _Destination { device, share }

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _message = TextEditingController();
  final _email = TextEditingController();
  bool _attachLogs = true;
  bool _busy = false;
  String? _messageError;
  String? _emailError;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<FeedbackDetails> _details() async {
    // English, like the rest of the report.
    String version;
    try {
      version = await ref.read(appVersionProvider.future) ?? 'Unknown';
    } catch (_) {
      version = 'Unknown';
    }
    final config = ref.read(walletConfigProvider);
    final choice = ref.read(networkChoiceProvider).value;
    final nodeUrl = config?.nodeUrl ?? choice?.nodeUrl;
    final relay = config != null
        ? EpicboxRelay(host: config.epicboxDomain, port: config.epicboxPort)
        : choice?.relay;
    final chain = config?.chain ?? choice?.preset.chain;
    return FeedbackDetails(
      appVersion: version,
      platform: ref.read(feedbackPlatformProvider),
      network: chain == null ? 'Unknown' : chainLabel(chain),
      node: nodeUrl == null ? 'Unknown' : (Uri.tryParse(nodeUrl)?.host ?? '?'),
      relay: relay?.label ?? 'Unknown',
      sync: describeSyncState(ref),
    );
  }

  /// The report as it would leave now.
  Future<String> _report() async {
    final details = await _details();
    String? log;
    if (_attachLogs) {
      try {
        log = await ref.read(feedbackLogProvider).tail(feedbackLogBytes);
      } catch (error) {
        log = 'The log could not be read: $error\n';
      }
    }
    return buildFeedbackReport(
      message: _message.text,
      email: _email.text,
      details: details,
      log: log,
      at: ref.read(clockProvider)(),
    );
  }

  bool _validate() {
    final l = context.l10n;
    final message = _message.text.trim();
    final email = _email.text.trim();
    setState(() {
      _messageError = message.isEmpty ? l.feedbackMessageMissing : null;
      _emailError = email.isNotEmpty && !isValidFeedbackEmail(email)
          ? l.feedbackEmailInvalid
          : null;
      _error = null;
    });
    return _messageError == null && _emailError == null;
  }

  Future<void> _preview() async {
    final report = await _report();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FeedbackPreviewScreen(report: report),
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || !_validate()) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      logWarn('feedback', 'not sent: $error');
      if (mounted) {
        final l = context.l10n;
        setState(
          () => _error = error is FeedbackSendError
              ? error.text(l)
              : describeError(l, error),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _done(String message) {
    if (!mounted) return;
    ref.read(noticeProvider.notifier).show(message, level: NoticeLevel.success);
    Navigator.of(context).pop();
  }

  Future<void> _send(Uri url) => _run(() async {
    final report = await _report();
    await ref.read(feedbackOutletProvider).post(url, report);
    logInfo('feedback', 'sent to ${url.host}');
    if (mounted) _done(context.l10n.feedbackSent);
  });

  Future<void> _handOver() async {
    if (_busy || !_validate()) return;
    final outlet = ref.read(feedbackOutletProvider);
    var destination = _Destination.device;
    // The choice comes first, so the button only spins while the file is handed over.
    if (outlet.canShare) {
      final chosen = await showModalBottomSheet<_Destination>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          final l = context.l10n;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.share),
                  title: Text(l.commonShare),
                  subtitle: Text(l.feedbackShareHint),
                  onTap: () => Navigator.pop(context, _Destination.share),
                ),
                ListTile(
                  leading: const Icon(Icons.save_alt),
                  title: Text(l.feedbackSaveToDevice),
                  onTap: () => Navigator.pop(context, _Destination.device),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
      if (chosen == null || !mounted) return;
      destination = chosen;
    }
    final dialogTitle = context.l10n.feedbackSaveDialogTitle;
    await _run(() async {
      final report = await _report();
      final name = feedbackFileName(ref.read(clockProvider)());
      final done = await ref
          .read(autoLockHoldProvider.notifier)
          .during(
            () => switch (destination) {
              _Destination.device => outlet.save(
                name: name,
                report: report,
                dialogTitle: dialogTitle,
              ),
              _Destination.share => outlet.share(name: name, report: report),
            },
          );
      if (!done) return;
      logInfo('feedback', 'handed over as ${destination.name}');
      if (!mounted) return;
      final l = context.l10n;
      _done(
        destination == _Destination.device
            ? l.feedbackSavedFile(name)
            : l.feedbackThanks,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final url = ref.watch(feedbackUrlProvider);
    final theme = Theme.of(context);
    return SlotScaffold(
      appBar: AppBar(title: Text(l.feedbackTitle)),
      body: ScreenBody(
        children: [
          Text(l.feedbackIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _message,
            minLines: 5,
            maxLines: 12,
            maxLength: maxFeedbackMessageChars,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_messageError != null) setState(() => _messageError = null);
            },
            decoration: InputDecoration(
              labelText: l.feedbackMessageLabel,
              alignLabelWithHint: true,
              error: _messageError == null
                  ? null
                  : LiveFieldError(_messageError!),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
            decoration: InputDecoration(
              labelText: l.feedbackEmailLabel,
              error: _emailError == null ? null : LiveFieldError(_emailError!),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.feedbackAttachLogs),
            subtitle: Text(l.feedbackAttachLogsHint),
            value: _attachLogs,
            onChanged: (on) => setState(() => _attachLogs = on),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l.feedbackPreviewButton),
              onPressed: _busy ? null : _preview,
            ),
          ),
          const SizedBox(height: 8),
          if (_error != null) ErrorText(_error!),
          if (url != null) ...[
            BusyButton(
              label: l.feedbackSend,
              busy: _busy,
              onPressed: () => _send(url),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _busy ? null : _handOver,
              child: Text(l.feedbackShareOrSaveInstead),
            ),
          ] else ...[
            Text(l.feedbackFileExplanation, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            BusyButton(
              label: l.feedbackShareOrSave,
              busy: _busy,
              onPressed: _handOver,
            ),
          ],
        ],
      ),
    );
  }
}

/// The exact text a report would carry, which stays English. One line per row, so a 256 KB log
/// scrolls smoothly; the selection area still lets the user copy across rows.
class FeedbackPreviewScreen extends StatelessWidget {
  const FeedbackPreviewScreen({super.key, required this.report});

  final String report;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final lines = report.split('\n');
    return SlotScaffold(
      appBar: AppBar(title: Text(context.l10n.feedbackPreviewTitle)),
      body: SafeArea(
        child: SelectionArea(
          child: Scrollbar(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lines.length,
              itemBuilder: (context, i) => Text(lines[i], style: style),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens [FeedbackScreen].
Future<void> openFeedback(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const FeedbackScreen()));
