# A 26.10.23 install

The data folder an Epic Cash Desktop install of 26.10.23 (the last release before 26.10.24
renamed the wallet folders without a migration) leaves on disk, for `test/install_upgrade_test.dart`
and the install contract (`tools/install-contract.json`, `docs/install-contract.md`).

- `home/.epic_cash_desktop/`: the data folder (`<home>` is `%USERPROFILE%` on Windows, `$HOME`
  elsewhere; the phone keeps the same tree in its own app folder): Wallet 1 at
  `wallets/mainnet`, an added wallet at `wallets/<id>/mainnet`, `wallets.json`, the built-in
  node at `node/main`, `contacts.json`, `logs/wfe.log`. No `settings.toml`: 26.10.23 kept the
  servers in the store.
- `store.json`: what the secret store held (Windows `flutter_secure_storage.dat`, the Linux
  keyring, Android's secure storage), as plain key/value pairs.

`@DATA@` stands for the data folder's absolute path; the test fills it in on a copy. No real
wallet, phrase, password, key or person: each `lepic/FIXTURE` stands for LEPIC's database, and
every host is under `.invalid`.
