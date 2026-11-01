// SPDX-License-Identifier: Apache-2.0
/// Invite links: a pairing invite (`epiccash://pair/1/…`) or a device-link invite
/// (`epiccash://device-link/1/…`) as text, as a shared https link, and as a link the system
/// hands to the app.
///
/// - [parseInvite] reads all three forms a person pastes, scans or opens: the https link of the
///   invite page (`https://<page>/pair#<rest>`, `https://<page>/link#<rest>`), the bare
///   `epiccash://` invite, either among other words.
/// - [inviteShareText] writes what Share invite, Copy invite and the QR carry: the https link
///   when the settings name an invite page (`[invite] page`), else the bare invite. The invite
///   goes only in the fragment, which a browser never sends to the page's server.
/// - [inviteInboxProvider] holds the newest invite the system opened (Android VIEW intent, iOS
///   and macOS open URL, the desktop's command line or a second start) until the wallet is open;
///   [incomingInvitesProvider] is the stream of them.
/// - [registerInviteHandler] is where the pairing and device features register one handler
///   per [InviteKind]. The app root ([InviteLinkGate]) hands each invite to it once a wallet is
///   open. A handler only opens its confirm sheet: an invite never pairs or links by itself.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_log.dart';
import 'scan/incoming_link.dart' show maxLinkChars;
import 'settings_file/settings_providers.dart' show hostSettingsProvider;

/// What an invite opens: pairing with a contact, or linking a device of the same wallet.
enum InviteKind { pair, deviceLink }

/// An invite, whatever form it came in. [invite] is the bare `epiccash://` text the pairing and
/// device layers read.
@immutable
class InviteLink {
  const InviteLink(this.kind, this.invite);
  final InviteKind kind;
  final String invite;

  @override
  bool operator ==(Object other) => other is InviteLink && other.kind == kind && other.invite == invite;

  @override
  int get hashCode => Object.hash(kind, invite);

  @override
  String toString() => 'InviteLink($kind)';
}

const String _scheme = 'epiccash://';
const String _pairPrefix = '${_scheme}pair/';
const String _devicePrefix = '${_scheme}device-link/';

/// The part of a pairing invite after `epiccash://pair/`: `<version>/<payload>`.
const String _pairRest = r'\d{1,3}/[A-Za-z0-9_\-=]+';

/// The part of a device-link invite after `epiccash://device-link/`:
/// `<version>/<base64url>[/<fingerprint>]`.
const String _deviceRest = r'\d{1,3}/[A-Za-z0-9_\-]+(?:/[0-9a-fA-F]{16})?';

/// The end of an invite: nothing more of its alphabet follows (a damaged tail is no invite).
const String _end = r'(?![A-Za-z0-9_\-=/])';

final RegExp _barePair = RegExp('epiccash://pair/($_pairRest)$_end', caseSensitive: false);
final RegExp _bareDevice = RegExp('epiccash://device-link/($_deviceRest)$_end', caseSensitive: false);

/// `https://<host>[/path]/pair#<rest>` or `…/link#<rest>`; the rest is checked as a bare invite.
final RegExp _https = RegExp(r'https://[^\s/?#]+(?:/[^\s?#]*)?/(pair|link)/?#([^\s]+)', caseSensitive: false);

final RegExp _pairRestOnly = RegExp('^$_pairRest\$');
final RegExp _deviceRestOnly = RegExp('^$_deviceRest\$');

/// The first invite in [text]: an https link of an invite page (any host), or a bare
/// `epiccash://pair/…` or `epiccash://device-link/…` invite, with whatever surrounds it left out.
/// Null when [text] holds none, or only a damaged one.
InviteLink? parseInvite(String text) {
  if (text.length > maxLinkChars) return null;
  final found = <(int, InviteLink)>[];
  final pair = _barePair.firstMatch(text);
  if (pair != null) found.add((pair.start, InviteLink(InviteKind.pair, '$_pairPrefix${pair.group(1)}')));
  final device = _bareDevice.firstMatch(text);
  if (device != null) found.add((device.start, InviteLink(InviteKind.deviceLink, '$_devicePrefix${device.group(1)}')));
  for (final m in _https.allMatches(text)) {
    final link = _fromFragment(m.group(1)!.toLowerCase(), m.group(2)!);
    if (link != null) {
      found.add((m.start, link));
      break;
    }
  }
  if (found.isEmpty) return null;
  found.sort((a, b) => a.$1.compareTo(b.$1));
  return found.first.$2;
}

InviteLink? _fromFragment(String page, String fragment) {
  var rest = fragment;
  if (rest.contains('%')) {
    try {
      rest = Uri.decodeComponent(rest);
    } on ArgumentError {
      return null;
    }
  }
  // A sentence's full stop or a closing bracket after the link is not the invite's.
  rest = rest.replaceFirst(RegExp(r'[.,;:!?)\]>"]+$'), '');
  return switch (page) {
    'pair' when _pairRestOnly.hasMatch(rest) => InviteLink(InviteKind.pair, '$_pairPrefix$rest'),
    'link' when _deviceRestOnly.hasMatch(rest) => InviteLink(InviteKind.deviceLink, '$_devicePrefix$rest'),
    _ => null,
  };
}

/// What Share invite, Copy invite and the QR carry for [link]: `<invitePage>/pair#<rest>` or
/// `<invitePage>/link#<rest>` (rest: the invite without `epiccash://pair/` or
/// `epiccash://device-link/`), or the bare invite when [invitePage] is null or empty.
String inviteShareText(InviteLink link, {String? invitePage}) {
  final page = (invitePage ?? '').trim().replaceFirst(RegExp(r'/+$'), '');
  if (page.isEmpty) return link.invite;
  final (path, prefix) = switch (link.kind) {
    InviteKind.pair => ('pair', _pairPrefix),
    InviteKind.deviceLink => ('link', _devicePrefix),
  };
  final rest = link.invite.toLowerCase().startsWith(prefix) ? link.invite.substring(prefix.length) : link.invite;
  return '$page/$path#$rest';
}

