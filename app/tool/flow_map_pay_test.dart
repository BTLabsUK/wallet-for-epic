// SPDX-License-Identifier: Apache-2.0
// Flow map "pay" part: shots of the screens the tour does not reach (scanner, scan result sheets,
// Send/Receive states). Harness copied from screenshot_tour_test.dart.
//
// Screenshot tour: renders every reachable screen with real fonts, in light and dark theme, and
// writes PNGs to `build/shots-app/`. Visual QA without a device.
//
//   . tools/env.sh && cd app && flutter test tool/screenshot_tour_test.dart
//
// TOUR_SHOTS_OUT=<dir> writes there instead; SHOTS_META=1 also writes `<shot>.json` beside each
// shot (tool/shot_meta.dart) for the screen catalog (tools/screens.sh).
//
// A narrower or shorter phone: `--dart-define=TOUR_WIDTH=360 --dart-define=TOUR_HEIGHT=640`
// writes to `build/shots-app-w360x640/`.
//
// In another language (de, pl, ru, zh), shots go to `build/shots-app/<code>/`:
//
//   flutter test tool/screenshot_tour_test.dart --dart-define=TOUR_LOCALE=de
//
// Chinese needs a CJK font: the tour then draws everything with Noto Sans CJK from the system
// (`fonts-noto-cjk`), since the test engine falls back to no other font.
//
// Each screen is its own test, so a Flutter error (overflow, exception) fails that test and its
// name says which screen and theme caused it. Everything runs on the same fakes as
// `test/wallet_flow_test.dart`; nothing touches the network or the native library.

import 'dart:async';
import 'package:epic_wallet/src/ui/kit/kit_tab_bar.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:epic_wallet/src/ui/scan_screen.dart';
import 'package:epic_wallet/src/ui/scanner_backend.dart' show CameraTurns;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:epic_wallet/src/connection_grace.dart' show connectionGraceLengthProvider;
import 'package:epic_wallet/src/name_service/payment_refusals.dart' show PaymentRefusals, paymentRefusalsProvider;
import 'package:epic_wallet/src/name_service/membership.dart' show nameServiceMembershipProvider;
import 'package:epic_wallet/src/name_service/pins.dart' show LinkMemory, ListingPin, pinKey;
import 'package:epic_wallet/src/scan/incoming_link.dart' show linkClockProvider;
import '../test/name_service_vectors_support.dart' show callKey;
import '../test/support/link_support.dart' show FakeMembership, LinkVectors, linkNow, vectorServiceKey;
import 'package:epic_wallet/src/settings_file/host_settings.dart';
import 'package:epic_wallet/src/desktop/data/mock_hosts.dart';
import 'package:epic_wallet/src/app.dart';
import 'package:epic_wallet/src/mock_fixtures.dart';
import 'package:epic_wallet/src/l10n.dart';
import 'package:epic_wallet/src/network.dart';
import 'package:epic_wallet/src/onion_notice.dart' show onionNoticeKey, onionNoticeSeen;
import 'package:epic_wallet/src/pairing_providers.dart' show pairingRefusalsProvider;
import 'package:epic_wallet/src/phone_tor.dart';
import 'package:epic_wallet/src/scan/incoming_link.dart' show incomingLinkProvider;
import 'package:epic_wallet/src/price.dart';
import 'package:epic_wallet/src/providers.dart';
import 'package:epic_wallet/src/relay_directory.dart';
import 'package:epic_wallet/src/secret_store.dart';
import 'package:epic_wallet/src/send_preflight.dart';
import 'package:epic_wallet/src/slate_files.dart';
import 'package:epic_wallet/src/password_lists.dart';
import 'package:epic_wallet/src/advanced.dart';
import 'package:epic_wallet/src/settings.dart';
import 'package:epic_wallet/src/tor_licence.dart';
import 'package:epic_wallet/src/tor_location.dart';
import 'package:epic_wallet/src/levels/relay_switch.dart' show RelaySwitchOffer;
import 'package:epic_wallet/src/levels/relay_switch_providers.dart'
    show RelaySwitchNotifier, RelaySwitchResult, relaySwitchProvider, relaySwitchResultProvider;
import 'package:epic_wallet/src/ui/kit/kit_keypad.dart' show KitKeypad;
import 'package:epic_wallet/src/ui/kit/kit_button.dart' show KitButton;
import 'package:epic_wallet/src/ui/common.dart'
    show ScreenBody, epicText;
import 'package:epic_wallet/src/ui/invoice_request_screen.dart' show requestShowQrKey, InvoiceRequestScreen;
import 'package:epic_wallet/src/ui/qr_camera.dart';
import 'package:epic_wallet/src/server_icons.dart';
import 'package:epic_wallet/src/settings_file/network_mode_file.dart' show networkModeKey, networkModeText;
import 'package:epic_wallet/src/network_gate.dart' show NetGate;
import 'package:epic_wallet/src/ui/finished_not_posted.dart' show FinishedNotPosted;
import 'package:epic_wallet/src/ui/settings_history.dart';
import '../test/support/fake_history_files.dart';
import 'package:epic_wallet/src/ui/theme/fonts.dart';
import 'package:epic_wallet/src/ui/send_screen.dart'
    show sendAmountFieldKey, sendFileAmountFieldKey, sendRecipientFieldKey, sendReplyFieldKey, sendReviewButtonKey;
import 'package:epic_wallet/src/updater.dart';
import 'package:epic_wallet/src/wallet_service.dart';
import 'package:epic_wallet/src/epic1.dart' show FakeEpic1;
import 'package:epic_wallet/src/ui/epic1/epic1_receive.dart' show epic1AskAmountKey;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shot_meta.dart';


/// A mid-size Android phone (Pixel 7 class): 412 x 915 dp at 2.625.
/// `--dart-define=TOUR_WIDTH=360` takes the narrowest phone we support instead.
const Size _logicalSize = Size(
  int.fromEnvironment('TOUR_WIDTH', defaultValue: 412) * 1.0,
  int.fromEnvironment('TOUR_HEIGHT', defaultValue: 915) * 1.0,
);
const double _pixelRatio = 2.625;

/// The language the tour runs in; `en` follows the system, like a new install.
const String _tourLocale = String.fromEnvironment(
  'TOUR_LOCALE',
  defaultValue: 'en',
);

const String _pin = '123456';
const String _mainnetDir = '/fake/wallets/mainnet';

