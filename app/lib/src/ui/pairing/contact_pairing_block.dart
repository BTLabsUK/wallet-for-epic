// SPDX-License-Identifier: Apache-2.0
/// The contact page's Pairing block, per state: Not paired with Pair; a request sent (the
/// date, Cancel, Show my code; expired: No answer, Pair again, Remove); Waiting for the
/// other wallet (Check the words, Remove pairing); Paired with "has not checked yet" and Check the
/// words; Verified with "confirmed too"; Keys changed; Ended with its reason, the sealed sends
/// still waiting (each with Cancel) and Remove. Seal payments and Allow invoices as before.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../amount.dart';
import '../../contacts.dart';
import '../../name_service/payment_refusals.dart' show paymentRefusalsProvider;
import '../../trust/policy.dart' show statedAutomated;
import '../../errors.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../pairing_text.dart';
import '../../providers.dart';
import '../../relay_moves.dart' show relayLabelOf;
import '../../wallet_service.dart';
import '../common.dart';
import '../status_icons.dart' show EpicGlyphs;
import '../theme/tokens.dart';
import 'pair_check.dart';
import 'pair_incoming.dart' show confirmCancelPairing;
import 'pair_screen.dart';
import 'pairing_parts.dart';
import 'relay_move_sheet.dart' show acceptPhoneRelayMove, refusePhoneRelayMove;

/// Keys for tests.
const Key contactPagePairKey = ValueKey('contact-page-pair');
const Key contactPageSealKey = ValueKey('contact-page-seal');
const Key contactPageInvoicesKey = ValueKey('contact-page-invoices');
const Key contactPageRemovePairingKey = ValueKey('contact-page-remove-pairing');
const Key contactPageCheckKey = ValueKey('contact-page-check');
const Key contactPageCancelPairingKey = ValueKey('contact-page-cancel-pairing');
const Key contactPageShowCodeKey = ValueKey('contact-page-show-code');
const Key contactPageNotAnsweringKey = ValueKey('contact-page-not-answering');
const Key contactPagePairAgainKey = ValueKey('contact-page-pair-again');
const Key contactPageEndedKey = ValueKey('contact-page-ended');
const Key contactPageHeldSendKey = ValueKey('contact-page-held-send');
const Key contactPageUpdateAddressKey = ValueKey('contact-page-update-address');
const Key contactPageDetachKey = ValueKey('contact-page-detach');
const Key contactPageUnprovenKey = ValueKey('contact-page-unproven');
const Key contactPagePairAgainUnprovenKey = ValueKey('contact-page-pair-again-unproven');
const Key contactPageMoveAskedKey = ValueKey('contact-page-move-asked');
const Key contactPageMoveAcceptKey = ValueKey('contact-page-move-accept');
const Key contactPageMoveRefuseKey = ValueKey('contact-page-move-refuse');
const Key contactPageMoveLineKey = ValueKey('contact-page-move-line');

/// The Pairing section of [contact]: [pairing] is the record the contact uses (null for
/// none), [pending] a request sent or an answer waiting for its confirm.
class ContactPairingBlock extends ConsumerWidget {
  const ContactPairingBlock({
    super.key,
    required this.contact,
    required this.pairing,
    required this.pending,
    required this.busy,
    required this.run,
    required this.onPair,
  });

  final Contact contact;
  final PairingRecord? pairing;
  final PairingRecord? pending;
  final bool busy;
  final Future<void> Function(Future<void> Function() call) run;

  /// Pair: the request sheet, or the Pair screen for the contact.
  final VoidCallback onPair;

