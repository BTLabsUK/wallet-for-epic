// SPDX-License-Identifier: Apache-2.0
/// Level 1 keeps invoices quiet ([InvoicePresence.quiet]): no notice and no Invoices screen. An
/// invoice waiting for the user is one row under Home's Recent activity and at the top of
/// Activity, "Invoice · waiting for your approval", which opens it (the review screen, where
/// it is paid or declined). Levels 2 and 3 keep today's notice and screens, so this draws
/// nothing there.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n.dart';
import '../../levels/level_features.dart' show InvoicePresence;
import '../../levels/level_providers.dart' show levelFeaturesProvider;
import '../../contacts.dart' show contactsProvider;
import '../../pairing_providers.dart' show pairingsProvider;
import '../../providers.dart';
import '../../wallet_service.dart';
import '../common.dart';
import '../invoice_review_screen.dart';
import '../invoices_screen.dart' show invoiceSenderName;
import '../theme/brand.dart';
import '../theme/tokens.dart';

/// The key of an invoice's row, for tests.
Key quietInvoiceKey(String slateId) => ValueKey('quiet-invoice-$slateId');

/// The invoices waiting, one row each; nothing when the level shows invoices its own way.
class QuietInvoiceRows extends ConsumerWidget {
  const QuietInvoiceRows({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiet = ref.watch(levelFeaturesProvider.select((f) => f.invoices)) == InvoicePresence.quiet;
    if (!quiet) return const SizedBox.shrink();
    final invoices = ref.watch(pendingInvoicesProvider).value ?? const <PendingInvoice>[];
    if (invoices.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final pairings = ref.watch(pairingsProvider).value ?? const <PairingRecord>[];
    final contacts = ref.watch(contactsProvider).value ?? const <Contact>[];
    final display = amountDisplay(ref);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final invoice in invoices)
          _Row(
            key: quietInvoiceKey(invoice.slateId),
            invoice: invoice,
            who: invoiceSenderName(l, pairings, contacts, invoice.pairingId),
            amount: shownEpic(l, invoice.amount, hidden: display.hidden),
            fiat: approxFiat(l, invoice.amount, display, short: true),
          ),
      ],
    );
  }
}

/// One invoice as a payment row reads: the sender, the step word, the amount and its value.
class _Row extends StatelessWidget {
  const _Row({super.key, required this.invoice, required this.who, required this.amount, required this.fiat});

  final PendingInvoice invoice;
  final String who;
  final String amount;
  final String? fiat;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    void open() => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => InvoiceReviewScreen(invoice: invoice)),
    );
    return Semantics(
      button: true,
      label: [who, l.lvPolInvoiceWaiting, amount, ?fiat].join(', '),
      excludeSemantics: true,
      onTap: open,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlyphTile(size: 40, child: Icon(Icons.receipt_long_outlined, size: 20, color: t.info)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(who, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      l.lvPolInvoiceWaiting,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: t.info),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AmountText(amount, style: theme.textTheme.bodyMedium?.copyWith(color: t.text)),
                  if (fiat != null) Text(fiat!, style: theme.textTheme.bodySmall?.copyWith(color: t.dim)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
