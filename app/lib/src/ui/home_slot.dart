// SPDX-License-Identifier: Apache-2.0
/// Home's slot (HANDOFF 7.1): one card under the balance. Things that need the user come first
/// (an invoice to review), then calmer cards (a reminder, a message from BT Labs).
///
/// The slot reads one list, [homeSlotItemsProvider]. **This is where other features plug in**:
/// the `announcements` branch adds its signed messages as [HomeSlotItem]s to that provider's
/// list, with `needsYou` false, and the slot draws them as an info card (title, one line, an
/// icon, a tap) after anything that needs the user. Nothing else on Home changes for that.
/// "Later" sets an item aside until the wallet is opened again ([homeSlotLaterProvider]).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contacts.dart' show contactsProvider;
import '../devices/device_providers.dart' show withDeviceHistory;
import '../devices/phone_devices.dart' show phoneDevices;
import '../l10n.dart';
import '../models.dart';
import '../pairing_providers.dart' show pairingsProvider;
import '../providers.dart';
import '../settings.dart';
import '../trust_ids.dart';
import 'backup_screen.dart' show backedUpProvider;
import 'common.dart';
import 'home_screen.dart' show paymentsNotInBackup, unbackedPayments;
import 'settings_history.dart' show exportHistoryBackup;
import 'invoice_review_screen.dart';
import 'invoices_screen.dart' show invoiceSenderName;
import 'kit/kit_icons.dart';
import 'kit/kit_slot_card.dart';

/// Where a card sits among the slot's pages, and how it asks to be put away.
class HomeSlotPage {
  const HomeSlotPage({required this.pages, required this.page, required this.onLater});

  final int pages;
  final int page;
  final VoidCallback onLater;
}

/// One thing Home's slot can show.
abstract class HomeSlotItem {
  const HomeSlotItem();

  /// Stable across rebuilds; "Later" remembers it.
  String get id;

  /// Needs a decision from the user: drawn first, in the gold card.
  bool get needsYou;

  Widget build(BuildContext context, WidgetRef ref, HomeSlotPage page);
}

/// An invoice waiting for the user's approval.
class InvoiceSlotItem extends HomeSlotItem {
  const InvoiceSlotItem(this.invoice);

  final PendingInvoice invoice;

  @override
  String get id => 'invoice-${invoice.slateId}';

  @override
  bool get needsYou => true;

  @override
  Widget build(BuildContext context, WidgetRef ref, HomeSlotPage page) {
    final l = context.l10n;
    final pairings = ref.watch(pairingsProvider).value ?? const <PairingRecord>[];
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final display = amountDisplay(ref);
    final who = invoiceSenderName(l, pairings, contacts, invoice.pairingId);
    final amount = shownEpic(l, invoice.amount, hidden: display.hidden);
    final fiat = phoneFiat(l, invoice.amount, display, approx: true);
    return KitNeedsYouCard(
      title: l.phoneHomeInvoiceTitle(who),
      subtitle: l.phoneHomeInvoiceBody(fiat == null ? amount : '$amount · $fiat'),
      reviewLabel: l.phoneReview,
      laterLabel: l.phoneLater,
      pages: page.pages,
      page: page.page,
      reviewId: TrustIds.homeReview,
      laterId: TrustIds.homeLater,
      onLater: page.onLater,
      onReview: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => InvoiceReviewScreen(invoice: invoice))),
    );
  }
}

/// A calm card: an icon, a title, a line, a tap. For reminders and messages.
class InfoSlotItem extends HomeSlotItem {
  const InfoSlotItem({required this.id, required this.title, this.subtitle, this.icon = KitIcons.info, this.onOpen});

  @override
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final void Function(BuildContext context)? onOpen;

  @override
  bool get needsYou => false;

  @override
  Widget build(BuildContext context, WidgetRef ref, HomeSlotPage page) => KitSlotCard(
    title: title,
    subtitle: subtitle,
    icon: icon,
    pages: page.pages,
    page: page.page,
    onTap: onOpen == null ? null : () => onOpen!(context),
  );
}

/// A history backup that is due: payments a restore from the phrase cannot bring back. "Not now"
/// puts the reminder off for 30 days; Export runs the backup.
class HistoryBackupSlotItem extends HomeSlotItem {
  const HistoryBackupSlotItem({required this.chain, required this.count, required this.exported});

  final Chain chain;
  final int count;

  /// Whether a backup was ever exported (the words differ).
  final bool exported;

  @override
  String get id => 'history-backup';

  @override
  bool get needsYou => true;

