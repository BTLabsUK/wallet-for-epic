# Signed-file test fixtures

Used by the tests of signed files (`keyring.json`, `update.json`).

- `test-a.key`, `test-b.key`: Ed25519 private keys made only for these tests.
- `test-keyring.json`: the keyring listing their public keys (`test-a`, `test-b`).
- `vectors.json` (the public file), `update-v2-vectors.json` (update-v2.json, the update format
  this app reads): btlabs-public's shared vectors, signed with those test keys. Copy them from
  btlabs-public's `testdata/` after `tool/make_vectors.py`.

They are **not** BT Labs' release keys. They protect nothing; anyone may use them. The real
signing keys are never in this repository.

Secret scanners flag the two keys. The publish scan's allowlist,
`tools/publish/secrets-allowed.txt`, lists them (gitleaks `private-key`, by the hash of each
key) with this folder's path; any other finding here needs a look.
