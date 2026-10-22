import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';
import 'prefs.dart';
import 'settings_frame.dart';
import 'settings_node.dart' show hostOf, minNodeVersion, nodeTone, versionOld;

// ---- My node -------------------------------------------------------------------------------

/// Add a node to My nodes, or edit one: address (checked as it is typed) and an optional
/// label. A node can be saved while it is offline. [showError] opens with a bad address.
Future<void> showMyNodeDialog(BuildContext context, {String initial = '', String label = '', bool adding = false, bool showError = false}) =>
    showEDialog(
      context,
      builder: (_) => MyNodeDialog(initial: initial, label: label, editing: !adding && initial.isNotEmpty, showError: showError),
    );

class MyNodeDialog extends ConsumerStatefulWidget {
  const MyNodeDialog({super.key, this.initial = '', this.label = '', this.editing = false, this.showError = false});

  final String initial;
  final String label;
  final bool editing;
  final bool showError;

  @override
  ConsumerState<MyNodeDialog> createState() => _MyNodeDialogState();
}

class _MyNodeDialogState extends ConsumerState<MyNodeDialog> {
  late final _address = TextEditingController(text: widget.initial);
  late final _label = TextEditingController(text: widget.label);
  NodeServer? _check;
  bool _checking = false;
  bool _tried = false;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initial.isNotEmpty) _recheck();
    _tried = widget.showError;
  }

  @override
  void dispose() {
    _address.dispose();
    _label.dispose();
    super.dispose();
  }

  String get _url {
    final t = _address.text.trim();
    return t.isEmpty || t.startsWith('http') ? t : 'http://$t';
  }

  /// A problem with the address itself; an offline node is not one.
  String? get _problem {
    final t = _address.text.trim();
    if (t.isEmpty) return _tried ? 'Enter the node’s address.' : null;
    if (t.contains(' ') || !RegExp(r'[.:]').hasMatch(t) || (widget.showError && t == widget.initial)) {
      return 'Not a node address. Check the address and the port (usually 3413).';
    }
    final mine = ref.read(deskProvider).nodes?.where((n) => n.own).map((n) => n.url) ?? const <String>[];
    final removed = ref.read(settingsPrefsProvider).removedNodes;
    if (_url != widget.initial && mine.contains(_url) && !removed.contains(_url)) return 'This address is already in My nodes.';
    return null;
  }

  Future<void> _recheck() async {
    final n = ++_seq;
    final url = _url;
    setState(() {
      _checking = url.isNotEmpty;
      _check = null;
    });
    if (url.isEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted || n != _seq) return;
    final r = await ref.read(deskApiProvider).checkNode(url);
    if (!mounted || n != _seq) return;
    setState(() {
      _checking = false;
      _check = r;
    });
  }

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_problem != null) return;
    final url = _url;
    final label = _label.text.trim();
    final prefs = ref.read(settingsPrefsProvider.notifier);
    final known = ref.read(deskProvider).nodes?.any((n) => n.own && n.url == url) ?? false;
    if (widget.editing && url != widget.initial) prefs.forgetNode(widget.initial);
    if (!known) {
      final r = _check;
      await ref.read(deskProvider.notifier).addNode(
        NodeServer(url: url, label: label, own: true, health: r?.health ?? ServiceHealth.down, height: r?.height, version: r?.version, latencyMs: r?.latencyMs),
      );
    }
    prefs.restoreNode(url);
    prefs.label(url, label);
    if (!mounted) return;
    Navigator.of(context).pop();
    showEToast(context, widget.editing ? 'Node saved' : 'Added to my nodes', text: label.isEmpty ? hostOf(url) : label);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final problem = _problem;
    final r = _check;
    Widget? status;
    if (problem == null && _checking) {
      status = Row(children: [ESpinner(size: Ctl.iconSm), SizedBox(width: Sp.x2), Text('Checking…', style: ts.small)]);
    } else if (problem == null && r != null) {
      final down = r.health == ServiceHealth.down;
      status = Wrap(
        spacing: Sp.x2,
        runSpacing: Sp.x1,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          EStatusDot(nodeTone(r.health)),
          Text(nodeWord(r.health), style: ts.small.copyWith(color: down ? c.risk : c.text, fontWeight: FontWeight.w600)),
          if (r.height != null) Text(groupDigits(r.height!), style: ts.mono(size: Fs.sm, color: c.dim)),
          if (versionOld(r.version)) ETag('Version older than $minNodeVersion', tone: ETone.warn),
          if (down) Text('It can be saved anyway.', style: ts.small),
        ],
      );
    }
    return EDialog(
      title: widget.editing ? 'Edit node' : 'Add to my nodes',
      description: 'Save a node address to find it again later. It can be saved while it is offline.',
      icon: EIcons.server,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EField(
            label: 'Node address',
            error: problem,
            child: EInput(
              controller: _address,
              hint: 'http://10.0.1.24:3413',
              mono: true,
              invalid: problem != null,
              autofocus: true,
              semanticLabel: 'Node address',
              onChanged: (_) => _recheck(),
              onSubmitted: (_) => _save(),
            ),
          ),
          if (status != null) ...[SizedBox(height: Sp.x2), Semantics(liveRegion: true, child: status)],
          SizedBox(height: Sp.x4),
          EField(
            label: 'Label',
            optional: true,
            child: EInput(controller: _label, hint: 'e.g. Home node', semanticLabel: 'Label', onSubmitted: (_) => _save()),
          ),
        ],
      ),
      actions: [
        EButton(label: 'Cancel', size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop()),
        EButton.primary(label: 'Save', icon: EIcons.check, size: EBtnSize.sm, onPressed: _address.text.trim().isEmpty ? null : _save),
      ],
    );
  }
}

