// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/desk_errors.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// The wallets whose password can open the address book for the open wallet: the others of
/// its network, whose folder is there.
List<WalletEntry> contactsJoinCandidates(List<WalletEntry>? all, String? openId) {
  if (all == null) return const [];
  final network = all.where((w) => w.id == openId).firstOrNull?.network;
  return [for (final w in all) if (w.id != openId && !w.missing && (network == null || w.network == network)) w];
}

/// Opens the address book for the open wallet with another wallet's password. True: it is open.
Future<bool?> showContactsJoinDialog(BuildContext context, List<WalletEntry> wallets) =>
    showEDialog<bool>(context, builder: (_) => ContactsJoinDialog(wallets: wallets));

class ContactsJoinDialog extends ConsumerStatefulWidget {
  const ContactsJoinDialog({super.key, required this.wallets});

  final List<WalletEntry> wallets;

  @override
  ConsumerState<ContactsJoinDialog> createState() => _ContactsJoinDialogState();
}

class _ContactsJoinDialogState extends ConsumerState<ContactsJoinDialog> {
  final _password = TextEditingController();
  late String _id = widget.wallets.first.id;
  bool _busy = false;
  bool _wrong = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  bool get _valid => _password.text.isNotEmpty;

  Future<void> _join() async {
    if (!_valid || _busy) return;
    final l = context.l10n;
    setState(() {
      _busy = true;
      _wrong = false;
      _error = null;
    });
    try {
      final ok = await ref.read(deskApiProvider).joinContactsBook(_id, _password.text);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _busy = false;
          _wrong = true;
        });
        return;
      }
      await ref.read(deskProvider.notifier).refresh();
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showEToast(context, l.deskConJoinDone, tone: ETone.ok);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = deskErrorText(e, l);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final one = widget.wallets.length == 1;
    return PopScope(
      canPop: !_busy,
      child: EDialog(
        title: l.deskConJoinButton,
        dismissible: !_busy,
        description: l.deskConJoinDesc,
        icon: EIcons.lock,
        body: EForm(
          onSubmit: _busy || !_valid ? null : _join,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EField(
                label: l.deskConJoinWallet,
                child: one
                    ? Text(widget.wallets.first.name, style: ts.body)
                    : ESelect<String>(
                        semanticLabel: l.deskConJoinWallet,
                        value: _id,
                        onChanged: _busy
                            ? (_) {}
                            : (id) => setState(() {
                                _id = id;
                                _wrong = false;
                                _error = null;
                              }),
                        items: [for (final w in widget.wallets) ESelectItem(w.id, w.name)],
                      ),
              ),
              SizedBox(height: Sp.x4),
              EField(
                label: l.deskConJoinPassword,
                error: _wrong ? l.deskErrWrongPassword : null,
                reserveError: true,
                child: EPasswordInput(
                  controller: _password,
                  autofocus: true,
                  invalid: _wrong,
                  semanticLabel: l.deskConJoinPassword,
                  onChanged: (_) => setState(() {
                    _wrong = false;
                    _error = null;
                  }),
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: Sp.x3),
                Semantics(liveRegion: true, child: Text(_error!, style: ts.small.copyWith(color: c.risk))),
              ],
            ],
          ),
        ),
        actions: [
          EButton(label: l.commonCancel, tabStop: false, onPressed: _busy ? null : () => Navigator.of(context).pop()),
          EButton.primary(label: l.deskConJoinButton, busy: _busy, onPressed: _valid ? _join : null),
        ],
      ),
    );
  }
}
