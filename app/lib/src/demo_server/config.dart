/// Settings of the demo server, from flags and `WFE_DEMO_*` environment variables.
library;

/// A setting that cannot be used. The server exits with 2 on it.
class ConfigError implements Exception {
  const ConfigError(this.message);

  final String message;

  @override
  String toString() => 'ConfigError: $message';
}

/// The defaults are the plan's server limits.
class DemoServerConfig {
  const DemoServerConfig({
    required this.dataRoot,
    this.bindAddress = '127.0.0.1',
    this.port = 8771,
    this.allowedOrigins = const {},
    this.trustProxy = false,
    this.secureCookie = true,
    this.ttl = const Duration(hours: 24),
    this.maxLiveDemos = 300,
    this.newDemosPerClientPerHour = 5,
    this.argonSlots = 2,
    this.maxFrameBytes = 256 * 1024,
    this.idleTimeout = const Duration(minutes: 10),
    this.sweepInterval = const Duration(minutes: 1),
    this.lepicLibrary,
    this.webRoot,
    this.landingRoot,
  });

  /// Holds `demos/<id>/` for every demo. Nothing else is written outside it.
  final String dataRoot;

  final String bindAddress;

  /// 0 picks a free port, for tests.
  final int port;

  /// `Origin` values a WebSocket and the demo API accept, such as `https://try.btlabs.uk`.
  /// Empty means this server's own loopback origins only ([effectiveOrigins]).
  final Set<String> allowedOrigins;

  /// Read the client from the last `X-Forwarded-For` entry, which the proxy we run appends.
  /// Off, the socket's peer address is the client.
  final bool trustProxy;

  /// Off only for plain-HTTP local tests: browsers drop a Secure cookie set over HTTP from a
  /// host other than localhost.
  final bool secureCookie;

  /// How long a demo lives after it starts.
  final Duration ttl;

  final int maxLiveDemos;
  final int newDemosPerClientPerHour;

  /// Argon2id operations (PIN and password calls) at once; each costs 64 MiB in LEPIC.
  final int argonSlots;

  /// The largest WebSocket frame read, in UTF-8 bytes.
  final int maxFrameBytes;

  /// A demo with no socket for this long has its sessions disposed, which locks its wallet.
  final Duration idleTimeout;

  final Duration sweepInterval;

  /// `liblepic_ffi.so` to load. Null loads it by name, as a Flutter bundle does.
  final String? lepicLibrary;

  /// A built `app/build/web`, served under `/app/`.
  final String? webRoot;

  /// The landing page directory, served at `/`.
  final String? landingRoot;

  /// [allowedOrigins], or this server's loopback origins when none are set.
  Set<String> effectiveOrigins(int boundPort) => allowedOrigins.isNotEmpty
      ? allowedOrigins
      : {'http://127.0.0.1:$boundPort', 'http://localhost:$boundPort'};

  /// Usage, printed for `--help` and with a [ConfigError].
  static const String usage = '''
Usage: wfe_demo_server [options]

Each option also reads from its environment variable; a flag wins.

  --data-root <dir>        WFE_DEMO_DATA_ROOT     where demos live (default ~/wfe-demo)
  --bind <address>         WFE_DEMO_BIND          listen address (default 127.0.0.1)
  --port <n>               WFE_DEMO_PORT          listen port (default 8771)
  --origins <a,b>          WFE_DEMO_ORIGINS       allowed Origin values (default the loopback origins)
  --trust-proxy <0|1>      WFE_DEMO_TRUST_PROXY   client from X-Forwarded-For (default 0)
  --secure-cookie <0|1>    WFE_DEMO_SECURE_COOKIE Secure flag on the cookie (default 1)
  --ttl <duration>         WFE_DEMO_TTL           demo lifetime (default 24h)
  --max-live <n>           WFE_DEMO_MAX_LIVE      live demos at most (default 300)
  --rate <n>               WFE_DEMO_RATE          new demos per client per hour (default 5)
  --argon <n>              WFE_DEMO_ARGON         Argon2id operations at once (default 2)
  --max-frame <bytes>      WFE_DEMO_MAX_FRAME     largest WebSocket frame (default 262144)
  --idle <duration>        WFE_DEMO_IDLE          lock after this long without a socket (default 10m)
  --sweep <duration>       WFE_DEMO_SWEEP         expiry check interval (default 1m)
  --lepic-lib <file>       WFE_DEMO_LEPIC_LIB     liblepic_ffi.so to load
  --web-root <dir>         WFE_DEMO_WEB_ROOT      built web app, served under /app/
  --landing-root <dir>     WFE_DEMO_LANDING_ROOT  landing page, served at /
  --help

Durations are a number with s, m or h, such as 90s, 15m or 24h.''';

