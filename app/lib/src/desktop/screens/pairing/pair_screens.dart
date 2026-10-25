/// Pairing on the desktop (SPEC 2.1 to 2.3, 2.6, desktop frames): no camera, so Show my code
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

import '../../../l10n.dart' show AppLocalizations, localClock, localDay, localDayMonth;
import '../../../models.dart'
    show PairingCard, PairingCheck, PairingEvent, PairingEventKind, PairingFailure, PairingInvitePreview, PairingParty, PairingRecord, PairingState, PairingWay, pairingError, pairingFailureOf;
import '../../../pairing_api.dart';
import '../../../pairing_text.dart';
import '../../../sas_table.dart';
import '../../../ui/pairing/pairing_notices.dart' show pairingWordsOnScreen;
import '../../../ui/pairing/pairing_parts.dart' show WordTileSize, WordTiles;
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../data/pairing_state.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../transfer/contact_picker.dart' show showContactPicker;

/// Keys for tests.
const Key deskPairEnterKey = ValueKey('desk-pair-enter');
const Key deskPairGoKey = ValueKey('desk-pair-go');
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
/// invite nobody named yet (PAIR-LNX-8).
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

/// Contacts › Pair: Show my code (an invite's code and its words) with Enter link or words,
/// and Invite online. [arg] is the [Contact] the pairing will attach to, if any.
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
  PairingRecord? _code;

  /// While nothing reaches the relays (Offline, Epicbox off): this wallet's card, shown and
  /// copied for pairing face to face, made for the name [_cardFor].
  PairingCard? _card;
  String? _cardFor;
  String? _codeError;
  String? _enterError;

  /// No name yet: the code waits for one, and the field says so only once the user tried.
  bool _needName = false;
  bool _triedInvite = false;
  bool _busy = false;
  Timer? _tick;
  Timer? _collect;
  Timer? _typed;
  StreamSubscription<PairingEvent>? _events;

  /// Any answer opens its words here.
  bool _onScreen(PairingEvent e) => e.kind == PairingEventKind.replied;

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
    _name.text = ref.read(deskSeenAsProvider);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    final api = ref.read(deskPairingApiProvider);
    _collect = Timer.periodic(const Duration(seconds: 10), (_) => api.collect().ignore());
    _events = api.events().listen((e) {
      if (e.kind == PairingEventKind.replied && e.pairingId != null && mounted) {
        unawaited(showDeskCheckWords(context, ref, e.pairingId!));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _makeCode());
  }

  @override
  void dispose() {
    pairingWordsOnScreen.remove(_onScreen);
    _tick?.cancel();
    _collect?.cancel();
    _typed?.cancel();
    _events?.cancel();
    _enter.dispose();
    _name.dispose();
    super.dispose();
  }

  String get _seenAs => _name.text.trim();

  Future<void> _makeCode() async {
    final l = context.l10n;
    if (_seenAs.isEmpty) {
      setState(() {
        _needName = true;
        _codeError = null;
      });
      return;
    }
    _needName = false;
    if (ref.read(deskPairNetProvider) != DeskPairNet.online) {
      // Pairing words need a relay; the card is made here and travels by hand.
      final name = _seenAs;
      try {
        // The card out now, unless the name changed since it was made.
        final own = ref.read(deskOwnCardProvider);
        final card = own != null && (_cardFor == null || _cardFor == name) ? own : await ref.read(deskPairingApiProvider).showCard(name: name);
        ref.read(deskOwnCardProvider.notifier).set(card);
        if (mounted) {
          setState(() {
            _card = card;
            _cardFor = name;
            _codeError = null;
          });
        }
      } catch (error) {
        if (mounted) setState(() => _codeError = deskErrorText(error, l));
      }
      return;
    }
    final old = _code;
    try {
      final code = await deskPairingCall(
        ref,
        (api) => api.makeInvite(name: _seenAs, expiry: pairingWordsExpiry, words: true, label: _contact?.name, contactId: _contact?.id),
      );
      if (old != null) await deskPairingCall(ref, (api) => api.cancelInvite(old.id));
      if (mounted) {
        setState(() {
          _code = code;
          _codeError = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _codeError = deskErrorText(error, l));
    }
  }

  void _nameChanged() {
    ref.read(deskSeenAsProvider.notifier).set(_name.text);
    setState(() {});
    // The first name typed makes the code once typing pauses; a later change on Enter or
    // New words, so no code is made per key (PAIR-LNX-6).
    _typed?.cancel();
    if (_code == null && _card == null && _seenAs.isNotEmpty) {
      _typed = Timer(const Duration(milliseconds: 700), () {
        if (mounted) _makeCode();
      });
    }
  }

  /// The typed words, by table name or emoji.
  List<String> get _words => _enter.text.trim().split(RegExp(r'[\s,·]+')).where((w) => w.isNotEmpty).toList();

  bool get _ready {
    if (pairingLinkIn(_enter.text) != null) return true;
    final w = _words;
    return w.length == pairingWordCount && w.every((x) => (sasWordNamed(x) ?? sasWordOfEmoji(x)) != null);
  }

  /// This wallet's card for pairing face to face: the other wallet pastes its link, and this
  /// one pastes theirs back.
  Future<void> _copyCard() async {
    final l = context.l10n;
    if (_seenAs.isEmpty) {
      setState(() => _triedInvite = true);
      return;
    }
    try {
      final card = ref.read(deskOwnCardProvider) ?? await ref.read(deskPairingApiProvider).showCard(name: _seenAs);
      ref.read(deskOwnCardProvider.notifier).set(card);
      if (!mounted) return;
      if (ref.read(deskPairNetProvider) != DeskPairNet.online) {
        setState(() {
          _card = card;
          _cardFor ??= _seenAs;
        });
      }
      await copyToClipboard(context, card.link, l.pairCopied);
    } catch (error) {
      if (mounted) showEToast(context, deskErrorText(error, l), tone: ETone.risk);
    }
  }

  Future<void> _go() async {
    if (_busy || !_ready) return;
    final l = context.l10n;
    // A card link needs this wallet's own card, and a card needs the name others see.
    if (pairingLinkKind(_enter.text) == PairingLinkKind.card && ref.read(deskOwnCardProvider) == null && _seenAs.isEmpty) {
      setState(() {
        _triedInvite = true;
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
      if (mounted) setState(() => _enterError = deskErrorText(error, l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyInvite() async {
    final l = context.l10n;
    if (_seenAs.isEmpty) {
      setState(() => _triedInvite = true);
      return;
    }
    try {
      final invite = await deskPairingCall(
        ref,
        (api) => api.makeInvite(name: _seenAs, expiry: _expiry, label: _contact?.name, contactId: _contact?.id),
      );
      if (!mounted) return;
      await copyToClipboard(context, l.pairShareText(_seenAs, invite.inviteLink ?? '', localDayTime(l, invite.expiresAt!)), l.pairCopied);
    } catch (error) {
      if (mounted) showEToast(context, deskErrorText(error, l), tone: ETone.risk);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    final code = _code;
    final now = DateTime.now();
    final left = code?.expiresAt?.difference(now);
    final expired = left != null && left.isNegative;
    final net = ref.watch(deskPairNetProvider);
    // Offline as with Epicbox off: the invite, the answer and the card travel by hand.
    final byHand = net != DeskPairNet.online;
    // A card that paired (Enter link took it) is gone; a new one is made on the next name.
    final card = ref.watch(deskOwnCardProvider) == null ? null : _card;
    final preview = l.pairShareText(_seenAs.isEmpty ? l.pairYourNamePlaceholder : _seenAs, 'epiccash://pair/1/…', localDayTime(l, now.add(_expiry)));

    final show = EPanel(
      title: l.pairShowMyCode,
      headTrailing: left != null && !expired ? EBadge(l.pairWordsDesktopChip(pairingClock(left)), icon: EIcons.clock) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_codeError != null) ...[ENotice(title: _codeError!, tone: ETone.warn), SizedBox(height: Sp.x4)],
          // Neutral until a name exists: the code needs it (the field is in Invite online).
          if (_needName && code == null && card == null) Text(l.pairNameForCode, style: ts.bodyDim),
          if (byHand && card != null)
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
                      Text(l.pairWordsNeedEpicbox, style: ts.small),
                    ],
                  ),
                ),
              ],
            ),
          if (!byHand && code != null)
            Wrap(
              spacing: Sp.x5,
              runSpacing: Sp.x4,
              children: [
                Opacity(opacity: expired ? 0.4 : 1, child: Semantics(label: l.pairCodeLabel, image: true, child: EQr(code.inviteLink ?? '', size: 176.u))),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 340.u),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.pairingDesktopShowCodeLead, style: ts.bodyDim),
                      SizedBox(height: Sp.x3),
                      WordTiles(words: code.inviteWords, label: l.pairWordsLabel, size: WordTileSize.small, dim: expired),
                      SizedBox(height: Sp.x3),
                      if (expired) ...[ENotice(title: l.pairWordsExpiredTitle, text: l.pairWordsExpiredBody, tone: ETone.warn), SizedBox(height: Sp.x3)],
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
                          EButton(label: l.pairWordsNew, size: EBtnSize.sm, onPressed: _makeCode),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          SizedBox(height: Sp.x5),
          Divider(height: 1, color: c.line),
          SizedBox(height: Sp.x4),
          EField(
            label: l.pairEnter,
            help: l.pairEnterDesktopHint,
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
                EButton.primary(key: deskPairGoKey, label: l.pairTitle, busy: _busy, onPressed: _ready ? _go : null),
              ],
            ),
          ),
          SizedBox(height: Sp.x3),
          Row(
            children: [
              Expanded(child: Text(l.pairCardHint, style: ts.small)),
              SizedBox(width: Sp.x2),
              EButton(key: deskPairCopyCardKey, label: l.pairCardCopy, icon: EIcons.copy, size: EBtnSize.sm, onPressed: _copyCard),
            ],
          ),
        ],
      ),
    );

    final invite = EPanel(
      title: l.pairingInviteOnline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(byHand ? l.pairOnlineLeadByHand : l.pairingDesktopInviteLead, style: ts.bodyDim),
          SizedBox(height: Sp.x4),
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
            child: SelectableText(preview, style: ts.mono()),
          ),
          SizedBox(height: Sp.x2),
          // By hand the invite is just as open: the warning stays.
          Text(l.pairShareWarning, style: ts.small),
          if (byHand) ...[SizedBox(height: Sp.x1), Text(l.pairWordsNeedEpicbox, style: ts.small)],
          SizedBox(height: Sp.x4),
          Align(
            alignment: Alignment.centerRight,
            child: EButton.primary(key: deskPairCopyInviteKey, label: l.pairCopyInvite, icon: EIcons.copy, size: EBtnSize.sm, onPressed: _copyInvite),
          ),
        ],
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
          ConstrainedBox(constraints: BoxConstraints(maxWidth: 720.u), child: Text(l.pairLead, style: ts.bodyDim)),
          SizedBox(height: Sp.x5),
          if (net == DeskPairNet.offline) ...[ENotice(title: l.pairOfflineHint, tone: ETone.warn), SizedBox(height: Sp.x4)],
          if (net == DeskPairNet.epicboxOff) ...[ENotice(title: l.pairEpicboxOffNotice, tone: ETone.info), SizedBox(height: Sp.x4)],
          // One name for both ways: the code shown in person and the invite sent online.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420.u),
            child: EField(
              label: l.pairSeenAs,
              // Only once something needed the name, never on a page just opened (PAIR-LNX-2).
              error: _triedInvite && _seenAs.isEmpty ? l.pairSeenAsMissing : null,
              child: EInput(
                controller: _name,
                autofocus: _name.text.isEmpty,
                onChanged: (_) => _nameChanged(),
                onSubmitted: (_) {
                  if (_seenAs.isEmpty) setState(() => _triedInvite = true);
                  _makeCode();
                },
              ),
            ),
          ),
          SizedBox(height: Sp.x5),
          LayoutBuilder(
            builder: (context, box) => box.maxWidth >= 900.u
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: show),
                      SizedBox(width: Sp.x5),
                      Expanded(child: invite),
                    ],
                  )
                : Column(children: [show, SizedBox(height: Sp.x5), invite]),
          ),
        ],
      ),
    );
  }
}

