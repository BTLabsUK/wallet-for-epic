// SPDX-License-Identifier: Apache-2.0
/// Receive in epic1 mode (Receive-5): the epic1 link as a QR with the epic1 mark, Copy link and
/// Share, "Ask for an amount" (a sheet) and "Other ways to receive" (in person).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../amount.dart';
import '../../epic1.dart';
import '../../errors.dart';
import '../../l10n.dart';
import '../../providers.dart';
import '../../slate_files.dart' show slateFilesProvider;
import '../../models.dart' show WalletError, WalletErrorKind;
import '../common.dart';
import '../in_person/in_person_entry.dart';
import '../receive_screen.dart' show ReceiveQr, shareAddress;
import '../kit/kit_button.dart';
import '../kit/kit_chip.dart';
import '../kit/kit_group.dart';
import '../kit/kit_icons.dart';
import '../kit/kit_row.dart';
import '../kit/kit_sheet.dart';
import '../kit/kit_tokens.dart';
import '../settings_sections.dart';
import '../theme/logo_qr.dart';
import '../theme/tokens.dart';
import '../theme/epic1_mark.dart';
import '../tour/tour_target.dart';
import 'epic1_common.dart';

/// Keys for tests and the screenshot tour.
const Key epic1LinkCardKey = ValueKey('epic1-link-card');
const Key epic1QrKey = ValueKey('epic1-qr');
const Key epic1CopyLinkKey = ValueKey('epic1-copy-link');
const Key epic1ShareLinkKey = ValueKey('epic1-share-link');
const Key epic1AskAmountKey = ValueKey('epic1-ask-amount');
const Key epic1AmountFieldKey = ValueKey('epic1-amount-field');
const Key epic1MessageFieldKey = ValueKey('epic1-message-field');
const Key epic1MakeLinkKey = ValueKey('epic1-make-link');
const Key epic1RelaySettingsKey = ValueKey('epic1-relay-settings');
const Key epic1RequestInPersonKey = ValueKey('epic1-request-in-person');

class Epic1ReceiveView extends ConsumerStatefulWidget {
  const Epic1ReceiveView({super.key});

  @override
  ConsumerState<Epic1ReceiveView> createState() => _Epic1ReceiveViewState();
}

class _Epic1ReceiveViewState extends ConsumerState<Epic1ReceiveView> {
  Epic1LinkMade? _link;
  BigInt? _amount;
  Object? _error;
  bool _busy = false;

  /// A local network server was accepted for links on this screen.
  bool _lanOk = false;

  /// The relay the link was made for; a new one is made when the server changes.
  String? _madeFor;

  String? get _relay => epic1OwnRelay(ref)?.label;

