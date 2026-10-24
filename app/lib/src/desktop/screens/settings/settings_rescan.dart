import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/api.dart' show DeskWalletApi;
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import 'settings_frame.dart';

/// Start states of Settings › Recheck balance.
enum RescanDemo { running }

/// Why a scan ended, for the result card.
enum _End { finished, stopped }

class SettingsRescanScreen extends ConsumerStatefulWidget {
  const SettingsRescanScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsRescanScreen> createState() => _SettingsRescanScreenState();
}

class _SettingsRescanScreenState extends ConsumerState<SettingsRescanScreen> {
  bool _running = false;
  bool _stopping = false;
  _End? _end;
  bool _deleteUnconfirmed = false;

  /// Whether the scan that ran had Delete unconfirmed on.
  bool _deleted = false;

  String? _failure;
  int? _percent;
  bool _finished = false;
  ScanCounts? _counts;

  /// The total balance before the scan and after it; null when it could not be read.
  int? _before;
  int? _after;

  /// Newest line first.
  final List<String> _log = [];
  StreamSubscription<ScanStep>? _scan;

  /// The scan answered once: before that a Stop reaches no scan, so Stop waits.
  bool _live = false;

  /// The wallet the scan runs on, kept to stop it when the screen goes.
  DeskWalletApi? _api;

  @override
  void initState() {
    super.initState();
    if (widget.arg == RescanDemo.running) WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    // Leaving the screen ends the scan: nothing would show its result.
    if (_running) unawaited(_api?.stopRescan());
    _scan?.cancel();
    super.dispose();
  }

  Future<int?> _total() async {
    try {
      return (await ref.read(deskApiProvider).balance()).total;
    } on Object {
      return null;
    }
  }

  Future<void> _start() async {
    final l = context.l10n;
    final delete = DeskFeatures.rescanRepair && _deleteUnconfirmed;
    setState(() {
      _running = true;
      _stopping = false;
      _end = null;
      _deleted = delete;
      _failure = null;
      _percent = null;
      _finished = false;
      _counts = null;
      _before = null;
      _after = null;
      _live = false;
      _log.clear();
    });
    final before = await _total();
    if (!mounted) return;
    setState(() => _before = before);
    final api = ref.read(deskApiProvider);
    _api = api;
    _scan = api.rescan(deleteUnconfirmed: delete).listen(
      (step) {
        if (!mounted) return;
        setState(() {
          _live = true;
          _percent = step.percent ?? _percent;
          _finished = _finished || step.finished;
          _counts = step.counts ?? _counts;
          if (_log.firstOrNull != step.message) _log.insert(0, step.message);
        });
      },
      onError: (Object e) {
        if (mounted) {
          setState(() {
            _running = false;
            _stopping = false;
            _failure = deskErrorText(e, l);
          });
        }
      },
      onDone: () async {
        if (!mounted || !_running) return;
        final after = await _total();
        if (!mounted) return;
        setState(() {
          _running = false;
          _stopping = false;
          _after = after;
          _end = _finished ? _End.finished : _End.stopped;
          _log.insert(0, _finished ? l.deskSetRescanComplete : l.deskSetRescanStoppedLine);
        });
      },
    );
  }

