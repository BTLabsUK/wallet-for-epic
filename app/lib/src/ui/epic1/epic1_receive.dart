// SPDX-License-Identifier: Apache-2.0
/// Receive in epic1 mode (spec P4): the epic1 link card (QR covered until tapped, the link
/// shortened in the middle, Copy link, Share, Ask an amount) and "Other ways to receive".
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../amount.dart';
import '../../epic1.dart';
import '../../errors.dart';
import '../../l10n.dart';
import '../../providers.dart';
import '../../settings.dart' show autoLockHoldProvider;
import '../../slate_files.dart' show slateFilesProvider;
import '../../models.dart' show WalletError, WalletErrorKind;
import '../app_dialog.dart';
import '../common.dart';
import '../in_person/in_person_entry.dart';
import '../phone_sheet.dart';
import '../settings_sections.dart';
import '../theme/brand.dart' show MarkedQr;
import '../theme/protocol.dart' show CornerTicksPainter;
import '../theme/tokens.dart';
import '../tip.dart';
import '../tour/tour_target.dart';
import 'epic1_common.dart';

/// Keys for tests and the screenshot tour.
const Key epic1LinkCardKey = ValueKey('epic1-link-card');
const Key epic1QrCoverKey = ValueKey('epic1-qr-cover');
const Key epic1QrKey = ValueKey('epic1-qr');
const Key epic1LinkTextKey = ValueKey('epic1-link-text');
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
  bool _covered = true;

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
        _covered = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(String link) async {
    final files = ref.read(slateFilesProvider);
    await ref.read(autoLockHoldProvider.notifier).during(() => files.shareText(link));
  }

  Future<void> _askAmount() async {
    final asked = await showPhoneSheet<({BigInt amount, String? message})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AskAmountSheet(),
    );
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
      card = _LinkCard(
        link: link.link,
        amount: _amount,
        covered: _covered,
        onCover: (covered) => setState(() => _covered = covered),
        onCopy: () => copyText(context, link.link, l.deskE1PhLinkCopied),
        onShare: ref.watch(slateFilesProvider).canShareText ? () => _share(link.link) : null,
        onAskAmount: _busy ? null : _askAmount,
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        PhoneTourTarget(id: 'tour-receive-address', child: card),
        const SizedBox(height: 8),
        SettingsHeader(l.deskE1PhOtherWays),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.handshake_outlined),
          title: Text(l.deskE1PhInPerson),
          trailing: TextButton(
            key: epic1RequestInPersonKey,
            onPressed: () => openRequestInPerson(context),
            child: Text(l.deskE1PhRequestInPerson),
          ),
        ),
      ],
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
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[Text(title!, style: theme.textTheme.titleMedium), const SizedBox(height: 8)],
            Text(text),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (secondary != null) TextButton(onPressed: onSecondary, child: Text(secondary!)),
                FilledButton(key: actionKey, onPressed: onAction, child: Text(action)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.link,
    required this.amount,
    required this.covered,
    required this.onCover,
    required this.onCopy,
    required this.onShare,
    required this.onAskAmount,
  });

  final String link;
  final BigInt? amount;
  final bool covered;
  final ValueChanged<bool> onCover;
  final VoidCallback onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onAskAmount;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    return Card(
      key: epic1LinkCardKey,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.deskE1PhLinkTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              amount == null ? l.deskE1PhAnyAmount : l.deskE1PhLinkAsks(epicFor(l, amount!)),
              style: TextStyle(color: t.dim),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, box) {
                final size = (box.maxWidth - 56).clamp(120.0, 220.0);
                return covered ? _QrCover(size: size, onShow: () => onCover(false)) : _LinkQr(link: link, size: size, onHide: () => onCover(true));
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: Tip.value(
                link,
                child: Text(
                  shortMiddle(link, keep: 34),
                  key: epic1LinkTextKey,
                  style: TextStyle(fontFamily: t.monoFamily, color: t.dim),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(key: epic1CopyLinkKey, icon: const Icon(Icons.copy), label: Text(l.deskE1PhCopyLink), onPressed: onCopy),
                if (onShare != null)
                  OutlinedButton.icon(key: epic1ShareLinkKey, icon: const Icon(Icons.share_outlined), label: Text(l.commonShare), onPressed: onShare),
                OutlinedButton.icon(
                  key: epic1AskAmountKey,
                  icon: const Icon(Icons.request_quote_outlined),
                  label: Text(l.deskE1PhAskAmount),
                  onPressed: onAskAmount,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The QR's place until tapped: an eye and "Show QR".
class _QrCover extends StatelessWidget {
  const _QrCover({required this.size, required this.onShow});

  final double size;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final side = size + 56;
    return Center(
      child: Semantics(
        button: true,
        label: l.qrShow,
        excludeSemantics: true,
        child: Material(
          color: t.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t.radiusSmall),
            side: BorderSide(color: t.line),
          ),
          child: InkWell(
            key: epic1QrCoverKey,
            borderRadius: BorderRadius.circular(t.radiusSmall),
            onTap: onShow,
            child: SizedBox.square(
              dimension: side,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_outlined, color: t.accentText, size: 32),
                  const SizedBox(height: 8),
                  Text(l.qrShow, style: TextStyle(color: t.accentText)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The link as a QR with the mark, framed as Receive frames the address; a tap covers it.
class _LinkQr extends StatelessWidget {
  const _LinkQr({required this.link, required this.size, required this.onHide});

  final String link;
  final double size;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    return Center(
      child: GestureDetector(
        key: epic1QrKey,
        onTap: onHide,
        child: CustomPaint(
          foregroundPainter: CornerTicksPainter(t.tick, length: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Dark modules on white scan reliably in either theme.
                color: protocolLight.surface,
                borderRadius: BorderRadius.circular(t.radiusSmall),
              ),
              child: Semantics(label: l.deskE1PhLinkQrLabel, image: true, child: MarkedQr(data: link, size: size)),
            ),
          ),
        ),
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
      padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.deskE1PhAskAmount, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
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
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                DialogButton.secondary(label: l.commonCancel, onPressed: () => Navigator.pop(context)),
                DialogButton.primary(key: epic1MakeLinkKey, label: l.deskE1PhMakeLink, onPressed: _done),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
