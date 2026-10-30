#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Offline check: runs integration_test/release_check/offline_test.dart (the real desktop wallet,
# real LEPIC) under xvfb inside a network namespace of its own, so the app starts with NO
# network while the rest of the machine keeps its own. Mid-run the test asks for the network
# back; this script then plugs a cable into the namespace and the test checks the app
# recovers by itself.
#
#   tool/offline_check.sh [test file]     OFFLINE_MODE=refuse (default): no route at all, every
#                                         connect and DNS lookup fails at once (cable out).
#                                         OFFLINE_MODE=drop: an interface and a route exist but
#                                         every packet is dropped, so connects and DNS time out
#                                         (dead Wi-Fi, captive network).
#                                         OFFLINE_RESTORE=0: stay offline to the end.
#                                         OFFLINE_EMPTY_LISTS=1: the settings file's Node and
#                                         Epicbox lists empty from the first start.
#                                         OFFLINE_ONLINE=1: the network is plugged in before the
#                                         app starts (the network-mode proofs).
#                                         OFFLINE_TRACE=1: every connect(), listen() and DNS query of
#                                         every process in the namespace is recorded (strace, $run/trace)
#                                         and summed up by tool/net_trace_summary.py; DNS goes
#                                         over plain UDP from the namespace so each name shows.
#   tool/offline_check.sh selftest        the same namespace, cut and restore with a curl probe in
#                                         place of the app: no build, about 20 s.
#
# How the network is cut: `sudo ip netns add` makes an empty namespace (loopback only, which
# the flutter tool needs to talk to the app); the test runs in it as this user again
# (setpriv), with a throwaway HOME, XDG dirs and keyring like tool/release_check.sh. The
# unprivileged `unshare -rn` is refused on this host (AppArmor restricts user namespaces).
# Nothing outside the namespace changes: no host firewall rule, no sysctl.
#
# How it comes back: a Docker bridge network of its own (Docker already forwards and NATs
# its bridges) and a veth pair, one end on that bridge, the other moved into the namespace
# with an address, a default route and /etc/netns/<ns>/resolv.conf (public resolvers). In
# drop mode the dead route and its sink namespace go first. Everything is removed on exit
# (trap), and a later run removes what a killed run left (wfeoff-<pid> whose pid is gone).
#
# Needs LEPIC built for Linux (tools/lepic.sh build linux) and passwordless sudo. Run it
# through build-slot. Env: RC_OUT (default $TMPDIR) holds data dirs, logs, shots/offline.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
root="$(cd "$here/.." && pwd)"
. "$root/tools/env.sh"
OUT="${RC_OUT:-${TMPDIR:-$HOME/.cache/release-check}}"
MODE="${OFFLINE_MODE:-refuse}"
RESTORE="${OFFLINE_RESTORE:-1}"
ONLINE="${OFFLINE_ONLINE:-0}"
TRACE="${OFFLINE_TRACE:-0}"
[ "$ONLINE" = 1 ] && RESTORE=0
SELFTEST=0
[ "${1:-}" = selftest ] && { SELFTEST=1; shift; }
file="${1:-integration_test/release_check/offline_test.dart}"
name="$(basename "$file" .dart)"
NS="wfeoff-$$"
NET="wfeoff-$$"
SINK="wfeoff-$$-sink"
VH="wfo$$h"; VN="wfo$$n"
run="$OUT/offline-$(date +%H%M%S)"
umask 077
mkdir -p "$run/home/data" "$run/home/config" "$run/home/cache" "$run/net" "$OUT/shots/offline"
chmod 777 "$run/net"   # the test (this user) writes want-up; the watcher (this user) answers

watcher=""
cleanup() {
  [ -n "$watcher" ] && kill "$watcher" 2>/dev/null
  sudo ip netns pids "$NS" 2>/dev/null | xargs -r sudo kill 2>/dev/null
  sudo ip link del "$VH" 2>/dev/null
  sudo ip netns del "$NS" 2>/dev/null
  sudo ip netns del "$SINK" 2>/dev/null
  docker network rm "$NET" >/dev/null 2>&1
  sudo rm -f "/etc/netns/$NS/resolv.conf" "/etc/netns/$NS/nsswitch.conf"
  sudo rmdir "/etc/netns/$NS" 2>/dev/null
}
trap cleanup EXIT INT TERM

