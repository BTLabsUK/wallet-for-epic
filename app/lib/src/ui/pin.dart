// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../reserved_slot.dart';
import '../trust_ids.dart';
import '../vault.dart';
import 'common.dart';
import 'kit/kit_button.dart';
import 'kit/kit_icons.dart';
import 'kit/kit_keypad.dart';
import 'kit/kit_row.dart' show KitIconWell;
import 'kit/kit_sheet.dart';
import 'kit/kit_tokens.dart';
import 'theme/tokens.dart';
import 'work_status.dart';

/// A masked [pinLength]-digit field that calls [onCompleted] once all digits are in. With
/// [passphrase] (a wallet whose PIN was replaced by a passphrase, Settings) a masked text
/// field instead, that calls [onCompleted] when the user submits it.
class PinField extends StatelessWidget {
  const PinField({
    super.key,
    required this.controller,
    required this.label,
    required this.onCompleted,
    this.errorText,
    this.enabled = true,
    this.autofocus = true,
    this.passphrase = false,
    this.reserveError = false,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onCompleted;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final bool passphrase;

  /// Keeps the error line's room while there is no error, so an error moves nothing.
  final bool reserveError;

  @override
  Widget build(BuildContext context) => TrustId(TrustIds.pinField, child: _field(context));

  Widget _field(BuildContext context) {
    if (passphrase) {
      return _PassphraseEntry(
        controller: controller,
        label: label,
        errorText: errorText,
        enabled: enabled,
        autofocus: autofocus,
        onCompleted: onCompleted,
        reserveError: reserveError,
      );
    }
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: pinLength,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: Theme.of(context).textTheme.headlineSmall
          ?.copyWith(letterSpacing: 12),
      onChanged: (value) {
        if (value.length == pinLength) onCompleted(value);
      },
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        helperText: reserveError ? ' ' : null,
        counterText: '',
      ),
    );
  }
}

