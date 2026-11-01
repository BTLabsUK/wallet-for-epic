// SPDX-License-Identifier: Apache-2.0
/// Settings › This wallet › Backup: export and import of the history backup, and the
/// payments as CSV, each through its dialog and the system Save or Open dialog.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../desk_l10n.dart';
import '../../../l10n.dart' show localClock, localDay;
import '../../../log.dart';
import 'prefs.dart';
import '../../data/files.dart' show deskOpenFolderProvider;
import '../../data/history_files.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../../history/backup_summary.dart';
import '../../data/backup_settings_desk.dart';
import '../../data/pairing_state.dart' show deskPairingCall;
import '../../widgets/kit.dart';
import '../devices/link_offer.dart';
import 'history_conflicts.dart';

/// The open wallet's backup record; read again when the transactions change.
final historyBackupProvider = FutureProvider.autoDispose<HistoryBackupState>((ref) {
  ref.watch(deskProvider.select((s) => s.txs));
  return ref.read(deskApiProvider).historyBackupState();
});

/// Start states of the Backup group for the screenshots.
enum BackupDemo { busy }

// English reads the formats without locale data (widget tests pump screens on their own).
String _clock(AppLocalizations l, DateTime d) => l.localeName == 'en' ? DateFormat('HH:mm').format(d) : localClock(l, d);

String _dayOf(AppLocalizations l, DateTime d) => l.localeName == 'en' ? DateFormat('d MMM yyyy').format(d) : localDay(l, d);

