// SPDX-License-Identifier: Apache-2.0
import '../../../ui/network_mode_text.dart' show blockMode, networkModeName;
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../../feedback.dart';
import '../../../log.dart';
import '../../../support_report.dart';
import '../../../ui/feedback_screen.dart' show feedbackCleanContextProvider, feedbackPlatformProvider;
import '../../app/shell.dart' show deskVersion;
import '../../data/logs.dart';
import '../../data/net_mode_view.dart';
import '../../../network_gate.dart' show NetBlock;
import '../../widgets/kit.dart';
import '../../../settings_file/host_settings.dart' show hostSettings, shippedHostSettings;

/// Settings › Help › Report a problem: what happened, an optional contact and the app log
/// (LEPIC's log ring, redacted at the source; `wfe.log`, cleaned, with Include full details),
/// previewed, sealed to the developer and sent to the support intake. The same report
/// as the phone's Send feedback and the Electron GUI's Report a problem (`support_report.dart`).
/// Save to file writes the same cleaned text, not sealed, where the user picks.
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

  /// "Include full details": the log's wallet addresses and amounts as they are, so `wfe.log`
  /// goes rather than LEPIC's ring, which never holds them.
  bool _fullDetails = false;
  bool _tried = false;
  bool _busy = false;
  String? _error;
  String? _sentId;
  bool _saving = false;
  String? _saved;

  /// The log's files as they were when the log was read, for "What is sent".
  List<LogFileInfo> _files = const [];

  // Read once, so the preview and the report sent are the same text: LEPIC's ring (null where
  // there is none), its files newest first for "What is sent", and the tail of `wfe.log`.
  List<LogRingFile>? _ring;
  List<LogFileInfo> _ringFiles = const [];
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
      final ring = await ref.read(feedbackRingProvider)();
      _ring = ring;
      if (ring != null) {
        _ringFiles = [for (final f in ring.reversed) LogFileInfo(f.name, utf8.encode(f.text).length)];
      }
      final sink = ref.read(feedbackLogProvider);
      _files = await sink.files();
      _log = await sink.tail(feedbackLogBytes);
    } catch (error) {
      _log = 'The log could not be read: $error\n'; // l10n-ok: goes into the report
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
      // l10n-ok: the report body sent to the developer stays English
      network: s.account?.network ?? 'Unknown', // l10n-ok
      node: status == null ? 'Unknown' : (Uri.tryParse(status.node.url)?.host ?? '?'), // l10n-ok
      relay: status?.epicbox.domain ?? 'Unknown', // l10n-ok
      sync: status == null
          ? (s.account == null ? 'Wallet locked' : 'Loading') // l10n-ok
          : [
              if (status.syncProgress case final p?) 'Syncing, ${(p * 100).round()}%', // l10n-ok
              'node ${status.nodeHealth.name} at height ${status.nodeHeight}', // l10n-ok
              'epicbox ${status.epicboxHealth.name}', // l10n-ok
            ].join(', '),
      logLevel: ref.read(logsProvider).label,
    );
  }

  /// The report as it would be sent now, cleaned on another isolate.
  Future<SupportReport> _report() {
    final message = _description.text;
    final email = _contact.text;
    final details = _details();
    final fullDetails = _attachLogs && _fullDetails;
    // The ring unless Include full details asks for what only `wfe.log` holds.
    final ring = _attachLogs && !fullDetails ? _ring : null;
    final log = _attachLogs && ring == null ? (_log ?? '') : null;
    final at = _at;
    final context = ref.read(feedbackCleanContextProvider);
    // The cleaning keeps the hosts the shipped files name: the other isolate gets a copy of the
    // settings in use and of the default copy (its own would fall back to the user's).
    final settings = hostSettings;
    final shipped = shippedHostSettings;
    return Isolate.run(() {
      hostSettings = settings;
      shippedHostSettings = shipped;
      return buildFeedbackReport(message: message, email: email, details: details, ring: ring, log: log, at: at, ui: 'desktop', context: context, fullDetails: fullDetails);
    });
  }

  bool get _empty => _description.text.trim().isEmpty;

  Future<void> _send() async {
    final l = context.l10n;
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
        setState(() => _error = error is FeedbackSendError ? error.message : l.deskSetReportNotSent);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Writes the cleaned report, not sealed, through the system Save dialog.
  Future<void> _save() async {
    if (_busy || _saving) return;
    final l = context.l10n;
    setState(() {
      _saving = true;
      _saved = null;
      _error = null;
    });
    try {
      await _logRead;
      final saved = await ref
          .read(feedbackOutletProvider)
          .save(name: feedbackFileName(_at), report: (await _report()).text, dialogTitle: l.deskSetReportSaveDialog);
      if (saved) logInfo('support', 'report saved to a file');
      if (mounted && saved) setState(() => _saved = l.deskSetReportSaved);
    } catch (error) {
      logWarn('support', 'report not saved: $error');
      if (mounted) setState(() => _error = l.deskSetReportNotSaved);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// "What is sent": the report text and each log file with how much of it goes along.
  List<String> _parts(AppLocalizations l) => [
    l.deskSetReportText,
    if (_attachLogs) ...[
      if (_ring != null && !_fullDetails)
        ...describeLogFiles(_ringFiles, logRingBytes, l)
      else if (_files.isEmpty)
        l.deskSetReportAppLog(logSize((_log ?? '').length, l))
      else
        ...describeLogFiles(_files, feedbackLogBytes, l),
      if (_fullDetails) l.deskSetReportPartFullDetails,
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final l = context.l10n;
    final nav = Navigator.of(context);
    if (_sentId case final id?) {
      return EDialog(
        title: l.deskSetReportSent,
        icon: EIcons.check,
        tone: ETone.ok,
        description: id.isEmpty ? l.deskSetReportArrived : l.deskSetReportArrivedRef(id),
        actions: [EButton.primary(label: l.commonClose, size: EBtnSize.sm, onPressed: nav.pop)],
      );
    }
    final block = ref.watch(deskNetBlockProvider);
    final canSend = ref.watch(feedbackUrlProvider) != null && block == NetBlock.none;
    final emptyError = _tried && _empty ? l.deskSetReportDescribe : null;
    return CallbackShortcuts(
      // The barrier does not close the dialog (a stray click would lose the text); Esc does.
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => _busy ? null : nav.maybePop()},
      child: PopScope(
      canPop: !_busy,
      child: EDialog(
        title: l.deskSetReportTitle,
        width: 560.u,
        dismissible: !_busy,
        description: l.deskSetReportDesc,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EField(
              label: l.deskSetReportWhat,
              error: emptyError,
              child: EInput(
                controller: _description,
                autofocus: true,
                maxLines: 4,
                invalid: emptyError != null,
                hint: l.deskSetReportWhatHint,
                semanticLabel: l.deskSetReportWhat,
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(height: Sp.x4),
            EField(
              label: l.deskSetReportContact,
              optional: true,
              child: EInput(
                controller: _contact,
                hint: l.deskSetReportContactHint,
                semanticLabel: l.deskSetReportContact,
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(height: Sp.x4),
            ECheckbox(
              value: _attachLogs,
              label: l.deskSetReportAttach,
              onChanged: (v) {
                setState(() => _attachLogs = v);
                _refreshPreview();
              },
            ),
            SizedBox(height: Sp.x1),
            Text(
              l.deskSetReportAttachHint,
              style: ts.small,
            ),
            if (_attachLogs) ...[
              SizedBox(height: Sp.x2),
              // The tick and, beside it, what it changes and what never goes: behind the info
              // icon, so the dialog carries no small print under it.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ECheckbox(
                    key: const ValueKey('report-full-details'),
                    value: _fullDetails,
                    label: l.deskSetReportFullDetails,
                    onChanged: (v) {
                      setState(() => _fullDetails = v);
                      _refreshPreview();
                    },
                  ),
                  SizedBox(width: Sp.x1),
                  EInfoHint(l.deskSetReportFullDetailsInfo, key: const ValueKey('report-full-details-info'), title: l.deskSetReportFullDetails, icon: EIcons.info),
                ],
              ),
            ],
            SizedBox(height: Sp.x3),
            EDetails(
              title: l.deskSetReportSentWhat,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_parts(l).join(' · '), style: ts.small),
                  SizedBox(height: Sp.x2),
                  ReportPreview(text: _log == null && _attachLogs ? null : _preview),
                ],
              ),
            ),
            if (_saved != null) ...[
              SizedBox(height: Sp.x3),
              Semantics(liveRegion: true, child: ENotice(title: _saved!, tone: ETone.ok, icon: EIcons.check)),
            ],
            if (_error != null) ...[
              SizedBox(height: Sp.x3),
              Semantics(liveRegion: true, child: ENotice(title: l.deskSetReportNotSentTitle, text: _error, tone: ETone.risk, icon: EIcons.alert)),
            ],
            if (!canSend) ...[
              SizedBox(height: Sp.x3),
              ENotice(
                title: blockMode(block) != null ? l.reportOffMode(networkModeName(l, blockMode(block)!)) : (netBlockReason(l, block) ?? l.deskSetReportOff),
                tone: ETone.warn,
              ),
            ],
          ],
        ),
        actions: [
          EButton(label: l.commonCancel, size: EBtnSize.sm, onPressed: _busy ? null : nav.pop),
          EButton(label: l.deskSetReportSaveToFile, icon: EIcons.download, size: EBtnSize.sm, busy: _saving, onPressed: _busy ? null : _save),
          EButton.primary(label: l.deskSetReportSend, icon: EIcons.send, size: EBtnSize.sm, busy: _busy, onPressed: canSend ? _send : null),
        ],
      ),
      ),
    );
  }
}

/// The report's full text, one line per row so a long log scrolls smoothly. Null while the log
/// is read.
class ReportPreview extends StatefulWidget {
  const ReportPreview({super.key, required this.text});

  final String? text;

  @override
  State<ReportPreview> createState() => _ReportPreviewState();
}

class _ReportPreviewState extends State<ReportPreview> {
  // Its own: the always-shown thumb (theme.dart) needs a controller, and a dialog has no primary one.
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final t = widget.text;
    if (t == null) return Padding(padding: EdgeInsets.all(Sp.x3), child: const ESpinner());
    final lines = t.split('\n');
    final style = ts.mono(size: Fs.xs, color: c.dim);
    // Short enough that the whole dialog, opened, fits an 800 px window (the Include full
    // details tick took its share).
    final height = (MediaQuery.sizeOf(context).height - 680.u).clamp(96.u, 220.u);
    return Container(
      height: height,
      decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
      // Selectable through the dialog's own selection area (selectable.dart).
      child: Scrollbar(
        controller: _scroll,
        child: ListView.builder(
          controller: _scroll,
          padding: EdgeInsets.all(Sp.x3),
          itemCount: lines.length,
          itemBuilder: (context, i) => Text(lines[i], style: style),
        ),
      ),
    );
  }
}
