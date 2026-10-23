/// Settings › This wallet › Backup (F34): export and import of the history backup, and the
/// payments as CSV, each through its dialog and the system Save or Open dialog.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../log.dart';
import '../../data/files.dart' show deskOpenFolderProvider;
import '../../data/history_files.dart';
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';

/// The open wallet's backup record; read again when the transactions change.
final historyBackupProvider = FutureProvider.autoDispose<HistoryBackupState>((ref) {
  ref.watch(deskProvider.select((s) => s.txs));
  return ref.read(deskApiProvider).historyBackupState();
});

/// Start states of the Backup group for the screenshots.
enum BackupDemo { busy }

final _dayTime = DateFormat('d MMM yyyy, HH:mm');
final _hm = DateFormat('HH:mm');

/// "3 Oct 2026, 14:02", "today, 14:02", "yesterday, 09:10".
String backupWhen(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final days = DateTime(n.year, n.month, n.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  return switch (days) {
    0 => 'today, ${_hm.format(d)}',
    1 => 'yesterday, ${_hm.format(d)}',
    _ => _dayTime.format(d),
  };
}

/// The line under Export history backup.
String backupStateLine(HistoryBackupState s, {DateTime? now}) {
  final last = s.lastExport;
  if (last == null) return 'Never exported.';
  final since = s.unbacked == 0 ? 'nothing new since' : '${s.unbacked} ${s.unbacked == 1 ? 'payment' : 'payments'} since';
  return 'Last export ${backupWhen(last, now: now)} · $since.';
}

/// `epic-history-<network>-<yyyymmdd>.<extension>`, as the phone names it.
String deskHistoryFileName(String network, DateTime day, String extension) =>
    'epic-history-$network-${DateFormat('yyyyMMdd').format(day)}.$extension';

/// Why a save failed, with the folder when the system says which.
String _notSaved(Object e) {
  if (e is FileSystemException) {
    final folder = e.path == null ? 'the folder' : File(e.path!).parent.path;
    return 'Could not write to $folder: ${e.osError?.message ?? e.message}. Choose another folder.';
  }
  if (e is DeskError) return e.message;
  return 'The file could not be written. Choose another folder.';
}

/// The Backup group, between This wallet and Files.
class BackupGroup extends ConsumerStatefulWidget {
  const BackupGroup({super.key, this.demo});

  final BackupDemo? demo;

  @override
  ConsumerState<BackupGroup> createState() => _BackupGroupState();
}

enum _Busy { export, import, csv }

class _BackupGroupState extends ConsumerState<BackupGroup> {
  late _Busy? _busy = widget.demo == BackupDemo.busy ? _Busy.export : null;

  Future<void> _run(_Busy what, Future<void> Function(BuildContext) dialog) async {
    setState(() => _busy = what);
    try {
      await dialog(context);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final state = ref.watch(historyBackupProvider).value;
    final busy = _busy;
    return ESetGroup(
      title: 'Backup',
      rows: [
        ESetRow(
          title: 'Export history backup',
          hint:
              'Payments with their details and contacts, in a file only a wallet with this recovery phrase opens. '
              'The phrase alone brings back the balance, not the records.',
          below: Padding(
            padding: EdgeInsets.only(top: Sp.x1),
            child: Text(state == null ? ' ' : backupStateLine(state), style: ts.caption),
          ),
          control: ERowControl(
            child: EButton(
              label: busy == _Busy.export ? 'Exporting…' : 'Export…',
              icon: EIcons.download,
              size: EBtnSize.sm,
              busy: busy == _Busy.export,
              onPressed: busy != null ? null : () => _run(_Busy.export, showExportHistoryDialog),
            ),
          ),
        ),
        ESetRow(
          title: 'Import history backup',
          hint: 'Merges a backup of this wallet into Activity. Nothing is removed; the same file twice changes nothing.',
          control: ERowControl(
            child: EButton(
              label: 'Import…',
              icon: EIcons.upload,
              size: EBtnSize.sm,
              onPressed: busy != null ? null : () => _run(_Busy.import, showImportHistoryDialog),
            ),
          ),
        ),
        ESetRow(
          title: 'Payments as CSV',
          hint: 'A plain table for spreadsheets. Not encrypted, not importable.',
          control: ERowControl(
            child: EButton(
              label: 'Export CSV…',
              icon: EIcons.table,
              size: EBtnSize.sm,
              onPressed: busy != null ? null : () => _run(_Busy.csv, showExportCsvDialog),
            ),
          ),
        ),
      ],
    );
  }
}

// ---- Shared parts of the three dialogs.

/// Label (104 u, faint) and value rows with lines between, as the design's lists.
class _List extends StatelessWidget {
  const _List(this.rows);

  final List<({String label, Widget value, String? sub})> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final line = BorderSide(color: c.line);
    return Container(
      decoration: BoxDecoration(border: Border(top: line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in rows)
            Container(
              padding: EdgeInsets.symmetric(vertical: 9.u),
              decoration: BoxDecoration(border: Border(bottom: line)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 104.u, child: Text(r.label, style: ts.small.copyWith(color: c.faint))),
                  SizedBox(width: Sp.x4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultTextStyle.merge(style: ts.small.copyWith(color: c.text), child: r.value),
                        if (r.sub != null) ...[SizedBox(height: 2.u), Text(r.sub!, style: ts.caption)],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The ok block of a finished step: a tick, the title, and what was done.
class _Done extends StatelessWidget {
  const _Done(this.title, this.child);

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.all(Sp.x3),
        decoration: BoxDecoration(color: c.okSoft, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.ok.withValues(alpha: 0.35))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle_outline, size: Ctl.icon, color: c.ok),
            SizedBox(width: Sp.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ts.strong),
                  SizedBox(height: 2.u),
                  DefaultTextStyle.merge(style: ts.small, child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _mono(BuildContext context, String text) => Text(text, style: context.ts.mono(size: 13.u, color: context.dc.text));

Widget _plain(BuildContext context, String text) => Padding(padding: EdgeInsets.only(top: Sp.x3), child: Text(text, style: context.ts.small));

Widget _notice(String title, String text) => Padding(
  padding: EdgeInsets.only(bottom: Sp.x3),
  child: ENotice(title: title, text: text, tone: ETone.risk, icon: EIcons.alert),
);

Future<void> _openFolder(WidgetRef ref, String path) => ref.read(deskOpenFolderProvider)(File(path).parent.path);

// ---- Export history backup.

Future<void> showExportHistoryDialog(BuildContext context) => showEDialog<void>(context, builder: (_) => const ExportHistoryDialog());

class ExportHistoryDialog extends ConsumerStatefulWidget {
  const ExportHistoryDialog({super.key, this.savedDemo});

  /// Opens in the saved state at this path (screenshots).
  final String? savedDemo;

  @override
  ConsumerState<ExportHistoryDialog> createState() => _ExportHistoryDialogState();
}

class _ExportHistoryDialogState extends ConsumerState<ExportHistoryDialog> {
  bool _saving = false;
  late String? _saved = widget.savedDemo;
  String? _failed;

  String get _name => deskHistoryFileName(ref.read(historyBackupProvider).value?.network ?? 'mainnet', DateTime.now(), 'wfeh');

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _failed = null;
    });
    try {
      final api = ref.read(deskApiProvider);
      // The bytes first, so a failure shows before the system dialog.
      final bytes = await api.exportHistory();
      final path = await ref.read(deskHistoryFilesProvider).save(name: _name, bytes: bytes, title: 'Save payment history');
      if (path != null) {
        await api.markHistoryExported(DateTime.now());
        ref.invalidate(historyBackupProvider);
      }
      if (mounted) setState(() => _saved = path);
    } on Object catch (e) {
      if (mounted) setState(() => _failed = _notSaved(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(historyBackupProvider).value;
    final saved = _saved;
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_failed != null) _notice('Not saved', _failed!),
        _List([
          (
            label: 'In the file',
            value: Text(s == null ? '…' : '${s.payments} ${s.payments == 1 ? 'payment' : 'payments'}, ${s.contacts} ${s.contacts == 1 ? 'contact' : 'contacts'}'),
            sub: 'Who paid what, fees, notes, slate ids',
          ),
          (label: 'Not in it', value: const Text('Keys, the recovery phrase, the password'), sub: null),
          (label: 'Opens with', value: const Text('This wallet, or one restored from its phrase'), sub: null),
          (label: 'File', value: _mono(context, _name), sub: null),
        ]),
        _plain(context, 'The file holds payments up to now. Export again after new payments.'),
      ],
    );
    return EDialog(
      icon: EIcons.download,
      title: 'Export history backup',
      description: 'A file with this wallet’s payments, their details and contacts. Only a wallet with the same recovery phrase opens it.',
      body: saved != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Done('Saved', _mono(context, saved)),
                _plain(context, 'Keep a copy off this computer too: a USB stick, another drive, or cloud storage. Export again after new payments.'),
              ],
            )
          : list,
      actions: saved != null
          ? [
              EButton(label: 'Open folder', icon: EIcons.folder, size: EBtnSize.sm, onPressed: () => _openFolder(ref, saved)),
              EButton.primary(label: 'Done', size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop()),
            ]
          : [
              EButton(label: 'Cancel', size: EBtnSize.sm, onPressed: _saving ? null : () => Navigator.of(context).pop()),
              EButton.primary(
                label: _saving ? 'Saving…' : (_failed != null ? 'Try again' : 'Save as…'),
                icon: EIcons.download,
                size: EBtnSize.sm,
                busy: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
    );
  }
}

// ---- Import history backup.

Future<void> showImportHistoryDialog(BuildContext context) => showEDialog<void>(context, builder: (_) => const ImportHistoryDialog());

class ImportHistoryDialog extends ConsumerStatefulWidget {
  const ImportHistoryDialog({super.key, this.doneDemo});

  /// Opens with this result (screenshots).
  final ({String name, HistoryImport result})? doneDemo;

  @override
  ConsumerState<ImportHistoryDialog> createState() => _ImportHistoryDialogState();
}

class _ImportHistoryDialogState extends ConsumerState<ImportHistoryDialog> {
  String? _reading;
  late ({String name, HistoryImport result})? _done = widget.doneDemo;
  HistoryFileError? _refused;
  String? _failed;

  Future<void> _choose() async {
    setState(() {
      _refused = null;
      _failed = null;
    });
    try {
      final file = await ref.read(deskHistoryFilesProvider).pick(title: 'Open history backup');
      if (file == null || !mounted) return;
      setState(() => _reading = file.name);
      final result = await ref.read(deskApiProvider).importHistory(file.bytes);
      if (mounted) setState(() => _done = (name: file.name, result: result));
      ref.invalidate(historyBackupProvider);
      // The archive rows now merge into Activity, and contacts may have come. The import is
      // done either way: a failed reload must not read as "Not imported".
      try {
        await ref.read(deskProvider.notifier).refresh();
      } on Object catch (e) {
        logWarn('desk', 'refresh after history import: ${e.runtimeType}');
      }
    } on HistoryFileError catch (e) {
      if (mounted) setState(() => _refused = e);
    } on Object catch (e) {
      if (mounted) setState(() => _failed = deskErrorText(e));
    } finally {
      if (mounted) setState(() => _reading = null);
    }
  }

  Widget _count(BuildContext context, int value, String label, [String? sub]) {
    final c = context.dc;
    final ts = context.ts;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.u, vertical: Sp.x3),
      decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: ts.h3.copyWith(fontSize: 22.u, fontFeatures: const [FontFeature.tabularFigures()])),
          SizedBox(height: 2.u),
          Text(label, style: ts.strong.copyWith(fontSize: 13.u)),
          if (sub != null) Text(sub, style: ts.caption),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final network = ref.watch(historyBackupProvider).value?.network ?? 'mainnet';
    final done = _done;
    final reading = _reading;
    final Widget body;
    final List<Widget> actions;
    if (done != null) {
      final r = done.result;
      final tiles = [
        if (r.merged > 0) _count(context, r.merged, 'Details restored', 'Payments already here got their counterparty, fee or note back'),
        if (r.added > 0) _count(context, r.added, 'Older payments added', 'Not in the list any more; shown as From backup'),
        if (r.contactsAdded > 0) _count(context, r.contactsAdded, 'Contacts added'),
        if (r.skipped > 0) _count(context, r.skipped, 'Already here', 'Unchanged'),
      ];
      body = r.nothingNew
          ? _Done(
              'Nothing new',
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Every record in '),
                    TextSpan(text: done.name, style: ts.mono(size: 13.u, color: context.dc.text)),
                    const TextSpan(text: ' was already here.'),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Done('Imported', _mono(context, done.name)),
                SizedBox(height: Sp.x3),
                LayoutBuilder(
                  builder: (context, box) {
                    final w = (box.maxWidth - Sp.x3) / 2;
                    return Wrap(spacing: Sp.x3, runSpacing: Sp.x3, children: [for (final t in tiles) SizedBox(width: w, child: t)]);
                  },
                ),
              ],
            );
      actions = [EButton.primary(label: 'Done', size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop())];
    } else {
      body = reading != null
          ? Padding(
              padding: EdgeInsets.only(top: 14.u, bottom: 6.u),
              child: Row(
                children: [
                  ESpinner(size: Ctl.iconSm),
                  SizedBox(width: Sp.x3),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Reading '),
                          TextSpan(text: reading, style: ts.mono(size: 13.u)),
                          const TextSpan(text: '…'),
                        ],
                      ),
                      style: ts.small,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_refused != null) _notice(_refused!.problem.title, _refused!.text),
                if (_failed != null) _notice('Not imported', _failed!),
                _List([
                  (label: 'Brings back', value: const Text('Who paid what, fees and notes of payments already here; older payments the list lost; contacts'), sub: null),
                  (label: 'Needs', value: Text('A file from this wallet (the same recovery phrase), on ${toBeginningOfSentenceCase(network)}'), sub: null),
                  (label: 'Never', value: const Text('Removes or changes a payment that is here'), sub: null),
                ]),
              ],
            );
      actions = [
        EButton(label: 'Cancel', size: EBtnSize.sm, onPressed: reading != null ? null : () => Navigator.of(context).pop()),
        EButton.primary(label: 'Choose file…', icon: EIcons.folder, size: EBtnSize.sm, onPressed: reading != null ? null : _choose),
      ];
    }
    return EDialog(
      icon: EIcons.upload,
      title: 'Import history backup',
      description: 'Merges a history backup of this wallet into Activity. Nothing is removed, and the same file twice changes nothing.',
      body: body,
      actions: actions,
    );
  }
}

