/// The app's own data folder, settled before anything asks for it. Off the web,
/// `data_folder_io.dart`; in the browser there is no folder and nothing to do.
library;

export 'data_folder_io.dart' if (dart.library.js_interop) 'data_folder_web.dart';
