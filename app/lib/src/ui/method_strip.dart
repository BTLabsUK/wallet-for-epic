// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../tor_build.dart';
import '../settings.dart';
import 'info_hint.dart';
import 'method_art.dart';
import 'method_icons.dart';
import 'theme/tokens.dart';

export 'method_art.dart' show TransferMethod;

/// The key of the strip, for tests.
const Key methodStripKey = ValueKey('method-strip');

/// The guide id of Send's method strip: one id for the place, whichever method it explains.
const String sendMethodTipId = 'send-method';

/// The guide id of Receive's method strip, shared by its three tabs.
const String receiveMethodTipId = 'receive-method';

/// The key of a guide's X, for tests.
Key tipHideKey(String id) => ValueKey('tip-hide-$id');

/// How much room a guide box keeps free at its end for the X.
const double _closeRoom = 48;

/// An inline guide the user can close for good with a small X at its top end. Closed, it keeps
/// its exact size and leaves the space empty, so nothing below moves; the guide fades out
/// over 200 ms (at once with reduced motion). The ids closed are kept in
/// `AppSettings.hiddenTips`; Show tips again in Settings brings them back.
///
/// The box inside reads [DismissibleTip.endRoom] to keep its text clear of the X.
class DismissibleTip extends ConsumerWidget {
  const DismissibleTip({super.key, required this.id, required this.child});

  /// Stable per place on screen, not per variant the guide shows.
  final String id;
  final Widget child;

  /// The end padding a box needs inside a [DismissibleTip] so its text never runs under the
  /// X; 0 outside one.
  static double endRoom(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TipScope>() == null
      ? 0
      : _closeRoom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final settings = ref.watch(appSettingsProvider).value;
    // Until the settings are read, the guide waits unseen rather than flashing.
    final shown = settings != null && !settings.hiddenTips.contains(id);
    final still = MediaQuery.disableAnimationsOf(context);
    void hide() => ref.read(appSettingsProvider.notifier).hideTip(id);
    return IgnorePointer(
      ignoring: !shown,
      child: ExcludeSemantics(
        excluding: !shown,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: still ? Duration.zero : const Duration(milliseconds: 200),
          curve: Curves.easeIn,
          child: Stack(
            children: [
              _TipScope(child: child),
              PositionedDirectional(
                top: 0,
                end: 0,
                // One node, "Hide tip, button": a tap there closes the guide and nothing under it.
                child: Semantics(
                  container: true,
                  label: context.l10n.tipHide,
                  button: true,
                  excludeSemantics: true,
                  onTap: hide,
                  child: IconButton(
                    key: tipHideKey(id),
                    tooltip: context.l10n.tipHide,
                    iconSize: 18,
                    color: t.dim,
                    constraints: const BoxConstraints.tightFor(
                      width: _closeRoom,
                      height: _closeRoom,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close),
                    onPressed: hide,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marks a box as sitting inside a [DismissibleTip].
class _TipScope extends InheritedWidget {
  const _TipScope({required super.child});

  @override
  bool updateShouldNotify(_TipScope oldWidget) => false;
}

/// What a method means, under Send's selector and at the top of each Receive tab: its picture
/// on the left, one short line on the right, and the rest behind the method's ⓘ, the same
/// shape for every method (the desktop's Send strip does the same). [receiving] picks
/// Receive's words; [overTor] adds "Over Tor." to the ⓘ's text while the method's connection
/// goes through Tor. A new method fades in over 160 ms; with reduced motion it swaps at once.
class MethodStrip extends StatelessWidget {
  const MethodStrip({
    super.key,
    required this.method,
    this.receiving = false,
    this.overTor = false,
  });

  final TransferMethod method;
  final bool receiving;
  final bool overTor;

  /// The line for [method] and what its ⓘ says, on Send or on Receive.
  static (String title, String line) words(
    AppLocalizations l,
    TransferMethod method, {
    bool receiving = false,
  }) => receiving
      ? switch (method) {
          TransferMethod.epicbox => (
            l.methodReceiveEpicboxShort,
            l.methodReceiveEpicboxMore,
          ),
          TransferMethod.direct => (
            l.methodReceiveDirectTitle,
            l.methodReceiveDirectLine,
          ),
          TransferMethod.qr => (l.methodReceiveQrTitle, l.methodReceiveQrLine),
          TransferMethod.file => (
            l.methodReceiveFileTitle,
            l.methodReceiveFileLine,
          ),
        }
      : switch (method) {
          TransferMethod.epicbox => (
            l.methodSendEpicboxTitle,
            l.methodSendEpicboxLine,
          ),
          TransferMethod.direct => (
            l.methodSendHttpTitle,
            torBuilt ? l.methodSendDirectLine : l.methodSendDirectLineNoTor,
          ),
          TransferMethod.qr => (l.methodSendQrTitle, l.methodSendQrLine),
          TransferMethod.file => (l.methodSendFileTitle, l.methodSendFileLine),
        };

  /// The method's name, the ⓘ sheet's title.
  static String name(AppLocalizations l, TransferMethod method) => switch (method) {
    TransferMethod.epicbox => l.methodEpicbox,
    TransferMethod.direct => MethodIcons.familyName(l, MethodFamily.link),
    TransferMethod.qr => MethodIcons.fullName(l, MethodKind.directQr),
    TransferMethod.file => MethodIcons.fullName(l, MethodKind.directFile),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final l = context.l10n;
    final (line, words) = MethodStrip.words(l, method, receiving: receiving);
    final more = overTor ? l.methodLineOverTor(words) : words;
    final still = MediaQuery.disableAnimationsOf(context);
    final text = Row(
      children: [
        Flexible(
          child: Text(
            line,
            style: theme.textTheme.bodyLarge?.copyWith(color: t.text),
          ),
        ),
        InfoHint(more, title: name(l, method)),
      ],
    );
    return Container(
      key: methodStripKey,
      padding: EdgeInsetsDirectional.fromSTEB(
        8,
        8,
        DismissibleTip.endRoom(context).clamp(12, double.infinity),
        8,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(t.radiusSmall),
      ),
      child: AnimatedSwitcher(
        duration: still ? Duration.zero : const Duration(milliseconds: 160),
        // Large text gets the strip's whole width: the picture goes above the words.
        child: MediaQuery.textScalerOf(context).scale(1) > 1.3
            ? Column(
                key: ValueKey(method),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [MethodArt(method), const SizedBox(height: 4), text],
              )
            : Row(
                key: ValueKey(method),
                children: [
                  MethodArt(method),
                  const SizedBox(width: 12),
                  Expanded(child: text),
                ],
              ),
      ),
    );
  }
}
