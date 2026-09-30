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

/// Commitments of the outputs `tx` created, from every stored version of every output
/// (`outputs` = the `o` rows followed by the output history `h` rows).
pub(crate) fn created_commits(tx: &TxLogEntry, outputs: &[OutputData]) -> Vec<String> {
    let send = is_send(&tx.tx_type);
    let set: BTreeSet<String> = outputs
        .iter()
        .filter(|o| o.tx_log_entry == Some(tx.id) && o.root_key_id == tx.parent_key_id)
        .filter(|o| !send || o.status == OutputStatus::Unconfirmed)
        .filter_map(|o| o.commit.clone())
        .collect();
    set.into_iter().collect()
}

/// Block height of the first of `commits` whose current row (`current` = the `o` rows) is on chain.
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
    let kernel_excess = t
        .kernel_excess
        .map(|c| to_hex(c.0.to_vec()))
        .or_else(|| ann.and_then(|a| a.kernel_excess.clone()));
    let restored = t.public_addr.as_deref() == Some(RESTORE_ADDR);
    let counterparty = ann
        .and_then(|a| some_str(&a.counterparty))
        .or_else(|| some_str(&t.public_addr).filter(|a| a != RESTORE_ADDR));
    let block_height = live.block_height.or_else(|| {
        if t.confirmed {
            kernel_excess
                .as_ref()
                .and_then(|k| meta.kernel_heights.get(k).copied())
                .filter(|h| *h > 0)
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
        status_detail: None,
    };
    MergedTx {
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
    };
    MergedTx {
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

/// Indices of live rows matching `r`: by slate id, then kernel, then created commitment.
fn matches(r: &Record, rows: &[MergedTx], hidden: &[bool]) -> Vec<usize> {
    let eq =
        |a: &Option<String>, b: &Option<String>| matches!((a, b), (Some(x), Some(y)) if x == y);
    let mut out = Vec::new();
    let push = |i: usize, out: &mut Vec<usize>| {
        if !hidden[i] && !out.contains(&i) {
            out.push(i);
        }
    };
    for (i, m) in rows.iter().enumerate() {
        if eq(&m.tx.slate_id, &r.slate_id) {
            push(i, &mut out);
        }
    }
    for (i, m) in rows.iter().enumerate() {
        if eq(&m.tx.kernel_excess, &r.kernel_excess) {
            push(i, &mut out);
        }
    }
    for (i, m) in rows.iter().enumerate() {
        if m.tx
            .output_commits
            .iter()
            .any(|c| r.output_commits.contains(c))
        {
            push(i, &mut out);
        }
    }
    out
}

/// Merges live rows and the archive into the list the UI shows, newest first.
pub(crate) fn merge(live: &[LiveTx], meta: &Meta) -> Vec<MergedTx> {
    let mut rows: Vec<MergedTx> = live.iter().map(|l| from_live(l, meta)).collect();
    let mut hidden = vec![false; rows.len()];
    let mut record_notes: HashMap<usize, String> = HashMap::new();
    let mut imported: Vec<(MergedTx, Option<String>)> = Vec::new();

    for r in &meta.records {
        let found = matches(r, &rows, &hidden);
        if found.is_empty() {
            imported.push((from_record(r), some_str(&r.note)));
            continue;
        }
        // Prefer a row the wallet made itself over one a scan rebuilt.
        let primary = found
            .iter()
            .copied()
            .find(|i| rows[*i].tx.source != TxSource::Restored)
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
    for (mut m, record_note) in out {
        let tx = &mut m.tx;
        let mut key = base_key(&tx.slate_id, &tx.kernel_excess, &tx.output_commits, tx.id);
        if !used.insert(key.clone()) {
            // Both sides of a self-send share a slate id.
            key = match tx.id {
                Some(i) => format!("{key}#l{i}"),
                None => format!("{key}#{}", used.len()),
            };
            used.insert(key.clone());
        }
        tx.key = key;
        if tx.block_time_unix.is_none() {
            tx.block_time_unix = tx
                .block_height
                .and_then(|h| meta.block_times.get(&h).copied());
        }
        tx.time_unix = match tx.source {
            TxSource::Restored => tx.block_time_unix.unwrap_or(tx.created_at_unix),
            _ => tx.created_at_unix,
        };
        m.aliases = aliases_of(tx);
        tx.note = m
            .aliases
            .iter()
            .find_map(|a| meta.notes.get(a).cloned())
            .or(record_note);
        result.push(m);
    }
    result.sort_by(|a, b| {
        b.tx.time_unix
            .cmp(&a.tx.time_unix)
            .then_with(|| b.tx.id.cmp(&a.tx.id))
    });
    result
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
        && matches!(
            m.tx.status,
            TxStatus::AwaitingRecipient | TxStatus::AwaitingConfirmation
        )
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
                "Never completed: its kernel was not on chain by block {tip}"
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
