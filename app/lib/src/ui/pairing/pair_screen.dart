// SPDX-License-Identifier: Apache-2.0
/// Pair (one code, two ways): the wallet's standing code as a QR, shared as a link, the name
/// the other side sees, and Have their code? with Scan and Paste. Everything scanned or
/// pasted goes through one handler: a code opens "Pair with …?", an answer the finish code,
/// a finish code the words check, anything else says "Not a pairing code". Opened for a
/// contact, the same screen is framed for it and the pairing attaches to it.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../pairing_text.dart';
import '../../slate_files.dart';
import '../../wallet_service.dart';
import '../notices.dart' show NoticeLevel, noticeProvider;
import '../scan_screen.dart';
import '../../trust_ids.dart';
import '../kit/kit_button.dart';
import '../kit/kit_group.dart';
import '../kit/kit_headers.dart';
import '../kit/kit_icons.dart';
import '../kit/kit_row.dart';
import '../kit/kit_sheet.dart';
import '../kit/kit_support.dart' show kitId;
import '../kit/kit_tokens.dart';
import '../theme/tokens.dart';
import '../scan_route.dart' show openDeviceLinkText;
import 'invite_links.dart';
import 'pair_check.dart';
import 'pair_incoming.dart';
import 'pair_flow.dart';
import 'pairing_clip_offer.dart';
import 'pairing_notices.dart' show pairingWordsOnScreen;
import 'pairing_parts.dart';

/// Keys for tests.
const Key pairShareKey = ValueKey('pair-share');
const Key pairCopyKey = ValueKey('pair-copy');
const Key pairChangeNameKey = ValueKey('pair-change-name');
const Key pairNameFieldKey = ValueKey('pair-name');
const Key pairNameSaveKey = ValueKey('pair-name-save');
const Key pairScanKey = ValueKey('pair-scan');
const Key pairPasteKey = ValueKey('pair-paste');
const Key pairFinishBoxKey = ValueKey('pair-finish-box');
const Key pairFinishShareKey = ValueKey('pair-finish-share');
const Key pairCheckWordsKey = ValueKey('pair-check-words');
const Key pairCodeKey = ValueKey('pair-code');
const Key pairStatusKey = ValueKey('pair-status');

/// The invite as the text a QR or a message carries: the page link when an invite page is
/// set, else the bare text. One place, so a shorter form later changes nothing else.
String pairingInviteText(PairingRecord invite, {String? invitePage}) =>
    inviteShareText(InviteLink(InviteKind.pair, invite.inviteLink ?? ''), invitePage: invitePage);

/// The Pair screen. [contact] frames it for an address-book contact: the title and captions
/// name the contact, and a pairing that completes here attaches to it.
class PairScreen extends ConsumerStatefulWidget {
  const PairScreen({super.key, this.contact});

  final Contact? contact;

  @override
  ConsumerState<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends ConsumerState<PairScreen> {
  PairingRecord? _code;
  String? _error;
  bool _busy = false;
  PairingCollector? _collector;
  StreamSubscription<PairingEvent>? _events;

  /// Pairings answered while this screen is up: the status under the code follows them.
  final Set<String> _answered = {};

  /// A reply pasted here: its finish code box stays under the code until the words.
  String? _finishFor;
  String? _finishLink;

  bool _onScreen(PairingEvent e) => e.pairingId != null && (_answered.contains(e.pairingId) || e.pairingId == _code?.id);

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
    final api = ref.read(pairingApiProvider);
    if (ref.read(pairNetProvider) == PairNet.online) _collector = PairingCollector(api)..start();
    _events = api.events().listen(_onEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _makeCode());
  }

  @override
  void dispose() {
    pairingWordsOnScreen.remove(_onScreen);
    _collector?.stop();
    _events?.cancel();
    super.dispose();
  }

