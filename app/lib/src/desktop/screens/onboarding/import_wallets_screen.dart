import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'onboarding_parts.dart';

/// The steps of the import wizard; also the [arg] a tour or a link can start on.
enum ImportStep { find, found, none, choose, check, copy, settings, done }

class _Old {
  const _Old(this.id, this.label, this.group, this.dir, this.used, this.contacts, this.size, this.seed,
      {this.floonet = false, this.legacyDb = false, this.chain});

  final String id, label, group, dir, used, seed;
  final int contacts, size;
  final bool floonet, legacyDb;
  final int? chain;
}

const _groups = {
  'old': ('Older Epic Wallet', EIcons.wallet),
  'cli': ('The epic program', EIcons.node),
  'picked': ('Chosen folders', EIcons.folder),
};

const _olds = [
  _Old('sav', 'Savings', 'old', '~/EpicWallet-old/Savings', '12 Sep 2026', 14, 38, 'A', legacyDb: true),
  _Old('eve', 'Everyday', 'old', '~/EpicWallet-old/Everyday', '2 Oct 2026', 9, 112, 'B'),
  _Old('tst', 'Testing', 'old', '~/EpicWallet-old/Testing', '30 Sep 2026', 0, 3, 'C', floonet: true),
  _Old('cli', 'Wallet (epic program)', 'cli', '~/.epic/main', '28 Aug 2026', 0, 21, 'D', chain: 8100),
];

String _size(int mb) => mb >= 1000 ? '${(mb / 1000).toStringAsFixed(1)} GB' : '$mb MB';

enum _Lock { checking, free, locked, skipped }

enum _Cp { wait, run, ok, fail, skip }

class _Copy {
  _Copy(this.st, [this.phase = 0, this.pct = 0]);
  _Cp st;
  int phase;
  double pct;
}

const _copyPhases = ['Old folder read', 'Copied to a temporary folder', 'Copy checked file by file', 'Old folder unchanged'];

/// Import wallets from older folders: find, choose, check for use, copy, settings, done.
/// With an [ImportStep] as arg the screen starts on that step as a still snapshot (no timers
/// until the user moves on).
class ImportWalletsScreen extends ConsumerStatefulWidget {
  const ImportWalletsScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<ImportWalletsScreen> createState() => _ImportWalletsScreenState();
}

