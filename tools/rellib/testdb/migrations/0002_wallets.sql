-- Test wallets (the harness's own; never a user's): phrases and passwords are kept here on purpose.
CREATE TABLE wallets(
  id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE, role TEXT NOT NULL, platform TEXT, lane TEXT,
  phrase TEXT, password TEXT, created TEXT, source TEXT, note TEXT,
  state TEXT NOT NULL DEFAULT 'active', updated TEXT, state_ts TEXT
);
CREATE TABLE wallet_addresses(
  wallet_id INTEGER NOT NULL REFERENCES wallets(id), kind TEXT NOT NULL, address TEXT NOT NULL,
  first_seen TEXT, last_seen TEXT, UNIQUE(wallet_id, kind, address)
);
-- Amounts are text in EPIC, as the drivers' digests carry them.
CREATE TABLE wallet_snapshots(
  id INTEGER PRIMARY KEY, wallet_id INTEGER NOT NULL REFERENCES wallets(id), ts TEXT NOT NULL,
  run TEXT, lane TEXT, n INTEGER, spendable TEXT, total TEXT, unconfirmed TEXT, locked TEXT, txs TEXT, source TEXT
);
CREATE INDEX wallet_snapshots_w ON wallet_snapshots(wallet_id, ts);
