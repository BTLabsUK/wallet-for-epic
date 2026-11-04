// SPDX-License-Identifier: Apache-2.0
/// The phone's parts of a directory pairing: the Join sheet, the waiting and Check the code
/// steps (the body of [CheckWordsScreen]) and the directory block of the contact page (Joined ·
/// since, the listing code, Leave; Join; Not listed). The service and the words behind them are
/// in `directory/`; nothing here names a service, the label is the pairing's name.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../directory/directory.dart';
import '../../directory/phone_directory.dart';
import '../../errors.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../wallet_service.dart';
import '../app_dialog.dart';
import '../common.dart';
import '../info_hint.dart';
import '../phone_sheet.dart';
import '../status_icons.dart' show EpicGlyphs;
import '../theme/brand.dart' show GlyphTile;
import '../theme/tokens.dart';
import 'pairing_parts.dart';

/// Keys for tests.
const Key dirJoinKey = ValueKey('dir-join');
const Key dirNotNowKey = ValueKey('dir-not-now');
const Key dirWaitCancelKey = ValueKey('dir-wait-cancel');
const Key dirLeaveKey = ValueKey('dir-leave');
const Key dirBlockKey = ValueKey('dir-block');
const Key dirCodeKey = ValueKey('dir-code');
const Key dirRemoveTooKey = ValueKey('dir-remove-too');

/// The Join sheet for the verified directory [dkey] named [label]. True once joined; false for
/// Not now, a swipe away or a failure (which says why in a notice).
Future<bool> showDirectoryJoinSheet(BuildContext context, WidgetRef ref, {required String dkey, required String label}) async {
  final service = ref.read(directoryServiceProvider);
  if (service == null) return false;
  final l = context.l10n;
  final String host;
  try {
    host = await service.joinHost(dkey);
  } catch (error) {
    if (context.mounted) ref.read(noticeProvider.notifier).show(describeError(l, error), level: NoticeLevel.error);
    return false;
  }
  if (!context.mounted) return false;
  final entry = service.entryOf(dkey);
  final joined = await showPhoneSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _JoinSheet(dkey: dkey, label: label, host: host, name: entry?.payAsArg ?? 'none', noPayments: entry?.noPayments ?? false),
  );
  return joined ?? false;
}

class _JoinSheet extends ConsumerStatefulWidget {
  const _JoinSheet({required this.dkey, required this.label, required this.host, required this.name, required this.noPayments});

  final String dkey;
  final String label;
  final String host;

  /// The user's own name at this contact from the hello (`dirJoin*` select argument), `none` without one.
  final String name;

  /// The contact takes no payments: the sheet says so in a second paragraph.
  final bool noPayments;

  @override
  ConsumerState<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends ConsumerState<_JoinSheet> {
  bool _busy = false;

  Future<void> _join() async {
    if (_busy) return;
    final l = context.l10n;
    final notices = ref.read(noticeProvider.notifier);
    setState(() => _busy = true);
    try {
      await ref.read(directoryServiceProvider)!.join(widget.dkey);
      notices.show(l.dirJoinedNotice(widget.name, widget.label), level: NoticeLevel.success);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      notices.show(describeError(l, error), level: NoticeLevel.error);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l.dirJoinTitle(widget.name, widget.label), style: theme.textTheme.titleLarge?.copyWith(fontFamily: t.headFamily)),
                ),
              ),
              InfoHint(l.dirJoinInfo(widget.label), title: l.dirJoinTitle(widget.name, widget.label)),
            ],
          ),
          const SizedBox(height: 8),
          Text(l.dirJoinBody(widget.name, widget.label, widget.host), style: theme.textTheme.bodyLarge?.copyWith(color: t.dim)),
          if (widget.noPayments) ...[
            const SizedBox(height: 8),
            Text(l.contactNoPaymentsNamed(widget.label), style: theme.textTheme.bodyLarge?.copyWith(color: t.dim)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            key: dirJoinKey,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : _join,
            child: Text(l.dirJoin(widget.name, widget.label)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: dirNotNowKey,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: Text(l.dirNotNow),
          ),
        ],
      ),
    );
  }
}

/// The four pictures of [indexes] as a code the user compares or reads.
class DirectoryCodeTiles extends StatelessWidget {
  const DirectoryCodeTiles({super.key, required this.indexes, required this.label, this.size = WordTileSize.check});

  final List<int> indexes;
  final String label;
  final WordTileSize size;

  @override
  Widget build(BuildContext context) => WordTiles(words: codeWords(indexes), label: label, size: size);
}

/// The wait for a directory's message: static text, never a spinner; Cancel gives the ordinary
/// words step.
class DirectoryWaiting extends StatelessWidget {
  const DirectoryWaiting({super.key, required this.label, required this.onCancel});

  final String label;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    return SlotScaffold(
      appBar: AppBar(title: Text(l.dirCodeTitle)),
      body: ScreenBody(
        bottom: OutlinedButton(
          key: dirWaitCancelKey,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: onCancel,
          child: Text(l.commonCancel),
        ),
        children: [
          const SizedBox(height: 48),
          Center(child: GlyphTile(size: 72, child: Icon(Icons.hourglass_empty_rounded, color: t.info))),
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(l.dirWaitingFor(label), textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(fontFamily: t.headFamily)),
          ),
        ],
      ),
    );
  }
}

