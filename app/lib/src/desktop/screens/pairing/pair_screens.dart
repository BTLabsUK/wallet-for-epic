// SPDX-License-Identifier: Apache-2.0
/// Pairing on the desktop: no camera, so Show my code
/// is an invite's code with its pairing words beside it, and Enter link or words takes a
/// pasted link (an invite, an answer or a confirm sent by hand, or the other wallet's card
/// link for pairing face to face) or typed words. Invite online
/// copies the invite. The incoming invite and the words check are dialogs; Pending invites is
/// a page under Contacts.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n.dart' show AppLocalizations, invitedLine, localDayMonth;
import '../../../models.dart'
    show PairingCard, PairingCheck, PairingEvent, PairingEventKind, PairingFailure, PairingInvitePreview, PairingParty, PairingRecord, PairingState, PairingWay, WalletError, WalletErrorKind, pairingError, pairingFailureOf;
import '../../../devices/device_link_code.dart' show isDeviceLinkText;
import '../../../help/help_content.dart' show HelpId;
import '../devices/link_flow.dart' show showDeskLinkDevice;
import '../../../pairing_api.dart';
import '../../../pairing_text.dart';
import '../../../sas_table.dart';
import '../../../ui/pairing/pairing_notices.dart' show pairingWordsOnScreen;
import '../../../ui/pairing/pairing_parts.dart' show WordTileSize, WordTiles;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/pairing_state.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../settings/help_pairing.dart' show HelpAt;
import '../transfer/contact_picker.dart' show showContactPicker;

/// Keys for tests.
const Key deskPairEnterKey = ValueKey('desk-pair-enter');
const Key deskPairNameKey = ValueKey('desk-pair-name');
const Key deskPairWordsKey = ValueKey('desk-pair-words');
const Key deskPairMessageKey = ValueKey('desk-pair-message');
const Key deskPairInPersonKey = ValueKey('desk-pair-in-person');
const Key deskPairWordsPanelKey = ValueKey('desk-pair-words-panel');
const Key deskPairMessagePanelKey = ValueKey('desk-pair-message-panel');
const Key deskPairInPersonPanelKey = ValueKey('desk-pair-in-person-panel');
const Key deskPairUseMessageKey = ValueKey('desk-pair-use-message');
const Key deskPairNewWordsKey = ValueKey('desk-pair-new-words');
const Key deskPairPasteReplyKey = ValueKey('desk-pair-paste-reply');
const Key deskPairCancelSentKey = ValueKey('desk-pair-cancel-sent');
const Key deskPairHowKey = ValueKey('desk-pair-how');
const Key deskFinishCopyKey = ValueKey('desk-finish-copy');
const Key deskReplyCopyKey = ValueKey('desk-reply-copy');
const Key deskPasteFinishKey = ValueKey('desk-paste-finish');
const Key deskPairGoKey = ValueKey('desk-pair-go');
const Key deskPairPasteKey = ValueKey('desk-pair-paste');
const Key deskPairCopyInviteKey = ValueKey('desk-pair-copy-invite');
const Key deskPairCopyCardKey = ValueKey('desk-pair-copy-card');
const Key deskCardBackLinkKey = ValueKey('desk-card-back-link');
const Key deskCardBackCheckKey = ValueKey('desk-card-back-check');
const Key deskConfirmBackLinkKey = ValueKey('desk-confirm-back-link');
const Key deskConfirmBackCheckKey = ValueKey('desk-confirm-back-check');
const Key deskIncomingPairKey = ValueKey('desk-incoming-pair');
const Key deskCheckMatchKey = ValueKey('desk-check-match');
const Key deskCheckNoMatchKey = ValueKey('desk-check-no-match');
const Key deskCheckSkipKey = ValueKey('desk-check-skip');
const Key deskPendingRemoveKey = ValueKey('desk-pending-remove');
const Key deskPendingRemovePairedKey = ValueKey('desk-pending-remove-paired');
const Key deskSavedNewKey = ValueKey('desk-saved-new');
const Key deskSavedAddToKey = ValueKey('desk-saved-add-to');
const Key deskSavedNotNowKey = ValueKey('desk-saved-not-now');
const Key deskSavedAddToNamedKey = ValueKey('desk-saved-add-to-named');

/// The contact's (or the invite's) initials in the desktop avatar; [icon] instead for an
/// invite nobody named yet.
class DeskPairAvatar extends StatelessWidget {
  const DeskPairAvatar({super.key, required this.name, this.size, this.icon});

  final String name;
  final double? size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final glyph = icon;
    if (glyph == null) return EAvatar(name.isEmpty ? '?' : name, size: size);
    final c = context.dc;
    final side = size ?? 32.u;
    return ExcludeSemantics(
      child: Container(
        width: side,
        height: side,
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.lineStrong)),
        child: Icon(glyph, size: side * 0.5, color: c.accentText),
      ),
    );
  }
}

/// The ways of [DeskPairScreen].
enum DeskPairWay { words, message, inPerson }

/// Contacts › Pair (Pairing UX plan 4.4): three ways as tiles, Words (five words, the relay
/// does the rest), Invite by message (three messages copied into any chat) and In person (the
/// phone scans this wallet's code, this one pastes the phone's code link), each opening its
/// panel; under them Got words or a link?, the field for the one who was invited. [arg] is the
/// [Contact] the pairing will attach to, if any, or the [DeskPairWay] to open.
class DeskPairScreen extends ConsumerStatefulWidget {
  const DeskPairScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<DeskPairScreen> createState() => _DeskPairScreenState();
}

class _DeskPairScreenState extends ConsumerState<DeskPairScreen> {
  late final Contact? _contact = widget.arg is Contact ? widget.arg! as Contact : null;
  final _enter = TextEditingController();
  final _name = TextEditingController();
  Duration _expiry = pairingInviteDefaultExpiry;

  /// The way open; [DeskPairScreen.arg] may name one (the screenshot catalogue).
  late DeskPairWay? _way = widget.arg is DeskPairWay ? widget.arg! as DeskPairWay : null;

  /// The words invite on show.
  PairingRecord? _code;

  /// The message invite sent and waiting for its reply (step 2).
  PairingRecord? _sent;

  /// The reply to [_sent] was handled (finish link or words opened).
  bool _sentDone = false;

  /// This wallet's card for In person, made for the name [_cardFor].
  PairingCard? _card;
  String? _cardFor;
  String? _codeError;
  bool _codeNoRelay = false;
  String? _enterError;

  /// The name was needed and is missing: its field says so.
  bool _triedName = false;
  bool _busy = false;
  Timer? _tick;
  Timer? _collect;
  Timer? _typed;
  StreamSubscription<PairingEvent>? _events;

  /// Any answer opens its next step here.
  bool _onScreen(PairingEvent e) => e.kind == PairingEventKind.replied;

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
    _name.text = ref.read(deskSeenAsProvider);
    _way ??= ref.read(deskPairNetProvider) == DeskPairNet.online ? DeskPairWay.words : DeskPairWay.message;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    final api = ref.read(deskPairingApiProvider);
    _collect = Timer.periodic(const Duration(seconds: 10), (_) => api.collect().ignore());
    _events = api.events().listen((e) {
      final id = e.pairingId;
      if (e.kind == PairingEventKind.replied && id != null && mounted) unawaited(_replied(id));
      // The invite sent by message ended without a reply: why, and the panel starts over.
      if (e.kind == PairingEventKind.failed && e.failure != null && id != null && id == _sent?.id && mounted) {
        deskPairingStepsOnScreen.remove(id);
        setState(() => _sent = null);
        unawaited(showDeskOutcome(context, e.failure!, name: e.name));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _open(_way!);
    });
  }

