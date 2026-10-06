/// What the app runs on, chosen by platform at compile time: LEPIC on this device
/// (`wallet_backend_io.dart`), or in the browser the wallet server (`wallet_backend_web.dart`).
///
/// `providers.dart` and `main.dart` reach the platform only through here, so no library the web
/// build reaches imports `package:lepic`, `dart:ffi` or `path_provider` through them.
library;

export 'wallet_backend_io.dart'
    if (dart.library.js_interop) 'wallet_backend_web.dart';