final String _outDir = () {
  final asked = Platform.environment['TOUR_SHOTS_OUT'];
  if (asked != null && asked.isNotEmpty) return asked;
  // `flutter test` runs with the package root (app/) as the working directory.
  final coord = Directory('${Directory.current.parent.path}/.coord');
  final width = _logicalSize.width == 412 && _logicalSize.height == 915
      ? ''
      : '-w${_logicalSize.width.round()}${_logicalSize.height == 915 ? '' : 'x${_logicalSize.height.round()}'}';
  return _tourLocale == 'en'
      ? '${coord.path}/shots-app$width'
      : '${coord.path}/shots-app$width/$_tourLocale';
}();

BigInt _epic(num value) => BigInt.from((value * 100000000).round());

/// A valid-looking epicbox address: 52 base58 characters, then the relay.
String _address(String seed) {
  const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  final buffer = StringBuffer('es');
  var n = seed.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0x7fffffff);
  while (buffer.length < 52) {
    n = (n * 1103515245 + 12345) & 0x7fffffff;
    buffer.write(alphabet[n % alphabet.length]);
  }
  return '$buffer@$mockBox';
}

final String _alice = _address('alice');
final String _bob = _address('bob');

final String _carol = _address('carol');

/// An operator's icon on the status site; the tour reads its bytes from
/// `test/fixtures/icons/<hash>-128.png` ([_iconFetch]).
ServerIcon _icon(String hash) => ServerIcon(
  hash: hash,
  urls: {128: Uri.parse(mockIconUrl(hash, 128))},
);

const _btlIcon = '7f31acd64c95a28ca70a';
const _epicIcon = '41bec7e038f3b806b2db';
const _cypherIcon = '9a573fcde155e6753f68';

/// The icons' bytes from the fixtures, by the hash the URL names.
Future<Uint8List?> _iconFetch(Uri url) async {
  final hash = url.pathSegments.last.split('-').first;
  final file = File('test/fixtures/icons/$hash-128.png');
  return file.existsSync() ? file.readAsBytesSync() : null;
}

/// The monitor as the tour sees it: the mainnet operators, names and icons as
/// the status site lists them (the third has no icon), one node behind, one relay down.
class _Relays implements RelayDirectory, NodeDirectory, NetworkDirectory {
  @override
  Future<List<RelayStatus>> relays(String chain) async => chain == 'mainnet'
      ? [
          RelayStatus(
            relay: EpicboxRelay(host: mockBox),
            healthy: true,
            verified: true,
            operator: 'Epic Cash',
            latencyMs: 412,
            uptime24h: 0.998,
            icon: _icon(_epicIcon),
          ),
          RelayStatus(
            relay: EpicboxRelay(host: mockBoxAt(2)),
            healthy: true,
            verified: true,
            operator: mockNodeOp(2),
            latencyMs: 766,
            uptime24h: 1,
          ),
          RelayStatus(
            relay: EpicboxRelay(host: mockBoxAt(1)),
            healthy: false,
            verified: false,
            operator: 'Cypher Stack',
            uptime24h: 0.71,
            icon: _icon(_cypherIcon),
          ),
        ]
      : chain == 'floonet'
      // The push relay: the monitor lists it under floonet only.
      ? [
          RelayStatus(
            relay: EpicboxRelay(host: mockBoxAt(3)),
            healthy: true,
            verified: true,
            operator: 'btlabs',
            latencyMs: 45,
            uptime24h: 0.9999,
            icon: _icon(_btlIcon),
          ),
        ]
      : const [];

  @override
  Future<List<NodeStatus>> nodes(String chain) async {
    if (chain != 'mainnet') return const [];
    final tip = _tip.toInt();
    return [
      NodeStatus(url: mockNodeAt(1), healthy: true, verified: true, operator: 'btlabs', height: tip, latencyMs: 20, state: NodeHealthState.healthy, nodeVersion: mockNodeVersion, tipLag: 0, peers: 61, uptime24h: mockNodeUptime, icon: _icon(_btlIcon)),
      NodeStatus(url: mockNodeAt(0), healthy: true, verified: true, operator: 'Epic Cash', height: tip, latencyMs: 733, state: NodeHealthState.healthy, nodeVersion: mockNodeVersion, tipLag: 0, peers: 54, uptime24h: mockNodeUptime, icon: _icon(_epicIcon)),
      NodeStatus(url: mockNodeAt(2), healthy: true, verified: true, operator: mockNodeOp(2), height: mockTip - 15000, latencyMs: 766, state: NodeHealthState.healthy, nodeVersion: mockNodeVersion, tipLag: 0, peers: 61, uptime24h: mockNodeUptime),
      NodeStatus(url: mockNodeAt(3), healthy: true, verified: true, operator: 'Cypher Stack', height: tip - 12, latencyMs: 1127, state: NodeHealthState.degraded, reason: 'behind', nodeVersion: mockNodeVersion, tipLag: 12, peers: 61, uptime24h: mockNodeUptime, icon: _icon(_cypherIcon)),
    ];
  }

  @override
  Future<NetworkStatus> network(String chain) async => NetworkStatus(
    tipHeight: _tip.toInt(),
    tipAgeSeconds: 40,
    releasedNodeVersion: mockNodeVersion,
    releasedWalletVersion: '4.1.0',
    nodesHealthy: 4,
    nodesTotal: 5,
    epicboxHealthy: 3,
    epicboxTotal: 4,
    medianNodeLatencyMs: 733,
    forked: false,
    healthScore: 90,
  );
}

/// The relay-down offer of level 1: Epicbox has been quiet, the next relay is ready. Switch moves
/// the wallet, as the real one does, and Receive then names the new server. It starts with no
/// offer and [show] raises it once the shell is up, as the 2-minute watch does: an offer standing
/// at the first frame makes RelayDownNotices read the localizations in initState (app bug, see
/// the l12 visit).
class _TourOffer extends RelaySwitchNotifier {
  static final _from = EpicboxRelay(host: mockBox);
  static final _to = EpicboxRelay(host: mockBoxAt(1));

  @override
  RelaySwitchOffer? build() => null;

  void show() => state = RelaySwitchOffer(from: _from, to: _to, name: mockBoxAt(1), address: _address('moved'));

  @override
  Future<RelaySwitchResult?> accept(WidgetRef widgetRef) async {
    state = null;
    final result = RelaySwitchResult(from: _from, relay: _to, name: mockBoxAt(1), address: _address('moved'));
    ref.read(relaySwitchResultProvider.notifier).set(result);
    return result;
  }
}

