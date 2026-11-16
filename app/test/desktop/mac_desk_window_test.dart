// SPDX-License-Identifier: Apache-2.0
// macOS: the window follows the focus, so a payment that arrives while another app is in front
// gets the system's notification (shell.dart reads `state.focused`).
import 'package:epic_wallet/src/desktop/app/desk_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the focus follows the window: blur, then focus again', () {
    final w = MacDeskWindow.detached();
    final seen = <bool>[];
    w.state.addListener(() => seen.add(w.state.value.focused));
    expect(w.state.value.focused, isTrue);

    w.onWindowBlur();
    expect(w.state.value.focused, isFalse);
    w.onWindowFocus();
    expect(w.state.value.focused, isTrue);
    expect(seen, [false, true]);
  });

  test('a blur changes the focus alone', () {
    final w = MacDeskWindow.detached();
    w.onWindowBlur();
    expect(w.state.value, const DeskWindowState(focused: false));
    expect(w.visible.value, isTrue);
  });

  test('init gives no Mac window on any other platform', () async {
    expect(await MacDeskWindow.init(), isNull);
  });
}
