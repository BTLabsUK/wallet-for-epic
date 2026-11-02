// SPDX-License-Identifier: Apache-2.0
/// Settings › Payments › Link · HTTP (HTTP receiving): the two addresses with their switches
/// (this computer; the internet, which binds 0.0.0.0) and the port. The guide is behind the
/// internet address's (?).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../log.dart';
import '../../data/desk_errors.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/http_addresses.dart';
import '../../widgets/kit.dart';
import 'setting_ids.dart';
import 'prefs.dart';

/// HTTP receiving as the status shows it.
HttpRun httpRun(ServiceStatus? s) => switch (s?.httpListener) {
  ServiceHealth.ok => HttpRun.on,
  ServiceHealth.checking => HttpRun.busy,
  ServiceHealth.down => HttpRun.failed,
  _ => HttpRun.off,
};

/// The port a field holds, or null when it is not one.
int? parsePort(String text) {
  final n = int.tryParse(text.trim());
  return n != null && n >= 1 && n <= 65535 ? n : null;
}

/// The indent of a method's detail rows in Settings › Payments: to the method's title
/// (ESetRow's leading, 18 px and a gap). Their dividers span the card.
EdgeInsetsDirectional get methodDetailsIndent => EdgeInsetsDirectional.only(start: 18.u + Sp.x3);

/// The HTTP group's options: the two addresses with their switches, and the port. The
/// method's switch and its state line are the group's own rows. It indents its own rows
/// ([methodDetailsIndent]) so its divider spans the card.
class HttpOptions extends ConsumerStatefulWidget {
  const HttpOptions({super.key});

  @override
  ConsumerState<HttpOptions> createState() => _HttpOptionsState();
}

class _HttpOptionsState extends ConsumerState<HttpOptions> {
  late final TextEditingController _port = TextEditingController(text: '${ref.read(deskProvider).settings.httpPort}');
  String? _portError;

  @override
  void dispose() {
    _port.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    final l = context.l10n;
    try {
      await action();
    } on Object catch (e) {
      logWarn('desk', 'http setting not changed: $e');
      if (mounted) showEToast(context, l.deskSetHttpNotChanged, text: deskErrorText(e, l), tone: ETone.risk);
    }
  }

  Future<void> _setPublic(bool public) async {
    final n = ref.read(deskProvider.notifier);
    final s = ref.read(deskProvider).settings;
    if (s.publicMode == public) return;
    await _run(() => n.saveSettings(s.copyWith(publicMode: public)));
  }

  Future<void> _applyPort() async {
    final port = parsePort(_port.text);
    if (port == null) {
      setState(() => _portError = context.l10n.deskSetHttpPortError);
      return;
    }
    setState(() => _portError = null);
    final n = ref.read(deskProvider.notifier);
    final s = ref.read(deskProvider).settings;
    if (s.httpPort != port) await _run(() => n.saveSettings(s.copyWith(httpPort: port)));
  }

