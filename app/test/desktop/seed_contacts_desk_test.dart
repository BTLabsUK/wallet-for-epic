// SPDX-License-Identifier: Apache-2.0
// The BT Labs contact on the desktop: a new wallet gets it once, at once; deleting
// it keeps it gone after a relaunch; the website's copy updates it unless the user edited it;
// a failed or bad website read changes nothing. On the fake core.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/btlabs_onions.dart';
import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/network_gate.dart' show NetGate;
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/seed_contacts.dart';
import 'package:epic_wallet/src/wallet_registry.dart' show WalletRegistry;
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

import '../support/btlabs_public_file.dart';
import '../support/btlabs_sign.dart';

const _password = 'test-pass-1234';
const _moved = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@box.stack.invalid';

void main() {
  late Directory files;
  late Directory support;
  late MemorySecretStore secrets;
  late core.FakeWalletService service;
  final opened = <LepicDeskWallet>[];

  setUp(() async {
    resetSignedDonation();
    files = await Directory.systemTemp.createTemp('desk-seed-test-');
    support = await Directory.systemTemp.createTemp('desk-seed-support-');
    secrets = MemorySecretStore();
    service = core.FakeWalletService(password: _password);
  });

  tearDown(() async {
    for (final w in opened) {
      await w.dispose();
    }
    opened.clear();
    await files.delete(recursive: true);
    await support.delete(recursive: true);
  });

  /// A fresh app over the same folders and key store; [web] is what the website answers.
  LepicDeskWallet app({Future<String?> Function(Uri url)? web, OnionDirectory? onions}) {
    final w = LepicDeskWallet(
      service: service,
      walletDir: (chain) async {
        final dir = Directory(WalletRegistry.firstWalletDir(support.path, chain));
        await dir.create(recursive: true);
        return dir.path;
      },
      secrets: secrets,
      filesDir: () async => files,
      nodePoll: const Duration(hours: 1),
      seedFetch: web,
      keyring: testKeyring(),
      onions: onions,
    );
    opened.add(w);
    return w;
  }

  /// A file signed with test key A: [c] is its donation.
  Future<String> webFile(SeedContact c, {int serial = 1, String? issuedAt, String? expiresAt, String? name, String? note}) =>
      signedPublicFile(
        [donation(c.id, c.address, name: name ?? c.name, note: note ?? c.note)],
        serial: serial,
        issuedAt: issuedAt,
        expiresAt: expiresAt,
      );

  const moved = SeedContact(id: 'btlabs', name: 'BT Labs', address: _moved, note: 'BT Labs, the makers of this wallet.');

  /// Opens a wallet on a fresh app whose website answers [body]; lets the refresh finish.
  Future<LepicDeskWallet> openWith(Future<String?> Function(Uri) web) async {
    final w = app(web: web);
    expect(await w.unlock(_password), isTrue);
    await pumpEventQueue(times: 50);
    return w;
  }

  Future<void> makeWallet() async {
    final w = app();
    await w.createWallet(name: 'Main', password: _password);
    expect(await w.unlock(_password), isTrue);
    await w.lock();
  }

  Future<Map<String, dynamic>> cache() async => jsonDecode(secrets.values['desk.btlabsPublic']!) as Map<String, dynamic>;

  void setCache(Map<String, dynamic> j) => secrets.values['desk.btlabsPublic'] = jsonEncode(j);

  Future<List<Contact>> bt(LepicDeskWallet w) async => (await w.contacts()).where((c) => c.name.startsWith('BT Labs')).toList();

  test('a new wallet has the BT Labs contact once, without waiting for the network', () async {
    final w = app();
    await w.createWallet(name: 'Main', password: _password);
    expect(await w.unlock(_password), isTrue);
    final cs = await bt(w);
    expect(cs.single.address, btLabsContact!.address);
    expect(cs.single.note, btLabsContact!.note);
    await w.lock();
    expect(await w.unlock(_password), isTrue);
    expect(await bt(w), hasLength(1), reason: 'never added twice');
  });

  test('deleted, it stays gone after a relaunch', () async {
    final w = app();
    await w.createWallet(name: 'Main', password: _password);
    expect(await w.unlock(_password), isTrue);
    await w.deleteContact((await bt(w)).single.id);
    await w.lock();
    final again = app();
    expect(await again.unlock(_password), isTrue);
    expect(await bt(again), isEmpty);
  });

  test("the website's copy updates an untouched contact and leaves an edited one", () async {
    const moved = SeedContact(id: 'btlabs', name: 'BT Labs', address: _moved, note: 'BT Labs, the makers of this wallet.');
    final w = app();
    await w.createWallet(name: 'Main', password: _password);
    expect(await w.unlock(_password), isTrue);
    await w.lock();

    final web = app(web: (_) => webFile(moved));
    expect(await web.unlock(_password), isTrue);
    await pumpEventQueue(times: 50);
    expect((await bt(web)).single.address, _moved);

    // The user edits it; a later website change leaves it.
    final c = (await bt(web)).single;
    await web.saveContact(
      Contact(id: c.id, name: 'BT Labs (mine)', address: 'esMine9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@x.y', note: c.note),
    );
    await web.lock();
    await secrets.delete('desk.btlabsPublic');
    final later = app(web: (_) => webFile(btLabsContact!, serial: 2));
    expect(await later.unlock(_password), isTrue);
    await pumpEventQueue(times: 50);
    expect((await bt(later)).single.name, 'BT Labs (mine)');
  });

  test('a failed or bad website read changes nothing', () async {
    final w = app(web: (_) async => throw const SocketException('offline'));
    await w.createWallet(name: 'Main', password: _password);
    expect(await w.unlock(_password), isTrue);
    await pumpEventQueue(times: 50);
    expect((await bt(w)).single.address, btLabsContact!.address);
    await w.lock();
    final bad = app(web: (_) async => '{"version": 2}');
    expect(await bad.unlock(_password), isTrue);
    await pumpEventQueue(times: 50);
    expect((await bt(bad)).single.address, btLabsContact!.address);
  });

  test("an edit of the name alone keeps the website's update away", () async {
    const moved = SeedContact(id: 'btlabs', name: 'BT Labs', address: _moved, note: 'BT Labs, the makers of this wallet.');
    final w = app();
    await w.createWallet(name: 'Main', password: _password);
    expect(await w.unlock(_password), isTrue);
    final c = (await bt(w)).single;
    await w.saveContact(Contact(id: c.id, name: 'BT Labs edited', address: c.address, note: c.note));
    await w.lock();
    final web = app(web: (_) => webFile(moved));
    expect(await web.unlock(_password), isTrue);
    await pumpEventQueue(times: 50);
    final after = (await bt(web)).single;
    expect(after.name, 'BT Labs edited');
    expect(after.address, c.address, reason: 'an edited contact is left alone');
  });

  test('the website file adds no contact the app does not ship', () async {
    const other = SeedContact(id: 'someone', name: 'Someone', address: _moved, note: 'Not ours.');
    final w = app(web: (_) => webFile(other));
    await w.createWallet(name: 'Main', password: _password);
    expect(await w.unlock(_password), isTrue);
    await pumpEventQueue(times: 50);
    await w.lock();
    expect(await w.unlock(_password), isTrue);
    final cs = await w.contacts();
    expect(cs.where((c) => c.name == 'Someone'), isEmpty);
    expect((await bt(w)).single.address, btLabsContact!.address);
  });

  test('a lost seed record never adds a second BT Labs row', () async {
    final w = app();
    await w.createWallet(name: 'Main', password: _password);
    expect(await w.unlock(_password), isTrue);
    await w.lock();
    // As if the write after the insert had failed: the contact is there, its record is not.
    var dropped = 0;
    for (final e in [...secrets.values.entries]) {
      if (!e.key.startsWith('desk.wallet.')) continue;
      final j = jsonDecode(e.value);
      if (j is Map && j.remove('seeds') != null) {
        secrets.values[e.key] = jsonEncode(j);
        dropped++;
      }
    }
    expect(dropped, 1);
    final again = app();
    expect(await again.unlock(_password), isTrue);
    expect(await bt(again), hasLength(1));
    // The adopted contact is the seed's again: deleting it keeps it gone.
    await again.deleteContact((await bt(again)).single.id);
    await again.lock();
    expect(await app().unlock(_password), isTrue);
    expect(await bt(opened.last), isEmpty);
  });

  test('a website answer that arrives after the wallet locked writes nothing into it', () async {
    const moved = SeedContact(id: 'btlabs', name: 'BT Labs', address: _moved, note: 'BT Labs, the makers of this wallet.');
    final w = app();
    await w.createWallet(name: 'Main', password: _password);
    expect(await w.unlock(_password), isTrue);
    await w.lock();
    final answer = Completer<String?>();
    final slow = app(web: (_) => answer.future);
    expect(await slow.unlock(_password), isTrue);
    await slow.lock();
    answer.complete(webFile(moved));
    await pumpEventQueue(times: 50);
    // Opened again, the update read meanwhile applies once.
    expect(await slow.unlock(_password), isTrue);
    expect((await bt(slow)).single.address, _moved);
  });

  group('the signed file', () {
    Future<void> unchanged(Future<String?> Function(Uri) web) async {
      await makeWallet();
      final w = await openWith(web);
      expect((await bt(w)).single.address, btLabsContact!.address);
      expect(secrets.values['desk.btlabsPublic']?.contains('"envelope"') ?? false, isFalse, reason: 'nothing cached');
    }

    test('an unsigned body in the old website format changes nothing', () async {
      await unchanged(
        (_) async => jsonEncode({
          'version': 1,
          'contacts': [
            {'id': 'btlabs', 'name': 'BT Labs', 'address': _moved, 'note': 'x'},
          ],
        }),
      );
    });

    test('a file signed by an unknown key changes nothing', () async {
      final stranger = await testKeyFromSeed(List.filled(32, 7));
      final body = await signedPublicFile([donation('btlabs', _moved)], keys: [stranger]);
      await unchanged((_) async => body);
    });

    test('a tampered file changes nothing', () async {
      final body = await webFile(moved);
      final env = jsonDecode(body) as Map<String, dynamic>;
      final payload = utf8.decode(base64.decode(env['payload'] as String));
      env['payload'] = base64.encode(utf8.encode(payload.replaceFirst(_moved, btLabsContact!.address.replaceFirst('Wxbo', 'Wxbp'))));
      await unchanged((_) async => jsonEncode(env));
    });

    test('an expired file changes nothing', () async {
      final now = DateTime.now().toUtc();
      final body = await webFile(
        moved,
        issuedAt: fileTime(now.subtract(const Duration(days: 100))),
        expiresAt: fileTime(now.subtract(const Duration(hours: 1))),
      );
      await unchanged((_) async => body);
    });

    test('an old file replayed after a newer one changes nothing, even after the 7 days', () async {
      await makeWallet();
      final w = await openWith((_) => webFile(moved, serial: 2));
      expect((await bt(w)).single.address, _moved);
      await w.lock();
      // The window passes (at and tried cleared); the website now serves serial 1.
      final c = await cache();
      setCache({...c, 'at': 0, 'tried': 0});
      final again = await openWith((_) => webFile(btLabsContact!, serial: 1));
      expect((await bt(again)).single.address, _moved);
      expect((await cache())['state']['serial'], 2);
    });

    test('an accepted file whose cache then expired keeps the contact it set', () async {
      await makeWallet();
      final now = DateTime.now().toUtc();
      final w = await openWith(
        (_) => webFile(
          moved,
          issuedAt: fileTime(now.subtract(const Duration(days: 30))),
          expiresAt: fileTime(now.add(const Duration(seconds: 2))),
        ),
      );
      expect((await bt(w)).single.address, _moved);
      await w.lock();
      await Future<void>.delayed(const Duration(seconds: 3));
      final later = app();
      expect(await later.unlock(_password), isTrue);
      await pumpEventQueue(times: 50);
      expect((await bt(later)).single.address, _moved, reason: 'no revert to the bundled address');
    });

    test('a different name or note updates the address only', () async {
      await makeWallet();
      final w = await openWith((_) => webFile(moved, name: 'Scam Inc', note: 'Send everything here'));
      final c = (await bt(w)).single;
      expect(c.address, _moved);
      expect(c.name, 'BT Labs');
      expect(c.note, btLabsContact!.note);
    });

    test('every app run reads the file again, after a rejected or a good read', () async {
      await makeWallet();
      var calls = 0;
      await openWith((_) async {
        calls++;
        return 'garbage';
      });
      expect(calls, 1);
      expect((await cache())['tried'], isA<int>());
      Future<String?> serve(Uri _) {
        calls++;
        return webFile(moved);
      }

      await openWith(serve);
      await openWith(serve);
      expect(calls, 3);
    });

    test('Node only and Kill switch read nothing', () async {
      await makeWallet();
      var calls = 0;
      for (final mode in [NetworkMode.nodeOnly, NetworkMode.killSwitch]) {
        final w = app(web: (_) async {
          calls++;
          return null;
        });
        NetGate.set(mode);
        try {
          expect(await w.unlock(_password), isTrue);
          await pumpEventQueue(times: 50);
        } finally {
          NetGate.set(NetworkMode.standard);
        }
      }
      expect(calls, 0);
    });

    test('at and tried in the future (a clock set back) do not block a fetch', () async {
      await makeWallet();
      final future = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;
      setCache({'at': future, 'tried': future});
      var calls = 0;
      await openWith((_) async {
        calls++;
        return null;
      });
      expect(calls, 1);
    });

    test('a body over 64 KiB is not read', () async {
      // fetchSeeds caps the body in httpGet; here the server sends a long answer.
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((r) {
        r.response
          ..statusCode = 200
          ..write('x' * 70000);
        r.response.close();
      });
      expect(await LepicDeskWallet.fetchSeeds(Uri.parse('http://127.0.0.1:${server.port}/')), isNull);
    });
  });

  group('onions', () {
    final d = [donation(btLabsContact!.id, btLabsContact!.address)];

    setUp(() async {
      final w = app();
      await w.createWallet(name: 'Main', password: _password);
    });

    Future<OnionDirectory> openAnswering(Future<String?> Function(Uri) web) async {
      final o = OnionDirectory();
      final w = app(web: web, onions: o);
      expect(await w.unlock(_password), isTrue);
      await pumpEventQueue(times: 50);
      return o;
    }

    test('a fetched file with onions replaces the built-in copy, and the cache keeps it', () async {
      final body = await signedPublicFile(d, serial: 3, onions: [onionEntry('node.lab.invalid', service: 'node')]);
      final o = await openAnswering((_) async => body);
      expect(o.entries.map((e) => e.host), ['node.lab.invalid']);
      final cached = OnionDirectory();
      final w = app(onions: cached);
      expect(await w.unlock(_password), isTrue);
      expect(cached.entries.map((e) => e.host), ['node.lab.invalid']);
    });

    test('a file without the field keeps the built-in copy', () async {
      final o = await openAnswering((_) async => signedPublicFile(d, serial: 3));
      expect(o.entries, builtInOnions);
    });

    test('a forged or unsigned file changes nothing', () async {
      final good = await signedPublicFile(d, serial: 3, onions: [onionEntry('node.lab.invalid')]);
      final forged = good.replaceFirst('"sig": "', '"sig": "Z');
      expect((await openAnswering((_) async => forged)).entries, builtInOnions);
      final unsigned = String.fromCharCodes(publicPayload(d, serial: 3, onions: [onionEntry('node.lab.invalid')]));
      expect((await openAnswering((_) async => unsigned)).entries, builtInOnions);
    });

    test('a rolled-back file never replaces what a newer one gave', () async {
      final o = OnionDirectory();
      var body = await signedPublicFile(d, serial: 4, onions: [onionEntry('new.lab.invalid')]);
      final w = app(web: (_) async => body, onions: o);
      expect(await w.unlock(_password), isTrue);
      await pumpEventQueue(times: 50);
      expect(o.entries.single.host, 'new.lab.invalid');
      await w.lock();
      setCache({...await cache(), 'at': 0, 'tried': 0});
      body = await signedPublicFile(d, serial: 3, onions: [onionEntry('old.lab.invalid')]);
      final again = app(web: (_) async => body, onions: o);
      expect(await again.unlock(_password), isTrue);
      await pumpEventQueue(times: 50);
      expect(o.entries.single.host, 'new.lab.invalid');
    });
  });
}
