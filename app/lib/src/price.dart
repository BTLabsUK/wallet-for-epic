// SPDX-License-Identifier: Apache-2.0
/// The EPIC price in the user's display currency: from CoinGecko, or with the Tor switch on
/// from BT Labs' copy of it on the status site ([BtlabsPriceSource]), never CoinGecko directly.
/// With Tor off, BT Labs' copy also stands in when CoinGecko gives no price.
///
/// Prices are decoration: a missing price never blocks anything, it only hides the fiat line.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'advanced.dart' show NetworkMode;
import 'amount.dart';
import 'net/http.dart';
import 'net/tor_switch.dart';
import 'providers.dart';
import 'settings_file/host_settings.dart' show HostSettings, appConfig, hostSettings;
import 'settings_file/settings_providers.dart' show hostSettingsProvider;
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

/// How often [priceProvider] asks for a new price while the app runs (`price.refresh_min`).
Duration get priceRefreshInterval => appConfig.priceRefresh;

/// The price of one EPIC in a currency.
abstract interface class PriceSource {
  /// Null when the price is not available. Never throws.
  Future<double?> price(String currency);
}

/// The price source's (`price.source`) `simple/price` for `epic-cash`, in CoinGecko's shape;
/// no price when `app-config.toml` names no source.
class CoinGeckoPriceSource implements PriceSource {
  const CoinGeckoPriceSource({this.timeout});

  /// `price.timeout_s` unless given.
  final Duration? timeout;

  @override
  Future<double?> price(String currency) async {
    final configured = hostSettings.priceSource;
    if (configured == null) return null;
    try {
      final source = Uri.parse(configured);
      final uri = source.replace(queryParameters: {
        ...source.queryParameters,
        'ids': 'epic-cash',
        'vs_currencies': currency,
      });
      final reply = await httpGet(
        uri,
        headers: const {'accept': 'application/json'},
        timeout: timeout ?? appConfig.priceTimeout,
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

/// BT Labs' copy of the price, refreshed by the status site every few minutes (`status.price`
/// in the settings file), which the app's HTTP reaches over the status onion while Tor is on. A file older than [maxAge], another schema or a missing currency is no
/// price.
class BtlabsPriceSource implements PriceSource {
  BtlabsPriceSource({
    this.timeout,
    this.maxAge,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// `status.price`; null when `app-config.toml` leaves it out (no copy is read).
  static Uri? get url => switch (hostSettings.statusPrice) {
    final u? => Uri.parse(u),
    null => null,
  };

  /// `price.fallback_timeout_s` and `price.max_age_min` unless given.
  final Duration? timeout;
  final Duration? maxAge;
  final DateTime Function() _now;

  @override
  Future<double?> price(String currency) async {
    final at = url;
    if (at == null) return null;
    try {
      final reply = await httpGet(
        at,
        headers: const {'accept': 'application/json'},
        timeout: timeout ?? appConfig.priceFallbackTimeout,
        maxBytes: 16 * 1024,
      );
      if (reply.status != 200) return null;
      return priceFromBtlabs(reply.body, currency, now: _now(), maxAge: maxAge ?? appConfig.priceMaxAge);
    } catch (error) {
      logInfo('price', 'no price: ${error.runtimeType}');
      return null;
    }
  }
}

/// The price of [currency] in a `price.json` body, or null (see [BtlabsPriceSource]).
double? priceFromBtlabs(
  String body,
  String currency, {
  required DateTime now,
  required Duration maxAge,
}) {
  final decoded = jsonDecode(body);
  if (decoded is! Map || decoded['schema'] != 1) return null;
  final at = DateTime.tryParse('${decoded['updated_at']}');
  if (at == null || now.difference(at) > maxAge) return null;
  final prices = decoded['prices'];
  final value = prices is Map ? prices[currency] : null;
  return value is num && value > 0 ? value.toDouble() : null;
}

final priceSourceProvider = Provider<PriceSource>(
  (ref) => const TorAwarePriceSource(),
);

/// CoinGecko with the Tor switch off; BT Labs' copy with it on ([TorSwitch.on]), asked at
/// each fetch so a switch takes effect at the next refresh. With Tor off and no price from
/// CoinGecko, BT Labs' copy: CoinGecko refuses a request without a User-Agent (403) and ours
/// carry none (`net/http.dart`).
class TorAwarePriceSource implements PriceSource {
  const TorAwarePriceSource({this.coinGecko, this.btlabs});

  final PriceSource? coinGecko;
  final PriceSource? btlabs;

  PriceSource get _copy => btlabs ?? BtlabsPriceSource();

  @override
  Future<double?> price(String currency) async {
    if (TorSwitch.on) return _copy.price(currency);
    return await (coinGecko ?? const CoinGeckoPriceSource()).price(currency) ?? await _copy.price(currency);
  }
}

/// Whether prices are offered at all: `[online] price` on in settings.toml and a price source
/// (or the status site's copy) in app-config.toml.
bool pricesOffered(HostSettings s) => s.priceEnabled && (s.priceSource != null || s.statusPrice != null);

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
    // settings.toml's `[online] price` off, or no source in app-config.toml: no price.
    final online = ref.watch(hostSettingsProvider.select(pricesOffered));
    if (!online) return null;
    final settings = await ref.watch(appSettingsProvider.future);
    if (!settings.showFiat) return null;
    final currency = settings.fiatCurrency;
    // Node only and Kill switch ask for no price: the last one seen stays; leaving them
    // fetches again.
    if (ref.watch(networkModeProvider.select((m) => m == NetworkMode.nodeOnly || m == NetworkMode.killSwitch))) return _cache[currency];
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