  /// Reads [args] over [environment]. Throws [ConfigError].
  static DemoServerConfig parse(
    List<String> args,
    Map<String, String> environment,
  ) {
    final flags = <String, String>{};
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (!arg.startsWith('--')) throw ConfigError('unexpected argument $arg');
      final eq = arg.indexOf('=');
      final String name;
      final String value;
      if (eq > 0) {
        name = arg.substring(2, eq);
        value = arg.substring(eq + 1);
      } else {
        name = arg.substring(2);
        if (i + 1 >= args.length) throw ConfigError('--$name needs a value');
        value = args[++i];
      }
      if (!_options.containsKey(name)) {
        throw ConfigError('unknown option --$name');
      }
      flags[name] = value;
    }

    String? read(String name) {
      final v = flags[name] ?? environment[_options[name]!];
      return v == null || v.trim().isEmpty ? null : v.trim();
    }

    int integer(String name, int fallback, {int min = 1, int max = 1 << 31}) {
      final text = read(name);
      if (text == null) return fallback;
      final n = int.tryParse(text);
      if (n == null || n < min || n > max) {
        throw ConfigError('--$name must be a whole number from $min to $max');
      }
      return n;
    }

    bool flag(String name, bool fallback) => switch (read(name)) {
      null => fallback,
      '1' || 'true' => true,
      '0' || 'false' => false,
      _ => throw ConfigError('--$name must be 0 or 1'),
    };

    Duration duration(String name, Duration fallback) {
      final text = read(name);
      if (text == null) return fallback;
      final d = parseDuration(text);
      if (d == null || d <= Duration.zero) {
        throw ConfigError('--$name must be a duration such as 90s, 15m or 24h');
      }
      return d;
    }

    final home = environment['HOME'];
    final dataRoot =
        read('data-root') ?? (home == null ? null : '$home/wfe-demo');
    if (dataRoot == null) throw const ConfigError('--data-root is required');

    final origins = <String>{};
    for (final o in (read('origins') ?? '').split(',')) {
      final t = o.trim();
      if (t.isEmpty) continue;
      final uri = Uri.tryParse(t);
      if (uri == null ||
          !(uri.scheme == 'https' || uri.scheme == 'http') ||
          uri.host.isEmpty ||
          uri.path.isNotEmpty ||
          uri.hasQuery) {
        throw ConfigError('--origins: $t is not an origin like https://host');
      }
      origins.add(t);
    }

    return DemoServerConfig(
      dataRoot: dataRoot,
      bindAddress: read('bind') ?? '127.0.0.1',
      port: integer('port', 8771, min: 0, max: 65535),
      allowedOrigins: origins,
      trustProxy: flag('trust-proxy', false),
      secureCookie: flag('secure-cookie', true),
      ttl: duration('ttl', const Duration(hours: 24)),
      maxLiveDemos: integer('max-live', 300),
      newDemosPerClientPerHour: integer('rate', 5),
      argonSlots: integer('argon', 2, max: 64),
      maxFrameBytes: integer('max-frame', 256 * 1024, min: 1024),
      idleTimeout: duration('idle', const Duration(minutes: 10)),
      sweepInterval: duration('sweep', const Duration(minutes: 1)),
      lepicLibrary: read('lepic-lib'),
      webRoot: read('web-root'),
      landingRoot: read('landing-root'),
    );
  }

  static const Map<String, String> _options = {
    'data-root': 'WFE_DEMO_DATA_ROOT',
    'bind': 'WFE_DEMO_BIND',
    'port': 'WFE_DEMO_PORT',
    'origins': 'WFE_DEMO_ORIGINS',
    'trust-proxy': 'WFE_DEMO_TRUST_PROXY',
    'secure-cookie': 'WFE_DEMO_SECURE_COOKIE',
    'ttl': 'WFE_DEMO_TTL',
    'max-live': 'WFE_DEMO_MAX_LIVE',
    'rate': 'WFE_DEMO_RATE',
    'argon': 'WFE_DEMO_ARGON',
    'max-frame': 'WFE_DEMO_MAX_FRAME',
    'idle': 'WFE_DEMO_IDLE',
    'sweep': 'WFE_DEMO_SWEEP',
    'lepic-lib': 'WFE_DEMO_LEPIC_LIB',
    'web-root': 'WFE_DEMO_WEB_ROOT',
    'landing-root': 'WFE_DEMO_LANDING_ROOT',
  };
}

/// `90s`, `15m`, `24h`, or null.
Duration? parseDuration(String text) {
  final m = RegExp(r'^(\d{1,9})([smh])$').firstMatch(text.trim());
  if (m == null) return null;
  final n = int.parse(m.group(1)!);
  return switch (m.group(2)) {
    's' => Duration(seconds: n),
    'm' => Duration(minutes: n),
    _ => Duration(hours: n),
  };
}
