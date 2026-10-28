# Signed-file test fixtures

Used by the tests of signed files (`keyring.json`, `update.json`).

- `test-a.key`, `test-b.key`: Ed25519 private keys made only for these tests.
- `test-keyring.json`: the keyring listing their public keys (`test-a`, `test-b`).
- `vectors.json`, `update-vectors.json`: files signed with those test keys.

They are **not** BT Labs' release keys. They protect nothing; anyone may use them. The real
signing keys are never in this repository.
