import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models.dart' show nothingToConsolidate;
import '../../data/lepic_desk_wallet.dart' show deskErrorText;
import '../../widgets/kit.dart';

/// Where a Split or Consolidate dialog is.
enum SelfSendPhase { choose, posting, done, notPosted, failed }

/// Opens a dialog at a phase with made-up figures (the screenshot tour).
class SelfSendDemo {
  const SelfSendDemo(this.phase, {this.outputs = 4, this.txId = 44});

  final SelfSendPhase phase;
  final int outputs;

  /// The send [SelfSendPhase.notPosted] posts again or cancels.
  final int txId;
}

/// Split outputs (F13): asks how many, shows the fee, posts it. Returns when closed; the
/// caller reloads the outputs and the balance.
Future<void> showSplitDialog(BuildContext context, {SelfSendDemo? demo}) =>
    showEDialog<void>(context, dismissible: false, builder: (_) => _SelfSendDialog(split: true, demo: demo));

/// Consolidate outputs (F13). [spendableCount] of 1 shows why there is nothing to do.
Future<void> showConsolidateDialog(BuildContext context, {int? spendableCount, SelfSendDemo? demo}) => showEDialog<void>(
  context,
  dismissible: false,
  builder: (_) => spendableCount == 1 ? const _NothingToConsolidate() : _SelfSendDialog(split: false, demo: demo),
);

/// Each split output must be at least this.
const int _minEach = nanoPerEpic ~/ 2;

const String _network = 'A normal network transaction to this wallet, confirmed after 3 blocks like any send; everything spendable is locked until then.';

class _SelfSendDialog extends ConsumerStatefulWidget {
  const _SelfSendDialog({required this.split, this.demo});

  final bool split;
  final SelfSendDemo? demo;

  @override
  ConsumerState<_SelfSendDialog> createState() => _SelfSendDialogState();
}

class _SelfSendDialogState extends ConsumerState<_SelfSendDialog> {
  late int _n = widget.demo?.outputs ?? 4;
  SendEstimate? _est;
  String? _estError;
  bool _notEnough = false;
  bool _estimating = true;
  late SelfSendPhase _phase = widget.demo?.phase ?? SelfSendPhase.choose;
  SelfSend? _sent;
  late int? _txId = widget.demo?.phase == SelfSendPhase.notPosted ? widget.demo!.txId : null;
  String? _error;
  bool _busy = false;
  Timer? _debounce;
  int _asked = 0;

  bool get _split => widget.split;

  int get _count => _split ? _n : 1;

