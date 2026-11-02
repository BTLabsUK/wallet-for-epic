// SPDX-License-Identifier: Apache-2.0
// Tor for payments (item 2): the state both apps show for Link · Tor, in every network mode.
import 'package:epic_wallet/src/advanced.dart' show NetworkMode;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/tor_pay.dart';
import 'package:epic_wallet/src/tor_routes.dart' show TorState;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

TorPay _of({bool linkTor = true, NetworkMode mode = NetworkMode.standard, bool torSwitch = false, TorState tor = TorState.starting, bool published = false, String? problem}) =>
    torPayOf(linkTor: linkTor, built: true, mode: mode, torSwitch: torSwitch, tor: tor, published: published, onion: published ? 'x.onion' : null, problem: problem);

void main() {
  test('Link · Tor off, or no tor in the build: off', () {
    expect(_of(linkTor: false).kind, TorPayKind.off);
    expect(torPayOf(linkTor: true, built: false, mode: NetworkMode.standard, torSwitch: false, tor: TorState.on, published: true).kind, TorPayKind.off);
  });

  test('Normal: starting, then ready with the onion once it is published', () {
    expect(_of().kind, TorPayKind.starting);
    expect(_of(tor: TorState.on).kind, TorPayKind.starting, reason: 'sends work, the onion is not up yet');
    final ready = _of(tor: TorState.on, published: true);
    expect(ready.kind, TorPayKind.ready);
    expect(ready.onion, 'x.onion');
    expect(ready.torAll, isFalse, reason: 'payments only');
  });

  test('failed, or running for sends with the onion not published: Retry', () {
    expect(_of(tor: TorState.failed).kind, TorPayKind.failed);
    expect(torPayRetry(_of(tor: TorState.failed)), isTrue);
    expect(_of(tor: TorState.on, problem: 'listener').kind, TorPayKind.failed);
  });

  test('Tor only and the Tor switch carry everything: the caption says so; the state is the same', () {
    expect(_of(mode: NetworkMode.torOnly, tor: TorState.on, published: true).torAll, isTrue);
    expect(_of(torSwitch: true, tor: TorState.on, published: true).torAll, isTrue);
    expect(_of(mode: NetworkMode.torOnly, tor: TorState.on, published: true).kind, TorPayKind.ready);
  });

  for (final mode in [NetworkMode.nodeOnly, NetworkMode.killSwitch]) {
    test('${mode.name}: blocked with the mode as the reason, the switch locked', () {
      final p = _of(mode: mode, tor: TorState.on, published: true);
      expect(p.kind, TorPayKind.blocked);
      expect(p.mode, mode);
      expect(torPayCanSwitch(p), isFalse);
    });
  }

  test('the state line names the mode when blocked', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(torPayLine(l, _of(mode: NetworkMode.killSwitch)), 'Off in Kill switch: nothing connects.');
    expect(torPayLine(l, _of(mode: NetworkMode.nodeOnly)), 'Off in Node only: only the node connects.');
    expect(torPayLine(l, _of()), 'Starting Tor · for payments only');
    expect(torPayLine(l, _of(tor: TorState.failed, problem: 'Tor stopped.')), 'Tor did not connect: Tor stopped.');
    expect(torPayRestLine(l, _of()), contains('off'));
  });
}
