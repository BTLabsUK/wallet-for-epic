import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../providers.dart';
import '../secure_screen.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'create_screen.dart' show checkNewPassword;

/// Lowercases the phrase and collapses whitespace, so pasted phrases validate.
String normalizePhrase(String input) =>
    input.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');

/// Restores a wallet from its recovery phrase, then scans the chain for its outputs.
class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  final _phrase = TextEditingController();
  final _startHeight = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _created = false;

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
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final service = ref.read(walletServiceProvider);
    final phrase = normalizePhrase(_phrase.text);
    String? problem;
    if (!service.validateMnemonic(phrase: phrase)) {
      problem = describeError(
        const WalletError(kind: WalletErrorKind.invalidMnemonic, message: ''),
      );
    } else {
      problem = checkNewPassword(_password.text, _repeat.text);
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
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await service.create(
        config: config,
        mnemonic: phrase,
        password: _password.text,
      );
      _phrase.clear();
      ref.read(sessionProvider.notifier).unlocked(session);
      if (!mounted) return;
      setState(() => _created = true);
      unawaited(setSecureScreen(false));
      final scanned = await ref
          .read(scanProvider.notifier)
          .run(startHeight: startHeight);
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
        children: _created ? _scanView(context) : _form(context),
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
      const SizedBox(height: 12),
      PasswordField(
        controller: _password,
        label: 'New password',
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 12),
      PasswordField(
        controller: _repeat,
        label: 'Repeat password',
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _restore(),
      ),
      const SizedBox(height: 16),
      if (_error != null) ErrorText(_error!),
      BusyButton(label: 'Restore', busy: _busy, onPressed: _restore),
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
