// SPDX-License-Identifier: Apache-2.0
// The epic1 wordmark (its size from the text it stands in, one "epic1" for screen readers,
// plain text below 13 px or without the token) and the "Sealed with epic1" mark on a history
// row: only on a sealed payment, only in epic1 mode, said once in the row's sentence.
import 'package:epic_wallet/src/epic1.dart';
import 'package:epic_wallet/src/history/meta_store.dart' show Meta;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/ui/backup_screen.dart' show backedUpProvider;
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/epic1/epic1_sealed.dart';
import 'package:epic_wallet/src/ui/theme/epic1_mark.dart';
import 'package:epic_wallet/src/ui/tip.dart' show Tip;
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/send_pin.dart';

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

class _Open extends SessionNotifier {
  _Open(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _NoRelays implements RelayDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => const [];
}

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

const _pairing = 'pair-1';
final _sent = fakeTx(id: 1, kind: TxKind.sent, status: TxStatus.confirmed, blockHeight: BigInt.from(100), transport: 'epicbox');

/// One row's status line for [tx], in epic1 mode when [on].
Future<void> _line(WidgetTester tester, TxEntry tx, {required bool on}) async {
  final session = FakeWalletSession()..epic1Fake = FakeEpic1(on: on);
  allowPinCheck(session, null);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(FakeWalletService(session: session)),
        secretStoreProvider.overrideWithValue(sendPinStore()..values['app.network'] = 'mainnet'),
        updatePlatformProvider.overrideWithValue(null),
        relayDirectoryProvider.overrideWithValue(_NoRelays()),
        priceSourceProvider.overrideWithValue(_NoPrice()),
        backedUpProvider.overrideWith((ref) async => true),
        sessionProvider.overrideWith(() => _Open(session)),
      ],
      child: _app(SizedBox(width: 340, child: TxStatusLine(tx: tx, tip: BigInt.from(200), date: 'Today'))),
    ),
  );
  await tester.pump();
}

/// Takes the scope down and lets its timers run out.
Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 5));
}

