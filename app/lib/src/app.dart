import 'package:flutter/material.dart';

import 'ui/setup_screen.dart';

const Color _seed = Color(0xFF5B3FD0);

/// Root widget. Expects a `ProviderScope` above it.
class WalletApp extends StatelessWidget {
  const WalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Epic Cash Wallet',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seed)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
      ),
      home: const SetupScreen(),
    );
  }
}