// ---- Node directory ------------------------------------------------------------------------

Future<void> showNodeDirectoryDialog(BuildContext context) =>
    showEDialog(context, builder: (_) => const NodeDirectoryDialog());

class NodeDirectoryDialog extends ConsumerWidget {
  const NodeDirectoryDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final st = ref.watch(deskProvider);
    final prefs = ref.watch(settingsPrefsProvider);
    final nodes = (st.nodes ?? const <NodeServer>[]).where((n) => !n.own).toList();
    final current = prefs.builtin ? null : (prefs.typedNode ?? st.status?.node)?.url;
    return EDialog(
      title: 'Node directory',
      description: 'Public nodes, their operators and their state at the last check.',
      icon: EIcons.server,
      width: 640.u,
      body: st.nodes == null
          ? const SettingsLoading()
          : nodes.isEmpty
          ? const EEmpty(icon: EIcons.node, title: 'No nodes to show')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
                  child: Column(
                    children: [
                      for (var i = 0; i < nodes.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: c.line),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(hostOf(nodes[i].url), style: ts.mono(size: Fs.sm, color: c.text), overflow: TextOverflow.ellipsis),
                                    Text(
                                      [nodes[i].operator, if (nodes[i].version != null) 'version ${nodes[i].version}', if (nodes[i].height != null) 'height ${groupDigits(nodes[i].height!)}']
                                          .whereType<String>()
                                          .join(' · '),
                                      style: ts.caption,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: Sp.x3),
                              HealthLine(nodes[i].health, latencyMs: nodes[i].latencyMs),
                              SizedBox(width: Sp.x3),
                              nodes[i].url == current
                                  ? const ETag('In use', tone: ETone.gold)
                                  : EButton(
                                      label: 'Use',
                                      size: EBtnSize.inline,
                                      onPressed: nodes[i].health == ServiceHealth.down
                                          ? null
                                          : () async {
                                              await ref.read(deskProvider.notifier).useNode(nodes[i].url);
                                              final p = ref.read(settingsPrefsProvider.notifier);
                                              p.set(ref.read(settingsPrefsProvider).copyWith(builtin: false, clearTyped: true));
                                              if (context.mounted) Navigator.of(context).pop();
                                            },
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: Sp.x3),
                Text('Response times are measured from the status site, not from this computer.', style: ts.caption),
              ],
            ),
      actions: [EButton(label: 'Close', size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop())],
    );
  }
}

