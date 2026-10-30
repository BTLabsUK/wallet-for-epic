# A 26.10.23 install after 26.10.24-r2 ran

The data folder of [`install_26_10_23`](../install_26_10_23/README.md) as Epic Cash Desktop
26.10.24-r2 leaves it, for `test/install_upgrade_test.dart`. 26.10.24-r2 read none of
26.10.23's stored servers (issue #143): it wrote `settings.toml` from its default copy, so the
user's own node and Epicbox server were gone from the lists and the default servers were in use.

- `home/.epic_cash_desktop/`: as 26.10.23 left it, plus `settings.toml`, the default copy as
  26.10.24-r2 wrote it on its first start (the test settings' servers in place of the real ones).
  Kept literally on purpose. The import reads a list equal to the current default copy as
  untouched and brings the old choices back. A later default copy whose lists differ makes this
  file look changed by the user, and the test fails until the import also knows this copy.
- `store.json`: unchanged from 26.10.23. 26.10.24-r2 never deleted or rewrote the old server
  records (`desk.serverList.*`, `app.node.*`, `app.relay.*`, `desk.nodes`), so they are still
  there to import.

`@DATA@` stands for the data folder's absolute path; the test fills it in on a copy. No real
wallet, phrase, password, key or person: each `lepic/FIXTURE` stands for LEPIC's database, and
every host is under `.invalid`. `settings.toml` and `wfe.log` need `git add -f` (both names are
git-ignored).
