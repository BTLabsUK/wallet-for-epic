// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/ui/common.dart';
import 'package:epic_wallet/src/ui/motion_switches.dart';
import 'package:epic_wallet/src/ui/theme/protocol.dart';
import 'package:epic_wallet/src/ui/theme/tokens.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A payment tile's square is its loader.

final AppLocalizations _l = lookupAppLocalizations(const Locale('en'));

/// The fake node's tip ([FakeWalletService.nodeTip]).
final BigInt _tip = BigInt.from(2500000);

const String _bob = 'esBobAddress1234567890@epicbox.epiccash.com';

final WalletTokens _t = protocolDark;

/// One theme for every pump: a new one would animate from the last.
final ThemeData _theme = buildWalletTheme(_t, Brightness.dark);

/// A [TxProgressSquare] alone, in the dark theme.
Widget _square({
  required TxPhase phase,
  double fraction = 0,
  bool still = false,
  String payment = 'p',
}) => MaterialApp(
  theme: _theme,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: still),
      child: Center(
        child: TxProgressSquare(
          payment: payment,
          phase: phase,
          fraction: fraction,
          child: const Icon(Icons.south_west, size: 20),
        ),
      ),
    ),
  ),
);

/// What the square paints now.
TxEdgePainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(TxProgressSquare),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as TxEdgePainter;

/// Total length of [path].
double _length(Path path) =>
    path.computeMetrics().fold(0, (sum, m) => sum + m.length);

class _NoPrice implements PriceSource {
  @override
  Future<double?> price(String currency) async => null;
}

class _OpenSession extends SessionNotifier {
  _OpenSession(this.session);

  final WalletSession session;

  @override
  WalletSession? build() => session;
}

class _Config extends WalletConfigNotifier {
  @override
  WalletConfig? build() => mainnetPreset.config(
    dataDir: '/fake/wallets/mainnet',
    nodeUrl: 'https://node',
  );
}

// One of each for every row, so pumping a row again keeps the providers' values.
final _session = FakeWalletSession();
final _service = FakeWalletService(session: _session);
final _store = MemorySecretStore();
final _price = _NoPrice();
DateTime _clock() => DateTime(2026, 10, 7, 12);

/// [child] with what a payment row reads, at [width] dp and text scale [textScale].
Future<void> _pumpRow(
  WidgetTester tester,
  Widget child, {
  double width = 412,
  double textScale = 1,
  bool still = false,
}) async {
  tester.view.physicalSize = Size(width * 3, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        walletServiceProvider.overrideWithValue(_service),
        secretStoreProvider.overrideWithValue(_store),
        priceSourceProvider.overrideWithValue(_price),
        clockProvider.overrideWithValue(_clock),
        sessionProvider.overrideWith(() => _OpenSession(_session)),
        walletConfigProvider.overrideWith(_Config.new),
      ],
      child: MaterialApp(
        theme: _theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: still,
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(body: child),
          ),
        ),
      ),
    ),
  );
}

/// One incoming payment from Bob, in the [phase] asked for. Every phase has the same key, so
/// a test can walk one row through them.
TxEntry _payment(TxPhase phase) => switch (phase) {
  TxPhase.waitingSender => fakeTx(
    slateId: 'pay',
    status: TxStatus.awaitingConfirmation,
    amountCredited: BigInt.from(250000000),
    counterparty: _bob,
  ),
  TxPhase.waitingRecipient => fakeTx(
    slateId: 'pay',
    kind: TxKind.sent,
    status: TxStatus.awaitingRecipient,
    amountDebited: BigInt.from(250000000),
    counterparty: _bob,
  ),
  TxPhase.waitingPayer => fakeTx(
    slateId: 'pay',
    status: TxStatus.awaitingConfirmation,
    amountCredited: BigInt.from(250000000),
    counterparty: _bob,
    flow: TxFlow.invoice,
    cancellable: true,
  ),
  TxPhase.confirming => _confirming(1),
  // A mining reward on the chain, locked for a day of blocks past the tip.
  TxPhase.maturing => fakeTx(
    slateId: 'pay',
    kind: TxKind.coinbase,
    status: TxStatus.confirmed,
    amountCredited: BigInt.from(250000000),
    blockHeight: _tip - BigInt.from(defaultMinimumConfirmations),
    rewardLockHeight: _tip + BigInt.from(1000),
  ),
  TxPhase.completed => _confirming(defaultMinimumConfirmations),
  TxPhase.cancelled => fakeTx(
    slateId: 'pay',
    kind: TxKind.receivedCancelled,
    status: TxStatus.cancelled,
    amountCredited: BigInt.from(250000000),
    counterparty: _bob,
  ),
  TxPhase.fromBackup => fakeTx(
    slateId: 'pay',
    status: TxStatus.awaitingConfirmation,
    source: TxSource.imported,
    amountCredited: BigInt.from(250000000),
    counterparty: _bob,
  ),
};