// ---- Existing blockchain data --------------------------------------------------------------

/// The built-in node picked and older chain data found: use it (true), download fresh
/// (false), or back (null). [inUse]: another Epic program holds the folder.
Future<bool?> showChainOfferDialog(BuildContext context, {bool inUse = false}) =>
    showEDialog<bool>(context, builder: (_) => ChainOfferDialog(inUse: inUse));

class ChainOfferDialog extends StatelessWidget {
  const ChainOfferDialog({super.key, this.inUse = false});

  final bool inUse;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final nav = Navigator.of(context);
    return EDialog(
      title: 'Existing blockchain data found',
      description: 'This computer already has Epic blockchain data that the built-in node can use.',
      icon: EIcons.node,
      tone: ETone.gold,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EFacts([
            ('Folder', Text('~/.epic/main/chain_data', style: ts.mono(size: Fs.sm, color: c.text))),
            ('Size', Text('4.2 GB', style: ts.mono(size: Fs.sm, color: c.text))),
            ('Last updated', Text('3 days ago', style: ts.small.copyWith(color: c.text))),
          ], labelWidth: 110.u),
          SizedBox(height: Sp.x3),
          Text('Other copies were found too (1). This one was updated most recently.', style: ts.small),
          SizedBox(height: Sp.x3),
          Text(
            inUse ? 'Another Epic program is using this folder. Close it, then pick the built-in node again to use this data.' : 'Use it? That saves downloading and syncing the whole blockchain.',
            style: ts.body.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: Sp.x2),
          Text('An older Epic Wallet that uses this folder may need to sync again after this. Coins are not affected.', style: ts.caption),
        ],
      ),
      actions: [
        EButton(label: 'Download fresh', size: EBtnSize.sm, kind: EBtnKind.ghost, onPressed: () => nav.pop(false)),
        if (inUse) EButton(label: 'Close', size: EBtnSize.sm, onPressed: () => nav.pop()),
        EButton.primary(label: 'Use this data', icon: EIcons.check, size: EBtnSize.sm, onPressed: inUse ? null : () => nav.pop(true)),
      ],
    );
  }
}

// ---- Change password -----------------------------------------------------------------------

Future<void> showChangePasswordDialog(BuildContext context) =>
    showEDialog(context, builder: (_) => const ChangePasswordDialog());

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;
  bool _tried = false;
  String? _wrong;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  String? get _nextError => !_tried
      ? null
      : _next.text.length < 8
      ? 'At least 8 characters.'
      : null;
  String? get _repeatError => _tried && _repeat.text != _next.text ? 'The passwords differ.' : null;

  Future<void> _save() async {
    setState(() {
      _tried = true;
      _wrong = null;
    });
    if (_current.text.isEmpty || _next.text.length < 8 || _repeat.text != _next.text) return;
    setState(() => _busy = true);
    try {
      await ref.read(deskApiProvider).changePassword(_current.text, _next.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      showEToast(context, 'Password changed');
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _wrong = 'Wrong password.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: EDialog(
      title: 'Change password',
      dismissible: !_busy,
      description: 'The new password unlocks this wallet from now on.',
      icon: EIcons.lock,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EField(
            label: 'Current password',
            error: _wrong ?? (_tried && _current.text.isEmpty ? 'Enter the current password.' : null),
            child: EPasswordInput(controller: _current, autofocus: true, invalid: _wrong != null, onChanged: (_) => setState(() => _wrong = null)),
          ),
          SizedBox(height: Sp.x4),
          EField(label: 'New password', error: _nextError, child: EPasswordInput(controller: _next, invalid: _nextError != null)),
          SizedBox(height: Sp.x4),
          EField(
            label: 'Repeat new password',
            error: _repeatError,
            child: EPasswordInput(controller: _repeat, invalid: _repeatError != null, onSubmitted: (_) => _save()),
          ),
        ],
      ),
      actions: [
        EButton(label: 'Cancel', size: EBtnSize.sm, onPressed: _busy ? null : () => Navigator.of(context).pop()),
        EButton.primary(label: 'Change password', size: EBtnSize.sm, busy: _busy, onPressed: _save),
      ],
    ),
    );
  }
}

