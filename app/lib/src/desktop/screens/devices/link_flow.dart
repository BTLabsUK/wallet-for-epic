// SPDX-License-Identifier: Apache-2.0
/// Link a device (desktop): this computer shows a code the other device scans (the phone) or
/// pastes (another computer, which has no camera), or pastes a code from the other device. Once
/// both are paired each shows the four pictures as "Linking…" while the hellos cross (nothing to
/// tap: the proof needs the recovery phrase), then "Linked" closes by itself. The service does
/// the work ([DeviceService.startShowing], [DeviceService.startScanned]); this is its dialog.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../devices/device_link_code.dart';
import '../../../devices/device_model.dart' show LinkedDevice;
import '../../../devices/device_service.dart';
import '../../../devices/invite_links_api.dart';
import '../../../ui/pairing/pairing_parts.dart' show WordTileSize, WordTiles;
import '../../data/devices_state.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

const Key deskLinkCodeKey = ValueKey('desk-link-code');
const Key deskLinkCopyKey = ValueKey('desk-link-copy');
const Key deskLinkPasteFieldKey = ValueKey('desk-link-paste-field');
const Key deskLinkGoKey = ValueKey('desk-link-go');
const Key deskLinkCancelKey = ValueKey('desk-link-cancel');
const Key deskLinkRetryKey = ValueKey('desk-link-retry');
const Key deskLinkPasteAnotherKey = ValueKey('desk-link-paste-another');
const Key deskLinkReplaceKey = ValueKey('desk-link-replace');
const Key deskLinkReplaceConfirmKey = ValueKey('desk-link-replace-confirm');

/// Opens the link dialog. With [pasted], a device code that came in as text (Send's field, the
/// Pair page) is answered at once; else this computer shows its own code.
Future<void> showDeskLinkDevice(BuildContext context, {String? pasted, bool paste = false, bool confirm = false}) =>
    showEDialog<void>(context, dismissible: false, builder: (_) => DeskLinkDialog(pasted: pasted, paste: paste, confirm: confirm));

/// Registers the handler of an incoming device invite (an `epiccash://device-link/…` or
/// `https://…/link#…` link the system opened): the link dialog with its confirm step. A link
/// never links by itself.
void registerDeskDeviceInviteHandler() =>
    registerInviteHandler(InviteKind.deviceLink, (context, link) => showDeskLinkDevice(context, pasted: link.invite, confirm: true));

class DeskLinkDialog extends ConsumerStatefulWidget {
  const DeskLinkDialog({super.key, this.pasted, this.paste = false, this.confirm = false});

  final String? pasted;

  /// [pasted] came in as a link: ask before answering it.
  final bool confirm;

  /// Opens on the Paste code tab (a computer links another computer).
  final bool paste;

  @override
  ConsumerState<DeskLinkDialog> createState() => _DeskLinkDialogState();
}

enum _Tab { show, paste }

class _DeskLinkDialogState extends ConsumerState<DeskLinkDialog> {
  late final DeviceService? _service = ref.read(deskDeviceServiceProvider);
  final _text = TextEditingController();
  _Tab _tab = _Tab.show;
  bool _busy = false;
  String? _error;

  /// An invite that came in as a link, waiting for the user's Link.
  bool _confirming = false;
  Timer? _tick;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    final pasted = widget.pasted;
    final running = _service?.link;
    // The minutes left on the code follow the clock.
    _tick = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
    if (pasted != null && widget.confirm) {
      _tab = _Tab.paste;
      _text.text = pasted;
      _confirming = true;
    } else if (pasted != null) {
      _tab = _Tab.paste;
      _text.text = pasted;
      WidgetsBinding.instance.addPostFrameCallback((_) => _answer());
    } else if (running != null) {
      // A link already under way: the dialog shows it, as it is.
      _tab = running.role == LinkRole.scans ? _Tab.paste : _Tab.show;
    } else if (widget.paste) {
      _tab = _Tab.paste;
    } else {
      // The invite is made only while Show code is visible.
      WidgetsBinding.instance.addPostFrameCallback((_) => _show());
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _tick?.cancel();
    _closeTimer?.cancel();
    final service = _service;
    if (service != null) {
      // Closed on a result: only the screen goes; closed on the way: the link is cancelled.
      final phase = service.link?.phase;
      if (phase == LinkPhase.done || phase == LinkPhase.failed) {
        service.closeLink();
      } else if (service.link != null) {
        unawaited(service.cancelLink());
      }
    }
    super.dispose();
  }

  Future<void> _show() async {
    final service = _service;
    if (service == null) return;
    final servers = ref.read(deskLinkServersProvider);
    await service.startShowing(service.linkServers(servers));
  }

