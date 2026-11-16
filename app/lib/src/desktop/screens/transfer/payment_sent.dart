// SPDX-License-Identifier: Apache-2.0
/// The Payment sent modal, the same after every send: whom the payment went to and how, the
/// amount as sent, and one line that follows the payment's row in the wallet's list. The full
/// progress is under Activity.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../trust_ids.dart';
import '../../../ui/epic1/epic1_sealed.dart' show Epic1SealedBadge;
import '../../../ui/theme/brand.dart' show GlyphTile;
import '../../../ui/theme/epic1_mark.dart' show Epic1Glyph;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../../widgets/pay_steps.dart' show PayFacts;
import '../wallet/tx_display.dart' show deskShowsSealed, statusOf;

/// A further action of the Payment sent modal: it closes the modal, then runs.
typedef PaymentSentAction = ({Key key, String label, IconData icon, VoidCallback run});

/// Opens the Payment sent modal over the page.
///
/// [txId] finds the payment's row in the wallet's list (its slate does when [sent], the row as
/// the send returned it, has one); [sent] stands in until the list has the row. [amount] is
/// the amount as sent. [name] is the contact it went to; without one [address] is shown short.
/// [method] and [methodIcon] say how it travelled. The mark is the epic1 glyph for an
/// [epic1Link], else [mark] (the method's own glyph), else the tone's tick. [more] comes
/// before View in Activity.
Future<void> showPaymentSent(
  BuildContext context, {
  required int txId,
  required int amount,
  required String method,
  Tx? sent,
  String? name,
  String? address,
  IconData? methodIcon,
  IconData? mark,
  bool epic1Link = false,
  PaymentSentAction? more,
}) => showEDialog<void>(
  context,
  builder: (_) => _PaymentSent(
    txId: txId,
    amount: amount,
    method: method,
    sent: sent,
    name: name,
    address: address,
    methodIcon: methodIcon,
    mark: mark,
    epic1Link: epic1Link,
    more: more,
  ),
);

class _PaymentSent extends ConsumerWidget {
  const _PaymentSent({
    required this.txId,
    required this.amount,
    required this.method,
    required this.sent,
    required this.name,
    required this.address,
    required this.methodIcon,
    required this.mark,
    required this.epic1Link,
    required this.more,
  });

  final int txId;
  final int amount;
  final String method;
  final Tx? sent;
  final String? name;
  final String? address;
  final IconData? methodIcon;
  final IconData? mark;
  final bool epic1Link;
  final PaymentSentAction? more;

  /// The tile beside an address: the epic1 glyph or the method's.
  Widget _tile(DeskColors c) => GlyphTile(
    size: 36.u,
    child: epic1Link ? Epic1Glyph(size: Ctl.icon, color: c.text) : Icon(methodIcon, size: Ctl.icon, color: c.accentText),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final nav = ref.read(deskNavProvider.notifier);
    final slate = sent?.slateId ?? '';
    // The payment as the wallet lists it now, so the line moves on its own.
    final live = ref.watch(deskProvider.select((s) => s.txs))?.where((t) => slate.isNotEmpty ? t.slateId == slate : t.id == txId).firstOrNull ?? sent;
    void close() => Navigator.of(context).pop();
    return EDialog(
      key: const ValueKey('payment-sent'),
      tone: ETone.ok,
      icon: mark,
      iconWidget: epic1Link ? Epic1Glyph(size: Ctl.iconLg, color: modalTone(context, ETone.ok).$1) : null,
      title: l.deskPaySentTitle,
      description: l.deskPaySentBody,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(Sp.x4),
            decoration: panelBox(c),
            child: Row(
              children: [
                if (name != null) EAvatar(name!, size: 36.u) else _tile(c),
                SizedBox(width: Sp.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (name != null)
                        Text(name!, style: ts.strong, maxLines: 1, overflow: TextOverflow.ellipsis)
                      else if (address != null)
                        epic1Link ? Epic1ShortAddress(address!, compact: true) : EShortAddress(address!, style: ts.mono(size: Fs.sm, color: c.text)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (methodIcon != null) ...[Icon(methodIcon, size: Ctl.iconSm, color: c.dim), SizedBox(width: Sp.x1)],
                          Flexible(child: Text(method, style: ts.small, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Sp.x3),
                EMoney(-amount, sign: true, color: c.txSent, size: Fs.lg),
              ],
            ),
          ),
          SizedBox(height: Sp.x4),
          _Now(tx: live, name: name),
          if (live != null && deskShowsSealed(ref, live)) ...[SizedBox(height: Sp.x3), const Center(child: Epic1SealedBadge())],
        ],
      ),
      actions: [
        if (more case final more?)
          EButton(
            key: more.key,
            label: more.label,
            icon: more.icon,
            onPressed: () {
              close();
              more.run();
            },
          ),
        EButton(
          key: const ValueKey('payment-sent-activity'),
          semanticsId: TrustIds.sendSentActivity,
          label: l.deskSendViewTx,
          onPressed: () {
            close();
            nav.go(DeskRoute.activity, txId);
          },
        ),
        EButton.primary(key: const ValueKey('payment-sent-done'), semanticsId: TrustIds.sendSentDone, label: l.commonDone, autofocus: true, onPressed: close),
      ],
    );
  }
}

/// Where the payment stands, in one line that follows its row: a spinner while it is under
/// way, a tick once it completed, the row's own status word when it ended or went wrong.
class _Now extends StatelessWidget {
  const _Now({required this.tx, required this.name});

  /// The payment's row; null until the list has it.
  final Tx? tx;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final t = tx;
    final waiting = name == null ? l.deskPaySentWaiting : l.sendTrackWaitingFor(name!);
    final done = t?.state == TxState.confirmed;
    final (String words, bool busy) = switch (t) {
      null => (waiting, true),
      _ when done => (l.deskTxStepSpendable, false),
      Tx(state: TxState.waitingRecipient, undelivered: false) => (waiting, true),
      // No block has it yet: posted, never "Confirming 0".
      final Tx p when (p.state == TxState.posted || p.state == TxState.confirming) && p.confirmations <= 0 && PayFacts.of(p).posted => (l.deskPaySentPosted, true),
      // The row's word; under way when the row counts it so.
      final Tx p => switch (statusOf(l, p)) {
        (final word, final tone) => (word, tone == ETone.info),
      },
    };
    return Semantics(
      liveRegion: true,
      child: Row(
        key: const ValueKey('payment-sent-now'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy) ...[ESpinner(size: 14.u, color: c.info), SizedBox(width: Sp.x2)],
          if (done) ...[Icon(EIcons.check, size: Ctl.iconSm, color: c.ok), SizedBox(width: Sp.x2)],
          Flexible(child: Text(words, style: context.ts.body, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
