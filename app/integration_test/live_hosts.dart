// SPDX-License-Identifier: Apache-2.0
/// The servers the tests that drive real networks talk to. None is named in code: they come from
/// a settings file given to the run, as the unit tests read `test/settings/`:
///
///     flutter test integration_test/<file> --dart-define-from-file=integration_test/live-hosts.json
///
/// `live-hosts.example.json` shows the keys with example hosts; copy it to `live-hosts.json`
/// (not tracked) and put the real servers in.
library;

/// Mainnet nodes, in the order the checks try them.
const String liveNode = String.fromEnvironment('LIVE_NODE');
const String liveNode2 = String.fromEnvironment('LIVE_NODE2');
const String liveNode3 = String.fromEnvironment('LIVE_NODE3');

/// The test chain's node and the faucet that pays test coins.
const String liveFlooNode = String.fromEnvironment('LIVE_FLOO_NODE');
const String liveFaucet = String.fromEnvironment('LIVE_FAUCET');

/// Epicbox servers (host names): the first, a second, the app's own default, the test chain's.
const String liveRelay = String.fromEnvironment('LIVE_RELAY');
const String liveRelay2 = String.fromEnvironment('LIVE_RELAY2');
const String liveRelay3 = String.fromEnvironment('LIVE_RELAY3');
const String liveFlooRelay = String.fromEnvironment('LIVE_FLOO_RELAY');

/// Live and integration tests that touch a real chain always use one confirmation.
final BigInt liveMinConfirmations = BigInt.one;
