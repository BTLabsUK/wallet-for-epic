// SPDX-License-Identifier: Apache-2.0
/// An invite from someone else: "Pair with Anna?", the answer and the wait for the
/// inviter's confirm, the answer by hand when no relay answers, and one outcome screen per
/// case of the cases file. [openPairingLink] is the entry for any pairing link: a scan, a
/// paste, a tapped `epiccash://pair/…`.
library;

import '../phone_sheet.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../wallet_service.dart';
import '../../pairing_text.dart';
import '../../phone_tor.dart' show epicboxOverTorProvider;
import '../../slate_files.dart';
import '../../tor_build.dart';
import '../../updater.dart' show updateProvider;
import '../common.dart';
import '../theme/tokens.dart';
import 'pair_check.dart';
import 'pair_screen.dart';
import 'pair_steps.dart';
import 'pairing_clip_offer.dart';
import 'pairing_notices.dart' show pairingWordsOnScreen;
import 'pairing_parts.dart';

/// Keys for tests.
const Key incomingPairKey = ValueKey('incoming-pair');
const Key incomingNotNowKey = ValueKey('incoming-not-now');
const Key incomingAllowKey = ValueKey('incoming-allow');
const Key waitingByHandKey = ValueKey('waiting-by-hand');
const Key byHandCheckWordsKey = ValueKey('by-hand-check-words');
const Key waitingPasteFinishKey = ValueKey('waiting-paste-finish');
const Key replyShareKey = ValueKey('reply-share');
const Key replyCopyKey = ValueKey('reply-copy');
const Key finishShareKey = ValueKey('finish-share');
const Key finishCheckKey = ValueKey('finish-check');

/// Opens the pairing link in [pasted] (an invite, a reply or finish link of Invite by message,
/// or a card): the incoming sheet, the finish link to send, the words check, or the screen
/// that says why not. [contact] is the address-book contact the pairing attaches to, when
/// known. With [replace] the screen that opens takes the place of the current one. Text
/// without a pairing link does nothing. A reply or finish link of a pairing that finished
/// already (the relay was faster) only says so; one whose message step is on screen
/// ([pairingStepsOnScreen]) leaves the next screen to that step.
Future<void> openPairingLink(
  BuildContext context,
  WidgetRef ref,
  String pasted, {
  Contact? contact,
  bool replace = false,
  bool byCamera = false,
}) async {
  final kind = pairingLinkKind(pasted);
  if (kind == null) return;
  // A shared message holds the link among words: the calls take the link alone.
  final text = pairingLinkIn(pasted)!;
  final api = ref.read(pairingApiProvider);
  final nav = Navigator.of(context);
  final notices = ref.read(noticeProvider.notifier);
  final l = context.l10n;
  // A step on top of the navigator moves on by itself; one under another screen does not.
  bool stepOnTop(String id) => pairingStepsOnScreen[id]?.call() ?? false;
  Future<void> show(Widget screen) =>
      replace ? nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => screen)) : nav.push(MaterialPageRoute<void>(builder: (_) => screen));
  // The pairings already finished before this link: a late reply or finish link changes nothing.
  var before = const <PairingRecord>[];
  try {
    before = await ref.read(pairingsProvider.future);
  } on Object {
    // No list: nothing counts as finished before.
  }
  final pairedBefore = {
    for (final r in before)
      if (r.state.isPaired) r.id,
  };
  bool already(PairingRecord r) {
    if (!pairedBefore.contains(r.id)) return false;
    notices.show(l.pairAlreadyPaired(ref.read(pairingNameProvider(r.id)).isEmpty ? r.shownName : ref.read(pairingNameProvider(r.id))), level: NoticeLevel.info);
    return true;
  }

  try {
    switch (kind) {
      case PairingLinkKind.invite:
        final preview = await api.openInvite(text);
        if (context.mounted) await showIncomingInvite(context, ref, preview, contact: contact, replace: replace);
      case PairingLinkKind.reply:
        // Their reply came in the chat: the finish link goes back the same way before the
        // words, which their wallet shows only once it has it.
        final record = await pairingCall(ref, (a) => a.openReply(text));
        if (already(record) || stepOnTop(record.id)) return;
        await show(PairFinishScreen(pairingId: record.id));
      case PairingLinkKind.confirm:
        final record = await pairingCall(ref, (a) => a.openConfirm(text));
        if (already(record) || stepOnTop(record.id)) return;
        await show(CheckWordsScreen(pairingId: record.id));
      case PairingLinkKind.card:
        // Their code was scanned first: show this phone's, and the pairing follows.
        await show(InPersonScreen(contact: contact, scanned: text, scannedByCamera: byCamera));
    }
  } catch (error) {
    final failure = pairingFailureOf(error);
    if (failure == null) rethrow;
    // A reply no invite of this wallet's opens: the other side answered someone else's.
    if (kind == PairingLinkKind.reply && failure == PairingFailure.notFound) {
      notices.show(l.pairReplyNotHere, level: NoticeLevel.warning);
      return;
    }
    await show(PairingOutcomeScreen(failure: failure));
  }
}

