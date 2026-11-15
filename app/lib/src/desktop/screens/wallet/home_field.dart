// SPDX-License-Identifier: Apache-2.0
/// Home's field: a name, an amount, an address or a payment code, typed or pasted, in any order
/// ("4 bt labs", "pay bt labs 5 for lunch", "request 5 from bt labs"). A line under it says what
/// Enter opens: Send or Request, filled in. Nothing is sent from here: Send's own review and
/// password follow. A transaction file and the camera stand beside the field.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../amount.dart' as shared show formatEpic;
import '../../../epic1.dart' show PaymentMode;
import '../../../l10n.dart' show LocalizedFormatException, localDecimal;
import '../../../name_service/payment_refusals.dart' show paymentRefusalsProvider;
import '../../../recipient.dart' show epic1Shaped;
import '../../../scan/scan_checks.dart' show CodeOrigin;
import '../../../scan/scan_router.dart' show classifyScan;
import '../../../send_route.dart';
import '../../../settings_file/host_settings.dart' show appConfig;
import '../../../settings_file/settings_providers.dart' show hostSettingsProvider;
import '../../../smart_outputs.dart';
import '../../../ui/send_route_text.dart' show sendContactedText, sendMethodName, sendProblemText;
import '../../data/pairing_state.dart' show deskContactPairingProvider, deskInvoicesShownProvider, deskPairsProvider;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../invoices/issue_invoice_screen.dart' show RequestArgs, deskRequestPayers;
import '../scan/desk_scan.dart' show DeskScanButton;
import '../scan/desk_scan_route.dart';
import '../transfer/contact_picker.dart' show contactEpic1Link, contactPairsNatively;
import '../transfer/send_screen.dart' show SendArgs;
import 'home_field_parse.dart';

/// The people Home's field can name: the contacts, then the addresses paid before that no
/// contact holds (newest first, each once).
List<HomePerson> homeFieldPeople(List<Contact> contacts, List<Tx> txs, {int pastMax = 30}) {
  final held = {for (final c in contacts) ...c.addresses};
  final sent = [for (final t in txs) if (t.direction == TxDirection.sent && (t.counterparty ?? '').trim().isNotEmpty) t]
    ..sort((a, b) => b.created.compareTo(a.created));
  final seen = <String>{};
  final past = <HomePerson>[];
  for (final t in sent) {
    final a = t.counterparty!.trim();
    if (held.contains(a) || !seen.add(a)) continue;
    past.add(HomePerson.past(a));
    if (past.length >= pastMax) break;
  }
  return [for (final c in contacts) HomePerson.contact(c), ...past];
}

/// Asks Home's field for the focus (Ctrl+K): a count, so every press asks again.
final homeFieldFocusProvider = NotifierProvider<HomeFieldFocus, int>(HomeFieldFocus.new);

class HomeFieldFocus extends Notifier<int> {
  /// The count the field last answered.
  int _answered = 0;

  @override
  int build() => 0;

  void request() => state++;

  /// Whether a press waits for the field, answering it: one press focuses the field once, not
  /// again each time Home is opened after it.
  bool take() {
    if (state == _answered) return false;
    _answered = state;
    return true;
  }
}

/// Ctrl+K outside Settings: Home, with its field focused.
void openHomeField(WidgetRef ref) {
  if (ref.read(deskNavProvider).route != DeskRoute.overview) ref.read(deskNavProvider.notifier).go(DeskRoute.overview);
  ref.read(homeFieldFocusProvider.notifier).request();
}

/// What Enter does for the field as it stands.
class HomeIntent {
  const HomeIntent({required this.line, this.icon, this.detail, this.note, this.problem, this.open});

  /// "Send 5 EPIC to BT Labs".
  final String line;
  final IconData? icon;

  /// The method and host, or what is wrong with the address.
  final String? detail;

  /// The message, then the fee and the balance after.
  final String? note;

  /// Why Enter does nothing; null when it opens something.
  final String? problem;

  /// Opens Send or Request; null when [problem] holds it or nothing matches.
  final Future<void> Function()? open;

  bool get enabled => open != null;
}

class HomeField extends ConsumerStatefulWidget {
  const HomeField({super.key});

  @override
  ConsumerState<HomeField> createState() => _HomeFieldState();
}

class _HomeFieldState extends ConsumerState<HomeField> {
  final _text = TextEditingController();
  late final _focus = FocusNode(debugLabel: 'home-field', onKeyEvent: _key);
  Timer? _timer;

  /// The match Enter takes when several fit.
  int _sel = 0;
  HomeRead _last = HomeRead.blank;

