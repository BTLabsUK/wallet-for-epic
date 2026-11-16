// SPDX-License-Identifier: Apache-2.0
/// Check the words: the four words both wallets show, then They match (Verified; the other
/// side learns of it) or They do not match (the pairing ends on both sides, kept, its sends
/// held). Back is later: the row stays Paired. The results offer to save the contact; the app
/// never decides on its own which address-book entry a pairing belongs to.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contact_label.dart';
import '../../contacts.dart';
import '../../name_service/name_service.dart';
import '../../name_service/phone_name_service.dart';
import '../../trust/policy.dart' show featureNameService, statedAutomated;
import '../../errors.dart';
import '../../history/domain_check_book.dart' show DomainStatus;
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../providers.dart' show sessionProvider;
import '../../pairing_text.dart' show isUnnamed, pairingPeerAddress, sameNamedContact, unnamedPeerLabel;
import '../../wallet_service.dart';
import '../common.dart';
import '../contact_page.dart' show ContactPage;
import '../contact_label_mark.dart' show ContactLabelGlyph, contactLabelName;
import '../contact_label_picker.dart' show showContactLabelPicker;
import '../contacts_screen.dart';
import '../kit/kit_button.dart';
import '../kit/kit_row.dart';
import '../kit/kit_tokens.dart';
import '../status_icons.dart';
import '../theme/tokens.dart';
import '../../trust_ids.dart';
import 'pair_flow.dart';
import 'name_service_parts.dart';
import 'add_to_contacts_button.dart';
import 'pairing_notices.dart' show pairingWordsOnScreen;
import 'pair_allow_row.dart';
import 'pairing_parts.dart';

/// Keys for tests.
const Key checkMatchKey = ValueKey('check-match');
const Key checkNoMatchKey = ValueKey('check-no-match');
const Key checkStopKey = ValueKey('check-stop');
const Key checkDoneKey = ValueKey('check-done');
const Key resultAllowKey = ValueKey('result-allow');
const Key resultSaveNewKey = ValueKey('result-save-new');
const Key resultLabelRowKey = ValueKey('result-label-row');
const Key resultAddToNamedKey = ValueKey('result-add-to-named');

/// Asks before removing the pairing with [name]: Keep, or Remove in risk. Undoing it
/// means pairing again.
Future<bool> confirmRemovePairing(BuildContext context, String name) {
  final l = context.l10n;
  return confirmPairSheet(
    context,
    title: l.contactRemovePairingTitle(name),
    body: l.contactRemovePairingBody(name),
    action: l.contactRemove,
    cancel: l.contactKeep,
    risky: true,
    actionKey: confirmRemovePairingKey,
    sheetId: TrustIds.pairflowRemoveSheet,
    actionId: TrustIds.pairflowRemoveConfirm,
    cancelId: TrustIds.pairflowRemoveKeep,
  );
}

/// The Remove button of [confirmRemovePairing], for tests.
const Key confirmRemovePairingKey = ValueKey('confirm-remove-pairing');

