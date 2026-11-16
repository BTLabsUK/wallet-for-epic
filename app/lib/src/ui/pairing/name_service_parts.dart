// SPDX-License-Identifier: Apache-2.0
/// The phone's parts of a name service pairing: the Join sheet, the waiting and Check the code
/// steps (the body of [CheckWordsScreen]) and the name service block of the contact page (Joined ·
/// since, the listing code, Leave; Join; Not listed). The service and the words behind them are
/// in `name_service/`; nothing here names a service, the label is the pairing's name.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../name_service/name_service.dart';
import '../../name_service/phone_name_service.dart';
import '../../errors.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../trust_ids.dart';
import '../common.dart';
import '../info_hint.dart';
import '../kit/kit_button.dart';
import '../kit/kit_sheet.dart';
import '../kit/kit_tokens.dart';
import '../status_icons.dart' show EpicGlyphs;
import '../theme/tokens.dart';
import 'pair_flow.dart';
import 'pairing_parts.dart';

/// Keys for tests.
const Key nsJoinKey = ValueKey('dir-join');
const Key nsNotNowKey = ValueKey('dir-not-now');
const Key nsLeaveKey = ValueKey('dir-leave');
const Key nsBlockKey = ValueKey('dir-block');
const Key nsCodeKey = ValueKey('dir-code');
const Key nsRemoveTooKey = ValueKey('dir-remove-too');

/// The Join sheet for the verified name service [serviceKey] named [label]. True once joined; false for
/// Not now, a swipe away or a failure (which says why in a notice).
Future<bool> showNameServiceJoinSheet(BuildContext context, WidgetRef ref, {required String serviceKey, required String label}) async {
  final service = ref.read(nameServiceProvider);
  if (service == null) return false;
  final l = context.l10n;
  final String host;
  try {
    host = await service.joinHost(serviceKey);
  } catch (error) {
    if (context.mounted) ref.read(noticeProvider.notifier).show(describeError(l, error), level: NoticeLevel.error);
    return false;
  }
  if (!context.mounted) return false;
  final entry = service.entryOf(serviceKey);
  final joined = await showKitSheet<bool>(
    context: context,
    builder: (_) => _JoinSheet(serviceKey: serviceKey, label: label, host: host, name: entry?.payAsArg ?? 'none', noPayments: ref.read(paymentRefusalsProvider).refusesPayments(pairingId: entry?.pairingId)),
  );
  return joined ?? false;
}

class _JoinSheet extends ConsumerStatefulWidget {
  const _JoinSheet({required this.serviceKey, required this.label, required this.host, required this.name, required this.noPayments});

  final String serviceKey;
  final String label;
  final String host;

  /// The user's own name at this contact from the hello (`nsJoin*` select argument), `none` without one.
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
      await ref.read(nameServiceProvider)!.join(widget.serviceKey);
      notices.show(l.nsJoinedNotice(widget.name, widget.label), level: NoticeLevel.success);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      notices.show(describeError(l, error), level: NoticeLevel.error);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final title = l.nsJoinTitle(widget.name, widget.label);
    return KitSheet(
      title: title,
      primary: KitButton(
        key: nsJoinKey,
        label: l.nsJoin(widget.name, widget.label),
        semanticsId: TrustIds.pairflowNsJoin,
        onPressed: _busy ? null : _join,
      ),
      secondary: KitButton(
        key: nsNotNowKey,
        label: l.nsNotNow,
        kind: KitButtonKind.quiet,
        semanticsId: TrustIds.pairflowNsNotNow,
        onPressed: _busy ? null : () => Navigator.pop(context, false),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.nsJoinBody(widget.name, widget.label, widget.host), style: KitType.body.copyWith(color: t.dim)),
                  if (widget.noPayments) ...[
                    const SizedBox(height: 8),
                    Text(l.contactNoPaymentsNamed(widget.label), style: KitType.body.copyWith(color: t.dim)),
                  ],
                ],
              ),
            ),
            InfoHint(l.nsJoinInfo(widget.label), title: title),
          ],
        ),
      ),
    );
  }
}

/// The four pictures of [indexes] as a code the user compares or reads.
class NameServiceCodeTiles extends StatelessWidget {
  const NameServiceCodeTiles({super.key, required this.indexes, required this.label, this.size = WordTileSize.check});

  final List<int> indexes;
  final String label;
  final WordTileSize size;

  @override
  Widget build(BuildContext context) => WordTiles(words: codeWords(indexes), label: label, size: size);
}

/// Check the code: the four pictures the name service shows in its chat, to compare.
class NameServiceCodeCheck extends StatelessWidget {
  const NameServiceCodeCheck({
    super.key,
    required this.label,
    required this.serviceKey,
    this.noPayments = false,
    required this.busy,
    required this.onMatch,
    required this.onNoMatch,
    required this.matchKey,
    required this.noMatchKey,
  });

