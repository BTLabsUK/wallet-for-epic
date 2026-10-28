// Screen-reader labels say each word once: a disabled switch row with an info hint, and
// Home's status icons.
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/ui/info_hint.dart';
import 'package:epic_wallet/src/ui/status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  ),
);

/// Every label and hint under [finder], joined, as a screen reader would walk them.
String _spoken(WidgetTester tester, Finder finder) {
  final out = <String>[];
  void walk(SemanticsNode n) {
    final d = n.getSemanticsData();
    for (final s in [d.label, d.value, d.hint]) {
      if (s.isNotEmpty) out.add(s);
    }
    n.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  walk(tester.getSemantics(finder));
  return out.join('|');
}

int _count(String text, String word) => word.allMatches(text).length;

void main() {
  testWidgets('a disabled switch row with an info hint names its title once', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const HintSwitchTile(
        key: ValueKey('row'),
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        hint: 'Payments arrive as notifications.',
        subtitle: Text('Needs Epicbox'),
        value: false,
        onChanged: null,
      ),
    );
    final spoken = _spoken(tester, find.byKey(const ValueKey('row')));
    expect(_count(spoken, 'Notifications'), 1, reason: spoken);
    expect(_count(spoken, 'Needs Epicbox'), 1, reason: spoken);
    handle.dispose();
  });

  testWidgets('a status icon says its state once', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      StatusIcon(
        key: const ValueKey('icon'),
        icon: Icons.mail_outline,
        dot: StatusDot.off,
        label: 'Epicbox, Off',
        detail: 'Off',
        onTap: () {},
      ),
    );
    final spoken = _spoken(tester, find.byKey(const ValueKey('icon')));
    expect(_count(spoken, 'Off'), 1, reason: spoken);
    handle.dispose();
  });
}