/// Save as a new contact: the form with the name the pairing claims (or "Contact {n}" when it
/// claims none) and its proven address, when it has one, for the user to check. The pairing pays
/// the contact, so no address is needed. The contact saved, or null.
Future<Contact?> savePairingAsNewContact(BuildContext context, PairingRecord r) {
  final count = ProviderScope.containerOf(context).read(contactsProvider).value?.length ?? 0;
  // No name: the start of its address when the app has it, else "Contact {n}".
  final tag = pairingPeerAddress(r);
  final name = !isUnnamed(r.name) ? r.name : (tag == null ? context.l10n.pairDefaultLabel(count + 1) : unnamedPeerLabel(context.l10n, tag));
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
  final asNew = await confirmPairSheet(
    context,
    title: l.pairOtherAddressTitle(contact.name),
    body: l.pairOtherAddressBody(contact.name),
    action: l.pairSaveNewContact,
    cancel: l.commonCancel,
    actionKey: pairOtherAddressNewKey,
    sheetId: TrustIds.pairflowOtherSheet,
    actionId: TrustIds.pairflowOtherNew,
    cancelId: TrustIds.pairflowOtherCancel,
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
/// words" on a pairing already paired. Inside a [PairFlowStage] (the answered code's one screen)
/// [onMatched] takes the match in place of the push of the result screen, and [onDomainVerified]
/// hears that a proof of the contact's domain arrived while the words were shown.
class CheckWordsScreen extends ConsumerStatefulWidget {
  const CheckWordsScreen({super.key, required this.pairingId, this.recheck = false, this.onMatched, this.onDomainVerified});

  final String pairingId;
  final bool recheck;
  final void Function(PairingRecord record)? onMatched;
  final VoidCallback? onDomainVerified;

  @override
  ConsumerState<CheckWordsScreen> createState() => _CheckWordsScreenState();
}

class _CheckWordsScreenState extends ConsumerState<CheckWordsScreen> {
  bool _busy = false;
  bool _left = false;

  /// An answer of this screen went out: a verification that follows is the words' own.
  bool _answered = false;
  void Function()? _unboost;
  StreamSubscription<PairingEvent>? _events;

  /// Where the name service's wait stands when the service has not said yet (its answer to
  /// [NameService.beginHello]); null while asking.
  HelloStep? _began;
  NameService? _nameService;
  bool _onScreen(PairingEvent e) => e.pairingId == widget.pairingId;

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
    final api = ref.read(pairingApiProvider);
    // The other wallet's verdict is heard within seconds, as on the desktop, not at the next
    // foreground tick.
    if (ref.read(pairNetProvider) == PairNet.online) _unboost = boostRelays(ref.read(sessionProvider)?.boosts, boostMinInterval);
    _events = api.events().listen((e) {
      // Ended while the words are open (the other wallet said they do not match): nothing is
      // left to check; the ended notice says why.
      if (e.kind != PairingEventKind.ended || e.pairingId != widget.pairingId || _busy || _left || !mounted) return;
      _left = true;
      final route = ModalRoute.of(context);
      if (route == null) return;
      if (route.isCurrent) {
        Navigator.pop(context);
      } else {
        Navigator.of(context).removeRoute(route);
      }
    });
    // A pairing whose peer claims the name service feature waits for its hello before the words.
    WidgetsBinding.instance.addPostFrameCallback((_) => _beginNameService());
  }

  Future<void> _beginNameService() async {
    final service = ref.read(nameServiceProvider);
    if (service == null) return;
    // Read afresh: the one who answered an invite learns the inviter's features from the confirm
    // that opened this screen, and the listed records may still be from before it.
    final PairingRecord? record;
    try {
      record = await ref.read(pairingApiProvider).pairing(widget.pairingId);
    } on Object {
      return;
    }
    if (!mounted || record == null || record.peerFeatures & featureNameService == 0) return;
    _nameService = service;
    final step = await service.beginHello(widget.pairingId);
    if (mounted) setState(() => _began = step);
  }

  @override
  void dispose() {
    _unboost?.call();
    _events?.cancel();
    pairingWordsOnScreen.remove(_onScreen);
    // Leaving the screen stops the wait; the words step is what Back leaves the pairing at.
    _nameService?.cancelHello(widget.pairingId);
    super.dispose();
  }

  /// [viaCode]: the answer was given on the name service's code check (the words view answers
  /// plainly, as when no hello comes): only that one pins or dismisses the service.
  Future<void> _answer(PairingCheck check, {bool viaCode = false}) async {
    if (_busy) return;
    final l = context.l10n;
    setState(() => _busy = true);
    _answered = true;
    try {
      final record = await pairingCall(ref, (api) => api.checkWords(widget.pairingId, check));
      // A plain answer ends the wait for a hello that has not come.
      if (!viaCode) _nameService?.cancelHello(widget.pairingId);
      final nameService = viaCode ? _nameService : null;
      if (nameService != null) {
        // The code was compared: the serviceKey is this contact's, or the name service is forgotten.
        if (check == PairingCheck.match && record != null) {
          await nameService.pin(widget.pairingId);
        } else {
          await nameService.dismiss(widget.pairingId);
        }
      }
      if (record != null && check == PairingCheck.match) await writeProvenAddress(ref, record);
      if (!mounted) return;
      if (check == PairingCheck.mismatch || record == null) {
        // Ended on both sides, kept: the contact page lists what was in flight.
        ref.read(noticeProvider.notifier).show(l.pairEndedNotice, level: NoticeLevel.warning);
        Navigator.pop(context);
        return;
      }
      final entry = nameService?.book.byPairing(widget.pairingId);
      if (entry != null && entry.pinned) {
        // The Join sheet; Not now leaves a verified name service with Join on its page.
        await showNameServiceJoinSheet(context, ref, serviceKey: entry.serviceKey, label: ref.read(pairingNameProvider(record.id)));
        if (!mounted) return;
      }
      final onMatched = widget.onMatched;
      if (onMatched != null) {
        onMatched(record);
      } else {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => PairingResultScreen(pairingId: record.id)),
        );
      }
    } catch (error) {
      _answered = false;
      if (mounted) ref.read(noticeProvider.notifier).show(describeError(l, error), level: NoticeLevel.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _noMatch({bool viaCode = false}) async {
    final l = context.l10n;
    final stop = await confirmPairSheet(
      context,
      title: l.sasNoMatchTitle,
      body: l.sasNoMatchBody,
      action: l.sasNoMatch,
      cancel: l.pairBack,
      risky: true,
      actionKey: checkStopKey,
      sheetId: TrustIds.pairflowCheckStopSheet,
      actionId: TrustIds.pairflowCheckStop,
      cancelId: TrustIds.pairflowCheckStopBack,
    );
    if (stop && mounted && !_left) await _answer(PairingCheck.mismatch, viaCode: viaCode);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final record = ref.watch(pairingByIdProvider(widget.pairingId));
    if (widget.onDomainVerified != null) {
      // The proof of the domain came after the wait: this pairing is Verified without the words.
      ref.listen(pairingByIdProvider(widget.pairingId), (_, now) {
        if (_answered || _left || now == null) return;
        if (now.state == PairingState.verified && now.domainStatus == DomainStatus.proven) widget.onDomainVerified!();
      });
    }
    if (record == null) {
      return PairFlowPage(title: l.sasTitle, leadingId: TrustIds.pairflowCheckClose, children: const []);
    }
    final name = ref.watch(pairingNameProvider(record.id));
    // The words come at once; a name service's hello, when it comes, upgrades the same screen to
    // its code check.
    final hello = _nameService == null ? null : ref.watch(phoneNameServices.view);
    final onCode = _nameService != null && (hello?.steps[widget.pairingId] ?? _began) == HelloStep.check;
    final serviceKey = onCode ? hello?.book.byPairing(record.id)?.serviceKey : null;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduced ? Duration.zero : PairFlowStage.fade,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
      child: serviceKey != null
          ? NameServiceCodeCheck(
              key: const ValueKey('check-view-service'),
              label: name,
              serviceKey: serviceKey,
              noPayments: ref.watch(paymentRefusalsProvider).refusesPayments(pairingId: record.id),
              busy: _busy,
              onMatch: () => _answer(PairingCheck.match, viaCode: true),
              onNoMatch: () => _noMatch(viaCode: true),
              matchKey: checkMatchKey,
              noMatchKey: checkNoMatchKey,
            )
          : _wordsView(l, t, record, name),
    );
  }

  Widget _wordsView(AppLocalizations l, WalletTokens t, PairingRecord record, String name) {
    // A name service confirms by itself once this side matched: nothing to confirm on its page.
    final service = statedAutomated(record.peerProfile) && record.peerFeatures & featureNameService == 0;
    final lead = service ? l.sasLeadExchange(name) : l.sasLead(name);
    // The contact's domain is being asked to prove its wallet: a calm line, nothing waits on it.
    final domain = record.domainChecking ? record.peerDomain : null;
    return PairFlowPage(
      key: const ValueKey('check-view-words'),
      title: l.sasTitle,
      leadingId: TrustIds.pairflowCheckClose,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KitButton(
            key: checkMatchKey,
            label: l.sasMatch,
            semanticsId: TrustIds.pairflowCheckMatch,
            onPressed: _busy ? null : () => _answer(PairingCheck.match),
          ),
          const PairGap(10),
          // Stacked (UP-029). No Skip: Back is later, the row stays Paired.
          KitButton(
            key: checkNoMatchKey,
            label: l.sasNoMatch,
            kind: KitButtonKind.quiet,
            semanticsId: TrustIds.pairflowCheckNoMatch,
            onPressed: _busy ? null : _noMatch,
          ),
        ],
      ),
      children: [
        const PairGap(6),
        Row(
          children: [
            PairAvatar(name: name),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: KitType.sheetTitle.copyWith(color: t.text), maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ),
        const PairGap(14),
        PairLead(lead),
        const PairGap(16),
        PairCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
              child: WordTiles(words: record.sas, label: l.sasWordsLabel, size: WordTileSize.check),
            ),
          ],
        ),
        if (domain != null) ...[const PairGap(14), _DomainCheckingLine(domain: domain)],
      ],
    );
  }
}

