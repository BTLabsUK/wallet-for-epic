/// The Peers tab of the local node panel (spec §20): the connected peers in a fixed-column
/// table (eight rows, then "N more"), Ban on hover or focus, the banned list with Unban,
/// preferred peers and the two maxima (they apply at the next restart).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../builtin_node.dart' show isPeerAddress;
import '../../data/desk_node.dart';
import '../../data/node_view.dart' show hhmm, digits;
import '../../widgets/kit.dart';
import 'local_node.dart' show localNodeOptionsProvider;

/// `MW/Epic 4.1.1` → `4.1.1`; an unknown agent stays whole.
String peerVersion(String userAgent) {
  final m = RegExp(r'^MW/Epic\s+v?(\S+)$').firstMatch(userAgent.trim());
  return m?[1] ?? userAgent;
}

/// `BadBlock` → `bad block`.
String banReasonText(String reason) => reason.replaceAllMapped(RegExp(r'(?<=[a-z])([A-Z])'), (m) => ' ${m[1]}').toLowerCase().trim();


const int peerMaxMin = 8;
const int peerMaxMax = 500;
const int peerMaxDefault = 128;

/// Rows shown before "N more".
const int peersShown = 8;

class PeersTab extends ConsumerStatefulWidget {
  const PeersTab({super.key, required this.restartNeeded, this.onRestart});

  final bool restartNeeded;
  final VoidCallback? onRestart;

  @override
  ConsumerState<PeersTab> createState() => _PeersTabState();
}

class _PeersTabState extends ConsumerState<PeersTab> {
  bool _all = false;
  String? _hover;
  String? _focused;
  final _preferred = TextEditingController();
  String? _preferredError;
  final _maxIn = TextEditingController();
  final _maxOut = TextEditingController();
  String? _maxError;
  bool _filled = false;

  @override
  void dispose() {
    _preferred.dispose();
    _maxIn.dispose();
    _maxOut.dispose();
    super.dispose();
  }

  Future<void> _ban(String addr) async {
    await ref.read(deskNodeProvider).ban(addr);
    ref.invalidate(deskPeersProvider);
    if (mounted) showEToast(context, 'Peer banned', text: addr);
  }

  Future<void> _unban(String addr) async {
    await ref.read(deskNodeProvider).unban(addr);
    ref.invalidate(deskPeersProvider);
    if (mounted) showEToast(context, 'Peer unbanned', text: addr);
  }

  Future<void> _addPreferred(NodeTomlOptions o) async {
    final t = _preferred.text.trim();
    // The node's peers_preferred takes socket addresses only, no host names.
    if (!isPeerAddress(t)) {
      setState(() => _preferredError = 'Not an IP address and port, such as 203.0.113.5:3414.');
      return;
    }
    if (o.preferredPeers.contains(t)) {
      setState(() => _preferredError = 'Already preferred.');
      return;
    }
    await ref.read(deskNodeProvider).setPeerOptions(preferred: [...o.preferredPeers, t]);
    ref.invalidate(localNodeOptionsProvider);
    if (!mounted) return;
    setState(() {
      _preferredError = null;
      _preferred.clear();
    });
  }

  Future<void> _removePreferred(NodeTomlOptions o, String addr) async {
    await ref.read(deskNodeProvider).setPeerOptions(preferred: [for (final p in o.preferredPeers) if (p != addr) p]);
    ref.invalidate(localNodeOptionsProvider);
  }

