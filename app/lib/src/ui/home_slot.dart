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

import 'dart:async';

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
import '../log.dart' show logWarn;
import 'backup_screen.dart' show BackupScreen, backedUpProvider;
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
      // News to answer, not a warning: the quiet blue card.
      info: true,
      onLater: page.onLater,
      onReview: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => InvoiceReviewScreen(invoice: invoice))),
    );
  }
}

/// A calm card: an icon, a title, a line, a tap. For reminders and messages.
class InfoSlotItem extends HomeSlotItem {
  const InfoSlotItem({required this.id, required this.title, this.subtitle, this.icon = KitIcons.info, this.action, this.onOpen});

  @override
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;

  /// The gold link under the text, as the frame draws a reminder's ("Back up now").
  final String? action;
  final void Function(BuildContext context)? onOpen;

  @override
  bool get needsYou => false;

  @override
  Widget build(BuildContext context, WidgetRef ref, HomeSlotPage page) => KitSlotCard(
    title: title,
    subtitle: subtitle,
    icon: icon,
    action: action,
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

/// The recovery phrase reminder, as the frame's "Wallet reminders" card: a shield, two lines, a
/// gold "Back up now" link that opens the back-up, and a × that hides it for [backupReminderEvery].
/// It stays in the slot until the phrase is written down.
class BackupReminderSlotItem extends HomeSlotItem {
  const BackupReminderSlotItem();

  @override
  String get id => 'backup-reminder';

  @override
  bool get needsYou => false;

  @override
  Widget build(BuildContext context, WidgetRef ref, HomeSlotPage page) {
    final l = context.l10n;
    return KitReminderCard(
      icon: KitIcons.security,
      text: l.phoneBackupReminderText,
      action: l.phoneBackupReminderAction,
      onAction: () => unawaited(openBackup(context, ref)),
      closeLabel: l.commonClose,
      onClose: () => unawaited(ref.read(backupReminderHiddenProvider.notifier).hide()),
      pages: page.pages,
      page: page.page,
      actionId: TrustIds.homeBackupReminder,
      closeId: TrustIds.homeBackupReminderClose,
    );
  }
}

/// Opens the back-up; "Done" there says so with a notice. The reminder leaves by itself: the
/// phrase is then backed up.
Future<void> openBackup(BuildContext context, WidgetRef ref) async {
  final notices = ref.read(noticeProvider.notifier);
  final done = context.l10n.homeBackedUpNotice;
  final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const BackupScreen()));
  if (saved == true) notices.show(done, level: NoticeLevel.success);
}

/// The reminder comes back this long after the user closed it.
const Duration backupReminderEvery = Duration(days: 1);

/// When the user closed the phrase reminder on [chain]'s wallet (milliseconds since the epoch).
/// Stored beside the vault's entries for the chain (`wallet.<chain>.*`), so deleting the wallet
/// forgets it too.
String backupNoticeKey(Chain chain) => 'wallet.${chain.name}.backupNoticeAt';

/// When the user last closed the phrase reminder, or null. Read again for each session.
final backupReminderHiddenProvider = AsyncNotifierProvider<BackupReminderHidden, DateTime?>(BackupReminderHidden.new);

class BackupReminderHidden extends AsyncNotifier<DateTime?> {
  @override
  Future<DateTime?> build() async {
    ref.watch(sessionProvider);
    final config = ref.watch(walletConfigProvider);
    if (config == null) return null;
    final ms = int.tryParse(await ref.read(secretStoreProvider).read(backupNoticeKey(config.chain)) ?? '');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Hides the reminder now, and for a day after a restart too.
  Future<void> hide() async {
    final config = ref.read(walletConfigProvider);
    if (config == null) return;
    final now = ref.read(clockProvider)();
    state = AsyncData(now);
    try {
      await ref.read(secretStoreProvider).write(backupNoticeKey(config.chain), '${now.millisecondsSinceEpoch}');
    } on Object catch (e) {
      logWarn('home', 'backup reminder time not saved: ${e.runtimeType}');
    }
  }
}

/// The phrase reminder as a slot item, or null: the phrase is written down, the answer is not
/// known yet, or it was closed less than [backupReminderEvery] ago.
BackupReminderSlotItem? _backupReminderItem(Ref ref, bool? backedUp) {
  if (backedUp != false) return null;
  final hidden = ref.watch(backupReminderHiddenProvider);
  if (!hidden.hasValue) return null;
  final at = hidden.value;
  if (at != null && ref.watch(clockProvider)().difference(at) < backupReminderEvery) return null;
  return const BackupReminderSlotItem();
}

/// The backup reminder as a slot item, or null when none is due. It waits until the phrase is
/// written down: that backup comes first.
HistoryBackupSlotItem? _historyBackupItem(Ref ref, bool? backedUpAnswer) {
  final config = ref.watch(walletConfigProvider);
  final settings = ref.watch(appSettingsProvider).value;
  final backedUp = backedUpAnswer ?? true;
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
}

/// Everything the slot could show, needs-you first. Add new kinds here.
final homeSlotItemsProvider = Provider<List<HomeSlotItem>>((ref) {
  final invoices = ref.watch(pendingInvoicesProvider).value ?? const <PendingInvoice>[];
  // The one reader of the phrase answer in this chain: two providers reading it separately
  // fail when a screen over Home pauses them and the answer changes meanwhile.
  final backedUp = ref.watch(backedUpProvider).value;
  final backup = _historyBackupItem(ref, backedUp);
  final phrase = _backupReminderItem(ref, backedUp);
  // Calm cards follow what needs the user, in this order: the wallet's own reminders, then (from
  // the `announcements` branch) the messages from BT Labs.
  return [for (final i in invoices) InvoiceSlotItem(i), ?backup, ?phrase];
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
