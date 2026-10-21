import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'settings_frame.dart';

/// Start states of Settings › Rescan.
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
  double _progress = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.arg == RescanDemo.running) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start(from: 0.42));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start({double from = 0}) async {
    setState(() {
      _running = true;
      _done = false;
      _progress = from;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted && _progress < 0.95) setState(() => _progress += 0.03);
    });
    await ref.read(deskApiProvider).rescan();
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _running = false;
      _done = true;
      _progress = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return SettingsFrame(
      route: DeskRoute.settingsRescan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ESectionHead('Rescan', top: 0),
          Text(
            'Scans the chain again when the balance looks wrong. Also removes outputs of transactions that never completed.',
            style: context.ts.bodyDim,
          ),
          const SizedBox(height: Sp.x5),
          if (_running) ...[
            ENotice(
              title: 'Scanning the chain',
              text: 'The wallet stays usable. The balance updates when the scan is done.',
              icon: EIcons.sync,
            ),
            const SizedBox(height: Sp.x4),
            EProgress(value: _progress),
            const SizedBox(height: Sp.x2),
            Text('${(_progress * 100).round()} %', style: context.ts.mono(size: Fs.sm, color: c.dim)),
          ] else if (_done) ...[
            const ENotice(title: 'Scan finished', text: 'The balance is up to date.', tone: ETone.ok),
            const SizedBox(height: Sp.x5),
          ],
          if (!_running)
            Align(
              alignment: Alignment.centerLeft,
              child: EButton.primary(label: _done ? 'Rescan again' : 'Rescan', icon: EIcons.scan, onPressed: _start),
            ),
        ],
      ),
    );
  }
}
