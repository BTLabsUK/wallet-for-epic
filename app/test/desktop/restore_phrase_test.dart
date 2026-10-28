// Restore's phrase grid: 24 numbered fields, a paste sets the count, words are checked on
// blur or commit only, the checksum once the phrase is complete. The mock wallet answers the
// checksum with the real BIP-39 rule, so the standard vectors apply.
import 'package:epic_wallet/src/bip39_words.dart';
import 'package:epic_wallet/src/desktop/data/phrase_check.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/phrase_grid.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/restore_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _vector(int n, String last) => [...List.filled(n - 1, 'abandon'), last];
final _v12 = _vector(12, 'about');
final _v24 = _vector(24, 'art');

Future<void> _pump(WidgetTester tester, {Size size = const Size(1280, 800)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildDeskTheme(Brightness.dark), home: const Scaffold(body: RestoreScreen())),
    ),
  );
  await tester.pump();
}

Finder _field(int i) => find.byType(EditableText).at(i);

PhraseGrid _grid(WidgetTester tester) => tester.widget<PhraseGrid>(find.byType(PhraseGrid));
PhraseEntry _entry(WidgetTester tester) => _grid(tester).entry;

bool _focusedOn(WidgetTester tester, int i) => _entry(tester).focus[i].hasFocus;

/// The phrase step's primary button: "Continue" until the phrase checks out, then "Use N words".
EButton _continue(WidgetTester tester) => tester.widget<EButton>(
  find.byWidgetPredicate((w) => w is EButton && (w.label == 'Continue' || RegExp(r'^Use \d+ words$').hasMatch(w.label))),
);

bool _continueEnabled(WidgetTester tester) => _continue(tester).onPressed != null;

/// Pastes [text] into field [i] with Ctrl+V, the clipboard holding it.
Future<void> _paste(WidgetTester tester, int i, String text) async {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.getData') return {'text': text};
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  _entry(tester).focusField(i);
  await tester.pump();
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
  await tester.pump();
}

/// 24 words that pass the checksum and whose first 12 do too (the 12-word vector, 11 more
/// "abandon" and a last word found here), so a typed 12-word prefix "checks out" on the way.
List<String> _v24With12Prefix() {
  final head = [..._v12, ...List.filled(11, 'abandon')];
  return [...head, bip39List.firstWhere((w) => bip39PhraseValid([...head, w]))];
}

