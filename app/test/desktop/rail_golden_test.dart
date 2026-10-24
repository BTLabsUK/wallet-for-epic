// The sidebar rail as it looks: each row's icon at the left, the bars at the right, one
// hairline between every two rows. At a 1280 px window at 100 % and a 2474 px window at 150 %.
// Regenerate with `flutter test --no-pub --update-goldens test/desktop/rail_golden_test.dart`.
import 'dart:io';

import 'package:epic_wallet/src/desktop/app/rail.dart';
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'advanced_on.dart';

class _Wallet extends MockDeskWallet {
  _Wallet() : super(delay: Duration.zero);

  @override
  Future<ServiceStatus> status() async => const ServiceStatus(
    node: NodeServer(url: 'https://node.btlabs.uk', label: 'BT Labs'),
    nodeHealth: ServiceHealth.ok,
    nodeHeight: 2914414,
    epicbox: EpicboxServer(domain: 'epicbox.stackwallet.com'),
    epicboxHealth: ServiceHealth.ok,
    httpListener: ServiceHealth.ok,
    tor: ServiceHealth.slow,
    torCanSend: true,
  );
}

Future<void> _loadFonts() async {
  final dir =
      '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async => ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final roboto = FontLoader('Roboto');
  for (final face in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf']) {
    roboto.addFont(read('$dir/$face'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(read('$dir/MaterialIcons-Regular.otf'))).load();
  await (FontLoader('EpicStatusIcons')..addFont(read('assets/fonts/EpicStatusIcons.ttf'))).load();
}

void main() {
  setUpAll(_loadFonts);

  Future<void> shot(WidgetTester tester, {required double width, required double percent, required String file}) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    deskScale = percent / 100 * deskBase;
    addTearDown(() {
      deskScale = deskBase;
      tester.view.reset();
    });
    final container = ProviderContainer(overrides: [deskApiProvider.overrideWithValue(_Wallet())]);
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(deskProvider.notifier).refresh());
    await tester.runAsync(() => advancedOn(container));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildDeskTheme(Brightness.dark),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: const ValueKey('rail-shot'),
                child: ColoredBox(
                  color: buildDeskTheme(Brightness.dark).scaffoldBackgroundColor,
                  child: SizedBox(width: 220.u, child: const ServiceRows()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(find.byKey(const ValueKey('rail-shot')), matchesGoldenFile('goldens/$file'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('rail at 1280 px, 100 %', (tester) => shot(tester, width: 1280, percent: 100, file: 'rail_1280.png'));
  testWidgets('rail at 2474 px, 150 %', (tester) => shot(tester, width: 2474, percent: 150, file: 'rail_2474.png'));
}
