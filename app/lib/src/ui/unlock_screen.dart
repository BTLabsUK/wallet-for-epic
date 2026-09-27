import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../network.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'common.dart';

/// Opens the existing wallet of the chosen network with its password.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _password = TextEditingController();
  String? _passwordError;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    if (_password.text.isEmpty) {
      setState(() => _passwordError = 'Enter your password.');
      return;
    }
    setState(() {
      _busy = true;
      _passwordError = null;
      _error = null;
    });
    try {
      final session = await ref
          .read(walletServiceProvider)
          .open(config: config, password: _password.text);
      ref.read(sessionProvider.notifier).unlocked(session);
      if (mounted) goHome(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (error is WalletError &&
            error.kind == WalletErrorKind.wrongPassword) {
          _passwordError = describeError(error);
          _password.clear();
        } else {
          _error = describeError(error);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(walletConfigProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          config == null
              ? 'Unlock'
              : 'Unlock ${chainLabel(config.chain)} wallet',
        ),
      ),
      body: ScreenBody(
        children: [
          PasswordField(
            controller: _password,
            label: 'Password',
            errorText: _passwordError,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _unlock(),
          ),
          const SizedBox(height: 16),
          if (_error != null) ErrorText(_error!),
          BusyButton(label: 'Unlock', busy: _busy, onPressed: _unlock),
        ],
      ),
    );
  }
}
