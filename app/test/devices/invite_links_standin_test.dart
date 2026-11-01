// SPDX-License-Identifier: Apache-2.0
// The stand-in of the invite links API (group I builds the real one): a device invite is read
// from its bare text, from an https link's fragment and among other text; Share and the QR
// carry a link only with an invite page set; the handler registry.
import 'package:epic_wallet/src/devices/device_link_code.dart';
import 'package:epic_wallet/src/devices/invite_links_api.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final invite = deviceLinkText('epiccash://pair/1/eyJ0IjoidC0xIn0', fingerprint: deviceLinkFingerprint('3045022100aa'));

  test('a device invite is read bare, in text, and from the fragment of an https link', () {
    expect(parseInvite(invite), isA<InviteLink>().having((l) => l.kind, 'kind', InviteKind.deviceLink).having((l) => l.invite, 'invite', invite));
    expect(parseInvite('Link: $invite\n')?.invite, invite);
    expect(parseInvite('https://epiccash.example/link#${Uri.encodeComponent(invite)}')?.invite, invite);
    expect(parseInvite('epiccash://pair/1/eyJ0IjoidC0xIn0')?.kind, InviteKind.pair);
    expect(parseInvite('hello'), isNull);
    expect(parseInvite('https://epiccash.example/link#nothing'), isNull);
  });

  test('Share and the QR carry a link only with an invite page set', () {
    final link = InviteLink(InviteKind.deviceLink, invite);
    expect(inviteShareText(link), invite);
    expect(inviteShareText(link, invitePage: ''), invite);
    final shared = inviteShareText(link, invitePage: 'https://epiccash.example/');
    expect(shared, 'https://epiccash.example/link#${Uri.encodeComponent(invite)}');
    expect(parseInvite(shared)?.invite, invite, reason: 'what is shared is read back');
    expect(inviteShareText(InviteLink(InviteKind.pair, 'epiccash://pair/1/x'), invitePage: 'https://epiccash.example'), startsWith('https://epiccash.example/pair#'));
  });

  test('the handler of a kind is the last one registered', () async {
    InviteLink? got;
    registerInviteHandler(InviteKind.deviceLink, (BuildContext context, InviteLink link) async => got = link);
    expect(inviteHandler(InviteKind.pair), isNull);
    await inviteHandler(InviteKind.deviceLink)!(_NoContext(), InviteLink(InviteKind.deviceLink, invite));
    expect(got?.invite, invite);
  });
}

class _NoContext extends Fake implements BuildContext {}
