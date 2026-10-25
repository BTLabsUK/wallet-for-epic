/// Pair (SPEC 2.1): the three ways in, in person (show my code, scan theirs), online (an
/// invite link with its expiry, or pairing words) and Enter link or words. Each ends at the
/// words check once the other side's answer is in.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../errors.dart';
import '../../l10n.dart';
import '../../pairing_providers.dart';
import '../../wallet_service.dart';
import '../../pairing_text.dart';
import '../../sas_table.dart';
import '../../secure_screen.dart' show openAppSettings;
import '../../slate_files.dart';
import '../common.dart';
import '../qr_camera.dart';
import '../scan_screen.dart' show qrScanSupported;
import '../theme/brand.dart';
import '../theme/protocol.dart';
import '../theme/tokens.dart';
import 'pair_check.dart';
import 'pair_incoming.dart';
import 'pairing_notices.dart' show pairingWordsOnScreen;
import 'pairing_parts.dart';

/// Keys for tests.
const Key pairInPersonKey = ValueKey('pair-in-person');
const Key pairOnlineKey = ValueKey('pair-online');
const Key pairEnterKey = ValueKey('pair-enter');
const Key pairShareKey = ValueKey('pair-share');
const Key pairUseWordsKey = ValueKey('pair-use-words');
const Key pairNameFieldKey = ValueKey('pair-name');
const Key pairEnterFieldKey = ValueKey('pair-enter-field');
const Key pairEnterGoKey = ValueKey('pair-enter-go');
const Key pairNewWordsKey = ValueKey('pair-new-words');
const Key pairCancelInviteKey = ValueKey('pair-cancel-invite');

/// The Pair screen: three rows in one card. [contact] is the address-book contact the
/// pairing will attach to, when started from its page.
class PairScreen extends ConsumerStatefulWidget {
  const PairScreen({super.key, this.contact});

  final Contact? contact;

