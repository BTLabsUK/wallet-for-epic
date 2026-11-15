// SPDX-License-Identifier: Apache-2.0
/// Paying an epic1 link (spec P2): read, "Send through this server?", Review, Waiting for the
/// recipient, Sent.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../amount.dart';
import '../../devices/phone_devices.dart' show deviceServiceProvider;
import '../../epic1.dart';
import '../../errors.dart';
import '../../l10n.dart';
import '../../models.dart';
import '../../providers.dart';
import '../../recipient.dart' show epic1Unwrap;
import '../app_dialog.dart';
import '../common.dart';
import '../pin.dart' show showPinSheet, usesPassphrase;
import '../theme/tokens.dart';
import '../tip.dart';
import '../kit/kit_ground.dart' show KitGround;
import 'epic1_common.dart';

/// Keys for tests and the screenshot tour.
const Key epic1FieldSettingsKey = ValueKey('epic1-field-settings');
/// The "No address?" sheet's Pay in person row (an epic1 in-person code).
const Key epic1PayInPersonKey = ValueKey('epic1-pay-in-person');
const Key epic1UseServerKey = ValueKey('epic1-use-server');
const Key epic1ReviewServerKey = ValueKey('epic1-review-server');
const Key epic1ReviewAmountKey = ValueKey('epic1-review-amount');
const Key epic1SendButtonKey = ValueKey('epic1-send-button');
const Key epic1WaitingKey = ValueKey('epic1-waiting');
const Key epic1TryNextKey = ValueKey('epic1-try-next');
const Key epic1CancelUnlockKey = ValueKey('epic1-cancel-unlock');
const Key epic1SentKey = ValueKey('epic1-sent');
const Key epic1DoneKey = ValueKey('epic1-done');

/// Pays the epic1 [link]: true when it was sent and Done pressed.
Future<bool> openEpic1LinkSend(BuildContext context, String link) async {
  final done = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(builder: (_) => Epic1LinkSendScreen(link: epic1Unwrap(link.trim()))),
  );
  return done == true;
}

enum _Stage { reading, review, waiting, sent, cancelled }

class Epic1LinkSendScreen extends ConsumerStatefulWidget {
  const Epic1LinkSendScreen({super.key, required this.link});

  final String link;

  @override
  ConsumerState<Epic1LinkSendScreen> createState() => _Epic1LinkSendScreenState();
}

class _Epic1LinkSendScreenState extends ConsumerState<Epic1LinkSendScreen> {
  _Stage _stage = _Stage.reading;
  Epic1LinkInfo? _info;
  Epic1Payment? _payment;
  Object? _error;
  bool _busy = false;

