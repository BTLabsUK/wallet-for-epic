/// A contact as a page: the header with the trust badge, Send and Show code, then
/// the contact's addresses (one per kind) and, where the wallet pairs, its Pairing
/// block: the trust state, Seal payments, Allow invoices, the relay it delivers through, the
/// keys-changed and relay notices, and Remove pairing. Replaces the contact sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart';
import '../errors.dart';
import '../initials.dart';
import '../l10n.dart';
import '../pairing_providers.dart';
import '../providers.dart';
import '../wallet_service.dart';
import 'common.dart';
import 'contacts_screen.dart';
import 'history_screen.dart' show HistoryScreen;
import 'method_names.dart';
import 'pairing/pair_check.dart';
import 'pairing/pair_screen.dart';
import 'pairing/pairing_parts.dart';
import 'pairing/pending_invites.dart' show PendingInvitesScreen;
import 'pairing/pairing_notices.dart' show pairingContactNoticeTag, pairingNewsOnScreen;
import 'scan_route.dart' show sendPayments;
import 'status_icons.dart' show EpicGlyphs;
import 'theme/brand.dart';
import 'theme/tokens.dart';

/// Keys of the contact page, for tests.
const Key contactPageSendKey = ValueKey('contact-page-send');
const Key contactPageEditKey = ValueKey('contact-page-edit');
const Key contactPageMoreKey = ValueKey('contact-page-more');
const Key contactPageDeleteKey = ValueKey('contact-page-delete');
const Key contactPagePairKey = ValueKey('contact-page-pair');
const Key contactPageHeaderPairKey = ValueKey('contact-page-header-pair');
const Key contactPageSealKey = ValueKey('contact-page-seal');
const Key contactPageInvoicesKey = ValueKey('contact-page-invoices');
const Key contactPageRemovePairingKey = ValueKey('contact-page-remove-pairing');
const Key contactPageCheckKey = ValueKey('contact-page-check');
const Key contactPageStarKey = ValueKey('contact-page-star');
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