/// A local day and time for an expiry, as the share text says it.
String localDayTime(AppLocalizations l, DateTime t) => l.dateWithTime(localDay(l, t), localClock(l, t));

/// Copies [text] and confirms with a toast.
Future<void> copyToClipboard(BuildContext context, String text, String toast) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showEToast(context, toast, tone: ETone.ok);
}

/// Opens [text]: a pairing link (invite, answer, confirm, card) or five pairing words. The
/// invite asks "Pair with Anna?"; an answer or a confirm opens the words check.
Future<void> deskOpenPairingText(BuildContext context, WidgetRef ref, String pasted, {Contact? contact}) async {
  final api = ref.read(deskPairingApiProvider);
  final kind = pairingLinkKind(pasted);
  // A shared message holds the link among words: the calls take the link alone (PAIR-LNX-1).
  final text = pairingLinkIn(pasted) ?? pasted;
  try {
    switch (kind) {
      case PairingLinkKind.invite:
        final preview = await api.openInvite(text);
        if (context.mounted) await showDeskIncoming(context, ref, preview, contact: contact);
      case PairingLinkKind.reply:
        // Their answer came by hand: the confirm goes back by hand before the words, which
        // their wallet shows only once it has it (PAIR-AND-10).
        final r = await deskPairingCall(ref, (a) => a.openReply(text));
        final confirm = await api.confirmLink(r.id).then<String?>((v) => v, onError: (Object _) => null);
        if (confirm != null && context.mounted) {
          await showEDialog<void>(context, builder: (_) => _ConfirmBackDialog(name: r.shownName, link: confirm));
        }
        if (context.mounted) await showDeskCheckWords(context, ref, r.id);
      case PairingLinkKind.confirm:
        final r = await deskPairingCall(ref, (a) => a.openConfirm(text));
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
        if (context.mounted) await showDeskCheckWords(context, ref, r.id);
      case null:
        final words = text.trim().split(RegExp(r'[\s,·]+')).where((w) => w.isNotEmpty).toList();
        final preview = await api.openWords([for (final w in words) (sasWordNamed(w) ?? sasWordOfEmoji(w))?.name ?? w]);
        if (context.mounted) await showDeskIncoming(context, ref, preview, contact: contact);
    }
  } catch (error) {
    final failure = pairingFailureOf(error);
    if (failure == null || failure == PairingFailure.notFound || !context.mounted) rethrow;
    await showDeskOutcome(context, failure);
  }
}