void main() {
  group('txSealed', () {
    test('a paired payment or an epic1 link is sealed; a plain resend or in person is not', () {
      expect(txSealed(pairingId: _pairing), isTrue);
      expect(txSealed(epic1Via: Epic1Via.link), isTrue);
      expect(txSealed(), isFalse);
      expect(txSealed(epic1Via: Epic1Via.inPerson), isFalse);
      expect(txSealed(epic1Via: Epic1Via.inPerson, pairingId: _pairing), isFalse);
      expect(txSealed(pairingId: _pairing, sentPlain: true), isFalse);
      expect(txSealed(epic1Via: Epic1Via.link, sentPlain: true), isFalse);
    });

    test('a plain resend is kept in the meta file and read back', () {
      final meta = Meta(plainResends: ['b', 'a']);
      expect(meta.toJson()['plain_resends'], ['a', 'b']);
      expect(Meta.fromJson(meta.toJson()).plainResends, {'a', 'b'});
      expect(Meta().toJson().containsKey('plain_resends'), isFalse);
    });
  });

  group('Epic1Mark', () {
    testWidgets('sets its letters at the text size on the baseline and says epic1 once', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(const Epic1Mark(fontSize: 16, scaleText: false)));
      await tester.pumpAndSettle();
      final size = tester.getSize(find.byType(Epic1Mark));
      // The pack's box: four letters at 0.58 em, a 0.1 em gap, the 0.73 em mark.
      expect(size.width, moreOrLessEquals(16 * (4 * 0.58 + 0.1 + 69 / 49 * 0.73), epsilon: 0.01));
      expect(size.height, moreOrLessEquals(Epic1Mark.sizeFor(16).height, epsilon: 0.01));
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.bySemanticsLabel('epic1'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('below the 14 px minimum it is the 1 alone, 0.73 em high on the baseline', (tester) async {
      await tester.pumpWidget(_app(const Epic1Mark(fontSize: 12, scaleText: false)));
      await tester.pumpAndSettle();
      expect(find.byType(SvgPicture), findsNothing);
      expect(tester.getSize(find.byType(Epic1Mark)), Size(12 * 0.73 * 29 / 49, 12 * 0.73));
    });

    testWidgets('Epic1Glyph: columns 0 to 4 from 24 px, the 1 alone below', (tester) async {
      for (final (size, columns) in [(24.0, 5), (20.0, 3)]) {
        await tester.pumpWidget(_app(Epic1Glyph(size: size)));
        await tester.pumpAndSettle();
        final paint = tester.getSize(find.descendant(of: find.byType(Epic1Glyph), matching: find.byType(CustomPaint)).last);
        expect(paint.height, moreOrLessEquals(size * 0.8, epsilon: 0.01));
        expect(paint.width / paint.height, moreOrLessEquals((columns * 10 - 1) / 49, epsilon: 0.001), reason: '$size');
      }
    });

    testWidgets('Epic1Text: the wordmark at 14 px and up with clear space, the plain token below or in a link', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(const Epic1Text('Use epic1 payments', style: TextStyle(fontSize: 16))));
      await tester.pumpAndSettle();
      expect(find.byType(Epic1Mark), findsOneWidget);
      expect(find.bySemanticsLabel('Use epic1 payments'), findsOneWidget);
      final mark = tester.widget<Epic1Mark>(find.byType(Epic1Mark));
      expect(mark.clearStart, greaterThanOrEqualTo(0));
      expect(mark.clearStart, mark.clearEnd);
      expect(Epic1Art.clearSpace, moreOrLessEquals(20 * 0.73 / 49, epsilon: 1e-9));

      for (final (text, size) in [('epic1 payments', 13.0), ('epic:epic1qabc', 16.0), ('epic1-Links', 16.0), ('Payments', 16.0)]) {
        await tester.pumpWidget(_app(Epic1Text(text, style: TextStyle(fontSize: size))));
        await tester.pumpAndSettle();
        expect(find.byType(Epic1Mark), findsNothing, reason: '$text at $size');
        expect(find.text(text), findsOneWidget, reason: '$text at $size');
      }
      semantics.dispose();
    });
  });

  group('Sealed with epic1', () {
    testWidgets('a sealed payment in epic1 mode shows the lock, with the words in its tip', (tester) async {
      await _line(tester, copyTxPairing(_sent, _pairing), on: true);
      expect(find.byKey(epic1SealedKey), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Tip && w.message == _l.deskE1Sealed), findsOneWidget);
      await _end(tester);
    });

    testWidgets('an unsealed payment shows none', (tester) async {
      await _line(tester, _sent, on: true);
      expect(find.byKey(epic1SealedKey), findsNothing);
      await _line(tester, copyTxPairing(_sent, _pairing, sentPlain: true), on: true);
      expect(find.byKey(epic1SealedKey), findsNothing);
      await _end(tester);
    });

    testWidgets('classic mode shows none, even on a sealed payment', (tester) async {
      await _line(tester, copyTxPairing(_sent, _pairing), on: false);
      expect(find.byKey(epic1SealedKey), findsNothing);
      await _end(tester);
    });

    test('the row sentence says it once, after the rest', () {
      String said({required bool sealed}) => txSpokenLabel(_l, _sent, who: 'Anna', date: 'today', status: 'Completed', hidden: true, sealed: sealed);
      expect(said(sealed: false), isNot(contains(_l.deskE1Sealed)));
      expect(said(sealed: true), _l.deskE1SpokenSealed(said(sealed: false)));
      expect(RegExp('epic1').allMatches(said(sealed: true)).length, 1);
    });
  });
}

/// [tx] linked to [pairingId], its slate handed over plain when [sentPlain].
TxEntry copyTxPairing(TxEntry tx, String pairingId, {bool sentPlain = false}) => fakeTx(
  id: tx.id,
  kind: tx.kind,
  status: tx.status,
  blockHeight: tx.blockHeight,
  transport: tx.transport,
  pairingId: pairingId,
  sentPlain: sentPlain,
);
