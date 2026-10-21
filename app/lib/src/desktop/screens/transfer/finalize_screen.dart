import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  wrongType('Not a response file', 'The file is not a response file. Choose the file the recipient sent back.'),
  unreadable('File not readable', 'The file could not be read. It may be damaged or still being copied.'),
  failed('Finalizing failed', 'The wallet could not finalize this file. It may belong to another transaction or be finalized already.'),
  notPosted('Not posted', 'The transaction was finalized but the node did not accept it. Check the node, then try again.');

  const FinalizeError(this.title, this.text);
  final String title;
  final String text;
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
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final tx = await ref.read(deskApiProvider).finalizeFile('invoice_0042.response.slate');
      if (!mounted) return;
      setState(() {
        _txId = tx.id;
        _done = true;
      });
      showEToast(context, 'Transaction posted');
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
    return EPage(
      title: 'Finalize a response file',
      width: EPageWidth.narrow,
      onBack: () => nav.canBack ? nav.back() : nav.go(DeskRoute.receive),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ENotice(
            title: 'For a transaction created as a file',
            text: 'Use the response file the recipient sent back.',
            icon: EIcons.info,
          ),
          SizedBox(height: Sp.x5),
          if (_error != null) ...[
            ENotice(
              title: _error!.title,
              text: _error!.text,
              tone: ETone.risk,
              icon: EIcons.error,
              actions: [if (_error == FinalizeError.notPosted) EButton(label: 'Try again', icon: EIcons.refresh, size: EBtnSize.inline, onPressed: _busy ? null : _pick)],
            ),
            SizedBox(height: Sp.x5),
          ],
          if (_done)
            ResultPanel(
              title: 'Transaction posted',
              text: 'The payment was finalized and sent to the network. Follow it in Activity.',
              actions: [
                EButton.primary(label: 'Finalize another file', icon: EIcons.fileUp, onPressed: () => setState(() => _done = false)),
                EButton(label: 'View in Activity', onPressed: () => nav.go(DeskRoute.activity, _txId)),
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
                  Text('Finalizing and posting', style: ts.bodyDim),
                ],
              ),
            )
          else
            EDropZone(
              title: 'Drop a response file here',
              text: 'The wallet completes the transaction and posts it to the network.',
              buttonLabel: 'Choose file',
              onPick: _pick,
            ),
        ],
      ),
    );
  }
}
