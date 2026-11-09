// SPDX-License-Identifier: Apache-2.0
/// Receive in epic1 mode (spec D2): the epic1 link card and "Other ways to receive" (In person).
/// The desktop has no share action: Copy link is the one way out, beside the QR code.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../epic1.dart';
import '../../../l10n.dart' show LocalizedFormatException;
import '../../../legacy/gui_rules.dart' show isPrivateHost;
import '../../../models.dart' show WalletError, WalletErrorKind;
import '../../../net/local_address.dart' show isLoopbackIp;
import '../../../trust_ids.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../in_person/in_person_entry.dart' show openDeskRequestInPerson;
import '../settings/prefs.dart' show settingsPrefsProvider;
import '../settings/setting_ids.dart';

/// [text] cut in the middle to [keep] characters: the scheme and start, then the end.
String shortMiddle(String text, {int keep = 44}) {
  if (text.length <= keep) return text;
  final head = (keep * 0.6).round();
  return '${text.substring(0, head)}…${text.substring(text.length - (keep - head - 1))}';
}

/// A server on the local network (not this computer): links on it are asked about first.
bool _onLan(String relay) {
  final host = relay.split(':').first;
  if (host == 'localhost' || isLoopbackIp(host)) return false;
  return isPrivateHost(host);
}

/// The epic1 link card: the link on [relay] (the wallet's Epicbox server, `host[:port]`) with
/// its QR code covered until clicked, Copy link, and Ask an amount.
class Epic1LinkCard extends ConsumerStatefulWidget {
  const Epic1LinkCard({super.key, required this.relay, this.showQr = false});

  /// Null while the server is not known yet.
  final String? relay;

  /// The tour's uncovered QR code; the app never sets it.
  final bool showQr;

  @override
  ConsumerState<Epic1LinkCard> createState() => _Epic1LinkCardState();
}

class _Epic1LinkCardState extends ConsumerState<Epic1LinkCard> {
  Epic1LinkMade? _link;
  Object? _error;
  bool _busy = false;

  /// The LAN server the user agreed to, so the prompt shows once per server.
  String? _lanOk;

  /// A LAN server the user has not agreed to yet: the card asks instead of making a link.
  bool _lanAsk = false;

  int? _amount;
  String? _message;

  @override
  void initState() {
    super.initState();
    _make();
  }

  @override
  void didUpdateWidget(Epic1LinkCard old) {
    super.didUpdateWidget(old);
    if (old.relay != widget.relay) _make();
  }

  Future<void> _make() async {
    final relay = widget.relay;
    final e1 = ref.read(deskApiProvider).epic1;
    if (relay == null || e1 == null) return;
    if (_onLan(relay) && _lanOk != relay) {
      setState(() => _lanAsk = true);
      return;
    }
    setState(() {
      _lanAsk = false;
      _busy = true;
      _error = null;
    });
    try {
      final made = await e1.makeLink(amount: _amount == null ? null : BigInt.from(_amount!), message: _message, relays: [relay]);
      if (mounted) setState(() => _link = made);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _askLan() async {
    final l = context.l10n;
    final relay = widget.relay!;
    final ok = await showEDialog<bool>(
      context,
      builder: (ctx) => EDialog(
        key: const ValueKey('e1-lan-dialog'),
        title: l.deskE1LanTitle,
        description: l.deskE1LanBody(relay),
        icon: EIcons.server,
        actions: [
          EButton(label: l.commonCancel, onPressed: () => Navigator.pop(ctx, false)),
          EButton.primary(key: const ValueKey('e1-lan-use'), label: l.deskE1UseServer, autofocus: true, onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _lanOk = relay;
    await _make();
  }

  Future<void> _ask() async {
    final asked = await showEDialog<(int, String?)>(context, builder: (_) => _AskAmountDialog(amount: _amount, message: _message));
    if (asked == null || !mounted) return;
    _amount = asked.$1;
    _message = asked.$2;
    await _make();
  }

  Future<void> _anyAmount() async {
    _amount = null;
    _message = null;
    await _make();
  }

  void _settings() => ref.read(settingsPrefsProvider.notifier).jumpToRow(SetId.epicboxServer);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.dc;
    final ts = context.ts;
    final link = _link;
    final error = _error;
    final Widget body;
    if (_lanAsk) {
      body = ENotice(
        key: const ValueKey('e1-lan'),
        title: l.deskE1LanTitle,
        text: l.deskE1LanBody(widget.relay ?? ''),
        tone: ETone.warn,
        icon: EIcons.server,
        actions: [
          EButton(key: const ValueKey('e1-lan-ask'), label: l.deskE1UseServer, size: EBtnSize.inline, onPressed: _askLan),
          EButton(label: l.deskRecvSettings, icon: EIcons.settings, size: EBtnSize.inline, onPressed: _settings),
        ],
      );
    } else if (error != null) {
      final own = error is WalletError && error.kind == WalletErrorKind.ownRelayLocal;
      body = ENotice(
        key: const ValueKey('e1-link-error'),
        title: deskErrorText(error, l),
        tone: ETone.risk,
        icon: own ? EIcons.server : EIcons.error,
        actions: [
          if (own)
            EButton(key: const ValueKey('e1-link-settings'), label: l.deskRecvSettings, icon: EIcons.settings, size: EBtnSize.inline, onPressed: _settings)
          else
            EButton(label: l.commonRetry, icon: EIcons.refresh, size: EBtnSize.inline, onPressed: _make),
        ],
      );
    } else if (link == null || widget.relay == null) {
      body = Padding(padding: EdgeInsets.symmetric(vertical: Sp.x6), child: const Center(child: ESpinner()));
    } else {
      final info = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.deskE1LinkSub, style: ts.bodyDim),
          SizedBox(height: Sp.x4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x3),
            decoration: BoxDecoration(color: c.s2, borderRadius: BorderRadius.circular(Rad.sm), border: Border.all(color: c.line)),
            child: Semantics(
              label: l.deskE1LinkTitle,
              value: link.link,
              child: ExcludeSemantics(
                child: Text(shortMiddle(link.link), key: const ValueKey('e1-link-text'), style: ts.mono(size: Fs.sm), maxLines: 1, overflow: TextOverflow.clip),
              ),
            ),
          ),
          if (_amount != null) ...[
            SizedBox(height: Sp.x2),
            Text(l.deskE1LinkAsks(epicTextL(l, _amount!)), key: const ValueKey('e1-link-asks'), style: ts.small),
          ],
          SizedBox(height: Sp.x4),
          Wrap(
            spacing: Sp.x3,
            runSpacing: Sp.x2,
            children: [
              ECopyButton(
                key: const ValueKey('e1-copy-link'),
                text: link.link,
                label: l.deskE1CopyLink,
                withLabel: true,
                kind: EBtnKind.secondary,
                size: EBtnSize.sm,
                semanticsId: TrustIds.e1CopyLink,
              ),
              EButton(
                key: const ValueKey('e1-ask-amount'),
                label: l.deskE1AskAmount,
                icon: EIcons.coins,
                size: EBtnSize.sm,
                busy: _busy,
                semanticsId: TrustIds.e1AskAmount,
                onPressed: _busy ? null : _ask,
              ),
              if (_amount != null)
                EButton.ghost(key: const ValueKey('e1-any-amount'), label: l.deskE1AnyAmount, size: EBtnSize.sm, onPressed: _busy ? null : _anyAmount),
            ],
          ),
        ],
      );
      final qr = EQrReveal(
        key: ValueKey('e1-qr-${link.link}'),
        address: link.link,
        form: QrRevealForm.covered,
        title: l.deskE1LinkTitle,
        method: 'epic1',
        initiallyShown: widget.showQr,
      );
      body = LayoutBuilder(
        builder: (context, box) => box.maxWidth < Lay.lg
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [info, SizedBox(height: Sp.x5), Align(alignment: Alignment.centerLeft, child: qr)])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: info), SizedBox(width: Sp.x6), qr]),
      );
    }
    return EPanel(key: const ValueKey('e1-link-card'), title: l.deskE1LinkTitle, child: body);
  }
}