  Future<void> _answer() async {
    final service = _service;
    final l = context.l10n;
    if (service == null) return;
    // The invite in any of its forms: a link, or the bare text.
    final text = parseInvite(_text.text.trim())?.invite ?? _text.text.trim();
    if (!isDeviceLinkText(text)) {
      setState(() => _error = l.linkFailInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _confirming = false;
    });
    try {
      await service.startScanned(text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _switch(_Tab tab) async {
    if (tab == _tab) return;
    final service = _service;
    setState(() {
      _tab = tab;
      _error = null;
    });
    if (service == null) return;
    if (service.link != null) await service.cancelLink();
    if (tab == _Tab.show) await _show();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty || !mounted) return;
    setState(() {
      _text.text = text;
      _error = null;
    });
  }

  void _close() => Navigator.of(context).pop();

  /// "Linked" closes by itself after [linkDoneShown].
  void _closeSoon() {
    _closeTimer ??= Timer(linkDoneShown, () {
      if (mounted) _close();
    });
  }

  /// After a failed paste: back to the Paste tab, the field cleared.
  void _pasteAnother() {
    _service?.closeLink();
    setState(() {
      _tab = _Tab.paste;
      _text.clear();
      _error = null;
    });
  }

  Future<void> _replace(LinkedDevice linked) async {
    final l = context.l10n;
    final ok = await showEDialog<bool>(
      context,
      builder: (ctx) => EDialog(
        title: l.linkReplaceTitle(linked.name),
        icon: EIcons.alert,
        tone: ETone.warn,
        description: l.linkReplaceBody(linked.name),
        actions: [
          EButton(label: l.linkKeep(linked.name), onPressed: () => Navigator.pop(ctx, false)),
          EButton(key: deskLinkReplaceConfirmKey, label: l.linkReplace, kind: EBtnKind.danger, onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _service?.replaceLinked();
    // This computer pasted the other's code, which is spent: the other device shows a new one.
    if (mounted && _service?.link == null) _pasteAnother();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final view = ref.watch(deskDeviceViewProvider);
    final link = view?.link;
    final phase = link?.phase;
    final failed = phase == LinkPhase.failed;
    final done = phase == LinkPhase.done;
    final linking = phase == LinkPhase.linking;
    final choosing = !linking && !done && !failed;
    if (done) _closeSoon();
    return EDialog(
      title: l.devicesLink,
      icon: EIcons.devices,
      dismissible: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (choosing && !_confirming) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ESegmented<_Tab>(
                value: _tab,
                onChanged: (t) => unawaited(_switch(t)),
                segments: [
                  ESegment(_Tab.show, l.linkShow),
                  ESegment(_Tab.paste, l.linkPaste),
                ],
              ),
            ),
            SizedBox(height: Sp.x4),
          ],
          if (_service == null) Text(l.devicesUnsupported, style: context.ts.bodyDim) else _content(context, link, choosing),
        ],
      ),
      actions: _actions(context, link),
    );
  }

  Widget _content(BuildContext context, LinkFlow? link, bool choosing) {
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    if (link == null && _confirming) return Text(l.linkConfirmInvite, style: ts.body);
    if (link == null && _tab == _Tab.paste) return _pasteBody(context);
    if (link == null) return _busyLine(context, l.deskDevMakingCode);
    switch (link.phase) {
      case LinkPhase.starting:
        return _busyLine(context, link.role == LinkRole.shows ? l.deskDevMakingCode : l.deskDevConnecting);
      case LinkPhase.waiting when link.role == LinkRole.scans:
        return _busyLine(context, l.linkWaitingFor(link.otherName ?? l.deskDevTheOther));
      case LinkPhase.waiting:
        return _codeBody(context, link);
      case LinkPhase.linking:
        final name = link.otherName ?? l.deskDevTheOther;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.linkLinkingWith(name), style: ts.strong),
            SizedBox(height: Sp.x4),
            WordTiles(words: link.sas, label: l.linkPicturesLabel, size: WordTileSize.check),
            SizedBox(height: Sp.x4),
            _busyLine(context, l.linkLinkingSame(name)),
          ],
        );
      case LinkPhase.done:
        final name = link.device?.name ?? link.otherName ?? l.deskDevTheOther;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(EIcons.okCircle, size: Ctl.icon, color: c.ok),
            SizedBox(width: Sp.x3),
            Expanded(child: Text(l.linkDone(name), style: ts.strong)),
          ],
        );
      case LinkPhase.failed:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(EIcons.alert, size: Ctl.icon, color: c.warn),
            SizedBox(width: Sp.x3),
            Expanded(child: Text(deskLinkFailureText(l, link.failure, link.otherName), style: ts.body)),
          ],
        );
    }
  }

  Widget _busyLine(BuildContext context, String text) => Row(
    children: [
      ESpinner(size: 16.u),
      SizedBox(width: Sp.x3),
      Expanded(child: Text(text, style: context.ts.bodyDim)),
    ],
  );

  Widget _codeBody(BuildContext context, LinkFlow link) {
    final l = context.l10n;
    final ts = context.ts;
    // The QR and Copy carry the invite as a link when the invite page is set, else bare.
    final code = inviteShareText(InviteLink(InviteKind.deviceLink, link.code ?? ''), invitePage: ref.watch(invitePageProvider));
    final until = link.expiresAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: Semantics(label: l.linkPasteLabel, image: true, child: EQr(code, size: 200.u))),
        SizedBox(height: Sp.x4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
          decoration: BoxDecoration(
            color: context.dc.s2,
            borderRadius: BorderRadius.circular(Rad.sm),
            border: Border.all(color: context.dc.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: EMiddleEllipsis(code, key: deskLinkCodeKey, style: ts.mono(size: Fs.xs)),
              ),
              SizedBox(width: Sp.x2),
              ECopyButton(key: deskLinkCopyKey, text: code, label: l.linkCopy, withLabel: true),
            ],
          ),
        ),
        SizedBox(height: Sp.x3),
        Row(
          children: [
            ESpinner(size: 14.u),
            SizedBox(width: Sp.x2),
            Expanded(child: Text(l.linkWaiting, style: ts.small)),
          ],
        ),
        if (until != null) ...[SizedBox(height: Sp.x1), Text(l.linkExpires(linkMinutesLeft(until, ref.read(deskDeviceClockProvider)())), style: ts.caption)],
      ],
    );
  }

  Widget _pasteBody(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.deskDevPasteLead, style: context.ts.bodyDim),
        SizedBox(height: Sp.x4),
        EField(
          label: l.linkPasteLabel,
          error: _error,
          child: EInput(
            key: deskLinkPasteFieldKey,
            controller: _text,
            mono: true,
            invalid: _error != null,
            autofocus: true,
            semanticLabel: l.linkPasteLabel,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _answer(),
            trailing: EIconButton(icon: EIcons.paste, label: l.commonPaste, onPressed: _pasteFromClipboard),
          ),
        ),
      ],
    );
  }

  List<Widget> _actions(BuildContext context, LinkFlow? link) {
    final l = context.l10n;
    final phase = link?.phase;
    // Linked closes by itself.
    if (phase == LinkPhase.done) return const [];
    if (phase == LinkPhase.failed) {
      final failure = link!.failure ?? LinkFailure.unreachable;
      final retry = failure == LinkFailure.unreachable || failure == LinkFailure.expired || failure == LinkFailure.notFound;
      // Two devices at most: a refused link offers to replace the one linked.
      final linked = failure == LinkFailure.tooMany ? _service?.book.linked : null;
      return [
        EButton(label: l.commonClose, size: EBtnSize.sm, onPressed: _close),
        if (linked != null)
          EButton.primary(key: deskLinkReplaceKey, label: l.linkReplaceTitle(linked.name), size: EBtnSize.sm, onPressed: () => unawaited(_replace(linked)))
        else if (link.role == LinkRole.scans)
          EButton.primary(key: deskLinkPasteAnotherKey, label: l.linkPasteAnother, size: EBtnSize.sm, onPressed: _pasteAnother)
        else if (retry)
          EButton.primary(
            key: deskLinkRetryKey,
            label: l.commonRetry,
            size: EBtnSize.sm,
            onPressed: () async {
              _service?.closeLink();
              await _show();
            },
          ),
      ];
    }
    return [
      EButton(key: deskLinkCancelKey, label: l.commonCancel, size: EBtnSize.sm, onPressed: _close),
      if (link == null && (_tab == _Tab.paste || _confirming))
        EButton.primary(key: deskLinkGoKey, label: l.linkGo, size: EBtnSize.sm, busy: _busy, onPressed: _answer),
    ];
  }
}

/// Why a link did not complete, in a sentence ([name]: the other device, when known).
String deskLinkFailureText(AppLocalizations l, LinkFailure? failure, String? name) => switch (failure) {
  LinkFailure.invalidCode => l.linkFailInvalid,
  LinkFailure.expired => l.linkFailExpired,
  LinkFailure.notFound => l.linkFailNotFound,
  LinkFailure.ownCode => l.linkFailOwn,
  LinkFailure.otherWallet => l.linkFailOtherWallet,
  LinkFailure.otherWalletCode => l.linkFailOtherWalletCode,
  LinkFailure.tooMany => l.linkFailTooMany,
  LinkFailure.full => l.linkFailFull(name ?? l.deskDevTheOther),
  LinkFailure.update => l.linkFailUpdate,
  LinkFailure.updateOther => l.linkFailUpdateOther(name ?? l.deskDevTheOther),
  LinkFailure.unreachable => l.linkFailUnreachable,
  LinkFailure.unsupported => l.devicesUnsupported,
  // The other device stopped: the same line as not reached, with Retry.
  LinkFailure.cancelled || null => l.linkFailUnreachable,
};
