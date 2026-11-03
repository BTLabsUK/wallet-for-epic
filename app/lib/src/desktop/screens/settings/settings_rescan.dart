// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/api.dart' show DeskWalletApi;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/net_mode_view.dart';
import '../../../network_gate.dart' show NetBlock;
import '../../../ui/scan_start.dart';
import '../../widgets/kit.dart';
import '../wallet/restore_scan_panel.dart' show RestoreScanProgress;
import '../../data/settings_registry.dart' show settingsEntry;
import '../../widgets/more_options.dart' show moreOptionsOpen;
import 'search/settings_sections.dart' show SetGate, setGateReasons, setJoinReasons, setViewProvider;
import 'setting_ids.dart';
import 'settings_frame.dart';
import 'settings_advanced.dart' show advancedHas, AdvancedFeature;

/// Start states of Settings › Recheck balance.
enum RescanShot { running }

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

  /// Where the scan starts, as on the phone (`scan_start.dart`): a month's block (mainnet;
  /// January 2025 unless another is picked), the start, or with Advanced › Recheck from a
  /// height a typed height. Made on first use: the network comes from the account.
  late final _scanStart = ScanStartController(dates: _datesOk);

  /// The reveal key of the Delete unconfirmed row the view or Advanced › Recheck from a height
  /// hides.
  static const _revealKey = 'rescan-start';

  /// The hidden options are in use: shown by the view and the switch, or revealed here.
  bool get _choice => advancedHas(ref, AdvancedFeature.recheckFromHeight) || moreOptionsOpen(ref, _revealKey);

  /// Dates map to heights only on mainnet.
  bool get _datesOk => (ref.read(deskProvider).account?.network ?? 'mainnet') == 'mainnet'; // l10n-ok: network id

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
    if (widget.arg == RescanShot.running) WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    // Leaving the screen ends the scan: nothing would show its result.
    if (_running) unawaited(_api?.stopRescan());
    _scan?.cancel();
    _scanStart.dispose();
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
    final delete = _choice && _deleteUnconfirmed;
    // Block 0 for the start, as the phone: never the core's "a little before the last scan".
    final from = _scanStart.start ?? BigInt.zero;
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
    _scan = api.rescan(deleteUnconfirmed: delete, startHeight: from).listen(
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
      decoration: c.well,
      child: Semantics(
        label: l.deskSetRescanLog,
        // A scroll view of a column: lines are added at the top, which a lazy list under the
        // text selection cannot take.
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Sp.x3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final line in _log) Text(line, style: ts.mono(size: Fs.xs, color: c.dim))],
          ),
        ),
      ),
    );
    final percent = _percent;
    // Offline without a local node, or Tor only without Tor: nothing to recheck against.
    final block = ref.watch(deskNodeBlockProvider);
    final reason = block == NetBlock.killSwitch ? l.recheckOffKill : netBlockReason(l, block);
    // The scan a restore owes runs: its progress here, and no second scan.
    final restore = ref.watch(deskProvider.select((s) => s.status?.restoreScan));
    final restoreRuns = !_running && restore?.state == RestoreScanState.running;
    final shown = advancedHas(ref, AdvancedFeature.recheckFromHeight);
    // Hidden here: what shows the rows, for the ⇕ control and each row's marker.
    final gate = settingsEntry(SetId.recheckDrop)?.gate ?? SetGate.none;
    final by = shown ? null : setJoinReasons(l, setGateReasons(l, gate, ref.watch(setViewProvider)));
    return SettingsFrame(
      route: DeskRoute.settingsRescan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The page title says Recheck balance; the group needs no second heading.
          ESetGroup(
            revealKey: _revealKey,
            hidden: !_running && !shown ? [_deleteRow(context, advancedBy: by)] : const [],
            rows: [
              if (!_running)
                ESetRow(
                  text: l.deskSetRescanText,
                  control: ERowControl(child: EButton.primary(label: _end != null || _failure != null ? l.deskSetRescanRecheckAgain : l.deskSetRescanRecheck, icon: EIcons.scan, size: EBtnSize.sm, onPressed: block == NetBlock.none && !restoreRuns ? _start : null)),
                  below: reason != null || restoreRuns
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (reason != null) Text(reason, key: const ValueKey('rescan-net-blocked'), style: ts.small),
                            if (restoreRuns) ...[
                              Text(l.deskSetRescanRestoreRunning, key: const ValueKey('rescan-restore-runs'), style: ts.small),
                              SizedBox(height: Sp.x2),
                              RestoreScanProgress(percent: restore!.percent),
                            ],
                          ],
                        )
                      : null,
                ),
              // Where to start: the phone's block, with heights behind the switch (or revealed).
              if (!_running)
                ESetRow(
                  anchor: SetId.recheckFrom,
                  title: l.deskSetRescanStartHeading,
                  stacked: true,
                  control: ScanStart(controller: _scanStart, heights: _choice),
                ),
              if (!_running && shown) _deleteRow(context),
              if (_running)
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

  /// The Delete unconfirmed row of Advanced › Recheck from a height, with its control in the
  /// control column.
  Widget _deleteRow(BuildContext context, {String? advancedBy}) {
    final l = context.l10n;
    return ESetRow(
      anchor: SetId.recheckDrop,
      advancedBy: advancedBy,
      title: l.deskSetRescanDeleteUnconfirmed,
      hint: l.deskSetRescanDeleteHint,
      control: ESwitch(
        key: const ValueKey('rescan-delete-unconfirmed'),
        value: _deleteUnconfirmed,
        semanticLabel: l.deskSetRescanDeleteUnconfirmed,
        onChanged: (v) => setState(() => _deleteUnconfirmed = v),
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
