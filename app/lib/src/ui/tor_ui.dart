// SPDX-License-Identifier: Apache-2.0
/// Tor on the phone, as the user sees it: the one Tor switch in Settings › Privacy
/// ([phoneTorProvider] is the one source of truth), its state in the same four words
/// everywhere, and the words for each way Tor can fail.
library;

import 'package:flutter/material.dart';
import 'status_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../phone_tor.dart';
import '../tor_phone.dart';
import '../tor_routes.dart';
import '../wallet_service.dart';
import 'info_hint.dart';
import 'settings_sections.dart' show SettingsSection, openSettingsSection;
import 'theme/advanced.dart';
import 'theme/tokens.dart';

/// Tor's icon wherever a method or a status needs one: a private connection.
const IconData torIcon = EpicGlyphs.tor;

/// Whether Receive's Link · Tor address and Settings' Tor switch exist: the app has Tor and the
/// controller has read this wallet's onion. Before that the controller says `off` with no
/// onion, and nothing Tor shows, so no tab flashes on a phone without Tor.
bool torShown(PhoneTorState s) =>
    s.phase != PhoneTorPhase.unavailable && s.onion != null;

/// The key of the Tor switch in Settings › Privacy, for tests.
const Key torReceivingSwitchKey = ValueKey('tor-receiving-switch');

/// The key of the line under the Tor switch that names the locking mode, for tests.
const Key torLockedLineKey = ValueKey('tor-locked-line');

/// The key of the Tor status line, for tests.
const Key torStatusKey = ValueKey('tor-status');

/// The key of Retry under a failed Tor, for tests.
const Key torRetryKey = ValueKey('tor-retry');

/// The key of Receive's link to the Tor switch in Settings, for tests.
const Key torSettingsLinkKey = ValueKey('tor-settings-link');

/// Why Tor is not working, in one short sentence.
String torFailureText(AppLocalizations l, TorFailure failure) =>
    switch (failure) {
      TorFailure.missing => l.torFailureMissing,
      TorFailure.start => l.torFailureStart,
      TorFailure.network => l.torFailureNetwork,
      TorFailure.clock => l.torFailureClock,
      TorFailure.listener => l.torFailureListener,
      TorFailure.stopped => l.torFailureStopped,
      TorFailure.publish => l.torFailurePublish,
      TorFailure.keys => l.torFailureKeys,
    };

/// What the status line says for [state], with the icon and colour that go with it, and
/// whether Retry belongs under it.
({IconData icon, String text, Color color, bool retry, double? progress})
torStatusOf(AppLocalizations l, WalletTokens t, PhoneTorState state) {
  final failure = state.failure;
  return switch (state.phase) {
    PhoneTorPhase.unavailable => (
      icon: torIcon,
      text: l.torFailureMissing,
      color: t.dim,
      retry: false,
      progress: null,
    ),
    PhoneTorPhase.off => (
      icon: torIcon,
      text: l.torStateOff,
      color: t.dim,
      retry: false,
      progress: null,
    ),
    PhoneTorPhase.starting => (
      icon: torIcon,
      text: l.torStateStarting(state.progress ?? 0),
      color: t.dim,
      retry: false,
      progress: (state.progress ?? 0) / 100,
    ),
    PhoneTorPhase.connected when failure != null => (
      icon: Icons.error_outline,
      text: l.torStateNotReachable(torFailureText(l, failure)),
      color: t.risk,
      retry: true,
      progress: null,
    ),
    PhoneTorPhase.connected => (
      icon: torIcon,
      text: l.torStatePublishing,
      color: t.dim,
      retry: false,
      progress: null,
    ),
    PhoneTorPhase.ready => (
      icon: torIcon,
      text: l.torStateReady,
      color: t.ok,
      retry: false,
      progress: null,
    ),
    PhoneTorPhase.failed => (
      icon: Icons.error_outline,
      text: torFailureText(l, failure ?? TorFailure.stopped),
      color: t.risk,
      retry: true,
      progress: null,
    ),
  };
}

/// The Tor switch's state in one word, the same everywhere: Off, Starting…, On, Not
/// connected.
String torWord(AppLocalizations l, TorState state) => switch (state) {
  TorState.off => l.netStatusOff,
  TorState.starting => l.torWordStarting,
  TorState.on => l.netStatusOn,
  TorState.failed => l.torWordNotConnected,
};

/// The colour of [torWord]: faint when off, dim while starting, ok when on, risk when not
/// connected.
Color torWordColor(WalletTokens t, TorState state) => switch (state) {
  TorState.off => t.faint,
  TorState.starting => t.dim,
  TorState.on => t.ok,
  TorState.failed => t.risk,
};

