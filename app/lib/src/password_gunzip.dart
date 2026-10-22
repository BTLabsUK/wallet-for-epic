/// Gunzip for the password word lists: dart:io off the web, unsupported in the browser (the
/// estimate then runs without the lists).
library;

export 'password_gunzip_io.dart' if (dart.library.js_interop) 'password_gunzip_web.dart';
