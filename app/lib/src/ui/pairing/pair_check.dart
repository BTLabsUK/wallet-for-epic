// SPDX-License-Identifier: Apache-2.0
/// Check the words: the four words both wallets show, then They match (Verified; the other
/// side learns of it) or They do not match (the pairing ends on both sides, kept, its sends
/// held). Back is later: the row stays Paired. The results offer to save the contact; the app
/// never decides on its own which address-book entry a pairing belongs to.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contacts.dart';
import '../../errors.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../pairing_text.dart' show isUnnamed, sameNamedContact;
import '../../wallet_service.dart';
import '../app_dialog.dart';
import '../common.dart';
import '../contact_page.dart' show ContactPage;
import '../contacts_screen.dart';
import '../status_icons.dart';
import '../theme/brand.dart';
import '../theme/tokens.dart';
import 'pairing_notices.dart' show pairingWordsOnScreen;
import 'pairing_parts.dart';

/// Keys for tests.
const Key checkMatchKey = ValueKey('check-match');
const Key checkNoMatchKey = ValueKey('check-no-match');
const Key checkStopKey = ValueKey('check-stop');
const Key checkDoneKey = ValueKey('check-done');
const Key checkAllowKey = ValueKey('check-allow');
const Key resultAllowKey = ValueKey('result-allow');
const Key resultSaveNewKey = ValueKey('result-save-new');
const Key resultAddToKey = ValueKey('result-add-to');
const Key resultAddToNamedKey = ValueKey('result-add-to-named');

/// Asks before removing the pairing with [name]: Keep, or Remove in risk. Undoing it
/// means pairing again.
Future<bool> confirmRemovePairing(BuildContext context, String name) async {
  final l = context.l10n;
  return confirmAppDialog(
    context,
    title: l.contactRemovePairingTitle(name),
    icon: Icons.link_off,
    tone: DialogTone.risk,
    description: l.contactRemovePairingBody(name),
    cancelLabel: l.contactKeep,
    confirmLabel: l.contactRemove,
    risk: true,
    confirmKey: confirmRemovePairingKey,
  );
}

/// The Remove button of [confirmRemovePairing], for tests.
const Key confirmRemovePairingKey = ValueKey('confirm-remove-pairing');

/// Save as a new contact: the form with the name the pairing claims (or "Contact {n}" when it
/// claims none) and its proven address, when it has one, for the user to check. The pairing pays
/// the contact, so no address is needed. The contact saved, or null.
Future<Contact?> savePairingAsNewContact(BuildContext context, PairingRecord r) {
  final count = ProviderScope.containerOf(context).read(contactsProvider).value?.length ?? 0;
  final name = isUnnamed(r.name) ? context.l10n.pairDefaultLabel(count + 1) : r.name;
  return Navigator.of(context).push<Contact>(
    MaterialPageRoute<Contact>(builder: (_) => ContactEditScreen(name: name, address: r.paymentsAddress, addressOptional: true)),
  );
}

/// Add to a contact: the user picks one of theirs; nothing is matched by name or address.
Future<Contact?> pickContactForPairing(BuildContext context) => Navigator.of(context).push<Contact>(
  MaterialPageRoute<Contact>(builder: (_) => const ContactsScreen(pick: true)),
);

/// Attaches the pairing [r] to [contact], the user's pick. Refused because the contact has an
/// Epicbox address the pairing cannot confirm (it proves another key, or none, as a pairing made
/// before 26.10.25): a dialog says so and offers Save as a new contact; pairing again brings the
/// proof. The contact the pairing went to, or null.
Future<Contact?> attachPairingTo(BuildContext context, WidgetRef ref, PairingRecord r, Contact contact) async {
  try {
    final attached = await pairingCall(ref, (api) => api.attach(r.id, contact.id, contactAddress: contact.epicbox));
    // The proven address fills the contact's empty Epicbox slot once verified.
    await writeProvenAddress(ref, attached);
    return contact;
  } on WalletError catch (error) {
    final failure = pairingFailureOf(error);
    if (failure != PairingFailure.otherAddress && failure != PairingFailure.addressProofMissing) rethrow;
  }
  if (!context.mounted) return null;
  final l = context.l10n;
  final asNew = await confirmAppDialog(
    context,
    title: l.pairOtherAddressTitle(contact.name),
    icon: Icons.person_add_alt_1_outlined,
    tone: DialogTone.warn,
    description: l.pairOtherAddressBody(contact.name),
    cancelLabel: l.commonCancel,
    confirmLabel: l.pairSaveNewContact,
    confirmKey: pairOtherAddressNewKey,
  );
  if (!asNew || !context.mounted) return null;
  final saved = await savePairingAsNewContact(context, r);
  if (saved == null || !context.mounted) return null;
  await pairingCall(ref, (api) => api.attach(r.id, saved.id));
  return saved;
}

/// Save as a new contact in [attachPairingTo]'s refusal, for tests.
const Key pairOtherAddressNewKey = ValueKey('pair-other-address-new');

