import 'package:flutter/material.dart';

import '../../app/shell.dart' show deskVersion;
import '../../widgets/kit.dart';

/// The version line under the full-window screens.
class AuthFoot extends StatelessWidget {
  const AuthFoot({super.key});

  @override
  Widget build(BuildContext context) => Text('Epic Wallet $deskVersion');
}

/// 0..4 for a password: length and variety.
int passwordStrength(String p) {
  if (p.isEmpty) return 0;
  var s = 0;
  if (p.length >= 8) s++;
  if (p.length >= 12) s++;
  if (RegExp('[a-z]').hasMatch(p) && RegExp('[A-Z]').hasMatch(p)) s++;
  if (RegExp('[0-9]').hasMatch(p) && RegExp('[^A-Za-z0-9]').hasMatch(p)) s++;
  return s.clamp(1, 4);
}

/// Four bars and a word under the password field.
class PasswordMeter extends StatelessWidget {
  const PasswordMeter(this.password, {super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final c = context.dc;
    final s = passwordStrength(password);
    final color = s <= 1 ? c.risk : (s == 2 ? c.warn : c.ok);
    const words = ['', 'Weak', 'Fair', 'Good', 'Strong'];
    return Semantics(
      label: password.isEmpty ? 'Password strength' : 'Password strength: ${words[s]}',
      child: Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i < s ? color : c.s3,
                  borderRadius: BorderRadius.circular(Rad.xs),
                ),
              ),
            ),
            if (i < 3) const SizedBox(width: Sp.x1),
          ],
          const SizedBox(width: Sp.x3),
          SizedBox(width: 48, child: Text(words[s], style: context.ts.caption)),
        ],
      ),
    );
  }
}

/// Name, password and confirmation: the first step of create and restore.
class AccountForm extends StatelessWidget {
  const AccountForm({
    super.key,
    required this.name,
    required this.password,
    required this.confirm,
    required this.onChanged,
    this.passwordError,
    this.confirmError,
  });

  final TextEditingController name, password, confirm;
  final VoidCallback onChanged;
  final String? passwordError;
  final String? confirmError;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EField(
        label: 'Name',
        optional: true,
        help: 'Shown in the wallet list. Can be changed later.',
        child: EInput(controller: name, hint: 'Main wallet', semanticLabel: 'Wallet name', onChanged: (_) => onChanged()),
      ),
      const SizedBox(height: Sp.x5),
      EField(
        label: 'Password',
        error: passwordError,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EPasswordInput(controller: password, invalid: passwordError != null, onChanged: (_) => onChanged()),
            const SizedBox(height: Sp.x2),
            PasswordMeter(password.text),
          ],
        ),
      ),
      const SizedBox(height: Sp.x5),
      EField(
        label: 'Confirm password',
        error: confirmError,
        child: EPasswordInput(controller: confirm, invalid: confirmError != null, onChanged: (_) => onChanged()),
      ),
    ],
  );
}

/// Validation of [AccountForm]; null when fine.
(String?, String?) accountErrors(String password, String confirm) {
  String? p;
  String? c;
  if (password.isNotEmpty && password.length < 8) p = 'At least 8 characters';
  if (confirm.isNotEmpty && confirm != password) c = 'Passwords differ';
  return (p, c);
}

/// A numbered grid of words, as the phrase is written on paper.
List<ERailStep> railOf(List<String> labels, int current) => [
  for (var i = 0; i < labels.length; i++) ERailStep(labels[i], done: i < current, current: i == current),
];

/// Back button used in the foot of the first-run frames.
Widget backButton(VoidCallback onTap, {String label = 'Back'}) =>
    EButton.ghost(label: label, icon: EIcons.arrowLeft, onPressed: onTap);
