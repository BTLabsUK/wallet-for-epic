// SPDX-License-Identifier: Apache-2.0
/// The Peers tab of the local node panel: the connected peers in a fixed-column
/// table (eight rows, then "N more"), Ban on hover or focus, the banned list with Unban,
/// preferred peers and the two maxima (they apply at the next restart). For an own node with
/// owner access ([PeersTab.ownUrl]) the same table and lists through its owner API; its peer
/// settings stay on the node's own computer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../desk_l10n.dart';
import '../../../builtin_node.dart' show isPeerAddress;
import '../../data/desk_node.dart';
import '../../data/node_view.dart' show hhmm, digits;
import '../../widgets/kit.dart';
import '../../../settings_file/host_settings.dart' show appConfig;
import 'local_node.dart' show localNodeOptionsProvider, localNodeHelp;
import 'own_node_panel.dart' show ownAskEvery;

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
  const PeersTab({super.key, required this.restartNeeded, this.onRestart, this.ownUrl});

  final bool restartNeeded;
  final VoidCallback? onRestart;

  /// An own node's URL: its peers, not the built-in node's.
  final String? ownUrl;

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

  /// The last maximum sent for each field: Enter and then the focus loss are one save, and the
  /// options in hand are older than it until the provider reloads.
  int? _sentIn;
  int? _sentOut;
  bool _filled = false;

  @override
  void dispose() {
    _preferred.dispose();
    _maxIn.dispose();
    _maxOut.dispose();
    super.dispose();
  }

  Future<void> _ban(String addr) async {
    final l = context.l10n;
    final own = widget.ownUrl;
    own == null ? await ref.read(deskNodeProvider).ban(addr) : await ref.read(deskNodeProvider).ownBan(own, addr);
    _reload();
    if (mounted) showEToast(context, l.deskSetPeersBannedToast, text: addr, tone: ETone.ok);
  }

  Future<void> _unban(String addr) async {
    final l = context.l10n;
    final own = widget.ownUrl;
    own == null ? await ref.read(deskNodeProvider).unban(addr) : await ref.read(deskNodeProvider).ownUnban(own, addr);
    _reload();
    if (mounted) showEToast(context, l.deskSetPeersUnbannedToast, text: addr, tone: ETone.ok);
  }

  void _reload() {
    final own = widget.ownUrl;
    own == null ? ref.invalidate(deskPeersProvider) : ref.invalidate(deskOwnPeersProvider(own));
  }

  Future<void> _addPreferred(NodeTomlOptions o) async {
    final l = context.l10n;
    final t = _preferred.text.trim();
    // The node's peers_preferred takes socket addresses only, no host names.
    if (!isPeerAddress(t)) {
      setState(() => _preferredError = l.deskSetPeersNotAddress('${appConfig.localNodeP2pPort}'));
      return;
    }
    if (o.preferredPeers.contains(t)) {
      setState(() => _preferredError = l.deskSetPeersAlreadyPreferred);
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
    final l = context.l10n;
    final t = (inbound ? _maxIn : _maxOut).text.trim();
    final n = int.tryParse(t);
    if (n == null || n < peerMaxMin || n > peerMaxMax) {
      setState(() => _maxError = l.deskSetPeersMaxRange(peerMaxMin, peerMaxMax));
      return;
    }
    if (n == (inbound ? _sentIn ?? o.maxInbound : _sentOut ?? o.maxOutbound)) return;
    if (inbound) {
      _sentIn = n;
    } else {
      _sentOut = n;
    }
    try {
      await ref.read(deskNodeProvider).setPeerOptions(maxInbound: inbound ? n : null, maxOutbound: inbound ? null : n);
    } on Object {
      if (inbound) {
        _sentIn = null;
      } else {
        _sentOut = null;
      }
      rethrow;
    }
    ref.invalidate(localNodeOptionsProvider);
    if (mounted) setState(() => _maxError = null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final own = widget.ownUrl;
    final snap = own == null ? ref.watch(deskPeersProvider).value : ref.watch(deskOwnPeersProvider(own)).value;
    final options = own == null ? ref.watch(localNodeOptionsProvider).value : null;
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
        ? l.deskSetPeersReading
        : banned.isNotEmpty
        ? l.deskSetPeersSummaryBanned(connected.length, inbound, outbound, banned.length)
        : l.deskSetPeersSummary(connected.length, inbound, outbound);

    Widget cell(String text, double width, {bool mono = false, TextAlign align = TextAlign.left, Color? color}) => SizedBox(
      width: width,
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: align, style: mono ? ts.mono(size: Fs.xs, color: color ?? c.dim) : ts.caption.copyWith(color: color ?? c.dim)),
    );

    Widget head(String text, double width, {TextAlign align = TextAlign.left, String? hint}) => SizedBox(
      width: width,
      child: hint == null
          ? Text(text, textAlign: align, style: ts.caption.copyWith(color: c.faint, fontWeight: FontWeight.w600))
          : Row(
              children: [
                // Wraps rather than cut: a column name is read whole ("First seen").
                Flexible(child: Text(text, style: ts.caption.copyWith(color: c.faint, fontWeight: FontWeight.w600))),
                SizedBox(width: Sp.x1),
                EInfoHint(hint, onHelp: localNodeHelp(ref)),
              ],
            ),
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
                  PeerDirection.inbound => l.deskSetPeersIn,
                  PeerDirection.outbound => l.deskSetPeersOut,
                  PeerDirection.unknown => '–',
                }, 70.u),
                cell(peerVersion(p.peer.userAgent), 70.u, mono: true),
                cell(digits(context.l10n, p.peer.height), 90.u, mono: true, align: TextAlign.right),
                SizedBox(width: Sp.x3),
                cell(p.firstSeen == null ? '–' : hhmm(p.firstSeen!), _firstSeenW),
                SizedBox(
                  width: 70.u,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Opacity(
                      opacity: active ? 1 : 0,
                      child: EButton.ghost(label: l.deskSetPeersBan, icon: EIcons.cancel, size: EBtnSize.inline, onPressed: () => _ban(addr)),
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
              Expanded(child: head(l.deskSetPeersColAddress, double.infinity)),
              SizedBox(width: Sp.x2),
              head(l.deskSetPeersColDirection, 70.u),
              head(l.deskSetPeersColVersion, 70.u),
              head(l.deskSetPeersColHeight, 90.u, align: TextAlign.right),
              SizedBox(width: Sp.x3),
              head(l.deskSetPeersColFirstSeen, _firstSeenW, hint: l.deskSetPeersFirstSeenHint),
              SizedBox(width: 70.u),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: c.line),
        if (snap != null && connected.isEmpty)
          Padding(padding: EdgeInsets.all(Sp.x3), child: Text(l.deskSetPeersNone, style: ts.small.copyWith(color: c.dim))),
        for (final p in shown) row(p),
        // The rest expands in place.
        ExpandFade(open: _all, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final p in rest) row(p)])),
        if (more > 0)
          EInkWell(
            onTap: () => setState(() => _all = true),
            borderRadius: BorderRadius.circular(Rad.xs),
            child: SizedBox(
              height: 28.u,
              child: Center(child: Text(l.deskSetPeersMore(more), style: ts.caption.copyWith(color: c.accentText))),
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
            Text(l.deskSetPeersRefreshed(widget.ownUrl == null ? 10 : ownAskEvery.inSeconds), style: ts.caption.copyWith(color: c.faint)),
          ],
        ),
        ExpandFade(
          open: widget.restartNeeded,
          child: Padding(
            padding: EdgeInsets.only(top: Sp.x3),
            child: ENotice(
              tone: ETone.warn,
              title: l.deskSetLnodeSettingsChanged,
              text: l.deskSetLnodeSettingsChangedText,
              // Restart is the page header's: each action once.
            ),
          ),
        ),
        SizedBox(height: Sp.x3),
        LayoutBuilder(
          builder: (context, box) => box.maxWidth < Lay.md
              ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: 600.u, child: table))
              : table,
        ),
        if (banned.isNotEmpty) ...[
          SizedBox(height: Sp.x4),
          Text(l.deskSetPeersBanned.toUpperCase(), style: ts.caption.copyWith(fontSize: 11.u, letterSpacing: 0.6, fontWeight: FontWeight.w600, color: c.faint)),
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
                      metaLine([if (b.lastBanned != null) l.deskSetPeersBannedAt(hhmm(b.lastBanned!)), if (b.banReason.isNotEmpty) banReasonText(b.banReason)]),
                      style: ts.caption.copyWith(color: c.dim),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  EButton.ghost(label: l.deskSetPeersUnban, size: EBtnSize.inline, onPressed: () => _unban(b.addr)),
                ],
              ),
            ),
        ],
        if (own == null) ...[
        SizedBox(height: Sp.x4),
        Divider(height: 1, thickness: 1, color: c.line),
        SizedBox(height: Sp.x3),
        Wrap(
          spacing: Sp.x4,
          runSpacing: Sp.x3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l.deskSetPeersPreferred, style: ts.small),
            SizedBox(
              width: 220.u,
              child: EInput(
                controller: _preferred,
                hint: 'ip:port', // l10n-ok: address format
                mono: true,
                invalid: _preferredError != null,
                semanticLabel: l.deskSetPeersPreferredLabel,
                onChanged: (_) => _preferredError == null ? null : setState(() => _preferredError = null),
                onSubmitted: (_) => options == null ? null : _addPreferred(options),
              ),
            ),
            EButton(label: l.deskSetPeersAdd, size: EBtnSize.inline, onPressed: options == null ? null : () => _addPreferred(options)),
            Text(l.deskSetPeersMaxIn, style: ts.small),
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
                  semanticLabel: l.deskSetPeersMaxInLabel,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => options == null ? null : _setMax(options, inbound: true),
                ),
              ),
            ),
            Text(l.deskSetPeersMaxOut, style: ts.small),
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
                  semanticLabel: l.deskSetPeersMaxOutLabel,
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
              Text(l.deskSetPeersPreferredCount(options.preferredPeers.length), style: ts.caption),
              for (final p in options.preferredPeers)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p, style: ts.mono(size: Fs.xs, color: c.dim)),
                    EIconButton(icon: EIcons.close, label: l.deskSetPeersForget(p), size: EBtnSize.inline, tabStop: false, onPressed: () => _removePreferred(options, p)),
                  ],
                ),
            ],
          ),
        ],
        SizedBox(height: Sp.x3),
        Text(
          l.deskSetPeersNote(peerMaxMin, peerMaxMax, peerMaxDefault),
          style: ts.caption.copyWith(color: c.faint),
        ),
        ],
      ],
    );
  }
}

/// The First seen column: its name and the ⓘ beside it whole at the reference widths.
double get _firstSeenW => 104.u;
