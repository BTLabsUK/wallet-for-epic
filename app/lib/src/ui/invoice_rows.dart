/// The rows of the Invoices screen (spec §5.1): an invoice to pay and a request this wallet
/// sent. Card-less, a hairline between rows; the amount in mono at the end, without a sign.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../wallet_service.dart';
import 'invoice_request_screen.dart';
import 'invoice_review_screen.dart';
import 'invoices_screen.dart';
import 'theme/brand.dart';
import 'theme/tokens.dart';
import 'tx_details_screen.dart';

/// Keys of the rows' Withdraw buttons, for tests.
Key requestWithdrawKey(String slateId) => ValueKey('request-withdraw-$slateId');

/// Under this much time left, the time left shows in the warning colour.
const Duration invoiceWarnUnder = Duration(hours: 1);

/// [left] as the desktop writes it, in warn under [invoiceWarnUnder].
TextSpan invoiceTimeLeftSpan(BuildContext context, Duration left) {
  final t = context.tokens;
  return TextSpan(
    text: invoiceTimeLeft(context.l10n, left),
    style: TextStyle(color: left < invoiceWarnUnder ? t.warn : t.dim),
  );
}

/// The frame both rows share: a 40 dp tile, two lines, the amount at the end, an optional
/// [foot] under it all.
class _InvoiceRowFrame extends StatelessWidget {
  const _InvoiceRowFrame({
    required this.icon,
    required this.title,
    required this.detail,
    required this.amount,
    required this.onTap,
    this.foot,
  });

  final IconData icon;
  final String title;
  final InlineSpan detail;
  final String amount;
  final VoidCallback onTap;
  final Widget? foot;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    GlyphTile(size: 40, child: Icon(icon)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.bodyLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text.rich(
                            detail,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: t.dim,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      amount,
                      style: TextStyle(
                        fontFamily: t.monoFamily,
                        fontSize: 15,
                        color: t.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ?foot,
        ],
      ),
    );
  }
}

/// An invoice waiting for the user: the service by the user's label, the time left and the
/// message's first line, the amount. A tap opens the review.
class InvoiceRow extends StatelessWidget {
  const InvoiceRow({
    super.key,
    required this.invoice,
    required this.service,
    required this.left,
    required this.amount,
  });

  final PendingInvoice invoice;
  final String service;
  final Duration left;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final message = invoiceMessageLine(invoice.message);
    return _InvoiceRowFrame(
      icon: Icons.receipt_long_outlined,
      title: service,
      detail: TextSpan(
        children: [
          invoiceTimeLeftSpan(context, left),
          if (message != null) TextSpan(text: ' · $message'),
        ],
      ),
      amount: amount,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => InvoiceReviewScreen(invoice: invoice),
        ),
      ),
    );
  }
}

/// A request this wallet sent: the payer, its state as a word with a mark, the amount, and
/// Withdraw on its own line while it can be withdrawn. A tap opens its payment's details.
class RequestRow extends ConsumerStatefulWidget {
  const RequestRow({
    super.key,
    required this.request,
    required this.payer,
    required this.left,
    required this.amount,
  });

  final IssuedInvoice request;
  final String payer;
  final Duration left;
  final String amount;

  @override
  ConsumerState<RequestRow> createState() => _RequestRowState();
}

class _RequestRowState extends ConsumerState<RequestRow> {
  bool _busy = false;

  Future<void> _withdraw() async {
    setState(() => _busy = true);
    try {
      await confirmWithdraw(context, ref, widget.request);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final request = widget.request;
    // A mark beside the word, so the state never rests on colour alone.
    InlineSpan marked(IconData icon, Color color, String word) => TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: Icon(icon, size: 14, color: color),
          ),
        ),
        TextSpan(text: word),
      ],
    );
    final detail = switch (request.state) {
      IssuedInvoiceState.waiting => TextSpan(
        children: [
          TextSpan(text: '${l.invoicesWaitingPayment} · '),
          invoiceTimeLeftSpan(context, widget.left),
        ],
      ),
      IssuedInvoiceState.paid => marked(Icons.check, t.ok, l.issuedPaid),
      IssuedInvoiceState.withdrawn => marked(
        Icons.radio_button_unchecked,
        t.dim,
        l.issuedWithdrawn,
      ),
      IssuedInvoiceState.expired => marked(
        Icons.radio_button_unchecked,
        t.dim,
        l.issuedExpired,
      ),
      IssuedInvoiceState.declined => marked(
        Icons.block,
        t.warn,
        l.issuedDeclined,
      ),
      IssuedInvoiceState.bounced => marked(
        Icons.reply,
        t.warn,
        l.issuedBounced,
      ),
    };
    return _InvoiceRowFrame(
      icon: Icons.call_received,
      title: widget.payer,
      detail: detail,
      amount: widget.amount,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TxDetailsScreen(txKey: 's:${request.slateId}'),
        ),
      ),
      foot: request.withdrawable
          ? Padding(
              padding: const EdgeInsetsDirectional.only(start: 60, bottom: 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: requestWithdrawKey(request.slateId),
                  style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: _busy ? null : _withdraw,
                  child: Text(l.issuedWithdraw),
                ),
              ),
            )
          : null,
    );
  }
}
