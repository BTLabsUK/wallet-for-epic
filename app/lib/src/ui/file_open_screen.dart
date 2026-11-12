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
                  const SizedBox(height: 4),
                  FileInfoLine(l.phoneFileOpenIntro, bare: true),
                  const SizedBox(height: 20),
                  KitGroup(
                    margin: EdgeInsets.zero,
                    children: [
                      KitRow(
                        title: l.phoneFileOpenFile,
                        subtitle: l.phoneFileOpenFileSub,
                        leading: const KitIconWell(Icons.file_open_outlined),
                        chevron: true,
                        semanticsId: TrustIds.fileOpen,
                        onTap: () => openSlateFile(context, ref),
                      ),
                      KitRow(
                        title: l.phoneFilePasteText,
                        subtitle: l.phoneFilePasteTextSub,
                        leading: const KitIconWell(KitIcons.paste),
                        chevron: true,
                        semanticsId: TrustIds.filePaste,
                        onTap: () => pasteSlate(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FileInfoLine(l.phoneFileOpenNote),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
