import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'settings_frame.dart';

// ---- My node -------------------------------------------------------------------------------

/// Add or edit a node of "My nodes": address, check, save. [showError] opens in the failed
/// check state (shot 31b).
Future<void> showMyNodeDialog(BuildContext context, {String initial = '', bool showError = false}) =>
    showEDialog(context, builder: (_) => MyNodeDialog(initial: initial, showError: showError));

class MyNodeDialog extends ConsumerStatefulWidget {
  const MyNodeDialog({super.key, this.initial = '', this.showError = false});

  final String initial;
  final bool showError;

  @override
  ConsumerState<MyNodeDialog> createState() => _MyNodeDialogState();
}

class _MyNodeDialogState extends ConsumerState<MyNodeDialog> {
  late final _address = TextEditingController(text: widget.initial);
  bool _checking = false;
  bool _saving = false;
  NodeServer? _result;
  late bool _failed = widget.showError;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final url = _address.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _checking = true;
      _failed = false;
      _result = null;
    });
    final r = await ref.read(deskApiProvider).checkNode(url);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _result = r;
      _failed = r.health == ServiceHealth.down;
    });
  }

  Future<void> _save() async {
    final r = _result;
    if (r == null) return;
    setState(() => _saving = true);
    await ref.read(deskProvider.notifier).addNode(r);
    if (!mounted) return;
    Navigator.of(context).pop();
    showEToast(context, 'Node saved', text: r.label);
  }

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final r = _result;
    return EDialog(
      title: widget.initial.isEmpty ? 'Add node' : 'Edit node',
      description: 'An Epic node of your own, by address and port (usually 3413).',
      icon: EIcons.node,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EField(
            label: 'Node address',
            error: _failed ? 'Not an Epic node. Check the address and the port (usually 3413).' : null,
            child: EInput(
              controller: _address,
              hint: 'http://10.0.1.24:3413',
              mono: true,
              invalid: _failed,
              autofocus: true,
              enabled: !_checking && !_saving,
              onChanged: (_) => setState(() {
                _result = null;
                _failed = false;
              }),
              onSubmitted: (_) => _check(),
              semanticLabel: 'Node address',
            ),
          ),
          if (r != null && !_failed) ...[
            const SizedBox(height: Sp.x4),
            EFacts([
              ('Status', HealthLine(r.health, latencyMs: r.latencyMs)),
              ('Height', Text('${r.height ?? '-'}', style: ts.mono(size: Fs.sm))),
              ('Version', Text(r.version ?? '-', style: ts.mono(size: Fs.sm))),
            ], labelWidth: 100),
          ],
        ],
      ),
      actions: [
        EButton(label: 'Cancel', size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop()),
        EButton(label: 'Check', size: EBtnSize.sm, icon: EIcons.refresh, busy: _checking, onPressed: _address.text.trim().isEmpty ? null : _check),
        EButton.primary(label: 'Save node', size: EBtnSize.sm, busy: _saving, onPressed: r != null && !_failed ? _save : null),
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
    final nodes = (st.nodes ?? const <NodeServer>[]).where((n) => !n.own).toList();
    final current = st.status?.node.url;
    return EDialog(
      title: 'Node directory',
      description: 'Public nodes and their operators. Status from the last check.',
      icon: EIcons.server,
      width: 640,
      body: st.nodes == null
          ? const SettingsLoading()
          : nodes.isEmpty
          ? const EEmpty(icon: EIcons.node, title: 'No nodes to show')
          : Container(
              decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
              child: Column(
                children: [
                  for (var i = 0; i < nodes.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: c.line),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nodes[i].label, style: ts.strong, overflow: TextOverflow.ellipsis),
                                Text(nodes[i].url.replaceFirst(RegExp('^https?://'), ''), style: ts.mono(size: Fs.xs, color: c.faint), overflow: TextOverflow.ellipsis),
                                if (nodes[i].operator != null) Text('Run by ${nodes[i].operator}', style: ts.caption),
                              ],
                            ),
                          ),
                          const SizedBox(width: Sp.x3),
                          HealthLine(nodes[i].health, latencyMs: nodes[i].latencyMs),
                          const SizedBox(width: Sp.x3),
                          nodes[i].url == current
                              ? const ETag('In use', tone: ETone.gold)
                              : EButton(
                                  label: 'Use',
                                  size: EBtnSize.inline,
                                  onPressed: nodes[i].health == ServiceHealth.down
                                      ? null
                                      : () async {
                                          await ref.read(deskProvider.notifier).useNode(nodes[i].url);
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
      actions: [EButton(label: 'Close', size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop())],
    );
  }
}

// ---- Public mode ---------------------------------------------------------------------------

