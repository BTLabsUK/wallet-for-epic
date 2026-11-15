// SPDX-License-Identifier: Apache-2.0
// Which software a relay runs (`relay_software.dart`): only the relay's own info file says
// Epicmail; anything else, or no answer, leaves the plain Epicbox name. One GET per relay, kept
// in memory, never thrown.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:epic_wallet/l10n/app_localizations.dart';
import 'package:epic_wallet/src/desktop/widgets/kit.dart';
import 'package:epic_wallet/src/l10n.dart' show englishStrings;
import 'package:epic_wallet/src/net/http.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/relay_software.dart';
import 'package:epic_wallet/src/ui/status.dart' show EpicboxState, epicboxStatusWords;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _json(Object o) => utf8.encode(jsonEncode(o));

void main() {
  group('relaySoftwareFromReply', () {
    test('the info file naming epicmail', () {
      expect(relaySoftwareFromReply(200, _json({'software': 'epicmail', 'name': 'epicmail'})), RelaySoftware.epicmail);
      expect(relaySoftwareFromReply(200, _json({'software': ' EpicMail '})), RelaySoftware.epicmail);
    });

    test('any other answer is not epicmail', () {
      expect(relaySoftwareFromReply(200, _json({'software': 'epicbox'})), RelaySoftware.other);
      expect(relaySoftwareFromReply(200, _json({'name': 'epicmail'})), RelaySoftware.other);
      expect(relaySoftwareFromReply(200, _json({'software': 7})), RelaySoftware.other);
      expect(relaySoftwareFromReply(200, _json(['epicmail'])), RelaySoftware.other);
      expect(relaySoftwareFromReply(200, utf8.encode('<html>epicmail</html>')), RelaySoftware.other);
      expect(relaySoftwareFromReply(404, _json({'software': 'epicmail'})), RelaySoftware.other);
      expect(relaySoftwareFromReply(200, const []), RelaySoftware.other);
    });
  });

  group('RelaySoftwareBook', () {
    const relay = EpicboxRelay(host: 'epicbox.example');
    late DateTime now;
    late List<Uri> asked;
    late Future<HttpBytes> Function() reply;

    RelaySoftwareBook book() => RelaySoftwareBook(
      now: () => now,
      fetch: (url, {required timeout, required maxBytes, required followRedirects}) {
        asked.add(url);
        expect(followRedirects, isFalse);
        expect(maxBytes, relayInfoMaxBytes);
        return reply();
      },
    );

    setUp(() {
      now = DateTime(2026, 11, 15, 12);
      asked = [];
      reply = () async => HttpBytes(200, Uint8List.fromList(_json({'software': 'epicmail'})));
    });

    test('asks the relay for its info file over https', () async {
      expect(await book().lookup(const EpicboxRelay(host: 'epicbox.example', port: 8443)), RelaySoftware.epicmail);
      expect(asked.single.toString(), 'https://epicbox.example:8443/.well-known/epicbox.json');
      asked.clear();
      await book().lookup(relay);
      expect(asked.single.toString(), 'https://epicbox.example/.well-known/epicbox.json');
    });

    test('knows nothing before it asks, then keeps the answer for hours', () async {
      final b = book();
      expect(b.known(relay), RelaySoftware.unknown);
      expect(await b.lookup(relay), RelaySoftware.epicmail);
      expect(b.known(relay), RelaySoftware.epicmail);
      now = now.add(const Duration(hours: 5));
      expect(await b.lookup(relay), RelaySoftware.epicmail);
      expect(asked, hasLength(1));
      now = now.add(const Duration(hours: 2));
      expect(b.known(relay), RelaySoftware.unknown);
      await b.lookup(relay);
      expect(asked, hasLength(2));
    });

    test('a request in flight is shared', () async {
      final gate = Completer<HttpBytes>();
      reply = () => gate.future;
      final b = book();
      final a = b.lookup(relay), c = b.lookup(relay);
      gate.complete(HttpBytes(200, Uint8List.fromList(_json({'software': 'epicmail'}))));
      expect(await a, RelaySoftware.epicmail);
      expect(await c, RelaySoftware.epicmail);
      expect(asked, hasLength(1));
    });

    test('no answer is unknown and asked again soon; a missing file is other', () async {
      reply = () async => throw const NetError('offline');
      final b = book();
      expect(await b.lookup(relay), RelaySoftware.unknown);
      expect(await b.lookup(relay), RelaySoftware.unknown);
      expect(asked, hasLength(1));
      now = now.add(relaySoftwareRetry + const Duration(seconds: 1));
      reply = () async => HttpBytes(404, Uint8List(0));
      expect(await b.lookup(relay), RelaySoftware.other);
      expect(asked, hasLength(2));
    });

    test('an oversize or timed-out answer never throws', () async {
      reply = () async => throw const NetTooLarge(relayInfoMaxBytes);
      expect(await book().lookup(relay), RelaySoftware.other);
      reply = () async => throw TimeoutException('slow');
      expect(await book().lookup(relay), RelaySoftware.unknown);
    });
  });

  group('desktop state line', () {
    final l = englishStrings;
    ServiceStatus status(ServiceHealth health) => ServiceStatus(
      node: const NodeServer(url: 'http://127.0.0.1:3413', label: 'Built-in'),
      nodeHealth: ServiceHealth.ok,
      nodeHeight: 1,
      epicbox: const EpicboxServer(domain: 'epicbox.example', port: 443),
      epicboxHealth: health,
      httpListener: ServiceHealth.off,
      tor: ServiceHealth.off,
    );

    test('connected on Epicmail names it, still with the host', () {
      final line = methodStateLine(l, TxMethod.epicbox, status(ServiceHealth.ok), const DeskSettings(), epicmail: true);
      expect(line.brand, 'Epicmail');
      expect(line.text, metaLine(['Connected', 'Epicmail', 'epicbox.example']));
    });

    test('plain Epicbox when not Epicmail, and while the relay is not connected', () {
      expect(methodStateLine(l, TxMethod.epicbox, status(ServiceHealth.ok), const DeskSettings()).brand, isNull);
      expect(methodStateLine(l, TxMethod.epicbox, status(ServiceHealth.down), const DeskSettings(), epicmail: true).brand, isNull);
    });
  });

  group('plain Epicbox relay keeps the Epicbox name', () {
    const relay = EpicboxRelay(host: 'epicbox.example');
    // A stackwallet-style info file (no "software"), and no info file at all.
    final answers = <String, HttpBytes Function()>{
      'stackwallet-style info file': () => HttpBytes(200, Uint8List.fromList(_json({'name': 'epicbox', 'version': '2.0'}))),
      'no info file': () => HttpBytes(404, Uint8List(0)),
    };

    for (final e in answers.entries) {
      test(e.key, () async {
        final container = ProviderContainer(
          overrides: [
            relaySoftwareBookProvider.overrideWithValue(
              RelaySoftwareBook(fetch: (url, {required timeout, required maxBytes, required followRedirects}) async => e.value()),
            ),
          ],
        );
        addTearDown(container.dispose);
        final software = await container.read(relaySoftwareProvider(relay).future);
        expect(software, isNot(RelaySoftware.epicmail));
        final isEpicmail = software == RelaySoftware.epicmail;

        // Desktop: the connected line carries no brand and the word Epicmail appears nowhere.
        final desk = methodStateLine(
          englishStrings,
          TxMethod.epicbox,
          ServiceStatus(
            node: const NodeServer(url: 'http://127.0.0.1:3413', label: 'Built-in'),
            nodeHealth: ServiceHealth.ok,
            nodeHeight: 1,
            epicbox: const EpicboxServer(domain: 'epicbox.example', port: 443),
            epicboxHealth: ServiceHealth.ok,
            httpListener: ServiceHealth.off,
            tor: ServiceHealth.off,
          ),
          const DeskSettings(),
          epicmail: isEpicmail,
        );
        expect(desk.brand, isNull);
        expect(desk.text, isNot(contains('Epicmail')));
      });
    }

    testWidgets('phone words say Epicbox, not Epicmail', (tester) async {
      late ({String label, String detail})? words;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              words = epicboxStatusWords(context, EpicboxState.online, null);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(words!.label, contains('Epicbox'));
      expect('${words!.label} ${words!.detail}', isNot(contains('Epicmail')));
    });
  });
}