/// The invite page of the settings in use (`[invite] page` of settings.toml); empty when the
/// user emptied it, and invites are then shared as bare `epiccash://` text.
final invitePageProvider = Provider<String>((ref) => ref.watch(hostSettingsProvider).invitePage);

// --- invites the system opened ---------------------------------------------------------------

/// The newest invite the system opened, waiting for a wallet to be open, and the stream of
/// arrivals. One invite is held, in memory only; a newer one replaces it.
class InviteInbox {
  InviteInbox();

  final StreamController<InviteLink> _arrivals = StreamController<InviteLink>.broadcast(sync: true);
  final StreamController<void> _unreadable = StreamController<void>.broadcast(sync: true);
  InviteLink? _held;

  /// Every invite as it arrives.
  Stream<InviteLink> get arrivals => _arrivals.stream;

  /// A link that looked like an invite but could not be read; the root says so briefly.
  Stream<void> get unreadable => _unreadable.stream;

  /// The invite waiting to be handled, if any.
  InviteLink? get held => _held;

  /// Reads [raw] as an invite and holds it. False when it is none: an `epiccash://pair/` or
  /// `device-link/` link that does not read also counts once on [unreadable].
  bool deliver(String raw) {
    final link = raw.length > maxLinkChars ? null : parseInvite(raw);
    if (link == null) {
      if (looksLikeInvite(raw)) {
        logInfo('links', 'an invite link that does not read was ignored');
        _unreadable.add(null);
      }
      return false;
    }
    logInfo('links', 'invite link received (${link.kind.name})');
    _held = link;
    _arrivals.add(link);
    return true;
  }

  /// Hands the held invite over and forgets it.
  InviteLink? take() {
    final link = _held;
    _held = null;
    return link;
  }

  void dispose() {
    _arrivals.close();
    _unreadable.close();
  }
}

/// Whether [text] is meant as an invite (its scheme and kind), read or not.
bool looksLikeInvite(String text) =>
    RegExp(r'epiccash://(pair|device-link)/', caseSensitive: false).hasMatch(text) ||
    RegExp(r'https://[^\s/?#]+(?:/[^\s?#]*)?/(pair|link)/?#', caseSensitive: false).hasMatch(text);

/// The invites the system opened. Reading it starts the desktop's link channel and reads the
/// launch's command line ([launchArgumentsProvider]); the phones' links come through
/// `IncomingLinkNotifier` (scan/incoming_link.dart), which hands invites here.
final inviteInboxProvider = Provider<InviteInbox>((ref) {
  final inbox = InviteInbox();
  ref.onDispose(inbox.dispose);
  for (final arg in ref.read(launchArgumentsProvider)) {
    if (looksLikeInvite(arg)) inbox.deliver(arg);
  }
  if (_desktopChannel) _listenDesktop(ref, inbox);
  return inbox;
});

/// The stream of invites from the system, as they arrive.
final incomingInvitesProvider = StreamProvider<InviteLink>((ref) => ref.watch(inviteInboxProvider).arrivals);

/// The desktop's command line (`main_desktop.dart`): a browser starts the app with the link as
/// its argument. Empty on the phones.
final launchArgumentsProvider = Provider<List<String>>((ref) => const []);

/// Linux, Windows and macOS: their runners hand a link opened while the app runs over
/// `epic_wallet/incoming_link` (as the phones do), and hold one that came before Dart listened.
bool get _desktopChannel =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS);

const MethodChannel _linkChannel = MethodChannel('epic_wallet/incoming_link');

void _listenDesktop(Ref ref, InviteInbox inbox) {
  _linkChannel.setMethodCallHandler((call) async {
    if (call.method != 'link') throw MissingPluginException();
    final text = call.arguments;
    if (text is String) inbox.deliver(text);
  });
  ref.onDispose(() => _linkChannel.setMethodCallHandler(null));
  _linkChannel.invokeMethod<Object?>('takePending').then((text) {
    if (text is String) inbox.deliver(text);
  }).catchError((Object error) {
    // No native side (tests, an older runner): nothing can have been opened.
    if (error is! MissingPluginException) logWarn('links', 'no pending link: $error');
  });
}

// --- handlers -------------------------------------------------------------------------------

/// Opens [link]'s confirm sheet over [context] (a context below the app's navigator). It must
/// not pair or link before the user confirms.
typedef InviteHandler = Future<void> Function(BuildContext context, InviteLink link);

final Map<InviteKind, InviteHandler> _handlers = {};

/// Bumped on every registration change, so the app root routes an invite that waited for its
/// handler.
final ValueNotifier<int> inviteHandlersChanged = ValueNotifier<int>(0);

/// Makes [handler] the one for [kind], in place of any before it (the last one registered wins).
void registerInviteHandler(InviteKind kind, InviteHandler handler) {
  _handlers[kind] = handler;
  inviteHandlersChanged.value++;
}

/// Takes [handler] out for [kind]; nothing when another one replaced it since.
void unregisterInviteHandler(InviteKind kind, InviteHandler handler) {
  if (_handlers[kind] != handler) return;
  _handlers.remove(kind);
  inviteHandlersChanged.value++;
}

/// The handler of [kind], or null while none is registered.
InviteHandler? inviteHandler(InviteKind kind) => _handlers[kind];

/// Forgets every handler (tests).
@visibleForTesting
void clearInviteHandlers() {
  _handlers.clear();
  inviteHandlersChanged.value++;
}
