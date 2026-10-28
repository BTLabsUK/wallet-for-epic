// SPDX-License-Identifier: Apache-2.0
/// Link a device (desktop): this computer shows a code the other device scans (the phone) or
/// pastes (another computer, which has no camera), or pastes a code from the other device. Both
/// devices then show the same four pictures and each user confirms; the link is made only after
/// both did. The service does the work ([DeviceService.startShowing], [DeviceService.startScanned],
/// [DeviceService.answerCheck]); this is its dialog.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../devices/device_link_code.dart';
import '../../../devices/device_model.dart' show maxLinkedDevices;
import '../../../devices/device_service.dart';
import '../../../ui/pairing/pairing_parts.dart' show WordTileSize, WordTiles;
import '../../data/devices_state.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

const Key deskLinkCodeKey = ValueKey('desk-link-code');
const Key deskLinkCopyKey = ValueKey('desk-link-copy');
const Key deskLinkPasteFieldKey = ValueKey('desk-link-paste-field');
const Key deskLinkGoKey = ValueKey('desk-link-go');
const Key deskLinkMatchKey = ValueKey('desk-link-match');
const Key deskLinkNoMatchKey = ValueKey('desk-link-no-match');
const Key deskLinkDoneKey = ValueKey('desk-link-done');
const Key deskLinkCancelKey = ValueKey('desk-link-cancel');
const Key deskLinkRetryKey = ValueKey('desk-link-retry');

/// Opens the link dialog. With [pasted], a device code that came in as text (Send's field, the
/// Pair page) is answered at once; else this computer shows its own code.
Future<void> showDeskLinkDevice(BuildContext context, {String? pasted, bool paste = false}) =>
    showEDialog<void>(context, dismissible: false, builder: (_) => DeskLinkDialog(pasted: pasted, paste: paste));

class DeskLinkDialog extends ConsumerStatefulWidget {
  const DeskLinkDialog({super.key, this.pasted, this.paste = false});

  final String? pasted;

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

  @override
  void initState() {
    super.initState();
    final pasted = widget.pasted;
    final running = _service?.link;
    if (pasted != null) {
      _tab = _Tab.paste;
      _text.text = pasted;
      WidgetsBinding.instance.addPostFrameCallback((_) => _answer());
    } else if (running != null) {
      // A link already under way (the pictures to check): the dialog shows it, as it is.
      _tab = running.role == LinkRole.scans ? _Tab.paste : _Tab.show;
    } else if (widget.paste) {
      _tab = _Tab.paste;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _show());
    }
  }

  @override
  void dispose() {
    _text.dispose();
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
    final text = _text.text.trim();
    if (!isDeviceLinkText(text)) {
      setState(() => _error = l.linkFailInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final view = ref.watch(deskDeviceViewProvider);
    final link = view?.link;
    final phase = link?.phase;
    final failed = phase == LinkPhase.failed;
    final done = phase == LinkPhase.done;
    final checking = phase == LinkPhase.checking || phase == LinkPhase.waitingOther;
    final choosing = !checking && !done && !failed;
    return EDialog(
      title: l.devicesLink,
      icon: EIcons.devices,
      width: 520.u,
      dismissible: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (choosing) ...[
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
    if (link == null && _tab == _Tab.paste) return _pasteBody(context);
    if (link == null) return _busyLine(context, l.deskDevMakingCode);
    switch (link.phase) {
      case LinkPhase.starting:
        return _busyLine(context, link.role == LinkRole.shows ? l.deskDevMakingCode : l.deskDevConnecting);
      case LinkPhase.waiting when link.role == LinkRole.scans:
        return _busyLine(context, l.linkWaitingFor(link.otherName ?? l.deskDevTheOther));
      case LinkPhase.waiting:
        return _codeBody(context, link);
      case LinkPhase.checking || LinkPhase.waitingOther:
        final name = link.otherName ?? l.deskDevTheOther;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.linkCheckLead(name), style: ts.bodyDim),
            SizedBox(height: Sp.x4),
            WordTiles(words: link.sas, label: l.linkPicturesLabel, size: WordTileSize.check, dim: link.phase == LinkPhase.waitingOther),
            if (link.phase == LinkPhase.waitingOther) ...[SizedBox(height: Sp.x4), _busyLine(context, l.linkWaitingCheck(name))],
          ],
        );
      case LinkPhase.done:
        final name = link.device?.name ?? link.otherName ?? l.deskDevTheOther;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(EIcons.okCircle, size: Ctl.icon, color: c.ok),
            SizedBox(width: Sp.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.linkDoneTitle, style: ts.strong),
                  SizedBox(height: Sp.x1),
                  Text(l.linkDone(name), style: ts.bodyDim),
                ],
              ),
            ),
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
    final code = link.code ?? '';
    final until = link.expiresAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.linkShowLead, style: ts.bodyDim),
        SizedBox(height: Sp.x4),
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
                child: Text(code, key: deskLinkCodeKey, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts.mono(size: Fs.xs)),
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
        if (until != null) ...[SizedBox(height: Sp.x1), Text(l.linkExpires(_minutesLeft(until, ref.read(deskDeviceClockProvider)())), style: ts.caption)],
        SizedBox(height: Sp.x1),
        Text(l.deskDevServersLine(link.servers.join(', ')), style: ts.caption),
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
    if (phase == LinkPhase.done) {
      return [EButton.primary(key: deskLinkDoneKey, label: l.commonDone, size: EBtnSize.sm, onPressed: _close)];
    }
    if (phase == LinkPhase.failed) {
      final again = link!.role == LinkRole.shows && link.failure != LinkFailure.tooMany && link.failure != LinkFailure.unsupported;
      return [
        EButton(label: l.commonClose, size: EBtnSize.sm, onPressed: _close),
        if (again)
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
    if (phase == LinkPhase.checking) {
      return [
        EButton(key: deskLinkNoMatchKey, label: l.sasNoMatch, size: EBtnSize.sm, onPressed: () => unawaited(_service?.answerCheck(false))),
        EButton.primary(key: deskLinkMatchKey, label: l.sasMatch, size: EBtnSize.sm, onPressed: () => unawaited(_service?.answerCheck(true))),
      ];
    }
    return [
      EButton(key: deskLinkCancelKey, label: l.commonCancel, size: EBtnSize.sm, onPressed: _close),
      if (link == null && _tab == _Tab.paste)
        EButton.primary(key: deskLinkGoKey, label: l.linkGo, size: EBtnSize.sm, busy: _busy, onPressed: _answer),
    ];
  }
}

/// Whole minutes until [t], at least 1 (the code's remaining time).
int _minutesLeft(DateTime t, DateTime now) => ((t.difference(now).inSeconds + 59) ~/ 60).clamp(1, 60);

/// Why a link did not complete, in a sentence ([name]: the other device, when known).
String deskLinkFailureText(AppLocalizations l, LinkFailure? failure, String? name) => switch (failure) {
  LinkFailure.invalidCode => l.linkFailInvalid,
  LinkFailure.expired => l.linkFailExpired,
  LinkFailure.notFound => l.linkFailNotFound,
  LinkFailure.ownCode => l.linkFailOwn,
  LinkFailure.otherWallet => l.linkFailOtherWallet,
  LinkFailure.otherWalletCode => l.linkFailOtherWalletCode,
  LinkFailure.mismatch => l.linkFailMismatch,
  LinkFailure.tooMany => l.linkFailTooMany(maxLinkedDevices),
  LinkFailure.unreachable => l.linkFailUnreachable,
  LinkFailure.unsupported => l.devicesUnsupported,
  LinkFailure.cancelled || null => l.linkFailCancelled,
};