/// [floonetAddress] is valid on the other network only.
class _LinkSession extends FakeWalletSession {
  _LinkSession({super.summary, super.transactions});

  LinkMemory? memory;

  @override
  LinkMemory linkMemory() => memory ?? const LinkMemory();
}

class _Refuses implements PaymentRefusals {
  _Refuses(this.address);

  final String address;

  @override
  bool refusesPayments({String? pairingId, String? address}) => address == this.address;

  @override
  String? refusedName({String? pairingId, String? address}) => refusesPayments(address: address) ? 'BT Labs Bot' : null;
}

/// The verifier answers from the signatures the name service vectors list.
class _VectorService extends FakeWalletService {
  _VectorService({super.existingWallets, super.session});

  static final Set<String> listed = LinkVectors().listed;

  @override
  Future<bool> verifyListingSignature(String publicKeyText, String domain, Uint8List message, Uint8List der) async =>
      listed.contains(callKey(publicKeyText, domain, message, der));
}

class _OtherChainService extends FakeWalletService {
  _OtherChainService({super.existingWallets, super.session});

  @override
  bool validateEpicboxAddress({required String address}) =>
      address != floonetAddress && super.validateEpicboxAddress(address: address);

  @override
  bool epicboxAddressOtherChain({required String address}) => address == floonetAddress;
}

final String floonetAddress = 'f${_address('floo').substring(1)}';

class _Price implements PriceSource {
  @override
  Future<double?> price(String currency) async => switch (currency) {
    'btc' => 0.0000071,
    'eur' => 0.39,
    _ => 0.42,
  };
}

/// The node tip [FakeWalletService.nodeTip] reports.
final BigInt _tip = BigInt.from(mockTip);

_LinkSession _session() {
  final now = DateTime.now();
  int ago(Duration d) => now.subtract(d).millisecondsSinceEpoch ~/ 1000;
  final session = _LinkSession(
    summary: WalletSummary(
      lastConfirmedHeight: _tip,
      minimumConfirmations: BigInt.from(defaultMinimumConfirmations),
      total: _epic(1283.0678),
      spendable: _epic(1234.5678),
      awaitingConfirmation: _epic(12.5),
      awaitingFinalization: _epic(6),
      immature: _epic(4),
      locked: _epic(26),
      validatedWithNode: true,
    ),
    transactions: [
      fakeTx(
        id: 12,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000012',
        kind: TxKind.sent,
        status: TxStatus.awaitingRecipient,
        createdAtUnix: ago(const Duration(minutes: 20)),
        amountDebited: _epic(25.008),
        amountCredited: BigInt.zero,
        fee: _epic(0.008),
        numInputs: 1,
        numOutputs: 0,
        counterparty: _alice,
        note: 'Dinner on Friday',
        messages: const [
          SlateMessage(role: SlateRole.sender, text: 'My half of dinner'),
        ],
        cancellable: true,
      ),
      fakeTx(
        id: 11,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000011',
        kind: TxKind.sent,
        status: TxStatus.awaitingConfirmation,
        createdAtUnix: ago(const Duration(hours: 2)),
        amountDebited: _epic(40),
        amountCredited: _epic(29.992),
        fee: _epic(0.008),
        numInputs: 1,
        numOutputs: 1,
        kernelExcess: '08a4c7e1f2b3d4c5e6f708192a3b4c5d6e7f8091a2b3c4d5e6f708192a3b4c5d6e',
        counterparty: 'https://pay.example.com:3415',
      ),
      fakeTx(
        id: 10,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000010',
        kind: TxKind.received,
        status: TxStatus.awaitingConfirmation,
        createdAtUnix: ago(const Duration(hours: 3)),
        amountCredited: _epic(12.5),
        numOutputs: 1,
        counterparty: _bob,
        blockHeight: _tip - BigInt.from(3),
      ),
      fakeTx(
        id: 9,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000009',
        kind: TxKind.received,
        status: TxStatus.confirmed,
        createdAtUnix: ago(const Duration(days: 1, hours: 2)),
        amountCredited: _epic(150),
        numOutputs: 1,
        counterparty: _alice,
        note: 'Rent share, September',
        messages: const [
          SlateMessage(role: SlateRole.sender, text: 'September rent, thanks!'),
        ],
        blockHeight: _tip - BigInt.from(1500),
        blockTimeUnix: ago(const Duration(days: 1, hours: 2)),
        kernelExcess: '09b5d8f203c4e5d6f708192a3b4c5d6e7f8091a2b3c4d5e6f708192a3b4c5d6e7f',
        outputCommits: const [
          '08c1f0e3a2b4c6d8e0f1a3b5c7d9e1f3a5b7c9d1e3f5a7b9c1d3e5f7a9b1c3d5e7',
        ],
      ),
      fakeTx(
        id: 8,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000008',
        kind: TxKind.sent,
        status: TxStatus.confirmed,
        createdAtUnix: ago(const Duration(days: 3)),
        amountDebited: _epic(100),
        amountCredited: _epic(19.992),
        fee: _epic(0.008),
        numInputs: 2,
        numOutputs: 1,
        counterparty: _carol,
        blockHeight: _tip - BigInt.from(4300),
      ),
      fakeTx(
        id: 7,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000007',
        kind: TxKind.sentCancelled,
        status: TxStatus.cancelled,
        createdAtUnix: ago(const Duration(days: 5)),
        amountDebited: _epic(10.008),
        fee: _epic(0.008),
        numInputs: 1,
        counterparty: _bob,
      ),
      fakeTx(
        id: 6,
        slateId: 'a1b2c3d4-0001-4e5f-8a9b-000000000006',
        kind: TxKind.receivedCancelled,
        status: TxStatus.cancelled,
        createdAtUnix: ago(const Duration(days: 6)),
        amountCredited: _epic(3),
      ),
      // The chain check: another wallet on this recovery phrase spent and received coins.
      fakeTx(
        id: 31,
        kind: TxKind.sent,
        status: TxStatus.confirmed,
        origin: TxOrigin.otherWallet,
        createdAtUnix: ago(const Duration(days: 4)),
        amountDebited: _epic(35.4),
        blockHeight: _tip - BigInt.from(5700),
        blockTimeUnix: ago(const Duration(days: 4)),
        spentCommits: const ['08c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2'],
      ),
      fakeTx(
        id: 32,
        kind: TxKind.received,
        status: TxStatus.confirmed,
        origin: TxOrigin.otherWallet,
        createdAtUnix: ago(const Duration(days: 4, hours: 6)),
        amountCredited: _epic(6.2),
        blockHeight: _tip - BigInt.from(6100),
        blockTimeUnix: ago(const Duration(days: 4, hours: 6)),
        outputCommits: const ['09a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b7'],
      ),
      fakeTx(
        id: 5,
        kind: TxKind.coinbase,
        status: TxStatus.confirmed,
        createdAtUnix: ago(const Duration(days: 10)),
        amountCredited: _epic(8),
        blockHeight: _tip - BigInt.from(14400),
      ),
      fakeTx(
        key: 'c:restored-1',
        id: 2,
        kind: TxKind.received,
        status: TxStatus.confirmed,
        source: TxSource.restored,
        createdAtUnix: ago(const Duration(hours: 1)),
        timeUnix: ago(const Duration(days: 40)),
        blockHeight: _tip - BigInt.from(57600),
        blockTimeUnix: ago(const Duration(days: 40)),
        amountCredited: _epic(1000),
        outputCommits: const [
          '09d2a1b4c3e6f5a8b7d0c9e2f1a4b3c6d5e8f7a0b9c2d1e4f3a6b5c8d7e0f9a2b1',
        ],
      ),
      fakeTx(
        key: 's:imported-1',
        slateId: 'imported-1',
        kind: TxKind.sent,
        status: TxStatus.confirmed,
        source: TxSource.imported,
        createdAtUnix: ago(const Duration(days: 90)),
        amountDebited: _epic(55.008),
        fee: _epic(0.008),
        numInputs: 1,
        counterparty: _carol,
        note: 'Old laptop',
        blockHeight: _tip - BigInt.from(129600),
      ),
    ],
  );
  session.address = _address('me');
  session.contactsValue.addAll([
    Contact(id: 'c1', name: 'Alice', address: _alice, note: 'Flatmate'),
    Contact(id: 'c2', name: 'Bob', address: _bob),
  ]);
  return session;
}

