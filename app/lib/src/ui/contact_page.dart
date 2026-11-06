// SPDX-License-Identifier: Apache-2.0
/// A contact as a page: the header with the trust badge, Send and Show code, then
/// the contact's addresses (one per kind) and, where the wallet pairs, its Pairing
/// block: the trust state, Seal payments, Allow invoices, the relay it delivers through, the
/// keys-changed and relay notices, and Remove pairing. Replaces the contact sheet.
library;

import 'dart:async';

import '../name_service/payment_refusals.dart' show paymentRefusalsProvider;
import 'phone_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart';
import '../history/domain_check_book.dart' show DomainStatus;
import '../errors.dart';
import '../initials.dart';
import '../l10n.dart';
import '../pairing_providers.dart';
import '../providers.dart';
import '../recent_activity.dart';
import '../wallet_service.dart';
import 'address_view.dart' show MarkedAddress;
import 'app_dialog.dart';
import 'common.dart';
import 'inline_button.dart';
import 'contact_label_picker.dart';
import 'contact_trust_line.dart';
import 'contacts_screen.dart';
import 'history_screen.dart' show HistoryScreen;
import 'method_names.dart';
import 'pairing/contact_pairing_block.dart';
import 'pairing/name_service_parts.dart' show NameServiceBlock;
import 'pairing/pair_check.dart';
import 'pairing/pair_screen.dart';
import 'pairing/pair_way1.dart' show pairWithContact;
import 'pairing/pairing_parts.dart';
import 'pairing/pairing_notices.dart' show pairingContactNoticeTag, pairingNewsOnScreen;
import 'scan_route.dart' show sendPayments;
import 'status_icons.dart' show EpicGlyphs;
import 'theme/brand.dart';
import 'theme/tokens.dart';
import 'tip.dart';

/// Keys of the contact page, for tests.
const Key contactPageSendKey = ValueKey('contact-page-send');
const Key contactPageEditKey = ValueKey('contact-page-edit');
const Key contactPageMoreKey = ValueKey('contact-page-more');
const Key contactPageDeleteKey = ValueKey('contact-page-delete');
const Key contactPageHeaderPairKey = ValueKey('contact-page-header-pair');
const Key contactPageStarKey = ValueKey('contact-page-star');
const Key contactPageNoPaymentsKey = ValueKey('contact-page-no-payments');
const Key contactPageSendReasonKey = ValueKey('contact-page-send-reason');
const Key contactPageViaPairingKey = ValueKey('contact-page-via-pairing');

/// Two letters for [name] ([nameInitials]: letters and digits only), `?` for a name with
/// none.
String contactInitials(String name) {
  final letters = nameInitials(name);
  return letters.isEmpty ? '?' : letters;
}

/// How the app reaches [address]: `Epicbox`, `Link Payment · HTTP` for an http(s) address, `Link ·
/// Tor` for an onion address.
String contactTag(AppLocalizations l, String address) => recipientMethodWord(l, parseRecipient(address).kind);

/// The payments with [contact] (GP-043): the newest five rows whose other side is one of
/// its addresses, then the way to all of them in Activity, searched by its name. Says so
/// when there are none yet.
class _Payments extends ConsumerWidget {
  const _Payments({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final all = ref.watch(homeProvider).value?.transactions ?? const <TxEntry>[];
    final mine = [for (final tx in all) if (contactFor([contact], tx.counterparty) != null) tx];
    if (mine.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(l.contactPaymentsNone, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final tx in mine.take(recentActivityCount)) TxTile(tx: tx),
        if (showViewAll(mine.length))
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InlineTextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => HistoryScreen(query: contact.name)),
              ),
              child: Text(l.contactPaymentsAll),
            ),
          ),
      ],
    );
  }
}

/// Opens the page of [contact].
Future<void> openContactPage(BuildContext context, Contact contact) => Navigator.of(context).push<void>(
  MaterialPageRoute<void>(builder: (_) => ContactPage(contactId: contact.id, initial: contact)),
);

/// The contact page. It follows the contact by id, so an edit shows at once; [initial] stands
/// in until the list has loaded.
class ContactPage extends ConsumerStatefulWidget {
  const ContactPage({super.key, required this.contactId, this.initial});

  final String contactId;
  final Contact? initial;

