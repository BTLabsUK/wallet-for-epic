import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'settings_frame.dart';

/// Start states of Settings › Recovery phrase.
enum PhraseDemo { shown, qr }

const _hideAfter = 60;

const _demoWords = [
  'orbit', 'hazard', 'velvet', 'cabin', 'sudden', 'meadow', 'brick', 'gesture', 'lunar', 'invest', 'pledge', 'saddle',
  'timber', 'crisp', 'wander', 'echo', 'faculty', 'notable', 'ripple', 'garlic', 'stamp', 'dwarf', 'enjoy', 'harbor',
];


Timer? _clipboardTimer;

/// Copies a recovery phrase and clears the clipboard 30 s later if the phrase is still there.
/// One timer for the app, outliving the page.
Future<void> copyPhrase(BuildContext context, String phrase) async {
  try {
    await Clipboard.setData(ClipboardData(text: phrase));
  } on Object {
    if (context.mounted) showEToast(context, 'Not copied', text: 'The clipboard refused the text.', tone: ETone.risk);
    return;
  }
  _clipboardTimer?.cancel();
  _clipboardTimer = Timer(const Duration(seconds: 30), () async {
    final now = await Clipboard.getData(Clipboard.kTextPlain);
    if (now?.text == phrase) await Clipboard.setData(const ClipboardData(text: ''));
  });
  if (context.mounted) showEToast(context, 'Phrase copied', text: 'The clipboard is cleared in 30 s.');
}

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
  bool _qr = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.arg == PhraseDemo.shown || widget.arg == PhraseDemo.qr) {
      _qr = widget.arg == PhraseDemo.qr;
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
      _qr = false;
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e is DeskError && !e.wrongPassword ? e.message : 'Wrong password.';
        });
      }
    }
  }

  void _copy() => copyPhrase(context, _words!.join(' '));

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
          SizedBox(height: Sp.x5),
          if (words == null)
            EPanel(
              title: 'Enter the password to show the words',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ESeedGrid(words: List.filled(24, ''), revealed: false),
                  SizedBox(height: Sp.x5),
                  EField(
                    label: 'Password',
                    error: _error,
                    child: EPasswordInput(controller: _password, invalid: _error != null, onChanged: (_) => setState(() => _error = null), onSubmitted: (_) => _show()),
                  ),
                  SizedBox(height: Sp.x4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: EButton.primary(label: 'Show words', icon: EIcons.eye, busy: _busy, onPressed: _show),
                  ),
                ],
              ),
            )
          else ...[
            Semantics(label: 'Recovery phrase, ${words.length} words', child: ESeedGrid(words: words)),
            SizedBox(height: Sp.x4),
            Wrap(
              spacing: Sp.x2,
              runSpacing: Sp.x2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                EButton(label: 'Copy', icon: EIcons.copy, size: EBtnSize.sm, kind: EBtnKind.ghost, onPressed: _copy),
                Semantics(
                  expanded: _qr,
                  child: EButton(
                    label: _qr ? 'Hide QR code' : 'Show QR code',
                    icon: _qr ? EIcons.eyeOff : EIcons.qr,
                    size: EBtnSize.sm,
                    kind: EBtnKind.ghost,
                    onPressed: () => setState(() => _qr = !_qr),
                  ),
                ),
                EButton(label: 'Hide words', icon: EIcons.eyeOff, size: EBtnSize.sm, onPressed: _hide),
                Text('Hides in $_left s', style: context.ts.small.copyWith(color: c.faint)),
              ],
            ),
            if (_qr) ...[
              SizedBox(height: Sp.x4),
              Align(
                alignment: Alignment.centerLeft,
                child: Semantics(label: 'QR code of the recovery phrase', image: true, child: EQr(words.join(' '), size: 216.u)),
              ),
            ],
            SizedBox(height: Sp.x5),
            const ENotice(
              title: 'Back up the phrase',
              text: 'Anyone with these words can take the EPIC. Check that nobody can see the screen.',
              tone: ETone.warn,
              icon: EIcons.shield,
            ),
          ],
        ],
      ),
    );
  }
}
