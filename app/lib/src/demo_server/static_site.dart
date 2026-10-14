/// Response headers from the plan's serving rules, and static files for `--web-root` and
/// `--landing-root`. Production puts nginx in front instead; this is for this host and the
/// tailnet.
library;

import 'dart:io';

/// Enforced from the start: none of these can break a page.
const String enforcedCsp =
    "frame-ancestors 'none'; base-uri 'self'; object-src 'none'";

/// Report-only until a build has been tested against it.
const String reportOnlyCsp =
    "default-src 'self'; "
    "script-src 'self' 'wasm-unsafe-eval'; "
    "style-src 'self' 'unsafe-inline'; "
    "img-src 'self' data: blob:; "
    "font-src 'self' data: https://fonts.gstatic.com; "
    "connect-src 'self' https://fonts.gstatic.com https://floo-explorer.btlabs.uk "
    "https://status.btlabs.uk https://api.coingecko.com "
    // Send checks a recipient's relay with a WebSocket handshake; relays are anywhere.
    "wss:; "
    "worker-src 'self'";

/// Sets the headers every response carries.
void setSecurityHeaders(HttpHeaders h) {
  h.set('Strict-Transport-Security', 'max-age=31536000');
  h.set('X-Content-Type-Options', 'nosniff');
  h.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  h.set('Cross-Origin-Opener-Policy', 'same-origin');
  h.set(
    'Permissions-Policy',
    'camera=(), microphone=(), geolocation=(), payment=()',
  );
  h.set('Content-Security-Policy', enforcedCsp);
  h.set('Content-Security-Policy-Report-Only', reportOnlyCsp);
}

const Map<String, String> _types = {
  'html': 'text/html; charset=utf-8',
  'js': 'text/javascript; charset=utf-8',
  'mjs': 'text/javascript; charset=utf-8',
  'css': 'text/css; charset=utf-8',
  'json': 'application/json',
  'wasm': 'application/wasm',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'webp': 'image/webp',
  'svg': 'image/svg+xml',
  'ico': 'image/x-icon',
  'otf': 'font/otf',
  'ttf': 'font/ttf',
  'woff2': 'font/woff2',
  'txt': 'text/plain; charset=utf-8',
  'webmanifest': 'application/manifest+json',
  'bin': 'application/octet-stream',
  'frag': 'application/octet-stream',
};

String _typeOf(String name) {
  if (name == 'NOTICES') return 'text/plain; charset=utf-8';
  final dot = name.lastIndexOf('.');
  final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  return _types[ext] ?? 'application/octet-stream';
}

/// Serves files under [root] for request paths below [prefix] (`/app/` or `/`).
class StaticSite {
  StaticSite({
    required this.root,
    required this.prefix,
    this.spaFallback = false,
  });

  final String root;
  final String prefix;

  /// A path with no file and no extension answers `index.html`, for the app's routes.
  final bool spaFallback;

  bool matches(String path) => path.startsWith(prefix) || '$path/' == prefix;

  /// Answers [request] and returns true, or returns false for a 404 left to the caller.
  Future<bool> serve(HttpRequest request) async {
    final path = request.uri.path;
    if ('$path/' == prefix) {
      // `/app` to `/app/`, so relative URLs in index.html resolve.
      request.response
        ..statusCode = HttpStatus.movedPermanently
        ..headers.set(HttpHeaders.locationHeader, prefix);
      await request.response.close();
      return true;
    }
    final segments = path
        .substring(prefix.length)
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    if (segments.any(_unsafe)) return false;
    var file = File([root, ...segments].join('/'));
    if (segments.isEmpty || await FileSystemEntity.isDirectory(file.path)) {
      file = File('${file.path}/index.html');
    }
    if (!await file.exists()) {
      final last = segments.isEmpty ? '' : segments.last;
      if (!spaFallback || last.contains('.')) return false;
      file = File('$root/index.html');
      if (!await file.exists()) return false;
    }
    final name = file.uri.pathSegments.last;
    final r = request.response;
    r.headers.contentType = ContentType.parse(_typeOf(name));
    r.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
    r.headers.set(HttpHeaders.varyHeader, 'Accept-Encoding');
    final accepts =
        request.headers.value(HttpHeaders.acceptEncodingHeader) ?? '';
    for (final (enc, ext) in [('br', 'br'), ('gzip', 'gz')]) {
      final packed = File('${file.path}.$ext');
      if (_accepts(accepts, enc) && await packed.exists()) {
        r.headers.set(HttpHeaders.contentEncodingHeader, enc);
        file = packed;
        break;
      }
    }
    r.headers.contentLength = await file.length();
    if (request.method == 'HEAD') {
      await r.close();
    } else {
      await r.addStream(file.openRead());
      await r.close();
    }
    return true;
  }

  static bool _unsafe(String s) =>
      s == '..' ||
      s.startsWith('.') ||
      s.contains('\\') ||
      s.contains('\u0000');

  static bool _accepts(String header, String encoding) => header
      .split(',')
      .map((e) => e.trim().split(';'))
      .any(
        (p) =>
            p.first.trim() == encoding &&
            !p.skip(1).any((q) => q.trim().replaceAll(' ', '') == 'q=0'),
      );
}