/// The payment from Bob with [confirmations] at [_tip].
TxEntry _confirming(int confirmations) => fakeTx(
  slateId: 'pay',
  status: confirmations >= defaultMinimumConfirmations
      ? TxStatus.confirmed
      : TxStatus.awaitingConfirmation,
  amountCredited: BigInt.from(250000000),
  counterparty: _bob,
  blockHeight: _tip - BigInt.from(confirmations - 1),
);

void main() {
  // Widget tests keep the run still (flutter_test_config.dart); these test it.
  setUp(() => txEdgeRunMoves = true);
  tearDown(() => txEdgeRunMoves = false);

  group('the edge path', () {
    const box = Rect.fromLTWH(1, 1, 38, 38);
    final perimeter = _length(txEdgePath(box, 7, 0, 1));

    test('starts at the top centre and runs clockwise', () {
      final start = txEdgePath(box, 7, 0, 0.1).computeMetrics().first;
      final at = start.getTangentForOffset(0)!.position;
      expect(at.dx, closeTo(20, 1e-6));
      expect(at.dy, closeTo(1, 1e-6));
      // Clockwise: it heads right along the top.
      final later = start.getTangentForOffset(5)!.position;
      expect(later.dx, greaterThan(at.dx));
      expect(later.dy, closeTo(1, 1e-6));
    });

    test('covers the share asked for, wrapping past the top', () {
      // A rounded square of 38 with corners of 7: four sides less the corners, plus a circle.
      expect(
        perimeter,
        closeTo(4 * (38 - 14) + 2 * 3.141592653589793 * 7, 0.5),
      );
      for (final share in [0.0, 0.16, 0.4, 0.9]) {
        expect(
          _length(txEdgePath(box, 7, 0, share)),
          closeTo(share * perimeter, 0.3),
          reason: 'share $share',
        );
      }
      final wrapped = txEdgePath(box, 7, 0.95, 0.16);
      expect(wrapped.computeMetrics().length, 2);
      expect(_length(wrapped), closeTo(0.16 * perimeter, 0.3));
    });
  });

  group('confirming', () {
    testWidgets('fills to the confirmations: 0, 1/3 and 3/3', (
      tester,
    ) async {
      for (final (n, share) in [(0, 0.0), (1, 1 / 3), (3, 1.0)]) {
        await tester.pumpWidget(
          _square(
            phase: TxPhase.confirming,
            fraction: txConfirmedShare(n, 3),
            payment: 'p$n',
          ),
        );
        final p = _painter(tester);
        expect(p.extent, closeTo(share, 1e-9), reason: '$n/3');
        expect(p.start, 0, reason: 'from the top centre');
        expect(p.edge, currentMarkEdge(_t));
        expect(p.halo, currentMarkHalo(_t));
      }
    });

    testWidgets('paints the share on the rounded square', (tester) async {
      await tester.pumpWidget(
        _square(phase: TxPhase.confirming, fraction: 0.4),
      );
      final p = _painter(tester);
      final rec = _PathRecorder();
      p.paint(rec, const Size.square(txTileSize));
      final drawn = rec.paths.single;
      final whole = _length(
        txEdgePath(const Rect.fromLTWH(1, 1, 38, 38), _t.radiusSmall - 1, 0, 1),
      );
      expect(_length(drawn), closeTo(0.4 * whole, 0.3));
    });

    testWidgets('nothing is drawn of the line at 0', (tester) async {
      await tester.pumpWidget(_square(phase: TxPhase.confirming));
      final rec = _PathRecorder();
      _painter(tester).paint(rec, const Size.square(txTileSize));
      expect(rec.paths, isEmpty);
      expect(rec.halos, 1, reason: 'still a pending tile');
    });

    testWidgets('a new count tweens over 0.9 s', (tester) async {
      await tester.pumpWidget(
        _square(phase: TxPhase.confirming, fraction: 0.4),
      );
      await tester.pumpWidget(
        _square(phase: TxPhase.confirming, fraction: 0.5),
      );
      expect(_painter(tester).extent, closeTo(0.4, 1e-9));
      await tester.pump(const Duration(milliseconds: 300));
      final mid = _painter(tester).extent;
      expect(mid, greaterThan(0.4));
      expect(mid, lessThan(0.5));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 16));
      expect(_painter(tester).extent, closeTo(0.5, 1e-9));
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('with reduced motion a new count cuts', (tester) async {
      await tester.pumpWidget(
        _square(phase: TxPhase.confirming, fraction: 0.4, still: true),
      );
      await tester.pumpWidget(
        _square(phase: TxPhase.confirming, fraction: 0.5, still: true),
      );
      expect(_painter(tester).extent, closeTo(0.5, 1e-9));
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('a real row reads 0 and 1 of 6 from the chain', (
      tester,
    ) async {
      await _pumpRow(tester, TxIcon(tx: _confirming(1), tip: _tip));
      await tester.pumpAndSettle();
      expect(_painter(tester).extent, closeTo(1 / defaultMinimumConfirmations, 1e-9));
      final unmined = fakeTx(
        slateId: 'unmined',
        kind: TxKind.sent,
        status: TxStatus.awaitingConfirmation,
        amountDebited: BigInt.from(100000000),
      );
      await _pumpRow(tester, TxIcon(tx: unmined, tip: _tip));
      await tester.pumpAndSettle();
      expect(
        txPhase(unmined, _tip),
        TxPhase.confirming,
        reason: 'posted, not in a block yet',
      );
      expect(_painter(tester).extent, 0);
    });
  });

  group('waiting', () {
    // Waiting shows in the status line (the hourglass), not on the tile: a moving fragment on a
    // static square read as a glitch (UP-022). The tile is the hairline and nothing turns.
    for (final phase in [
      TxPhase.waitingSender,
      TxPhase.waitingRecipient,
      TxPhase.waitingPayer,
    ]) {
      for (final still in [false, true]) {
        testWidgets('${phase.name}${still ? ' with reduced motion' : ''}: the hairline, still', (
          tester,
        ) async {
          await tester.pumpWidget(_square(phase: phase, still: still));
          final p = _painter(tester);
          expect(txEdgeKind(phase), TxEdgeKind.hairline);
          expect(p.edge, isNull);
          expect(p.halo, isNull);
          expect(p.extent, 0);
          expect(tester.binding.transientCallbackCount, 0);
          await tester.pump(const Duration(seconds: 3));
          expect(_painter(tester).start, p.start);
        });
      }
    }
  });

  group('landing', () {
    testWidgets('confirming to completed closes in ok, then the hairline', (
      tester,
    ) async {
      await tester.pumpWidget(
        _square(phase: TxPhase.confirming, fraction: 0.9),
      );
      await tester.pumpWidget(_square(phase: TxPhase.completed));
      await tester.pump(const Duration(milliseconds: 900));
      final p = _painter(tester);
      expect(p.edge, doneMarkEdge(_t));
      expect(p.extent, closeTo(1, 1e-9), reason: 'closed');
      expect(p.halo, doneMarkEdge(_t).withValues(alpha: txEdgeLandHaloAlpha));
      await tester.pump(const Duration(milliseconds: 500));
      final after = _painter(tester);
      expect(after.edge, isNull);
      expect(after.halo, isNull);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('with reduced motion it cuts straight to the hairline', (
      tester,
    ) async {
      await tester.pumpWidget(
        _square(phase: TxPhase.confirming, fraction: 0.9, still: true),
      );
      await tester.pumpWidget(_square(phase: TxPhase.completed, still: true));
      final p = _painter(tester);
      expect(p.edge, isNull);
      expect(p.halo, isNull);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('only a payment that was confirming lands', (tester) async {
      for (final before in [
        TxPhase.waitingSender,
        TxPhase.waitingRecipient,
        TxPhase.cancelled,
        TxPhase.fromBackup,
      ]) {
        await tester.pumpWidget(_square(phase: before, payment: before.name));
        await tester.pumpWidget(
          _square(phase: TxPhase.completed, payment: before.name),
        );
        expect(_painter(tester).edge, isNull, reason: 'from $before');
      }
      // Nor one first shown completed, nor a confirming one that is cancelled.
      await tester.pumpWidget(_square(phase: TxPhase.completed, payment: 'x'));
      expect(_painter(tester).edge, isNull);
      await tester.pumpWidget(
        _square(phase: TxPhase.confirming, fraction: 0.5, payment: 'y'),
      );
      await tester.pumpWidget(_square(phase: TxPhase.cancelled, payment: 'y'));
      expect(_painter(tester).edge, isNull);
    });

    testWidgets('a list that rebuilds the row still lands it', (tester) async {
      // The tile moves under another parent, as a list reorders it: a new State.
      Widget at(bool moved, TxPhase phase) => MaterialApp(
        theme: _theme,
        home: Column(
          children: [
            if (moved) const SizedBox(height: 10),
            if (moved)
              Padding(
                padding: EdgeInsets.zero,
                child: TxProgressSquare(
                  payment: 'moved',
                  phase: phase,
                  fraction: 1,
                  child: const SizedBox(),
                ),
              )
            else
              TxProgressSquare(
                payment: 'moved',
                phase: phase,
                fraction: 0.9,
                child: const SizedBox(),
              ),
          ],
        ),
      );
      await tester.pumpWidget(at(false, TxPhase.confirming));
      await tester.pumpWidget(at(true, TxPhase.completed));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_painter(tester).edge, doneMarkEdge(_t));
      await tester.pumpAndSettle();
      expect(_painter(tester).edge, isNull);
    });

    testWidgets('a payment no tile shows any more is forgotten', (
      tester,
    ) async {
      await tester.pumpWidget(
        _square(phase: TxPhase.confirming, fraction: 0.9, payment: 'gone'),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pumpWidget(
        _square(phase: TxPhase.completed, payment: 'gone'),
      );
      expect(_painter(tester).edge, isNull);
    });
  });

  group('final tiles', () {
    for (final phase in [
      TxPhase.completed,
      TxPhase.cancelled,
      TxPhase.fromBackup,
    ]) {
      testWidgets('${phase.name} paints only the hairline', (tester) async {
        await tester.pumpWidget(_square(phase: phase));
        final p = _painter(tester);
        expect(p.edge, isNull);
        expect(p.halo, isNull);
        expect(p.hairline, _t.lineStrong);
        final box = find.descendant(
          of: find.byType(TxProgressSquare),
          matching: find.byType(CustomPaint),
        );
        expect(
          box,
          paints..rrect(
            rrect: RRect.fromRectAndRadius(
              const Rect.fromLTWH(0.5, 0.5, 39, 39),
              Radius.circular(_t.radiusSmall - 0.5),
            ),
            color: _t.lineStrong,
            strokeWidth: 1,
            style: PaintingStyle.stroke,
          ),
        );
        expect(box, isNot(paints..path()));
        expect(box, isNot(paints..drrect()));
        expect(tester.binding.transientCallbackCount, 0);
      });
    }

    testWidgets('a pending tile paints the hairline, halo and line', (
      tester,
    ) async {
      await tester.pumpWidget(_square(phase: TxPhase.confirming, fraction: 0.5));
      final box = find.descendant(
        of: find.byType(TxProgressSquare),
        matching: find.byType(CustomPaint),
      );
      expect(
        box,
        paints
          ..drrect(color: currentMarkHalo(_t))
          ..rrect(color: _t.lineStrong)
          ..path(
            color: currentMarkEdge(_t),
            strokeWidth: currentMarkStroke,
            style: PaintingStyle.stroke,
          ),
      );
    });
  });

  testWidgets('the Details tile and the timeline mark read as one', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: _theme,
        home: const Scaffold(
          body: StatusTimeline(
            steps: [TimelineStep('Waiting', TimelineState.current)],
          ),
        ),
      ),
    );
    final mark = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(StatusTimeline),
            matching: find.byType(Container),
          ),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.border != null);
    final side = (mark.border! as Border).top;
    await tester.pumpWidget(_square(phase: TxPhase.confirming, fraction: 0.5));
    final tile = _painter(tester);
    expect(tile.edge, side.color);
    expect(side.width, currentMarkStroke);
    expect(tile.halo, mark.boxShadow!.single.color);
    // The timeline mark is round, as the send tracker's nodes; the tile keeps its
    // rounded square.
    expect(mark.shape, BoxShape.circle);
    expect(tile.radius, _t.radiusSmall);
  });

  group('the row', () {
    // Rows settle with pumpAndSettle, so their waiting runs stay still.
    setUp(() => txEdgeRunMoves = false);

    testWidgets('keeps its size and tile place in every phase', (tester) async {
      for (final width in [320.0, 360.0, 412.0]) {
        for (final scale in [1.0, 2.0]) {
          Size? size;
          Offset? tile;
          Future<void> check(String what) async {
            final s = tester.getSize(find.byType(TxTile));
            final at = tester.getTopLeft(find.byType(TxProgressSquare));
            expect(
              tester.getSize(find.byType(TxProgressSquare)),
              const Size.square(txTileSize),
              reason: what,
            );
            size ??= s;
            tile ??= at;
            expect(s, size, reason: '$what at $width dp, x$scale');
            expect(at, tile, reason: '$what at $width dp, x$scale');
          }

          for (final phase in [
            TxPhase.waitingSender,
            TxPhase.confirming,
            TxPhase.completed,
            TxPhase.fromBackup,
          ]) {
            await _pumpRow(
              tester,
              TxTile(tx: _payment(phase)),
              width: width,
              textScale: scale,
            );
            await tester.pumpAndSettle();
            await check(phase.name);
          }
          // Confirming, then landing: mid-flash and after.
          await _pumpRow(
            tester,
            TxTile(tx: _confirming(2)),
            width: width,
            textScale: scale,
          );
          await tester.pumpAndSettle();
          await check('2/3');
          await _pumpRow(
            tester,
            TxTile(tx: _confirming(defaultMinimumConfirmations)),
            width: width,
            textScale: scale,
          );
          await tester.pump(const Duration(milliseconds: 400));
          expect(_painter(tester).edge, doneMarkEdge(_t));
          await check('landing');
          await tester.pumpAndSettle();
          await check('landed');
        }
      }
    });

    testWidgets('outgoing, waiting payer and cancelled keep the tile', (
      tester,
    ) async {
      // Their titles and chips differ, so only the tile's size and place are compared.
      Offset? tile;
      for (final phase in [
        TxPhase.waitingRecipient,
        TxPhase.waitingPayer,
        TxPhase.cancelled,
      ]) {
        await _pumpRow(tester, TxTile(tx: _payment(phase)));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(TxProgressSquare)),
          const Size.square(txTileSize),
        );
        final at = tester.getTopLeft(find.byType(TxProgressSquare));
        tile ??= at;
        expect(at, tile, reason: phase.name);
      }
    });

    testWidgets('the tile adds no spoken text', (tester) async {
      final handle = tester.ensureSemantics();
      for (final (phase, label) in [
        (TxPhase.waitingSender, _l.txIconIncoming),
        (TxPhase.confirming, _l.txIconIncoming),
        (TxPhase.completed, _l.txIconIncoming),
        (TxPhase.waitingRecipient, _l.txIconOutgoing),
        (TxPhase.cancelled, _l.txIconCancelled),
      ]) {
        await _pumpRow(
          tester,
          MergeSemantics(
            child: TxIcon(tx: _payment(phase), tip: _tip),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(find.byType(MergeSemantics)).label,
          label,
          reason: phase.name,
        );
      }
      handle.dispose();
    });

    testWidgets('the chip counts in tabular figures', (tester) async {
      await _pumpRow(tester, TxStatusChip(tx: _confirming(1), tip: _tip));
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(find.text(_l.txStatusConfirming(1, defaultMinimumConfirmations)));
      expect(
        text.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });
}

/// A canvas that keeps the paths and halos drawn on it.
class _PathRecorder implements Canvas {
  final List<Path> paths = [];
  int halos = 0;

  @override
  void drawPath(Path path, Paint paint) => paths.add(path);

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) => halos++;

  @override
  void drawRRect(RRect rrect, Paint paint) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
