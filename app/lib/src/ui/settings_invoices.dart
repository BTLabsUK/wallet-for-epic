/// Settings › Wallet › Invoices: who may ask this wallet to pay. Since RFC 0002
/// that is a paired, verified contact with Allow invoices on; the screen lists the paired
/// contacts with their switch and offers Pair with a shop or exchange. Time to pay stays a
/// readout under Advanced. Nothing here pays: each request waits on the Invoices screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart';
import '../errors.dart';
import '../l10n.dart';
import '../pairing_providers.dart';
import '../pairing_text.dart' show sameNamedContact;
import '../wallet_service.dart';
import 'common.dart';
import 'pairing/pair_check.dart';
import 'pairing/pair_screen.dart';
import 'pairing/pairing_parts.dart';
import 'theme/advanced.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';

/// Keys for tests.
const Key invoiceSettingsPairKey = ValueKey('invoice-settings-pair');

/// The key of the row menu of the pairing [id] (Save as a new contact, Add to a contact, Check
/// the words, Remove pairing).
Key invoiceSettingsMenuKey(String id) => ValueKey('invoice-settings-menu-$id');

/// The key of the Allow invoices switch of the pairing [id].
Key invoiceSettingsSwitchKey(String id) => ValueKey('invoice-settings-allow-$id');

class InvoiceSettingsScreen extends ConsumerStatefulWidget {
  const InvoiceSettingsScreen({super.key});