  /// Opened again on another way while it is up (the same route): that way.
  @override
  void didUpdateWidget(DeskPairScreen old) {
    super.didUpdateWidget(old);
    final way = widget.arg;
    if (way is DeskPairWay && way != old.arg && way != _way) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _open(way);
      });
    }
  }

  @override
  void dispose() {
    pairingWordsOnScreen.remove(_onScreen);
    if (_sent case final sent?) deskPairingStepsOnScreen.remove(sent.id);
    _tick?.cancel();
    _collect?.cancel();
    _typed?.cancel();
    _events?.cancel();
    _enter.dispose();
    _name.dispose();
    super.dispose();
  }

  String get _seenAs => _name.text.trim();

  /// An invite of this wallet's was answered: the finish link first when this wallet holds one
  /// to send (the reply came in a message), else the words (the relay sent the confirm too).
  /// A reply pasted here opens its own steps.
  Future<void> _replied(String id) async {
    // Let a paste that is opening this reply claim it first.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted || deskPairingFinishing.contains(id)) return;
    if (_sent?.id == id) setState(() => _sentDone = true);
    await deskAfterReply(context, ref, id);
  }

  void _open(DeskPairWay way) {
    setState(() => _way = way);
    switch (way) {
      case DeskPairWay.words:
        if (_code == null) _makeWords();
      case DeskPairWay.inPerson:
        if (_card == null) _makeCard();
      case DeskPairWay.message:
    }
  }

  /// The name others see, or null (and the field says so) when there is none.
  String? _needName() {
    if (_seenAs.isNotEmpty) return _seenAs;
    setState(() => _triedName = true);
    return null;
  }

  void _nameChanged() {
    ref.read(deskSeenAsProvider.notifier).set(_name.text);
    setState(() => _triedName = false);
    // The first name typed makes the words or the code once typing pauses; a later change on
    // Enter or New words, so none is made per key.
    _typed?.cancel();
    if (_seenAs.isEmpty) return;
    final words = _way == DeskPairWay.words && _code == null;
    final card = _way == DeskPairWay.inPerson && _card == null;
    if (words || card) {
      _typed = Timer(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        if (words) _makeWords();
        if (card) _makeCard();
      });
    }
  }

  Future<void> _makeWords({bool fresh = false}) async {
    final l = context.l10n;
    // The words carry the name the other side sees: they wait for one.
    final name = _seenAs;
    if (name.isEmpty) return;
    final old = _code;
    // Opened again: the words still open show, not a new invite each visit (WIN2-1).
    if (old == null && !fresh) {
      var all = const <PairingRecord>[];
      try {
        all = await ref.read(deskPairingsProvider.future);
      } catch (_) {
        // No list: a new invite, as before.
      }
      final open = openWordsInvite(all, contactId: _contact?.id, now: DateTime.now());
      if (open != null) {
        if (mounted) setState(() => _code = open);
        return;
      }
    }
    try {
      final code = await deskPairingCall(
        ref,
        (api) => api.makeInvite(name: name, expiry: pairingWordsExpiry, words: true, label: _contact?.name, contactId: _contact?.id),
      );
      if (old != null) await deskPairingCall(ref, (api) => api.cancelInvite(old.id));
      if (mounted) {
        setState(() {
          _code = code;
          _codeError = null;
          _codeNoRelay = false;
        });
      }
    } catch (error) {
      final failure = pairingFailureOf(error);
      if (mounted) {
        setState(() {
          _codeError = deskErrorText(error, l);
          _codeNoRelay = failure != null && pairingNoRelay(failure);
        });
      }
    }
  }

  /// This wallet's card for In person: the phone scans its code, this wallet pastes theirs.
  Future<void> _makeCard() async {
    final name = _seenAs;
    if (name.isEmpty) return;
    try {
      final own = ref.read(deskOwnCardProvider);
      final card = own != null && (_cardFor == null || _cardFor == name) ? own : await ref.read(deskPairingApiProvider).showCard(name: name);
      ref.read(deskOwnCardProvider.notifier).set(card);
      if (mounted) {
        setState(() {
          _card = card;
          _cardFor = name;
        });
      }
    } catch (error) {
      if (mounted) showEToast(context, deskErrorText(error, context.l10n), tone: ETone.risk);
    }
  }

  Future<void> _copyCard() async {
    if (_needName() == null) return;
    if (_card == null || _cardFor != _seenAs) await _makeCard();
    final card = _card;
    if (card == null || !mounted) return;
    await copyToClipboard(context, card.link, context.l10n.pairCopied);
  }

  /// The words, a link or a message typed or pasted under Got words or a link?.
  List<String> get _words => pairingWordParts(_enter.text);

  /// Paste: the clipboard into the field, read on this press only; Pair opens it.
  Future<void> _pasteEnter() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
    if (!mounted || text.isEmpty) return;
    _enter.text = text;
    setState(() => _enterError = null);
  }

  bool get _ready {
    if (pairingLinkIn(_enter.text) != null || isDeviceLinkText(_enter.text)) return true;
    final w = _words;
    return w.length == pairingWordCount && w.every((x) => (sasWordNamed(x) ?? sasWordOfEmoji(x)) != null);
  }

  Future<void> _go() async {
    if (_busy || !_ready) return;
    final l = context.l10n;
    // A device link opens Link a device, not a pairing.
    if (isDeviceLinkText(_enter.text)) {
      final text = _enter.text;
      _enter.clear();
      await showDeskLinkDevice(context, pasted: text);
      return;
    }
    // A card link needs this wallet's own card, and a card needs the name others see.
    if (pairingLinkKind(_enter.text) == PairingLinkKind.card && ref.read(deskOwnCardProvider) == null && _seenAs.isEmpty) {
      setState(() {
        _triedName = true;
        _enterError = l.pairSeenAsMissing;
      });
      return;
    }
    setState(() {
      _busy = true;
      _enterError = null;
    });
    try {
      await deskOpenPairingText(context, ref, _enter.text, contact: _contact);
      _enter.clear();
    } catch (error) {
      final failure = pairingFailureOf(error);
      // Words that found nothing because no relay answers: the message way needs none.
      final text = deskErrorText(error, l);
      if (mounted) setState(() => _enterError = failure != null && pairingNoRelay(failure) ? '$text ${l.pairAskForMessage}' : text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Invite by message, step 1: makes the invite and copies its message.
  Future<void> _copyInvite() async {
    final l = context.l10n;
    final name = _needName();
    if (name == null) return;
    try {
      final invite = await deskPairingCall(ref, (api) => api.makeInvite(name: name, expiry: _expiry, label: _contact?.name, contactId: _contact?.id));
      if (!mounted) return;
      final link = invite.inviteLink ?? '';
      await copyToClipboard(context, l.pairInviteMessage(link), l.pairMessageCopied);
      deskPairingStepsOnScreen.add(invite.id);
      setState(() {
        _sent = invite;
        _sentDone = false;
      });
    } catch (error) {
      if (mounted) showEToast(context, deskErrorText(error, l), tone: ETone.risk);
    }
  }

  /// Invite by message, step 2: the reply in the clipboard.
  Future<void> _pasteReply() async {
    final l = context.l10n;
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    if (!mounted) return;
    if (pairingLinkKind(text) != PairingLinkKind.reply) {
      showEToast(context, l.pairInvalidLink, tone: ETone.warn);
      return;
    }
    try {
      await deskOpenPairingText(context, ref, text, contact: _contact);
      if (mounted) setState(() => _sentDone = true);
    } catch (error) {
      if (mounted) showEToast(context, deskErrorText(error, l), tone: ETone.warn);
    }
  }

  Future<void> _cancelSent() async {
    final sent = _sent;
    if (sent == null) return;
    await deskPairingCall(ref, (api) => api.cancelInvite(sent.id));
    deskPairingStepsOnScreen.remove(sent.id);
    if (mounted) setState(() => _sent = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final net = ref.watch(deskPairNetProvider);
    final online = net == DeskPairNet.online;
    final way = _way;
    // A name, not a paragraph: its own width, at the start of a stretched column.
    final nameField = Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420.u),
        child: EField(
        label: l.pairSeenAs,
        // Only once something needed the name, never on a page just opened.
        error: _triedName && _seenAs.isEmpty ? l.pairSeenAsMissing : null,
        child: EInput(
          key: deskPairNameKey,
          controller: _name,
          autofocus: _name.text.isEmpty,
          onChanged: (_) => _nameChanged(),
          onSubmitted: (_) {
            if (_seenAs.isEmpty) setState(() => _triedName = true);
            if (_way == DeskPairWay.inPerson) _makeCard();
            if (_way == DeskPairWay.words && _code == null) _makeWords();
          },
        ),
        ),
      ),
    );
    final tiles = [
      _DeskWayTile(
        key: deskPairWordsKey,
        icon: EIcons.words,
        title: l.pairWayWords,
        badge: EBadge(l.pairWayAutomatic, icon: EIcons.automatic, tone: ETone.info),
        info: l.pairWayWordsInfo,
        text: online ? l.pairWayWordsHint : l.pairWordsNeedEpicbox,
        selected: way == DeskPairWay.words,
        onTap: online ? () => _open(DeskPairWay.words) : null,
      ),
      _DeskWayTile(
        key: deskPairMessageKey,
        icon: EIcons.chat,
        title: l.pairWayMessage,
        info: l.pairWayMessageInfo,
        text: l.pairWayMessageHint,
        selected: way == DeskPairWay.message,
        onTap: () => _open(DeskPairWay.message),
      ),
      _DeskWayTile(
        key: deskPairInPersonKey,
        icon: EIcons.qr,
        title: l.pairInPerson,
        text: l.pairWayInPersonDesk,
        selected: way == DeskPairWay.inPerson,
        onTap: () => _open(DeskPairWay.inPerson),
      ),
    ];
    final Widget panel = switch (way) {
      DeskPairWay.words => _wordsPanel(l, nameField),
      DeskPairWay.message => _messagePanel(l, nameField, online),
      DeskPairWay.inPerson => _inPersonPanel(l, nameField),
      null => const SizedBox.shrink(),
    };
    final enter = EPanel(
      title: l.pairGotInvite,
      child: EField(
        label: l.pairGotInviteHint,
        error: _enterError,
        child: Row(
          children: [
            Expanded(
              child: EInput(
                key: deskPairEnterKey,
                controller: _enter,
                hint: l.pairEnterDesktopPlaceholder,
                invalid: _enterError != null,
                onChanged: (_) => setState(() => _enterError = null),
                onSubmitted: (_) => _go(),
              ),
            ),
            SizedBox(width: Sp.x2),
            EButton.ghost(key: deskPairPasteKey, label: l.commonPaste, icon: EIcons.paste, onPressed: _pasteEnter),
            SizedBox(width: Sp.x2),
            EButton.primary(key: deskPairGoKey, label: l.pairTitle, size: EBtnSize.sm, busy: _busy, onPressed: _ready ? _go : null),
          ],
        ),
      ),
    );
    return EPage(
      title: _contact == null ? l.pairTitle : l.pairWithName(_contact.name),
      width: EPageWidth.full,
      onBack: () => ref.read(deskNavProvider.notifier).go(DeskRoute.contacts),
      actions: [EButton.ghost(label: l.pendingTitle, icon: EIcons.clock, onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.pairPending))],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(constraints: BoxConstraints(maxWidth: 720.u), child: Text(l.pairWaysLead, style: ts.bodyDim)),
          SizedBox(height: Sp.x5),
          if (net == DeskPairNet.offline) ...[ENotice(title: l.pairOfflineHint, tone: ETone.warn), SizedBox(height: Sp.x4)],
          if (net == DeskPairNet.epicboxOff) ...[ENotice(title: l.pairEpicboxOffNotice, tone: ETone.info), SizedBox(height: Sp.x4)],
          LayoutBuilder(
            builder: (context, box) => box.maxWidth >= 900.u
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < tiles.length; i++) ...[if (i > 0) SizedBox(width: Sp.x3), Expanded(child: tiles[i])],
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < tiles.length; i++) ...[if (i > 0) SizedBox(height: Sp.x2), tiles[i]],
                    ],
                  ),
          ),
          SizedBox(height: Sp.x5),
          panel,
          SizedBox(height: Sp.x5),
          enter,
          SizedBox(height: Sp.x3),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: EButton.ghost(
              key: deskPairHowKey,
              label: l.pairHowItWorks,
              icon: EIcons.help,
              onPressed: () => ref.read(deskNavProvider.notifier).go(DeskRoute.settingsHelp, HelpAt.topic(HelpId.pairingWays)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wordsPanel(AppLocalizations l, Widget nameField) {
    final ts = context.ts;
    final code = _code;
    final left = code?.expiresAt?.difference(DateTime.now());
    final expired = left != null && left.isNegative;
    return EPanel(
      key: deskPairWordsPanelKey,
      title: l.pairWayWords,
      headTrailing: left != null && !expired ? EBadge(l.pairWordsDesktopChip(pairingClock(left)), icon: EIcons.clock) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The words carry the name the other side sees.
          nameField,
          SizedBox(height: Sp.x4),
          if (_codeError != null) ...[
            ENotice(
              title: _codeError!,
              tone: ETone.warn,
              actionsBelow: true,
              // No relay took the words: a message in any chat needs none.
              actions: [
                if (_codeNoRelay) EButton(key: deskPairUseMessageKey, label: l.pairUseMessageInstead, size: EBtnSize.sm, onPressed: () => _open(DeskPairWay.message)),
              ],
            ),
            SizedBox(height: Sp.x4),
          ],
          // Neutral until a name exists: the words need it.
          if (code == null && _codeError == null) _seenAs.isEmpty ? Text(l.pairNameForCode, style: ts.bodyDim) : const Center(child: ESpinner()),
          if (code != null) ...[
            Text(l.pairWordsLead, style: ts.bodyDim),
            SizedBox(height: Sp.x3),
            WordTiles(words: code.inviteWords, label: l.pairWordsLabel, dim: expired),
            SizedBox(height: Sp.x3),
            if (expired)
              ENotice(title: l.pairWordsExpiredTitle, text: l.pairWordsExpiredBody, tone: ETone.warn)
            else ...[
              Row(
                children: [
                  const ESpinner(),
                  SizedBox(width: Sp.x3),
                  Expanded(child: Semantics(liveRegion: true, child: Text(l.pairWordsWaiting, style: ts.body))),
                ],
              ),
              SizedBox(height: Sp.x2),
              Text(l.pairWordsBothOnline, style: ts.small),
              SizedBox(height: Sp.x1),
              Text(l.pairWordsFooter, style: ts.small),
            ],
            SizedBox(height: Sp.x4),
            Wrap(
              spacing: Sp.x2,
              runSpacing: Sp.x2,
              children: [
                EButton(
                  label: l.pairWordsCopy,
                  icon: EIcons.copy,
                  size: EBtnSize.sm,
                  onPressed: expired ? null : () => copyToClipboard(context, pairingWordsText(code.inviteWords), l.pairCopied),
                ),
                EButton(key: deskPairNewWordsKey, label: l.pairWordsNew, size: EBtnSize.sm, onPressed: () => _makeWords(fresh: true)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _messagePanel(AppLocalizations l, Widget nameField, bool online) {
    final ts = context.ts;
    final c = context.dc;
    final sent = _sent;
    if (sent != null) {
      final record = ref.watch(deskPairingByIdProvider(sent.id));
      return EPanel(
        key: deskPairMessagePanelKey,
        title: l.pairWayMessage,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DeskPairSteps(current: 2),
            SizedBox(height: Sp.x5),
            if (_sentDone || (record != null && record.state.isPaired)) ...[
              Semantics(header: true, child: Text(l.noticePairingReplied(ref.watch(deskPairingNameProvider(sent.id))), style: ts.h3)),
              SizedBox(height: Sp.x4),
              Align(alignment: AlignmentDirectional.centerStart, child: EButton.primary(label: l.noticeCheckWords, size: EBtnSize.sm, onPressed: () => deskAfterReply(context, ref, sent.id))),
            ] else ...[
              Row(
                children: [
                  const ESpinner(),
                  SizedBox(width: Sp.x3),
                  Expanded(child: Semantics(header: true, liveRegion: true, child: Text(l.pairAwaitReplyTitle, style: ts.h3))),
                ],
              ),
              SizedBox(height: Sp.x2),
              Text(l.pairAwaitReplyBody, style: ts.bodyDim),
              SizedBox(height: Sp.x2),
              // Past its time the wallet still takes a late reply once, then the invite ends.
              if ((record ?? sent).expiredAt(DateTime.now()))
                Text(l.pairLateCheck, style: ts.small)
              else if ((record ?? sent).expiresAt != null)
                Text('${l.pairExpiresIn} ${pairingSpan(l, (record ?? sent).expiresAt!.difference(DateTime.now()))}', style: ts.small),
              if (online) ...[SizedBox(height: Sp.x1), Text(l.pairByItself, style: ts.small)],
              // The invite's relay is not answering: the reply comes by message only.
              if (online && (record?.relayDown ?? false)) ...[
                SizedBox(height: Sp.x3),
                ENotice(title: l.pairRelayUnreachableTitle, text: record!.homeRelay.isEmpty ? null : record.homeRelay, tone: ETone.warn),
              ],
              SizedBox(height: Sp.x4),
              Wrap(
                spacing: Sp.x2,
                runSpacing: Sp.x2,
                children: [
                  EButton.primary(key: deskPairPasteReplyKey, label: l.pairPasteReply, icon: EIcons.paste, size: EBtnSize.sm, onPressed: _pasteReply),
                  EButton(label: l.pairCopyMessage, icon: EIcons.copy, size: EBtnSize.sm, onPressed: () => copyToClipboard(context, l.pairInviteMessage(sent.inviteLink ?? ''), l.pairMessageCopied)),
                  EButton(key: deskPairCancelSentKey, label: l.pairCancelInvite, kind: EBtnKind.danger, size: EBtnSize.sm, onPressed: _cancelSent),
                ],
              ),
            ],
          ],
        ),
      );
    }
    return EPanel(
      key: deskPairMessagePanelKey,
      title: l.pairWayMessage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DeskPairSteps(current: 1),
          SizedBox(height: Sp.x4),
          Text(l.pairMessageLead, style: ts.bodyDim),
          SizedBox(height: Sp.x4),
          nameField,
          SizedBox(height: Sp.x3),
          EField(
            label: l.pairExpiresIn,
            child: ESegmented<Duration>(
              segments: [
                ESegment(pairingInviteExpiries[0], l.pairExpiry1h),
                ESegment(pairingInviteExpiries[1], l.pairExpiry24h),
                ESegment(pairingInviteExpiries[2], l.pairExpiry7d),
              ],
              value: _expiry,
              onChanged: (v) => setState(() => _expiry = v),
            ),
          ),
          SizedBox(height: Sp.x4),
          Text(l.pairWhatTheyReceive, style: ts.label),
          SizedBox(height: Sp.x1),
          Container(
            padding: EdgeInsets.all(Sp.x3),
            decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
            child: SelectableText(l.pairInviteMessage('epiccash://pair/1/…'), style: ts.mono()),
          ),
          SizedBox(height: Sp.x2),
          Text(l.pairShareWarning, style: ts.small),
          SizedBox(height: Sp.x4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: EButton.primary(key: deskPairCopyInviteKey, label: l.pairCopyMessage, icon: EIcons.copy, size: EBtnSize.sm, onPressed: _copyInvite),
          ),
        ],
      ),
    );
  }

  Widget _inPersonPanel(AppLocalizations l, Widget nameField) {
    final ts = context.ts;
    // A card that paired (Got words or a link took it) is gone; a new one comes with the name.
    final card = ref.watch(deskOwnCardProvider) == null ? null : _card;
    return EPanel(
      key: deskPairInPersonPanelKey,
      title: l.pairInPerson,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          nameField,
          SizedBox(height: Sp.x4),
          if (card == null)
            Text(l.pairNameForCode, style: ts.bodyDim)
          else
            Wrap(
              spacing: Sp.x5,
              runSpacing: Sp.x4,
              children: [
                Semantics(label: l.pairCodeLabel, image: true, child: EQr(card.link, size: 176.u)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 340.u),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.pairShowCodeCaption, style: ts.bodyDim),
                      SizedBox(height: Sp.x3),
                      Text(l.pairCardHint, style: ts.small),
                    ],
                  ),
                ),
              ],
            ),
          SizedBox(height: Sp.x4),
          // Always there: it makes the code first when there is none yet.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: EButton(key: deskPairCopyCardKey, label: l.pairCardCopy, icon: EIcons.copy, size: EBtnSize.sm, onPressed: _copyCard),
          ),
        ],
      ),
    );
  }
}

