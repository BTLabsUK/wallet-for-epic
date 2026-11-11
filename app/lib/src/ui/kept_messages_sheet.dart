// SPDX-License-Identifier: Apache-2.0
/// The messages the wallet keeps unread (LEPIC's quarantine), opened from the message checks'
/// "1 message could not be read" row: per message when it arrived, who sent it, what it is and
/// why it was not read, with Try again and Remove from this device; the technical facts under
/// "For advanced users"; Copy details for support. The desktop's twin is
/// `desktop/app/kept_messages_dialog.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../pairing_api.dart';
import '../pairing_providers.dart';
import '../settings_file/host_settings.dart' show appConfig;
import 'app_dialog.dart';
import 'common.dart';
import 'kept_messages_text.dart';
import 'phone_sheet.dart';
import 'settings_sections.dart' show appVersionProvider;
import 'theme/tokens.dart';

/// The sheet's keys, for tests.
const Key keptSheetKey = ValueKey('kept-sheet');
ValueKey<String> keptRetryKey(String id) => ValueKey('kept-retry-$id');
ValueKey<String> keptRemoveKey(String id) => ValueKey('kept-remove-$id');

/// Opens the list of kept messages.
Future<void> showKeptMessagesSheet(BuildContext context) => showPhoneSheet<void>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) => const KeptMessagesSheet(),
);

class KeptMessagesSheet extends ConsumerStatefulWidget {
  const KeptMessagesSheet({super.key});

  @override
  ConsumerState<KeptMessagesSheet> createState() => _KeptMessagesSheetState();
}

typedef _Result = ({String text, NoticeLevel level});

class _KeptMessagesSheetState extends ConsumerState<KeptMessagesSheet> {
  List<KeptMessage>? _kept;
  bool _loadFailed = false;
  final Map<String, _Result> _results = {};
  final Set<String> _busy = {};
  _Result? _gone;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final kept = await ref.read(pairingApiProvider).keptMessages();
      if (mounted) setState(() => _kept = kept);
    } on Object {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _retry(KeptMessage m) async {
    final l = context.l10n;
    setState(() => _busy.add(m.id));
    try {
      await pairingCall(ref, (api) => api.retryKept(id: m.id));
      final kept = await ref.read(pairingApiProvider).keptMessages();
      if (!mounted) return;
      final still = kept.any((k) => k.id == m.id);
      setState(() {
        _kept = kept;
        if (still) {
          _results[m.id] = (text: l.msgKeptStillKept, level: NoticeLevel.warning);
        } else {
          _results.remove(m.id);
          _gone = (text: l.msgKeptRetried, level: NoticeLevel.success);
        }
      });
    } on Object {
      if (mounted) setState(() => _results[m.id] = (text: l.msgKeptActionFailed, level: NoticeLevel.error));
    } finally {
      if (mounted) setState(() => _busy.remove(m.id));
    }
  }

  Future<void> _remove(KeptMessage m) async {
    final l = context.l10n;
    final sure = await confirmAppDialog(
      context,
      title: l.msgKeptRemoveTitle,
      icon: Icons.delete_outline,
      tone: DialogTone.risk,
      description: l.msgKeptRemoveBody,
      cancelLabel: l.commonCancel,
      confirmLabel: l.msgKeptRemoveConfirm,
      risk: true,
    );
    if (!sure || !mounted) return;
    setState(() => _busy.add(m.id));
    try {
      await pairingCall(ref, (api) => api.removeKept(m.id));
      final kept = await ref.read(pairingApiProvider).keptMessages();
      if (mounted) setState(() => _kept = kept);
    } on Object {
      if (mounted) setState(() => _results[m.id] = (text: l.msgKeptActionFailed, level: NoticeLevel.error));
    } finally {
      if (mounted) setState(() => _busy.remove(m.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final kept = _kept;
    return SingleChildScrollView(
      key: keptSheetKey,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l.msgKeptTitle, style: text.titleLarge)),
          const SizedBox(height: 8),
          Text(l.msgKeptIntro(appConfig.number('contacts.quarantine_keep_days')), style: text.bodyMedium?.copyWith(color: t.dim)),
          const SizedBox(height: 16),
          if (_loadFailed)
            InlineNotice(level: NoticeLevel.error, text: l.msgKeptLoadFailed)
          else if (kept == null)
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()))
          else ...[
            if (_gone case final g?) ...[InlineNotice(level: g.level, text: g.text, liveRegion: true), const SizedBox(height: 12)],
            if (kept.isEmpty) Text(l.msgKeptEmpty, style: text.bodyMedium?.copyWith(color: t.dim)),
            for (final (n, m) in kept.indexed) ...[
              if (n > 0) const SizedBox(height: 12),
              _KeptCard(
                key: ValueKey(m.id),
                message: m,
                busy: _busy.contains(m.id),
                result: _results[m.id],
                onRetry: () => _retry(m),
                onRemove: () => _remove(m),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: t.line),
          const SizedBox(height: 12),
          if (kept != null && kept.isNotEmpty)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: Text(l.msgKeptCopy),
              onPressed: () async {
                final version = ref.read(appVersionProvider).value;
                final details = keptSupportText(kept, addressOf: (id) => ref.read(pairingByIdProvider(id))?.paymentsAddress, appVersion: version);
                await copyText(context, details, l.msgKeptCopied);
              },
            ),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: t.dim),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.commonClose),
          ),
        ],
      ),
    );
  }
}

