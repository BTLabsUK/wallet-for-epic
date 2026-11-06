// SPDX-License-Identifier: Apache-2.0
/// The desktop's parts of a name service pairing: the Join dialog, the waiting and Check the code
/// bodies of the words dialog, and the name service block of a contact page (Joined · since, the
/// listing code, Leave; Join; Not listed). The service and the words behind them are in
/// `name_service/`; nothing here names a service, the label is the pairing's name.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../name_service/name_service.dart';
import '../../../ui/pairing/pairing_parts.dart' show NoPaymentsBadge, WordTileSize, WordTiles;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/name_service_state.dart';
import '../../data/pairing_state.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import 'pair_screens.dart' show DeskPairAvatar;

/// Keys for tests.
const Key deskDirJoinKey = ValueKey('desk-dir-join');
const Key deskDirNotNowKey = ValueKey('desk-dir-not-now');
const Key deskDirWaitCancelKey = ValueKey('desk-dir-wait-cancel');
const Key deskDirLeaveKey = ValueKey('desk-dir-leave');
const Key deskDirBlockKey = ValueKey('desk-dir-block');
const Key deskDirCodeKey = ValueKey('desk-dir-code');
const Key deskDirRemoveTooKey = ValueKey('desk-dir-remove-too');

/// The Join dialog for the verified name service [serviceKey] named [label]. True once joined; false for
/// Not now or a failure (a toast says why).
Future<bool> showDeskNameServiceJoin(BuildContext context, WidgetRef ref, {required String serviceKey, required String label}) async {
  final service = ref.read(deskNameServiceProvider);
  if (service == null) return false;
  final l = context.l10n;
  final String host;
  try {
    host = await service.joinHost(serviceKey);
  } catch (error) {
    if (context.mounted) showEToast(context, deskErrorText(error, l), tone: ETone.risk);
    return false;
  }
  if (!context.mounted) return false;
  final entry = service.entryOf(serviceKey);
  final joined = await showEDialog<bool>(
    context,
    builder: (_) => _JoinDialog(serviceKey: serviceKey, label: label, host: host, name: entry?.payAsArg ?? 'none', noPayments: ref.read(paymentRefusalsProvider).refusesPayments(pairingId: entry?.pairingId)),
  );
  return joined ?? false;
}

class _JoinDialog extends ConsumerStatefulWidget {
  const _JoinDialog({required this.serviceKey, required this.label, required this.host, required this.name, required this.noPayments});

  final String serviceKey;
  final String label;
  final String host;

  /// The user's own name at this contact from the hello (`nsJoin*` select argument), `none` without one.
  final String name;

  /// The contact takes no payments: the dialog says so in a second paragraph.
  final bool noPayments;

  @override
  ConsumerState<_JoinDialog> createState() => _JoinDialogState();
}

class _JoinDialogState extends ConsumerState<_JoinDialog> {
  bool _busy = false;

  Future<void> _join() async {
    if (_busy) return;
    final l = context.l10n;
    final host = Navigator.of(context).context;
    setState(() => _busy = true);
    try {
      await ref.read(deskNameServiceProvider)!.join(widget.serviceKey);
      if (!mounted) return;
      Navigator.pop(context, true);
      if (host.mounted) showEToast(host, l.nsJoinedNotice(widget.name, widget.label), tone: ETone.ok);
    } catch (error) {
      if (!mounted) return;
      showEToast(context, deskErrorText(error, l), tone: ETone.risk);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EDialog(
      title: l.nsJoinTitle(widget.name, widget.label),
      titleTrailing: EInfoHint(l.nsJoinInfo(widget.label), title: l.nsJoinTitle(widget.name, widget.label)),
      icon: EIcons.trusted,
      description: widget.noPayments
          ? '${l.nsJoinBody(widget.name, widget.label, widget.host)}\n\n${l.contactNoPaymentsNamed(widget.label)}'
          : l.nsJoinBody(widget.name, widget.label, widget.host),
      actions: [
        EButton(key: deskDirNotNowKey, label: l.nsNotNow, onPressed: _busy ? null : () => Navigator.pop(context, false)),
        EButton.primary(key: deskDirJoinKey, label: l.nsJoin(widget.name, widget.label), busy: _busy, onPressed: _busy ? null : _join),
      ],
    );
  }
}

/// The body of the words dialog while it waits for the name service's message: static text, never a
/// spinner. Cancel gives the ordinary words step.
class DeskNameServiceWaiting extends StatelessWidget {
  const DeskNameServiceWaiting({super.key, required this.label, required this.onCancel});

  final String label;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    return EDialog(
      title: l.nsCodeTitle,
      icon: EIcons.trusted,
      body: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(EIcons.sand, color: context.dc.info),
            SizedBox(width: Sp.x3),
            Expanded(child: Text(l.nsWaitingFor(label), style: ts.body)),
          ],
        ),
      ),
      actions: [EButton(key: deskDirWaitCancelKey, label: l.commonCancel, onPressed: onCancel)],
    );
  }
}

/// Check the code: the four pictures the name service shows in its chat, to compare.
class DeskNameServiceCodeCheck extends StatelessWidget {
  const DeskNameServiceCodeCheck({
    super.key,
    required this.label,
    required this.serviceKey,
    this.noPayments = false,
    required this.busy,
    required this.onLater,
    required this.onMatch,
    required this.onNoMatch,
    required this.matchKey,
    required this.noMatchKey,
    required this.laterKey,
  });