/// Where the tour starts.
enum _Start { home }

class _Tour {
  _Tour(this.tester, this.theme);

  final WidgetTester tester;
  final ThemeMode theme;

  /// Start with Advanced options on, for visits to controls only it reveals.
  bool advanced = false;

  /// The stored Advanced choice (`AdvancedPrefs.encode`) a visit starts with, e.g. `|offline`.
  String? advancedPrefs;

  /// The visit's name, for the shot metadata.
  String visit = '';

  /// Epicbox addresses starting with `f` are the other network's.
  bool otherChain = false;

  /// Signed payment links: the verifier knows the vectors' signatures, the listing is a member.
  bool vectorLinks = false;
  String? refusedAddress;

  /// The core cannot pair (a pairing link then gets the "not here yet" sheet).
  bool pairingOff = false;
  bool relayBlocked = false;

  /// A fresh install at the first-start step: no stored marker, the gate holds every connection.
  bool freshInstall = false;

  /// The wallet opens in epic1 mode (its epic1 switch was on at unlock).
  bool epic1 = false;

  /// A relay offer standing from the start (level 1), as the notice shows it.
  bool relayOffer = false;

  /// The network mode a visit runs in (settings.toml's `[network] mode`); Normal when null.
  NetworkMode? mode;

  /// A designer-frame visit (`fr-<Frame>`, tool/tour/FRAMES.md): the frame's 390x844 at 2x, with
  /// its safe areas, on the frame's sample wallet.
  bool get frame => false;
  Size get logicalSize => _logicalSize;
  double get pixelRatio => _pixelRatio;

  /// Whether the visit is one of the Pairing and Invoices ones, kept apart in the catalogue.
  bool get isExperimental => false;

  /// The strings the screens show, so the tour finds buttons in any language.
  final AppLocalizations l = lookupAppLocalizations(const Locale(_tourLocale));
  final _boundary = GlobalKey();
  final store = MemorySecretStore();
  final bio = MemoryBiometricStore(available: true);
  final files = FakeHistoryFiles();

  /// The share sheet: what Share hands it, for the share card pictures.
  final slateFiles = FakeSlateFiles();
  late final _LinkSession session = _session();
  late final FakeWalletService service;

  /// The camera of the QR scan screen: a placeholder picture, and the codes the shots hand it.
  final camera = FakeQrCamera();

  /// Home's Scan tab and Send's scan button read the next queued text from here.
  final scanner = FakeQrScanner();