class _ImportWalletsScreenState extends ConsumerState<ImportWalletsScreen> {
  ImportStep _step = ImportStep.find;
  int _scan = 0;
  List<_Old> _found = [];
  final Map<String, bool> _sel = {};
  final Map<String, _Lock> _lock = {};
  final Map<String, _Copy> _copy = {};
  final Map<String, bool> _set = {'contacts': true, 'node': true, 'epicbox': true, 'lang': true, 'chain': false};
  bool _applying = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final a = widget.arg;
    if (a is ImportStep) {
      _snapshot(a);
    } else {
      _enter(ImportStep.find);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<_Old> get _chosen => _found.where((f) => _sel[f.id] == true).toList();
  List<_Old> get _free => _chosen.where((f) => _lock[f.id] == _Lock.free).toList();

  String? _same(_Old f) {
    final i = _found.indexOf(f);
    for (final o in _found.take(i)) {
      if (o.seed == f.seed) return o.label;
    }
    return null;
  }

  /// A still state of [s]: what the wizard looks like part-way, set without timers.
  void _snapshot(ImportStep s) {
    _step = s;
    _found = s == ImportStep.none || s == ImportStep.find ? [] : List.of(_olds);
    if (s == ImportStep.find) _scan = 1;
    for (final f in _found) {
      _sel[f.id] = true;
    }
    if (s.index >= ImportStep.check.index) {
      _lock
        ..['sav'] = _Lock.free
        ..['eve'] = _Lock.free
        ..['tst'] = _Lock.free
        ..['cli'] = s == ImportStep.check ? _Lock.locked : _Lock.free;
    }
    if (s == ImportStep.copy) {
      _copy
        ..['sav'] = _Copy(_Cp.ok, 4, 1)
        ..['eve'] = _Copy(_Cp.run, 2, .45)
        ..['tst'] = _Copy(_Cp.wait)
        ..['cli'] = _Copy(_Cp.wait);
    } else if (s.index > ImportStep.copy.index) {
      for (final f in _found) {
        _copy[f.id] = _Copy(_Cp.ok, 4, 1);
      }
    }
  }

  void _enter(ImportStep s) {
    _timer?.cancel();
    setState(() => _step = s);
    switch (s) {
      case ImportStep.find:
        _scan = 0;
        _timer = Timer.periodic(const Duration(milliseconds: 700), (t) {
          setState(() => _scan++);
          if (_scan >= 3) {
            t.cancel();
            _found = List.of(_olds);
            for (final f in _found) {
              _sel[f.id] = true;
            }
            setState(() => _step = _found.isEmpty ? ImportStep.none : ImportStep.found);
          }
        });
      case ImportStep.check:
        for (final f in _chosen) {
          _lock[f.id] = _Lock.checking;
        }
        _timer = Timer(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() {
            for (final f in _chosen) {
              _lock[f.id] = f.id == 'cli' ? _Lock.locked : _Lock.free;
            }
          });
        });
      case ImportStep.copy:
        _startCopy();
      default:
    }
  }

  void _startCopy() {
    final todo = _free;
    for (final f in todo) {
      _copy[f.id] = _Copy(_Cp.wait);
    }
    _timer = Timer.periodic(const Duration(milliseconds: 120), (t) {
      final cur = todo.where((f) => _copy[f.id]!.st != _Cp.ok).firstOrNull;
      if (cur == null) {
        t.cancel();
        return;
      }
      final c = _copy[cur.id]!;
      setState(() {
        c.st = _Cp.run;
        c.pct += 0.08;
        c.phase = (c.pct * 4).floor().clamp(0, 3);
        if (c.pct >= 1) {
          c.st = _Cp.ok;
          c.phase = 4;
          c.pct = 1;
        }
      });
    });
  }

  void _recheck(String id) {
    setState(() => _lock[id] = _Lock.checking);
    Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _lock[id] = _Lock.free);
    });
  }

  void _next() {
    switch (_step) {
      case ImportStep.found:
        // Duplicates start unticked.
        for (final f in _found) {
          _sel[f.id] = _same(f) == null;
        }
        _enter(ImportStep.choose);
      case ImportStep.choose:
        _enter(ImportStep.check);
      case ImportStep.check:
        _enter(ImportStep.copy);
      case ImportStep.copy:
        _enter(ImportStep.settings);
      case ImportStep.settings:
        setState(() => _applying = true);
        _timer = Timer(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() => _applying = false);
          _enter(ImportStep.done);
        });
      case ImportStep.done:
        ref.read(deskNavProvider.notifier).reset(DeskRoute.unlock);
      default:
    }
  }

  void _back() {
    final prev = switch (_step) {
      ImportStep.choose => ImportStep.found,
      ImportStep.check => ImportStep.choose,
      ImportStep.copy => ImportStep.choose,
      _ => null,
    };
    if (prev != null) {
      _timer?.cancel();
      setState(() => _step = prev);
    }
  }

  Future<void> _cancel() async {
    final nav = ref.read(deskNavProvider.notifier);
    void leave() => nav.canBack ? nav.back() : nav.reset(DeskRoute.welcome);
    if (_step == ImportStep.copy || _step == ImportStep.settings) {
      final stop = await showImportStopDialog(context);
      if (stop == true) leave();
    } else {
      leave();
    }
  }

  Future<void> _pickFolder() async {
    final path = await showImportPickerDialog(context);
    if (path == null || !mounted) return;
    setState(() {
      if (!_found.any((f) => f.dir == path)) {
        _found = [
          ..._found,
          _Old('bak', 'Backup 2024', 'picked', path, '3 Mar 2026', 2, 19, 'E'),
        ];
        _sel['bak'] = true;
      }
      if (_step == ImportStep.none) _step = ImportStep.found;
    });
  }

  ({String title, String? lead}) get _head => switch (_step) {
    ImportStep.find => (title: 'Finding wallets', lead: 'Searching the folders of older Epic Wallet versions and the epic program. Nothing is changed.'),
    ImportStep.found => (title: '${_found.length} wallet${_found.length == 1 ? '' : 's'} found', lead: 'Old folders are only read.'),
    ImportStep.none => (title: 'No wallets found', lead: 'None in the usual places.'),
    ImportStep.choose => (title: 'Choose wallets', lead: 'Ticked wallets are copied into the app. Each keeps its password.'),
    ImportStep.check => (title: 'Checking for use', lead: 'A wallet in use by another program is not copied.'),
    ImportStep.copy => (title: 'Copying', lead: 'Each copy is compared with the original file by file. Old folders are only read.'),
    ImportStep.settings => (title: 'Settings', lead: 'Settings from the older app. Untick to keep the defaults.'),
    ImportStep.done => (title: 'Wallets copied', lead: 'Unlock each wallet once to finish.'),
  };

  int get _railIndex => switch (_step) {
    ImportStep.find || ImportStep.found || ImportStep.none => 0,
    ImportStep.choose => 1,
    ImportStep.check => 2,
    ImportStep.copy => 3,
    ImportStep.settings => 4,
    ImportStep.done => 5,
  };

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final h = _head;
    final chosen = _chosen;
    final copied = _free.where((f) => _copy[f.id]?.st == _Cp.ok).length;
    final busyCheck = chosen.any((f) => _lock[f.id] == null || _lock[f.id] == _Lock.checking);
    final pending = chosen.any((f) => _lock[f.id] == _Lock.locked);
    final copyOpen = _free.any((f) => _copy[f.id]?.st != _Cp.ok && _copy[f.id]?.st != _Cp.skip);
    final (label, enabled, stat) = switch (_step) {
      ImportStep.find => ('Continue', false, null),
      ImportStep.found => ('Continue', true, null),
      ImportStep.none => ('Continue', false, null),
      ImportStep.choose => ('Continue', chosen.isNotEmpty, '${chosen.length} of ${_found.length} selected'),
      ImportStep.check => (
        'Continue',
        !busyCheck && !pending && _free.isNotEmpty,
        busyCheck ? 'Checking…' : (pending ? 'Close the other program or skip the wallet' : null),
      ),
      ImportStep.copy => ('Continue', !copyOpen && copied > 0, '$copied of ${_free.length} copied'),
      ImportStep.settings => ('Continue', !_applying, null),
      ImportStep.done => ('Open wallet', true, null),
    };
    return EOnbFrame(
      sideTitle: 'Import wallets',
      steps: railOf(['Find', 'Choose', 'Check', 'Copy', 'Settings', 'Done'], _railIndex),
      title: h.title,
      lead: h.lead,
      sideFoot: _step == ImportStep.done
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: EButton.ghost(label: 'Cancel', icon: EIcons.close, onPressed: _cancel),
            ),
      actions: [
        if (stat != null)
          Expanded(child: Text(stat, style: ts.small))
        else
          const SizedBox.shrink(),
        if ([ImportStep.choose, ImportStep.check, ImportStep.copy].contains(_step))
          Padding(padding: const EdgeInsets.only(right: Sp.x3), child: EButton(label: 'Back', onPressed: _back)),
        EButton.primary(label: label, busy: _applying, onPressed: enabled ? _next : null),
      ],
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) => switch (_step) {
    ImportStep.find => _finding(context),
    ImportStep.found => _foundList(context, selectable: false),
    ImportStep.none => _none(context),
    ImportStep.choose => _foundList(context, selectable: true),
    ImportStep.check => _check(context),
    ImportStep.copy => _copying(context),
    ImportStep.settings => _settings(context),
    ImportStep.done => _done(context),
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

  Widget _finding(BuildContext context) {
    const rows = [
      ('Older Epic Wallet', EIcons.wallet, 'Accounts and folders'),
      ('The epic program', EIcons.node, '~/.epic'),
      ('Older app profiles', EIcons.contacts, 'Labels and contacts'),
    ];
    final ts = context.ts;
    final c = context.dc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _wlist(context, [
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.all(Sp.x4),
              child: Row(
                children: [
                  Icon(rows[i].$2, size: Ctl.icon, color: c.dim),
                  const SizedBox(width: Sp.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rows[i].$1, style: ts.label),
                        Text(rows[i].$3, style: ts.small),
                      ],
                    ),
                  ),
                  if (i < _scan)
                    Row(children: [Icon(EIcons.okCircle, size: Ctl.iconSm, color: c.ok), const SizedBox(width: Sp.x1), Text('Done', style: ts.small)])
                  else if (i == _scan)
                    Row(children: [const ESpinner(), const SizedBox(width: Sp.x2), Text('Searching…', style: ts.small)])
                  else
                    Text('Waiting', style: ts.caption),
                ],
              ),
            ),
        ]),
        const SizedBox(height: Sp.x4),
        EProgress(value: _scan / 3),
      ],
    );
  }

  Widget _none(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: Sp.x4,
        runSpacing: Sp.x2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          EButton(label: 'Choose a folder', icon: EIcons.folderOpen, onPressed: _pickFolder),
          ELink(label: 'Restore from phrase', onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.restore)),
        ],
      ),
    ],
  );

  Widget _rowTags(_Old f, {String? same}) => Wrap(
    spacing: Sp.x2,
    children: [
      if (f.floonet) const ETag('Floonet'),
      if (same != null) const ETag('Same wallet', tone: ETone.warn, icon: EIcons.alert),
    ],
  );

  Widget _foundList(BuildContext context, {required bool selectable}) {
    final ts = context.ts;
    final c = context.dc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in _groups.entries)
          if (_found.any((f) => f.group == g.key)) ...[
            Padding(
              padding: const EdgeInsets.only(top: Sp.x2, bottom: Sp.x2),
              child: Row(
                children: [
                  Icon(g.value.$2, size: Ctl.iconSm, color: c.dim),
                  const SizedBox(width: Sp.x2),
                  Text(g.value.$1, style: ts.label),
                ],
              ),
            ),
            _wlist(context, [
              for (final f in _found.where((f) => f.group == g.key))
                _foundRow(context, f, selectable),
            ]),
            const SizedBox(height: Sp.x4),
          ],
        EButton(label: 'Choose a folder', icon: EIcons.folderOpen, size: EBtnSize.sm, onPressed: _pickFolder),
      ],
    );
  }

  Widget _foundRow(BuildContext context, _Old f, bool selectable) {
    final ts = context.ts;
    final c = context.dc;
    final same = _same(f);
    final meta = 'Last used ${f.used} · ${f.contacts} contact${f.contacts == 1 ? '' : 's'} · ${_size(f.size)}';
    final info = Padding(
      padding: const EdgeInsets.all(Sp.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectable)
            Padding(
              padding: const EdgeInsets.only(right: Sp.x3),
              child: ECheckbox(
                value: _sel[f.id] == true,
                label: f.label,
                onChanged: (v) {
                  setState(() => _sel[f.id] = v);
                  if (v && same != null) showImportSameWalletDialog(context, f.label, same);
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: Sp.x3),
              child: Icon(EIcons.wallet, size: Ctl.icon, color: c.dim),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!selectable) Text(f.label, style: ts.label),
                Text(f.dir, style: ts.mono(size: Fs.xs, color: c.dim), overflow: TextOverflow.ellipsis),
                if (selectable) Text(meta, style: ts.caption),
                if (selectable && same != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Sp.x1),
                    child: Text('Same wallet as $same. Tick for a second copy.', style: ts.small),
                  ),
                if (selectable && f.legacyDb)
                  Padding(
                    padding: const EdgeInsets.only(top: Sp.x1),
                    child: Text('Epic Wallet 5.x or older. One blockchain scan restores the history.', style: ts.small),
                  ),
              ],
            ),
          ),
          _rowTags(f, same: same),
        ],
      ),
    );
    return info;
  }

  Widget _check(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    return _wlist(context, [
      for (final f in _chosen)
        Padding(
          padding: const EdgeInsets.all(Sp.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(EIcons.wallet, size: Ctl.icon, color: c.dim),
                  const SizedBox(width: Sp.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.label, style: ts.label),
                        Text(f.dir, style: ts.mono(size: Fs.xs, color: c.dim), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  switch (_lock[f.id]) {
                    null || _Lock.checking => Row(children: [const ESpinner(), const SizedBox(width: Sp.x2), Text('Checking…', style: ts.small)]),
                    _Lock.free => Row(children: [Icon(EIcons.okCircle, size: Ctl.iconSm, color: c.ok), const SizedBox(width: Sp.x1), Text('Not in use', style: ts.small)]),
                    _Lock.skipped => Row(children: [Icon(EIcons.cancel, size: Ctl.iconSm, color: c.faint), const SizedBox(width: Sp.x1), Text('Skipped', style: ts.small)]),
                    _Lock.locked => Row(children: [Icon(EIcons.error, size: Ctl.iconSm, color: c.risk), const SizedBox(width: Sp.x1), Text('In use', style: ts.small.copyWith(color: c.risk))]),
                  },
                ],
              ),
              if (_lock[f.id] == _Lock.locked) ...[
                const SizedBox(height: Sp.x3),
                Text('In use by another program. Close the older Epic Wallet or the epic program, then check again.', style: ts.small),
                const SizedBox(height: Sp.x3),
                Row(
                  children: [
                    EButton(label: 'Check again', size: EBtnSize.inline, onPressed: () => _recheck(f.id)),
                    const SizedBox(width: Sp.x2),
                    EButton.ghost(label: 'Skip', size: EBtnSize.inline, onPressed: () => setState(() => _lock[f.id] = _Lock.skipped)),
                  ],
                ),
              ],
            ],
          ),
        ),
    ]);
  }

  Widget _copying(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    final rows = _free;
    return _wlist(context, [
      for (final f in rows)
        Builder(builder: (context) {
          final cp = _copy[f.id] ?? _Copy(_Cp.wait);
          return Padding(
            padding: const EdgeInsets.all(Sp.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(EIcons.wallet, size: Ctl.icon, color: c.dim),
                    const SizedBox(width: Sp.x3),
                    Expanded(child: Text('${f.label} · ${_size(f.size)}', style: ts.label)),
                    switch (cp.st) {
                      _Cp.ok => Row(children: [Icon(EIcons.okCircle, size: Ctl.iconSm, color: c.ok), const SizedBox(width: Sp.x1), Text('Copied and checked', style: ts.small)]),
                      _Cp.run => Row(children: [const ESpinner(), const SizedBox(width: Sp.x2), Text('Copying…', style: ts.small)]),
                      _Cp.fail => Row(children: [Icon(EIcons.error, size: Ctl.iconSm, color: c.risk), const SizedBox(width: Sp.x1), Text('Not copied', style: ts.small)]),
                      _ => Text('Waiting', style: ts.caption),
                    },
                  ],
                ),
                if (cp.st == _Cp.run || cp.st == _Cp.ok) ...[
                  const SizedBox(height: Sp.x3),
                  EProgress(value: cp.pct),
                  const SizedBox(height: Sp.x3),
                  for (var i = 0; i < _copyPhases.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            child: i < cp.phase
                                ? Icon(EIcons.check, size: Ctl.iconSm, color: c.ok)
                                : (i == cp.phase ? const ESpinner(size: 12) : Icon(Icons.circle, size: 5, color: c.faint)),
                          ),
                          Text(_copyPhases[i], style: i <= cp.phase ? ts.small : ts.caption),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          );
        }),
    ]);
  }

  Widget _settings(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    final chosen = _found.where((f) => _copy[f.id]?.st == _Cp.ok).toList();
    final contacts = chosen.fold<int>(0, (a, f) => a + f.contacts);
    final chain = chosen.where((f) => f.chain != null).firstOrNull;
    Widget row(String key, String title, String text, String value) => Padding(
      padding: const EdgeInsets.all(Sp.x4),
      child: Row(
        children: [
          Expanded(
            child: ECheckbox(
              value: _set[key] == true,
              label: title,
              onChanged: _applying ? (_) {} : (v) => setState(() => _set[key] = v),
            ),
          ),
          Text(value, style: ts.mono(size: Fs.xs, color: c.dim)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _wlist(context, [
          row('contacts', 'Contacts', 'Added to the address book', '$contacts contacts'),
          row('node', 'Node', 'Node of the older app', 'node.example.net:3413'),
          row('epicbox', 'Epicbox server', 'Updated to the current server', 'epicbox.epiccash.com'),
          row('lang', 'Language', 'Language of the older app', 'Deutsch'),
        ]),
        if (chain != null) ...[
          const SizedBox(height: Sp.x4),
          EPanel(
            title: 'Blockchain data',
            headTrailing: ETag(_size(chain.chain!)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Found in ${chain.dir}. Copied, not moved; used only by the built-in node.', style: ts.small),
                const SizedBox(height: Sp.x3),
                ECheckbox(
                  value: _set['chain'] == true,
                  label: 'Copy the blockchain data',
                  onChanged: (v) => setState(() => _set['chain'] = v),
                ),
              ],
            ),
          ),
        ],
        if (_applying) ...[
          const SizedBox(height: Sp.x4),
          Text('Applying settings…', style: ts.small),
          const SizedBox(height: Sp.x2),
          const EProgress(),
        ],
      ],
    );
  }

  Widget _done(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    final done = _found.where((f) => _copy[f.id]?.st == _Cp.ok).toList();
    final bits = [
      if (_set['contacts'] == true) 'Contacts',
      if (_set['node'] == true) 'Node',
      if (_set['epicbox'] == true) 'Epicbox server',
      if (_set['lang'] == true) 'Language',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _wlist(context, [
          for (final f in done)
            Padding(
              padding: const EdgeInsets.all(Sp.x4),
              child: Row(
                children: [
                  Icon(EIcons.okCircle, size: Ctl.icon, color: c.ok),
                  const SizedBox(width: Sp.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(f.label, style: ts.label), Text('Copied and checked', style: ts.small)],
                    ),
                  ),
                ],
              ),
            ),
        ]),
        if (bits.isNotEmpty) ...[
          const SizedBox(height: Sp.x4),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Settings:', style: ts.small),
              for (final b in bits) ETag(b, tone: ETone.ok, icon: EIcons.check),
            ],
          ),
        ],
        const SizedBox(height: Sp.x4),
        Text('Old folders can be deleted after the first unlock.', style: ts.bodyDim),
        const SizedBox(height: Sp.x2),
        Align(
          alignment: Alignment.centerLeft,
          child: ELink(
            label: 'Delete an old folder',
            onPressed: () => showImportDeleteDialog(context, done.first.label, done.first.dir),
          ),
        ),
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
    description: 'Copies made so far are removed. Old folders are unchanged.',
    icon: EIcons.stop,
    tone: ETone.warn,
    width: 420,
    actions: [
      EButton(label: 'Go back', onPressed: () => Navigator.pop(ctx, false)),
      EButton(label: 'Stop import', kind: EBtnKind.danger, onPressed: () => Navigator.pop(ctx, true)),
    ],
  ),
);

