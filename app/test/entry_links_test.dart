// SPDX-License-Identifier: Apache-2.0
// The ways a payment link or invite reaches the app: an https link of the link page (any host),
// a shared message with one in it, and the desktop runner's hand-off. The Android intent filters
// are checked by the debug build's manifest merge; here is what Dart does with the text.
import 'package:epic_wallet/src/invite_links.dart';
import 'package:epic_wallet/src/scan/incoming_link.dart';
import 'package:epic_wallet/src/recipient.dart' show Recipient;
import 'package:epic_wallet/src/scan/scan_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'name_service_vectors_support.dart';

AddressVerdict _invalid(Recipient _) => AddressVerdict.invalid;

const _pairRest = '1/AbC_d-ef0123456789xyz';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = vectorList(loadVectors(), 'payreqs');
  final texts = [for (final e in requests) (e['text']! as Map<String, Object?>).cast<String, String>()];

  group('payment links from the vectors', () {
    test('the https link of any host reads as the epiccash:// one does', () {
      for (final t in texts) {
        final scheme = classifyScan(t['scheme']!, check: _invalid);
        expect(scheme, isA<PaymentLink>());
        for (final host in ['links.example', 'epiccash.btlabs.uk', 'other.example.net:8443']) {
          final p = t['scheme']!.substring('epiccash://pay/'.length);
          final https = classifyScan('https://$host/p#$p', check: _invalid);
          expect(https, isA<PaymentLink>(), reason: host);
          expect((https as PaymentLink).error, isNull);
          expect(https.request, isNotNull);
          expect(https.request!.toBytes(), (scheme as PaymentLink).request!.toBytes());
        }
        expect(classifyScan(t['https']!, check: _invalid), isA<PaymentLink>());
      }
    });

    test('a shared message with the link in it opens as if pasted', () {
      final link = texts.first['https']!;
      final shared = classifyScan('Pay me here:\n$link\nThanks!', check: _invalid);
      expect(shared, isA<PaymentLink>());
      expect((shared as PaymentLink).request, isNotNull);
      expect(classifyScan('Pay me $link please', check: _invalid), isA<PaymentLink>());
    });

    test('any other text or https URL is a code the wallet does not read', () {
      for (final text in ['hello there', 'https://example.org/', 'https://example.org/p', 'https://example.org/other#1/abc']) {
        expect(classifyScan(text, check: _invalid), isA<UnknownCode>(), reason: text);
      }
    });
  });

  group('invites from an https link', () {
    test('/pair#… of any host is a pairing invite, /p#… is not', () {
      for (final host in ['epiccash.btlabs.uk', 'invite.example.org']) {
        expect(parseInvite('https://$host/pair#$_pairRest'), const InviteLink(InviteKind.pair, 'epiccash://pair/$_pairRest'));
      }
      expect(parseInvite(texts.first['https']!), isNull);
    });
  });

  group('the link notifier', () {
    ProviderContainer container() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('an https payment link is held for the router, fragment intact', () {
      final c = container();
      final link = texts.first['https']!;
      c.read(incomingLinkProvider.notifier).deliver(link);
      expect(c.read(incomingLinkProvider)?.text, link);
      expect(c.read(inviteInboxProvider).held, isNull);
    });

    test('an https invite goes to the invite inbox, not the router', () {
      final c = container();
      c.read(incomingLinkProvider.notifier).deliver('https://epiccash.btlabs.uk/pair#$_pairRest');
      expect(c.read(incomingLinkProvider), isNull);
      expect(c.read(inviteInboxProvider).held?.kind, InviteKind.pair);
    });

    test('shared text goes to the router, which decides', () {
      final c = container();
      c.read(incomingLinkProvider.notifier).deliver('some words');
      expect(c.read(incomingLinkProvider)?.text, 'some words');
    });
  });

  group('desktop hand-off', () {
    const channel = MethodChannel('epic_wallet/incoming_link');
    late Object? pending;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      pending = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'takePending') return pending;
        return null;
      });
    });
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('a pay link the runner holds (a cold start) reaches the link notifier whole', () async {
      final link = texts.first['scheme']!;
      expect(link.length, greaterThan(500));
      pending = link;
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(incomingLinkProvider);
      c.read(inviteInboxProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(incomingLinkProvider)?.text, link);
      expect(c.read(inviteInboxProvider).held, isNull);
    });

    test('a pay link on the command line reaches the link notifier', () async {
      final link = texts.first['scheme']!;
      final c = ProviderContainer(overrides: [launchArgumentsProvider.overrideWithValue(['--flag', link])]);
      addTearDown(c.dispose);
      c.read(inviteInboxProvider);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(incomingLinkProvider)?.text, link);
    });

    test('a link opened while the app runs arrives over the channel', () async {
      final link = texts.last['scheme']!;
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(inviteInboxProvider);
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(MethodCall('link', link)),
        (_) {},
      );
      expect(c.read(incomingLinkProvider)?.text, link);
    });

    test('an invite from the runner still goes to the inbox', () async {
      pending = 'epiccash://pair/$_pairRest';
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(inviteInboxProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(inviteInboxProvider).held?.kind, InviteKind.pair);
      expect(c.read(incomingLinkProvider), isNull);
    });
  });
}
