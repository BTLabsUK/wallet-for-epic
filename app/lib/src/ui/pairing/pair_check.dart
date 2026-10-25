/// Check the words (SPEC 2.3, RFC 7.5): the four words both wallets show, then They match
/// (Verified), They don't match (the pairing goes on this side) or Skip for now (Paired, not
/// verified). The results offer to save the contact; the app never decides on its own which
/// address-book entry a pairing belongs to.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contacts.dart';
import '../../errors.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../wallet_service.dart';
import '../common.dart';
import '../contacts_screen.dart';
import '../status_icons.dart';
import '../theme/brand.dart';
import '../theme/tokens.dart';
import 'pairing_notices.dart' show pairingWordsOnScreen;
import 'pairing_parts.dart';

/// Keys for tests.
const Key checkMatchKey = ValueKey('check-match');
const Key checkNoMatchKey = ValueKey('check-no-match');
const Key checkSkipKey = ValueKey('check-skip');
const Key checkStopKey = ValueKey('check-stop');
const Key checkDoneKey = ValueKey('check-done');
const Key checkAllowKey = ValueKey('check-allow');
const Key resultAllowKey = ValueKey('result-allow');
const Key resultSaveNewKey = ValueKey('result-save-new');
const Key resultAddToKey = ValueKey('result-add-to');

/// The words check of the pairing [pairingId]. [recheck] is the contact page's "Check the
/// words again": Later instead of Skip for now. [inPerson]: the camera saw the other phone.
/// Asks before removing the pairing with [name] (SPEC 2.4): Keep, or Remove in risk. Undoing it
/// means pairing again.
Future<bool> confirmRemovePairing(BuildContext context, String name) async {
  final l = context.l10n;
  final sure = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.contactRemovePairingTitle(name)),
      content: Text(l.contactRemovePairingBody(name)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.contactKeep)),
        TextButton(
          key: confirmRemovePairingKey,
          style: TextButton.styleFrom(foregroundColor: context.tokens.risk),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.contactRemove),
        ),
      ],
    ),
  );
  return sure ?? false;
}

/// The Remove button of [confirmRemovePairing], for tests.
const Key confirmRemovePairingKey = ValueKey('confirm-remove-pairing');

/// Save as a new contact: the form with the name the pairing claims and its card's payments
/// address, for the user to check. The contact saved, or null.
Future<Contact?> savePairingAsNewContact(BuildContext context, PairingRecord r) => Navigator.of(context).push<Contact>(
  MaterialPageRoute<Contact>(builder: (_) => ContactEditScreen(name: r.name, address: r.paymentsAddress)),
);

/// Add to a contact: the user picks one of theirs; nothing is matched by name or address.
Future<Contact?> pickContactForPairing(BuildContext context) => Navigator.of(context).push<Contact>(
  MaterialPageRoute<Contact>(builder: (_) => const ContactsScreen(pick: true)),
);

class CheckWordsScreen extends ConsumerStatefulWidget {
  const CheckWordsScreen({super.key, required this.pairingId, this.recheck = false, this.inPerson = false});

  final String pairingId;
  final bool recheck;
  final bool inPerson;

  @override
  ConsumerState<CheckWordsScreen> createState() => _CheckWordsScreenState();
}