  @override
  ConsumerState<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends ConsumerState<PairScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(pairNetProvider) == PairNet.offline) {
        ref.read(noticeProvider.notifier).show(context.l10n.pairOfflineHint, level: NoticeLevel.warning);
      }
    });
  }

  void _push(Widget screen) => Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final offline = ref.watch(pairNetProvider) == PairNet.offline;
    return SlotScaffold(
      appBar: AppBar(title: Text(widget.contact == null ? l.pairTitle : l.pairWithName(widget.contact!.name))),
      body: ScreenBody(
        children: [
          PairLead(l.pairLead),
          const SizedBox(height: 16),
          PairCard(
            children: [
              _WayTile(
                key: pairInPersonKey,
                icon: Icons.qr_code_2,
                title: l.pairInPerson,
                subtitle: l.pairInPersonHint,
                onTap: () => _push(InPersonScreen(contact: widget.contact)),
              ),
              _WayTile(
                key: pairOnlineKey,
                icon: Icons.link,
                title: l.pairOnline,
                // Offline the invite and the answer travel by hand, as with Epicbox off.
                subtitle: offline ? l.pairOfflineHint : l.pairOnlineHint,
                onTap: () => _push(PairOnlineScreen(contact: widget.contact)),
              ),
              _WayTile(
                key: pairEnterKey,
                icon: Icons.keyboard_outlined,
                title: l.pairEnter,
                subtitle: l.pairEnterHint,
                onTap: () => _push(EnterLinkScreen(contact: widget.contact)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WayTile extends StatelessWidget {
  const _WayTile({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListTile(
      minTileHeight: 64,
      leading: Icon(icon, color: onTap == null ? t.faint : t.accentText),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: t.dim),
      enabled: onTap != null,
      onTap: onTap,
    );
  }
}

/// The "They will see you as" field: the name the other side sees, remembered on the device.
class SeenAsField extends ConsumerStatefulWidget {
  const SeenAsField({super.key, this.onChanged, this.error, this.autofocus = false});

  /// Takes the focus when no name is kept yet: the screen needs one before it can go on.
  final bool autofocus;

  /// After the user changed the name: on submit, when the field loses focus, or once typing
  /// pauses. The name itself is current at every key, for a button tapped with the keyboard up.
  final ValueChanged<String>? onChanged;
  final String? error;

  @override
  ConsumerState<SeenAsField> createState() => _SeenAsFieldState();
}

class _SeenAsFieldState extends ConsumerState<SeenAsField> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _loaded = false;
  Timer? _pause;

  /// The name [SeenAsField.onChanged] last told.
  String? _committed;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void dispose() {
    _pause?.cancel();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    _pause?.cancel();
    final name = _text.text.trim();
    if (name == (_committed ?? ref.read(pairingSeenAsProvider).value ?? '')) return;
    _committed = name;
    ref.read(pairingSeenAsProvider.notifier).set(name);
    widget.onChanged?.call(name);
  }

  /// Every key: the screens read the name at once (Share invite tapped with the keyboard up,
  /// PAIR-AND-1); it is kept, and [SeenAsField.onChanged] told, once typing pauses.
  void _typed(String text) {
    ref.read(pairingSeenAsProvider.notifier).type(text);
    _pause?.cancel();
    _pause = Timer(const Duration(milliseconds: 700), () {
      if (mounted) _commit();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final saved = ref.watch(pairingSeenAsProvider).value;
    if (!_loaded && saved != null) {
      _loaded = true;
      _committed = saved;
      _text.text = saved;
      if (widget.autofocus && saved.trim().isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focus.requestFocus();
        });
      }
    }
    return TextField(
      key: pairNameFieldKey,
      controller: _text,
      focusNode: _focus,
      textCapitalization: TextCapitalization.words,
      maxLength: 48,
      buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
      onChanged: _typed,
      onSubmitted: (_) => _commit(),
      decoration: InputDecoration(
        labelText: l.pairSeenAs,
        border: const OutlineInputBorder(),
        errorText: widget.error,
        suffixIcon: IconButton(
          tooltip: l.pairSeenAsEdit,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _focus.requestFocus(),
        ),
      ),
    );
  }
}

/// The name check of [SeenAsField]: an error, or null.
String? seenAsError(AppLocalizations l, String name) {
  final t = name.trim();
  if (t.isEmpty) return l.pairSeenAsMissing;
  if (utf8.encode(t).length > 48) return l.pairSeenAsTooLong;
  return null;
}

// ---------------------------------------------------------------------------------------
// In person.

/// In person (RFC 7.4): this phone's code to be scanned, and the camera for theirs. Once the
/// camera read the other card, the words check opens. [scanned] is a card read before this
/// screen opened (the Home scan), paired as soon as this phone's card is shown.
class InPersonScreen extends ConsumerStatefulWidget {
  const InPersonScreen({super.key, this.contact, this.scanned, this.startOnScan = false});

  final Contact? contact;
  final String? scanned;
  final bool startOnScan;

  @override
  ConsumerState<InPersonScreen> createState() => _InPersonScreenState();
}

class _InPersonScreenState extends ConsumerState<InPersonScreen> {
  late bool _scan = widget.startOnScan;
  PairingCard? _card;
  String? _cardFor;
  String? _nameError;
  bool _pairing = false;

  /// No name yet: the code waits for one, with no error until the user gave a name.
  bool _noName = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _makeCard());
  }

  Future<void> _makeCard({bool typed = false}) async {
    final l = context.l10n;
    final name = await readSeenAs(ref);
    if (!mounted) return;
    final error = seenAsError(l, name);
    setState(() {
      _noName = name.trim().isEmpty;
      _nameError = typed || !_noName ? error : null;
    });
    if (error != null || name == _cardFor) return;
    try {
      final card = await ref.read(pairingApiProvider).showCard(name: name.trim());
      if (!mounted) return;
      setState(() {
        _card = card;
        _cardFor = name;
      });
      final pending = widget.scanned;
      if (pending != null) await _paired(pending);
    } catch (error) {
      if (mounted) ref.read(noticeProvider.notifier).show(describeError(l, error), level: NoticeLevel.error);
    }
  }

  Future<void> _paired(String text) async {
    final card = _card;
    if (card == null || _pairing) return;
    _pairing = true;
    try {
      final record = await pairingCall(ref, (api) => api.scanCard(cardId: card.id, text: text));
      await pairingCall(ref, (api) => dropOlderInPersonPairings(api, record));
      if (widget.contact != null) await pairingCall(ref, (api) => api.attach(record.id, widget.contact!.id));
      if (!mounted) return;
      SemanticsService.sendAnnouncement(View.of(context), context.l10n.pairInPersonDone, Directionality.of(context));
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: record.id, inPerson: true)),
      );
    } catch (error) {
      _pairing = false;
      if (!mounted) return;
      final failure = pairingFailureOf(error);
      if (failure != null) {
        await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => PairingOutcomeScreen(failure: failure)));
      } else {
        ref.read(noticeProvider.notifier).show(describeError(context.l10n, error), level: NoticeLevel.error);
      }
    }
  }

  void _words() => Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => PairingWordsScreen(contact: widget.contact)),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final words = ref.watch(pairNetProvider) == PairNet.online;
    final card = _card;
    return SlotScaffold(
      appBar: AppBar(title: Text(l.pairInPersonTitle)),
      body: ScreenBody(
        bottom: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              key: pairUseWordsKey,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.abc),
              label: Text(l.pairUseWords),
              onPressed: words ? _words : null,
            ),
            if (!words) ...[const SizedBox(height: 6), PairSmallPrint(l.pairWordsNeedEpicbox)],
          ],
        ),
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l.pairShowMyCode), icon: const Icon(Icons.qr_code_2)),
              ButtonSegment(value: true, label: Text(l.pairScanTheirs), icon: const Icon(Icons.qr_code_scanner)),
            ],
            selected: {_scan},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _scan = s.first),
          ),
          const SizedBox(height: 16),
          if (!_scan) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: t.surface, border: Border.all(color: t.line), borderRadius: BorderRadius.circular(t.radius)),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      // Dark modules on white scan reliably in either theme.
                      color: protocolLight.surface,
                      border: Border.all(color: t.line),
                      borderRadius: BorderRadius.circular(t.radiusSmall),
                    ),
                    child: card == null
                        ? SizedBox.square(
                            dimension: 226,
                            child: Center(
                              child: _noName || _nameError != null
                                  // Neutral until a name exists: the code needs it.
                                  ? Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(l.pairNameForCode, textAlign: TextAlign.center, style: TextStyle(color: protocolLight.dim)),
                                    )
                                  : const CircularProgressIndicator(),
                            ),
                          )
                        : Semantics(label: l.pairCodeLabel, image: true, child: MarkedQr(data: card.link, size: 226)),
                  ),
                  const SizedBox(height: 12),
                  Text(l.pairShowCodeCaption, textAlign: TextAlign.center, style: TextStyle(color: t.dim)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SeenAsField(error: _nameError, autofocus: true, onChanged: (_) => _makeCard(typed: true)),
          ] else
            _CardScanner(onCode: _paired, onWords: words ? _words : null),
        ],
      ),
    );
  }
}

