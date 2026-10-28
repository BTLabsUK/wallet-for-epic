import 'dart:io';

import 'package:epic_wallet/src/desktop/app/desk_app.dart' show DeskTextScaler;
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/activity_screen.dart';
import 'package:epic_wallet/src/desktop/screens/wallet/tx_display.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Rows with very different amount widths: the Status, Time and Amount columns must line up.
// Regenerate with `flutter test --no-pub --update-goldens test/desktop/tx_table_golden_test.dart`.
const _nano = nanoPerEpic;

Tx _tx(
  int id,
  TxDirection dir,
  int amount, {
  TxState state = TxState.confirmed,
  int fee = 0,
  bool scan = false,
  FoundDuring? during,
  bool byBlock = true,
}) => Tx(
  id: id,
  slateId: 's$id',
  direction: dir,
  state: state,
  method: TxMethod.epicbox,
  amount: amount,
  fee: fee,
  created: DateTime(2026, 10, 22, 4, 24),
  confirmations: 10,
  counterparty: scan ? null : 'someone@epicbox.example',
  foundByScan: scan,
  foundDuring: during,
  datedByBlock: byBlock,
);

final _txs = [
  _tx(1, TxDirection.received, _nano, scan: true),
  _tx(2, TxDirection.sent, _nano ~/ 2, state: TxState.cancelled, fee: 2000000),
  _tx(3, TxDirection.received, 238243300, scan: true),
  _tx(4, TxDirection.sent, 1234567891234, fee: 8000000),
  _tx(5, TxDirection.received, 88000000, scan: true),
];

// The four origins of a scan find.
final _found = [
  _tx(1, TxDirection.received, _nano, scan: true, during: FoundDuring.restore),
  _tx(2, TxDirection.received, 238243300, scan: true, during: FoundDuring.rescan),
  _tx(3, TxDirection.received, 88000000, scan: true, during: FoundDuring.rescan, byBlock: false),
  _tx(4, TxDirection.received, 4100000000, scan: true),
];

Future<void> _loadFonts() async {
  final dir =
      '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async =>
      ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final roboto = FontLoader('Roboto');
  for (final face in [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    roboto.addFont(read('$dir/$face'));
  }
  await roboto.load();
  for (final (family, file) in [
    ('Montserrat', 'assets/fonts/Montserrat-SemiBold.ttf'),
    ('JetBrainsMonoNL', 'assets/fonts/JetBrainsMonoNL-Regular.ttf'),
    ('EpicStatusIcons', 'assets/fonts/EpicStatusIcons.ttf'),
  ]) {
    await (FontLoader(family)..addFont(read(file))).load();
  }
  await (FontLoader(
    'MaterialIcons',
  )..addFont(read('$dir/MaterialIcons-Regular.otf'))).load();
}

Future<void> _pump(WidgetTester tester, double scale, bool compact, [List<Tx>? txs]) async {
  tester.view.physicalSize = const Size(1000, 640);
  tester.view.devicePixelRatio = 1;
  deskScale = scale * deskBase;
  addTearDown(() {
    tester.view.reset();
    deskScale = deskBase;
  });
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildDeskTheme(Brightness.dark),
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: DeskTextScaler(mq.textScaler, deskScale),
            ),
            child: child!,
          );
        },
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!compact) const ActivityListHead(),
                      for (final t in txs ?? _txs)
                        TxRow(tx: t, compact: compact, onTap: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(_loadFonts);
  testWidgets('Activity rows found by a scan', (tester) async {
    await _pump(tester, 1, false, _found);
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/activity_found.png'));
  });
  for (final scale in [1.0, 1.5]) {
    final pct = (scale * 100).round();
    testWidgets('Activity table at $pct%', (tester) async {
      await _pump(tester, scale, false);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/activity_table_$pct.png'),
      );
    });
    testWidgets('Recent activity at $pct%', (tester) async {
      await _pump(tester, scale, true);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/recent_activity_$pct.png'),
      );
    });
  }
}
