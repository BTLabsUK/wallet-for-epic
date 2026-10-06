/// The EPIC price in the user's display currency, from CoinGecko.
///
/// Prices are decoration: a missing price never blocks anything, it only hides the fiat line.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'amount.dart';
import 'net/http.dart';
import 'providers.dart';
import 'settings.dart';
import 'wallet_service.dart' show Chain;

/// Display currencies offered in settings: lower-case CoinGecko codes. `currencyName`
/// (l10n.dart) names them.
const List<String> fiatCurrencies = [
  'usd',
  'eur',
  'gbp',
  'btc',
  'jpy',
  'cny',
  'cad',
  'aud',
  'chf',
  'inr',
  'brl',
  'krw',
  'pln',
  'try',
];

/// How often [priceProvider] asks for a new price while the app runs.
const Duration priceRefreshInterval = Duration(minutes: 5);

/// The price of one EPIC in a currency.
abstract interface class PriceSource {
  /// Null when the price is not available. Never throws.
  Future<double?> price(String currency);
}

/// CoinGecko's `simple/price` for `epic-cash`.
class CoinGeckoPriceSource implements PriceSource {
  const CoinGeckoPriceSource({this.timeout = const Duration(seconds: 10)});

  final Duration timeout;

  @override
  Future<double?> price(String currency) async {
    try {
      final uri = Uri.https('api.coingecko.com', '/api/v3/simple/price', {
        'ids': 'epic-cash',
        'vs_currencies': currency,
      });
      final reply = await httpGet(
        uri,
        headers: const {'accept': 'application/json'},
        timeout: timeout,
      );
      if (reply.status != 200) return null;
      final decoded = jsonDecode(reply.body);
      if (decoded is! Map) return null;
      final coin = decoded['epic-cash'];
      final value = coin is Map ? coin[currency] : null;
      return value is num && value > 0 ? value.toDouble() : null;
    } catch (error) {
      // Offline, blocked, rate-limited or malformed: no price this time.
      logInfo('price', 'no price: ${error.runtimeType}');
      return null;
    }
  }
}

final priceSourceProvider = Provider<PriceSource>(
  (ref) => const CoinGeckoPriceSource(),
);

/// The price of one EPIC in the chosen currency, or null when prices are off or none has been
/// fetched. Refreshes every [priceRefreshInterval] while the app runs. A failed refresh keeps the
/// last price for that currency, so one dropped request does not blank every fiat line.
final priceProvider = AsyncNotifierProvider<PriceNotifier, double?>(
  PriceNotifier.new,
);

class PriceNotifier extends AsyncNotifier<double?> {
  /// Last good price per currency, for the life of the app.
  final Map<String, double> _cache = {};

  @override
  Future<double?> build() async {
    // Test coins on floonet and usernet are worthless: no price, and no request.
    final chain = ref.watch(walletConfigProvider.select((c) => c?.chain));
    if (chain != null && chain != Chain.mainnet) return null;
    final settings = await ref.watch(appSettingsProvider.future);
    if (!settings.showFiat) return null;
    final currency = settings.fiatCurrency;
    final timer = Timer.periodic(
      priceRefreshInterval,
      (_) => _refresh(currency),
    );
    ref.onDispose(timer.cancel);
    return _fetch(currency);
  }

  Future<double?> _fetch(String currency) async {
    final fresh = await ref.read(priceSourceProvider).price(currency);
    if (fresh != null) _cache[currency] = fresh;
    return fresh ?? _cache[currency];
  }

  Future<void> _refresh(String currency) async {
    final value = await _fetch(currency);
    if (ref.mounted) state = AsyncData(value);
  }
}

/// `12.34 USD` for [amount] atomic units at [price] per EPIC. Bitcoin gets 8 decimals.
String fiatText(BigInt amount, double price, String currency) {
  final value = amount / atomicPerEpic * price;
  final code = currency.toUpperCase();
  if (code == 'BTC') return '${value.toStringAsFixed(8)} BTC';
  final fixed = value.abs().toStringAsFixed(2);
  final dot = fixed.indexOf('.');
  final whole = fixed.substring(0, dot);
  final grouped = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
    grouped.write(whole[i]);
  }
  final sign = value < 0 && fixed != '0.00' ? '-' : '';
  return '$sign$grouped${fixed.substring(dot)} $code';
}
