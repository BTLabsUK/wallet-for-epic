/// Tor on the phone, as the user sees it: the one "Tor receiving" switch (Receive and
/// Settings share it, [phoneTorProvider] is the one source of truth), the status line under
/// it, and the words for each way Tor can fail. Tor is slower, more private, and blocked or
/// not allowed in some countries: that is all the app says about it (F21).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../phone_tor.dart';
import '../wallet_service.dart';
import 'theme/tokens.dart';

/// Tor's icon wherever a method or a status needs one: a private connection.
const IconData torIcon = Icons.private_connectivity;

/// Whether Receive's Tor tab and Settings' Tor block exist: the app has Tor and the
/// controller has read this wallet's onion. Before that the controller says `off` with no
/// onion, and nothing Tor shows, so no tab flashes on a phone without Tor.
bool torShown(PhoneTorState s) =>
    s.phase != PhoneTorPhase.unavailable && s.onion != null;

/// The key of the Tor receiving switch, for tests.
const Key torReceivingSwitchKey = ValueKey('tor-receiving-switch');

/// The key of the Tor status line, for tests.
const Key torStatusKey = ValueKey('tor-status');

/// The key of Retry under a failed Tor, for tests.
const Key torRetryKey = ValueKey('tor-retry');

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

/// The "Tor receiving" switch with its status under the title: off, connecting with a
/// progress bar, on, or why it stopped, then the one honest line about Tor. Retry follows a
/// failure. The same block on Receive and in Settings; [leading] adds the icon Settings' rows
/// have.
class TorReceivingBlock extends ConsumerWidget {
  const TorReceivingBlock({super.key, this.leading = false});

  final bool leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context);
    final state = ref.watch(phoneTorProvider);
    final status = torStatusOf(l, t, state);
    final busy = state.phase == PhoneTorPhase.unavailable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: torReceivingSwitchKey,
          secondary: leading ? const Icon(torIcon) : null,
          contentPadding: leading
              ? null
              : const EdgeInsetsDirectional.only(start: 4, end: 8),
          title: Text(l.torReceivingTitle),
          isThreeLine: true,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Semantics(
                key: torStatusKey,
                liveRegion: true,
                container: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: ExcludeSemantics(
                        child: Icon(status.icon, size: 16, color: status.color),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        status.text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: status.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (status.progress case final progress?)
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      value: progress,
                      semanticsLabel: status.text,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                l.torHonestLine,
                style: theme.textTheme.bodySmall?.copyWith(color: t.dim),
              ),
            ],
          ),
          value: state.receiving,
          onChanged: busy
              ? null
              : (on) => ref.read(phoneTorProvider.notifier).setReceiving(on),
        ),
        if (status.retry)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: leading ? 60 : 12),
              child: TextButton.icon(
                key: torRetryKey,
                style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                icon: const Icon(Icons.refresh),
                label: Text(l.commonRetry),
                onPressed: () => ref.read(phoneTorProvider.notifier).retry(),
              ),
            ),
          ),
      ],
    );
  }
}
