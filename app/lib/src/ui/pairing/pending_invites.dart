/// Contacts › Pending invites (SPEC 2.6): every pairing in flight. Invites this wallet made and
/// nobody answered (how and until when; expired ones with Invite again), answers waiting for
/// their confirm, pairings whose words are still to be checked, and second answers to a used
/// invite, which are not stored and can be removed.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../wallet_service.dart';
import '../../pairing_text.dart';
import '../common.dart';
import '../theme/brand.dart';
import '../theme/tokens.dart';
import 'pair_check.dart';
import 'pair_incoming.dart' show PairFinishScreen, PairingByHandScreen, openPairingLink;
import 'pair_screen.dart';
import 'pairing_clip_offer.dart' show markPairingLinkSeen, sharePairingMessage;
import 'pairing_parts.dart';

/// Keys for tests.
const Key pendingInviteAgainKey = ValueKey('pending-invite-again');
const Key pendingCheckKey = ValueKey('pending-check');
const Key pendingRemoveStrayKey = ValueKey('pending-remove-stray');
const Key pendingRemoveReplyKey = ValueKey('pending-remove-reply');
const Key pendingByHandKey = ValueKey('pending-by-hand');

/// The menu of an invite nobody answered yet, by its id.
Key pendingInviteMenuKey(String id) => ValueKey('pending-invite-menu-$id');

/// The menu of a pairing whose words wait to be checked, by its id.
Key pendingRowMenuKey(String id) => ValueKey('pending-row-menu-$id');

class PendingInvitesScreen extends ConsumerStatefulWidget {
  const PendingInvitesScreen({super.key});

  @override
  ConsumerState<PendingInvitesScreen> createState() => _PendingInvitesScreenState();
}

