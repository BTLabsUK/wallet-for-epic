// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../providers.dart';
import 'common.dart';
import 'pin.dart';
import '../phrase_clipboard.dart';
import '../secure_screen.dart' show hidePreview;

/// Whether the open wallet's recovery phrase has been written down.
final backedUpProvider = FutureProvider.autoDispose<bool>((ref) {
  final config = ref.watch(walletConfigProvider);
  if (config == null) return true;
  return ref.watch(vaultProvider).isBackedUp(config.chain);
});

/// Shows the recovery phrase once the user has agreed to keep any copy private and entered the
/// PIN. Screenshots and Copy are allowed, since a phrase people cannot copy is a phrase they do
/// not back up; Copy warns first and clears the clipboard after 60 s and on lock ([copyRecoveryPhrase]).
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
    if (_previewHidden) unawaited(hidePreview(false));
    super.dispose();
  }

  /// The app switcher shows no preview while the words are on screen; screenshots stay allowed.
  bool _previewHidden = false;

  Future<void> _load() async {
    setState(() => _asked = true);
    final l = context.l10n;
    final session = ref.read(sessionProvider);
    final config = ref.read(walletConfigProvider);
    if (session == null || config == null) return;
    final vault = ref.read(vaultProvider);
    final phrase = await askPin(
      context,
      reason: usesPassphrase(ref) ? l.backupPassphraseReason : l.backupPinReason,
      action: (pin) => vault.mnemonic(session, config, pin),
    );
    if (!mounted) return;
    if (phrase == null) {
      Navigator.pop(context, false);
      return;
    }
    _previewHidden = true;
    unawaited(hidePreview(true));
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
            // The PIN dialog is the whole state: no progress line behind it (UP-031).
            : _words.isEmpty
            ? const []
            : _phrase(context),
      ),
    );
  }

  /// What a copy of the phrase means, agreed to before the PIN.
  List<Widget> _consent(BuildContext context) {
    final l = context.l10n;
    return [
      InlineNotice(
        level: NoticeLevel.warning,
        title: l.backupConsentTitle,
        text: '${l.backupConsentWhat} ${l.backupConsentReady}\n\n${l.backupCopyWarning}',
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
      InlineNotice(level: NoticeLevel.warning, text: l.backupWriteDown(_words.length)),
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

/// Copies the recovery phrase, cleared after [phraseClipboardLifetime] and on lock, as on the
/// desktop. False when the clipboard refused the text.
Future<bool> copyRecoveryPhrase(String phrase) => copyPhraseToClipboard(phrase);
