/// The browser's side of [ServerDemoApi]: `fetch` and a new tab (`demo_web_platform_browser.dart`).
/// Off the web there is no demo server to talk to, and these throw.
library;

export 'demo_web_platform_io.dart'
    if (dart.library.js_interop) 'demo_web_platform_browser.dart';
