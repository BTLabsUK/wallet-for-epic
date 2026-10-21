import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'onboarding_parts.dart';

/// Opens the app. [arg] `'error'` starts with the wrong-password message.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _password = TextEditingController();
  List<WalletEntry>? _wallets;
  String? _folder;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.arg == 'error') {
      _error = 'Wrong password. Check Caps Lock and the keyboard layout.';
      _password.text = 'secret';
    }
    ref.read(deskApiProvider).wallets().then((w) {
      if (!mounted) return;
      setState(() {
        _wallets = w;
        _folder = w.where((e) => e.current).firstOrNull?.folder ?? w.firstOrNull?.folder;
      });
    });
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_busy) return;
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter the password');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref.read(deskApiProvider).unlock(_password.text);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = 'Wrong password. Check Caps Lock and the keyboard layout.';
      });
      return;
    }
    await ref.read(deskProvider.notifier).refresh();
    ref.read(deskNavProvider.notifier).reset(DeskRoute.overview);
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.read(deskNavProvider.notifier);
    final wallets = _wallets;
    return EHeroScreen(
      footer: const AuthFoot(),
      child: EAuthCard(
        title: 'Unlock wallet',
        lead: 'Keys stay on this computer.',
        alternatives: [
          ELink(label: 'Other wallet', dim: true, onPressed: () => nav.go(DeskRoute.found)),
          ELink(label: 'New or restore', dim: true, onPressed: () => nav.go(DeskRoute.welcome)),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wallets != null && wallets.length > 1) ...[
              EField(
                label: 'Wallet',
                child: ESelect<String>(
                  semanticLabel: 'Wallet',
                  value: _folder ?? wallets.first.folder,
                  onChanged: _busy ? (_) {} : (v) => setState(() => _folder = v),
                  items: [
                    for (final w in wallets) ESelectItem(w.folder, w.name, subtitle: w.folder),
                  ],
                ),
              ),
              const SizedBox(height: Sp.x5),
            ] else if (wallets == null)
              const Padding(
                padding: EdgeInsets.only(bottom: Sp.x5),
                child: Align(alignment: Alignment.centerLeft, child: ESpinner()),
              ),
            EField(
              label: 'Password',
              error: _error,
              child: EPasswordInput(
                controller: _password,
                autofocus: true,
                invalid: _error != null,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _unlock(),
              ),
            ),
            const SizedBox(height: Sp.x6),
            EButton.primary(label: 'Unlock', icon: EIcons.lockOpen, expand: true, busy: _busy, onPressed: _unlock),
          ],
        ),
      ),
    );
  }
}