/// "Pair with Anna?" for [preview]. Pair answers it; an invite that came as a link
/// ([viaLink]) opens the reply to send back (Invite by message, step 2), one found by its
/// words the wait for the confirm.
Future<void> showIncomingInvite(
  BuildContext context,
  WidgetRef ref,
  PairingInvitePreview preview, {
  Contact? contact,
  bool replace = false,
  bool viaLink = true,
}) async {
  final answered = await showPhoneSheet<PairingRecord>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => IncomingInviteSheet(preview: preview, contact: contact),
  );
  if (answered == null || !context.mounted) return;
  // A link came in a message: the reply goes back the same way (it also goes to the relay).
  // Words: the relay carries the answer, and the wait follows.
  final Widget screen = viaLink ? PairReplyScreen(pairingId: answered.id, name: preview.name) : PairingWaitingScreen(pairingId: answered.id);
  final nav = Navigator.of(context);
  await (replace ? nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => screen)) : nav.push(MaterialPageRoute<void>(builder: (_) => screen)));
}

/// The sheet: the claimed name marked as such, what pairing does, the expiry; an invite that
/// asks for invoices offers the switch, off until the user turns it on (the name and kind are
/// the inviter's claim). Pops with the answered record.
class IncomingInviteSheet extends ConsumerStatefulWidget {
  const IncomingInviteSheet({super.key, required this.preview, this.contact});

  final PairingInvitePreview preview;
  final Contact? contact;

  @override
  ConsumerState<IncomingInviteSheet> createState() => _IncomingInviteSheetState();
}

class _IncomingInviteSheetState extends ConsumerState<IncomingInviteSheet> {
  bool _allow = false;
  bool _busy = false;
  String? _nameError;

  /// No name kept when the sheet opened: the field stays while one is typed (the name is
  /// current at every key, so it would go after the first letter).
  bool _askName = false;

  Future<void> _pair() async {
    final l = context.l10n;
    final name = ref.read(pairingSeenAsProvider).value ?? '';
    final error = seenAsError(l, name);
    setState(() => _nameError = error);
    if (error != null) return;
    setState(() => _busy = true);
    try {
      final record = await pairingCall(
        ref,
        (api) => api.acceptInvite(
          token: widget.preview.token,
          name: name.trim(),
          allowInvoices: _allow,
          contactId: widget.contact?.id,
          byHand: ref.read(pairNetProvider) != PairNet.online,
        ),
      );
      if (mounted) Navigator.pop(context, record);
    } catch (error) {
      if (!mounted) return;
      final failure = pairingFailureOf(error);
      Navigator.pop(context);
      if (failure != null) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => PairingOutcomeScreen(failure: failure, name: widget.preview.name)),
        );
      } else {
        ref.read(noticeProvider.notifier).show(describeError(l, error), level: NoticeLevel.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final p = widget.preview;
    final seenAs = ref.watch(pairingSeenAsProvider);
    if (seenAs.hasValue && (seenAs.value ?? '').trim().isEmpty) _askName = true;
    final needsName = _askName || _nameError != null;
    // The keyboard too: a modal sheet is not lifted by it on edge-to-edge Android.
    final media = MediaQuery.of(context);
    final foot = math.max(media.padding.bottom, media.viewInsets.bottom);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + foot),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PairAvatar(name: p.name, kind: p.kind, size: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text(l.pairIncomingTitle(p.name), style: theme.textTheme.titleLarge)),
                    const SizedBox(height: 6),
                    const ClaimedNameBadge(long: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(l.pairIncomingBody(p.name), style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
          if (p.asksInvoices && ref.watch(invoicesOnProvider)) ...[
            const SizedBox(height: 14),
            PairCard(
              children: [
                PairSwitchRow(
                  switchKey: incomingAllowKey,
                  label: l.pairIncomingAllowInvoices(p.name),
                  info: '',
                  hint: l.pairIncomingAllowHint,
                  value: _allow,
                  onChanged: _busy ? null : (v) => setState(() => _allow = v),
                ),
              ],
            ),
          ],
          if (needsName) ...[
            const SizedBox(height: 14),
            SeenAsField(error: _nameError, onChanged: (_) => setState(() => _nameError = null)),
          ],
          const SizedBox(height: 14),
          PairCountdown(until: p.expiresAt, label: l.pairExpiresIn),
          const SizedBox(height: 20),
          // The primary over the secondary, as every foot on the phone (UP-029).
          FilledButton(
            key: incomingPairKey,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : _pair,
            child: _busy
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l.pairTitle),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: incomingNotNowKey,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(l.pairNotNow),
          ),
        ],
      ),
    );
  }
}