/// The words check of the pairing [pairingId]. [recheck] is the contact page's "Check the
/// words" on a pairing already paired.
class CheckWordsScreen extends ConsumerStatefulWidget {
  const CheckWordsScreen({super.key, required this.pairingId, this.recheck = false});

  final String pairingId;
  final bool recheck;

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
      if (record != null && check == PairingCheck.match) await writeProvenAddress(ref, record);
      if (!mounted) return;
      if (check == PairingCheck.mismatch || record == null) {
        // Ended on both sides, kept: the contact page lists what was in flight.
        ref.read(noticeProvider.notifier).show(l.pairEndedNotice, level: NoticeLevel.warning);
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
    final stop = await confirmAppDialog(
      context,
      title: l.sasNoMatchTitle,
      icon: Icons.gpp_bad_outlined,
      tone: DialogTone.risk,
      description: l.sasNoMatchBody,
      cancelLabel: l.pairBack,
      confirmLabel: l.sasNoMatch,
      risk: true,
      confirmKey: checkStopKey,
    );
    if (stop) await _answer(PairingCheck.mismatch);
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
    final lead = service ? l.sasLeadExchange(name) : l.sasLead(name);
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
            // Stacked (UP-029). No Skip: Back is later, the row stays Paired.
            OutlinedButton(
              key: checkNoMatchKey,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: _busy ? null : _noMatch,
              child: Text(l.sasNoMatch),
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

  /// The contact the user attached it to: when its key check finds the old keys, LEPIC folds
  /// this pairing into the old one, and the screen goes to that contact (its notice says the
  /// keys are back) instead of staying empty.
  String? _attachedTo;
  bool _left = false;

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
    _attachedTo = contact.id;
    final to = await attachPairingTo(context, ref, r, contact);
    _attachedTo = to?.id;
    if (to != null) ref.read(noticeProvider.notifier).show(l.pairSavedAs(to.name), level: NoticeLevel.success);
  });

  /// The pairing is gone (folded into the old one, or removed): leave once.
  void _leave() {
    if (_left) return;
    _left = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final to = _attachedTo;
      final nav = Navigator.of(context);
      if (to == null) {
        nav.pop();
      } else {
        nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => ContactPage(contactId: to)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final record = ref.watch(pairingByIdProvider(widget.pairingId));
    if (record == null) {
      if (ref.watch(pairingsProvider).hasValue) _leave();
      return SlotScaffold(appBar: AppBar(title: Text(l.pairWaitingTitleShort)), body: const SizedBox.shrink());
    }
    final name = ref.watch(pairingNameProvider(record.id));
    final verified = record.state == PairingState.verified;
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final who = ref.watch(pairingNameProvider(record.id));
    final saved = record.contactId != null && contacts.any((c) => c.id == record.contactId);
    // A contact of the name it chose (a restore or re-pair): one tap attaches it, and the key
    // check finds whether its keys are back.
    final pairings = ref.watch(pairingsProvider).value ?? const <PairingRecord>[];
    final suggested = saved
        ? null
        : sameNamedContact<Contact>(
            record,
            contacts,
            (c) => c.name,
            paired: (c) => pairings.any((p) => p.id != record.id && p.contactId == c.id && p.state.isPaired),
            epicboxOf: (c) => c.epicbox,
          );
    final done = FilledButton(
      key: checkDoneKey,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: () => Navigator.pop(context),
      child: Text(l.commonDone),
    );
    return SlotScaffold(
      appBar: AppBar(title: Text(l.pairWaitingTitleShort)),
      body: ScreenBody(
        // Stacked, the primary first (UP-029).
        bottom: verified
            ? done
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  done,
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: record.id)),
                    ),
                    child: Text(l.sasCheckNow),
                  ),
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
          // The result's badge is the big one: the same badge, scaled up.
          Center(child: SizedBox(height: 30, child: FittedBox(child: TrustBadge(record)))),
          if (verified) ...[
            const SizedBox(height: 8),
            Text(
              record.peerVerifiedAt != null ? l.pairConfirmedToo(who) : l.pairNotChecked(who),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
            ),
          ],
          // Where it goes first: at 360 dp the choices show without scrolling.
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
                      if (suggested != null) ...[
                        FilledButton(
                          key: resultAddToNamedKey,
                          onPressed: _busy ? null : () => _attach(record, suggested),
                          child: Text(l.pairAddToNamed(suggested.name), textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Two halves of the card's width, the same gutter on both sides.
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              key: resultSaveNewKey,
                              onPressed: _busy ? null : () => _saveNew(record),
                              child: Text(l.pairSaveNewContact, textAlign: TextAlign.center),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              key: resultAddToKey,
                              onPressed: _busy ? null : () => _addTo(record),
                              child: Text(l.pairAddToAContact, textAlign: TextAlign.center),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
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
        ],
      ),
    );
  }
}