Future<void> showPublicModeDialog(BuildContext context) =>
    showEDialog(context, builder: (_) => const PublicModeDialog());

class PublicModeDialog extends ConsumerStatefulWidget {
  const PublicModeDialog({super.key});

  @override
  ConsumerState<PublicModeDialog> createState() => _PublicModeDialogState();
}

class _PublicModeDialogState extends ConsumerState<PublicModeDialog> {
  late bool _public = ref.read(deskProvider).settings.publicMode;
  bool _busy = false;

  Future<void> _apply() async {
    setState(() => _busy = true);
    final n = ref.read(deskProvider.notifier);
    await n.saveSettings(ref.read(deskProvider).settings.copyWith(publicMode: _public));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return EDialog(
      title: 'Receive from the internet',
      description: 'A sender reaches the router; the router forwards port 3415 to this computer.',
      icon: EIcons.web,
      width: 560,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EChoiceCard(
            title: 'Local only',
            description: 'Only programs on this computer reach the HTTP address. Safe default.',
            icon: EIcons.lock,
            selected: !_public,
            onTap: () => setState(() => _public = false),
          ),
          const SizedBox(height: Sp.x3),
          EChoiceCard(
            title: 'Public',
            description: 'Other devices and the internet reach it once the router forwards TCP 3415.',
            icon: EIcons.web,
            selected: _public,
            onTap: () => setState(() => _public = true),
          ),
          if (_public) ...[
            const SizedBox(height: Sp.x4),
            const ENotice(
              title: 'Forward the port',
              text: 'Open the router page, find Port forwarding and forward TCP 3415 to this computer. Plain HTTP is not encrypted; Tor is.',
              tone: ETone.warn,
            ),
          ],
          const SizedBox(height: Sp.x3),
          Text('Only the receiving API is exposed. The wallet owner API stays on this computer.', style: context.ts.small.copyWith(color: c.faint)),
        ],
      ),
      actions: [
        EButton(label: 'Cancel', size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop()),
        EButton.primary(label: 'Apply', size: EBtnSize.sm, busy: _busy, onPressed: _apply),
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
    return EDialog(
      title: 'Change password',
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
          const SizedBox(height: Sp.x4),
          EField(label: 'New password', error: _nextError, child: EPasswordInput(controller: _next, invalid: _nextError != null)),
          const SizedBox(height: Sp.x4),
          EField(
            label: 'Repeat new password',
            error: _repeatError,
            child: EPasswordInput(controller: _repeat, invalid: _repeatError != null, onSubmitted: (_) => _save()),
          ),
        ],
      ),
      actions: [
        EButton(label: 'Cancel', size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop()),
        EButton.primary(label: 'Change password', size: EBtnSize.sm, busy: _busy, onPressed: _save),
      ],
    );
  }
}

// ---- Remove wallet -------------------------------------------------------------------------

Future<void> showRemoveWalletDialog(BuildContext context) =>
    showEDialog(context, builder: (_) => const RemoveWalletDialog());

class RemoveWalletDialog extends ConsumerStatefulWidget {
  const RemoveWalletDialog({super.key});

  @override
  ConsumerState<RemoveWalletDialog> createState() => _RemoveWalletDialogState();
}

class _RemoveWalletDialogState extends ConsumerState<RemoveWalletDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _confirmed = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _remove() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter the password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(deskApiProvider).removeWallet(_password.text);
      if (!mounted) return;
      final nav = ref.read(deskNavProvider.notifier);
      Navigator.of(context).pop();
      nav.reset(DeskRoute.welcome);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Wrong password.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(deskProvider.select((s) => s.account?.name)) ?? 'this wallet';
    return EDialog(
      title: 'Remove $name?',
      description: 'The wallet is deleted from this computer. Coins are not lost: the recovery phrase restores them.',
      icon: EIcons.trash,
      tone: ETone.risk,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ENotice(
            title: 'Without the phrase, the coins are gone',
            text: 'Check that the recovery phrase is written down before removing.',
            tone: ETone.risk,
          ),
          const SizedBox(height: Sp.x4),
          ECheckbox(value: _confirmed, onChanged: (v) => setState(() => _confirmed = v), label: 'The recovery phrase is written down'),
          const SizedBox(height: Sp.x4),
          EField(
            label: 'Password',
            error: _error,
            child: EPasswordInput(controller: _password, invalid: _error != null, onChanged: (_) => setState(() => _error = null), onSubmitted: (_) => _confirmed ? _remove() : null),
          ),
        ],
      ),
      actions: [
        EButton(label: 'Keep wallet', size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop()),
        EButton(label: 'Remove wallet', size: EBtnSize.sm, kind: EBtnKind.danger, busy: _busy, onPressed: _confirmed ? _remove : null),
      ],
    );
  }
}
