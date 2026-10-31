// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gui_contact_import.dart' show ContactImport;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/server_lists.dart' show ServerKind, deskServerListProvider;
import '../../../l10n.dart' show localDay, localDigits;
import '../../desk_l10n.dart';
import '../../data/api.dart';
import '../../widgets/kit.dart';
import 'onboarding_parts.dart';
import '../../../settings_file/host_settings.dart' show hostSettings;

/// The steps of the import wizard; also the [arg] a tour or a link can start on.
enum ImportStep { find, found, none, choose, check, import, done }

/// The in-use check of one chosen wallet.
enum _Use { checking, free, inUse, unknown, skipped }

const _groupIcons = {
  OldWalletGroup.gui: EIcons.wallet,
  OldWalletGroup.cli: EIcons.node,
  OldWalletGroup.picked: EIcons.folder,
};

String _size(AppLocalizations l, int bytes) {
  final mb = bytes / (1 << 20);
  if (mb >= 1000) return '${localDigits(l, (mb / 1024).toStringAsFixed(1))} GB';
  return mb < 1 ? '< 1 MB' : '${mb.round()} MB';
}

/// `21 Sep 2026`; English is written here so a screen pumped without date data still reads.
String _date(AppLocalizations l, DateTime d) {
  if (l.localeName != 'en') return localDay(l, d);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']; // l10n-ok: English only; other languages use localDay
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _message(AppLocalizations l, Object e) => deskErrorText(e, l);

/// Import wallets from older folders: find, choose, check for use, import, done. Old folders
/// are only read: each wallet's wallet.seed opens once with its old password and becomes a new
/// wallet of the app, whose history a scan rebuilds at the first unlock. With an [ImportStep]
/// as arg the screen starts on that step as a still snapshot.
class ImportWalletsScreen extends ConsumerStatefulWidget {
  const ImportWalletsScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<ImportWalletsScreen> createState() => _ImportWalletsScreenState();
}

class _ImportWalletsScreenState extends ConsumerState<ImportWalletsScreen> {
  ImportStep _step = ImportStep.find;
  List<OldWallet> _found = [];
  final Map<String, bool> _sel = {};
  final Map<String, _Use> _use = {};
  final Map<String, ImportedWallet> _done = {};
  final Set<String> _skipped = {};

  /// The wallets that keep the older app's Epicbox server (all of them at first).
  final Map<String, bool> _keepRelay = {};

  final _old = TextEditingController();
  final _new = TextEditingController();
  final _repeat = TextEditingController();
  bool _needNew = false;
  String? _error;
  bool _busy = false;
  bool _picking = false;
  String? _pickNote;

  DeskWalletApi get _api => ref.read(deskApiProvider);

  @override
  void initState() {
    super.initState();
    final a = widget.arg;
    _find(snapshot: a is ImportStep ? a : null);
  }

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _repeat.dispose();
    super.dispose();
  }

  List<OldWallet> get _chosen => _found.where((f) => _sel[f.id] == true).toList();

  /// The chosen wallets the import step takes: not in use, not skipped.
  List<OldWallet> get _toImport => _chosen.where((f) => _use[f.id] == _Use.free || _use[f.id] == _Use.unknown).toList();

  /// The wallet asking for its password now.
  OldWallet? get _current => _toImport.where((f) => !_done.containsKey(f.id) && !_skipped.contains(f.id)).firstOrNull;

  void _add(List<OldWallet> wallets) {
    for (final w in wallets) {
      if (_found.any((f) => f.id == w.id)) continue;
      _found = [..._found, w];
      // Wallets the app holds, other copies and wallets it cannot take start unticked.
      _sel[w.id] = w.importable && w.sameAs == null;
    }
  }

  Future<void> _find({ImportStep? snapshot}) async {
    if (snapshot == ImportStep.find) return;
    List<OldWallet> found;
    try {
      found = snapshot == ImportStep.none ? const [] : await _api.findOldWallets();
    } on Object {
      found = const [];
    }
    if (!mounted) return;
    setState(() {
      _found = [];
      _sel.clear();
      _add(found);
      _step = _found.isEmpty ? ImportStep.none : ImportStep.found;
      if (snapshot != null) _snapshot(snapshot);
    });
  }

  /// A still state of [s] over the found wallets: what the wizard looks like part-way.
  void _snapshot(ImportStep s) {
    _step = s;
    if (s.index < ImportStep.check.index) return;
    // The check shows the epic program's wallet in use: tick every importable one.
    if (s == ImportStep.check) _sel.updateAll((id, v) => v || _found.any((f) => f.id == id && f.importable));
    for (final f in _chosen) {
      _use[f.id] = s == ImportStep.check && f.group == OldWalletGroup.cli ? _Use.inUse : _Use.free;
    }
    final todo = _toImport;
    final upTo = s == ImportStep.import ? 1 : todo.length;
    for (final f in todo.take(upTo)) {
      _done[f.id] = ImportedWallet(
        id: f.id,
        name: f.name,
        oldRelay: f == todo.first ? 'epicbox.example.org' : null, // l10n-ok: a sample host
        appRelay: hostSettings.epicboxUse,
        // The tour's sample proof lines (the real ones come from the wallet service).
        proof: [
          ImportProof.l10n((l) => l.deskErrProofSeedRead),
          ImportProof.l10n((l) => l.deskErrProofWalletCreated),
          ImportProof.l10n((l) => l.deskErrProofHistory(41)),
          ...const ContactImport(added: 12, merged: 2, skipped: 1).proof(),
          ImportProof.l10n((l) => l.deskErrProofFolderUnchanged),
        ],
      );
    }
  }

  Future<void> _check() async {
    final chosen = _chosen;
    setState(() {
      _step = ImportStep.check;
      for (final f in chosen) {
        _use[f.id] = _Use.checking;
      }
    });
    await Future.wait([for (final f in chosen) _checkOne(f.id)]);
    if (!mounted || _step != ImportStep.check) return;
    // Nothing in use: straight on to Import; on Windows, which cannot tell, Check stays to
    // ask for the older app to be closed first.
    if (_closeFirst) return;
    if (!_chosen.any((f) => _use[f.id] == _Use.inUse)) setState(() => _step = ImportStep.import);
  }

  /// Windows gives the in-use check no answer: Check says to close the older app first.
  bool get _closeFirst => defaultTargetPlatform == TargetPlatform.windows && _chosen.any((f) => _use[f.id] == _Use.unknown);

  Future<void> _checkOne(String id) async {
    if (mounted) setState(() => _use[id] = _Use.checking);
    _Use use;
    try {
      use = switch (await _api.checkOldWallet(id)) {
        OldWalletUse.free => _Use.free,
        OldWalletUse.inUse => _Use.inUse,
        OldWalletUse.unknown => _Use.unknown,
      };
    } on Object {
      use = _Use.unknown;
    }
    if (mounted) setState(() => _use[id] = use);
  }

  bool get _shortOld => _needNew || (_old.text.isNotEmpty && _old.text.length < minPasswordLength);

  Future<void> _importCurrent() async {
    final w = _current;
    if (w == null || _busy) return;
    final needNew = _shortOld;
    final l = context.l10n;
    if (_old.text.isEmpty) return setState(() => _error = l.deskOnbImportEnterOld);
    if (needNew) {
      if (_new.text.length < minPasswordLength) return setState(() => _error = l.deskOnbImportNewShort(minPasswordLength));
      if (_new.text != _repeat.text) return setState(() => _error = l.deskOnbImportNewDiffer);
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await _api.importOldWallet(w.id, oldPassword: _old.text, newPassword: needNew ? _new.text : null);
      if (!mounted) return;
      setState(() {
        _done[w.id] = r;
        if (r.oldRelay != null) _keepRelay[w.id] = true;
        _clearPasswords();
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        if (e is DeskError && e.newPasswordNeeded) _needNew = true;
        _error = _message(context.l10n, e);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clearPasswords() {
    _old.clear();
    _new.clear();
    _repeat.clear();
    _needNew = false;
    _error = null;
  }

  /// Keep or Use for [id]'s Epicbox server; the list follows ([DeskWalletApi.keepOldRelay]).
  Future<void> _chooseRelay(String id, bool keep) async {
    if ((_keepRelay[id] ?? true) == keep) return;
    setState(() => _keepRelay[id] = keep);
    try {
      await _api.keepOldRelay(id, keep: keep);
      ref.invalidate(deskServerListProvider(ServerKind.relay));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _keepRelay[id] = !keep);
      showEToast(context, _message(context.l10n, e), tone: ETone.risk);
    }
  }

  void _skipCurrent() {
    final w = _current;
    if (w == null || _busy) return;
    setState(() {
      _skipped.add(w.id);
      _clearPasswords();
    });
  }

  Future<void> _openWallet() async {
    final done = _done.values.toList();
    final nav = ref.read(deskNavProvider.notifier);
    final l = context.l10n;
    final last = done.last;
    try {
      await _api.selectWallet(last.id);
    } on Object {
      // Unlock offers the wallet opened last.
    }
    nav.reset(
      DeskRoute.unlock,
      UnlockAdded(
        done.length == 1 ? last.name : l.deskOnbImportWalletsN(done.length),
        id: last.id,
        notice: l.deskOnbImportDone(done.length),
      ),
    );
  }

  void _next() {
    switch (_step) {
      case ImportStep.found:
        setState(() => _step = ImportStep.choose);
      case ImportStep.choose:
        _check();
      case ImportStep.check:
        setState(() => _step = ImportStep.import);
      case ImportStep.import:
        if (_current != null) {
          _importCurrent();
        } else {
          setState(() => _step = ImportStep.done);
        }
      case ImportStep.done:
        _openWallet();
      default:
    }
  }

  void _back() {
    final prev = switch (_step) {
      ImportStep.choose => ImportStep.found,
      ImportStep.check || ImportStep.import => ImportStep.choose,
      _ => null,
    };
    if (prev == null) return;
    // A typed password belongs to the wallet it was typed for.
    if (_step == ImportStep.import) _clearPasswords();
    setState(() => _step = prev);
  }

  Future<void> _cancel() async {
    final nav = ref.read(deskNavProvider.notifier);
    void leave() => nav.canBack ? nav.back() : nav.reset(DeskRoute.welcome);
    if (_done.isEmpty) return leave();
    final stop = await showImportStopDialog(context);
    if (stop != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _api.cancelImport();
    } on Object {
      // The wallets left are listed; All wallets can delete them.
    }
    if (mounted) leave();
  }

  Future<void> _pickFolder() async {
    setState(() {
      _picking = true;
      _pickNote = null;
    });
    final l = context.l10n;
    FolderFind? pick;
    String? note;
    try {
      pick = await _api.pickFolder();
    } on Object catch (e) {
      note = _message(l, e);
    }
    if (!mounted) return;
    setState(() {
      _picking = false;
      _pickNote = note ?? pick?.message;
      if (pick == null || pick.wallets.isEmpty) return;
      _add(pick.wallets);
      if (_step == ImportStep.none) _step = ImportStep.found;
    });
  }

  ({String title, String? lead}) _head(AppLocalizations l) => switch (_step) {
    ImportStep.find => (title: l.deskOnbImportFindingTitle, lead: l.deskOnbImportFindingLead),
    ImportStep.found => (title: l.deskOnbImportFoundTitle(_found.length), lead: null),
    ImportStep.none => (title: l.deskOnbImportNoneTitle, lead: l.deskOnbImportNoneLead),
    ImportStep.choose => (title: l.deskOnbImportChooseTitle, lead: l.deskOnbImportChooseLead),
    ImportStep.check => (title: l.deskOnbImportCheckTitle, lead: l.deskOnbImportCheckLead),
    ImportStep.import => (title: l.deskOnbImportTitle, lead: l.deskOnbImportLead),
    ImportStep.done => (title: l.deskOnbImportDoneTitle, lead: l.deskOnbImportDoneLead),
  };

  int get _railIndex => switch (_step) {
    ImportStep.find || ImportStep.found || ImportStep.none => 0,
    ImportStep.choose => 1,
    ImportStep.check => 2,
    ImportStep.import => 3,
    ImportStep.done => 4,
  };

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final l = context.l10n;
    final h = _head(l);
    final chosen = _chosen;
    final todo = _toImport;
    final busyCheck = chosen.any((f) => _use[f.id] == null || _use[f.id] == _Use.checking);
    final pending = chosen.any((f) => _use[f.id] == _Use.inUse);
    final current = _current;
    final (label, enabled, stat) = switch (_step) {
      ImportStep.find => (l.commonContinue, false, null),
      ImportStep.found => (l.commonContinue, true, null),
      ImportStep.none => (l.commonContinue, false, null),
      ImportStep.choose => (l.commonContinue, chosen.isNotEmpty, l.deskOnbImportSelected(chosen.length, _found.length)),
      ImportStep.check => (
        l.commonContinue,
        !busyCheck && !pending && todo.isNotEmpty,
        busyCheck ? l.deskOnbImportChecking : (pending ? l.deskOnbImportCloseOther : null),
      ),
      ImportStep.import => (
        current == null ? l.commonContinue : l.deskOnbImportTitle,
        current != null ? !_busy : _done.isNotEmpty,
        l.deskOnbImportImportedOf(_done.length, todo.length),
      ),
      ImportStep.done => (l.deskOnbImportOpen, true, null),
    };
    final canBack = _step == ImportStep.choose || _step == ImportStep.check || (_step == ImportStep.import && _done.isEmpty && !_busy);
    final leaveSafe = _step == ImportStep.find || _step == ImportStep.found || _step == ImportStep.none;
    // Back (mouse, Alt+Left) goes one step back; held once a wallet is imported (Cancel asks).
    return DeskStepBack(
      onBack: canBack ? _back : (leaveSafe && !_busy ? null : () {}),
      child: EOnbFrame(
      sideTitle: l.deskOnbWelcomeImport,
      steps: railOf([l.deskOnbImportStepFind, l.deskOnbImportStepChoose, l.deskOnbImportStepCheck, l.deskOnbImportTitle, l.commonDone], _railIndex),
      title: h.title,
      lead: h.lead,
      sideFoot: _step == ImportStep.done
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: EButton.ghost(label: l.commonCancel, icon: EIcons.close, tabStop: false, onPressed: _busy ? null : _cancel),
            ),
      actions: [
        if (stat != null) Expanded(child: Text(stat, style: ts.small)) else const SizedBox.shrink(),
        if (canBack) Padding(padding: EdgeInsets.only(right: Sp.x3), child: EButton(label: l.deskOnbImportBack, tabStop: false, onPressed: _back)),
        if (_step == ImportStep.import && current != null)
          // Tab: Import, then Skip (Skip sits left of the main button).
          FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FocusTraversalOrder(
                  order: const NumericFocusOrder(2),
                  child: EButton.ghost(label: l.deskOnbImportSkip, size: EBtnSize.inline, onPressed: _busy ? null : _skipCurrent),
                ),
                SizedBox(width: Sp.x3),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: EButton.primary(label: label, busy: _busy, onPressed: enabled ? _next : null),
                ),
              ],
            ),
          )
        else
          EButton.primary(label: label, busy: _busy && _step == ImportStep.import, onPressed: enabled ? _next : null),
      ],
      child: _body(context),
    ),
    );
  }

  Widget _body(BuildContext context) => switch (_step) {
    ImportStep.find => _finding(context),
    ImportStep.found => _foundList(context, selectable: false),
    ImportStep.none => _none(context),
    ImportStep.choose => _foundList(context, selectable: true),
    ImportStep.check => _checkList(context),
    ImportStep.import => _importList(context),
    ImportStep.done => _doneList(context),
  };

  Widget _wlist(BuildContext context, List<Widget> rows) {
    final c = context.dc;
    return Container(
      decoration: BoxDecoration(
        color: c.s1,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(Rad.sm),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.line),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _status(BuildContext context, IconData? icon, String text, {Color? color, bool spin = false}) {
    final ts = context.ts;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (spin) const ESpinner() else if (icon != null) Icon(icon, size: Ctl.iconSm, color: color),
        SizedBox(width: spin ? Sp.x2 : Sp.x1),
        Text(text, style: ts.small),
      ],
    );
  }

  Widget _head2(BuildContext context, OldWallet f, Widget trailing, {String? extra}) {
    final ts = context.ts;
    final c = context.dc;
    return Row(
      children: [
        Icon(EIcons.wallet, size: Ctl.icon, color: c.dim),
        SizedBox(width: Sp.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(extra == null ? f.name : '${f.name} · $extra', style: ts.label),
              ETip.value(
                f.folder,
                mono: true,
                child: Text(f.folder, style: ts.mono(size: Fs.xs, color: c.dim), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        SizedBox(width: Sp.x2),
        trailing,
      ],
    );
  }

  Widget _finding(BuildContext context) {
    final l = context.l10n;
    final rows = [
      (l.deskOnbImportOlder, EIcons.wallet, l.deskOnbImportOlderSub),
      (l.deskOnbImportEpicProgram, EIcons.node, '~/.epic'), // l10n-ok: a path
    ];
    final ts = context.ts;
    final c = context.dc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _wlist(context, [
          for (final r in rows)
            Padding(
              padding: EdgeInsets.all(Sp.x4),
              child: Row(
                children: [
                  Icon(r.$2, size: Ctl.icon, color: c.dim),
                  SizedBox(width: Sp.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(r.$1, style: ts.label), Text(r.$3, style: ts.small)],
                    ),
                  ),
                  _status(context, null, l.deskOnbImportSearching, spin: true),
                ],
              ),
            ),
        ]),
        SizedBox(height: Sp.x4),
        const EProgress(),
      ],
    );
  }

  Widget _pickButton({bool small = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      EButton(
        label: context.l10n.deskOnbWelcomeChooseFolder,
        icon: EIcons.folderOpen,
        size: small ? EBtnSize.sm : EBtnSize.md,
        busy: _picking,
        onPressed: _picking ? null : _pickFolder,
      ),
      if (_pickNote != null)
        Padding(
          padding: EdgeInsets.only(top: Sp.x2),
          child: Builder(builder: (context) => Text(_pickNote!, style: context.ts.small)),
        ),
    ],
  );

  Widget _none(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(context.l10n.deskOnbWelcomeOtherApps, style: context.ts.small),
      SizedBox(height: Sp.x4),
      _pickButton(),
      SizedBox(height: Sp.x4),
      ELink(label: context.l10n.deskOnbImportRestore, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.restore)),
    ],
  );

  Widget _foundList(BuildContext context, {required bool selectable}) {
    final ts = context.ts;
    final c = context.dc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in OldWalletGroup.values)
          if (_found.any((f) => f.group == g)) ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: Sp.x2),
              child: Row(
                children: [
                  Icon(_groupIcons[g], size: Ctl.iconSm, color: c.dim),
                  SizedBox(width: Sp.x2),
                  Text(g.label(context.l10n), style: ts.label),
                ],
              ),
            ),
            _wlist(context, [for (final f in _found.where((f) => f.group == g)) _foundRow(context, f, selectable)]),
            SizedBox(height: Sp.x4),
          ],
        Align(alignment: Alignment.centerLeft, child: _pickButton(small: true)),
      ],
    );
  }

  Widget _foundRow(BuildContext context, OldWallet f, bool selectable) {
    final ts = context.ts;
    final c = context.dc;
    final l = context.l10n;
    final meta = [if (f.lastUsed != null) l.deskOnbImportLastUsed(_date(l, f.lastUsed!)), _size(l, f.sizeBytes)].join(' · ');
    final notes = [
      if (f.blocked != null) f.blocked!,
      if (f.importable && f.sameAs != null) l.deskOnbImportSecondCopy('${f.sameAs}'),
    ];
    return Padding(
      padding: EdgeInsets.all(Sp.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: Sp.x3),
            child: !selectable
                ? Icon(EIcons.wallet, size: Ctl.icon, color: c.dim)
                : f.importable
                ? ECheckbox(value: _sel[f.id] == true, label: f.name, onChanged: (v) => setState(() => _sel[f.id] = v))
                : Semantics(label: l.deskOnbImportCannot(f.name), child: Icon(EIcons.cancel, size: Ctl.icon, color: c.faint)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!selectable || !f.importable) Text(f.name, style: ts.label),
                ETip.value(
                  f.folder,
                  mono: true,
                  child: Text(f.folder, style: ts.mono(size: Fs.xs, color: c.dim), overflow: TextOverflow.ellipsis),
                ),
                if (selectable) Text(meta, style: ts.caption),
                if (selectable)
                  for (final n in notes) Padding(padding: EdgeInsets.only(top: Sp.x1), child: Text(n, style: ts.small)),
              ],
            ),
          ),
          Wrap(
            spacing: Sp.x2,
            children: [
              if (f.network != 'mainnet' && DeskFeatures.testNetworks) EBadge(networkName(f.network)),
              if (f.sameAs != null) EBadge(f.inApp ? l.deskOnbImportInApp : l.deskOnbImportSameWallet, tone: ETone.warn, icon: EIcons.alert),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkList(BuildContext context) {
    final l = context.l10n;
    final list = _checkRows(context);
    if (!_closeFirst) return list;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ENotice(tone: ETone.warn, icon: EIcons.alert, title: l.deskOnbImportCloseFirstWindows),
        SizedBox(height: Sp.x4),
        list,
      ],
    );
  }

  Widget _checkRows(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    final l = context.l10n;
    return _wlist(context, [
      for (final f in _chosen)
        Padding(
          padding: EdgeInsets.all(Sp.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _head2(
                context,
                f,
                switch (_use[f.id]) {
                  null || _Use.checking => _status(context, null, l.deskOnbImportChecking, spin: true),
                  _Use.free => _status(context, EIcons.okCircle, l.deskOnbImportNotInUse, color: c.ok),
                  _Use.unknown => _status(context, EIcons.info, l.deskOnbImportNotChecked, color: c.faint),
                  _Use.skipped => _status(context, EIcons.cancel, l.deskOnbImportSkipped, color: c.faint),
                  _Use.inUse => _status(context, EIcons.error, l.deskOnbImportInUse, color: c.risk),
                },
              ),
              if (_use[f.id] == _Use.inUse) ...[
                SizedBox(height: Sp.x3),
                Text(l.deskOnbImportInUseText, style: ts.small),
                SizedBox(height: Sp.x3),
                Row(
                  children: [
                    EButton(label: l.deskOnbImportCheckAgain, size: EBtnSize.inline, onPressed: () => _checkOne(f.id)),
                    SizedBox(width: Sp.x2),
                    EButton.ghost(label: l.deskOnbImportSkip, size: EBtnSize.inline, onPressed: () => setState(() => _use[f.id] = _Use.skipped)),
                  ],
                ),
              ],
            ],
          ),
        ),
    ]);
  }

  Widget _proof(BuildContext context, ImportedWallet r) {
    final ts = context.ts;
    final c = context.dc;
    return Padding(
      padding: EdgeInsets.only(top: Sp.x3, left: Ctl.icon + Sp.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in r.proof)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  SizedBox(width: 20.u, child: Icon(p.ok ? EIcons.check : EIcons.alert, size: Ctl.iconSm, color: p.ok ? c.ok : c.warn)),
                  Flexible(child: Text(p.line(context.l10n), style: ts.small)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _importList(BuildContext context) {
    final c = context.dc;
    final l = context.l10n;
    final current = _current;
    return _wlist(context, [
      for (final f in _toImport)
        Padding(
          padding: EdgeInsets.all(Sp.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _head2(
                context,
                f,
                _done.containsKey(f.id)
                    ? _status(context, EIcons.okCircle, l.deskOnbImportImported, color: c.ok)
                    : _skipped.contains(f.id)
                    ? _status(context, EIcons.cancel, l.deskOnbImportSkipped, color: c.faint)
                    : f.id == current?.id
                    ? (_busy ? _status(context, null, l.deskOnbImportImporting, spin: true) : const SizedBox.shrink())
                    : _status(context, null, l.deskOnbImportWaiting),
              ),
              if (_done[f.id] != null) _proof(context, _done[f.id]!),
              if (f.id == current?.id) _passwordForm(context, f),
            ],
          ),
        ),
    ]);
  }

  Widget _passwordForm(BuildContext context, OldWallet f) {
    final ts = context.ts;
    final l = context.l10n;
    final short = _shortOld;
    // Enter: Old → New → Repeat, then Import.
    return Padding(
      padding: EdgeInsets.only(top: Sp.x4),
      child: EForm(
        onSubmit: _busy ? null : _importCurrent,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EField(
            label: l.deskOnbImportOldPassword,
            help: l.deskOnbImportOldHelp(f.name),
            error: short ? null : _error,
            child: EPasswordInput(
              key: ValueKey('old-${f.id}'),
              controller: _old,
              autofocus: true,
              invalid: _error != null && !short,
              semanticLabel: l.deskOnbImportOldOf(f.name),
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
          if (short) ...[
            SizedBox(height: Sp.x3),
            Text(l.deskOnbImportOldShort(minPasswordLength), style: ts.small),
            SizedBox(height: Sp.x3),
            EField(
              label: l.deskOnbImportNewPassword,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EPasswordInput(controller: _new, semanticLabel: l.deskOnbImportNewPassword, onChanged: (_) => setState(() => _error = null)),
                  SizedBox(height: Sp.x2),
                  ExcludeFocusTraversal(child: PasswordHint(controller: _new)),
                ],
              ),
            ),
            SizedBox(height: Sp.x3),
            EField(
              label: l.deskOnbImportRepeat,
              error: _error,
              child: EPasswordInput(
                controller: _repeat,
                semanticLabel: l.deskOnbImportRepeatNew,
                invalid: _error != null,
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _doneList(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _wlist(context, [
          for (final r in _done.values)
            Padding(
              padding: EdgeInsets.all(Sp.x4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(EIcons.okCircle, size: Ctl.icon, color: c.ok),
                      SizedBox(width: Sp.x3),
                      Expanded(child: Text(r.name, style: ts.label)),
                      Text(l.deskOnbImportImported, style: ts.small),
                    ],
                  ),
                  _proof(context, r),
                  Padding(
                    padding: EdgeInsets.only(top: Sp.x2, left: Ctl.icon + Sp.x3),
                    child: Text(r.newPassword ? l.deskOnbImportUnlockNew : l.deskOnbImportUnlockOld, style: ts.small),
                  ),
                  if (r.oldRelay != null) _relayChoice(context, r),
                ],
              ),
            ),
        ]),
        SizedBox(height: Sp.x4),
        Text(l.deskOnbImportUnchanged, style: ts.bodyDim),
      ],
    );
  }
}

// ---------------------------------------------------------------- relay choice

extension on _ImportWalletsScreenState {
  /// Keep the older app's Epicbox server (the address stays) or use the app's (it changes).
  Widget _relayChoice(BuildContext context, ImportedWallet r) {
    final ts = context.ts;
    final l = context.l10n;
    final old = r.oldRelay!;
    final keep = _keepRelay[r.id] ?? true;
    return Padding(
      padding: EdgeInsets.only(top: Sp.x4, left: Ctl.icon + Sp.x3),
      child: Semantics(
        container: true,
        label: l.deskOnbImportRelayTitle(r.name),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.deskOnbImportRelayTitle(r.name), style: ts.label),
            SizedBox(height: Sp.x1),
            Text(l.deskOnbImportRelayLead(old), style: ts.small),
            SizedBox(height: Sp.x3),
            EChoiceCard(
              title: l.deskOnbImportRelayKeep(old),
              description: l.deskOnbImportRelayKeepHint,
              selected: keep,
              onTap: () => _chooseRelay(r.id, true),
            ),
            SizedBox(height: Sp.x2),
            EChoiceCard(
              title: l.deskOnbImportRelayApp(r.appRelay),
              description: l.deskOnbImportRelayAppHint,
              selected: !keep,
              onTap: () => _chooseRelay(r.id, false),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- dialogs

/// "Stop the import?" Pops true when the user stops.
Future<bool?> showImportStopDialog(BuildContext context) => showEDialog<bool>(
  context,
  builder: (ctx) => EDialog(
    title: ctx.l10n.deskOnbImportStopTitle,
    description: ctx.l10n.deskOnbImportStopBody,
    icon: EIcons.stop,
    tone: ETone.warn,
    width: 420.u,
    actions: [
      EButton(label: ctx.l10n.deskOnbImportGoBack, onPressed: () => Navigator.pop(ctx, false)),
      EButton(label: ctx.l10n.deskOnbImportStop, kind: EBtnKind.danger, onPressed: () => Navigator.pop(ctx, true)),
    ],
  ),
);
