# Legacy wallet fixtures

Throwaway test data for the import tests (`test/desktop/import_wallets_test.dart`,
`import_gui_contacts_test.dart`, `legacy_gui_profile_test.dart`, `legacy_leveldb_test.dart`).
Nothing here is a real wallet and nothing was ever funded.

- `cli/`, `gui531/`, `gui616/`: folders laid out like the older Epic command line wallet
  (`.epic/main`) and the older Epic GUI (`.epic/…`, `.epic-gui/wallets/…`), each with an
  `epic-wallet.toml`, a settings file and a `wallet_data/wallet.seed`. The `wallet.seed` files are
  placeholders (a few bytes of JSON such as `{"fixture":"main"}`), not encrypted seeds, so no
  password opens them. The tests that need a password pass their own made-up one to a fake wallet
  service.
- `idb/`: Chromium IndexedDB (LevelDB) folders with the contacts and settings rows the older GUI
  wrote. Made by `app/tool/legacy_gui_fixtures.py`, which writes the rows with real Chromium in a
  throwaway profile and copies the database out (run instructions are in that script).
