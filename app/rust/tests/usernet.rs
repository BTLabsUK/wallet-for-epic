//! End to end on the local usernet stable network (`/opt/epic/stable-network`, see
//! its README). `#[ignore]`, so plain `cargo test` stays offline.
//! Run with `cargo test --test usernet -- --ignored`.
//!
//! Two fresh wallets made by this crate, A and B. alice (the funded network wallet, driven through the
//! network's own `bin/epic-wallet`) pays A with a file slate; then A pays B entirely through our API;
//! then a send from A is cancelled and its outputs come back; then a send finalized while the node
//! was unreachable is reposted and confirms; then a restore of A's seed rescans the
//! chain and finds the same balance, and importing A's history file brings back an HTTP payment to
//! alice with its fee, counterparty, note and time.
//!
//! Network hygiene: `burn_reward` stays as the network has it (on), so mining confirms transactions
//! without crediting anyone. The miner is started for the test and stopped by a guard; the node is
//! started only if it was not already running, and then stopped again. Seeds are never printed.

mod common;

use std::fs::{self, File};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::time::{Duration, Instant};

use common::*;
use epic_wallet_core::api::types::SlateStage;
use epic_wallet_core::api::types::{
    Chain, Contact, ListenerEventKind, TxKind, TxSource, TxStatus, WalletConfig, WalletErrorKind,
};
use epic_wallet_core::api::wallet::{inspect_slate, node_tip, EpicWallet};

const NODE_URL: &str = "http://127.0.0.1:23413";
const MIN_CONF: u64 = 3;
const LOG_DIR: &str = "/tmp/epic-build/wfe-app-logs";

fn net_root() -> PathBuf {
    std::env::var_os("EPIC_STABLE_NET")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("/opt/epic/stable-network"))
}

/// Runs `script` in bash inside the network directory with `env.sh` sourced, output to a log file
/// (never a pipe: net.sh leaves daemons holding inherited descriptors). Returns the log text.
fn net_shell(step: &str, script: &str, timeout_secs: u64) -> String {
    let log = PathBuf::from(LOG_DIR).join(format!("rustcore-usernet-{step}.log"));
    fs::create_dir_all(LOG_DIR).expect("log dir");
    let out = File::create(&log).expect("log file");
    let err = out.try_clone().expect("log file");
    let status = Command::new("timeout")
        .arg(timeout_secs.to_string())
        .arg("bash")
        .arg("-c")
        .arg(format!(". ./env.sh && {script}"))
        .current_dir(net_root())
        .stdin(Stdio::null())
        .stdout(out)
        .stderr(err)
        .status()
        .expect("spawn bash");
    let text = fs::read_to_string(&log).unwrap_or_default();
    assert!(status.success(), "`{step}` failed, see {}", log.display());
    text
}

fn node_config() -> WalletConfig {
    config(Path::new("/nonexistent"), Chain::Usernet, NODE_URL)
}

fn height() -> u64 {
    node_tip(node_config()).expect("node tip").height
}

fn kill_pidfile(name: &str) {
    let pidfile = net_root().join("var/run").join(format!("{name}.pid"));
    if let Ok(pid) = fs::read_to_string(&pidfile) {
        let _ = Command::new("kill")
            .arg(pid.trim())
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();
        let _ = fs::remove_file(pidfile);
    }
}

/// Starts what the test needs and stops, on drop, whatever it started.
struct Network {
    started_node: bool,
    miner_running: bool,
}

impl Network {
    fn up() -> Network {
        let started_node = node_tip(node_config()).is_err();
        if started_node {
            net_shell("node", "bash net.sh node", 150);
        }
        Network {
            started_node,
            miner_running: false,
        }
    }

    /// Mines until `done()` holds, polling every two seconds, for at most `limit`.
    fn mine_until(&mut self, what: &str, limit: Duration, mut done: impl FnMut() -> bool) {
        if !self.miner_running {
            net_shell("miner", "bash net.sh miner", 60);
            self.miner_running = true;
        }
        let start = Instant::now();
        while !done() {
            assert!(
                start.elapsed() < limit,
                "gave up after {:?} waiting for {what} (height {})",
                limit,
                height()
            );
            std::thread::sleep(Duration::from_secs(2));
        }
        eprintln!(
            "{what}: reached at height {} after {:?}",
            height(),
            start.elapsed()
        );
    }

    fn stop_miner(&mut self) {
        if self.miner_running {
            kill_pidfile("miner");
            self.miner_running = false;
        }
    }
}

impl Drop for Network {
    fn drop(&mut self) {
        self.stop_miner();
        if self.started_node {
            kill_pidfile("node");
        }
    }
}

fn spendable(w: &EpicWallet) -> u64 {
    w.summary(true, MIN_CONF).expect("summary").spendable
}