  /// The code was answered: the status says so, and a code answer opens the words once the
  /// confirm went out (the relay did it). A request is verified without words.
  void _onEvent(PairingEvent e) {
    final id = e.pairingId;
    if (!mounted || id == null) return;
    if (e.kind == PairingEventKind.replied && (id == _code?.id || _answered.contains(id))) {
      _answered.add(id);
      // The standing code was used: the next visit shows a fresh one.
      if (id == _code?.id) _makeCode(fresh: true);
      final record = ref.read(pairingByIdProvider(id));
      // A paste in progress took this answer by hand: its confirmation box follows, not the words.
      if (!_busy && _finishFor != id && (ModalRoute.of(context)?.isCurrent ?? false) && record?.expectAddress == null) {
        _attachIfFramed(id);
        Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: id)));
      }
      setState(() {});
    }
    if (e.kind == PairingEventKind.failed && _answered.contains(id)) setState(() => _answered.remove(id));
  }

  /// Opened for a contact: a pairing made here attaches to it (the attach rules apply).
  Future<void> _attachIfFramed(String id) async {
    final c = widget.contact;
    if (c == null) return;
    final record = ref.read(pairingByIdProvider(id));
    if (record == null || record.contactId == c.id) return;
    await attachPairingTo(context, ref, record, c);
  }

  Future<void> _makeCode({bool fresh = false}) async {
    final l = context.l10n;
    final name = await seenAsForWire(ref);
    if (!mounted) return;
    try {
      final code = await ref.read(pairingApiProvider).standingCode(name: name);
      if (mounted) {
        setState(() {
          _code = code;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = describeError(l, error));
    }
  }

  Future<void> _share({required bool copy}) async {
    final code = _code;
    if (code == null) return;
    await sharePairingMessage(context, ref, context.l10n.pairInviteMessage(pairingInviteText(code, invitePage: ref.read(invitePageProvider))), copy: copy);
  }

  Future<void> _changeName() async {
    final current = ref.read(pairingSeenAsProvider).value ?? '';
    final name = await showKitSheet<String>(context: context, builder: (_) => _NameSheet(initial: current));
    if (name == null || !mounted) return;
    await ref.read(pairingSeenAsProvider.notifier).set(name);
    await _makeCode();
  }

  /// Scan: the camera, then the one handler.
  Future<void> _scan() async {
    final text = await ref.read(qrScannerProvider).scanCode(context);
    if (text == null || !mounted) return;
    await _open(text, byCamera: true);
  }

  /// Paste: the clipboard, read on this press only, then the one handler.
  Future<void> _paste() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    if (!mounted) return;
    await _open(text);
  }

  /// The one handler: a code → Pair with …?; an answer → the finish code here; a finish code
  /// → the words; anything else → Not a pairing code.
  Future<void> _open(String text, {bool byCamera = false}) async {
    final l = context.l10n;
    final notices = ref.read(noticeProvider.notifier);
    // An invite as a page link or bare; a device invite goes to Link a device.
    final invite = parseInvite(text);
    if (invite != null && invite.kind == InviteKind.deviceLink) return openDeviceLinkText(context, ref, invite.invite);
    final kind = pairingLinkKind(invite?.invite ?? text);
    if (kind == null || kind == PairingLinkKind.card) {
      notices.show(l.pairNotACode, level: NoticeLevel.warning);
      return;
    }
    if (kind != PairingLinkKind.reply) {
      await openPairingLink(context, ref, invite?.invite ?? text, contact: widget.contact, byCamera: byCamera, source: byCamera ? InviteSource.scanned : InviteSource.pasted);
      return;
    }
    setState(() => _busy = true);
    try {
      final record = await pairingCall(ref, (api) => api.openReply(pairingLinkIn(text)!));
      _answered.add(record.id);
      if (record.id == _code?.id) unawaited(_makeCode(fresh: true));
      await _attachIfFramed(record.id);
      // After an answer taken by hand the finish code always goes back the same way.
      final finish = await ref.read(pairingApiProvider).confirmLink(record.id);
      if (mounted) {
        setState(() {
          _finishFor = record.id;
          _finishLink = finish;
        });
      }
    } catch (error) {
      if (!mounted) return;
      final failure = pairingFailureOf(error);
      notices.show(failure == null ? describeError(l, error) : pairingFailureText(l, failure), level: NoticeLevel.warning);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareFinish({required bool copy}) async {
    final link = _finishLink;
    if (link == null) return;
    await sharePairingMessage(context, ref, context.l10n.pairFinishLinkMessage(link), copy: copy);
  }

  void _checkWords(String id) => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: id)));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final contact = widget.contact;
    final net = ref.watch(pairNetProvider);
    final seenAs = ref.watch(pairingSeenAsProvider).value ?? '';
    final canShare = ref.watch(slateFilesProvider).canShareText;
    final code = _code;
    final scan = offersQrScan(ref);
    // The status under the code: the framed contact's pending pairing, or one answered here.
    final all = ref.watch(pairingsProvider).value ?? const <PairingRecord>[];
    final followed = <PairingRecord>[
      for (final r in all)
        if (_answered.contains(r.id) || (contact != null && r.contactId == contact.id && (r.state.isPending || r.state == PairingState.waiting))) r,
    ];
    return PairFlowPage(
      title: contact == null ? l.pairTitle : l.pairWithName(contact.name),
      leadingId: TrustIds.pairflowClose,
      children: [
        PairSection(l.pairYourCode),
        Column(
          key: pairCodeKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PairQr(
              data: code == null ? null : pairingInviteText(code, invitePage: ref.watch(invitePageProvider)),
              label: l.pairCodeLabel,
              placeholder: _error == null ? null : Text(_error!, textAlign: TextAlign.center, style: KitType.rowSub.copyWith(color: protocolLight.dim)),
            ),
            const PairGap(14),
            PairNote(contact == null ? l.pairCodeCaption : l.pairCodeCaptionFor(contact.name), center: true),
            const PairGap(14),
            Row(
              children: [
                Expanded(
                  child: KitButton(
                    key: pairShareKey,
                    label: canShare ? l.commonShare : l.commonCopy,
                    icon: canShare ? KitIcons.share : KitIcons.copy,
                    semanticsId: TrustIds.pairflowShare,
                    onPressed: code == null ? null : () => _share(copy: !canShare),
                  ),
                ),
                if (canShare) ...[
                  const SizedBox(width: 8),
                  KitIconButton(
                    key: pairCopyKey,
                    icon: KitIcons.copy,
                    label: l.commonCopy,
                    filled: true,
                    semanticsId: TrustIds.pairflowCopy,
                    onPressed: code == null ? null : () => _share(copy: true),
                  ),
                ],
              ],
            ),
            if (net == PairNet.epicboxOff) ...[const PairGap(8), PairSmallPrint(l.pairEpicboxOffLine)],
          ],
        ),
        const PairGap(),
        KitGroup(
          margin: EdgeInsets.zero,
          children: [
            KitRow(
              key: pairChangeNameKey,
              title: seenAs.isEmpty ? l.pairSeenAsNone : l.pairSeenAsLine(seenAs),
              value: seenAs.isEmpty ? l.pairSeenAsAdd : l.pairChange,
              chevron: true,
              size: KitRowSize.settings,
              semanticsId: TrustIds.pairflowNameRow,
              onTap: _changeName,
            ),
          ],
        ),
        if (_finishFor != null && _finishLink != null) ...[
          const PairGap(),
          _FinishBox(
            name: ref.watch(pairingNameProvider(_finishFor!)),
            link: _finishLink!,
            canShare: canShare,
            onShare: () => _shareFinish(copy: !canShare),
            onCopy: () => _shareFinish(copy: true),
            onCheck: () => _checkWords(_finishFor!),
          ),
        ],
        for (final r in followed)
          if (r.id != _finishFor) ...[
            const PairGap(),
            _StatusLine(record: r, name: ref.watch(pairingNameProvider(r.id)), onCheck: r.sas.isEmpty ? null : () => _checkWords(r.id)),
          ],
        PairSection(contact == null ? l.pairHaveTheirCode : l.pairHaveNamesCode(contact.name)),
        KitGroup(
          margin: EdgeInsets.zero,
          children: [
            if (scan)
              KitRow(
                key: pairScanKey,
                title: l.pairScan,
                leading: const KitIconWell(KitIcons.scan),
                chevron: true,
                semanticsId: TrustIds.pairflowScan,
                onTap: _busy ? null : _scan,
              ),
            KitRow(
              key: pairPasteKey,
              title: l.pairPaste,
              leading: const KitIconWell(KitIcons.paste),
              chevron: true,
              semanticsId: TrustIds.pairflowPaste,
              onTap: _busy ? null : _paste,
            ),
          ],
        ),
      ],
    );
  }
}

