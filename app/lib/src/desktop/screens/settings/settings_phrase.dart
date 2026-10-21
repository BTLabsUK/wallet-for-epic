import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'settings_frame.dart';

/// Start states of Settings › Recovery phrase.
enum PhraseDemo { shown }

const _hideAfter = 60;

const _demoWords = [
  'orbit', 'hazard', 'velvet', 'cabin', 'sudden', 'meadow', 'brick', 'gesture', 'lunar', 'invest', 'pledge', 'saddle',
  'timber', 'crisp', 'wander', 'echo', 'faculty', 'notable', 'ripple', 'garlic', 'stamp', 'dwarf', 'enjoy', 'harbor',
];

class SettingsPhraseScreen extends ConsumerStatefulWidget {
  const SettingsPhraseScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsPhraseScreen> createState() => _SettingsPhraseScreenState();
}

class _SettingsPhraseScreenState extends ConsumerState<SettingsPhraseScreen> {
  final _password = TextEditingController();
  List<String>? _words;
  bool _busy = false;
  String? _error;
  int _left = _hideAfter;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.arg == PhraseDemo.shown) {
      _words = _demoWords;
      _left = 48;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _password.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) _hide();
    });
  }

  void _hide() {
    _timer?.cancel();
    setState(() {
      _words = null;
      _password.clear();
      _left = _hideAfter;
    });
  }

  Future<void> _show() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter the password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final w = await ref.read(deskApiProvider).revealPhrase(_password.text);
      if (!mounted) return;
      setState(() {
        _words = w;
        _busy = false;
        _left = _hideAfter;
      });
      _startTimer();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Wrong password.';
        });
      }
    }
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _words!.join(' ')));
    Timer(const Duration(seconds: 30), () => Clipboard.setData(const ClipboardData(text: '')));
    showEToast(context, 'Phrase copied', text: 'The clipboard is cleared in 30 s.');
  }

  @override
  Widget build(BuildContext context) {
    final words = _words;
    final c = context.dc;
    return SettingsFrame(
      route: DeskRoute.settingsPhrase,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ESectionHead('Recovery phrase', top: 0),
          Text('Write the words on paper, in this order. Never type them into a website or a chat.', style: context.ts.bodyDim),
          const SizedBox(height: Sp.x5),
          if (words == null)
            EPanel(
              title: 'Enter the password to show the words',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ESeedGrid(words: List.filled(24, ''), revealed: false),
                  const SizedBox(height: Sp.x5),
                  EField(
                    label: 'Password',
                    error: _error,
                    child: EPasswordInput(controller: _password, invalid: _error != null, onChanged: (_) => setState(() => _error = null), onSubmitted: (_) => _show()),
                  ),
                  const SizedBox(height: Sp.x4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: EButton.primary(label: 'Show words', icon: EIcons.eye, busy: _busy, onPressed: _show),
                  ),
                ],
              ),
            )
          else ...[
            const ENotice(
              title: 'Anyone with these words can take the EPIC',
              text: 'Check that nobody can see the screen.',
              tone: ETone.warn,
            ),
            const SizedBox(height: Sp.x4),
            Semantics(label: 'Recovery phrase, ${words.length} words', child: ESeedGrid(words: words)),
            const SizedBox(height: Sp.x4),
            Row(
              children: [
                EButton(label: 'Copy', icon: EIcons.copy, size: EBtnSize.sm, onPressed: _copy),
                const SizedBox(width: Sp.x2),
                EButton(label: 'Hide', icon: EIcons.eyeOff, size: EBtnSize.sm, onPressed: _hide),
                const Spacer(),
                Text('Hides in $_left s', style: context.ts.small.copyWith(color: c.faint)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
