// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n.dart' show autoLockLabel;
import '../../../settings.dart' show autoLockChoices;
import '../../app/routes.dart' show deskNoLock;
import '../../desk_l10n.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../widgets/kit.dart';
import '../onboarding/unlock_screen.dart' show rememberWho;
import 'dialogs.dart';
import 'setting_ids.dart';
import 'settings_frame.dart';

/// States of the page for the tour's shots.
enum SecurityShot { autoLockOpen }

/// The button that opens Recovery phrase from Security.
const settingsPhraseOpenKey = ValueKey('settings-phrase-open');

/// Settings › Security, in the phone's order: the recovery phrase (its own page), auto-lock,
/// the password and this computer's Remember. Delete wallet is under Wallet › Remove.
class SettingsSecurityScreen extends ConsumerStatefulWidget {
  const SettingsSecurityScreen({super.key, this.arg});

  final Object? arg;

  @override
  ConsumerState<SettingsSecurityScreen> createState() => _SettingsSecurityScreenState();
}

class _SettingsSecurityScreenState extends ConsumerState<SettingsSecurityScreen> {
  /// Whether this wallet opens at start without its password (Unlock's Remember).
  bool _remembered = false;

  @override
  void initState() {
    super.initState();
    _readRemembered();
  }

  /// The open wallet's list id; empty in the mock, which answers for its selected wallet.
  String get _walletId => ref.read(deskProvider).account?.id ?? '';

  Future<void> _readRemembered() async {
    try {
      final r = await ref.read(deskApiProvider).isRemembered(_walletId);
      if (mounted) setState(() => _remembered = r);
    } on Object {
      // Unknown: the row stays hidden.
    }
  }

  Future<void> _forget() async {
    final l = context.l10n;
    try {
      await ref.read(deskApiProvider).forgetRemembered(_walletId);
    } on Object catch (e) {
      if (mounted) showEToast(context, l.deskSetAcctNotForgotten, text: deskErrorText(e, l), tone: ETone.risk);
      return;
    }
    if (!mounted) return;
    setState(() => _remembered = false);
    showEToast(context, l.deskSetAcctForgotten, text: l.deskSetAcctForgottenText, tone: ETone.ok);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = ref.read(deskNavProvider.notifier);
    return SettingsFrame(
      route: DeskRoute.settingsSecurity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ESetGroup(
            rows: [
              ESetRow(
                anchor: SetId.phraseGo,
                title: l.deskSetFramePhrase,
                hint: l.deskSetPhraseIntro,
                control: ERowControl(
                  child: EButton(
                    key: settingsPhraseOpenKey,
                    label: l.commonOpen,
                    icon: EIcons.key,
                    size: EBtnSize.sm,
                    onPressed: () => nav.go(DeskRoute.settingsPhrase),
                  ),
                ),
              ),
              _AutoLockRow(open: widget.arg == SecurityShot.autoLockOpen),
              if (!deskNoLock) ESetRow(
                anchor: SetId.password,
                title: l.deskSetDlgPassword,
                hint: l.deskSetAcctPasswordHint,
                control: ERowControl(child: EButton(label: l.deskSetAcctChangePassword, size: EBtnSize.sm, icon: EIcons.lock, onPressed: () => showChangePasswordDialog(context))),
              ),
              if (_remembered)
                ESetRow(
                  anchor: SetId.remembered,
                  title: l.deskSetAcctRemembered,
                  hint: l.deskSetAcctRememberedHint(rememberWho(l)),
                  control: ERowControl(child: EButton(label: l.deskSetAcctForget, icon: EIcons.lock, size: EBtnSize.sm, onPressed: _forget)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Auto-lock: after how many minutes without a key or the mouse (the phone's choices), or
/// Never (testers looked for an Off in the list; a separate switch was missed). Never keeps the
/// minutes, so choosing a time again needs no second step. Lock wallet works either way.
class _AutoLockRow extends ConsumerWidget {
  const _AutoLockRow({this.open = false});

  /// The list opens with the page (the tour's shot).
  final bool open;

  /// The list's value for Never; the minutes are all positive.
  static const _never = -1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(deskProvider.select((d) => d.settings));
    void save(DeskSettings next) => ref.read(deskProvider.notifier).saveSettings(next);
    return ESetRow(
      anchor: SetId.autolock,
      title: l.settingsAutoLock,
      hint: l.deskSetAcctAutoLockHint,
      control: ERowControl(
        child: ESelect<int>(
          key: const ValueKey('auto-lock-minutes'),
          size: EBtnSize.sm,
          semanticLabel: l.settingsAutoLock,
          value: s.autoLockOn ? s.autoLockMinutes : _never,
          openInitially: open,
          items: [
            for (final m in autoLockChoices) ESelectItem(m, autoLockLabel(l, m)),
            ESelectItem(_never, autoLockLabel(l, null)),
          ],
          onChanged: (m) => save(
            m == _never ? s.copyWith(autoLockOn: false) : s.copyWith(autoLockOn: true, autoLockMinutes: m),
          ),
        ),
      ),
    );
  }
}