/// One way in as a tile: its glyph, title (with a badge and an info icon where it has them),
/// one line; selected, it carries the accent edge. A null [onTap] shows it disabled, its line
/// saying why.
class _DeskWayTile extends StatelessWidget {
  const _DeskWayTile({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    required this.selected,
    required this.onTap,
    this.badge,
    this.info,
  });

  final IconData icon;
  final String title;
  final String text;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? badge;
  final String? info;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final ts = context.ts;
    final on = onTap != null;
    return Semantics(
      button: true,
      selected: selected,
      enabled: on,
      child: Material(
        color: selected ? c.s3 : c.s1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Rad.sm),
          side: BorderSide(color: selected ? c.text.withValues(alpha: 0.4) : c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(Sp.x4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20.u, color: on ? c.accentText : c.faint),
                SizedBox(width: Sp.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: Sp.x2,
                        runSpacing: Sp.x1,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(title, style: ts.strong.copyWith(color: on ? c.text : c.dim)),
                          ?badge,
                          if (info case final i?) EInfoHint(i, title: title),
                        ],
                      ),
                      SizedBox(height: Sp.x1),
                      Text(text, style: ts.small),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The step strip of Invite by message on the desktop: four bars, Invite, Reply, Finish link,
/// Words, the current one in the accent.
class DeskPairSteps extends StatelessWidget {
  const DeskPairSteps({super.key, required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final names = [l.pairStepInvite, l.pairStepReply, l.pairStepFinish, l.pairStepWords];
    return Semantics(
      container: true,
      label: l.pairStepOf(current, names[current - 1]),
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < names.length; i++) ...[
              if (i > 0) SizedBox(width: Sp.x1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 3.u,
                      decoration: BoxDecoration(
                        color: i + 1 == current ? c.accent : (i + 1 < current ? c.accent.withValues(alpha: 0.55) : c.line),
                        borderRadius: BorderRadius.circular(2.u),
                      ),
                    ),
                    SizedBox(height: Sp.x1),
                    // Shrinks rather than wraps or cuts.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        names[i],
                        maxLines: 1,
                        style: ts.small.copyWith(color: i + 1 == current ? c.text : c.dim, fontWeight: i + 1 == current ? FontWeight.w600 : null),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Copies [text] and confirms with a toast.
Future<void> copyToClipboard(BuildContext context, String text, String toast) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showEToast(context, toast, tone: ETone.ok);
}

/// Opens [pasted]: a pairing link (invite, reply, finish link, card) or five pairing words.
/// The invite asks "Pair with Anna?"; a reply opens the finish link to send, then the words;
/// a finish link opens the words. A reply or finish link of a pairing that finished already
/// (the relay was faster) only says so.
Future<void> deskOpenPairingText(BuildContext context, WidgetRef ref, String pasted, {Contact? contact}) async {
  // A device link is Link a device's, not a pairing's.
  if (isDeviceLinkText(pasted)) return showDeskLinkDevice(context, pasted: pasted);
  final api = ref.read(deskPairingApiProvider);
  final l = context.l10n;
  final kind = pairingLinkKind(pasted);
  // A shared message holds the link among words: the calls take the link alone.
  final text = pairingLinkIn(pasted) ?? pasted;
  // The pairings already finished before this link: a late reply or finish link changes nothing.
  var before = const <PairingRecord>[];
  try {
    before = await ref.read(deskPairingsProvider.future);
  } on Object {
    // No list: nothing counts as finished before.
  }
  final pairedBefore = {
    for (final r in before)
      if (r.state.isPaired) r.id,
  };
  bool already(PairingRecord r) {
    if (!pairedBefore.contains(r.id) || !context.mounted) return false;
    showEToast(context, l.pairAlreadyPaired(ref.read(deskPairingNameProvider(r.id)).isEmpty ? r.shownName : ref.read(deskPairingNameProvider(r.id))), tone: ETone.info);
    return true;
  }

  try {
    switch (kind) {
      case PairingLinkKind.invite:
        final preview = await api.openInvite(text);
        if (context.mounted) await showDeskIncoming(context, ref, preview, contact: contact);
      case PairingLinkKind.reply:
        // Their reply came in the chat: the finish link goes back the same way before the
        // words, which their wallet shows only once it has it.
        final r = await deskPairingCall(ref, (a) => a.openReply(text));
        if (already(r)) return;
        deskPairingFinishing.add(r.id);
        if (context.mounted) await deskAfterReply(context, ref, r.id);
      case PairingLinkKind.confirm:
        final r = await deskPairingCall(ref, (a) => a.openConfirm(text));
        if (already(r)) return;
        // The joiner's wait for it is up: it moves on to the words by itself.
        if (deskPairingStepsOnScreen.contains(r.id)) return;
        if (context.mounted) await showDeskCheckWords(context, ref, r.id);
      case PairingLinkKind.card:
        // Face to face without a camera: the other wallet's card against this wallet's own,
        // made now when this side has not handed one over yet.
        final own = ref.read(deskOwnCardProvider);
        final name = ref.read(deskSeenAsProvider).trim();
        if (own == null && name.isEmpty) throw pairingError(PairingFailure.invalid);
        final card = own ?? await api.showCard(name: name);
        final r = await deskPairingCall(ref, (a) => a.scanCard(cardId: card.id, text: text));
        await deskPairingCall(ref, (a) => dropOlderInPersonPairings(a, r));
        ref.read(deskOwnCardProvider.notifier).set(null);
        if (own == null && context.mounted) {
          await showEDialog<void>(context, builder: (_) => _CardBackDialog(name: r.shownName, link: card.link));
        }
        // The phone's camera read this computer's code from its screen, so the words check
        // holds (RFC 0002 7.4) although the phone's code came back by paste.
        if (context.mounted) await showDeskCheckWords(context, ref, r.id);
      case null:
        final words = pairingWordParts(text);
        final preview = await api.openWords([for (final w in words) (sasWordNamed(w) ?? sasWordOfEmoji(w))?.name ?? w]);
        if (context.mounted) await showDeskIncoming(context, ref, preview, contact: contact, viaLink: false);
    }
  } catch (error) {
    final failure = pairingFailureOf(error);
    if (failure == null || failure == PairingFailure.notFound || !context.mounted) {
      // A reply no invite of this wallet's opens: the other side answered someone else's.
      if (kind == PairingLinkKind.reply && failure == PairingFailure.notFound) throw WalletError(kind: WalletErrorKind.other, message: l.pairReplyNotHere);
      rethrow;
    }
    await showDeskOutcome(context, failure);
  }
}

/// The replies whose finish link a paste is opening: the Pair page's
/// own handling of the same answer stands back.
final Set<String> deskPairingFinishing = {};

/// After the reply to this wallet's invite [id] is in: the finish link when this wallet holds
/// one to send (the reply came in a message), then the words; only the words when the relay
/// carried the reply and the finish link with it.
Future<void> deskAfterReply(BuildContext context, WidgetRef ref, String id) async {
  String? finish;
  try {
    finish = await ref.read(deskPairingApiProvider).confirmLink(id);
  } on Object {
    finish = null;
  }
  if (!context.mounted) return;
  try {
    if (finish != null) {
      final checkNow = await showEDialog<bool>(context, dismissible: false, builder: (_) => DeskFinishDialog(pairingId: id, link: finish!));
      if (checkNow != true || !context.mounted) return;
    }
    await showDeskCheckWords(context, ref, id);
  } finally {
    deskPairingFinishing.remove(id);
  }
}

/// Invite by message, the inviter's step 3: the finish link to copy into the chat, then the
/// words. Pops true for Check the words.
class DeskFinishDialog extends ConsumerStatefulWidget {
  const DeskFinishDialog({super.key, required this.pairingId, required this.link});

  final String pairingId;
  final String link;

  @override
  ConsumerState<DeskFinishDialog> createState() => _DeskFinishDialogState();
}

class _DeskFinishDialogState extends ConsumerState<DeskFinishDialog> {
  bool _copied = false;

  Future<void> _copy() async {
    final l = context.l10n;
    await copyToClipboard(context, l.pairFinishMessage(widget.link), l.pairMessageCopied);
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    final name = ref.watch(deskPairingNameProvider(widget.pairingId));
    return EDialog(
      title: l.pairFinishTitle,
      width: 560.u,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DeskPairSteps(current: 3),
          SizedBox(height: Sp.x4),
          Text(l.pairFinishLead(name), style: ts.bodyDim),
          SizedBox(height: Sp.x3),
          Text(l.pairWhatTheyReceive, style: ts.label),
          SizedBox(height: Sp.x1),
          Container(
            padding: EdgeInsets.all(Sp.x3),
            decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
            child: SelectableText(l.pairFinishMessage(widget.link), key: deskConfirmBackLinkKey, style: ts.mono()),
          ),
          SizedBox(height: Sp.x2),
          Text(l.pairFinishThenCheck, style: ts.small),
        ],
      ),
      actions: [
        // Once it is copied, the words are the main step.
        if (_copied) ...[
          EButton(label: l.pairCopyMessage, icon: EIcons.copy, size: EBtnSize.sm, onPressed: _copy),
          EButton.primary(key: deskConfirmBackCheckKey, label: l.noticeCheckWords, size: EBtnSize.sm, autofocus: true, onPressed: () => Navigator.pop(context, true)),
        ] else ...[
          EButton(key: deskConfirmBackCheckKey, label: l.noticeCheckWords, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, true)),
          EButton.primary(key: deskFinishCopyKey, label: l.pairCopyMessage, icon: EIcons.copy, size: EBtnSize.sm, autofocus: true, onPressed: _copy),
        ],
      ],
    );
  }
}

/// This wallet's card link to paste into the other wallet, which read none yet; then the
/// words check.
class _CardBackDialog extends StatelessWidget {
  const _CardBackDialog({required this.name, required this.link});

  final String name;
  final String link;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    return EDialog(
      title: l.pairCardBackTitle(name),
      width: 520.u,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.pairCardBackBody(name), style: ts.bodyDim),
          SizedBox(height: Sp.x3),
          SelectableText(link, key: deskCardBackLinkKey, style: ts.mono()),
        ],
      ),
      actions: [
        EButton(label: l.commonCopy, icon: EIcons.copy, size: EBtnSize.sm, onPressed: () => copyToClipboard(context, link, l.pairCopied)),
        EButton.primary(key: deskCardBackCheckKey, label: l.noticeCheckWords, size: EBtnSize.sm, onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}

/// "Pair with Anna?" as a dialog. Pair answers; an invite that came as a link ([viaLink]) then
/// shows the reply to copy back (Invite by message, step 2), one found by its words the wait
/// for the confirm.
Future<void> showDeskIncoming(BuildContext context, WidgetRef ref, PairingInvitePreview p, {Contact? contact, bool viaLink = true}) async {
  final answered = await showEDialog<PairingRecord>(context, builder: (_) => _IncomingDialog(preview: p, contact: contact));
  if (answered == null || !context.mounted) return;
  await showEDialog<void>(context, dismissible: false, builder: (_) => DeskPairWaitingDialog(pairingId: answered.id, byMessage: viaLink));
}

class _IncomingDialog extends ConsumerStatefulWidget {
  const _IncomingDialog({required this.preview, this.contact});

  final PairingInvitePreview preview;
  final Contact? contact;

  @override
  ConsumerState<_IncomingDialog> createState() => _IncomingDialogState();
}

class _IncomingDialogState extends ConsumerState<_IncomingDialog> {
  late final _name = TextEditingController(text: ref.read(deskSeenAsProvider));
  bool _allow = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    final l = context.l10n;
    final name = _name.text.trim();
    if (name.isEmpty || utf8.encode(name).length > 48) {
      setState(() => _error = name.isEmpty ? l.pairSeenAsMissing : l.pairSeenAsTooLong);
      return;
    }
    ref.read(deskSeenAsProvider.notifier).set(name);
    setState(() => _busy = true);
    try {
      final r = await deskPairingCall(
        ref,
        (api) => api.acceptInvite(
          token: widget.preview.token,
          name: name,
          allowInvoices: _allow,
          contactId: widget.contact?.id,
          byHand: ref.read(deskPairNetProvider) != DeskPairNet.online,
        ),
      );
      if (mounted) Navigator.pop(context, r);
    } catch (error) {
      if (mounted) setState(() => _error = deskErrorText(error, l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final p = widget.preview;
    final left = p.expiresAt.difference(DateTime.now());
    return EDialog(
      title: l.pairIncomingTitle(p.name),
      width: 520.u,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DeskPairAvatar(name: p.name, size: 56.u),
              SizedBox(width: Sp.x3),
              EBadge(l.pairNameClaimed, icon: EIcons.user),
            ],
          ),
          SizedBox(height: Sp.x3),
          Text(l.pairIncomingBody(p.name), style: ts.bodyDim),
          if (p.asksInvoices) ...[
            SizedBox(height: Sp.x3),
            ESetGroup(
              gap: false,
              rows: [
                ESetRow(
                  title: l.pairIncomingAllowInvoices(p.name),
                  text: l.pairIncomingAllowHintDesktop,
                  control: ESwitch(value: _allow, semanticLabel: l.pairIncomingAllowInvoices(p.name), onChanged: _busy ? null : (v) => setState(() => _allow = v)),
                ),
              ],
            ),
          ],
          SizedBox(height: Sp.x3),
          EField(label: l.pairSeenAs, error: _error, child: EInput(controller: _name, onSubmitted: (_) => _pair())),
          SizedBox(height: Sp.x2),
          Text('${l.pairExpiresIn} ${pairingSpan(l, left)}', style: ts.small),
        ],
      ),
      actions: [
        EButton(label: l.pairNotNow, size: EBtnSize.sm, onPressed: _busy ? null : () => Navigator.pop(context)),
        EButton.primary(key: deskIncomingPairKey, label: l.pairTitle, size: EBtnSize.sm, busy: _busy, onPressed: _pair),
      ],
    );
  }
}