/// "Same wallet as …": keep both copies or remove this one.
Future<bool?> showImportSameWalletDialog(BuildContext context, String name, String other) => showEDialog<bool>(
  context,
  builder: (ctx) => EDialog(
    title: 'Same wallet as $other',
    description: '$name has the same address as $other. Both show the same coins.',
    icon: EIcons.alert,
    tone: ETone.warn,
    width: 440,
    actions: [
      EButton(label: 'Keep both', onPressed: () => Navigator.pop(ctx, true)),
      EButton.primary(label: 'Remove this copy', onPressed: () => Navigator.pop(ctx, false)),
    ],
  ),
);

/// "Delete the old folder of …?": files go to the Recycle Bin.
Future<bool?> showImportDeleteDialog(BuildContext context, String name, String dir) => showEDialog<bool>(
  context,
  builder: (ctx) => EDialog(
    title: 'Delete the old folder of $name?',
    description: 'Moved to the Recycle Bin. Other files stay; the folder is removed only when empty.',
    icon: EIcons.trash,
    tone: ETone.risk,
    width: 460,
    body: Builder(
      builder: (ctx) => Text(dir, style: ctx.ts.mono()),
    ),
    actions: [
      EButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx, false)),
      EButton(label: 'Delete', icon: EIcons.trash, kind: EBtnKind.danger, onPressed: () => Navigator.pop(ctx, true)),
    ],
  ),
);

