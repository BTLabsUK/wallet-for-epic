/// The web page's splash (`web/index.html`, `#splash`): removed once Flutter has drawn its first
/// frame. Nothing to do on other platforms.
library;

export 'splash_none.dart' if (dart.library.js_interop) 'splash_web.dart';