  /// Asks the core to stop; the scan ends at its next page and the balance is read again.
  Future<void> _stop() async {
    setState(() => _stopping = true);
    await ref.read(deskApiProvider).stopRescan();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final log = Container(
      constraints: BoxConstraints(maxHeight: 220.u),
      decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
      child: Semantics(
        label: l.deskSetRescanLog,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(Sp.x3),
          children: [for (final line in _log) Text(line, style: ts.mono(size: Fs.xs, color: c.dim))],
        ),
      ),
    );
    final percent = _percent;
    return SettingsFrame(
      route: DeskRoute.settingsRescan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ESetGroup(
            title: l.deskSetFrameRescan,
            rows: [
              if (!_running)
                ESetRow(
                  text: l.deskSetRescanText,
                  control: ERowControl(child: EButton.primary(label: _end != null || _failure != null ? l.deskSetRescanStartAgain : l.deskSetLnodeStart, icon: EIcons.scan, size: EBtnSize.sm, onPressed: _start)),
                  below: DeskFeatures.rescanRepair
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ECheckbox(value: _deleteUnconfirmed, onChanged: (v) => setState(() => _deleteUnconfirmed = v), label: l.deskSetRescanDeleteUnconfirmed),
                            Padding(
                              padding: EdgeInsets.only(left: Sp.x8),
                              child: Text(
                                l.deskSetRescanDeleteHint,
                                style: ts.caption,
                              ),
                            ),
                          ],
                        )
                      : null,
                )
              else
                ESetRow(
                  text: l.deskSetRescanScanning,
                  stacked: true,
                  control: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          ESpinner(size: Ctl.iconSm),
                          SizedBox(width: Sp.x2),
                          Expanded(
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                _stopping ? l.deskSetRescanStopping : (percent == null ? l.deskSetFrameChecking : l.deskSetRescanChecking(percent)),
                                style: ts.strong,
                              ),
                            ),
                          ),
                          if (DeskFeatures.stopScan)
                            ERowControl(child: EButton(label: l.deskSetLnodeStop, icon: EIcons.stop, size: EBtnSize.sm, busy: _stopping, onPressed: _stopping || !_live ? null : _stop)),
                        ],
                      ),
                      SizedBox(height: Sp.x3),
                      EProgress(value: percent == null ? null : percent / 100),
                      SizedBox(height: Sp.x3),
                      EDetails(title: l.deskSetRescanLog, initiallyOpen: true, child: log),
                    ],
                  ),
                ),
            ],
          ),
          if (_end != null) _result(context),
          if (_failure != null) ENotice(title: l.deskSetRescanFailed, text: _failure, tone: ETone.risk, icon: EIcons.error),
          if (!_running && _log.isNotEmpty) ...[
            SizedBox(height: Sp.x4),
            EDetails(title: l.deskSetRescanLog, child: log),
          ],
        ],
      ),
    );
  }

  /// The Delete unconfirmed outcome. The core counts outputs, not transactions (a send has
  /// locked inputs and an unconfirmed change output), so no transaction count is claimed.
  static String _cancelled(AppLocalizations l, ScanCounts c) => c.unlocked + c.deleted == 0 ? l.deskSetRescanNoneFound : l.deskSetRescanCancelled;

  Widget _result(BuildContext context) {
    final l = context.l10n;
    final finished = _end == _End.finished;
    final counts = _counts;
    Widget money(int? nano) => nano == null ? Text(l.deskSetRescanNotRead) : EMoney(nano);
    return ESetGroup(
      title: finished ? l.deskSetRescanFinished : l.deskSetRescanStoppedLine,
      rows: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  [
                    if (finished) ...[
                      l.deskSetRescanUpToDate,
                      if (_deleted && counts != null) _cancelled(l, counts),
                      if (counts?.resumed == true) l.deskSetRescanResumed,
                    ] else ...[
                      l.deskSetRescanStoppedEarly,
                      if (_deleted) l.deskSetRescanNotDeleted,
                    ],
                  // Chinese sentences follow each other without a space; Thai separates them with one.
                  ].join(l.localeName == 'zh' ? '' : ' '),
                  style: context.ts.bodyDim,
                ),
              ),
              SizedBox(height: Sp.x3),
              EFacts([
                (l.deskSetRescanBefore, money(_before)),
                (l.deskSetRescanAfter, money(_after)),
                if (counts != null) ...[
                  (l.deskSetRescanFound, Text('${counts.found}')),
                  (l.deskSetRescanRestored, Text('${counts.restored}')),
                  (l.deskSetRescanRevived, Text('${counts.revived}')),
                  if (_deleted) ...[
                    (l.deskSetRescanUnlocked, Text('${counts.unlocked}')),
                    (l.deskSetRescanDeleted, Text('${counts.deleted}')),
                  ],
                ],
              ]),
            ],
          ),
        ),
      ],
    );
  }
}
