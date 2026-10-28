import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/api.dart' show DeskWalletApi;
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../data/net_mode_view.dart';
import '../../../network_gate.dart' show NetBlock;
import '../../widgets/kit.dart';
import '../wallet/restore_scan_panel.dart' show RestoreScanProgress;
import 'settings_frame.dart';
import 'settings_advanced.dart' show advancedHas, AdvancedFeature;

/// Start states of Settings › Recheck balance.
enum RescanDemo { running }

/// Why a scan ended, for the result card.
enum _End { finished, stopped }

/// Where Recheck starts with Advanced › Recheck from a height, as on the phone: a date's
/// block (mainnet), a typed height, or block 0. Without the switch it starts a little before
/// the last scan's end.
enum _From { date, height, wholeChain }

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
  _From? _fromChoice;
  DateTime? _fromDate;

  /// Dates map to heights only on mainnet.
  bool get _datesOk => (ref.read(deskProvider).account?.network ?? 'mainnet') == 'mainnet'; // l10n-ok: network id

  _From get _from => _fromChoice ?? (_datesOk ? _From.date : _From.height);
  set _from(_From v) => _fromChoice = v;
  final _height = TextEditingController();
  String? _heightError;

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
    _height.dispose();
    super.dispose();
  }

  Future<int?> _total() async {
    try {
      return (await ref.read(deskApiProvider).balance()).total;
    } on Object {
      return null;
    }
  }

  /// The start the choice asks for; null for the recent blocks. A height that is not a number of
  /// 1 or more is refused under the field.
  ({BigInt? start, bool ok}) _startHeight(AppLocalizations l) {
    if (!advancedHas(ref, AdvancedFeature.recheckFromHeight)) return (start: null, ok: true);
    switch (_from) {
      case _From.date:
        final d = _fromDate;
        if (d == null) {
          setState(() => _heightError = l.deskSetRescanPickDateFirst);
          return (start: null, ok: false);
        }
        return (start: mainnetHeightForDate(d), ok: true);
      case _From.wholeChain:
        return (start: BigInt.zero, ok: true);
      case _From.height:
        final h = BigInt.tryParse(_height.text.trim());
        if (h == null || h < BigInt.one) {
          setState(() => _heightError = l.deskSetRescanHeightInvalid);
          return (start: null, ok: false);
        }
        return (start: h, ok: true);
    }
  }

  Future<void> _start() async {
    final l = context.l10n;
    final delete = DeskFeatures.rescanRepair && advancedHas(ref, AdvancedFeature.recheckFromHeight) && _deleteUnconfirmed;
    final from = _startHeight(l);
    if (!from.ok) return;
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
    _scan = api.rescan(deleteUnconfirmed: delete, startHeight: from.start).listen(
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
    // Offline without a local node, or Tor only without Tor: nothing to recheck against.
    final block = ref.watch(deskNodeBlockProvider);
    final reason = netBlockReason(l, block);
    // The scan a restore owes runs: its progress here, and no second scan.
    final restore = ref.watch(deskProvider.select((s) => s.status?.restoreScan));
    final restoreRuns = !_running && restore?.state == RestoreScanState.running;
    final choice = advancedHas(ref, AdvancedFeature.recheckFromHeight);
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
                  control: ERowControl(child: EButton.primary(label: _end != null || _failure != null ? l.deskSetRescanRecheckAgain : l.deskSetRescanRecheck, icon: EIcons.scan, size: EBtnSize.sm, onPressed: block == NetBlock.none && !restoreRuns ? _start : null)),
                  below: reason != null || restoreRuns || choice
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (reason != null) Text(reason, key: const ValueKey('rescan-net-blocked'), style: ts.small),
                            if (restoreRuns) ...[
                              Text(l.deskSetRescanRestoreRunning, key: const ValueKey('rescan-restore-runs'), style: ts.small),
                              SizedBox(height: Sp.x2),
                              RestoreScanProgress(percent: restore!.percent),
                            ],
                            if (choice) ...[
                              SizedBox(height: Sp.x3),
                              Semantics(header: true, child: Text(l.deskSetRescanStartHeading, style: ts.label)),
                              SizedBox(height: Sp.x2),
                              // One choice, as radio buttons are (EChoiceCard is a mutually exclusive group).
                              for (final (from, title, hint) in [
                                if (_datesOk) (_From.date, l.deskSetRescanFromDate, null),
                                (_From.height, l.deskSetRescanFromHeight, null),
                                (_From.wholeChain, l.deskSetRescanWholeChain, l.deskSetRescanWholeChainHint),
                              ]) ...[
                                EChoiceCard(
                                  key: ValueKey('rescan-from-${from.name}'),
                                  title: title,
                                  description: hint,
                                  selected: _from == from,
                                  onTap: () => setState(() {
                                    _from = from;
                                    _heightError = null;
                                  }),
                                ),
                                if (from == _From.date && _from == _From.date)
                                  Padding(
                                    padding: EdgeInsets.only(top: Sp.x2, left: Sp.x4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        EStartDate(
                                          date: _fromDate,
                                          label: l.deskSetRescanPickDate,
                                          onChanged: (d) => setState(() {
                                            _fromDate = d;
                                            _heightError = null;
                                          }),
                                        ),
                                        if (_heightError != null) ...[SizedBox(height: Sp.x1), Text(_heightError!, style: ts.small.copyWith(color: c.risk))],
                                      ],
                                    ),
                                  ),
                                if (from == _From.height && _from == _From.height)
                                  Padding(
                                    padding: EdgeInsets.only(top: Sp.x2, left: Sp.x4),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: 240.u),
                                      child: EField(
                                        label: l.deskOnbRestoreFromLabel,
                                        error: _heightError,
                                        child: EInput(
                                          key: const ValueKey('rescan-height'),
                                          controller: _height,
                                          mono: true,
                                          autofocus: true,
                                          semanticLabel: l.deskOnbRestoreFromLabel,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          invalid: _heightError != null,
                                          onChanged: (_) => setState(() => _heightError = null),
                                          onSubmitted: (_) => _start(),
                                        ),
                                      ),
                                    ),
                                  ),
                                SizedBox(height: Sp.x2),
                              ],
                              SizedBox(height: Sp.x2),
                            ],
                            if (DeskFeatures.rescanRepair && choice) ...[
                            ECheckbox(value: _deleteUnconfirmed, onChanged: (v) => setState(() => _deleteUnconfirmed = v), label: l.deskSetRescanDeleteUnconfirmed),
                            Padding(
                              padding: EdgeInsets.only(left: Sp.x8),
                              child: Text(
                                l.deskSetRescanDeleteHint,
                                style: ts.caption,
                              ),
                            ),
                            ],
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
