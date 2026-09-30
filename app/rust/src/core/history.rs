//! The transaction list: epic-wallet's live log merged with the app's archive (`core/meta.rs`).
//!
//! Everything here is pure: `Session` gathers the live rows under the wallet lock and hands them
//! over, so the rules can be tested on synthetic rows.
//!
//! Rules, from epic-wallet 4.0.2 :
//! - Created outputs: a receive row (`TxReceived*`, `ConfirmedCoinbase`) owns every output any
//!   version of which points at it. A send row owns only the outputs it created as change, which
//!   `lock_tx_context` saves `Unconfirmed`; its inputs are re-pointed at it too, but were never
//!   `Unconfirmed` under its id. The output history table keeps the earlier versions.
//! - Status: `*Cancelled` is cancelled; `confirmed` is confirmed; an unconfirmed send is awaiting
//!   the recipient until it is finalized (its stored transaction carries a real kernel, or it went
//!   to the mempool, or this core finalized it); anything else unconfirmed awaits confirmation.
//! - Cancellable: epic-wallet cancels only an unconfirmed `TxSentCreated` or `TxReceived`
//!   (`tx.rs:309`); of those sends, only one still awaiting the recipient is offered.
//! - A live row absorbs an archive record matching by slate id, then kernel, then a created
//!   commitment. Live status and amounts win, except on rows a scan rebuilt ("Restore"), which only
//!   know one output: those take the record's kind, amounts and time.

use std::collections::{BTreeSet, HashMap, HashSet};

use epic_wallet_libwallet::{OutputData, OutputStatus, TxLogEntry, TxLogEntryType};
use epic_wallet_util::epic_util::to_hex;

use super::meta::{Meta, Record};
use crate::api::types::{TxEntry, TxKind, TxSource, TxStatus};

/// `public_addr` epic-wallet writes on rows a scan rebuilt (`scan.rs:241`).
pub(crate) const RESTORE_ADDR: &str = "Restore";

/// One row of epic-wallet's log with what the core read about it from the outputs.
#[derive(Debug, Clone)]
pub(crate) struct LiveTx {
    pub entry: TxLogEntry,
    pub created_commits: Vec<String>,
    /// Block height of a created output that is on chain.
    pub block_height: Option<u64>,
    /// The send's stored transaction holds the final kernel (see `stored_tx::kernel_is_final`).
    pub finalized: bool,
}

/// A merged transaction plus what an export needs beyond `TxEntry`.
#[derive(Debug, Clone)]
pub(crate) struct MergedTx {
    pub tx: TxEntry,
    /// Every key the transaction was ever known by, for notes.
    pub aliases: Vec<String>,
    pub kernel_lookup_min_height: Option<u64>,
    pub messages: Option<serde_json::Value>,
    pub payment_proof: Option<serde_json::Value>,
    /// For a finalized send the node refused: the height after which a kernel that is still not
    /// on chain makes it releasable. `enrich` looks the kernel up once the tip passes it.
    pub release_check_after: Option<u64>,
}

pub(crate) fn kind_of(t: &TxLogEntryType) -> TxKind {
    match t {
        TxLogEntryType::ConfirmedCoinbase => TxKind::Coinbase,
        TxLogEntryType::TxReceived | TxLogEntryType::TxReceivedMempool => TxKind::Received,
        TxLogEntryType::TxSent | TxLogEntryType::TxSentMempool | TxLogEntryType::TxSentCreated => {
            TxKind::Sent
        }
        TxLogEntryType::TxReceivedCancelled => TxKind::ReceivedCancelled,
        TxLogEntryType::TxSentCancelled => TxKind::SentCancelled,
    }
}

pub(crate) fn kind_name(k: TxKind) -> &'static str {
    match k {
        TxKind::Coinbase => "Coinbase",
        TxKind::Received => "Received",
        TxKind::Sent => "Sent",
        TxKind::ReceivedCancelled => "ReceivedCancelled",
        TxKind::SentCancelled => "SentCancelled",
    }
}

fn kind_from(s: &str) -> TxKind {
    match s {
        "Coinbase" => TxKind::Coinbase,
        "Sent" => TxKind::Sent,
        "ReceivedCancelled" => TxKind::ReceivedCancelled,
        "SentCancelled" => TxKind::SentCancelled,
        _ => TxKind::Received,
    }
}

pub(crate) fn status_name(s: TxStatus) -> &'static str {
    match s {
        TxStatus::AwaitingRecipient => "AwaitingRecipient",
        TxStatus::AwaitingConfirmation => "AwaitingConfirmation",
        TxStatus::Confirmed => "Confirmed",
        TxStatus::Cancelled => "Cancelled",
    }
}

fn status_from(s: &str, confirmed: bool) -> TxStatus {
    match s {
        "AwaitingRecipient" => TxStatus::AwaitingRecipient,
        "AwaitingConfirmation" => TxStatus::AwaitingConfirmation,
        "Cancelled" => TxStatus::Cancelled,
        "Confirmed" => TxStatus::Confirmed,
        _ if confirmed => TxStatus::Confirmed,
        _ => TxStatus::AwaitingConfirmation,
    }
}

fn is_send(t: &TxLogEntryType) -> bool {
    matches!(
        t,
        TxLogEntryType::TxSent
            | TxLogEntryType::TxSentMempool
            | TxLogEntryType::TxSentCreated
            | TxLogEntryType::TxSentCancelled
    )
}

/// epic-wallet's log rows with what the outputs say about each. `current` are the `o` rows,
/// `history` the `h` rows; `stored_final` reads a send's stored transaction and is only called
/// for unconfirmed sends. Outputs are indexed by the tx they point at once, so this is linear in
/// rows plus outputs.
pub(crate) fn live_rows(
    txs: Vec<TxLogEntry>,
    current: &[OutputData],
    history: &[OutputData],
    stored_final: impl Fn(&TxLogEntry) -> bool,
) -> Vec<LiveTx> {
    let mut by_tx: HashMap<u32, Vec<&OutputData>> = HashMap::new();
    for o in current.iter().chain(history) {
        if let Some(id) = o.tx_log_entry {
            by_tx.entry(id).or_default().push(o);
        }
    }
    let mut current_by_commit: HashMap<&str, &OutputData> = HashMap::new();
    for o in current {
        if let Some(c) = o.commit.as_deref() {
            current_by_commit.insert(c, o);
        }
    }
    txs.into_iter()
        .map(|entry| {
            let linked = by_tx.get(&entry.id).map(Vec::as_slice).unwrap_or(&[]);
            let created_commits = created_commits_of(&entry, linked.iter().copied());
            let block_height = created_commits
                .iter()
                .filter_map(|c| current_by_commit.get(c.as_str()))
                .filter(|o| on_chain(o))
                .map(|o| o.height)
                .filter(|h| *h > 0)
                .min();
            let finalized = matches!(
                entry.tx_type,
                TxLogEntryType::TxSent
                    | TxLogEntryType::TxSentCreated
                    | TxLogEntryType::TxSentMempool
            ) && !entry.confirmed
                && stored_final(&entry);
            LiveTx {
                entry,
                created_commits,
                block_height,
                finalized,
            }
        })
        .collect()
}

fn on_chain(o: &OutputData) -> bool {
    matches!(
        o.status,
        OutputStatus::Unspent | OutputStatus::Locked | OutputStatus::Spent
    )
}