  @override
  Widget build(BuildContext context, WidgetRef ref, HomeSlotPage page) {
    final l = context.l10n;
    return KitNeedsYouCard(
      title: exported ? l.homeHistoryChangedSinceBackup(count) : l.homeHistoryNotBackedUp(count),
      reviewLabel: l.homeHistoryExportButton,
      laterLabel: l.homeHistoryReminderNotNow,
      icon: KitIcons.backup,
      pages: page.pages,
      page: page.page,
      reviewId: TrustIds.homeBackupExport,
      laterId: TrustIds.homeBackupNotNow,
      onLater: () => ref.read(appSettingsProvider.notifier).dismissHistoryReminder(chain, ref.read(clockProvider)()),
      onReview: () => exportHistoryBackup(context, ref),
    );
  }
}

/// The backup reminder as a slot item, or null when none is due. It waits until the phrase is
/// written down: that backup comes first.
final _historyBackupItemProvider = Provider<HistoryBackupSlotItem?>((ref) {
  final config = ref.watch(walletConfigProvider);
  final settings = ref.watch(appSettingsProvider).value;
  final backedUp = ref.watch(backedUpProvider).value ?? true;
  if (config == null || settings == null || !backedUp) return null;
  final rows = withDeviceHistory(ref.watch(homeProvider).value?.transactions ?? const <TxEntry>[], ref.watch(phoneDevices.view));
  final chain = config.chain;
  final now = ref.watch(clockProvider)();
  final exportedAt = settings.historyExportedAt[chain.name];
  final firstSeenAt = settings.historyReminderFirstSeenAt[chain.name];
  final snapshot = settings.historyExportSnapshots[chain.name];
  if (firstSeenAt == null && unbackedPayments(rows, exportedAt: exportedAt, snapshot: snapshot) > 0) {
    // The 30 days of a wallet with no export and no dismissal start here.
    final notifier = ref.read(appSettingsProvider.notifier);
    Future.microtask(() => notifier.markHistoryReminderSeen(chain, now));
  }
  final count = paymentsNotInBackup(
    rows,
    now: now,
    exportedAt: exportedAt,
    dismissedAt: settings.historyReminderDismissedAt[chain.name],
    firstSeenAt: firstSeenAt,
    snapshot: snapshot,
  );
  if (count == null) return null;
  return HistoryBackupSlotItem(chain: chain, count: count, exported: exportedAt != null);
});

/// Everything the slot could show, needs-you first. Add new kinds here.
final homeSlotItemsProvider = Provider<List<HomeSlotItem>>((ref) {
  final invoices = ref.watch(pendingInvoicesProvider).value ?? const <PendingInvoice>[];
  final backup = ref.watch(_historyBackupItemProvider);
  return [for (final i in invoices) InvoiceSlotItem(i), ?backup];
});

/// The ids the user put away with "Later" in this session.
final homeSlotLaterProvider = NotifierProvider<HomeSlotLaterNotifier, Set<String>>(HomeSlotLaterNotifier.new);

class HomeSlotLaterNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    // A new session starts clean.
    ref.watch(sessionProvider);
    return const {};
  }

  void put(String id) => state = {...state, id};
}

/// What the slot draws now: [homeSlotItemsProvider] without what was put away, items that need
/// the user first.
final homeSlotVisibleProvider = Provider<List<HomeSlotItem>>((ref) {
  final later = ref.watch(homeSlotLaterProvider);
  final items = [for (final i in ref.watch(homeSlotItemsProvider)) if (!later.contains(i.id)) i];
  return [...items.where((i) => i.needsYou), ...items.where((i) => !i.needsYou)];
});

/// The slot on Home: the first card, with page dots when there are more; a swipe turns the page.
class HomeSlot extends ConsumerStatefulWidget {
  const HomeSlot({super.key});

  @override
  ConsumerState<HomeSlot> createState() => _HomeSlotState();
}

class _HomeSlotState extends ConsumerState<HomeSlot> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(homeSlotVisibleProvider);
    if (items.isEmpty) return const SizedBox.shrink();
    final page = _page.clamp(0, items.length - 1);
    final item = items[page];
    void turn(int by) => setState(() => _page = (page + by).clamp(0, items.length - 1));
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: items.length < 2
          ? null
          : (d) {
              final v = d.primaryVelocity ?? 0;
              final rtl = Directionality.of(context) == TextDirection.rtl;
              if (v.abs() < 200) return;
              turn((v < 0) != rtl ? 1 : -1);
            },
      child: KeyedSubtree(
        key: ValueKey('home-slot-${item.id}'),
        child: item.build(
          context,
          ref,
          HomeSlotPage(
            pages: items.length,
            page: page,
            onLater: () => ref.read(homeSlotLaterProvider.notifier).put(item.id),
          ),
        ),
      ),
    );
  }
}
