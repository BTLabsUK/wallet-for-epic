import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api.dart';
import '../../widgets/kit.dart';
import 'onboarding_parts.dart';

/// The steps of the import wizard; also the [arg] a tour or a link can start on.
enum ImportStep { find, found, none, choose, check, import, done }

/// The in-use check of one chosen wallet.
enum _Use { checking, free, inUse, unknown, skipped }

const _groupIcons = {
  OldWalletGroup.gui: EIcons.wallet,
  OldWalletGroup.cli: EIcons.node,
  OldWalletGroup.picked: EIcons.folder,
};

String _size(int bytes) {
  final mb = bytes / (1 << 20);
  if (mb >= 1000) return '${(mb / 1024).toStringAsFixed(1)} GB';
  return mb < 1 ? '< 1 MB' : '${mb.round()} MB';
}

String _date(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _message(Object e) => e is DeskError ? e.message : 'Something went wrong';

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
        proof: const [ImportProof('Seed read'), ImportProof('Wallet created'), ImportProof('Old folder unchanged')],
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
    // Nothing in use: straight on to Import.
    if (!_chosen.any((f) => _use[f.id] == _Use.inUse)) setState(() => _step = ImportStep.import);
  }

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
    if (_old.text.isEmpty) return setState(() => _error = 'Enter the old password');
    if (needNew) {
      if (_new.text.length < minPasswordLength) return setState(() => _error = 'New password: at least $minPasswordLength characters');
      if (_new.text != _repeat.text) return setState(() => _error = 'The new passwords differ');
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
        _clearPasswords();
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        if (e is DeskError && e.newPasswordNeeded) _needNew = true;
        _error = _message(e);
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
    try {
      await _api.selectWallet(done.first.id);
    } on Object {
      // Unlock offers the wallet opened last.
    }
    nav.reset(DeskRoute.unlock, UnlockAdded(done.length == 1 ? done.first.name : '${done.length} wallets'));
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
    FolderFind? pick;
    String? note;
    try {
      pick = await _api.pickFolder();
    } on Object catch (e) {
      note = _message(e);
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

  ({String title, String? lead}) get _head => switch (_step) {
    ImportStep.find => (title: 'Finding wallets', lead: 'Searching the folders of older Epic Wallet versions and the epic program. Nothing is changed.'),
    ImportStep.found => (title: '${_found.length} wallet${_found.length == 1 ? '' : 's'} found', lead: 'Old folders are only read.'),
    ImportStep.none => (title: 'No wallets found', lead: 'Choose the wallet folder, or restore from the recovery phrase.'),
    ImportStep.choose => (title: 'Choose wallets', lead: 'Ticked wallets are added to the app. History is rebuilt by a scan.'),
    ImportStep.check => (title: 'Checking for use', lead: 'A wallet in use by another program is not imported.'),
    ImportStep.import => (title: 'Import', lead: 'Each wallet asks for its old password once.'),
    ImportStep.done => (title: 'Wallets imported', lead: 'The first unlock of each wallet scans the chain for its history.'),
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
    final h = _head;
    final chosen = _chosen;
    final todo = _toImport;
    final busyCheck = chosen.any((f) => _use[f.id] == null || _use[f.id] == _Use.checking);
    final pending = chosen.any((f) => _use[f.id] == _Use.inUse);
    final current = _current;
    final (label, enabled, stat) = switch (_step) {
      ImportStep.find => ('Continue', false, null),
      ImportStep.found => ('Continue', true, null),
      ImportStep.none => ('Continue', false, null),
      ImportStep.choose => ('Continue', chosen.isNotEmpty, '${chosen.length} of ${_found.length} selected'),
      ImportStep.check => (
        'Continue',
        !busyCheck && !pending && todo.isNotEmpty,
        busyCheck ? 'Checking…' : (pending ? 'Close the other program or skip the wallet' : null),
      ),
      ImportStep.import => (
        current == null ? 'Continue' : 'Import',
        current != null ? !_busy : _done.isNotEmpty,
        '${_done.length} of ${todo.length} imported',
      ),
      ImportStep.done => ('Open wallet', true, null),
    };
    final canBack = _step == ImportStep.choose || _step == ImportStep.check || (_step == ImportStep.import && _done.isEmpty && !_busy);
    return EOnbFrame(
      sideTitle: 'Import wallets',
      steps: railOf(['Find', 'Choose', 'Check', 'Import', 'Done'], _railIndex),
      title: h.title,
      lead: h.lead,
      sideFoot: _step == ImportStep.done
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: EButton.ghost(label: 'Cancel', icon: EIcons.close, onPressed: _busy ? null : _cancel),
            ),
      actions: [
        if (stat != null) Expanded(child: Text(stat, style: ts.small)) else const SizedBox.shrink(),
        if (canBack) Padding(padding: EdgeInsets.only(right: Sp.x3), child: EButton(label: 'Back', onPressed: _back)),
        EButton.primary(label: label, busy: _busy && _step == ImportStep.import, onPressed: enabled ? _next : null),
      ],
      child: _body(context),
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
              Tooltip(
                message: f.folder,
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
    const rows = [
      ('Older Epic Wallet', EIcons.wallet, 'Accounts and folders'),
      ('The epic program', EIcons.node, '~/.epic'),
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
                  _status(context, null, 'Searching…', spin: true),
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
        label: 'Choose a folder',
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
      _pickButton(),
      SizedBox(height: Sp.x4),
      ELink(label: 'Restore from phrase', onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.restore)),
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
                  Text(g.title, style: ts.label),
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
    final meta = [if (f.lastUsed != null) 'Last used ${_date(f.lastUsed!)}', _size(f.sizeBytes)].join(' · ');
    final notes = [
      if (f.blocked != null) f.blocked!,
      if (f.importable && f.sameAs != null) '${f.sameAs}. Tick for a second copy.',
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
                : Semantics(label: '${f.name}: cannot be imported', child: Icon(EIcons.cancel, size: Ctl.icon, color: c.faint)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!selectable || !f.importable) Text(f.name, style: ts.label),
                Tooltip(
                  message: f.folder,
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
              if (f.network != 'mainnet') ETag('${f.network[0].toUpperCase()}${f.network.substring(1)}'),
              if (f.sameAs != null) ETag(f.inApp ? 'In the app' : 'Same wallet', tone: ETone.warn, icon: EIcons.alert),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkList(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
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
                  null || _Use.checking => _status(context, null, 'Checking…', spin: true),
                  _Use.free => _status(context, EIcons.okCircle, 'Not in use', color: c.ok),
                  _Use.unknown => _status(context, EIcons.info, 'Not checked', color: c.faint),
                  _Use.skipped => _status(context, EIcons.cancel, 'Skipped', color: c.faint),
                  _Use.inUse => _status(context, EIcons.error, 'In use', color: c.risk),
                },
              ),
              if (_use[f.id] == _Use.inUse) ...[
                SizedBox(height: Sp.x3),
                Text('In use by another program. Close the older Epic Wallet or the epic program, then check again.', style: ts.small),
                SizedBox(height: Sp.x3),
                Row(
                  children: [
                    EButton(label: 'Check again', size: EBtnSize.inline, onPressed: () => _checkOne(f.id)),
                    SizedBox(width: Sp.x2),
                    EButton.ghost(label: 'Skip', size: EBtnSize.inline, onPressed: () => setState(() => _use[f.id] = _Use.skipped)),
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
                  Flexible(child: Text(p.text, style: ts.small)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _importList(BuildContext context) {
    final c = context.dc;
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
                    ? _status(context, EIcons.okCircle, 'Imported', color: c.ok)
                    : _skipped.contains(f.id)
                    ? _status(context, EIcons.cancel, 'Skipped', color: c.faint)
                    : f.id == current?.id
                    ? (_busy ? _status(context, null, 'Importing…', spin: true) : const SizedBox.shrink())
                    : _status(context, null, 'Waiting'),
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
    final short = _shortOld;
    return Padding(
      padding: EdgeInsets.only(top: Sp.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EField(
            label: 'Old password',
            help: 'The password of ${f.name} in the older app.',
            error: short ? null : _error,
            child: EPasswordInput(
              key: ValueKey('old-${f.id}'),
              controller: _old,
              autofocus: true,
              invalid: _error != null && !short,
              semanticLabel: 'Old password of ${f.name}',
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _importCurrent(),
            ),
          ),
          if (short) ...[
            SizedBox(height: Sp.x3),
            Text('The old password is short. Choose a new one, $minPasswordLength or more characters.', style: ts.small),
            SizedBox(height: Sp.x3),
            EField(
              label: 'New password',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EPasswordInput(controller: _new, semanticLabel: 'New password', onChanged: (_) => setState(() => _error = null)),
                  SizedBox(height: Sp.x2),
                  PasswordHint(controller: _new),
                ],
              ),
            ),
            SizedBox(height: Sp.x3),
            EField(
              label: 'Repeat',
              error: _error,
              child: EPasswordInput(
                controller: _repeat,
                semanticLabel: 'Repeat the new password',
                invalid: _error != null,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _importCurrent(),
              ),
            ),
          ],
          SizedBox(height: Sp.x3),
          Align(
            alignment: Alignment.centerLeft,
            child: EButton.ghost(label: 'Skip', size: EBtnSize.inline, onPressed: _busy ? null : _skipCurrent),
          ),
        ],
      ),
    );
  }

  Widget _doneList(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
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
                      Text('Imported', style: ts.small),
                    ],
                  ),
                  _proof(context, r),
                ],
              ),
            ),
        ]),
        SizedBox(height: Sp.x4),
        Text('Old folders are unchanged. The older app can still open them.', style: ts.bodyDim),
      ],
    );
  }
}

// ---------------------------------------------------------------- dialogs

/// "Stop the import?" Pops true when the user stops.
Future<bool?> showImportStopDialog(BuildContext context) => showEDialog<bool>(
  context,
  builder: (ctx) => EDialog(
    title: 'Stop the import?',
    description: 'Wallets imported so far are removed. Old folders are unchanged.',
    icon: EIcons.stop,
    tone: ETone.warn,
    width: 420.u,
    actions: [
      EButton(label: 'Go back', onPressed: () => Navigator.pop(ctx, false)),
      EButton(label: 'Stop import', kind: EBtnKind.danger, onPressed: () => Navigator.pop(ctx, true)),
    ],
  ),
);
