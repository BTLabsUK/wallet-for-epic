import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:epic_wallet/l10n/app_localizations_en.dart';
import 'package:epic_wallet/src/message_checks.dart';
import 'package:epic_wallet/src/pairing_api.dart';
import 'package:epic_wallet/src/pairing_fake.dart';
import 'package:epic_wallet/src/pairing_providers.dart';
import 'package:epic_wallet/src/ui/kept_messages_sheet.dart';
import 'package:epic_wallet/src/ui/kept_messages_text.dart';
import 'package:epic_wallet/src/ui/message_check_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

KeptMessage _kept(String id, String code) =>
    KeptMessage(id: id, contactId: 'p-anna', code: code, firstSeen: DateTime.utc(2026, 11, 10, 9, 30), attempts: 3, size: 812);

void main() {
  test('each reason says what the message is and why, in plain words', () {
    final l = AppLocalizationsEn();
    expect(KeptReason.of('undecodable_slate'), KeptReason.undecodableSlate);
    expect(KeptReason.of('something_new'), KeptReason.other);
    expect(keptKind(l, _kept('a', 'receive_refused')), 'Payment');
    expect(keptKind(l, _kept('a', 'unknown_notice')), 'Contact message');
    expect(keptWhy(l, _kept('a', 'receipt_cap')), l.msgKeptWhyCap);
    expect(keptWhy(l, _kept('a', 'x')), 'Your wallet did not record why.');
    expect(keptFrom(l, ''), 'From a paired contact');
    expect(keptFrom(l, 'Anna'), 'From Anna');
  });

  test('the support text carries the facts and a short address, no name', () {
    final text = keptSupportText(
      [_kept('m1', 'hold_bound')],
      addressOf: (_) => 'esWkiYK5gSUUk3U6pnGVzWx3rkbVS2ZXmqsa6bUo1kXrkRKhzXWZ@epicbox.epiccash.com',
      appVersion: '26.11.1',
    );
    expect(text, contains('id: m1'));
    expect(text, contains('reason: hold_bound'));
    expect(text, contains('first seen: 2026-11-10T09:30:00.000Z'));
    expect(text, contains('tries: 3'));
    expect(text, contains('App: 26.11.1'));
    expect(text, isNot(contains('esWkiYK5gSUUk3U6pnGVzWx3rkbVS2ZXmqsa6bUo1kXrkRKhzXWZ')));
  });

  group('phone', () {
    late FakePairing api;

    Future<void> pump(WidgetTester tester, Widget home) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            pairingApiProvider.overrideWithValue(api),
            pairingNameProvider.overrideWith((ref, id) => id == 'p-anna' ? 'Anna' : ''),
            pairingByIdProvider.overrideWith((ref, id) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: home),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      api = FakePairing()
        ..keptList.addAll([_kept('m1', 'undecodable_slate'), _kept('m2', 'receive_refused')]);
    });

    testWidgets('only the unreadable line opens, and it opens the kept messages', (tester) async {
      await pump(
        tester,
        const MessageCheckPanel(MessageCheck(outcome: CheckOutcome(rejected: 1, unreadable: 2)), open: true),
      );
      // Turned away has nothing to do: no tap target.
      expect(find.ancestor(of: find.text('1 message turned away'), matching: find.byType(InkWell)), findsNothing);
      await tester.tap(find.byKey(messageCheckKeptKey));
      await tester.pumpAndSettle();
      expect(find.byKey(keptSheetKey), findsOneWidget);
      expect(find.text('Payment or invoice'), findsOneWidget);
      expect(find.text('From Anna'), findsNWidgets(2));
      expect(find.text(AppLocalizationsEn().msgKeptWhyRefused), findsOneWidget);
    });

    testWidgets('Try again says when a message stays, and drops one that was read', (tester) async {
      await pump(tester, const KeptMessagesSheet());
      await tester.tap(find.byKey(keptRetryKey('m1')));
      await tester.pumpAndSettle();
      expect(find.text('Still not read. It stays here.'), findsOneWidget);
      api.keptTakenOnRetry.add('m1');
      await tester.tap(find.byKey(keptRetryKey('m1')));
      await tester.pumpAndSettle();
      expect(find.text('Read. It is no longer kept.'), findsOneWidget);
      expect(find.byKey(keptRetryKey('m1')), findsNothing);
      expect(api.calls.where((c) => c == 'retryKept'), hasLength(2));
    });

    testWidgets('Remove asks first; Cancel keeps it, Remove deletes it', (tester) async {
      await pump(tester, const KeptMessagesSheet());
      await tester.ensureVisible(find.byKey(keptRemoveKey('m2')));
      await tester.tap(find.byKey(keptRemoveKey('m2')));
      await tester.pumpAndSettle();
      expect(find.text('Remove this message?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(api.keptList, hasLength(2));
      await tester.ensureVisible(find.byKey(keptRemoveKey('m2')));
      await tester.tap(find.byKey(keptRemoveKey('m2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(api.keptList.map((m) => m.id), ['m1']);
      expect(find.byKey(keptRemoveKey('m2')), findsNothing);
    });
  });
}