fn created_commits_of<'a>(
    tx: &TxLogEntry,
    outputs: impl Iterator<Item = &'a OutputData>,
) -> Vec<String> {
    let send = is_send(&tx.tx_type);
    let set: BTreeSet<String> = outputs
        .filter(|o| o.tx_log_entry == Some(tx.id) && o.root_key_id == tx.parent_key_id)
        .filter(|o| !send || o.status == OutputStatus::Unconfirmed)
        .filter_map(|o| o.commit.clone())
        .collect();
    set.into_iter().collect()
}

/// Commitments of the outputs `tx` created, from every stored version of every output
/// (`outputs` = the `o` rows followed by the output history `h` rows).
#[cfg(test)]
pub(crate) fn created_commits(tx: &TxLogEntry, outputs: &[OutputData]) -> Vec<String> {
    created_commits_of(tx, outputs.iter())
}

/// Block height of the first of `commits` whose current row (`current` = the `o` rows) is on chain.
#[cfg(test)]
pub(crate) fn confirmed_height(commits: &[String], current: &[OutputData]) -> Option<u64> {
    current
        .iter()
        .filter(|o| o.commit.as_ref().is_some_and(|c| commits.contains(c)))
        .filter(|o| {
            matches!(
                o.status,
                OutputStatus::Unspent | OutputStatus::Locked | OutputStatus::Spent
            )
        })
        .map(|o| o.height)
        .filter(|h| *h > 0)
        .min()
}

fn live_status(live: &LiveTx, finalized_by_us: bool) -> TxStatus {
    let t = &live.entry;
    match t.tx_type {
        TxLogEntryType::TxSentCancelled | TxLogEntryType::TxReceivedCancelled => {
            TxStatus::Cancelled
        }
        _ if t.confirmed => TxStatus::Confirmed,
        TxLogEntryType::TxSentMempool => TxStatus::AwaitingConfirmation,
        TxLogEntryType::TxSent | TxLogEntryType::TxSentCreated => {
            if live.finalized || finalized_by_us {
                TxStatus::AwaitingConfirmation
            } else {
                TxStatus::AwaitingRecipient
            }
        }
        _ => TxStatus::AwaitingConfirmation,
    }
}

fn some_str(s: &Option<String>) -> Option<String> {
    s.as_ref()
        .map(|v| v.trim())
        .filter(|v| !v.is_empty())
        .map(str::to_owned)
}

fn base_key(
    slate: &Option<String>,
    kernel: &Option<String>,
    commits: &[String],
    id: Option<u32>,
) -> String {
    if let Some(s) = slate {
        format!("s:{s}")
    } else if let Some(k) = kernel {
        format!("k:{k}")
    } else if let Some(c) = commits.first() {
        format!("c:{c}")
    } else if let Some(i) = id {
        format!("l:{i}")
    } else {
        "x:unknown".to_owned()
    }
}

fn aliases_of(tx: &TxEntry) -> Vec<String> {
    let mut v = vec![tx.key.clone()];
    if let Some(s) = &tx.slate_id {
        v.push(format!("s:{s}"));
    }
    if let Some(k) = &tx.kernel_excess {
        v.push(format!("k:{k}"));
    }
    v.extend(tx.output_commits.iter().map(|c| format!("c:{c}")));
    if let Some(i) = tx.id {
        v.push(format!("l:{i}"));
    }
    let mut seen = HashSet::new();
    v.retain(|a| seen.insert(a.clone()));
    v
}

fn from_live(live: &LiveTx, meta: &Meta) -> MergedTx {
    let t = &live.entry;
    let slate_id = t.tx_slate_id.map(|u| u.to_string());
    let ann = slate_id.as_ref().and_then(|s| meta.annotations.get(s));
    let finalized = live.finalized
        || ann.is_some_and(|a| a.finalized)
        || t.tx_type == TxLogEntryType::TxSentMempool;
    let log_kernel = t.kernel_excess.map(|c| to_hex(c.0.to_vec()));
    let ann_kernel = ann.and_then(|a| a.kernel_excess.clone());
    // A send's kernel is final only once it is finalized: at lock time epic-wallet stores
    // `calc_excess` of the slate before the recipient's output is in (`selection.rs:147-150`).
    // That value is never shown, exported or looked up.
    let kernel_excess = if is_send(&t.tx_type) {
        if finalized || t.confirmed {
            ann_kernel.or(log_kernel)
        } else {
            None
        }
    } else {
        log_kernel.or(ann_kernel)
    };
    let restored = t.public_addr.as_deref() == Some(RESTORE_ADDR);
    let counterparty = ann
        .and_then(|a| some_str(&a.counterparty))
        .or_else(|| some_str(&t.public_addr).filter(|a| a != RESTORE_ADDR));
    // Heights come from our own data first: a created output on chain, then a kernel height
    // cached earlier, then the log's `confirmation_height`. epic-wallet sets that to the node's tip
    // when it saw the confirmation (`updater.rs:356, 370`), so it can be a few blocks late, but it
    // needs no node call. Only rows with none of these send their kernel to the node (`enrich`).
    let block_height = live.block_height.or_else(|| {
        if t.confirmed {
            kernel_excess
                .as_ref()
                .and_then(|k| meta.kernel_heights.get(k).copied())
                .filter(|h| *h > 0)
                .or(t.confirmation_height.filter(|h| *h > 0))
        } else {
            None
        }
    });
    let status = live_status(live, ann.is_some_and(|a| a.finalized));
    // epic-wallet would also cancel a send that was finalized and posted, but that only unlocks
    // outputs the chain may still spend, so such a send is not offered.
    let cancellable = match t.tx_type {
        TxLogEntryType::TxSentCreated => status == TxStatus::AwaitingRecipient,
        TxLogEntryType::TxReceived => !t.confirmed,
        _ => false,
    };
    let repostable = !t.confirmed
        && live.finalized
        && matches!(
            t.tx_type,
            TxLogEntryType::TxSentCreated | TxLogEntryType::TxSent | TxLogEntryType::TxSentMempool
        );
    // Releasing (cancel after the fact) only for a send the node refused, whose kernel a lookup
    // did not find on chain at least a day of blocks after it was finalized.
    let refused = ann.is_some_and(|a| a.post_refused);
    let release_check_after = if repostable && refused && t.tx_type == TxLogEntryType::TxSentCreated
    {
        ann.and_then(|a| a.finalized_height)
            .or(t.kernel_lookup_min_height)
            .map(|h| h.saturating_add(BLOCKS_PER_DAY))
    } else {
        None
    };
    let releasable = release_check_after.is_some_and(|after| {
        ann.and_then(|a| a.kernel_absent_at)
            .is_some_and(|tip| tip >= after)
    });
    let status_detail = if repostable {
        ann.and_then(|a| a.post_error.as_deref()).map(|e| {
            format!(
                "The network has not taken this payment yet: {}",
                e.lines().next().unwrap_or(e)
            )
        })
    } else {
        None
    };
    let tx = TxEntry {
        key: String::new(),
        id: Some(t.id),
        slate_id,
        kind: kind_of(&t.tx_type),
        status,
        source: if restored {
            TxSource::Restored
        } else {
            TxSource::Wallet
        },
        created_at_unix: t.creation_ts.timestamp(),
        time_unix: 0,
        confirmed: t.confirmed,
        block_height,
        block_time_unix: None,
        amount_credited: t.amount_credited,
        amount_debited: t.amount_debited,
        fee: t.fee,
        num_inputs: u32::try_from(t.num_inputs).unwrap_or(u32::MAX),
        num_outputs: u32::try_from(t.num_outputs).unwrap_or(u32::MAX),
        kernel_excess,
        output_commits: live.created_commits.clone(),
        counterparty,
        note: None,
        ttl_cutoff_height: t.ttl_cutoff_height,
        cancellable,
        repostable,
        status_detail,
        releasable,
        finalized_at_unix: ann.and_then(|a| a.finalized_at_unix),
    };
    MergedTx {
        release_check_after,
        tx,
        aliases: Vec::new(),
        kernel_lookup_min_height: t.kernel_lookup_min_height,
        messages: t
            .messages
            .as_ref()
            .and_then(|m| serde_json::to_value(m).ok()),
        payment_proof: t
            .payment_proof
            .as_ref()
            .and_then(|p| serde_json::to_value(p).ok()),
    }
}

