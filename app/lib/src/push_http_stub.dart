/// The push registration's HTTP where there is no `dart:io` (the web): push is never offered.
library;

Future<int> directPost(Uri url, String body, Duration timeout) =>
    Future.error(UnsupportedError('push registration'));