/// The passphrase field of [PinField]: masked, with the show/hide eye the app's password
/// fields have, submitted by the keyboard's Done or the arrow.
class _PassphraseEntry extends StatefulWidget {
  const _PassphraseEntry({
    required this.controller,
    required this.label,
    required this.onCompleted,
    required this.errorText,
    required this.enabled,
    required this.autofocus,
    required this.reserveError,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onCompleted;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final bool reserveError;

  @override
  State<_PassphraseEntry> createState() => _PassphraseEntryState();
}

class _PassphraseEntryState extends State<_PassphraseEntry> {
  bool _obscure = true;

  void _submit() {
    if (widget.controller.text.isNotEmpty) widget.onCompleted(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      enableIMEPersonalizedLearning: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        helperText: widget.reserveError ? ' ' : null,
        errorMaxLines: 3,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: _obscure ? l.passwordShow : l.passwordHide,
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            IconButton(
              icon: TrustId(TrustIds.commonContinue, child: const Icon(Icons.arrow_forward)),
              tooltip: l.commonContinue,
              onPressed: widget.enabled ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// The trust id of a [KitKeypad] key of the PIN pad (digits '0'..'9', [KitKey.delete],
/// [KitKey.biometrics]), for the test drivers.
String? pinKeyId(String key) => switch (key) {
  '0' => TrustIds.pinKey0,
  '1' => TrustIds.pinKey1,
  '2' => TrustIds.pinKey2,
  '3' => TrustIds.pinKey3,
  '4' => TrustIds.pinKey4,
  '5' => TrustIds.pinKey5,
  '6' => TrustIds.pinKey6,
  '7' => TrustIds.pinKey7,
  '8' => TrustIds.pinKey8,
  '9' => TrustIds.pinKey9,
  KitKey.delete => TrustIds.pinKeyDelete,
  KitKey.biometrics => TrustIds.pinKeyBio,
  _ => null,
};

/// The PIN's six dots on the wallet's own keypad (HANDOFF 7.8): the dots, then [KitKeypad]. The
/// digits stay with the caller ([digits], [onChanged]); [onCompleted] runs once [pinLength] of
/// them are in. A hardware keyboard types too (digits and Backspace), so a tablet or a driver
/// with a keyboard needs no touch. With [enabled] false the keys are dimmed and do nothing
/// (while a PIN is checked). [error] draws the dots in risk. The PIN goes nowhere but to
/// [onChanged] and [onCompleted]: this widget keeps and logs nothing.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.digits,
    required this.onChanged,
    required this.onCompleted,
    this.error = false,
    this.enabled = true,
    this.onBiometrics,
    this.below,
    this.top = const [],
    this.fill = false,
    this.topGap,
    this.footGap = 0,
  });

  final String digits;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;
  final bool error;
  final bool enabled;

  /// Shows the biometrics key bottom-left and calls this when it is pressed.
  final VoidCallback? onBiometrics;

  /// What sits between the dots and the keys: the error line, the wait, the progress.
  final Widget? below;

  /// What sits above the dots: the title and its hint.
  final List<Widget> top;

  /// With a bounded height: [top] and the dots are centred in the room above the keys, which
  /// sit at the foot of the screen. Otherwise everything follows in one column.
  final bool fill;

  /// With [fill]: [top] starts this far below the top, not centred (the setup steps' frame).
  final double? topGap;

  /// With [fill]: the room under the keys.
  final double footGap;

  void _digit(String d) {
    if (!enabled || digits.length >= pinLength) return;
    final next = digits + d;
    onChanged(next);
    if (next.length == pinLength) onCompleted(next);
  }

  void _delete() {
    if (!enabled || digits.isEmpty) return;
    onChanged(digits.substring(0, digits.length - 1));
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _delete();
      return KeyEventResult.handled;
    }
    final c = event.character;
    if (c != null && c.length == 1 && c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39) {
      _digit(c);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final head = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...top,
        TrustId(TrustIds.pinField, child: KitPinDots(filled: digits.length, error: error)),
        if (below != null) ...[const SizedBox(height: 14), below!],
      ],
    );
    final keys = Opacity(
      opacity: enabled ? 1 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: KitKeypad(
          onDigit: _digit,
          onDelete: _delete,
          onDeleteLong: () {
            if (enabled && digits.isNotEmpty) onChanged('');
          },
          onBiometrics: onBiometrics,
          idFor: pinKeyId,
        ),
      ),
    );
    return Focus(
      autofocus: true,
      onKeyEvent: _key,
      child: fill
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: topGap == null
                      ? Center(child: SingleChildScrollView(child: head))
                      : SingleChildScrollView(padding: EdgeInsets.only(top: topGap!), child: head),
                ),
                keys,
                SizedBox(height: footGap),
              ],
            )
          : Column(mainAxisSize: MainAxisSize.min, children: [head, const SizedBox(height: 22), keys]),
    );
  }
}

/// The line under the PIN's dots: [text] in risk (a wrong PIN) or, with [quiet], in the dim
/// colour. It holds two lines of room whether or not it says anything, so a message moves
/// nothing around it.
class PinMessage extends StatelessWidget {
  const PinMessage(this.text, {super.key, this.quiet = false, this.child});

  final String? text;
  final bool quiet;

  /// Instead of [text]: a chip or a progress line in the same room.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = KitType.body.copyWith(color: quiet ? t.dim : t.risk);
    return ReservedSlot.lines(
      style: style,
      lines: 2,
      alignment: AlignmentDirectional.topCenter,
      child: child ?? (text == null ? null : Semantics(liveRegion: true, child: Text(text!, style: style, textAlign: TextAlign.center))),
    );
  }
}

/// Picks a PIN on the keypad, confirms it, then asks about biometric unlock where the device
/// has it. Calls [onDone] once, with the PIN and the biometric answer. It brings its own title
/// and hint; the screen around it brings the header.
class PinSetupView extends ConsumerStatefulWidget {
  const PinSetupView({
    super.key,
    required this.onDone,
    this.intro,
    this.askBiometrics = true,
    this.chooseTitle,
    this.chooseLabel,
    this.actionsAtFoot = false,
  });

  final void Function(String pin, bool useBiometrics) onDone;

