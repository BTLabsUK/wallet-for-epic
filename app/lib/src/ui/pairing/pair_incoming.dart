// SPDX-License-Identifier: Apache-2.0
/// A code or request from someone else: "Pair with Anna?" (from a contact, or by code), the
/// wait for the inviter's confirm with the answer to send by hand when the relay cannot carry
/// it, the finish code of an answer opened outside the Pair screen, and one outcome screen
/// per failure. [openPairingLink] is the entry for any pairing link: a scan, a paste, a tapped
/// `epiccash://pair/…`.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contacts.dart';
import '../../errors.dart';
import '../../history/domain_check_book.dart' show DomainStatus;
import '../../key_picture.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../providers.dart' show sessionProvider;
import 'pair_screen.dart' show editSeenAs, ownWalletLabel, seenAsForWire, seenAsLine;
import '../../pairing_text.dart';
import '../../slate_files.dart';
import '../../tor_build.dart';
import '../../updater.dart' show updateProvider;
import '../../wallet_service.dart';
import '../common.dart';
import '../address_view.dart' show ShortAddressText;
import '../key_picture.dart';
import '../kit/kit_button.dart';
import '../kit/kit_chip.dart';
import '../kit/kit_group.dart';
import '../kit/kit_icons.dart';
import '../kit/kit_row.dart';
import '../kit/kit_sheet.dart';
import '../kit/kit_support.dart' show kitId;
import '../kit/kit_tokens.dart';
import '../theme/tokens.dart';
import '../../trust_ids.dart';
import 'pair_flow.dart';
import 'invite_links.dart';
import 'pair_check.dart';
import 'pairing_clip_offer.dart';
import 'pairing_notices.dart' show pairingWordsOnScreen;
import 'pairing_parts.dart';

/// Keys for tests.
const Key incomingPairKey = ValueKey('incoming-pair');
const Key incomingNotNowKey = ValueKey('incoming-not-now');
const Key incomingServerKey = ValueKey('incoming-server');
const Key incomingSourceKey = ValueKey('incoming-source');
const Key incomingSeenAsKey = ValueKey('incoming-seen-as');
const Key incomingExpiresKey = ValueKey('incoming-expires');
const Key waitingCancelKey = ValueKey('waiting-cancel');
const Key waitingAnswerBoxKey = ValueKey('waiting-answer-box');
const Key waitingShareKey = ValueKey('waiting-share');
const Key waitingFinishFieldKey = ValueKey('waiting-finish-field');
const Key waitingFinishGoKey = ValueKey('waiting-finish-go');
const Key finishScreenShareKey = ValueKey('finish-share');
const Key finishScreenCheckKey = ValueKey('finish-check');