#[test]
#[ignore = "needs the local usernet stable network"]
fn usernet_end_to_end() {
    init_logging();
    let mut net = Network::up();
    let dirs = tempfile::tempdir().expect("tempdir");
    let dir_a = dirs.path().join("a");
    let dir_b = dirs.path().join("b");
    let dir_c = dirs.path().join("c");
    let slates = dirs.path().join("slates");
    fs::create_dir_all(&slates).expect("slates dir");

    let mut a = EpicWallet::create(
        config(&dir_a, Chain::Usernet, NODE_URL),
        None,
        PASSWORD.into(),
    )
    .expect("create A");
    let b = EpicWallet::create(
        config(&dir_b, Chain::Usernet, NODE_URL),
        None,
        PASSWORD.into(),
    )
    .expect("create B");
    let start = a.summary(true, MIN_CONF).expect("summary A");
    assert!(start.validated_with_node, "usernet node reports no_sync");
    assert_eq!(start.total, 0);

    // 1. alice -> A with the CLI's file-slate flow.
    let fund_file = slates.join("fund.tx");
    net_shell(
        "alice-send",
        &format!(
            "w alice send -m file -d {} -c \"$MIN_CONF\" 10",
            fund_file.display()
        ),
        300,
    );
    let request = fs::read_to_string(&fund_file).expect("alice's slate");
    let response = a.receive_slate(request).expect("A receives alice's slate");
    let response_file = slates.join("fund.tx.response");
    fs::write(&response_file, &response.json).expect("write response");
    net_shell(
        "alice-finalize",
        &format!("w alice finalize -f -i {}", response_file.display()),
        300,
    );
    net.mine_until("A's 10 EPIC spendable", Duration::from_secs(600), || {
        spendable(&a) == 10 * EPIC
    });
    let received = a.transactions(true).expect("A txs");
    assert_eq!(received.len(), 1);
    assert_eq!(received[0].kind, TxKind::Received);
    assert!(received[0].confirmed);
    assert_eq!(received[0].amount_credited, 10 * EPIC);
    assert_eq!(
        received[0].slate_id.as_deref(),
        Some(response.slate_id.as_str())
    );

    // 2. A -> B entirely through our API.
    let amount = 2 * EPIC;
    let estimate = a.estimate_fee(amount, MIN_CONF).expect("estimate");
    assert_eq!(estimate.amount, amount);
    assert!(estimate.fee > 0);
    assert_eq!(
        kind_of(a.create_send_slate(1_000 * EPIC, MIN_CONF)),
        WalletErrorKind::NotEnoughFunds
    );
    let send = a
        .create_send_slate(amount, MIN_CONF)
        .expect("A creates slate");
    let locked = a.summary(false, MIN_CONF).expect("summary");
    assert_eq!(locked.locked, 10 * EPIC, "A's only output is locked");
    assert_eq!(locked.spendable, 0);
    let info = inspect_slate(send.json.clone()).expect("inspect send");
    assert_eq!(info.stage, SlateStage::Send);
    assert_eq!(info.amount, amount);
    assert_eq!(info.slate_id, send.slate_id);
    let reply = b.receive_slate(send.json.clone()).expect("B receives");
    assert_eq!(reply.slate_id, send.slate_id);
    assert_eq!(
        inspect_slate(reply.json.clone())
            .expect("inspect reply")
            .stage,
        SlateStage::Response
    );
    assert_eq!(
        kind_of(b.receive_slate(send.json)),
        WalletErrorKind::InvalidSlate,
        "a slate is received once"
    );
    let sent = a
        .finalize_and_post(reply.json)
        .expect("A finalizes and posts");
    assert_eq!(sent.kind, TxKind::Sent);
    assert_eq!(sent.slate_id.as_deref(), Some(send.slate_id.as_str()));
    let fee = sent.fee.expect("fee recorded");
    assert_eq!(fee, estimate.fee);

    net.mine_until("B's 2 EPIC spendable", Duration::from_secs(600), || {
        spendable(&b) == amount && spendable(&a) == 10 * EPIC - amount - fee
    });
    let sa = a.summary(true, MIN_CONF).expect("summary A");
    let sb = b.summary(true, MIN_CONF).expect("summary B");
    assert_eq!(sa.total, 10 * EPIC - amount - fee);
    assert_eq!(sa.locked, 0);
    assert_eq!(sb.total, amount);
    let a_txs = a.transactions(true).expect("A txs");
    assert_eq!(a_txs.len(), 2);
    assert_eq!(a_txs[0].kind, TxKind::Sent, "newest first");
    assert!(a_txs[0].confirmed);
    assert_eq!(
        a_txs[0].amount_debited - a_txs[0].amount_credited,
        amount + fee
    );
    let b_txs = b.transactions(true).expect("B txs");
    assert_eq!(b_txs.len(), 1);
    assert_eq!(b_txs[0].kind, TxKind::Received);
    assert!(b_txs[0].confirmed);
    assert_eq!(b_txs[0].amount_credited, amount);
    assert!(b_txs[0].kernel_excess.is_some());

    // 3. Cancel returns the locked outputs.
    let before = a.summary(true, MIN_CONF).expect("summary");
    let pending = a.create_send_slate(EPIC, MIN_CONF).expect("second slate");
    assert!(a.summary(false, MIN_CONF).expect("summary").locked > 0);
    let entry = a
        .transactions(false)
        .expect("txs")
        .into_iter()
        .find(|t| t.slate_id.as_deref() == Some(pending.slate_id.as_str()))
        .expect("log entry for the pending slate");
    a.cancel_transaction(entry.id.expect("live row"))
        .expect("cancel");
    let after = a.summary(true, MIN_CONF).expect("summary");
    assert_eq!(after.locked, 0);
    assert_eq!(after.spendable, before.spendable);
    let cancelled = a
        .transactions(false)
        .expect("txs")
        .into_iter()
        .find(|t| t.id == entry.id)
        .expect("cancelled entry");
    assert_eq!(cancelled.kind, TxKind::SentCancelled);
    assert_eq!(
        kind_of(a.cancel_transaction(entry.id.expect("live row") + 100)),
        WalletErrorKind::InvalidArgument
    );

    // 3a. A finalized send whose post failed: it is repostable, not cancellable, and a repost
    // gets it on chain. A opens once against a dead node to finalize without posting.
    // A send with a TTL is not finished while the chain height cannot be read: the answer is
    // left for a later try, and the send still waits for its recipient.
    let guarded = a
        .create_send_slate(EPIC / 2, MIN_CONF)
        .expect("slate with a TTL");
    let guarded_reply = b.receive_slate(guarded.json).expect("B answers");
    drop(a);
    let offline = EpicWallet::open(config(&dir_a, Chain::Usernet, DEAD_NODE), PASSWORD.into())
        .expect("open A offline again");
    assert_eq!(
        kind_of(offline.finalize_and_post(guarded_reply.json)),
        WalletErrorKind::NodeUnreachable,
        "no chain height, no finalize"
    );
    let waiting = offline
        .transactions(false)
        .expect("txs")
        .into_iter()
        .find(|t| t.slate_id.as_deref() == Some(guarded.slate_id.as_str()))
        .expect("the guarded send");
    assert_eq!(waiting.status, TxStatus::AwaitingRecipient, "not finalized");
    drop(offline);
    a = EpicWallet::open(config(&dir_a, Chain::Usernet, NODE_URL), PASSWORD.into())
        .expect("reopen A");
    a.cancel_transaction(waiting.id.expect("live"))
        .expect("cancel the guarded send");

    // Without a TTL: a send with one is never finalized while the chain height cannot be read
    // (3d), so an offline finalize is only possible for sends made before TTLs existed.
    a.set_send_ttl_blocks_for_tests(0);
    let stuck = a.create_send_slate(EPIC, MIN_CONF).expect("third slate");
    a.set_send_ttl_blocks_for_tests(20_160);
    let stuck_reply = b.receive_slate(stuck.json).expect("B receives");
    drop(a);
    let offline = EpicWallet::open(config(&dir_a, Chain::Usernet, DEAD_NODE), PASSWORD.into())
        .expect("open A offline");
    // The post fails, but the payment is finished: a result, not an error, so nobody sends again.
    let finished = offline
        .finalize_and_post(stuck_reply.json)
        .expect("a finished payment is a result even when the post fails");
    assert!(finished.repostable);
    assert!(!finished.cancellable);
    assert!(
        finished
            .status_detail
            .as_deref()
            .is_some_and(|d| d.starts_with("The network has not taken this payment yet")),
        "{:?}",
        finished.status_detail
    );
    assert!(finished.finalized_at_unix.is_some());
    assert!(finished.kernel_excess.is_some(), "the final kernel");
    drop(offline);
    a = EpicWallet::open(config(&dir_a, Chain::Usernet, NODE_URL), PASSWORD.into())
        .expect("reopen A");
    let stuck_row = a
        .transactions(false)
        .expect("txs")
        .into_iter()
        .find(|t| t.slate_id.as_deref() == Some(stuck.slate_id.as_str()))
        .expect("the stuck send");
    assert_eq!(stuck_row.status, TxStatus::AwaitingConfirmation);
    assert!(stuck_row.repostable);
    assert!(!stuck_row.cancellable);
    assert!(
        !stuck_row.releasable,
        "the node never refused it, it was only unreachable"
    );
    a.repost_transaction(stuck_row.key.clone()).expect("repost");
    net.mine_until(
        "the reposted send confirmed",
        Duration::from_secs(600),
        || spendable(&b) == amount + EPIC,
    );
    let settled = a
        .transactions(true)
        .expect("txs")
        .into_iter()
        .find(|t| t.key == stuck_row.key)
        .expect("same key");
    assert_eq!(settled.status, TxStatus::Confirmed);
    assert!(!settled.repostable);
    assert_eq!(
        settled.status_detail, None,
        "the repost cleared the post error"
    );
    assert_eq!(
        kind_of(a.repost_transaction(settled.key)),
        WalletErrorKind::InvalidArgument
    );

    // 3c. Every send has a TTL (20160 blocks). Past it, a refresh cancels the send and unlocks
    // its funds, and a late answer is refused. A 3-block TTL here, through the test hook.
    assert_eq!(stuck_row.ttl_cutoff_height, None, "made without a TTL");
    let with_ttl = a
        .create_send_slate(EPIC, MIN_CONF)
        .expect("slate with the default TTL");
    let ttl_row = a
        .transactions(false)
        .expect("txs")
        .into_iter()
        .find(|t| t.slate_id.as_deref() == Some(with_ttl.slate_id.as_str()))
        .expect("the new send");
    assert!(
        ttl_row
            .ttl_cutoff_height
            .is_some_and(|c| c >= height() + 20_000),
        "sends carry the 14-day TTL: {:?}",
        ttl_row.ttl_cutoff_height
    );
    a.cancel_transaction(ttl_row.id.expect("live"))
        .expect("cancel it again");
    a.set_send_ttl_blocks_for_tests(3);
    let before_ttl = a.summary(true, MIN_CONF).expect("summary");
    let short = a
        .create_send_slate(EPIC, MIN_CONF)
        .expect("short-lived slate");
    a.set_send_ttl_blocks_for_tests(20_160);
    assert!(a.summary(false, MIN_CONF).expect("summary").locked > 0);
    let cutoff = height() + 3;
    net.mine_until("past the short TTL", Duration::from_secs(300), || {
        height() > cutoff + 1
    });
    b.summary(true, MIN_CONF).expect("B refresh");
    assert_eq!(
        kind_of(b.receive_slate(short.json)),
        WalletErrorKind::InvalidSlate,
        "an expired payment is refused"
    );
    let after_ttl = a.summary(true, MIN_CONF).expect("summary");
    assert_eq!(
        after_ttl.locked, 0,
        "the refresh cancelled it and unlocked the funds"
    );
    assert_eq!(after_ttl.spendable, before_ttl.spendable);
    let expired = a
        .transactions(false)
        .expect("txs")
        .into_iter()
        .find(|t| t.slate_id.as_deref() == Some(short.slate_id.as_str()))
        .expect("the expired send");
    assert_eq!(expired.status, TxStatus::Cancelled);
    assert_eq!(expired.kind, TxKind::SentCancelled);

    // 3d. An answer at or near the TTL cutoff is not finalized: the send is cancelled instead,
    // so a refresh can never cancel a payment the network is about to confirm. A 3-block TTL
    // is inside the 60-block margin at once.
    a.set_send_ttl_blocks_for_tests(3);
    let late = a.create_send_slate(EPIC, MIN_CONF).expect("slate");
    a.set_send_ttl_blocks_for_tests(20_160);
    let late_reply = b.receive_slate(late.json).expect("B answers in time for B");
    let e = a
        .finalize_and_post(late_reply.json)
        .err()
        .expect("a late answer is refused");
    assert_eq!(e.kind, WalletErrorKind::PaymentExpired, "{}", e.message);
    assert!(e.message.contains("nothing was sent"), "{}", e.message);
    let after_late = a.summary(true, MIN_CONF).expect("summary");
    assert_eq!(after_late.locked, 0, "its funds are unlocked");
    let late_row = a
        .transactions(false)
        .expect("txs")
        .into_iter()
        .find(|t| t.slate_id.as_deref() == Some(late.slate_id.as_str()))
        .expect("the late send");
    assert_eq!(late_row.status, TxStatus::Cancelled);
    assert_eq!(late_row.finalized_at_unix, None, "never finalized");

    // 3b. A pays alice over HTTP with a note and a contact: the history a restore must bring back.
    let alice_url = "http://127.0.0.1:23415";
    let started_listener = std::net::TcpStream::connect(("127.0.0.1", 23415)).is_err();
    if started_listener {
        net_shell("listener", "bash net.sh listener", 120);
    }
    let before_paid = a.summary(true, MIN_CONF).expect("summary").spendable;
    let paid = a.send_http(EPIC, MIN_CONF, alice_url.into());
    if started_listener {
        kill_pidfile("listener");
    }
    let paid = paid.expect("A pays alice over HTTP");
    assert_eq!(paid.counterparty.as_deref(), Some(alice_url));
    assert_eq!(
        paid.status,
        TxStatus::AwaitingConfirmation,
        "finalized and posted"
    );
    assert!(!paid.cancellable);
    let paid_fee = paid.fee.expect("fee");
    a.set_tx_note(paid.key.clone(), Some("coffee for alice".into()))
        .expect("note");
    a.save_contact(Contact {
        id: String::new(),
        name: "alice".into(),
        address: alice_url.into(),
        note: None,
    })
    .expect("contact");
    net.mine_until(
        "the HTTP payment confirmed",
        Duration::from_secs(600),
        || spendable(&a) == before_paid - EPIC - paid_fee,
    );
    a.transactions(true).expect("refresh");
    assert!(
        a.enrich_history().expect("enrich") >= 1,
        "block times arrive"
    );
    assert_eq!(
        a.enrich_history().expect("enrich again"),
        0,
        "nothing left to fetch"
    );
    let paid_row = a
        .transactions(false)
        .expect("txs")
        .into_iter()
        .find(|t| t.key == paid.key)
        .expect("the payment keeps its key");
    assert_eq!(paid_row.status, TxStatus::Confirmed);
    assert_eq!(paid_row.note.as_deref(), Some("coffee for alice"));
    assert!(
        paid_row.block_height.is_some(),
        "height from the change output"
    );
    assert!(
        paid_row.block_time_unix.is_some(),
        "block time from get_header"
    );
    assert_eq!(paid_row.output_commits.len(), 1, "the change output");
    let sa = a.summary(true, MIN_CONF).expect("summary A");
    let history = a.export_history().expect("export");
    net.stop_miner();

    // 4. Scan streams progress and ends with `finished`; a restore finds the same balance.
    // A rescan from height 1 keeps notes, contacts and annotations, and adds no rows.
    let sig = |txs: &[epic_wallet_core::api::types::TxEntry]| {
        let mut v: Vec<(String, Option<String>, Option<String>, bool)> = txs
            .iter()
            .map(|t| {
                (
                    t.key.clone(),
                    t.note.clone(),
                    t.counterparty.clone(),
                    t.confirmed,
                )
            })
            .collect();
        v.sort();
        v
    };
    let before_scan = sig(&a.transactions(false).expect("txs"));
    let contacts_before = a.contacts().expect("contacts").len();
    let mut events = Vec::new();
    a.scan_with(Some(1), |p| events.push(p)).expect("scan A");
    assert_eq!(
        sig(&a.transactions(false).expect("txs")),
        before_scan,
        "same rows, notes and counterparties after a rescan"
    );
    assert_eq!(a.contacts().expect("contacts").len(), contacts_before);
    assert!(
        before_scan.iter().any(|(_, n, _, _)| n.is_some()),
        "a note was there to keep"
    );
    assert!(events.len() >= 2, "progress plus the final event");
    let last = events.last().expect("final event");
    assert!(last.finished);
    assert!(events[..events.len() - 1].iter().all(|p| !p.finished));
    assert!(events.iter().any(|p| p.percent.is_some()));
    assert_eq!(a.summary(false, MIN_CONF).expect("summary").total, sa.total);

    let phrase = a.mnemonic(PASSWORD.into()).expect("A's phrase");
    let c = EpicWallet::create(
        config(&dir_c, Chain::Usernet, NODE_URL),
        Some(phrase),
        PASSWORD.into(),
    )
    .expect("restore A as C");
    let mut c_events = 0usize;
    c.scan_with(None, |_| c_events += 1).expect("scan C");
    assert!(c_events >= 1);
    let sc = c.summary(false, MIN_CONF).expect("summary C");
    assert_eq!(sc.total, sa.total, "restore finds A's outputs");
    assert_eq!(
        c.epicbox_address().expect("addr"),
        a.epicbox_address().expect("addr")
    );

    // 5. The restore knows only its unspent output; the history file brings the rest back.
    let restored = c.transactions(true).expect("C txs");
    assert_eq!(
        restored.len(),
        1,
        "one unspent output: the payment's change"
    );
    assert_eq!(restored[0].source, TxSource::Restored);
    assert_eq!(restored[0].counterparty, None);
    assert_eq!(restored[0].output_commits, paid_row.output_commits);
    assert_eq!(restored[0].block_height, paid_row.block_height);
    let report = c.import_history(history.clone()).expect("import");
    assert_eq!(report.merged, 1, "the payment matched its restored change");
    assert!(
        report.added >= 3,
        "alice's funding, the send to B, the cancelled send"
    );
    assert_eq!(report.contacts_added, 1);
    let again = c.import_history(history).expect("import again");
    assert_eq!((again.merged, again.added, again.contacts_added), (0, 0, 0));
    let c_txs = c.transactions(true).expect("C txs");
    let back = c_txs
        .iter()
        .find(|t| t.slate_id == paid.slate_id)
        .expect("the HTTP payment is back");
    assert_eq!(back.key, paid.key);
    assert_eq!(back.kind, TxKind::Sent);
    assert_eq!(back.source, TxSource::Imported);
    assert_eq!(back.status, TxStatus::Confirmed);
    assert_eq!(back.fee, Some(paid_fee));
    assert_eq!(back.counterparty.as_deref(), Some(alice_url));
    assert_eq!(back.note.as_deref(), Some("coffee for alice"));
    assert_eq!(back.created_at_unix, paid.created_at_unix);
    assert_eq!(back.time_unix, paid.created_at_unix);
    assert_eq!(back.amount_debited - back.amount_credited, EPIC + paid_fee);
    assert!(
        back.id.is_some(),
        "still the live restored row, now with details"
    );
    assert_eq!(
        c_txs
            .iter()
            .filter(|t| t.source == TxSource::Restored)
            .count(),
        0,
        "no leftover 'Received' row for the change"
    );
    assert!(c_txs
        .iter()
        .any(|t| t.slate_id.as_deref() == Some(send.slate_id.as_str())));
    let contacts = c.contacts().expect("contacts");
    assert_eq!(contacts.len(), 1);
    assert_eq!(contacts[0].address, alice_url);
    let csv = c.export_history_csv().expect("csv");
    assert!(csv.contains("coffee for alice"));
    assert!(
        csv.contains(",Sent,Completed,") || csv.contains(",Sent,Confirming "),
        "status words as the app shows them"
    );

    // 6. A later export with a new note merges into the records imported before.
    let to_b = a
        .transactions(false)
        .expect("A txs")
        .into_iter()
        .find(|t| t.slate_id.as_deref() == Some(send.slate_id.as_str()))
        .expect("the first send to B");
    a.set_tx_note(to_b.key.clone(), Some("first payment to B".into()))
        .expect("note");
    std::thread::sleep(Duration::from_millis(1100)); // a newer `exported_at_unix`
    let newer = c
        .import_history(a.export_history().expect("export again"))
        .expect("import the newer file");
    assert!(newer.merged >= 1, "the new note merged: {newer:?}");
    assert_eq!(newer.added, 0);
    let noted = c
        .transactions(false)
        .expect("C txs")
        .into_iter()
        .find(|t| t.key == to_b.key)
        .expect("the send to B, from the backup");
    assert_eq!(noted.note.as_deref(), Some("first payment to B"));
}