  /// The keypad at the foot of the screen with the title centred in the room above it (needs a
  /// bounded height), as first run does; otherwise the parts follow one another.
  final bool actionsAtFoot;

  /// Whether to offer biometric unlock after the PIN. Off when changing an existing PIN.
  final bool askBiometrics;

  /// Replaces "Choose a 6-digit PIN".
  final String? chooseTitle;

  /// Kept for the screens that name the first PIN ("New PIN"); the keypad has no field label,
  /// so it only labels the dots for a screen reader.
  final String? chooseLabel;

  /// Shown above the title of the first step.
  final Widget? intro;

  @override
  ConsumerState<PinSetupView> createState() => _PinSetupViewState();
}

enum _PinStep { choose, confirm }

class _PinSetupViewState extends ConsumerState<PinSetupView> {
  late final Future<bool> _biometricsAvailable = ref.read(biometricStoreProvider).isAvailable();
  _PinStep _step = _PinStep.choose;
  bool _mismatch = false;
  String _digits = '';
  String _chosen = '';
  bool _asking = false;

  @override
  void dispose() {
    _digits = '';
    _chosen = '';
    super.dispose();
  }

  void _chosenPin(String pin) {
    // A beat on the full dots before the next step, so the sixth digit is seen.
    setState(() {
      _chosen = pin;
      _mismatch = false;
    });
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      setState(() {
        _digits = '';
        _step = _PinStep.confirm;
      });
    });
  }

  Future<void> _confirmed(String pin) async {
    if (pin != _chosen) {
      setState(() {
        _digits = '';
        _chosen = '';
        _mismatch = true;
        _step = _PinStep.choose;
      });
      return;
    }
    if (widget.askBiometrics && await _biometricsAvailable) {
      if (!mounted) return;
      setState(() => _asking = true);
      final use = await showPinBiometricsOffer(context);
      if (!mounted) return;
      widget.onDone(_chosen, use);
    } else {
      widget.onDone(pin, false);
    }
  }

  void _chooseDifferent() => setState(() {
    _digits = '';
    _chosen = '';
    _step = _PinStep.choose;
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    final choose = _step == _PinStep.choose;
    final hintStyle = KitType.body.copyWith(color: t.dim, height: 1.45);
    final frame = widget.actionsAtFoot;
    final top = <Widget>[
      if (choose) ?widget.intro,
      Semantics(
        header: true,
        child: Text(
          choose ? (widget.chooseTitle ?? l.pinChooseTitle(pinLength)) : l.pinConfirmTitle,
          style: KitType.pageTitle.copyWith(color: t.text, fontSize: frame ? 24 : null, letterSpacing: frame ? -0.48 : null),
          textAlign: TextAlign.center,
        ),
      ),
      SizedBox(height: frame ? (choose ? 10 : 0) : 12),
      // The hint's room stays on the repeat step, so the keypad and the title do not move.
      if (frame && !choose)
        const SizedBox.shrink()
      else
        Padding(
        padding: EdgeInsets.symmetric(horizontal: frame ? 40 : 0),
        child: ReservedSlot.like(
          alignment: AlignmentDirectional.topCenter,
          model: Text(l.phonePinChooseHint, style: hintStyle, textAlign: TextAlign.center),
          child: choose ? Text(l.phonePinChooseHint, style: hintStyle, textAlign: TextAlign.center) : null,
        ),
      ),
      SizedBox(height: frame ? 44 : 28),
    ];
    return PinPad(
      key: ValueKey('pin-${_step.name}'),
      top: top,
      fill: widget.actionsAtFoot,
      topGap: frame ? 54 : null,
      footGap: frame ? 25 : 0,
      digits: _asking ? _chosen : _digits,
      enabled: !_asking,
      onChanged: (v) => setState(() => _digits = v),
      onCompleted: choose ? _chosenPin : _confirmed,
      error: _mismatch,
      below: PinMessage(
        _mismatch ? l.pinMismatch : null,
        child: !choose && !_asking
            ? KitButton(label: l.pinChooseDifferent, onPressed: _chooseDifferent, kind: KitButtonKind.ghost, small: true, expand: false)
            : null,
      ),
    );
  }
}

