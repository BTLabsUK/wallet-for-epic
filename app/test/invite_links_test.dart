// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/invite_links.dart';
import 'package:epic_wallet/src/scan/incoming_link.dart';
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/settings_file/settings_layout.dart' show checkInvitePage;
import 'package:epic_wallet/src/ui/invite_link_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_settings.dart';

const _pairRest = '1/AbC_d-ef0123456789xyz';
const _pair = 'epiccash://pair/$_pairRest';
const _deviceRest = '1/aHR0cHM6Ly9leGFtcGxl/0123456789abcdef';
const _device = 'epiccash://device-link/$_deviceRest';
const _page = 'https://invite.example.org';

void main() {
  group('parseInvite', () {
    test('reads the bare invites of both kinds', () {
      expect(parseInvite(_pair), const InviteLink(InviteKind.pair, _pair));
      expect(parseInvite(_device), const InviteLink(InviteKind.deviceLink, _device));
      // Without the fingerprint (made before it existed).
      expect(parseInvite('epiccash://device-link/1/aHR0cA'), const InviteLink(InviteKind.deviceLink, 'epiccash://device-link/1/aHR0cA'));
    });

    test('reads the https link of any host, both kinds', () {
      expect(parseInvite('$_page/pair#$_pairRest'), const InviteLink(InviteKind.pair, _pair));
      expect(parseInvite('$_page/link#$_deviceRest'), const InviteLink(InviteKind.deviceLink, _device));
      expect(parseInvite('https://other.example.net/some/path/pair/#$_pairRest'), const InviteLink(InviteKind.pair, _pair));
    });

    test('leaves out the surrounding words and whitespace', () {
      expect(parseInvite('  Pair with me: $_pair  \n'), const InviteLink(InviteKind.pair, _pair));
      expect(parseInvite('Open $_page/pair#$_pairRest.'), const InviteLink(InviteKind.pair, _pair));
      expect(parseInvite('($_device)'), const InviteLink(InviteKind.deviceLink, _device));
      // A message with both forms: the first one.
      expect(parseInvite('$_page/link#$_deviceRest or $_pair')?.kind, InviteKind.deviceLink);
      // Any case of the scheme; the invite reads with the lower-case prefix.
      expect(parseInvite('EPICCASH://PAIR/$_pairRest'), const InviteLink(InviteKind.pair, _pair));
    });

    test('the fragment alone is no invite', () {
      expect(parseInvite('#$_pairRest'), isNull);
      expect(parseInvite(_pairRest), isNull);
      expect(parseInvite('$_page/pair'), isNull);
      expect(parseInvite('$_page/pair#'), isNull);
      expect(parseInvite('$_page/pair?$_pairRest'), isNull);
    });

    test('junk and other links are none', () {
      for (final text in [
        '',
        '   ',
        'hello',
        'epiccash://pair/',
        'epiccash://pair/1/',
        'epiccash://pair/abc',
        'epiccash://pair-reply/1/abc',
        'epiccash://contact/1/abc',
        'epic:esAbc@epicbox.example.org',
        'epiccash://device-link/1/abc/not-a-fingerprint',
        'epiccash://device-link/1/abc/0123',
        'http://invite.example.org/pair#$_pairRest',
        '$_page/link#$_pairRest!!x',
        '$_page/pair#1/abc%zz',
        '$_page/other#$_pairRest',
        'x' * 5000 + _pair,
      ]) {
        expect(parseInvite(text), isNull, reason: text);
      }
    });
  });

  group('inviteShareText', () {
    test('the https link, the invite only in the fragment', () {
      final pair = parseInvite(_pair)!;
      final device = parseInvite(_device)!;
      expect(inviteShareText(pair, invitePage: _page), '$_page/pair#$_pairRest');
      expect(inviteShareText(device, invitePage: _page), '$_page/link#$_deviceRest');
      expect(inviteShareText(pair, invitePage: '$_page/'), '$_page/pair#$_pairRest');
      expect(inviteShareText(pair, invitePage: '$_page/invites'), '$_page/invites/pair#$_pairRest');
      final uri = Uri.parse(inviteShareText(pair, invitePage: _page));
      expect(uri.path, '/pair');
      expect(uri.query, isEmpty);
      expect(uri.fragment, _pairRest);
    });

    test('no page, or an empty one: the bare invite', () {
      final pair = parseInvite(_pair)!;
      final device = parseInvite(_device)!;
      expect(inviteShareText(pair), _pair);
      expect(inviteShareText(pair, invitePage: ''), _pair);
      expect(inviteShareText(device, invitePage: '  '), _device);
    });

    test('reads back as the same invite', () {
      for (final link in [parseInvite(_pair)!, parseInvite(_device)!]) {
        expect(parseInvite(inviteShareText(link, invitePage: _page)), link);
        expect(parseInvite(inviteShareText(link)), link);
      }
    });
  });

  group('[invite] page', () {
    test('the shipped default copy names the site; a file without it reads that', () {
      expect(shippedSettings().invitePage, startsWith('https://'));
      final read = readSettings('[node]\nservers = []\n', shipped: testSettings());
      expect(read.settings.invitePage, testSettings().invitePage);
      expect(read.issues, isEmpty);
    });

    test('empty or an https page; nothing else', () {
      expect(checkInvitePage(''), isNull);
      expect(checkInvitePage(_page), isNull);
      expect(checkInvitePage('$_page/invites'), isNull);
      expect(checkInvitePage('http://invite.example.org'), isNotNull);
      expect(checkInvitePage('$_page/?x=1'), isNotNull);
      expect(checkInvitePage('$_page/#x'), isNotNull);
      expect(checkInvitePage('invite.example.org'), isNotNull);
    });
  });

  group('incoming invites', () {
    late List<String> calls;
    setUp(() => calls = []);
    tearDown(clearInviteHandlers);

    Future<ProviderContainer> pumpGate(WidgetTester tester, {ProviderContainer? container, VoidCallback? unreadable}) async {
      final c = container ?? ProviderContainer();
      addTearDown(c.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          home: InviteLinkGate(
            onUnreadable: (_) => unreadable?.call(),
            onNoHandler: (_, kind) => calls.add('none ${kind.name}'),
            child: const SizedBox(),
          ),
        ),
      ));
      await tester.pump();
      return c;
    }

    testWidgets('an invite that came before the unlock waits for the open wallet', (tester) async {
      final c = ProviderContainer();
      registerInviteHandler(InviteKind.pair, (_, link) async => calls.add('pair ${link.invite}'));
      expect(c.read(inviteInboxProvider).deliver(_pair), isTrue);
      await tester.pump();
      expect(calls, isEmpty, reason: 'no wallet open: nothing is handled');
      await pumpGate(tester, container: c);
      expect(calls, ['pair $_pair']);
      expect(c.read(inviteInboxProvider).held, isNull);
      await tester.pump(const Duration(seconds: 5));
      expect(calls, hasLength(1), reason: 'handled once');
    });

    testWidgets('one handler per kind; the newest replaces the one before', (tester) async {
      final c = await pumpGate(tester);
      Future<void> first(BuildContext _, InviteLink _) async => calls.add('first');
      registerInviteHandler(InviteKind.pair, first);
      registerInviteHandler(InviteKind.pair, (_, _) async => calls.add('second'));
      registerInviteHandler(InviteKind.deviceLink, (_, _) async => calls.add('device'));
      // Taking out a replaced handler leaves the newer one.
      unregisterInviteHandler(InviteKind.pair, first);
      expect(inviteHandler(InviteKind.pair), isNotNull);
      c.read(inviteInboxProvider).deliver('$_page/pair#$_pairRest');
      await tester.pump();
      c.read(inviteInboxProvider).deliver(_device);
      await tester.pump();
      expect(calls, ['second', 'device']);
    });

    testWidgets('a handler registered late gets the waiting invite', (tester) async {
      final c = await pumpGate(tester);
      c.read(inviteInboxProvider).deliver(_device);
      await tester.pump(const Duration(seconds: 1));
      expect(calls, isEmpty);
      expect(c.read(inviteInboxProvider).held?.kind, InviteKind.deviceLink, reason: 'held, not dropped');
      registerInviteHandler(InviteKind.deviceLink, (_, link) async => calls.add('device ${link.invite}'));
      await tester.pump(const Duration(seconds: 5));
      expect(calls, ['device $_device']);
    });

    testWidgets('no handler for its kind: a notice, and the invite is dropped', (tester) async {
      final c = await pumpGate(tester);
      c.read(inviteInboxProvider).deliver(_pair);
      await tester.pump(inviteHandlerWait + const Duration(milliseconds: 100));
      expect(calls, ['none pair']);
      expect(c.read(inviteInboxProvider).held, isNull);
      registerInviteHandler(InviteKind.pair, (_, _) async => calls.add('pair'));
      await tester.pump();
      expect(calls, ['none pair'], reason: 'a dropped invite never opens later');
    });

    testWidgets('nothing acts while a PIN prompt or a send runs; the invite waits', (tester) async {
      registerInviteHandler(InviteKind.pair, (_, _) async => calls.add('pair'));
      final c = await pumpGate(tester);
      c.read(linkBusyProvider.notifier).set(true);
      c.read(inviteInboxProvider).deliver(_pair);
      await tester.pump(const Duration(seconds: 5));
      expect(calls, isEmpty);
      c.read(linkBusyProvider.notifier).set(false);
      await tester.pump();
      expect(calls, ['pair']);
    });

    testWidgets('a link that is no readable invite is ignored with a notice', (tester) async {
      var notices = 0;
      final c = await pumpGate(tester, unreadable: () => notices++);
      expect(c.read(inviteInboxProvider).deliver('epiccash://pair/1/'), isFalse);
      expect(c.read(inviteInboxProvider).deliver('epiccash://device-link/x'), isFalse);
      // Not meant as an invite at all: no notice (a payment link has its own route).
      expect(c.read(inviteInboxProvider).deliver('epic:esAbc'), isFalse);
      await tester.pump(const Duration(seconds: 5));
      expect(calls, isEmpty);
      expect(notices, 2);
      expect(c.read(inviteInboxProvider).held, isNull);
    });

    test('a phone link that is an invite goes to the inbox, not to the payment link route', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(incomingLinkProvider.notifier).deliver('  $_pair ');
      expect(c.read(incomingLinkProvider), isNull);
      expect(c.read(inviteInboxProvider).held, const InviteLink(InviteKind.pair, _pair));
    });

    test('the desktop command line holds its invite', () {
      final c = ProviderContainer(overrides: [
        launchArgumentsProvider.overrideWithValue(['--skia', '$_page/link#$_deviceRest']),
      ]);
      addTearDown(c.dispose);
      expect(c.read(inviteInboxProvider).held, const InviteLink(InviteKind.deviceLink, _device));
    });
  });
}
