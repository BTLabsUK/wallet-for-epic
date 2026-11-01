// SPDX-License-Identifier: Apache-2.0
/// A stand-in for `invite_links.dart` (built on another branch, group I), with its exact
/// signatures, so the linked devices code is written against the real names. It makes and
/// reads only the bare `epiccash://` forms; the `https://<invite page>/link#…` form needs the
/// invite page setting, which the real file reads. `invite_links_api.dart` exports it; the
/// switch to the real file is that one export.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_link_code.dart' show deviceInviteIn;

/// What an invite is for: a contact pairing, or a device link.
enum InviteKind { pair, deviceLink }

/// An invite as the app reads it: [invite] is the bare `epiccash://…` text, whatever form it
/// came in (a QR, an `https://…/link#…` link, or the text itself).
class InviteLink {
  const InviteLink(this.kind, this.invite);

  final InviteKind kind;
  final String invite;
}

/// The invite in [text]: an `https://<host>/link#…` or `/pair#…` link, or a bare `epiccash://`
/// invite, with surrounding text allowed; null for anything else.
InviteLink? parseInvite(String text) {
  final t = text.trim();
  final hash = t.indexOf('#');
  // The https form carries the invite in its fragment only (the stand-in reads the fragment,
  // and leaves the host to the real file).
  final body = hash >= 0 && t.startsWith('https://') ? Uri.decodeComponent(t.substring(hash + 1)) : t;
  final device = _deviceInvite(body);
  if (device != null) return InviteLink(InviteKind.deviceLink, device);
  final pair = RegExp(r'epiccash://pair/[A-Za-z0-9_\-/=]+', caseSensitive: false).firstMatch(body)?.group(0);
  if (pair != null) return InviteLink(InviteKind.pair, pair);
  return null;
}

/// The device invite text in [body] as the app writes it (`epiccash://device-link/…`), or null.
String? _deviceInvite(String body) {
  final m = RegExp(r'epiccash://device-link/[A-Za-z0-9_\-/=]+', caseSensitive: false).firstMatch(body);
  if (m == null) return null;
  final text = m.group(0)!;
  return deviceInviteIn(text) == null ? null : text;
}

/// What Share, Copy and the QR carry: an `https://<invitePage>/link#…` (or `/pair#…`) link
/// when the invite page is set, else the bare invite text.
String inviteShareText(InviteLink link, {String? invitePage}) {
  final page = invitePage?.trim() ?? '';
  if (page.isEmpty) return link.invite;
  final path = link.kind == InviteKind.deviceLink ? 'link' : 'pair';
  final host = page.endsWith('/') ? page.substring(0, page.length - 1) : page;
  return '$host/$path#${Uri.encodeComponent(link.invite)}';
}

/// The invite page host from `settings.toml`; null or empty shares bare invites. The stand-in
/// has no setting: bare invites.
final invitePageProvider = Provider<String?>((ref) => null);

/// What the app root calls with an incoming invite of a kind: it opens the confirm step (a
/// link never acts by itself).
typedef InviteHandler = Future<void> Function(BuildContext context, InviteLink link);

final Map<InviteKind, InviteHandler> _handlers = {};

/// Registers the [handler] of [kind]; the last one registered wins.
void registerInviteHandler(InviteKind kind, InviteHandler handler) => _handlers[kind] = handler;

/// The handler of [kind], or null while none is registered.
InviteHandler? inviteHandler(InviteKind kind) => _handlers[kind];