/// Opens the pairing link in [pasted] (a code, an answer or a finish code): the incoming
/// sheet, the finish code to send, the words check, or the notice that says why not.
/// [contact] is the address-book contact the pairing attaches to, when known. With [replace]
/// the screen that opens takes the place of the current one. Text without a pairing link,
/// or an older in-person card, is "Not a pairing code". [source] is how the text came, for the
/// pair request's Source row; [byCamera] alone counts as scanned. [onConfirmed] takes a
/// confirmation that is not Verified yet, in place of the push of the words.
Future<void> openPairingLink(
  BuildContext context,
  WidgetRef ref,
  String pasted, {
  Contact? contact,
  bool replace = false,
  bool byCamera = false,
  InviteSource? source,
  Future<void> Function(PairingRecord record)? onConfirmed,
}) async {
  source ??= byCamera ? InviteSource.scanned : null;
  // A page link carries the invite in its fragment; a message holds the bare text among words.
  final bare = parseInvite(pasted)?.invite ?? pasted;
  final kind = pairingLinkKind(bare);
  final notices = ref.read(noticeProvider.notifier);
  final l = context.l10n;
  if (kind == null || kind == PairingLinkKind.card) {
    notices.show(l.pairNotACode, level: NoticeLevel.warning);
    return;
  }
  final text = pairingLinkIn(bare)!;
  final api = ref.read(pairingApiProvider);
  final nav = Navigator.of(context);
  Future<void> show(Widget screen) =>
      replace ? nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => screen)) : nav.push(MaterialPageRoute<void>(builder: (_) => screen));
  // The pairings already finished before this link: a late answer or finish code changes nothing.
  var before = const <PairingRecord>[];
  try {
    before = await ref.read(pairingsProvider.future);
  } on Object {
    // No list: nothing counts as finished before.
  }
  final doneBefore = {
    for (final r in before)
      if (r.state.isRecord) r.id,
  };
  bool already(PairingRecord r) {
    if (!doneBefore.contains(r.id)) return false;
    final name = ref.read(pairingNameProvider(r.id));
    notices.show(l.pairAlreadyPaired(name.isEmpty ? peerLabel(l, r) : name), level: NoticeLevel.info);
    return true;
  }

  try {
    switch (kind) {
      case PairingLinkKind.invite:
        final preview = await api.openInvite(text);
        if (context.mounted) await showIncomingInvite(context, ref, preview, contact: contact, replace: replace, source: source);
      case PairingLinkKind.reply:
        // Their answer came by hand: the finish code goes back the same way, then the words.
        final record = await pairingCall(ref, (a) => a.openReply(text));
        if (already(record)) return;
        if (contact != null && record.contactId != contact.id && context.mounted) await attachPairingTo(context, ref, record, contact);
        await show(FinishCodeScreen(pairingId: record.id));
      case PairingLinkKind.confirm:
        final record = await pairingCall(ref, (a) => a.openConfirm(text));
        if (already(record)) return;
        if (record.state == PairingState.verified) {
          notices.show(l.pairPairedWith(ref.read(pairingNameProvider(record.id))), level: NoticeLevel.success);
          return;
        }
        if (onConfirmed != null) {
          await onConfirmed(record);
        } else {
          await show(CheckWordsScreen(pairingId: record.id));
        }
      case PairingLinkKind.card:
        return;
    }
  } catch (error) {
    final failure = pairingFailureOf(error);
    if (failure == null) rethrow;
    if (!context.mounted) return;
    notices.show(pairingFailureText(l, failure), level: NoticeLevel.warning);
  }
}

/// "Pair with Anna?" for [preview]. Pair answers it and opens the wait for the confirm.
/// [source] is how the invite came (see [InviteSource]).
Future<void> showIncomingInvite(
  BuildContext context,
  WidgetRef ref,
  PairingInvitePreview preview, {
  Contact? contact,
  bool replace = false,
  InviteSource? source,
}) async {
  final answered = await showKitSheet<PairingRecord>(
    context: context,
    builder: (_) => IncomingInviteSheet(preview: preview, contact: contact, source: source),
  );
  if (answered == null || !context.mounted) return;
  final screen = PairingWaitingScreen(pairingId: answered.id, name: preview.name);
  final nav = Navigator.of(context);
  await (replace ? nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => screen)) : nav.push(MaterialPageRoute<void>(builder: (_) => screen)));
}

/// The sheet, in two forms: from a contact (the request's sender is in Contacts: avatar, "In
/// your contacts", the sender address) or by code (the name alone, no chip). When the invite
/// has a key, its key picture takes the avatar's place; a BT Labs service shows its listed
/// name and a green check after it instead of the claimed name. Under it what pairing does,
/// then the facts the invite really carries: its server, how it came, the time it has left.
/// Pair · Not now; no name field, no invoice switch. Pops with the answered record.
class IncomingInviteSheet extends ConsumerStatefulWidget {
  const IncomingInviteSheet({super.key, required this.preview, this.contact, this.source});

  final PairingInvitePreview preview;
  final Contact? contact;

  /// How the invite came; null shows no Source row (a request has its own).
  final InviteSource? source;

  @override
  ConsumerState<IncomingInviteSheet> createState() => _IncomingInviteSheetState();
}

class _IncomingInviteSheetState extends ConsumerState<IncomingInviteSheet> {
  bool _busy = false;

  /// The contact the request came from, when its sender is in Contacts.
  Contact? _sender() {
    final from = widget.preview.fromAddress;
    if (from == null) return widget.contact;
    final contacts = ref.read(contactsProvider).value ?? const <Contact>[];
    final key = epicboxKey(from);
    return contacts.where((c) => c.epicbox != null && epicboxKey(c.epicbox!) == key).firstOrNull ?? widget.contact;
  }