  @override
  ConsumerState<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends ConsumerState<InvoiceSettingsScreen> {
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(pairNetProvider) == PairNet.epicboxOff && ref.read(pairedProvider).isNotEmpty) {
        final l = context.l10n;
        ref.read(noticeProvider.notifier).show('${l.contactPausedEpicboxOff}. ${l.invSetPausedBody}', level: NoticeLevel.info);
      }
    });
  }

  void _pair() => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const PairScreen()));

  Future<void> _set(PairingRecord r, String name, bool on) async {
    final l = context.l10n;
    final notices = ref.read(noticeProvider.notifier);
    setState(() => _busy.add(r.id));
    try {
      final declined = await pairingCall(ref, (api) => api.setAllowInvoices(r.id, on));
      if (!on) {
        notices.show(
          declined > 0 ? '${l.invSetSwitchedOff(name)} ${l.invSetDeclinedCount(declined)}' : l.invSetSwitchedOff(name),
          level: NoticeLevel.info,
        );
      }
    } catch (error) {
      notices.show(describeError(l, error), level: NoticeLevel.error);
    } finally {
      if (mounted) setState(() => _busy.remove(r.id));
    }
  }

  /// Puts the pairing [r] in the contacts, the way the user picks (security review: never
  /// matched for them): a new contact from the form, or one of theirs.
  Future<void> _attach(PairingRecord r, {required bool asNew}) async {
    final contact = asNew ? await savePairingAsNewContact(context, r) : await pickContactForPairing(context);
    if (contact == null || !mounted) return;
    final l = context.l10n;
    await pairingCall(ref, (api) => api.attach(r.id, contact.id));
    ref.read(noticeProvider.notifier).show(l.pairSavedAs(contact.name), level: NoticeLevel.success);
  }

  Future<void> _attachTo(PairingRecord r, Contact contact) async {
    final l = context.l10n;
    await pairingCall(ref, (api) => api.attach(r.id, contact.id));
    if (!mounted) return;
    ref.read(noticeProvider.notifier).show(l.pairSavedAs(contact.name), level: NoticeLevel.success);
  }

  Future<void> _remove(PairingRecord r, String name) async {
    if (await confirmRemovePairing(context, name)) await pairingCall(ref, (api) => api.removePairing(r.id));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final paired = ref.watch(pairedProvider);
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final paused = ref.watch(pairNetProvider) == PairNet.epicboxOff;
    final loading = ref.watch(pairingsProvider).isLoading;
    final pairButton = OutlinedButton.icon(
      key: invoiceSettingsPairKey,
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      icon: const Icon(Icons.storefront_outlined),
      label: Text(l.invSetPairShop),
      onPressed: _pair,
    );
    return SlotScaffold(
      idle: loading ? SlotProgress(label: l.invSetTitle) : null,
      appBar: AppBar(title: Text(l.invSetTitle)),
      body: ScreenBody(
        children: [
          PairLead(l.invSetLead),
          if (paired.isEmpty && !loading)
            EmptyState(
              icon: const Icon(Icons.shield_outlined),
              message: l.invSetEmpty,
              action: FilledButton.icon(
                key: invoiceSettingsPairKey,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                icon: const Icon(Icons.storefront_outlined),
                label: Text(l.invSetPairShop),
                onPressed: _pair,
              ),
            )
          else ...[
            PairSection(l.invSetPaired),
            PairCard(
              children: [
                for (final r in paired) _row(l, t, r, contacts, paused),
              ],
            ),
            const SizedBox(height: 16),
            pairButton,
          ],
          // How long an invoice stays payable is technical: the simple path never needs it.
          Advanced(
            feature: AdvancedFeature.technicalDetails,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(l.invSetTimeToPay),
                  subtitle: Text(l.invSetTimeToPayHint(invoiceExpiry.inHours)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(AppLocalizations l, WalletTokens t, PairingRecord r, List<Contact> contacts, bool paused) {
    final theme = Theme.of(context);
    final contact = r.contactId == null ? null : contacts.where((c) => c.id == r.contactId).firstOrNull;
    final name = contact?.name ?? r.shownName;
    final verified = r.state == PairingState.verified;
    final orphan = contact == null;
    // A contact of the name it chose comes first: a re-pair's key check starts there.
    final all = ref.watch(pairingsProvider).value ?? const <PairingRecord>[];
    final suggested = orphan
        ? sameNamedContact<Contact>(r, contacts, (c) => c.name, paired: (c) => all.any((p) => p.id != r.id && p.contactId == c.id && p.state.isPaired))
        : null;
    // Keys changed, as the contact page shows it: the risk badge, paused until the words match.
    final changed = r.state == PairingState.keysChanged;
    final subtitle = changed
        ? l.contactKeysChangedPaused
        : verified
        ? (r.allowInvoices ? l.invSetAllowed : l.invSetOff)
        : l.contactCheckWordsFirst;
    final checkWords = !verified && (r.state == PairingState.paired || changed);
    // Not faded and not merged: the text keeps its contrast, and a screen reader reaches the
    // switch and the row's menu on their own.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 0, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PairAvatar(name: name, kind: r.kind, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: theme.textTheme.bodyLarge?.copyWith(color: verified ? t.text : t.dim), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (changed) ...[
                    Padding(padding: const EdgeInsets.only(top: 2, bottom: 2), child: TrustBadge(r, short: true)),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                  ] else
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                  if (orphan) Text(l.pairNotInContacts, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                ],
              ),
            ),
            Semantics(
              label: l.invSetAllowFor(name),
              child: Switch(
                key: invoiceSettingsSwitchKey(r.id),
                value: verified && r.allowInvoices,
                onChanged: !verified || paused || _busy.contains(r.id) ? null : (v) => _set(r, name, v),
              ),
            ),
            if (orphan || checkWords)
              PopupMenuButton<String>(
                key: invoiceSettingsMenuKey(r.id),
                tooltip: l.contactMore,
                onSelected: (v) => switch (v) {
                  'named' when suggested != null => _attachTo(r, suggested),
                  'new' => _attach(r, asNew: true),
                  'add' => _attach(r, asNew: false),
                  'check' => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: r.id, recheck: changed))),
                  'remove' => _remove(r, name),
                  _ => null,
                },
                itemBuilder: (context) => [
                  if (checkWords) PopupMenuItem(value: 'check', child: Text(l.noticeCheckWords)),
                  if (orphan) ...[
                    if (suggested != null) PopupMenuItem(value: 'named', child: Text(l.pairAddToNamed(suggested.name))),
                    PopupMenuItem(value: 'new', child: Text(l.pairSaveNewContact)),
                    PopupMenuItem(value: 'add', child: Text(l.pairAddToAContact)),
                  ],
                  PopupMenuItem(value: 'remove', child: Text(l.contactRemovePairing, style: TextStyle(color: t.risk))),
                ],
              )
            else
              // The menu's width: every switch lines up.
              const SizedBox(width: kMinInteractiveDimension),
          ],
        ),
      ),
    );
  }
}