  Future<void> _make({BigInt? amount, String? message}) async {
    final epic1 = ref.read(epic1Provider);
    final relay = _relay;
    if (epic1 == null || relay == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final made = await epic1.makeLink(amount: amount, message: message, relays: [relay]);
      if (!mounted) return;
      setState(() {
        _link = made;
        _amount = amount;
        _madeFor = relay;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(String link) =>
      shareAddress(context, ref, address: link, chain: ref.read(walletConfigProvider)?.chain, logo: QrLogo.epic1);

  Future<void> _askAmount() async {
    final asked = await showKitSheet<({BigInt amount, String? message})>(context: context, builder: (_) => const _AskAmountSheet());
    if (asked != null) await _make(amount: asked.amount, message: asked.message);
  }

  Future<void> _settings() => openSettingsSection(context, SettingsSection.privacyNetwork);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final relay = ref.watch(walletConfigProvider.select((c) => c == null ? null : epic1OwnRelay(ref)?.label));
    final place = relay == null ? null : epic1RelayPlace(relay.split(':').first);
    // The server changed since the link was made: a new link for the new one.
    if (relay != null && _madeFor != null && relay != _madeFor && !_busy) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _make();
      });
    }
    final Widget card;
    var linkShown = false;
    if (place == Epic1RelayPlace.thisDevice || _ownRelayError(_error)) {
      card = _Notice(text: l.deskE1ErrOwnRelayLocal, action: l.deskE1PhSettings, actionKey: epic1RelaySettingsKey, onAction: _settings);
    } else if (place == Epic1RelayPlace.localNetwork && !_lanOk) {
      card = _Notice(
        title: l.deskE1PhLanTitle,
        text: l.deskE1PhLanBody(relay!),
        action: l.deskE1PhMakeLink,
        actionKey: epic1MakeLinkKey,
        onAction: () async {
          setState(() => _lanOk = true);
          await _make();
        },
        secondary: l.deskE1PhSettings,
        onSecondary: _settings,
      );
    } else if (_link case final link?) {
      linkShown = true;
      card = _LinkCard(
        link: link.link,
        amount: _amount,
        onCopy: () => copyText(context, link.link, l.deskE1PhLinkCopied),
        onShare: ref.watch(slateFilesProvider).canShareText ? () => _share(link.link) : null,
      );
    } else if (_error case final error?) {
      card = _Notice(text: describeError(l, error), action: l.deskE1PhMakeLink, actionKey: epic1MakeLinkKey, onAction: _make);
    } else {
      if (relay != null && !_busy) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _link == null && _error == null) _make();
        });
      }
      card = const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
    }
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Kit.gutter, 24, Kit.gutter, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PhoneTourTarget(id: 'tour-receive-address', child: card),
                  const SizedBox(height: 22),
                  KitGroup(
                    margin: EdgeInsets.zero,
                    children: [
                      if (linkShown)
                        KitRow(
                          key: epic1AskAmountKey,
                          leading: KitIconWell(KitIcons.invoice),
                          title: l.phoneRecvAsk,
                          subtitle: l.phoneRecvAskLineLink,
                          chevron: true,
                          onTap: _busy ? null : _askAmount,
                        ),
                      KitRow(
                        key: epic1RequestInPersonKey,
                        leading: KitIconWell(KitIcons.qr),
                        title: l.phoneRecvOther,
                        subtitle: l.deskE1PhInPerson,
                        chevron: true,
                        onTap: () => openRequestInPerson(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _ownRelayError(Object? e) => e is WalletError && e.kind == WalletErrorKind.ownRelayLocal;

/// A line in a card with one or two buttons.
class _Notice extends StatelessWidget {
  const _Notice({
    this.title,
    required this.text,
    required this.action,
    required this.onAction,
    this.actionKey,
    this.secondary,
    this.onSecondary,
  });

  final String? title;
  final String text;
  final String action;
  final VoidCallback onAction;
  final Key? actionKey;
  final String? secondary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(Kit.gutter),
      decoration: BoxDecoration(color: t.fill, borderRadius: BorderRadius.circular(Kit.rGroup)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[Text(title!, style: KitType.rowTitle.copyWith(color: t.text)), const SizedBox(height: 6)],
          Text(text, style: KitType.body.copyWith(color: t.dim)),
          const SizedBox(height: 14),
          KitButton(key: actionKey, label: action, onPressed: onAction),
          if (secondary != null) ...[
            const SizedBox(height: 10),
            KitButton(label: secondary!, kind: KitButtonKind.quiet, onPressed: onSecondary),
          ],
        ],
      ),
    );
  }
}

/// The link: its QR with the epic1 mark, the wordmark and what it asks, Copy link and Share.
class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.link, required this.amount, required this.onCopy, required this.onShare});

  final String link;
  final BigInt? amount;
  final VoidCallback onCopy;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Column(
      key: epic1LinkCardKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: epic1QrKey,
          child: ReceiveQr(address: link, semanticsLabel: l.deskE1PhLinkQrLabel, logo: QrLogo.epic1),
        ),
        const SizedBox(height: 22),
        Center(child: Epic1Text(l.deskE1PhLinkTitle, style: KitType.flowTitle.copyWith(color: t.text))),
        const SizedBox(height: 12),
        Center(child: KitChip(amount == null ? l.deskE1PhAnyAmount : l.deskE1PhLinkAsks(epicFor(l, amount!)))),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: KitButton(key: epic1CopyLinkKey, label: l.deskE1PhCopyLink, kind: KitButtonKind.quiet, icon: KitIcons.copy, onPressed: onCopy),
            ),
            if (onShare != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: KitButton(key: epic1ShareLinkKey, label: l.commonShare, icon: KitIcons.share, onPressed: onShare),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        const _ListeningLine(),
      ],
    );
  }
}

/// "Listening for payments" under the buttons, as on Receive.
class _ListeningLine extends StatelessWidget {
  const _ListeningLine();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      container: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: t.ok)),
          ),
          const SizedBox(width: 8),
          Text(context.l10n.phoneRecvListening, style: KitType.rowSub.copyWith(color: t.dim)),
        ],
      ),
    );
  }
}

/// Amount and an optional message for a link that asks an amount.
class _AskAmountSheet extends StatefulWidget {
  const _AskAmountSheet();

  @override
  State<_AskAmountSheet> createState() => _AskAmountSheetState();
}

class _AskAmountSheetState extends State<_AskAmountSheet> {
  final _amount = TextEditingController();
  final _message = TextEditingController();
  String? _amountError;

  @override
  void dispose() {
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  void _done() {
    final l = context.l10n;
    try {
      final amount = parseEpic(_amount.text);
      if (amount == BigInt.zero) throw AmountFormatException(AmountProblem.malformed, (l) => l.amountEnterExample, _amount.text);
      final message = _message.text.trim();
      Navigator.pop(context, (amount: amount, message: message.isEmpty ? null : message));
    } catch (e) {
      setState(() => _amountError = describeError(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: KitSheet(
        title: l.phoneRecvAsk,
        primary: KitButton(key: epic1MakeLinkKey, label: l.deskE1PhMakeLink, onPressed: _done),
        secondary: KitButton(label: l.commonCancel, kind: KitButtonKind.ghost, onPressed: () => Navigator.pop(context)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: epic1AmountFieldKey,
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: InputDecoration(labelText: l.deskE1PhAmount, suffixText: epicUnit, errorText: _amountError),
                onChanged: (_) {
                  if (_amountError != null) setState(() => _amountError = null);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                key: epic1MessageFieldKey,
                controller: _message,
                maxLength: 120,
                decoration: InputDecoration(labelText: l.deskE1PhMessage),
                onSubmitted: (_) => _done(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
