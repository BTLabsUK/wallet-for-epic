// SPDX-License-Identifier: Apache-2.0
/// Pairing on the desktop: one Pair page (Your invite as a QR with Copy invite on the left,
/// Have their invite? with a Paste field on the right), the incoming dialog (from a contact or
/// by invite), the wait for the inviter's confirmation with the answer to copy by hand, the
/// confirmation to copy after an answer taken by hand, the words check without Skip, the
/// request dialog of the contact pane (Way 1) and the Pair requests dialog.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../contact_label.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../devices/device_link_code.dart' show isDeviceLinkText;
import '../../../history/domain_check_book.dart' show DomainStatus;
import '../../../key_picture.dart';
import '../../../l10n.dart' show localDayMonth;
import '../../../models.dart'
    show
        PairRequest,
        PairingCheck,
        PairingEvent,
        PairingEventKind,
        PairingFailure,
        PairingInvitePreview,
        PairingRecord,
        PairingState,
        SealMode,
        WalletError,
        epicboxKey,
        pairingFailureOf;
import '../../../pairing_api.dart';
import '../../../pairing_text.dart';
import '../../../boosts.dart' show boostRelays;
import '../../../trust_ids.dart';
import '../../../ui/key_picture.dart';
import '../../../ui/pairing/invite_links.dart';
import '../../../name_service/name_service.dart';
import '../../../trust/policy.dart' show featureNameService, mayOfferPair, statedAutomated;
import '../../../ui/pairing/pairing_notices.dart' show pairingWordsOnScreen;
import '../../../ui/pairing/pairing_parts.dart' show NoPaymentsBadge, PairTimeLeft, WordTileSize, WordTiles;
import '../../data/desk_errors.dart' show deskErrorText;
import '../../data/name_service_state.dart';
import '../../data/pairing_state.dart';
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../devices/link_flow.dart' show showDeskLinkDevice;
import '../scan/desk_scan.dart';
import '../scan/desk_scan_text.dart';
import 'desk_allow_row.dart';
import 'name_service_dialogs.dart';
import '../wallet/contact_label_menu.dart' show ContactLabelField;
import 'add_to_contacts_button.dart' show DeskAddToContactsButton;
import '../transfer/contact_picker.dart' show showContactPicker;

/// Keys for tests.
const Key deskPairEnterKey = ValueKey('desk-pair-enter');
const Key deskPairGoKey = ValueKey('desk-pair-go');
const Key deskPairPasteKey = ValueKey('desk-pair-paste');
const Key deskPairScanKey = ValueKey('desk-pair-scan');
const Key deskPairCopyInviteKey = ValueKey('desk-pair-copy-invite');
const Key deskPairChangeNameKey = ValueKey('desk-pair-change-name');
const Key deskPairNameKey = ValueKey('desk-pair-name');
const Key deskPairNameSaveKey = ValueKey('desk-pair-name-save');
const Key deskPairStatusKey = ValueKey('desk-pair-status');
const Key deskPairConfirmationKey = ValueKey('desk-pair-confirmation');
const Key deskPairCheckWordsKey = ValueKey('desk-pair-check-words');
const Key deskIncomingPairKey = ValueKey('desk-incoming-pair');
const Key deskIncomingNotNowKey = ValueKey('desk-incoming-not-now');
const Key deskIncomingServerKey = ValueKey('desk-incoming-server');
const Key deskIncomingSourceKey = ValueKey('desk-incoming-source');
const Key deskIncomingExpiresKey = ValueKey('desk-incoming-expires');
const Key deskWaitingCancelKey = ValueKey('desk-waiting-cancel');
const Key deskWaitingCloseKey = ValueKey('desk-waiting-close');
const Key deskWaitingAnswerKey = ValueKey('desk-waiting-answer');
const Key deskWaitingCopyKey = ValueKey('desk-waiting-copy');
const Key deskWaitingFinishKey = ValueKey('desk-waiting-finish');
const Key deskWaitingFinishGoKey = ValueKey('desk-waiting-finish-go');
const Key deskWaitingScanKey = ValueKey('desk-waiting-scan');
const Key deskConfirmCopyKey = ValueKey('desk-confirm-copy');
const Key deskConfirmCheckKey = ValueKey('desk-confirm-check');
const Key deskCheckMatchKey = ValueKey('desk-check-match');
const Key deskCheckNoMatchKey = ValueKey('desk-check-no-match');
const Key deskCheckLaterKey = ValueKey('desk-check-later');
const Key deskSavedNotNowKey = ValueKey('desk-saved-not-now');
const Key deskSavedAddToNamedKey = ValueKey('desk-saved-add-to-named');
const Key deskSavedAddKey = ValueKey('desk-saved-add');
const Key deskWay1SendKey = ValueKey('desk-way1-send');
const Key deskWay1ShowInviteKey = ValueKey('desk-way1-show-invite');
const Key deskRequestsPairKey = ValueKey('desk-requests-pair');
const Key deskRequestsNotNowKey = ValueKey('desk-requests-not-now');

/// The invite as the text the QR or Copy invite carries: the page link when an invite page is
/// set, else the bare text. One place, so a shorter form later changes nothing else.
String deskPairingInviteText(PairingRecord invite, {String? invitePage}) =>
    inviteShareText(InviteLink(InviteKind.pair, invite.inviteLink ?? ''), invitePage: invitePage);

/// The contact's (or the invite's) initials in the desktop avatar; [icon] instead for a
/// pairing nobody named yet.
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

/// Contacts › Pair: Your invite (the standing QR, Copy invite, the name they see) on the
/// left, Have their invite? (a Paste field) on the right. One handler for anything pasted: an
/// invite → Pair with …?; an answer → the confirmation to copy; a confirmation → the words;
/// anything else → "Not a pairing invite". [arg] is the [Contact] the page is framed for.
class DeskPairScreen extends ConsumerStatefulWidget {
  const DeskPairScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<DeskPairScreen> createState() => _DeskPairScreenState();
}

class _DeskPairScreenState extends ConsumerState<DeskPairScreen> {
  late final Contact? _contact = widget.arg is Contact ? widget.arg! as Contact : null;
  final _enter = TextEditingController();
  PairingRecord? _invite;
  String? _inviteError;
  String? _enterError;
  bool _busy = false;
  void Function()? _unboost;
  StreamSubscription<PairingEvent>? _events;

  /// Pairings answered while this page is up: the status under the invite follows them.
  final Set<String> _answered = {};

  /// An answer pasted here: its confirmation stays under the invite until the words.
  String? _confirmFor;
  String? _confirmLink;

