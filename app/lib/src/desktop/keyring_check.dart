// SPDX-License-Identifier: Apache-2.0
/// Linux: the Secret Service (gnome-keyring, KWallet) holds the app's settings and the wallet's
/// sealed password. libsecret blocks the window's thread while it waits for a keyring that is
/// missing or must first be made, so the window never showed (linux-01). Before the first
/// read the app asks the service itself over D-Bus, on a connection of its own and with a time
/// limit, and starts on [KeyringScreen] when there is no keyring to use.
library;

import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter/material.dart';

import '../l10n.dart';
import '../log.dart';
import 'theme/theme.dart';
import '../ui/more_below.dart';

enum KeyringProblem {
  /// No Secret Service on the session bus, no default keyring, or no answer in time.
  missing,

  /// The default keyring is there but locked.
  locked,
}

/// Asks the Secret Service whether the default keyring is locked. Throws when there is no
/// session bus, no Secret Service or no default keyring. Tests give their own.
typedef KeyringRunner = Future<bool> Function();

const _service = 'org.freedesktop.Secret.Service';
const _collection = 'org.freedesktop.Secret.Collection';

/// The default keyring's `Locked` flag, over one connection to the session bus.
///
/// gnome-keyring registers a caller as a client from an idle callback queued by its message
/// filter, and the method that serves the call can run before it (gnome-keyring 48.0,
/// gkd-secret-service.c). A call that needs the client then fails an assertion, and a Get on a
/// collection ends in a GLib abort that kills the daemon. It shows when two callers talk to
/// the daemon at the same moment. So the first call is one that never needs the client (the
/// service's `Collections`), and its reply is the signal that the client exists; the alias and
/// the collection are asked after it. OpenSession first does not help: it needs the client too.
Future<bool> _askSecretService() async {
  final bus = DBusClient.session(introspectable: false);
  try {
    final service = DBusRemoteObject(
      bus,
      name: 'org.freedesktop.secrets',
      path: DBusObjectPath('/org/freedesktop/secrets'),
    );
    await service.getProperty(_service, 'Collections');
    final alias = await service.callMethod(
      _service,
      'ReadAlias',
      [DBusString('default')],
      replySignature: DBusSignature('o'),
    );
    final path = alias.returnValues.first.asObjectPath();
    if (path.value == '/') throw StateError('no default keyring');
    final collection = DBusRemoteObject(bus, name: 'org.freedesktop.secrets', path: path);
    return (await collection.getProperty(_collection, 'Locked', signature: DBusSignature('b'))).asBoolean();
  } finally {
    // The daemon forgets its client for this connection when it closes.
    unawaited(bus.close().catchError((_) {}));
  }
}

/// What is wrong with the default keyring, or null when it can be used or this cannot be told
/// (not Linux): the app then starts as before.
Future<KeyringProblem?> checkLinuxKeyring({
  KeyringRunner? run,
  Duration timeout = const Duration(seconds: 5),
  bool? linux,
}) async {
  if (!(linux ?? Platform.isLinux)) return null;
  try {
    final locked = await (run ?? _askSecretService)().timeout(timeout);
    if (!locked) return null;
    logWarn('desk', 'keyring locked');
    return KeyringProblem.locked;
  } on TimeoutException {
    logWarn('desk', 'keyring: the Secret Service did not answer in time');
  } catch (e) {
    logWarn('desk', 'keyring missing: $e');
  }
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
    scrollBehavior: const MoreBelowScrollBehavior(),
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildDeskTheme(Brightness.dark),
    home: KeyringScreen(problem: problem, check: check, onReady: onReady),
  );
}
