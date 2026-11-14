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
import '../kit/kit_button.dart';
import '../kit/kit_chip.dart';
import '../kit/kit_group.dart';
import '../kit/kit_icons.dart';
import '../kit/kit_row.dart';
import '../kit/kit_tokens.dart';
import '../pairing/pair_flow.dart';
import '../pairing/pairing_parts.dart' show WordTileSize, WordTiles;
import '../scan_screen.dart' show ScanCode, qrScannerProvider;
import '../../trust_ids.dart';
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
const Key linkCopyKey = ValueKey('link-copy');

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
    final (:children, :bottom) = switch (flow) {
      _ when view == null || !view.supported => (children: [PairNote(l.devicesUnsupported)], bottom: null),
      null when _toConfirm != null => _confirm(context, _toConfirm!),
      null => _start(context),
      LinkFlow(phase: LinkPhase.starting) => _wait(context, null),
      LinkFlow(phase: LinkPhase.waiting, role: LinkRole.shows) => _showCode(context, flow),
      LinkFlow(phase: LinkPhase.waiting, otherName: final name?) => _wait(context, l.linkWaitingFor(name)),
      LinkFlow(phase: LinkPhase.waiting) => _wait(context, l.linkWaiting),
      LinkFlow(phase: LinkPhase.linking) => _linking(context, flow),
      LinkFlow(phase: LinkPhase.done) => _done(context, flow),
      LinkFlow(phase: LinkPhase.failed) => _failed(context, flow),
    };
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        // Leaving mid-way ends the link on both sides; a finished one stays.
        if (didPop && active) _service?.cancelLink();
        if (didPop && !active) _service?.closeLink();
      },
      child: PairFlowPage(
        title: l.devicesLink,
        leadingId: TrustIds.linkdevClose,
        idle: active && flow.phase != LinkPhase.linking ? const SlotProgress(label: '') : null,
        bottom: bottom,
        children: children,
      ),
    );
  }

  /// An invite that came in as a link: the user chooses to answer it.
  _Step _confirm(BuildContext context, String invite) {
    final l = context.l10n;
    return (
      children: [PairNote(l.linkConfirmInvite)],
      bottom: _Buttons([
        KitButton(
          key: linkConfirmKey,
          label: l.linkGo,
          semanticsId: TrustIds.linkdevConfirm,
          onPressed: _busy
              ? null
              : () {
                  setState(() => _toConfirm = null);
                  unawaited(_run((s) => s.startScanned(_invite(invite))));
                },
        ),
        KitButton(
          label: l.commonCancel,
          kind: KitButtonKind.quiet,
          semanticsId: TrustIds.linkdevConfirmCancel,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ]),
    );
  }

  Widget _cancelButton(BuildContext context) => KitButton(
    key: linkCancelKey,
    label: context.l10n.commonCancel,
    kind: KitButtonKind.quiet,
    semanticsId: TrustIds.linkdevCancel,
    onPressed: _cancel,
  );

  /// A wait with a Cancel: answering, or the other device's turn.
  _Step _wait(BuildContext context, String? text) =>
      (children: [if (text != null) PairNote(text)], bottom: _cancelButton(context));

  _Step _start(BuildContext context) {
    final l = context.l10n;
    final servers = phoneLinkServers(ref);
    final scanner = ref.watch(qrScannerProvider);
    final showOff = _busy || servers.isEmpty;
    return (
      children: [
        PairNote(l.linkLead),
        const PairGap(Kit.gutter),
        KitGroup(
          margin: EdgeInsets.zero,
          dividerInset: Kit.dividerInsetList,
          children: [
            if (scanner.supported)
              KitRow(
                key: linkScanKey,
                leading: const KitIconWell(KitIcons.scan),
                title: l.linkScan,
                subtitle: l.phoneLinkScanSub,
                chevron: true,
                semanticsId: TrustIds.linkdevScan,
                onTap: _busy ? null : _scan,
              ),
            KitRow(
              key: linkShowKey,
              leading: const KitIconWell(KitIcons.qr),
              title: l.linkShowMine,
              subtitle: l.phoneLinkShowSub,
              chevron: true,
              semanticsId: TrustIds.linkdevShow,
              onTap: showOff ? null : () => _run((s) => s.startShowing(servers)),
            ),
            KitRow(
              key: linkPasteOpenKey,
              leading: const KitIconWell(KitIcons.paste),
              title: l.linkPaste,
              subtitle: l.phoneLinkPasteSub,
              chevron: !_pasting,
              selected: false,
              semanticsId: TrustIds.linkdevPasteOpen,
              onTap: _busy ? null : () => setState(() => _pasting = true),
            ),
          ],
        ),
        if (_pasting) ...[
          const PairGap(Kit.gutter),
          PairField(
            key: linkPasteFieldKey,
            controller: _paste,
            label: l.linkPasteLabel,
            maxLines: 2,
            autofocus: true,
            semanticsId: TrustIds.linkdevPasteField,
            onSubmitted: (_) => _pasteNow(),
          ),
          const PairGap(),
          KitButton(
            key: linkPasteKey,
            label: l.linkGo,
            semanticsId: TrustIds.linkdevPasteGo,
            onPressed: _busy ? null : _pasteNow,
          ),
        ],
      ],
      bottom: null,
    );
  }

  _Step _showCode(BuildContext context, LinkFlow flow) {
    final l = context.l10n;
    // The QR and Copy carry the invite as a link when the invite page is set, else bare.
    final code = inviteShareText(InviteLink(InviteKind.deviceLink, flow.code ?? ''), invitePage: ref.watch(invitePageProvider));
    final until = flow.expiresAt;
    return (
      children: [
        const PairGap(8),
        PairQr(data: code, label: l.linkPasteLabel),
        const PairGap(Kit.gutter),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              if (until != null) KitChip(l.linkExpires(linkMinutesLeft(until, ref.read(clockProvider)())), icon: KitIcons.info),
            ],
          ),
        ),
        const PairGap(8),
        PairNote(l.linkWaiting, center: true),
      ],
      bottom: _Buttons([
        KitButton(
          key: linkCopyKey,
          label: l.linkCopy,
          icon: KitIcons.copy,
          semanticsId: TrustIds.linkdevCopy,
          onPressed: () => copySecretText(context, code, l.linkCopied),
        ),
        _cancelButton(context),
      ]),
    );
  }

  /// Both devices show the same four pictures while the hellos cross. Nothing to tap.
  _Step _linking(BuildContext context, LinkFlow flow) {
    final l = context.l10n;
    final t = context.tokens;
    final name = flow.otherName ?? '';
    return (
      children: [
        Semantics(
          header: true,
          child: Text(l.linkLinkingWith(name), textAlign: TextAlign.center, style: KitType.sheetTitle.copyWith(color: t.text)),
        ),
        const PairGap(Kit.gutter),
        KitGroup(
          margin: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
              child: WordTiles(words: flow.sas, label: l.linkPicturesLabel, size: WordTileSize.check),
            ),
          ],
        ),
        const PairGap(),
        PairNote(l.linkLinkingSame(name), center: true),
      ],
      bottom: _cancelButton(context),
    );
  }

  _Step _done(BuildContext context, LinkFlow flow) {
    final l = context.l10n;
    return (
      children: [PairOutcome(icon: KitIcons.success, title: l.linkDone(flow.device?.name ?? flow.otherName ?? ''))],
      bottom: null,
    );
  }

  _Step _failed(BuildContext context, LinkFlow flow) {
    final l = context.l10n;
    final failure = flow.failure ?? LinkFailure.unreachable;
    final linked = failure == LinkFailure.tooMany ? _service?.book.linked : null;
    // A pasted code that failed: another one can be pasted. A code this device showed that
    // went nowhere: a new one.
    final pasted = flow.role == LinkRole.scans && _pasting;
    final retry = !pasted && (failure == LinkFailure.unreachable || failure == LinkFailure.cancelled || failure == LinkFailure.expired || failure == LinkFailure.notFound);
    return (
      children: [
        PairOutcome(icon: KitIcons.warning, good: false, title: l.linkFailedTitle, body: linkFailureText(l, failure, flow.otherName)),
      ],
      bottom: _Buttons([
        // Two devices at most: a refused link offers to replace the one linked.
        if (linked != null)
          KitButton(
            key: linkReplaceKey,
            label: l.linkReplaceTitle(linked.name),
            semanticsId: TrustIds.linkdevReplace,
            onPressed: () async {
              final yes = await confirmPairSheet(
                context,
                title: l.linkReplaceTitle(linked.name),
                body: l.linkReplaceBody(linked.name),
                action: l.linkReplace,
                cancel: l.linkKeep(linked.name),
                risky: true,
                sheetId: TrustIds.linkdevReplaceSheet,
                actionId: TrustIds.linkdevReplaceYes,
                cancelId: TrustIds.linkdevReplaceKeep,
              );
              if (!yes || !context.mounted) return;
              await _run((s) => s.replaceLinked());
            },
          )
        else if (pasted)
          KitButton(
            key: linkPasteAnotherKey,
            label: l.linkPasteAnother,
            semanticsId: TrustIds.linkdevPasteAnother,
            onPressed: () {
              _service?.closeLink();
              setState(() => _paste.clear());
            },
          )
        else if (retry)
          KitButton(
            key: linkRetryKey,
            label: l.commonRetry,
            semanticsId: TrustIds.linkdevRetry,
            onPressed: () {
              _service?.closeLink();
              if (flow.role == LinkRole.shows && flow.servers.isNotEmpty) {
                unawaited(_run((s) => s.startShowing(flow.servers)));
              } else if (ref.read(qrScannerProvider).supported) {
                unawaited(_scan());
              }
            },
          ),
        KitButton(
          label: l.commonClose,
          kind: KitButtonKind.quiet,
          semanticsId: TrustIds.linkdevCloseFailed,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ]),
    );
  }
}

/// One step of the screen: what scrolls, and the buttons pinned under it.
typedef _Step = ({List<Widget> children, Widget? bottom});

/// Buttons stacked on the bottom of a step, [Kit.groupGap] apart.
class _Buttons extends StatelessWidget {
  const _Buttons(this.buttons);

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < buttons.length; i++) ...[if (i > 0) const SizedBox(height: 8), buttons[i]],
    ],
  );
}
