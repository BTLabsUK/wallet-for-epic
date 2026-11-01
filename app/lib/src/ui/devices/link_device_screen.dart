// SPDX-License-Identifier: Apache-2.0
/// Link a device (phone): the camera opens first; Show my code and Paste code are the other
/// ways. Once both devices are paired each shows the four pictures as "Linking…" while the
/// hellos cross (nothing to tap: the proof needs the recovery phrase), then "Linked" closes by
/// itself (`devices/device_service.dart`).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/device_service.dart';
import '../../devices/invite_links_api.dart';
import '../../devices/phone_devices.dart';
import '../../l10n.dart';
import '../../settings.dart' show autoLockHoldProvider, clockProvider;
import '../common.dart';
import '../pairing/pairing_parts.dart';
import '../scan_screen.dart' show ScanCode, qrScannerProvider;
import '../theme/brand.dart';
import '../theme/tokens.dart';
import 'device_parts.dart';

const Key linkShowKey = ValueKey('link-show');
const Key linkScanKey = ValueKey('link-scan');
const Key linkPasteFieldKey = ValueKey('link-paste-field');
const Key linkPasteKey = ValueKey('link-paste');
const Key linkPasteOpenKey = ValueKey('link-paste-open');
const Key linkCancelKey = ValueKey('link-cancel');
const Key linkReplaceKey = ValueKey('link-replace');
const Key linkRetryKey = ValueKey('link-retry');
const Key linkPasteAnotherKey = ValueKey('link-paste-another');
const Key linkConfirmKey = ValueKey('link-confirm');

class LinkDeviceScreen extends ConsumerStatefulWidget {
  const LinkDeviceScreen({super.key, this.code, this.openCamera = true, this.confirm = false});

  /// A device invite from a scan or a paste elsewhere: answered at once, or, with [confirm]
  /// (it came in as a link), once the user chose to.
  final String? code;

  /// The invite came in as a link: ask before answering it. A link never links by itself.
  final bool confirm;

  /// Opens the camera first (where the phone scans); the tour and tests start on the choices.
  final bool openCamera;

