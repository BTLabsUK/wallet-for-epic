// SPDX-License-Identifier: Apache-2.0
// The window's first size and its kept place (lib/src/desktop/app/window_placement.dart): the
// first-start rule on the display sizes testers have, the restore rule (valid, off-screen, too
// big, display gone), the minimum, the memory's JSON, and the place written to and read from the
// desktop store through window_manager's and screen_retriever's channels.
import 'package:epic_wallet/src/desktop/app/window_placement.dart';
import 'package:epic_wallet/src/desktop/data/desk_store.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_retriever/screen_retriever.dart' show Display;

/// A display of [w]x[h] logical px whose work area loses [panel] px at the bottom.
DeskDisplay _display(String key, double w, double h, {double panel = 0, double left = 0, double scale = 1}) =>
    DeskDisplay(key: key, work: Rect.fromLTWH(left, 0, w, h - panel), scale: scale);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('first start', () {
    test('80 % of the work area, centred', () {
      final d = _display('a', 1920, 1080, panel: 40);
      expect(firstStartFrame(d), const Rect.fromLTWH(192, 104, 1536, 832));
    });

    test('1366x768: 80 % wide, the minimum height', () {
      final d = _display('a', 1366, 768, panel: 28);
      final f = firstStartFrame(d);
      expect(f.size, const Size(1093, 700));
      expect(f.left, 137);
      expect(f.top, 20);
    });

    test('1920x1080 at 150 %: 1280x688 logical, the height all of it', () {
      // Windows' 48 px taskbar: (1080 - 48) / 1.5 = 688 logical.
      final d = _display('a', 1280, 720, panel: 32, scale: 1.5);
      final f = firstStartFrame(d);
      expect(f, const Rect.fromLTWH(128, 0, 1024, 688));
      // Whole physical pixels.
      expect(f.width * 1.5 % 1, 0);
    });

    test('2560x1440 and 2474x1338: capped at 1600x1000', () {
      expect(firstStartFrame(_display('a', 2560, 1440, panel: 40)), const Rect.fromLTWH(480, 200, 1600, 1000));
      expect(firstStartFrame(_display('b', 2474, 1338, panel: 40)).size, deskWindowMaxStart);
    });

    test('a work area smaller than the minimum: all of it', () {
      final d = _display('a', 760, 600);
      expect(firstStartFrame(d), const Rect.fromLTWH(0, 0, 760, 600));
      expect(deskWindowMinOn(d), const Size(760, 600));
    });

    test('never under the minimum where it fits', () {
      for (final (w, h) in [(1024.0, 768.0), (1280.0, 800.0), (900.0, 720.0)]) {
        final f = firstStartFrame(_display('a', w, h));
        expect(f.width, greaterThanOrEqualTo(deskWindowMinSize.width), reason: '$w x $h');
        expect(f.height, greaterThanOrEqualTo(deskWindowMinSize.height), reason: '$w x $h');
      }
    });

    test('a fractional scale lands on whole physical pixels', () {
      final d = DeskDisplay(key: 'a', work: const Rect.fromLTWH(0, 0, 1229.6, 819.2), scale: 1.25);
      final f = firstStartFrame(d);
      for (final v in [f.left, f.top, f.width, f.height]) {
        expect((v * 1.25 - (v * 1.25).roundToDouble()).abs(), lessThan(1e-9), reason: '$v');
      }
    });

    test('on a second display, on its own work area', () {
      final d = _display('b', 1920, 1080, left: 2560);
      final f = firstStartFrame(d);
      expect(f.left, 2560 + 192);
      expect(d.work.contains(f.center), isTrue);
    });
  });

  group('restore', () {
    final main = _display('main', 1920, 1080, panel: 40);
    final side = _display('side', 2560, 1440, left: 1920);

    test('a saved window that fits comes back as it was, maximised too', () {
      const saved = SavedWindow(frame: Rect.fromLTWH(100, 50, 1200, 800), maximized: true);
      final start = windowStart(
        displays: [main, side],
        openOn: main,
        memory: const WindowMemory(last: 'main', displays: {'main': saved}),
      );
      expect(start.restored, isTrue);
      expect(start.frame, saved.frame);
      expect(start.maximized, isTrue);
    });

    test('the last display wins over the one the pointer is on', () {
      const onSide = SavedWindow(frame: Rect.fromLTWH(2100, 100, 1400, 900));
      const onMain = SavedWindow(frame: Rect.fromLTWH(10, 10, 900, 700));
      final start = windowStart(
        displays: [main, side],
        openOn: main,
        memory: const WindowMemory(last: 'side', displays: {'side': onSide, 'main': onMain}),
      );
      expect(start.display.key, 'side');
      expect(start.frame, onSide.frame);
    });

    test('the last display unplugged: the saved window of the display the pointer is on', () {
      const onSide = SavedWindow(frame: Rect.fromLTWH(2100, 100, 1400, 900));
      const onMain = SavedWindow(frame: Rect.fromLTWH(10, 10, 900, 700));
      final start = windowStart(
        displays: [main],
        openOn: main,
        memory: const WindowMemory(last: 'side', displays: {'side': onSide, 'main': onMain}),
      );
      expect(start.display.key, 'main');
      expect(start.frame, onMain.frame);
      expect(start.restored, isTrue);
    });

    test('unplugged, nothing saved for this display: the first-start rule', () {
      const onSide = SavedWindow(frame: Rect.fromLTWH(2100, 100, 1400, 900), maximized: true);
      final start = windowStart(displays: [main], openOn: main, memory: const WindowMemory(last: 'side', displays: {'side': onSide}));
      expect(start.restored, isFalse);
      expect(start.frame, firstStartFrame(main));
      // Maximised belonged to the display that is gone.
      expect(start.maximized, isFalse);
    });

    test('off-screen on its display (the layout moved): the first-start rule', () {
      const saved = SavedWindow(frame: Rect.fromLTWH(-1500, 50, 1000, 800));
      final start = windowStart(displays: [main], openOn: main, memory: const WindowMemory(last: 'main', displays: {'main': saved}));
      expect(start.restored, isFalse);
      expect(start.frame, firstStartFrame(main));
    });

    test('bigger than the work area now (the scale went up): the first-start rule, still maximised', () {
      // 1600x1000 saved at 100 %; the same display at 150 % is 1280x693 logical.
      const saved = SavedWindow(frame: Rect.fromLTWH(160, 20, 1600, 1000), maximized: true);
      final scaled = _display('main', 1280, 720, panel: 27, scale: 1.5);
      final start = windowStart(displays: [scaled], openOn: scaled, memory: const WindowMemory(last: 'main', displays: {'main': saved}));
      expect(start.restored, isFalse);
      expect(start.frame, firstStartFrame(scaled));
      expect(start.maximized, isTrue);
    });

    test('a little over the edge: moved in, same size', () {
      const saved = SavedWindow(frame: Rect.fromLTWH(1000, 400, 1200, 800));
      final f = restoredFrame(saved, main);
      expect(f, const Rect.fromLTWH(720, 240, 1200, 800));
    });

    test('under the minimum (an older version): grown to it', () {
      const saved = SavedWindow(frame: Rect.fromLTWH(100, 100, 800, 640));
      expect(restoredFrame(saved, main), const Rect.fromLTWH(100, 100, 800, 700));
    });

    test('nothing saved: the first-start rule on the display the pointer is on', () {
      final start = windowStart(displays: [main, side], openOn: side);
      expect(start.restored, isFalse);
      expect(start.display.key, 'side');
      expect(start.frame, firstStartFrame(side));
    });

    test('displayOf: the display holding the centre, else the one overlapped most', () {
      expect(displayOf(const Rect.fromLTWH(1800, 100, 400, 300), [main, side])?.key, 'side');
      expect(displayOf(const Rect.fromLTWH(1700, 1060, 400, 300), [main, side])?.key, 'side');
      expect(displayOf(const Rect.fromLTWH(-900, -900, 100, 100), [main, side]), isNull);
    });
  });

  group('memory', () {
    test('JSON round trip', () {
      const m = WindowMemory(
        last: 'b',
        displays: {
          'a': SavedWindow(frame: Rect.fromLTWH(1, 2, 1000, 700)),
          'b': SavedWindow(frame: Rect.fromLTWH(-5, 7.5, 1600, 1000), maximized: true),
        },
      );
      expect(WindowMemory.fromJson(m.toJson()), m);
    });

    test('garbage reads as nothing saved, a bad entry is skipped', () {
      expect(WindowMemory.fromJson(null), WindowMemory.empty);
      expect(WindowMemory.fromJson('x'), WindowMemory.empty);
      final m = WindowMemory.fromJson({
        'last': 3,
        'displays': {
          'a': {'x': 0, 'y': 0, 'w': 900, 'h': 700},
          'b': {'x': 0, 'y': 0, 'w': -1, 'h': 700},
          'c': 'no',
        },
      });
      expect(m.last, isNull);
      expect(m.displays.keys, ['a']);
    });

    test('withSaved: that display becomes the last, the oldest goes past the limit', () {
      var m = WindowMemory.empty;
      for (var i = 0; i < 10; i++) {
        m = m.withSaved('d$i', SavedWindow(frame: Rect.fromLTWH(0, 0, 900 + i.toDouble(), 700)));
      }
      expect(m.last, 'd9');
      expect(m.displays.length, 8);
      expect(m.displays.containsKey('d0'), isFalse);
      // Saving again moves it to the newest.
      m = m.withSaved('d2', const SavedWindow(frame: Rect.fromLTWH(0, 0, 1000, 700)));
      expect(m.displays.keys.last, 'd2');
    });

    test('Linux gives no display id: the key is its name, size and work-area origin', () {
      final d = deskDisplayOf(
        Display.fromJson({
          'id': '',
          'name': 'DELL U2720Q',
          'size': {'width': 2560.0, 'height': 1440.0},
          'visiblePosition': {'dx': 1920.0, 'dy': 0.0},
          'visibleSize': {'width': 2560.0, 'height': 1400.0},
          'scaleFactor': 1.0,
        }),
      );
      expect(d.key, 'DELL U2720Q@2560x1440+1920,0');
      expect(d.work, const Rect.fromLTWH(1920, 0, 2560, 1400));
      final mac = deskDisplayOf(Display.fromJson({'id': '69733382', 'size': {'width': 1512.0, 'height': 982.0}, 'scaleFactor': 2.0}));
      expect(mac.key, '69733382');
      expect(mac.scale, 2);
    });
  });

  group('placed and kept through the store', () {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const wm = MethodChannel('window_manager');
    const sr = MethodChannel('dev.leanflutter.plugins/screen_retriever');

    late Rect bounds;
    late bool maximized;
    late List<MethodCall> calls;

    setUp(() {
      bounds = const Rect.fromLTWH(0, 0, 1280, 820);
      maximized = false;
      calls = [];
      messenger.setMockMethodCallHandler(wm, (call) async {
        calls.add(call);
        final a = call.arguments is Map ? call.arguments as Map : const {};
        switch (call.method) {
          case 'getBounds':
            return {'x': bounds.left, 'y': bounds.top, 'width': bounds.width, 'height': bounds.height};
          case 'setBounds':
            bounds = Rect.fromLTWH(
              (a['x'] as num?)?.toDouble() ?? bounds.left,
              (a['y'] as num?)?.toDouble() ?? bounds.top,
              (a['width'] as num?)?.toDouble() ?? bounds.width,
              (a['height'] as num?)?.toDouble() ?? bounds.height,
            );
            return null;
          case 'isMaximized':
            return maximized;
          case 'maximize':
            maximized = true;
            return null;
          case 'isMinimized' || 'isFullScreen':
            return false;
          default:
            return null;
        }
      });
      final display = {
        'id': '',
        'name': 'Xvfb',
        'size': {'width': 1920.0, 'height': 1080.0},
        'visiblePosition': {'dx': 0.0, 'dy': 0.0},
        'visibleSize': {'width': 1920.0, 'height': 1040.0},
        'scaleFactor': 1.0,
      };
      messenger.setMockMethodCallHandler(sr, (call) async {
        return switch (call.method) {
          'getAllDisplays' => {
            'displays': [display],
          },
          'getPrimaryDisplay' => display,
          'getCursorScreenPoint' => {'dx': 10.0, 'dy': 10.0},
          _ => null,
        };
      });
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(wm, null);
      messenger.setMockMethodCallHandler(sr, null);
    });

    test('first start: minimum set, 80 % placed; a move is saved; the next start restores it', () async {
      final secrets = MemorySecretStore();
      final store = DeskStore(secrets);
      final keeper = await placeDeskWindow(store);
      expect(keeper, isNotNull);
      final min = calls.firstWhere((c) => c.method == 'setMinimumSize').arguments as Map;
      expect((min['width'], min['height']), (deskWindowMinSize.width, deskWindowMinSize.height));
      expect(bounds, const Rect.fromLTWH(192, 104, 1536, 832));
      // Placing itself writes nothing.
      expect(await secrets.read(DeskStore.windowKey), isNull);

      // The user moves and resizes it, then maximises it.
      bounds = const Rect.fromLTWH(300, 120, 1100, 760);
      await keeper!.save();
      maximized = true;
      bounds = const Rect.fromLTWH(0, 0, 1920, 1040);
      await keeper.save();
      final saved = WindowMemory.fromJson(await store.readJson(DeskStore.windowKey));
      expect(saved.last, 'Xvfb@1920x1080+0,0');
      // Maximised keeps the frame under it.
      expect(saved.displays[saved.last], const SavedWindow(frame: Rect.fromLTWH(300, 120, 1100, 760), maximized: true));

      // Next start.
      maximized = false;
      bounds = const Rect.fromLTWH(0, 0, 1280, 820);
      calls.clear();
      await placeDeskWindow(store);
      expect(bounds, const Rect.fromLTWH(300, 120, 1100, 760));
      expect(maximized, isTrue);
    });

    test('a change is written once, after the window stops moving', () async {
      final secrets = MemorySecretStore();
      final keeper = DeskWindowKeeper(DeskStore(secrets), WindowMemory.empty, delay: const Duration(milliseconds: 20));
      bounds = const Rect.fromLTWH(50, 60, 1000, 720);
      for (var i = 0; i < 5; i++) {
        keeper.onWindowMove();
        keeper.onWindowResize();
      }
      expect(await secrets.read(DeskStore.windowKey), isNull);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final saved = WindowMemory.fromJson(await DeskStore(secrets).readJson(DeskStore.windowKey));
      expect(saved.displays.values.single.frame, const Rect.fromLTWH(50, 60, 1000, 720));
      final getBounds = calls.where((c) => c.method == 'getBounds').length;
      expect(getBounds, 1);
      // Unchanged: nothing more is asked of the store.
      await keeper.save();
      expect(keeper.memory, saved);
    });

    test('the store unreadable: the first-start rule, and the window still placed', () async {
      final store = DeskStore(_BrokenStore());
      await placeDeskWindow(store);
      expect(bounds, const Rect.fromLTWH(192, 104, 1536, 832));
    });
  });
}

class _BrokenStore extends MemorySecretStore {
  @override
  Future<String?> read(String key) async => throw StateError('locked');
}