/// The camera in the page, with gold corner marks, for the other phone's code. A denied
/// camera shows why and how to allow it.
class _CardScanner extends ConsumerStatefulWidget {
  const _CardScanner({required this.onCode, required this.onWords});

  final Future<void> Function(String text) onCode;
  final VoidCallback? onWords;

  @override
  ConsumerState<_CardScanner> createState() => _CardScannerState();
}

class _CardScannerState extends ConsumerState<_CardScanner> {
  QrCamera? _camera;
  StreamSubscription<String>? _codes;

  @override
  void initState() {
    super.initState();
    if (qrScanSupported || ref.read(qrCameraFactoryProvider) != MobileQrCamera.new) {
      final camera = ref.read(qrCameraFactoryProvider)();
      _camera = camera;
      _codes = camera.codes.listen((text) {
        if (pairingLinkKind(text) == PairingLinkKind.card) widget.onCode(text);
      });
      camera.start();
    }
  }

  @override
  void dispose() {
    _codes?.cancel();
    _camera?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final camera = _camera;
    if (camera == null) {
      return PairEdgeNotice(tone: BadgeTone.warn, title: l.pairCameraDeniedTitle, body: l.pairCameraDeniedBody);
    }
    return ValueListenableBuilder<QrCameraState>(
      valueListenable: camera,
      builder: (context, state, _) {
        if (state.problem != null) {
          return PairEdgeNotice(
            tone: BadgeTone.warn,
            title: l.pairCameraDeniedTitle,
            body: l.pairCameraDeniedBody,
            actions: [
              if (state.problem == QrCameraProblem.denied)
                OutlinedButton(onPressed: () => openAppSettings(), child: Text(l.pairOpenSettings)),
            ],
          );
        }
        return Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(t.radiusSmall),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    camera.preview(context),
                    Padding(
                      padding: const EdgeInsets.all(36),
                      child: CustomPaint(painter: CornerTicksPainter(t.accent, length: 26, width: 3)),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(l.pairScanPrompt, style: const TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 4)])),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(l.pairScanCaption, textAlign: TextAlign.center, style: TextStyle(color: t.dim)),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------------------
// Online.

/// Pair online (RFC 7.1): the expiry, the name they see, what they receive, then the share
/// sheet (or Copy). Once shared, the invite waits under Pending invites and this screen says
/// so with its countdown. While Epicbox is off or the wallet is Offline the answer comes back
/// by hand.
class PairOnlineScreen extends ConsumerStatefulWidget {
  const PairOnlineScreen({super.key, this.contact});

  final Contact? contact;

  @override
  ConsumerState<PairOnlineScreen> createState() => _PairOnlineScreenState();
}

class _PairOnlineScreenState extends ConsumerState<PairOnlineScreen> {
  Duration _expiry = pairingInviteDefaultExpiry;
  PairingRecord? _sent;
  String? _nameError;
  bool _busy = false;
  PairingCollector? _collector;
  StreamSubscription<PairingEvent>? _events;
  bool _onScreen(PairingEvent e) => e.pairingId != null && e.pairingId == _sent?.id;

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (ref.read(pairNetProvider)) {
        case PairNet.epicboxOff:
          ref.read(noticeProvider.notifier).show(context.l10n.pairEpicboxOffNotice, level: NoticeLevel.info);
        case PairNet.offline:
          ref.read(noticeProvider.notifier).show(context.l10n.pairOfflineHint, level: NoticeLevel.warning);
        case PairNet.online:
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

  String _shareText(AppLocalizations l, String name, String link, DateTime expires) =>
      l.pairShareText(name, link, formatDateTime(l, expires));

  Future<PairingRecord?> _make() async {
    final l = context.l10n;
    final name = ref.read(pairingSeenAsProvider).value ?? '';
    final error = seenAsError(l, name);
    setState(() => _nameError = error);
    if (error != null) return null;
    setState(() => _busy = true);
    try {
      return await pairingCall(
        ref,
        (api) => api.makeInvite(name: name.trim(), expiry: _expiry, label: widget.contact?.name, contactId: widget.contact?.id),
      );
    } catch (error) {
      if (mounted) ref.read(noticeProvider.notifier).show(describeError(l, error), level: NoticeLevel.error);
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share({required bool copy}) async {
    final l = context.l10n;
    final invite = await _make();
    if (invite == null || !mounted) return;
    final text = _shareText(l, ref.read(pairingSeenAsProvider).value ?? '', invite.inviteLink ?? '', invite.expiresAt!);
    final files = ref.read(slateFilesProvider);
    if (copy || !files.canShareText) {
      await copyText(context, text, l.pairCopied);
    } else {
      await files.shareText(text);
    }
    if (!mounted) return;
    setState(() => _sent = invite);
    _watch(invite.id);
  }

  void _watch(String id) {
    final api = ref.read(pairingApiProvider);
    _collector = PairingCollector(api)..start();
    _events = api.events().listen((e) {
      if (e.pairingId != id || !mounted) return;
      if (e.kind == PairingEventKind.replied) {
        Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: id)));
      }
    });
  }

  Future<void> _cancel() async {
    final l = context.l10n;
    final sent = _sent;
    if (sent == null) return;
    final name = sent.label ?? l.pairUnnamedInvite;
    final sure = await confirmCancelInvite(context, name);
    if (!sure || !mounted) return;
    await pairingCall(ref, (api) => api.cancelInvite(sent.id));
    if (mounted) Navigator.pop(context);
  }

  void _words() => Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(builder: (_) => PairingWordsScreen(contact: widget.contact)),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final byHand = ref.watch(pairNetProvider) != PairNet.online;
    final sent = _sent;
    if (sent != null) return _sentView(l, sent);
    final name = ref.watch(pairingSeenAsProvider).value ?? '';
    final canShare = ref.watch(slateFilesProvider).canShareText;
    final preview = _shareText(l, name.isEmpty ? l.pairYourNamePlaceholder : name, 'epiccash://pair/1/…', DateTime.now().add(_expiry));
    return SlotScaffold(
      appBar: AppBar(title: Text(l.pairOnlineTitle)),
      body: ScreenBody(
        bottom: Row(
          children: [
            Expanded(
              child: byHand
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(l.commonCopy),
                      onPressed: _busy ? null : () => _share(copy: true),
                    )
                  : OutlinedButton.icon(
                      key: pairUseWordsKey,
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      icon: const Icon(Icons.abc),
                      label: Text(l.pairUseWordsShort),
                      onPressed: _busy ? null : _words,
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                key: pairShareKey,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: Icon(canShare ? Icons.ios_share : Icons.copy, size: 18),
                label: Text(canShare ? l.pairShareInvite : l.pairCopyInvite),
                onPressed: _busy ? null : () => _share(copy: !canShare),
              ),
            ),
          ],
        ),
        children: [
          PairLead(byHand ? l.pairOnlineLeadByHand : l.pairOnlineLead),
          const SizedBox(height: 16),
          Text(l.pairExpiresIn, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.tokens.dim)),
          const SizedBox(height: 6),
          SegmentedButton<Duration>(
            segments: [
              ButtonSegment(value: pairingInviteExpiries[0], label: Text(l.pairExpiry1h)),
              ButtonSegment(value: pairingInviteExpiries[1], label: Text(l.pairExpiry24h)),
              ButtonSegment(value: pairingInviteExpiries[2], label: Text(l.pairExpiry7d)),
            ],
            selected: {_expiry},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _expiry = s.first),
          ),
          const SizedBox(height: 16),
          SeenAsField(error: _nameError, autofocus: true, onChanged: (_) => setState(() => _nameError = null)),
          const SizedBox(height: 8),
          ShareBox(label: l.pairWhatTheyReceive, text: preview),
          const SizedBox(height: 10),
          // By hand the invite is just as open: the warning stays.
          PairSmallPrint(l.pairShareWarning),
          if (byHand) ...[const SizedBox(height: 6), PairSmallPrint(l.pairWordsNeedEpicbox)],
        ],
      ),
    );
  }

  Widget _sentView(AppLocalizations l, PairingRecord sent) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return SlotScaffold(
      appBar: AppBar(title: Text(l.pairOnlineTitle)),
      body: ScreenBody(
        bottom: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: pairCancelInviteKey,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: _cancel,
                child: Text(l.pairCancelInvite),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => Navigator.pop(context),
                child: Text(l.commonDone),
              ),
            ),
          ],
        ),
        children: [
          const SizedBox(height: 24),
          const Center(child: GlyphTile(size: 72, child: Icon(Icons.link))),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(l.pairInviteSentTitle, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
          Text(
            // By hand the answer comes back the same way, not on its own.
            ref.watch(pairNetProvider) != PairNet.online
                ? l.pairOnlineLeadByHand
                : (sent.label == null ? l.pairInviteSentBodyAnyone : l.pairInviteSentBody(sent.label!)),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: t.dim),
          ),
          const SizedBox(height: 16),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: PairCountdown(until: sent.expiresAt!, label: l.pairExpiresIn),
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks before cancelling the invite for [name]; true to cancel.
Future<bool> confirmCancelInvite(BuildContext context, String name) async {
  final l = context.l10n;
  final sure = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.pairCancelInviteTitle(name)),
      content: Text(l.pairCancelInviteBody(name)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.contactKeep)),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: context.tokens.risk),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.pairCancelInvite),
        ),
      ],
    ),
  );
  return sure == true;
}

