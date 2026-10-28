// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('kit widgets build', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildDeskTheme(Brightness.dark),
          home: Scaffold(
            body: Column(
              children: [
                EButton(label: 'Send', onPressed: () {}),
                EButton.primary(label: 'Send', icon: EIcons.send, onPressed: () {}),
                EIconButton(icon: EIcons.copy, label: 'Copy', onPressed: () {}),
                const ESwitch(value: true),
                const EBadge('Ok', tone: ETone.ok),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
