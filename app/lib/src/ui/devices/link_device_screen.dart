// SPDX-License-Identifier: Apache-2.0
/// Link a device (phone): one device shows a code, the other scans or pastes it; both compare
/// four pictures and tap They match. Nothing is linked until both did, and the two must hold the
/// same wallet (`devices/device_service.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/device_link_code.dart';
import '../../devices/device_service.dart';
import '../../devices/phone_devices.dart';
import '../../l10n.dart';
import '../../pairing_api.dart' show privateInviteExpiry;
import '../common.dart';
import '../pairing/pairing_parts.dart';
import '../scan_screen.dart' show qrScannerProvider;
import '../theme/brand.dart';
import '../theme/tokens.dart';
import 'device_parts.dart';

const Key linkShowKey = ValueKey('link-show');
const Key linkScanKey = ValueKey('link-scan');
const Key linkPasteFieldKey = ValueKey('link-paste-field');
const Key linkPasteKey = ValueKey('link-paste');
const Key linkMatchKey = ValueKey('link-match');
const Key linkNoMatchKey = ValueKey('link-no-match');
const Key linkServersKey = ValueKey('link-servers');

class LinkDeviceScreen extends ConsumerStatefulWidget {
  const LinkDeviceScreen({super.key, this.code});

  /// A device link text from a scan or a paste elsewhere: answered at once.
  final String? code;