fn from_record(r: &Record) -> MergedTx {
    let status = status_from(&r.status, r.confirmed);
    let tx = TxEntry {
        key: String::new(),
        id: None,
        slate_id: some_str(&r.slate_id),
        kind: kind_from(&r.kind),
        status,
        source: TxSource::Imported,
        created_at_unix: r.created_at_unix,
        time_unix: 0,
        confirmed: r.confirmed,
        block_height: r.block_height,
        block_time_unix: r.block_time_unix,
        amount_credited: r.amount_credited,
        amount_debited: r.amount_debited,
        fee: r.fee,
        num_inputs: r.num_inputs,
        num_outputs: r.num_outputs,
        kernel_excess: some_str(&r.kernel_excess),
        output_commits: r.output_commits.clone(),
        counterparty: some_str(&r.counterparty),
        note: None,
        ttl_cutoff_height: r.ttl_cutoff_height,
        cancellable: false,
        repostable: false,
        status_detail: some_str(&r.status_detail),
        releasable: false,
        finalized_at_unix: None,
    };
    MergedTx {
        release_check_after: None,
        tx,
        aliases: Vec::new(),
        kernel_lookup_min_height: r.kernel_lookup_min_height,
        messages: r.messages.clone(),
        payment_proof: r.payment_proof.clone(),
    }
}

/// Fills `m` (a live row) from the record `r` it matched.
fn absorb(m: &mut MergedTx, r: &Record) {
    let tx = &mut m.tx;
    if tx.source == TxSource::Restored {
        // The scan saw one output; the record knows the whole transaction.
        tx.source = TxSource::Imported;
        tx.kind = kind_from(&r.kind);
        tx.amount_credited = r.amount_credited;
        tx.amount_debited = r.amount_debited;
        tx.num_inputs = r.num_inputs;
        tx.num_outputs = r.num_outputs;
        tx.created_at_unix = r.created_at_unix;
        tx.fee = r.fee.or(tx.fee);
    } else {
        tx.fee = tx.fee.or(r.fee);
    }
    if tx.slate_id.is_none() {
        tx.slate_id = some_str(&r.slate_id);
    }
    if tx.kernel_excess.is_none() {
        tx.kernel_excess = some_str(&r.kernel_excess);
    }
    if tx.counterparty.is_none() {
        tx.counterparty = some_str(&r.counterparty);
    }
    if tx.block_height.is_none() {
        tx.block_height = r.block_height;
    }
    if tx.block_time_unix.is_none() {
        tx.block_time_unix = r.block_time_unix;
    }
    for c in &r.output_commits {
        if !tx.output_commits.contains(c) {
            tx.output_commits.push(c.clone());
        }
    }
    if m.kernel_lookup_min_height.is_none() {
        m.kernel_lookup_min_height = r.kernel_lookup_min_height;
    }
    if m.messages.is_none() {
        m.messages = r.messages.clone();
    }
    if m.payment_proof.is_none() {
        m.payment_proof = r.payment_proof.clone();
    }
}

/// Live rows by slate id, kernel and created commitment, so matching a record is a lookup
/// instead of a walk over every row. Kept current as rows absorb records.
#[derive(Default)]
struct RowIndex {
    slate: HashMap<String, Vec<usize>>,
    kernel: HashMap<String, Vec<usize>>,
    commit: HashMap<String, Vec<usize>>,
}

impl RowIndex {
    fn add(&mut self, i: usize, tx: &TxEntry) {
        fn put(map: &mut HashMap<String, Vec<usize>>, k: &str, i: usize) {
            let v = map.entry(k.to_owned()).or_default();
            if !v.contains(&i) {
                v.push(i);
            }
        }
        if let Some(s) = &tx.slate_id {
            put(&mut self.slate, s, i);
        }
        if let Some(k) = &tx.kernel_excess {
            put(&mut self.kernel, k, i);
        }
        for c in &tx.output_commits {
            put(&mut self.commit, c, i);
        }
    }

    /// Rows matching `r`: by slate id, then kernel, then created commitment, each group in row
    /// order.
    fn matches(&self, r: &Record, hidden: &[bool]) -> Vec<usize> {
        let mut out: Vec<usize> = Vec::new();
        let mut group = |mut hits: Vec<usize>, out: &mut Vec<usize>| {
            hits.sort_unstable();
            for i in hits {
                if !hidden[i] && !out.contains(&i) {
                    out.push(i);
                }
            }
        };
        let lookup = |map: &HashMap<String, Vec<usize>>, k: &Option<String>| {
            k.as_ref()
                .and_then(|k| map.get(k))
                .cloned()
                .unwrap_or_default()
        };
        group(lookup(&self.slate, &r.slate_id), &mut out);
        group(lookup(&self.kernel, &r.kernel_excess), &mut out);
        let by_commit = r
            .output_commits
            .iter()
            .filter_map(|c| self.commit.get(c))
            .flatten()
            .copied()
            .collect();
        group(by_commit, &mut out);
        out
    }
}

fn is_incoming(k: TxKind) -> bool {
    matches!(
        k,
        TxKind::Received | TxKind::ReceivedCancelled | TxKind::Coinbase
    )
}

/// Short stable hash of what identifies an imported row.
fn identity_hash(tx: &TxEntry) -> String {
    let text = format!(
        "{:?}|{:?}|{:?}|{}|{}|{}",
        tx.slate_id,
        tx.kernel_excess,
        tx.output_commits,
        tx.created_at_unix,
        tx.amount_credited,
        tx.amount_debited
    );
    let d = ring::digest::digest(&ring::digest::SHA256, text.as_bytes());
    hex::encode(&d.as_ref()[..4])
}

/// Aliases that more than one row carries.
pub(crate) fn shared_aliases(rows: &[MergedTx]) -> HashSet<String> {
    let mut seen = HashSet::new();
    let mut shared = HashSet::new();
    for a in rows.iter().flat_map(|m| m.aliases.iter()) {
        if !seen.insert(a.clone()) {
            shared.insert(a.clone());
        }
    }
    shared
}