  Future<void> start(_Start from) async {
    store.values['app.theme'] = theme.name;
    // The old Advanced switch maps as at launch.
    final features = advanced ? 'recheckFromHeight,serverDetails,technicalDetails' : '';
    store.values['app.advanced_prefs'] = switch (advancedPrefs) {
      final prefs? when prefs.startsWith('|') => '$features$prefs',
      final prefs? => prefs,
      null => '$features|standard',
    };
    if (freshInstall) {
      store.values.remove('app.advanced_prefs');
      NetGate.holdFirstStart();
      addTearDown(NetGate.releaseFirstStart);
    }
    // The mode is kept in the settings file; every visit starts from Normal unless it says so.
    final runMode = mode ?? NetworkMode.standard;
    if (mode != null) hostSettings = hostSettings.withValues({networkModeKey: networkModeText(runMode)});
    NetGate.set(runMode);
    addTearDown(() {
      if (mode != null) hostSettings = hostSettings.withValues({networkModeKey: networkModeText(NetworkMode.standard)});
      NetGate.set(NetworkMode.standard);
    });
    if (_tourLocale != 'en') store.values['app.language'] = _tourLocale;
    store.values['wallet.mainnet.pinSealed'] = fakeSealedPassword(_pin);
    store.values['wallet.mainnet.backedUp'] = '1';
    // A wallet made on this version: the one-time Tor address notice is already seen.
    store.values[onionNoticeKey('mainnet', null)] = onionNoticeSeen;
    if (pairingOff) session.pairing.enabled = false;
    if (epic1) session.epic1Fake = FakeEpic1(on: true);
    service = (vectorLinks ? _VectorService.new : otherChain ? _OtherChainService.new : FakeWalletService.new)(
      existingWallets: {_mainnetDir},
      session: session,
    )..nodeTipValue = NodeTip(height: _tip, nodeVersion: mockNodeVersion);
    // Touch devices show no keyboard-focus rings; the test binding would otherwise draw them.
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
    tester.view.physicalSize = logicalSize * pixelRatio;
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _boundary,
        child: ProviderScope(
          retry: (_, _) => null,
          overrides: [
            relayProbeProvider.overrideWithValue(FakeRelayProbe()),
            // The app's own refusals, as main.dart sets them: a card that takes no payments.
            if (refusedAddress != null)
              paymentRefusalsProvider.overrideWithValue(_Refuses(refusedAddress!))
            else
              paymentRefusalsProvider.overrideWith((ref) => ref.watch(pairingRefusalsProvider)),
            if (vectorLinks) ...[
              linkClockProvider.overrideWithValue(() => linkNow),
              nameServiceMembershipProvider.overrideWithValue(FakeMembership(labels: {vectorServiceKey: 'Test Service'})),
            ],
            if (relayOffer) relaySwitchProvider.overrideWith(_TourOffer.new),
            // The pictures show the notices at once, not after the connection grace (item 11).
            connectionGraceLengthProvider.overrideWithValue(Duration.zero),
            walletServiceProvider.overrideWithValue(service),
            walletDirProvider.overrideWithValue(
              (chain) async => '/fake/wallets/${chain.name}',
            ),
            secretStoreProvider.overrideWithValue(store),
            biometricStoreProvider.overrideWithValue(bio),
            updatePlatformProvider.overrideWithValue(null),
            relayDirectoryProvider.overrideWithValue(_Relays()),
            serverIconFetchProvider.overrideWithValue(_iconFetch),
            slateFilesProvider.overrideWithValue(slateFiles),
            historyFilesProvider.overrideWithValue(files),
            priceSourceProvider.overrideWithValue(_Price()),
            qrScannerProvider.overrideWithValue(scanner),
            if (relayBlocked) listenerProvider.overrideWith(_BlockedListener.new),
            qrCameraFactoryProvider.overrideWithValue(() => camera),
            // The tour is the phone: QR is a method, File sits behind Advanced.
            phonePaymentsProvider.overrideWithValue(true),
            // This phone has Tor: the Receive tab and the Settings block exist. No restart
            // or stall timers of their own while the fake clock runs.
            torBundleFinderProvider.overrideWithValue(
              () async =>
                  const TorBundle(binary: '/data/app/lib/arm64/libtor.so'),
            ),
            networkChangesProvider.overrideWithValue(
              const Stream<bool>.empty(),
            ),
            phoneTorTimingProvider.overrideWithValue(
              PhoneTorTiming(
                backoff: [Duration(hours: 1)],
                sendWait: Duration(hours: 1),
              ),
            ),
          ],
          child: const WalletApp(),
        ),
      ),
    );
    await frames();
    // Unmounting cancels refresh timers before the test ends.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
    if (from == _Start.home) {
      await enter(l.pinLabel, _pin);
      // The listener subscribes once the wallet is open; the fake's stream is broadcast.
      session.listenerEvents.add(
        const ListenerEvent(kind: ListenerEventKind.connected, message: ''),
      );
      await frames();
    }
  }

  /// Lets the server tiles' icons load and decode (real async), then paints them.
  Future<void> images() async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
  }

  /// A second and a half of frames: long enough for route and dialog animations, and safe with
  /// spinners that never settle.
  Future<void> frames() async {
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// [ms] of frames, a tenth of a second each: timers fire on time and animations that start
  /// on the way get their frames, which one long pump would not give them.
  Future<void> elapse(int ms) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Waits for the Tor controller to have read the bundle and the onion, which it does on
  /// real async the fake clock does not move.
  Future<void> torOpened() async {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Navigator).first),
    );
    for (var i = 0; i < 50; i++) {
      final s = container.read(phoneTorProvider);
      if (s.onion != null || s.phase == PhoneTorPhase.unavailable) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
  }

  /// Tor's next event, with what `torStatus` answers afterwards, then frames and a slice of
  /// real time for the controller's work.
  Future<void> torEvent(
    TorEventKind kind, {
    int? progress,
    TorFailure? failure,
  }) async {
    session.torStatusValue = switch (kind) {
      TorEventKind.starting => TorStatus(
        kind: TorStatusKind.starting,
        progress: progress,
      ),
      TorEventKind.bootstrapped => const TorStatus(
        kind: TorStatusKind.bootstrapped,
      ),
      TorEventKind.ready => TorStatus(
        kind: TorStatusKind.ready,
        onion: session.onion,
      ),
      _ => TorStatus.off,
    };
    session.torEvents.add(
      TorEvent(
        kind: kind,
        progress: progress,
        failure: failure,
        onion: kind == TorEventKind.ready ? session.onion : null,
      ),
    );
    await frames();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await frames();
  }

  /// Flutter's own strings (date picker buttons), in the tour's language.
  MaterialLocalizations get material =>
      MaterialLocalizations.of(tester.element(find.byType(Navigator).first));

  /// Waits for the licence page to have read the licences, which it does on real async:
  /// until [until] is on screen and nothing loads any more.
  Future<void> licencesLoaded(Finder until) async {
    for (var i = 0; i < 200; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      if (until.evaluate().isNotEmpty &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
    await frames();
  }


  Future<void> push(Widget screen) async {
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    unawaited(navigator.push(MaterialPageRoute<void>(builder: (_) => screen)));
    await frames();
  }

  Future<void> tap(Finder finder) async {
    if (finder.evaluate().isEmpty) {
      // Lazy lists build only what is on screen.
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(finder.first);
    await tester.pump();
    await tester.tap(finder.first);
    await frames();
  }

  Future<void> tapText(String text) => tap(find.text(text));

  /// Opens Receive. The tour's wallet has a payment on its way, so the arriving sheet opens over
  /// Receive; it is closed here (the l16 shot keeps it).
  Future<void> openReceive() async {
    await tapText(l.homeReceiveButton);
    await frames();
    await closeArrival();
  }

  /// Closes the arriving sheet when it is open.
  Future<void> closeArrival() async {
    final done = find.text(l.commonDone);
    if (done.evaluate().isNotEmpty) {
      await tap(done.last);
      await frames();
    }
  }

  /// Receive's "Other ways" sheet, then its row titled [title].
  Future<void> receiveWay(String title) async {
    await tapText(l.phoneRecvOther);
    await tapText(title);
  }

  /// Types [text] on the PIN keypad; true when a keypad is on the screen.
  Future<bool> typeOnPad(String text) async {
    // The topmost keypad: a PIN page can sit over Send's amount keypad.
    final all = find.byType(KitKeypad);
    if (all.evaluate().isEmpty) return false;
    final pad = all.hitTestable().evaluate().isEmpty ? all.first : all.hitTestable().last;
    for (final digit in text.split('')) {
      await tester.tap(find.descendant(of: pad, matching: find.text(digit)).first);
      await tester.pump();
    }
    await frames();
    return true;
  }

  /// Answers a PIN ask: the keypad, or the PIN field where one is still shown.
  Future<void> enterPin() async {
    if (await typeOnPad(_pin)) return;
    final field = find.widgetWithText(TextField, l.pinLabel);
    if (field.evaluate().isEmpty) return;
    await tester.enterText(field, _pin);
    await frames();
  }

  Future<void> enter(String label, String text) async {
    if ((label == l.pinLabel || label == l.pinRepeatLabel) && await typeOnPad(text)) return;
    // The restore screen's phrase box has no label of its own (its hint sits inside it).
    // Send's amount is a hidden field the keypad writes into: it has no label of its own.
    final amountField = find.byWidgetPredicate((w) => w.key == sendAmountFieldKey || w.key == sendFileAmountFieldKey);
    if (label == l.sendAmountLabel('EPIC') && amountField.evaluate().isNotEmpty) {
      await tester.enterText(amountField.first, text);
      await frames();
      return;
    }
    final field = label == l.restorePhraseLabel ? find.byType(TextField) : find.widgetWithText(TextField, label);
    // Below a short screen's fold the field is built but offstage: ensureVisible brings it up.
    await tester.ensureVisible(label == l.restorePhraseLabel ? field.first : find.widgetWithText(TextField, label, skipOffstage: false).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(field.first, text);
    await frames();
  }

  /// Taps the review's send button, then answers the PIN dialog every send asks.
  Future<void> send(String amount) async {
    await tapText(l.sendReviewSendButton(amount));
    await enterPin();
  }

  Future<void> enterRecipient(String text) async {
    final field = find.byKey(sendRecipientFieldKey);
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    await frames();
  }

  /// Scrolls the frontmost list by [dy] logical pixels.
  Future<void> scroll(double dy) async {
    await tester.drag(find.byType(Scrollable).last, Offset(0, -dy));
    await frames();
  }

  /// Presses [button] and writes the picture it hands the share sheet as [name].png, with the
  /// text that goes with it as [name].txt.
  Future<void> shareShot(String name, Finder button) async {
    final before = slateFiles.sharedImages.length;
    await tester.ensureVisible(button);
    await frames();
    await tester.tap(button);
    final clock = Stopwatch()..start();
    while (slateFiles.sharedImages.length == before && clock.elapsed < const Duration(seconds: 30)) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(slateFiles.sharedImages.length, before + 1, reason: 'Share sent no picture');
    final shared = slateFiles.sharedImages.last;
    final file = File('$_outDir/$name-${theme.name}.png');
    await tester.runAsync(() async {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(shared.png, flush: true);
      await File('$_outDir/$name-${theme.name}.txt').writeAsString(shared.text, flush: true);
    });
    await frames();
  }

  Future<void> shot(String name) async {
    final file = File('$_outDir/$name-${theme.name}.png');
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    // flutter_test paints elevation as a solid black outline. Repaint with real shadows for
    // the capture only, because the test must end with the variable at its test value.
    await _repaint(boundary, shadows: true);
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    });
    if (shotMeta) {
      writeShotMeta(file.path, _boundary.currentContext! as Element, {
        'id': name,
        'visit': visit,
        'experimental': isExperimental,
        'advanced': advanced,
        'width': logicalSize.width.round(),
        'height': logicalSize.height.round(),
        'pixelRatio': pixelRatio,
        'theme': theme.name,
        'lang': _tourLocale,
      });
    }
    await _repaint(boundary, shadows: false);
    // ignore: avoid_print
    print('wrote ${file.path}');
  }

  /// [rect] of the screen, in logical pixels, as an image at [ratio] pixels each.
  Future<ui.Image> crop(Rect rect, double ratio) async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final screen = Offset.zero & boundary.size;
    final area = rect.intersect(screen);
    await _repaint(boundary, shadows: true);
    final image = await tester.runAsync(() async {
      final full = await boundary.toImage(pixelRatio: ratio);
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImageRect(
        full,
        Rect.fromLTRB(
          area.left * ratio,
          area.top * ratio,
          area.right * ratio,
          area.bottom * ratio,
        ),
        Offset.zero & area.size * ratio,
        Paint(),
      );
      full.dispose();
      return recorder.endRecording().toImage(
        (area.width * ratio).round(),
        (area.height * ratio).round(),
      );
    });
    await _repaint(boundary, shadows: false);
    return image!;
  }

  /// Writes [image] as `<name>-<theme>.png` beside the shots.
  Future<void> writePng(ui.Image image, String name) async {
    final file = File('$_outDir/$name-${theme.name}.png');
    await tester.runAsync(() async {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    });
    image.dispose();
    // ignore: avoid_print
    print('wrote ${file.path}');
  }

  Future<void> _repaint(RenderObject root, {required bool shadows}) async {
    debugDisableShadows = !shadows;
    void mark(RenderObject o) {
      o.markNeedsPaint();
      o.visitChildren(mark);
    }

    mark(root);
    await tester.pump();
  }
}
Future<void> _loadFonts() async {
  final dir =
      '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}'
      '/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String path) async =>
      ByteData.sublistView(Uint8List.fromList(await File(path).readAsBytes()));
  final roboto = FontLoader('Roboto');
  if (_tourLocale == 'zh') {
    // The first face of each collection; it has Latin, Cyrillic and Han glyphs.
    for (final weight in ['Regular', 'Bold']) {
      roboto.addFont(
        read('/usr/share/fonts/opentype/noto/NotoSansCJK-$weight.ttc'),
      );
    }
  } else {
    for (final face in [
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
      'Roboto-Light.ttf',
      'Roboto-Italic.ttf',
    ]) {
      roboto.addFont(read('$dir/$face'));
    }
  }
  await roboto.load();
  // The Protocol look's bundled faces (pubspec.yaml), which tests do not load by themselves. In
  // Chinese they are Noto Sans CJK too: the test engine falls back to no other font, while a
  // device falls back to its own CJK font.
  final cjk = _tourLocale == 'zh';
  for (final (family, file) in [
    ('Montserrat', cjk ? '/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc' : 'assets/fonts/Montserrat-SemiBold.ttf'),
    ('JetBrainsMonoNL', cjk ? '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc' : 'assets/fonts/JetBrainsMonoNL-Regular.ttf'),
    ('Lucide', 'assets/fonts/Lucide.ttf'),
    ('EpicStatusIcons', 'assets/fonts/EpicStatusIcons.ttf'), // the icon font is not loaded by the test binding
  ]) {
    await (FontLoader(family)..addFont(read(file))).load();
  }
  // Inter, the phone's body face, in its three weights.
  final inter = FontLoader('Inter');
  for (final face in ['Regular', 'Medium', 'SemiBold']) {
    inter.addFont(read('assets/fonts/Inter-$face.ttf'));
  }
  await inter.load();
  // The Thai fallback of both themes (bundledFallback), every bundled weight.
  final thai = FontLoader('NotoSansThai');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    thai.addFont(read('assets/fonts/NotoSansThai-$weight.ttf'));
  }
  await thai.load();
  // The bundled Chinese fallback (cjkFamily).
  await (FontLoader('NotoSansSCSubset')..addFont(read('assets/fonts/NotoSansSCSubset.otf'))).load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(read('$dir/MaterialIcons-Regular.otf'));
  await icons.load();
}

