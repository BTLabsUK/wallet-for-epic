// SPDX-License-Identifier: Apache-2.0
// Push sessions as the app uses them (epicbox_mux.dart): which groups, when the listener and the
// contacts start and stop, the relay's mail turning into one contacts collect, and when the
// contacts check may rest. The fake session stands for LEPIC; no relay.
import 'dart:async';

import 'package:epic_wallet/src/contact_check.dart';
import 'package:epic_wallet/src/epicbox_mux.dart';
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _on = MuxPolicy(enabled: true, waitingEveryS: 300);
const _off = MuxPolicy(enabled: false, waitingEveryS: 300);
const _relay = 'relay.example.org:443';
const _other = 'second.example.org:443';

PairingRecord _pairing(String id, String relay, {PairingState state = PairingState.verified}) => PairingRecord(
  id: id,
  state: state,
  way: PairingWay.link,
  inviter: true,
  createdAt: DateTime.utc(2026, 11, 13),
  homeRelay: relay,
);

void main() {
  group('the groups', () {
    test('Tor on: the listener is in pay and the contacts in contacts; Tor off: both in main', () {
      final tor = _on.groupsFor(overTor: true);
      expect((tor.listener, tor.contacts), ('pay', 'contacts'));
      final plain = _on.groupsFor(overTor: false);
      expect((plain.listener, plain.contacts), ('main', 'main'));
    });

    test('the session\'s Tor setting picks them; one that cannot say counts as Tor off', () async {
      final s = FakeWalletSession()..epicboxOverTorValue = true;
      final mux = EpicboxMux.of(s, _on)!;
      expect((await mux.groups()).listener, 'pay');
      s.epicboxOverTorValue = false;
      expect((await mux.groups()).listener, 'main');
      mux.close();
    });

    test('with the setting off there is no mux, so nothing is called with a group', () {
      final s = FakeWalletSession();
      expect(EpicboxMux.of(s, _off), isNull);
      expect(EpicboxMux.of(null, _on), isNull);
      expect(s.listenerVia, isEmpty);
      expect(s.contactsPushLog, isEmpty);
    });
  });

  group('start and stop', () {
    test('the listener starts through its group, with the waiting check interval', () async {
      final s = FakeWalletSession()..epicboxOverTorValue = true;
      final mux = EpicboxMux.of(s, _on)!;
      final sub = mux.startListener().listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(s.listenerVia, [('pay', 300)]);
      expect(s.listenerStarts, 1);
      await sub.cancel();
      mux.close();
    });

    test('the contacts start in their group, stop on a lock, and start again after the next unlock', () async {
      final s = FakeWalletSession()..epicboxOverTorValue = true;
      final mux = EpicboxMux.of(s, _on)!;
      await mux.startContacts();
      expect(mux.contactsGroup, 'contacts');
      await mux.stopContacts();
      expect(mux.contactsGroup, isNull);
      await mux.startContacts();
      expect(s.contactsPushLog, ['start:contacts', 'stop', 'start:contacts']);
      mux.close();
    });

    test('Tor off: the contacts are in main, with the listener', () async {
      final s = FakeWalletSession()..epicboxOverTorValue = false;
      final mux = EpicboxMux.of(s, _on)!;
      await mux.startContacts();
      final sub = mux.startListener().listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(s.contactsPushLog, ['start:main']);
      expect(s.listenerVia.single.$1, 'main');
      await sub.cancel();
      mux.close();
    });

    test('a closed mux calls nothing more on the session', () async {
      final s = FakeWalletSession();
      final mux = EpicboxMux.of(s, _on)!..close();
      await mux.startContacts();
      expect(s.contactsPushLog, isEmpty);
    });
  });

  group('the app\'s session', () {
    ProviderContainer container() => ProviderContainer(
      retry: (_, _) => null,
      overrides: [networkChangesProvider.overrideWithValue(const Stream<bool>.empty())],
    );

    test('an unlock starts the contacts; a lock stops them; the next unlock starts them again', () {
      fakeAsync((async) {
        final c = container();
        final first = FakeWalletSession();
        unawaited(c.read(sessionProvider.notifier).open(first));
        async.flushMicrotasks();
        c.listen(epicboxMuxProvider, (_, _) {}, fireImmediately: true);
        async.flushMicrotasks();
        expect(first.contactsPushLog, ['start:contacts']);

        c.read(sessionProvider.notifier).lock();
        async.flushMicrotasks();
        expect(first.contactsPushLog, ['start:contacts', 'stop']);
        expect(c.read(epicboxMuxProvider), isNull);

        final second = FakeWalletSession();
        unawaited(c.read(sessionProvider.notifier).open(second));
        async.flushMicrotasks();
        // The open waits on tor's preparation before the session is the wallet's.
        async.elapse(const Duration(seconds: 11));
        expect(second.contactsPushLog, ['start:contacts']);
        c.dispose();
      });
    });

    test('the payments listener starts through the mux group', () {
      fakeAsync((async) {
        final c = container();
        final s = FakeWalletSession();
        unawaited(c.read(sessionProvider.notifier).open(s));
        async.flushMicrotasks();
        c.listen(listenerProvider, (_, _) {}, fireImmediately: true);
        async.flushMicrotasks();
        expect(s.listenerVia.map((v) => v.$1), ['pay']);
        expect(s.listenerStarts, 1);
        c.dispose();
      });
    });

    test('a resume starts the contacts again when they are not running', () {
      fakeAsync((async) {
        final c = container();
        final s = FakeWalletSession();
        unawaited(c.read(sessionProvider.notifier).open(s));
        async.flushMicrotasks();
        c.listen(epicboxMuxProvider, (_, _) {}, fireImmediately: true);
        async.flushMicrotasks();
        unawaited(c.read(epicboxMuxProvider)!.stopContacts());
        async.flushMicrotasks();
        unawaited(c.read(epicboxMuxProvider)!.startContacts());
        async.flushMicrotasks();
        expect(s.contactsPushLog, ['start:contacts', 'stop', 'start:contacts']);
        c.dispose();
      });
    });
  });

  group('mail', () {
    test('mail in the contacts\' group gives one event a second after the last of a burst', () {
      fakeAsync((async) {
        final s = FakeWalletSession();
        final mux = EpicboxMux.of(s, _on)!;
        unawaited(mux.startContacts());
        async.flushMicrotasks();
        var events = 0;
        mux.mail.listen((_) => events++);
        s.queueMail(_relay, 'contacts');
        async.elapse(const Duration(milliseconds: 500));
        s.queueMail(_relay, 'contacts');
        s.queueMail(_other, 'contacts');
        async.elapse(const Duration(milliseconds: 900));
        expect(events, 0);
        async.elapse(const Duration(milliseconds: 200));
        expect(events, 1);
        async.elapse(const Duration(seconds: 5));
        expect(events, 1);
        mux.close();
      });
    });

    test('mail for the payments listener\'s group asks no contacts collect', () {
      fakeAsync((async) {
        final s = FakeWalletSession();
        final mux = EpicboxMux.of(s, _on)!;
        unawaited(mux.startContacts());
        async.flushMicrotasks();
        var events = 0;
        mux.mail.listen((_) => events++);
        s.queueMail(_relay, 'pay');
        async.elapse(const Duration(seconds: 5));
        expect(events, 0);
        mux.close();
      });
    });

    test('MailQueued runs the contacts collect once, with the push trigger', () {
      fakeAsync((async) {
        final s = FakeWalletSession();
        final mux = EpicboxMux.of(s, _on)!;
        final triggers = <PairingCollectTrigger>[];
        final check = ContactCheck(
          boosts: MemoryBoosts(),
          collect: (t, {only}) async {
            triggers.add(t);
            return 0;
          },
          sync: (_) async {},
          inFlight: () => const [],
          idleChecks: const [Duration(seconds: 45)],
          inFlightEvery: const Duration(seconds: 45),
          paused: () => false,
          idlePaused: () => false,
        );
        final live = MuxLive(relays: () => {_relay})
          ..check = check
          ..bind(mux);
        unawaited(mux.startContacts());
        async.flushMicrotasks();
        s.queueMail(_relay, 'contacts');
        s.queueMail(_relay, 'contacts');
        async.elapse(const Duration(seconds: 2));
        expect(triggers, [PairingCollectTrigger.push]);
        expect(check.pushChecks, 1);
        live.dispose();
        mux.close();
      });
    });
  });

  group('live', () {
    EpicboxMux started(FakeAsync async, FakeWalletSession s) {
      final mux = EpicboxMux.of(s, _on)!;
      unawaited(mux.startContacts());
      async.flushMicrotasks();
      return mux;
    }

    test('live while every relay in use has an attached session of the contacts\' group', () {
      fakeAsync((async) {
        final s = FakeWalletSession();
        final mux = started(async, s);
        expect(mux.liveFor({_relay}), isFalse, reason: 'no session yet');
        s.setPushState(_relay, 'contacts', PushState.attached);
        expect(mux.liveFor({_relay}), isTrue);
        expect(mux.liveFor({_relay, _other}), isFalse);
        s.setPushState(_other, 'contacts', PushState.attached);
        expect(mux.liveFor({_relay, _other}), isTrue);
        s.setPushState(_other, 'contacts', PushState.reconnecting);
        expect(mux.liveFor({_relay, _other}), isFalse);
        mux.close();
      });
    });

    test('a relay without mux/1 (notOffered), another group, and no relay in use are not live', () {
      fakeAsync((async) {
        final s = FakeWalletSession();
        final mux = started(async, s);
        s.setPushState(_relay, 'contacts', PushState.notOffered);
        expect(mux.liveFor({_relay}), isFalse);
        s.setPushState(_relay, 'pay', PushState.attached);
        expect(mux.liveFor({_relay}), isFalse);
        s.setPushState(_relay, 'contacts', PushState.attached);
        expect(mux.liveFor(const {}), isFalse);
        mux.close();
      });
    });

    test('never live before the contacts start or after they stop', () async {
      final s = FakeWalletSession()..setPushState(_relay, 'contacts', PushState.attached);
      final mux = EpicboxMux.of(s, _on)!;
      expect(mux.liveFor({_relay}), isFalse);
      await mux.startContacts();
      expect(mux.liveFor({_relay}), isTrue);
      await mux.stopContacts();
      expect(mux.liveFor({_relay}), isFalse);
      mux.close();
    });

    test('the relays in use: those of pairings not ended, a home relay with its port, the wallet\'s own for none', () {
      expect(muxRelayKey('Relay.Example.org'), 'relay.example.org:443');
      expect(muxRelayKey('relay.example.org:4443'), 'relay.example.org:4443');
      final relays = muxRelaysOf([
        _pairing('a', 'relay.example.org'),
        _pairing('b', 'second.example.org:443'),
        _pairing('c', 'gone.example.org', state: PairingState.ended),
      ]);
      expect(relays, {'relay.example.org:443', 'second.example.org:443'});
      expect(muxRelaysOf([_pairing('d', '')]), {muxOwnRelay});
    });

    test('a pairing of the wallet\'s own relay is met by any attached session', () {
      fakeAsync((async) {
        final s = FakeWalletSession();
        final mux = started(async, s);
        expect(mux.liveFor({muxOwnRelay}), isFalse);
        s.setPushState(_relay, 'contacts', PushState.attached);
        expect(mux.liveFor({muxOwnRelay}), isTrue);
        mux.close();
      });
    });

    test('an idle hour with sessions attached reads no contact in flight', () {
      fakeAsync((async) {
        final s = FakeWalletSession();
        final mux = started(async, s);
        s.setPushState(_relay, 'contacts', PushState.attached);
        final reads = <({Duration at, List<String>? only})>[];
        final live = MuxLive(relays: () => {_relay});
        final check = ContactCheck(
          boosts: MemoryBoosts(),
          collect: (t, {only}) async {
            reads.add((at: async.elapsed, only: only));
            return 0;
          },
          sync: (_) async {},
          inFlight: () => const ['c1'],
          idleChecks: const [Duration(seconds: 45), Duration(seconds: 90)],
          inFlightEvery: const Duration(seconds: 45),
          paused: () => false,
          idlePaused: () => false,
          live: () => live.live,
        );
        live
          ..check = check
          ..bind(mux);
        check.start();
        async.elapse(const Duration(hours: 1));
        final inFlightReads = reads.where((r) => r.only != null).length;
        // ignore: avoid_print
        print('idle hour, sessions attached: $inFlightReads in-flight reads, ${reads.length} full checks');
        expect(inFlightReads, 0);
        expect(reads.length, lessThanOrEqualTo(6));

        // The relay stops answering: the check goes back to its own steps.
        s.setPushState(_relay, 'contacts', PushState.reconnecting);
        async.elapse(const Duration(minutes: 2));
        expect(reads.where((r) => r.only != null), isNotEmpty);
        check.stop();
        live.dispose();
        mux.close();
      });
    });
  });
}
