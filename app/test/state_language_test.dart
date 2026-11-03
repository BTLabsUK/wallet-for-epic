// SPDX-License-Identifier: Apache-2.0
// The one state language (state_language.dart): each state's word, mark and tone; the desktop's
// and the phone's dots drawn from it; server health and Tor through it; and the own node's one
// state for the Node field and its panel (#76).
import 'package:epic_wallet/src/desktop/data/desk_node.dart' show mockOwnNodeInfo, NodeHead;
import 'package:epic_wallet/src/desktop/data/node_view.dart';
import 'package:epic_wallet/src/desktop/data/models.dart' show ServiceHealth;
import 'package:epic_wallet/src/desktop/widgets/status.dart' show EState;
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/node_failover.dart' show NodeFailover;
import 'package:epic_wallet/src/relay_directory.dart' show NodeHealthState;
import 'package:epic_wallet/src/state_language.dart';
import 'package:epic_wallet/src/tor_routes.dart' show TorState;
import 'package:epic_wallet/src/ui/status.dart' show StatusDot;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final _l = englishStrings;

void main() {
  late AppLocalizations l;
  setUpAll(() async => l = await AppLocalizations.delegate.load(const Locale('en')));

  test('every state has one word, and its mark follows its tone', () {
    final words = <String, ShownState>{};
    for (final s in ShownState.values) {
      final w = s.word(l);
      expect(w, isNotEmpty, reason: s.name);
      expect(words[w], isNull, reason: '${s.name} and ${words[w]?.name} share "$w"');
      words[w] = s;
      expect(s.mark, s.tone.mark);
    }
  });

  test('the decided marks: green solid, blue ring, "!" for a problem, slash for off', () {
    expect(ShownState.connected.mark, StateMark.ok);
    expect(ShownState.synced.tone, StateTone.ok);
    expect(ShownState.checking.mark, StateMark.busy);
    expect(ShownState.unchecked.mark, StateMark.busy, reason: 'not known yet is a blue ring, never healthy');
    expect(ShownState.notAnswering.mark, StateMark.problem);
    expect(ShownState.notAnswering.tone, StateTone.risk);
    expect(ShownState.behind.mark, StateMark.problem);
    expect(ShownState.behind.tone, StateTone.warn);
    expect(ShownState.off.mark, StateMark.off);
    // On and Off are switch words: no connection reads "On" (#29).
    for (final s in ShownState.values) {
      expect(s.word(l), isNot('On'), reason: s.name);
    }
    expect(ShownState.connected.word(l), _l.netStatusConnected);
    expect(ShownState.receiving.word(l), _l.stateReceiving);
  });

  test('the desktop and the phone draw the same dot for a state', () {
    for (final s in ShownState.values) {
      expect(EState.of(s).tone, s.tone, reason: s.name);
      expect(StatusDot.of(s).tone, s.tone, reason: s.name);
      expect(EState.of(s).mark, StatusDot.of(s).mark, reason: s.name);
    }
    for (final t in StateTone.values) {
      expect(EState.ofTone(t).tone, t);
      expect(StatusDot.ofTone(t).tone, t);
    }
  });

  test('server health: not answering is red "!", nothing known is a blue ring', () {
    expect(serverHealthState(NodeHealthState.healthy), ShownState.healthy);
    expect(serverHealthState(NodeHealthState.degraded), ShownState.behind);
    expect(serverHealthState(NodeHealthState.down).mark, StateMark.problem);
    expect(serverHealthState(NodeHealthState.unknown), ShownState.unchecked);
    expect(serverHealthState(null), ShownState.unchecked);
  });

  test('Tor in one word per state', () {
    expect(torShownState(TorState.on).word(l), _l.netStatusConnected);
    expect(torShownState(TorState.off).mark, StateMark.off);
    expect(torShownState(TorState.starting).mark, StateMark.busy);
    expect(torShownState(TorState.failed).tone, StateTone.risk);
  });

  group('the own node: one state for the field and the panel (#76)', () {
    const url = 'http://192.168.1.24:3413';
    final down = mockOwnNodeInfo(url, head: NodeHead.down);
    final standIn = NodeFailover(chosen: url, inUse: 'https://node.example', at: DateTime(2026, 10, 22, 14, 2));

    test('down with a public node standing in: Not answering, not the stand-in\'s Synced', () {
      final v = ownNodeView(l, url, down, health: ServiceHealth.ok, standIn: standIn);
      expect(v.state, EState.risk);
      expect(v.word, _l.deskNodeNotAnswering);
    });

    test('in use and answering the wallet: the wallet\'s own view speaks for it', () {
      final v = ownNodeView(l, url, down, health: ServiceHealth.ok);
      expect(v.state, EState.ok);
    });

    test('nothing known yet: Checking, a blue ring', () {
      final v = ownNodeView(l, url, null);
      expect(v.word, _l.deskNodeChecking);
      expect(v.state, EState.active);
    });
  });
}