  final String label;
  final String serviceKey;

  /// The hello says the contact takes no payments: its badge sits in the head row.
  final bool noPayments;
  final bool busy;
  final VoidCallback onLater;
  final VoidCallback onMatch;
  final VoidCallback onNoMatch;
  final Key matchKey;
  final Key noMatchKey;
  final Key laterKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    return EDialog(
      title: l.nsCodeTitle,
      icon: EIcons.trusted,
      size: DialogWidth.wide,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [DeskPairAvatar(name: label, size: 48.u), SizedBox(width: Sp.x3), Expanded(child: Text(label, style: ts.h3)), if (noPayments) ...[SizedBox(width: Sp.x2), const NoPaymentsBadge()]]),
          SizedBox(height: Sp.x3),
          Text(l.nsCodeLead(label), style: ts.bodyDim),
          SizedBox(height: Sp.x4),
          WordTiles(key: deskDirCodeKey, words: codeWords(nameServiceCodeIndexes(fromHex(serviceKey))), label: l.nsCodeLabel, size: WordTileSize.check),
        ],
      ),
      actions: [
        EButton(key: laterKey, label: l.pairBack, onPressed: busy ? null : onLater),
        EButton(key: noMatchKey, label: l.sasNoMatch, onPressed: busy ? null : onNoMatch),
        EButton.primary(key: matchKey, label: l.sasMatch, busy: busy, onPressed: busy ? null : onMatch),
      ],
    );
  }
}

/// The name service block of a contact page: for the pairing [pairingId] when a verified name service
/// is behind it, else nothing. [label] is the contact's name.
class DeskNameServiceBlock extends ConsumerStatefulWidget {
  const DeskNameServiceBlock({super.key, required this.pairingId, required this.label});

  final String pairingId;
  final String label;

  @override
  ConsumerState<DeskNameServiceBlock> createState() => _DeskNameServiceBlockState();
}

class _DeskNameServiceBlockState extends ConsumerState<DeskNameServiceBlock> {
  bool _busy = false;

  Future<void> _join(NameServiceEntry e) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await showDeskNameServiceJoin(context, ref, serviceKey: e.serviceKey, label: widget.label);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave(NameServiceEntry e) async {
    if (_busy) return;
    final l = context.l10n;
    final host = Navigator.of(context).context;
    setState(() => _busy = true);
    try {
      await ref.read(deskNameServiceProvider)!.leave(e.serviceKey);
      if (host.mounted) showEToast(host, l.nsLeftNotice(e.payAsArg, widget.label), tone: ETone.ok);
    } catch (error) {
      if (mounted) {
        showEToast(context, deskErrorText(error, l), tone: ETone.risk);
        setState(() => _busy = false);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    // Remove the name service too: the existing remove-pairing path.
    final remove = await showEDialog<bool>(
      context,
      builder: (ctx) => EDialog(
        title: l.nsRemoveTooTitle(widget.label),
        description: l.contactRemovePairingBody(widget.label),
        tone: ETone.risk,
        icon: EIcons.trash,
        actions: [
          EButton(label: l.contactKeep, onPressed: () => Navigator.pop(ctx, false)),
          EButton(key: deskDirRemoveTooKey, label: l.contactRemove, kind: EBtnKind.danger, onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (remove != true || !mounted) return;
    try {
      await deskPairingCall(ref, (api) => api.removePairing(widget.pairingId));
    } catch (error) {
      if (mounted) showEToast(context, deskErrorText(error, l), tone: ETone.risk);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(deskNameServices.nameServiceOfPairing(widget.pairingId));
    if (entry == null) return const SizedBox.shrink();
    final l = context.l10n;
    final ts = context.ts;
    final code = ref.read(deskNameServiceProvider)?.listingCodeFor(entry.serviceKey);
    final joined = entry.joined;
    final unlisted = entry.state == ListingState.unlisted;
    final since = entry.joinedAt;
    final sinceText = since == null ? '' : MaterialLocalizations.of(context).formatMediumDate(since.toLocal());
    return Padding(
      key: deskDirBlockKey,
      padding: EdgeInsets.only(top: Sp.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.label, style: ts.label),
          SizedBox(height: Sp.x2),
          ESetGroup(
            gap: false,
            rows: [
              ESetRow(
                title: joined ? l.nsJoined(entry.payAsArg, widget.label, sinceText) : (unlisted ? l.nsNotListed : l.nsNotJoined),
                text: unlisted ? l.nsNotListedBody(widget.label) : null,
                control: joined
                    ? EButton(key: deskDirLeaveKey, label: l.nsLeave, size: EBtnSize.sm, onPressed: _busy ? null : () => _leave(entry))
                    : EButton.primary(
                        key: deskDirJoinKey,
                        label: unlisted ? l.nsJoinAgain : l.nsJoin(entry.payAsArg, widget.label),
                        size: EBtnSize.sm,
                        onPressed: _busy ? null : () => _join(entry),
                      ),
              ),
              if (joined && code != null)
                ESetRow(
                  title: l.nsListingCode,
                  hint: l.nsListingCodeInfo(widget.label),
                  below: WordTiles(words: codeWords(code), label: l.nsListingCode, size: WordTileSize.small),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
