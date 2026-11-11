// SPDX-License-Identifier: Apache-2.0
import 'dart:convert' show utf8;
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../epic1.dart' show PaymentMode, looksLikeEpictx;
import '../../../slate_files.dart' show maxSlateFileBytes;
import '../../data/files.dart';
import '../../data/invoice_state.dart' show RequestFile;
import '../../data/net_mode_view.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../epic1/epic1_files.dart' show openDeskEpictx, showEpic1ModeDialog;
import '../invoices/review_screen.dart' show RequestFileReview;
import '../scan/desk_scan.dart' show DeskPasted, DeskScanned;
import 'file_panels.dart';
import 'qr_payment.dart';

/// Argument of the Import route: [done] opens on the saved response file, [error] on a
/// refused file.
class ImportArgs {
  const ImportArgs({this.done = false, this.error, this.text});

  final bool done;
  final ImportError? error;

  /// A transaction file's text pasted into Send: signed at once, as a chosen file is.
  final String? text;
}

/// Why a transaction file was not signed.
enum ImportError {
  wrongType,
  unreadable,
  noPlace,
  failed;

  String title(AppLocalizations l) => switch (this) {
    wrongType => l.deskImpWrongType,
    unreadable => l.deskImpUnreadable,
    noPlace => l.deskImpNoPlace,
    failed => l.deskImpFailed,
  };

  String text(AppLocalizations l) => switch (this) {
    wrongType => l.deskImpWrongTypeText,
    unreadable => l.deskImpUnreadableText,
    noPlace => l.deskImpNoPlaceText,
    failed => l.deskImpFailedText,
  };
}

class ImportTxScreen extends ConsumerStatefulWidget {
  const ImportTxScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<ImportTxScreen> createState() => _ImportTxScreenState();
}

class _ImportTxScreenState extends ConsumerState<ImportTxScreen> {
  bool _busy = false;

  /// What was signed came as pasted text, not a file: its error says so (LNX-3).
  bool _pasted = false;
  String? _response;
  ImportError? _error;

  /// The wallet's own reason, under a failed signing.
  DeskError? _detail;
  Tx? _tx;
  // The paired contact a sealed file came from; a plain file names none, whatever it claims.
  String? _sender;

  /// A payment request read from the file, under review (DESIGN §3.3).
  RequestFile? _request;