  final String label;
  final String serviceKey;

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
    return PairFlowPage(
      title: l.nsCodeTitle,
      leadingId: TrustIds.pairflowNsCheckClose,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KitButton(key: matchKey, label: l.sasMatch, semanticsId: TrustIds.pairflowNsMatch, onPressed: busy ? null : onMatch),
          const PairGap(10),
          KitButton(
            key: noMatchKey,
            label: l.sasNoMatch,
            kind: KitButtonKind.quiet,
            semanticsId: TrustIds.pairflowNsNoMatch,
            onPressed: busy ? null : onNoMatch,
          ),
        ],
      ),
      children: [
        const PairGap(6),
        Row(
          children: [
            PairAvatar(name: label),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: KitType.sheetTitle.copyWith(color: t.text), maxLines: 2, overflow: TextOverflow.ellipsis)),
            if (noPayments) ...[const SizedBox(width: 8), const NoPaymentsBadge()],
          ],
        ),
        const PairGap(14),
        PairLead(l.nsCodeLead(label)),
        const PairGap(16),
        PairCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
              child: NameServiceCodeTiles(key: nsCodeKey, indexes: nameServiceCodeIndexes(fromHex(serviceKey)), label: l.nsCodeLabel),
            ),
          ],
        ),
      ],
    );
  }
}

/// The name service block of a contact page: for the pairing [pairingId] when a verified name service
/// is behind it, else nothing. [label] is the contact's name.
class NameServiceBlock extends ConsumerStatefulWidget {
  const NameServiceBlock({super.key, required this.pairingId, required this.label});

  final String pairingId;
  final String label;

  @override
  ConsumerState<NameServiceBlock> createState() => _NameServiceBlockState();
}

class _NameServiceBlockState extends ConsumerState<NameServiceBlock> {
  bool _busy = false;

  Future<void> _join(NameServiceEntry e) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await showNameServiceJoinSheet(context, ref, serviceKey: e.serviceKey, label: widget.label);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave(NameServiceEntry e) async {
    if (_busy) return;
    final l = context.l10n;
    final notices = ref.read(noticeProvider.notifier);
    setState(() => _busy = true);
    try {
      await ref.read(nameServiceProvider)!.leave(e.serviceKey);
      notices.show(l.nsLeftNotice(e.payAsArg, widget.label), level: NoticeLevel.success);
    } catch (error) {
      notices.show(describeError(l, error), level: NoticeLevel.error);
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    // Remove the name service too: the existing remove-pairing path.
    final remove = await confirmPairSheet(
      context,
      title: l.nsRemoveTooTitle(widget.label),
      body: l.contactRemovePairingBody(widget.label),
      action: l.contactRemove,
      cancel: l.contactKeep,
      risky: true,
      actionKey: nsRemoveTooKey,
      sheetId: TrustIds.pairflowNsRemoveSheet,
      actionId: TrustIds.pairflowNsRemoveConfirm,
      cancelId: TrustIds.pairflowNsRemoveKeep,
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
    final entry = ref.watch(phoneNameServices.nameServiceOfPairing(widget.pairingId));
    if (entry == null) return const SizedBox.shrink();
    final l = context.l10n;
    final t = context.tokens;
    final service = ref.read(nameServiceProvider);
    final code = service?.listingCodeFor(entry.serviceKey);
    final since = entry.joinedAt;
    final joined = entry.joined;
    final unlisted = entry.state == ListingState.unlisted;
    final since0 = since == null ? '' : MaterialLocalizations.of(context).formatMediumDate(since.toLocal());
    return Column(
      key: nsBlockKey,
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
                        Text(joined ? l.nsJoined(entry.payAsArg, widget.label, since0) : (unlisted ? l.nsNotListed : l.nsNotJoined), style: KitType.rowTitle.copyWith(color: t.text)),
                        if (unlisted) Text(l.nsNotListedBody(widget.label), style: KitType.rowSub.copyWith(color: t.dim)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Flexible: a long "Pay me as @name" button wraps instead of overflowing.
                  Flexible(
                    flex: 2,
                    child: joined
                        ? KitButton(
                            key: nsLeaveKey,
                            label: l.nsLeave,
                            small: true,
                            kind: KitButtonKind.quiet,
                            semanticsId: TrustIds.pairflowNsLeave,
                            onPressed: _busy ? null : () => _leave(entry),
                          )
                        : KitButton(
                            key: nsJoinKey,
                            label: unlisted ? l.nsJoinAgain : l.nsJoin(entry.payAsArg, widget.label),
                            small: true,
                            semanticsId: TrustIds.pairflowNsBlockJoin,
                            onPressed: _busy ? null : () => _join(entry),
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
                        Expanded(child: Text(l.nsListingCode, style: KitType.groupLabel.copyWith(color: t.dim))),
                        InfoHint(l.nsListingCodeInfo(widget.label), title: l.nsListingCode, size: InfoHint.inRow),
                      ],
                    ),
                    const SizedBox(height: 8),
                    NameServiceCodeTiles(indexes: code, label: l.nsListingCode, size: WordTileSize.small),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
