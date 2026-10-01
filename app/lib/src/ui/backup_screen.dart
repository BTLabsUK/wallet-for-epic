import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../secure_screen.dart';
import 'common.dart';
import 'pin.dart';

/// Whether the open wallet's recovery phrase has been written down.
final backedUpProvider = FutureProvider.autoDispose<bool>((ref) {
  final config = ref.watch(walletConfigProvider);
  if (config == null) return true;
  return ref.watch(vaultProvider).isBackedUp(config.chain);
});

/// Shows the recovery phrase after the PIN. "Done" marks it backed up and pops true.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  List<String> _words = const [];
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
    super.dispose();
  }

  Future<void> _load() async {
    final l = context.l10n;
    final password = await askWalletPassword(
      context,
      reason: l.backupPinReason,
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
      if (!mounted) return;
      setState(() => _words = phrase.split(' '));
    } catch (error) {
      if (mounted) setState(() => _error = describeError(l, error));
    }
  }

  Future<void> _done() async {
    final config = ref.read(walletConfigProvider);
    if (config != null) {
      await ref.read(vaultProvider).markBackedUp(config.chain);
    }
    ref.invalidate(backedUpProvider);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return SlotScaffold(
      appBar: AppBar(title: Text(context.l10n.backupTitle)),
      body: ScreenBody(
        children: _words.isEmpty
            ? [
                if (_error != null)
                  ErrorText(_error!)
                else
                  const LinearProgressIndicator(),
              ]
            : _phrase(context),
      ),
    );
  }

  List<Widget> _phrase(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
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
                semanticLabel: l.backupWarningIconLabel,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.backupWriteDown(_words.length),
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
              // The words are BIP39 English in every language: never translated.
              for (var i = 0; i < _words.length; i++)
                Semantics(
                  label: l.backupWordSpoken(i + 1, _words[i]),
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
      BusyButton(label: l.commonDone, onPressed: _done),
    ];
  }
}