  /// The saved file answers a payment request, not a payment to this wallet.
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    final a = widget.arg;
    if (a is ImportArgs && a.done) _response = 'f0e1d2c3.response';
    if (a is ImportArgs) _error = a.error;
    final text = a is ImportArgs ? a.text : null;
    if (text != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final api = ref.read(deskApiProvider);
        if (await _isRequest(() => api.readRequestText(text), pasted: true)) return;
        await _receive(() => api.receiveText(text), pasted: true);
      });
    }
  }

  Future<void> _pick() async {
    final files = ref.read(deskFilesProvider);
    final path = files == null ? 'invoice_0042.slate' : await files.pickSlate(title: context.l10n.deskImpPickTitle);
    if (path == null || !mounted) return;
    if (files != null && await _otherMode(path)) return;
    final api = ref.read(deskApiProvider);
    if (await _isRequest(() => api.readRequestFile(path))) return;
    await _receive(() => api.receiveFile(path), mock: files == null);
  }

  /// A file the payment mode in use does not open: in epic1 mode a `.epictx` goes on to its
  /// flow and a classic file gets the mode line; in classic mode a `.epictx` gets the mode line.
  /// True when the file was handled here.
  Future<bool> _otherMode(String path) async {
    final String text;
    try {
      final file = File(path);
      if (await file.length() > maxSlateFileBytes) return false;
      text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
    } on Object {
      return false;
    }
    if (!mounted) return false;
    final epictx = path.toLowerCase().endsWith('.epictx') || looksLikeEpictx(text);
    final epic1Mode = ref.read(deskPaymentModeProvider) == PaymentMode.epic1;
    if (epic1Mode && epictx) {
      await openDeskEpictx(context, ref, text);
    } else if (epic1Mode) {
      await showEpic1ModeDialog(context, ref, context.l10n.deskE1ModeClassicFile);
    } else if (epictx) {
      await showEpic1ModeDialog(context, ref, context.l10n.deskE1ModeEpic1File);
    } else {
      return false;
    }
    return true;
  }

  /// A payment request opens its Review. True when the file was one. Any other file, or one
  /// that cannot be read, goes on to signing, which says why.
  Future<bool> _isRequest(Future<RequestFile?> Function() read, {bool pasted = false}) async {
    final RequestFile? request;
    try {
      request = await read();
    } on Object {
      return false;
    }
    if (request == null || !mounted) return false;
    setState(() {
      _pasted = pasted;
      _detail = null;
      if (ref.read(deskApiProvider).supportsRequestFiles) {
        _request = request;
        _error = null;
      } else {
        _error = ImportError.wrongType;
      }
    });
    return true;
  }

  /// Signs what [receive] reads and shows the answer, or why not.
  Future<void> _receive(Future<ReceivedFile> Function() receive, {bool mock = false, bool pasted = false}) async {
    if (!mounted) return;
    setState(() {
      _pasted = pasted;
      _busy = true;
      _error = null;
      _detail = null;
    });
    try {
      final r = await receive();
      if (!mounted) return;
      setState(() {
        _tx = r.tx;
        _sender = r.sender;
        _response = mock ? 'f0e1d2c3.response' : r.response;
      });
    } on DeskError catch (e) {
      if (mounted) {
        setState(() {
          _error = e.unreadable ? ImportError.unreadable : (e.wrongType ? ImportError.wrongType : ImportError.failed);
          _detail = e;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = ImportError.unreadable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Scan QR: a sender's payment or an invoice as an animated code, or the text pasted in its
  /// place, read as pasted text. A scanned payment's reply is shown as a QR code at once.
  Future<void> _scan() async {
    final l = context.l10n;
    final got = await deskScanSlate(context, ref, title: l.qrScanPayment, hint: l.deskQrAimPayment, notSlate: (l) => l.qrScanNotPayment);
    if (got == null || !mounted) return;
    final (text, scanned) = switch (got) {
      DeskScanned(:final value) => (value, true),
      DeskPasted(:final text) => (text, false),
    };
    final api = ref.read(deskApiProvider);
    if (await _isRequest(() => api.readRequestText(text), pasted: true)) return;
    await _receive(() => api.receiveText(text), pasted: true);
    final response = _response;
    if (scanned && response != null && deskQrShowsFile(response) && mounted) {
      await showDeskSlateQr(context, kind: DeskQrKind.reply, path: response);
    }
  }

  void _again() => setState(() {
    _response = null;
    _tx = null;
    _sender = null;
    _request = null;
    _answered = false;
  });

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final ts = context.ts;
    final l = context.l10n;
    // Offline on a node that is not local: the file still runs, through that node.
    final offlineNode = ref.watch(deskOfflineUsesNodeProvider);
    final request = _request;
    if (request != null && _response == null) {
      return EPage(
        title: l.reqTitle,
        onBack: _again,
        child: RequestFileReview(
          file: request,
          onNotNow: _again,
          onAnswered: (r) => setState(() {
            _request = null;
            _answered = true;
            _tx = r.tx;
            _response = r.response;
          }),
        ),
      );
    }
    // After paying a request file the page is about that payment: no "signing spends nothing".
    final paid = _answered && _response != null;
    return EPage(
      title: paid ? l.reqTitle : l.deskImpTitle,
      width: EPageWidth.narrow,
      onBack: () => nav.canBack ? nav.back() : nav.go(DeskRoute.receive),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!paid) ...[
            ENotice(
              title: l.deskImpNoticeTitle,
              text: l.deskImpNoticeText,
              icon: EIcons.info,
            ),
            SizedBox(height: Sp.x5),
          ],
          if (offlineNode) ...[
            ENotice(
              key: const ValueKey('file-offline-node'),
              title: l.advModeNodeOnly,
              text: l.netOfflineNodeHint,
              tone: ETone.info,
              icon: EIcons.info,
            ),
            SizedBox(height: Sp.x5),
          ],
          if (_error != null) ...[
            ENotice(title: _error!.title(l), text: _error == ImportError.failed && _detail != null ? _failedText(l, _detail!.text(l)) : (_error == ImportError.wrongType && _pasted ? l.deskImpWrongTypePasted : _error!.text(l)), tone: ETone.risk, icon: EIcons.error),
            SizedBox(height: Sp.x5),
          ],
          if (_response != null)
            ResultPanel(
              title: _answered ? l.reqAnswerTitle : l.deskImpSaved,
              text: _answered ? l.reqAnswerLead : l.deskImpSavedText,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FileChip(_response!),
                  if (_tx != null) ...[
                    SizedBox(height: Sp.x3),
                    Row(children: [Text(l.deskImpAmount, style: ts.small), EMoney(_tx!.amount)]),
                  ],
                  if (_tx != null && !_answered) ...[
                    SizedBox(height: Sp.x2),
                    Row(
                      children: [
                        Text(l.deskImpFrom, style: ts.small),
                        SizedBox(width: Sp.x2),
                        Flexible(child: Text(_sender ?? l.deskTxUnknownSender, key: const ValueKey('imp-sender'), style: _sender == null ? ts.bodyDim : ts.strong, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                EButton.primary(label: paid ? l.deskImpOpenAnother : l.deskImpAnother, icon: EIcons.fileUp, onPressed: _again),
                if (deskQrShowsFile(_response!))
                  DeskShowQrButton(key: const ValueKey('imp-show-qr'), kind: _answered ? DeskQrKind.paid : DeskQrKind.reply, path: _response),
                EButton(label: l.deskFinViewActivity, onPressed: () => nav.go(DeskRoute.activity, _tx?.id)),
              ],
            )
          else if (_busy)
            EPanel(
              padding: EdgeInsets.all(Sp.x8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ESpinner(size: 20.u),
                  SizedBox(width: Sp.x3),
                  Text(l.deskImpBusy, style: ts.bodyDim),
                ],
              ),
            )
          else ...[
            EDropZone(
              title: l.deskImpChoose,
              text: l.deskImpChooseText,
              buttonLabel: l.deskFinChooseFile,
              onPick: _pick,
            ),
            SizedBox(height: Sp.x3),
            DeskScanRow(text: l.deskQrScanImport, button: DeskQrScanButton(key: const ValueKey('imp-scan'), onScan: _scan)),
          ],
        ],
      ),
    );
  }
}

/// Why signing a file failed. An unfinished restore says only that (the file is fine); other
/// reasons follow the usual lead, without a second full stop.
String _failedText(AppLocalizations l, String detail) {
  if (detail == l.deskErrRestoreScanRequired) return detail;
  final bare = detail.endsWith('.') || detail.endsWith('。') ? detail.substring(0, detail.length - 1) : detail;
  return l.deskImpFailedDetail(bare);
}
