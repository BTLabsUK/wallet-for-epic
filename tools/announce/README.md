# tools/announce

Builds, signs, verifies and publishes the wallet announcements feed
(the announcements design, sections 2, 6, 8). Python 3 with `cryptography`; run with `python3 -I`.

Default folder `--dir ~/.config/btlabs/announcements-test/` holds `feed.payload.json` (source),
`announcements.json` (last signed envelope), `ann-test-a.key` (rank-1 key, mode 600, never in the
repo), `announcements-keyring.json` and `.last-signed-serial`.

```sh
A=tools/announce/announce.py
python3 -I $A add --id ID --text "…" [--link-label L --link-url U] [--image PNG] [--days 14] \
  [--starts ISO] [--platforms desktop,phone]
python3 -I $A list
python3 -I $A remove --id ID
python3 -I $A sign [--days 30]            # validates, signs, verifies, checks the 64 KiB cap
python3 -I $A verify --envelope FILE      # or --url URL
python3 -I $A publish --target test       # scp + sudo install on demo-vps, fetch back, verify
python3 -I $A fixtures --out DIR --png PNG  # test vectors for the app's tests
```

Flow: `add` (repeat) → `list` → `sign` → `publish --target test` → `verify --url
https://examples.btlabs.uk/epic/announcements-test/announcements.json`.

`sign` drops ended messages, refuses a serial that is not above the last signed one, and refuses
anything the client would reject.

Production: `--target prod` before the command picks `~/.config/btlabs/announcements/` and signs
with `~/.config/btlabs/signing/btlabs-ann-2026-a.key` (rank 1, keyid 8d85230d01812375). The rank-2
key btlabs-ann-2026-b (5536e619d3a69009) is offline and only revokes rank 1 (`sign --revoke`).

```sh
python3 -I $A --target prod add …      # then list, sign as above
python3 -I $A --target prod publish --target prod
python3 -I $A --target prod verify --url https://raw.githubusercontent.com/BTLabsUK/btlabs-epic.github.io/main/announcements.json
```

`publish --target prod` commits `announcements.json` to `~/code/btlabs-epic.github.io` (beside
`btlabs.json`), pushes a cleaned copy to GitHub with `tools/push-github.sh` as
`tools/publish-update-json.sh` does, and reads the raw file back (or the pushed commit's raw URL
while GitHub's cache still serves main's old copy).

Tests: `python3 -I tools/announce/test_announce.py`