  void _showCode(BuildContext context) =>
      Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => PairScreen(contact: contact)));

  void _check(BuildContext context, PairingRecord p) =>
      Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: p.id, recheck: p.state.isPaired)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = pairing;
    final q = pending;
    final now = ref.watch(pairingClockProvider)();
    if (p == null && q != null) return _pendingBlock(context, ref, q, now);
    if (p == null) return _notPaired(context, l);
    if (p.state == PairingState.ended) return _ended(context, ref, p);
    return _live(context, ref, p);
  }

  Widget _notPaired(BuildContext context, AppLocalizations l) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return PairCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            children: [
              Icon(EpicGlyphs.paired, color: t.dim),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.pairNotPaired, style: theme.textTheme.bodyLarge),
                    Text(l.pairNotPairedHint, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(key: contactPagePairKey, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)), onPressed: onPair, child: Text(l.pairTitle)),
            ],
          ),
        ),
      ],
    );
  }

  /// A request sent (or a code answered, waiting for its confirm): Waiting, with Cancel and
  /// Show my code from the first moment. Expired unanswered: No answer, Pair again, Remove.
  Widget _pendingBlock(BuildContext context, WidgetRef ref, PairingRecord q, DateTime now) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final expired = q.state == PairingState.pendingInvite && q.expiredAt(now);
    final name = contact.name;
    Future<void> cancel() async {
      if (expired || await confirmCancelPairing(context, name)) {
        await run(() => pairingCall(ref, (api) => api.cancelInvite(q.id)));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PairCard(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  if (expired) Icon(Icons.schedule, color: t.warn, size: 22) else const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(expired ? l.pairNoAnswerFrom(name) : l.pairWaitingFor(name), style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                        if (q.state == PairingState.pendingInvite)
                          Text(l.pairRequestSent(localDayMonth(l, q.createdAt)), style: theme.textTheme.bodySmall?.copyWith(color: t.dim))
                        else
                          Text(l.pairPairingWith(name), style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (expired)
              FilledButton.tonal(key: contactPagePairAgainKey, onPressed: busy ? null : () => _showCode(context), child: Text(l.pairAgain))
            else
              OutlinedButton(key: contactPageShowCodeKey, onPressed: busy ? null : () => _showCode(context), child: Text(l.pairShowMyCode)),
            TextButton(
              key: contactPageCancelPairingKey,
              style: TextButton.styleFrom(foregroundColor: t.risk),
              onPressed: busy ? null : cancel,
              child: Text(expired ? l.contactRemove : l.commonCancel),
            ),
          ],
        ),
      ],
    );
  }

  /// Ended: the reason, the sealed sends held in that mailbox with Cancel, Pair again, Remove.
  Widget _ended(BuildContext context, WidgetRef ref, PairingRecord p) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final name = contact.name;
    final held = ref.watch(heldSendsProvider(p.id));
    final session = ref.read(sessionProvider);
    Future<void> cancelSend(TxEntry tx) => run(() async {
      final id = tx.id;
      if (session == null || id == null) return;
      await session.cancelTransaction(txId: id);
      ref.invalidate(homeProvider);
    });
    Future<void> remove() async {
      if (await confirmRemovePairing(context, name)) await run(() => pairingCall(ref, (api) => api.removePairing(p.id)));
    }

    return Column(
      key: contactPageEndedKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PairCard(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.block, color: t.dim, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.pairEndedShort, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                        Text(pairingEndedRowText(l, p.endedReason ?? PairingEndReason.neverFinished), style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (final tx in held)
              Padding(
                key: contactPageHeldSendKey,
                padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 6, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(epicFor(l, -tx.amountDebited), style: theme.textTheme.bodyMedium?.copyWith(fontFamily: t.monoFamily)),
                          Text(l.pairHeldSend, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                        ],
                      ),
                    ),
                    TextButton(style: TextButton.styleFrom(foregroundColor: t.risk), onPressed: busy ? null : () => cancelSend(tx), child: Text(l.commonCancel)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonal(key: contactPagePairAgainKey, onPressed: busy ? null : () => _showCode(context), child: Text(l.pairAgain)),
            TextButton(key: contactPageRemovePairingKey, style: TextButton.styleFrom(foregroundColor: t.risk), onPressed: busy ? null : remove, child: Text(l.contactRemovePairing)),
          ],
        ),
      ],
    );
  }

  /// Waiting, Paired, Verified or Keys changed: the status row, the two switches, the relay.
  Widget _live(BuildContext context, WidgetRef ref, PairingRecord p) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final name = contact.name;
    final net = ref.watch(pairNetProvider);
    final paused = net == PairNet.epicboxOff;
    final changed = p.state == PairingState.keysChanged;
    final verified = p.state == PairingState.verified;
    final waiting = p.state == PairingState.waiting;
    final noPayments = ref.watch(paymentRefusalsProvider).refusesPayments(pairingId: p.id);
    final notices = ref.read(noticeProvider.notifier);
    final back = ref.watch(keysBackProvider).contains(p.id);

    Future<void> setSeal(bool on) => run(() async {
      await pairingCall(ref, (api) => api.setSeal(p.id, on));
    });
    Future<void> setInvoices(bool on) => run(() async {
      final declined = await pairingCall(ref, (api) => api.setAllowInvoices(p.id, on));
      if (!on) {
        notices.show(
          declined > 0 ? '${l.invSetSwitchedOff(name)} ${l.invSetDeclinedCount(declined)}' : l.invSetSwitchedOff(name),
          level: NoticeLevel.info,
        );
      }
    });
    Future<void> keys(KeysChoice choice) => run(() async {
      await pairingCall(ref, (api) => api.resolveKeysChanged(p.id, choice));
    });
    Future<void> remove() async {
      if (await confirmRemovePairing(context, name)) {
        await run(() => pairingCall(ref, (api) => api.removePairing(p.id)));
      }
    }

    // A later card proved another address than the contact's: the user decides.
    final provesOther = p.paymentsAddress != null && contact.epicbox != null && !pairingVouchesFor(p, contact.epicbox);
    // A pairing made before addresses were proven: nothing confirms the contact's address.
    final unproven = (verified || p.state == PairingState.paired) && p.paymentsAddress == null;
    Future<void> updateAddress() => run(() async {
      await ref.read(contactsProvider.notifier).save(contact.withAddress(RecipientKind.epicbox, p.paymentsAddress));
    });
    Future<void> detach() => run(() => pairingCall(ref, (api) => api.attach(p.id, null)));

    final sealInfo = '${l.contactSealInfo(name)}\n\n${l.contactSealInfoMore(name)}';
    final allowInfo = '${l.contactAllowInfo(name)}\n\n${l.contactAllowInfoMore}';
    final statusText = changed
        ? l.trustKeysChanged
        : waiting
            ? l.pairWaitingFor(name)
            : verified
                ? l.trustVerified
                : l.trustPaired;
    final statusLine = changed
        ? l.contactKeysChangedStatus
        : waiting
            ? l.pairAnsweredNotHeard
            : statedAutomated(p.peerProfile)
                ? l.pairIsService
                : (verified && p.peerVerifiedAt != null)
                    ? l.pairConfirmedToo(name)
                    : l.pairNotChecked(name);
    final status = Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      child: Row(
        children: [
          if (waiting)
            const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          else
            Icon(
              changed ? EpicGlyphs.keysChanged : (verified ? EpicGlyphs.verified : EpicGlyphs.paired),
              color: changed ? t.risk : (verified ? t.ok : t.warn),
              size: 22,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: statusText, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (verified && p.verifiedAt != null)
                        TextSpan(text: '  ${localDayMonth(l, p.verifiedAt!)}', style: TextStyle(color: t.dim, fontFamily: t.monoFamily, fontSize: 12)),
                    ],
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
                Text(statusLine, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
              ],
            ),
          ),
          if ((p.state == PairingState.paired || waiting) && p.sas.isNotEmpty)
            OutlinedButton(
              key: contactPageCheckKey,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () => _check(context, p),
              child: Text(l.pairCheckWords),
            ),
        ],
      ),
    );
    // A relay move (`relay_moves.dart`): asked and open as a notice above; refused, not
    // followed or made in the last 30 days as a quiet line under the relay.
    final asked = p.requestedRelay;
    final moveShown = asked == null ? null : relayLabelOf(asked);
    final moveOpen = asked != null && (p.relayMove == RelayMoveState.ask || p.relayMove == RelayMoveState.open);
    Future<void> acceptMove() => run(() => acceptPhoneRelayMove(ref, p, asked!));
    Future<void> refuseMove() => run(() => refusePhoneRelayMove(ref, p, asked!));
    final moveLine = paused || moveShown == null
        ? (paused || p.movedAt == null ? null : l.contactMovedOn(localDayMonth(l, p.movedAt!)))
        : switch (p.relayMove) {
            RelayMoveState.refused => l.contactMoveRefused(moveShown),
            RelayMoveState.notPublic => l.contactMoveNotPublic(moveShown),
            _ => p.movedAt == null ? null : l.contactMovedOn(localDayMonth(l, p.movedAt!)),
          };
    final relayRow = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 6, 12),
      child: Row(
        children: [
          Icon(paused ? Icons.pause_circle_outline : Icons.alt_route, size: 20, color: t.dim),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paused ? l.contactPausedEpicboxOff : l.contactDeliveredVia(p.homeRelay),
                  style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
                ),
                if (moveLine != null)
                  Text(moveLine, key: contactPageMoveLineKey, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
              ],
            ),
          ),
          if (!paused && asked != null && p.relayMove == RelayMoveState.refused)
            TextButton(key: contactPageMoveAcceptKey, onPressed: busy ? null : acceptMove, child: Text(l.relayMoveAccept)),
        ],
      ),
    );
    final switchesLocked = busy || paused || changed || waiting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (changed) ...[
          PairEdgeNotice(
            tone: BadgeTone.warn,
            title: l.contactKeysChangedTitle(name),
            body: l.contactKeysChangedBody,
            stretchActions: true,
            actions: [
              FilledButton(onPressed: busy ? null : () => _check(context, p), child: Text(l.pairCheckWords)),
              OutlinedButton(onPressed: busy ? null : () => keys(KeysChoice.keepOld), child: Text(l.contactKeepOldKeys)),
              OutlinedButton(onPressed: busy ? null : () => keys(KeysChoice.useNew), child: Text(l.contactUseNewKeys)),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (back && !changed) ...[
          PairEdgeNotice(
            tone: BadgeTone.ok,
            title: l.contactKeysBack(name),
            body: l.contactKeysBackBody,
            actions: [TextButton(onPressed: () => ref.read(keysBackProvider.notifier).close(p.id), child: Text(l.commonOk))],
          ),
          const SizedBox(height: 12),
        ],
        if (p.relayDown && !paused) ...[
          PairEdgeNotice(tone: BadgeTone.warn, title: l.contactRelayDownTitle(name), body: l.contactRelayDownBody),
          const SizedBox(height: 12),
        ],
        // The check after a long gap got no answer: Pair again, until the contact is heard.
        if (p.notAnswering && !paused && !changed) ...[
          PairEdgeNotice(
            key: contactPageNotAnsweringKey,
            tone: BadgeTone.warn,
            title: l.trustNotAnswering,
            body: l.contactNotAnsweringBody,
            actions: [FilledButton.tonal(key: contactPagePairAgainKey, onPressed: busy ? null : () => _showCode(context), child: Text(l.pairAgain))],
          ),
          const SizedBox(height: 12),
        ],
        if (provesOther) ...[
          PairEdgeNotice(
            tone: BadgeTone.warn,
            title: l.pairProvesOther(name),
            body: p.paymentsAddress,
            actions: [
              FilledButton.tonal(key: contactPageUpdateAddressKey, onPressed: busy ? null : updateAddress, child: Text(l.pairUpdateAddress)),
              OutlinedButton(key: contactPageDetachKey, onPressed: busy ? null : detach, child: Text(l.pairDetach)),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (moveOpen && !paused) ...[
          PairEdgeNotice(
            key: contactPageMoveAskedKey,
            tone: BadgeTone.info,
            title: l.contactMoveAsked(moveShown!),
            body: l.relayMoveBody(name, moveShown),
            actions: [
              FilledButton.tonal(key: contactPageMoveAcceptKey, onPressed: busy ? null : acceptMove, child: Text(l.relayMoveAccept)),
              OutlinedButton(key: contactPageMoveRefuseKey, onPressed: busy ? null : refuseMove, child: Text(l.relayMoveRefuse)),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (p.seal == SealMode.degraded && !changed) ...[
          PairEdgeNotice(tone: BadgeTone.info, title: l.contactSealDegradedTitle(name), body: l.contactSealDegradedBody(name)),
          const SizedBox(height: 12),
        ],
        PairCard(
          children: [
            status,
            // A contact that takes no payments has nothing to seal or invoice.
            if (!noPayments)
            PairSwitchRow(
              switchKey: contactPageSealKey,
              label: l.contactSealPayments,
              info: sealInfo,
              value: !changed && !waiting && p.seal != SealMode.off,
              hint: changed ? l.contactPausedUntilChecked : (waiting ? l.pairWaitingFor(name) : null),
              onChanged: switchesLocked ? null : setSeal,
            ),
            // Invoices off (Settings › Advanced): the switch is not offered; what it holds stays.
            if (!noPayments && ref.watch(invoicesOnProvider))
              PairSwitchRow(
                switchKey: contactPageInvoicesKey,
                label: l.contactAllowInvoices,
                info: allowInfo,
                value: verified && p.allowInvoices,
                hint: changed ? l.contactPausedUntilChecked : (verified ? null : l.contactCheckWordsFirst),
                onChanged: switchesLocked || !verified ? null : setInvoices,
              ),
            relayRow,
          ],
        ),
        if (unproven)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Text(l.pairAddressNotConfirmed, key: contactPageUnprovenKey, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
          ),
        Wrap(
          spacing: 8,
          children: [
            if (unproven)
              OutlinedButton(key: contactPagePairAgainUnprovenKey, onPressed: busy ? null : onPair, child: Text(l.pairAgain)),
            if (waiting) OutlinedButton(key: contactPageShowCodeKey, onPressed: busy ? null : () => _showCode(context), child: Text(l.pairShowMyCode)),
            TextButton(
              key: contactPageRemovePairingKey,
              style: TextButton.styleFrom(foregroundColor: t.risk, minimumSize: const Size(0, 48)),
              onPressed: busy ? null : remove,
              child: Text(l.contactRemovePairing),
            ),
          ],
        ),
      ],
    );
  }
}

/// Words a data error reads as, for the block's calls.
String pairingCallError(AppLocalizations l, Object error) {
  final failure = pairingFailureOf(error);
  return failure == null ? describeError(l, error) : pairingFailureText(l, failure);
}
