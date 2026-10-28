// SPDX-License-Identifier: Apache-2.0
// A copied recovery phrase leaves the clipboard after 60 s and when the wallet locks, on the
// phone and on the desktop; a clipboard that has something else by then keeps it.
import 'package:epic_wallet/src/desktop/data/mock_wallet.dart';
import 'package:epic_wallet/src/desktop/data/state.dart';
import 'package:epic_wallet/src/phrase_clipboard.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  String? clip;
  const phrase = 'abandon ability able about above absent absorb abstract absurd abuse access accident';

  setUp(() {
    clip = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clip = (call.arguments as Map)['text'] as String?;
        if (call.method == 'Clipboard.getData') return clip == null ? null : <String, dynamic>{'text': clip};
        return null;
      },
    );
  });
  tearDown(() async {
    await clearCopiedPhrase();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('60 s: still there at 59 s, gone at 60 s', () {
    fakeAsync((async) {
      copyPhraseToClipboard(phrase);
      async.flushMicrotasks();
      expect(clip, phrase);
      async.elapse(const Duration(seconds: 59));
      expect(clip, phrase);
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(clip, '');
    });
  });

  test('something copied after the phrase stays', () {
    fakeAsync((async) {
      copyPhraseToClipboard(phrase);
      async.flushMicrotasks();
      clip = 'an address';
      async.elapse(phraseClipboardLifetime);
      async.flushMicrotasks();
      expect(clip, 'an address');
    });
  });

  test('the phone: locking the wallet clears it at once', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await copyPhraseToClipboard(phrase), isTrue);
    container.read(sessionProvider.notifier).lock();
    await pumpEventQueue();
    expect(clip, '');
  });

  test('the desktop: Lock clears it at once', () async {
    final container = ProviderContainer(
      overrides: [deskApiProvider.overrideWithValue(MockDeskWallet(delay: Duration.zero))],
    );
    addTearDown(container.dispose);
    expect(await copyPhraseToClipboard(phrase), isTrue);
    await container.read(deskProvider.notifier).lock();
    await pumpEventQueue();
    expect(clip, '');
  });

  test('a lock with nothing copied leaves the clipboard alone', () async {
    clip = 'an address';
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(sessionProvider.notifier).lock();
    await pumpEventQueue();
    expect(clip, 'an address');
  });
}