  @override
  void initState() {
    super.initState();
    _estimate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _estimate() async {
    final ask = ++_asked;
    setState(() => _estimating = true);
    final api = ref.read(deskApiProvider);
    try {
      final e = await (_split ? api.estimateSplit(_n) : api.estimateConsolidate());
      if (!mounted || ask != _asked) return;
      setState(() {
        _est = e;
        _estError = null;
        _notEnough = false;
        _estimating = false;
      });
    } on Object catch (e) {
      if (!mounted || ask != _asked) return;
      final text = deskErrorText(e);
      setState(() {
        _est = null;
        _estError = text;
        _notEnough = text == 'Not enough funds';
        _estimating = false;
      });
    }
  }

  void _setN(int n) {
    if (n == _n) return;
    setState(() => _n = n);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), _estimate);
  }

  /// About each new output: what the spent ones hold less the fee, shared out.
  int? get _each => _est == null ? null : (_est!.locked - _est!.fee) ~/ _count;

  bool get _tooSmall => _notEnough || (_split && _each != null && _each! < _minEach);

  /// LEPIC found fewer than two spendable outputs: nothing to merge, not an error.
  bool get _nothing => !_split && (_estError == nothingToConsolidate || _error == nothingToConsolidate);

  bool get _canGo => _phase == SelfSendPhase.choose && _est != null && !_tooSmall && !_estimating;

  Future<void> _go() async {
    if (!_canGo) return;
    setState(() {
      _phase = SelfSendPhase.posting;
      _busy = true;
    });
    final api = ref.read(deskApiProvider);
    try {
      final s = await (_split ? api.splitOutputs(_n) : api.consolidateOutputs());
      if (!mounted) return;
      setState(() {
        _sent = s;
        _phase = SelfSendPhase.done;
      });
    } on DeskError catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.notPostedTx != null) {
          _txId = e.notPostedTx;
          _phase = SelfSendPhase.notPosted;
        } else {
          _error = e.message;
          _phase = SelfSendPhase.failed;
        }
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = deskErrorText(e);
        _phase = SelfSendPhase.failed;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _repost() async {
    final id = _txId;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(deskApiProvider).repostTx(id);
      if (!mounted) return;
      setState(() => _phase = SelfSendPhase.done);
    } on Object catch (e) {
      if (mounted) showEToast(context, 'Not posted', text: deskErrorText(e), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelIt() async {
    final id = _txId;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(deskProvider.notifier).cancelTx(id);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showEToast(context, 'Not cancelled', text: deskErrorText(e), tone: ETone.risk);
    }
  }

  String _e4(int nano) => formatEpic(nano, decimals: 4);

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    final word = _split ? 'split' : 'consolidate';
    final e = _est;
    final each = _each;
    final bold = TextStyle(color: c.text, fontWeight: FontWeight.w600);

    final paragraph = e == null
        ? null
        : Text.rich(
            TextSpan(
              children: _split
                  ? [
                      const TextSpan(text: 'Spends '),
                      TextSpan(text: '${e.inputCount} ${e.inputCount == 1 ? 'output' : 'outputs'} (${formatEpic(e.locked)} EPIC)', style: bold),
                      const TextSpan(text: ' and makes '),
                      TextSpan(text: '$_n outputs of about ${_e4(each!)} EPIC', style: bold),
                      const TextSpan(text: ' each. $_network'),
                    ]
                  : [
                      const TextSpan(text: 'Spends '),
                      TextSpan(text: '${e.inputCount} outputs (${formatEpic(e.locked)} EPIC)', style: bold),
                      const TextSpan(text: ' and makes '),
                      TextSpan(text: 'one output of ${formatEpic(e.locked - e.fee)} EPIC', style: bold),
                      const TextSpan(text: '. $_network The next send spends one output, so its fee is the smallest.'),
                    ],
            ),
            style: ts.bodyDim,
          );

    final facts = e == null
        ? null
        : EFacts([
            ('Network fee', Text('${formatEpic(e.fee, minDecimals: 3)} EPIC')),
            if (_split) ('Each output', Text('about ${_e4(each!)} EPIC')),
            ('Locked', Text('${formatEpic(e.locked)} EPIC, about 3 blocks. Nothing stays spendable.')),
          ]);

    final List<Widget> body;
    final List<Widget> actions;
    if (_nothing && (_phase == SelfSendPhase.choose || _phase == SelfSendPhase.failed)) {
      return const _NothingToConsolidate(several: true);
    }
    switch (_phase) {
      case SelfSendPhase.choose:
        body = [
          ?paragraph,
          if (_split) ...[
            SizedBox(height: Sp.x4),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text('Outputs to make', style: ts.strong), Text('2 to 10.', style: ts.small)],
                  ),
                ),
                EStepper(value: _n, min: 2, max: 10, onChanged: _setN, label: 'Outputs to make'),
              ],
            ),
          ],
          SizedBox(height: Sp.x3),
          if (facts != null)
            facts
          else if (_estimating)
            Row(children: [const ESpinner(), SizedBox(width: Sp.x3), Text('Working out the fee', style: ts.bodyDim)])
          else if (!_notEnough && !_nothing)
            ENotice(title: 'No estimate', text: _estError, tone: ETone.risk),
          if (_tooSmall) ...[
            SizedBox(height: Sp.x2),
            Semantics(
              liveRegion: true,
              child: Text(_split ? 'Each output must be at least 0.5 EPIC.' : 'Not enough to pay the fee.', style: ts.small.copyWith(color: c.warn)),
            ),
          ],
        ];
        actions = [
          EButton(label: 'Cancel', size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop()),
          EButton.primary(
            label: _split ? 'Split into $_n' : 'Consolidate',
            icon: _split ? EIcons.split : EIcons.merge,
            size: EBtnSize.sm,
            onPressed: _canGo ? _go : null,
          ),
        ];
      case SelfSendPhase.posting:
        body = [
          if (paragraph != null) ...[paragraph, SizedBox(height: Sp.x3)],
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                const ESpinner(),
                SizedBox(width: Sp.x3),
                Expanded(child: Text('Building and posting the $word. Keep the app open.', style: ts.body)),
              ],
            ),
          ),
        ];
        actions = const [];
      case SelfSendPhase.done:
        final n = _sent?.outputCount ?? _count;
        // The split's outputs share what was spent less the fee; a consolidate makes one.
        final perOne = e == null ? (_sent?.amount ?? 0) : (e.locked - e.fee) ~/ n;
        body = [
          ENotice(
            tone: ETone.ok,
            icon: EIcons.okCircle,
            title: _split ? 'Split posted' : 'Consolidate posted',
            text: _split
                ? 'The wallet now has $n outputs of about ${_e4(perOne)} EPIC, confirming. Everything is locked until they confirm (3 blocks). Activity shows two entries: a send and a receive, both to this wallet.'
                : 'One output of ${formatEpic(perOne)} EPIC, confirming. Everything is locked until it confirms (3 blocks). Activity shows two entries: a send and a receive, both to this wallet.',
          ),
        ];
        actions = [EButton.primary(label: 'Done', size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop())];
      case SelfSendPhase.notPosted:
        body = [
          ENotice(
            tone: ETone.risk,
            title: 'Not posted.',
            text: 'The $word was built and stored, but the node did not take it. Post it again, or cancel it to unlock the outputs.',
          ),
        ];
        actions = [
          EButton(label: 'Cancel the $word', size: EBtnSize.sm, onPressed: _busy ? null : _cancelIt),
          EButton.primary(label: 'Post again', icon: EIcons.refresh, size: EBtnSize.sm, busy: _busy, onPressed: _busy ? null : _repost),
        ];
      case SelfSendPhase.failed:
        body = [ENotice(tone: ETone.risk, title: 'Not done', text: '${_error ?? 'Something went wrong'}. The outputs are unchanged.')];
        actions = [
          EButton(label: 'Close', size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop()),
          EButton.primary(
            label: 'Try again',
            size: EBtnSize.sm,
            onPressed: () {
              setState(() => _phase = SelfSendPhase.choose);
              _estimate();
            },
          ),
        ];
    }

    final busy = _phase == SelfSendPhase.posting || _busy;
    return PopScope(
      canPop: !busy,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): () {
            if (_canGo) _go();
          },
        },
        child: Focus(
          autofocus: true,
          child: EDialog(
            title: _split ? 'Split outputs' : 'Consolidate outputs',
            icon: _split ? EIcons.split : EIcons.merge,
            description: switch (_phase) {
              SelfSendPhase.posting => 'Posting.',
              SelfSendPhase.done => 'Done.',
              _ => _split ? 'More outputs, so several sends can follow each other.' : 'One output instead of many.',
            },
            dismissible: !busy,
            width: 520.u,
            body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: body),
            actions: actions,
          ),
        ),
      ),
    );
  }
}