  @override
  ConsumerState<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends ConsumerState<LinkDeviceScreen> {
  final _paste = TextEditingController();
  bool _busy = false;
  bool _pasting = false;

  /// An invite that came in as a link, waiting for the user's Link.
  String? _toConfirm;
  Timer? _tick;
  Timer? _close;
  Completer<void>? _hold;

  @override
  void initState() {
    super.initState();
    final code = widget.code;
    // A link under way holds auto-lock, as a scan does: the user may switch to a messenger to
    // send the code. Released when the screen goes.
    final hold = Completer<void>();
    _hold = hold;
    // The minutes left on the invite, and the auto-close, follow the clock.
    _tick = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Taken after the first frame: a provider is not changed while the tree builds.
      unawaited(ref.read(autoLockHoldProvider.notifier).during(() => hold.future));
      final service = ref.read(deviceServiceProvider);
      // A flow left from an earlier visit that ended is not this one.
      service?.closeLink();
      if (code != null && widget.confirm) {
        setState(() => _toConfirm = code);
      } else if (code != null) {
        unawaited(_run((s) => s.startScanned(code)));
      } else if (widget.openCamera && ref.read(qrScannerProvider).supported) {
        unawaited(_scan());
      }
    });
  }

  @override
  void dispose() {
    _paste.dispose();
    _tick?.cancel();
    _close?.cancel();
    _hold?.complete();
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

  /// The invite in [text], in any of its forms (a link, the bare text), as the service reads it.
  String _invite(String text) => parseInvite(text)?.invite ?? text;

  Future<void> _scan() async {
    final text = await ref.read(qrScannerProvider).scanCode(context);
    if (text == null || !mounted) return;
    await _run((s) => s.startScanned(_invite(text)));
  }

  Future<void> _pasteNow() async {
    var text = _paste.text.trim();
    if (text.isEmpty) text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
    if (text.isEmpty || !mounted) return;
    await _run((s) => s.startScanned(_invite(text)));
  }

  Future<void> _cancel() async {
    await _service?.cancelLink();
    if (mounted) await Navigator.of(context).maybePop();
  }

  /// "Linked" closes by itself after [linkDoneShown].
  void _closeSoon() {
    _close ??= Timer(linkDoneShown, () {
      if (!mounted) return;
      _service?.closeLink();
      Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final view = ref.watch(phoneDevices.view);
    final flow = view?.link;
    final active = flow != null && flow.phase != LinkPhase.done && flow.phase != LinkPhase.failed;
    if (flow?.phase == LinkPhase.done) _closeSoon();
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        // Leaving mid-way ends the link on both sides; a finished one stays.
        if (didPop && active) _service?.cancelLink();
        if (didPop && !active) _service?.closeLink();
      },
      child: SlotScaffold(
        appBar: AppBar(title: Text(l.devicesLink)),
        idle: active && flow.phase != LinkPhase.linking ? const SlotProgress(label: '') : null,
        body: switch (flow) {
          _ when view == null || !view.supported => _message(context, l.devicesUnsupported),
          null when _toConfirm != null => _confirm(context, _toConfirm!),
          null => _start(context),
          LinkFlow(phase: LinkPhase.starting) => _wait(context, null),
          LinkFlow(phase: LinkPhase.waiting, role: LinkRole.shows) => _showCode(context, flow),
          LinkFlow(phase: LinkPhase.waiting, otherName: final name?) => _wait(context, l.linkWaitingFor(name)),
          LinkFlow(phase: LinkPhase.waiting) => _wait(context, l.linkWaiting),
          LinkFlow(phase: LinkPhase.linking) => _linking(context, flow),
          LinkFlow(phase: LinkPhase.done) => _done(context, flow),
          LinkFlow(phase: LinkPhase.failed) => _failed(context, flow),
        },
      ),
    );
  }

  Widget _message(BuildContext context, String text) => ScreenBody(children: [PairLead(text)]);

  /// An invite that came in as a link: the user chooses to answer it.
  Widget _confirm(BuildContext context, String invite) {
    final l = context.l10n;
    return ScreenBody(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            key: linkConfirmKey,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy
                ? null
                : () {
                    setState(() => _toConfirm = null);
                    unawaited(_run((s) => s.startScanned(_invite(invite))));
                  },
            child: Text(l.linkGo),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.of(context).maybePop(), child: Text(l.commonCancel)),
        ],
      ),
      children: [PairLead(l.linkConfirmInvite)],
    );
  }

  Widget _cancelButton(BuildContext context) => OutlinedButton(
    key: linkCancelKey,
    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    onPressed: _cancel,
    child: Text(context.l10n.commonCancel),
  );

  /// A wait with a Cancel: answering, or the other device's turn.
  Widget _wait(BuildContext context, String? text) => ScreenBody(
    bottom: _cancelButton(context),
    children: [if (text != null) PairLead(text)],
  );

  Widget _start(BuildContext context) {
    final l = context.l10n;
    final servers = phoneLinkServers(ref);
    final scanner = ref.watch(qrScannerProvider);
    return ScreenBody(
      children: [
        PairLead(l.linkLead),
        const SizedBox(height: 16),
        if (scanner.supported) ...[
          FilledButton.icon(
            key: linkScanKey,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l.linkScan),
            onPressed: _busy ? null : _scan,
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            TextButton.icon(
              key: linkShowKey,
              icon: const Icon(Icons.qr_code_2),
              label: Text(l.linkShowMine),
              onPressed: _busy || servers.isEmpty ? null : () => _run((s) => s.startShowing(servers)),
            ),
            TextButton.icon(
              key: linkPasteOpenKey,
              icon: const Icon(Icons.content_paste),
              label: Text(l.linkPaste),
              onPressed: _busy ? null : () => setState(() => _pasting = true),
            ),
          ],
        ),
        if (_pasting) ...[
          const SizedBox(height: 8),
          TextField(
            key: linkPasteFieldKey,
            controller: _paste,
            maxLines: 2,
            minLines: 1,
            autofocus: true,
            decoration: InputDecoration(labelText: l.linkPasteLabel, border: const OutlineInputBorder()),
            onSubmitted: (_) => _pasteNow(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(key: linkPasteKey, onPressed: _busy ? null : _pasteNow, child: Text(l.linkGo)),
          ),
        ],
      ],
    );
  }

  Widget _showCode(BuildContext context, LinkFlow flow) {
    final l = context.l10n;
    final t = context.tokens;
    // The QR and Copy carry the invite as a link when the invite page is set, else bare.
    final code = inviteShareText(InviteLink(InviteKind.deviceLink, flow.code ?? ''), invitePage: ref.watch(invitePageProvider));
    final width = MediaQuery.sizeOf(context).width;
    final size = (width - 96).clamp(180.0, 260.0);
    final until = flow.expiresAt;
    return ScreenBody(
      bottom: _cancelButton(context),
      children: [
        const SizedBox(height: 8),
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
        if (until != null) PairSmallPrint(l.linkExpires(linkMinutesLeft(until, ref.read(clockProvider)()))),
        const SizedBox(height: 4),
        PairSmallPrint(l.linkWaiting),
      ],
    );
  }

  /// Both devices show the same four pictures while the hellos cross. Nothing to tap.
  Widget _linking(BuildContext context, LinkFlow flow) {
    final l = context.l10n;
    final name = flow.otherName ?? '';
    return ScreenBody(
      bottom: _cancelButton(context),
      children: [
        Text(l.linkLinkingWith(name), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontFamily: context.tokens.headFamily)),
        const SizedBox(height: 16),
        PairCard(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
              child: WordTiles(words: flow.sas, label: l.linkPicturesLabel, size: WordTileSize.check),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PairSmallPrint(l.linkLinkingSame(name)),
      ],
    );
  }

  Widget _done(BuildContext context, LinkFlow flow) {
    final l = context.l10n;
    final t = context.tokens;
    return ScreenBody(
      children: [
        Icon(Icons.check_circle_outline, size: 48, color: t.ok),
        const SizedBox(height: 12),
        Text(l.linkDone(flow.device?.name ?? flow.otherName ?? ''), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: t.headFamily)),
      ],
    );
  }

  Widget _failed(BuildContext context, LinkFlow flow) {
    final l = context.l10n;
    final t = context.tokens;
    final failure = flow.failure ?? LinkFailure.unreachable;
    final linked = failure == LinkFailure.tooMany ? _service?.book.linked : null;
    // A pasted code that failed: another one can be pasted. A code this device showed that
    // went nowhere: a new one.
    final pasted = flow.role == LinkRole.scans && _pasting;
    final retry = !pasted && (failure == LinkFailure.unreachable || failure == LinkFailure.cancelled || failure == LinkFailure.expired || failure == LinkFailure.notFound);
    return ScreenBody(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Two devices at most: a refused link offers to replace the one linked.
          if (linked != null)
            FilledButton(
              key: linkReplaceKey,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () async {
                final yes = await confirmDeviceAction(
                  context,
                  title: l.linkReplaceTitle(linked.name),
                  body: l.linkReplaceBody(linked.name),
                  action: l.linkReplace,
                  cancel: l.linkKeep(linked.name),
                  risky: true,
                );
                if (!yes || !context.mounted) return;
                await _run((s) => s.replaceLinked());
              },
              child: Text(l.linkReplaceTitle(linked.name)),
            )
          else if (pasted)
            FilledButton(
              key: linkPasteAnotherKey,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                _service?.closeLink();
                setState(() => _paste.clear());
              },
              child: Text(l.linkPasteAnother),
            )
          else if (retry)
            FilledButton(
              key: linkRetryKey,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                _service?.closeLink();
                if (flow.role == LinkRole.shows && flow.servers.isNotEmpty) {
                  unawaited(_run((s) => s.startShowing(flow.servers)));
                } else if (ref.read(qrScannerProvider).supported) {
                  unawaited(_scan());
                }
              },
              child: Text(l.commonRetry),
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
        PairLead(linkFailureText(l, failure, flow.otherName)),
      ],
    );
  }
}