class _KeptCard extends ConsumerWidget {
  const _KeptCard({super.key, required this.message, required this.busy, required this.result, required this.onRetry, required this.onRemove});

  final KeptMessage message;
  final bool busy;
  final _Result? result;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final m = message;
    final name = ref.watch(pairingNameProvider(m.contactId));
    final address = ref.watch(pairingByIdProvider(m.contactId))?.paymentsAddress;
    final mono = text.bodySmall?.copyWith(fontFamily: 'monospace', color: t.text);
    Widget fact(String label, String value, {bool code = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 104, child: Text(label, style: text.bodySmall?.copyWith(color: t.dim))),
          Expanded(child: SelectableText(value, style: code ? mono : text.bodySmall)),
        ],
      ),
    );
    // A Material, not a coloured box: the Advanced fold's ink shows on it.
    return Material(
      color: t.surfaceHi,
      shape: RoundedRectangleBorder(side: BorderSide(color: t.line), borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(keptKind(l, m), style: text.titleSmall),
            Text(keptFrom(l, name), style: text.bodySmall?.copyWith(color: t.dim)),
            Text(keptArrived(l, m), style: text.bodySmall?.copyWith(color: t.dim)),
            const SizedBox(height: 8),
            Text(keptWhy(l, m), style: text.bodyMedium),
            if (result case final r?) ...[const SizedBox(height: 8), InlineNotice(level: r.level, text: r.text, liveRegion: true)],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: keptRetryKey(m.id),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  icon: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh, size: 18),
                  label: Text(l.msgKeptRetry),
                  onPressed: busy ? null : onRetry,
                ),
                TextButton.icon(
                  key: keptRemoveKey(m.id),
                  style: TextButton.styleFrom(minimumSize: const Size(0, 44), foregroundColor: t.risk),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l.msgKeptRemove),
                  onPressed: busy ? null : onRemove,
                ),
              ],
            ),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                title: Text(l.msgKeptAdvanced, style: text.bodyMedium?.copyWith(color: t.dim)),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fact(l.msgKeptReasonCode, m.code, code: true),
                  fact(l.msgKeptTries, '${m.attempts}'),
                  fact(l.msgKeptSize, l.msgKeptSizeBytes(m.size)),
                  if (address != null && address.isNotEmpty) fact(l.msgKeptAddress, shortAddress(address), code: true),
                  fact(l.msgKeptContactId, m.contactId, code: true),
                  fact(l.msgKeptMessageId, m.id, code: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