/// Settings › Privacy's one Tor switch: the phone's per-wallet switch ([PhoneTor.setReceiving]).
/// The row is the label "Tor network" with the explanation behind its info icon; its line
/// shows only a state that needs saying: "Starting…", or "Not connected" with Retry.
/// No confirmation and no other change: Tor on routes, nothing the user chose moves.
class TorSwitchTile extends ConsumerWidget {
  const TorSwitchTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final tor = ref.watch(phoneTorProvider);
    final state = phoneTorState(tor);
    final failed = state == TorState.failed;
    final busy = tor.phase == PhoneTorPhase.unavailable;
    // Advanced › Network: Tor only locks the switch on, Offline turns it off and away.
    final mode = AdvancedOptions.of(context).networkMode;
    final locked = mode != NetworkMode.standard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HintSwitchTile(
          key: torReceivingSwitchKey,
          icon: torIcon,
          title: l.torNetworkLabel,
          hint: l.torNetworkHint,
          sheetTitle: l.torNetworkLabel,
          sheetIcon: torIcon,
          subtitle: switch (state) {
            TorState.failed || TorState.starting => Semantics(
              key: torStatusKey,
              liveRegion: true,
              container: true,
              child: Text(
                failed ? l.torWordNotConnected : l.torWordStarting,
                style: failed
                    ? theme.textTheme.bodyMedium?.copyWith(color: t.risk)
                    : null,
              ),
            ),
            _ => null,
          },
          value: switch (mode) {
            NetworkMode.torOnly => true,
            NetworkMode.killSwitch => false,
            NetworkMode.standard || NetworkMode.nodeOnly => tor.receiving,
          },
          onChanged: busy || locked
              ? null
              : (on) => ref.read(phoneTorProvider.notifier).setReceiving(on),
        ),
        if (locked)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InkWell(
              key: torLockedLineKey,
              onTap: () =>
                  openSettingsSection(context, SettingsSection.advanced),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(60, 4, 16, 8),
                child: Text(
                  mode == NetworkMode.torOnly
                      ? l.netBlockTorOnly
                      : mode == NetworkMode.killSwitch
                      ? l.netBlockKillSwitch
                      : l.netBlockNodeOnly,
                  style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
                ),
              ),
            ),
          ),
        if (failed && !mode.restricted)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 60),
              child: TextButton(
                key: torRetryKey,
                style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                onPressed: () => ref.read(phoneTorProvider.notifier).retry(),
                child: Text(l.commonRetry),
              ),
            ),
          ),
      ],
    );
  }
}

/// Receive's Link tab under the onion address: "Tor · Starting…" (or On, Not connected),
/// why the address is not reachable yet when that is known, Retry after a failure, and a link
/// to the switch in Settings › Privacy.
class TorStateLine extends ConsumerWidget {
  const TorStateLine({super.key, required this.openSettings});

  final VoidCallback openSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final tor = ref.watch(phoneTorProvider);
    final state = phoneTorState(tor);
    final status = torStatusOf(l, t, tor);
    // Starting, on and ready say it in the state word; a failure says why.
    final why = status.retry ? status.text : null;
    final quiet = TextButton.styleFrom(minimumSize: const Size(48, 44));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          key: torStatusKey,
          liveRegion: true,
          container: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    state == TorState.failed ? Icons.error_outline : torIcon,
                    size: 16,
                    color: torWordColor(t, state),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${l.netStatusTor} · ${torWord(l, state)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: torWordColor(t, state),
                      ),
                    ),
                  ),
                ],
              ),
              if (why != null)
                Text(
                  why,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
                ),
            ],
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: [
            if (status.retry)
              TextButton(
                key: torRetryKey,
                style: quiet,
                onPressed: () => ref.read(phoneTorProvider.notifier).retry(),
                child: Text(l.commonRetry),
              ),
            TextButton(
              key: torSettingsLinkKey,
              style: quiet,
              onPressed: openSettings,
              child: Text(l.torSettingsLink),
            ),
          ],
        ),
      ],
    );
  }
}

/// What a connection that goes [way] says about Tor, as desktop's status rows: "Over Tor" (ok),
/// "Waiting for Tor" (warn) while Tor starts, "Waiting for Tor" in the risk colour with
/// [detail] "Tor is not connected." when it failed. null on the clearnet or with Tor off.
({String word, Color color, String? detail})? torWayWords(
  AppLocalizations l,
  WalletTokens t,
  TorWay way,
) => switch (way) {
  TorWay.overTor => (word: l.torWayOver, color: t.ok, detail: null),
  TorWay.wait => (word: l.torWayWaiting, color: t.warn, detail: null),
  TorWay.blocked => (
    word: l.torWayWaiting,
    color: t.risk,
    detail: l.torWayNotConnected,
  ),
  TorWay.clearnet || TorWay.needsTor || TorWay.off => null,
};

/// What [route] does under the Tor switch right now: "Over Tor", "Waiting for Tor" (warn) or
/// "Waiting for Tor" in the risk colour when Tor is not connected; nothing (SizedBox.shrink) on
/// the clearnet or with Tor off. Reads phoneTorProvider.
class TorWayLine extends ConsumerWidget {
  const TorWayLine({super.key, required this.route});

  final TorRoute route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = phoneTorState(ref.watch(phoneTorProvider));
    final words = torWayWords(
      context.l10n,
      context.tokens,
      torWay(route, state),
    );
    if (words == null) return const SizedBox.shrink();
    return Semantics(
      container: true,
      liveRegion: true,
      label: [words.word, ?words.detail].join(', '),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(torIcon, size: 16, color: words.color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              words.word,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: words.color),
            ),
          ),
        ],
      ),
    );
  }
}