  Future<void> _setMax(NodeTomlOptions o, {required bool inbound}) async {
    final t = (inbound ? _maxIn : _maxOut).text.trim();
    final n = int.tryParse(t);
    if (n == null || n < peerMaxMin || n > peerMaxMax) {
      setState(() => _maxError = '$peerMaxMin to $peerMaxMax.');
      return;
    }
    if (n == (inbound ? o.maxInbound : o.maxOutbound)) return;
    await ref.read(deskNodeProvider).setPeerOptions(maxInbound: inbound ? n : null, maxOutbound: inbound ? null : n);
    ref.invalidate(localNodeOptionsProvider);
    if (mounted) setState(() => _maxError = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final snap = ref.watch(deskPeersProvider).value;
    final options = ref.watch(localNodeOptionsProvider).value;
    if (options != null && !_filled) {
      _filled = true;
      _maxIn.text = '${options.maxInbound ?? peerMaxDefault}';
      _maxOut.text = '${options.maxOutbound ?? peerMaxDefault}';
    }
    final connected = snap?.connected ?? const <PeerView>[];
    final banned = snap?.banned ?? const <StoredPeer>[];
    final inbound = connected.where((p) => p.peer.direction == PeerDirection.inbound).length;
    final outbound = connected.where((p) => p.peer.direction == PeerDirection.outbound).length;
    final shown = connected.take(peersShown).toList();
    final rest = connected.skip(peersShown).toList();
    final more = _all ? 0 : rest.length;

    final summary = snap == null
        ? 'Reading the peers…'
        : '${connected.length} connected · $inbound in · $outbound out${banned.isNotEmpty ? ' · ${banned.length} banned' : ''}';

    Widget cell(String text, double width, {bool mono = false, TextAlign align = TextAlign.left, Color? color}) => SizedBox(
      width: width,
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: align, style: mono ? ts.mono(size: Fs.xs, color: color ?? c.dim) : ts.caption.copyWith(color: color ?? c.dim)),
    );

    Widget head(String text, double width, {TextAlign align = TextAlign.left}) => SizedBox(
      width: width,
      child: Text(text, textAlign: align, style: ts.caption.copyWith(color: c.faint, fontWeight: FontWeight.w600)),
    );

    Widget row(PeerView p) {
      final addr = p.peer.addr;
      final active = _hover == addr || _focused == addr;
      return Focus(
        onFocusChange: (f) => setState(() => _focused = f ? addr : (_focused == addr ? null : _focused)),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = addr),
          onExit: (_) => setState(() => _hover = _hover == addr ? null : _hover),
          child: Container(
            height: 36.u,
            padding: EdgeInsets.symmetric(horizontal: Sp.x2),
            decoration: BoxDecoration(color: active ? c.s2 : null, borderRadius: BorderRadius.circular(Rad.xs)),
            child: Row(
              children: [
                Expanded(child: Text(addr, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts.mono(size: Fs.sm, color: c.text))),
                SizedBox(width: Sp.x2),
                cell(switch (p.peer.direction) {
                  PeerDirection.inbound => 'in',
                  PeerDirection.outbound => 'out',
                  PeerDirection.unknown => '–',
                }, 70.u),
                cell(peerVersion(p.peer.userAgent), 70.u, mono: true),
                cell(digits(p.peer.height), 90.u, mono: true, align: TextAlign.right),
                SizedBox(width: Sp.x3),
                cell(p.firstSeen == null ? '–' : hhmm(p.firstSeen!), 80.u),
                SizedBox(
                  width: 70.u,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Opacity(
                      opacity: active ? 1 : 0,
                      child: EButton.ghost(label: 'Ban', icon: EIcons.cancel, size: EBtnSize.inline, onPressed: () => _ban(addr)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final table = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Sp.x2, vertical: Sp.x1),
          child: Row(
            children: [
              Expanded(child: head('Address', double.infinity)),
              SizedBox(width: Sp.x2),
              head('Direction', 70.u),
              head('Version', 70.u),
              head('Height', 90.u, align: TextAlign.right),
              SizedBox(width: Sp.x3),
              head('First seen', 80.u),
              SizedBox(width: 70.u),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: c.line),
        if (snap != null && connected.isEmpty)
          Padding(padding: EdgeInsets.all(Sp.x3), child: Text('No peers connected.', style: ts.small.copyWith(color: c.dim))),
        for (final p in shown) row(p),
        // The rest expands in place.
        ExpandFade(open: _all, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final p in rest) row(p)])),
        if (more > 0)
          InkWell(
            onTap: () => setState(() => _all = true),
            borderRadius: BorderRadius.circular(Rad.xs),
            child: SizedBox(
              height: 28.u,
              child: Center(child: Text('$more more', style: ts.caption.copyWith(color: c.accentText))),
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(summary, style: ts.small.copyWith(color: c.dim))),
            Text('Refreshed every 10 s', style: ts.caption.copyWith(color: c.faint)),
          ],
        ),
        ExpandFade(
          open: widget.restartNeeded,
          child: Padding(
            padding: EdgeInsets.only(top: Sp.x3),
            child: ENotice(
              tone: ETone.warn,
              title: 'Settings changed.',
              text: 'They apply at the next restart.',
              actions: [EButton(label: 'Restart now', size: EBtnSize.inline, onPressed: widget.onRestart)],
            ),
          ),
        ),
        SizedBox(height: Sp.x3),
        LayoutBuilder(
          builder: (context, box) => box.maxWidth < 600.u
              ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: 600.u, child: table))
              : table,
        ),
        if (banned.isNotEmpty) ...[
          SizedBox(height: Sp.x4),
          Text('BANNED', style: ts.caption.copyWith(fontSize: 11.u, letterSpacing: 0.6, fontWeight: FontWeight.w600, color: c.faint)),
          SizedBox(height: Sp.x1),
          for (final b in banned)
            SizedBox(
              height: 36.u,
              child: Row(
                children: [
                  SizedBox(width: Sp.x2),
                  Text(b.addr, style: ts.mono(size: Fs.sm, color: c.text)),
                  SizedBox(width: Sp.x3),
                  Expanded(
                    child: Text(
                      [if (b.lastBanned != null) 'banned ${hhmm(b.lastBanned!)}', if (b.banReason.isNotEmpty) banReasonText(b.banReason)].join(' · '),
                      style: ts.caption.copyWith(color: c.dim),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  EButton.ghost(label: 'Unban', size: EBtnSize.inline, onPressed: () => _unban(b.addr)),
                ],
              ),
            ),
        ],
        SizedBox(height: Sp.x4),
        Divider(height: 1, thickness: 1, color: c.line),
        SizedBox(height: Sp.x3),
        Wrap(
          spacing: Sp.x4,
          runSpacing: Sp.x3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Preferred peers', style: ts.small),
            SizedBox(
              width: 220.u,
              child: EInput(
                controller: _preferred,
                hint: 'ip:port',
                mono: true,
                invalid: _preferredError != null,
                semanticLabel: 'Preferred peer, IP address and port',
                onChanged: (_) => _preferredError == null ? null : setState(() => _preferredError = null),
                onSubmitted: (_) => options == null ? null : _addPreferred(options),
              ),
            ),
            EButton(label: 'Add', size: EBtnSize.inline, onPressed: options == null ? null : () => _addPreferred(options)),
            Text('Max incoming', style: ts.small),
            SizedBox(
              width: 64.u,
              // Saved on Enter and when the field loses focus.
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onFocusChange: (f) => f || options == null ? null : _setMax(options, inbound: true),
                child: EInput(
                  controller: _maxIn,
                  mono: true,
                  invalid: _maxError != null,
                  semanticLabel: 'Max incoming peers',
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => options == null ? null : _setMax(options, inbound: true),
                ),
              ),
            ),
            Text('Max outgoing', style: ts.small),
            SizedBox(
              width: 64.u,
              // Saved on Enter and when the field loses focus.
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onFocusChange: (f) => f || options == null ? null : _setMax(options, inbound: false),
                child: EInput(
                  controller: _maxOut,
                  mono: true,
                  invalid: _maxError != null,
                  semanticLabel: 'Max outgoing peers',
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => options == null ? null : _setMax(options, inbound: false),
                ),
              ),
            ),
          ],
        ),
        if (_preferredError != null || _maxError != null) ...[
          SizedBox(height: Sp.x1),
          Text(_preferredError ?? _maxError!, style: ts.caption.copyWith(color: c.risk)),
        ],
        if (options != null && options.preferredPeers.isNotEmpty) ...[
          SizedBox(height: Sp.x2),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${options.preferredPeers.length} preferred:', style: ts.caption),
              for (final p in options.preferredPeers)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p, style: ts.mono(size: Fs.xs, color: c.dim)),
                    EIconButton(icon: EIcons.close, label: 'Forget $p', size: EBtnSize.inline, tabStop: false, onPressed: () => _removePreferred(options, p)),
                  ],
                ),
            ],
          ),
        ],
        SizedBox(height: Sp.x3),
        Text(
          'First seen is when this app first saw the peer connected, this session; the node does not report when a connection began. Ban and unban use the node’s owner API. Enter saves a maximum ($peerMaxMin to $peerMaxMax, $peerMaxDefault by default).',
          style: ts.caption.copyWith(color: c.faint),
        ),
      ],
    );
  }
}