/// "Checking {domain}…" under the words: a small spinner and a muted line that goes when the
/// proof ends. It announces itself politely once and never takes focus.
class _DomainCheckingLine extends StatelessWidget {
  const _DomainCheckingLine({required this.domain});

  final String domain;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: t.faint)),
          const SizedBox(width: 8),
          Flexible(child: Text(context.l10n.deskPairDomainChecking(domain), style: KitType.rowSub.copyWith(color: t.dim), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// After the check: Verified with the two switches, or Paired, not verified with Check now.
/// A pairing not yet in the address book offers Save as a new contact or Add to a contact.
///
/// [domain] is the domain whose proof ended this pairing Verified without the words: the line
/// says so. Inside a [PairFlowStage] [onCheckNow] takes Check now in place of the push of the
/// words.
class PairingResultScreen extends ConsumerStatefulWidget {
  const PairingResultScreen({super.key, required this.pairingId, this.domain, this.onCheckNow});

  final String pairingId;
  final String? domain;
  final VoidCallback? onCheckNow;

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

  /// The label for the contact this saves; the default writes nothing.
  ContactLabel _label = ContactLabel.wallet;

  Future<void> _pickLabel() async {
    final picked = await showContactLabelPicker(context, _label);
    if (picked != null && mounted) setState(() => _label = picked);
  }

  BusyRow? _busyRow;

  Future<void> _run(Future<void> Function() call, {BusyRow? row}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _busyRow = row;
    });
    try {
      await call();
    } catch (error) {
      if (mounted) ref.read(noticeProvider.notifier).show(describeError(context.l10n, error), level: NoticeLevel.error);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyRow = null;
        });
      }
    }
  }

  Future<void> _saveNew(PairingRecord r) async {
    final saved = await savePairingAsNewContact(context, r);
    if (saved == null || !mounted) return;
    final stored = _label == ContactLabel.wallet ? saved : await ref.read(contactsProvider.notifier).save(saved.copyWith(label: _label));
    if (!mounted) return;
    await _attach(r, stored);
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
    final record = ref.watch(pairingByIdProvider(widget.pairingId));
    if (record == null) {
      if (ref.watch(pairingsProvider).hasValue) _leave();
      return PairFlowPage(title: l.pairWaitingTitleShort, leadingId: TrustIds.pairflowResultClose, children: const []);
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
    final noPayments = ref.watch(paymentRefusalsProvider).refusesPayments(pairingId: record.id);
    final done = KitButton(key: checkDoneKey, label: l.commonDone, semanticsId: TrustIds.pairflowResultDone, onPressed: () => Navigator.pop(context));
    return PairFlowPage(
      title: l.pairWaitingTitleShort,
      leadingId: TrustIds.pairflowResultClose,
      // Stacked, the primary first (UP-029).
      bottom: verified
          ? done
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                done,
                const PairGap(10),
                KitButton(
                  label: l.sasCheckNow,
                  kind: KitButtonKind.quiet,
                  semanticsId: TrustIds.pairflowResultCheckNow,
                  onPressed: widget.onCheckNow ?? () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: record.id))),
                ),
              ],
            ),
      children: [
        // Verified needs no line when no payments go through it: the badges below say it.
        PairOutcome(
          icon: verified ? EpicGlyphs.verified : EpicGlyphs.paired,
          title: verified ? l.sasMatchedTitle(name) : l.sasSkippedTitle(name),
          body: verified
              ? (widget.domain != null ? l.deskPairDomainVerifiedBody(name, widget.domain!) : (noPayments ? null : l.sasMatchedBody(name)))
              : l.sasSkippedBody(name),
          good: verified,
        ),
        const PairGap(12),
        // The result's badge is the big one: the same badge, scaled up.
        Center(
          child: SizedBox(
            height: 30,
            child: FittedBox(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [TrustBadge(record), if (noPayments) ...[const SizedBox(width: 6), const NoPaymentsBadge()]],
              ),
            ),
          ),
        ),
        // On the domain path no words were compared, so the peer's side of the check is not a question.
        if (verified && widget.domain == null) ...[
          const PairGap(8),
          PairNote(
            statedAutomated(record.peerProfile)
                ? l.pairIsService
                : record.peerVerifiedAt != null
                    ? l.pairConfirmedToo(who)
                    : l.pairNotChecked(who),
            center: true,
          ),
        ],
        // Where it goes first: at 360 dp the choices show without scrolling.
        if (!saved) ...[
          const PairGap(20),
          PairCard(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                child: Text(l.pairSaveContactTitle(name), style: KitType.rowTitle.copyWith(color: t.text)),
              ),
              KitRow(
                key: resultLabelRowKey,
                title: l.deskConLabelTitle,
                value: contactLabelName(l, _label),
                leading: KitIconWell.child(ContactLabelGlyph(_label, size: 22, color: _label == ContactLabel.wallet ? t.faint : t.dim)),
                chevron: true,
                semanticsId: TrustIds.pairflowResultLabel,
                onTap: _busy ? null : _pickLabel,
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (suggested != null) ...[
                      KitButton(
                        key: resultAddToNamedKey,
                        label: l.pairAddToNamed(suggested.name),
                        semanticsId: TrustIds.pairflowResultAddNamed,
                        onPressed: _busy ? null : () => _attach(record, suggested),
                      ),
                      const PairGap(8),
                    ],
                    AddToContactsButton(
                      key: resultSaveNewKey,
                      onNew: _busy ? null : () => _saveNew(record),
                      onExisting: _busy ? null : () => _addTo(record),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        if (verified && !noPayments) ...[
          const PairGap(20),
          PairMatchedCard(
            name: name,
            seal: record.seal != SealMode.off,
            onSeal: _busy ? null : (v) => _run(() => pairingCall(ref, (api) => api.setSeal(record.id, v)), row: BusyRow.seal),
            allow: record.allowInvoices,
            offLine: l.sasAllowOffLine(name),
            onAllow: _busy ? null : (v) => _run(() => pairingCall(ref, (api) => api.setAllowInvoices(record.id, v)), row: BusyRow.allow),
            busy: _busyRow,
            allowKey: resultAllowKey,
          ),
        ],
      ],
    );
  }
}