// ---------------------------------------------------------------------------------------------
// The pay part of the flow map.

/// Replaces the camera plugin's platform: [cameras] answers `availableCameras` (a never-completing
/// future while null, the scanner then shows its aiming view), or throws [error].
class _FakeCameraPlatform extends CameraPlatform {
  _FakeCameraPlatform({this.cameras, this.error});

  final List<CameraDescription>? cameras;
  final CameraException? error;

  /// The answer of the aiming view, held open until the test lets it go.
  final pending = Completer<List<CameraDescription>>();

  @override
  Future<List<CameraDescription>> availableCameras() {
    if (error != null) return Future.error(error!);
    if (cameras == null) return pending.future;
    return Future.value(cameras!);
  }
}

class _BlockedListener extends ListenerNotifier {
  @override
  ListenerState build() => const ListenerState(blocked: true, status: 'blocked');
}

typedef _Setup = void Function(_Tour t);

void _visit(String name, Future<void> Function(_Tour t) body, {_Setup? setup, _Start from = _Start.home}) {
  testWidgets('$name (dark)', (tester) async {
    // Inside the test's own zone: the camera queue of an earlier test never completes here.
    // A widget test kept in tool/ (the flow map), so the analyzer does not count it as a test.
    // ignore: invalid_use_of_visible_for_testing_member
    CameraTurns.reset();
    final t = _Tour(tester, ThemeMode.dark)..visit = name;
    setup?.call(t);
    await t.start(from);
    await body(t);
  });
}

