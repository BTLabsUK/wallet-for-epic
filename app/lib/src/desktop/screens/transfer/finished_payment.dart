// SPDX-License-Identifier: Apache-2.0
/// The desktop's two ends of a Kill switch payment. [FinishedNotPostedPanel] is what Finalize
/// shows when it finished a payment without a node: "Finished, not posted", with the finished
/// payment as a file (`<first 8 of the id>.finished.tx`, LEPIC's final slate) or as text to copy.
/// [PostFinishedDialog] is Receive › Transaction files › Post a finished payment: open the file
/// or paste its text, read the amount, fee and kernel, and post it to the node in use. No PIN:
/// posting needs no key. The desktop shows no QR codes of payments, so a finished payment
/// leaves it as a file or text; the phone's Post a finished payment also scans one.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models.dart' show FinishedPayment;
import '../../../network_gate.dart';
import '../../../slate_files.dart' show shortSlateId;
import '../../data/history_files.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/net_mode_view.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'file_panels.dart' show ResultGlyph, ResultPanel;

/// The file a finished payment is saved as.
String finishedFileName(String slateId) => '${shortSlateId(slateId)}.finished.tx';

/// Save file and Copy for the finished payment [tx], two small buttons: in a payment's details
/// while Kill switch holds it ([Tx.notPosted]).
class FinishedPaymentActions extends ConsumerWidget {
  const FinishedPaymentActions({super.key, required this.tx});

  final Tx tx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    Future<String?> text() async {
      try {
        return await ref.read(deskApiProvider).finishedPayment(tx.id);
      } on Object catch (e) {
        if (context.mounted) showEToast(context, e is DeskError && e.unsupported ? l.finishedUnavailable : l.finishedFailed, tone: ETone.warn);
        return null;
      }
    }
    return Wrap(
      spacing: Sp.x2,
      runSpacing: Sp.x2,
      children: [
        EButton.primary(
          key: const ValueKey('tx-finished-save'),
          label: l.finishedSaveFile,
          icon: EIcons.fileDown,
          size: EBtnSize.sm,
          onPressed: () async {
            final t = await text();
            if (t == null || !context.mounted) return;
            final name = finishedFileName(tx.slateId);
            final path = await ref.read(deskHistoryFilesProvider).save(name: name, bytes: Uint8List.fromList(utf8.encode(t)), title: l.finishedSaveFile);
            if (path != null && context.mounted) showEToast(context, l.finishedSaved(name), tone: ETone.ok);
          },
        ),
        EButton(
          key: const ValueKey('tx-finished-copy'),
          label: l.commonCopy,
          icon: EIcons.copy,
          size: EBtnSize.sm,
          onPressed: () async {
            final t = await text();
            if (t == null || !context.mounted) return;
            await Clipboard.setData(ClipboardData(text: t));
            if (context.mounted) showEToast(context, l.slateCopied, tone: ETone.ok);
          },
        ),
      ],
    );
  }
}

/// "Finished, not posted" for the payment [tx] (finalized while Kill switch holds every
/// connection): what to do with it and the buttons.
class FinishedNotPostedPanel extends ConsumerStatefulWidget {
  const FinishedNotPostedPanel({super.key, required this.tx, required this.actions});

  final Tx tx;

  /// The buttons after Save file (Another file, View in Activity).
  final List<Widget> actions;

  @override
  ConsumerState<FinishedNotPostedPanel> createState() => _FinishedNotPostedPanelState();
}

class _FinishedNotPostedPanelState extends ConsumerState<FinishedNotPostedPanel> {
  bool _busy = false;
  String? _error;

