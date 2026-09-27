import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  // Wallet errors are final answers (wrong password, node down); do not retry them silently.
  runApp(ProviderScope(retry: (_, _) => null, child: const WalletApp()));
}
