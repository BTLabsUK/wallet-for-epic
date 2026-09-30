//! The app's own history archive: `<data_dir>/wfe_meta.json`.
//!
//! epic-wallet's `epic.db` stays the live ledger and is never written from here. This file holds
//! what epic.db cannot keep: notes, contacts, facts recorded as transactions happen (counterparty,
//! created output commitments, finalization), records imported from a history file, and cached
//! block heights and times. Balance never reads any of it, so nothing here can move funds.
//!
//! Every change is written atomically: a temp file in the same directory, fsync, rename, fsync of
//! the directory where the platform allows it.

use std::collections::BTreeMap;
use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use serde::{Deserialize, Serialize};

use super::history::BLOCKS_PER_DAY;

use super::error::{CoreError, CoreResult};

pub(crate) const META_FILE: &str = "wfe_meta.json";
const META_VERSION: u32 = 1;

fn meta_version() -> u32 {
    META_VERSION
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub(crate) struct ContactRec {
    pub id: String,
    pub name: String,
    pub address: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
}

/// Facts about one of our transactions, recorded when the core performs a step. Keyed by slate id.
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub(crate) struct Annotation {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub counterparty: Option<String>,
    /// This wallet finalized the send (the recipient had signed).
    #[serde(default, skip_serializing_if = "std::ops::Not::not")]
    pub finalized: bool,
    /// The final kernel, from the finalized slate.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub kernel_excess: Option<String>,
    /// When this wallet finalized the send, and the wallet's height then.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub finalized_at_unix: Option<i64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub finalized_height: Option<u64>,
    /// The last post (or repost) error; cleared by a post the node took.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub post_error: Option<String>,
    /// The node answered a post with a refusal at least once (not a transport failure).
    #[serde(default, skip_serializing_if = "std::ops::Not::not")]
    pub post_refused: bool,
    /// Why this wallet cancelled it: `user`, `release`, `late_answer`, `failed`. None when
    /// epic-wallet cancelled it on its own (the TTL) or before reasons were recorded.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub cancelled_by: Option<String>,
    /// Tip height at which a lookup found the final kernel nowhere on chain.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub kernel_absent_at: Option<u64>,
}

/// One transaction as it travels in a history file, and as it is kept once imported.
/// Amounts are in the smallest unit. Nothing in here is secret.
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub(crate) struct Record {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub slate_id: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub kernel_excess: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub kernel_lookup_min_height: Option<u64>,
    /// `TxKind` name: Coinbase, Received, Sent, ReceivedCancelled, SentCancelled.
    pub kind: String,
    /// `TxStatus` name at export time.
    pub status: String,
    pub confirmed: bool,
    pub created_at_unix: i64,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub block_height: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub block_time_unix: Option<i64>,
    pub amount_credited: u64,
    pub amount_debited: u64,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub fee: Option<u64>,
    #[serde(default)]
    pub num_inputs: u32,
    #[serde(default)]
    pub num_outputs: u32,
    #[serde(default)]
    pub output_commits: Vec<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub counterparty: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub ttl_cutoff_height: Option<u64>,
    /// epic-wallet's `ParticipantMessages`, as it serialises them.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub messages: Option<serde_json::Value>,
    /// epic-wallet's `StoredProofInfo` (public keys and signatures only).
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub payment_proof: Option<serde_json::Value>,
    /// Set when the core settled a pending record against the chain.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub status_detail: Option<String>,
    /// `CancelReason` name, for a cancelled record.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub cancel_reason: Option<String>,
    /// `exported_at_unix` of the file this record's status came from. Set on import.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub exported_at_unix: Option<i64>,
}

fn pending(status: &str) -> bool {
    matches!(status, "AwaitingRecipient" | "AwaitingConfirmation")
}

impl Record {
    /// Merges a record of the same transaction from another import into this one. Fields this
    /// one lacks are filled in (commitments are added); the status, kind and amounts are taken
    /// when the other file is newer, except that a settled status never goes back to pending.
    /// Returns true when anything the user can see changed.
    pub(crate) fn merge_from(&mut self, other: &Record) -> bool {
        let before = self.clone();
        fn fill<T: Clone>(mine: &mut Option<T>, theirs: &Option<T>) {
            if mine.is_none() {
                mine.clone_from(theirs);
            }
        }
        fill(&mut self.slate_id, &other.slate_id);
        fill(&mut self.kernel_excess, &other.kernel_excess);
        fill(
            &mut self.kernel_lookup_min_height,
            &other.kernel_lookup_min_height,
        );
        fill(&mut self.block_height, &other.block_height);
        fill(&mut self.block_time_unix, &other.block_time_unix);
        fill(&mut self.fee, &other.fee);
        let newer = other.exported_at_unix.unwrap_or(0) > self.exported_at_unix.unwrap_or(0);
        // A newer file's note and counterparty are the user's latest edits.
        if newer && other.note.is_some() {
            self.note.clone_from(&other.note);
        }
        if newer && other.counterparty.is_some() {
            self.counterparty.clone_from(&other.counterparty);
        }
        fill(&mut self.counterparty, &other.counterparty);
        fill(&mut self.note, &other.note);
        fill(&mut self.ttl_cutoff_height, &other.ttl_cutoff_height);
        fill(&mut self.messages, &other.messages);
        fill(&mut self.payment_proof, &other.payment_proof);
        for c in &other.output_commits {
            if !self.output_commits.contains(c) {
                self.output_commits.push(c.clone());
            }
        }
        if newer && !(pending(&other.status) && !pending(&self.status)) {
            self.status.clone_from(&other.status);
            self.confirmed = other.confirmed;
            self.kind.clone_from(&other.kind);
            self.status_detail.clone_from(&other.status_detail);
            self.cancel_reason.clone_from(&other.cancel_reason);
            self.amount_credited = other.amount_credited;
            self.amount_debited = other.amount_debited;
            self.num_inputs = other.num_inputs;
            self.num_outputs = other.num_outputs;
        }
        let mut seen = self.clone();
        seen.exported_at_unix = before.exported_at_unix;
        let changed = seen != before;
        if newer {
            self.exported_at_unix = other.exported_at_unix;
        }
        changed
    }

    /// Same transaction as `other`: shared slate id, kernel, or created output.
    pub(crate) fn same_tx(&self, other: &Record) -> bool {
        let eq =
            |a: &Option<String>, b: &Option<String>| matches!((a, b), (Some(x), Some(y)) if x == y);
        eq(&self.slate_id, &other.slate_id)
            || eq(&self.kernel_excess, &other.kernel_excess)
            || self
                .output_commits
                .iter()
                .any(|c| other.output_commits.contains(c))
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub(crate) struct Meta {
    #[serde(default = "meta_version")]
    pub version: u32,
    /// Notes by transaction key (`TxEntry.key`).
    #[serde(default)]
    pub notes: BTreeMap<String, String>,
    #[serde(default)]
    pub contacts: Vec<ContactRec>,
    #[serde(default)]
    pub annotations: BTreeMap<String, Annotation>,
    #[serde(default)]
    pub records: Vec<Record>,
    /// Block height to block time (unix seconds), from the node's headers.
    #[serde(default)]
    pub block_times: BTreeMap<u64, i64>,
    /// Kernel excess (hex) to the height of the block that holds it.
    #[serde(default)]
    pub kernel_heights: BTreeMap<String, u64>,
    /// Heights the node had no header for, with the node's tip at the time. Asked again after
    /// a day of blocks past that tip.
    #[serde(default, skip_serializing_if = "BTreeMap::is_empty")]
    pub block_time_misses: BTreeMap<u64, u64>,
    /// The node URL the caches above came from. A different node starts them afresh.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub cache_node: Option<String>,
}

impl Meta {
    /// Whether to ask the node for the block time at `height`, with `tip` the node's tip if
    /// known. A cached time is final. A miss is asked again only after a day of blocks past the
    /// tip it was recorded at, so a node that lacks old headers is not asked on every refresh.
    /// A `0` from older files counts as a miss at tip 0.
    pub(crate) fn wants_block_time(&self, height: u64, tip: Option<u64>) -> bool {
        let retry_after = |at: u64| tip.is_some_and(|t| t >= at.saturating_add(BLOCKS_PER_DAY));
        match self.block_times.get(&height) {
            Some(t) if *t > 0 => false,
            Some(_) => retry_after(0),
            None => match self.block_time_misses.get(&height) {
                Some(at) => retry_after(*at),
                None => true,
            },
        }
    }

    /// Drops the block caches when they came from another node. Returns true when it did.
    /// The first node seen is only recorded, so upgrading keeps the caches.
    pub(crate) fn use_node(&mut self, url: &str) -> bool {
        match self.cache_node.as_deref() {
            Some(n) if n == url => false,
            None => {
                self.cache_node = Some(url.to_owned());
                false
            }
            Some(_) => {
                self.block_times.clear();
                self.block_time_misses.clear();
                self.kernel_heights.clear();
                self.cache_node = Some(url.to_owned());
                true
            }
        }
    }
}

impl Default for Meta {
    fn default() -> Self {
        Meta {
            version: META_VERSION,
            notes: BTreeMap::new(),
            contacts: Vec::new(),
            annotations: BTreeMap::new(),
            records: Vec::new(),
            block_times: BTreeMap::new(),
            kernel_heights: BTreeMap::new(),
            block_time_misses: BTreeMap::new(),
            cache_node: None,
        }
    }
}

fn io_err(what: &str, path: &Path, e: std::io::Error) -> CoreError {
    CoreError::Io(format!("{what} {}: {e}", path.display()))
}

/// Writes `bytes` to `path` so a crash leaves either the old file or the new one.
pub(crate) fn write_atomic(path: &Path, bytes: &[u8]) -> CoreResult<()> {
    // The directory must exist: a wallet deleted while a call on it was still running must not
    // come back as a directory holding only this file.
    let dir = path.parent().unwrap_or_else(|| Path::new("."));
    let tmp = path.with_extension("tmp");
    {
        let mut f = File::create(&tmp).map_err(|e| io_err("creating", &tmp, e))?;
        f.write_all(bytes).map_err(|e| io_err("writing", &tmp, e))?;
        f.sync_all().map_err(|e| io_err("syncing", &tmp, e))?;
    }
    fs::rename(&tmp, path).map_err(|e| io_err("replacing", path, e))?;
    // Makes the rename durable on Linux and Android. Windows cannot open a directory this way,
    // and its rename is already durable enough for this file.
    if let Ok(d) = File::open(dir) {
        let _ = d.sync_all();
    }
    Ok(())
}

/// The archive of one wallet, loaded once per session and shared with the listener.
pub(crate) struct MetaStore {
    path: PathBuf,
    meta: Mutex<Meta>,
}

impl MetaStore {
    /// Loads `<data_dir>/wfe_meta.json`, or starts empty when there is none. A file that cannot be
    /// parsed is moved aside to `wfe_meta.json.corrupt-<ms>` rather than overwritten, so notes are
    /// never destroyed silently, and the wallet still opens.
    pub(crate) fn open(data_dir: &str) -> CoreResult<MetaStore> {
        let path = Path::new(data_dir).join(META_FILE);
        let meta = match fs::read(&path) {
            Ok(bytes) => match serde_json::from_slice::<Meta>(&bytes) {
                Ok(m) => m,
                Err(e) => {
                    // Timestamped, so a second damaged file does not replace the first.
                    let stamp = std::time::SystemTime::now()
                        .duration_since(std::time::UNIX_EPOCH)
                        .map(|d| d.as_millis())
                        .unwrap_or(0);
                    let aside = path.with_extension(format!("json.corrupt-{stamp}"));
                    log::warn!(
                        "{} is unreadable ({e}); moved to {}",
                        path.display(),
                        aside.display()
                    );
                    fs::rename(&path, &aside).map_err(|e| io_err("moving", &path, e))?;
                    Meta::default()
                }
            },
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => Meta::default(),
            Err(e) => return Err(io_err("reading", &path, e)),
        };
        Ok(MetaStore {
            path,
            meta: Mutex::new(meta),
        })
    }

    fn lock(&self) -> std::sync::MutexGuard<'_, Meta> {
        self.meta.lock().unwrap_or_else(|p| p.into_inner())
    }

    /// A copy of the current state.
    pub(crate) fn snapshot(&self) -> Meta {
        self.lock().clone()
    }

    /// Applies `f` and persists the result. The in-memory state changes only if the write
    /// succeeds. Nothing is written when `f` leaves the state unchanged.
    pub(crate) fn update<R>(&self, f: impl FnOnce(&mut Meta) -> CoreResult<R>) -> CoreResult<R> {
        let mut guard = self.lock();
        if guard.version > META_VERSION {
            // Rewriting it would drop whatever the newer version added.
            return Err(CoreError::Io(format!(
                "{} was written by a newer version of the app; update the app to change notes, \
                 contacts or history",
                self.path.display()
            )));
        }
        let mut next = guard.clone();
        let out = f(&mut next)?;
        if next != *guard {
            // Compact: a big wallet's archive is rewritten on every listener event.
            let bytes = serde_json::to_vec(&next)
                .map_err(|e| CoreError::Io(format!("encoding {}: {e}", self.path.display())))?;
            write_atomic(&self.path, &bytes)?;
            *guard = next;
        }
        Ok(out)
    }
}

impl MetaStore {
    /// Records facts about the transaction with `slate_id`. A failure is logged, never returned:
    /// the transaction itself already happened.
    pub(crate) fn annotate(&self, slate_id: &str, f: impl FnOnce(&mut Annotation)) {
        let r = self.update(|m| {
            f(m.annotations.entry(slate_id.to_owned()).or_default());
            Ok(())
        });
        if let Err(e) = r {
            log::warn!("recording details of {slate_id}: {e}");
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trips_and_writes_atomically() {
        let dir = tempfile::tempdir().unwrap();
        let data_dir = dir.path().to_str().unwrap();
        let store = MetaStore::open(data_dir).unwrap();
        assert_eq!(store.snapshot(), Meta::default());
        assert!(
            !dir.path().join(META_FILE).exists(),
            "nothing written before a change"
        );

        store
            .update(|m| {
                m.notes.insert("s:abc".into(), "rent".into());
                m.contacts.push(ContactRec {
                    id: "1".into(),
                    name: "Bob".into(),
                    address: "addr".into(),
                    note: None,
                });
                m.block_times.insert(10, 1_790_000_000);
                Ok(())
            })
            .unwrap();
        assert!(
            !dir.path().join("wfe_meta.tmp").exists(),
            "temp file renamed away"
        );

        let reopened = MetaStore::open(data_dir).unwrap();
        assert_eq!(reopened.snapshot(), store.snapshot());
        assert_eq!(reopened.snapshot().notes["s:abc"], "rent");
    }

    #[test]
    fn a_write_never_recreates_a_deleted_wallet_directory() {
        let dir = tempfile::tempdir().unwrap();
        let data_dir = dir.path().join("wallet");
        fs::create_dir_all(&data_dir).unwrap();
        let store = MetaStore::open(data_dir.to_str().unwrap()).unwrap();
        fs::remove_dir_all(&data_dir).unwrap();
        let r = store.update(|m| {
            m.notes.insert("k".into(), "v".into());
            Ok(())
        });
        assert!(r.is_err());
        assert!(!data_dir.exists(), "the deleted directory stays deleted");
    }

    #[test]
    fn a_missing_block_time_is_asked_again_after_a_day_of_blocks() {
        let mut m = Meta::default();
        assert!(m.wants_block_time(5, None), "never asked");
        m.block_times.insert(5, 1_700_000_000);
        assert!(!m.wants_block_time(5, Some(9)), "known");
        m.block_time_misses.insert(6, 100);
        assert!(!m.wants_block_time(6, None), "tip unknown: not yet");
        assert!(
            !m.wants_block_time(6, Some(100)),
            "same tip: the node still lacks it"
        );
        assert!(
            !m.wants_block_time(6, Some(99 + BLOCKS_PER_DAY)),
            "less than a day of blocks"
        );
        assert!(
            m.wants_block_time(6, Some(100 + BLOCKS_PER_DAY)),
            "a day later"
        );
        m.block_times.insert(7, 0); // an older file's miss, at tip 0
        assert!(!m.wants_block_time(7, Some(1)));
        assert!(m.wants_block_time(7, Some(BLOCKS_PER_DAY)));
    }

    #[test]
    fn another_node_starts_the_block_caches_afresh() {
        let mut m = Meta::default();
        m.block_times.insert(5, 1);
        m.kernel_heights.insert("k".into(), 5);
        assert!(!m.use_node("https://a"), "the first node is only recorded");
        assert_eq!(m.block_times.len(), 1);
        assert!(!m.use_node("https://a"));
        m.block_time_misses.insert(6, 10);
        assert!(m.use_node("https://b"));
        assert!(
            m.block_times.is_empty()
                && m.kernel_heights.is_empty()
                && m.block_time_misses.is_empty()
        );
        assert_eq!(m.cache_node.as_deref(), Some("https://b"));
    }

    #[test]
    fn failed_update_changes_nothing() {
        let dir = tempfile::tempdir().unwrap();
        let store = MetaStore::open(dir.path().to_str().unwrap()).unwrap();
        let r: CoreResult<()> = store.update(|m| {
            m.notes.insert("k".into(), "v".into());
            Err(CoreError::InvalidArgument("no".into()))
        });
        assert!(r.is_err());
        assert!(store.snapshot().notes.is_empty());
        assert!(!dir.path().join(META_FILE).exists());
    }

    fn corrupt_copies(dir: &Path) -> Vec<Vec<u8>> {
        let mut v: Vec<_> = fs::read_dir(dir)
            .unwrap()
            .filter_map(|e| e.ok())
            .filter(|e| {
                e.file_name()
                    .to_string_lossy()
                    .starts_with("wfe_meta.json.corrupt-")
            })
            .map(|e| fs::read(e.path()).unwrap())
            .collect();
        v.sort();
        v
    }

    #[test]
    fn unreadable_file_is_moved_aside_not_lost() {
        let dir = tempfile::tempdir().unwrap();
        fs::write(dir.path().join(META_FILE), b"{ not json").unwrap();
        let store = MetaStore::open(dir.path().to_str().unwrap()).unwrap();
        assert_eq!(store.snapshot(), Meta::default());
        assert_eq!(corrupt_copies(dir.path()), vec![b"{ not json".to_vec()]);
        std::thread::sleep(std::time::Duration::from_millis(5));
        fs::write(dir.path().join(META_FILE), b"[second").unwrap();
        MetaStore::open(dir.path().to_str().unwrap()).unwrap();
        assert_eq!(
            corrupt_copies(dir.path()),
            vec![b"[second".to_vec(), b"{ not json".to_vec()],
            "the first damaged copy is kept"
        );
    }

    #[test]
    fn a_newer_files_version_is_never_rewritten() {
        let dir = tempfile::tempdir().unwrap();
        let text = br#"{"version":99,"notes":{"a":"b"},"future_field":[1]}"#;
        fs::write(dir.path().join(META_FILE), text).unwrap();
        let store = MetaStore::open(dir.path().to_str().unwrap()).unwrap();
        assert_eq!(store.snapshot().notes["a"], "b", "still readable");
        let e = store
            .update(|m| {
                m.notes.clear();
                Ok(())
            })
            .unwrap_err();
        assert!(e.to_string().contains("newer version"), "{e}");
        assert_eq!(fs::read(dir.path().join(META_FILE)).unwrap(), text);
    }

    fn rec(status: &str, exported: i64) -> Record {
        Record {
            slate_id: Some("s".into()),
            kind: "Sent".into(),
            status: status.into(),
            exported_at_unix: Some(exported),
            ..Record::default()
        }
    }

    #[test]
    fn a_later_import_fills_gaps_and_updates_status_when_newer() {
        let mut stored = rec("AwaitingRecipient", 100);
        assert!(
            !stored.merge_from(&stored.clone()),
            "identical: nothing changes"
        );

        let mut later = rec("Confirmed", 200);
        later.confirmed = true;
        later.note = Some("rent".into());
        later.fee = Some(7);
        later.block_height = Some(9);
        later.output_commits = vec!["c".into()];
        assert!(stored.merge_from(&later));
        assert_eq!(stored.status, "Confirmed");
        assert!(stored.confirmed);
        assert_eq!(
            (stored.note.as_deref(), stored.fee, stored.block_height),
            (Some("rent"), Some(7), Some(9))
        );
        assert_eq!(stored.output_commits, ["c"]);
        assert_eq!(stored.exported_at_unix, Some(200));

        // A newer file's edited note replaces the stored one.
        let mut edited = rec("Confirmed", 250);
        edited.note = Some("rent, March".into());
        assert!(stored.merge_from(&edited));
        assert_eq!(stored.note.as_deref(), Some("rent, March"));

        // An older file fills gaps but never changes the status or an existing note.
        let mut older = rec("AwaitingRecipient", 50);
        older.note = Some("old note".into());
        older.counterparty = Some("bob".into());
        assert!(stored.merge_from(&older));
        assert_eq!(stored.status, "Confirmed");
        assert_eq!(stored.note.as_deref(), Some("rent, March"));
        assert_eq!(stored.counterparty.as_deref(), Some("bob"));

        // A newer file that is still pending does not undo a settled status.
        let mut stale = rec("AwaitingConfirmation", 300);
        stale.note = Some("rent, March".into());
        assert!(!stored.merge_from(&stale));
        assert_eq!(stored.status, "Confirmed");
    }

    #[test]
    fn older_files_without_new_fields_still_load() {
        let dir = tempfile::tempdir().unwrap();
        fs::write(dir.path().join(META_FILE), br#"{"notes":{"l:1":"x"}}"#).unwrap();
        let store = MetaStore::open(dir.path().to_str().unwrap()).unwrap();
        assert_eq!(store.snapshot().notes["l:1"], "x");
        assert_eq!(store.snapshot().version, META_VERSION);
    }
}