// ---- Payments as CSV.

Future<void> showExportCsvDialog(BuildContext context) => showEDialog<void>(context, builder: (_) => const ExportCsvDialog());

enum CsvRange { all, thisYear, lastYear, custom }

/// The local days a [range] covers (inclusive), or nulls for no limit. Custom days that do not
/// read as dates give null.
({DateTime? from, DateTime? to})? csvDays(CsvRange range, {required DateTime now, String from = '', String to = ''}) => switch (range) {
  CsvRange.all => (from: null, to: null),
  CsvRange.thisYear => (from: DateTime(now.year), to: DateTime(now.year, 12, 31)),
  CsvRange.lastYear => (from: DateTime(now.year - 1), to: DateTime(now.year - 1, 12, 31)),
  CsvRange.custom => switch ((parseDay(from), parseDay(to))) {
    (final DateTime f, final DateTime t) => (from: f, to: t),
    _ => null,
  },
};

/// `YYYY-MM-DD` as a local day; null when it is not one.
DateTime? parseDay(String text) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text.trim());
  if (m == null) return null;
  final d = DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  return d.month == int.parse(m[2]!) && d.day == int.parse(m[3]!) ? d : null;
}

class ExportCsvDialog extends ConsumerStatefulWidget {
  const ExportCsvDialog({super.key, this.initial = CsvRange.all});

