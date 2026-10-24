import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Link · HTTP address card on the phone's Receive › Link tab: the address wallets on
/// this Wi-Fi network can pay (`phone_http.dart` runs the listener), its state (starting,
/// listening, port in use, off while Tor is on, no network) and Retry. Shown only while
/// Link · HTTP is on (Settings › Transactions). Built by the `phone-http` part; this is its
/// place in the screen.
class ReceiveHttpCard extends ConsumerWidget {
  const ReceiveHttpCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const SizedBox.shrink();
}