  bool _onScreen(PairingEvent e) => e.pairingId != null && (_answered.contains(e.pairingId) || e.pairingId == _invite?.id);

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
    final api = ref.read(deskPairingApiProvider);
    if (ref.read(deskPairNetProvider) == DeskPairNet.online) _unboost = boostRelays(ref.read(deskApiProvider).boosts, const Duration(seconds: 10));
    _events = api.events().listen(_onEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _makeInvite());
  }

  @override
  void dispose() {
    pairingWordsOnScreen.remove(_onScreen);
    _unboost?.call();
    _events?.cancel();
    _enter.dispose();
    super.dispose();
  }

  void _onEvent(PairingEvent e) {
    final id = e.pairingId;
    if (!mounted || id == null) return;
    if (e.kind == PairingEventKind.replied && (id == _invite?.id || _answered.contains(id))) {
      _answered.add(id);
      if (id == _invite?.id) _makeInvite();
      final record = ref.read(deskPairingByIdProvider(id));
      // A paste in progress took this answer by hand: its confirmation box follows, not the words.
      if (!_busy && _confirmFor != id && record?.expectAddress == null) {
        unawaited(_attachIfFramed(id).then((_) => mounted ? showDeskCheckWords(context, ref, id) : null));
      }
      setState(() {});
    }
    if (e.kind == PairingEventKind.failed && _answered.contains(id)) setState(() => _answered.remove(id));
  }

  Future<void> _attachIfFramed(String id) async {
    final c = _contact;
    if (c == null) return;
    final record = ref.read(deskPairingByIdProvider(id));
    if (record == null || record.contactId == c.id) return;
    await deskAttachPairingTo(context, ref, record, c);
  }

  String get _seenAs {
    final name = ref.read(deskSeenAsProvider).trim();
    return name.isEmpty ? unnamedPeerName : name;
  }

  Future<void> _makeInvite() async {
    final l = context.l10n;
    try {
      final invite = await ref.read(deskPairingApiProvider).standingCode(name: _seenAs);
      if (mounted) {
        setState(() {
          _invite = invite;
          _inviteError = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _inviteError = deskErrorText(error, l));
    }
  }

  Future<void> _copyInvite() async {
    final invite = _invite;
    if (invite == null) return;
    await copyToClipboard(context, context.l10n.pairInviteMessage(deskPairingInviteText(invite, invitePage: ref.read(invitePageProvider))), context.l10n.pairMessageCopied);
  }

  Future<void> _changeName() async {
    final name = await showPairNameDialog(context, ref.read(deskSeenAsProvider));
    if (name == null || !mounted) return;
    await ref.read(deskSeenAsProvider.notifier).set(name);
    await _makeInvite();
  }

  /// Paste: the clipboard into the field, read on this press only; Pair opens it.
  Future<void> _pasteEnter() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
    if (!mounted || text.isEmpty) return;
    _enter.text = text;
    setState(() => _enterError = null);
  }

  /// Scan: the code the camera (or the dialog's paste) gave fills the field as Paste does.
  Future<void> _scanEnter() async {
    final r = await deskScanQr(context, title: context.l10n.scanQrTitle, hint: context.l10n.scanQrHint);
    final text = r?.scanText;
    if (!mounted || text == null || text.isEmpty) return;
    _enter.text = text;
    setState(() => _enterError = null);
  }

  bool get _ready => _enter.text.trim().isNotEmpty;

  Future<void> _go() async {
    if (_busy || !_ready) return;
    final l = context.l10n;
    final text = _enter.text;
    // A device link opens Link a device, not a pairing.
    if (isDeviceLinkText(text)) {
      _enter.clear();
      await showDeskLinkDevice(context, pasted: text);
      return;
    }
    setState(() {
      _busy = true;
      _enterError = null;
    });
    try {
      if (pairingLinkKind(text) == PairingLinkKind.reply) {
        final record = await deskPairingCall(ref, (api) => api.openReply(pairingLinkIn(text)!));
        _answered.add(record.id);
        if (record.id == _invite?.id) unawaited(_makeInvite());
        await _attachIfFramed(record.id);
        final confirm = await ref.read(deskPairingApiProvider).confirmLink(record.id);
        if (mounted) {
          setState(() {
            _confirmFor = record.id;
            _confirmLink = confirm;
          });
        }
      } else {
        await deskOpenPairingText(context, ref, text, contact: _contact, source: InviteSource.pasted);
      }
      _enter.clear();
    } catch (error) {
      if (mounted) setState(() => _enterError = deskErrorText(error, l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final contact = _contact;
    final net = ref.watch(deskPairNetProvider);
    final seenAs = ref.watch(deskSeenAsProvider);
    final invite = _invite;
    final all = ref.watch(deskPairingsProvider).value ?? const <PairingRecord>[];
    final followed = <PairingRecord>[
      for (final r in all)
        if (_answered.contains(r.id) || (contact != null && r.contactId == contact.id && (r.state.isPending || r.state == PairingState.waiting))) r,
    ];
    final inviteSide = EPanel(
      title: l.pairYourCode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: invite == null
                ? SizedBox.square(
                    dimension: 248.u,
                    child: Center(child: _inviteError != null ? Text(_inviteError!, style: ts.bodyDim, textAlign: TextAlign.center) : const ESpinner()),
                  )
                : Semantics(label: l.pairCodeLabel, image: true, child: EQr(deskPairingInviteText(invite, invitePage: ref.watch(invitePageProvider)), size: 248.u, epic1: true, label: l.pairCodeLabel, copyText: deskPairingInviteText(invite, invitePage: ref.watch(invitePageProvider)))),
          ),
          SizedBox(height: Sp.x3),
          Text(contact == null ? l.pairCodeCaption : l.pairCodeCaptionFor(contact.name), style: ts.bodyDim, textAlign: TextAlign.center),
          SizedBox(height: Sp.x3),
          Center(child: EButton.primary(key: deskPairCopyInviteKey, semanticsId: TrustIds.pairScreenCopy, label: l.pairCopyLink, icon: EIcons.copy, size: EBtnSize.sm, onPressed: invite == null ? null : _copyInvite)),
          SizedBox(height: Sp.x2),
          Text(l.pairStandingFootnote, style: ts.small, textAlign: TextAlign.center),
          if (net == DeskPairNet.epicboxOff) ...[SizedBox(height: Sp.x2), Text(l.pairEpicboxOffLine, style: ts.small, textAlign: TextAlign.center)],
          SizedBox(height: Sp.x3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text(seenAs.isEmpty ? l.pairSeenAsNone : l.pairSeenAsLine(seenAs), style: ts.small, overflow: TextOverflow.ellipsis)),
              SizedBox(width: Sp.x2),
              EButton.ghost(key: deskPairChangeNameKey, semanticsId: TrustIds.pairScreenChange, label: seenAs.isEmpty ? l.pairSeenAsAdd : l.pairChange, size: EBtnSize.inline, onPressed: _changeName),
            ],
          ),
          if (_confirmFor != null && _confirmLink != null) ...[
            SizedBox(height: Sp.x4),
            _ConfirmationBox(name: ref.watch(deskPairingNameProvider(_confirmFor!)), link: _confirmLink!, onCheck: () => showDeskCheckWords(context, ref, _confirmFor!)),
          ],
          for (final r in followed)
            if (r.id != _confirmFor) ...[
              SizedBox(height: Sp.x3),
              _DeskStatusLine(record: r, name: ref.watch(deskPairingNameProvider(r.id)), onCheck: r.sas.isEmpty ? null : () => showDeskCheckWords(context, ref, r.id)),
            ],
        ],
      ),
    );
    final enterSide = EPanel(
      title: contact == null ? l.pairHaveTheirCode : l.pairHaveNamesCode(contact.name),
      child: EField(
        label: l.pairPasteField,
        error: _enterError,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EInput(
              key: deskPairEnterKey,
              semanticsId: TrustIds.pairScreenEnter,
              controller: _enter,
              maxLines: 3,
              invalid: _enterError != null,
              onChanged: (_) => setState(() => _enterError = null),
              onSubmitted: (_) => _go(),
            ),
            SizedBox(height: Sp.x2),
            Wrap(
              spacing: Sp.x2,
              runSpacing: Sp.x2,
              alignment: WrapAlignment.end,
              children: [
                EButton.ghost(key: deskPairPasteKey, label: l.commonPaste, icon: EIcons.paste, onPressed: _pasteEnter),
                DeskScanButton(key: deskPairScanKey, onScan: _scanEnter, size: EBtnSize.sm),
                EButton.primary(key: deskPairGoKey, semanticsId: TrustIds.pairScreenGo, label: l.pairTitle, size: EBtnSize.sm, busy: _busy, onPressed: _ready ? _go : null),
              ],
            ),
            const DeskNoCameraLine(),
          ],
        ),
      ),
    );
    return EPage(
      title: contact == null ? l.pairTitle : l.pairWithName(contact.name),
      width: EPageWidth.full,
      onBack: () => ref.read(deskNavProvider.notifier).go(DeskRoute.contacts),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (net == DeskPairNet.offline) ...[ENotice(title: l.pairOfflineHint, tone: ETone.warn), SizedBox(height: Sp.x4)],
          LayoutBuilder(
            builder: (context, box) => box.maxWidth >= Lay.xl
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: inviteSide),
                      SizedBox(width: Sp.x4),
                      Expanded(child: enterSide),
                    ],
                  )
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [inviteSide, SizedBox(height: Sp.x4), enterSide]),
          ),
        ],
      ),
    );
  }
}

/// The status under the invite for one pairing in progress.
class _DeskStatusLine extends StatelessWidget {
  const _DeskStatusLine({required this.record, required this.name, this.onCheck});

  final PairingRecord record;
  final String name;
  final VoidCallback? onCheck;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
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
    return Semantics(
      key: deskPairStatusKey,
      liveRegion: true,
      child: Row(
        children: [
          if (done) Icon(EIcons.okCircle, size: Ctl.iconSm, color: context.dc.ok) else const ESpinner(),
          SizedBox(width: Sp.x3),
          Expanded(child: Text(text, style: ts.bodyDim)),
          if (onCheck != null && (r.state == PairingState.waiting || r.state == PairingState.paired || r.state == PairingState.keysChanged))
            EButton(key: deskPairCheckWordsKey, label: l.pairCheckWords, size: EBtnSize.sm, onPressed: onCheck),
        ],
      ),
    );
  }
}

/// The confirmation box: after an answer taken by hand, the confirmation to copy back the
/// same way, then the words.
class _ConfirmationBox extends StatelessWidget {
  const _ConfirmationBox({required this.name, required this.link, required this.onCheck});

  final String name;
  final String link;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    return Container(
      key: deskPairConfirmationKey,
      padding: EdgeInsets.all(Sp.x3),
      decoration: c.well,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.pairFinishCodeTitle, style: ts.strong),
          SizedBox(height: Sp.x1),
          Text(l.pairFinishCodeBody(name), style: ts.small),
          SizedBox(height: Sp.x2),
          SelectableText(l.pairFinishLinkMessage(link), style: ts.mono()),
          SizedBox(height: Sp.x2),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              EButton.primary(key: deskConfirmCopyKey, label: l.commonCopy, icon: EIcons.copy, size: EBtnSize.sm, onPressed: () => copyToClipboard(context, l.pairFinishLinkMessage(link), l.pairMessageCopied)),
              EButton(key: deskConfirmCheckKey, label: l.pairCheckWords, size: EBtnSize.sm, onPressed: onCheck),
            ],
          ),
        ],
      ),
    );
  }
}

