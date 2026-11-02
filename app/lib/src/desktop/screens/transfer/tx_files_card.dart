// SPDX-License-Identifier: Apache-2.0
/// Receive › Transaction files: one Open for every transaction file. The wallet reads each file
/// chosen and does its next step with the calls the single-purpose pages use: a finished payment
/// ([DeskWalletApi.inspectFinished]) is posted, an invoice ([DeskWalletApi.readRequestText])
/// waits for its Review, an answer to one of this wallet's payments
/// ([DeskWalletApi.isResponseText]) is finalized and posted, and anything else is signed and
/// its response saved beside it. One short line per file says what happened.
library;

import 'dart:convert' show utf8;
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models.dart' show FinishedPayment;
import '../../../network_gate.dart' show NetGate;
import '../../../slate_files.dart' show decodeSlateFile;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/files.dart';
import '../../data/invoice_state.dart' show RequestFile;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'import_tx_screen.dart' show ImportArgs;
import 'send_screen.dart' show SendArgs;

/// The Transaction files card. [offlineNode]: Offline on a node that is not local; the files
/// still run, through it. [casual]: the level's plainer heading.
class TxFilesCard extends ConsumerStatefulWidget {
  const TxFilesCard({super.key, required this.offlineNode, this.casual = false});

  final bool offlineNode;
  final bool casual;

  @override
  ConsumerState<TxFilesCard> createState() => _TxFilesCardState();
}

enum _Tone { ok, wait, risk }

/// One file's result line, with the one action that goes on from it.
class _Line {
  const _Line(this.name, this.text, this.tone, {this.action, this.onAction});

  final String name;
  final String? text;
  final _Tone tone;
  final String? action;
  final VoidCallback? onAction;

  bool get working => text == null;
}

class _TxFilesCardState extends ConsumerState<TxFilesCard> {
  final List<_Line> _lines = [];
  bool _busy = false;

  Future<void> _open() async {
    final l = context.l10n;
    // The browser build has no file dialog of its own: the system picker reads the files there.
    // Elsewhere without one (the tests' mock), a fixed sender's file.
    final files = ref.read(deskFilesProvider) ?? (kIsWeb ? const SystemDeskFiles() : null);
    final List<PickedSlate> picked;
    try {
      picked = files == null
          ? [(name: 'invoice_0042.slate', path: 'invoice_0042.slate', bytes: utf8.encode('{"sta":"S1"}'))]
          : await files.pickSlates(title: l.deskTfPickTitle);
    } on Object {
      if (mounted) showEToast(context, l.deskErrFileNotReadable, tone: ETone.warn);
      return;
    }
    if (picked.isEmpty || !mounted) return;
    setState(() {
      _busy = true;
      _lines
        ..clear()
        ..addAll([for (final f in picked) _Line(f.name, null, _Tone.wait)]);
    });
    for (var i = 0; i < picked.length; i++) {
      final line = await _run(picked[i]);
      if (!mounted) return;
      setState(() => _lines[i] = line);
    }
    if (mounted) setState(() => _busy = false);
  }

