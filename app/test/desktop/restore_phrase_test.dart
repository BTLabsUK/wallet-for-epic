// SPDX-License-Identifier: Apache-2.0
// Restore's phrase grid: 24 numbered fields, a paste sets the count, words are checked on
// blur or commit only, the checksum once the phrase is complete. The mock wallet answers the
// checksum with the real BIP-39 rule, so the standard vectors apply.
import 'dart:ui' as ui;

import 'package:epic_wallet/src/bip39_words.dart';
import 'package:epic_wallet/src/desktop/data/phrase_check.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/phrase_grid.dart';
import 'package:epic_wallet/src/desktop/screens/onboarding/restore_screen.dart';
import 'package:epic_wallet/src/desktop/theme/theme.dart';
import 'package:epic_wallet/src/desktop/widgets/buttons.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _l = englishStrings;

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
  find.byWidgetPredicate((w) => w is EButton && (w.label == _l.commonContinue || RegExp(r'^Use \d+ words$').hasMatch(w.label))),
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

/// Types [text] key by key the way the desktop engines deliver it: each key event goes to the
/// app first, and only a key the app leaves alone becomes text, inserted by the engine into its
/// copy of the field and sent as a separate message to the field that had the input connection
/// when the key was pressed. With [lag] 1 that text arrives after the next key's event (fast
/// typing); with 0, before it. Text sent to a connection that has closed since is dropped.
/// Without [keys], characters come as text alone, with no key event (Windows input methods,
/// dictation, a remote desktop).
Future<void> _typeKeys(WidgetTester tester, String text, {int lag = 1, bool keys = true}) async {
  final input = tester.testTextInput;
  var seen = 0;
  int? client;
  var value = TextEditingValue.empty;
  // Follows what the app told the engine: which field has the connection, and its text.
  void follow() {
    for (; seen < input.log.length; seen++) {
      final call = input.log[seen];
      switch (call.method) {
        case 'TextInput.setClient':
          client = (call.arguments as List)[0] as int;
          value = TextEditingValue.empty;
        case 'TextInput.setEditingState':
          value = TextEditingValue.fromJSON((call.arguments as Map).cast<String, dynamic>());
        case 'TextInput.clearClient':
          client = null;
      }
    }
  }

  final pending = <(int, TextEditingValue)>[];
  Future<void> deliver(int keep) async {
    while (pending.length > keep) {
      final (id, v) = pending.removeAt(0);
      final call = MethodCall('TextInputClient.updateEditingState', [id, v.toJSON()]);
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(call),
        (_) {},
      );
    }
  }

  for (final ch in text.split('')) {
    follow();
    final handled = keys && await tester.sendKeyDownEvent(LogicalKeyboardKey(ch.toLowerCase().codeUnitAt(0)), character: ch);
    follow();
    if (!handled && client != null) {
      final sel = value.selection.isValid ? value.selection : TextSelection.collapsed(offset: value.text.length);
      final t = value.text.replaceRange(sel.start, sel.end, ch);
      value = TextEditingValue(text: t, selection: TextSelection.collapsed(offset: sel.start + 1));
      pending.add((client!, value));
    }
    await deliver(lag);
    if (keys) await tester.sendKeyUpEvent(LogicalKeyboardKey(ch.toLowerCase().codeUnitAt(0)));
  }
  await deliver(0);
  await tester.pump();
}

/// Types [text] the way a desktop engine delivers fast typing: the key events of [batch] keys come
/// in one key message, and the framework hands all of them to the field that has the focus when
/// the message arrives (a focus move made by one of them takes effect only after the message).
Future<void> _typeBatched(WidgetTester tester, String text, {required int batch}) async {
  // The engine's own entry points (deprecated for apps, still what the desktop engines call).
  // ignore: deprecated_member_use
  final keys = tester.binding.keyEventManager;
  final chars = text.split('');
  for (var start = 0; start < chars.length; start += batch) {
    for (final ch in chars.skip(start).take(batch)) {
      for (final down in [true, false]) {
        // ignore: deprecated_member_use
        keys.handleKeyData(
          ui.KeyData(
            timeStamp: Duration.zero,
            type: down ? ui.KeyEventType.down : ui.KeyEventType.up,
            physical: 0x100000000 + ch.codeUnitAt(0),
            logical: ch.toLowerCase().codeUnitAt(0),
            character: down ? ch : null,
            synthesized: false,
          ),
        );
      }
    }
    // The raw message that makes the framework dispatch every key event since the last one.
    // ignore: deprecated_member_use
    await keys.handleRawKeyMessage(<String, dynamic>{
      'type': 'keyup',
      'keymap': 'linux',
      'toolkit': 'gtk',
      'keyCode': 0x61,
      'scanCode': 0x26,
      'modifiers': 0,
      'unicodeScalarValues': 0,
    });
    await tester.pump();
  }
}

/// Text widgets (labels, status and error lines; not the word fields) that show [word].
Finder _shown(String word) => find.byWidgetPredicate(
  (w) => w is Text && (w.data ?? w.textSpan?.toPlainText() ?? '').contains(word),
);

