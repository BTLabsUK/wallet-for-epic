// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/desk_errors.dart' show deskErrorText;
import '../../desk_l10n.dart';
import '../../widgets/kit.dart';

/// The healthiest other public Epicbox server to offer while ours does not answer, or null.
EpicboxServer? healthiestOtherEpicbox(DeskState st) {
  final current = st.status?.epicbox.domain;
  final ok = [
    for (final b in st.epicboxes ?? const <EpicboxServer>[])
      if (b.domain != current && (b.health == ServiceHealth.ok || b.health == ServiceHealth.slow)) b,
  ]..sort((a, b) {
      final h = a.health.index.compareTo(b.health.index);
      return h != 0 ? h : (a.latencyMs ?? 9999).compareTo(b.latencyMs ?? 9999);
    });
  return ok.isEmpty ? null : ok.first;
}

/// Our Epicbox server does not answer: one line, and a one-click switch to the healthiest other
/// server. Never switched by itself. The same words on Send and Receive.
///
/// When the network blocks the relay ([ServiceStatus.epicboxBlocked]) it says so instead, with
/// one button that moves to [ServiceStatus.epicboxInstead] at once (no confirmation) and, under
/// it, that the Epicbox address changes. [sentence] false: the screen's state line already says
/// it (Receive, Settings), so only the button and the caption show (nothing when no other
/// server answers).
class EpicboxDownNotice extends ConsumerStatefulWidget {
  const EpicboxDownNotice({super.key, this.sentence = true, this.status});

  final bool sentence;

  /// The status to read instead of the wallet's (the tour's laid-over state).
  final ServiceStatus? status;

  @override
  ConsumerState<EpicboxDownNotice> createState() => _EpicboxDownNoticeState();
}

class _EpicboxDownNoticeState extends ConsumerState<EpicboxDownNotice> {
  bool _busy = false;

  Future<void> _switch(String domain) async {
    setState(() => _busy = true);
    try {
      await ref.read(deskProvider.notifier).useEpicbox(domain);
      if (mounted) showEToast(context, context.l10n.deskSendEpicboxSwitched(domain), tone: ETone.ok);
    } on Object catch (e) {
      if (mounted) showEToast(context, context.l10n.deskSendEpicboxNotSwitched, text: deskErrorText(e, context.l10n), tone: ETone.risk);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _blocked(AppLocalizations l, ServiceStatus s) {
    final instead = s.epicboxInstead;
    final ts = context.ts;
    final button = instead == null
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EButton(
                key: const ValueKey('epicbox-blocked-switch'),
                label: l.deskEpicboxBlockedSwitch(instead.host),
                icon: EIcons.swap,
                size: widget.sentence ? EBtnSize.inline : EBtnSize.md,
                busy: _busy,
                onPressed: _busy ? null : () => _switch(instead.label),
              ),
              SizedBox(height: Sp.x2),
              Text(l.slSwitchBody, style: ts.caption),
            ],
          );
    if (!widget.sentence) return button ?? const SizedBox.shrink();
    return ENotice(
      key: const ValueKey('epicbox-blocked'),
      title: l.deskEpicboxBlockedWord,
      text: l.deskEpicboxBlockedShort(s.epicbox.domain),
      tone: ETone.risk,
      icon: EIcons.antenna,
      below: button,
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(deskProvider);
    final l = context.l10n;
    final s = widget.status ?? st.status;
    if (s != null && s.epicboxBlocked) return _blocked(l, s);
    final other = healthiestOtherEpicbox(st);
    // Under a state line that says "Not answering" already: only an offer to switch adds to it.
    if (!widget.sentence && other == null) return const SizedBox.shrink();
    return ENotice(
      title: l.deskSendEpicboxDownTitle,
      text: other == null ? l.deskSendEpicboxDownWait : l.deskSendEpicboxSwitchTo(other.domain),
      tone: ETone.warn,
      icon: EIcons.antenna,
      actions: [
        if (other != null)
          EButton(label: l.deskSendEpicboxSwitch, icon: EIcons.swap, size: EBtnSize.inline, busy: _busy, onPressed: _busy ? null : () => _switch(other.domain)),
      ],
    );
  }
}
