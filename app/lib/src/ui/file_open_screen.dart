// SPDX-License-Identifier: Apache-2.0
/// The page where a payment file is opened (Gap-4 of the phone design): the receiver's first
/// step of "With a file". Two rows, a file from the device or the text of one on the clipboard;
/// both lead to the same accept page as before.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../trust_ids.dart';
import 'common.dart';
import 'file_exchange_help.dart' show FileExchangeRole, showFileExchangeHelp;
import 'file_flow_pages.dart';
import 'kit/kit_group.dart';
import 'kit/kit_headers.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_row.dart';
import 'kit/kit_step_strip.dart';
import 'kit/kit_tokens.dart';
import 'theme/tokens.dart';
import 'net_block.dart' show OfflineNodeNote, watchOfflineUsesNode;
import 'receive_screen.dart' show pasteSlate;
import 'slate_file_screen.dart' show openSlateFile;

/// Opens the file page: pick a file, or paste its text.
Future<void> openFileOpenPage(BuildContext context) =>
    Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const FileOpenScreen()));

class FileOpenScreen extends ConsumerWidget {
  const FileOpenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return SlotScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitFlowHeader(
              title: l.phoneFileTitleReceive,
              back: true,
              onLeading: () => Navigator.of(context).maybePop(),
              leadingId: TrustIds.fileBack,
              onHelp: () => showFileExchangeHelp(context, role: FileExchangeRole.receiver),
            ),
            KitStepStrip(labels: [l.phoneStepRecvFileOpen, l.phoneStepRecvFileReply, l.commonDone], current: 0),
            Expanded(
              child: ScreenBody(
                children: [
                  // `.lead`, 34 under the strip: 15 dim, centred, 40 in from the screen's edges.
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40 - Kit.gutter),
                    child: Text(
                      l.phoneFileOpenIntro,
                      textAlign: TextAlign.center,
                      style: KitType.body.copyWith(color: context.tokens.dim, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 26),
                  KitGroup(
                    margin: EdgeInsets.zero,
                    children: [
                      KitRow(
                        title: l.phoneFileOpenFile,
                        subtitle: l.phoneFileOpenFileSub,
                        leading: KitIconWell(KitIcons.file, color: context.tokens.accentText),
                        minHeight: 72,
                        chevron: true,
                        semanticsId: TrustIds.fileOpen,
                        onTap: () => openSlateFile(context, ref),
                      ),
                      KitRow(
                        title: l.phoneFilePasteText,
                        subtitle: l.phoneFilePasteTextSub,
                        leading: KitIconWell(KitIcons.paste, color: context.tokens.accentText),
                        minHeight: 72,
                        chevron: true,
                        semanticsId: TrustIds.filePaste,
                        onTap: () => pasteSlate(context, ref),
                      ),
                    ],
                  ),
                  // `.note`: 8 under the group.
                  const SizedBox(height: 8),
                  FileInfoLine(l.phoneFileOpenNote, bare: true),
                  // Opening a file needs the node; offline, say so before the user picks one.
                  if (watchOfflineUsesNode(context, ref)) const Padding(padding: EdgeInsets.only(top: 12), child: OfflineNodeNote()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
