// SPDX-License-Identifier: Apache-2.0
/// A code or request from someone else: "Pair with Anna?" (from a contact, or by code), the
/// wait for the inviter's confirm with the answer to send by hand when the relay cannot carry
/// it, the finish code of an answer opened outside the Pair screen, and one outcome screen
/// per failure. [openPairingLink] is the entry for any pairing link: a scan, a paste, a tapped
/// `epiccash://pair/…`.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contacts.dart';
import '../../errors.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import 'pair_screen.dart' show seenAsOrAsk;
import '../../pairing_text.dart';
import '../../slate_files.dart';
import '../../tor_build.dart';
import '../../updater.dart' show updateProvider;
import '../../wallet_service.dart';
import '../app_dialog.dart';
import '../common.dart';
import '../contact_page.dart' show AddressText;
import '../phone_sheet.dart';
import '../theme/brand.dart';
import '../theme/tokens.dart';
import 'invite_links.dart';
import 'pair_check.dart';
import 'pairing_clip_offer.dart';
import 'pairing_notices.dart' show pairingWordsOnScreen;
import 'pairing_parts.dart';

/// Keys for tests.
const Key incomingPairKey = ValueKey('incoming-pair');
const Key incomingNotNowKey = ValueKey('incoming-not-now');
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
/// or an older in-person card, is "Not a pairing code".
Future<void> openPairingLink(
  BuildContext context,
  WidgetRef ref,
  String pasted, {
  Contact? contact,
  bool replace = false,
  bool byCamera = false,
}) async {
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
    notices.show(l.pairAlreadyPaired(name.isEmpty ? r.shownName : name), level: NoticeLevel.info);
    return true;
  }

  try {
    switch (kind) {
      case PairingLinkKind.invite:
        final preview = await api.openInvite(text);
        if (context.mounted) await showIncomingInvite(context, ref, preview, contact: contact, replace: replace);
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
        await show(CheckWordsScreen(pairingId: record.id));
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
Future<void> showIncomingInvite(
  BuildContext context,
  WidgetRef ref,
  PairingInvitePreview preview, {
  Contact? contact,
  bool replace = false,
}) async {
  final answered = await showPhoneSheet<PairingRecord>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => IncomingInviteSheet(preview: preview, contact: contact),
  );
  if (answered == null || !context.mounted) return;
  final screen = PairingWaitingScreen(pairingId: answered.id, name: preview.name);
  final nav = Navigator.of(context);
  await (replace ? nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => screen)) : nav.push(MaterialPageRoute<void>(builder: (_) => screen)));
}

/// The sheet, in two forms: from a contact (the request's sender is in Contacts: avatar, "In
/// your contacts", the sender address) or by code ("Name chosen by them"). Pair · Not now;
/// no name field, no invoice switch, no expiry row. Pops with the answered record.
class IncomingInviteSheet extends ConsumerStatefulWidget {
  const IncomingInviteSheet({super.key, required this.preview, this.contact});

  final PairingInvitePreview preview;
  final Contact? contact;

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
    final name = await seenAsOrAsk(context, ref);
    if (name == null || !mounted) return;
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
    final theme = Theme.of(context);
    final p = widget.preview;
    final sender = p.isRequest ? _sender() : null;
    final name = sender?.name ?? p.name;
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
              PairAvatar(name: name, kind: p.kind, size: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text(l.pairIncomingTitle(name), style: theme.textTheme.titleLarge)),
                    const SizedBox(height: 6),
                    if (sender != null)
                      EBadge(l.pairInContacts, icon: Icons.person_outline, tone: BadgeTone.ok)
                    else
                      const ClaimedNameBadge(long: true),
                  ],
                ),
              ),
            ],
          ),
          if (p.fromAddress case final from?) ...[
            const SizedBox(height: 12),
            AddressText(from, short: true),
          ],
          const SizedBox(height: 20),
          // The primary over the secondary, as every foot on the phone (UP-029).
          FilledButton(
            key: incomingPairKey,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : _pair,
            child: _busy ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l.pairTitle),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: incomingNotNowKey,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(l.pairNotNow),
          ),
          SizedBox(height: t.radiusSmall),
        ],
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
class PairingWaitingScreen extends ConsumerStatefulWidget {
  const PairingWaitingScreen({super.key, required this.pairingId, this.name = ''});

  final String pairingId;

  /// The inviter's name from its code, until the records have it.
  final String name;

  @override
  ConsumerState<PairingWaitingScreen> createState() => _PairingWaitingScreenState();
}