class _CheckWordsScreenState extends ConsumerState<CheckWordsScreen> {
  bool _allow = false;
  bool _busy = false;
  bool _onScreen(PairingEvent e) => e.pairingId == widget.pairingId;

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
  }

  @override
  void dispose() {
    pairingWordsOnScreen.remove(_onScreen);
    super.dispose();
  }

  Future<void> _answer(PairingCheck check) async {
    if (_busy) return;
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final record = await pairingCall(ref, (api) => api.checkWords(widget.pairingId, check));
      if (record != null && check == PairingCheck.match && _allow && !record.allowInvoices) {
        await pairingCall(ref, (api) => api.setAllowInvoices(record.id, true));
      }
      if (!mounted) return;
      if (check == PairingCheck.mismatch || record == null) {
        Navigator.pop(context);
        return;
      }
      if (widget.recheck && check == PairingCheck.skip) {
        Navigator.pop(context);
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => PairingResultScreen(pairingId: record.id)),
      );
    } catch (error) {
      if (mounted) ref.read(noticeProvider.notifier).show(describeError(l, error), level: NoticeLevel.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _noMatch() async {
    final l = context.l10n;
    final stop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.sasNoMatchTitle),
        content: Text(l.sasNoMatchBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.pairBack)),
          TextButton(
            key: checkStopKey,
            style: TextButton.styleFrom(foregroundColor: context.tokens.risk),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.sasStopPairing),
          ),
        ],
      ),
    );
    if (stop == true) await _answer(PairingCheck.mismatch);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final record = ref.watch(pairingByIdProvider(widget.pairingId));
    if (record == null) {
      return SlotScaffold(appBar: AppBar(title: Text(l.sasTitle)), body: const SizedBox.shrink());
    }
    final name = ref.watch(pairingNameProvider(record.id));
    final service = record.kind != PairingParty.person;
    final lead = widget.recheck
        ? l.sasLeadRecheck(name)
        : (service && record.way != PairingWay.inPerson ? l.sasLeadExchange(name) : l.sasLead(name));
    final offersInvoices = !widget.recheck && (record.asksInvoices || record.caps.issuesInvoices) && record.state == PairingState.paired;
    return SlotScaffold(
      appBar: AppBar(title: Text(l.sasTitle)),
      body: ScreenBody(
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              key: checkMatchKey,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: _busy ? null : () => _answer(PairingCheck.match),
              child: Text(l.sasMatch),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: checkNoMatchKey,
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: _busy ? null : _noMatch,
                    child: Text(l.sasNoMatch),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    key: checkSkipKey,
                    style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: t.dim),
                    onPressed: _busy ? null : () => _answer(PairingCheck.skip),
                    child: Text(widget.recheck ? l.sasLater : l.sasSkip),
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Row(
            children: [
              PairAvatar(name: name, kind: record.kind),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleMedium?.copyWith(fontFamily: t.headFamily)),
                    const SizedBox(height: 4),
                    const ClaimedNameBadge(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PairLead(lead),
          const SizedBox(height: 16),
          PairCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
                child: WordTiles(words: record.sas, label: l.sasWordsLabel, size: WordTileSize.check),
              ),
            ],
          ),
          if (offersInvoices) ...[
            const SizedBox(height: 16),
            PairCard(
              children: [
                PairSwitchRow(
                  switchKey: checkAllowKey,
                  label: l.contactAllowInvoices,
                  info: '${l.contactAllowInfo(name)}\n\n${l.contactAllowInfoMore}',
                  hint: l.sasAllowAfterMatch,
                  value: _allow,
                  onChanged: _busy ? null : (v) => setState(() => _allow = v),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// After the check: Verified with the two switches, or Paired, not verified with Check now.
/// A pairing not yet in the address book offers Save as a new contact or Add to a contact.
class PairingResultScreen extends ConsumerStatefulWidget {
  const PairingResultScreen({super.key, required this.pairingId});

  final String pairingId;

  @override
  ConsumerState<PairingResultScreen> createState() => _PairingResultScreenState();
}

class _PairingResultScreenState extends ConsumerState<PairingResultScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() call) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await call();
    } catch (error) {
      if (mounted) ref.read(noticeProvider.notifier).show(describeError(context.l10n, error), level: NoticeLevel.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveNew(PairingRecord r) async {
    final saved = await savePairingAsNewContact(context, r);
    if (saved == null || !mounted) return;
    await _attach(r, saved);
  }

  Future<void> _addTo(PairingRecord r) async {
    final picked = await pickContactForPairing(context);
    if (picked == null || !mounted) return;
    await _attach(r, picked);
  }

  Future<void> _attach(PairingRecord r, Contact contact) => _run(() async {
    final l = context.l10n;
    await pairingCall(ref, (api) => api.attach(r.id, contact.id));
    ref.read(noticeProvider.notifier).show(l.pairSavedAs(contact.name), level: NoticeLevel.success);
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final record = ref.watch(pairingByIdProvider(widget.pairingId));
    if (record == null) {
      return SlotScaffold(appBar: AppBar(title: Text(l.pairWaitingTitleShort)), body: const SizedBox.shrink());
    }
    final name = ref.watch(pairingNameProvider(record.id));
    final verified = record.state == PairingState.verified;
    final saved = record.contactId != null && (ref.watch(contactsProvider).value ?? const <Contact>[]).any((c) => c.id == record.contactId);
    final done = FilledButton(
      key: checkDoneKey,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: () => Navigator.pop(context),
      child: Text(l.commonDone),
    );
    return SlotScaffold(
      appBar: AppBar(title: Text(l.pairWaitingTitleShort)),
      body: ScreenBody(
        bottom: verified
            ? done
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: record.id)),
                      ),
                      child: Text(l.sasCheckNow),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: done),
                ],
              ),
        children: [
          const SizedBox(height: 16),
          Center(child: GlyphTile(size: 72, child: Icon(verified ? EpicGlyphs.verified : EpicGlyphs.paired))),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              verified ? l.sasMatchedTitle(name) : l.sasSkippedTitle(name),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontFamily: t.headFamily, fontSize: 22),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            verified ? l.sasMatchedBody(name) : l.sasSkippedBody(name),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
          ),
          const SizedBox(height: 12),
          Center(child: TrustBadge(record)),
          if (verified) ...[
            const SizedBox(height: 20),
            PairCard(
              children: [
                PairSwitchRow(
                  label: l.contactSealPayments,
                  info: '${l.contactSealInfo(name)}\n\n${l.contactSealInfoMore(name)}',
                  value: record.seal != SealMode.off,
                  onChanged: _busy ? null : (v) => _run(() => pairingCall(ref, (api) => api.setSeal(record.id, v))),
                ),
                PairSwitchRow(
                  switchKey: resultAllowKey,
                  label: l.contactAllowInvoices,
                  info: '${l.contactAllowInfo(name)}\n\n${l.contactAllowInfoMore}',
                  hint: l.sasAllowInvoicesHint(name),
                  value: record.allowInvoices,
                  onChanged: _busy ? null : (v) => _run(() => pairingCall(ref, (api) => api.setAllowInvoices(record.id, v))),
                ),
              ],
            ),
          ],
          if (!saved) ...[
            const SizedBox(height: 20),
            PairCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l.pairSaveContactTitle(name), style: theme.textTheme.titleSmall),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonal(
                            key: resultSaveNewKey,
                            onPressed: _busy ? null : () => _saveNew(record),
                            child: Text(l.pairSaveNewContact),
                          ),
                          OutlinedButton(
                            key: resultAddToKey,
                            onPressed: _busy ? null : () => _addTo(record),
                            child: Text(l.pairAddToAContact),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