Future<void> _type(WidgetTester tester, int i, String text) async {
  await tester.enterText(_field(i), text);
  await tester.pump();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

void main() {
  group('bip39PhraseValid', () {
    test('accepts the standard vectors of every length', () {
      expect(bip39PhraseValid(_v12), isTrue);
      expect(bip39PhraseValid(_vector(15, 'address')), isTrue);
      expect(bip39PhraseValid(_vector(18, 'agent')), isTrue);
      expect(bip39PhraseValid(_vector(21, 'admit')), isTrue);
      expect(bip39PhraseValid(_v24), isTrue);
      expect(bip39PhraseValid('legal winner thank year wave sausage worth useful legal winner thank yellow'.split(' ')), isTrue);
      expect(bip39PhraseValid([...List.filled(23, 'zoo'), 'vote']), isTrue);
    });

    test('refuses a bad checksum, a bad length and a word off the list', () {
      expect(bip39PhraseValid(List.filled(12, 'abandon')), isFalse);
      expect(bip39PhraseValid(List.filled(13, 'abandon')), isFalse);
      expect(bip39PhraseValid([...List.filled(11, 'abandon'), 'h4rbor']), isFalse);
      expect(bip39PhraseValid([]), isFalse);
    });
  });

  group('PhraseEntry.split', () {
    test('drops line breaks, commas, extra spaces and numbering', () {
      expect(PhraseEntry.split('1. abandon\n2) ability,  3: able\r\n4 about'), ['abandon', 'ability', 'able', 'about']);
      expect(PhraseEntry.split('Abandon, ABILITY'), ['abandon', 'ability']);
      expect(PhraseEntry.split('   '), isEmpty);
    });

    test('numbering glued to a word, dashes and full stops are dropped', () {
      expect(PhraseEntry.split('1.abandon 2)ability 3:able'), ['abandon', 'ability', 'able']);
      expect(PhraseEntry.split('1 - abandon\n2 - ability'), ['abandon', 'ability']);
      expect(PhraseEntry.split('abandon ability able.'), ['abandon', 'ability', 'able']);
      expect(PhraseEntry.split('12) about. - .'), ['about']);
      expect(PhraseEntry.split('1'), isEmpty);
    });
  });

  group('PhraseEntry.checksumOk', () {
    test('asks the core once per word list', () {
      var calls = 0;
      final e = PhraseEntry(
        check: (ws) {
          calls++;
          return bip39PhraseValid(ws);
        },
      );
      addTearDown(e.dispose);
      e.paste(_v12.join(' '));
      for (var i = 0; i < 5; i++) {
        expect(e.complete, isTrue);
        expect(e.length, 12);
      }
      expect(calls, 1);
      e.controllers[11].text = 'abandon';
      e.changed(11, 'abandon');
      expect(e.checksumOk, isFalse);
      expect(calls, 2);
    });
  });

  testWidgets('24 numbered fields from the start; nothing is red while a word is typed', (tester) async {
    await _pump(tester);
    expect(find.byType(EditableText), findsNWidgets(24));
    expect(find.text('0 of 24 words'), findsOneWidget);
    expect(_focusedOn(tester, 0), isTrue, reason: 'the first field has focus on open');
    for (final t in ['a', 'ab', 'aba', 'aban', 'aband', 'abando', 'abandon']) {
      await _type(tester, 0, t);
      expect(_entry(tester).invalid, isEmpty, reason: '"$t" is being typed');
      expect(find.textContaining('not in the word list'), findsNothing);
      expect(_focusedOn(tester, 0), isTrue, reason: 'focus stays while typing "$t"');
    }
    expect(find.text('1 of 24 words'), findsOneWidget);
  });

  testWidgets('typing the last word: no checksum error while its prefix is a word of its own', (tester) async {
    // 23 words, then a last word that checks out and has a shorter list word as its prefix
    // ("fat" of "fatigue"): typing that prefix must not show the checksum error yet.
    final head = List.filled(23, 'abandon');
    final last = bip39List.firstWhere((w) {
      if (!bip39PhraseValid([...head, w])) return false;
      return [for (var n = 3; n < w.length; n++) w.substring(0, n)]
          .any((p) => bip39Words.contains(p) && !bip39PhraseValid([...head, p]));
    });
    final prefix = [for (var n = 3; n < last.length; n++) last.substring(0, n)]
        .firstWhere((p) => bip39Words.contains(p) && !bip39PhraseValid([...head, p]));
    await _pump(tester);
    for (var i = 0; i < 23; i++) {
      await _type(tester, i, head[i]);
    }
    _entry(tester).focusField(23);
    await tester.pump();
    await _type(tester, 23, prefix);
    expect(find.textContaining('check number does not match'), findsNothing, reason: '"$prefix" of "$last" is being typed');
    await _type(tester, 23, last);
    expect(find.text('All 24 words check out.'), findsOneWidget);
    // A wrong last word shows the error once the field is left.
    await _type(tester, 23, prefix);
    _entry(tester).focusField(0);
    await tester.pump();
    expect(find.textContaining('check number does not match'), findsOneWidget);
  });

  testWidgets('a wrong word is marked when focus leaves it and cleared once corrected', (tester) async {
    await _pump(tester);
    await _type(tester, 0, 'abandn');
    expect(find.textContaining('not in the word list'), findsNothing);
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focusedOn(tester, 1), isTrue);
    expect(_entry(tester).invalid, {0});
    expect(find.text('Word 1, "abandn", is not in the word list.'), findsOneWidget);
    await _type(tester, 0, 'abandon');
    expect(_entry(tester).invalid, isEmpty);
    expect(find.textContaining('not in the word list'), findsNothing);
  });

  testWidgets('the 12-word vector typed with spaces: Space moves on, Enter moves on, the button continues', (tester) async {
    await _pump(tester);
    for (var i = 0; i < 12; i++) {
      await _type(tester, i, _v12[i]);
      expect(_entry(tester).invalid, isEmpty);
      if (i < 11) {
        await _key(tester, LogicalKeyboardKey.space);
        expect(_focusedOn(tester, i + 1), isTrue, reason: 'Space after word ${i + 1}');
        expect(_entry(tester).controllers[i].text, _v12[i], reason: 'no space in the field');
      }
    }
    expect(_continueEnabled(tester), isTrue, reason: 'the 12 typed words pass the checksum');
    expect(find.text('12 of 12 words'), findsOneWidget);
    expect(_continue(tester).label, 'Continue');
    await _key(tester, LogicalKeyboardKey.enter);
    expect(find.byKey(const ValueKey('wallet-name-title')), findsNothing, reason: 'a typed phrase under 24 words goes on with the button only');
    expect(_focusedOn(tester, 12), isTrue);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.byKey(const ValueKey('wallet-name-title')), findsOneWidget);
    expect(find.textContaining('Set the password that unlocks this wallet'), findsOneWidget);
  });

  testWidgets('a 24-word phrase typed with Enter after each word never leaves early', (tester) async {
    final words = _v24With12Prefix();
    expect(bip39PhraseValid(words.take(12).toList()), isTrue, reason: 'the 12-word prefix checks out on its own');
    await _pump(tester);
    for (var i = 0; i < 24; i++) {
      await _type(tester, i, words[i]);
      await _key(tester, LogicalKeyboardKey.enter);
      if (i < 23) {
        expect(find.byKey(const ValueKey('wallet-name-title')), findsNothing, reason: 'Enter after word ${i + 1}');
        expect(_focusedOn(tester, i + 1), isTrue, reason: 'Enter after word ${i + 1} moves on');
      }
    }
    expect(find.byKey(const ValueKey('wallet-name-title')), findsOneWidget, reason: 'Enter on the 24th word continues');
    expect(find.textContaining('Set the password that unlocks this wallet'), findsOneWidget);
  });

  testWidgets('Enter takes the completion from four letters only; Tab always', (tester) async {
    await _pump(tester);
    await _type(tester, 0, 'aba');
    expect(_entry(tester).suggestion(0), 'abandon');
    await _key(tester, LogicalKeyboardKey.enter);
    expect(_entry(tester).controllers[0].text, 'aba', reason: 'three letters: Enter leaves the completion');
    expect(_entry(tester).invalid, {0});
    expect(_focusedOn(tester, 1), isTrue);
    await _type(tester, 1, 'abil');
    await _key(tester, LogicalKeyboardKey.enter);
    expect(_entry(tester).controllers[1].text, 'ability', reason: 'four letters start one word only');
    await _type(tester, 2, 'ab');
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_entry(tester).controllers[2].text, 'abandon', reason: 'Tab takes the completion');
  });

  testWidgets('a paste takes the clipboard, not the field joined with it', (tester) async {
    await _pump(tester);
    await _type(tester, 0, 't');
    await _paste(tester, 0, ['able', ..._v12.skip(1)].join(' '));
    expect(_entry(tester).controllers[0].text, 'able');
    expect(_entry(tester).controllers[0].text, isNot('table'));
    expect(_entry(tester).count, 12);
    // One word pasted into a field replaces what it held, there only.
    await _type(tester, 3, 'ab');
    await _paste(tester, 3, 'zoo');
    expect(_entry(tester).controllers[3].text, 'zoo');
    expect(_entry(tester).controllers[0].text, 'able');
  });

  testWidgets('a typed digit stays in its field: no paste, no focus move', (tester) async {
    await _pump(tester);
    await _type(tester, 0, 'abandon');
    await _key(tester, LogicalKeyboardKey.space);
    expect(_focusedOn(tester, 1), isTrue);
    await _type(tester, 1, '1');
    expect(_focusedOn(tester, 1), isTrue);
    expect(_entry(tester).controllers[1].text, '1');
    expect(_entry(tester).controllers[0].text, 'abandon');
    expect(_entry(tester).pasteError, isNull);
  });

  testWidgets('a typed 12-word phrase: 12 of 12, the rest dimmed, Continue on', (tester) async {
    await _pump(tester);
    for (var i = 0; i < 12; i++) {
      await _type(tester, i, _v12[i]);
      if (i < 11) await _key(tester, LogicalKeyboardKey.space);
    }
    expect(find.text('12 of 12 words'), findsOneWidget);
    expect(find.text('All 12 words check out.'), findsOneWidget);
    expect(_continueEnabled(tester), isTrue);
    final dimmed = tester.widgetList<Opacity>(find.byType(Opacity)).where((o) => o.opacity < 1).length;
    expect(dimmed, 12, reason: 'fields 13 to 24 are dimmed');
    expect(_entry(tester).phrase, _v12);
  });

  testWidgets('a typed phrase of 12 words with a bad checksum is a soft note, not an error', (tester) async {
    await _pump(tester);
    for (var i = 0; i < 12; i++) {
      await _type(tester, i, 'abandon');
      await _key(tester, LogicalKeyboardKey.space);
    }
    expect(_focusedOn(tester, 12), isTrue, reason: 'Space after word 12 moves on to 13');
    expect(find.text('12 of 24 words'), findsOneWidget);
    expect(find.textContaining('12 words so far; the check number does not match.'), findsOneWidget);
    expect(_continueEnabled(tester), isFalse);
  });

  testWidgets('pasting a numbered 24-word phrase with line breaks into any field fills all 24', (tester) async {
    await _pump(tester);
    final text = [for (var i = 0; i < 24; i++) '${i + 1}. ${_v24[i]}'].join('\n');
    await _paste(tester, 5, text);
    expect([for (final c in _entry(tester).controllers) c.text], _v24);
    expect(find.text('24 of 24 words'), findsOneWidget);
    expect(find.text('All 24 words check out.'), findsOneWidget);
    expect(_continueEnabled(tester), isTrue);
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.byKey(const ValueKey('wallet-name-title')), findsOneWidget);
    expect(find.byType(EditableText), findsNWidgets(2), reason: 'password and confirmation; the wallet name is the title, edited from its pen');
  });

  testWidgets('pasting 12 words sets the count to 12 with no error', (tester) async {
    await _pump(tester);
    await _type(tester, 0, _v12.join(' '));
    expect(_entry(tester).count, 12);
    expect(find.text('12 of 12 words'), findsOneWidget);
    expect(find.text('All 12 words check out.'), findsOneWidget);
    expect(find.textContaining('not'), findsNothing);
    expect(_continueEnabled(tester), isTrue);
  });

  testWidgets('pasting 13 words says what a phrase has', (tester) async {
    await _pump(tester);
    await _type(tester, 0, List.filled(13, 'abandon').join(' '));
    expect(find.text('13 words pasted; a phrase has 12, 15, 18, 21 or 24'), findsOneWidget);
    expect(find.text('13 of 24 words'), findsOneWidget);
    expect(_continueEnabled(tester), isFalse);
  });

  testWidgets('a pasted phrase with a bad checksum shows the one line', (tester) async {
    await _pump(tester);
    await _type(tester, 0, List.filled(12, 'abandon').join(' '));
    expect(find.text('This phrase’s check number does not match. Compare every word with the paper.'), findsOneWidget);
    expect(_continueEnabled(tester), isFalse);
    await _type(tester, 0, _v24.join(' '));
    expect(find.text('All 24 words check out.'), findsOneWidget);
  });

  testWidgets('a pasted word off the list is marked at once, by number', (tester) async {
    await _pump(tester);
    await _type(tester, 0, [..._v24.take(23), 'h4rbor'].join(' '));
    expect(find.text('Word 24, "h4rbor", is not in the word list.'), findsOneWidget);
    expect(_focusedOn(tester, 23), isTrue, reason: 'focus lands on the bad word');
    expect(_continueEnabled(tester), isFalse);
  });

  testWidgets('Backspace in an empty field goes back; Tab takes the completion', (tester) async {
    await _pump(tester);
    await _type(tester, 0, 'aban');
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_entry(tester).controllers[0].text, 'abandon', reason: 'Tab accepts the dim completion');
    expect(_focusedOn(tester, 1), isTrue);
    await _key(tester, LogicalKeyboardKey.backspace);
    expect(_focusedOn(tester, 0), isTrue);
    expect(_entry(tester).controllers[0].text, 'abandon', reason: 'going back deletes nothing');
    // A word that is itself in the list gets no completion ("act" is not completed to "action").
    await _type(tester, 0, 'act');
    expect(_entry(tester).suggestion(0), isNull);
    await _type(tester, 0, 'acti');
    expect(_entry(tester).suggestion(0), 'action');
  });

  testWidgets('the paste button fills the grid from the clipboard', (tester) async {
    await _pump(tester);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return {'text': _v12.join(', ')};
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.tap(find.text('Paste'));
    await tester.pump();
    expect(find.text('12 of 12 words'), findsOneWidget);
    // The focus is in the grid, not on the button, so Enter goes on rather than pasting again.
    expect(_entry(tester).focus.any((f) => f.hasFocus), isTrue);
    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(find.text('0 of 24 words'), findsOneWidget);
    expect(_entry(tester).count, isNull);
  });

  testWidgets('the grid keeps its place and the first field its focus at a narrow width', (tester) async {
    await _pump(tester, size: const Size(700, 900));
    final before = tester.getTopLeft(find.byType(PhraseGrid));
    for (final t in ['a', 'ab', 'aband', 'abandon']) {
      await _type(tester, 0, t);
      expect(tester.getTopLeft(find.byType(PhraseGrid)), before);
      expect(_focusedOn(tester, 0), isTrue);
    }
  });
}