/// Change "They see you as": one field, one name per wallet.
/// "The name shown when paired": the name, or null when cancelled.
Future<String?> showPairNameDialog(BuildContext context, String initial) =>
    showEDialog<String>(context, builder: (_) => _NameDialog(initial: initial));

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _text = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final l = context.l10n;
    final name = _text.text.trim();
    if (utf8.encode(name).length > 48) {
      setState(() => _error = l.pairSeenAsTooLong);
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Dlg-Pair-name: what the name is for, then the field.
    return EDialog(
      title: l.deskPairNameTitle,
      description: l.deskPairNameDesc,
      icon: EIcons.paired,
      body: EField(
        label: l.deskPairNameField,
        help: l.pairSeenAsHint,
        error: _error,
        child: EInput(key: deskPairNameKey, semanticsId: TrustIds.pairNameField, controller: _text, hint: l.pairSeenAsHint, autofocus: true, onChanged: (_) => setState(() => _error = null), onSubmitted: (_) => _save()),
      ),
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.pop(context)),
        EButton.primary(key: deskPairNameSaveKey, semanticsId: TrustIds.pairNameSave, label: l.commonSave, onPressed: _save),
      ],
    );
  }
}

/// Copies [text] and confirms with a toast.
Future<void> copyToClipboard(BuildContext context, String text, String toast) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showEToast(context, toast, tone: ETone.ok);
}

/// Opens [pasted]: an invite asks "Pair with Anna?"; an answer opens the confirmation to
/// copy, then the words; a confirmation opens the words (a request ends Verified with a
/// toast). Anything else is "Not a pairing invite". An answer or confirmation of a pairing
/// that finished already (the relay was faster) only says so. [source] is how the invite
/// came, for Pair with Anna?'s Source line.
Future<void> deskOpenPairingText(BuildContext context, WidgetRef ref, String pasted, {Contact? contact, InviteSource? source}) async {
  // A device link is Link a device's, not a pairing's; a page link carries the invite in its
  // fragment.
  final invite = parseInvite(pasted);
  if (invite?.kind == InviteKind.deviceLink || isDeviceLinkText(pasted)) return showDeskLinkDevice(context, pasted: invite?.invite ?? pasted);
  final bare = invite?.invite ?? pasted;
  final api = ref.read(deskPairingApiProvider);
  final l = context.l10n;
  final kind = pairingLinkKind(bare);
  if (kind == null || kind == PairingLinkKind.card) {
    showEToast(context, l.pairNotACode, tone: ETone.warn);
    return;
  }
  final text = pairingLinkIn(bare)!;
  var before = const <PairingRecord>[];
  try {
    before = await ref.read(deskPairingsProvider.future);
  } on Object {
    // No list: nothing counts as finished before.
  }
  final doneBefore = {
    for (final r in before)
      if (r.state.isRecord) r.id,
  };
  bool already(PairingRecord r) {
    if (!doneBefore.contains(r.id) || !context.mounted) return false;
    final name = ref.read(deskPairingNameProvider(r.id));
    showEToast(context, l.pairAlreadyPaired(name.isEmpty ? peerLabel(l, r) : name), tone: ETone.info);
    return true;
  }

  try {
    switch (kind) {
      case PairingLinkKind.invite:
        final preview = await api.openInvite(text);
        if (context.mounted) await showDeskIncoming(context, ref, preview, contact: contact, source: source);
      case PairingLinkKind.reply:
        final r = await deskPairingCall(ref, (a) => a.openReply(text));
        if (already(r)) return;
        if (contact != null && r.contactId != contact.id && context.mounted) await deskAttachPairingTo(context, ref, r, contact);
        final confirm = await api.confirmLink(r.id);
        if (!context.mounted) return;
        final checkNow = await showEDialog<bool>(context, dismissible: false, builder: (_) => DeskConfirmationDialog(pairingId: r.id, link: confirm));
        if (checkNow == true && context.mounted) await showDeskCheckWords(context, ref, r.id);
      case PairingLinkKind.confirm:
        final r = await deskPairingCall(ref, (a) => a.openConfirm(text));
        if (already(r)) return;
        // The answerer's wait for it is up: it moves on to the words by itself.
        if (deskPairingStepsOnScreen.contains(r.id)) return;
        if (!context.mounted) return;
        if (r.state == PairingState.verified) {
          showEToast(context, l.pairPairedWith(ref.read(deskPairingNameProvider(r.id))), tone: ETone.ok);
          return;
        }
        await showDeskCheckWords(context, ref, r.id);
      case PairingLinkKind.card:
        return;
    }
  } catch (error) {
    final failure = pairingFailureOf(error);
    if (failure == null || !context.mounted) rethrow;
    showEToast(context, pairingFailureText(l, failure), text: pairingFailureBody(l, failure), tone: ETone.warn);
  }
}

/// The confirmation to copy into the chat after an answer taken by hand, then the words.
/// Pops true for Check the words.
class DeskConfirmationDialog extends ConsumerWidget {
  const DeskConfirmationDialog({super.key, required this.pairingId, required this.link});

  final String pairingId;
  final String link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    final name = ref.watch(deskPairingNameProvider(pairingId));
    return EDialog(
      title: l.pairFinishCodeTitle,
      icon: EIcons.trusted,
      size: DialogWidth.wide,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.pairFinishCodeBody(name), style: ts.bodyDim),
          SizedBox(height: Sp.x3),
          Container(
            padding: EdgeInsets.all(Sp.x3),
            decoration: c.well,
            child: SelectableText(l.pairFinishLinkMessage(link), style: ts.mono()),
          ),
        ],
      ),
      actions: [
        EButton(key: deskConfirmCheckKey, label: l.pairCheckWords, onPressed: () => Navigator.pop(context, true)),
        EButton.primary(key: deskConfirmCopyKey, label: l.commonCopy, icon: EIcons.copy, autofocus: true, onPressed: () => copyToClipboard(context, l.pairFinishLinkMessage(link), l.pairMessageCopied)),
      ],
    );
  }
}

/// "Pair with Anna?" as a dialog, in two forms (from a contact, by invite). Pair answers and
/// opens the wait for the confirmation. Below the inviter, what the invite itself says: the
/// server it came by, how it came ([source]; a request is always by Epicbox) and how long it
/// stays open.
///
/// One window from the code to the result: the same dialog goes on to the wait, the domain
/// check and the words or the Verified result ([_PairFlowDialog]).
Future<void> showDeskIncoming(BuildContext context, WidgetRef ref, PairingInvitePreview p, {Contact? contact, InviteSource? source}) =>
    showEDialog<void>(context, dismissible: false, builder: (_) => _PairFlowDialog.incoming(preview: p, contact: contact, source: source));

class _IncomingDialog extends ConsumerStatefulWidget {
  const _IncomingDialog({required this.preview, this.contact, this.source});

  final PairingInvitePreview preview;
  final Contact? contact;
  final InviteSource? source;

  @override
  ConsumerState<_IncomingDialog> createState() => _IncomingDialogState();
}

class _IncomingDialogState extends ConsumerState<_IncomingDialog> {
  bool _busy = false;
  String? _error;

  Contact? _sender() {
    final from = widget.preview.fromAddress;
    if (from == null) return widget.contact;
    final contacts = ref.read(deskProvider).contacts ?? const <Contact>[];
    final key = epicboxKey(from);
    return contacts.where((c) => c.epicbox != null && epicboxKey(c.epicbox!) == key).firstOrNull ?? widget.contact;
  }

