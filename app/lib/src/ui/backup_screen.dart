import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../providers.dart';
import 'common.dart';
import 'pin.dart';

/// Whether the open wallet's recovery phrase has been written down.
final backedUpProvider = FutureProvider.autoDispose<bool>((ref) {
  final config = ref.watch(walletConfigProvider);
  if (config == null) return true;
  return ref.watch(vaultProvider).isBackedUp(config.chain);
});

/// Shows the recovery phrase once the user has agreed to keep any copy private and entered the
/// PIN. Screenshots and Copy are allowed, since a phrase people cannot copy is a phrase they do
/// not back up; Copy warns first and clears the clipboard after 30 s ([copyRecoveryPhrase]).
/// "Done" marks it backed up and pops true.
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
  void dispose() {
    _words = const [];
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

  /// Asks before copying (anyone with the words can take the funds), then copies and says that
  /// the clipboard is cleared soon.
  Future<void> _copy() async {
    final l = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.backupCopyTitle),
        content: Text(l.backupCopyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.commonCopy),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final copied = await copyRecoveryPhrase(_words.join(' '));
    if (!mounted) return;
    ref
        .read(noticeProvider.notifier)
        .show(
          copied ? l.backupCopied : l.backupNotCopied,
          level: copied ? NoticeLevel.success : NoticeLevel.error,
        );
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
      const SizedBox(height: 16),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: _copy,
        icon: const Icon(Icons.copy),
        label: Text(l.commonCopy),
      ),
      const SizedBox(height: 16),
      BusyButton(label: l.commonDone, onPressed: _done),
    ];
  }
}

Timer? _clipboardTimer;

/// Copies the recovery phrase and clears the clipboard 30 s later if the phrase is still there
/// (as the desktop does). One timer for the app, outliving the screen. False when the clipboard
/// refused the text. Android 10+ lets an app read the clipboard only while it is in the
/// foreground: when the read finds nothing (the app is in the background), the clipboard is
/// cleared anyway, as the phrase may still be on it.
Future<bool> copyRecoveryPhrase(String phrase) async {
  try {
    await Clipboard.setData(ClipboardData(text: phrase));
  } on Object {
    return false;
  }
  _clipboardTimer?.cancel();
  _clipboardTimer = Timer(const Duration(seconds: 30), () async {
    try {
      final now = await Clipboard.getData(Clipboard.kTextPlain);
      if (now?.text == null || now!.text == phrase) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    } on Object {
      // Nothing more to do.
    }
  });
  return true;
}