/// "3 Oct 2026, 14:02", "today, 14:02", "yesterday, 09:10".
String backupWhen(AppLocalizations l, DateTime d, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final days = DateTime(n.year, n.month, n.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  return switch (days) {
    0 => l.deskSetBackupWhenToday(_clock(l, d)),
    1 => l.deskSetBackupWhenYesterday(_clock(l, d)),
    _ => l.deskSetBackupWhenDate(_dayOf(l, d), _clock(l, d)),
  };
}

/// The line under Export wallet data.
String backupStateLine(AppLocalizations l, HistoryBackupState s, {DateTime? now}) {
  final last = s.lastExport;
  if (last == null) return l.deskSetBackupNeverExported;
  final when = backupWhen(l, last, now: now);
  return s.unbacked == 0 ? l.deskSetBackupLastExportNothingNew(when) : l.deskSetBackupLastExportSince(when, s.unbacked);
}

/// The wallet's name as a file name part: lower case, only ASCII letters and digits kept,
/// anything else (spaces, accents, symbols) a `-`, runs of `-` collapsed, trimmed, at most 12
/// characters, cut after a whole word where it has to be cut. "Main wallet" gives `main-wallet`,
/// "Savings account" gives `savings`, "Épargne" gives `pargne`; a name with no ASCII letter or
/// digit (Thai, Chinese) gives an empty string, and the file name leaves the part out.
String deskWalletFileLabel(String name) {
  final dashed = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  if (dashed.length <= 12) return dashed;
  final cut = dashed.substring(0, 12);
  // A word cut in the middle goes, unless it is the only one.
  final end = dashed[12] == '-' ? 12 : cut.lastIndexOf('-');
  return end > 0 ? cut.substring(0, end) : cut;
}

/// `epic-wallet-data-<wallet>-<yyyymmdd>.<extension>`: the phone's name with the open
/// wallet's name ([deskWalletFileLabel]) after `data`, left out when [wallet] cleans to nothing.
String deskHistoryFileName(String network, DateTime day, String extension, {String wallet = ''}) {
  final label = deskWalletFileLabel(wallet);
  // Mainnet, the only network a user sees, is never named; a dev chain is.
  final tag = network.isEmpty || network == 'mainnet' ? '' : '$network-';
  return 'epic-wallet-data-${label.isEmpty ? '' : '$label-'}$tag${DateFormat('yyyyMMdd').format(day)}.$extension';
}

/// `epic-payments-<wallet>-<yyyymmdd>.csv`: the name offered for a new payments export.
String deskPaymentsFileName(String network, DateTime day, {String wallet = ''}) {
  final label = deskWalletFileLabel(wallet);
  final tag = network.isEmpty || network == 'mainnet' ? '' : '$network-';
  return 'epic-payments-${label.isEmpty ? '' : '$label-'}$tag${DateFormat('yyyyMMdd').format(day)}.csv';
}

/// The open wallet's name as the app shows it (the title bar's rule).
String _openWalletName(WidgetRef ref) {
  final account = ref.read(deskProvider).account;
  final label = ref.read(settingsPrefsProvider).walletLabel;
  return account?.id != null || (label ?? '').isEmpty ? (account?.name ?? '') : label!;
}

/// Why a save failed, with the folder when the system says which.
String _notSaved(AppLocalizations l, Object e) {
  if (e is FileSystemException) {
    final reason = e.osError?.message ?? e.message;
    return e.path == null ? l.deskSetBackupWriteFailedHere(reason) : l.deskSetBackupWriteFailedIn(File(e.path!).parent.path, reason);
  }
  if (e is DeskError) return deskErrorText(e, l);
  return l.deskSetBackupWriteFailed;
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

  void _idle() {
    if (mounted) setState(() => _busy = null);
  }

  Future<void> _run(_Busy what, Future<void> Function(BuildContext, VoidCallback) dialog) async {
    setState(() => _busy = what);
    try {
      await dialog(context, _idle);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final l = context.l10n;
    final state = ref.watch(historyBackupProvider).value;
    final busy = _busy;
    return ESetGroup(
      title: l.deskSetBackupGroup,
      rows: [
        ESetRow(
          title: l.deskSetBackupExportTitle,
          hint: l.deskSetBackupExportHint,
          below: Padding(
            padding: EdgeInsets.only(top: Sp.x1),
            child: Text(state == null ? ' ' : backupStateLine(l, state), style: ts.caption),
          ),
          control: ERowControl(
            child: EButton(
              label: busy == _Busy.export ? l.deskSetBackupExporting : l.deskSetBackupExportButton,
              icon: EIcons.download,
              size: EBtnSize.sm,
              busy: busy == _Busy.export,
              onPressed: busy != null ? null : () => _run(_Busy.export, (c, done) => showExportHistoryDialog(c, onSaved: done)),
            ),
          ),
        ),
        ESetRow(
          title: l.deskSetBackupImportTitle,
          hint: l.deskSetBackupImportHint,
          control: ERowControl(
            child: EButton(
              label: l.deskSetBackupImportButton,
              icon: EIcons.upload,
              size: EBtnSize.sm,
              onPressed: busy != null ? null : () => _run(_Busy.import, (c, _) => showImportHistoryDialog(c)),
            ),
          ),
        ),
        ESetRow(
          title: l.deskSetBackupCsvDialogTitle,
          hint: l.deskSetBackupCsvHint,
          control: ERowControl(
            child: EButton(
              label: l.deskSetBackupExportButton,
              icon: EIcons.table,
              size: EBtnSize.sm,
              onPressed: busy != null ? null : () => _run(_Busy.csv, (c, done) => showExportCsvDialog(c, onSaved: done)),
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

/// Marks where a file name goes in a sentence the translation owns.
const _slot = '\u0000';

/// [text] with [_slot] replaced by [name] in [nameStyle]: a sentence around a file name.
Widget _withName(String text, String name, TextStyle nameStyle, {TextStyle? style}) {
  final i = text.indexOf(_slot);
  return Text.rich(
    TextSpan(children: [TextSpan(text: text.substring(0, i)), TextSpan(text: name, style: nameStyle), TextSpan(text: text.substring(i + 1))]),
    style: style,
  );
}

Widget _mono(BuildContext context, String text) => Text(text, style: context.ts.mono(size: 13.u, color: context.dc.text));

Widget _plain(BuildContext context, String text) => Padding(padding: EdgeInsets.only(top: Sp.x3), child: Text(text, style: context.ts.small));

Widget _notice(String title, String text) => Padding(
  padding: EdgeInsets.only(bottom: Sp.x3),
  child: ENotice(title: title, text: text, tone: ETone.risk, icon: EIcons.alert),
);

Future<void> _openFolder(WidgetRef ref, String path) => ref.read(deskOpenFolderProvider)(File(path).parent.path);

// ---- Export wallet data.

/// [onSaved] runs as soon as the save has finished, while the Saved dialog is still open.
Future<void> showExportHistoryDialog(BuildContext context, {VoidCallback? onSaved}) => showEDialog<void>(context, builder: (_) => ExportHistoryDialog(onSaved: onSaved));

class ExportHistoryDialog extends ConsumerStatefulWidget {
  const ExportHistoryDialog({super.key, this.savedDemo, this.onSaved});

  final VoidCallback? onSaved;

  /// Opens in the saved state at this path (screenshots).
  final String? savedDemo;

  @override
  ConsumerState<ExportHistoryDialog> createState() => _ExportHistoryDialogState();
}

class _ExportHistoryDialogState extends ConsumerState<ExportHistoryDialog> {
  bool _saving = false;
  late String? _saved = widget.savedDemo;
  String? _failed;

  String get _name => deskHistoryFileName(ref.read(historyBackupProvider).value?.network ?? 'mainnet', DateTime.now(), 'wfeh', wallet: _openWalletName(ref));

  Future<void> _save() async {
    final l = context.l10n;
    setState(() {
      _saving = true;
      _failed = null;
    });
    try {
      final api = ref.read(deskApiProvider);
      // The bytes first, so a failure shows before the system dialog.
      final bytes = await api.exportHistory();
      final path = await ref.read(deskHistoryFilesProvider).save(name: _name, bytes: bytes, title: l.deskSetBackupSaveDialogTitle);
      if (path != null) {
        await api.markHistoryExported(DateTime.now());
        ref.invalidate(historyBackupProvider);
      }
      if (mounted) setState(() => _saved = path);
    } on Object catch (e) {
      if (mounted) setState(() => _failed = _notSaved(l, e));
    } finally {
      if (mounted) setState(() => _saving = false);
      widget.onSaved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(historyBackupProvider).value;
    final saved = _saved;
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_failed != null) _notice(l.deskSetBackupNotSaved, _failed!),
        _List([
          (
            label: l.deskSetBackupInFile,
            value: Text(s == null ? '…' : l.deskSetBackupInFileCounts(s.payments, s.contacts)),
            sub: l.deskSetBackupInFileSub,
          ),
          (label: l.deskSetBackupNotIn, value: Text(l.deskSetBackupNotInValue), sub: null),
          (label: l.deskSetBackupOpensWith, value: Text(l.deskSetBackupOpensWithValue), sub: null),
          (label: l.deskSetBackupFile, value: _mono(context, _name), sub: null),
        ]),
        _plain(context, l.deskSetBackupFileNote),
      ],
    );
    return EDialog(
      icon: EIcons.download,
      title: l.deskSetBackupExportTitle,
      description: l.deskSetBackupExportDesc,
      body: saved != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Done(l.deskSetBackupSaved, _mono(context, saved)),
                _plain(context, l.deskSetBackupKeepCopy),
              ],
            )
          : list,
      actions: saved != null
          ? [
              EButton(label: l.deskSetBackupOpenFolder, icon: EIcons.folder, onPressed: () => _openFolder(ref, saved)),
              EButton(label: l.commonDone, onPressed: () => Navigator.of(context).pop()),
            ]
          : [
              EButton(label: l.commonCancel, onPressed: _saving ? null : () => Navigator.of(context).pop()),
              EButton.primary(
                label: _saving ? l.deskSetBackupSaving : (_failed != null ? l.deskSetBackupTryAgain : l.deskSetBackupSaveAs),
                icon: EIcons.download,
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
  final ({String name, HistoryImport result, int settings, bool walletName})? doneDemo;

  @override
  ConsumerState<ImportHistoryDialog> createState() => _ImportHistoryDialogState();
}

class _ImportHistoryDialogState extends ConsumerState<ImportHistoryDialog> {
  String? _reading;
  late ({String name, HistoryImport result, int settings, bool walletName})? _done = widget.doneDemo;
  HistoryFileError? _refused;
  String? _failed;

  Future<void> _choose() async {
    setState(() {
      _refused = null;
      _failed = null;
    });
    try {
      final file = await ref.read(deskHistoryFilesProvider).pick(title: context.l10n.deskSetBackupOpenDialogTitle);
      if (file == null || !mounted) return;
      setState(() => _reading = file.name);
      final api = ref.read(deskApiProvider);
      var result = await api.importHistory(file.bytes);
      if (!result.applied) {
        // The file disagrees with what was typed here: nothing is written until the user chose.
        if (!mounted) return;
        final choices = await showHistoryConflicts(context, result.conflicts);
        if (choices == null || !mounted) return;
        result = await api.importHistory(file.bytes, useBackup: choices);
      }
      // The settings and the wallet's name: those still as the app came are taken; any the user
      // changed here that the file has otherwise ask once for all. The server lists, shared by
      // the other wallets here, ask on their own.
      var settings = 0;
      var named = false;
      if (mounted) {
        final plan = await planDeskBackupSettings(ref, result);
        if (!mounted) return;
        var takeServers = false;
        if (plan.asksServers) {
          final l = context.l10n;
          takeServers = await showEDialog<bool>(
                context,
                builder: (ctx) => EDialog(
                  title: l.deskSetBackupServersTitle,
                  description: l.deskSetBackupServersBody,
                  icon: EIcons.settings,
                  actions: [
                    EButton(label: l.deskSetBackupServersKeep, onPressed: () => Navigator.pop(ctx, false)),
                    EButton.primary(label: l.deskSetBackupServersUse, onPressed: () => Navigator.pop(ctx, true)),
                  ],
                ),
              ) ==
              true;
          if (!mounted) return;
        }
        var take = false;
        if (plan.conflicts.isNotEmpty) {
          final l = context.l10n;
          take = await showEDialog<bool>(
                context,
                builder: (ctx) => EDialog(
                  title: l.backupSettingsTitle,
                  description: l.backupSettingsBody(plan.conflicts.length),
                  icon: EIcons.settings,
                  actions: [
                    EButton(label: l.backupSettingsKeepMine, onPressed: () => Navigator.pop(ctx, false)),
                    EButton.primary(label: l.backupSettingsUseBackup, onPressed: () => Navigator.pop(ctx, true)),
                  ],
                ),
              ) ==
              true;
          if (!mounted) return;
        }
        named = plan.values(takeConflicts: take).containsKey(BackupItem.walletName);
        final changed = await applyDeskBackupSettings(ref, plan, takeConflicts: take, takeServers: takeServers);
        settings = named ? changed - 1 : changed;
      }
      if (mounted) setState(() => _done = (name: file.name, result: result, settings: settings, walletName: named));
      ref.invalidate(historyBackupProvider);
      // Pairings used on another device wait until the user takes them over here (RFC 9.5).
      if (result.pairingsOtherDevice > 0 && mounted) {
        final l = context.l10n;
        final use = await showEDialog<bool>(
          context,
          builder: (ctx) => EDialog(
            title: l.restoreUseContactsTitle,
            description: l.restoreUseContactsBody(result.pairingsOtherDevice),
            icon: EIcons.trusted,
            actions: [
              EButton(label: l.pairNotNow, onPressed: () => Navigator.pop(ctx, false)),
              EButton.primary(label: l.restoreUseHere, onPressed: () => Navigator.pop(ctx, true)),
            ],
          ),
        );
        if (use == true) await deskPairingCall(ref, (api) => api.useImportedPairings());
      }
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
      if (mounted) setState(() => _failed = deskErrorText(e, context.l10n));
    } finally {
      if (mounted) setState(() => _reading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final l = context.l10n;
    final done = _done;
    final reading = _reading;
    final Widget body;
    final List<Widget> actions;
    if (done != null) {
      final r = done.result;
      // One summary of what came back, as on the phone.
      final summary = backupRestoredText(
        l,
        payments: r.merged + r.added,
        notes: r.notesAdded,
        labels: r.labelsAdded,
        contacts: r.contactsAdded,
        stars: r.starsAdded,
        pairings: r.pairingsAdded,
        invoices: r.invoicesAdded,
        settings: done.settings > 0,
        walletName: done.walletName,
        alreadyHere: r.skipped,
      );
      body = r.nothingNew && done.settings == 0 && !done.walletName
          ? _Done(
              l.deskSetBackupNothingNew,
              _withName(l.deskSetBackupNothingNewBody(_slot), done.name, ts.mono(size: 13.u, color: context.dc.text)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Done(l.deskSetBackupImported, _mono(context, done.name)),
                SizedBox(height: Sp.x3),
                Text(summary, style: ts.body),
                if (r.replaced > 0) ...[SizedBox(height: Sp.x3), Text(l.deskHistImportedReplaced(r.replaced), style: ts.small)],
              ],
            );
      actions = [EButton(label: l.commonDone, onPressed: () => Navigator.of(context).pop())];
    } else {
      body = reading != null
          ? Padding(
              padding: EdgeInsets.only(top: 14.u, bottom: 6.u),
              child: Row(
                children: [
                  ESpinner(size: Ctl.iconSm),
                  SizedBox(width: Sp.x3),
                  Expanded(
                    child: _withName(l.deskSetBackupReading(_slot), reading, ts.mono(size: 13.u), style: ts.small),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_refused != null) _notice(_refused!.problem.label(l), _refused!.shown(l)),
                if (_failed != null) _notice(l.deskSetBackupNotImported, _failed!),
                _List([
                  (label: l.deskSetBackupBringsBack, value: Text(l.deskSetBackupBringsBackValue), sub: null),
                  (label: l.deskSetBackupNeeds, value: Text(l.deskSetBackupNeedsValue), sub: null),
                ]),
              ],
            );
      actions = [
        EButton(label: l.commonCancel, onPressed: reading != null ? null : () => Navigator.of(context).pop()),
        EButton.primary(label: l.deskSetBackupChooseFile, icon: EIcons.folder, onPressed: reading != null ? null : _choose),
      ];
    }
    return EDialog(
      icon: EIcons.upload,
      title: l.deskSetBackupImportTitle,
      description: l.deskSetBackupImportDesc,
      body: body,
      actions: actions,
    );
  }
}

// ---- Payments as CSV.

Future<void> showExportCsvDialog(BuildContext context, {VoidCallback? onSaved}) => showEDialog<void>(context, builder: (_) => ExportCsvDialog(onSaved: onSaved));

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
  const ExportCsvDialog({super.key, this.initial = CsvRange.all, this.onSaved});

  final VoidCallback? onSaved;

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

  String get _name => deskPaymentsFileName(ref.read(historyBackupProvider).value?.network ?? 'mainnet', DateTime.now(), wallet: _openWalletName(ref));

  int _count(List<Tx> txs, ({DateTime? from, DateTime? to}) days) {
    final from = days.from, to = days.to;
    return txs.where((t) {
      if (from != null && t.created.isBefore(from)) return false;
      if (to != null && !t.created.isBefore(DateTime(to.year, to.month, to.day + 1))) return false;
      return true;
    }).length;
  }

  Future<void> _save(int count) async {
    final l = context.l10n;
    final days = _days;
    if (days == null) return;
    setState(() {
      _saving = true;
      _failed = null;
    });
    try {
      final text = await ref.read(deskApiProvider).exportHistoryCsv(from: days.from, to: days.to);
      final path = await ref.read(deskHistoryFilesProvider).save(name: _name, bytes: utf8.encode(text), title: l.deskSetBackupSaveCsvDialogTitle);
      if (path != null && mounted) setState(() => _saved = (path: path, count: count));
    } on Object catch (e) {
      if (mounted) setState(() => _failed = _notSaved(l, e));
    } finally {
      if (mounted) setState(() => _saving = false);
      widget.onSaved?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final txs = ref.watch(deskProvider.select((s) => s.txs)) ?? const <Tx>[];
    final saved = _saved;
    if (saved != null) {
      return EDialog(
        icon: EIcons.table,
        title: l.deskSetBackupCsvDialogTitle,
        description: l.deskSetBackupCsvDialogDesc,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Done(l.deskSetBackupSaved, _mono(context, saved.path)),
            _plain(context, l.deskSetBackupCsvSavedNote(saved.count)),
          ],
        ),
        actions: [
          EButton(label: l.deskSetBackupOpenFolder, icon: EIcons.folder, onPressed: () => _openFolder(ref, saved.path)),
          EButton(label: l.commonDone, onPressed: () => Navigator.of(context).pop()),
        ],
      );
    }
    final days = _days;
    final count = days == null ? null : _count(txs, days);
    final ts = context.ts;
    Widget day(String label, TextEditingController controller) => Expanded(
      child: EField(
        label: label,
        error: parseDay(controller.text) == null ? l.deskSetBackupDateError : null,
        child: EInput(
          controller: controller,
          hint: l.deskSetBackupDateHint,
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
      title: l.deskSetBackupCsvDialogTitle,
      description: l.deskSetBackupCsvDialogDesc,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_failed != null) _notice(l.deskSetBackupNotSaved, _failed!),
          EField(
            label: l.deskSetBackupRange,
            // Stretched: the four segments share the dialog's width, so a larger text size
            // never pushes the last one out.
            child: ESegmented<CsvRange>(
              stretch: true,
              segments: [
                ESegment(CsvRange.all, l.deskSetBackupRangeAll),
                ESegment(CsvRange.thisYear, l.deskSetBackupRangeThisYear),
                ESegment(CsvRange.lastYear, l.deskSetBackupRangeLastYear),
                ESegment(CsvRange.custom, l.deskSetBackupRangeCustom),
              ],
              value: _range,
              onChanged: (v) => setState(() => _range = v),
            ),
          ),
          if (_range == CsvRange.custom) ...[
            SizedBox(height: Sp.x3),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [day(l.deskSetBackupFrom, _from), SizedBox(width: Sp.x3), day(l.deskSetBackupTo, _to)]),
          ],
          SizedBox(height: Sp.x3),
          _withName(
            count == null ? l.deskSetBackupCsvInfoNoCount(_slot) : l.deskSetBackupCsvInfo(count, _slot),
            _name,
            ts.mono(size: 13.u, color: context.dc.text),
            style: ts.small,
          ),
          SizedBox(height: Sp.x3),
          ENotice(
            title: l.deskSetBackupNotEncrypted,
            text: l.deskSetBackupNotEncryptedBody,
            tone: ETone.warn,
            icon: EIcons.alert,
          ),
        ],
      ),
      actions: [
        EButton(label: l.commonCancel, onPressed: _saving ? null : () => Navigator.of(context).pop()),
        EButton.primary(
          label: _saving ? l.deskSetBackupSaving : (_failed != null ? l.deskSetBackupTryAgain : l.deskSetBackupSaveAs),
          icon: EIcons.table,
          busy: _saving,
          onPressed: _saving || count == null ? null : () => _save(count),
        ),
      ],
    );
  }
}

// ---- The import offer of a restored wallet .

/// A wallet restored from its phrase (or rebuilt from a damaged database) has its funds back but
/// not who was paid, fees or notes: Overview asks once, at the first unlock, whether to import a
/// history backup. Asked is answered: Not now leaves it to Settings › This wallet › Backup.
Future<void> showHistoryImportOffer(BuildContext context, WidgetRef ref) async {
  await ref.read(deskApiProvider).dismissHistoryImportOffer();
  ref.invalidate(historyBackupProvider);
  if (!context.mounted) return;
  final import = await showEDialog<bool>(context, builder: (_) => const HistoryImportOfferDialog()) ?? false;
  if (import && context.mounted) await showImportHistoryDialog(context);
}

class HistoryImportOfferDialog extends StatelessWidget {
  const HistoryImportOfferDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EDialog(
      key: const ValueKey('history-import-offer'),
      title: l.deskOvRestoredImportTitle,
      description: l.deskOvRestoredImportBody,
      icon: EIcons.archive,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.deskOvRestoredImportLater, style: context.ts.small),
          // Using this wallet on another device too: the one quiet offer to link them.
          DeskLinkOffer(text: l.offerLinkRestore, inDialog: true),
        ],
      ),
      actions: [
        EButton(label: l.deskSetBackupNotNow, onPressed: () => Navigator.pop(context, false)),
        EButton.primary(label: l.deskOvRestoredImportButton, icon: EIcons.upload, onPressed: () => Navigator.pop(context, true)),
      ],
    );
  }
}

// ---- The reminder on Overview.

/// The history backup reminder for the notice stack on Overview: shown while
/// [HistoryBackupState.reminder] names a count (the backup reminder rule).
class HistoryReminder extends ConsumerWidget {
  const HistoryReminder({super.key, required this.state});

  final HistoryBackupState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final n = state.reminder ?? 0;
    // A narrow window puts the two buttons under the text instead of past the edge.
    return LayoutBuilder(builder: (context, box) => ENotice(
      tone: ETone.warn,
      icon: EIcons.archive,
      title: state.lastExport == null ? l.deskSetBackupReminderNever(n) : l.deskSetBackupReminderChanged(n),
      text: l.deskSetBackupReminderBody,
      actionsBelow: box.maxWidth < 640.u,
      actions: [
        EButton.ghost(
          label: l.deskSetBackupNotNow,
          size: EBtnSize.inline,
          onPressed: () async {
            await ref.read(deskApiProvider).dismissHistoryReminder(DateTime.now());
            ref.invalidate(historyBackupProvider);
          },
        ),
        EButton(label: l.deskSetBackupExportTitle, icon: EIcons.download, size: EBtnSize.inline, onPressed: () => showExportHistoryDialog(context)),
      ],
    ));
  }
}
