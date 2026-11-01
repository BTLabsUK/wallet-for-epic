// SPDX-License-Identifier: Apache-2.0
/// A stand-in for `invite_links.dart` (group I, built on another branch) with the same
/// signatures, so the pairing screens code against the final names now. The one import
/// `ui/pairing/invite_links.dart` switches to the real file; nothing else changes.
///
/// An invite travels as `<invite page>/pair#<invite>` (a device invite under `/link#`), the
/// invite only in the fragment, or as the bare `epiccash://` text when no page is set. The
/// page lives only in the settings file; an empty one shares the bare text.
library;

import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum InviteKind { pair, deviceLink }

class InviteLink {
  const InviteLink(this.kind, this.invite);

  final InviteKind kind;

  /// The bare `epiccash://` text.
  final String invite;
}

const _prefix = {InviteKind.pair: 'epiccash://pair/', InviteKind.deviceLink: 'epiccash://link/'};

/// The invite in [text]: an `https://…/pair#…` or `/link#…` page link (the fragment is the
/// invite without its scheme and path, or the whole invite), or a bare `epiccash://` text,
/// with surrounding words allowed. Null for anything else.
InviteLink? parseInvite(String text) {
  final page = RegExp(r'https://[^\s#]+/(pair|link)#([^\s]+)', caseSensitive: false).firstMatch(text);
  if (page != null) {
    final kind = page.group(1)!.toLowerCase() == 'link' ? InviteKind.deviceLink : InviteKind.pair;
    final fragment = Uri.decodeComponent(page.group(2)!);
    final bare = fragment.toLowerCase().startsWith('epiccash://') ? fragment : '${_prefix[kind]}$fragment';
    return InviteLink(kind, bare);
  }
  final bare = RegExp(r'epiccash://[A-Za-z0-9_\-/=.:]+', caseSensitive: false).firstMatch(text)?.group(0);
  if (bare == null) return null;
  final rest = bare.substring('epiccash://'.length).toLowerCase();
  if (rest.startsWith('link/')) return InviteLink(InviteKind.deviceLink, bare);
  if (rest.startsWith('pair/')) return InviteLink(InviteKind.pair, bare);
  return null;
}

/// What Share invite, Copy invite and the QR carry: `page/pair#invite` (the invite without its scheme
/// and path) when [invitePage] (a full page URL) is set, else the bare text.
String inviteShareText(InviteLink link, {String? invitePage}) {
  final page = (invitePage ?? '').trim().replaceAll(RegExp(r'/+$'), '');
  if (page.isEmpty) return link.invite;
  final path = link.kind == InviteKind.deviceLink ? 'link' : 'pair';
  final prefix = _prefix[link.kind]!;
  final fragment = link.invite.toLowerCase().startsWith(prefix) ? link.invite.substring(prefix.length) : link.invite;
  return '$page/$path#$fragment';
}

/// The invite page's URL from the settings file ('' when none is set: bare text then).
final invitePageProvider = Provider<String>((ref) => '');

/// What an incoming invite of a kind opens: the Pair handler opens the confirm sheet (a link
/// never pairs by itself). The app root routes an OS-opened invite, and paste or scan route
/// theirs, to the handler registered here.
typedef InviteHandler = Future<void> Function(BuildContext context, InviteLink link);

final Map<InviteKind, InviteHandler> _handlers = {};

void registerInviteHandler(InviteKind kind, InviteHandler handler) => _handlers[kind] = handler;

/// A no-op when another handler replaced [handler] since.
void unregisterInviteHandler(InviteKind kind, InviteHandler handler) {
  if (_handlers[kind] == handler) _handlers.remove(kind);
}

InviteHandler? inviteHandler(InviteKind kind) => _handlers[kind];