/// The inviter's confirm to send back by hand, as the phone's Send by hand; then the words
/// check.
class _ConfirmBackDialog extends StatelessWidget {
  const _ConfirmBackDialog({required this.name, required this.link});

  final String name;
  final String link;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    return EDialog(
      title: l.pairByHandTitle,
      width: 520.u,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.pairConfirmByHandLead(name), style: ts.bodyDim),
          SizedBox(height: Sp.x3),
          SelectableText(link, key: deskConfirmBackLinkKey, style: ts.mono()),
        ],
      ),
      actions: [
        EButton(label: l.commonCopy, icon: EIcons.copy, size: EBtnSize.sm, onPressed: () => copyToClipboard(context, link, l.pairCopied)),
        EButton.primary(key: deskConfirmBackCheckKey, label: l.noticeCheckWords, size: EBtnSize.sm, onPressed: () => Navigator.pop(context)),
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

/// "Pair with Anna?" as a dialog. Pair answers and waits for the confirm in the next dialog.
Future<void> showDeskIncoming(BuildContext context, WidgetRef ref, PairingInvitePreview p, {Contact? contact}) async {
  final answered = await showEDialog<PairingRecord>(context, builder: (_) => _IncomingDialog(preview: p, contact: contact));
  if (answered == null || !context.mounted) return;
  await showEDialog<void>(context, dismissible: false, builder: (_) => _WaitingDialog(pairingId: answered.id));
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
class _WaitingDialog extends ConsumerStatefulWidget {
  const _WaitingDialog({required this.pairingId});

  final String pairingId;

  @override
  ConsumerState<_WaitingDialog> createState() => _WaitingDialogState();
}

class _WaitingDialogState extends ConsumerState<_WaitingDialog> {
  Timer? _collect;
  StreamSubscription<PairingEvent>? _events;
  String? _link;
  bool _onScreen(PairingEvent e) => e.pairingId == widget.pairingId;

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
    final api = ref.read(deskPairingApiProvider);
    _collect = Timer.periodic(const Duration(seconds: 5), (_) => api.collect().ignore());
    _events = api.events().listen((e) {
      if (e.pairingId != widget.pairingId || !mounted) return;
      if (e.kind == PairingEventKind.confirmed) {
        Navigator.pop(context);
        unawaited(showDeskCheckWords(context, ref, widget.pairingId));
      } else if (e.kind == PairingEventKind.failed && e.failure != null) {
        Navigator.pop(context);
        unawaited(showDeskOutcome(context, e.failure!, name: e.name));
      }
    });
  }

  @override
  void dispose() {
    pairingWordsOnScreen.remove(_onScreen);
    _collect?.cancel();
    _events?.cancel();
    super.dispose();
  }

  Future<void> _byHand() async {
    final link = await ref.read(deskPairingApiProvider).replyLink(widget.pairingId);
    if (mounted) setState(() => _link = link);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final name = ref.watch(deskPairingNameProvider(widget.pairingId));
    final r = ref.watch(deskPairingByIdProvider(widget.pairingId));
    final link = _link;
    return EDialog(
      title: link == null ? l.pairWaitingTitle(name) : l.pairByHandTitle,
      width: 520.u,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (link == null) ...[
            const Center(child: ESpinner()),
            SizedBox(height: Sp.x3),
            Text(l.pairWaitingBody, style: ts.bodyDim),
            if ((r?.relayDown ?? false) || ref.watch(deskPairNetProvider) != DeskPairNet.online) ...[
              SizedBox(height: Sp.x3),
              ENotice(title: l.pairRelayUnreachableTitle, text: l.pairRelayUnreachableBody, tone: ETone.warn),
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
/// Asks before removing the pairing with [name] (SPEC 2.4): Keep, or Remove in risk.
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
    // Not Send's picker: the pairing joins the contact (PAIR-LNX-11).
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
/// attaching it starts the key check, PAIR-LNX-7); null when there is none or several.
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
      // does (PAIR-LNX-4); else the toast says it.
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
class DeskPendingScreen extends ConsumerWidget {
  const DeskPendingScreen({super.key, this.arg});

  final Object? arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            if (r.inviteLink != null)
              EButton(label: l.pendingCopyLink, icon: EIcons.copy, size: EBtnSize.sm, onPressed: () => copyToClipboard(context, r.inviteLink!, l.pairCopied)),
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
          l.pendingWaitingConfirm(pairingSpan(l, now.difference(r.createdAt))),
          [
            const ESpinner(),
            EButton(
              key: deskPendingRemoveKey,
              label: l.contactRemove,
              size: EBtnSize.sm,
              onPressed: () => deskPairingCall(ref, (api) => api.cancelInvite(r.id)),
            ),
          ],
        ),
        _ => (
          l.pendingPairedCheck,
          [
            EButton.primary(label: l.contactCheckAgain, size: EBtnSize.sm, onPressed: () => showDeskCheckWords(context, ref, r.id)),
            // An abandoned pairing need not be checked to go (PAIR-AND-7).
            EButton(
              key: deskPendingRemovePairedKey,
              label: l.contactRemove,
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
