// SPDX-License-Identifier: Apache-2.0
/// The messages the wallet keeps unread (LEPIC's quarantine), opened from the Epicbox status
/// popover's "1 message could not be read" row: per message when it arrived, who sent it, what
/// it is and why it was not read, with Try again and Remove from this device; the technical
/// facts under "For advanced users"; Copy details for support. The phone's twin is
/// `ui/kept_messages_sheet.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pairing_api.dart';
import '../../settings_file/host_settings.dart' show appConfig;
import '../../ui/kept_messages_text.dart';
import '../data/desk_update.dart' show deskAppVersion;
import '../data/pairing_state.dart';
import '../desk_l10n.dart';
import '../widgets/kit.dart';

/// The dialog's keys, for tests and shots.
const Key deskKeptDialogKey = ValueKey('desk-kept-dialog');
ValueKey<String> deskKeptRetryKey(String id) => ValueKey('desk-kept-retry-$id');
ValueKey<String> deskKeptRemoveKey(String id) => ValueKey('desk-kept-remove-$id');

/// Opens the list of kept messages over [context]'s navigator.
Future<void> showDeskKeptMessages(BuildContext context) =>
    showEDialog<void>(context, builder: (_) => const DeskKeptMessagesDialog());

class DeskKeptMessagesDialog extends ConsumerStatefulWidget {
  const DeskKeptMessagesDialog({super.key});

  @override
  ConsumerState<DeskKeptMessagesDialog> createState() => _DeskKeptMessagesDialogState();
}

/// The last result on one message: read, still kept, or failed.
typedef _Result = ({String text, ETone tone});

class _DeskKeptMessagesDialogState extends ConsumerState<DeskKeptMessagesDialog> {
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
      final kept = await ref.read(deskPairingApiProvider).keptMessages();
      if (mounted) setState(() => _kept = kept);
    } on Object {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _retry(KeptMessage m) async {
    final l = context.l10n;
    setState(() => _busy.add(m.id));
    try {
      await deskPairingCall(ref, (api) => api.retryKept(id: m.id));
      final kept = await ref.read(deskPairingApiProvider).keptMessages();
      if (!mounted) return;
      final still = kept.any((k) => k.id == m.id);
      setState(() {
        _kept = kept;
        if (still) {
          _results[m.id] = (text: l.msgKeptStillKept, tone: ETone.warn);
        } else {
          _results.remove(m.id);
          _gone = (text: l.msgKeptRetried, tone: ETone.ok);
        }
      });
    } on Object {
      if (mounted) setState(() => _results[m.id] = (text: l.msgKeptActionFailed, tone: ETone.risk));
    } finally {
      if (mounted) setState(() => _busy.remove(m.id));
    }
  }

  Future<void> _remove(KeptMessage m) async {
    final l = context.l10n;
    final sure = await showEDialog<bool>(
      context,
      builder: (context) => EDialog(
        title: l.msgKeptRemoveTitle,
        description: l.msgKeptRemoveBody,
        icon: EIcons.trash,
        tone: ETone.risk,
        actions: [
          EButton(label: l.commonCancel, onPressed: () => Navigator.pop(context, false)),
          EButton(label: l.msgKeptRemoveConfirm, kind: EBtnKind.danger, onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() => _busy.add(m.id));
    try {
      await deskPairingCall(ref, (api) => api.removeKept(m.id));
      final kept = await ref.read(deskPairingApiProvider).keptMessages();
      if (mounted) setState(() => _kept = kept);
    } on Object {
      if (mounted) setState(() => _results[m.id] = (text: l.msgKeptActionFailed, tone: ETone.risk));
    } finally {
      if (mounted) setState(() => _busy.remove(m.id));
    }
  }

  String? _addressOf(String contactId) => ref.read(deskPairingByIdProvider(contactId))?.paymentsAddress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final kept = _kept;
    final days = appConfig.number('contacts.quarantine_keep_days');
    final Widget body;
    if (_loadFailed) {
      body = ENotice(title: l.msgKeptLoadFailed, tone: ETone.risk);
    } else if (kept == null) {
      body = Padding(padding: EdgeInsets.symmetric(vertical: Sp.x4), child: const Center(child: ESpinner()));
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_gone case final g?) ...[ENotice(title: g.text, tone: g.tone), SizedBox(height: Sp.x3)],
          if (kept.isEmpty)
            Text(l.msgKeptEmpty, style: context.ts.bodyDim)
          else
            for (final (n, m) in kept.indexed) ...[
              if (n > 0) SizedBox(height: Sp.x3),
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
      );
    }
    return EDialog(
      key: deskKeptDialogKey,
      title: l.msgKeptTitle,
      description: l.msgKeptIntro(days),
      icon: EIcons.eyeOff,
      tone: ETone.warn,
      size: DialogWidth.wide,
      body: body,
      actions: [
        if (kept != null && kept.isNotEmpty)
          ECopyButton(
            text: keptSupportText(kept, addressOf: _addressOf, appVersion: deskAppVersion),
            label: l.msgKeptCopy,
            withLabel: true,
            kind: EBtnKind.secondary,
            size: EBtnSize.md,
          ),
        EButton.primary(label: l.commonClose, onPressed: () => Navigator.pop(context)),
      ],
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
    final c = context.dc;
    final ts = context.ts;
    final m = message;
    final name = ref.watch(deskPairingNameProvider(m.contactId));
    final address = ref.watch(deskPairingByIdProvider(m.contactId))?.paymentsAddress;
    return Container(
      padding: EdgeInsets.all(Sp.x3),
      decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(keptKind(l, m), style: ts.strong),
          Text([keptFrom(l, name), keptArrived(l, m)].join(' · '), style: ts.small),
          SizedBox(height: Sp.x2),
          Text(keptWhy(l, m), style: ts.body),
          if (result case final r?) ...[SizedBox(height: Sp.x2), ENotice(title: r.text, tone: r.tone)],
          SizedBox(height: Sp.x3),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              EButton(key: deskKeptRetryKey(m.id), label: l.msgKeptRetry, icon: EIcons.refresh, size: EBtnSize.sm, busy: busy, onPressed: busy ? null : onRetry),
              EButton(key: deskKeptRemoveKey(m.id), label: l.msgKeptRemove, icon: EIcons.trash, size: EBtnSize.sm, kind: EBtnKind.ghost, onPressed: busy ? null : onRemove),
            ],
          ),
          SizedBox(height: Sp.x2),
          EDetails(
            title: l.msgKeptAdvanced,
            child: EFacts([
              (l.msgKeptReasonCode, EMonoText(m.code)),
              (l.msgKeptTries, Text('${m.attempts}', style: ts.body)),
              (l.msgKeptSize, Text(l.msgKeptSizeBytes(m.size), style: ts.body)),
              if (address != null && address.isNotEmpty) (l.msgKeptAddress, EMonoText(shortAddress(address))),
              (l.msgKeptContactId, EMonoText(m.contactId)),
              (l.msgKeptMessageId, EMonoText(m.id)),
            ]),
          ),
        ],
      ),
    );
  }
}
