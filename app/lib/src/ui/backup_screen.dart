import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Shows the recovery phrase once the user has agreed to keep any copy private and entered the
/// PIN. Screenshots, screen recording and the app-switcher preview are blocked while it is open
/// ([setSecureScreen]); a screenshot often ends up in a cloud photo library. "Done" marks it
/// backed up and pops true.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  List<String> _words = const [];
  bool _agreed = false;
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    setSecureScreen(true);
  }

  @override
  void dispose() {
    setSecureScreen(false);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _asked = true);
    final l = context.l10n;
    final session = ref.read(sessionProvider);
    final config = ref.read(walletConfigProvider);
    if (session == null || config == null) return;
    final vault = ref.read(vaultProvider);
    final phrase = await askPin(
      context,
      reason: l.backupPinReason,
      action: (pin) => vault.mnemonic(session, config, pin),
    );
    if (!mounted) return;
    if (phrase == null) {
      Navigator.pop(context, false);
      return;
    }
    setState(() => _words = phrase.split(' '));
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
        children: !_asked
            ? _consent(context)
            : _words.isEmpty
            ? [const LinearProgressIndicator()]
            : _phrase(context),
      ),
    );
  }

  /// What a copy of the phrase means, agreed to before the PIN.
  List<Widget> _consent(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final onError = theme.colorScheme.onErrorContainer;
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
                color: onError,
                semanticLabel: l.backupWarningIconLabel,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.backupCopyWarning,
                  style: TextStyle(color: onError),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: _agreed,
        onChanged: (value) => setState(() => _agreed = value ?? false),
        title: Text(l.backupCopyAgree),
      ),
      const SizedBox(height: 16),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: _agreed ? _load : null,
        child: Text(l.backupShowPhrase),
      ),
    ];
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
