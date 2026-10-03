/// Which native wallet core the app runs on, chosen at build time:
///
///     flutter run --dart-define=WFE_CORE=lepic
///
/// `epicwallet` (the default) is `app/rust` over epic-wallet. `lepic` is the LEPIC library
///, still missing features; [LepicWalletService] lists them.
library;

enum CoreBackend {
  epicWallet('epicwallet'),
  lepic('lepic');

  const CoreBackend(this.define);

  /// The `WFE_CORE` value that selects it.
  final String define;

  static CoreBackend parse(String value) => values.firstWhere(
    (b) => b.define == value,
    orElse: () => throw ArgumentError.value(
      value,
      'WFE_CORE',
      'expected ${values.map((b) => b.define).join(' or ')}',
    ),
  );
}

const String _coreDefine = String.fromEnvironment(
  'WFE_CORE',
  defaultValue: 'epicwallet',
);

/// The backend this build was compiled for. An unknown `WFE_CORE` fails at the first read, so a
/// typo never silently falls back to the default.
final CoreBackend coreBackend = CoreBackend.parse(_coreDefine);
