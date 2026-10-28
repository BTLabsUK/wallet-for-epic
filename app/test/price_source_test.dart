// SPDX-License-Identifier: Apache-2.0
import 'package:epic_wallet/src/net/tor_switch.dart';
import 'package:epic_wallet/src/price.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fixed implements PriceSource {
  _Fixed(this.value);
  final double? value;
  int asked = 0;

  @override
  Future<double?> price(String currency) async {
    asked++;
    return value;
  }
}

void main() {
  tearDown(() => TorSwitch.on = false);

  test('Tor off: CoinGecko refuses (no User-Agent, 403) → BT Labs\' copy', () async {
    final coinGecko = _Fixed(null);
    final btlabs = _Fixed(1.09);
    final price = await TorAwarePriceSource(coinGecko: coinGecko, btlabs: btlabs).price('usd');
    expect(price, 1.09);
    expect(coinGecko.asked, 1);
    expect(btlabs.asked, 1);
  });

  test('Tor off: CoinGecko answers → its price, BT Labs not asked', () async {
    final btlabs = _Fixed(1.09);
    final price = await TorAwarePriceSource(coinGecko: _Fixed(1.1), btlabs: btlabs).price('usd');
    expect(price, 1.1);
    expect(btlabs.asked, 0);
  });

  test('Tor on: only BT Labs\' copy, never CoinGecko', () async {
    TorSwitch.on = true;
    final coinGecko = _Fixed(1.1);
    final price = await TorAwarePriceSource(coinGecko: coinGecko, btlabs: _Fixed(1.09)).price('usd');
    expect(price, 1.09);
    expect(coinGecko.asked, 0);
  });

  test('both silent → no price', () async {
    expect(await TorAwarePriceSource(coinGecko: _Fixed(null), btlabs: _Fixed(null)).price('usd'), isNull);
  });
}
