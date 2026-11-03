# Hermetic services for the G4 trust lanes

A local mainnet node and a loopback Epicbox relay, so the update-trust checks touch no outside server
except the one live-funds send and receive per platform per release. Test-only infrastructure. The app is
mainnet-only, so the node is a mainnet node: no usernet, no floonet.

```
tools/rellib/hermetic/
  env.sh      every port and path; sourced by the rest
  node.sh     start | stop | status | health   local mainnet epic node
  relay.sh    start | stop | status | health   loopback epic-relay
  up.sh       both up, then both health checks (idempotent)
  down.sh     both down; chain and database kept
```

Everything they run or write lives under `/tmp/epic-build/rel/hermetic/` (`HERMETIC_ROOT`), one directory
per the rules in the workspace's `epic-test-env.md`:

```
bin/epic, bin/foundation.json, bin/PROVENANCE.md   copied in, sha256-checked by node.sh
node/epic-server.toml, node/chain_data/            the node; config keys rewritten from env.sh on start
var/run/{node,relay}.pid, var/log/{node,relay}.log
status.json                                        written by the health checks, read by drivers/core/hermetic.py
```

## Ports

| What | Port | Bound to |
| --- | --- | --- |
| node API (foreign open, owner) | 43413 | 127.0.0.1 |
| node P2P | 43414 | 127.0.0.1: outbound peers only, nobody dials in |
| relay (ws://) | 43423 | 127.0.0.1 |
| relay PostgreSQL | 7787 | 127.0.0.1, epic-relay's `dev/pg.sh` container; database `epicrelay_hermetic` |

Epic protocol ports, so they are recorded in `env.sh` and not in the workspace `ports.json`. The block
avoids the mainnet defaults (3413/3414), the stable network (234xx), the dev relay (3423) and the ssh
tunnels on 334xx.

## Use

```bash
bash tools/rellib/hermetic/up.sh          # exit 0 when node synced and relay healthy
bash tools/rellib/hermetic/node.sh health # local height vs node.btlabs.uk; exit 0 within 5 blocks
bash tools/rellib/hermetic/down.sh
```

A lane asks `core.hermetic.services()` for `{"node": url or None, "relay": "127.0.0.1:43423" or None}`.
It reads `status.json` and offers a service only when its last health check passed within 15 minutes, so
run `up.sh` (or the two `health` commands) right before a lane.

## Node

- The 4.1.1 release binary (`/tmp/epic-build/node-bin/4.1.1`) and the mainnet `foundation.json`, copied
  into `bin/` with their sha256 in `PROVENANCE.md`.
- `archive_mode = false`: a pruned node. It fast-syncs headers, downloads the state at the horizon and
  keeps only recent full blocks.
- Runs at `nice 10`, `ionice idle`. The node is a daemon, so it does not hold a `build-slot` slot.
- `health` writes the node into `status.json` only when synced; `NODE_MAX_GB` (25) is the ceiling it
  warns about.
- Owner API: `node.sh` writes `node/.api_secret`, yet the 4.1.1 release answers `/v2/owner` and `/v1`
  without it (seen 2026-11-03). The loopback-only bind is what keeps it off the network.

## Relay

`/opt/epic/epic-relay` run with `uv run --frozen epic-relay` on `127.0.0.1:43423`, against its dev
PostgreSQL in a database of its own. Its identity is `127.0.0.1:43423`, spelled as the app is given it:
a wallet told `127.0.0.1:<port>` stamps its address `@127.0.0.1:<port>`, and a relay named `localhost`
would refuse to carry the reply. `localhost:43423` is an alias.

### ws:// only to loopback

The app speaks plain `ws://` to a loopback relay and `wss://` to any other host:

- LEPIC `crates/lepic-epicbox/src/session.rs`, `RelayEndpoint::check_security`: a plain websocket to a
  host that is not loopback is refused (`PlainToRemoteHost`); `address.rs` `is_loopback` accepts
  `localhost` and 127.0.0.0/8.
- `app/lib/src/send_preflight.dart`, `relayProbeUri`: `ws` on a loopback host, `wss` everywhere else.
- The node is the same: `app/lib/src/node/node_api.dart` allows `http` only to a loopback host.

So a device must reach these services on its own 127.0.0.1: `adb reverse` on the Android emulator (its
10.0.2.2 is not loopback to the app, which would then insist on TLS), an ssh `-R` forward on a Windows
rig.