  @override
  ConsumerState<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends ConsumerState<ContactPage> {
  bool _busy = false;

  /// The page shows this contact's relay and keys itself.
  bool _shows(PairingEvent e) =>
      const {PairingEventKind.homeRelayUnreachable, PairingEventKind.keysChanged, PairingEventKind.keysRestored}.contains(e.kind) &&
      e.pairingId != null &&
      e.pairingId == ref.read(contactPairingProvider(widget.contactId))?.id;

  @override
  void dispose() {
    pairingNewsOnScreen.remove(_shows);
    _notices.dismissTag(_pausedTag);
    super.dispose();
  }

  /// The Epicbox-off notice of this page.
  static const _pausedTag = 'contact-paused-epicbox-off';

  /// Read in [initState]: [dispose] closes the page's notice and may not read providers.
  late final NoticeNotifier _notices;

  @override
  void initState() {
    super.initState();
    _notices = ref.read(noticeProvider.notifier);
    pairingNewsOnScreen.add(_shows);
    // The contact's claimed domain is checked when it is due; the lists read again if it moved.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pairing = ref.read(contactPairingProvider(widget.contactId));
      if (pairing?.peerDomain != null) unawaited(ref.read(pairingApiProvider).checkDomain(pairing!.id));
    });
    // Epicbox off pauses the contact's pairing; say so once on the way in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The page shows the contact's relay and keys: their notices have done their job.
      final pairing = ref.read(contactPairingProvider(widget.contactId));
      if (pairing != null) ref.read(noticeProvider.notifier).dismissTag(pairingContactNoticeTag(pairing.id));
      final paired = pairing != null;
      if (paired && ref.read(pairNetProvider) == PairNet.epicboxOff) {
        final l = context.l10n;
        // Persistent, so it pushes the page down instead of covering its header; it goes with
        // the page.
        _notices.show('${l.contactPausedEpicboxOff}. ${l.contactPausedEpicboxOffBody}', level: NoticeLevel.info, persistent: true, tag: _pausedTag);
      }
    });
  }

  Contact? _contact() {
    final all = ref.watch(contactsProvider).value;
    return all?.where((c) => c.id == widget.contactId).firstOrNull ?? (all == null ? widget.initial : null);
  }

  /// Send with the contact's address whose method is on (Epicbox, Tor, HTTP), as Send picks it;
  /// a contact with no address, through its pairing's mailbox.
  void _send(Contact contact, PairingRecord? pairing) => contact.addresses.isEmpty && pairing != null
      ? showShellTab(context, ShellTab.send, pairingTo: pairing.id)
      : showShellTab(context, ShellTab.send, recipient: contactSendAddress(contact, sendPayments(ref).offers));

  void _edit(Contact contact) => Navigator.of(
    context,
  ).push<Contact>(MaterialPageRoute<Contact>(builder: (_) => ContactEditScreen(contact: contact)));

  Future<void> _delete(Contact contact, PairingRecord? pairing) async {
    final l = context.l10n;
    final sure = await confirmAppDialog(
      context,
      title: l.contactsDeleteTitle(contact.name),
      icon: Icons.person_remove_outlined,
      tone: DialogTone.risk,
      description: pairing == null ? l.contactsDeleteConfirmBody : '${l.contactsDeleteConfirmBody}\n\n${l.contactDeletePaired(contact.name)}',
      cancelLabel: l.commonCancel,
      confirmLabel: l.commonDelete,
      risk: true,
    );
    if (!sure || !mounted) return;
    final notices = ref.read(noticeProvider.notifier);
    try {
      // Deleting a paired contact removes its pairing (C-19).
      if (pairing != null) await pairingCall(ref, (api) => api.removePairing(pairing.id));
      await ref.read(contactsProvider.notifier).delete(contact.id);
      notices.show(l.contactsDeleted(contact.name), level: NoticeLevel.success);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      notices.show(describeError(l, error), level: NoticeLevel.error);
    }
  }

  void _showCode(Contact contact) => showPhoneSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _CodeSheet(contact: contact),
  );

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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final contact = _contact();
    if (contact == null) {
      // Deleted (from its form, or elsewhere): the page has nothing left to show.
      if (ref.watch(contactsProvider).hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ModalRoute.of(context)?.isCurrent == true) Navigator.pop(context);
        });
      }
      return SlotScaffold(appBar: AppBar(title: Text(l.contactTitle)), body: const SizedBox.shrink());
    }
    final pairs = ref.watch(pairingSupportedProvider);
    final pairing = pairs ? ref.watch(contactPairingProvider(contact.id)) : null;
    // A request sent to this contact, or its code answered, waiting for the confirm.
    final pending = pairs && (pairing == null || pairing.ended) ? ref.watch(contactPendingPairingProvider(contact.id)) : null;
    final starred = ref.watch(favouriteContactsProvider).value?.contains(contact.id) ?? false;
    final noPayments = ref.watch(paymentRefusalsProvider).refusesPayments(pairingId: pairing?.id, address: contact.epicbox);
    return SlotScaffold(
      appBar: AppBar(
        title: Text(l.contactTitle),
        actions: [
          IconButton(key: contactPageEditKey, tooltip: l.contactEdit, icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(contact)),
          PopupMenuButton<String>(
            key: contactPageMoreKey,
            tooltip: l.contactMore,
            onSelected: (v) => switch (v) {
              'star' => _run(() => ref.read(favouriteContactsProvider.notifier).set(contact.id, !starred)),
              'check' when pairing != null && !pairing.ended && pairing.sas.isNotEmpty => _openCheck(pairing),
              'delete' => _delete(contact, pairing),
              _ => null,
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                key: contactPageStarKey,
                value: 'star',
                child: ListTile(
                  leading: Icon(starred ? Icons.star_rounded : Icons.star_outline_rounded),
                  title: Text(starred ? l.contactUnstar : l.contactStar),
                ),
              ),
              if (pairing != null && !pairing.ended && pairing.sas.isNotEmpty)
                PopupMenuItem(value: 'check', child: ListTile(leading: const Icon(EpicGlyphs.verified), title: Text(l.pairCheckWords))),
              PopupMenuItem(
                key: contactPageDeleteKey,
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: context.tokens.risk),
                  title: Text(l.contactDelete, style: TextStyle(color: context.tokens.risk)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ScreenBody(
        children: [
          _Header(
            contact: contact,
            pairing: pairing,
            starred: starred,
            onSend: () => _send(contact, pairing),
            onCode: () => _showCode(contact),
            onPair: pairs && (pairing == null || pairing.ended) && pending == null ? () => _pair(contact) : null,
            onPending: pairs && (pairing == null || pairing.ended) && pending != null ? () => _showMyCode(contact) : null,
          ),
          // A contact that takes no payments: its own card first, then Pairing, Addresses last.
          if (noPayments && pairs && pairing != null && !pairing.ended) NameServiceBlock(pairingId: pairing.id, label: contact.name),
          if (!noPayments) ...[PairSection(l.contactAddresses), _Addresses(contact: contact, pairing: pairing)],
          if (pairs) ...[
            PairSection(l.contactPairing),
            ContactPairingBlock(contact: contact, pairing: pairing, pending: pending, busy: _busy, run: _run, onPair: () => _pair(contact)),
            // A service the user paired with and took a name from: Pay me as @name · since, the
            // picture code and Leave, or the button that turns it on.
            if (!noPayments && pairing != null && !pairing.ended) NameServiceBlock(pairingId: pairing.id, label: contact.name),
          ],
          if (noPayments) ...[PairSection(l.contactAddresses), _Addresses(contact: contact, pairing: pairing)],
          // The compatibility line (trust policy): one sentence, never a badge; a plain
          // contact's key can answer as another wallet app with pairing off too.
          ContactTrustLine(contactId: contact.id, name: contact.name),
          if (contact.note?.trim() case final note? when note.isNotEmpty) ...[
            PairSection(l.contactsNoteHeading),
            Text(note, style: Theme.of(context).textTheme.bodyMedium),
          ],
          PairSection(l.contactPaymentsWith(contact.name)),
          _Payments(contact: contact),
        ],
      ),
    );
  }

  /// Pair: the request sheet when a request can go, else the Pair screen for the contact.
  void _pair(Contact contact) => pairWithContact(context, ref, contact);

  void _showMyCode(Contact contact) => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => PairScreen(contact: contact)));

  void _openCheck(PairingRecord p) =>
      Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: p.id, recheck: p.state.isPaired)));
}

