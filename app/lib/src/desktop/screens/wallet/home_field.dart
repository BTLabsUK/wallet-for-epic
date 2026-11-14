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

/// The contacts whose name holds [typed] (any case), favourites first, at most [max]; none for
/// an amount or for nothing typed.
List<Contact> homeFieldMatches(List<Contact> all, String typed, {int max = 4}) {
  final q = typed.trim().toLowerCase();
  if (q.isEmpty || RegExp(r'^\d+([.,]\d*)?$').hasMatch(q)) return const [];
  final hits = [for (final c in all) if (c.name.toLowerCase().contains(q)) c]
    ..sort((a, b) => a.favourite == b.favourite ? a.name.toLowerCase().compareTo(b.name.toLowerCase()) : (a.favourite ? -1 : 1));
  return hits.take(max).toList();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(homeFieldFocusProvider.notifier).take()) _focus.requestFocus();
    });
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
    ref.listen(homeFieldFocusProvider, (_, _) {
      if (ref.read(homeFieldFocusProvider.notifier).take()) _focus.requestFocus();
    });
    final matches = homeFieldMatches(ref.watch(deskProvider.select((s) => s.contacts)) ?? const [], _text.text);
    // The page's one place to type: taller than a form's field, as the canvas draws it.
    final field = ConstrainedBox(
      constraints: BoxConstraints(minHeight: 58.u),
      child: EInput(
      key: const ValueKey('home-field'),
      controller: _text,
      focusNode: _focus,
      onChanged: (_) => setState(() {}),
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
    if (matches.isEmpty) return field;
    final c = context.dc;
    final ts = context.ts;
    // The contacts the typing names, under the field: a click opens Send to one.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        SizedBox(height: Sp.x1),
        EPanel(
          key: const ValueKey('home-field-matches'),
          padding: EdgeInsets.all(Sp.x1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final x in matches)
                EInkWell(
                  key: ValueKey('home-field-match-${x.id}'),
                  onTap: () {
                    _text.clear();
                    nav.go(DeskRoute.send, SendArgs(contact: x));
                  },
                  borderRadius: BorderRadius.circular(Rad.sm),
                  hoverColor: c.hover,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
                    child: Row(
                      children: [
                        EAvatar(x.name, size: 28.u),
                        SizedBox(width: Sp.x3),
                        Expanded(child: Text(l.deskOvSendTo(x.name), style: ts.strong, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Icon(EIcons.chevronRight, size: Ctl.iconSm, color: c.faint),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
