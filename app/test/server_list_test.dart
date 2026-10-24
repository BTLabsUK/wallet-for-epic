import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/server_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const node = ServerKind.node;
  const relay = ServerKind.relay;

  group('the list', () {
    test('a seed is the built-in servers, then the old own list, one row per server', () {
      final l = ServerList.seed(
        node,
        ['https://node.btlabs.uk', 'https://node.epicnet.us:3413'],
        carried: ['https://NODE.btlabs.uk:443', 'https://mine.example:3413'],
      );
      expect(l.entries, [
        'https://node.btlabs.uk',
        'https://node.epicnet.us:3413',
        'https://mine.example:3413',
      ]);
      expect(l.removed, isEmpty);
    });

    test('directory servers join at the end; listed and removed ones do not', () {
      final l = const ServerList(entries: ['a.example'], removed: {'gone.example'});
      final out = l.absorb(relay, ['a.example', 'gone.example', 'new.example', 'new.example:443']);
      expect(out.entries, ['a.example', 'new.example']);
      expect(out.removed, {'gone.example'});
      expect(l.missing(relay, ['a.example', 'gone.example', 'new.example']), ['new.example']);
      expect(identical(out.absorb(relay, ['a.example']), out), isTrue);
    });

    test('remove remembers the key and says where the row was; add at that place undoes it', () {
      final l = const ServerList(entries: ['a.example', 'b.example', 'c.example']);
      final r = l.remove(relay, 'b.example');
      expect(r.at, 1);
      expect(r.list.entries, ['a.example', 'c.example']);
      expect(r.list.removed, {'b.example'});
      // A removed public server stays out of a directory update.
      expect(r.list.absorb(relay, ['b.example']).entries, ['a.example', 'c.example']);
      final back = r.list.add(relay, 'b.example', at: r.at);
      expect(back.entries, ['a.example', 'b.example', 'c.example']);
      expect(back.removed, isEmpty);
      expect(l.remove(relay, 'none.example').at, isNull);
    });

    test('add puts a new server last and leaves a listed one alone', () {
      final l = const ServerList(entries: ['https://node.btlabs.uk']);
      expect(l.add(node, 'https://node.btlabs.uk:443'), same(l));
      expect(l.add(node, 'https://mine.example:3413').entries.last, 'https://mine.example:3413');
    });

    test('restore shows only while a public server is removed, and puts them back in order', () {
      const public = ['a.example', 'b.example', 'c.example'];
      final l = const ServerList(
        entries: ['a.example', 'mine.example'],
        removed: {'c.example', 'b.example'},
      );
      expect(l.restorable(relay, public), ['b.example', 'c.example']);
      final out = l.restore(relay, public);
      expect(out.entries, ['a.example', 'mine.example', 'b.example', 'c.example']);
      expect(out.removed, isEmpty);
      expect(out.restorable(relay, public), isEmpty);
      // An own server removed is not a public one: nothing to restore.
      final own = const ServerList(entries: ['a.example'], removed: {'mine.example'});
      expect(own.restorable(relay, public), isEmpty);
    });

    test('a stored list reads back; a broken one is null so the caller seeds again', () {
      final l = const ServerList(entries: ['a.example'], removed: {'b.example'});
      expect(ServerList.decode(l.encode()), l);
      expect(ServerList.decode('{oops'), isNull);
      expect(ServerList.decode('[1]'), isNull);
      expect(ServerList.decode(null), isNull);
    });
  });

  group('typed addresses', () {
    test('nodes: host or host:port, https added', () {
      expect(typedServerValue(node, 'node.example'), 'https://node.example');
      expect(typedServerValue(node, ' Node.Example:3413 '), 'https://node.example:3413');
      expect(typedServerValue(node, 'http://10.0.0.2:3413'), 'http://10.0.0.2:3413');
      expect(typedServerValue(node, 'localhost:3413'), 'https://localhost:3413');
      for (final bad in [
        '',
        'node',
        'two words.example',
        'node.example/path',
        'ftp://x.example',
        'u@node.example',
        'node.example?q=1',
      ]) {
        expect(typedServerValue(node, bad), isNull, reason: bad);
      }
    });

    test('relays: host or host:port, a wss:// or https:// in front dropped', () {
      expect(typedServerValue(relay, 'epicbox.example'), 'epicbox.example');
      expect(typedServerValue(relay, 'wss://EPICBOX.example:443/'), 'epicbox.example');
      expect(typedServerValue(relay, 'epicbox.example:8443'), 'epicbox.example:8443');
      for (final bad in [
        '',
        'epicbox',
        'a b.example',
        'x..example',
        '.example',
        'epicbox.example:0',
        'epicbox.example/path',
      ]) {
        expect(typedServerValue(relay, bad), isNull, reason: bad);
      }
    });

    test('the filter matches host or operator and ignores a typed scheme', () {
      expect(serverMatches('btlabs', host: 'node.btlabs.uk'), isTrue);
      expect(serverMatches('https://node.btl', host: 'node.btlabs.uk'), isTrue);
      expect(
        serverMatches('cypher', host: 'epic.stackwallet.com:3413', operator: 'Cypher Stack'),
        isTrue,
      );
      expect(serverMatches('zzz', host: 'node.btlabs.uk', operator: 'btlabs'), isFalse);
      expect(serverMatches('  ', host: 'node.btlabs.uk'), isTrue);
    });
  });

  group('tiles', () {
    test('initials from the operator, else the host', () {
      expect(serverInitials('Cypher Stack', 'x'), 'CS');
      expect(serverInitials('EpicNet', 'x'), 'EN');
      expect(serverInitials('btlabs', 'x'), 'BT');
      expect(serverInitials(null, 'node.epiccash.com:3413'), 'EP');
      expect(serverInitials('', 'https://epicbox.iniaku.my.id'), 'IN');
      expect(serverInitials(null, 'node.'), '?');
    });

    const btl = ServerIcon(hash: 'h1', urls: {});

    test('an icon is the server own, else its operator one, else none', () {
      final known = [(operator: 'Iniaku pool', icon: btl), (operator: 'Other', icon: null)];
      const own = ServerIcon(hash: 'own', urls: {});
      expect(serverIconFor(own, 'Iniaku pool', known), own);
      expect(serverIconFor(null, 'iniaku pool ', known), btl);
      expect(serverIconFor(null, 'Iniaku-Pool', known), btl);
      expect(serverIconFor(null, 'Other', known), isNull);
      expect(serverIconFor(null, null, known), isNull);
    });

    test('the monitor icon field: sizes in order, only https on the monitor host', () {
      final icon = parseServerIcon({
        'hash': 'abc',
        'urls': {
          '256': 'https://status.btlabs.uk/api/v1/icons/abc-256.png',
          '128': 'https://status.btlabs.uk/api/v1/icons/abc-128.png',
          '64': 'https://evil.example/abc-64.png',
          '32': 'http://status.btlabs.uk/abc-32.png',
        },
      })!;
      expect(icon.urls.keys, [128, 256]);
      expect(icon.forPixels(36 * 2).path, endsWith('-128.png'));
      expect(icon.forPixels(36 * 4).path, endsWith('-256.png'));
      expect(icon.forPixels(999).path, endsWith('-256.png'));
      expect(parseServerIcon(null), isNull);
      expect(
        parseServerIcon({
          'hash': 'x',
          'urls': {'64': 'https://evil.example/x.png'},
        }),
        isNull,
      );
    });

    test('the status list carries each entry icon', () {
      const json =
          '''{"nodes":[{"kind":"node","endpoint":"https://node.btlabs.uk","state":"healthy",
        "icon":{"hash":"h","urls":{"128":"https://status.btlabs.uk/api/v1/icons/h-128.png"}}}],
        "epicbox":[{"endpoint":"wss://epicbox.example:443/","state":"healthy","icon":null}]}''';
      expect(parseNodeStatus(json).single.icon?.hash, 'h');
      expect(parseRelayStatus(json).single.icon, isNull);
    });
  });
}