/// Blocks a refresh scans below the tip (`core/session.rs`, `REFRESH_SCAN_BACK`).
const SCAN_BACK: u64 = 100;
/// Blocks mined while a wallet is closed: more than `SCAN_BACK`, so the payment's block lies
/// outside what the reopened wallet's refresh scans.
const CLOSED_BLOCKS: u64 = 150;

/// Mines `CLOSED_BLOCKS` past `from` and stops the miner. Returns the time it took.
fn mine_while_closed(net: &mut Network, what: &str, from: u64) -> Duration {
    let t = Instant::now();
    net.mine_until(what, Duration::from_secs(1200), || {
        height() >= from + CLOSED_BLOCKS
    });
    net.stop_miner();
    t.elapsed()
}

/// A payment cannot reach a closed wallet: the wallet signs the slate first, and whatever it
/// signs or creates is in epic.db as unconfirmed. So a refresh after days confirms it by
/// commitment (step 1), even though it scans only the last 100 blocks and the payment's block is
/// older. Two cases, each with the wallet closed for 150 blocks and then one `summary(true)`:
/// A receives from alice (A signs, closes, alice finalizes and posts), and A sends to B (A
/// finalizes and posts, closes); A's change and B's output confirm.
#[test]
#[ignore = "needs the local usernet stable network"]
fn payments_made_before_closing_confirm_after_150_blocks() {
    init_logging();
    let started = Instant::now();
    let mut net = Network::up();
    let dirs = tempfile::tempdir().expect("tempdir");
    let cfg_a = config(&dirs.path().join("a"), Chain::Usernet, NODE_URL);
    let cfg_b = config(&dirs.path().join("b"), Chain::Usernet, NODE_URL);
    let slates = dirs.path().join("slates");
    fs::create_dir_all(&slates).expect("slates dir");

    let a = EpicWallet::create(cfg_a.clone(), None, PASSWORD.into()).expect("create A");
    let b = EpicWallet::create(cfg_b.clone(), None, PASSWORD.into()).expect("create B");
    let a_seen = a.summary(true, MIN_CONF).expect("summary A");
    assert!(a_seen.validated_with_node, "usernet node reports no_sync");
    b.summary(true, MIN_CONF).expect("summary B");
    let b_seen = height();

    // 1. alice -> A. A signs, then closes before alice finalizes and posts.
    let fund_file = slates.join("fund.tx");
    net_shell(
        "closed-alice-send",
        &format!(
            "w alice send -m file -d {} -c \"$MIN_CONF\" 10",
            fund_file.display()
        ),
        300,
    );
    let request = fs::read_to_string(&fund_file).expect("alice's slate");
    let response = a.receive_slate(request).expect("A receives alice's slate");
    drop(a);
    let response_file = slates.join("fund.tx.response");
    fs::write(&response_file, &response.json).expect("write response");
    net_shell(
        "closed-alice-finalize",
        &format!("w alice finalize -f -i {}", response_file.display()),
        300,
    );
    let posted = height();
    let mined = mine_while_closed(&mut net, "150 blocks with A closed", posted);

    let a = EpicWallet::open(cfg_a.clone(), PASSWORD.into()).expect("reopen A");
    let tip = height();
    assert!(
        tip > a_seen.last_confirmed_height + SCAN_BACK,
        "A's last refresh ({}) is out of scan range of tip {tip}",
        a_seen.last_confirmed_height
    );
    let t = Instant::now();
    let s = a.summary(true, MIN_CONF).expect("one refresh of A");
    let refresh_receive = t.elapsed();
    assert!(s.validated_with_node);
    assert!(s.last_confirmed_height >= tip);
    assert_eq!(s.spendable, 10 * EPIC, "the payment is spendable");
    assert_eq!(s.total, 10 * EPIC);
    assert_eq!(s.awaiting_confirmation, 0);
    let rows = a.transactions(false).expect("A txs, no refresh");
    let row = rows
        .iter()
        .find(|t| t.slate_id.as_deref() == Some(response.slate_id.as_str()))
        .expect("A's receive row");
    assert_eq!(row.kind, TxKind::Received);
    assert!(row.confirmed, "the receive row is confirmed");
    assert_eq!(row.status, TxStatus::Confirmed);
    assert_eq!(row.amount_credited, 10 * EPIC);
    let at = row.block_height.expect("the receive's block height");
    assert!(
        at > posted && at <= posted + 10,
        "mined right after the post at {posted}, found at {at}"
    );
    assert!(
        at + SCAN_BACK < tip,
        "block {at} is outside the refresh's scan from {}",
        tip - SCAN_BACK
    );
    eprintln!(
        "receive: posted at {posted}, in block {at}, A reopened at {tip}; mining {mined:?}, \
         one refresh {refresh_receive:?}"
    );

    // 2. A -> B. A finalizes and posts, then A and B close.
    let amount = 2 * EPIC;
    let send = a.create_send_slate(amount, MIN_CONF).expect("A's slate");
    let reply = b.receive_slate(send.json).expect("B receives");
    drop(b);
    let sent = a
        .finalize_and_post(reply.json)
        .expect("A finalizes and posts");
    let fee = sent.fee.expect("fee");
    let a_seen = a.summary(false, MIN_CONF).expect("local summary");
    assert_eq!(
        a_seen.locked,
        10 * EPIC,
        "A's input is locked until it confirms"
    );
    drop(a);
    let posted = height();
    let mined = mine_while_closed(&mut net, "150 blocks with A and B closed", posted);

    let a = EpicWallet::open(cfg_a, PASSWORD.into()).expect("reopen A");
    let tip = height();
    let t = Instant::now();
    let s = a.summary(true, MIN_CONF).expect("one refresh of A");
    let refresh_send = t.elapsed();
    assert!(s.validated_with_node);
    let change = 10 * EPIC - amount - fee;
    assert_eq!(s.spendable, change, "the change is spendable");
    assert_eq!(s.total, change);
    assert_eq!(s.locked, 0, "the spent input is no longer locked");
    assert_eq!(s.awaiting_confirmation, 0);
    let row = a
        .transactions(false)
        .expect("A txs, no refresh")
        .into_iter()
        .find(|t| t.slate_id.as_deref() == Some(send.slate_id.as_str()) && t.kind == TxKind::Sent)
        .expect("A's send row");
    assert!(row.confirmed, "the send row is confirmed");
    assert_eq!(row.status, TxStatus::Confirmed);
    assert_eq!(row.amount_debited - row.amount_credited, amount + fee);
    let at = row.block_height.expect("the send's block height");
    assert!(
        at > posted && at <= posted + 10,
        "mined right after the post at {posted}, found at {at}"
    );
    assert!(at + SCAN_BACK < tip);

    let b = EpicWallet::open(cfg_b, PASSWORD.into()).expect("reopen B");
    assert!(tip > b_seen + SCAN_BACK + CLOSED_BLOCKS);
    let t = Instant::now();
    let sb = b.summary(true, MIN_CONF).expect("one refresh of B");
    let refresh_b = t.elapsed();
    assert_eq!(sb.spendable, amount, "B's payment is spendable");
    let b_row = b
        .transactions(false)
        .expect("B txs")
        .into_iter()
        .find(|t| t.slate_id.as_deref() == Some(send.slate_id.as_str()))
        .expect("B's receive row");
    assert!(b_row.confirmed);
    assert_eq!(
        b_row.block_height,
        Some(at),
        "B's output is in the same block"
    );
    eprintln!(
        "send: posted at {posted}, in block {at}, reopened at {tip}; mining {mined:?}, one \
         refresh A {refresh_send:?}, B {refresh_b:?}; whole test {:?}",
        started.elapsed()
    );
}

