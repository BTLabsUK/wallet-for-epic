// SPDX-License-Identifier: Apache-2.0
/// Home's field: a name, an amount, an address or a payment code, typed or pasted. Enter opens
/// Send with it: an amount alone starts a send of that much; anything else lands in To as if
/// typed there, and is read as a pasted text is (a payment link or request fills the form).
/// A transaction file and the camera stand beside it. Nothing is sent from here: Send's own
/// review and password follow.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../scan/scan_checks.dart' show CodeOrigin;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';
import '../scan/desk_scan.dart' show DeskScanButton;
import '../scan/desk_scan_route.dart';
import '../transfer/send_screen.dart' show SendArgs;

/// What Send opens with for [typed]; null for nothing typed.
SendArgs? homeFieldSend(String typed) {
  final text = typed.trim();
  if (text.isEmpty) return null;
  // Digits with at most one decimal mark: an amount.
  if (RegExp(r'^\d+([.,]\d+)?$').hasMatch(text)) return SendArgs(amount: text);
  return SendArgs(recipient: text, suggest: true, code: text, codeOrigin: CodeOrigin.paste);
}

/// Asks Home's field for the focus (Ctrl+K): a count, so every press asks again.
final homeFieldFocusProvider = NotifierProvider<HomeFieldFocus, int>(HomeFieldFocus.new);

class HomeFieldFocus extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

/// Ctrl+K outside Settings: Home, with its field focused.
void openHomeField(WidgetRef ref) {
  if (ref.read(deskNavProvider).route != DeskRoute.overview) ref.read(deskNavProvider.notifier).go(DeskRoute.overview);
  ref.read(homeFieldFocusProvider.notifier).request();
}

class HomeField extends ConsumerStatefulWidget {
  const HomeField({super.key});

  @override
  ConsumerState<HomeField> createState() => _HomeFieldState();
}

class _HomeFieldState extends ConsumerState<HomeField> {
  final _text = TextEditingController();
  final _focus = FocusNode(debugLabel: 'home-field');

  @override
  void initState() {
    super.initState();
    // Opened by Ctrl+K: the request came before this field was built.
    if (ref.read(homeFieldFocusProvider) > 0) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _focus.requestFocus() : null);
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _go(String typed) {
    final args = homeFieldSend(typed);
    if (args == null) return;
    _text.clear();
    ref.read(deskNavProvider.notifier).go(DeskRoute.send, args);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = ref.read(deskNavProvider.notifier);
    ref.listen(homeFieldFocusProvider, (_, _) => _focus.requestFocus());
    return EInput(
      key: const ValueKey('home-field'),
      controller: _text,
      focusNode: _focus,
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
    );
  }
}
