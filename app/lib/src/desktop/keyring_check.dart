// SPDX-License-Identifier: Apache-2.0
/// Linux: the Secret Service (gnome-keyring, KWallet) holds the app's settings and the wallet's
/// sealed password. libsecret blocks the window's thread while it waits for a keyring that is
/// missing or must first be made, so the window never showed (linux-01). Before the first
/// read the app asks the service itself over D-Bus, in another process and with a time limit,
/// and starts on [KeyringScreen] when there is no keyring to use.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../log.dart';
import 'theme/theme.dart';

enum KeyringProblem {
  /// No Secret Service on the session bus, no default keyring, or no answer in time.
  missing,

  /// The default keyring is there but locked.
  locked,
}

/// Runs a command; the result's exit code and output. Tests give their own.
typedef KeyringRunner = Future<ProcessResult> Function(String executable, List<String> arguments);

const _query = [
  '--session',
  '--print-reply=literal',
  '--reply-timeout=3000',
  '--dest=org.freedesktop.secrets',
  '/org/freedesktop/secrets/aliases/default',
  'org.freedesktop.DBus.Properties.Get',
  'string:org.freedesktop.Secret.Collection',
  'string:Locked',
];

/// What is wrong with the default keyring, or null when it can be used or this cannot be told
/// (not Linux, no `dbus-send`): the app then starts as before.
Future<KeyringProblem?> checkLinuxKeyring({
  KeyringRunner? run,
  Duration timeout = const Duration(seconds: 5),
  bool? linux,
}) async {
  if (!(linux ?? Platform.isLinux)) return null;
  final ProcessResult r;
  try {
    r = await (run ?? Process.run)('dbus-send', _query).timeout(timeout);
  } on TimeoutException {
    logWarn('desk', 'keyring: the Secret Service did not answer in time');
    return KeyringProblem.missing;
  } on ProcessException {
    // No dbus-send here: nothing can be told, so libsecret is asked as before.
    return null;
  }
  final problem = keyringProblemOf(r.exitCode, '${r.stdout}');
  if (problem != null) {
    logWarn('desk', 'keyring ${problem.name}: ${'${r.stderr}${r.stdout}'.trim().split('\n').first}');
  }
  return problem;
}

/// `dbus-send`'s answer about the default keyring's `Locked` property.
KeyringProblem? keyringProblemOf(int exitCode, String stdout) {
  if (exitCode != 0) return KeyringProblem.missing;
  if (stdout.contains('boolean true')) return KeyringProblem.locked;
  if (stdout.contains('boolean false')) return null;
  return KeyringProblem.missing;
}

/// The first screen while there is no keyring to use: what is missing and what to do. Try
/// again asks once more; [onReady] starts the app once the keyring can be used, and, for a
/// locked keyring, when the user goes on anyway (the system then asks to unlock it).
class KeyringScreen extends StatefulWidget {
  const KeyringScreen({super.key, required this.problem, required this.check, required this.onReady});

  final KeyringProblem problem;
  final Future<KeyringProblem?> Function() check;
  final VoidCallback onReady;

  @override
  State<KeyringScreen> createState() => _KeyringScreenState();
}

class _KeyringScreenState extends State<KeyringScreen> {
  late KeyringProblem _problem = widget.problem;
  bool _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    final p = await widget.check();
    if (!mounted) return;
    if (p == null) return widget.onReady();
    setState(() {
      _busy = false;
      _problem = p;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final locked = _problem == KeyringProblem.locked;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(locked ? Icons.lock_outline : Icons.key_off_outlined, size: 40, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  locked ? l.deskKeyringLockedTitle : l.deskKeyringMissingTitle,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(locked ? l.deskKeyringLockedText : l.deskKeyringMissingText, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton(onPressed: _busy ? null : _retry, child: Text(l.commonRetry)),
                    if (locked)
                      TextButton(onPressed: _busy ? null : widget.onReady, child: Text(l.deskKeyringUnlockNow)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [KeyringScreen] as the whole app, in the system's language and the desktop's dark theme.
class KeyringApp extends StatelessWidget {
  const KeyringApp({super.key, required this.problem, required this.check, required this.onReady});

  final KeyringProblem problem;
  final Future<KeyringProblem?> Function() check;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildDeskTheme(Brightness.dark),
    home: KeyringScreen(problem: problem, check: check, onReady: onReady),
  );
}