/// The answerer's wait for the confirm (RFC 7.3, 8.2): collects every 5 s while open, says
/// when the relay could not take the answer, and opens the words check when the confirm
/// arrives. It can be closed: the pairing goes on in the background.
class PairingWaitingScreen extends ConsumerStatefulWidget {
  const PairingWaitingScreen({super.key, required this.pairingId, this.byMessage = false, this.name = ''});

  final String pairingId;

  /// The inviter's name from its invite, until the records have it.
  final String name;

  /// Invite by message, step 3: the finish link comes back in the chat (Paste finish link, or
  /// the clipboard offer), or through a relay by itself.
  final bool byMessage;

  @override
  ConsumerState<PairingWaitingScreen> createState() => _PairingWaitingScreenState();
}

class _PairingWaitingScreenState extends ConsumerState<PairingWaitingScreen> {
  PairingCollector? _collector;
  bool _left = false;
  StreamSubscription<PairingEvent>? _events;
  bool _onScreen(PairingEvent e) => e.pairingId == widget.pairingId;

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
    pairingStepsOnScreen[widget.pairingId] = () => mounted && (ModalRoute.of(context)?.isCurrent ?? false);
    final api = ref.read(pairingApiProvider);
    _collector = PairingCollector(api, every: const Duration(seconds: 5))..start();
    _events = api.events().listen((e) {
      if (e.pairingId != widget.pairingId || !mounted) return;
      // Under another screen (the confirm pasted by hand opened its own words check), the
      // build below closes this one instead.
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      final nav = Navigator.of(context);
      if (_left) return;
      if (e.kind == PairingEventKind.confirmed) {
        _left = true;
        nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: widget.pairingId)));
      } else if (e.kind == PairingEventKind.failed && e.failure != null) {
        _left = true;
        nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => PairingOutcomeScreen(failure: e.failure!, name: e.name)));
      }
    });
  }

  /// Paste finish link: the confirm in the clipboard, read on this press only.
  Future<void> _pasteFinish() async {
    final l = context.l10n;
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    if (!mounted) return;
    if (pairingLinkKind(text) != PairingLinkKind.confirm) {
      ref.read(noticeProvider.notifier).show(l.pairInvalidLink, level: NoticeLevel.warning);
      return;
    }
    await openPairingLink(context, ref, text);
  }

  @override
  void dispose() {
    pairingWordsOnScreen.remove(_onScreen);
    pairingStepsOnScreen.remove(widget.pairingId);
    _collector?.stop();
    _events?.cancel();
    super.dispose();
  }

  void _byHand() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => PairingByHandScreen(pairingId: widget.pairingId)),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final record = ref.watch(pairingByIdProvider(widget.pairingId));
    // Nothing to wait for any more (the confirm came another way, by hand, or the pairing was
    // removed): this screen goes, so Done on a later screen does not land back on it.
    final loaded = ref.watch(pairingsProvider).hasValue;
    if (loaded && !_left && (record == null || record.state != PairingState.pendingReply)) {
      _left = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final route = ModalRoute.of(context);
        if (route == null) return;
        if (!route.isCurrent) {
          Navigator.of(context).removeRoute(route);
        } else if (record != null && record.state.isPaired) {
          // The finish link came another way (pasted, offered, by the relay): the words.
          Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: widget.pairingId)));
        } else {
          Navigator.of(context).pop();
        }
      });
    }
    final known = record?.shownName ?? '';
    final name = known.isEmpty ? widget.name : known;
    final overTor = ref.watch(epicboxOverTorProvider);
    final net = ref.watch(pairNetProvider);
    final unreachable = (record?.relayDown ?? false) || net != PairNet.online;
    if (widget.byMessage) {
      return SlotScaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: Text(l.pairWayMessage)),
        body: ScreenBody(
          bottom: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                key: waitingPasteFinishKey,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.content_paste, size: 18),
                label: Text(l.pairPasteFinish),
                onPressed: _pasteFinish,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => Navigator.pop(context),
                child: Text(l.pairClosed),
              ),
            ],
          ),
          children: [
            const PairSteps(current: 3),
            const SizedBox(height: 28),
            const Center(child: SizedBox.square(dimension: 32, child: CircularProgressIndicator(strokeWidth: 3))),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(l.pairAwaitFinishTitle, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            Text(l.pairAwaitFinishBody(name), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
            const SizedBox(height: 16),
            if (record?.expiresAt != null)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: PairCountdown(until: record!.expiresAt!),
                ),
              ),
            if (net == PairNet.online) ...[const SizedBox(height: 16), PairSmallPrint(l.pairByItself)],
          ],
        ),
      );
    }
    return SlotScaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(l.pairWaitingTitleShort)),
      body: ScreenBody(
        bottom: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.pop(context),
              child: Text(l.pairClosed),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: waitingByHandKey,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: _byHand,
              child: Text(l.pairSendByHand),
            ),
          ],
        ),
        children: [
          const SizedBox(height: 24),
          const Center(child: SizedBox.square(dimension: 40, child: CircularProgressIndicator())),
          const SizedBox(height: 20),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(l.pairWaitingFinish(name), textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
          // By hand (Offline, Epicbox off) nothing continues in the background.
          if (net == PairNet.online) Text(l.pairWaitingBody, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
          const SizedBox(height: 16),
          if (record?.expiresAt != null)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: PairCountdown(until: record!.expiresAt!),
              ),
            ),
          if (unreachable) ...[
            const SizedBox(height: 20),
            // Offline or Epicbox off on this wallet is no relay trouble: it says which.
            PairEdgeNotice(
              tone: net == PairNet.epicboxOff ? BadgeTone.info : BadgeTone.warn,
              title: switch (net) {
                PairNet.offline => l.pairOfflineHint,
                PairNet.epicboxOff => l.pairEpicboxOffNotice,
                PairNet.online => l.pairRelayUnreachableTitle,
              },
              body: net != PairNet.online ? null : (overTor ? l.pairRelayUnreachableTor : l.pairRelayUnreachableBody),
              actions: [
                FilledButton(onPressed: _byHand, child: Text(l.pairSendByHand)),
                if (net == PairNet.online) OutlinedButton(onPressed: () => ref.read(pairingApiProvider).collect().ignore(), child: Text(l.pairEnterTryAgain)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Invite by message, the joiner's step 2: the reply to send back in the same chat. It went to
/// the relay as well, so with a relay on both sides the pairing may finish by itself: the
/// words check opens then. After sharing, the wait for the finish link.
class PairReplyScreen extends ConsumerStatefulWidget {
  const PairReplyScreen({super.key, required this.pairingId, this.name = ''});

  final String pairingId;

  /// The inviter's name from its invite, until the records have it.
  final String name;

  @override
  ConsumerState<PairReplyScreen> createState() => _PairReplyScreenState();
}

class _PairReplyScreenState extends ConsumerState<PairReplyScreen> {
  String? _link;
  String? _error;
  bool _left = false;
  PairingCollector? _collector;
  StreamSubscription<PairingEvent>? _events;
  bool _onScreen(PairingEvent e) => e.pairingId == widget.pairingId;

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
    pairingStepsOnScreen[widget.pairingId] = () => mounted && (ModalRoute.of(context)?.isCurrent ?? false);
    final api = ref.read(pairingApiProvider);
    if (ref.read(pairNetProvider) == PairNet.online) {
      _collector = PairingCollector(api, every: const Duration(seconds: 5))..start();
    }
    // The answer ended (Not completed, cancelled by the inviter): why, on its own screen.
    _events = api.events().listen((e) {
      if (e.pairingId != widget.pairingId || e.kind != PairingEventKind.failed || e.failure == null || _left || !mounted) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
      _left = true;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => PairingOutcomeScreen(failure: e.failure!, name: e.name)));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final link = await ref.read(pairingApiProvider).replyLink(widget.pairingId);
        if (mounted) setState(() => _link = link);
      } catch (error) {
        if (mounted) setState(() => _error = describeError(context.l10n, error));
      }
    });
  }

  @override
  void dispose() {
    pairingWordsOnScreen.remove(_onScreen);
    pairingStepsOnScreen.remove(widget.pairingId);
    _collector?.stop();
    _events?.cancel();
    super.dispose();
  }

  Future<void> _share({required bool copy}) async {
    final link = _link;
    if (link == null) return;
    await sharePairingMessage(context, ref, context.l10n.pairReplyMessage(link), copy: copy);
    if (!mounted || _left) return;
    _left = true;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => PairingWaitingScreen(pairingId: widget.pairingId, byMessage: true, name: widget.name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final known = ref.watch(pairingNameProvider(widget.pairingId));
    final name = known.isEmpty ? widget.name : known;
    final record = ref.watch(pairingByIdProvider(widget.pairingId));
    final link = _link;
    final canShare = ref.watch(slateFilesProvider).canShareText;
    // Finished through the relay while the reply was still to send: the words.
    if (!_left && record != null && record.state.isPaired) {
      _left = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: widget.pairingId)));
        }
      });
    }
    return SlotScaffold(
      appBar: AppBar(title: Text(l.pairWayMessage)),
      body: ScreenBody(
        bottom: FilledButton.icon(
          key: replyShareKey,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: Icon(canShare ? Icons.ios_share : Icons.copy, size: 18),
          label: Text(canShare ? l.pairShareReply : l.pairCopyMessage),
          onPressed: link == null ? null : () => _share(copy: !canShare),
        ),
        children: [
          const PairSteps(current: 2),
          const SizedBox(height: 16),
          Semantics(header: true, child: Text(l.pairReplyTitle, style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: 8),
          PairLead(l.pairReplyLead(name)),
          const SizedBox(height: 16),
          if (_error != null) ErrorText(_error!),
          if (link != null) ...[
            ShareBox(label: l.pairWhatTheyReceive, text: l.pairReplyMessage(link)),
            if (canShare)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  key: replyCopyKey,
                  style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(l.pairCopyMessage),
                  onPressed: () => _share(copy: true),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Invite by message, the inviter's step 3: the finish link, which the other wallet needs to
/// show the words; opens by itself once the reply is in. Then the words check.
class PairFinishScreen extends ConsumerStatefulWidget {
  const PairFinishScreen({super.key, required this.pairingId});

  final String pairingId;

  @override
  ConsumerState<PairFinishScreen> createState() => _PairFinishScreenState();
}

class _PairFinishScreenState extends ConsumerState<PairFinishScreen> {
  String? _link;
  String? _error;
  bool _shared = false;
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
    await sharePairingMessage(context, ref, context.l10n.pairFinishMessage(link), copy: copy);
    if (mounted) setState(() => _shared = true);
  }

  void _check() => Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: widget.pairingId)),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = ref.watch(pairingNameProvider(widget.pairingId));
    final link = _link;
    final canShare = ref.watch(slateFilesProvider).canShareText;
    final share = FilledButton.icon(
      key: finishShareKey,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      icon: Icon(canShare ? Icons.ios_share : Icons.copy, size: 18),
      label: Text(canShare ? l.pairShareFinish : l.pairCopyMessage),
      onPressed: link == null ? null : () => _share(copy: !canShare),
    );
    // Once it is sent, the words are the main step.
    final check = _shared
        ? FilledButton(key: finishCheckKey, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)), onPressed: _check, child: Text(l.noticeCheckWords))
        : OutlinedButton(key: finishCheckKey, style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)), onPressed: _check, child: Text(l.noticeCheckWords));
    return SlotScaffold(
      appBar: AppBar(title: Text(l.pairWayMessage)),
      body: ScreenBody(
        bottom: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: _shared
              ? [check, const SizedBox(height: 8), OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  icon: Icon(canShare ? Icons.ios_share : Icons.copy, size: 18),
                  label: Text(canShare ? l.pairShareFinish : l.pairCopyMessage),
                  onPressed: link == null ? null : () => _share(copy: !canShare),
                )]
              : [share, const SizedBox(height: 8), check],
        ),
        children: [
          const PairSteps(current: 3),
          const SizedBox(height: 16),
          Semantics(header: true, child: Text(l.pairFinishTitle, style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: 8),
          PairLead(l.pairFinishLead(name)),
          const SizedBox(height: 16),
          if (_error != null) ErrorText(_error!),
          if (link != null) ...[
            ShareBox(label: l.pairWhatTheyReceive, text: l.pairFinishMessage(link)),
            if (canShare)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(l.pairCopyMessage),
                  onPressed: () => _share(copy: true),
                ),
              ),
          ],
          const SizedBox(height: 8),
          PairSmallPrint(l.pairFinishThenCheck),
        ],
      ),
    );
  }
}

