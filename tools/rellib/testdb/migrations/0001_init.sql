-- The BT Wallet test database. Text ids: lanes "<run>/<lane>", attempts "<run>/<lane>#<n>",
-- steps "<attempt>/<step>". state_ts is the ts of the event that last set a row's state:
-- an older event never overwrites newer state.
CREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY, value TEXT);

CREATE TABLE events(
  id INTEGER PRIMARY KEY,
  eid TEXT NOT NULL UNIQUE,
  ts TEXT NOT NULL,
  host TEXT NOT NULL,
  source TEXT NOT NULL,
  seq INTEGER,
  kind TEXT NOT NULL,
  body TEXT NOT NULL,
  received TEXT NOT NULL
);
CREATE INDEX events_kind_ts ON events(kind, ts);

CREATE TABLE runs(
  run_id TEXT PRIMARY KEY, kind TEXT, version TEXT, host TEXT, state TEXT,
  started TEXT, ended TEXT, note TEXT, state_ts TEXT
);

CREATE TABLE lanes(
  id TEXT PRIMARY KEY, run_id TEXT NOT NULL REFERENCES runs(run_id), name TEXT NOT NULL,
  platform TEXT, variant TEXT, state TEXT, started TEXT, ended TEXT, attempts INTEGER NOT NULL DEFAULT 0,
  cause_class TEXT, cause TEXT, state_ts TEXT
);
CREATE INDEX lanes_name ON lanes(name);

CREATE TABLE attempts(
  id TEXT PRIMARY KEY, lane_id TEXT NOT NULL REFERENCES lanes(id), n INTEGER NOT NULL, state TEXT,
  started TEXT, ended TEXT, rc INTEGER, cause_class TEXT, cause TEXT, note TEXT,
  log_path TEXT, out_dir TEXT, heartbeat TEXT, state_ts TEXT
);
CREATE INDEX attempts_lane ON attempts(lane_id, n);

CREATE TABLE steps(
  id TEXT PRIMARY KEY, attempt_id TEXT NOT NULL REFERENCES attempts(id), name TEXT NOT NULL, state TEXT,
  started TEXT, ended TEXT, skipped INTEGER NOT NULL DEFAULT 0, detail TEXT, state_ts TEXT
);

CREATE TABLE failures(
  id INTEGER PRIMARY KEY, eid TEXT UNIQUE, attempt_id TEXT NOT NULL REFERENCES attempts(id), step TEXT,
  cause_class TEXT, cause TEXT, what TEXT, bundle_id INTEGER, resolved_by TEXT, ts TEXT NOT NULL
);
CREATE INDEX failures_attempt ON failures(attempt_id, step);

CREATE TABLE bundles(
  id INTEGER PRIMARY KEY, eid TEXT UNIQUE, attempt_id TEXT NOT NULL REFERENCES attempts(id), step TEXT,
  dir TEXT, screen_path TEXT, log_tail_path TEXT, shot_path TEXT
);

CREATE TABLE playbook(
  id INTEGER PRIMARY KEY, key TEXT NOT NULL UNIQUE, situation TEXT, fix TEXT, source_failure TEXT,
  state TEXT NOT NULL DEFAULT 'open', version_added TEXT, created TEXT, updated TEXT, state_ts TEXT
);

CREATE TABLE ai_paths(
  id INTEGER PRIMARY KEY, key TEXT NOT NULL UNIQUE, platform TEXT, goal TEXT, screen_sig TEXT,
  actions TEXT, state TEXT NOT NULL DEFAULT 'new', hits INTEGER NOT NULL DEFAULT 0,
  fails INTEGER NOT NULL DEFAULT 0, created TEXT, last_used TEXT, reviewed_by TEXT, state_ts TEXT
);

-- running attempts and steps, with the age of their last sign of life
CREATE VIEW live AS
  SELECT 'attempt' AS what, a.id AS id, l.run_id AS run_id, l.name AS lane, a.n AS n, NULL AS step,
         a.started AS started, a.heartbeat AS heartbeat,
         CAST((julianday('now') - julianday(COALESCE(a.heartbeat, a.started))) * 86400 AS INTEGER) AS age_s
    FROM attempts a JOIN lanes l ON l.id = a.lane_id WHERE a.state = 'running'
  UNION ALL
  SELECT 'step', s.id, l.run_id, l.name, a.n, s.name, s.started, a.heartbeat,
         CAST((julianday('now') - julianday(COALESCE(a.heartbeat, s.started))) * 86400 AS INTEGER)
    FROM steps s JOIN attempts a ON a.id = s.attempt_id JOIN lanes l ON l.id = a.lane_id
   WHERE s.state = 'running';

-- the newest attempt of every lane name
CREATE VIEW last_per_lane AS
  SELECT lane, run_id, n, state, rc, cause_class, cause, note, started, ended, log_path FROM (
    SELECT l.name AS lane, l.run_id AS run_id, a.n AS n, a.state AS state, a.rc AS rc,
           a.cause_class AS cause_class, a.cause AS cause, a.note AS note, a.started AS started,
           a.ended AS ended, a.log_path AS log_path,
           ROW_NUMBER() OVER (PARTITION BY l.name ORDER BY a.started DESC, a.n DESC) AS rk
      FROM attempts a JOIN lanes l ON l.id = a.lane_id)
  WHERE rk = 1;

CREATE VIEW failures_by_cause AS
  SELECT COALESCE(cause_class, '?') AS cause_class, COALESCE(cause, '') AS cause,
         COUNT(*) AS n, MAX(ts) AS last
    FROM failures GROUP BY 1, 2;
