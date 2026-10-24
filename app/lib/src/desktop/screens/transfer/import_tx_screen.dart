import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/files.dart';
import '../../data/net_mode_view.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'file_panels.dart';

/// Argument of the Import route: [done] opens on the saved response file, [error] on a
/// refused file.
class ImportArgs {
  const ImportArgs({this.done = false, this.error});

  final bool done;
  final ImportError? error;
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
  String? _response;
  ImportError? _error;

  /// The wallet's own reason, under a failed signing.
  DeskError? _detail;
  Tx? _tx;

  @override
  void initState() {
    super.initState();
    final a = widget.arg;
    if (a is ImportArgs && a.done) _response = 'invoice_0042.response.slate';
    if (a is ImportArgs) _error = a.error;
  }

  Future<void> _pick() async {
    final files = ref.read(deskFilesProvider);
    final path = files == null ? 'invoice_0042.slate' : await files.pickSlate(title: context.l10n.deskImpPickTitle);
    if (path == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _detail = null;
    });
    try {
      final r = await ref.read(deskApiProvider).receiveFile(path);
      if (!mounted) return;
      setState(() {
        _tx = r.tx;
        _response = files == null ? 'invoice_0042.response.slate' : r.response;
      });
    } on DeskError catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message == 'File not readable' ? ImportError.unreadable : (e.message == 'Not a transaction file' ? ImportError.wrongType : ImportError.failed); // l10n-ok: DeskError.message is the English key
          _detail = e;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = ImportError.unreadable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _again() => setState(() {
    _response = null;
    _tx = null;
  });

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final ts = context.ts;
    final l = context.l10n;
    // Offline on a node that is not local: the file still runs, through that node.
    final offlineNode = ref.watch(deskOfflineUsesNodeProvider);
    return EPage(
      title: l.deskImpTitle,
      width: EPageWidth.narrow,
      onBack: () => nav.canBack ? nav.back() : nav.go(DeskRoute.receive),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ENotice(
            title: l.deskImpNoticeTitle,
            text: l.deskImpNoticeText,
            icon: EIcons.info,
          ),
          SizedBox(height: Sp.x5),
          if (offlineNode) ...[
            ENotice(
              key: const ValueKey('file-offline-node'),
              title: l.advHomeOffline,
              text: l.netOfflineNodeHint,
              tone: ETone.info,
              icon: EIcons.info,
            ),
            SizedBox(height: Sp.x5),
          ],
          if (_error != null) ...[
            ENotice(title: _error!.title(l), text: _error == ImportError.failed && _detail != null ? l.deskImpFailedDetail(_detail!.text(l)) : _error!.text(l), tone: ETone.risk, icon: EIcons.error),
            SizedBox(height: Sp.x5),
          ],
          if (_response != null)
            ResultPanel(
              title: l.deskImpSaved,
              text: l.deskImpSavedText,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FileChip(_response!),
                  if (_tx != null) ...[
                    SizedBox(height: Sp.x3),
                    Row(children: [Text(l.deskImpAmount, style: ts.small), EMoney(_tx!.amount)]),
                  ],
                ],
              ),
              actions: [
                EButton.primary(label: l.deskImpAnother, icon: EIcons.fileDown, onPressed: _again),
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
          else
            EDropZone(
              title: l.deskImpChoose,
              text: l.deskImpChooseText,
              buttonLabel: l.deskFinChooseFile,
              onPick: _pick,
            ),
        ],
      ),
    );
  }
}