  /// Reads [f], works out what it is and does its step.
  Future<_Line> _run(PickedSlate f) async {
    final l = context.l10n;
    final api = ref.read(deskApiProvider);
    final nav = ref.read(deskNavProvider.notifier);
    _Line say(String text, _Tone tone, {String? action, VoidCallback? onAction}) =>
        _Line(f.name, text, tone, action: action, onAction: onAction);
    _Line failed(Object e) => say(_bare(e is DeskError ? e.text(l) : deskErrorText(e, l)), _Tone.risk);

    final String text;
    try {
      final bytes = f.bytes ?? (kIsWeb ? null : await File(f.path).readAsBytes());
      if (bytes == null) return say(l.deskErrFileNotReadable, _Tone.risk);
      text = decodeSlateFile(bytes);
    } on FormatException {
      return say(l.deskErrNotTxFile2, _Tone.risk);
    } on Object {
      return say(l.deskErrFileNotReadable, _Tone.risk);
    }

    // A payment both sides finished (under Kill switch, often on another device): post it.
    FinishedPayment? finished;
    try {
      finished = await api.inspectFinished(text);
    } on Object {
      finished = null;
    }
    if (finished != null) {
      final id = finished.slateId;
      final known = (ref.read(deskProvider).txs ?? const <Tx>[]).where((t) => t.slateId == id);
      if (known.any((t) => !t.notPosted && (t.state == TxState.posted || t.state == TxState.confirming || t.state == TxState.confirmed))) {
        return say(l.deskTfAlreadyPosted, _Tone.ok);
      }
      try {
        await api.postFinished(text);
        return say(l.deskFinPosted, _Tone.ok);
      } on Object catch (e) {
        return failed(e);
      }
    }

    // An invoice to pay: nothing is paid before its Review, behind the password.
    RequestFile? request;
    try {
      request = await api.readRequestText(text);
    } on Object {
      request = null;
    }
    if (request != null) {
      if (request.alreadyPaid) return say(l.reqFileAlreadyPaid, _Tone.ok);
      return say(
        l.deskTfInvoice(epicTextL(l, request.amount)),
        _Tone.wait,
        action: l.deskTfReview,
        onAction: () => nav.go(DeskRoute.importTx, ImportArgs(text: text)),
      );
    }

    // The answer to one of this wallet's payments, or to its invoice: finalize and post.
    if (await api.isResponseText(text)) {
      try {
        final tx = kIsWeb ? await api.finalizeText(text) : await api.finalizeFile(f.path);
        // Kill switch finishes without a node: the payment waits in Activity as a file to post.
        if (NetGate.killSwitch && tx.notPosted) {
          return say(l.finalizeNotPostedTitle, _Tone.wait, action: l.deskFinViewActivity, onAction: () => nav.go(DeskRoute.activity, tx.id));
        }
        return say(l.deskFinPosted, _Tone.ok);
      } on Object catch (e) {
        return failed(e);
      }
    }

    // A sender's file: sign it and save the response beside it.
    try {
      final r = kIsWeb ? await api.receiveText(text) : await api.receiveFile(f.path);
      return say(l.deskTfSigned(r.response), _Tone.ok);
    } on Object catch (e) {
      return failed(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final nav = ref.read(deskNavProvider.notifier);
    final canCreate = ref.watch(deskProvider.select((s) => s.settings.payments.directFile));
    return EPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(Sp.panel, Sp.panel, Sp.panel, Sp.x2),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Sp.x3,
              runSpacing: Sp.x2,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(EIcons.file, size: 20.u, color: c.dim),
                    SizedBox(width: 10.u),
                    Semantics(header: true, child: Text(widget.casual ? l.deskLvSendPayFiles : l.deskRecvFiles, style: ts.h3)),
                  ],
                ),
                if (canCreate)
                  EButton.ghost(
                    key: const ValueKey('rx-files-create'),
                    label: l.deskTfCreate,
                    icon: EIcons.send,
                    size: EBtnSize.inline,
                    onPressed: () => nav.go(DeskRoute.send, const SendArgs(method: TxMethod.file)),
                  ),
              ],
            ),
          ),
          ESetRow(
            key: const ValueKey('rx-files-open-row'),
            title: l.deskTfOpenTitle,
            text: l.deskTfOpenText,
            control: EButton(
              key: const ValueKey('rx-files-open'),
              label: l.deskRecvOpen,
              icon: EIcons.fileUp,
              size: EBtnSize.sm,
              busy: _busy,
              onPressed: _busy ? null : _open,
            ),
            below: _lines.isEmpty ? null : _results(),
          ),
          if (widget.offlineNode) ...[
            Divider(height: 1, thickness: 1, color: c.line),
            Padding(
              padding: EdgeInsets.fromLTRB(Sp.panel, Sp.x3, Sp.panel, Sp.x4),
              child: Row(
                key: const ValueKey('rx-files-offline-node'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(EIcons.info, size: 16.u, color: c.info),
                  SizedBox(width: 8.u),
                  Expanded(child: Text(l.netOfflineNodeHint, style: ts.small)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _results() {
    final c = context.dc;
    final ts = context.ts;
    return Semantics(
      key: const ValueKey('rx-files-results'),
      container: true,
      liveRegion: true,
      label: context.l10n.deskTfResults,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in _lines)
            Padding(
              padding: EdgeInsets.symmetric(vertical: Sp.x1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 16.u,
                    height: 20.u,
                    child: Center(
                      child: line.working
                          ? ESpinner(size: 14.u)
                          : Icon(
                              switch (line.tone) {
                                _Tone.ok => EIcons.check,
                                _Tone.wait => EIcons.info,
                                _Tone.risk => EIcons.error,
                              },
                              size: 16.u,
                              color: switch (line.tone) {
                                _Tone.ok => c.ok,
                                _Tone.wait => c.info,
                                _Tone.risk => c.risk,
                              },
                            ),
                    ),
                  ),
                  SizedBox(width: Sp.x2),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: line.name, style: ts.small.copyWith(color: c.text, fontWeight: FontWeight.w600)),
                          TextSpan(text: '  ${line.text ?? context.l10n.deskTfWorking}'),
                        ],
                      ),
                      style: ts.small,
                    ),
                  ),
                  if (line.action != null) ...[
                    SizedBox(width: Sp.x2),
                    EButton.ghost(label: line.action!, size: EBtnSize.inline, onPressed: line.onAction),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// [text] without its closing full stop: a result line, not a sentence of its own.
String _bare(String text) => text.endsWith('.') ? text.substring(0, text.length - 1) : text;
