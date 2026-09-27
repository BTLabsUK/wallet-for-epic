import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../providers.dart';
import '../secure_screen.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'pin.dart';

/// Lowercases the phrase and collapses whitespace, so pasted phrases validate.
String normalizePhrase(String input) =>
    input.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');

/// Restores a wallet from its recovery phrase, protects it with a PIN, then scans the chain.
///
/// A wallet the first run created in the meantime is deleted first: its phrase was never
/// shown, so it cannot hold funds.
class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

enum _RestoreStep { phrase, pin, scan }

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  final _phrase = TextEditingController();
  final _startHeight = TextEditingController();
  _RestoreStep _step = _RestoreStep.phrase;
  String _validPhrase = '';
  BigInt? _height;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    setSecureScreen(true);
  }

  @override
  void dispose() {
    setSecureScreen(false);
    _phrase.dispose();
    _startHeight.dispose();
    super.dispose();
  }

  void _checkPhrase() {
    final service = ref.read(walletServiceProvider);
    final phrase = normalizePhrase(_phrase.text);
    String? problem;
    if (!service.validateMnemonic(phrase: phrase)) {
      problem = describeError(
        const WalletError(kind: WalletErrorKind.invalidMnemonic, message: ''),
      );
    }
    final heightText = _startHeight.text.trim();
    final startHeight = heightText.isEmpty ? null : BigInt.tryParse(heightText);
    if (problem == null && heightText.isNotEmpty && startHeight == null) {
      problem = 'Start height must be a whole number.';
    }
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    _phrase.clear();
    setState(() {
      _validPhrase = phrase;
      _height = startHeight;
      _error = null;
      _step = _RestoreStep.pin;
    });
  }

  Future<void> _restore(String pin, bool useBiometrics) async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(walletSetupProvider.notifier).discard(config);
      final service = ref.read(walletServiceProvider);
      // A wallet still here after discard has a PIN or a password; never replace it.
      if (await service.walletExists(config: config)) {
        throw const WalletError(
          kind: WalletErrorKind.walletAlreadyExists,
          message: 'wallet exists',
        );
      }
      final vault = ref.read(vaultProvider);
      final password = await vault.pendingPassword(config.chain);
      final session = await service.create(
        config: config,
        mnemonic: _validPhrase,
        password: password,
      );
      _validPhrase = '';
      await vault.seal(
        config.chain,
        pin: pin,
        password: password,
        useBiometrics: useBiometrics,
      );
      // The user typed the phrase in, so they have it.
      await vault.markBackedUp(config.chain);
      ref.read(sessionProvider.notifier).unlocked(session);
      if (!mounted) return;
      setState(() => _step = _RestoreStep.scan);
      unawaited(setSecureScreen(false));
      final scanned = await ref
          .read(scanProvider.notifier)
          .run(startHeight: _height);
      if (scanned && mounted) goHome(context);
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restore wallet')),
      body: ScreenBody(
        children: switch (_step) {
          _RestoreStep.phrase => _form(context),
          _RestoreStep.pin => [
            if (_busy)
              const LinearProgressIndicator()
            else
              PinSetupView(onDone: _restore),
            if (_error != null) ...[
              ErrorText(_error!),
              TextButton(
                onPressed: () => setState(() {
                  _error = null;
                  _step = _RestoreStep.phrase;
                }),
                child: const Text('Back to the phrase'),
              ),
            ],
          ],
          _RestoreStep.scan => _scanView(context),
        },
      ),
    );
  }

  List<Widget> _form(BuildContext context) {
    return [
      TextField(
        controller: _phrase,
        minLines: 3,
        maxLines: 5,
        autocorrect: false,
        enableSuggestions: false,
        enableIMEPersonalizedLearning: false,
        keyboardType: TextInputType.visiblePassword,
        decoration: const InputDecoration(
          labelText: 'Recovery phrase',
          helperText: 'The 12 or 24 words, separated by spaces.',
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _startHeight,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          labelText: 'Start height (optional)',
          helperText:
              'Scan from this block. Leave empty to scan the whole chain.',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      if (_error != null) ErrorText(_error!),
      BusyButton(label: 'Continue', onPressed: _checkPhrase),
    ];
  }

  List<Widget> _scanView(BuildContext context) {
    final scan = ref.watch(scanProvider);
    return [
      Text(
        'Scanning the chain for your outputs',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 16),
      ScanProgressView(scan: scan),
      if (_error != null) ErrorText(_error!),
      if (!scan.running) ...[
        const SizedBox(height: 16),
        BusyButton(label: 'Open wallet', onPressed: () => goHome(context)),
        const SizedBox(height: 8),
        const Text('You can run a full rescan later from the wallet menu.'),
      ],
    ];
  }
}

/// Progress bar and latest message of a scan, or its error.
class ScanProgressView extends StatelessWidget {
  const ScanProgressView({super.key, required this.scan});

  final ScanState scan;

  @override
  Widget build(BuildContext context) {
    final percent = scan.percent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scan.running)
          LinearProgressIndicator(
            value: percent == null ? null : percent / 100,
            semanticsLabel: 'Scan progress',
            semanticsValue: percent == null ? null : '$percent percent',
          ),
        if (scan.message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              percent == null || !scan.running
                  ? scan.message!
                  : '${scan.message} ($percent%)',
            ),
          ),
        if (scan.error != null) ErrorText(scan.error!),
      ],
    );
  }
}
