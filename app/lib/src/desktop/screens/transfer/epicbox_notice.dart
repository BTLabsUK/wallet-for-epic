import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lepic_desk_wallet.dart' show deskErrorText;
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
class EpicboxDownNotice extends ConsumerStatefulWidget {
  const EpicboxDownNotice({super.key});

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

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(deskProvider);
    final other = healthiestOtherEpicbox(st);
    final l = context.l10n;
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
