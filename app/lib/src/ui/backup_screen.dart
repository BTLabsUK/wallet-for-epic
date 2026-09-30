import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../providers.dart';
import '../secure_screen.dart';
import 'common.dart';
import 'pin.dart';

/// Words the user must re-enter to prove they wrote the phrase down.
const int confirmWordCount = 3;

/// Whether the open wallet's recovery phrase has been written down.
final backedUpProvider = FutureProvider.autoDispose<bool>((ref) {
  final config = ref.watch(walletConfigProvider);
  if (config == null) return true;
  return ref.watch(vaultProvider).isBackedUp(config.chain);
});

enum _Step { showPhrase, confirmPhrase }

/// Shows the recovery phrase after the PIN, then checks three words. Pops true when done.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  List<String> _words = const [];
  List<int> _confirmIndexes = const [];
  final _confirmControllers = List.generate(
    confirmWordCount,
    (_) => TextEditingController(),
  );
  _Step _step = _Step.showPhrase;
  String? _error;

  @override
  void initState() {
    super.initState();
    setSecureScreen(true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    setSecureScreen(false);
    for (final controller in _confirmControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final password = await askWalletPassword(
      context,
      reason: 'Enter your PIN to show the recovery phrase.',
    );
    if (!mounted) return;
    if (password == null) {
      Navigator.pop(context, false);
      return;
    }
    final session = ref.read(sessionProvider);
    if (session == null) return;
    try {
      final phrase = await session.mnemonic(password: password);
      final words = phrase.split(' ');
      final indexes = List.generate(words.length, (i) => i)
        ..shuffle(Random.secure());
      if (!mounted) return;
      setState(() {
        _words = words;
        _confirmIndexes = indexes.take(confirmWordCount).toList()..sort();
      });
    } catch (error) {
      if (mounted) setState(() => _error = describeError(error));
    }
  }

  Future<void> _checkWords() async {
    for (var i = 0; i < confirmWordCount; i++) {
      final entered = _confirmControllers[i].text.trim().toLowerCase();
      if (entered != _words[_confirmIndexes[i]]) {
        setState(
          () => _error =
              'One or more words do not match. Check your written copy.',
        );
        return;
      }
    }
    final config = ref.read(walletConfigProvider);
    if (config != null) {
      await ref.read(vaultProvider).markBackedUp(config.chain);
    }
    ref.invalidate(backedUpProvider);
    if (mounted) Navigator.pop(context, true);
  }

  void _goTo(_Step step) => setState(() {
    _step = step;
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recovery phrase')),
      body: ScreenBody(
        children: _words.isEmpty
            ? [
                if (_error != null)
                  ErrorText(_error!)
                else
                  const LinearProgressIndicator(),
              ]
            : switch (_step) {
                _Step.showPhrase => _phraseStep(context),
                _Step.confirmPhrase => _confirmStep(context),
              },
      ),
    );
  }

  List<Widget> _phraseStep(BuildContext context) {
    final theme = Theme.of(context);
    return [
      Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber,
                color: theme.colorScheme.onErrorContainer,
                semanticLabel: 'Warning',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Write these ${_words.length} words on paper, in order. '
                  'Anyone who has them can take your funds, and they are the '
                  'only way to recover this wallet if this device is lost.',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          // Three columns on a phone, two on narrow screens; the words fill the width.
          final columns = constraints.maxWidth >= 330 ? 3 : 2;
          final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _words.length; i++)
                Semantics(
                  label: 'Word ${i + 1}: ${_words[i]}',
                  excludeSemantics: true,
                  child: Container(
                    width: width,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // Long words shrink instead of being cut off.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${i + 1}. ${_words[i]}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      BusyButton(
        label: 'I have written them down',
        onPressed: () => _goTo(_Step.confirmPhrase),
      ),
    ];
  }

  List<Widget> _confirmStep(BuildContext context) {
    return [
      Text(
        'Enter these words from your phrase to confirm you wrote it down.',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 16),
      for (var i = 0; i < confirmWordCount; i++) ...[
        TextField(
          key: ValueKey('confirm-word-${_confirmIndexes[i]}'),
          controller: _confirmControllers[i],
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: i == confirmWordCount - 1
              ? TextInputAction.done
              : TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Word ${_confirmIndexes[i] + 1}',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (_error != null) ErrorText(_error!),
      BusyButton(label: 'Confirm', onPressed: _checkWords),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => _goTo(_Step.showPhrase),
        child: const Text('Show the phrase again'),
      ),
    ];
  }
}