/// A stock epic-wallet 4.0.0 CLI, the upstream release, used as an epicbox sender.
const STOCK_CLI: &str = "/opt/epic/user-env/bin/epic-wallet";
const CLI_PASS: &str = "stock-cli-usernet";
/// The local relay: `/opt/epic/epic-relay`, run as its README documents, epicbox protocol 3.0.0.
const RELAY_HOST: &str = "127.0.0.1";
const RELAY_PORT: u16 = 3423;

/// A throwaway stock CLI wallet on usernet whose epicbox is the local relay.
struct StockCli {
    dir: tempfile::TempDir,
    listener: Option<std::process::Child>,
}

impl StockCli {
    fn command(&self, args: &[&str], log: &str) -> Command {
        let out = File::create(PathBuf::from(LOG_DIR).join(log)).expect("log");
        let err = out.try_clone().expect("log");
        let mut c = Command::new(STOCK_CLI);
        c.args(["--usernet", "--pass", CLI_PASS])
            .args(args)
            .current_dir(self.dir.path())
            .stdin(Stdio::null())
            .stdout(out)
            .stderr(err);
        c
    }

    /// Runs `args` and returns its output. Never used for commands that print the phrase.
    fn run(&self, step: &str, args: &[&str]) -> String {
        let log = format!("core4-cli-{step}.log");
        let status = self.command(args, &log).status().expect("cli");
        let text = fs::read_to_string(PathBuf::from(LOG_DIR).join(&log)).unwrap_or_default();
        assert!(status.success(), "cli {step} failed, see {LOG_DIR}/{log}");
        text
    }