/// Merges live rows and the archive into the list the UI shows, newest first.
pub(crate) fn merge(live: &[LiveTx], meta: &Meta) -> Vec<MergedTx> {
    let mut rows: Vec<MergedTx> = live.iter().map(|l| from_live(l, meta)).collect();
    let mut hidden = vec![false; rows.len()];
    let mut record_notes: HashMap<usize, String> = HashMap::new();
    let mut imported: Vec<(MergedTx, Option<String>)> = Vec::new();
    let mut index = RowIndex::default();
    for (i, m) in rows.iter().enumerate() {
        index.add(i, &m.tx);
    }

    for r in &meta.records {
        let found = index.matches(r, &hidden);
        if found.is_empty() {
            imported.push((from_record(r), some_str(&r.note)));
            continue;
        }
        // Prefer a row of the record's own kind (both sides of a self-send share a slate id),
        // and among those a row the wallet made itself over one a scan rebuilt.
        let kind = kind_from(&r.kind);
        let same_kind = |i: &usize| {
            let k = rows[*i].tx.kind;
            k == kind || (rows[*i].tx.source == TxSource::Restored && is_incoming(kind))
        };
        let made = |i: &usize| rows[*i].tx.source != TxSource::Restored;
        let primary = found
            .iter()
            .copied()
            .find(|i| same_kind(i) && made(i))
            .or_else(|| found.iter().copied().find(|i| same_kind(i)))
            .or_else(|| found.iter().copied().find(|i| made(i)))
            .unwrap_or(found[0]);
        absorb(&mut rows[primary], r);
        if let Some(n) = some_str(&r.note) {
            record_notes.entry(primary).or_insert(n);
        }
        // Other outputs of the same transaction that a scan rebuilt as separate "Received" rows.
        for i in found {
            if i != primary && rows[i].tx.source == TxSource::Restored {
                let commits = rows[i].tx.output_commits.clone();
                for c in commits {
                    if !rows[primary].tx.output_commits.contains(&c) {
                        rows[primary].tx.output_commits.push(c);
                    }
                }
                hidden[i] = true;
            }
        }
        // The primary row may now carry the record's slate id, kernel and commitments.
        index.add(primary, &rows[primary].tx);
    }

    let mut out: Vec<(MergedTx, Option<String>)> = rows
        .into_iter()
        .enumerate()
        .filter(|(i, _)| !hidden[*i])
        .map(|(i, m)| {
            let n = record_notes.remove(&i);
            (m, n)
        })
        .collect();
    out.extend(imported);

    let mut used = HashSet::new();
    let mut result = Vec::with_capacity(out.len());
    let mut record_notes_by_row = Vec::with_capacity(out.len());
    for (mut m, record_note) in out {
        let tx = &mut m.tx;
        let mut key = base_key(&tx.slate_id, &tx.kernel_excess, &tx.output_commits, tx.id);
        if !used.insert(key.clone()) {
            // Both sides of a self-send share a slate id. The suffix depends only on the row
            // itself, so a note saved under it stays with that row when others are added.
            key = match tx.id {
                Some(i) => format!("{key}#l{i}"),
                None => format!("{key}#{}", identity_hash(tx)),
            };
            used.insert(key.clone());
        }
        tx.key = key;
        if tx.block_time_unix.is_none() {
            tx.block_time_unix = tx
                .block_height
                .and_then(|h| meta.block_times.get(&h).copied())
                .filter(|t| *t > 0);
        }
        tx.time_unix = match tx.source {
            TxSource::Restored => tx.block_time_unix.unwrap_or(tx.created_at_unix),
            _ => tx.created_at_unix,
        };
        m.aliases = aliases_of(tx);
        record_notes_by_row.push(record_note);
        result.push(m);
    }
    // A note belongs to a row by its key, or by an alias no other row shares (the two sides of a
    // self-send share `s:<slate>`, and must not show each other's notes).
    let shared = shared_aliases(&result);
    for (m, record_note) in result.iter_mut().zip(record_notes_by_row) {
        let own = meta.notes.get(&m.tx.key).cloned();
        let by_alias = || {
            m.aliases
                .iter()
                .filter(|a| !shared.contains(*a))
                .find_map(|a| meta.notes.get(a).cloned())
        };
        m.tx.note = own.or_else(by_alias).or(record_note);
    }
    result.sort_by(|a, b| {
        b.tx.time_unix
            .cmp(&a.tx.time_unix)
            .then_with(|| b.tx.id.cmp(&a.tx.id))
    });
    result
}

/// Rows of `after` whose height, time, status or kind differ from `before` (by key), or are new.
pub(crate) fn changed_rows(before: &[MergedTx], after: &[MergedTx]) -> u32 {
    let old: HashMap<&str, &TxEntry> = before.iter().map(|m| (m.tx.key.as_str(), &m.tx)).collect();
    let n = after
        .iter()
        .filter(|m| match old.get(m.tx.key.as_str()) {
            Some(o) => {
                (
                    o.block_height,
                    o.block_time_unix,
                    o.status,
                    o.kind,
                    &o.status_detail,
                ) != (
                    m.tx.block_height,
                    m.tx.block_time_unix,
                    m.tx.status,
                    m.tx.kind,
                    &m.tx.status_detail,
                )
            }
            None => true,
        })
        .count();
    u32::try_from(n).unwrap_or(u32::MAX)
}

/// True when the record describes the transaction shown as `tx`.
pub(crate) fn record_matches(r: &Record, tx: &TxEntry) -> bool {
    let eq =
        |a: &Option<String>, b: &Option<String>| matches!((a, b), (Some(x), Some(y)) if x == y);
    eq(&tx.slate_id, &r.slate_id)
        || eq(&tx.kernel_excess, &r.kernel_excess)
        || tx
            .output_commits
            .iter()
            .any(|c| r.output_commits.contains(c))
}

/// The archive record an export writes for `m`.
pub(crate) fn to_record(m: &MergedTx) -> Record {
    let tx = &m.tx;
    Record {
        slate_id: tx.slate_id.clone(),
        kernel_excess: tx.kernel_excess.clone(),
        kernel_lookup_min_height: m.kernel_lookup_min_height,
        kind: kind_name(tx.kind).to_owned(),
        status: status_name(tx.status).to_owned(),
        confirmed: tx.confirmed,
        created_at_unix: tx.created_at_unix,
        block_height: tx.block_height,
        block_time_unix: tx.block_time_unix,
        amount_credited: tx.amount_credited,
        amount_debited: tx.amount_debited,
        fee: tx.fee,
        num_inputs: tx.num_inputs,
        num_outputs: tx.num_outputs,
        output_commits: tx.output_commits.clone(),
        counterparty: tx.counterparty.clone(),
        note: tx.note.clone(),
        ttl_cutoff_height: tx.ttl_cutoff_height,
        messages: m.messages.clone(),
        payment_proof: m.payment_proof.clone(),
        status_detail: tx.status_detail.clone(),
        // The file's own `exported_at_unix` stands for every record in it.
        exported_at_unix: None,
    }
}

/// About a day of Epic blocks (one a minute): how long a pending record with no TTL may stay
/// off chain before it counts as never completed.
pub(crate) const BLOCKS_PER_DAY: u64 = 1_440;

/// What the chain says about an imported record that was still pending when exported.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Settlement {
    /// Its kernel is in the block at this height.
    Confirmed(u64),
    /// Its kernel was not found by `tip`, past the record's TTL (or a day of blocks).
    NeverCompleted { tip: u64 },
}

