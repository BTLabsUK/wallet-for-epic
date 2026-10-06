/// `demo_web_platform.dart` off the web: the demo runs only in the browser.
library;

import 'demo_web.dart';

DemoHttp browserDemoHttp() =>
    throw UnsupportedError('the web demo runs only in a browser');

Future<void> openInNewTab(Uri uri) =>
    throw UnsupportedError('the web demo runs only in a browser');