    fn create() -> StockCli {
        let cli = StockCli {
            dir: tempfile::tempdir().expect("tempdir"),
            listener: None,
        };
        // `init` prints the recovery phrase: its output goes nowhere.
        let status = Command::new(STOCK_CLI)
            .args(["--usernet", "--pass", CLI_PASS, "init", "-w"])
            .current_dir(cli.dir.path())
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .expect("cli init");
        assert!(status.success(), "cli init failed");
        let toml = cli.dir.path().join("epic-wallet.toml");
        let text = fs::read_to_string(&toml).expect("toml");
        let text = text
            .lines()
            .map(|l| match l.split('=').next().unwrap_or("").trim() {
                "api_listen_port" => "api_listen_port = 23893".to_owned(),
                "owner_api_listen_port" => "owner_api_listen_port = 23894".to_owned(),
                "check_node_api_http_addr" => format!("check_node_api_http_addr = \"{NODE_URL}\""),
                "node_api_secret_path" => format!("#{l}"),
                "use_tor_listener" => "use_tor_listener = false".to_owned(),
                "epicbox_domain" => format!("epicbox_domain = \"{RELAY_HOST}\""),
                "epicbox_port" => format!("epicbox_port = {RELAY_PORT}"),
                "epicbox_protocol_unsecure" => "epicbox_protocol_unsecure = true".to_owned(),
                _ => l.to_owned(),
            })
            .collect::<Vec<_>>()
            .join("\n");
        fs::write(&toml, text).expect("write toml");
        cli
    }

