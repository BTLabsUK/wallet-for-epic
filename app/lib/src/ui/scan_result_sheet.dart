/// The sheet after a scan, paste or link that is not for Send: not an Epic code, an address of
/// the other network, a transaction file's text, a pairing link. Shaped like [InfoSheet].
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../scan/scan_router.dart' show untrustedTextForbidden;
import '../scan/scan_text.dart';
import 'notices.dart';
import 'theme/tokens.dart';

const Key scanResultSheetKey = Key('scan-result-sheet');
const Key scanResultCopyKey = Key('scan-result-copy');
const Key scanResultPrimaryKey = Key('scan-result-primary');

/// Shows the sheet; true when the primary button closed it.
Future<bool> showScanResultSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  String? text,
  String? preview,
  bool previewWhole = false,
  String? copy,
  required String primary,
  String? secondary,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final l = context.l10n;
  final result = await showModalBottomSheet<_SheetResult>(
    context: context,
    showDragHandle: true,
    builder: (_) => ScanResultSheet(
      icon: icon,
      title: title,
      text: text,
      preview: preview,
      previewWhole: previewWhole,
      canCopy: copy != null,
      primary: primary,
      secondary: secondary,
    ),
  );
  if (result == _SheetResult.copy && copy != null) {
    await Clipboard.setData(ClipboardData(text: copy));
    container
        .read(noticeProvider.notifier)
        .show(l.scanCopied, level: NoticeLevel.success);
  }
  return result == _SheetResult.primary;
}

enum _SheetResult { primary, copy, secondary }

class ScanResultSheet extends StatelessWidget {
  const ScanResultSheet({
    super.key,
    required this.icon,
    required this.title,
    this.text,
    this.preview,
    this.previewWhole = false,
    this.canCopy = false,
    required this.primary,
    this.secondary,
  });

  final IconData icon;
  final String title;
  final String? text;

  /// The scanned text, shown cut to [scanPreviewLength] characters in a mono box.
  final String? preview;

  /// Show [preview] whole (an address), up to three lines.
  final bool previewWhole;
  final bool canCopy;
  final String primary;

  /// A quiet button before the primary one (Cancel), instead of Copy.
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final theme = Theme.of(context);
    final text = this.text;
    final preview = this.preview;
    final shown = preview == null
        ? null
        : previewWhole
        ? preview.replaceAll(untrustedTextForbidden, '')
        : scanPreview(preview);
    const target = Size(64, 44);
    return SafeArea(
      key: scanResultSheetKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: t.dim),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ),
              ],
            ),
            if (text != null) ...[
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: t.dim,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            if (shown != null) ...[
              const SizedBox(height: 12),
              Semantics(
                label: l.scanCodeTextLabel,
                value: shown,
                excludeSemantics: true,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.field,
                    borderRadius: BorderRadius.circular(t.radiusSmall),
                  ),
                  child: Text(
                    shown,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: t.monoFamily,
                      color: t.text,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (secondary != null)
                  TextButton(
                    style: TextButton.styleFrom(minimumSize: target),
                    onPressed: () =>
                        Navigator.pop(context, _SheetResult.secondary),
                    child: Text(secondary!),
                  )
                else if (canCopy)
                  TextButton(
                    key: scanResultCopyKey,
                    style: TextButton.styleFrom(minimumSize: target),
                    onPressed: () => Navigator.pop(context, _SheetResult.copy),
                    child: Text(l.commonCopy),
                  ),
                FilledButton(
                  key: scanResultPrimaryKey,
                  style: FilledButton.styleFrom(minimumSize: target),
                  onPressed: () => Navigator.pop(context, _SheetResult.primary),
                  child: Text(primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