  @override
  ConsumerState<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends ConsumerState<LinkDeviceScreen> {
  final _paste = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final code = widget.code;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final service = ref.read(deviceServiceProvider);
      // A flow left from an earlier visit that ended is not this one.
      service?.closeLink();
      if (code != null) service?.startScanned(code);
    });
  }

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  DeviceService? get _service => ref.read(deviceServiceProvider);

  Future<void> _run(Future<void> Function(DeviceService s) call) async {
    final s = _service;
    if (s == null || _busy) return;
    setState(() => _busy = true);
    try {
      await call(s);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scan() async {
    final text = await ref.read(qrScannerProvider).scan(context);
    if (text == null || !mounted) return;
    await _run((s) => s.startScanned(text));
  }

  Future<void> _pasteNow() async {
    var text = _paste.text.trim();
    if (text.isEmpty) text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
    if (text.isEmpty || !mounted) return;
    await _run((s) => s.startScanned(text));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final view = ref.watch(phoneDevices.view);
    final flow = view?.link;
    final active = flow != null && flow.phase != LinkPhase.done && flow.phase != LinkPhase.failed;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        // Leaving mid-way ends the link on both sides; a finished one stays.
        if (didPop && active) _service?.cancelLink();
        if (didPop && !active) _service?.closeLink();
      },
      child: SlotScaffold(
        appBar: AppBar(title: Text(l.devicesLink)),
        idle: active && flow.phase != LinkPhase.checking ? SlotProgress(label: l.linkWaiting) : null,
        body: switch (flow) {
          _ when view == null || !view.supported => _message(context, l.devicesUnsupported),
          null => _start(context),
          LinkFlow(phase: LinkPhase.starting) => const SizedBox.shrink(),
          LinkFlow(phase: LinkPhase.waiting, role: LinkRole.shows) => _showCode(context, flow),
          LinkFlow(phase: LinkPhase.waiting, otherName: final name?) => _message(context, l.linkWaitingFor(name)),
          LinkFlow(phase: LinkPhase.waiting) => _message(context, l.linkWaiting),
          LinkFlow(phase: LinkPhase.checking || LinkPhase.waitingOther) => _check(context, flow),
          LinkFlow(phase: LinkPhase.done) => _done(context, flow),
          LinkFlow(phase: LinkPhase.failed) => _failed(context, flow),
        },
      ),
    );
  }

  Widget _message(BuildContext context, String text) => ScreenBody(children: [PairLead(text)]);

  Widget _start(BuildContext context) {
    final l = context.l10n;
    final servers = phoneLinkServers(ref);
    final scanner = ref.watch(qrScannerProvider);
    return ScreenBody(
      children: [
        PairLead(l.linkLead),
        const SizedBox(height: 16),
        PairCard(
          children: [
            ListTile(
              key: linkServersKey,
              leading: const Icon(Icons.dns_outlined),
              title: Text(l.devicesServers),
              // Read-only: the first servers of the Epicbox list (Settings › Epicbox).
              subtitle: Text(servers.join(', ')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: linkShowKey,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.qr_code_2),
          label: Text(l.linkShow),
          onPressed: _busy || servers.isEmpty ? null : () => _run((s) => s.startShowing(servers)),
        ),
        if (scanner.supported) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: linkScanKey,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l.linkScan),
            onPressed: _busy ? null : _scan,
          ),
        ],
        PairSection(l.linkPaste),
        TextField(
          key: linkPasteFieldKey,
          controller: _paste,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(labelText: l.linkPasteLabel, border: const OutlineInputBorder()),
          onSubmitted: (_) => _pasteNow(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(key: linkPasteKey, onPressed: _busy ? null : _pasteNow, child: Text(l.linkGo)),
        ),
      ],
    );
  }

  Widget _showCode(BuildContext context, LinkFlow flow) {
    final l = context.l10n;
    final t = context.tokens;
    final code = flow.code ?? '';
    final width = MediaQuery.sizeOf(context).width;
    final size = (width - 96).clamp(180.0, 260.0);
    return ScreenBody(
      children: [
        PairLead(l.linkShowLead),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: protocolLight.surface, borderRadius: BorderRadius.circular(t.radiusSmall)),
            child: Semantics(label: l.linkPasteLabel, image: true, child: MarkedQr(data: code, size: size)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.copy),
            label: Text(l.linkCopy),
            onPressed: () => copySecretText(context, code, l.linkCopied),
          ),
        ),
        const SizedBox(height: 12),
        PairSmallPrint(l.linkExpires(privateInviteExpiry.inMinutes)),
        const SizedBox(height: 4),
        PairSmallPrint(l.linkWaiting),
      ],
    );
  }

  Widget _check(BuildContext context, LinkFlow flow) {
    final l = context.l10n;
    final name = flow.otherName ?? '';
    final waiting = flow.phase == LinkPhase.waitingOther;
    return ScreenBody(
      bottom: waiting
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  key: linkMatchKey,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: _busy ? null : () => _run((s) => s.answerCheck(true)),
                  child: Text(l.sasMatch),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: linkNoMatchKey,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: _busy ? null : () => _run((s) => s.answerCheck(false)),
                  child: Text(l.sasNoMatch),
                ),
              ],
            ),
      children: [
        Text(l.linkCheckTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: context.tokens.headFamily)),
        const SizedBox(height: 8),
        PairLead(l.linkCheckLead(name)),
        const SizedBox(height: 16),
        PairCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
              child: WordTiles(words: flow.sas, label: l.linkPicturesLabel, size: WordTileSize.check, dim: waiting),
            ),
          ],
        ),
        if (waiting) ...[const SizedBox(height: 16), PairLead(l.linkWaitingCheck(name))],
      ],
    );
  }

  Widget _done(BuildContext context, LinkFlow flow) {
    final l = context.l10n;
    final t = context.tokens;
    return ScreenBody(
      bottom: FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: () => Navigator.of(context).maybePop(),
        child: Text(l.commonDone),
      ),
      children: [
        Icon(Icons.check_circle_outline, size: 48, color: t.ok),
        const SizedBox(height: 12),
        Text(l.linkDoneTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: t.headFamily)),
        const SizedBox(height: 8),
        PairLead(l.linkDone(flow.device?.name ?? flow.otherName ?? '')),
        const SizedBox(height: 16),
        const RelayClashNotice(),
      ],
    );
  }

  Widget _failed(BuildContext context, LinkFlow flow) {
    final l = context.l10n;
    final t = context.tokens;
    final linked = flow.failure == LinkFailure.tooMany ? _service?.book.devices.firstOrNull : null;
    return ScreenBody(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Two devices at most: a refused link offers to remove the one linked, not to try again.
          if (linked != null)
            FilledButton(
              key: linkRemoveKey,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () async {
                final yes = await confirmDeviceAction(
                  context,
                  title: l.devicesRemoveTitle(linked.name),
                  body: l.devicesRemoveBody(linked.name),
                  action: l.devicesRemove,
                  risky: true,
                );
                if (!yes || !context.mounted) return;
                await _service?.removeDevice(linked.deviceId);
                if (context.mounted) await Navigator.of(context).maybePop();
              },
              child: Text(l.devicesRemove),
            )
          else if (flow.failure != LinkFailure.tooMany)
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => _service?.closeLink(),
              child: Text(l.linkTryAgain),
            ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.of(context).maybePop(), child: Text(l.commonClose)),
        ],
      ),
      children: [
        Icon(Icons.link_off, size: 48, color: t.warn),
        const SizedBox(height: 12),
        Text(l.linkFailedTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: t.headFamily)),
        const SizedBox(height: 8),
        PairLead(linkFailureText(l, flow.failure ?? LinkFailure.cancelled)),
      ],
    );
  }
}

/// Whether [text] is a device link: the scan and paste routes hand it to Link a device.
bool isDeviceLink(String text) => isDeviceLinkText(text);
