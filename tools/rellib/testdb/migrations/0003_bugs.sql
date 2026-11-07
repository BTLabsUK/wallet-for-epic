-- SPDX-License-Identifier: Apache-2.0
-- The bug ledger: one row per failed attempt, a warned one too. `class` is required.
-- To reverse: DROP TABLE bugs; and set meta schema_version back to 2.
CREATE TABLE bugs(
  id INTEGER PRIMARY KEY,
  eid TEXT UNIQUE,
  attempt_id INTEGER NOT NULL REFERENCES attempts(id),
  step TEXT,
  class TEXT NOT NULL,
  cause TEXT,
  note TEXT,
  warned INTEGER NOT NULL DEFAULT 0,
  log_path TEXT,
  commit_sha TEXT,
  version TEXT,
  ts TEXT
);
CREATE INDEX bugs_attempt ON bugs(attempt_id);
CREATE INDEX bugs_class ON bugs(class);
