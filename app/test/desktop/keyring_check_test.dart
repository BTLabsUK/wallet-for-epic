// SPDX-License-Identifier: Apache-2.0
// linux-01: without a usable keyring the desktop app starts on a screen that says what is
// missing, instead of a window that never shows (libsecret held its thread) or a bogus
// "Unlock wallet … Something went wrong". The check asks the Secret Service over D-Bus on a
// connection of its own, with a time limit.
import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:epic_wallet/src/desktop/keyring_check.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

KeyringRunner _locked(bool locked) => () async => locked;

KeyringRunner _fails(Object error) => () async => throw error;

void main() {
  group('the Secret Service answer', () {
    test('an unlocked default keyring: nothing to say', () async {
      expect(await checkLinuxKeyring(linux: true, run: _locked(false)), isNull);
    });

    test('a locked one', () async {
      expect(await checkLinuxKeyring(linux: true, run: _locked(true)), KeyringProblem.locked);
    });

    test('no session bus, no Secret Service, or no default keyring: missing', () async {
      for (final error in [
        const SocketException('Connection refused'),
        DBusServiceUnknownException(
          DBusMethodErrorResponse('org.freedesktop.DBus.Error.ServiceUnknown', [DBusString('no secrets')]),
        ),
        DBusUnknownObjectException(
          DBusMethodErrorResponse('org.freedesktop.DBus.Error.UnknownObject', [DBusString('no collection')]),
        ),
        StateError('no default keyring'),
      ]) {
        expect(await checkLinuxKeyring(linux: true, run: _fails(error)), KeyringProblem.missing, reason: '$error');
      }
    });

    test('a service that does not answer in time is missing, and the start goes on', () async {
      final never = Completer<bool>();
      expect(
        await checkLinuxKeyring(linux: true, run: () => never.future, timeout: const Duration(milliseconds: 20)),
        KeyringProblem.missing,
      );
    });

    test('not Linux: cannot tell, the app starts as before', () async {
      expect(await checkLinuxKeyring(linux: false, run: _locked(true)), isNull);
    });
  });

  group('the first screen', () {
    Future<void> show(WidgetTester tester, KeyringProblem p, Future<KeyringProblem?> Function() check, VoidCallback onReady) =>
        tester.pumpWidget(KeyringApp(problem: p, check: check, onReady: onReady));

    testWidgets('missing: says so; Retry starts the app once the keyring answers', (tester) async {
      var ready = 0;
      KeyringProblem? next = KeyringProblem.missing;
      await show(tester, KeyringProblem.missing, () async => next, () => ready++);
      final l = lookupAppLocalizations(const Locale('en'));
      expect(find.text(l.deskKeyringMissingTitle), findsOneWidget);
      expect(find.text(l.deskKeyringUnlockNow), findsNothing);
      await tester.tap(find.text(l.commonRetry));
      await tester.pump();
      expect(ready, 0);
      next = null;
      await tester.tap(find.text(l.commonRetry));
      await tester.pump();
      expect(ready, 1);
    });

    testWidgets('locked: Unlock now goes on, so the system asks for the password', (tester) async {
      var ready = 0;
      await show(tester, KeyringProblem.locked, () async => KeyringProblem.locked, () => ready++);
      final l = lookupAppLocalizations(const Locale('en'));
      expect(find.text(l.deskKeyringLockedTitle), findsOneWidget);
      await tester.tap(find.text(l.deskKeyringUnlockNow));
      await tester.pump();
      expect(ready, 1);
    });
  });
}
