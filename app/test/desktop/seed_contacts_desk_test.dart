// The BT Labs contact on the desktop (spec 9): a new wallet gets it once, at once; deleting
// it keeps it gone after a relaunch; the website's copy updates it unless the user edited it;
// a failed or bad website read changes nothing. On the fake core.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:epic_wallet/src/desktop/data/lepic_desk_wallet.dart';
import 'package:epic_wallet/src/desktop/data/models.dart';
import 'package:epic_wallet/src/secret_store_api.dart';
import 'package:epic_wallet/src/seed_contacts.dart';
import 'package:epic_wallet/src/wallet_service.dart' as core;
import 'package:flutter_test/flutter_test.dart';

const _password = 'test-pass-1234';
const _moved = 'esWxboBPMgL4RqufRYcGUJ7t6YVWGvyuid6xRM62UkRzSb3jUcNK@epicbox.stackwallet.com';

void main() {
  late Directory files;
  late Directory support;
  late MemorySecretStore secrets;
  late core.FakeWalletService service;
  final opened = <LepicDeskWallet>[];

  setUp(() async {
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
  LepicDeskWallet app({Future<String?> Function(Uri url)? web}) {
    final w = LepicDeskWallet(
      service: service,
      walletDir: (chain) async {
        final dir = Directory('${support.path}/wallets/${chain.name}');
        await dir.create(recursive: true);
        return dir.path;
      },
      secrets: secrets,
      filesDir: () async => files,
      nodePoll: const Duration(hours: 1),
      seedFetch: web,
    );
    opened.add(w);
    return w;
  }

  String webFile(SeedContact c) => jsonEncode({
    'version': 1,
    'contacts': [
      {'id': c.id, 'name': c.name, 'address': c.address, 'note': c.note},
    ],
  });

  Future<List<Contact>> bt(LepicDeskWallet w) async => (await w.contacts()).where((c) => c.name.startsWith('BT Labs')).toList();

  test('a new wallet has the BT Labs contact once, without waiting for the network', () async {
    final w = app();
    await w.createWallet(name: 'Main', password: _password);
    expect(await w.unlock(_password), isTrue);
    final cs = await bt(w);
    expect(cs.single.address, btLabsContact.address);
    expect(cs.single.note, btLabsContact.note);
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
    const moved = SeedContact(id: 'btlabs', name: 'BT Labs', address: _moved, note: 'Donations support development of this wallet.');
    final w = app();
    await w.createWallet(name: 'Main', password: _password);
    expect(await w.unlock(_password), isTrue);
    await w.lock();

    final web = app(web: (_) async => webFile(moved));
    expect(await web.unlock(_password), isTrue);
    await pumpEventQueue(times: 50);
    expect((await bt(web)).single.address, _moved);

    // The user edits it; a later website change leaves it.
    final c = (await bt(web)).single;
    await web.saveContact(Contact(id: c.id, name: 'BT Labs (mine)', address: 'esMine9TzWmR8uPfVc2LdN6hJx4gA7sKeQ1oBnC5vD9rHtF3w@x.y', note: c.note));
    await web.lock();
    await secrets.delete('desk.seedContacts');
    final later = app(web: (_) async => webFile(btLabsContact));
    expect(await later.unlock(_password), isTrue);
    await pumpEventQueue(times: 50);
    expect((await bt(later)).single.name, 'BT Labs (mine)');
  });

  test('a failed or bad website read changes nothing', () async {
    final w = app(web: (_) async => throw const SocketException('offline'));
    await w.createWallet(name: 'Main', password: _password);
    expect(await w.unlock(_password), isTrue);
    await pumpEventQueue(times: 50);
    expect((await bt(w)).single.address, btLabsContact.address);
    await w.lock();
    final bad = app(web: (_) async => '{"version": 2}');
    expect(await bad.unlock(_password), isTrue);
    await pumpEventQueue(times: 50);
    expect((await bt(bad)).single.address, btLabsContact.address);
  });

  test("an edit of the name alone keeps the website's update away", () async {
    const moved = SeedContact(id: 'btlabs', name: 'BT Labs', address: _moved, note: 'Donations support development of this wallet.');
    final w = app();
    await w.createWallet(name: 'Main', password: _password);
    expect(await w.unlock(_password), isTrue);
    final c = (await bt(w)).single;
    await w.saveContact(Contact(id: c.id, name: 'BT Labs donations', address: c.address, note: c.note));
    await w.lock();
    final web = app(web: (_) async => webFile(moved));
    expect(await web.unlock(_password), isTrue);
    await pumpEventQueue(times: 50);
    final after = (await bt(web)).single;
    expect(after.name, 'BT Labs donations');
    expect(after.address, btLabsContact.address, reason: 'an edited contact is left alone');
  });

  test('the website file adds no contact the app does not ship', () async {
    const other = SeedContact(id: 'someone', name: 'Someone', address: _moved, note: 'Not ours.');
    final w = app(web: (_) async => webFile(other));
    await w.createWallet(name: 'Main', password: _password);
    expect(await w.unlock(_password), isTrue);
    await pumpEventQueue(times: 50);
    await w.lock();
    expect(await w.unlock(_password), isTrue);
    final cs = await w.contacts();
    expect(cs.where((c) => c.name == 'Someone'), isEmpty);
    expect((await bt(w)).single.address, btLabsContact.address);
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
    const moved = SeedContact(id: 'btlabs', name: 'BT Labs', address: _moved, note: 'Donations support development of this wallet.');
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
}