  Future<void> _pair() async {
    final l = context.l10n;
    var name = ref.read(deskSeenAsProvider).trim();
    if (name.isEmpty) name = unnamedPeerName;
    setState(() => _busy = true);
    try {
      final r = await deskPairingCall(
        ref,
        (api) => api.acceptInvite(token: widget.preview.token, name: name, contactId: _sender()?.id, byHand: ref.read(deskPairNetProvider) != DeskPairNet.online),
      );
      if (mounted) _PairFlowScope.of(context).flow.answered(r);
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
    final sender = p.isRequest ? _sender() : null;
    // As on the phone sheet: the key picture when the invite has a key, and a key on the
    // BT Labs list shows its listed name.
    final key = p.inviteKey;
    final btlabs = sender == null && key != null ? btLabsKeyOf(key) : null;
    final name = sender?.name ?? btlabs?.name ?? p.name;
    final noName = sender == null && btlabs == null && isUnnamed(p.name);
    final shown = noName ? l.commonUnknown : name;
    final server = relayHostOf(p.homeRelay);
    final source = inviteSourceText(l, widget.source, request: p.isRequest);
    return EDialog(
      title: l.pairIncomingTitle(noName ? l.commonUnknown : name),
      titleTrailing: btlabs != null ? VerifiedCheck(label: l.pairVerifiedService, colour: context.dc.ok, size: 18.u) : null,
      // Wide, as its 520 u width rendered (it snapped up).
      size: DialogWidth.wide,
      minBodyHeight: _PairFlowScope.of(context).minBody,
      minFootHeight: _PairFlowScope.of(context).minFoot,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (key != null)
                KeyPictureView(picture: KeyPicture.of(key), size: 56.u, framed: true)
              else
                DeskPairAvatar(name: noName ? l.pairUnnamed : name, size: 56.u),
              // 24 u, less the bracket offset on a key picture.
              SizedBox(width: key != null ? Sp.x6 - KeyPictureView.frameOffsetOf(56.u) + 1 : Sp.x6),
              if (sender != null) EBadge(l.pairInContacts, icon: EIcons.user, tone: ETone.ok),
            ],
          ),
          if (p.fromAddress case final from?) ...[SizedBox(height: Sp.x3), Text(from, style: ts.mono())],
          SizedBox(height: Sp.x4),
          Text(p.isRequest ? l.pairIncomingBodyRequest(shown) : l.pairIncomingBody(shown), style: ts.bodyDim),
          SizedBox(height: Sp.x3),
          EFacts([
            if (server.isNotEmpty) (l.pairIncomingServer, Text(server, key: deskIncomingServerKey, style: ts.mono())),
            if (source != null) (l.pairIncomingSource, Text(source, key: deskIncomingSourceKey)),
            (l.pairExpiresIn, PairTimeLeft(key: deskIncomingExpiresKey, until: p.expiresAt, style: ts.body)),
          ]),
          if (_error != null) ...[SizedBox(height: Sp.x3), ENotice(title: _error!, tone: ETone.warn)],
        ],
      ),
      actions: [
        EButton(key: deskIncomingNotNowKey, label: l.pairNotNow, onPressed: _busy ? null : () => Navigator.pop(context)),
        EButton.primary(key: deskIncomingPairKey, semanticsId: TrustIds.pairIncomingPair, label: l.pairTitle, busy: _busy, onPressed: _pair),
      ],
    );
  }
}

/// The wait for the inviter's confirmation: "Pairing with Anna…", Cancel; after
/// [pairReplyFallbackAfter] (at once with Epicbox off, Offline, or the relay not taking the
/// answer) the Your answer box with Copy and a field for the confirmation that comes back.
class DeskPairWaitingDialog extends ConsumerStatefulWidget {
  const DeskPairWaitingDialog({super.key, required this.pairingId, this.name = ''});

  final String pairingId;
  final String name;

  @override
  ConsumerState<DeskPairWaitingDialog> createState() => _DeskPairWaitingDialogState();
}

class _DeskPairWaitingDialogState extends ConsumerState<DeskPairWaitingDialog> {
  void Function()? _unboost;
  Timer? _slow;
  bool _late = false;
  bool _done = false;

  /// The records were read again after this dialog opened (see the phone's wait).
  bool _fresh = false;
  String? _link;
  final _finish = TextEditingController();
  StreamSubscription<PairingEvent>? _events;
  bool _onScreen(PairingEvent e) => e.pairingId == widget.pairingId;

  /// The flow window this wait is a step of; null for a wait shown on its own.
  _PairFlowState? _flow;

  @override
  void initState() {
    super.initState();
    _flow = _PairFlowScope.maybeOf(context)?.flow;
    pairingWordsOnScreen.add(_onScreen);
    // A flow window holds the pairing's marks for all its steps.
    if (_flow == null) deskPairingStepsOnScreen.add(widget.pairingId);
    final api = ref.read(deskPairingApiProvider);
    if (ref.read(deskPairNetProvider) == DeskPairNet.online) {
      _unboost = boostRelays(ref.read(deskApiProvider).boosts, const Duration(seconds: 10));
      _slow = Timer(pairReplyFallbackAfter, () => mounted ? setState(() => _late = true) : null);
    } else {
      _late = true;
    }
    _events = api.events().listen((e) {
      if (e.pairingId != widget.pairingId || !mounted || _done) return;
      if (e.kind == PairingEventKind.confirmed) unawaited(_finished());
      if (e.kind == PairingEventKind.failed && e.failure != null) {
        _done = true;
        Navigator.pop(context);
        unawaited(showDeskOutcome(context, e.failure!, name: e.name));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(deskPairingsProvider.notifier).reload().then((_) => mounted ? setState(() => _fresh = true) : null).ignore();
      try {
        final link = await api.replyLink(widget.pairingId);
        if (mounted) setState(() => _link = link);
      } catch (_) {
        // Gone already.
      }
    });
  }

  @override
  void dispose() {
    if (_flow == null) deskPairingStepsOnScreen.remove(widget.pairingId);
    pairingWordsOnScreen.remove(_onScreen);
    _unboost?.call();
    _slow?.cancel();
    _events?.cancel();
    _finish.dispose();
    super.dispose();
  }

  String get _name {
    final known = ref.read(deskPairingNameProvider(widget.pairingId));
    return known.isEmpty ? widget.name : known;
  }

  /// The confirm is in. The provider's records are read again by a pairing event, so they may
  /// still be the old ones here: the wallet is asked for this pairing, and the words open
  /// whenever it cannot be seen Verified.
  Future<void> _finished() async {
    _done = true;
    final host = Navigator.of(context).context;
    final api = ref.read(deskPairingApiProvider);
    final l = context.l10n;
    final name = _name;
    PairingRecord? record;
    try {
      record = await api.pairing(widget.pairingId);
    } on Object {
      // Not read: the words are the safe way on.
    }
    if (!mounted) return;
    final flow = _flow;
    if (flow != null) {
      flow.confirmed(record);
      return;
    }
    Navigator.pop(context);
    if (record != null && record.state == PairingState.verified) {
      if (host.mounted) showEToast(host, l.pairPairedWith(name), tone: ETone.ok);
      return;
    }
    if (host.mounted) unawaited(showDeskCheckWords(host, ref, widget.pairingId));
  }

  Future<void> _cancel() async {
    if (!await deskConfirmCancelPairing(context, _name) || !mounted) return;
    _done = true;
    await deskPairingCall(ref, (api) => api.cancelInvite(widget.pairingId));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pasteFinish() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
    if (!mounted || text.isEmpty) return;
    _finish.text = text;
    await _openFinish();
  }

  Future<void> _scanFinish() async {
    final r = await deskScanQr(context, title: context.l10n.scanQrTitle, hint: context.l10n.scanQrHint);
    final text = r?.scanText;
    if (!mounted || text == null || text.isEmpty) return;
    _finish.text = text;
    await _openFinish();
  }

  Future<void> _openFinish() async {
    final l = context.l10n;
    final text = _finish.text;
    if (pairingLinkKind(text) != PairingLinkKind.confirm) {
      showEToast(context, l.pairNotACode, tone: ETone.warn);
      return;
    }
    try {
      final r = await deskPairingCall(ref, (api) => api.openConfirm(pairingLinkIn(text)!));
      // The confirm's own event moved this dialog on already.
      if (!mounted || _done) return;
      if (r.id == widget.pairingId) {
        _finished();
      } else {
        showEToast(context, l.pairPairedWith(ref.read(deskPairingNameProvider(r.id))), tone: ETone.ok);
      }
    } catch (error) {
      if (mounted) showEToast(context, deskErrorText(error, l), tone: ETone.warn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    final record = ref.watch(deskPairingByIdProvider(widget.pairingId));
    final loaded = ref.watch(deskPairingsProvider).hasValue;
    if (loaded && _fresh && !_done && (record == null || record.state != PairingState.pendingReply)) {
      _done = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (record != null && record.state.isRecord) {
          _done = false;
          _finished();
        } else {
          Navigator.pop(context);
        }
      });
    }
    final name = _name;
    final byHand = _late || (record?.relayDown ?? false);
    final link = _link;
    return EDialog(
      title: l.pairPairingWith(name),
      icon: EIcons.trusted,
      size: DialogWidth.wide,
      minBodyHeight: _flow?.minBody,
      minFootHeight: _flow?.minFoot,
      // In the flow window the key strip stays, so the footer keeps its place: Esc is Close.
      dismissible: _flow != null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [const ESpinner(), SizedBox(width: Sp.x3), Expanded(child: Semantics(liveRegion: true, child: Text(l.pairWaitingBody, style: ts.bodyDim)))]),
          if (byHand) ...[
            SizedBox(height: Sp.x4),
            Container(
              key: deskWaitingAnswerKey,
              padding: EdgeInsets.all(Sp.x3),
              decoration: c.well,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.pairByHandYourAnswer, style: ts.strong),
                  SizedBox(height: Sp.x1),
                  Text(l.pairYourAnswerBody, style: ts.small),
                  if (link != null) ...[
                    SizedBox(height: Sp.x2),
                    SelectableText(l.pairReplyMessage(link), style: ts.mono()),
                    SizedBox(height: Sp.x2),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: EButton.primary(key: deskWaitingCopyKey, label: l.commonCopy, icon: EIcons.copy, size: EBtnSize.sm, onPressed: () => copyToClipboard(context, l.pairReplyMessage(link), l.pairMessageCopied)),
                    ),
                  ],
                  SizedBox(height: Sp.x3),
                  EField(
                    label: l.pairPasteFinishField,
                    child: Row(
                      children: [
                        Expanded(child: EInput(key: deskWaitingFinishKey, controller: _finish, onSubmitted: (_) => _openFinish())),
                        SizedBox(width: Sp.x2),
                        EButton.ghost(label: l.commonPaste, icon: EIcons.paste, onPressed: _pasteFinish),
                        SizedBox(width: Sp.x2),
                        DeskScanButton(key: deskWaitingScanKey, onScan: _scanFinish, size: EBtnSize.sm),
                        SizedBox(width: Sp.x2),
                        EButton(key: deskWaitingFinishGoKey, label: l.pairTitle, size: EBtnSize.sm, onPressed: _openFinish),
                      ],
                    ),
                  ),
                  const DeskNoCameraLine(),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        EButton(key: deskWaitingCloseKey, semanticsId: TrustIds.pairWaitingClose, label: l.commonClose, onPressed: () => Navigator.pop(context)),
        EButton(key: deskWaitingCancelKey, label: l.commonCancel, kind: EBtnKind.danger, onPressed: _cancel),
      ],
    );
  }
}