/// The biometrics offer after the PIN (HANDOFF 7.8): a sheet over the PIN screen with the
/// fingerprint tile, a question, "Use biometrics" and "Not now". Answers true to use them;
/// false for Not now, the back key or a swipe down.
Future<bool> showPinBiometricsOffer(BuildContext context) async {
  final use = await showKitSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (sheet) {
      final t = sheet.tokens;
      final l = sheet.l10n;
      return KitSheet(
        primaryLabel: l.pinBiometricsEnable,
        onPrimary: () => Navigator.pop(sheet, true),
        actionsTop: 24,
        buttonsGap: 4,
        secondary: SizedBox(
          height: 44,
          child: KitButton(label: l.pinBiometricsNotNow, onPressed: () => Navigator.pop(sheet, false), kind: KitButtonKind.ghost, semanticsId: TrustIds.pinBiometricsNotnow),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            children: [
              Semantics(label: l.pinBiometricsIconLabel, child: KitIconWell(KitIcons.fingerprint, color: t.accent, size: 64, iconSize: 32)),
              const SizedBox(height: 18),
              Text(l.pinBiometricsQuestion, style: KitType.sheetTitle.copyWith(color: t.text), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(l.phonePinBiometricsBody, style: KitType.body.copyWith(color: t.dim, height: 1.45), textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      );
    },
  );
  return use ?? false;
}

/// A PIN step's heading, with room for two lines whether it takes one or two: the steps'
/// headings differ in length (and wrap differently per language), and the field under them
/// stays in one place. The spare line falls above the heading, which stays by its field.
class PinStepTitle extends StatelessWidget {
  const PinStepTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium ?? const TextStyle();
    return ReservedSlot.lines(
      style: style,
      lines: 2,
      alignment: AlignmentDirectional.bottomCenter,
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }
}

/// The room under a PIN step's field: the confirm step's "Choose a different PIN" holds it, and
/// every other step keeps it free (or puts its progress or error in it), so changing step moves
/// nothing.
class PinStepFoot extends StatelessWidget {
  const PinStepFoot({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => ReservedSlot.like(
        model: TextButton(onPressed: null, child: Text(context.l10n.pinChooseDifferent)),
        child: child,
      );
}

/// A sentence for a wait before LEPIC checks a PIN: seconds up to two minutes, then minutes.
String _describeWait(
  Duration wait,
  String Function(int) seconds,
  String Function(int) minutes,
) {
  final s = wait.inSeconds < 1 ? 1 : wait.inSeconds;
  return s < 120 ? seconds(s) : minutes((s / 60).ceil());
}

/// A sentence for a rejected PIN: the tries left, or how long the next one waits.
String describePinRejection(AppLocalizations l, PinRejected rejection) {
  final wait = rejection.nextWait;
  if (wait == Duration.zero) return l.pinWrong(rejection.attemptsLeft);
  return _describeWait(wait, l.pinWrongWaitSeconds, l.pinWrongWaitMinutes);
}

/// The line under the PIN field while a PIN is checked and the wallet opens (the unlock screen,
/// the PIN prompt): a thin brand-gold line, not the stock in-progress bar, and only once the
/// check takes long enough to notice, so a quick unlock shows nothing at all. With [status] or
/// [lines], a quiet line under it says which step runs ([WorkStatus]).
class PinCheckBar extends StatefulWidget {
  const PinCheckBar({super.key, this.status, this.lines = const []});

  final String? status;
  final List<String> lines;

  /// How long a check runs before the line shows.
  static const Duration showAfter = Duration(milliseconds: 400);

  @override
  State<PinCheckBar> createState() => _PinCheckBarState();
}

class _PinCheckBarState extends State<PinCheckBar> {
  bool _shown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(PinCheckBar.showAfter, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bar = SizedBox(
      height: 4,
      child: Center(
        child: AnimatedOpacity(
          opacity: _shown ? 1 : 0,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _shown
              ? LinearProgressIndicator(
                  minHeight: 2,
                  color: t.accent,
                  backgroundColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(1),
                )
              : const SizedBox(height: 2),
        ),
      ),
    );
    if (widget.status == null && widget.lines.isEmpty) return bar;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        bar,
        const SizedBox(height: 6),
        WorkStatus(text: widget.status, lines: widget.lines, showAfter: PinCheckBar.showAfter),
      ],
    );
  }
}

/// Counts down to [until], while LEPIC waits before it checks a PIN after repeated failures.
class PinWaitNote extends StatefulWidget {
  const PinWaitNote({super.key, required this.until});

  final DateTime until;

  @override
  State<PinWaitNote> createState() => _PinWaitNoteState();
}

class _PinWaitNoteState extends State<PinWaitNote> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final left = widget.until.difference(DateTime.now());
    return Text(
      left <= Duration.zero
          ? l.pinChecking
          : _describeWait(left, l.pinCheckingSeconds, l.pinCheckingMinutes),
      textAlign: TextAlign.center,
    );
  }
}

/// When a PIN typed now will be checked, or null if at once.
Future<DateTime?> pinCheckTime(WidgetRef ref) async {
  final config = ref.read(walletConfigProvider);
  if (config == null) return null;
  // Only for the note: a count that cannot be read (a lost Keystore key) is reported by the
  // attempt itself.
  try {
    final wait = await ref.read(vaultProvider).nextPinWait(config);
    return wait == Duration.zero ? null : DateTime.now().add(wait);
  } catch (_) {
    return null;
  }
}

/// Whether the open wallet's secret is a passphrase ([usesPassphraseProvider]), for the reason
/// line of [askPin]: the xPassphraseReason string in place of xPinReason.
bool usesPassphrase(WidgetRef ref) => ref.read(usesPassphraseProvider).value ?? false;

/// Asks for the PIN of the open wallet (or, with [allowBiometrics], its biometric copy) and
/// runs [action] with it. Returns what [action] returned, or null if the user cancelled. A
/// wrong PIN ([PinRejected] from [action]) is shown in the sheet and asked again. This is the
/// one PIN sheet of the app ([showPinSheet]); [reason] is the line under its title.
Future<T?> askPin<T extends Object>(
  BuildContext context, {
  String? reason,
  bool allowBiometrics = true,
  required Future<T> Function(String pin) action,
}) => showPinSheet<T>(context, reason: reason, allowBiometrics: allowBiometrics, action: action);

/// The PIN sheet (HANDOFF 7.8): "Enter your PIN", what it is for, six dots, the wallet's own
/// keypad (with the biometrics key where the wallet has them) and Cancel. Runs [action] with the
/// PIN once six digits are in and returns what it returned, or null on Cancel. A wrong PIN
/// shows under the dots and the sheet asks again; the sheet stays open while [action] runs
/// (LEPIC may wait up to an hour before it checks a PIN). A wallet that uses a passphrase gets
/// the passphrase field instead of the keypad.
Future<T?> showPinSheet<T extends Object>(
  BuildContext context, {
  String? reason,
  bool allowBiometrics = true,
  required Future<T> Function(String pin) action,
}) async {
  // The web preview asks nothing: the fake wallet takes any PIN (previewNoLock is const false
  // in every real build).
  if (previewNoLock) {
    try {
      return await action('000000');
    } catch (_) {
      return null;
    }
  }
  return showKitSheet<T>(
    context: context,
    enableDrag: false,
    builder: (_) => _PinSheet<T>(reason: reason, allowBiometrics: allowBiometrics, action: action),
  );
}

class _PinSheet<T extends Object> extends ConsumerStatefulWidget {
  const _PinSheet({this.reason, required this.allowBiometrics, required this.action});

  final String? reason;
  final bool allowBiometrics;
  final Future<T> Function(String pin) action;

  @override
  ConsumerState<_PinSheet<T>> createState() => _PinSheetState<T>();
}

class _PinSheetState<T extends Object> extends ConsumerState<_PinSheet<T>> {
  final _passphrase = TextEditingController();
  String _digits = '';
  String? _error;
  bool _busy = false;
  bool _biometrics = false;
  DateTime? _checkAt;

  @override
  void initState() {
    super.initState();
    unawaited(_checkBiometrics());
  }

  @override
  void dispose() {
    _digits = '';
    _passphrase.clear();
    _passphrase.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final config = ref.read(walletConfigProvider);
    if (config == null || !widget.allowBiometrics) return;
    final enabled = await ref.read(vaultProvider).biometricsEnabled(config.chain);
    if (!mounted) return;
    setState(() => _biometrics = enabled);
    // Biometrics go first, as on the unlock screen; the PIN stays for a dismissed prompt.
    if (enabled) await _useBiometrics();
  }

  Future<void> _useBiometrics() async {
    final config = ref.read(walletConfigProvider);
    if (config == null || _busy) return;
    final vault = ref.read(vaultProvider);
    final pin = await vault.readBiometricPin(config.chain);
    if (pin == null) {
      final still = await vault.biometricsEnabled(config.chain);
      if (mounted) setState(() => _biometrics = still);
      return;
    }
    await _run(pin, biometric: true);
  }

  Future<void> _run(String pin, {bool biometric = false}) async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    final checkAt = await pinCheckTime(ref);
    if (mounted) setState(() => _checkAt = checkAt);
    try {
      final result = await widget.action(pin);
      if (mounted) Navigator.pop(context, result);
    } on PinRejected catch (rejection) {
      _clear();
      final config = ref.read(walletConfigProvider);
      // A biometric copy that no longer opens is of no use.
      if (biometric && config != null) {
        await ref.read(vaultProvider).disableBiometrics(config.chain);
      }
      if (mounted) {
        setState(() {
          if (biometric) _biometrics = false;
          _error = describePinRejection(l, rejection);
        });
      }
    } catch (error) {
      _clear();
      if (mounted) setState(() => _error = describeError(l, error));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _checkAt = null;
        });
      }
    }
  }

  void _clear() {
    _passphrase.clear();
    if (mounted) setState(() => _digits = '');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final checkAt = _checkAt;
    final passphrase = ref.watch(usesPassphraseProvider).value ?? false;
    final reason = widget.reason;
    final head = <Widget>[
      Semantics(
        header: true,
        child: Text(
          passphrase ? l.passphrasePromptTitle : l.pinPromptTitle,
          style: KitType.sheetTitle.copyWith(color: t.text),
          textAlign: TextAlign.center,
        ),
      ),
      if (reason != null) ...[
        const SizedBox(height: 6),
        Text(reason, style: KitType.body.copyWith(color: t.dim), textAlign: TextAlign.center),
      ],
      const SizedBox(height: 24),
    ];
    final progress = _busy
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            const PinCheckBar(),
            if (checkAt != null) ...[const SizedBox(height: 8), PinWaitNote(until: checkAt)],
          ])
        : null;
    // Closing the sheet would not stop a running action, so it stays open until the action ends.
    return PopScope(
      canPop: !_busy,
      child: ColoredBox(
        color: t.sheet,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 12 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const KitGrabber(),
                if (passphrase) ...[
                  ...head.map((w) => Padding(padding: const EdgeInsets.symmetric(horizontal: Kit.gutter), child: w)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
                    child: PinField(
                      controller: _passphrase,
                      label: l.passphraseLabel,
                      enabled: !_busy,
                      errorText: _error,
                      onCompleted: _run,
                      passphrase: true,
                    ),
                  ),
                  if (progress != null) Padding(padding: const EdgeInsets.only(top: 8, left: Kit.gutter, right: Kit.gutter), child: progress),
                ] else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
                    child: PinPad(
                      top: head,
                      digits: _digits,
                      enabled: !_busy,
                      error: _error != null,
                      onChanged: (v) => setState(() => _digits = v),
                      onCompleted: _run,
                      onBiometrics: _biometrics ? _useBiometrics : null,
                      below: PinMessage(_error, child: progress),
                    ),
                  ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Kit.gutter),
                  child: KitButton(
                    label: l.commonCancel,
                    kind: KitButtonKind.quiet,
                    onPressed: _busy ? null : () => Navigator.pop(context),
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