  final CsvRange initial;

  @override
  ConsumerState<ExportCsvDialog> createState() => _ExportCsvDialogState();
}

class _ExportCsvDialogState extends ConsumerState<ExportCsvDialog> {
  final _day = DateFormat('yyyy-MM-dd');
  late CsvRange _range = widget.initial;
  late final _from = TextEditingController(text: _day.format(DateTime(DateTime.now().year)));
  late final _to = TextEditingController(text: _day.format(DateTime.now()));
  bool _saving = false;
  ({String path, int count})? _saved;
  String? _failed;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  ({DateTime? from, DateTime? to})? get _days => csvDays(_range, now: DateTime.now(), from: _from.text, to: _to.text);

  String get _name => deskHistoryFileName(ref.read(historyBackupProvider).value?.network ?? 'mainnet', DateTime.now(), 'csv');

  int _count(List<Tx> txs, ({DateTime? from, DateTime? to}) days) {
    final from = days.from, to = days.to;
    return txs.where((t) {
      if (from != null && t.created.isBefore(from)) return false;
      if (to != null && !t.created.isBefore(DateTime(to.year, to.month, to.day + 1))) return false;
      return true;
    }).length;
  }

  Future<void> _save(int count) async {
    final days = _days;
    if (days == null) return;
    setState(() {
      _saving = true;
      _failed = null;
    });
    try {
      final text = await ref.read(deskApiProvider).exportHistoryCsv(from: days.from, to: days.to);
      final path = await ref.read(deskHistoryFilesProvider).save(name: _name, bytes: utf8.encode(text), title: 'Save payments as CSV');
      if (path != null && mounted) setState(() => _saved = (path: path, count: count));
    } on Object catch (e) {
      if (mounted) setState(() => _failed = _notSaved(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(deskProvider.select((s) => s.txs)) ?? const <Tx>[];
    final saved = _saved;
    if (saved != null) {
      return EDialog(
        icon: EIcons.table,
        title: 'Export CSV',
        description: 'A plain table of this wallet’s payments, for spreadsheets.',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Done('Saved', _mono(context, saved.path)),
            _plain(context, '${saved.count} ${saved.count == 1 ? 'payment' : 'payments'}, newest first. Amounts in EPIC with 8 decimals; dates in UTC.'),
          ],
        ),
        actions: [
          EButton(label: 'Open folder', icon: EIcons.folder, size: EBtnSize.sm, onPressed: () => _openFolder(ref, saved.path)),
          EButton.primary(label: 'Done', size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop()),
        ],
      );
    }
    final days = _days;
    final count = days == null ? null : _count(txs, days);
    final ts = context.ts;
    Widget day(String label, TextEditingController controller) => Expanded(
      child: EField(
        label: label,
        error: parseDay(controller.text) == null ? 'Enter a date as 2026-01-31' : null,
        child: EInput(
          controller: controller,
          hint: 'YYYY-MM-DD',
          mono: true,
          semanticLabel: label,
          invalid: parseDay(controller.text) == null,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')), LengthLimitingTextInputFormatter(10)],
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
    return EDialog(
      icon: EIcons.table,
      title: 'Export CSV',
      description: 'A plain table of this wallet’s payments, for spreadsheets.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_failed != null) _notice('Not saved', _failed!),
          EField(
            label: 'Range',
            // Stretched: the four segments share the dialog's width, so a larger text size
            // never pushes the last one out.
            child: ESegmented<CsvRange>(
              stretch: true,
              segments: const [
                ESegment(CsvRange.all, 'All payments'),
                ESegment(CsvRange.thisYear, 'This year'),
                ESegment(CsvRange.lastYear, 'Last year'),
                ESegment(CsvRange.custom, 'Custom'),
              ],
              value: _range,
              onChanged: (v) => setState(() => _range = v),
            ),
          ),
          if (_range == CsvRange.custom) ...[
            SizedBox(height: Sp.x3),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [day('From', _from), SizedBox(width: Sp.x3), day('To', _to)]),
          ],
          SizedBox(height: Sp.x3),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text:
                      '${count == null ? '–' : '$count ${count == 1 ? 'payment' : 'payments'}'} · columns: date, type, status, amount, fee, '
                      'counterparty, note, slate id, kernel, block height. File ',
                ),
                TextSpan(text: _name, style: ts.mono(size: 13.u, color: context.dc.text)),
                const TextSpan(text: '.'),
              ],
            ),
            style: ts.small,
          ),
          SizedBox(height: Sp.x3),
          const ENotice(
            title: 'Not encrypted.',
            text: 'Anyone with the file reads amounts, dates, addresses and notes. It cannot be imported; the history backup is for that.',
            tone: ETone.warn,
            icon: EIcons.alert,
          ),
        ],
      ),
      actions: [
        EButton(label: 'Cancel', size: EBtnSize.sm, onPressed: _saving ? null : () => Navigator.of(context).pop()),
        EButton.primary(
          label: _saving ? 'Saving…' : (_failed != null ? 'Try again' : 'Save as…'),
          icon: EIcons.table,
          size: EBtnSize.sm,
          busy: _saving,
          onPressed: _saving || count == null ? null : () => _save(count),
        ),
      ],
    );
  }
}

// ---- The reminder on Overview (F33).

/// The history backup reminder for the notice stack on Overview: shown while
/// [HistoryBackupState.reminder] names a count (the F33 rule).
class HistoryReminder extends ConsumerWidget {
  const HistoryReminder({super.key, required this.state});

  final HistoryBackupState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = state.reminder ?? 0;
    final payments = '$n ${n == 1 ? 'payment' : 'payments'}';
    return ENotice(
      tone: ETone.warn,
      icon: EIcons.archive,
      title: state.lastExport == null ? '$payments ${n == 1 ? 'is' : 'are'} not in a history backup.' : '$payments ${n == 1 ? 'is' : 'are'} new or changed since the last history backup.',
      text: 'A restore from the recovery phrase brings back the balance, not who paid what.',
      actions: [
        EButton.ghost(
          label: 'Not now',
          size: EBtnSize.inline,
          onPressed: () async {
            await ref.read(deskApiProvider).dismissHistoryReminder(DateTime.now());
            ref.invalidate(historyBackupProvider);
          },
        ),
        EButton(label: 'Export history backup', icon: EIcons.download, size: EBtnSize.inline, onPressed: () => showExportHistoryDialog(context)),
      ],
    );
  }
}
