import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/kit.dart';
import 'tx_display.dart';

/// States the tour can start Overview in.
enum OverviewDemo { loading, empty, nodeDown }

/// Mock price for the fiat line.
const double _usdPerEpic = 0.42;

/// Overview: the balance (the one framed object), recent activity and the status card.
class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await ref.read(deskProvider.notifier).refresh();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final demo = widget.arg is OverviewDemo ? widget.arg! as OverviewDemo : null;
    final s = ref.watch(deskProvider);
    final hidden = s.settings.hideAmounts;
    final loading = demo == OverviewDemo.loading || s.balance == null;
    final empty = demo == OverviewDemo.empty;
    final balance = empty ? const Balance(spendable: 0, awaitingConfirmation: 0, locked: 0, awaitingFinalization: 0) : s.balance;
    final txs = empty ? const <Tx>[] : (demo == OverviewDemo.loading ? null : s.txs);
    final nav = ref.read(deskNavProvider.notifier);
    final wide = MediaQuery.sizeOf(context).width >= 1280;
    final narrow = MediaQuery.sizeOf(context).width < 900;

    final recent = _Recent(txs: txs, onOpen: (t) => nav.go(DeskRoute.activity, t.id), onAll: () => nav.go(DeskRoute.activity));
    final status = _StatusCard(nodeDown: demo == OverviewDemo.nodeDown);
    final pending = empty ? 0 : s.pendingFiles;

    return EPage(
      title: 'Overview',
      width: EPageWidth.full,
      actions: [
        EIconButton(
          icon: hidden ? EIcons.eyeOff : EIcons.eye,
          label: hidden ? 'Show amounts' : 'Hide amounts',
          selected: hidden,
          onPressed: () => ref.read(deskProvider.notifier).saveSettings(s.settings.copyWith(hideAmounts: !hidden)),
        ),
        _refreshing
            ? const SizedBox.square(dimension: Ctl.sm, child: Center(child: ESpinner()))
            : EIconButton(icon: EIcons.refresh, label: 'Refresh', onPressed: _refresh),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (demo == OverviewDemo.nodeDown) ...[
            ENotice(
              tone: ETone.risk,
              title: 'Node not answering',
              text: 'Balance and history may be out of date. Sending waits for a node.',
              actions: [
                EButton(label: 'Node settings', kind: EBtnKind.ghost, size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.settingsNode)),
              ],
            ),
            const SizedBox(height: Sp.x4),
          ],
          _BalancePanel(balance: loading ? null : balance, empty: empty, hidden: hidden),
          const SizedBox(height: Sp.x2),
          if (narrow) ...[
            recent,
            status,
            if (pending > 0) _PendingFiles(count: pending),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: recent),
                const SizedBox(width: Sp.x6),
                SizedBox(
                  width: wide ? 320 : 264,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [status, if (pending > 0) _PendingFiles(count: pending)],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BalancePanel extends ConsumerWidget {
  const _BalancePanel({required this.balance, required this.empty, required this.hidden});

  final Balance? balance;
  final bool empty;
  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final nav = ref.read(deskNavProvider.notifier);
    final b = balance;
    final amount = b == null
        ? _Skeleton(width: 260, height: 40)
        : _BigAmount(nano: b.spendable, hidden: hidden);
    final actions = Wrap(
      spacing: Sp.x2,
      runSpacing: Sp.x2,
      children: empty
          ? [EButton.primary(label: 'Receive EPIC', icon: EIcons.receive, onPressed: () => nav.go(DeskRoute.receive))]
          : [
              EButton.primary(label: 'Send', icon: EIcons.send, onPressed: () => nav.go(DeskRoute.send)),
              EButton(label: 'Receive', icon: EIcons.receive, onPressed: () => nav.go(DeskRoute.receive)),
            ],
    );
    return ETicked(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.x8, Sp.x6, Sp.x8, 0),
            child: LayoutBuilder(
              builder: (context, box) {
                final words = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available to spend', style: ts.bodyDim.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    amount,
                    const SizedBox(height: 6),
                    if (empty)
                      Text('Share the Epicbox address to receive the first EPIC.', style: ts.bodyDim)
                    else if (b != null)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: hidden ? '≈ \$•••' : '≈ \$${(b.total / nanoPerEpic * _usdPerEpic).toStringAsFixed(2)}'),
                            TextSpan(text: '  whole balance, CoinGecko', style: TextStyle(color: c.faint)),
                          ],
                        ),
                        style: ts.bodyDim,
                      ),
                  ],
                );
                if (box.maxWidth < 560) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [words, const SizedBox(height: Sp.x4), actions]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(child: words), const SizedBox(width: Sp.x6), actions],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.x8, Sp.x5, Sp.x8, 0),
            child: SizedBox(height: 26, child: CustomPaint(painter: _TracePainter(c.accent))),
          ),
          const SizedBox(height: Sp.x5),
          Divider(height: 1, color: c.line),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Break(label: 'Total', nano: b?.total, first: true),
                _Break(label: 'Confirming', nano: b?.awaitingConfirmation, lead: const ERing(confirmations: 1, size: 15)),
                _Break(label: 'Awaiting finalization', nano: b?.awaitingFinalization),
                _Break(label: 'Locked in sends', nano: b?.locked, lead: Icon(EIcons.lock, size: Ctl.iconSm, color: c.dim), last: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The balance in Montserrat 44: whole part bright, fraction dim, unit in mono.
class _BigAmount extends StatelessWidget {
  const _BigAmount({required this.nano, required this.hidden});

  final int nano;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final text = formatEpic(nano);
    final dot = text.indexOf('.');
    final whole = dot < 0 ? text : text.substring(0, dot);
    final frac = dot < 0 ? '' : text.substring(dot);
    return Semantics(
      label: hidden ? 'Hidden amount' : '$text EPIC',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: hidden
                      ? [const TextSpan(text: '••••••')]
                      : [TextSpan(text: whole), TextSpan(text: frac, style: TextStyle(color: c.dim))],
                ),
                style: ts.display.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('EPIC', style: ts.mono(size: Fs.md, color: c.dim, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Break extends StatelessWidget {
  const _Break({required this.label, required this.nano, this.lead, this.first = false, this.last = false});

  final String label;
  final int? nano;
  final Widget? lead;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final zero = nano == 0;
    return Expanded(
      child: Container(
        padding: EdgeInsets.fromLTRB(first ? Sp.x8 : Sp.x5, Sp.x4, Sp.x5, Sp.x4),
        decoration: BoxDecoration(border: last ? null : Border(right: BorderSide(color: c.line))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (lead != null) ...[lead!, const SizedBox(width: 6)],
                Flexible(child: Text(label, style: ts.small, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: Sp.x1),
            nano == null
                ? _Skeleton(width: 90, height: 16)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: EMoney(nano!, size: Fs.lg, unit: false, color: zero ? c.faint : c.text),
                  ),
          ],
        ),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  const _TracePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // The signal trace of the 700×26 original, stretched to the panel.
    final sx = size.width / 700;
    final pts = <Offset>[
      const Offset(0, 13), const Offset(150, 13), const Offset(156, 4), const Offset(164, 22), const Offset(172, 8),
      const Offset(178, 13), const Offset(368, 13), const Offset(374, 6), const Offset(380, 20), const Offset(386, 13),
      const Offset(700, 13),
    ];
    final path = Path()..moveTo(pts.first.dx * sx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx * sx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TracePainter old) => old.color != color;
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: context.dc.s3, borderRadius: BorderRadius.circular(Rad.xs)),
  );
}

class _Recent extends StatelessWidget {
  const _Recent({required this.txs, required this.onOpen, required this.onAll});

  final List<Tx>? txs;
  final ValueChanged<Tx> onOpen;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final list = txs;
    Widget body;
    if (list == null) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.x10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [const ESpinner(), const SizedBox(width: Sp.x3), Text('Loading transactions', style: context.ts.bodyDim)],
        ),
      );
    } else if (list.isEmpty) {
      body = Builder(
        builder: (context) => Consumer(
          builder: (context, ref, _) => EEmpty(
            icon: EIcons.receive,
            title: 'No transactions yet',
            text: 'Received EPIC shows here first as confirming, then as spendable after $minConfirmations blocks.',
            actions: [
              EButton.primary(label: 'Show address', onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.receive)),
              EButton.ghost(label: 'Receive a file', size: EBtnSize.md, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.importTx)),
            ],
          ),
        ),
      );
    } else {
      body = Column(
        children: [
          for (final (i, t) in list.take(5).indexed) ...[
            if (i > 0) Divider(height: 1, color: c.line),
            TxRow(tx: t, compact: true, onTap: () => onOpen(t)),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ESectionHead(
          'Recent activity',
          top: Sp.x6,
          trailing: list == null || list.isEmpty ? null : ELink(label: 'View all ${list.length}', onPressed: onAll),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.s1,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(Rad.sm),
          ),
          child: body,
        ),
      ],
    );
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard({required this.nodeDown});

  final bool nodeDown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.dc;
    final ts = context.ts;
    final st = ref.watch(deskProvider.select((s) => s.status));
    final nav = ref.read(deskNavProvider.notifier);
    final rows = st == null
        ? const <_SRow>[]
        : [
            _SRow(EIcons.node, 'Node', nodeDown ? ServiceHealth.down : st.nodeHealth, st.node.url.replaceFirst(RegExp(r'^https?://'), ''),
                sub: nodeDown ? 'Not answering' : 'Height ${st.nodeHeight}', mono: true),
            _SRow(EIcons.epicbox, 'Epicbox', st.epicboxHealth, st.epicbox.domain, mono: true),
            _SRow(EIcons.http, 'Direct HTTP', st.httpListener, st.httpListener == ServiceHealth.off ? '' : 'Port 3415'),
            _SRow(EIcons.tor, 'Tor', st.tor, st.tor == ServiceHealth.off ? '' : 'Onion service ready'),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ESectionHead('Status', top: Sp.x6),
        Container(
          decoration: BoxDecoration(color: c.s1, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
          padding: const EdgeInsets.symmetric(vertical: Sp.x2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (st == null)
                const Padding(padding: EdgeInsets.all(Sp.x6), child: Center(child: ESpinner()))
              else
                for (final r in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Sp.x5, vertical: Sp.x3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(r.icon, size: Ctl.icon, color: c.dim),
                              Positioned(right: -3, bottom: -2, child: EStatusDot(healthTone(r.health), size: 8)),
                            ],
                          ),
                        ),
                        const SizedBox(width: Sp.x3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(r.label, style: ts.strong)),
                                  Text(healthWord(r.health), style: ts.caption.copyWith(color: _toneColor(c, healthTone(r.health)))),
                                ],
                              ),
                              if (r.value.isNotEmpty) Text(r.value, style: r.mono ? ts.mono(size: Fs.xs, color: c.dim) : ts.small),
                              if (r.sub != null) Text(r.sub!, style: ts.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.x5, Sp.x2, Sp.x5, Sp.x3),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: EButton(
                    label: 'Receive options',
                    size: EBtnSize.sm,
                    onPressed: () => nav.go(DeskRoute.settingsReceiving),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Color _toneColor(DeskColors c, ETone t) => switch (t) {
  ETone.ok => c.ok,
  ETone.warn => c.warn,
  ETone.risk => c.risk,
  ETone.gold => c.accentText,
  ETone.neutral => c.faint,
};

class _SRow {
  const _SRow(this.icon, this.label, this.health, this.value, {this.sub, this.mono = false});

  final IconData icon;
  final String label;
  final ServiceHealth health;
  final String value;
  final String? sub;
  final bool mono;
}

class _PendingFiles extends ConsumerWidget {
  const _PendingFiles({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(top: Sp.x3),
    child: ENotice(
      tone: ETone.gold,
      icon: EIcons.file,
      title: count == 1 ? '1 file send open' : '$count file sends open',
      text: 'Finalize with the response file from the recipient.',
      actions: [
        EButton(
          label: 'Finalize',
          kind: EBtnKind.ghost,
          size: EBtnSize.inline,
          onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.finalize),
        ),
      ],
    ),
  );
}
