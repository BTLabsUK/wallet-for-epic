// SPDX-License-Identifier: Apache-2.0
/// The desktop's layout of the scan-start block (ui/scan_start.dart): the same line, buttons
/// and choice in the desktop's widgets. The web build takes scan_start_desk_web.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;

import '../../trust_ids.dart';
import '../../ui/scan_start.dart';
import '../desk_l10n.dart';
import 'kit.dart';

Widget deskScanStart(BuildContext context, ScanStart s) {
  final l = context.l10n;
  final c = s.controller;
  final ids = s.ids;
  final ts = context.ts;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(ScanStart.line(l, c), key: ScanStart.lineKey, style: ts.body)),
          SizedBox(width: Sp.x1),
          if (s.picks)
            ScanStart.change(
              c.open,
              EIconButton(
                key: ScanStart.changeKey,
                icon: EIcons.calendar,
                label: l.scanStartChange,
                selected: c.open,
                semanticsId: ids.start,
                onPressed: c.toggle,
              ),
            ),
          TrustId(
            ids.info,
            child: EInfoHint(
              l.scanStartInfo,
              key: ScanStart.infoKey,
              title: l.scanStartInfoTitle,
              size: Ctl.sm,
              action: s.fromStartAction(l),
            ),
          ),
        ],
      ),
      if (s.picks)
        ExpandFade(
          open: c.open,
          child: Padding(
            padding: EdgeInsets.only(top: Sp.x2, bottom: Sp.x1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (s.both) ...[
                  ESegmented<ScanStartBy>(
                    key: ScanStart.byKey,
                    segments: [
                      ESegment(ScanStartBy.month, l.restoreStartByMonth, semanticsId: ids.byMonth),
                      ESegment(ScanStartBy.height, l.restoreStartByHeight, semanticsId: ids.byHeight),
                    ],
                    value: c.by,
                    onChanged: c.pickBy,
                  ),
                  SizedBox(height: Sp.x3),
                ],
                if (s.byMonth)
                  EStartDate(
                    date: c.month.firstDay,
                    semanticsId: ids.month,
                    onChanged: (d) => c.pickMonth(d == null ? defaultStartMonth : StartMonth.of(d)),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(minWidth: Ctl.rowWide),
                    child: EField(
                      label: l.restoreStartHeightLabel,
                      help: l.restoreStartHeightHelper,
                      child: EInput(
                        key: ScanStart.heightKey,
                        controller: c.height,
                        mono: true,
                        semanticLabel: l.restoreStartHeightLabel,
                        semanticsId: ids.height,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => c.heightChanged(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
    ],
  );
}