/// Home's Scan tab reads [text] from the queue and routes it; the answer shows over Home.
Future<void> _scanText(_Tour t, String text) async {
  t.scanner.codes.add(text);
  await t.tap(find.byKey(kitScanButtonKey));
  await t.frames();
}

const String _epic1Link = 'epic:epic1qlink0000000000000000000000000000?amount=250000000';

void main() {
  setUpAll(_loadFonts);
  hostSettings = HostSettings.fromText(
    File('assets/config/settings.default.toml').readAsStringSync(),
    config: AppConfig.fromText(File('assets/config/app-config.toml').readAsStringSync()),
  );
  shippedHostSettings = hostSettings;
  setUpAll(() {
    registerFontLicences();
    registerPasswordListLicences();
    registerTorLicence();
  });

  late CameraPlatform platformBefore;
  setUpAll(() => platformBefore = CameraPlatform.instance);
  tearDown(() => CameraPlatform.instance = platformBefore);

  _visit('fm-pay-scan-denied', (t) async {
    CameraPlatform.instance = _FakeCameraPlatform(error: CameraException('CameraAccessDenied', 'denied'));
    await t.push(const ScanScreen());
    await t.shot('fm-pay-scan-denied');
  });
  _visit('fm-pay-scan-failed', (t) async {
    CameraPlatform.instance = _FakeCameraPlatform(cameras: const []);
    await t.push(const ScanScreen());
    await t.shot('fm-pay-scan-failed');
  });

  _visit('fm-pay-scan', (t) async {
    final platform = _FakeCameraPlatform();
    CameraPlatform.instance = platform;
    await t.push(const ScanScreen());
    await t.shot('fm-pay-scan');
    // The camera answers after the shot, so the screen is not left waiting on it.
    platform.pending.complete(const []);
    await t.frames();
  });
  _visit('fm-pay-send-scan-not-epic', (t) async {
    await _scanText(t, 'hello, this is not an Epic code');
    await t.shot('fm-pay-send-scan-not-epic');
  });
  _visit('fm-pay-send-scan-other-network', (t) async {
    await _scanText(t, floonetAddress);
    await t.shot('fm-pay-send-scan-other-network');
  }, setup: (t) => t.otherChain = true);
  _visit('fm-pay-send-scan-slate-text', (t) async {
    await _scanText(t, '{"version_info":{"version":2},"id":"fm-pay"}');
    await t.shot('fm-pay-send-scan-slate-text');
  });
  _visit('fm-pay-send-scan-pairing-link', (t) async {
    await _scanText(t, 'epiccash://pair/1/abc');
    await t.shot('fm-pay-send-scan-pairing-link');
  }, setup: (t) => t.pairingOff = true);
  _visit('fm-pay-send-recovery-phrase-found', (t) async {
    await _scanText(t, List.filled(11, 'abandon').followedBy(['about']).join(' '));
    await t.shot('fm-pay-send-recovery-phrase-found');
  });
  _visit('fm-pay-send-epic1-mode-sheet', (t) async {
    await _scanText(t, _epic1Link);
    await t.shot('fm-pay-send-epic1-mode-sheet');
  });

  // Second batch: screens inside Send and Receive.
  _visit('fm-pay-send-net-block', (t) async {
    await t.tapText(t.l.homeSendButton);
    await t.shot('fm-pay-send-net-block');
  }, setup: (t) => t.mode = NetworkMode.nodeOnly);
  _visit('fm-pay-receive-relay-blocked', (t) async {
    await t.openReceive();
    await t.shot('fm-pay-receive-relay-blocked');
  }, setup: (t) => t.relayBlocked = true);
  _visit('fm-pay-send-not-posted', (t) async {
    final tx = fakeTx(
      key: 's:fin',
      id: 7,
      slateId: 'a1f9e8d7c0b64f21',
      kind: TxKind.sent,
      status: TxStatus.awaitingConfirmation,
      repostable: true,
      amountDebited: BigInt.from(12500000000),
      amountCredited: BigInt.zero,
    );
    await t.push(Scaffold(
      appBar: AppBar(title: Text(t.l.sendFileTitle)),
      body: ScreenBody(children: [FinishedNotPosted(tx: tx)]),
    ));
    await t.shot('fm-pay-send-not-posted');
  }, setup: (t) => t.mode = NetworkMode.killSwitch);
  _visit('fm-pay-send-empty', (t) async {
    await _noCoins(t);
    await t.tapText(t.l.homeSendButton);
    await t.shot('fm-pay-send-empty');
  });
  _visit('fm-pay-send-request-banner', (t) async {
    await _noCoins(t);
    final container = ProviderScope.containerOf(t.tester.element(find.byType(Navigator).first));
    container.read(incomingLinkProvider.notifier).deliver('epic:$_alice?amount=0');
    await t.frames();
    await t.shot('fm-pay-send-request-banner');
  });
  _visit('fm-pay-send-if-not', (t) async {
    await t.tapText(t.l.homeSendButton);
    await t.enterRecipient(_alice);
    await t.tap(find.widgetWithText(FilledButton, t.l.commonContinue));
    await t.enter(t.l.sendAmountLabel('EPIC'), localDecimal(t.l, '12.5'));
    await t.tap(find.byKey(sendReviewButtonKey));
    await t.send(epicText(t.l, _epic(12.5)));
    await t.tapText(t.l.sendTrackIfNot);
    await t.shot('fm-pay-send-if-not');
  });
  _visit('fm-pay-send-file-sent', (t) async {
    await _directWaysOn(t);
    await t.tapText(t.l.homeSendButton);
    await t.tapText(t.l.sendNoAddress);
    await t.tapText(t.l.phoneSendWithFile);
    await t.enter(t.l.sendAmountLabel('EPIC'), localDecimal(t.l, '12.5'));
    await t.tap(find.widgetWithText(KitButton, t.l.sendMakeFile));
    await t.enterPin();
    // Their reply, pasted under "Copy and paste instead": finished and posted.
    await t.tapText(t.l.sendCopyPasteInstead);
    final field = find.descendant(of: find.byKey(sendReplyFieldKey), matching: find.byType(TextField));
    await t.tester.ensureVisible(field);
    t.service.slateInfos[t.session.responseSlate.json] = SlateInfo(
      slateId: t.session.sendSlate.slateId,
      amount: BigInt.from(12500000000),
      fee: t.session.fee,
      stage: SlateStage.response,
    );
    await t.tester.enterText(field, t.session.responseSlate.json);
    await t.tester.pump();
    final finish = find.text(t.l.slateFinishPayment);
    await t.tester.ensureVisible(finish);
    await t.tester.pumpAndSettle();
    await t.tester.tap(finish);
    await t.tester.pumpAndSettle();
    await t.shot('fm-pay-send-file-sent');
  });
  _visit('fm-pay-send-changed-wallet', (t) async {
    final request = LinkVectors().request('req-basic');
    t.session.memory = LinkMemory(
      pins: {
        pinKey(request.card.serviceKey, request.card.handle): const ListingPin(
          listingKey: '03aa8c2f48c588fa84ed97a219b9841579c04241c1cef99b69bb19bb5168011df6',
          firstPaid: 1790000000,
          lastPaid: 1790000000,
        ),
      },
    );
    await _deliverLink(t, LinkVectors().https('req-basic'));
    for (var i = 0; i < 3 && find.textContaining('Send 2.5').evaluate().isEmpty; i++) {
      final next = find.widgetWithText(FilledButton, t.l.commonContinue);
      await t.tap(next.evaluate().isNotEmpty ? next : find.byKey(sendReviewButtonKey));
    }
    await t.tester.ensureVisible(find.textContaining('Send 2.5'));
    await t.tester.pumpAndSettle();
    await t.tester.tap(find.textContaining('Send 2.5'));
    await t.frames();
    await t.shot('fm-pay-send-changed-wallet');
  }, setup: (t) => t.vectorLinks = true);
  _visit('fm-pay-send-link-sheet', (t) async {
    await _deliverLink(t, LinkVectors().https('req-basic'));
    await t.shot('fm-pay-send-link-sheet');
  }, setup: (t) {
    t.vectorLinks = true;
    t.refusedAddress = LinkVectors().request('req-basic').card.address;
  });
  _visit('fm-pay-receive-request-qr', (t) async {
    await t.push(const InvoiceRequestScreen(asQr: true));
    for (final c in '12.5'.split('')) {
      await t.tap(find.descendant(of: find.byType(KitKeypad), matching: find.text(c)));
    }
    await t.tap(find.byKey(requestShowQrKey));
    await t.shot('fm-pay-receive-request-qr');
  });
  _visit('fm-pay-receive-epic1-ask-amount', (t) async {
    await t.openReceive();
    await t.tap(find.byKey(epic1AskAmountKey));
    await t.shot('fm-pay-receive-epic1-ask-amount');
  }, setup: (t) => t.epic1 = true);
}