/// Asks before cancelling the pairing with [name]; true to cancel.
Future<bool> deskConfirmCancelPairing(BuildContext context, String name) async {
  final l = context.l10n;
  final sure = await showEDialog<bool>(
    context,
    builder: (ctx) => EDialog(
      title: l.pairCancelPairingTitle,
      description: l.pairCancelPairingBody(name),
      tone: ETone.warn,
      icon: EIcons.alert,
      actions: [
        EButton(label: l.contactKeep, onPressed: () => Navigator.pop(ctx, false)),
        EButton(label: l.pairCancelPairing, kind: EBtnKind.danger, onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
  return sure ?? false;
}

/// Pair on the contact pane: the request dialog when a request can go (a fresh proven peer,
/// Epicbox on), else the Pair page framed for [contact].
Future<void> showDeskPairWithContact(BuildContext context, WidgetRef ref, Contact contact) async {
  final l = context.l10n;
  final address = contact.epicbox;
  var sendable = address != null && address.trim().isNotEmpty && ref.read(deskPairNetProvider) == DeskPairNet.online;
  if (sendable) {
    final compat = await ref.read(deskPeerCompatProvider(address).future);
    sendable = mayOfferPair(compat, ref.read(deskContactRelationshipProvider(contact.id)), DateTime.now());
  }
  if (!context.mounted) return;
  final nav = ref.read(deskNavProvider.notifier);
  if (!sendable) return nav.go(DeskRoute.pair, contact);
  final send = await showEDialog<bool>(
    context,
    builder: (ctx) => EDialog(
      title: l.pairWithName(contact.name),
      description: l.pairRequestBody,
      icon: EIcons.trusted,
      actions: [
        EButton(key: deskWay1ShowInviteKey, label: l.pairShowMyCodeInstead, onPressed: () => Navigator.pop(ctx, false)),
        EButton.primary(key: deskWay1SendKey, semanticsId: TrustIds.pairRequestSend, label: l.pairSendRequest, autofocus: true, onPressed: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
  if (send == null || !context.mounted) return;
  if (!send) return nav.go(DeskRoute.pair, contact);
  var name = ref.read(deskSeenAsProvider).trim();
  if (name.isEmpty) name = unnamedPeerName;
  try {
    await deskPairingCall(ref, (api) => api.requestPairing(toAddress: address!, name: name, contactId: contact.id));
    if (context.mounted) showEToast(context, l.pairRequestSent(localDayMonth(l, DateTime.now())), tone: ETone.ok);
  } catch (error) {
    if (!context.mounted) return;
    final failure = pairingFailureOf(error);
    if (failure == PairingFailure.peerNotProven || failure == PairingFailure.relayUnreachable) return nav.go(DeskRoute.pair, contact);
    showEToast(context, deskErrorText(error, l), tone: ETone.warn);
  }
}

/// Pair requests: those from contacts, newest first, each with Pair · Not now.
Future<void> showDeskPairRequests(BuildContext context, WidgetRef ref) =>
    showEDialog<void>(context, builder: (_) => const _RequestsDialog());

class _RequestsDialog extends ConsumerWidget {
  const _RequestsDialog();

  Future<void> _pair(BuildContext context, WidgetRef ref, PairRequest r, Contact? contact) async {
    final l = context.l10n;
    final host = Navigator.of(context).context;
    try {
      final preview = await ref.read(deskPairingApiProvider).openRequest(r.id);
      if (!context.mounted) return;
      Navigator.pop(context);
      if (host.mounted) await showDeskIncoming(host, ref, preview, contact: contact);
    } catch (error) {
      if (context.mounted) showEToast(context, deskErrorText(error, l), tone: ETone.warn);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ts = context.ts;
    final c = context.dc;
    final requests = ref.watch(deskPairRequestsProvider).value ?? const <PairRequest>[];
    final contacts = ref.watch(deskProvider.select((s) => s.contacts)) ?? const <Contact>[];
    if (requests.isEmpty && ref.watch(deskPairRequestsProvider).hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? false)) Navigator.pop(context);
      });
    }
    return EDialog(
      title: l.pairRequestsTitle,
      icon: EIcons.userPlus,
      size: DialogWidth.wide,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, r) in requests.indexed) ...[
            if (i > 0) Divider(height: Sp.x4, color: c.line),
            Builder(
              builder: (context) {
                final contact = deskContactOfRequest(contacts, r);
                final name = contact?.name ?? r.claimedName;
                return Row(
                  children: [
                    DeskPairAvatar(name: name, size: 40.u),
                    SizedBox(width: Sp.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Text(l.pairWantsToPair(name), style: ts.strong), Text(r.fromAddress, style: ts.mono(), maxLines: 1, overflow: TextOverflow.ellipsis)],
                      ),
                    ),
                    SizedBox(width: Sp.x2),
                    EButton(key: deskRequestsNotNowKey, label: l.pairNotNow, size: EBtnSize.sm, onPressed: () => deskPairingCall(ref, (api) => api.dismissRequest(r.id))),
                    SizedBox(width: Sp.x2),
                    EButton.primary(key: deskRequestsPairKey, semanticsId: TrustIds.pairRequestsPair, label: l.pairRequestPair, size: EBtnSize.sm, onPressed: () => _pair(context, ref, r, contact)),
                  ],
                );
              },
            ),
          ],
        ],
      ),
      actions: [EButton(label: l.commonClose, onPressed: () => Navigator.pop(context))],
    );
  }
}

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
        EButton(label: l.contactKeep, onPressed: () => Navigator.pop(ctx, false)),
        EButton(key: deskConfirmRemovePairingKey, semanticsId: TrustIds.pairContactRemoveok, label: l.contactRemove, kind: EBtnKind.danger, onPressed: () => Navigator.pop(ctx, true)),
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
  if (asNew) return _deskSaveAsNewContact(context, ref, r);
  // Not Send's picker: the pairing joins the contact.
  final picked = await showContactPicker(context, description: context.l10n.deskConPickForPairing);
  if (picked == null || !context.mounted) return false;
  return deskAttachPairingTo(context, ref, r, picked);
}

/// Save as a new contact: the form (the name it claims and its proven address shown), then
/// the pairing joins the contact it made. The proven address is written into the contact at
/// Verified only ([deskWriteProvenAddress]): now when the words were checked, else when they are.
Future<bool> _deskSaveAsNewContact(BuildContext context, WidgetRef ref, PairingRecord r) async {
  final l = context.l10n;
  // The form owns its field: it is disposed with the dialog, after the close animation.
  final form = await showEDialog<(String, ContactLabel)>(context, builder: (_) => _SaveContactDialog(record: r, defaultName: l.pairDefaultLabel((ref.read(deskProvider).contacts?.length ?? 0) + 1)));
  if (form == null || form.$1.isEmpty || !context.mounted) return false;
  final saved = form.$1;
  final contactId = await ref.read(deskProvider.notifier).saveContact(Contact(id: '', name: saved, label: form.$2));
  final attached = await deskPairingCall(ref, (api) => api.attach(r.id, contactId));
  await deskWriteProvenAddress(ref, attached);
  if (context.mounted) showEToast(context, l.pairSavedAs(saved), tone: ETone.ok);
  return true;
}

