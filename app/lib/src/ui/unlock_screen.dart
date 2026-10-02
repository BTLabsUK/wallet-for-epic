import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'centered_body.dart';
import 'common.dart';
import 'pin.dart';
import 'theme/brand.dart';

/// Opens a wallet made before PINs existed with its password, then moves it to a PIN.
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

  /// The checked password, kept until the new PIN seals it.
  String? _openedPassword;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    final l = context.l10n;
    if (_password.text.isEmpty) {
      setState(() => _passwordError = l.unlockPasswordEmpty);
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
      if (!mounted) return;
      setState(() {
        _busy = false;
        _openedPassword = _password.text;
      });
      _password.clear();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (error is WalletError &&
            error.kind == WalletErrorKind.wrongPassword) {
          _passwordError = describeError(l, error);
          _password.clear();
        } else {
          _error = describeError(l, error);
        }
      });
    }
  }

  Future<void> _setPin(String pin, bool useBiometrics) async {
    final config = ref.read(walletConfigProvider);
    final password = _openedPassword;
    if (config == null || password == null) return;
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      await ref
          .read(vaultProvider)
          .seal(
            config.chain,
            pin: pin,
            password: password,
            useBiometrics: useBiometrics,
          );
      // The user saw the phrase when they made this wallet.
      await ref.read(vaultProvider).markBackedUp(config.chain);
      _openedPassword = null;
      if (mounted) goHome(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(l, error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(walletConfigProvider);
    return SlotScaffold(
      centered: true,
      glow: heroGlow,
      appBar: AppBar(),
      body: CenteredBody(
        children: [
          BrandHero(
            title: config == null
                ? l.unlockTitle
                : '${l.unlockTitle}${networkSuffix(l, config.chain)}',
          ),
          const SizedBox(height: 28),
          ...(_openedPassword != null
              ? [
                  Text(l.unlockMovedToPin),
                  const SizedBox(height: 16),
                  if (_busy)
                    const LinearProgressIndicator()
                  else
                    PinSetupView(onDone: _setPin),
                  if (_error != null) ErrorText(_error!),
                ]
              : [
                  PasswordField(
                    controller: _password,
                    label: l.unlockPasswordLabel,
                    errorText: _passwordError,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _unlock(),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ErrorText(_error!),
                  BusyButton(
                    label: l.unlockButton,
                    busy: _busy,
                    onPressed: _unlock,
                  ),
                ]),
        ],
      ),
    );
  }
}
