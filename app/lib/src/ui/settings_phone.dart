// SPDX-License-Identifier: Apache-2.0
/// The frame every phone Settings page shares: a back link named for the hub, the page title,
/// a "?" that opens the page's help sheet, and a scrolling list on the kit's groups. The pages
/// themselves (`settings_sections.dart`) only fill [SettingsPhonePage.children].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import 'common.dart';
import 'help_screen.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_help_sheet.dart';
import 'kit/kit_tokens.dart';
import 'phone_frame.dart' show phoneFrameBreakpoint;
import 'restore_screen.dart' show ScanSlotLine;

/// What a page's "?" shows: a title, the lines that were behind the page's ⓘ icons, and the
/// Help page "More in Help" opens ([topic], else the Help index).
class SettingsPageHelp {
  const SettingsPageHelp({required this.title, required this.lines, this.topic, this.sheetId, this.moreId});

  final String title;
  final List<String> lines;
  final String? topic;
  final String? sheetId;
  final String? moreId;

  Future<void> show(BuildContext context) => showKitHelp(
    context,
    title: title,
    lines: lines,
    sheetId: sheetId,
    moreId: moreId,
    onMore: () => openHelp(context, topic),
  );
}

/// One Settings page. [pageKey] is the scaffold's key (tests find a page by it). [controller]
/// scrolls the list. A running scan shows in the slot under the top edge, a failed one as a
/// line on the list.
class SettingsPhonePage extends ConsumerWidget {
  const SettingsPhonePage({
    super.key,
    this.pageKey,
    required this.title,
    required this.children,
    this.backLabel,
    this.help,
    this.helpId,
    this.backId,
    this.controller,
  });

  final Key? pageKey;
  final String title;
  final List<Widget> children;

  /// The back link's words; the hub's name unless a page says otherwise.
  final String? backLabel;
  final SettingsPageHelp? help;
  final String? helpId;
  final String? backId;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scan = ref.watch(scanProvider);
    return SlotScaffold(
      key: pageKey,
      // A running scan shows in the slot; a busy page shows nothing, as most of its time is
      // spent waiting on a sheet or dialog.
      idle: scan.running ? ScanSlotLine(scan: scan) : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: phoneFrameBreakpoint),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitPageHeader(
                  backLabel: backLabel ?? l.settingsTitle,
                  onBack: () => Navigator.of(context).maybePop(),
                  title: title,
                  onHelp: help == null ? null : () => help!.show(context),
                  helpId: helpId,
                  backId: backId,
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.only(bottom: Kit.gutter * 2),
                    children: [
                      if (!scan.running && scan.error != null)
                        Padding(
                          padding: const EdgeInsets.all(Kit.gutter),
                          child: ErrorText(describeError(l, scan.error!)),
                        ),
                      ...children,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The gap between two groups of a page.
class SettingsGap extends StatelessWidget {
  const SettingsGap({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(height: Kit.groupGap);
}

/// An auto-lock choice in words: `15 minutes`, `1 hour`.
String autoLockDuration(AppLocalizations l, int minutes) =>
    minutes == 60 ? l.phoneSettingsOneHour : l.phoneSettingsMinutes(minutes);

/// The auto-lock value on its row: the duration, or `Never` for an old setting of none.
String autoLockValue(AppLocalizations l, int? minutes) => minutes == null ? l.autoLockNever : autoLockDuration(l, minutes);
