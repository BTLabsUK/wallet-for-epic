// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../widgets/kit.dart';
import 'settings_frame.dart';
import '../../../phrase_clipboard.dart';

/// Start states of Settings › Recovery phrase.
enum PhraseDemo { shown, qr }

const _hideAfter = 60;

const _demoWords = [
  'orbit', 'hazard', 'velvet', 'cabin', 'sudden', 'meadow', 'brick', 'gesture', 'lunar', 'invest', 'pledge', 'saddle',
  'timber', 'crisp', 'wonder', 'echo', 'faculty', 'notable', 'ripple', 'garlic', 'stamp', 'dwarf', 'enjoy', 'harbor',
];


/// Warns that anyone with the words can take the funds, and copies a recovery phrase if the
/// user agrees. The clipboard is cleared after [phraseClipboardLifetime] and on lock, if the
/// phrase is still there ([copyPhraseToClipboard]).
Future<void> copyPhrase(BuildContext context, String phrase) async {
  final l = context.l10n;
  final sure = await showEDialog<bool>(
    context,
    builder: (context) => EDialog(
      title: l.deskSetPhraseCopyTitle,
      description: l.deskSetPhraseCopyText,
      icon: EIcons.alert,
      tone: ETone.warn,
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.of(context).pop(false)),
        EButton.primary(label: l.commonCopy, onPressed: () => Navigator.of(context).pop(true)),
      ],
    ),
  );
  if (sure != true || !context.mounted) return;
  if (!await copyPhraseToClipboard(phrase)) {
    if (context.mounted) showEToast(context, l.deskSetPhraseNotCopied, text: l.deskSetPhraseClipboardRefused, tone: ETone.risk);
    return;
  }
  if (context.mounted) showEToast(context, l.deskSetPhraseCopied, text: l.deskSetPhraseCleared, tone: ETone.ok);
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
  /// The open QR dialog's context: hiding the words closes it too.
  BuildContext? _qrDialog;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.arg == PhraseDemo.shown || widget.arg == PhraseDemo.qr) {
      _words = _demoWords;
      _left = 48;
      if (widget.arg == PhraseDemo.qr) WidgetsBinding.instance.addPostFrameCallback((_) => _openQr());
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

  void _openQr() {
    final words = _words;
    if (!mounted || words == null) return;
    showPhraseQrDialog(context, words.join(' '), onOpen: (dialog) => _qrDialog = dialog).whenComplete(() => _qrDialog = null);
  }

  void _hide() {
    _timer?.cancel();
    final dialog = _qrDialog;
    if (dialog != null && dialog.mounted) Navigator.of(dialog).pop();
    setState(() {
      _words = null;
      _password.clear();
      _left = _hideAfter;
    });
  }

  Future<void> _show() async {
    final l = context.l10n;
    if (_password.text.isEmpty) {
      setState(() => _error = l.deskSetPhraseEnterPassword);
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
          _error = e is DeskError && !e.wrongPassword ? deskErrorText(e, l) : l.deskSetPhraseWrongPassword;
        });
      }
    }
  }

  void _copy() => copyPhrase(context, _words!.join(' '));

  @override
  Widget build(BuildContext context) {
    final words = _words;
    final c = context.dc;
    final l = context.l10n;
    final head = [
      ESectionHead(l.deskSetFramePhrase, top: 0),
      Text(l.deskSetPhraseIntro, style: context.ts.bodyDim),
      SizedBox(height: Sp.x5),
    ];
    if (words == null) {
      return SettingsFrame(
        route: DeskRoute.settingsPhrase,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...head,
            EPanel(
              title: l.deskSetPhrasePanel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ESeedGrid(words: List.filled(24, ''), revealed: false),
                  SizedBox(height: Sp.x5),
                  EField(
                    label: l.deskSetDlgPassword,
                    error: _error,
                    child: EPasswordInput(controller: _password, invalid: _error != null, onChanged: (_) => setState(() => _error = null), onSubmitted: (_) => _show()),
                  ),
                  SizedBox(height: Sp.x4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: EButton.primary(label: l.deskSetPhraseShowWords, icon: EIcons.eye, busy: _busy, onPressed: _show),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    // The words scroll on their own: the actions above them and the warning under them stay in view.
    return SettingsFrame(
      route: DeskRoute.settingsPhrase,
      fill: true,
      child: EPhraseLayout(
        header: head,
        actions: [
          Text(l.deskSetPhraseHidesIn(_left), style: context.ts.small.copyWith(color: c.faint)),
          EButton(label: l.commonCopy, icon: EIcons.copy, size: EBtnSize.sm, kind: EBtnKind.ghost, onPressed: _copy),
          // A centred dialog, never under the scrolling words (item 18).
          EButton(label: l.deskSetPhraseShowQr, icon: EIcons.qr, size: EBtnSize.sm, kind: EBtnKind.ghost, onPressed: _openQr),
          EButton(label: l.deskSetPhraseHideWords, icon: EIcons.eyeOff, size: EBtnSize.sm, onPressed: _hide),
        ],
        grid: Semantics(label: l.deskSetPhraseWordsLabel(words.length), child: ESeedGrid(words: words)),
        footer: ENotice(
          title: l.deskSetPhraseBackUp,
          text: l.deskSetPhraseBackUpText,
          tone: ETone.warn,
          icon: EIcons.shield,
        ),
      ),
    );
  }
}
