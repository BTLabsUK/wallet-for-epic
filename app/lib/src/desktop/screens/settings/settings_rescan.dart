import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import 'settings_frame.dart';

/// Start states of Settings › Recheck balance.
enum RescanDemo { running }


class SettingsRescanScreen extends ConsumerStatefulWidget {
  const SettingsRescanScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsRescanScreen> createState() => _SettingsRescanScreenState();
}

class _SettingsRescanScreenState extends ConsumerState<SettingsRescanScreen> {
  bool _running = false;
  bool _done = false;
  bool _stopped = false;
  bool _deleteUnconfirmed = false;

  String? _failure;
  int? _percent;

  /// Newest line first.
  final List<String> _log = [];
  StreamSubscription<ScanStep>? _scan;

  @override
  void initState() {
    super.initState();
    if (widget.arg == RescanDemo.running) WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _scan?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _done = false;
      _stopped = false;
      _failure = null;
      _percent = null;
      _log.clear();
    });
    _scan = ref.read(deskApiProvider).rescan().listen(
      (step) {
        if (!mounted) return;
        setState(() {
          _percent = step.percent ?? _percent;
          if (_log.firstOrNull != step.message) _log.insert(0, step.message);
        });
      },
      onError: (Object e) {
        if (mounted) {
          setState(() {
            _running = false;
            _failure = deskErrorText(e);
          });
        }
      },
      onDone: () {
        if (mounted && _running) {
          setState(() {
            _running = false;
            _done = true;
            _log.insert(0, 'Scan complete');
          });
        }
      },
    );
  }

  void _stop() {
    _scan?.cancel();
    setState(() {
      _running = false;
      _stopped = true;
      _log.insert(0, 'Scan stopped');
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final log = Container(
      constraints: BoxConstraints(maxHeight: 220.u),
      decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
      child: Semantics(
        label: 'Scan log',
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(Sp.x3),
          children: [for (final l in _log) Text(l, style: ts.mono(size: Fs.xs, color: c.dim))],
        ),
      ),
    );
    return SettingsFrame(
      route: DeskRoute.settingsRescan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ESetGroup(
            title: 'Recheck balance',
            rows: [
              if (!_running)
                ESetRow(
                  title: 'Recheck balance',
                  text: 'Scans the chain again when the balance looks wrong.',
                  control: EButton.primary(label: _done || _stopped ? 'Start again' : 'Start', icon: EIcons.scan, size: EBtnSize.sm, onPressed: _start),
                  below: DeskFeatures.rescanRepair
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ECheckbox(value: _deleteUnconfirmed, onChanged: (v) => setState(() => _deleteUnconfirmed = v), label: 'Delete unconfirmed transactions'),
                            Padding(
                              padding: EdgeInsets.only(left: Sp.x8),
                              child: Text('Also removes outputs of transactions that never completed.', style: ts.caption),
                            ),
                          ],
                        )
                      : null,
                )
              else
                ESetRow(
                  title: 'Recheck balance',
                  text: 'Scanning the chain. The wallet stays usable; the balance updates when the scan is done.',
                  stacked: true,
                  control: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          ESpinner(size: Ctl.iconSm),
                          SizedBox(width: Sp.x2),
                          Expanded(child: Semantics(liveRegion: true, child: Text(_percent == null ? 'Checking…' : 'Checking… $_percent %', style: ts.strong))),
                          if (DeskFeatures.stopScan) EButton(label: 'Stop', icon: EIcons.stop, size: EBtnSize.sm, onPressed: _stop),
                        ],
                      ),
                      SizedBox(height: Sp.x3),
                      const EProgress(),
                      SizedBox(height: Sp.x3),
                      EDetails(title: 'Scan log', initiallyOpen: true, child: log),
                    ],
                  ),
                ),
            ],
          ),
          if (_done) const ENotice(title: 'Scan finished', text: 'The balance is up to date.', tone: ETone.ok),
          if (_failure != null) ENotice(title: 'Scan failed', text: _failure, tone: ETone.risk, icon: EIcons.error),
          if (!_running && _log.isNotEmpty) ...[
            SizedBox(height: Sp.x4),
            EDetails(title: 'Scan log', child: log),
          ],
        ],
      ),
    );
  }
}