/// Asks for the contact's label and saves it on the contact as it stands (every other field
/// is kept). Dismissing the sheet changes nothing.
Future<void> _pickLabel(BuildContext context, WidgetRef ref, Contact contact) async {
  final picked = await showContactLabelPicker(context, contact.label);
  if (picked == null || picked == contact.label) return;
  try {
    await ref.read(contactsProvider.notifier).save(contact.copyWith(label: picked));
  } catch (error) {
    if (context.mounted) ref.read(noticeProvider.notifier).show(describeError(context.l10n, error), level: NoticeLevel.error);
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.contact,
    required this.pairing,
    required this.starred,
    required this.onSend,
    required this.onCode,
    this.onPair,
    this.onPending,
  });

  final Contact contact;
  final PairingRecord? pairing;
  final bool starred;
  final VoidCallback onSend;
  final VoidCallback onCode;

  /// Not paired: Pair opens the Pair screen for this contact.
  final VoidCallback? onPair;

  /// A request sent or its code answered: Waiting opens the Pair screen for the contact.
  final VoidCallback? onPending;

  /// A header button: 36 dp, hugging its content; [soft] the primary's soft gold (accentSoft
  /// fill, accentText ink, a gold hairline), the rest outlined.
  static ButtonStyle _headerStyle(BuildContext context, {bool soft = false}) {
    final t = context.tokens;
    final base = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
      fixedSize: const WidgetStatePropertyAll(Size.fromHeight(36)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    if (!soft) return base.copyWith(side: WidgetStatePropertyAll(BorderSide(color: t.lineStrong)), foregroundColor: WidgetStatePropertyAll(t.text));
    return base.copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? t.surfaceHi : t.accentSoft),
      foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? t.faint : t.accentText),
      iconColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? t.faint : t.accentText),
      side: WidgetStateProperty.resolveWith(
        (s) => BorderSide(color: s.contains(WidgetState.disabled) ? t.line : t.accent.withValues(alpha: 0.35)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final p = pairing;
    final noPayments = ref.watch(paymentRefusalsProvider).refusesPayments(pairingId: p?.id, address: contact.epicbox);
    final claimed = p?.name?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PairAvatar(
              name: contact.name,
              size: 72,
              label: contact.label,
              onLabelTap: () => _pickLabel(context, ref, contact),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text.rich(
                      TextSpan(
                        text: contact.name,
                        children: [
                          if (starred)
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(padding: EdgeInsetsDirectional.only(start: 6), child: ContactStar(size: 18)),
                            ),
                        ],
                      ),
                      style: theme.textTheme.headlineSmall?.copyWith(fontFamily: t.headFamily, fontSize: 22),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Verified is about the Epicbox address: none beside one the pairing did not bring.
                  if ((p != null && pairingVouchesFor(p, contact.epicbox)) || noPayments) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (p != null && pairingVouchesFor(p, contact.epicbox)) TrustBadge(p),
                        if (noPayments) NoPaymentsBadge(key: contactPageNoPaymentsKey),
                        if (!noPayments && p != null && p.allowInvoices && ref.watch(invoicesOnProvider))
                          EBadge(l.trustAllowsInvoices, icon: Icons.receipt_long_outlined),
                      ],
                    ),
                  ],
                  if (claimed != null && claimed.isNotEmpty && claimed != contact.name) ...[
                    const SizedBox(height: 4),
                    Text(l.pairCallsThemselves(claimed), style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                  ],
                  // Only a proven domain is shown here; claimed or refused is in the details.
                  if (p != null && p.peerDomain != null && p.domainStatus == DomainStatus.proven) ...[
                    const SizedBox(height: 4),
                    Semantics(
                      label: '${p.peerDomain}, ${l.contactDomainVerified}',
                      excludeSemantics: true,
                      child: Row(
                        key: contactPageDomainKey,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.language, size: 14, color: t.dim),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              p.peerDomain!,
                              style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // One row of compact buttons, each hugging its icon and one word (Pairing UX plan
        // 4.2): Send in soft gold, not a filled block; Pair while not paired, outlined as in
        // Contacts' app bar ("Pair with Anna" only as its tooltip); Show code a glyph beside
        // Pair, so the row fits Russian at 360 dp.
        // Labelled buttons only (UP-028): the row wraps to a second line where the words
        // need it (Russian at 360 dp).
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (!noPayments)
            FilledButton.tonalIcon(
              key: contactPageSendKey,
              style: _headerStyle(context, soft: true),
              icon: const Icon(Icons.north_east, size: 18),
              label: Text(l.contactsSendAction),
              onPressed: contact.addresses.isEmpty && !(p?.paysByMailbox ?? false) ? null : onSend,
            ),
            if (onPair != null) ...[
              Tip(
                l.pairWithName(contact.name),
                excludeFromSemantics: true,
                child: Semantics(
                  label: l.pairWithName(contact.name),
                  button: true,
                  excludeSemantics: true,
                  child: OutlinedButton.icon(
                    key: contactPageHeaderPairKey,
                    style: _headerStyle(context),
                    icon: const Icon(EpicGlyphs.verified, size: 18),
                    label: Text(l.pairTitle),
                    onPressed: onPair,
                  ),
                ),
              ),
            ] else if (onPending != null) ...[
              OutlinedButton.icon(
                key: contactPageHeaderPairKey,
                style: _headerStyle(context),
                icon: const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                label: Text(l.trustWaiting),
                onPressed: onPending,
              ),
            ],
            OutlinedButton.icon(
              style: _headerStyle(context),
              icon: const Icon(Icons.qr_code_2, size: 18),
              label: Text(l.contactsShowCode),
              onPressed: contact.addresses.isEmpty ? null : onCode,
            ),
          ],
        ),
        // A contact with only a pairing that cannot take a payment now: why Send is off.
        if (!noPayments && contact.addresses.isEmpty && p != null && !p.paysByMailbox) ...[
          const SizedBox(height: 4),
          Text(
            p.state == PairingState.keysChanged ? l.contactSendKeysChanged : l.contactSendNoSealed(contact.name),
            key: contactPageSendReasonKey,
            style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
          ),
        ],
      ],
    );
  }
}