/// The wait for the inviter's confirm, closable; Send by hand shows the answer as a link.
class DeskPairWaitingDialog extends ConsumerStatefulWidget {
  const DeskPairWaitingDialog({super.key, required this.pairingId, this.byMessage = false});

  final String pairingId;

  /// Invite by message: the reply to copy, then the wait for the finish link.
  final bool byMessage;

  @override
  ConsumerState<DeskPairWaitingDialog> createState() => _DeskPairWaitingDialogState();
}

class _DeskPairWaitingDialogState extends ConsumerState<DeskPairWaitingDialog> {
  Timer? _collect;
  StreamSubscription<PairingEvent>? _events;
  String? _link;
  bool _copied = false;
  bool _done = false;

  /// A finish link found on the clipboard when the window came back: offered here, as the
  /// shell offers nothing while a dialog is up.
  bool _onScreen(PairingEvent e) => e.pairingId == widget.pairingId;

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
    deskPairingStepsOnScreen.add(widget.pairingId);
    final api = ref.read(deskPairingApiProvider);
    _collect = Timer.periodic(const Duration(seconds: 5), (_) => api.collect().ignore());
    _events = api.events().listen((e) {
      if (e.pairingId != widget.pairingId || !mounted || _done) return;
      if (e.kind == PairingEventKind.confirmed) {
        _finished();
      } else if (e.kind == PairingEventKind.failed && e.failure != null) {
        _done = true;
        Navigator.pop(context);
        unawaited(showDeskOutcome(context, e.failure!, name: e.name));
      }
    });
    if (widget.byMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final link = await api.replyLink(widget.pairingId);
          if (mounted) setState(() => _link = link);
        } catch (error) {
          if (mounted) showEToast(context, deskErrorText(error, context.l10n), tone: ETone.risk);
        }
      });
    }
  }

  @override
  void dispose() {
    deskPairingStepsOnScreen.remove(widget.pairingId);
    pairingWordsOnScreen.remove(_onScreen);
    _collect?.cancel();
    _events?.cancel();
    super.dispose();
  }

  Future<void> _byHand() async {
    final link = await ref.read(deskPairingApiProvider).replyLink(widget.pairingId);
    if (mounted) setState(() => _link = link);
  }

  /// Invite by message, the joiner's steps 2 and 3: the reply to copy into the chat, then the
  /// wait for the finish link, pasted here.
  Widget _byMessage(AppLocalizations l, String name) {
    final ts = context.ts;
    final c = context.dc;
    final link = _link;
    final online = ref.watch(deskPairNetProvider) == DeskPairNet.online;
    if (!_copied) {
      return EDialog(
        title: l.pairReplyTitle,
        width: 560.u,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DeskPairSteps(current: 2),
            SizedBox(height: Sp.x4),
            Text(l.pairReplyLead(name), style: ts.bodyDim),
            SizedBox(height: Sp.x3),
            Text(l.pairWhatTheyReceive, style: ts.label),
            SizedBox(height: Sp.x1),
            Container(
              padding: EdgeInsets.all(Sp.x3),
              decoration: BoxDecoration(color: c.s2, border: Border.all(color: c.line), borderRadius: BorderRadius.circular(Rad.sm)),
              child: link == null ? const Center(child: ESpinner()) : SelectableText(l.pairReplyMessage(link), style: ts.mono()),
            ),
          ],
        ),
        actions: [
          EButton(label: l.pairClosed, size: EBtnSize.sm, onPressed: () => Navigator.pop(context)),
          EButton.primary(key: deskReplyCopyKey, label: l.pairCopyMessage, icon: EIcons.copy, size: EBtnSize.sm, autofocus: true, onPressed: link == null ? null : _copyReply),
        ],
      );
    }
    return EDialog(
      title: l.pairAwaitFinishTitle,
      width: 560.u,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DeskPairSteps(current: 3),
          SizedBox(height: Sp.x4),
          Row(
            children: [
              const ESpinner(),
              SizedBox(width: Sp.x3),
              Expanded(child: Semantics(liveRegion: true, child: Text(l.pairAwaitFinishBody(name), style: ts.bodyDim))),
            ],
          ),
          if (online) ...[SizedBox(height: Sp.x3), Text(l.pairByItself, style: ts.small)],
        ],
      ),
      actions: [
        EButton(label: l.pairCopyMessage, icon: EIcons.copy, size: EBtnSize.sm, onPressed: link == null ? null : _copyReply),
        EButton(label: l.pairClosed, size: EBtnSize.sm, onPressed: () => Navigator.pop(context)),
        EButton.primary(
          key: deskPasteFinishKey,
          label: l.pairPasteFinish,
          icon: EIcons.paste,
          size: EBtnSize.sm,
          onPressed: _pasteFinish,
        ),
      ],
    );
  }

  Future<void> _copyReply() async {
    final link = _link;
    if (link == null) return;
    final l = context.l10n;
    await copyToClipboard(context, l.pairReplyMessage(link), l.pairMessageCopied);
    if (mounted) setState(() => _copied = true);
  }

  /// Paste finish link: the confirm in the clipboard, opened here; the words follow.
  Future<void> _pasteFinish() async {
    final l = context.l10n;
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    if (!mounted) return;
    if (pairingLinkKind(text) != PairingLinkKind.confirm) {
      showEToast(context, l.pairInvalidLink, tone: ETone.warn);
      return;
    }
    try {
      await deskPairingCall(ref, (a) => a.openConfirm(pairingLinkIn(text)!));
    } catch (error) {
      if (mounted) showEToast(context, deskErrorText(error, l), tone: ETone.warn);
      return;
    }
    _finished();
  }

  /// The finish link is in (pasted or by the relay): the words.
  void _finished() {
    if (_done || !mounted) return;
    _done = true;
    Navigator.pop(context);
    unawaited(showDeskCheckWords(context, ref, widget.pairingId));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final name = ref.watch(deskPairingNameProvider(widget.pairingId));
    final r = ref.watch(deskPairingByIdProvider(widget.pairingId));
    // The finish link came another way (pasted on the page, by the relay): the words.
    if (r != null && r.state.isPaired && !_done) WidgetsBinding.instance.addPostFrameCallback((_) => _finished());
    if (widget.byMessage) return _byMessage(l, name);
    final link = _link;
    return EDialog(
      title: link == null ? l.pairWaitingFinish(name) : l.pairByHandTitle,
      width: 520.u,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (link == null) ...[
            const Center(child: ESpinner()),
            SizedBox(height: Sp.x3),
            // By hand (Offline, Epicbox off) nothing continues in the background.
            if (ref.watch(deskPairNetProvider) == DeskPairNet.online) Text(l.pairWaitingBody, style: ts.bodyDim),
            // Offline or Epicbox off on this wallet is no relay trouble: it says which.
            if (ref.watch(deskPairNetProvider) case final net when (r?.relayDown ?? false) || net != DeskPairNet.online) ...[
              SizedBox(height: Sp.x3),
              switch (net) {
                DeskPairNet.offline => ENotice(title: l.pairOfflineHint, tone: ETone.warn),
                DeskPairNet.epicboxOff => ENotice(title: l.pairEpicboxOffNotice, tone: ETone.info),
                DeskPairNet.online => ENotice(title: l.pairRelayUnreachableTitle, text: l.pairRelayUnreachableBody, tone: ETone.warn),
              },
            ],
          ] else ...[
            Text(l.pairByHandLead(name), style: ts.bodyDim),
            SizedBox(height: Sp.x3),
            Text(l.pairByHandYourAnswer, style: ts.label),
            SizedBox(height: Sp.x1),
            SelectableText(link, style: ts.mono()),
            SizedBox(height: Sp.x2),
            Text(l.pairByHandFooter(name), style: ts.small),
          ],
        ],
      ),
      actions: [
        if (link == null)
          EButton(label: l.pairSendByHand, size: EBtnSize.sm, onPressed: _byHand)
        else
          EButton(label: l.commonCopy, icon: EIcons.copy, size: EBtnSize.sm, onPressed: () => copyToClipboard(context, link, l.pairCopied)),
        EButton.primary(label: l.pairClosed, size: EBtnSize.sm, onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}

/// The words check as a dialog: the four large tiles, Skip for now, They don't match, They
/// match; then the result as a toast.
/// Asks before removing the pairing with [name]: Keep, or Remove in risk.
Future<bool> deskConfirmRemovePairing(BuildContext context, String name) async {
  final l = context.l10n;
  final sure = await showEDialog<bool>(
    context,
    builder: (ctx) => EDialog(
      title: l.contactRemovePairingTitle(name),
      description: l.contactRemovePairingBody(name),
      tone: ETone.risk,
      icon: EIcons.trash,
      actions: [
        EButton(label: l.contactKeep, size: EBtnSize.sm, onPressed: () => Navigator.pop(ctx, false)),
        EButton(key: deskConfirmRemovePairingKey, label: l.contactRemove, kind: EBtnKind.danger, size: EBtnSize.sm, onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
  return sure ?? false;
}

/// The Remove button of [deskConfirmRemovePairing], for tests.
const Key deskConfirmRemovePairingKey = ValueKey('desk-confirm-remove-pairing');

/// Puts the pairing [r] in the contacts the way the user picks (security review: never
/// matched or saved for them): with [asNew], a form with the name it claims to check first;
/// else one of their contacts from the picker. True once it is in one.
Future<bool> deskPutPairingInContacts(BuildContext context, WidgetRef ref, PairingRecord r, {required bool asNew}) async {
  final l = context.l10n;
  final String contactId;
  final String name;
  if (asNew) {
    // The form owns its field: it is disposed with the dialog, after the close animation.
    final saved = await showEDialog<String>(context, builder: (_) => _SaveContactDialog(record: r));
    if (saved == null || saved.isEmpty || !context.mounted) return false;
    contactId = await ref.read(deskProvider.notifier).saveContact(Contact(id: '', name: saved, address: r.paymentsAddress));
    name = saved;
  } else {
    // Not Send's picker: the pairing joins the contact.
    final picked = await showContactPicker(context, description: context.l10n.deskConPickForPairing);
    if (picked == null) return false;
    contactId = picked.id;
    name = picked.name;
  }
  await deskPairingCall(ref, (api) => api.attach(r.id, contactId));
  if (context.mounted) showEToast(context, l.pairSavedAs(name), tone: ETone.ok);
  return true;
}

/// Save as a new contact: the name it claims, to check, and its payments address.
class _SaveContactDialog extends StatefulWidget {
  const _SaveContactDialog({required this.record});

  final PairingRecord record;

  @override
  State<_SaveContactDialog> createState() => _SaveContactDialogState();
}

class _SaveContactDialogState extends State<_SaveContactDialog> {
  late final _text = TextEditingController(text: widget.record.shownName);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = widget.record;
    return EDialog(
      title: l.pairSaveContactTitle(r.shownName),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          EField(label: l.deskConFieldName, child: EInput(key: deskSaveContactNameKey, controller: _text, autofocus: true)),
          if (r.paymentsAddress case final a?) ...[
            SizedBox(height: Sp.x3),
            EField(label: l.deskConFieldAddress, child: Text(a, style: context.ts.mono())),
          ],
        ],
      ),
      actions: [
        EButton(label: l.commonCancel, size: EBtnSize.sm, onPressed: () => Navigator.pop(context)),
        EButton.primary(label: l.deskConSave, size: EBtnSize.sm, onPressed: () => Navigator.pop(context, _text.text.trim())),
      ],
    );
  }
}

/// The contact of the name the pairing [r] chose, to offer first (a restore or a re-pair:
/// attaching it starts the key check); null when there is none or several.
Contact? deskSuggestedContact(WidgetRef ref, PairingRecord r) {
  final contacts = ref.watch(deskProvider.select((s) => s.contacts)) ?? const <Contact>[];
  if (r.contactId != null && contacts.any((c) => c.id == r.contactId)) return null;
  final all = ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[];
  return sameNamedContact<Contact>(r, contacts, (c) => c.name, paired: (c) => all.any((p) => p.id != r.id && p.contactId == c.id && p.state.isPaired));
}

/// Attaches the pairing [r] to [contact], the user's one-tap choice of [deskSuggestedContact].
Future<void> deskAttachPairing(BuildContext context, WidgetRef ref, PairingRecord r, Contact contact) async {
  final l = context.l10n;
  try {
    await deskPairingCall(ref, (api) => api.attach(r.id, contact.id));
    if (context.mounted) showEToast(context, l.pairSavedAs(contact.name), tone: ETone.ok);
  } catch (error) {
    if (context.mounted) showEToast(context, deskErrorText(error, l), tone: ETone.risk);
  }
}

/// The name field of the Save as a new contact form, for tests.
const Key deskSaveContactNameKey = ValueKey('desk-save-contact-name');

Future<void> showDeskCheckWords(BuildContext context, WidgetRef ref, String pairingId, {bool recheck = false}) async {
  // One words check per pairing: an answer's event and the paste that took it both ask.
  if (!_checksOpen.add(pairingId)) return;
  try {
    await showEDialog<void>(context, builder: (_) => _CheckDialog(pairingId: pairingId, recheck: recheck));
  } finally {
    _checksOpen.remove(pairingId);
  }
}

/// The pairings whose words check dialog is up.
final Set<String> _checksOpen = {};

/// Forgets the open words checks: a test that ends with one up never closes it, and the next
/// test's fake hands out the same ids.
@visibleForTesting
void deskForgetOpenChecks() => _checksOpen.clear();

/// [showDeskCheckWords] from a plain [BuildContext], for the screenshot catalogue.
Future<void> showDeskCheckWordsFor(BuildContext context, String pairingId) =>
    showEDialog<void>(context, builder: (_) => _CheckDialog(pairingId: pairingId, recheck: false));

class _CheckDialog extends ConsumerStatefulWidget {
  const _CheckDialog({required this.pairingId, required this.recheck});

  final String pairingId;
  final bool recheck;

  @override
  ConsumerState<_CheckDialog> createState() => _CheckDialogState();
}

class _CheckDialogState extends ConsumerState<_CheckDialog> {
  bool _busy = false;
  bool _allow = false;
  bool _onScreen(PairingEvent e) => e.pairingId == widget.pairingId;

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
  }

  @override
  void dispose() {
    pairingWordsOnScreen.remove(_onScreen);
    super.dispose();
  }

  Future<void> _answer(PairingCheck check) async {
    final l = context.l10n;
    final name = ref.read(deskPairingNameProvider(widget.pairingId));
    if (check == PairingCheck.mismatch) {
      final stop = await showEDialog<bool>(
        context,
        builder: (ctx) => EDialog(
          title: l.sasNoMatchTitle,
          description: l.sasNoMatchBody,
          tone: ETone.risk,
          icon: EIcons.alert,
          actions: [
            EButton(label: l.pairBack, size: EBtnSize.sm, onPressed: () => Navigator.pop(ctx, false)),
            EButton(label: l.sasStopPairing, kind: EBtnKind.danger, size: EBtnSize.sm, onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      );
      if (stop != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final r = await deskPairingCall(ref, (api) => api.checkWords(widget.pairingId, check));
      if (r != null && check == PairingCheck.match && _allow) await deskPairingCall(ref, (api) => api.setAllowInvoices(r.id, true));
      if (!mounted) return;
      final host = Navigator.of(context).context;
      final contacts = ref.read(deskProvider).contacts ?? const <Contact>[];
      final saved = r == null || (r.contactId != null && contacts.any((c) => c.id == r.contactId));
      Navigator.pop(context);
      // Not in the contacts yet: the result asks where it goes, as the phone's Verified screen
      // does; else the toast says it.
      if (!saved && check != PairingCheck.mismatch && !widget.recheck && host.mounted) {
        await showEDialog<void>(host, builder: (_) => DeskPairedSaveDialog(pairingId: r.id, verified: check == PairingCheck.match));
        return;
      }
      if (check == PairingCheck.match) showEToast(context, l.sasMatchedTitle(name), text: l.sasMatchedBody(name), tone: ETone.ok);
      if (check == PairingCheck.skip && !widget.recheck) showEToast(context, l.sasSkippedTitle(name), text: l.sasSkippedBody(name), tone: ETone.warn);
    } catch (error) {
      if (mounted) showEToast(context, deskErrorText(error, l), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final r = ref.watch(deskPairingByIdProvider(widget.pairingId));
    final name = ref.watch(deskPairingNameProvider(widget.pairingId));
    if (r == null) return EDialog(title: l.sasTitle);
    final lead = widget.recheck
        ? l.sasLeadRecheck(name)
        : (r.kind != PairingParty.person && r.way != PairingWay.inPerson ? l.sasLeadExchange(name) : l.sasLead(name));
    final offersInvoices = !widget.recheck && (r.asksInvoices || r.caps.issuesInvoices) && r.state == PairingState.paired;
    return EDialog(
      title: l.sasDialogTitle(name),
      width: 520.u,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [DeskPairAvatar(name: name, size: 48.u), SizedBox(width: Sp.x3), EBadge(l.pairNameClaimedShort, icon: EIcons.user)]),
          SizedBox(height: Sp.x3),
          Text(lead, style: ts.bodyDim),
          SizedBox(height: Sp.x4),
          WordTiles(words: r.sas, label: l.sasWordsLabel, size: WordTileSize.check),
          if (offersInvoices) ...[
            SizedBox(height: Sp.x4),
            ESetGroup(
              gap: false,
              rows: [
                ESetRow(
                  title: l.contactAllowInvoices,
                  text: l.sasAllowAfterMatch,
                  control: ESwitch(value: _allow, semanticLabel: l.contactAllowInvoices, onChanged: _busy ? null : (v) => setState(() => _allow = v)),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        EButton.ghost(key: deskCheckSkipKey, label: widget.recheck ? l.sasLater : l.sasSkip, onPressed: _busy ? null : () => _answer(PairingCheck.skip)),
        EButton(key: deskCheckNoMatchKey, label: l.sasNoMatch, size: EBtnSize.sm, onPressed: _busy ? null : () => _answer(PairingCheck.mismatch)),
        EButton.primary(key: deskCheckMatchKey, label: l.sasMatch, size: EBtnSize.sm, busy: _busy, onPressed: () => _answer(PairingCheck.match)),
      ],
    );
  }
}

/// After the words check of a pairing that is in no contact yet: Verified (or Paired, not
/// verified) and where it goes, Save as a new contact or Add to a contact, or Not now.
class DeskPairedSaveDialog extends ConsumerWidget {
  const DeskPairedSaveDialog({super.key, required this.pairingId, required this.verified});

  final String pairingId;
  final bool verified;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ts = context.ts;
    final r = ref.watch(deskPairingByIdProvider(pairingId));
    // The pairing is gone (folded into the old one when its keys came back, or removed): the
    // dialog closes instead of staying open with no name over the page.
    if (r == null && ref.watch(deskPairingsProvider).hasValue) {
      final route = ModalRoute.of(context);
      final nav = Navigator.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route != null && route.isActive) nav.removeRoute(route);
      });
      return const SizedBox.shrink();
    }
    final name = ref.watch(deskPairingNameProvider(pairingId));
    Future<void> put({required bool asNew}) async {
      if (r == null) return;
      if (await deskPutPairingInContacts(context, ref, r, asNew: asNew) && context.mounted) Navigator.pop(context);
    }

    final suggested = r == null ? null : deskSuggestedContact(ref, r);

    return EDialog(
      title: verified ? l.sasMatchedTitle(name) : l.sasSkippedTitle(name),
      tone: verified ? ETone.ok : ETone.warn,
      icon: verified ? EIcons.trusted : EIcons.shield,
      // Room for the three choices on one line in every language.
      width: suggested == null ? 520.u : 680.u,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(verified ? l.sasMatchedBody(name) : l.sasSkippedBody(name), style: ts.bodyDim),
          SizedBox(height: Sp.x4),
          Text(l.pairSaveContactTitle(name), style: ts.label),
        ],
      ),
      actions: [
        // With a contact to offer, the × is Not now: the three choices keep one line.
        if (suggested == null) EButton.ghost(key: deskSavedNotNowKey, label: l.pairNotNow, onPressed: () => Navigator.pop(context)),
        EButton(key: deskSavedAddToKey, label: l.pairAddToAContact, size: EBtnSize.sm, onPressed: () => put(asNew: false)),
        if (suggested == null)
          EButton.primary(key: deskSavedNewKey, label: l.pairSaveNewContact, size: EBtnSize.sm, onPressed: () => put(asNew: true))
        else ...[
          EButton(key: deskSavedNewKey, label: l.pairSaveNewContact, size: EBtnSize.sm, onPressed: () => put(asNew: true)),
          EButton.primary(
            key: deskSavedAddToNamedKey,
            label: l.pairAddToNamed(suggested.name),
            size: EBtnSize.sm,
            onPressed: () async {
              await deskAttachPairing(context, ref, r!, suggested);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ],
    );
  }
}

/// One outcome of the cases file as a dialog.
Future<void> showDeskOutcome(BuildContext context, PairingFailure failure, {String name = ''}) {
  final l = context.l10n;
  final tone = switch (failure) {
    PairingFailure.changedOnTheWay || PairingFailure.sealedForOther => ETone.risk,
    PairingFailure.cancelled || PairingFailure.newerVersion => ETone.info,
    _ => ETone.warn,
  };
  return showEDialog<void>(
    context,
    builder: (ctx) => EDialog(
      title: pairingFailureText(l, failure, name: name),
      description: pairingFailureBody(l, failure, name: name),
      tone: tone,
      icon: tone == ETone.info ? EIcons.info : EIcons.alert,
      actions: [EButton.primary(label: l.pairClosed, size: EBtnSize.sm, onPressed: () => Navigator.pop(ctx))],
    ),
  );
}

/// Contacts › Pending invites.
class DeskPendingScreen extends ConsumerStatefulWidget {
  const DeskPendingScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<DeskPendingScreen> createState() => _DeskPendingScreenState();
}

class _DeskPendingScreenState extends ConsumerState<DeskPendingScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // The rows' times move on while the page is open.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    final pending = ref.watch(deskPendingPairingsProvider);
    final nav = ref.read(deskNavProvider.notifier);
    final now = DateTime.now();
    Widget row(PairingRecord r) {
      final name = r.label ?? (r.state == PairingState.pendingInvite ? l.pairUnnamedInvite : deskPairingName(r, ref.watch(deskProvider.select((s) => s.contacts))));
      final left = r.expiresAt?.difference(now) ?? Duration.zero;
      final expired = r.state == PairingState.pendingInvite && r.expiredAt(now);
      final (String text, List<Widget> actions) = switch (r.state) {
        PairingState.pendingInvite when expired => (
          '${l.pendingExpired} · ${localDayMonth(l, r.expiresAt!)}',
          [
            EButton(
              label: l.pendingInviteAgain,
              size: EBtnSize.sm,
              onPressed: () async {
                await deskPairingCall(ref, (api) => api.cancelInvite(r.id));
                nav.go(DeskRoute.pair);
              },
            ),
          ],
        ),
        PairingState.pendingInvite => (
          r.way == PairingWay.words ? l.pendingWords(pairingSpan(l, left)) : l.pendingLink(pairingSpan(l, left)),
          [
            if (r.inviteLink != null) ...[
              EButton(label: l.pairCopyMessage, icon: EIcons.copy, size: EBtnSize.sm, onPressed: () => copyToClipboard(context, l.pairInviteMessage(r.inviteLink!), l.pairMessageCopied)),
              EButton(label: l.pairPasteReply, icon: EIcons.paste, size: EBtnSize.sm, onPressed: () => _pasteReply(context, ref)),
            ],
            if (r.inviteWords.isNotEmpty)
              EButton(
                label: l.pendingShowWords,
                size: EBtnSize.sm,
                onPressed: () => showEDialog<void>(
                  context,
                  builder: (ctx) => EDialog(
                    title: l.pairWordsTitle,
                    body: WordTiles(words: r.inviteWords, label: l.pairWordsLabel, size: WordTileSize.words),
                    actions: [EButton.primary(label: l.pairClosed, size: EBtnSize.sm, onPressed: () => Navigator.pop(ctx))],
                  ),
                ),
              ),
            EButton(label: l.commonCancel, size: EBtnSize.sm, onPressed: () => deskPairingCall(ref, (api) => api.cancelInvite(r.id))),
          ],
        ),
        // The other side may never confirm (They don't match there): the answer can go.
        PairingState.pendingReply => (
          '${l.pendingWaitingConfirm} · ${invitedLine(l, r.createdAt, now)}',
          [
            const ESpinner(),
            EButton(
              key: deskPendingRemoveKey,
              label: l.contactRemove,
              kind: EBtnKind.danger,
              size: EBtnSize.sm,
              onPressed: () => deskPairingCall(ref, (api) => api.cancelInvite(r.id)),
            ),
          ],
        ),
        _ => (
          l.pendingPairedCheck,
          [
            EButton.primary(label: l.contactCheckAgain, size: EBtnSize.sm, onPressed: () => showDeskCheckWords(context, ref, r.id)),
            // An abandoned pairing need not be checked to go.
            EButton(
              key: deskPendingRemovePairedKey,
              label: l.contactRemove,
              kind: EBtnKind.danger,
              size: EBtnSize.sm,
              onPressed: () async {
                if (await deskConfirmRemovePairing(context, name)) await deskPairingCall(ref, (api) => api.removePairing(r.id));
              },
            ),
          ],
        ),
      };
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
        child: Row(
          children: [
            DeskPairAvatar(
              name: r.label ?? r.name ?? '',
              size: 40.u,
              icon: r.label == null && (r.name ?? '').trim().isEmpty ? (r.way == PairingWay.words ? EIcons.words : EIcons.link) : null,
            ),
            SizedBox(width: Sp.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: ts.body),
                  Text(text, style: expired ? ts.small.copyWith(color: c.warn) : ts.small),
                ],
              ),
            ),
            Wrap(spacing: Sp.x2, children: actions),
          ],
        ),
      );
    }

    return EPage(
      title: l.pendingTitle,
      onBack: () => nav.go(DeskRoute.contacts),
      actions: [EButton.primary(label: l.pairTitle, icon: EIcons.trusted, size: EBtnSize.sm, onPressed: () => nav.go(DeskRoute.pair))],
      child: pending.isEmpty
          ? EEmpty(icon: EIcons.clock, title: l.pendingEmpty)
          : ESetGroup(rows: [for (final r in pending) row(r)]),
    );
  }
}

/// Paste reply on a Pending invites row, as on the Pair page.
Future<void> _pasteReply(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
  if (!context.mounted) return;
  if (pairingLinkKind(text) != PairingLinkKind.reply) {
    showEToast(context, l.pairInvalidLink, tone: ETone.warn);
    return;
  }
  try {
    await deskOpenPairingText(context, ref, text);
  } catch (error) {
    if (context.mounted) showEToast(context, deskErrorText(error, l), tone: ETone.warn);
  }
}