/// True for an unmatched imported record whose export said it was still pending, and which has
/// the kernel and lower search bound a lookup needs.
pub(crate) fn needs_settling(m: &MergedTx) -> bool {
    m.tx.id.is_none()
        && m.tx.source == TxSource::Imported
        // Only a record whose kernel is final: one still awaiting the recipient was never
        // finalized when exported, so its kernel cannot be on chain.
        && m.tx.status == TxStatus::AwaitingConfirmation
        && m.tx.kernel_excess.is_some()
        && m.kernel_lookup_min_height.is_some()
}

/// The verdict for a pending record given a kernel lookup up to `tip`, or `None` to ask again
/// on a later refresh.
pub(crate) fn settle(
    found_at: Option<u64>,
    lookup_min_height: u64,
    ttl_cutoff_height: Option<u64>,
    tip: u64,
) -> Option<Settlement> {
    if let Some(h) = found_at {
        return Some(Settlement::Confirmed(h));
    }
    let deadline = ttl_cutoff_height.unwrap_or(lookup_min_height.saturating_add(BLOCKS_PER_DAY));
    (tip > deadline).then_some(Settlement::NeverCompleted { tip })
}

/// Writes `s` into the record, so the verdict is cached and exported with it.
pub(crate) fn apply_settlement(r: &mut Record, s: Settlement) {
    match s {
        Settlement::Confirmed(h) => {
            r.status = status_name(TxStatus::Confirmed).into();
            r.confirmed = true;
            r.block_height = Some(h);
            r.status_detail = None;
        }
        Settlement::NeverCompleted { tip } => {
            r.status = status_name(TxStatus::Cancelled).into();
            r.confirmed = false;
            r.kind = match kind_from(&r.kind) {
                TxKind::Sent | TxKind::SentCancelled => kind_name(TxKind::SentCancelled),
                _ => kind_name(TxKind::ReceivedCancelled),
            }
            .into();
            r.status_detail = Some(format!(
                "Never completed: it had not reached the network by block {tip}"
            ));
        }
    }
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;
    use epic_wallet_util::epic_keychain::{ExtKeychain, Identifier, Keychain};

    pub(crate) fn parent() -> Identifier {
        ExtKeychain::derive_key_id(2, 0, 0, 0, 0)
    }

    pub(crate) fn entry(id: u32, t: TxLogEntryType) -> TxLogEntry {
        TxLogEntry::new(parent(), t, id)
    }

    pub(crate) fn output(
        n: u32,
        commit: &str,
        status: OutputStatus,
        tx: u32,
        height: u64,
    ) -> OutputData {
        OutputData {
            root_key_id: parent(),
            key_id: ExtKeychain::derive_key_id(3, 0, 0, n, 0),
            n_child: n,
            commit: Some(commit.to_owned()),
            mmr_index: None,
            value: 100,
            status,
            height,
            lock_height: 0,
            is_coinbase: false,
            tx_log_entry: Some(tx),
        }
    }

    pub(crate) fn live(e: TxLogEntry, commits: &[&str], height: Option<u64>) -> LiveTx {
        LiveTx {
            entry: e,
            created_commits: commits.iter().map(|c| c.to_string()).collect(),
            block_height: height,
            finalized: false,
        }
    }

    #[test]
    fn created_commits_skip_a_sends_inputs() {
        let send = entry(5, TxLogEntryType::TxSent);
        let outputs = vec![
            // Input: first received by tx 1, then locked and spent by the send.
            output(1, "in", OutputStatus::Spent, 5, 10),
            output(1, "in", OutputStatus::Unspent, 1, 10),
            output(1, "in", OutputStatus::Locked, 5, 10),
            // Change: created unconfirmed by the send, now on chain.
            output(2, "change", OutputStatus::Unspent, 5, 20),
            output(2, "change", OutputStatus::Unconfirmed, 5, 15),
        ];
        assert_eq!(created_commits(&send, &outputs), vec!["change".to_owned()]);
        let recv = entry(1, TxLogEntryType::TxReceived);
        assert_eq!(created_commits(&recv, &outputs), vec!["in".to_owned()]);
        assert_eq!(
            confirmed_height(&["change".into()], &outputs[..4]),
            Some(20)
        );
    }

    #[test]
    fn status_and_cancellable_follow_epic_wallet() {
        let mut created = entry(1, TxLogEntryType::TxSentCreated);
        created.tx_slate_id = Some(uuid::Uuid::from_u128(7));
        let mut finalized = live(created.clone(), &[], None);
        finalized.finalized = true;
        let mut confirmed = entry(2, TxLogEntryType::TxSent);
        confirmed.confirmed = true;
        let mempool = entry(3, TxLogEntryType::TxSentMempool);
        let recv = entry(4, TxLogEntryType::TxReceived);
        let cancelled = entry(5, TxLogEntryType::TxSentCancelled);
        let rows = vec![
            live(created, &[], None),
            finalized,
            live(confirmed, &[], None),
            live(mempool, &[], None),
            live(recv, &[], None),
            live(cancelled, &[], None),
        ];
        let merged = merge(&rows, &Meta::default());
        let by_id = |i: u32| {
            merged
                .iter()
                .find(|m| m.tx.id == Some(i))
                .unwrap()
                .tx
                .clone()
        };
        // The first two share a slate id: keys stay unique.
        let first = merged
            .iter()
            .filter(|m| m.tx.id == Some(1))
            .map(|m| (m.tx.status, m.tx.cancellable))
            .collect::<Vec<_>>();
        assert!(first.contains(&(TxStatus::AwaitingRecipient, true)));
        assert!(
            first.contains(&(TxStatus::AwaitingConfirmation, false)),
            "a finalized send is not offered for cancel"
        );
        assert_eq!(
            merged
                .iter()
                .map(|m| &m.tx.key)
                .collect::<HashSet<_>>()
                .len(),
            merged.len()
        );
        assert_eq!(by_id(2).status, TxStatus::Confirmed);
        assert_eq!(by_id(3).status, TxStatus::AwaitingConfirmation);
        assert!(
            !by_id(3).cancellable,
            "epic-wallet refuses to cancel TxSentMempool"
        );
        assert_eq!(by_id(4).status, TxStatus::AwaitingConfirmation);
        assert!(by_id(4).cancellable);
        assert_eq!(by_id(5).status, TxStatus::Cancelled);
        assert!(!by_id(5).cancellable);
    }

    #[test]
    fn restore_rows_hide_the_marker_and_use_block_time() {
        let mut e = entry(0, TxLogEntryType::TxReceived);
        e.public_addr = Some(RESTORE_ADDR.into());
        e.confirmed = true;
        let mut meta = Meta::default();
        meta.block_times.insert(42, 1_700_000_000);
        let m = &merge(&[live(e, &["c1"], Some(42))], &meta)[0].tx;
        assert_eq!(m.source, TxSource::Restored);
        assert_eq!(m.counterparty, None);
        assert_eq!(m.key, "c:c1");
        assert_eq!(m.block_time_unix, Some(1_700_000_000));
        assert_eq!(m.time_unix, 1_700_000_000);
    }

    fn record(slate: Option<&str>, kernel: Option<&str>, commits: &[&str]) -> Record {
        Record {
            slate_id: slate.map(str::to_owned),
            kernel_excess: kernel.map(str::to_owned),
            kind: "Sent".into(),
            status: "Confirmed".into(),
            confirmed: true,
            created_at_unix: 1_600_000_000,
            amount_credited: 30,
            amount_debited: 100,
            fee: Some(7),
            num_inputs: 1,
            num_outputs: 1,
            output_commits: commits.iter().map(|c| c.to_string()).collect(),
            counterparty: Some("bob@relay".into()),
            note: Some("rent".into()),
            ..Record::default()
        }
    }

    #[test]
    fn records_merge_by_slate_kernel_then_commit() {
        let slate = uuid::Uuid::from_u128(9);
        let mut by_slate = entry(1, TxLogEntryType::TxSent);
        by_slate.tx_slate_id = Some(slate);
        by_slate.confirmed = true;
        let mut restored = entry(2, TxLogEntryType::TxReceived);
        restored.public_addr = Some(RESTORE_ADDR.into());
        restored.confirmed = true;
        restored.amount_credited = 30;
        let rows = vec![
            live(by_slate, &[], Some(5)),
            live(restored, &["chg"], Some(9)),
        ];
        let mut meta = Meta::default();
        meta.records
            .push(record(Some(&slate.to_string()), None, &[]));
        meta.records
            .push(record(Some("other-slate"), Some("kern"), &["chg"]));
        meta.records.push(record(None, Some("lonely"), &["gone"]));
        let merged = merge(&rows, &meta);
        assert_eq!(merged.len(), 3, "two live rows plus one imported record");

        let a = merged.iter().find(|m| m.tx.id == Some(1)).unwrap();
        assert_eq!(a.tx.source, TxSource::Wallet);
        assert_eq!(a.tx.counterparty.as_deref(), Some("bob@relay"));
        assert_eq!(a.tx.note.as_deref(), Some("rent"));

        let b = merged.iter().find(|m| m.tx.id == Some(2)).unwrap();
        assert_eq!(
            b.tx.source,
            TxSource::Imported,
            "restored row took the record"
        );
        assert_eq!(b.tx.kind, TxKind::Sent);
        assert_eq!(b.tx.amount_debited, 100);
        assert_eq!(b.tx.fee, Some(7));
        assert_eq!(b.tx.key, "s:other-slate");
        assert_eq!(b.tx.time_unix, 1_600_000_000);
        assert_eq!(b.tx.block_height, Some(9), "live height wins");
        assert!(b.aliases.contains(&"c:chg".to_owned()));

        let c = merged.iter().find(|m| m.tx.id.is_none()).unwrap();
        assert_eq!(c.tx.source, TxSource::Imported);
        assert_eq!(c.tx.key, "k:lonely");
        assert!(!c.tx.cancellable);
    }

    #[test]
    fn a_record_absorbs_every_restored_output_of_its_transaction() {
        let mut rows = Vec::new();
        for (i, c) in ["o1", "o2"].iter().enumerate() {
            let mut e = entry(i as u32, TxLogEntryType::TxReceived);
            e.public_addr = Some(RESTORE_ADDR.into());
            e.confirmed = true;
            rows.push(live(e, &[c], Some(3)));
        }
        let mut meta = Meta::default();
        let mut r = record(None, Some("k"), &["o1", "o2"]);
        r.kind = "Received".into();
        meta.records.push(r);
        let merged = merge(&rows, &meta);
        assert_eq!(merged.len(), 1);
        assert_eq!(merged[0].tx.output_commits.len(), 2);
    }

    #[test]
    fn only_a_finalized_unconfirmed_send_is_repostable() {
        let mut posted = live(entry(1, TxLogEntryType::TxSentCreated), &[], None);
        posted.finalized = true;
        let waiting = live(entry(2, TxLogEntryType::TxSentCreated), &[], None);
        let mut done = live(entry(3, TxLogEntryType::TxSent), &[], None);
        done.entry.confirmed = true;
        done.finalized = true;
        let mut recv = live(entry(4, TxLogEntryType::TxReceived), &[], None);
        recv.finalized = true;
        let merged = merge(&[posted, waiting, done, recv], &Meta::default());
        let r = |i: u32| {
            merged
                .iter()
                .find(|m| m.tx.id == Some(i))
                .unwrap()
                .tx
                .repostable
        };
        assert!(r(1));
        assert!(!r(2), "not finalized: nothing to post");
        assert!(!r(3), "already on chain");
        assert!(!r(4), "receives are posted by the sender");
    }

    #[test]
    fn pending_imports_settle_by_kernel_and_deadline() {
        assert_eq!(
            settle(Some(500), 100, None, 900),
            Some(Settlement::Confirmed(500))
        );
        assert_eq!(
            settle(None, 100, None, 100 + BLOCKS_PER_DAY),
            None,
            "not yet a day"
        );
        assert_eq!(
            settle(None, 100, None, 101 + BLOCKS_PER_DAY),
            Some(Settlement::NeverCompleted {
                tip: 101 + BLOCKS_PER_DAY
            })
        );
        assert_eq!(
            settle(None, 100, Some(160), 161),
            Some(Settlement::NeverCompleted { tip: 161 })
        );
        assert_eq!(
            settle(None, 100, Some(160), 160),
            None,
            "TTL wins over the day"
        );

        let mut r = record(None, Some("kern"), &[]);
        r.status = "AwaitingConfirmation".into();
        r.confirmed = false;
        r.kernel_lookup_min_height = Some(100);
        let mut meta = Meta::default();
        meta.records.push(r.clone());
        assert!(needs_settling(&merge(&[], &meta)[0]));

        let mut gone = r.clone();
        apply_settlement(&mut gone, Settlement::NeverCompleted { tip: 2_000 });
        meta.records = vec![gone];
        let m = &merge(&[], &meta)[0];
        assert!(!needs_settling(m), "a verdict is final");
        assert_eq!(m.tx.status, TxStatus::Cancelled);
        assert_eq!(m.tx.kind, TxKind::SentCancelled);
        assert!(m
            .tx
            .status_detail
            .as_deref()
            .unwrap()
            .contains("Never completed"));
        assert_eq!(
            to_record(m).status_detail,
            m.tx.status_detail,
            "exported with the record"
        );

        let mut found = r;
        apply_settlement(&mut found, Settlement::Confirmed(777));
        meta.records = vec![found];
        let m = &merge(&[], &meta)[0].tx;
        assert_eq!(
            (m.status, m.confirmed, m.block_height),
            (TxStatus::Confirmed, true, Some(777))
        );
    }

    #[test]
    fn heights_come_from_our_data_before_the_node() {
        // A no-change send confirmed through its kernel: the log's confirmation height is used.
        let mut e = entry(1, TxLogEntryType::TxSent);
        e.confirmed = true;
        e.confirmation_height = Some(77);
        let m = &merge(&[live(e.clone(), &[], None)], &Meta::default())[0].tx;
        assert_eq!(m.block_height, Some(77));
        // A created output on chain wins.
        let m = &merge(&[live(e, &["chg"], Some(75))], &Meta::default())[0].tx;
        assert_eq!(m.block_height, Some(75));
    }

    #[test]
    fn changed_rows_counts_height_time_and_status_changes() {
        let mut e = entry(1, TxLogEntryType::TxReceived);
        e.confirmed = true;
        let rows = [live(e, &["c"], Some(5))];
        let before = merge(&rows, &Meta::default());
        assert_eq!(changed_rows(&before, &before), 0);
        let mut meta = Meta::default();
        meta.block_times.insert(5, 1_700_000_000);
        let after = merge(&rows, &meta);
        assert_eq!(changed_rows(&before, &after), 1);
    }

    #[test]
    fn duplicate_imported_keys_are_stable_when_rows_are_added() {
        let mut a = record(Some("dup"), None, &[]);
        a.created_at_unix = 1;
        let mut b = record(Some("dup"), None, &[]);
        b.created_at_unix = 2;
        b.kind = "Received".into();
        let mut meta = Meta::default();
        meta.records = vec![a.clone(), b.clone()];
        let key_of_b = |rows: &[MergedTx]| {
            rows.iter()
                .find(|m| m.tx.created_at_unix == 2)
                .unwrap()
                .tx
                .key
                .clone()
        };
        let first = key_of_b(&merge(&[], &meta));
        let mut other = record(None, Some("zzz"), &[]);
        other.created_at_unix = 3;
        meta.records.insert(0, other);
        assert_eq!(key_of_b(&merge(&[], &meta)), first);
    }

    #[test]
    fn a_restored_self_send_keeps_both_sides() {
        // Restored from seed: the send's change and the receive's output, both unspent.
        let mut rows = Vec::new();
        for (i, c) in ["chg", "recv"].iter().enumerate() {
            let mut e = entry(i as u32, TxLogEntryType::TxReceived);
            e.public_addr = Some(RESTORE_ADDR.into());
            e.confirmed = true;
            rows.push(live(e, &[c], Some(3)));
        }
        let mut meta = Meta::default();
        meta.records.push(record(Some("self"), None, &["chg"]));
        let mut r = record(Some("self"), None, &["recv"]);
        r.kind = "Received".into();
        meta.records.push(r);
        let merged = merge(&rows, &meta);
        let kinds: Vec<TxKind> = merged.iter().map(|m| m.tx.kind).collect();
        assert_eq!(merged.len(), 2, "{kinds:?}");
        assert!(kinds.contains(&TxKind::Sent) && kinds.contains(&TxKind::Received));
    }

    #[test]
    fn self_send_sides_do_not_share_notes() {
        let slate = uuid::Uuid::from_u128(5);
        let mut s = entry(1, TxLogEntryType::TxSent);
        s.tx_slate_id = Some(slate);
        let mut r = entry(2, TxLogEntryType::TxReceived);
        r.tx_slate_id = Some(slate);
        let rows = [live(s, &[], None), live(r, &[], None)];
        let merged = merge(&rows, &Meta::default());
        let send_key = merged
            .iter()
            .find(|m| m.tx.id == Some(1))
            .unwrap()
            .tx
            .key
            .clone();
        let mut meta = Meta::default();
        meta.notes.insert(send_key, "for the send".into());
        let merged = merge(&rows, &meta);
        let note = |i: u32| {
            merged
                .iter()
                .find(|m| m.tx.id == Some(i))
                .unwrap()
                .tx
                .note
                .clone()
        };
        assert_eq!(note(1).as_deref(), Some("for the send"));
        assert_eq!(note(2), None);
        assert!(shared_aliases(&merged).contains(&format!("s:{slate}")));
    }

    fn kernel(b: u8) -> epic_wallet_util::epic_util::secp::pedersen::Commitment {
        epic_wallet_util::epic_util::secp::pedersen::Commitment::from_vec(vec![b; 33])
    }

    #[test]
    fn an_unfinalized_sends_kernel_is_never_shown() {
        let mut waiting = entry(1, TxLogEntryType::TxSentCreated);
        waiting.tx_slate_id = Some(uuid::Uuid::from_u128(1));
        waiting.kernel_excess = Some(kernel(8)); // calc_excess at lock time: not final
        let mut recv = entry(2, TxLogEntryType::TxReceived);
        recv.kernel_excess = Some(kernel(9));
        let mut done = entry(3, TxLogEntryType::TxSent);
        done.confirmed = true;
        done.kernel_excess = Some(kernel(7));
        let merged = merge(
            &[
                live(waiting.clone(), &[], None),
                live(recv, &[], None),
                live(done, &[], None),
            ],
            &Meta::default(),
        );
        let k = |i: u32| {
            merged
                .iter()
                .find(|m| m.tx.id == Some(i))
                .unwrap()
                .tx
                .kernel_excess
                .clone()
        };
        assert_eq!(k(1), None);
        assert!(k(2).is_some() && k(3).is_some());
        assert!(
            to_record(merged.iter().find(|m| m.tx.id == Some(1)).unwrap())
                .kernel_excess
                .is_none()
        );

        // Once finalized, the annotation's final kernel is the one shown.
        let mut meta = Meta::default();
        meta.annotations.insert(
            uuid::Uuid::from_u128(1).to_string(),
            crate::core::meta::Annotation {
                finalized: true,
                kernel_excess: Some("08final".into()),
                finalized_at_unix: Some(1_800_000_000),
                ..Default::default()
            },
        );
        let m = &merge(&[live(waiting, &[], None)], &meta)[0].tx;
        assert_eq!(m.kernel_excess.as_deref(), Some("08final"));
        assert_eq!(m.finalized_at_unix, Some(1_800_000_000));
    }

    #[test]
    fn only_records_awaiting_confirmation_are_settled() {
        let mut r = record(None, Some("kern"), &[]);
        r.status = "AwaitingRecipient".into();
        r.confirmed = false;
        r.kernel_lookup_min_height = Some(100);
        let mut meta = Meta::default();
        meta.records.push(r);
        assert!(!needs_settling(&merge(&[], &meta)[0]));
    }

    #[test]
    fn a_refused_send_becomes_releasable_only_after_a_day_without_its_kernel() {
        let slate = uuid::Uuid::from_u128(4);
        let mut e = entry(1, TxLogEntryType::TxSentCreated);
        e.tx_slate_id = Some(slate);
        let mut l = live(e, &[], None);
        l.finalized = true;
        let ann = |refused: bool, absent: Option<u64>| crate::core::meta::Annotation {
            finalized: true,
            kernel_excess: Some("08k".into()),
            finalized_height: Some(1_000),
            post_error: Some("Unable to parse response for push_transaction: refused".into()),
            post_refused: refused,
            kernel_absent_at: absent,
            ..Default::default()
        };
        let row = |a| {
            let mut meta = Meta::default();
            meta.annotations.insert(slate.to_string(), a);
            merge(&[l.clone()], &meta).remove(0)
        };
        let not_refused = row(ann(false, Some(5_000)));
        assert!(!not_refused.tx.releasable, "only after the node refused it");
        assert_eq!(not_refused.release_check_after, None);
        assert!(not_refused.tx.repostable);
        assert!(not_refused
            .tx
            .status_detail
            .as_deref()
            .unwrap()
            .starts_with("The network has not taken"));

        let fresh = row(ann(true, None));
        assert_eq!(fresh.release_check_after, Some(1_000 + BLOCKS_PER_DAY));
        assert!(!fresh.tx.releasable, "no lookup yet");
        assert!(
            !row(ann(true, Some(1_000 + BLOCKS_PER_DAY - 1)))
                .tx
                .releasable,
            "too soon"
        );
        assert!(row(ann(true, Some(1_000 + BLOCKS_PER_DAY))).tx.releasable);
    }

    #[test]
    fn a_block_time_the_node_lacks_is_cached_but_not_shown() {
        let mut e = entry(1, TxLogEntryType::TxReceived);
        e.confirmed = true;
        let mut meta = Meta::default();
        meta.block_times.insert(5, 0);
        let m = &merge(&[live(e, &["c"], Some(5))], &meta)[0].tx;
        assert_eq!(m.block_time_unix, None);
    }

    /// A wallet with `n` receives and `n` sends (each spending one receive and making change),
    /// the output versions epic-wallet keeps for them, and an archive that annotates every send
    /// and holds an imported record for each.
    pub(crate) fn big_wallet(n: u32) -> (Vec<TxLogEntry>, Vec<OutputData>, Vec<OutputData>, Meta) {
        let mut txs = Vec::new();
        let mut current = Vec::new();
        let mut hist = Vec::new();
        let mut meta = Meta::default();
        for i in 0..n {
            let mut r = entry(i, TxLogEntryType::TxReceived);
            r.tx_slate_id = Some(uuid::Uuid::from_u128(u128::from(i) + 1));
            r.confirmed = true;
            r.amount_credited = 100;
            txs.push(r);
            let send_id = n + i;
            let mut s = entry(send_id, TxLogEntryType::TxSent);
            let slate = uuid::Uuid::from_u128(u128::from(send_id) + 1);
            s.tx_slate_id = Some(slate);
            s.confirmed = true;
            s.amount_debited = 100;
            s.amount_credited = 40;
            s.fee = Some(1);
            s.kernel_excess = Some(kernel((i % 250) as u8));
            txs.push(s);
            let recv_out = format!("r{i}");
            let change = format!("c{i}");
            hist.push(output(i, &recv_out, OutputStatus::Unconfirmed, i, 10));
            hist.push(output(
                i,
                &recv_out,
                OutputStatus::Unspent,
                i,
                100 + u64::from(i),
            ));
            hist.push(output(
                i,
                &recv_out,
                OutputStatus::Locked,
                send_id,
                100 + u64::from(i),
            ));
            current.push(output(
                i,
                &recv_out,
                OutputStatus::Spent,
                send_id,
                100 + u64::from(i),
            ));
            hist.push(output(
                2 * n + i,
                &change,
                OutputStatus::Unconfirmed,
                send_id,
                20,
            ));
            current.push(output(
                2 * n + i,
                &change,
                OutputStatus::Unspent,
                send_id,
                200 + u64::from(i),
            ));
            meta.annotations.insert(
                slate.to_string(),
                crate::core::meta::Annotation {
                    counterparty: Some(format!("es{i:050}@epicbox.epiccash.com")),
                    finalized: true,
                    kernel_excess: Some(format!("08{i:064}")),
                    finalized_at_unix: Some(1_790_000_000 + i64::from(i)),
                    finalized_height: Some(100 + u64::from(i)),
                    ..Default::default()
                },
            );
            let mut rec = record(Some(&slate.to_string()), None, &[&change]);
            rec.note = Some(format!("payment number {i}"));
            meta.records.push(rec);
        }
        for h in 0..500u64 {
            meta.block_times
                .insert(100 + h, 1_790_000_000 + h as i64 * 60);
        }
        (txs, current, hist, meta)
    }

    #[test]
    fn two_thousand_rows_merge_quickly() {
        let (txs, current, hist, meta) = big_wallet(1_000);
        let mut all = current.clone();
        all.extend(hist.iter().cloned());

        // The per-row scan this replaced, for the record: every row walked every output.
        let t = std::time::Instant::now();
        let naive: Vec<(Vec<String>, Option<u64>)> = txs
            .iter()
            .map(|e| {
                let c = created_commits(e, &all);
                let h = confirmed_height(&c, &current);
                (c, h)
            })
            .collect();
        let naive_ms = t.elapsed().as_millis();

        let t = std::time::Instant::now();
        let live = live_rows(txs.clone(), &current, &hist, |_| false);
        let live_ms = t.elapsed().as_millis();
        for (l, (c, h)) in live.iter().zip(&naive) {
            assert_eq!(&l.created_commits, c, "same result as the scan");
            assert_eq!(&l.block_height, h);
        }

        let t = std::time::Instant::now();
        let merged = merge(&live, &meta);
        let merge_ms = t.elapsed().as_millis();
        eprintln!(
            "2000 rows, {} outputs, {} records: old output scan {naive_ms} ms, live_rows {live_ms} ms, merge {merge_ms} ms",
            all.len(),
            meta.records.len()
        );
        assert_eq!(merged.len(), 2_000);
        assert!(merged.iter().filter(|m| m.tx.note.is_some()).count() == 1_000);
        // Debug build, shared CI-class host: generous, but far below a frame budget in release.
        assert!(
            live_ms + merge_ms < 1_000,
            "live {live_ms} ms + merge {merge_ms} ms"
        );
    }

    #[test]
    fn the_archive_of_a_big_wallet_stays_small_and_quick_to_write() {
        let (_, _, _, mut meta) = big_wallet(1_000);
        // 2,000 annotated rows: every send already is; add every receive, and a note on each.
        for i in 0..1_000u32 {
            let slate = uuid::Uuid::from_u128(u128::from(i) + 1).to_string();
            meta.annotations.insert(
                slate.clone(),
                crate::core::meta::Annotation {
                    counterparty: Some(format!("es{i:050}@epicbox.epiccash.com")),
                    ..Default::default()
                },
            );
        }
        for i in 0..2_000u32 {
            meta.notes
                .insert(format!("s:{i}"), format!("note for payment {i}"));
        }
        assert_eq!(meta.annotations.len(), 2_000);
        let pretty = serde_json::to_vec_pretty(&meta).unwrap().len();
        let compact = serde_json::to_vec(&meta).unwrap().len();
        let dir = tempfile::tempdir().unwrap();
        let store = crate::core::meta::MetaStore::open(dir.path().to_str().unwrap()).unwrap();
        let t = std::time::Instant::now();
        store
            .update(|m| {
                *m = meta.clone();
                Ok(())
            })
            .unwrap();
        let first = t.elapsed().as_millis();
        let t = std::time::Instant::now();
        for i in 0..10 {
            store.annotate("listener-event", |a| a.counterparty = Some(format!("x{i}")));
        }
        let ten = t.elapsed().as_millis();
        let on_disk = std::fs::metadata(dir.path().join(crate::core::meta::META_FILE))
            .unwrap()
            .len();
        eprintln!(
            "archive with 2000 annotations, 2000 notes, 1000 records, 500 block times: \
             pretty {pretty} B, compact {compact} B, on disk {on_disk} B; \
             first write {first} ms, 10 listener annotations {ten} ms"
        );
        assert!(on_disk < 2_000_000, "{on_disk} bytes");
        assert!((on_disk as usize) < pretty, "written compact");
    }

    #[test]
    fn notes_follow_any_alias() {
        let mut e = entry(0, TxLogEntryType::TxReceived);
        e.public_addr = Some(RESTORE_ADDR.into());
        let mut meta = Meta::default();
        meta.notes
            .insert("c:c1".into(), "from before the import".into());
        meta.records.push(record(Some("sl"), None, &["c1"]));
        let m = &merge(&[live(e, &["c1"], None)], &meta)[0].tx;
        assert_eq!(m.key, "s:sl");
        assert_eq!(
            m.note.as_deref(),
            Some("from before the import"),
            "note wins over record note"
        );
    }
}