  Future<String?> _text() async {
    final l = context.l10n;
    try {
      return await ref.read(deskApiProvider).finishedPayment(widget.tx.id);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e is DeskError && e.unsupported ? l.finishedUnavailable : l.finishedFailed);
      return null;
    }
  }

  Future<void> _save() async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final text = await _text();
      if (text == null || !mounted) return;
      final name = finishedFileName(widget.tx.slateId);
      final path = await ref.read(deskHistoryFilesProvider).save(name: name, bytes: Uint8List.fromList(utf8.encode(text)), title: l.finishedSaveFile);
      if (path != null && mounted) showEToast(context, l.finishedSaved(name), tone: ETone.ok);
    } on Object catch (e) {
      if (mounted) setState(() => _error = deskErrorText(e, l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final l = context.l10n;
    final text = await _text();
    if (text == null || !mounted) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showEToast(context, l.slateCopied, tone: ETone.ok);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    return ResultPanel(
      title: l.finalizeNotPostedTitle,
      text: l.deskFinNotPostedKillBody(epicTextL(l, widget.tx.amount)),
      glyph: const ResultGlyph.waiting(),
      body: _error == null ? null : Text(_error!, key: const ValueKey('finished-error'), style: context.ts.small.copyWith(color: c.dim)),
      actions: [
        EButton.primary(key: const ValueKey('finished-save'), label: l.finishedSaveFile, icon: EIcons.fileDown, busy: _busy, onPressed: _busy ? null : _save),
        EButton(key: const ValueKey('finished-copy'), label: l.commonCopy, icon: EIcons.copy, onPressed: _busy ? null : _copy),
        ...widget.actions,
      ],
    );
  }
}

/// Opens Post a finished payment; with [text] it opens on that text's summary (the screenshot
/// tour and the tests).
Future<void> showPostFinished(BuildContext context, {String? text}) =>
    showEDialog<void>(context, builder: (_) => PostFinishedDialog(text: text));

class PostFinishedDialog extends ConsumerStatefulWidget {
  const PostFinishedDialog({super.key, this.text});

  /// A finished payment's text to read at once.
  final String? text;

  @override
  ConsumerState<PostFinishedDialog> createState() => _PostFinishedDialogState();
}

class _PostFinishedDialogState extends ConsumerState<PostFinishedDialog> {
  @override
  void initState() {
    super.initState();
    final text = widget.text;
    if (text != null) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _read(text) : null);
  }

  String? _text;
  FinishedPayment? _payment;
  String? _error;
  bool _busy = false;
  bool _posted = false;

  Future<void> _read(String text) async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
      _payment = null;
      _text = null;
    });
    try {
      final p = await ref.read(deskApiProvider).inspectFinished(text.trim());
      if (!mounted) return;
      setState(() {
        _text = text.trim();
        _payment = p;
      });
    } on Object {
      if (mounted) setState(() => _error = l.postFinishedNotFinished);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose() async {
    final l = context.l10n;
    try {
      final file = await ref.read(deskHistoryFilesProvider).pick(title: l.postFinishedChooseFile, extensions: const ['tx', 'json'], maxBytes: 1 << 20);
      if (file == null || !mounted) return;
      await _read(utf8.decode(file.bytes, allowMalformed: true));
    } on Object {
      if (mounted) setState(() => _error = l.postFinishedNotFinished);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (!mounted) return;
    if (text == null || text.isEmpty) {
      setState(() => _error = context.l10n.postFinishedNotFinished);
      return;
    }
    await _read(text);
  }

  Future<void> _post() async {
    final l = context.l10n;
    final text = _text;
    if (text == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(deskApiProvider).postFinished(text);
      if (mounted) setState(() => _posted = true);
    } on NetBlocked {
      if (mounted) setState(() => _error = NetGate.killSwitch ? l.postFinishedOffKill : l.postFinishedOffTor);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e is DeskError ? deskErrorText(e, l) : l.postFinishedFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final block = ref.watch(deskNodeBlockProvider);
    final blocked = block != NetBlock.none;
    final p = _payment;
    final kernel = p?.kernelExcess;
    Widget row(String label, String value, {bool mono = false}) => Padding(
      padding: EdgeInsets.symmetric(vertical: Sp.x1),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ts.bodyDim)),
          Text(value, style: mono ? ts.mono(size: Fs.sm, color: c.text) : ts.body),
        ],
      ),
    );
    return EDialog(
      key: const ValueKey('post-finished-dialog'),
      title: _posted ? l.postFinishedDone : l.postFinishedTitle,
      description: _posted ? l.postFinishedDoneBody : l.postFinishedIntro,
      icon: _posted ? EIcons.check : EIcons.fileUp,
      tone: _posted ? ETone.ok : ETone.neutral,
      body: _posted
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: Sp.x3,
                  runSpacing: Sp.x2,
                  children: [
                    EButton(key: const ValueKey('post-finished-choose'), label: l.postFinishedChooseFile, icon: EIcons.fileDown, onPressed: blocked || _busy ? null : _choose),
                    EButton(key: const ValueKey('post-finished-paste'), label: l.postFinishedPaste, icon: EIcons.copy, onPressed: blocked || _busy ? null : _paste),
                  ],
                ),
                if (blocked) ...[
                  SizedBox(height: Sp.x3),
                  Text(
                    block == NetBlock.killSwitch ? l.postFinishedOffKill : (block == NetBlock.waitingForTor ? l.postFinishedOffTor : netBlockReason(l, block) ?? ''),
                    key: const ValueKey('post-finished-blocked'),
                    style: ts.small.copyWith(color: c.dim),
                  ),
                ],
                if (_error != null) ...[
                  SizedBox(height: Sp.x3),
                  Text(_error!, key: const ValueKey('post-finished-error'), style: ts.small.copyWith(color: c.risk)),
                ],
                if (p != null) ...[
                  SizedBox(height: Sp.x4),
                  Semantics(header: true, child: Text(l.postFinishedSummary, style: ts.strong)),
                  SizedBox(height: Sp.x2),
                  Column(
                    key: const ValueKey('post-finished-summary'),
                    children: [
                      row(l.postFinishedAmount, formatEpicL(l, p.amount.toInt())),
                      row(l.postFinishedFee, formatEpicL(l, p.fee.toInt())),
                      if (kernel != null) row(l.postFinishedKernel, kernel.length <= 20 ? kernel : '${kernel.substring(0, 10)}…${kernel.substring(kernel.length - 8)}', mono: true),
                    ],
                  ),
                  SizedBox(height: Sp.x3),
                  Text(l.postFinishedNote, style: ts.small),
                ],
              ],
            ),
      actions: [
        if (_posted)
          EButton(label: l.commonDone, autofocus: true, onPressed: () => Navigator.pop(context))
        else ...[
          EButton(label: l.commonClose, onPressed: () => Navigator.pop(context)),
          if (p != null)
            EButton.primary(
              key: const ValueKey('post-finished-post'),
              label: _busy ? l.postFinishedPosting : l.postFinishedPost,
              busy: _busy,
              onPressed: blocked || _busy ? null : _post,
            ),
        ],
      ],
    );
  }
}
