/// The node service layer, one import for the node screens (`package:epic_wallet/src/node/node.dart`).
///
/// The data and service layer behind the node screens (F24, F26, F27, O2, D-7): the bundled local
/// node's state and controls, its peers and data folder, and what the app can tell about any node.
/// Desktop only (the local node); `NodeInfo` works anywhere. Pure Dart over `dart:io`; every
/// outside call (HTTP, clock, disk, process, lock) can be injected, so tests need no real node.
/// `test/node/node_live_test.dart` drives the real epic binary (see its header).
///
/// Reading a provider never starts a node or downloads anything. Only `LocalNodeController.start()`
/// does, after the user agreed (O2). In Riverpod 3 a provider that nobody listens to is paused, so
/// screens `watch` and tests `listen`.
///
/// ## Providers (`node_providers.dart`)
///
/// | Provider | Gives | Notes |
/// |---|---|---|
/// | `localNodeStateProvider(chain)` | `LocalNodeState` stream | the state line, progress, tiles |
/// | `localNodeControllerProvider(chain)` | `LocalNodeController` | start, stop, restart, options, log |
/// | `nodeMaintenanceProvider(chain)` | `NodeMaintenance` | change folder, reuse, delete chain data |
/// | `peersProvider(chain)` | `PeerSnapshot` stream | autoDispose: reads every 10 s only while watched |
/// | `peerServiceProvider(chain)` | `PeerService` | `ban`, `unban`, `history` (30 s samples) |
/// | `nodeInfoProvider((url:, preset:))` | `NodeInfo` | F27, any node; `ref.invalidate` to refresh |
/// | `localNodeProbeProvider(chain)` | `LocalNodeProbe` | F24: a node already on 127.0.0.1 |
/// | `localNodeFactsProvider(chain)` | `LocalNodeFacts` | F24 explanation step facts |
/// | `chainDataCandidatesProvider(chain)` | `List<ChainDataInfo>` | other nodes' chain data to reuse |
/// | `fallbackChoiceProvider(chain)` | `FallbackChoice` | D-7 answer (unasked/accepted/declined) |
/// | `fallbackDecisionProvider(chain)` | `FallbackDecision` | what the wallet should use now |
/// | `nodeSettingsProvider(chain)` | `NodeSettings` | start with the app, folder, peers, fallback |
///
/// ## Local node
///
/// `LocalNodeState.phase`: `stopped`, `starting`, `syncing`, `synced`, `error`. `online` is true
/// only when synced: the node answered `ready_for_txs == true` (or, for a node older than 4.1.0, its
/// status says `no_sync`), its height is above 0, it has peers, and it is at most 10 blocks behind
/// the network tip when that is known (O2: never "Online · 0"). A stalled node is `error` with `stalled`, its reason
/// kept. A failed one is `error` with `failure` (`NodeFailure`: binaryMissing, portInUse, diskLow,
/// spawnFailed, exited, restartFailed, orphanStuck) and `reason`.
///
/// While syncing, `progress` (`SyncProgress`) has `stage` (`SyncStage`: waitingForPeers, headers,
/// chainStateDownload, chainStateKernels, chainStateRangeProofs, chainStateProcessing, blocks,
/// compacting, shuttingDown, unknown), `done`/`total` in the stage's own units (heights, bytes,
/// items) and `overall` (0–1, a rough weighted blend: headers 30 %, download 30 %, checks 15 %,
/// processing 5 %, blocks 20 %). `overall` is null in the node's catch-all `syncing` status: keep
/// the last value on screen. `eta` and `stageRate` (units per second; bytes/s during the download)
/// come from a sliding window and are null until there is enough data.
///
/// Also: `height`, `networkHeight` (the monitor's tip when it answered, else the peers' median
/// height; never below the node's own highest), `blocksBehind`, `readyForTxs`, `version`, `startedAt`, `uptime`, `peers`, `dataFolder`,
/// `chainDataPath`, `chainDataBytes` (and `chainDataBytesAtStart` for growth this session),
/// `freeBytes`, `restartNeeded` (options changed while running), `userToml` (the toml was edited by
/// hand: the app's options do not apply, and maintenance refuses with `userToml`),
/// `chainDataOrigin` (`own`, `moved` by the app, or `pointed`: another node's folder used in place)
/// and `chainDataReused` (= pointed: Delete is off).
///
/// `LocalNodeController`: `start()`, `stop()`, `restart()` (the state is up to date when they
/// return), `setMaxPeers(inbound:, outbound:)` (the
/// node's default is 128 each), `setPreferredPeers([...])` ("ip:port" only), `setOptions(...)`,
/// `setChainDataPath(...)`, `logPath`, `logTail(lines: 200)`, `refreshDisk()`. Option changes apply
/// at the next start and set `restartNeeded`; the node never restarts by itself.
///
/// `NodeMaintenance` (each stops the node first and starts it again when it ran; on a failure the
/// old folder stays in use):
/// - `planMove(folder)` → `MovePlan.problems` (`MoveProblem`: targetInsideSource,
///   sourceInsideTarget, targetNotEmpty, notEnoughSpace, sourceMissing, sourceLocked,
///   targetNotWritable, layoutIncomplete); `bytesNeeded`, `freeOnTarget`.
/// - `changeDataFolder(folder, how: FolderChange.move | point, progress:, cancelled:)`. The data
///   goes in `<folder>/chain_data`. A move copies, checks, switches, then removes the old copy; a
///   crash leaves one whole copy.
/// - `reuseChainData(candidate, how: ReuseMode.copy | point)`. A copy only reads the other folder.
///   A point uses it in place (the other node must not run; its lock refuses).
/// - `deleteChainData()`: the node's own data only (`<node folder>/chain_data`, or where the app
///   moved it). Never a pointed folder, never a CLI/GUI node's folder, never with a hand-edited toml,
///   never while a node holds its lock. It returns the bytes freed. The node stays stopped.
/// - Every operation refuses with `userToml` when the toml was edited by hand, and stops a copy
///   (`cancelled`) when the node is started meanwhile (the wallet can start it). A CLI/GUI node's
///   folder is never a move or copy target (`MoveProblem.targetForeign`).
///
/// Errors are `DataFolderException(reason, message, problems)`. On Linux and macOS the lock probe
/// uses `flock` or `perl`. Without them the lock is `unknown` and Delete refuses (`lockUnknown`), so
/// say "could not check whether another program uses it".
///
/// ## Peers
///
/// `PeerSnapshot.connected` is a list of `PeerView` (`peer`: `ConnectedPeer` addr, direction,
/// userAgent, protocolVersion, height, totalDifficulty, onionAddr; `stored`: `StoredPeer`;
/// `firstSeen`). `banned` is a list of `StoredPeer` (flag, banReason, lastBanned, lastConnected).
/// Snapshots also have `inbound`, `outbound` and `maxHeight`. `firstSeen` is recorded by the app
/// (the first read the peer was in; kept over one missed read). The node gives no ping,
/// connected-since or byte counts, and no bandwidth.
///
/// ## Node info (F27)
///
/// `NodeInfo.source`:
/// - `directory`: status.btlabs.uk lists the node. Gives state, reason, height, blocksBehind,
///   version vs releasedVersion (`updateAvailable`), uptime24h, peers, operator, listing, country
///   and `network`.
/// - `limited`: the monitor is unreachable or does not list the node. Gives height, tipTime,
///   version, readyForTxs and state from the node's own answer.
/// - `none`: neither answered.
///
/// `latencyMs` is always this computer's own (the median of its last three checks) when it reached
/// the node. `monitorLatencyMs` is the monitor's figure (for picker rows not yet checked here).
/// `directoryReachedAt` is when the monitor last answered. `NetworkStatus` gives the tip height and
/// time, tip age, released versions, nodes and Epicbox healthy/total, forked and the health score.
///
/// ## First run (F24) and fallback (D-7)
///
/// `detectLocalNode(chain, url:)` → `LocalNodeProbe` (answers, version, height, readyForTxs,
/// latencyMs, ours/otherNode). `localNodeFacts` → `LocalNodeFacts` (chainBytes: a dated estimate of
/// 5 GB or a found chain's real size, freeBytes, enoughSpace, firewallPrompt on Windows, reusable).
///
/// `decideFallback(localState, choice)`:
/// - a synced local node → `useLocal`;
/// - accepted → `usePublic` with the agreed node until synced (`active` for the status row);
/// - declined → `useLocal` (the wallet waits);
/// - unasked while starting or syncing → `ask`. The rule asks on every state until an answer is
///   saved, so the UI must save a dismissed dialog as declined to ask only once.
///
/// Save the answer with `NodeSettings.setFallbackChoice(FallbackChoice(...))`. Switching the
/// wallet's node on `usePublic`/`useLocal` belongs to the wallet (`lepic_desk_wallet.dart`), wired
/// with the UI.
///
/// ## What the node cannot provide
///
/// These are not in any epic 4.1.0 API: peer ping, connected-since, bytes per peer, and network
/// bandwidth per process (the process I/O counters include disk). The chain size is not published
/// by status.btlabs.uk either. Max peers is two settings (incoming, outgoing), not one.
library;

export 'chain_data.dart';
export 'data_folder_ops.dart';
export 'fallback.dart';
export 'local_node_controller.dart';
export 'local_node_state.dart';
export 'node_api.dart';
export 'node_api_types.dart';
export 'node_detect.dart';
export 'node_info.dart';
export 'node_maintenance.dart';
export 'node_providers.dart';
export 'node_settings.dart';
export 'peers.dart';
export 'sync_progress.dart';
