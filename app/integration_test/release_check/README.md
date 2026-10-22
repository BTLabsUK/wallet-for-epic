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