/// "Checking the copy": the four steps of the test open, shown part-way.
Future<void> showImportCheckingDialog(BuildContext context, String name, {int step = 2}) => showEDialog<void>(
  context,
  dismissible: false,
  builder: (ctx) => EDialog(
    title: 'Checking the copy of $name',
    width: 440,
    dismissible: false,
    body: Builder(
      builder: (ctx) {
        const steps = ['Opening with the password', 'Reading the database', 'Reading the balance and transactions', 'Checking the address'];
        final c = ctx.dc;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Sp.x1),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: i < step
                          ? Icon(EIcons.check, size: Ctl.iconSm, color: c.ok)
                          : (i == step ? const ESpinner() : Icon(Icons.circle, size: 5, color: c.faint)),
                    ),
                    Text(steps[i], style: i <= step ? ctx.ts.body : ctx.ts.small),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  ),
);

/// "The copy did not open".
Future<void> showImportOpenFailDialog(BuildContext context, String name) => showEDialog<void>(
  context,
  builder: (ctx) => EDialog(
    title: 'The copy of $name did not open',
    description: 'The copy matches the original, but the wallet could not open it. The old folder is unchanged. Import it again, or restore from the recovery phrase.',
    icon: EIcons.error,
    tone: ETone.risk,
    width: 460,
    actions: [EButton.primary(label: 'Remove the copy', onPressed: () => Navigator.pop(ctx))],
  ),
);

