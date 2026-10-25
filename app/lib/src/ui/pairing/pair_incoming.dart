/// An invite from someone else (SPEC 2.2): "Pair with Anna?", the answer and the wait for the
/// inviter's confirm, the answer by hand when no relay answers, and one outcome screen per
/// case of the cases file. [openPairingLink] is the entry for any pairing link: a scan, a
/// paste, a tapped `epiccash://pair/…`.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../wallet_service.dart';
import '../../pairing_text.dart';
import '../../phone_tor.dart' show epicboxOverTorProvider;
import '../../slate_files.dart';
import '../../updater.dart' show updateProvider;
import '../common.dart';
import '../theme/tokens.dart';
import 'pair_check.dart';
import 'pair_screen.dart';
import 'pairing_notices.dart' show pairingWordsOnScreen;
import 'pairing_parts.dart';

/// Keys for tests.
const Key incomingPairKey = ValueKey('incoming-pair');
const Key incomingNotNowKey = ValueKey('incoming-not-now');
const Key incomingAllowKey = ValueKey('incoming-allow');
const Key waitingByHandKey = ValueKey('waiting-by-hand');
const Key byHandCheckWordsKey = ValueKey('by-hand-check-words');

/// Opens the pairing link in [text] (an invite, an answer or confirm sent by hand, or a card):
/// the incoming sheet, the words check, or the screen that says why not. [contact] is the
/// address-book contact the pairing attaches to, when known. With [replace] the screen that
/// opens takes the place of the current one. Text without a pairing link does nothing.
Future<void> openPairingLink(
  BuildContext context,
  WidgetRef ref,
  String pasted, {
  Contact? contact,
  bool replace = false,
}) async {
  final kind = pairingLinkKind(pasted);
  if (kind == null) return;
  // A shared message holds the link among words: the calls take the link alone (PAIR-LNX-1).
  final text = pairingLinkIn(pasted)!;
  final api = ref.read(pairingApiProvider);
  final nav = Navigator.of(context);
  Future<void> show(Widget screen) =>
      replace ? nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => screen)) : nav.push(MaterialPageRoute<void>(builder: (_) => screen));
  try {
    switch (kind) {
      case PairingLinkKind.invite:
        final preview = await api.openInvite(text);
        if (context.mounted) await showIncomingInvite(context, ref, preview, contact: contact, replace: replace);
      case PairingLinkKind.reply:
        // Their answer came by hand, so the confirm goes back by hand before the words: their
        // wallet shows the words only once it has it (PAIR-AND-10).
        final record = await pairingCall(ref, (a) => a.openReply(text));
        await show(PairingByHandScreen(pairingId: record.id, confirm: true));
      case PairingLinkKind.confirm:
        final record = await pairingCall(ref, (a) => a.openConfirm(text));
        await show(CheckWordsScreen(pairingId: record.id));
      case PairingLinkKind.card:
        // Their code was scanned first: show this phone's, and the pairing follows.
        await show(InPersonScreen(contact: contact, scanned: text));
    }
  } catch (error) {
    final failure = pairingFailureOf(error);
    if (failure == null) rethrow;
    await show(PairingOutcomeScreen(failure: failure));
  }
}

/// "Pair with Anna?" for [preview]. Pair answers it and opens the wait for the confirm.
Future<void> showIncomingInvite(
  BuildContext context,
  WidgetRef ref,
  PairingInvitePreview preview, {
  Contact? contact,
  bool replace = false,
}) async {
  final answered = await showModalBottomSheet<PairingRecord>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => IncomingInviteSheet(preview: preview, contact: contact),
  );
  if (answered == null || !context.mounted) return;
  final screen = PairingWaitingScreen(pairingId: answered.id);
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
    final foot = MediaQuery.paddingOf(context).bottom;
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
          if (p.asksInvoices) ...[
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: incomingNotNowKey,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: Text(l.pairNotNow),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: incomingPairKey,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: _busy ? null : _pair,
                  child: _busy
                      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l.pairTitle),
                ),
              ),
            ],
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
  const PairingWaitingScreen({super.key, required this.pairingId});

  final String pairingId;

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
    final api = ref.read(pairingApiProvider);
    _collector = PairingCollector(api, every: const Duration(seconds: 5))..start();
    _events = api.events().listen((e) {
      if (e.pairingId != widget.pairingId || !mounted) return;
      // Under another screen (the confirm pasted by hand opened its own words check), the
      // build below closes this one instead.
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      final nav = Navigator.of(context);
      if (e.kind == PairingEventKind.confirmed) {
        nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: widget.pairingId)));
      } else if (e.kind == PairingEventKind.failed && e.failure != null) {
        nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => PairingOutcomeScreen(failure: e.failure!, name: e.name)));
      }
    });
  }

  @override
  void dispose() {
    pairingWordsOnScreen.remove(_onScreen);
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
        if (route.isCurrent) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).removeRoute(route);
        }
      });
    }
    final name = record?.shownName ?? '';
    final overTor = ref.watch(epicboxOverTorProvider);
    final unreachable = (record?.relayDown ?? false) || ref.watch(pairNetProvider) != PairNet.online;
    return SlotScaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(l.pairWaitingTitleShort)),
      body: ScreenBody(
        bottom: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: waitingByHandKey,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: _byHand,
                child: Text(l.pairSendByHand),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => Navigator.pop(context),
                child: Text(l.pairClosed),
              ),
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
            child: Text(l.pairWaitingTitle(name), textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
          Text(l.pairWaitingBody, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: t.dim)),
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
            PairEdgeNotice(
              tone: BadgeTone.warn,
              title: l.pairRelayUnreachableTitle,
              body: overTor ? l.pairRelayUnreachableTor : l.pairRelayUnreachableBody,
              actions: [
                FilledButton(onPressed: _byHand, child: Text(l.pairSendByHand)),
                OutlinedButton(onPressed: () => ref.read(pairingApiProvider).collect().ignore(), child: Text(l.pairEnterTryAgain)),
              ],
            ),
          ],
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    icon: const Icon(Icons.copy, size: 18),
                    label: Text(l.commonCopy),
                    onPressed: link == null ? null : () => copyText(context, link, l.pairCopied),
                  ),
                ),
                if (files.canShareText) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: Text(l.commonShare),
                      onPressed: link == null ? null : () => files.shareText(link),
                    ),
                  ),
                ],
              ],
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
      PairingFailure.noAnswer => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const InPersonScreen())),
              child: Text(l.pairInPersonTitle),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: close),
        ],
      ),
      PairingFailure.newerVersion => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => Navigator.pop(context),
              child: Text(l.pairClosed),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                ref.read(updateProvider.notifier).check();
                ref.read(noticeProvider.notifier).show(l.updateChecking, level: NoticeLevel.info);
              },
              child: Text(l.pairCheckForUpdates),
            ),
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