Future<void> _deliverLink(_Tour t, String text) async {
  final container = ProviderScope.containerOf(t.tester.element(find.byType(Navigator).first));
  container.read(incomingLinkProvider.notifier).deliver(text);
  await t.frames();
  // Over an open Send the link waits behind a notice; Open takes it.
  final open = find.text(t.l.commonOpen);
  if (open.evaluate().isNotEmpty) await t.tap(open);
}

/// A wallet with nothing spendable: Send shows its empty state.
Future<void> _noCoins(_Tour t) async {
  final container = ProviderScope.containerOf(t.tester.element(find.byType(Navigator).first));
  t.session.summaryValue = WalletSummary(
    lastConfirmedHeight: _tip,
    minimumConfirmations: BigInt.from(defaultMinimumConfirmations),
    total: BigInt.zero,
    spendable: BigInt.zero,
    awaitingConfirmation: BigInt.zero,
    awaitingFinalization: BigInt.zero,
    immature: BigInt.zero,
    locked: BigInt.zero,
    validatedWithNode: true,
  );
  container.invalidate(homeProvider);
  await t.frames();
}

/// Settings › Transactions › Pay in person (QR) and Pay with a file on.
Future<void> _directWaysOn(_Tour t) async {
  final container = ProviderScope.containerOf(t.tester.element(find.byType(Navigator).first));
  final settings = container.read(appSettingsProvider.notifier);
  final now = container.read(appSettingsProvider).value ?? const AppSettings();
  await settings.setPayments(now.payments.copyWith(directQr: true, directFile: true));
  await t.frames();
}