/// [contactInitials] in a [GlyphTile] of [size], in the display face.
class ContactTile extends StatelessWidget {
  const ContactTile({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // A neutral circle, as the desktop's rows: the gold brackets are brand art.
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: t.surfaceHi, border: Border.all(color: t.line)),
      child: Text(
        contactInitials(name),
        style: TextStyle(fontFamily: t.headFamily, fontSize: size * 0.35, fontWeight: FontWeight.w600, color: t.text),
      ),
    );
  }
}

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
        for (final tx in mine.take(5)) TxTile(tx: tx),
        if (mine.length > 5)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
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
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.contactsDeleteTitle(contact.name)),
        content: Text(pairing == null ? l.contactsDeleteConfirmBody : '${l.contactsDeleteConfirmBody}\n\n${l.contactDeletePaired(contact.name)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.tokens.risk),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
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

  void _showCode(Contact contact) => showModalBottomSheet<void>(
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
    // An invite or answer for this contact in flight.
    final inFlight = pairs &&
        (pairing == null || pairing.removedByPeer) &&
        (ref.watch(pairingsProvider).value ?? const <PairingRecord>[]).any((r) => r.contactId == contact.id && r.state.isPending);
    final starred = ref.watch(favouriteContactsProvider).value?.contains(contact.id) ?? false;
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
              'check' when pairing != null => _openCheck(pairing.id),
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
              if (pairing != null)
                PopupMenuItem(value: 'check', child: ListTile(leading: const Icon(EpicGlyphs.verified), title: Text(l.contactCheckWordsAgain))),
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
            onPair: pairs && (pairing == null || pairing.removedByPeer) && !inFlight ? () => _pair(contact) : null,
            onPending: pairs && (pairing == null || pairing.removedByPeer) && inFlight
                ? () => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const PendingInvitesScreen()))
                : null,
          ),
          PairSection(l.contactAddresses),
          _Addresses(contact: contact, pairing: pairing),
          if (pairs) ...[
            PairSection(l.contactPairing),
            if (pairing == null)
              _NotPaired(onPair: () => _pair(contact))
            // The other side removed it: no switches on a dead pairing, Pair again instead.
            else if (pairing.removedByPeer)
              _NotPaired(onPair: () => _pair(contact), title: l.trustRemovedBy(contact.name), hint: l.noticeUnpaired(contact.name), removed: true)
            else
              _PairingBlock(
                contact: contact,
                pairing: pairing,
                busy: _busy,
                run: _run,
                onCheck: () => _openCheck(pairing.id),
              ),
          ],
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

  void _pair(Contact contact) => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => PairScreen(contact: contact)));

  void _openCheck(String id) =>
      Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: id, recheck: true)));
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

  /// An invite or answer for it in flight: Pairing… opens Pending invites.
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
    final claimed = p?.name?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PairAvatar(name: contact.name, kind: p?.kind ?? PairingParty.person, size: 72),
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
                  if (p != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        TrustBadge(p),
                        if (p.allowInvoices && ref.watch(invoicesOnProvider)) EBadge(l.trustAllowsInvoices, icon: Icons.receipt_long_outlined),
                      ],
                    ),
                  ],
                  if (claimed != null && claimed.isNotEmpty && claimed != contact.name) ...[
                    const SizedBox(height: 4),
                    Text(l.pairCallsThemselves(claimed), style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
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
        Row(
          children: [
            FilledButton.tonalIcon(
              key: contactPageSendKey,
              style: _headerStyle(context, soft: true),
              icon: const Icon(Icons.north_east, size: 18),
              label: Text(l.contactsSendAction),
              onPressed: contact.addresses.isEmpty && !(p?.paysByMailbox ?? false) ? null : onSend,
            ),
            if (onPair != null) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: l.pairWithName(contact.name),
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
              const SizedBox(width: 8),
              Tooltip(
                message: l.pairBadgePendingTip,
                child: OutlinedButton.icon(
                  key: contactPageHeaderPairKey,
                  style: _headerStyle(context),
                  icon: const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  label: Text(l.pairBadgePending),
                  onPressed: onPending,
                ),
              ),
            ],
            const SizedBox(width: 8),
            if (onPair != null || onPending != null)
              IconButton.outlined(
                tooltip: l.contactsShowCode,
                style: IconButton.styleFrom(side: BorderSide(color: t.lineStrong), fixedSize: const Size(36, 36), minimumSize: const Size(36, 36)),
                icon: const Icon(Icons.qr_code_2, size: 18),
                onPressed: contact.addresses.isEmpty ? null : onCode,
              )
            else
              OutlinedButton.icon(
                style: _headerStyle(context),
                icon: const Icon(Icons.qr_code_2, size: 18),
                label: Text(l.contactsShowCode),
                onPressed: contact.addresses.isEmpty ? null : onCode,
              ),
          ],
        ),
        // A contact with only a pairing that cannot take a payment now: why Send is off.
        if (contact.addresses.isEmpty && p != null && !p.paysByMailbox) ...[
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
        for (final kind in contact.kinds)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 4, 4),
              child: Row(
                children: [
                  EBadge.kind(kind, l: l),
                  const SizedBox(width: 10),
                  Expanded(child: AddressText(contact.addressOf(kind)!, short: true)),
                  IconButton(
                    tooltip: l.contactCopyAddress(recipientMethodWord(l, kind)),
                    icon: Icon(Icons.copy, size: 20, color: t.accentText),
                    onPressed: () => copyText(context, contact.addressOf(kind)!, l.contactsCopied),
                  ),
                ],
              ),
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

class _NotPaired extends StatelessWidget {
  const _NotPaired({required this.onPair, this.title, this.hint, this.removed = false});

  final VoidCallback onPair;

  /// Instead of Not paired: the pairing the other side removed, with its reason.
  final String? title;
  final String? hint;
  final bool removed;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    return PairCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            children: [
              Icon(removed ? EpicGlyphs.keysChanged : EpicGlyphs.paired, color: removed ? t.risk : t.dim),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title ?? l.pairNotPaired, style: theme.textTheme.bodyLarge),
                    Text(hint ?? l.pairNotPairedHint, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: contactPagePairKey,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: onPair,
                child: Text(l.pairTitle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PairingBlock extends ConsumerWidget {
  const _PairingBlock({required this.contact, required this.pairing, required this.busy, required this.run, required this.onCheck});

  final Contact contact;
  final PairingRecord pairing;
  final bool busy;
  final Future<void> Function(Future<void> Function() call) run;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final p = pairing;
    final name = contact.name;
    final net = ref.watch(pairNetProvider);
    final paused = net == PairNet.epicboxOff;
    final changed = p.state == PairingState.keysChanged;
    final verified = p.state == PairingState.verified;
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
      if (await confirmRemovePairing(context, name)) await run(() => pairingCall(ref, (api) => api.removePairing(p.id)));
    }

    final sealInfo = '${l.contactSealInfo(name)}\n\n${l.contactSealInfoMore(name)}';
    final allowInfo = '${l.contactAllowInfo(name)}\n\n${l.contactAllowInfoMore}';
    final status = Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      child: Row(
        children: [
          Icon(
            changed ? EpicGlyphs.keysChanged : (verified ? EpicGlyphs.verified : EpicGlyphs.paired),
            color: changed ? t.risk : (verified ? t.ok : t.warn),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: changed ? l.trustKeysChanged : (verified ? l.trustVerified : l.trustPaired),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (changed) TextSpan(text: ' · ${l.contactKeysChangedStatus}', style: TextStyle(color: t.dim)),
                  if (verified && p.verifiedAt != null)
                    TextSpan(text: '  ${localDayMonth(l, p.verifiedAt!)}', style: TextStyle(color: t.dim, fontFamily: t.monoFamily, fontSize: 12)),
                ],
              ),
              style: theme.textTheme.bodyLarge,
            ),
          ),
          if (p.state == PairingState.paired)
            OutlinedButton(
              key: contactPageCheckKey,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: onCheck,
              child: Text(l.noticeCheckWords),
            ),
        ],
      ),
    );
    final relayRow = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Icon(paused ? Icons.pause_circle_outline : Icons.alt_route, size: 20, color: t.dim),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              paused ? l.contactPausedEpicboxOff : l.contactDeliveredVia(p.homeRelay),
              style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
            ),
          ),
        ],
      ),
    );
    final switchesLocked = busy || paused || changed;
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
              FilledButton(onPressed: busy ? null : onCheck, child: Text(l.noticeCheckWords)),
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
        if (p.seal == SealMode.degraded && !changed) ...[
          PairEdgeNotice(tone: BadgeTone.info, title: l.contactSealDegradedTitle(name), body: l.contactSealDegradedBody(name)),
          const SizedBox(height: 12),
        ],
        PairCard(
          children: [
            status,
            PairSwitchRow(
              switchKey: contactPageSealKey,
              label: l.contactSealPayments,
              info: sealInfo,
              value: !changed && p.seal != SealMode.off,
              hint: changed ? l.contactPausedUntilChecked : null,
              onChanged: switchesLocked ? null : setSeal,
            ),
            // Invoices off (Settings › Advanced): the switch is not offered; what it holds stays.
            if (ref.watch(invoicesOnProvider)) PairSwitchRow(
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
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            key: contactPageRemovePairingKey,
            style: TextButton.styleFrom(foregroundColor: t.risk, minimumSize: const Size(0, 48)),
            onPressed: busy ? null : remove,
            child: Text(l.contactRemovePairing),
          ),
        ),
      ],
    );
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
            decoration: BoxDecoration(
              color: t.field,
              border: Border.all(color: t.line),
              borderRadius: BorderRadius.circular(t.radiusSmall),
            ),
            padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 0, 4),
            child: Row(
              children: [
                Expanded(child: AddressText(address, selectable: true)),
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
