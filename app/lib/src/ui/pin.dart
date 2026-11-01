// SPDX-License-Identifier: Apache-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo.dart';
import '../errors.dart';
import '../l10n.dart';
import '../providers.dart';
import '../reserved_slot.dart';
import '../vault.dart';
import 'common.dart';
import 'demo_pin.dart';
import 'theme/tokens.dart';

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
  Widget build(BuildContext context) {
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
        border: const OutlineInputBorder(),
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
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: _obscure ? l.passwordShow : l.passwordHide,
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              tooltip: l.commonContinue,
              onPressed: widget.enabled ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Picks a PIN, confirms it, then asks about biometric unlock where the device has it.
/// Calls [onDone] once, with the PIN and the biometric answer.
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

  /// The step's buttons at the foot of the screen (needs a bounded height), as first run
  /// does; otherwise they follow the content.
  final bool actionsAtFoot;

  /// Whether to offer biometric unlock after the PIN. Off when changing an existing PIN.
  final bool askBiometrics;

  /// Replaces "Choose a 6-digit PIN".
  final String? chooseTitle;

  /// Replaces the first field's label, "PIN" ("New PIN" on Change PIN).
  final String? chooseLabel;

  /// Shown above the first PIN field.
  final Widget? intro;

  @override
  ConsumerState<PinSetupView> createState() => _PinSetupViewState();
}

enum _PinStep { choose, confirm, biometrics }

class _PinSetupViewState extends ConsumerState<PinSetupView> {
  final _pin = TextEditingController();
  final _confirm = TextEditingController();
  late final Future<bool> _biometricsAvailable = ref
      .read(biometricStoreProvider)
      .isAvailable();
  _PinStep _step = _PinStep.choose;
  bool _mismatch = false;
  String _chosen = '';