/// Attaches the pairing [r] to [contact], the user's pick. Refused because the contact has an
/// Epicbox address the pairing proves another key for, or proves none (a pairing made before
/// 26.10.25 never does): the dialog says so and offers Save as a new contact; pairing again
/// brings the proof. True once the pairing is in a contact.
Future<bool> deskAttachPairingTo(BuildContext context, WidgetRef ref, PairingRecord r, Contact contact) async {
  final l = context.l10n;
  try {
    final attached = await deskPairingCall(ref, (api) => api.attach(r.id, contact.id, contactAddress: contact.epicbox));
    await deskWriteProvenAddress(ref, attached);
  } on WalletError catch (error) {
    final failure = pairingFailureOf(error);
    if ((failure != PairingFailure.otherAddress && failure != PairingFailure.addressProofMissing) || !context.mounted) rethrow;
    final asNew = await showEDialog<bool>(
      context,
      builder: (ctx) => EDialog(
        title: l.pairOtherAddressTitle(contact.name),
        description: l.pairOtherAddressBody(contact.name),
        tone: ETone.warn,
        icon: EIcons.alert,
        actions: [
          EButton(label: l.commonCancel, onPressed: () => Navigator.pop(ctx, false)),
          EButton.primary(key: deskOtherAddressNewKey, semanticsId: TrustIds.pairSavedNew, label: l.pairSaveNewContact, onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (asNew != true || !context.mounted) return false;
    return _deskSaveAsNewContact(context, ref, r);
  }
  if (context.mounted) showEToast(context, l.pairSavedAs(contact.name), tone: ETone.ok);
  return true;
}

/// Save as a new contact in [deskAttachPairingTo]'s refusal, for tests.
const Key deskOtherAddressNewKey = ValueKey('desk-other-address-new');

/// Save as a new contact: the name it claims, to check, and its proven address.
class _SaveContactDialog extends StatefulWidget {
  const _SaveContactDialog({required this.record, required this.defaultName});

  final PairingRecord record;

  /// The name offered when the pairing claims none.
  final String defaultName;

  @override
  State<_SaveContactDialog> createState() => _SaveContactDialogState();
}

class _SaveContactDialogState extends State<_SaveContactDialog> {
  late final _text = TextEditingController(text: isUnnamed(widget.record.name) ? widget.defaultName : widget.record.shownName);
  var _label = ContactLabel.wallet;

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
      title: l.pairSaveContactTitle(peerLabel(l, r)),
      icon: EIcons.userPlus,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          EField(label: l.deskConFieldName, child: EInput(key: deskSaveContactNameKey, controller: _text, autofocus: true)),
          if (r.paymentsAddress case final a?) ...[
            SizedBox(height: Sp.x3),
            EField(label: l.deskConFieldAddress, child: Text(a, style: context.ts.mono())),
          ],
          SizedBox(height: Sp.x3),
          EField(label: l.deskConLabelTitle, child: ContactLabelField(value: _label, onChanged: (v) => setState(() => _label = v))),
        ],
      ),
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.pop(context)),
        EButton.primary(semanticsId: TrustIds.pairSavedSave, label: l.deskConSave, onPressed: () => Navigator.pop(context, (_text.text.trim(), _label))),
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
  return sameNamedContact<Contact>(r, contacts, (c) => c.name, paired: (c) => all.any((p) => p.id != r.id && p.contactId == c.id && p.state.isPaired), epicboxOf: (c) => c.epicbox);
}

/// Attaches the pairing [r] to [contact], the user's one-tap choice of [deskSuggestedContact].
Future<void> deskAttachPairing(BuildContext context, WidgetRef ref, PairingRecord r, Contact contact) async {
  final l = context.l10n;
  try {
    await deskAttachPairingTo(context, ref, r, contact);
  } catch (error) {
    if (context.mounted) showEToast(context, deskErrorText(error, l), tone: ETone.risk);
  }
}

/// The name field of the Save as a new contact form, for tests.
const Key deskSaveContactNameKey = ValueKey('desk-save-contact-name');

/// The check of a pairing: the words, or first the contact's domain when it can prove the
/// wallet ([PairingRecord.domainProvable]), in one window ([_PairFlowDialog]).
Future<void> showDeskCheckWords(BuildContext context, WidgetRef ref, String pairingId, {bool recheck = false}) async {
  // One words check per pairing: an answer's event and the paste that took it both ask.
  if (!_checksOpen.add(pairingId)) return;
  try {
    var record = ref.read(deskPairingByIdProvider(pairingId));
    if (record == null) {
      // The records are still being read: the window must know whether the domain goes first.
      try {
        await ref.read(deskPairingsProvider.future);
      } on Object {
        // The words are the safe way on.
      }
      record = ref.read(deskPairingByIdProvider(pairingId));
    }
    if (!context.mounted) return;
    final proof = !recheck && (record?.domainProvable ?? false);
    await showEDialog<void>(context, builder: (_) => _PairFlowDialog.check(pairingId: pairingId, recheck: recheck, proof: proof));
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
    showEDialog<void>(context, builder: (_) => _PairFlowDialog.check(pairingId: pairingId, recheck: false, proof: false));

/// Check the words: They match (Verified), They do not match (ended on both sides). Close is
/// later: the row stays Paired. No Skip.
class _CheckDialog extends ConsumerStatefulWidget {
  const _CheckDialog({required this.pairingId});

  final String pairingId;

  @override
  ConsumerState<_CheckDialog> createState() => _CheckDialogState();
}

class _CheckDialogState extends ConsumerState<_CheckDialog> {
  bool _busy = false;

  /// The name service's wait as the service first answered; null while asking.
  HelloStep? _began;
  NameService? _nameService;
  bool _onScreen(PairingEvent e) => e.pairingId == widget.pairingId;

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
    // A pairing whose peer claims the name service feature listens for its hello under the words.
    WidgetsBinding.instance.addPostFrameCallback((_) => _beginNameService());
  }

  Future<void> _beginNameService() async {
    final service = ref.read(deskNameServiceProvider);
    if (service == null) return;
    // The wallet's own view: the provider's records may be older than the confirm.
    PairingRecord? record;
    try {
      record = await ref.read(deskPairingApiProvider).pairing(widget.pairingId);
    } on Object {
      return;
    }
    if (!mounted) return;
    if (record == null || record.peerFeatures & featureNameService == 0) return;
    _nameService = service;
    final step = await service.beginHello(widget.pairingId);
    if (mounted) setState(() => _began = step);
  }

  /// Where the name service step stands, null for the ordinary words step.
  HelloStep? get _step => _nameService == null ? null : ref.read(deskNameServices.view)?.steps[widget.pairingId] ?? _began;

  @override
  void dispose() {
    pairingWordsOnScreen.remove(_onScreen);
    // Leaving the dialog stops the wait; the words step is what Back leaves the pairing at.
    _nameService?.cancelHello(widget.pairingId);
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
            EButton(label: l.pairBack, onPressed: () => Navigator.pop(ctx, false)),
            EButton(label: l.sasNoMatch, kind: EBtnKind.danger, onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      );
      if (stop != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final nameService = _nameService != null && _step == HelloStep.check ? _nameService : null;
      final r = await deskPairingCall(ref, (api) => api.checkWords(widget.pairingId, check));
      // The plain words were answered before any hello came: the listening is over.
      if (nameService == null) _nameService?.cancelHello(widget.pairingId);
      if (nameService != null) {
        // The code was compared: the serviceKey is this contact's, or the name service is forgotten.
        if (check == PairingCheck.match && r != null) {
          await nameService.pin(widget.pairingId);
        } else {
          await nameService.dismiss(widget.pairingId);
        }
      }
      if (r != null && check == PairingCheck.match) await deskWriteProvenAddress(ref, r);
      if (!mounted) return;
      final flow = _PairFlowScope.of(context).flow;
      if (check == PairingCheck.mismatch) {
        final host = Navigator.of(context).context;
        Navigator.pop(context);
        if (host.mounted) showEToast(host, l.pairEndedNotice, tone: ETone.warn);
        return;
      }
      final entry = nameService?.book.byPairing(widget.pairingId);
      if (entry != null && entry.pinned) {
        // The Join dialog, over this window; Not now leaves a verified name service with Join on its page.
        await showDeskNameServiceJoin(context, ref, serviceKey: entry.serviceKey, label: name);
        if (!mounted) return;
      }
      // The window goes on to the result in place: the save offer, the Allow row or the toast.
      await flow.showResult(r, name: name);
    } catch (error) {
      if (mounted) showEToast(context, deskErrorText(error, l), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = ref.watch(deskPairingByIdProvider(widget.pairingId));
    final name = ref.watch(deskPairingNameProvider(widget.pairingId));
    if (r == null) return EDialog(title: l.sasTitle, icon: EIcons.trusted);
    final flow = _PairFlowScope.of(context);
    Widget? code;
    if (_nameService != null) {
      final view = ref.watch(deskNameServices.view);
      final step = view?.steps[widget.pairingId] ?? _began;
      final serviceKey = view?.book.byPairing(r.id)?.serviceKey;
      // A hello arrived: the same window turns into the service's code check. Without one
      // (a plain wallet never sends it) the words are all there is.
      if (step == HelloStep.check && serviceKey != null) {
        code = DeskNameServiceCodeCheck(
          key: const ValueKey('code'),
          label: name,
          serviceKey: serviceKey,
          noPayments: ref.watch(paymentRefusalsProvider).refusesPayments(pairingId: r.id),
          busy: _busy,
          minBodyHeight: flow.minBody,
          minFootHeight: flow.minFoot,
          onLater: () => Navigator.pop(context),
          onMatch: () => _answer(PairingCheck.match),
          onNoMatch: () => _answer(PairingCheck.mismatch),
          matchKey: deskCheckMatchKey,
          noMatchKey: deskCheckNoMatchKey,
          laterKey: deskCheckLaterKey,
        );
      }
    }
    final still = MediaQuery.disableAnimationsOf(context);
    final current = code == null ? const ValueKey('words') : const ValueKey('code');
    return AnimatedSwitcher(
      duration: still ? Duration.zero : Motion.cross,
      switchInCurve: Motion.easeOut,
      transitionBuilder: (child, animation) => child.key == current ? FadeTransition(opacity: animation, child: child) : IgnorePointer(child: child),
      child: code ?? _words(context, r, name),
    );
  }

  Widget _words(BuildContext context, PairingRecord r, String name) {
    final l = context.l10n;
    final ts = context.ts;
    final lead = statedAutomated(r.peerProfile) ? l.sasLeadExchange(name) : l.sasLead(name);
    return EDialog(
      key: const ValueKey('words'),
      title: l.sasDialogTitle(name),
      icon: EIcons.trusted,
      // Wide, as its 520 u width rendered (it snapped up).
      size: DialogWidth.wide,
      minBodyHeight: _PairFlowScope.of(context).minBody,
      minFootHeight: _PairFlowScope.of(context).minFoot,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [DeskPairAvatar(name: name, size: 48.u)]),
          SizedBox(height: Sp.x3),
          Text(lead, style: ts.bodyDim),
          SizedBox(height: Sp.x4),
          WordTiles(words: r.sas, label: l.sasWordsLabel, size: WordTileSize.check),
          if (r.domainChecking && (r.peerDomain ?? '').isNotEmpty) ...[
            SizedBox(height: Sp.x3),
            // The contact's domain is being asked: a calm line, the words stay usable.
            Row(
              key: deskDomainCheckingKey,
              children: [
                ESpinner(size: 12.u),
                SizedBox(width: Sp.x2),
                Expanded(child: Semantics(liveRegion: true, child: Text(l.deskPairDomainChecking(r.peerDomain!), style: ts.caption.copyWith(color: context.dc.dim)))),
              ],
            ),
          ],
        ],
      ),
      actions: [
        EButton(key: deskCheckLaterKey, label: l.pairBack, onPressed: _busy ? null : () => Navigator.pop(context)),
        EButton(key: deskCheckNoMatchKey, label: l.sasNoMatch, onPressed: _busy ? null : () => _answer(PairingCheck.mismatch)),
        EButton.primary(key: deskCheckMatchKey, semanticsId: TrustIds.pairCheckMatch, label: l.sasMatch, busy: _busy, onPressed: () => _answer(PairingCheck.match)),
      ],
    );
  }
}

/// After the words check of a pairing that is in no contact yet: Verified and where it goes,
/// Add to contacts (a new contact or one there), or Not now.
class DeskPairedSaveDialog extends ConsumerWidget {
  const DeskPairedSaveDialog({super.key, required this.pairingId, required this.verified, this.domain});

  final String pairingId;
  final bool verified;

  /// The domain that proved the wallet, when it did and no words were compared.
  final String? domain;

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
    final suggested = r == null ? null : deskSuggestedContact(ref, r);
    final noPayments = ref.watch(paymentRefusalsProvider).refusesPayments(pairingId: pairingId);
    final inFlow = _PairFlowScope.maybeOf(context);
    return EDialog(
      title: verified ? l.sasMatchedTitle(name) : l.sasSkippedTitle(name),
      tone: verified ? ETone.ok : ETone.warn,
      icon: verified ? EIcons.trusted : EIcons.shield,
      // Room for the choices on one line in every language; the flow window keeps its width.
      size: suggested == null && inFlow == null ? DialogWidth.standard : DialogWidth.wide,
      minBodyHeight: inFlow?.minBody,
      minFootHeight: inFlow?.minFoot,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (domain case final d? when verified)
            Text(l.deskPairDomainVerifiedBody(name, d), style: ts.bodyDim)
          else if (!verified || !noPayments)
            Text(verified ? l.sasMatchedBody(name) : l.sasSkippedBody(name), style: ts.bodyDim),
          if (verified && !noPayments) ...[
            SizedBox(height: Sp.x3),
            DeskAllowGroup(pairingId: pairingId),
          ],
          if (noPayments) ...[
            SizedBox(height: Sp.x3),
            Align(alignment: AlignmentDirectional.centerStart, child: const NoPaymentsBadge()),
          ],
          if (r != null && statedAutomated(r.peerProfile)) ...[
            SizedBox(height: Sp.x3),
            Text(l.pairIsService, style: ts.bodyDim),
          ],
          SizedBox(height: Sp.x4),
          Text(l.pairSaveContactTitle(name), style: ts.label),
        ],
      ),
      actions: [
        // With a contact to offer, the × is Not now: the choices keep one line. Add to contacts
        // is keyed: saving a new contact brings the offer, and its save must run on.
        if (suggested == null) EButton(key: deskSavedNotNowKey, label: l.pairNotNow, onPressed: () => Navigator.pop(context)),
        if (r != null) DeskAddToContactsButton(key: deskSavedAddKey, record: r, primary: suggested == null, size: EBtnSize.md, onSaved: () => Navigator.pop(context)),
        if (suggested != null) ...[
          EButton.primary(
            key: deskSavedAddToNamedKey,
            label: l.pairAddToNamed(suggested.name),
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

/// The seal and Allow invoices rows of a verified pairing, each writing its own change: the
/// result after the words match, in [DeskMatchedResult] and in [DeskPairedSaveDialog].
class DeskAllowGroup extends ConsumerStatefulWidget {
  const DeskAllowGroup({super.key, required this.pairingId});

  final String pairingId;

  @override
  ConsumerState<DeskAllowGroup> createState() => _DeskAllowGroupState();
}

class _DeskAllowGroupState extends ConsumerState<DeskAllowGroup> {
  DeskBusyRow? _busy;

  Future<void> _run(DeskBusyRow row, Future<Object?> Function(PairingApi api) call) async {
    if (_busy != null) return;
    setState(() => _busy = row);
    try {
      await deskPairingCall(ref, call);
    } catch (error) {
      if (mounted) showEToast(context, deskErrorText(error, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = ref.watch(deskPairingByIdProvider(widget.pairingId));
    if (r == null) return const SizedBox.shrink();
    final name = ref.watch(deskPairingNameProvider(widget.pairingId));
    return DeskMatchedGroup(
      name: name,
      seal: r.seal != SealMode.off,
      onSeal: _busy != null ? null : (v) => _run(DeskBusyRow.seal, (api) => api.setSeal(r.id, v)),
      allow: r.allowInvoices,
      offLine: l.sasAllowOffLine(name),
      onLine: l.sasAllowInvoicesHintDesktop(name),
      onAllow: _busy != null ? null : (v) => _run(DeskBusyRow.allow, (api) => api.setAllowInvoices(r.id, v)),
      busy: _busy,
    );
  }
}

/// The result of a words check that matched, for a pairing already in a contact (or a
/// recheck): the verified title, the line, and the Allow invoices row, off until the payer
/// turns it on. The phone shows the same on its result screen.
class DeskMatchedResult extends ConsumerWidget {
  const DeskMatchedResult({super.key, required this.pairingId, this.domain});

  final String pairingId;

  /// The domain that proved the wallet, when it did and no words were compared.
  final String? domain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ts = context.ts;
    final r = ref.watch(deskPairingByIdProvider(pairingId));
    final name = ref.watch(deskPairingNameProvider(pairingId));
    final inFlow = _PairFlowScope.maybeOf(context);
    return EDialog(
      title: l.sasMatchedTitle(name),
      tone: ETone.ok,
      icon: EIcons.trusted,
      size: inFlow == null ? DialogWidth.standard : DialogWidth.wide,
      minBodyHeight: inFlow?.minBody,
      minFootHeight: inFlow?.minFoot,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(domain == null ? l.sasMatchedBody(name) : l.deskPairDomainVerifiedBody(name, domain!), style: ts.bodyDim),
          if (r != null && statedAutomated(r.peerProfile)) ...[
            SizedBox(height: Sp.x1),
            Text(l.pairIsService, style: ts.bodyDim),
          ],
          SizedBox(height: Sp.x4),
          DeskAllowGroup(pairingId: pairingId),
        ],
      ),
      actions: [EButton.primary(key: deskMatchedDoneKey, semanticsId: TrustIds.pairResultDone, label: l.commonDone, onPressed: () => Navigator.of(context).pop())],
    );
  }
}

/// One outcome of a pairing that ended, as a dialog.
Future<void> showDeskOutcome(BuildContext context, PairingFailure failure, {String name = ''}) {
  final l = context.l10n;
  final tone = switch (failure) {
    PairingFailure.changedOnTheWay || PairingFailure.sealedForOther || PairingFailure.otherWallet => ETone.risk,
    PairingFailure.cancelled || PairingFailure.newerVersion || PairingFailure.crossed => ETone.info,
    _ => ETone.warn,
  };
  return showEDialog<void>(
    context,
    builder: (ctx) => EDialog(
      title: pairingFailureText(l, failure, name: name),
      description: pairingFailureBody(l, failure, name: name),
      tone: tone,
      icon: tone == ETone.info ? EIcons.info : EIcons.alert,
      actions: [EButton.primary(label: l.pairClosed, onPressed: () => Navigator.pop(ctx))],
    ),
  );
}

/// The body height every step of the pairing window shares, at scale 1: the window keeps one
/// size from the code to the result.
const double _flowBodyHeight = 224;

/// The steps of the pairing window.
enum _FlowPhase { incoming, waiting, words, result }

/// What the flow's last step offers.
enum _FlowResult { saveOffer, matched }

/// The line under the words while the contact's domain is being asked, for tests.
const Key deskDomainCheckingKey = ValueKey('desk-domain-checking');

/// What the steps of a [_PairFlowDialog] reach: the window, to tell it the step is done.
class _PairFlowScope extends InheritedWidget {
  const _PairFlowScope({required this.flow, required super.child});

  final _PairFlowState flow;

  double get minBody => flow.minBody;
  double get minFoot => flow.minFoot;

  static _PairFlowScope? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<_PairFlowScope>();

  static _PairFlowScope of(BuildContext context) => maybeOf(context)!;

  @override
  bool updateShouldNotify(_PairFlowScope old) => flow != old.flow;
}

/// The pairing window for a code this wallet answered (and the words check from the other
/// entry points): ONE dialog from "Pair with Anna?" to the result. It never closes and
/// reopens: the incoming step, the wait, the words and the result change inside it with a
/// short cross-fade (none with reduce motion), at one width and one body height.
///
/// Nothing waits up front: after the confirm the words show at once for every peer. A
/// pairing with [PairingRecord.domainProvable] asks the domain under them ("Checking
/// `domain`…"); a proof turns the window into Verified in place, a refusal or silence only
/// removes the line. A name service hello that arrives upgrades the words to its code check.
class _PairFlowDialog extends ConsumerStatefulWidget {
  const _PairFlowDialog.incoming({required PairingInvitePreview this.preview, this.contact, this.source})
    : pairingId = null,
      recheck = false,
      proof = false;

  const _PairFlowDialog.check({required String this.pairingId, required this.recheck, required this.proof})
    : preview = null,
      contact = null,
      source = null;

  final PairingInvitePreview? preview;
  final Contact? contact;
  final InviteSource? source;
  final String? pairingId;
  final bool recheck;
  /// The check opens on a pairing whose contact's domain can prove it: the proof runs under the words.
  final bool proof;

  @override
  ConsumerState<_PairFlowDialog> createState() => _PairFlowState();
}

class _PairFlowState extends ConsumerState<_PairFlowDialog> {
  late _FlowPhase _phase;
  String? _id;
  String _domain = '';
  _FlowResult _result = _FlowResult.matched;

  /// The domain's answer was taken (proven): a second one does nothing.
  bool _proved = false;

  /// The ids this window put in the on-screen sets, to take them out again.
  bool _marked = false;

  double get minBody => _flowBodyHeight.u;

  /// Three buttons stacked, the tallest footer of the steps.
  double get minFoot => 3 * Ctl.md + 2 * Sp.x2p5;

  @override
  void initState() {
    super.initState();
    final id = widget.pairingId;
    if (id == null) {
      _phase = _FlowPhase.incoming;
      return;
    }
    _id = id;
    _phase = _FlowPhase.words;
    if (widget.proof) WidgetsBinding.instance.addPostFrameCallback((_) => _startProof(id));
  }

  @override
  void dispose() {
    final id = _id;
    if (id != null && _marked && widget.pairingId == null) {
      deskPairingStepsOnScreen.remove(id);
      _checksOpen.remove(id);
    }
    super.dispose();
  }

  void _go(_FlowPhase phase) {
    if (mounted) setState(() => _phase = phase);
  }

  /// The answer to the code went out: the wait for the confirmation.
  void answered(PairingRecord r) {
    _id = r.id;
    // The wait is up, and the words check is this window's: nobody opens a second one.
    deskPairingStepsOnScreen.add(r.id);
    _checksOpen.add(r.id);
    _marked = true;
    _go(_FlowPhase.waiting);
  }

  /// The confirmation is in; [record] is the wallet's own view of the pairing, null when
  /// it could not be read.
  void confirmed(PairingRecord? record) {
    final id = _id!;
    if (record != null && record.state == PairingState.verified) {
      final host = Navigator.of(context).context;
      final l = context.l10n;
      final name = ref.read(deskPairingNameProvider(id));
      Navigator.pop(context);
      if (host.mounted) showEToast(host, l.pairPairedWith(name), tone: ETone.ok);
      return;
    }
    // The words at once, for every peer; a domain that can prove the wallet is asked under them.
    _go(_FlowPhase.words);
    if (record != null && record.domainProvable) _startProof(id);
  }

  /// Asks the contact's domain while the words are up. Proven, the window turns Verified in
  /// place; refused or unreachable, the line under the words just goes away.
  void _startProof(String id) {
    if (!mounted) return;
    unawaited(_runProof(id));
  }

  Future<void> _runProof(String id) async {
    final api = ref.read(deskPairingApiProvider);
    final records = ref.read(deskPairingsProvider.notifier);
    var proven = false;
    try {
      proven = await api.proveByDomain(id);
    } on Object {
      // Not proven: the words stay.
    }
    if (!mounted) return;
    if (proven && _phase == _FlowPhase.words) {
      await _verifiedByDomain(id);
      return;
    }
    // The record's own domainChecking turns the line off; read it again.
    unawaited(records.reload());
  }

  /// The domain proved the wallet: the pairing is Verified; the window shows it in place.
  Future<void> _verifiedByDomain(String id) async {
    if (_proved) return;
    _proved = true;
    PairingRecord? record;
    try {
      record = await ref.read(deskPairingApiProvider).pairing(id);
    } on Object {
      // The records are read again by the event.
    }
    if (!mounted) return;
    unawaited(ref.read(deskPairingsProvider.notifier).reload());
    if (record != null) await deskWriteProvenAddress(ref, record);
    if (!mounted) return;
    if (record?.peerDomain case final d? when d.isNotEmpty) _domain = d;
    await showResult(record, name: ref.read(deskPairingNameProvider(id)), domain: _domain);
  }

  /// The result in place: the save offer when the pairing is in no contact yet, else the
  /// matched result with its Allow row, else the toast.
  Future<void> showResult(PairingRecord? r, {required String name, String? domain}) async {
    if (!mounted) return;
    final l = context.l10n;
    final host = Navigator.of(context).context;
    final contacts = ref.read(deskProvider).contacts ?? const <Contact>[];
    final saved = r == null || (r.contactId != null && contacts.any((c) => c.id == r.contactId));
    if (domain != null && domain.isEmpty) domain = null;
    if (!saved && !widget.recheck) {
      _show(_FlowResult.saveOffer, domain);
    } else if (r != null && !ref.read(paymentRefusalsProvider).refusesPayments(pairingId: r.id)) {
      _show(_FlowResult.matched, domain);
    } else {
      Navigator.pop(context);
      if (host.mounted) showEToast(host, l.sasMatchedTitle(name), tone: ETone.ok);
    }
  }

  void _show(_FlowResult result, String? domain) {
    setState(() {
      _result = result;
      _domain = domain ?? '';
      _phase = _FlowPhase.result;
    });
  }

  Widget _step(BuildContext context) {
    final id = _id;
    switch (_phase) {
      case _FlowPhase.incoming:
        return _IncomingDialog(preview: widget.preview!, contact: widget.contact, source: widget.source);
      case _FlowPhase.waiting:
        return DeskPairWaitingDialog(pairingId: id!, name: widget.preview?.name ?? '');
      case _FlowPhase.words:
        return _CheckDialog(pairingId: id!);
      case _FlowPhase.result:
        final domain = _domain.isEmpty ? null : _domain;
        return _result == _FlowResult.saveOffer
            ? DeskPairedSaveDialog(pairingId: id!, verified: true, domain: domain)
            : DeskMatchedResult(pairingId: id!, domain: domain);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A proof that comes after the wait: the words turn into Verified, no new window.
    ref.listen<PairingRecord?>(deskPairingByIdProvider(_id ?? ''), (_, next) {
      if (_phase == _FlowPhase.words && next != null && next.state == PairingState.verified && next.domainStatus == DomainStatus.proven) {
        unawaited(_verifiedByDomain(next.id));
      }
    });
    final still = MediaQuery.disableAnimationsOf(context);
    final current = ValueKey(_phase);
    return _PairFlowScope(
      flow: this,
      // The words step is taller than the others: the window grows to it in place, not in a jump.
      child: AnimatedSize(
        duration: still ? Duration.zero : Motion.cross,
        curve: Motion.easeOut,
        clipBehavior: Clip.none,
        child: AnimatedSwitcher(
          duration: still ? Duration.zero : Motion.cross,
          switchInCurve: Motion.easeOut,
          // The new step fades in over the old one, which stays whole until it is covered, so
          // the window never thins out in between.
          transitionBuilder: (child, animation) => child.key == current ? FadeTransition(opacity: animation, child: child) : IgnorePointer(child: child),
          child: KeyedSubtree(key: current, child: _step(context)),
        ),
      ),
    );
  }
}
