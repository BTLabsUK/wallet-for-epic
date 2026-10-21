import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../slate_files.dart' show responseFileName;
import '../../data/files.dart';
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
  wrongType('Not a transaction file', 'The file is not a transaction file. Choose the .slate or .tx file the sender gave.'),
  unreadable('File not readable', 'The file could not be read. It may be damaged or still being copied.'),
  noPlace('Nothing signed', 'No place was chosen for the response file, so nothing was signed.'),
  failed('Signing failed', 'The wallet could not sign this file. It may be for another wallet or already used.');

  const ImportError(this.title, this.text);
  final String title;
  final String text;
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
  String? _detail;
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
    final path = files == null ? 'invoice_0042.slate' : await files.pickSlate(title: 'Transaction file');
    if (path == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _detail = null;
    });
    try {
      final tx = await ref.read(deskApiProvider).receiveFile(path);
      if (!mounted) return;
      setState(() {
        _tx = tx;
        _response = files == null ? 'invoice_0042.response.slate' : responseFileName(path);
      });
    } on DeskError catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message == 'File not readable' ? ImportError.unreadable : (e.message == 'Not a transaction file' ? ImportError.wrongType : ImportError.failed);
          _detail = e.message;
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
          SizedBox(height: Sp.x5),
          if (_error != null) ...[
            ENotice(title: _error!.title, text: _error == ImportError.failed && _detail != null ? '${_error!.text} $_detail.' : _error!.text, tone: ETone.risk, icon: EIcons.error),
            SizedBox(height: Sp.x5),
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
                    SizedBox(height: Sp.x3),
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
              padding: EdgeInsets.all(Sp.x8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ESpinner(size: 20.u),
                  SizedBox(width: Sp.x3),
                  Text('Signing the file', style: ts.bodyDim),
                ],
              ),
            )
          else
            EDropZone(
              title: 'Choose a transaction file',
              text: 'The wallet signs it and saves a response for the sender.',
              buttonLabel: 'Choose file',
              onPick: _pick,
            ),
        ],
      ),
    );
  }
}