# Left by a run that was killed (SIGKILL skips the trap): wfeoff-<pid> with that pid gone.
for old in $(ip netns list 2>/dev/null | awk '{print $1}' | grep '^wfeoff-[0-9]*$'); do
  p="${old#wfeoff-}"
  kill -0 "$p" 2>/dev/null && continue
  echo "removing leftovers of run $p"
  sudo ip netns pids "$old" 2>/dev/null | xargs -r sudo kill 2>/dev/null
  sudo ip link del "wfo${p}h" 2>/dev/null
  sudo ip netns del "$old"
  sudo ip netns del "$old-sink" 2>/dev/null
  docker network rm "$old" >/dev/null 2>&1
  sudo rm -f "/etc/netns/$old/resolv.conf" "/etc/netns/$old/nsswitch.conf"; sudo rmdir "/etc/netns/$old" 2>/dev/null
done

sudo ip netns add "$NS" || { echo "cannot make a network namespace" >&2; exit 3; }
sudo ip -n "$NS" link set lo up
if [ "$MODE" = drop ]; then
  # A route out through a veth into a sink namespace of its own, which drops everything as it
  # arrives: the sender sees no refusal, only silence (a drop in this namespace's own output
  # would answer EPERM at once, which is the refuse case again).
  sudo ip netns add "$SINK"
  sudo ip link add dead0 netns "$NS" type veth peer name dead1 netns "$SINK"
  sudo ip -n "$NS" addr add 10.254.254.2/24 dev dead0
  sudo ip -n "$NS" link set dead0 up
  sudo ip -n "$SINK" addr add 10.254.254.1/24 dev dead1
  sudo ip -n "$SINK" link set dead1 up
  sudo ip -n "$NS" route add default via 10.254.254.1
  sudo ip netns exec "$SINK" nft -f - <<'EOF2'