  /// The fee asked for [_feeFor] (null while none, or when the estimate failed).
  int _feeFor = -1;
  SendEstimate? _est;

  /// Everything spendable, minus the fee, as Send's Max works it out; [_maxAt] is the balance it
  /// was asked for.
  SendEstimate? _max;
  int _maxAt = -1;

  @override
  void initState() {
    super.initState();
    // Opened by Ctrl+K: the request came before this field was built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(homeFieldFocusProvider.notifier).take()) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  RecipientInput _readOf(String t) => readRecipient(t, defaultRelay: ref.read(hostSettingsProvider).epicboxUse, listenPort: appConfig.httpListenPort);

  HomeRead _readTyped(String typed, List<HomePerson> people) => readHomeField(
    typed,
    people: people,
    classify: (t) => classifyScan(t, check: deskScanCheck(ref.read(deskApiProvider))),
    read: _readOf,
  );

  List<HomePerson> _people() {
    final st = ref.read(deskProvider);
    return homeFieldPeople(st.contacts ?? const [], st.txs ?? const []);
  }

  /// The amount as typed: nano, or the problem, or both null for none. [max] stands for
  /// everything spendable.
  ({int? nano, String? error, bool max}) _amountOf(HomeRead r) {
    final a = r.amount;
    if (a == null) return (nano: null, error: null, max: false);
    if (a.max) return (nano: _max != null && _maxAt == _spendable ? _max!.amount : null, error: null, max: true);
    final l = context.l10n;
    try {
      final n = parseEpicIn(l, a.text);
      if (n <= 0) return (nano: null, error: l.deskSendErrAmountZero, max: false);
      return (nano: n, error: null, max: false);
    } on AmountFormatException catch (e) {
      return (
        nano: null,
        error: switch (e.problem) {
          AmountProblem.malformed => l.deskSendErrAmountEnter,
          AmountProblem.decimals => l.deskSendErrAmountDecimals,
          AmountProblem.tooLarge => e.text(l),
        },
        max: false,
      );
    } on LocalizedFormatException catch (e) {
      return (nano: null, error: e.text(l), max: false);
    }
  }

  int? get _spendable => ref.read(deskProvider).balance?.spendable;

  void _changed(String _) {
    setState(() => _sel = 0);
    _ask();
  }

  /// Asks for the fee (or the max) of what is typed, once typing pauses.
  void _ask() {
    _timer?.cancel();
    final r = _readTyped(_text.text, _people());
    if (r.verb != HomeVerb.send || r.amount == null) return;
    final a = _amountOf(r);
    if (a.max) {
      final s = _spendable;
      if (s != null && s > 0 && _maxAt != s) _timer = Timer(const Duration(milliseconds: 150), _loadMax);
    } else if (a.nano != null && a.nano != _feeFor) {
      final n = a.nano!;
      _timer = Timer(const Duration(milliseconds: 250), () => unawaited(_loadFee(n)));
    }
  }

  Future<void> _loadMax() async {
    final s = _spendable;
    if (s == null || s <= 0) return;
    SendEstimate? e;
    try {
      e = await ref.read(deskApiProvider).estimateMax();
    } on Object {
      e = null;
    }
    if (!mounted) return;
    setState(() {
      _max = e;
      _maxAt = e == null ? -1 : s;
    });
  }

  /// The fee Send would show: its own plan (strategy, Split change).
  Future<void> _loadFee(int n) async {
    final api = ref.read(deskApiProvider);
    SendEstimate? est;
    try {
      final prefs = ref.read(deskOutputPrefsProvider).value ?? const OutputPrefs();
      int? outputs;
      try {
        final list = ref.read(deskOutputsProvider).value ?? await api.outputs();
        outputs = list.where((o) => o.spendable).length;
      } on Object {
        // Without the list the change is not split.
      }
      final plan = await planSend(
        estimate: (o) => api.estimateSend(n, options: o),
        strategy: prefs.strategy,
        smartOutputsOn: prefs.smartOutputs && outputs != null,
        spendableOutputs: outputs ?? 0,
        splitRefused: deskSplitRefused,
      );
      est = plan.estimate;
    } on Object {
      est = null;
    }
    if (!mounted) return;
    setState(() {
      _est = est;
      _feeFor = est == null ? -1 : n;
    });
  }

  String _amountText(AppLocalizations l, int nano) => epicTextL(l, nano);

  /// Send's To takes the address as Send would pick it for a contact.
  String _bestOf(HomePerson p) {
    final list = p.addresses;
    final i = bestAddressIndex(list, read: _readOf, held: (_) => false);
    return i < 0 ? (list.isEmpty ? '' : list.first) : list[i];
  }

  String _nameOf(HomePerson p) {
    final c = p.contact;
    if (c != null) return c.name;
    return shortAddress(p.name, compact: true);
  }

  /// What Enter does for [r] with [who] chosen.
  HomeIntent? _intentFor(AppLocalizations l, HomeRead r, HomePerson? who) {
    switch (r.kind) {
      case HomeKind.blank:
        return null;
      case HomeKind.none:
        if (r.query.isEmpty) return HomeIntent(line: l.scanPhraseFoundPasted, icon: EIcons.alert, problem: l.scanPhraseFoundPasted);
        return HomeIntent(line: l.deskHomeNoMatch(r.query), icon: EIcons.search, problem: l.deskHomeNoMatch(r.query));
      case HomeKind.code:
        return HomeIntent(
          line: l.deskHomeOpenCode,
          icon: EIcons.send,
          open: () async => _nav(DeskRoute.send, SendArgs(code: r.code, codeOrigin: CodeOrigin.paste)),
        );
      case HomeKind.amount || HomeKind.person || HomeKind.address:
        break;
    }
    final request = r.verb == HomeVerb.request;
    if (request && !ref.read(deskInvoicesShownProvider)) {
      return HomeIntent(line: l.deskHomeRequestOnly, icon: EIcons.request, problem: l.deskHomeRequestsOff, note: l.deskHomeRequestsOff);
    }
    final a = _amountOf(r);
    final spendable = _spendable;
    final name = who != null ? _nameOf(who) : (r.kind == HomeKind.address ? shortAddress(r.address ?? '', compact: true) : null);

    String? label;
    if (a.nano != null) label = a.max ? l.deskHomeMaxAmount(_amountText(l, a.nano!)) : _amountText(l, a.nano!);
    if (a.max && a.nano == null) label = l.deskHomeMaxWord;
    final line = request
        ? (name != null
              ? (label != null ? l.deskHomeRequestFrom(label, name) : l.deskHomeRequestName(name))
              : (label != null ? l.deskHomeRequestAmount(label) : l.deskHomeRequestOnly))
        : (name != null
              ? (label != null ? l.deskHomeSendTo(label, name) : l.deskOvSendTo(name))
              : (label != null ? l.deskHomeSendAmount(label) : l.deskHomeSendOnly));

    // The address: its method and host, or what is wrong with it.
    String? detail;
    String? problem = a.error;
    RecipientInput? rr;
    if (who != null) {
      final addr = _bestOf(who);
      if (addr.isNotEmpty) rr = _readOf(addr);
    } else if (r.kind == HomeKind.address) {
      rr = r.recipient;
    }
    if (r.kind == HomeKind.address && !request) {
      final x = r.recipient!;
      if (r.wrongNetwork) {
        problem ??= l.scanWrongNetworkBody;
        detail = l.scanWrongNetworkBody;
      } else if (x.problem != null) {
        problem ??= sendProblemText(l, x.problem!);
        detail = sendProblemText(l, x.problem!);
      }
    }
    if (detail == null && rr != null && rr.isAddress) {
      detail = [sendMethodName(l, rr), sendContactedText(rr)].where((x) => x.isNotEmpty).join(' · ');
      if (detail.isEmpty) detail = null;
    }

    // What Send would stop on: a contact that takes no payments, and in epic1 mode anything that
    // is not an epic1 link, a paired contact or a contact with an epic1 link.
    if (!request) {
      final epic1 = ref.read(deskPaymentModeProvider) == PaymentMode.epic1;
      final c = who?.contact;
      if (c != null) {
        final pairing = ref.read(deskPairsProvider) ? ref.read(deskContactPairingProvider(c.id)) : null;
        final refusals = ref.read(paymentRefusalsProvider);
        if (refusals.refusesPayments(pairingId: pairing?.id, address: c.epicbox)) {
          problem ??= l.contactNoPaymentsNamed(refusals.refusedName(pairingId: pairing?.id, address: c.epicbox) ?? c.name);
        } else if (epic1) {
          if (contactEpic1Link(ref, c, watch: false) != null) {
            detail = l.deskE1LinkTitle;
          } else if (!contactPairsNatively(ref, c, watch: false)) {
            problem ??= l.deskE1ClassicTip;
          }
        }
      } else if (epic1 && who != null) {
        problem ??= l.deskE1ModeClassicAddress;
      } else if (epic1 && r.kind == HomeKind.address && !epic1Shaped(r.address ?? '')) {
        problem ??= l.deskE1ModeClassicAddress;
      }
    }

    final notes = <String>[];
    if (r.message != null && r.message!.isNotEmpty) notes.add(l.deskHomeMessage(r.message!));
    if (!request && a.nano != null && spendable != null) {
      final est = a.max ? _max : (_feeFor == a.nano ? _est : null);
      final fee = est?.fee;
      final balance = ref.read(deskProvider).balance;
      if (a.max) {
        // Everything spendable goes, the fee included.
      } else if (a.nano! > spendable || (fee != null && a.nano! + fee > spendable)) {
        problem ??= l.deskHomeOver(epicTextL(l, spendable));
      }
      // The same figures as Send's summary: the fee, and the whole balance once the send is done.
      if (problem == null && est != null && balance != null) {
        final sum = SendSummary.of(balance: balance.total, spendable: spendable, estimate: est);
        notes.add(l.deskHomeFee(epicTextL(l, sum.fee), epicTextL(l, sum.balanceAfter)));
      }
    }
    if (request && a.max) problem ??= l.deskSendErrAmountEnter;

    // Request: a paired contact that pays requests is asked; anyone else, no payer yet.
    Object? payer;
    if (request) {
      final c = who?.contact;
      final p = c == null ? null : ref.read(deskContactPairingProvider(c.id));
      if (p != null && deskRequestPayers([p]).isNotEmpty) payer = p.id;
      if (payer == null && name != null) detail = l.deskHomeNotPayer(name);
    }

    return HomeIntent(
      line: line,
      icon: request ? EIcons.request : EIcons.send,
      detail: detail,
      note: notes.isEmpty ? null : notes.join(' · '),
      problem: problem,
      open: problem != null ? null : () => _open(r, who, payer),
    );
  }

  void _nav(DeskRoute route, Object? args) {
    _text.clear();
    setState(() => _sel = 0);
    ref.read(deskNavProvider.notifier).go(route, args);
  }

  Future<void> _open(HomeRead r, HomePerson? who, Object? payer) async {
    final l = context.l10n;
    final a = _amountOf(r);
    var nano = a.nano;
    if (a.max && (nano == null || r.verb == HomeVerb.send)) {
      // Everything spendable: epic1's page has no Max, so it gets the figure; the classic form
      // works it out as its own button does.
      if (ref.read(deskPaymentModeProvider) == PaymentMode.epic1 && (nano == null)) {
        try {
          nano = (await ref.read(deskApiProvider).estimateMax()).amount;
        } on Object {
          nano = null;
        }
        if (!mounted) return;
      }
    }
    String? amount;
    if (nano != null && nano > 0) amount = localDecimal(l, shared.formatEpic(BigInt.from(nano)));
    final all = a.max && ref.read(deskPaymentModeProvider) != PaymentMode.epic1;
    final message = r.message;
    if (r.verb == HomeVerb.request) {
      _nav(DeskRoute.invoiceIssue, RequestArgs(to: payer, amount: amount, message: message));
      return;
    }
    switch (r.kind) {
      case HomeKind.person:
        final c = who?.contact;
        if (c != null) {
          _nav(DeskRoute.send, SendArgs(contact: c, amount: all ? null : amount, message: message, all: all));
        } else if (who != null) {
          _nav(DeskRoute.send, SendArgs(recipient: who.addresses.first, amount: all ? null : amount, message: message, all: all));
        }
      case HomeKind.address:
        _nav(DeskRoute.send, SendArgs(recipient: r.address, amount: all ? null : amount, message: message, all: all));
      case HomeKind.amount:
        final empty = amount == null && !all && message == null;
        _nav(DeskRoute.send, empty ? null : SendArgs(amount: all ? null : amount, message: message, all: all));
      case HomeKind.code || HomeKind.none || HomeKind.blank:
        break;
    }
  }

  /// Enter: opens what the line says; nothing when it says why not.
  void _go(String typed) {
    final r = _readTyped(typed, _people());
    final people = r.matches;
    final who = people.isEmpty ? null : people[_sel.clamp(0, people.length - 1)];
    final i = _intentFor(context.l10n, r, who);
    if (i == null || !i.enabled) return;
    unawaited(i.open!());
  }

  /// ↑ ↓ choose among the matches, Tab writes the chosen name, Esc clears.
  KeyEventResult _key(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final r = _last;
    final key = e.logicalKey;
    if ((key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) && r.kind == HomeKind.person && r.matches.length > 1) {
      final n = r.matches.length;
      setState(() => _sel = (_sel + (key == LogicalKeyboardKey.arrowDown ? 1 : n - 1)) % n);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab && !HardwareKeyboard.instance.isShiftPressed && r.kind == HomeKind.person && r.nameStart >= 0 && r.matches.isNotEmpty) {
      final who = r.matches[_sel.clamp(0, r.matches.length - 1)];
      final typed = homeClean(_text.text);
      final name = who.contact?.name ?? who.name;
      final done = typed.replaceRange(r.nameStart, r.nameEnd, name);
      if (done == typed) return KeyEventResult.ignored;
      _text.value = TextEditingValue(text: done, selection: TextSelection.collapsed(offset: done.length));
      _changed(done);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && _text.text.isNotEmpty) {
      _text.clear();
      _changed('');
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = ref.read(deskNavProvider.notifier);
    ref.listen(homeFieldFocusProvider, (_, _) {
      if (ref.read(homeFieldFocusProvider.notifier).take()) _focus.requestFocus();
    });
    // The contacts, the past payments and the balance move the line with them.
    ref.watch(deskProvider.select((s) => (s.contacts, s.txs, s.balance?.spendable)));
    ref.watch(deskInvoicesShownProvider);
    final people = _people();
    final r = _readTyped(_text.text, people);
    _last = r;
    final sel = r.matches.isEmpty ? 0 : _sel.clamp(0, r.matches.length - 1);
    final who = r.matches.isEmpty ? null : r.matches[sel];
    final intent = _intentFor(l, r, who);
    // The page's one place to type: taller than a form's field, as the canvas draws it.
    final field = ConstrainedBox(
      constraints: BoxConstraints(minHeight: 58.u),
      child: EInput(
        key: const ValueKey('home-field'),
        controller: _text,
        focusNode: _focus,
        onChanged: _changed,
        leading: EIcons.search,
        hint: l.deskOvFieldHint,
        semanticLabel: l.deskOvFieldHint,
        onSubmitted: _go,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EIconButton(icon: EIcons.file, label: l.deskOvReceiveFile, size: EBtnSize.inline, onPressed: () => nav.go(DeskRoute.importTx)),
            DeskScanButton(key: const ValueKey('home-field-scan'), onScan: () => unawaited(openDeskScan(context, ref))),
          ],
        ),
      ),
    );
    final c = context.dc;
    final ts = context.ts;
    // What Enter opens, under the field, and the other people the typing names: a click opens
    // one. The field stays the Column's first child with or without them: a field moved to
    // another parent is built anew, and the new one never takes the keyboard back, so typing
    // stopped there.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        if (intent != null) ...[
          SizedBox(height: Sp.x1),
          EPanel(
            key: const ValueKey('home-field-matches'),
            padding: EdgeInsets.all(Sp.x1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _row(c, ts, intent, key: const ValueKey('home-field-preview'), who: who),
                for (var i = 0; i < r.matches.length; i++)
                  if (i != sel)
                    _row(c, ts, _intentFor(l, r, r.matches[i])!, key: ValueKey('home-field-match-${r.matches[i].id}'), who: r.matches[i], other: true),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(DeskColors c, DeskText ts, HomeIntent i, {required Key key, HomePerson? who, bool other = false}) {
    final warn = i.problem != null;
    return EInkWell(
      key: key,
      onTap: i.enabled ? () => unawaited(i.open!()) : null,
      borderRadius: BorderRadius.circular(Rad.sm),
      hoverColor: c.hover,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
        child: Row(
          children: [
            if (who != null && other) EAvatar(_nameOf(who), size: 28.u) else Icon(i.icon ?? EIcons.send, size: Ctl.iconSm, color: warn ? c.warn : c.accentText),
            SizedBox(width: Sp.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i.line, style: ts.strong.copyWith(color: warn && !i.enabled && i.detail == null ? c.dim : null), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (i.detail != null) Text(i.detail!, key: other ? null : const ValueKey('home-field-detail'), style: ts.small.copyWith(color: i.problem != null ? c.warn : c.dim), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (i.problem != null && i.problem != i.detail && i.problem != i.line) Text(i.problem!, key: other ? null : const ValueKey('home-field-problem'), style: ts.small.copyWith(color: c.warn), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (i.note != null) Text(i.note!, key: other ? null : const ValueKey('home-field-note'), style: ts.small, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (i.enabled) Icon(EIcons.chevronRight, size: Ctl.iconSm, color: c.faint),
          ],
        ),
      ),
    );
  }
}