  Future<void> _pair() async {
    final l = context.l10n;
    final name = await seenAsForWire(ref);
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final record = await pairingCall(
        ref,
        (api) => api.acceptInvite(
          token: widget.preview.token,
          name: name,
          contactId: _sender()?.id,
          byHand: ref.read(pairNetProvider) != PairNet.online,
        ),
      );
      if (mounted) Navigator.pop(context, record);
    } catch (error) {
      if (!mounted) return;
      final failure = pairingFailureOf(error);
      Navigator.pop(context);
      ref.read(noticeProvider.notifier).show(
        failure == null ? describeError(l, error) : pairingFailureText(l, failure, name: widget.preview.name),
        level: NoticeLevel.warning,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final p = widget.preview;
    final sender = p.isRequest ? _sender() : null;
    // A key on the BT Labs list is a service of ours: its listed name replaces the claimed one.
    final key = p.inviteKey;
    final btlabs = sender == null && key != null ? btLabsKeyOf(key) : null;
    final name = sender?.name ?? btlabs?.name ?? p.name;
    final noName = sender == null && btlabs == null && isUnnamed(p.name);
    // No name at all: the start of the sender's address when a request carries it, else Unknown.
    final tag = walletTag(p.fromAddress);
    final unnamedLabel = tag == null ? l.commonUnknown : l.phonePairUnnamedShort(tag);
    final shown = noName ? unnamedLabel : name;
    final seenAs = ref.watch(pairingSeenAsProvider).value ?? '';
    final ownLabel = ownWalletLabel(l, ref);
    final host = relayHostOf(p.homeRelay);
    final source = inviteSourceText(l, widget.source, request: p.isRequest);
    return kitId(
      TrustIds.pairflowInviteSheet,
      KitSheet(
        title: l.pairIncomingTitle(shown),
        primary: KitButton(key: incomingPairKey, label: l.pairTitle, semanticsId: TrustIds.pairflowInvitePair, onPressed: _busy ? null : _pair),
        secondary: KitButton(
          key: incomingNotNowKey,
          label: l.pairNotNow,
          kind: KitButtonKind.quiet,
          semanticsId: TrustIds.pairflowInviteNotNow,
          onPressed: _busy ? null : () => Navigator.pop(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: key != null
                  ? KeyPictureView(picture: KeyPicture.of(key), size: 72, framed: true)
                  : PairAvatar(name: noName ? unnamedLabel : name, size: 72),
            ),
            const PairGap(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text(shown, textAlign: TextAlign.center, style: KitType.rowTitle.copyWith(color: t.text), maxLines: 2, overflow: TextOverflow.ellipsis)),
                if (btlabs != null) ...[
                  const SizedBox(width: 6),
                  VerifiedCheck(label: l.pairVerifiedService, colour: t.ok),
                ],
              ],
            ),
            if (sender != null) ...[
              const PairGap(8),
              Center(child: KitChip(l.pairInContacts, icon: KitIcons.contact, info: true)),
            ],
            if (p.fromAddress case final from?) ...[
              const PairGap(8),
              Center(child: ShortAddressText(from, style: KitType.rowSub.copyWith(color: t.dim))),
            ],
            const PairGap(14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(p.isRequest ? l.pairIncomingBodyRequest(shown) : l.pairIncomingBody(shown), style: KitType.body.copyWith(color: t.dim)),
            ),
            const PairGap(14),
            KitGroup(
              onSheet: true,
              dividerInset: Kit.dividerInsetPlain,
              children: [
                if (host.isNotEmpty)
                  KitRow(
                    key: incomingServerKey,
                    title: l.pairIncomingServer,
                    size: KitRowSize.sheet,
                    trailing: Flexible(child: Text(host, style: KitType.rowSub.copyWith(fontFamily: t.monoFamily, color: t.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ),
                KitRow(
                  key: incomingSeenAsKey,
                  title: seenAsLine(l, seenAs, ownLabel),
                  value: seenAs.isEmpty && ownLabel == null ? l.pairSeenAsAdd : l.pairChange,
                  chevron: true,
                  size: KitRowSize.sheet,
                  semanticsId: TrustIds.pairflowInviteNameRow,
                  onTap: _busy ? null : () => editSeenAs(context, ref),
                ),
                if (source != null) KitRow(key: incomingSourceKey, title: l.pairIncomingSource, size: KitRowSize.sheet, value: source),
                KitRow(
                  key: incomingExpiresKey,
                  title: l.pairExpiresIn,
                  size: KitRowSize.sheet,
                  trailing: PairTimeLeft(until: p.expiresAt, style: KitType.rowSub.copyWith(color: t.text)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The answerer's wait for the confirm (RFC 7.3, 8.2): "Pairing with Anna…", Cancel,
/// collects every 5 s while open. After [pairReplyFallbackAfter] (at once when Epicbox is off
/// or the wallet is Offline, or the relay did not take the answer) the Your answer box: a QR,
/// Share / Copy, and a field for the finish code that comes back by hand. The confirm opens
/// the words check (a request ends Verified with a notice instead). It can be closed: the
/// pairing goes on in the background.
///
/// The screen stays one route from the answer to the end: the wait, then the words at once (a
/// name service's code check or a contact's proven domain take over the same screen when they
/// arrive), then the result, each step giving way to the next in place.
class PairingWaitingScreen extends ConsumerStatefulWidget {
  const PairingWaitingScreen({super.key, required this.pairingId, this.name = ''});

  final String pairingId;

  /// The inviter's name from its code, until the records have it.
  final String name;

  @override
  ConsumerState<PairingWaitingScreen> createState() => _PairingWaitingScreenState();
}

/// Where the answered code's screen stands.
enum _Stage { waiting, words, result }

class _PairingWaitingScreenState extends ConsumerState<PairingWaitingScreen> {
  _Stage _stage = _Stage.waiting;

  /// The contact's domain when it proved the pairing.
  String? _domain;

  /// The result is Verified by the domain, not by the words.
  bool _byDomain = false;
  void Function()? _unboost;
  Timer? _slow;
  bool _late = false;
  bool _left = false;

  /// The records were read again after this screen opened. The list from before the answer
  /// does not hold it yet: its absence there is no sign that the pairing went.
  bool _fresh = false;
  String? _link;
  final _finish = TextEditingController();
  StreamSubscription<PairingEvent>? _events;
  bool _onScreen(PairingEvent e) => e.pairingId == widget.pairingId;

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
    pairingStepsOnScreen[widget.pairingId] = () => mounted && (ModalRoute.of(context)?.isCurrent ?? false);
    final api = ref.read(pairingApiProvider);
    if (ref.read(pairNetProvider) == PairNet.online) {
      _unboost = boostRelays(ref.read(sessionProvider)?.boosts, boostMinInterval);
      _slow = Timer(pairReplyFallbackAfter, () => mounted ? setState(() => _late = true) : null);
    } else {
      _late = true;
    }
    _events = api.events().listen((e) {
      if (e.pairingId != widget.pairingId || !mounted || _left) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      if (e.kind == PairingEventKind.confirmed) unawaited(_finished());
      if (e.kind == PairingEventKind.failed && e.failure != null) {
        _left = true;
        Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => PairingOutcomeScreen(failure: e.failure!, name: e.name)));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLink();
      ref.read(pairingsProvider.notifier).reload().then((_) => mounted ? setState(() => _fresh = true) : null).ignore();
    });
  }

  Future<void> _loadLink() async {
    try {
      final link = await ref.read(pairingApiProvider).replyLink(widget.pairingId);
      if (mounted) setState(() => _link = link);
    } catch (_) {
      // Gone already: the build below leaves.
    }
  }

  /// The confirm is in: a request ends Verified (no words), a code opens the words. The
  /// provider's records are read again by a pairing event, so they may still be the old ones
  /// here: the wallet is asked for this pairing, and the words open whenever it cannot be seen
  /// Verified.
  Future<void> _finished() async {
    _left = true;
    final api = ref.read(pairingApiProvider);
    PairingRecord? record;
    try {
      record = await api.pairing(widget.pairingId);
    } on Object {
      // Not read: the words are the safe way on.
    }
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (record != null && record.state == PairingState.verified && record.domainStatus == DomainStatus.proven && record.peerDomain != null) {
      // The domain's proof was in before the words were: Verified by it, in place.
      _unboost?.call();
      _unboost = null;
      _slow?.cancel();
      setState(() {
        _domain = record!.peerDomain;
        _byDomain = true;
        _stage = _Stage.result;
      });
      return;
    }
    if (record != null && record.state == PairingState.verified) {
      ref.read(noticeProvider.notifier).show(context.l10n.pairPairedWith(_name), level: NoticeLevel.success);
      nav.pop();
      return;
    }
    // The wait is over: its timers go, the words step boosts the relays for itself.
    _unboost?.call();
    _unboost = null;
    _slow?.cancel();
    // The words at once: a domain's proof (started by the service) or a name service's hello
    // upgrades this same screen when it arrives.
    setState(() => _stage = _Stage.words);
  }

  /// The words matched: the result, in place.
  void _matched(PairingRecord record) {
    if (!mounted) return;
    setState(() {
      _byDomain = false;
      _stage = _Stage.result;
    });
  }

  /// The domain's proof came while the words were shown: Verified, in place.
  void _provenLate() {
    if (!mounted || _stage != _Stage.words) return;
    setState(() {
      _domain = ref.read(pairingByIdProvider(widget.pairingId))?.peerDomain ?? _domain;
      _byDomain = _domain != null;
      _stage = _Stage.result;
    });
  }

  String get _name {
    final known = ref.read(pairingNameProvider(widget.pairingId));
    return known.isEmpty ? widget.name : known;
  }

  @override
  void dispose() {
    pairingWordsOnScreen.remove(_onScreen);
    pairingStepsOnScreen.remove(widget.pairingId);
    _unboost?.call();
    _slow?.cancel();
    _events?.cancel();
    _finish.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    final l = context.l10n;
    final sure = await confirmCancelPairing(context, _name);
    if (!sure || !mounted) return;
    _left = true;
    await pairingCall(ref, (api) => api.cancelInvite(widget.pairingId));
    if (mounted) {
      ref.read(noticeProvider.notifier).show(l.pairCancelledTitle(_name), level: NoticeLevel.info);
      Navigator.pop(context);
    }
  }

  Future<void> _share({required bool copy}) async {
    final link = _link;
    if (link == null) return;
    await sharePairingMessage(context, ref, context.l10n.pairReplyMessage(link), copy: copy);
  }

  Future<void> _pasteFinish() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    if (!mounted) return;
    _finish.text = text;
    await _openFinish();
  }

  Future<void> _openFinish() async {
    final l = context.l10n;
    final text = _finish.text;
    if (pairingLinkKind(text) != PairingLinkKind.confirm) {
      ref.read(noticeProvider.notifier).show(l.pairNotACode, level: NoticeLevel.warning);
      return;
    }
    _left = true;
    await openPairingLink(
      context,
      ref,
      text,
      onConfirmed: (record) async {
        if (!mounted) return;
        if (record.id == widget.pairingId) {
          _left = false;
          await _finished();
        } else {
          await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: record.id)));
        }
      },
    );
    if (mounted && _stage == _Stage.waiting && (ModalRoute.of(context)?.isCurrent ?? false)) _left = false;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final record = ref.watch(pairingByIdProvider(widget.pairingId));
    final loaded = ref.watch(pairingsProvider).hasValue;
    // Nothing to wait for any more (the confirm came another way, or the pairing was
    // cancelled): this screen goes.
    if (loaded && _fresh && !_left && (record == null || record.state != PairingState.pendingReply)) {
      _left = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final route = ModalRoute.of(context);
        if (route == null) return;
        if (!route.isCurrent) {
          Navigator.of(context).removeRoute(route);
        } else if (record != null && record.state.isRecord) {
          _left = false;
          _finished();
        } else {
          Navigator.of(context).pop();
        }
      });
    }
    final name = _name;
    final net = ref.watch(pairNetProvider);
    final byHand = _late || (record?.relayDown ?? false) || net != PairNet.online;
    final canShare = ref.watch(slateFilesProvider).canShareText;
    final link = _link;
    final Widget step = switch (_stage) {
      _Stage.waiting => _waiting(l, t, name: name, byHand: byHand, canShare: canShare, link: link),
      _Stage.words => CheckWordsScreen(pairingId: widget.pairingId, onMatched: _matched, onDomainVerified: _provenLate),
      _Stage.result => PairingResultScreen(pairingId: widget.pairingId, domain: _byDomain ? _domain : null, onCheckNow: () => setState(() => _stage = _Stage.words)),
    };
    return PairFlowStage(stepKey: _stage, child: step);
  }

  Widget _waiting(AppLocalizations l, WalletTokens t, {required String name, required bool byHand, required bool canShare, required String? link}) {
    return PairFlowPage(
      title: l.pairWaitingTitleShort,
      leadingId: TrustIds.pairflowWaitingClose,
      bottom: KitButton(
        key: waitingCancelKey,
        label: l.commonCancel,
        kind: KitButtonKind.quiet,
        semanticsId: TrustIds.pairflowWaitingCancel,
        onPressed: _cancel,
      ),
      children: [
        const PairGap(10),
        Semantics(
          header: true,
          liveRegion: true,
          child: Row(
            children: [
              const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
              const SizedBox(width: 12),
              Expanded(child: Text(l.pairPairingWith(name), style: KitType.sheetTitle.copyWith(color: t.text))),
            ],
          ),
        ),
        if (byHand) ...[
          const PairGap(18),
          PairCard(
            key: waitingAnswerBoxKey,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.pairByHandYourAnswer, style: KitType.rowTitle.copyWith(color: t.text)),
                    const PairGap(6),
                    PairSmallPrint(l.pairYourAnswerBody),
                    if (link != null) ...[
                      const PairGap(14),
                      PairQr(data: link, size: 180, label: l.pairByHandYourAnswer),
                      const PairGap(14),
                      Row(
                        children: [
                          Expanded(
                            child: KitButton(
                              key: waitingShareKey,
                              label: canShare ? l.commonShare : l.commonCopy,
                              icon: canShare ? KitIcons.share : KitIcons.copy,
                              small: true,
                              semanticsId: TrustIds.pairflowWaitingShare,
                              onPressed: () => _share(copy: !canShare),
                            ),
                          ),
                          if (canShare) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: KitButton(
                                label: l.commonCopy,
                                icon: KitIcons.copy,
                                small: true,
                                kind: KitButtonKind.quiet,
                                semanticsId: TrustIds.pairflowWaitingCopy,
                                onPressed: () => _share(copy: true),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const PairGap(16),
                    PairField(
                      key: waitingFinishFieldKey,
                      controller: _finish,
                      label: l.pairPasteFinishField,
                      maxLines: 3,
                      semanticsId: TrustIds.pairflowWaitingFinishField,
                      onSubmitted: (_) => _openFinish(),
                    ),
                    const PairGap(8),
                    Row(
                      children: [
                        Expanded(
                          child: KitButton(
                            label: l.pairPaste,
                            icon: KitIcons.paste,
                            small: true,
                            kind: KitButtonKind.quiet,
                            semanticsId: TrustIds.pairflowWaitingPaste,
                            onPressed: _pasteFinish,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: KitButton(key: waitingFinishGoKey, label: l.pairTitle, small: true, semanticsId: TrustIds.pairflowWaitingFinishGo, onPressed: _openFinish),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Asks before cancelling the pairing with [name]; true to cancel.
Future<bool> confirmCancelPairing(BuildContext context, String name) {
  final l = context.l10n;
  return confirmPairSheet(
    context,
    title: l.pairCancelPairingTitle,
    body: l.pairCancelPairingBody(name),
    action: l.pairCancelPairing,
    cancel: l.contactKeep,
    risky: true,
    sheetId: TrustIds.pairflowCancelSheet,
    actionId: TrustIds.pairflowCancelConfirm,
    cancelId: TrustIds.pairflowCancelKeep,
  );
}

/// An answer opened outside the Pair screen (a scan, a tapped link): the finish code to send
/// back the way the answer came, then the words.
class FinishCodeScreen extends ConsumerStatefulWidget {
  const FinishCodeScreen({super.key, required this.pairingId});

  final String pairingId;

  @override
  ConsumerState<FinishCodeScreen> createState() => _FinishCodeScreenState();
}

class _FinishCodeScreenState extends ConsumerState<FinishCodeScreen> {
  String? _link;
  String? _error;
  bool _onScreen(PairingEvent e) => e.pairingId == widget.pairingId;

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final link = await ref.read(pairingApiProvider).confirmLink(widget.pairingId);
        if (mounted) setState(() => _link = link);
      } catch (error) {
        if (mounted) setState(() => _error = describeError(context.l10n, error));
      }
    });
  }

  @override
  void dispose() {
    pairingWordsOnScreen.remove(_onScreen);
    super.dispose();
  }

  Future<void> _share({required bool copy}) async {
    final link = _link;
    if (link == null) return;
    await sharePairingMessage(context, ref, context.l10n.pairFinishLinkMessage(link), copy: copy);
  }

  void _check() => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: widget.pairingId)));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final name = ref.watch(pairingNameProvider(widget.pairingId));
    final link = _link;
    final canShare = ref.watch(slateFilesProvider).canShareText;
    final record = ref.watch(pairingByIdProvider(widget.pairingId));
    return PairFlowPage(
      title: l.pairWaitingTitleShort,
      leadingId: TrustIds.pairflowFinishClose,
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KitButton(
            key: finishScreenShareKey,
            label: canShare ? l.commonShare : l.commonCopy,
            icon: canShare ? KitIcons.share : KitIcons.copy,
            semanticsId: TrustIds.pairflowFinishScreenShare,
            onPressed: link == null ? null : () => _share(copy: !canShare),
          ),
          const PairGap(10),
          KitButton(
            key: finishScreenCheckKey,
            label: l.pairCheckWords,
            kind: KitButtonKind.quiet,
            semanticsId: TrustIds.pairflowFinishScreenCheck,
            onPressed: record == null || record.sas.isEmpty ? null : _check,
          ),
        ],
      ),
      children: [
        const PairGap(10),
        Semantics(header: true, child: Text(l.pairFinishCodeTitle, style: KitType.sheetTitle.copyWith(color: t.text))),
        const PairGap(8),
        PairLead(l.pairFinishCodeBody(name)),
        const PairGap(16),
        if (_error != null) PairEdgeNotice(tone: BadgeTone.risk, title: _error!),
        if (link != null) ShareBox(text: l.pairFinishLinkMessage(link)),
      ],
    );
  }
}

/// One outcome of a pairing that ended: a card centred on the screen and Close. [name] is
/// the other side's, where the sentence names it.
class PairingOutcomeScreen extends ConsumerWidget {
  const PairingOutcomeScreen({super.key, required this.failure, this.name = '', this.file = false});

  final PairingFailure failure;
  final String name;
  final bool file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tone = switch (failure) {
      PairingFailure.changedOnTheWay || PairingFailure.sealedForOther || PairingFailure.otherWallet => BadgeTone.risk,
      PairingFailure.cancelled || PairingFailure.newerVersion || PairingFailure.crossed => BadgeTone.info,
      _ => BadgeTone.warn,
    };
    final close = KitButton(label: l.pairClosed, semanticsId: TrustIds.pairflowOutcomeClose, onPressed: () => Navigator.pop(context));
    // No in-app updates in the build without Tor: Close alone.
    final Widget bottom = failure == PairingFailure.newerVersion && inAppUpdates
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KitButton(
                label: l.pairCheckForUpdates,
                semanticsId: TrustIds.pairflowOutcomeUpdate,
                onPressed: () {
                  ref.read(updateProvider.notifier).check();
                  ref.read(noticeProvider.notifier).show(l.updateChecking, level: NoticeLevel.info);
                },
              ),
              const PairGap(10),
              KitButton(label: l.pairClosed, kind: KitButtonKind.quiet, semanticsId: TrustIds.pairflowOutcomeClose, onPressed: () => Navigator.pop(context)),
            ],
          )
        : close;
    return PairFlowPage(
      title: l.pairWaitingTitleShort,
      leadingId: TrustIds.pairflowOutcomeBack,
      bottom: bottom,
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.14),
        PairEdgeNotice(
          tone: tone,
          title: pairingFailureText(l, failure, name: name),
          body: pairingFailureBody(l, failure, name: name, file: file),
        ),
      ],
    );
  }
}
