import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'file_panels.dart';

/// Argument of the Import route: [done] opens on the saved response file.
class ImportArgs {
  const ImportArgs({this.done = false});

  final bool done;
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
  String? _error;
  Tx? _tx;

  @override
  void initState() {
    super.initState();
    final a = widget.arg;
    if (a is ImportArgs && a.done) _response = 'invoice_0042.response.slate';
  }

  Future<void> _pick() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final tx = await ref.read(deskApiProvider).receiveFile('invoice_0042.slate');
      if (!mounted) return;
      setState(() {
        _tx = tx;
        _response = 'invoice_0042.response.slate';
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'The file could not be read as a transaction file.');
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
    return EPage(
      title: 'Sign a transaction file',
      width: EPageWidth.narrow,
      onBack: () => nav.canBack ? nav.back() : nav.go(DeskRoute.receive),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ENotice(
            title: 'Signing does not spend anything',
            text: 'Send the response file back to the sender over the same channel they used.',
            icon: EIcons.info,
          ),
          const SizedBox(height: Sp.x5),
          if (_error != null) ...[
            ENotice(title: 'File not accepted', text: _error, tone: ETone.risk, icon: EIcons.error),
            const SizedBox(height: Sp.x5),
          ],
          if (_response != null)
            ResultPanel(
              title: 'Response saved',
              text: 'Send the response file back to the sender. The EPIC arrives once the sender finalizes it.',
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FileChip(_response!),
                  if (_tx != null) ...[
                    const SizedBox(height: Sp.x3),
                    Row(children: [Text('Amount ', style: ts.small), EMoney(_tx!.amount)]),
                  ],
                ],
              ),
              actions: [
                EButton.primary(label: 'Sign another file', icon: EIcons.fileDown, onPressed: _again),
                EButton(label: 'View in Activity', onPressed: () => nav.go(DeskRoute.activity, _tx?.id)),
              ],
            )
          else if (_busy)
            EPanel(
              padding: const EdgeInsets.all(Sp.x8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ESpinner(size: 20),
                  const SizedBox(width: Sp.x3),
                  Text('Signing the file', style: ts.bodyDim),
                ],
              ),
            )
          else
            EDropZone(
              title: 'Drop a transaction file here',
              text: 'The wallet signs it and saves a response for the sender.',
              buttonLabel: 'Choose file',
              onPick: _pick,
            ),
        ],
      ),
    );
  }
}