class _PairingWaitingScreenState extends ConsumerState<PairingWaitingScreen> {
  PairingCollector? _collector;
  Timer? _slow;
  bool _late = false;
  bool _left = false;
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
      _collector = PairingCollector(api, every: const Duration(seconds: 5))..start();
      _slow = Timer(pairReplyFallbackAfter, () => mounted ? setState(() => _late = true) : null);
    } else {
      _late = true;
    }
    _events = api.events().listen((e) {
      if (e.pairingId != widget.pairingId || !mounted || _left) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      if (e.kind == PairingEventKind.confirmed) _finished();
      if (e.kind == PairingEventKind.failed && e.failure != null) {
        _left = true;
        Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => PairingOutcomeScreen(failure: e.failure!, name: e.name)));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLink());
  }

  Future<void> _loadLink() async {
    try {
      final link = await ref.read(pairingApiProvider).replyLink(widget.pairingId);
      if (mounted) setState(() => _link = link);
    } catch (_) {
      // Gone already: the build below leaves.
    }
  }

  /// The confirm is in: a request ends Verified (no words), a code opens the words.
  void _finished() {
    _left = true;
    final record = ref.read(pairingByIdProvider(widget.pairingId));
    final nav = Navigator.of(context);
    if (record != null && record.state == PairingState.verified) {
      ref.read(noticeProvider.notifier).show(context.l10n.pairPairedWith(_name), level: NoticeLevel.success);
      nav.pop();
      return;
    }
    nav.pushReplacement(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: widget.pairingId)));
  }

  String get _name {
    final known = ref.read(pairingNameProvider(widget.pairingId));
    return known.isEmpty ? widget.name : known;
  }

  @override
  void dispose() {
    pairingWordsOnScreen.remove(_onScreen);
    pairingStepsOnScreen.remove(widget.pairingId);
    _collector?.stop();
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
    await openPairingLink(context, ref, text, replace: true);
    if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) _left = false;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final record = ref.watch(pairingByIdProvider(widget.pairingId));
    final loaded = ref.watch(pairingsProvider).hasValue;
    // Nothing to wait for any more (the confirm came another way, or the pairing was
    // cancelled): this screen goes.
    if (loaded && !_left && (record == null || record.state != PairingState.pendingReply)) {
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
    return SlotScaffold(
      appBar: AppBar(title: Text(l.pairWaitingTitleShort)),
      body: ScreenBody(
        bottom: OutlinedButton(
          key: waitingCancelKey,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: t.risk),
          onPressed: _cancel,
          child: Text(l.commonCancel),
        ),
        children: [
          const SizedBox(height: 16),
          Semantics(
            header: true,
            liveRegion: true,
            child: Row(
              children: [
                const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                const SizedBox(width: 12),
                Expanded(child: Text(l.pairPairingWith(name), style: theme.textTheme.titleLarge)),
              ],
            ),
          ),
          if (byHand) ...[
            const SizedBox(height: 20),
            PairCard(
              key: waitingAnswerBoxKey,
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l.pairByHandYourAnswer, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 6),
                      PairSmallPrint(l.pairYourAnswerBody),
                      if (link != null) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: protocolLight.surface, borderRadius: BorderRadius.circular(t.radiusSmall)),
                            child: MarkedQr(data: link, size: 180),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              key: waitingShareKey,
                              icon: Icon(canShare ? Icons.ios_share : Icons.copy, size: 18),
                              label: Text(canShare ? l.commonShare : l.commonCopy),
                              onPressed: () => _share(copy: !canShare),
                            ),
                            if (canShare) OutlinedButton.icon(icon: const Icon(Icons.copy, size: 18), label: Text(l.commonCopy), onPressed: () => _share(copy: true)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextField(
                        key: waitingFinishFieldKey,
                        controller: _finish,
                        autocorrect: false,
                        enableSuggestions: false,
                        minLines: 1,
                        maxLines: 3,
                        onSubmitted: (_) => _openFinish(),
                        decoration: InputDecoration(
                          labelText: l.pairPasteFinishField,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(tooltip: l.pairPaste, icon: const Icon(Icons.content_paste), onPressed: _pasteFinish),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: OutlinedButton(key: waitingFinishGoKey, onPressed: _openFinish, child: Text(l.pairTitle)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Asks before cancelling the pairing with [name]; true to cancel.
Future<bool> confirmCancelPairing(BuildContext context, String name) async {
  final l = context.l10n;
  return confirmAppDialog(
    context,
    title: l.pairCancelPairingTitle,
    icon: Icons.link_off,
    tone: DialogTone.risk,
    description: l.pairCancelPairingBody(name),
    cancelLabel: l.contactKeep,
    confirmLabel: l.pairCancelPairing,
    risk: true,
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
    final name = ref.watch(pairingNameProvider(widget.pairingId));
    final link = _link;
    final canShare = ref.watch(slateFilesProvider).canShareText;
    final record = ref.watch(pairingByIdProvider(widget.pairingId));
    return SlotScaffold(
      appBar: AppBar(title: Text(l.pairWaitingTitleShort)),
      body: ScreenBody(
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              key: finishScreenShareKey,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: Icon(canShare ? Icons.ios_share : Icons.copy, size: 18),
              label: Text(canShare ? l.commonShare : l.commonCopy),
              onPressed: link == null ? null : () => _share(copy: !canShare),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: finishScreenCheckKey,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: record == null || record.sas.isEmpty ? null : _check,
              child: Text(l.pairCheckWords),
            ),
          ],
        ),
        children: [
          Semantics(header: true, child: Text(l.pairFinishCodeTitle, style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: 8),
          PairLead(l.pairFinishCodeBody(name)),
          const SizedBox(height: 16),
          if (_error != null) ErrorText(_error!),
          if (link != null) ShareBox(text: l.pairFinishLinkMessage(link)),
        ],
      ),
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
    final close = FilledButton(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: () => Navigator.pop(context),
      child: Text(l.pairClosed),
    );
    // No in-app updates in the build without Tor: Close alone.
    final Widget bottom = failure == PairingFailure.newerVersion && inAppUpdates
        ? Column(
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
          )
        : close;
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