/// "Choose a folder": a small mock of the system folder dialog. Pops the chosen path.
Future<String?> showImportPickerDialog(BuildContext context) => showEDialog<String>(
  context,
  builder: (ctx) => const _PickerDialog(),
);

class _PickerDialog extends StatefulWidget {
  const _PickerDialog();

  @override
  State<_PickerDialog> createState() => _PickerDialogState();
}

class _PickerDialogState extends State<_PickerDialog> {
  static const _folders = ['~/.epic/chain_backup', '~/Desktop/epic-blockchain', '~/Documents/old-wallet-backup', '~/Downloads'];
  String? _sel;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return EDialog(
      title: 'Choose a folder',
      description: 'Select the wallet folder. It is only read.',
      width: 520,
      body: Container(
        decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
        child: Column(
          children: [
            for (final f in _folders)
              ListTile(
                dense: true,
                selected: _sel == f,
                selectedTileColor: c.s3,
                leading: Icon(EIcons.folder, size: Ctl.icon, color: c.dim),
                title: Text(f, style: context.ts.mono()),
                onTap: () => setState(() => _sel = f),
              ),
          ],
        ),
      ),
      actions: [
        EButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
        EButton.primary(label: 'Choose', onPressed: _sel == null ? null : () => Navigator.pop(context, _sel)),
      ],
    );
  }
}