Future<void> _type(WidgetTester tester, int i, String text) async {
  await tester.enterText(_field(i), text);
  await tester.pump();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

void main() {
  // The start month shows as a month and year (localMonthYear).
  setUpAll(initializeDateFormatting);
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
      _entry(tester).controllers[i].text = head[i];
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
    expect(find.text('Word 1 is not in the word list.'), findsOneWidget);
    expect(_shown('abandn'), findsNothing, reason: 'the error names the word by number only');
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
    expect(_continue(tester).label, _l.commonContinue);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(find.byKey(const ValueKey('wallet-name-title')), findsNothing, reason: 'a typed phrase under 24 words goes on with the button only');
    expect(_focusedOn(tester, 12), isTrue);
    await tester.tap(find.text(_l.commonContinue));
    await tester.pump();
    expect(find.byKey(const ValueKey('wallet-name-title')), findsOneWidget);
    expect(find.textContaining('It unlocks this wallet'), findsOneWidget);
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
    expect(find.textContaining('It unlocks this wallet'), findsOneWidget);
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
    await tester.tap(find.text(_l.commonContinue));
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
    expect(find.text('13 words pasted; a phrase has 12, 15, 18, 21 or 24.'), findsOneWidget);
    expect(find.text('13 of 24 words'), findsOneWidget);
    expect(_continueEnabled(tester), isFalse);
  });

  testWidgets('a pasted phrase with a bad checksum shows the one line', (tester) async {
    await _pump(tester);
    await _type(tester, 0, List.filled(12, 'abandon').join(' '));
    expect(find.text(_l.deskOnbRestoreChecksumFirm), findsOneWidget);
    expect(_continueEnabled(tester), isFalse);
    await _type(tester, 0, _v24.join(' '));
    expect(find.text('All 24 words check out.'), findsOneWidget);
  });

  testWidgets('a pasted word off the list is marked at once, by number', (tester) async {
    await _pump(tester);
    await _type(tester, 0, [..._v24.take(23), 'h4rbor'].join(' '));
    expect(find.text('Word 24 is not in the word list.'), findsOneWidget);
    expect(_shown('h4rbor'), findsNothing, reason: 'the error names the word by number only');
    expect(_focusedOn(tester, 23), isTrue, reason: 'focus lands on the bad word');
    expect(_continueEnabled(tester), isFalse);
  });

  for (final (speed, lag) in [('slowly', 0), ('fast', 1)]) {
    testWidgets('a 24-word phrase typed key by key, $speed, fills every field and checks out', (tester) async {
      final words = _v24With12Prefix();
      await _pump(tester);
      expect(_focusedOn(tester, 0), isTrue);
      await _typeKeys(tester, words.join(' '), lag: lag);
      expect([for (var i = 0; i < 24; i++) _entry(tester).controllers[i].text], words);
      expect(_entry(tester).invalid, isEmpty);
      expect(find.text('All 24 words check out.'), findsOneWidget);
      expect(_continueEnabled(tester), isTrue);
    });
  }

  for (final batch in [3, 5]) {
    testWidgets('a 24-word phrase typed so fast that $batch keys come in one key message fills every field', (tester) async {
      final words = _v24With12Prefix();
      await _pump(tester);
      await _typeBatched(tester, words.join(' '), batch: batch);
      expect([for (var i = 0; i < 24; i++) _entry(tester).controllers[i].text], words);
      expect(_entry(tester).invalid, isEmpty);
      expect(find.text('All 24 words check out.'), findsOneWidget);
      expect(_continueEnabled(tester), isTrue);
    });
  }

  testWidgets('a 24-word phrase that comes as text without key events fills field by field', (tester) async {
    final words = _v24With12Prefix();
    await _pump(tester);
    await _typeKeys(tester, words.join(' '), lag: 0, keys: false);
    expect([for (var i = 0; i < 24; i++) _entry(tester).controllers[i].text], words);
    expect(_entry(tester).count, isNull, reason: 'typing, not a paste');
    expect(find.text('All 24 words check out.'), findsOneWidget);
    expect(_continueEnabled(tester), isTrue);
  });

  testWidgets('a few words at once in a later field go there and on, not to field 1', (tester) async {
    await _pump(tester);
    await _typeKeys(tester, 'abandon ', lag: 0, keys: false);
    await _type(tester, 1, 'ability able abo');
    final e = _entry(tester);
    expect([for (var i = 0; i < 5; i++) e.controllers[i].text], ['abandon', 'ability', 'able', 'abo', '']);
    expect(e.invalid, isEmpty, reason: 'the last word is still being typed');
    expect(_focusedOn(tester, 3), isTrue);
    await _type(tester, 3, 'abqz ');
    expect(e.invalid, {3});
    expect(_focusedOn(tester, 4), isTrue);
  });

  testWidgets('typed letters go in at the cursor, lower-cased; Backspace still deletes', (tester) async {
    await _pump(tester);
    await _typeKeys(tester, 'Abndon');
    final c = _entry(tester).controllers[0];
    expect(c.text, 'abndon');
    c.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump();
    await _typeKeys(tester, 'a');
    expect(c.text, 'abandon');
    expect(c.selection, const TextSelection.collapsed(offset: 3));
    c.selection = const TextSelection(baseOffset: 0, extentOffset: 7);
    await tester.pump();
    await _typeKeys(tester, 'x');
    expect(c.text, 'x', reason: 'a typed letter replaces the selection');
    await _key(tester, LogicalKeyboardKey.backspace);
    expect(c.text, isEmpty);
  });

  testWidgets('several words off the list: the line gives their numbers, never the words', (tester) async {
    await _pump(tester);
    await _typeKeys(tester, 'abandon qzxw abandon vrolp ');
    expect(_entry(tester).invalid, {1, 3});
    expect(find.text('Words 2, 4 are not in the word list.'), findsOneWidget);
    expect(_shown('qzxw'), findsNothing);
    expect(_shown('vrolp'), findsNothing);
    expect(_shown('abandon'), findsNothing);
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
    await tester.tap(find.text(_l.commonPaste));
    await tester.pump();
    expect(find.text('12 of 12 words'), findsOneWidget);
    // The focus is in the grid, not on the button, so Enter goes on rather than pasting again.
    expect(_entry(tester).focus.any((f) => f.hasFocus), isTrue);
    await tester.tap(find.text(_l.deskOnbRestoreClear));
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
