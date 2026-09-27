import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../providers.dart';
import '../secure_screen.dart';
import 'common.dart';

/// Words in a newly generated recovery phrase.
const int newPhraseWords = 24;

/// Words the user must re-enter to prove they wrote the phrase down.
const int confirmWordCount = 3;

/// Minimum password length for a new wallet.
const int minPasswordLength = 8;

/// Returns an error sentence for a new password pair, or null when acceptable.
String? checkNewPassword(String password, String repeat) {
  if (password.length < minPasswordLength) {
    return 'Use at least $minPasswordLength characters.';
  }
  if (password != repeat) return 'The passwords do not match.';
  return null;
}

enum _Step { showPhrase, confirmPhrase, password }

/// Creates a wallet: show the phrase once, confirm three words, set a password.
class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  List<String> _words = const [];
  List<int> _confirmIndexes = const [];
  String? _generateError;
  final _confirmControllers = List.generate(
    confirmWordCount,
    (_) => TextEditingController(),
  );
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  _Step _step = _Step.showPhrase;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    try {
      final phrase = ref
          .read(walletServiceProvider)
          .generateMnemonic(wordCount: newPhraseWords);
      _words = phrase.split(' ');
    } catch (error) {
      _generateError = describeError(error);
      return;
    }
    final indexes = List.generate(_words.length, (i) => i)
      ..shuffle(Random.secure());
    _confirmIndexes = indexes.take(confirmWordCount).toList()..sort();
    setSecureScreen(true);
  }

  @override
  void dispose() {
    setSecureScreen(false);
    for (final controller in _confirmControllers) {
      controller.dispose();
    }
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _goTo(_Step step) {
    setSecureScreen(step != _Step.password);
    setState(() {
      _step = step;
      _error = null;
    });
  }

  void _checkWords() {
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
    for (final controller in _confirmControllers) {
      controller.clear();
    }
    _goTo(_Step.password);
  }

  Future<void> _create() async {
    final problem = checkNewPassword(_password.text, _repeat.text);
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
      final session = await ref
          .read(walletServiceProvider)
          .create(
            config: config,
            mnemonic: _words.join(' '),
            password: _password.text,
          );
      ref.read(sessionProvider.notifier).unlocked(session);
      if (mounted) goHome(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = describeError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create wallet')),
      body: ScreenBody(
        children: _generateError != null
            ? [ErrorText(_generateError!)]
            : switch (_step) {
                _Step.showPhrase => _phraseStep(context),
                _Step.confirmPhrase => _confirmStep(context),
                _Step.password => _passwordStep(context),
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
                  'only way to recover this wallet. They are shown only once.',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < _words.length; i++)
            Semantics(
              label: 'Word ${i + 1}: ${_words[i]}',
              excludeSemantics: true,
              child: Container(
                width: 132,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${i + 1}. ${_words[i]}',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
        ],
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

  List<Widget> _passwordStep(BuildContext context) {
    return [
      Text(
        'Set a password. You need it to open the wallet on this device.',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 16),
      PasswordField(
        controller: _password,
        label: 'Password',
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 12),
      PasswordField(
        controller: _repeat,
        label: 'Repeat password',
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _create(),
      ),
      const SizedBox(height: 16),
      if (_error != null) ErrorText(_error!),
      BusyButton(label: 'Create wallet', busy: _busy, onPressed: _create),
    ];
  }
}