  @override
  void dispose() {
    _pin.clear();
    _confirm.clear();
    _chosen = '';
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _chosenPin(String pin) {
    setState(() {
      _chosen = pin;
      _mismatch = false;
      _step = _PinStep.confirm;
    });
  }

  Future<void> _confirmed(String pin) async {
    if (pin != _chosen) {
      _confirm.clear();
      _pin.clear();
      setState(() {
        _chosen = '';
        _mismatch = true;
        _step = _PinStep.choose;
      });
      return;
    }
    if (widget.askBiometrics && await _biometricsAvailable) {
      if (mounted) setState(() => _step = _PinStep.biometrics);
    } else {
      widget.onDone(pin, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    // The step's content, then its actions: at the foot of the screen when asked. The choose
    // step holds the room of the confirm step's button ([PinStepFoot]), so the PIN field stays
    // in one place between the two steps.
    final (List<Widget> content, List<Widget> actions) = switch (_step) {
      _PinStep.choose => (_chooseStep(theme, l), [const SizedBox(height: 8), const PinStepFoot()]),
      _PinStep.confirm => (
        _confirmStep(theme, l),
        [const SizedBox(height: 8), PinStepFoot(child: _chooseDifferent(l))],
      ),
      _PinStep.biometrics => (_biometricsStep(theme, l), _biometricsActions(l)),
    };
    if (!widget.actionsAtFoot) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...content, ...actions]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: content),
            ),
          ),
        ),
        ...actions,
      ],
    );
  }

  List<Widget> _chooseStep(ThemeData theme, AppLocalizations l) => [
          ?widget.intro,
          PinStepTitle(widget.chooseTitle ?? l.pinChooseTitle(pinLength)),
          const SizedBox(height: 16),
          PinField(
            key: const ValueKey('pin-choose'),
            controller: _pin,
            label: widget.chooseLabel ?? l.pinLabel,
            errorText: _mismatch ? l.pinMismatch : null,
            reserveError: true,
            onCompleted: _chosenPin,
          ),
        ];

  List<Widget> _confirmStep(ThemeData theme, AppLocalizations l) => [
          PinStepTitle(l.pinConfirmTitle),
          const SizedBox(height: 16),
          PinField(
            key: const ValueKey('pin-confirm'),
            controller: _confirm,
            label: l.pinRepeatLabel,
            reserveError: true,
            onCompleted: _confirmed,
          ),
        ];

  Widget _chooseDifferent(AppLocalizations l) => TextButton(
        onPressed: () {
          _pin.clear();
          _confirm.clear();
          setState(() => _step = _PinStep.choose);
        },
        child: Text(l.pinChooseDifferent),
      );

  List<Widget> _biometricsStep(ThemeData theme, AppLocalizations l) => [
          Icon(
            Icons.fingerprint,
            size: 64,
            color: theme.colorScheme.primary,
            semanticLabel: l.pinBiometricsIconLabel,
          ),
          const SizedBox(height: 16),
          Text(
            l.pinBiometricsQuestion,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(l.pinBiometricsPinStillWorks, textAlign: TextAlign.center),
          const SizedBox(height: 24),
        ];

  List<Widget> _biometricsActions(AppLocalizations l) => [
          BusyButton(
            label: l.pinBiometricsEnable,
            onPressed: () => widget.onDone(_chosen, true),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => widget.onDone(_chosen, false),
            child: Text(l.pinBiometricsNotNow),
          ),
        ];
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
/// check takes long enough to notice, so a quick unlock shows nothing at all.
class PinCheckBar extends StatefulWidget {
  const PinCheckBar({super.key});

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
    return SizedBox(
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
/// wrong PIN ([PinRejected] from [action]) is shown in the dialog and asked again.
Future<T?> askPin<T extends Object>(
  BuildContext context, {
  String? reason,
  bool allowBiometrics = true,
  required Future<T> Function(String pin) action,
}) {
  return showDialog<T>(
    context: context,
    builder: (_) => _PinPromptDialog<T>(
      reason: reason,
      allowBiometrics: allowBiometrics,
      action: action,
    ),
  );
}

class _PinPromptDialog<T extends Object> extends ConsumerStatefulWidget {
  const _PinPromptDialog({
    this.reason,
    required this.allowBiometrics,
    required this.action,
  });

  final String? reason;
  final bool allowBiometrics;
  final Future<T> Function(String pin) action;

  @override
  ConsumerState<_PinPromptDialog<T>> createState() =>
      _PinPromptDialogState<T>();
}

class _PinPromptDialogState<T extends Object>
    extends ConsumerState<_PinPromptDialog<T>> {
  final _pin = TextEditingController();
  String? _error;

  /// Whether the last try ended in [PinRejected].
  bool _rejected = false;
  bool _busy = false;
  bool _biometrics = false;
  DateTime? _checkAt;

  /// Web demo only: true while the demo PIN is filled in, false for the PIN field, null until
  /// [_checkDemoPin] has looked. Outside the demo always false.
  bool? _autoPin;

  @override
  void initState() {
    super.initState();
    // The web demo and preview fill in the demo PIN: no PIN is asked.
    if (ref.read(demoModeProvider) || ref.read(pinlessProvider)) {
      unawaited(_checkDemoPin());
    } else {
      _autoPin = false;
    }
    unawaited(_checkBiometrics());
  }

  Future<void> _checkDemoPin() async {
    final config = ref.read(walletConfigProvider);
    var auto = false;
    try {
      // As on unlock: once a PIN was refused, the visitor types it.
      auto =
          config != null &&
          await ref.read(walletServiceProvider).pinFailures(config: config) ==
              0 &&
          await ref.read(vaultProvider).usesDemoPin(config.chain);
    } catch (_) {
      // Unreadable: the PIN field shows.
    }
    if (mounted) setState(() => _autoPin = auto);
  }

  /// Runs the action with [demoPin]. A refused PIN brings the field; any other error stays
  /// here, under the filled dots, with Try again.
  Future<void> _runDemoPin() async {
    await _run(demoPin);
    if (mounted && _rejected) setState(() => _autoPin = false);
  }

  @override
  void dispose() {
    _pin.clear();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final config = ref.read(walletConfigProvider);
    if (config == null || !widget.allowBiometrics) return;
    final enabled = await ref
        .read(vaultProvider)
        .biometricsEnabled(config.chain);
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
      _rejected = false;
    });
    final checkAt = await pinCheckTime(ref);
    if (mounted) setState(() => _checkAt = checkAt);
    try {
      final result = await widget.action(pin);
      if (mounted) Navigator.pop(context, result);
    } on PinRejected catch (rejection) {
      _rejected = true;
      _pin.clear();
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
      _pin.clear();
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final checkAt = _checkAt;
    final passphrase = ref.watch(usesPassphraseProvider).value ?? false;
    // Closing the dialog would not stop a running action (LEPIC may wait up to an hour before
    // it checks the PIN), so it stays open until the action ends.
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(passphrase ? l.passphrasePromptTitle : l.pinPromptTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.reason != null) ...[
              Text(widget.reason!),
              const SizedBox(height: 16),
            ],
            switch (_autoPin) {
              null => const SizedBox(height: 56),
              true => DemoPinFill(compact: true, onDone: _runDemoPin),
              false => PinField(
                controller: _pin,
                label: passphrase ? l.passphraseLabel : l.pinLabel,
                enabled: !_busy,
                errorText: _error,
                onCompleted: _run,
                passphrase: passphrase,
              ),
            },
            if (_busy) ...[
              const SizedBox(height: 8),
              const PinCheckBar(),
              if (checkAt != null) ...[
                const SizedBox(height: 8),
                PinWaitNote(until: checkAt),
              ],
            ],
            if (_autoPin == true && _error != null && !_busy) ...[
              ErrorText(_error!),
              BusyButton(label: l.launchTryAgain, onPressed: _runDemoPin),
            ],
            if (_biometrics)
              TextButton.icon(
                icon: const Icon(Icons.fingerprint),
                label: Text(l.pinUseBiometrics),
                onPressed: _busy ? null : _useBiometrics,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(l.commonCancel),
          ),
        ],
      ),
    );
  }
}
