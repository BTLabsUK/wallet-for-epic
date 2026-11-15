// SPDX-License-Identifier: Apache-2.0
/// The enlarged QR: every desktop code ([EQr]) opens it on a click, Enter or Space. A centred
/// modal draws the same code as large as the window allows on white with a quiet zone, the label
/// under it and Copy and Close beside it. Esc, a click outside and Close dismiss it.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/theme/logo_qr.dart';
import '../desk_l10n.dart';
import '../theme/tokens.dart';
import 'buttons.dart';
import 'surfaces.dart' show ECopyButton;
import 'dialogs.dart' show showEDialog;

const Key deskQrZoomKey = ValueKey('desk-qr-zoom');
const Key deskQrZoomImageKey = ValueKey('desk-qr-zoom-image');
const Key deskQrZoomCloseKey = ValueKey('desk-qr-zoom-close');

/// Opens the enlarged code of [data]. [label] names it under the code; [copyText] is what Copy
/// puts on the clipboard (null: no Copy, for a secret).
Future<void> showEQrZoom(BuildContext context, {required String data, required QrLogo logo, String? label, String? copyText}) =>
    showEDialog<void>(context, builder: (_) => EQrZoomDialog(data: data, logo: logo, label: label, copyText: copyText));

class EQrZoomDialog extends StatelessWidget {
  const EQrZoomDialog({super.key, required this.data, required this.logo, this.label, this.copyText});

  final String data;
  final QrLogo logo;
  final String? label;
  final String? copyText;

  /// The quiet zone round the modules, as a share of the white square (at least four modules
  /// on the densest code the wallet draws).
  static const double quiet = 0.06;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    final screen = MediaQuery.sizeOf(context);
    final inset = Sp.x5;
    final beside = screen.width >= 760.u;
    final sideWidth = beside ? 168.u : 0.0;
    final padding = Sp.x6;
    final labelRoom = 104.u;
    final room = math.min(screen.height - 2 * inset - 2 * padding - labelRoom - (beside ? 0 : 56.u), screen.width - 2 * inset - 2 * padding - sideWidth - (beside ? Sp.x5 : 0));
    final side = math.max(160.0, math.min(room, 880.0));
    final pad = side * quiet;
    final qr = Semantics(
      image: true,
      label: label ?? l.deskKitQrCode,
      excludeSemantics: true,
      child: Container(
        key: deskQrZoomImageKey,
        width: side,
        height: side,
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Rad.sm), boxShadow: [BoxShadow(color: c.lineStrong, spreadRadius: 1)]),
        child: LogoQr(data: data, size: side - 2 * pad, logo: logo),
      ),
    );
    final copy = copyText;
    final buttons = [
      if (copy != null) ECopyButton(text: copy, withLabel: true, kind: EBtnKind.secondary, size: EBtnSize.md, label: l.commonCopy),
      EButton.primary(key: deskQrZoomCloseKey, label: l.commonClose, autofocus: true, onPressed: () => Navigator.of(context).pop()),
    ];
    final caption = Text(label ?? l.deskKitQrCode, style: ts.small, textAlign: TextAlign.center);
    return Dialog(
      key: deskQrZoomKey,
      backgroundColor: c.modal,
      insetPadding: EdgeInsets.all(inset),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Rad.lg), side: BorderSide(color: c.lineStrong)),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (beside)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  qr,
                  SizedBox(width: Sp.x5),
                  SizedBox(
                    width: sideWidth,
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final b in buttons) ...[b, SizedBox(height: Sp.x2)]]),
                  ),
                ],
              )
            else ...[
              qr,
              SizedBox(height: Sp.x3),
              Wrap(alignment: WrapAlignment.center, spacing: Sp.x2, runSpacing: Sp.x2, children: buttons),
            ],
            SizedBox(height: Sp.x3),
            SizedBox(width: side, child: caption),
          ],
        ),
      ),
    );
  }
}