class _PendingInvitesScreenState extends ConsumerState<PendingInvitesScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // The rows' times ("under a minute", "expires in 23 h") move on while the page is open.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pending = ref.watch(pendingPairingsProvider);
    final strays = ref.watch(pairingStraysProvider).value ?? const <PairingStray>[];
    final loading = ref.watch(pairingsProvider).isLoading;
    final none = pending.isEmpty && strays.isEmpty && !loading;
    return SlotScaffold(
      centered: none,
      idle: loading ? SlotProgress(label: l.pendingTitle) : null,
      appBar: AppBar(title: Text(l.pendingTitle)),
      body: none
          ? Center(
              child: EmptyState(
                icon: const Icon(Icons.schedule),
                message: l.pendingEmpty,
                action: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const PairScreen())),
                  child: Text(l.pairTitle),
                ),
              ),
            )
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: DockSlack.pad(context, const EdgeInsets.symmetric(vertical: 8)),
                    children: [
                      for (final r in pending) _PendingRow(record: r),
                      for (final s in strays) _StrayRow(stray: s),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.avatar, required this.title, required this.subtitle, this.trailing});

  final Widget avatar;
  final String title;
  final Widget subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  DefaultTextStyle.merge(style: theme.textTheme.bodySmall?.copyWith(color: context.tokens.dim), child: subtitle),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _PendingRow extends ConsumerWidget {
  const _PendingRow({required this.record});

  final PairingRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final r = record;
    final now = ref.watch(pairingClockProvider)();
    final String name = r.label ?? (r.state == PairingState.pendingInvite ? l.pairUnnamedInvite : ref.watch(pairingNameProvider(r.id)));
    // An invite nobody named yet shows how it went out, not a bare mark (PAIR-LNX-8).
    final unnamed = r.label == null && (r.name ?? '').trim().isEmpty;
    final Widget avatar = unnamed
        ? GlyphTile(size: 48, child: Icon(r.way == PairingWay.words ? Icons.abc : Icons.link, color: t.accentText))
        : PairAvatar(name: r.label ?? r.name ?? '', kind: r.kind);
    final left = r.expiresAt == null ? Duration.zero : r.expiresAt!.difference(now);
    switch (r.state) {
      case PairingState.pendingInvite when r.expiredAt(now):
        return _Row(
          avatar: avatar,
          title: name,
          // Past its time the wallet still collects a late answer once: it says so, or that the
          // relay is not answering, until the invite ends.
          subtitle: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: l.pendingExpired, style: TextStyle(color: t.warn)),
                TextSpan(text: ' · ${r.relayDown ? l.pairRelayUnreachableTitle : l.pairLateCheck}'),
              ],
            ),
          ),
          // The list's end gutter: the button ends where the other rows' menus do.
          trailing: Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: OutlinedButton(
              key: pendingInviteAgainKey,
              onPressed: () => _again(context, ref),
              child: Text(l.pendingInviteAgain),
            ),
          ),
        );
      case PairingState.pendingInvite:
        return _Row(
          avatar: avatar,
          title: name,
          // A relay that does not answer: the reply can still come by message.
          subtitle: r.relayDown
              ? Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: l.pairRelayUnreachableTitle, style: TextStyle(color: t.warn)),
                      if (r.homeRelay.isNotEmpty) TextSpan(text: ' · ${r.homeRelay}'),
                    ],
                  ),
                )
              : Text(r.way == PairingWay.words ? l.pendingWords(pairingSpan(l, left)) : l.pendingLink(pairingSpan(l, left))),
          trailing: PopupMenuButton<String>(
            key: pendingInviteMenuKey(r.id),
            tooltip: l.contactMore,
            onSelected: (v) => switch (v) {
              'share' => _share(context, ref),
              'paste' => _pasteReply(context, ref),
              'words' => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => PairingWordsScreen(invite: r))),
              'cancel' => _cancel(context, ref, name),
              _ => null,
            },
            itemBuilder: (context) => [
              if (r.inviteLink != null) PopupMenuItem(value: 'share', child: Text(l.pendingShareAgain)),
              if (r.inviteLink != null) PopupMenuItem(value: 'paste', child: Text(l.pairPasteReply)),
              if (r.inviteWords.isNotEmpty) PopupMenuItem(value: 'words', child: Text(l.pendingShowWords)),
              PopupMenuItem(value: 'cancel', child: Text(l.pairCancelInvite, style: TextStyle(color: t.risk))),
            ],
          ),
        );
      case PairingState.pendingReply:
        return _Row(
          avatar: avatar,
          title: name,
          subtitle: Text(l.pendingWaitingConfirm),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // An answer the relay did not take, while this run still has its link (PAIR-AND-11).
              if (r.relayDown)
                IconButton(
                  key: pendingByHandKey,
                  tooltip: l.pairSendByHand,
                  icon: const Icon(Icons.ios_share),
                  onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => PairingByHandScreen(pairingId: r.id))),
                ),
              // The other side may never confirm (They don't match there): the answer can go.
              TextButton(
                key: pendingRemoveReplyKey,
                style: TextButton.styleFrom(foregroundColor: t.risk),
                onPressed: () => pairingCall(ref, (api) => api.cancelInvite(r.id)),
                child: Text(l.contactRemove),
              ),
            ],
          ),
        );
      default:
        return _Row(
          avatar: avatar,
          title: name,
          subtitle: Text(l.pendingPairedCheck),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                key: pendingCheckKey,
                onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: r.id))),
                child: Text(l.contactCheckAgain),
              ),
              // An abandoned scan need not be checked to go (PAIR-AND-7).
              PopupMenuButton<String>(
                key: pendingRowMenuKey(r.id),
                tooltip: l.contactMore,
                onSelected: (v) async {
                  if (v == 'byhand') {
                    await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => PairFinishScreen(pairingId: r.id)));
                  } else if (await confirmRemovePairing(context, name)) {
                    await pairingCall(ref, (api) => api.removePairing(r.id));
                  }
                },
                itemBuilder: (context) => [
                  // The inviter's confirm, again, while the other side waits for it (PAIR-AND-10).
                  if (r.inviter) PopupMenuItem(value: 'byhand', child: Text(l.pairSendByHand)),
                  PopupMenuItem(value: 'remove', child: Text(l.contactRemovePairing, style: TextStyle(color: t.risk))),
                ],
              ),
            ],
          ),
        );
    }
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final link = record.inviteLink;
    if (link == null) return;
    await sharePairingMessage(context, ref, context.l10n.pairInviteMessage(link), link: link);
  }

  /// Paste reply, as on the invite's own screen.
  Future<void> _pasteReply(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    if (!context.mounted) return;
    if (pairingLinkKind(text) != PairingLinkKind.reply) {
      ref.read(noticeProvider.notifier).show(l.pairInvalidLink, level: NoticeLevel.warning);
      return;
    }
    await markPairingLinkSeen(ref, pairingLinkIn(text)!);
    if (context.mounted) await openPairingLink(context, ref, text);
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, String name) async {
    if (!await confirmCancelInvite(context, name)) return;
    await pairingCall(ref, (api) => api.cancelInvite(record.id));
  }

  Future<void> _again(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    try {
      final name = ref.read(pairingSeenAsProvider).value ?? '';
      await pairingCall(ref, (api) => api.cancelInvite(record.id));
      if (record.way == PairingWay.words) {
        if (context.mounted) await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const PairingWordsScreen()));
        return;
      }
      await pairingCall(
        ref,
        (api) => api.makeInvite(name: name.isEmpty ? l.pairTitle : name, expiry: pairingInviteDefaultExpiry, label: record.label, contactId: record.contactId),
      );
    } catch (error) {
      if (context.mounted) ref.read(noticeProvider.notifier).show(describeError(l, error), level: NoticeLevel.error);
    }
  }
}

class _StrayRow extends ConsumerWidget {
  const _StrayRow({required this.stray});

  final PairingStray stray;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    return _Row(
      avatar: const GlyphTile(size: 48, child: Icon(Icons.question_mark)),
      title: '“${stray.name}”',
      subtitle: Text(l.pairAnsweredSameInvite),
      trailing: TextButton(
        key: pendingRemoveStrayKey,
        style: TextButton.styleFrom(foregroundColor: t.risk),
        onPressed: () => pairingCall(ref, (api) => api.removeStray(stray.id)),
        child: Text(l.contactRemove),
      ),
    );
  }
}