/// The status under the code for one pairing in progress: waiting for the answer (a request
/// sent), answered and finishing, or waiting for the other wallet once it answered.
class _StatusLine extends ConsumerWidget {
  const _StatusLine({required this.record, required this.name, this.onCheck});

  final PairingRecord record;
  final String name;
  final VoidCallback? onCheck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final r = record;
    final who = name.isEmpty ? peerLabel(l, r) : name;
    final text = switch (r.state) {
      PairingState.pendingInvite => l.pairWaitingAnswer,
      PairingState.pendingReply => l.pairPairingWith(who),
      PairingState.waiting => l.pairWaitingFor(who),
      _ when r.state.isPaired => l.pairPairedWith(who),
      _ => l.pairAnsweredFinishing(who),
    };
    // Heard from: the pairing is on, nothing more to wait for.
    final done = r.state.isPaired;
    final check = onCheck != null && (r.state == PairingState.waiting || r.state == PairingState.paired || r.state == PairingState.keysChanged);
    return KitGroup(
      margin: EdgeInsets.zero,
      children: [
        Semantics(
          key: pairStatusKey,
          liveRegion: true,
          child: KitRow(
            title: text,
            size: KitRowSize.settings,
            leading: KitIconWell.child(
              done
                  ? Icon(KitIcons.success, size: 22, color: t.ok)
                  : const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
        ),
        if (check)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: KitButton(
                key: pairCheckWordsKey,
                label: l.pairCheckWords,
                kind: KitButtonKind.quiet,
                small: true,
                expand: false,
                semanticsId: TrustIds.pairflowStatusCheck,
                onPressed: onCheck,
              ),
            ),
          ),
      ],
    );
  }
}

