import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The desktop's clock, for screens that say how long ago something happened or how long is
/// left (an incoming payment's Cancel hold). Tests override it; the app reads `DateTime.now`.
final deskClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