/// Check the code: the four pictures the directory shows in its chat, to compare.
class DirectoryCodeCheck extends StatelessWidget {
  const DirectoryCodeCheck({
    super.key,
    required this.label,
    required this.kind,
    required this.dkey,
    this.noPayments = false,
    required this.busy,
    required this.onMatch,
    required this.onNoMatch,
    required this.matchKey,
    required this.noMatchKey,
  });

  final String label;
  final PairingParty kind;
  final String dkey;

  /// The hello says the contact takes no payments: its badge sits in the head row.
  final bool noPayments;
  final bool busy;
  final VoidCallback onMatch;
  final VoidCallback onNoMatch;
  final Key matchKey;
  final Key noMatchKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    return SlotScaffold(
      appBar: AppBar(title: Text(l.dirCodeTitle)),
      body: ScreenBody(
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              key: matchKey,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: busy ? null : onMatch,
              child: Text(l.sasMatch),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: noMatchKey,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: busy ? null : onNoMatch,
              child: Text(l.sasNoMatch),
            ),
          ],
        ),
        children: [
          Row(
            children: [
              PairAvatar(name: label, kind: kind),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: theme.textTheme.titleMedium?.copyWith(fontFamily: t.headFamily))),
              if (noPayments) ...[const SizedBox(width: 8), const NoPaymentsBadge()],
            ],
          ),
          const SizedBox(height: 16),
          PairLead(l.dirCodeLead(label)),
          const SizedBox(height: 16),
          PairCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
                child: DirectoryCodeTiles(key: dirCodeKey, indexes: directoryCodeIndexes(fromHex(dkey)), label: l.dirCodeLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The directory block of a contact page: for the pairing [pairingId] when a verified directory
/// is behind it, else nothing. [label] is the contact's name.
class DirectoryBlock extends ConsumerStatefulWidget {
  const DirectoryBlock({super.key, required this.pairingId, required this.label});

  final String pairingId;
  final String label;

  @override
  ConsumerState<DirectoryBlock> createState() => _DirectoryBlockState();
}

class _DirectoryBlockState extends ConsumerState<DirectoryBlock> {
  bool _busy = false;

  Future<void> _join(DirectoryEntry e) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await showDirectoryJoinSheet(context, ref, dkey: e.dkey, label: widget.label);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave(DirectoryEntry e) async {
    if (_busy) return;
    final l = context.l10n;
    final notices = ref.read(noticeProvider.notifier);
    setState(() => _busy = true);
    try {
      await ref.read(directoryServiceProvider)!.leave(e.dkey);
      notices.show(l.dirLeftNotice(e.payAsArg, widget.label), level: NoticeLevel.success);
    } catch (error) {
      notices.show(describeError(l, error), level: NoticeLevel.error);
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    // Remove the directory too: the existing remove-pairing path.
    final remove = await confirmAppDialog(
      context,
      title: l.dirRemoveTooTitle(widget.label),
      icon: Icons.link_off,
      tone: DialogTone.risk,
      description: l.contactRemovePairingBody(widget.label),
      cancelLabel: l.contactKeep,
      confirmLabel: l.contactRemove,
      risk: true,
      confirmKey: dirRemoveTooKey,
    );
    if (!remove || !mounted) return;
    try {
      await pairingCall(ref, (api) => api.removePairing(widget.pairingId));
    } catch (error) {
      notices.show(describeError(l, error), level: NoticeLevel.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(phoneDirectories.directoryOfPairing(widget.pairingId));
    if (entry == null) return const SizedBox.shrink();
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final service = ref.read(directoryServiceProvider);
    final code = service?.listingCodeFor(entry.dkey);
    final since = entry.joinedAt;
    final joined = entry.joined;
    final unlisted = entry.state == ListingState.unlisted;
    final since0 = since == null ? '' : MaterialLocalizations.of(context).formatMediumDate(since.toLocal());
    return Column(
      key: dirBlockKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PairSection(widget.label),
        PairCard(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              child: Row(
                children: [
                  Icon(joined ? EpicGlyphs.verified : Icons.person_off_outlined, color: joined ? t.ok : t.dim),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(joined ? l.dirJoined(entry.payAsArg, widget.label, since0) : (unlisted ? l.dirNotListed : l.dirNotJoined), style: theme.textTheme.bodyLarge),
                        if (unlisted) Text(l.dirNotListedBody(widget.label), style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Flexible: a long "Pay me as @name" button wraps instead of overflowing.
                  Flexible(
                    flex: 2,
                    child: joined
                        ? OutlinedButton(
                            key: dirLeaveKey,
                            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                            onPressed: _busy ? null : () => _leave(entry),
                            child: Text(l.dirLeave),
                          )
                        : FilledButton(
                            key: dirJoinKey,
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                            onPressed: _busy ? null : () => _join(entry),
                            child: Text(unlisted ? l.dirJoinAgain : l.dirJoin(entry.payAsArg, widget.label), textAlign: TextAlign.center),
                          ),
                  ),
                ],
              ),
            ),
            if (joined && code != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 10, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(l.dirListingCode, style: theme.textTheme.labelLarge?.copyWith(color: t.dim))),
                        InfoHint(l.dirListingCodeInfo(widget.label), title: l.dirListingCode, size: InfoHint.inRow),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DirectoryCodeTiles(indexes: code, label: l.dirListingCode, size: WordTileSize.small),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
