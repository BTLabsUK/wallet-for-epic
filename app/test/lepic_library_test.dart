import 'package:flutter_test/flutter_test.dart';
import 'package:epic_wallet/src/lepic_wallet_service.dart';

void main() {
  test('a release build opens the bundled LEPIC library by its place in the bundle', () {
    expect(
      bundledLepicLibrary(os: 'linux', executable: '/opt/epic/epic_cash_desktop'),
      '/opt/epic/lib/liblepic_ffi.so',
    );
    expect(
      bundledLepicLibrary(os: 'windows', executable: r'C:\Program Files\Epic Cash\epic_cash.exe'),
      r'C:\Program Files\Epic Cash\lepic_ffi.dll',
    );
    expect(bundledLepicLibrary(os: 'android', executable: '/system/bin/app_process64'), 'liblepic_ffi.so');
    expect(bundledLepicLibrary(os: 'ios', executable: '/var/Runner.app/Runner'), '/var/Runner.app/Frameworks/lepic_ffi.framework/lepic_ffi');
    expect(
      bundledLepicLibrary(os: 'macos', executable: '/Applications/Epic.app/Contents/MacOS/Epic'),
      '/Applications/Epic.app/Contents/Frameworks/lepic_ffi.framework/lepic_ffi',
    );
  });
}