    fn spendable(&self) -> u64 {
        let info = self.run("info", &["info", "--min_conf", &MIN_CONF.to_string()]);
        let line = info
            .lines()
            .find(|l| l.contains("Currently Spendable"))
            .expect("info has a spendable line");
        let value = line.rsplit('|').next().unwrap_or("").trim();
        let (whole, frac) = value.split_once('.').unwrap_or((value, "0"));
        let frac = format!("{frac:0<8}");
        whole.parse::<u64>().unwrap_or(0) * EPIC + frac[..8].parse::<u64>().unwrap_or(0)
    }

    fn listen(&mut self) {
        let child = self
            .command(&["listen", "-m", "epicbox"], "core4-cli-listen.log")
            .spawn()
            .expect("cli listen");
        self.listener = Some(child);
    }
}

impl Drop for StockCli {
    fn drop(&mut self) {
        if let Some(mut c) = self.listener.take() {
            let _ = c.kill();
            let _ = c.wait();
        }
    }
}

/// The question behind round 4: when an upstream wallet sends to us over epicbox, can it finalize
/// the reply our listener sends back? The stock CLI publishes the slate before it locks its
/// outputs (`controller/src/command.rs`, `send`, method "epicbox"), so a reply that arrives first
/// finds no transaction to finalize. Several sends in a row, each must reach the chain.
#[test]
#[ignore = "needs the usernet stable network and the local epicbox relay on 127.0.0.1:3423"]
fn stock_cli_sender_finalizes_our_epicbox_replies() {
    init_logging();
    assert!(
        std::net::TcpStream::connect((RELAY_HOST, RELAY_PORT)).is_ok(),
        "start the local relay first: cd /opt/epic/epic-relay && \
         EPIC_RELAY_EPICBOX_DOMAIN=127.0.0.1 EPIC_RELAY_ALIASES=localhost:3423 uv run epic-relay"
    );
    let mut net = Network::up();
    let dirs = tempfile::tempdir().expect("tempdir");
    let mut cfg = config(&dirs.path().join("b"), Chain::Usernet, NODE_URL);
    cfg.epicbox_domain = RELAY_HOST.into();
    cfg.epicbox_port = RELAY_PORT;
    let b = EpicWallet::create(cfg, None, PASSWORD.into()).expect("create B");
    let (tx, events) = std::sync::mpsc::channel();
    b.start_listener_with(move |e| {
        eprintln!("  B listener: {:?} {}", e.kind, e.message);
        let _ = tx.send(e);
    });
    let connected = events
        .recv_timeout(Duration::from_secs(30))
        .expect("B's listener event");
    assert_eq!(
        connected.kind,
        ListenerEventKind::Connected,
        "{}",
        connected.message
    );
    let b_address = b.epicbox_address().expect("address");

    // Fund the CLI from alice with a file slate, as a user would.
    let mut cli = StockCli::create();
    let slates = dirs.path().join("slates");
    fs::create_dir_all(&slates).expect("slates");
    let fund = slates.join("cli.tx");
    net_shell(
        "core4-alice-send",
        &format!(
            "w alice send -m file -d {} -c \"$MIN_CONF\" 3",
            fund.display()
        ),
        300,
    );
    cli.run("receive", &["receive", "-i", &fund.to_string_lossy()]);
    net_shell(
        "core4-alice-finalize",
        &format!("w alice finalize -f -i {}.response", fund.display()),
        300,
    );
    net.mine_until(
        "the CLI's 3 EPIC spendable",
        Duration::from_secs(600),
        || cli.spendable() == 3 * EPIC,
    );
    cli.listen();
    std::thread::sleep(Duration::from_secs(5));

    let each = EPIC / 10;
    for round in 1..=3u64 {
        cli.run(
            &format!("send-{round}"),
            &[
                "send",
                "-m",
                "epicbox",
                "-d",
                &b_address,
                "-c",
                &MIN_CONF.to_string(),
                "0.1",
            ],
        );
        loop {
            let e = events
                .recv_timeout(Duration::from_secs(60))
                .expect("B hears the send");
            if e.kind == ListenerEventKind::Received {
                assert_eq!(e.amount, Some(each));
                break;
            }
            assert_ne!(e.kind, ListenerEventKind::Error, "{}", e.message);
        }
        net.mine_until(
            &format!("send {round} confirmed at B"),
            Duration::from_secs(300),
            || spendable(&b) == round * each,
        );
    }
    let log =
        fs::read_to_string(PathBuf::from(LOG_DIR).join("core4-cli-listen.log")).unwrap_or_default();
    assert!(
        !log.contains("TransactionDoesntExist"),
        "the CLI could not finalize a reply"
    );
}