// ---- Remove wallet -------------------------------------------------------------------------

/// What to remove of a wallet. [app] and [everything] both delete the wallet (the app keeps no
/// files of its own for a wallet): its keys and database. `wallet_data` stays.
enum RemoveMode { list, app, everything }

/// Remove [wallet] from this computer: from the list only, or delete it (typed name and a
/// tick). The open wallet is locked first.
Future<void> showRemoveWalletDialog(BuildContext context, WalletEntry wallet, {RemoveMode? mode}) =>
    showEDialog(context, builder: (_) => RemoveWalletDialog(wallet: wallet, initialMode: mode));

class RemoveWalletDialog extends ConsumerStatefulWidget {
  const RemoveWalletDialog({super.key, required this.wallet, this.initialMode});

  final WalletEntry wallet;
  final RemoveMode? initialMode;

  @override
  ConsumerState<RemoveWalletDialog> createState() => _RemoveWalletDialogState();
}

class _RemoveWalletDialogState extends ConsumerState<RemoveWalletDialog> {
  final _typed = TextEditingController();
  bool _busy = false;
  bool _ack = false;
  String? _error;
  late WalletRemoval? _mode = switch (widget.initialMode) {
    null => null,
    RemoveMode.list => WalletRemoval.list,
    RemoveMode.app || RemoveMode.everything => WalletRemoval.delete,
  };

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  WalletEntry get w => widget.wallet;

  bool get _nameOk => _typed.text.trim() == w.name;

  bool get _ready => !_busy && _mode != null && (_mode != WalletRemoval.delete || (_nameOk && _ack));

  Future<void> _remove() async {
    final mode = _mode;
    if (mode == null || !_ready) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(deskProvider.notifier).removeWallet(w.id, mode);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = deskErrorText(e);
        });
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showEToast(context, switch (mode) {
      WalletRemoval.list => '${w.name} removed from the list',
      WalletRemoval.delete => '${w.name} deleted',
    }, text: mode == WalletRemoval.list ? 'Files kept.' : null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    Widget choice(WalletRemoval m, String title, String hint) => Padding(
      padding: EdgeInsets.only(bottom: Sp.x2),
      child: IgnorePointer(
        ignoring: _busy,
        child: EChoiceCard(
          title: title,
          description: hint,
          selected: _mode == m,
          onTap: () => setState(() {
            _mode = m;
            _error = null;
          }),
        ),
      ),
    );
    return PopScope(
      canPop: !_busy,
      child: EDialog(
        title: 'Remove ${w.name}?',
        description: 'Nothing changes until the button below is pressed.',
        icon: EIcons.trash,
        tone: ETone.risk,
        dismissible: !_busy,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label: 'What to remove',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  choice(WalletRemoval.list, 'Remove from list', 'Files stay in ${w.folder}. All wallets can add it back.'),
                  choice(
                    WalletRemoval.delete,
                    'Delete wallet',
                    'Deletes its keys and database from ${w.folder}. Only the recovery phrase restores it; without it the coins are lost.',
                  ),
                ],
              ),
            ),
            if (_mode == WalletRemoval.delete) ...[
              SizedBox(height: Sp.x2),
              const ENotice(
                title: 'Cannot be undone',
                text: 'Only the recovery phrase restores the wallet; without it the coins are lost for good.',
                tone: ETone.risk,
              ),
              SizedBox(height: Sp.x4),
              EField(
                label: 'Wallet name',
                help: 'Type ${w.name} to confirm.',
                error: _typed.text.isNotEmpty && !_nameOk ? 'Name does not match' : null,
                child: EInput(
                  controller: _typed,
                  enabled: !_busy,
                  invalid: _typed.text.isNotEmpty && !_nameOk,
                  semanticLabel: 'Wallet name',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(height: Sp.x3),
              ECheckbox(value: _ack, onChanged: (v) => setState(() => _ack = v), label: 'The recovery phrase is written down'),
            ],
            if (_error != null) ...[
              SizedBox(height: Sp.x3),
              Semantics(liveRegion: true, child: Text(_error!, style: ts.small.copyWith(color: c.risk))),
            ],
            if (_busy) ...[
              SizedBox(height: Sp.x2),
              Text('Removing…', style: ts.small.copyWith(color: c.dim)),
            ],
          ],
        ),
        actions: [
          EButton(label: 'Cancel', size: EBtnSize.sm, kind: EBtnKind.ghost, onPressed: _busy ? null : () => Navigator.of(context).pop()),
          EButton(
            label: _mode == WalletRemoval.delete ? 'Delete wallet' : 'Remove from list',
            icon: EIcons.trash,
            size: EBtnSize.sm,
            kind: EBtnKind.danger,
            busy: _busy,
            onPressed: _ready ? _remove : null,
          ),
        ],
      ),
    );
  }
}

