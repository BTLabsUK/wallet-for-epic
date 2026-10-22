import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feedback.dart';
import '../../../log.dart';
import '../../../support_report.dart';
import '../../../ui/feedback_screen.dart' show feedbackCleanContextProvider, feedbackPlatformProvider;
import '../../app/shell.dart' show deskVersion;
import '../../widgets/kit.dart';

/// Settings › Help › Report a problem: what happened, an optional contact and the app log,
/// cleaned, previewed, sealed to the developer and sent to the support intake. The same report
/// as the phone's Send feedback and the Electron GUI's Report a problem (`support_report.dart`).
Future<void> showReportProblemDialog(BuildContext context) =>
    showEDialog(context, dismissible: false, builder: (_) => const ReportProblemDialog());

class ReportProblemDialog extends ConsumerStatefulWidget {
  const ReportProblemDialog({super.key});

  @override
  ConsumerState<ReportProblemDialog> createState() => _ReportProblemDialogState();
}

class _ReportProblemDialogState extends ConsumerState<ReportProblemDialog> {
  final _description = TextEditingController();
  final _contact = TextEditingController();
  bool _attachLogs = true;
  bool _tried = false;
  bool _busy = false;
  String? _error;
  String? _sentId;

  // Read once, so the preview and the report sent are the same text.
  String? _log;
  late final Future<void> _logRead = _readLog();
  late final DateTime _at = DateTime.now();

  // The preview, built off the UI thread a moment after the last change: cleaning a 256 KB
  // log takes most of a second, too long for every keystroke.
  String? _preview;
  Timer? _previewTimer;
  int _previewRun = 0;

  @override
  void initState() {
    super.initState();
    _logRead;
    _description.addListener(_refreshPreview);
    _contact.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _description.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(milliseconds: 300), () async {
      final run = ++_previewRun;
      final text = (await _report()).text;
      if (mounted && run == _previewRun) setState(() => _preview = text);
    });
  }

  Future<void> _readLog() async {
    try {
      _log = await ref.read(feedbackLogProvider).tail(feedbackLogBytes);
    } catch (error) {
      _log = 'The log could not be read: $error\n';
    }
    if (mounted) setState(() {});
    _refreshPreview();
  }

  FeedbackDetails _details() {
    final s = ref.read(deskProvider);
    final status = s.status;
    return FeedbackDetails(
      appVersion: deskVersion,
      platform: ref.read(feedbackPlatformProvider),
      network: s.account?.network ?? 'Unknown',
      node: status == null ? 'Unknown' : (Uri.tryParse(status.node.url)?.host ?? '?'),
      relay: status?.epicbox.domain ?? 'Unknown',
      sync: status == null
          ? (s.account == null ? 'Wallet locked' : 'Loading')
          : [
              if (status.syncProgress case final p?) 'Syncing, ${(p * 100).round()}%',
              'node ${status.nodeHealth.name} at height ${status.nodeHeight}',
              'epicbox ${status.epicboxHealth.name}',
            ].join(', '),
    );
  }

  /// The report as it would be sent now, cleaned on another isolate.
  Future<SupportReport> _report() {
    final message = _description.text;
    final email = _contact.text;
    final details = _details();
    final log = _attachLogs ? (_log ?? '') : null;
    final at = _at;
    final context = ref.read(feedbackCleanContextProvider);
    return Isolate.run(
      () => buildFeedbackReport(message: message, email: email, details: details, log: log, at: at, ui: 'desktop', context: context),
    );
  }

  bool get _empty => _description.text.trim().isEmpty;

  Future<void> _send() async {
    setState(() {
      _tried = true;
      _error = null;
    });
    final url = ref.read(feedbackUrlProvider);
    if (_empty || _busy || url == null) return;
    setState(() => _busy = true);
    try {
      await _logRead;
      final id = await ref.read(feedbackOutletProvider).post(url, await _report());
      logInfo('support', 'report sent, $id');
      if (mounted) setState(() => _sentId = id);
    } catch (error) {
      logWarn('support', 'report not sent: $error');
      if (mounted) {
        setState(() => _error = error is FeedbackSendError ? error.message : 'The report was not sent. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final nav = Navigator.of(context);
    if (_sentId case final id?) {
      return EDialog(
        title: 'Report sent',
        icon: EIcons.check,
        tone: ETone.ok,
        description: id.isEmpty ? 'The report arrived.' : 'The report arrived. Its reference is $id.',
        actions: [EButton.primary(label: 'Close', size: EBtnSize.sm, onPressed: nav.pop)],
      );
    }
    final canSend = ref.watch(feedbackUrlProvider) != null;
    final emptyError = _tried && _empty ? 'Describe what happened.' : null;
    return PopScope(
      canPop: !_busy,
      child: EDialog(
        title: 'Report a problem',
        width: 560.u,
        dismissible: !_busy,
        description: 'The report is encrypted so only the developer can read it. Nothing is sent before Send.',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EField(
              label: 'What happened',
              error: emptyError,
              child: EInput(
                controller: _description,
                autofocus: true,
                maxLines: 5,
                invalid: emptyError != null,
                hint: 'What you did, what you expected, what happened instead',
                semanticLabel: 'What happened',
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(height: Sp.x4),
            EField(
              label: 'Contact',
              optional: true,
              help: 'An email address or other handle, for a reply.',
              child: EInput(controller: _contact, semanticLabel: 'Contact', onChanged: (_) => setState(() {})),
            ),
            SizedBox(height: Sp.x4),
            ECheckbox(
              value: _attachLogs,
              label: 'Attach logs (recommended)',
              onChanged: (v) {
                setState(() => _attachLogs = v);
                _refreshPreview();
              },
            ),
            SizedBox(height: Sp.x1),
            Text(
              'The newest part of the app log. Recovery phrases, passwords, addresses, IPs and home folders are removed first.',
              style: ts.small,
            ),
            SizedBox(height: Sp.x3),
            EDetails(title: 'What is sent', child: ReportPreview(text: _log == null && _attachLogs ? null : _preview)),
            if (_error != null) ...[
              SizedBox(height: Sp.x3),
              Semantics(liveRegion: true, child: ENotice(title: 'Not sent', text: _error, tone: ETone.risk, icon: EIcons.alert)),
            ],
            if (!canSend) ...[
              SizedBox(height: Sp.x3),
              const ENotice(title: 'Sending is off in this build', tone: ETone.warn),
            ],
          ],
        ),
        actions: [
          EButton(label: 'Cancel', size: EBtnSize.sm, onPressed: _busy ? null : nav.pop),
          EButton.primary(label: 'Send', icon: EIcons.send, size: EBtnSize.sm, busy: _busy, onPressed: canSend ? _send : null),
        ],
      ),
    );
  }
}

/// The report's full text, one line per row so a long log scrolls smoothly. Null while the log
/// is read.
class ReportPreview extends StatelessWidget {
  const ReportPreview({super.key, required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final t = text;
    if (t == null) return Padding(padding: EdgeInsets.all(Sp.x3), child: const ESpinner());
    final lines = t.split('\n');
    final style = ts.mono(size: Fs.xs, color: c.dim);
    return Container(
      height: 220.u,
      decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
      child: SelectionArea(
        child: Scrollbar(
          child: ListView.builder(
            padding: EdgeInsets.all(Sp.x3),
            itemCount: lines.length,
            itemBuilder: (context, i) => Text(lines[i], style: style),
          ),
        ),
      ),
    );
  }
}