/// The answer (or, for the inviter, the confirm) as a link to send on any channel, when the
/// relay cannot carry it.
class PairingByHandScreen extends ConsumerStatefulWidget {
  const PairingByHandScreen({super.key, required this.pairingId, this.confirm = false});

  final String pairingId;

  /// The inviter's confirm instead of the answer.
  final bool confirm;

  @override
  ConsumerState<PairingByHandScreen> createState() => _PairingByHandScreenState();
}

class _PairingByHandScreenState extends ConsumerState<PairingByHandScreen> {
  String? _link;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final api = ref.read(pairingApiProvider);
      try {
        final link = widget.confirm ? await api.confirmLink(widget.pairingId) : await api.replyLink(widget.pairingId);
        if (mounted) setState(() => _link = link);
      } catch (error) {
        if (mounted) setState(() => _error = describeError(context.l10n, error));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = ref.watch(pairingNameProvider(widget.pairingId));
    final link = _link;
    final files = ref.watch(slateFilesProvider);
    return SlotScaffold(
      appBar: AppBar(title: Text(l.pairByHandTitle)),
      body: ScreenBody(
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stacked, the primary first (UP-029).
            if (files.canShareText) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.ios_share, size: 18),
                label: Text(l.commonShare),
                onPressed: link == null ? null : () => files.shareText(link),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.copy, size: 18),
              label: Text(l.commonCopy),
              onPressed: link == null ? null : () => copySecretText(context, link, l.pairCopied),
            ),
            // The confirm sent, the words are next on both sides.
            if (widget.confirm)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton(
                  key: byHandCheckWordsKey,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: widget.pairingId)),
                  ),
                  child: Text(l.noticeCheckWords),
                ),
              ),
          ],
        ),
        children: [
          PairLead(widget.confirm ? l.pairConfirmByHandLead(name) : l.pairByHandLead(name)),
          const SizedBox(height: 16),
          if (_error != null) ErrorText(_error!),
          if (link != null) ShareBox(label: l.pairByHandYourAnswer, text: link),
          const SizedBox(height: 10),
          if (!widget.confirm) PairSmallPrint(l.pairByHandFooter(name)),
        ],
      ),
    );
  }
}