/// One row per address: the kind badge, the short address in mono, Copy. A contact with only
/// a pairing gets one row saying payments go through it (dim while it cannot take one).
class _Addresses extends StatelessWidget {
  const _Addresses({required this.contact, this.pairing});

  final Contact contact;
  final PairingRecord? pairing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final p = pairing;
    if (contact.addresses.isEmpty && p != null) {
      final color = p.caps.opensSealed ? t.text : t.dim;
      return PairCard(
        children: [
          ConstrainedBox(
            key: contactPageViaPairingKey,
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                children: [
                  Icon(EpicGlyphs.sealed, size: 20, color: t.dim),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.contactNoAddressPaired, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color))),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (contact.addresses.isEmpty) return Text(l.contactNoAddresses, style: TextStyle(color: t.dim));
    return PairCard(
      children: [
        // Each address in full, its method chip and Copy on the label row above it.
        for (final kind in contact.kinds)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 4, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EBadge.kind(kind, l: l),
                    const Spacer(),
                    IconButton(
                      tooltip: l.contactCopyAddress(recipientMethodWord(l, kind)),
                      icon: Icon(Icons.copy, size: 20, color: t.accentText),
                      onPressed: () => copyText(context, contact.addressOf(kind)!, l.contactsCopied),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: MarkedAddress(contact.addressOf(kind)!, selectable: true),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// An address in mono: the key part in the text colour (its start in the accent's), the relay
/// after `@` dim; short, as in rows, with [short].
class AddressText extends StatelessWidget {
  const AddressText(this.address, {super.key, this.short = false, this.selectable = false});

  final String address;
  final bool short;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final shown = short ? shortAddress(address) : address;
    final at = shown.indexOf('@');
    final span = TextSpan(
      style: TextStyle(fontFamily: t.monoFamily, fontSize: 13, color: t.text),
      children: [
        TextSpan(text: at < 0 ? shown : shown.substring(0, at)),
        if (at >= 0) TextSpan(text: shown.substring(at), style: TextStyle(color: t.dim)),
      ],
    );
    return selectable ? SelectableText.rich(span) : Text.rich(span, maxLines: short ? 1 : null, overflow: short ? TextOverflow.ellipsis : null);
  }
}

/// The contact's addresses as codes: one at a time, the kind chosen with segments when there
/// are several, with the full address under the code.
class _CodeSheet extends StatefulWidget {
  const _CodeSheet({required this.contact});

  final Contact contact;

  @override
  State<_CodeSheet> createState() => _CodeSheetState();
}

class _CodeSheetState extends State<_CodeSheet> {
  late RecipientKind _kind = widget.contact.kinds.first;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final kinds = widget.contact.kinds;
    final address = widget.contact.addressOf(_kind) ?? widget.contact.address;
    final foot = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + foot),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (kinds.length > 1) ...[
            SegmentedButton<RecipientKind>(
              segments: [for (final k in kinds) ButtonSegment(value: k, label: Text(recipientMethodWord(l, k)))],
              selected: {_kind},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 16),
          ],
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // Dark modules on white scan reliably in either theme.
                color: protocolLight.surface,
                borderRadius: BorderRadius.circular(t.radiusSmall),
              ),
              child: Semantics(
                label: l.contactsQrLabel(widget.contact.name),
                image: true,
                child: MarkedQr(data: address, size: 220),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: t.well,
            padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 0, 4),
            child: Row(
              children: [
                Expanded(child: MarkedAddress(address, selectable: true)),
                IconButton(
                  tooltip: l.commonCopy,
                  color: t.accentText,
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => copyText(context, address, l.contactsCopied),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