// ---- Delete this wallet --------------------------------------------------------------------

/// Deletes the open wallet from this computer after its password. Then Unlock opens, or
/// Welcome when no wallet is left.
Future<void> showDeleteWalletDialog(BuildContext context) => showEDialog(context, builder: (_) => const DeleteWalletDialog());

class DeleteWalletDialog extends ConsumerStatefulWidget {
  const DeleteWalletDialog({super.key});

  @override
  ConsumerState<DeleteWalletDialog> createState() => _DeleteWalletDialogState();
}

class _DeleteWalletDialogState extends ConsumerState<DeleteWalletDialog> {
  final _password = TextEditingController();
  bool _ack = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  bool get _ready => !_busy && _ack && _password.text.isNotEmpty;

  Future<void> _delete() async {
    if (!_ready) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final desk = ref.read(deskProvider.notifier);
    final nav = ref.read(deskNavProvider.notifier);
    final id = ref.read(deskProvider).account?.id;
    try {
      if (id == null) throw const DeskError('The wallet is locked');
      await desk.removeWallet(id, WalletRemoval.delete, password: _password.text);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = deskErrorText(e);
        });
      }
      return;
    }
    final left = ref.read(deskProvider).wallets ?? const [];
    if (!mounted) return;
    Navigator.of(context).pop();
    nav.reset(left.isEmpty ? DeskRoute.welcome : DeskRoute.unlock);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: EDialog(
      title: 'Delete this wallet?',
      description: 'Deletes the wallet and its seed from this computer. Only the recovery phrase restores it; without it the coins are lost.',
      icon: EIcons.trash,
      tone: ETone.risk,
      dismissible: !_busy,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EField(
            label: 'Password',
            error: _error,
            child: EPasswordInput(
              controller: _password,
              autofocus: true,
              invalid: _error != null,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _delete(),
            ),
          ),
          SizedBox(height: Sp.x4),
          ECheckbox(value: _ack, onChanged: (v) => setState(() => _ack = v), label: 'The recovery phrase is written down'),
        ],
      ),
      actions: [
        EButton(label: 'Cancel', size: EBtnSize.sm, kind: EBtnKind.ghost, onPressed: _busy ? null : () => Navigator.of(context).pop()),
        EButton(label: 'Delete wallet', icon: EIcons.trash, size: EBtnSize.sm, kind: EBtnKind.danger, busy: _busy, onPressed: _ready ? _delete : null),
      ],
    ),
  );
}