  /// The review showed the link's server, and "Use server" was pressed for one not in the
  /// server list: LEPIC pays only with this true.
  bool _hostsOk = false;
  final _amount = TextEditingController();
  String? _amountError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _read());
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _read() async {
    final l = context.l10n;
    final epic1 = ref.read(epic1Provider);
    if (epic1 == null) return;
    try {
      final info = await epic1.readLink(widget.link);
      if (!mounted) return;
      final unknown = info.hosts.where((h) => !h.inRelayList).toList();
      if (unknown.isNotEmpty) {
        final use = await askEpic1(
          context,
          title: l.deskE1PhUnknownTitle,
          body: l.deskE1PhUnknownBody(unknown.first.host),
          yes: l.deskE1PhUseServer,
          icon: Icons.dns_outlined,
          tone: DialogTone.warn,
          yesKey: epic1UseServerKey,
        );
        if (!mounted) return;
        if (!use) {
          Navigator.pop(context, false);
          return;
        }
      }
      setState(() {
        _hostsOk = true;
        _info = info;
        _stage = _Stage.review;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  BigInt? _amountToPay() {
    final asked = _info?.amount;
    if (asked != null) return asked;
    try {
      final a = parseEpic(_amount.text);
      if (a == BigInt.zero) throw AmountFormatException(AmountProblem.malformed, (l) => l.amountEnterExample, _amount.text);
      return a;
    } catch (e) {
      setState(() => _amountError = describeError(context.l10n, e));
      return null;
    }
  }

  /// Every send asks the PIN right before money moves, as the classic Send does.
  Future<bool> _pinGate(BigInt amount) async {
    final l = context.l10n;
    final session = ref.read(sessionProvider);
    final config = ref.read(walletConfigProvider);
    if (session == null || config == null) return false;
    final vault = ref.read(vaultProvider);
    final text = epicText(l, amount);
    final ok = await showPinSheet<bool>(
      context,
      reason: usesPassphrase(ref) ? l.sendPassphraseReason(text) : l.sendPinReason(text),
      action: (pin) async {
        await vault.checkPin(session, config, pin);
        return true;
      },
    );
    return ok == true && mounted;
  }

  Future<void> _send() async {
    final epic1 = ref.read(epic1Provider);
    final amount = _amountToPay();
    if (epic1 == null || amount == null || _busy) return;
    final total = _info?.amount ?? amount;
    if (!await _pinGate(total)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final payment = await epic1.payLink(
        link: widget.link,
        amount: _info?.amount == null ? amount : null,
        minimumConfirmations: ref.read(countedConfirmationsProvider),
        hostsOk: _hostsOk,
      );
      ref.invalidate(homeProvider);
      if (!mounted) return;
      setState(() {
        _payment = payment;
        _stage = _Stage.waiting;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _tryNext() async {
    final epic1 = ref.read(epic1Provider);
    final payment = _payment;
    if (epic1 == null || payment == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final next = await epic1.postNext(slateId: payment.slateId, hostsOk: _hostsOk);
      if (mounted) setState(() => _payment = next);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final session = ref.read(sessionProvider);
    final payment = _payment;
    if (session == null || payment == null || _busy) return;
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.cancelTransaction(txId: payment.txId);
      // The linked devices free its coins at once, not at the next tick.
      unawaited(container.read(deviceServiceProvider)?.announceNow());
      container.invalidate(homeProvider);
      if (mounted) setState(() => _stage = _Stage.cancelled);
    } catch (e) {
      container.invalidate(homeProvider);
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Waiting turns into Sent when the recipient's answer moved the payment on.
    if (_stage == _Stage.waiting && _payment != null) {
      final tx = ref.watch(homeProvider.select((h) => h.value?.transactions.where((t) => t.id == _payment!.txId).firstOrNull));
      if (tx != null && tx.status != TxStatus.awaitingRecipient) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _stage == _Stage.waiting) {
            setState(() => _stage = tx.status == TxStatus.cancelled ? _Stage.cancelled : _Stage.sent);
          }
        });
      }
    }
    final (title, children, bottom) = switch (_stage) {
      _Stage.reading => (l.deskE1PhReview, _reading(context), null),
      _Stage.review => (l.deskE1PhReview, _review(context), _reviewAction(context)),
      _Stage.waiting => (l.homeSendButton, _waiting(context), _waitingAction(context)),
      _Stage.sent => (l.deskE1PhSent, _end(context, sent: true), _doneAction(context)),
      _Stage.cancelled => (l.deskE1PhCancelled, _end(context, sent: false), _doneAction(context)),
    };
    return PopScope(
      // A payment on its way is left with Done or Cancel and unlock, never by Back.
      canPop: _stage == _Stage.reading || _stage == _Stage.review,
      child: KitGround(child: Scaffold(
        appBar: AppBar(title: Text(title), automaticallyImplyLeading: _stage == _Stage.reading || _stage == _Stage.review),
        body: SafeArea(
          child: ScreenBody(
            bottom: bottom,
            children: [
              ...children,
              if (_error case final e?) ...[const SizedBox(height: 12), ErrorText(describeError(l, e))],
            ],
          ),
        ),
      )),
    );
  }

  List<Widget> _reading(BuildContext context) => [
    if (_error == null) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
  ];

  Widget _row(BuildContext context, String label, Widget value, {Key? key}) {
    final t = context.tokens;
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: t.dim)),
          const SizedBox(height: 2),
          value,
        ],
      ),
    );
  }

  Widget _mono(BuildContext context, String text, {String? whole}) {
    final w = Text(text, style: TextStyle(fontFamily: context.tokens.monoFamily));
    return whole == null ? w : Tip.value(whole, child: w);
  }

  String? get _host => _payment?.postedHost ?? _info?.hosts.firstOrNull?.host;

  List<Widget> _review(BuildContext context) {
    final l = context.l10n;
    final info = _info!;
    final theme = Theme.of(context);
    return [
      _row(context, l.deskE1PhTo, _mono(context, shortAddress(info.address), whole: info.address)),
      if (info.amount case final amount?)
        _row(context, l.deskE1PhAmount, Text(epicFor(l, amount), style: theme.textTheme.titleLarge), key: epic1ReviewAmountKey)
      else
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextField(
            key: epic1ReviewAmountKey,
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(labelText: l.deskE1PhAmount, suffixText: epicUnit, errorText: _amountError),
            onChanged: (_) => setState(() => _amountError = null),
          ),
        ),
      if (info.message case final message? when message.isNotEmpty)
        _row(context, l.deskE1PhNote, Text('“$message”', style: const TextStyle(fontStyle: FontStyle.italic))),
      if (_host case final host?) _row(context, l.deskE1PhServer, _mono(context, host), key: epic1ReviewServerKey),
    ];
  }

  Widget _reviewAction(BuildContext context) => BusyButton(
    key: epic1SendButtonKey,
    label: context.l10n.deskE1PhSend,
    busy: _busy,
    onPressed: _busy ? null : _send,
  );

  List<Widget> _waiting(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final payment = _payment!;
    final notTaken = payment.posted == null;
    return [
      Row(
        key: epic1WaitingKey,
        children: [
          if (notTaken) Icon(Icons.cloud_off_outlined, color: t.dim) else const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Expanded(child: Text(l.deskE1PhWaiting, style: Theme.of(context).textTheme.titleMedium)),
        ],
      ),
      const SizedBox(height: 12),
      _row(context, l.deskE1PhTo, _mono(context, shortAddress(payment.address), whole: payment.address)),
      if (_info?.amount ?? _amountOrNull() case final amount?) _row(context, l.deskE1PhAmount, Text(epicFor(l, amount))),
      if (_host case final host?) _row(context, l.deskE1PhServer, _mono(context, host), key: epic1ReviewServerKey),
      if (notTaken && payment.attempts.isNotEmpty) Text(l.deskE1PhNotTaken(payment.attempts.last.host), style: TextStyle(color: t.dim)),
    ];
  }

  BigInt? _amountOrNull() {
    try {
      return parseEpic(_amount.text);
    } catch (_) {
      return null;
    }
  }

  Widget _waitingAction(BuildContext context) {
    final l = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_payment?.posted == null) ...[
          FilledButton(
            key: epic1TryNextKey,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: _busy ? null : _tryNext,
            child: Text(l.deskE1PhTryNext),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton(
          key: epic1CancelUnlockKey,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          onPressed: _busy ? null : _cancel,
          child: Text(l.deskE1PhCancelUnlock),
        ),
      ],
    );
  }

  List<Widget> _end(BuildContext context, {required bool sent}) {
    final l = context.l10n;
    final t = context.tokens;
    return [
      const SizedBox(height: 24),
      Icon(sent ? Icons.check_circle : Icons.undo, key: sent ? epic1SentKey : null, size: 48, color: sent ? t.accentText : t.dim),
      const SizedBox(height: 12),
      Text(sent ? l.deskE1PhSent : l.deskE1PhCancelled, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
    ];
  }

  Widget _doneAction(BuildContext context) => FilledButton(
    key: epic1DoneKey,
    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    onPressed: () => Navigator.pop(context, _stage == _Stage.sent),
    child: Text(context.l10n.deskE1PhDone),
  );
}
