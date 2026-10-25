import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/files.dart';
import '../../data/net_mode_view.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'file_panels.dart';

/// Argument of the Finalize route: [done] opens on the posted transaction, [error] on a
/// refused file.
class FinalizeArgs {
  const FinalizeArgs({this.done = false, this.error});

  final bool done;
  final FinalizeError? error;
}

/// Why a response file was not finalized.
enum FinalizeError {
  wrongType,
  unreadable,
  failed,
  notPosted;

  String title(AppLocalizations l) => switch (this) {
    wrongType => l.deskFinWrongType,
    unreadable => l.deskFinUnreadable,
    failed => l.deskFinFailed,
    notPosted => l.deskFinNotPosted,
  };

  String text(AppLocalizations l) => switch (this) {
    wrongType => l.deskFinWrongTypeText,
    unreadable => l.deskFinUnreadableText,
    failed => l.deskFinFailedText,
    notPosted => l.deskFinNotPostedText,
  };
}

class FinalizeScreen extends ConsumerStatefulWidget {
  const FinalizeScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<FinalizeScreen> createState() => _FinalizeScreenState();
}

class _FinalizeScreenState extends ConsumerState<FinalizeScreen> {
  bool _busy = false;
  bool _done = false;
  int _txId = 38;
  FinalizeError? _error;

  @override
  void initState() {
    super.initState();
    final a = widget.arg;
    _done = a is FinalizeArgs && a.done;
    if (a is FinalizeArgs) _error = a.error;
  }

  Future<void> _pick() async {
    final files = ref.read(deskFilesProvider);
    final path = files == null ? 'invoice_0042.response.slate' : await files.pickSlate(title: context.l10n.deskFinPickTitle);
    if (path == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final tx = await ref.read(deskApiProvider).finalizeFile(path);
      if (!mounted) return;
      setState(() {
        _txId = tx.id;
        _done = true;
      });
      showEToast(context, context.l10n.deskFinPosted, tone: ETone.ok);
    } on DeskError catch (e) {
      if (mounted) {
        setState(() => _error = switch (e.message) {
          'File not readable' => FinalizeError.unreadable, // l10n-ok: DeskError.message is the English key
          'Not a transaction file' => FinalizeError.wrongType, // l10n-ok
          'Node not answering' => FinalizeError.notPosted, // l10n-ok
          _ => FinalizeError.failed,
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = FinalizeError.unreadable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final ts = context.ts;
    final l = context.l10n;
    // Offline on a node that is not local: the file still runs, through that node.
    final offlineNode = ref.watch(deskOfflineUsesNodeProvider);
    return EPage(
      title: l.deskFinTitle,
      width: EPageWidth.narrow,
      onBack: () => nav.canBack ? nav.back() : nav.go(DeskRoute.receive),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ENotice(
            title: l.deskFinNoticeTitle,
            text: l.deskFinNoticeText,
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
            ENotice(
              title: _error!.title(l),
              text: _error!.text(l),
              tone: ETone.risk,
              icon: EIcons.error,
              actions: [if (_error == FinalizeError.notPosted) EButton(label: l.deskFinTryAgain, icon: EIcons.refresh, size: EBtnSize.inline, onPressed: _busy ? null : _pick)],
            ),
            SizedBox(height: Sp.x5),
          ],
          if (_done)
            ResultPanel(
              title: l.deskFinPosted,
              text: l.deskFinPostedText,
              actions: [
                EButton.primary(label: l.deskFinAnother, icon: EIcons.fileUp, onPressed: () => setState(() => _done = false)),
                EButton(label: l.deskFinViewActivity, onPressed: () => nav.go(DeskRoute.activity, _txId)),
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
                  Text(l.deskFinBusy, style: ts.bodyDim),
                ],
              ),
            )
          else
            EDropZone(
              title: l.deskFinChoose,
              text: l.deskFinChooseText,
              buttonLabel: l.deskFinChooseFile,
              onPick: _pick,
            ),
        ],
      ),
    );
  }
}
