// SPDX-License-Identifier: Apache-2.0
import 'phone_sheet.dart';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_log.dart';
import '../errors.dart';
import '../feedback.dart';
import '../l10n.dart';
import '../last_session.dart';
import '../network.dart';
import '../providers.dart';
import '../settings.dart';
import '../network_gate.dart';
import '../support_clean.dart';
import '../support_report.dart';
import 'common.dart';
import 'contacts_screen.dart' show LiveFieldError;
import 'net_block.dart';
import 'network_mode_text.dart' show blockMode, networkModeName;
import 'settings_screen.dart' show appVersionProvider;

/// `android 14 (…)`: the OS and its version, as Dart reports them. Tests pin it.
// A browser has no dart:io Platform: every member throws there, and the preview build runs
// this screen in a browser, so both providers ask kIsWeb first.
final feedbackPlatformProvider = Provider<String>(
  (ref) => kIsWeb
      ? 'web'
      : '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
);

/// The user's home folder and names, which a report leaves out. Tests pin it.
final feedbackCleanContextProvider = Provider<CleanContext>(
  (ref) => kIsWeb
      ? const CleanContext()
      : CleanContext(
          home:
              Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'],
          username:
              Platform.environment['USER'] ?? Platform.environment['USERNAME'],
          hostname: Platform.localHostname,
        ),
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
    // As the balance header counts it (`walletStatus`): the balance's height, else the node's
    // tip; LEPIC can answer 0 for the balance's.
    final counted = data?.summary.lastConfirmedHeight;
    final height = counted != null && counted > BigInt.zero
        ? counted
        : ref.exists(nodeTipProvider)
        ? ref.read(nodeTipProvider).value?.height
        : null;
    parts.add(
      home.hasError
          ? 'Last sync failed: ${describeError(englishStrings, home.error!)}'
          : data == null
          ? 'Loading'
          : data.syncing
          ? 'Syncing'
          : data.summary.validatedWithNode
          ? height == null
                ? 'Up to date'
                : 'Up to date at height $height'
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
  const FeedbackScreen({super.key, this.lastSession});

  /// The last session that froze or crashed (the notice's Send): its kept log goes instead of
  /// this session's, and the message starts with what happened.
  final LastSessionLog? lastSession;

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

enum _Destination { device, share }

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _message = TextEditingController();
  bool _prefilled = false;
  final _email = TextEditingController();
  bool _attachLogs = true;
  bool _busy = false;
  String? _messageError;
  String? _emailError;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Opened from the last-session notice: the description starts with what happened.
    if (_prefilled) return;
    _prefilled = true;
    final l = context.l10n;
    _message.text = switch (widget.lastSession?.end) {
      null => '',
      LastSessionEnd.froze => l.deskLastSessionReportFroze,
      LastSessionEnd.closed => l.deskLastSessionReportClosed,
    };
  }

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
  Future<SupportReport> _report() async {
    final details = await _details();
    // LEPIC's log ring, redacted at the source; the log's tail where there is none (the web).
    List<LogRingFile>? ring;
    String? log;
    final last = widget.lastSession;
    if (_attachLogs && last != null) {
      ring = last.ring;
      if (ring == null) log = last.log ?? '';
    } else if (_attachLogs) {
      try {
        ring = await ref.read(feedbackRingProvider)();
        if (ring == null) log = await ref.read(feedbackLogProvider).tail(feedbackLogBytes);
      } catch (error) {
        log = 'The log could not be read: $error\n';
      }
    }
    return buildFeedbackReport(
      message: _message.text,
      email: _email.text,
      details: details,
      ring: ring,
      log: log,
      at: ref.read(clockProvider)(),
      context: ref.read(feedbackCleanContextProvider),
      lastSession: widget.lastSession,
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

  /// Opens the preview with the report as it would leave now. Building it reads and cleans
  /// the log tail, so the button shows busy meanwhile, and a failure shows under it instead of
  /// nothing happening.
  Future<void> _preview() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final SupportReport report;
    try {
      report = await _report();
    } catch (error) {
      logWarn('feedback', 'preview failed: $error');
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(context.l10n, error);
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FeedbackPreviewScreen(report: report.text),
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
    final id = await ref.read(feedbackOutletProvider).post(url, report);
    logInfo('feedback', 'sent to ${url.host}, report $id');
    if (mounted) _done(context.l10n.feedbackSent);
  });

  Future<void> _handOver() async {
    if (_busy || !_validate()) return;
    final outlet = ref.read(feedbackOutletProvider);
    var destination = _Destination.device;
    // The choice comes first, so the button only spins while the file is handed over.
    if (outlet.canShare) {
      final chosen = await showPhoneSheet<_Destination>(
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
      final report = (await _report()).text;
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
    // Sending is a network action; saving or sharing the report is not.
    final block = watchNetBlock(context, ref);
    return SlotScaffold(
      appBar: AppBar(title: Text(l.feedbackTitle)),
      body: ScreenBody(
        // The main action at the foot of the screen, as on every form.
        bottom: url != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BusyButton(
                    label: l.feedbackSend,
                    busy: _busy,
                    onPressed: block == NetBlock.none ? () => _send(url) : null,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _busy ? null : _handOver,
                    child: Text(l.feedbackShareOrSaveInstead),
                  ),
                ],
              )
            : BusyButton(
                label: l.feedbackShareOrSave,
                busy: _busy,
                onPressed: _handOver,
              ),
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
            subtitle: Text(
              widget.lastSession == null
                  ? l.feedbackAttachLogsHint
                  : '${l.feedbackAttachLogsHint} ${l.deskLastSessionAttached}',
            ),
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
          if (url != null)
            NetBlockNote(
              block,
              line: blockMode(block) != null ? l.reportOffMode(networkModeName(l, blockMode(block)!)) : null,
            )
          else Text(l.feedbackFileExplanation, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// The exact text a report would carry, which stays English. One line per row, built as it
/// scrolls into view, so a 256 KB log opens at once; the selection area still lets the user
/// copy across rows. The lines are split once, not on every build.
class FeedbackPreviewScreen extends StatefulWidget {
  const FeedbackPreviewScreen({super.key, required this.report});

  final String report;

  @override
  State<FeedbackPreviewScreen> createState() => _FeedbackPreviewScreenState();
}

class _FeedbackPreviewScreenState extends State<FeedbackPreviewScreen> {
  late final List<String> _lines = widget.report.split('\n');
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return SlotScaffold(
      appBar: AppBar(title: Text(context.l10n.feedbackPreviewTitle)),
      body: SafeArea(
        child: SelectionArea(
          child: Scrollbar(
            controller: _scroll,
            child: ListView.builder(
              key: feedbackPreviewListKey,
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _lines.length,
              itemBuilder: (context, i) => Text(_lines[i], style: style),
            ),
          ),
        ),
      ),
    );
  }
}

/// The key of the preview's list, for tests.
const Key feedbackPreviewListKey = ValueKey('feedback-preview-list');


/// Opens [FeedbackScreen]; with [lastSession], for the kept log of a session that froze or
/// crashed.
Future<void> openFeedback(BuildContext context, {LastSessionLog? lastSession}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FeedbackScreen(lastSession: lastSession),
      ),
    );
