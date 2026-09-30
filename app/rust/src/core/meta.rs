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
    #[serde(default)]
    pub note: Option<String>,
}

/// Facts about one of our transactions, recorded when the core performs a step. Keyed by slate id.
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub(crate) struct Annotation {
    #[serde(default)]
    pub counterparty: Option<String>,
    /// This wallet finalized the send (the recipient had signed).
    #[serde(default)]
    pub finalized: bool,
    #[serde(default)]
    pub kernel_excess: Option<String>,
}

/// One transaction as it travels in a history file, and as it is kept once imported.
/// Amounts are in the smallest unit. Nothing in here is secret.
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub(crate) struct Record {
    #[serde(default)]
    pub slate_id: Option<String>,
    #[serde(default)]
    pub kernel_excess: Option<String>,
    #[serde(default)]
    pub kernel_lookup_min_height: Option<u64>,
    /// `TxKind` name: Coinbase, Received, Sent, ReceivedCancelled, SentCancelled.
    pub kind: String,
    /// `TxStatus` name at export time.
    pub status: String,
    pub confirmed: bool,
    pub created_at_unix: i64,
    #[serde(default)]
    pub block_height: Option<u64>,
    #[serde(default)]
    pub block_time_unix: Option<i64>,
    pub amount_credited: u64,
    pub amount_debited: u64,
    #[serde(default)]
    pub fee: Option<u64>,
    #[serde(default)]
    pub num_inputs: u32,
    #[serde(default)]
    pub num_outputs: u32,
    #[serde(default)]
    pub output_commits: Vec<String>,
    #[serde(default)]
    pub counterparty: Option<String>,
    #[serde(default)]
    pub note: Option<String>,
    #[serde(default)]
    pub ttl_cutoff_height: Option<u64>,
    /// epic-wallet's `ParticipantMessages`, as it serialises them.
    #[serde(default)]
    pub messages: Option<serde_json::Value>,
    /// epic-wallet's `StoredProofInfo` (public keys and signatures only).
    #[serde(default)]
    pub payment_proof: Option<serde_json::Value>,
}

impl Record {
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
        }
    }
}

fn io_err(what: &str, path: &Path, e: std::io::Error) -> CoreError {
    CoreError::Io(format!("{what} {}: {e}", path.display()))
}

/// Writes `bytes` to `path` so a crash leaves either the old file or the new one.
pub(crate) fn write_atomic(path: &Path, bytes: &[u8]) -> CoreResult<()> {
    let dir = path.parent().unwrap_or_else(|| Path::new("."));
    fs::create_dir_all(dir).map_err(|e| io_err("creating", dir, e))?;
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
    /// parsed is moved aside to `wfe_meta.json.corrupt` rather than overwritten, so notes are
    /// never destroyed silently, and the wallet still opens.
    pub(crate) fn open(data_dir: &str) -> CoreResult<MetaStore> {
        let path = Path::new(data_dir).join(META_FILE);
        let meta = match fs::read(&path) {
            Ok(bytes) => match serde_json::from_slice::<Meta>(&bytes) {
                Ok(m) => m,
                Err(e) => {
                    let aside = path.with_extension("json.corrupt");
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
        let mut next = guard.clone();
        let out = f(&mut next)?;
        if next != *guard {
            let bytes = serde_json::to_vec_pretty(&next)
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

    #[test]
    fn unreadable_file_is_moved_aside_not_lost() {
        let dir = tempfile::tempdir().unwrap();
        fs::write(dir.path().join(META_FILE), b"{ not json").unwrap();
        let store = MetaStore::open(dir.path().to_str().unwrap()).unwrap();
        assert_eq!(store.snapshot(), Meta::default());
        assert_eq!(
            fs::read(dir.path().join("wfe_meta.json.corrupt")).unwrap(),
            b"{ not json"
        );
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