class _NothingToConsolidate extends StatelessWidget {
  const _NothingToConsolidate({this.several = false});

  /// Said by the wallet core (fewer than two spendable), not counted here (one).
  final bool several;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    return EDialog(
      title: 'Consolidate outputs',
      icon: EIcons.merge,
      width: 520.u,
      body: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Nothing to consolidate: the wallet has '),
            TextSpan(text: several ? 'fewer than two spendable outputs' : 'one spendable output', style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
            const TextSpan(text: '. Consolidate merges several outputs into one.'),
          ],
        ),
        style: context.ts.bodyDim,
      ),
      actions: [EButton.primary(label: 'OK', size: EBtnSize.sm, onPressed: () => Navigator.of(context).pop())],
    );
  }
}

/// A whole number from [min] to [max]: − and + buttons around an editable value. Arrow keys
/// step, Home and End jump to the ends; screen readers hear a slider.
class EStepper extends StatefulWidget {
  const EStepper({super.key, required this.value, required this.min, required this.max, required this.onChanged, required this.label});

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String label;

  @override
  State<EStepper> createState() => _EStepperState();
}

class _EStepperState extends State<EStepper> {
  late final _text = TextEditingController(text: '${widget.value}');

  @override
  void didUpdateWidget(EStepper old) {
    super.didUpdateWidget(old);
    if (int.tryParse(_text.text) != widget.value) _text.text = '${widget.value}';
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _set(int v) => widget.onChanged(v.clamp(widget.min, widget.max));

  KeyEventResult _key(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final v = widget.value;
    if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.arrowRight) {
      _set(v + 1);
    } else if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.arrowLeft) {
      _set(v - 1);
    } else if (k == LogicalKeyboardKey.home) {
      _set(widget.min);
    } else if (k == LogicalKeyboardKey.end) {
      _set(widget.max);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value;
    return Semantics(
      slider: true,
      label: widget.label,
      value: '$v',
      increasedValue: '${(v + 1).clamp(widget.min, widget.max)}',
      decreasedValue: '${(v - 1).clamp(widget.min, widget.max)}',
      onIncrease: v < widget.max ? () => _set(v + 1) : null,
      onDecrease: v > widget.min ? () => _set(v - 1) : null,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _key,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EIconButton(icon: Icons.remove, label: 'Fewer', tabStop: false, onPressed: v > widget.min ? () => _set(v - 1) : null),
            SizedBox(width: Sp.x1),
            SizedBox(
              width: 52.u,
              child: EInput(
                controller: _text,
                mono: true,
                semanticLabel: widget.label,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                onChanged: (t) {
                  final n = int.tryParse(t);
                  if (n != null && n >= widget.min && n <= widget.max) widget.onChanged(n);
                },
              ),
            ),
            SizedBox(width: Sp.x1),
            EIconButton(icon: Icons.add, label: 'More', tabStop: false, onPressed: v < widget.max ? () => _set(v + 1) : null),
          ],
        ),
      ),
    );
  }
}
