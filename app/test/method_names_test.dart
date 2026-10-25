// The one naming rule for a payment method on the phone: Epicbox, Link · HTTP, Link · Tor or
// Direct · File Transfer, in each language. HTTP and Tor are Link's transport and never a method on their own.
// The CSV's `method` column names them in English; the desktop's mapper is in
// test/desktop/method_names_test.dart.
import 'package:epic_wallet/src/history/export.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/recipient.dart';
import 'package:epic_wallet/src/ui/contact_page.dart';
import 'package:epic_wallet/src/ui/method_names.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Epicbox, Link · HTTP, Link · Tor, Direct · File Transfer per language; Link stays Latin in en, de and pl; ru, zh and th name it in their own word, as Direct (AND-11).
const _names = <String, List<String>>{
  'en': ['Epicbox', 'Link · HTTP', 'Link · Tor', 'Direct · File Transfer'],
  'de': ['Epicbox', 'Link · HTTP', 'Link · Tor', 'Direkt · Dateiübertragung'],
  'pl': ['Epicbox', 'Link · HTTP', 'Link · Tor', 'Bezpośrednio · Przesyłanie pliku'],
  'ru': ['Epicbox', 'Ссылка · HTTP', 'Ссылка · Tor', 'Напрямую · Передача файла'],
  'zh': ['Epicbox', '链接 · HTTP', '链接 · Tor', '直接 · 文件传输'],
  'th': ['Epicbox', 'ลิงก์ · HTTP', 'ลิงก์ · Tor', 'โดยตรง · โอนไฟล์'],
};

void main() {
  group('the phone names a method from one mapper', () {
    for (final MapEntry(key: lang, value: names) in _names.entries) {
      test('$lang: epicbox, http, tor and file', () {
        final l = lookupAppLocalizations(Locale(lang));
        expect([
          for (final t in ['epicbox', 'http', 'tor', 'file']) txMethodWord(l, t),
        ], names);
        expect([
          for (final k in RecipientKind.values) recipientMethodWord(l, k),
        ], [names[0], names[2], names[1]], reason: 'enum order: epicbox, tor, http');
      });
    }

    test('an unknown or missing transport reads Unknown, not a bare protocol', () {
      final l = lookupAppLocalizations(const Locale('en'));
      expect(txMethodWord(l, null), 'Unknown');
      expect(txMethodWord(l, 'carrier-pigeon'), 'Unknown');
    });

    test('no language names HTTP or Tor alone as a method', () {
      for (final lang in _names.keys) {
        final l = lookupAppLocalizations(Locale(lang));
        for (final t in ['http', 'tor']) {
          expect(txMethodWord(l, t), isNot(anyOf('HTTP', 'Tor')), reason: lang);
          expect(txMethodWord(l, t), endsWith(t == 'http' ? ' · HTTP' : ' · Tor'), reason: '$lang: Link\'s word, then the transport');
        }
      }
    });

    test('a contact\'s tag is the method its address is reached by', () {
      final l = lookupAppLocalizations(const Locale('de'));
      expect(contactTag(l, 'esAbc@epicbox.epiccash.com'), 'Epicbox');
      expect(contactTag(l, 'https://pay.example.org:3415'), 'Link · HTTP');
    });
  });

  group('the CSV method column', () {
    test('names the four methods the way the app does, in English', () {
      expect(methodWord('epicbox'), 'Epicbox');
      expect(methodWord('http'), 'Link · HTTP');
      expect(methodWord('tor'), 'Link · Tor');
      expect(methodWord('file'), 'Direct · File Transfer');
      expect(methodWord(null), '');
      expect(methodWord('other'), 'other');
    });

    test('a row carries the name, not LEPIC\'s transport', () {
      TxEntry row(String? transport) => fakeTx(
        key: 's:$transport',
        id: 1,
        slateId: 's-$transport',
        kind: TxKind.sent,
        status: TxStatus.confirmed,
        createdAtUnix: 1790000000,
        blockHeight: BigInt.from(12),
        amountDebited: BigInt.from(200000000),
        transport: transport,
      );
      final lines = historyCsv([
        for (final t in ['epicbox', 'http', 'tor', 'file', null]) row(t),
      ], BigInt.from(40)).trim().split('\n');
      final methods = [for (final line in lines.skip(1)) line.split(',')[11]];
      expect(methods, ['Epicbox', 'Link · HTTP', 'Link · Tor', 'Direct · File Transfer', '']);
      expect(lines.join('\n'), isNot(contains(',http,')));
      expect(lines.join('\n'), isNot(contains(',tor,')));
    });
  });
}
