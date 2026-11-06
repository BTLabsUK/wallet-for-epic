// SPDX-License-Identifier: Apache-2.0
/// The levels' parts of the web preview: the first-start step on every visit, and the Epicbox
/// relay going quiet with the offer to move (the real notifier waits two minutes
/// and asks the status site; the preview plays it in seconds against [PreviewDirectory]'s
/// list). Same API as `relay_switch_providers.dart`, so the screens do not know the difference.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connection_state.dart';
import '../desktop/data/mock_hosts.dart';
import '../levels/first_start.dart';
import '../levels/level_providers.dart' show levelFeaturesProvider;
import '../levels/relay_switch.dart';
import '../levels/relay_switch_providers.dart';
import '../network.dart' show EpicboxRelay;
import '../providers.dart' show sessionProvider, walletConfigProvider;
import '../ui/status.dart' show EpicboxState;
import '../wallet_service.dart' show WalletConfig, WalletError, WalletErrorKind;
import 'preview_live.dart';

/// `?relaydown` on the page's URL: the relay is gone as soon as Home opens.
bool get previewRelayDownAtOnce => Uri.base.queryParameters.containsKey('relaydown');

/// `?relaymove` on the page's URL: a contact has moved relay and a BT Labs service asks to.
bool get previewRelayMove => Uri.base.queryParameters.containsKey('relaymove');

/// How long after Home opens the fake relay goes quiet (level 1), and how long it must have
/// been quiet before the move is offered.
const Duration previewRelayDownAfter = Duration(seconds: 45);
const Duration previewOfferAfter = Duration(seconds: 6);

/// How long "Keep waiting" holds the offer back.
const Duration previewKeepWaitingFor = Duration(seconds: 40);

/// The first-start step shows on every visit: the preview keeps nothing across a reload (its
/// wallet is in memory), so a visit is always a fresh install. Answering it hides it.
class PreviewFirstStart extends FirstStartNotifier {
  @override
  bool build() => true;
}

/// The relay offer for the presentation. The fake relay stops answering
/// [previewRelayDownAfter] after the wallet opens (at once with `?relaydown`), and
/// [previewOfferAfter] later the move to a relay the preview directory lists as healthy is
/// offered; accepting gives the wallet a new address on it.
class PreviewRelaySwitch extends RelaySwitchNotifier {
  Timer? _drop;
  Timer? _offer;
  DateTime? _keptAt;
  bool _moving = false;

  @override
  RelaySwitchOffer? build() {
    final session = ref.watch(sessionProvider);
    final prompt = ref.watch(levelFeaturesProvider.select((f) => f.relaySwitchPrompt));
    ref.onDispose(() {
      _drop?.cancel();
      _offer?.cancel();
    });
    if (session is! PreviewSession || !prompt) return null;
    ref.listen(walletStatusProvider.select((s) => s.epicbox), (_, epicbox) {
      if (epicbox == EpicboxState.offline) {
        _arm();
      } else {
        _offer?.cancel();
        _offer = null;
        _keptAt = null;
        if (state != null) state = null;
      }
    });
    _drop = Timer(previewRelayDownAtOnce ? const Duration(seconds: 2) : previewRelayDownAfter, session.dropRelay);
    return null;
  }

  void _arm() {
    if (_offer != null) return;
    _offer = Timer(previewOfferAfter, () {
      _offer = null;
      if (!ref.mounted) return;
      final kept = _keptAt;
      if (kept != null && DateTime.now().difference(kept) < previewKeepWaitingFor) {
        _arm();
        return;
      }
      final session = ref.read(sessionProvider);
      if (session is! PreviewSession || session.relayUp) return;
      // The second server of the shipped list, named by its operator as the real offer names
      // a candidate (`relayCandidates`): the same entry the preview directory lists healthy.
      final to = EpicboxRelay(host: mockBoxAt(1));
      state = RelaySwitchOffer(
        from: EpicboxRelay(host: mockBox),
        to: to,
        name: mockBoxAt(1),
        address: addressAtRelay(session.address, to),
      );
    });
  }

  @override
  void keepWaiting() {
    _keptAt = DateTime.now();
    state = null;
    _arm();
  }

  @override
  Future<RelaySwitchResult?> accept(WidgetRef widgetRef) async {
    final offer = state;
    final session = ref.read(sessionProvider);
    if (offer == null || session is! PreviewSession || _moving) return null;
    _moving = true;
    try {
      // The wallet takes a moment to move, as the real one does.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      final address = offer.address;
      if (address == null) {
        throw const WalletError(kind: WalletErrorKind.invalidArgument, message: 'no address');
      }
      session.moveRelay(address);
      final result = RelaySwitchResult(from: offer.from, relay: offer.to, name: offer.name, address: address);
      if (ref.mounted) {
        // The wallet's config follows the move, as `switchServersLive` makes it: Receive's
        // state line and the Epicbox sheet then name the new server.
        final config = ref.read(walletConfigProvider);
        if (config != null) {
          ref
              .read(walletConfigProvider.notifier)
              .select(
                WalletConfig(
                  dataDir: config.dataDir,
                  chain: config.chain,
                  nodeUrl: config.nodeUrl,
                  nodeApiSecret: config.nodeApiSecret,
                  epicboxDomain: offer.to.host,
                  epicboxPort: offer.to.port,
                  walletId: config.walletId,
                  offline: config.offline,
                ),
              );
        }
        state = null;
        _keptAt = null;
        ref.read(relaySwitchResultProvider.notifier).set(result);
      }
      return result;
    } finally {
      _moving = false;
    }
  }
}