// ---------------------------------------------------------------------------------------
// Pairing words.

/// Pairing words (RFC 7.7): five words for the other side to type, good for 10 minutes, with
/// the countdown; New words makes a fresh invite. [invite] shows an invite's words again (from
/// Pending invites); without one the screen makes the invite.
class PairingWordsScreen extends ConsumerStatefulWidget {
  const PairingWordsScreen({super.key, this.contact, this.invite});

  final Contact? contact;
  final PairingRecord? invite;

  @override
  ConsumerState<PairingWordsScreen> createState() => _PairingWordsScreenState();
}

class _PairingWordsScreenState extends ConsumerState<PairingWordsScreen> {
  late PairingRecord? _invite = widget.invite;
  String? _error;
  PairingCollector? _collector;
  StreamSubscription<PairingEvent>? _events;
  Timer? _expiry;
  bool _onScreen(PairingEvent e) => e.pairingId != null && e.pairingId == _invite?.id;

  @override
  void initState() {
    super.initState();
    pairingWordsOnScreen.add(_onScreen);
    final api = ref.read(pairingApiProvider);
    _collector = PairingCollector(api)..start();
    _events = api.events().listen((e) {
      if (e.kind == PairingEventKind.replied && e.pairingId == _invite?.id && mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => CheckWordsScreen(pairingId: e.pairingId!)));
      }
    });
    if (_invite == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _make());
    } else {
      _armExpiry();
    }
  }

  @override
  void dispose() {
    pairingWordsOnScreen.remove(_onScreen);
    _collector?.stop();
    _events?.cancel();
    _expiry?.cancel();
    super.dispose();
  }

  void _armExpiry() {
    _expiry?.cancel();
    final until = _invite?.expiresAt;
    if (until == null) return;
    final left = until.difference(ref.read(pairingClockProvider)());
    _expiry = Timer(left.isNegative ? Duration.zero : left, () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _make() async {
    final l = context.l10n;
    final old = _invite;
    final name = (await readSeenAs(ref)).trim();
    if (!mounted) return;
    try {
      final invite = await pairingCall(
        ref,
        (api) => api.makeInvite(
          name: name.isEmpty ? l.pairTitle : name,
          expiry: pairingWordsExpiry,
          words: true,
          label: widget.contact?.name ?? old?.label,
          contactId: widget.contact?.id ?? old?.contactId,
        ),
      );
      if (old != null) await pairingCall(ref, (api) => api.cancelInvite(old.id));
      if (!mounted) return;
      setState(() {
        _invite = invite;
        _error = null;
      });
      _armExpiry();
    } catch (error) {
      if (mounted) setState(() => _error = describeError(l, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final invite = _invite;
    final now = ref.watch(pairingClockProvider)();
    final expired = invite?.expiresAt != null && !now.isBefore(invite!.expiresAt!);
    final words = invite?.inviteWords ?? const <SasWord>[];
    return SlotScaffold(
      appBar: AppBar(title: Text(l.pairWordsTitle)),
      body: ScreenBody(
        bottom: Row(
          children: [
            if (!expired) ...[
              Expanded(
                child: OutlinedButton(
                  key: pairNewWordsKey,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: _make,
                  child: Text(l.pairWordsNew),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: expired
                  ? FilledButton(
                      key: pairNewWordsKey,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      onPressed: _make,
                      child: Text(l.pairWordsNew),
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(l.pairWordsCopy),
                      onPressed: words.isEmpty ? null : () => copyText(context, pairingWordsText(words), l.pairCopied),
                    ),
            ),
          ],
        ),
        children: [
          if (!expired) ...[PairLead(l.pairWordsLead), const SizedBox(height: 16)],
          if (_error != null) ...[PairEdgeNotice(tone: BadgeTone.warn, title: _error!), const SizedBox(height: 12)],
          PairCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: words.isEmpty
                    ? const SizedBox(height: 90, child: Center(child: CircularProgressIndicator()))
                    : WordTiles(words: words, label: l.pairWordsLabel, dim: expired),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (expired)
            PairEdgeNotice(tone: BadgeTone.warn, title: l.pairWordsExpiredTitle, body: l.pairWordsExpiredBody)
          else if (invite?.expiresAt != null) ...[
            PairCountdown(until: invite!.expiresAt!, label: l.pairWordsGoodFor, lastMinute: l.pairWordsLastMinute, clock: true),
            const SizedBox(height: 8),
            PairSmallPrint(l.pairWordsFooter),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------
// Enter link or words.

/// Enter link or words: one field for a pasted link (an invite, an answer or a confirm sent
/// by hand) or the five pairing words, completed from the word table. Pair opens what it
/// holds; words that find nothing say so.
class EnterLinkScreen extends ConsumerStatefulWidget {
  const EnterLinkScreen({super.key, this.contact, this.initial});

  final Contact? contact;
  final String? initial;

  @override
  ConsumerState<EnterLinkScreen> createState() => _EnterLinkScreenState();
}

class _EnterLinkScreenState extends ConsumerState<EnterLinkScreen> {
  late final _text = TextEditingController(text: widget.initial);
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// The typed words: each a table name or emoji, the last one still being typed.
  List<String> get _parts => _text.text.trim().split(RegExp(r'[\s,·]+')).where((w) => w.isNotEmpty).toList();

  List<SasWord?> get _tiles {
    final parts = _parts;
    return [
      for (var i = 0; i < pairingWordCount; i++)
        i < parts.length ? (sasWordNamed(parts[i]) ?? sasWordOfEmoji(parts[i])) : null,
    ];
  }

  Set<int> get _unknown {
    final parts = _parts;
    final typing = !_text.text.endsWith(' ');
    return {
      for (var i = 0; i < parts.length && i < pairingWordCount; i++)
        if ((sasWordNamed(parts[i]) ?? sasWordOfEmoji(parts[i])) == null && !(typing && i == parts.length - 1)) i,
    };
  }

  bool get _isLink => pairingLinkIn(_text.text) != null;

  bool get _ready => _isLink || (_parts.length == pairingWordCount && _tiles.every((w) => w != null));

  void _complete(SasWord w) {
    final parts = _parts..removeLast();
    _text.text = '${[...parts, w.name].join(' ')} ';
    _text.selection = TextSelection.collapsed(offset: _text.text.length);
    setState(() => _error = null);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _text.text = text;
    setState(() => _error = null);
  }

  Future<void> _go() async {
    if (_busy || !_ready) return;
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_isLink) {
        await openPairingLink(context, ref, _text.text, contact: widget.contact, replace: true);
      } else {
        final preview = await ref.read(pairingApiProvider).openWords([for (final w in _tiles) w!.name]);
        if (!mounted) return;
        await showIncomingInvite(context, ref, preview, contact: widget.contact, replace: true);
      }
    } catch (error) {
      final failure = pairingFailureOf(error);
      if (!mounted) return;
      setState(() => _error = failure == null ? describeError(l, error) : pairingFailureText(l, failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final parts = _parts;
    final typing = parts.isNotEmpty && !_text.text.endsWith(' ') && !_isLink;
    final suggestions = typing ? sasCompletions(parts.last) : const <SasWord>[];
    return SlotScaffold(
      appBar: AppBar(title: Text(l.pairEnter)),
      body: ScreenBody(
        bottom: FilledButton(
          key: pairEnterGoKey,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _busy || !_ready ? null : _go,
          child: _busy
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_error != null ? l.pairEnterTryAgain : l.pairTitle),
        ),
        children: [
          PairLead(l.pairEnterLead),
          const SizedBox(height: 16),
          TextField(
            key: pairEnterFieldKey,
            controller: _text,
            autocorrect: false,
            enableSuggestions: false,
            minLines: 1,
            maxLines: 4,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _go(),
            decoration: InputDecoration(
              labelText: l.pairEnterField,
              border: const OutlineInputBorder(),
              errorText: _error,
              errorMaxLines: 3,
              suffixIcon: IconButton(tooltip: l.pairPaste, icon: const Icon(Icons.content_paste), onPressed: _paste),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Semantics(
              container: true,
              label: l.pairSuggestions,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final w in suggestions)
                    ActionChip(
                      avatar: Text(w.emoji),
                      label: Text(w.name),
                      onPressed: () => _complete(w),
                    ),
                ],
              ),
            ),
          ],
          if (!_isLink) ...[
            const SizedBox(height: 20),
            WordTiles(words: _tiles, label: l.pairWordsEnteredLabel, bad: _unknown),
          ] else ...[
            const SizedBox(height: 12),
            Text(l.pairEnterHint, style: TextStyle(color: t.dim)),
          ],
        ],
      ),
    );
  }
}