/// One outcome of the cases file: a card centred on the screen and its next step. [name] is
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
      PairingFailure.changedOnTheWay || PairingFailure.sealedForOther => BadgeTone.risk,
      PairingFailure.cancelled || PairingFailure.newerVersion => BadgeTone.info,
      _ => BadgeTone.warn,
    };
    final close = FilledButton(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: () => Navigator.pop(context),
      child: Text(l.pairClosed),
    );
    final Widget bottom = switch (failure) {
      // Stacked, the primary first (UP-029).
      PairingFailure.noAnswer => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          close,
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const InPersonScreen())),
            child: Text(l.pairInPersonTitle),
          ),
        ],
      ),
      // No in-app updates in the build without Tor: Close alone.
      PairingFailure.newerVersion when inAppUpdates => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () {
              ref.read(updateProvider.notifier).check();
              ref.read(noticeProvider.notifier).show(l.updateChecking, level: NoticeLevel.info);
            },
            child: Text(l.pairCheckForUpdates),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => Navigator.pop(context),
            child: Text(l.pairClosed),
          ),
        ],
      ),
      _ => close,
    };
    return SlotScaffold(
      appBar: AppBar(title: Text(l.pairWaitingTitleShort)),
      body: ScreenBody(
        bottom: bottom,
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
          PairEdgeNotice(
            tone: tone,
            title: pairingFailureText(l, failure, name: name),
            body: pairingFailureBody(l, failure, name: name, file: file),
          ),
        ],
      ),
    );
  }
}