table inet sink {
  chain pre { type filter hook prerouting priority -300; policy drop; }
}
EOF2
fi
sudo mkdir -p "/etc/netns/$NS"
printf 'nameserver 1.1.1.1\nnameserver 9.9.9.9\n' | sudo tee "/etc/netns/$NS/resolv.conf" >/dev/null
# Traced: names resolve over plain UDP from inside the namespace (no mDNS, no resolver socket
# outside it), so every lookup is a connect() and a query the trace shows.
[ "$TRACE" = 1 ] && printf 'passwd: files\ngroup: files\nhosts: files dns\n' | sudo tee "/etc/netns/$NS/nsswitch.conf" >/dev/null
# Readable by the app's user (this script runs with umask 077).
sudo chmod 755 "/etc/netns/$NS"; sudo chmod 644 /etc/netns/"$NS"/*.conf
echo "namespace $NS, mode $MODE, restore $RESTORE, run $run"

plug_in() {
  local sub id br i
  for i in 1 2 3 4 5; do
    sub="10.231.$((RANDOM % 200 + 20))"
    docker network create --subnet "$sub.0/24" "$NET" >/dev/null 2>&1 && break
    sub=""
  done
  [ -n "$sub" ] || { echo "no docker network" >&2; return 1; }
  id="$(docker network inspect -f '{{.Id}}' "$NET")"; br="br-${id:0:12}"
  if [ "$MODE" = drop ]; then
    sudo ip -n "$NS" link del dead0
    sudo ip netns del "$SINK"
  fi
  sudo ip link add "$VH" type veth peer name "$VN" &&
  sudo ip link set "$VH" master "$br" up &&
  sudo ip link set "$VN" netns "$NS" &&
  sudo ip -n "$NS" addr add "$sub.50/24" dev "$VN" &&
  sudo ip -n "$NS" link set "$VN" up &&
  sudo ip -n "$NS" route replace default via "$sub.1"
}

if [ "$ONLINE" = 1 ]; then
  plug_in || exit 3
  echo "network plugged in before the start"
fi
if [ "$RESTORE" = 1 ]; then
  (
    # Ends with the script, even one killed past its trap.
    while [ ! -e "$run/net/want-up" ]; do kill -0 $$ 2>/dev/null || exit 0; sleep 1; done
    if plug_in; then
      t=$(date +%s)
      echo "network plugged in at $(date +%T)"
      echo "$t" > "$run/net/up"
    fi
  ) &
  watcher=$!
fi

cd "$here"
home="$run/home"
uid="$(id -u)"; gid="$(id -g)"
if [ "$SELFTEST" = 1 ]; then
  # The probe does what the test does: reach out, ask for the network, reach out again.
  sudo ip netns exec "$NS" setpriv --reuid="$uid" --regid="$gid" --init-groups env -i PATH="$PATH" HOME="$home" bash -c '
    probe() { curl -s -o /dev/null -m 6 -w "%{http_code}" https://status.btlabs.uk/api/v1/status.json; }
    t=$(date +%s); c=$(probe); echo "offline probe: http=$c ($(( $(date +%s) - t )) s)"
    [ "$c" = 000 ] || { echo "FAIL: reached the network while cut"; exit 1; }
    [ -n "$0" ] || { echo "PASS (no restore)"; exit 0; }
    touch "$0/want-up"
    for i in $(seq 1 60); do [ -e "$0/up" ] && break; sleep 1; done
    [ -e "$0/up" ] || { echo "FAIL: the network was not plugged in"; exit 1; }
    for i in 1 2 3 4 5; do c=$(probe); [ "$c" = 200 ] && break; sleep 2; done
    echo "online probe: http=$c (try $i)"
    [ "$c" = 200 ] && echo PASS || { echo "FAIL: no answer after the network came back"; exit 1; }
  ' "$([ "$RESTORE" = 1 ] && echo "$run/net")"
  exit $?
fi
# Inside: this user again, a clean environment, the release_check keyring pattern.
timeout 2400 sudo ip netns exec "$NS" setpriv --reuid="$uid" --regid="$gid" --init-groups \
  env -i PATH="$PATH" USER="$USER" LOGNAME="$USER" LANG="${LANG:-C.UTF-8}" \
    HOME="$home" XDG_DATA_HOME="$home/data" XDG_CONFIG_HOME="$home/config" XDG_CACHE_HOME="$home/cache" \
    PUB_CACHE="${PUB_CACHE:-/home/$USER/.pub-cache}" TMPDIR="$run" TMPDIR="$run" \
    ANDROID_HOME="${ANDROID_HOME:-}" JAVA_HOME="${JAVA_HOME:-}" \
    FLUTTER_SUPPRESS_ANALYTICS=true CI=1 \
    OFFLINE_EMPTY_LISTS="${OFFLINE_EMPTY_LISTS:-}" NET_MODE="${NET_MODE:-}" NET_NODE="${NET_NODE:-}" NET_TOR="${NET_TOR:-}" NET_TOR_BUNDLE="${NET_TOR_BUNDLE:-}" OFFLINE_ONLINE="$ONLINE" RC_SHOTS="$OUT/shots/offline" RC_HOME="$home" OFFLINE_NET_DIR="$([ "$RESTORE" = 1 ] && echo "$run/net")" \
  xvfb-run -a -s "-screen 0 1600x1000x24" dbus-run-session -- bash -c '
    printf "%s" "throwaway-$$" | gnome-keyring-daemon --unlock --components=secrets >/dev/null 2>&1
    if [ -n "$1" ]; then
      exec strace -f -Y -yy --seccomp-bpf -s 300 -e trace=connect,sendto,sendmsg,sendmmsg,listen -o "$1" flutter test --no-pub -d linux "$0"
    fi
    exec flutter test --no-pub -d linux "$0"
  ' "$file" "$([ "$TRACE" = 1 ] && echo "$run/trace")" 2>&1 | tee "$OUT/$name.log" | grep --line-buffered -E '^(RC |VISIT )|[0-9]+:[0-9]+ \+|Error|Exception' | tail -200
rc="${PIPESTATUS[0]}"
grep -h '^RC ' "$OUT/$name.log" | sed 's/^RC //' > "$OUT/offline-results.txt"
if [ "$TRACE" = 1 ]; then
  python3 -I "$here/tool/net_trace_summary.py" "$run/trace" ${NET_NODE:+--node "$NET_NODE"} | tee "$OUT/$name-trace.txt"
fi
echo "results: $(grep -c '^PASS' "$OUT/offline-results.txt") pass, $(grep -c '^FAIL' "$OUT/offline-results.txt") fail ($OUT/offline-results.txt)"
exit "$rc"