/// Amount and an optional message for the link. Pops `(nanoepic, message)`.
class _AskAmountDialog extends StatefulWidget {
  const _AskAmountDialog({this.amount, this.message});

  final int? amount;
  final String? message;

  @override
  State<_AskAmountDialog> createState() => _AskAmountDialogState();
}

class _AskAmountDialogState extends State<_AskAmountDialog> {
  late final _amount = TextEditingController();
  late final _message = TextEditingController(text: widget.message ?? '');
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  void _done() {
    final l = context.l10n;
    final String? error;
    var nano = 0;
    if (_amount.text.trim().isEmpty) {
      error = l.deskSendErrAmountEnter;
    } else {
      try {
        nano = parseEpicIn(l, _amount.text);
      } on LocalizedFormatException catch (e) {
        setState(() => _error = e.text(l));
        return;
      }
      error = nano <= 0 ? l.deskSendErrAmountZero : null;
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final m = _message.text.trim();
    Navigator.pop(context, (nano, m.isEmpty ? null : m));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EDialog(
      key: const ValueKey('e1-ask-dialog'),
      title: l.deskE1AskAmount,
      icon: EIcons.coins,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EField(
            label: l.deskSendAmount,
            error: _error,
            child: EInput(
              key: const ValueKey('e1-ask-amount-input'),
              controller: _amount,
              autofocus: true,
              invalid: _error != null,
              semanticLabel: l.deskSendAmount,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _done(),
            ),
          ),
          SizedBox(height: Sp.x4),
          EField(
            label: l.sendNoteLabel,
            optional: true,
            child: EInput(key: const ValueKey('e1-ask-message-input'), controller: _message, semanticLabel: l.sendNoteLabel, onSubmitted: (_) => _done()),
          ),
        ],
      ),
      actions: [
        EButton(label: l.commonCancel, onPressed: () => Navigator.pop(context)),
        EButton.primary(key: const ValueKey('e1-make-link'), label: l.deskE1MakeLink, onPressed: _done),
      ],
    );
  }
}

/// "Other ways to receive" in epic1 mode: In person only.
class Epic1OtherWays extends StatelessWidget {
  const Epic1OtherWays({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ts = context.ts;
    return Column(
      key: const ValueKey('e1-other-ways'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ESectionHead(l.deskE1OtherWays, top: 0),
        EPanel(
          title: l.deskE1InPerson,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.deskE1InPersonSub, style: ts.bodyDim),
              SizedBox(height: Sp.x4),
              Align(
                alignment: Alignment.centerLeft,
                child: EButton(
                  key: const ValueKey('e1-request-in-person'),
                  label: l.deskE1RequestInPerson,
                  icon: EIcons.phone,
                  size: EBtnSize.sm,
                  semanticsId: TrustIds.e1RequestInPerson,
                  onPressed: () => openDeskRequestInPerson(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