/// The finish code box: after an answer taken by hand, the confirm to send back the same way,
/// then the words.
class _FinishBox extends StatelessWidget {
  const _FinishBox({required this.name, required this.link, required this.canShare, required this.onShare, required this.onCopy, required this.onCheck});

  final String name;
  final String link;
  final bool canShare;
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return PairCard(
      key: pairFinishBoxKey,
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text(l.pairFinishCodeTitle, style: KitType.rowTitle.copyWith(color: t.text))),
              const PairGap(6),
              PairSmallPrint(l.pairFinishCodeBody(name)),
              const PairGap(12),
              ShareBox(text: link),
              const PairGap(12),
              KitButton(
                key: pairFinishShareKey,
                label: canShare ? l.commonShare : l.commonCopy,
                icon: canShare ? KitIcons.share : KitIcons.copy,
                semanticsId: TrustIds.pairflowFinishShare,
                onPressed: onShare,
              ),
              if (canShare) ...[
                const PairGap(8),
                KitButton(label: l.commonCopy, icon: KitIcons.copy, kind: KitButtonKind.quiet, semanticsId: TrustIds.pairflowFinishCopy, onPressed: onCopy),
              ],
              const PairGap(8),
              KitButton(key: pairCheckWordsKey, label: l.pairCheckWords, kind: KitButtonKind.quiet, semanticsId: TrustIds.pairflowFinishCheck, onPressed: onCheck),
            ],
          ),
        ),
      ],
    );
  }
}

/// Change "They see you as": one field, one name per wallet; applies to every later code and
/// request, and the paired contacts get the new name.
class _NameSheet extends StatefulWidget {
  const _NameSheet({required this.initial});

  final String initial;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final _text = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final error = seenAsError(context.l10n, _text.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, _text.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return KitSheet(
      title: l.pairSeenAsEdit,
      primary: KitButton(key: pairNameSaveKey, label: l.commonSave, semanticsId: TrustIds.pairflowNameSave, onPressed: _save),
      secondaryLabel: l.commonCancel,
      secondaryId: TrustIds.pairflowNameCancel,
      onSecondary: () => Navigator.pop(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PairField(
              key: pairNameFieldKey,
              controller: _text,
              label: l.pairSeenAsField,
              hint: l.pairSeenAsHint,
              autofocus: true,
              maxLength: 48,
              error: _error,
              semanticsId: TrustIds.pairflowNameField,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _save(),
            ),
            const PairGap(8),
            kitId(TrustIds.pairflowNameSheet, Text(l.pairSeenAsOptional, style: KitType.rowSub.copyWith(color: t.dim))),
          ],
        ),
      ),
    );
  }
}

/// The name that goes on the wire: the one kept, or [unnamedPeerName] when there is none
/// (LEPIC needs 1 to 48 bytes). Never asks.
Future<String> seenAsForWire(WidgetRef ref) async {
  final kept = (await readSeenAs(ref)).trim();
  return kept.isEmpty ? unnamedPeerName : kept;
}

/// The name check of the name they see: an error, or null. Empty is fine (no name).
String? seenAsError(AppLocalizations l, String name) {
  if (utf8.encode(name.trim()).length > 48) return l.pairSeenAsTooLong;
  return null;
}
