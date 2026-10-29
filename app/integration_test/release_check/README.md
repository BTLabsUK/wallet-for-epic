# Release check

Independent check of the desktop wallet on the real LEPIC core, a real node and a real Epicbox relay.

    tools/lepic.sh sync && tools/lepic.sh build linux     # LEPIC at the pin
    app/tool/release_check.sh pick                         # node and relay that would be used
    app/tool/release_check.sh desktop                      # desktop_test.dart, then restore_test.dart

Each file runs in its own fresh HOME / XDG dirs under `$RC_OUT` (default `$TMPDIR`) with a
throwaway keyring under `dbus-run-session` and `xvfb-run`. Screenshots go to `$RC_OUT/shots/desktop`,
`$RC_OUT/results.txt` has one PASS/FAIL line per check. Nothing is sent; wallets stay empty.

`desktop_test.dart` leaves the first wallet's phrase in a mode-600 file (`RC_PHRASE_FILE`) for
`restore_test.dart`, which deletes it right after reading; the script deletes it again at the end.
Throwaway empty wallets only; never use this for a wallet that holds funds.

## Offline

    app/tool/offline_check.sh selftest      # the namespace, the cut and the restore, no build
    app/tool/offline_check.sh               # offline_test.dart: the app from its first start with no network
    OFFLINE_MODE=drop app/tool/offline_check.sh   # packets vanish instead of being refused
    OFFLINE_EMPTY_LISTS=1 app/tool/offline_check.sh   # settings.toml lists no node and no Epicbox server
    app/tool/offline_phone.sh               # offline_phone_test.dart on an emulator of its own in airplane mode

`offline_check.sh` runs the test in a network namespace (`sudo ip netns`, loopback only) as this
user, so only that process is offline. Mid-run the test asks for the network back and the script
plugs a veth on a Docker bridge network of its own into the namespace. It removes the namespace
(`wfeoff-<pid>`, `wfeoff-<pid>-sink` in drop mode), the veth (`wfo<pid>h`), the Docker network
(`wfeoff-<pid>`) and `/etc/netns/wfeoff-<pid>/` on exit, and a later run removes what a killed one
left. Results: `$RC_OUT/offline-results.txt`, one line per check and one per screen visited;
shots in `$RC_OUT/shots/offline`. The phone script uses AVD `wfe_small` on port 5560, never 5554,
5556 or 5558; it types the AVD's screen-lock PIN (`OFFLINE_DEVICE_PIN`, 1111) and talks to the
test through the app's `files/rc-offline` folder (`adb shell run-as`). Widget and unit tests of the same cases with fakes are in `test/offline/`.