  /// The guide, behind the (?) of the internet address; opening it changes nothing, only its
  /// buttons do.
  Future<void> _openGuide() async {
    final n = ref.read(deskProvider.notifier);
    final s = ref.read(deskProvider).settings;
    if (!s.internetGuideSeen) unawaited(_run(() => n.saveSettings(s.copyWith(internetGuideSeen: true))));
    final choice = await showEDialog<InternetGuideChoice>(context, builder: (_) => InternetGuide(port: s.httpPort, isPublic: s.publicMode));
    switch (choice) {
      case InternetGuideChoice.public:
        await _setPublic(true);
      case InternetGuideChoice.local:
        await _setPublic(false);
      case InternetGuideChoice.tor:
        // Lands on the Tor group, connecting.
        ref.read(settingsPrefsProvider.notifier).jumpTo(SettingsJump.network);
        await _run(() => ref.read(deskProvider.notifier).setTor(true));
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(deskProvider.select((st) => st.settings));
    final listening = ref.watch(deskProvider.select((st) => st.status?.httpListener == ServiceHealth.ok));
    final c = context.dc;
    final ts = context.ts;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The two addresses, each with its switch: this computer's is the method's own switch
        // above; the internet's makes the listener answer on 0.0.0.0.
        SetAnchor(
          id: SetId.httpReach,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Sp.panel, vertical: Sp.x4).add(methodDetailsIndent),
            child: HttpAddresses(
              local: listening ? 'http://127.0.0.1:${s.httpPort}' : null,
              publicTrailing: EIconButton(icon: EIcons.help, label: l.deskSetHttpGuideHelp, size: EBtnSize.sm, tabStop: false, onPressed: _openGuide),
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: c.line),
        Padding(
          padding: methodDetailsIndent,
          child: ESetRow(
          anchor: SetId.httpPort,
          title: l.deskSetHttpPort,
          hint: l.deskSetHttpPortHint,
          control: ERowControl(
            child: Focus(
              onFocusChange: (f) => f ? null : unawaited(_applyPort()),
              child: EInput(
                size: EBtnSize.sm,
                controller: _port,
                mono: true,
                invalid: _portError != null,
                semanticLabel: l.deskSetHttpPortLabel,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                onSubmitted: (_) => _applyPort(),
              ),
            ),
          ),
          below: _portError == null ? null : Text(_portError!, style: ts.small.copyWith(color: c.risk)),
          ),
        ),
      ],
    );
  }
}

/// Receive from the internet: Local only or From the internet, how to forward the
/// port, and Tor as the way with nothing to set up. Pops an [InternetGuideChoice], null on Close.
/// What the guide was closed with: "Receive from the internet", "Back to local only" or
/// "Turn on Tor receiving".
enum InternetGuideChoice { public, local, tor }

class InternetGuide extends StatelessWidget {
  const InternetGuide({super.key, required this.port, required this.isPublic});

  final int port;
  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    final ts = context.ts;
    final c = context.dc;
    final l = context.l10n;
    Widget step(int n, String title, String text, [Widget? extra]) => Padding(
      padding: EdgeInsets.only(bottom: Sp.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: SizedBox(width: Sp.x6, child: Text('$n', style: ts.strong.copyWith(color: c.accentText)))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ts.strong),
                SizedBox(height: 2.u),
                Text(text, style: ts.small),
                ?extra,
              ],
            ),
          ),
        ],
      ),
    );
    return EDialog(
      title: l.deskSetHttpGuideTitle,
      description: isPublic ? l.deskSetHttpGuideNowPublic : l.deskSetHttpGuideNowLocal,
      icon: EIcons.web,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          step(1, l.deskSetHttpStep1, l.deskSetHttpStep1Text('$port')),
          step(2, l.deskSetHttpStep2, l.deskSetHttpStep2Text('$port')),
          step(3, l.deskSetHttpStep3, l.deskSetHttpStep3Text('$port')),
          if (DeskFeatures.tor) ...[
            ENotice(
              icon: EIcons.tor,
              title: l.deskSetHttpNoRouter,
              text: l.deskSetHttpNoRouterText,
              actionsBelow: true,
              actions: [
                EButton(label: l.deskSetHttpTurnOnTor, size: EBtnSize.inline, onPressed: () => Navigator.of(context).pop(InternetGuideChoice.tor)),
              ],
            ),
            SizedBox(height: Sp.x3),
          ],
          Text(l.deskSetHttpExposed, style: ts.caption),
        ],
      ),
      actions: [
        EButton(label: l.commonClose, onPressed: () => Navigator.of(context).pop()),
        if (isPublic)
          EButton(label: l.deskSetHttpBackLocal, onPressed: () => Navigator.of(context).pop(InternetGuideChoice.local))
        else
          EButton.primary(label: l.deskSetHttpGuideTitle, icon: EIcons.web, onPressed: () => Navigator.of(context).pop(InternetGuideChoice.public)),
      ],
    );
  }
}
