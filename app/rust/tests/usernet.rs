//! End to end on the local usernet stable network (`/opt/epic/stable-network`, see
//! its README). `#[ignore]`, so plain `cargo test` stays offline.
//! Run with `cargo test --test usernet -- --ignored`.
//!
//! Two fresh wallets made by this crate, A and B. alice (the funded network wallet, driven through the
//! network's own `bin/epic-wallet`) pays A with a file slate; then A pays B entirely through our API;
//! then a send from A is cancelled and its outputs come back; then a restore of A's seed rescans the
//! chain and finds the same balance.
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
use epic_wallet_core::api::types::{Chain, TxKind, WalletConfig, WalletErrorKind};
use epic_wallet_core::api::wallet::{node_tip, EpicWallet};

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

    let a = EpicWallet::create(
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
    let reply = b.receive_slate(send.json.clone()).expect("B receives");
    assert_eq!(reply.slate_id, send.slate_id);
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
    a.cancel_transaction(entry.id).expect("cancel");
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
        kind_of(a.cancel_transaction(entry.id + 100)),
        WalletErrorKind::InvalidArgument
    );
    net.stop_miner();

    // 4. Scan streams progress and ends with `finished`; a restore finds the same balance.
    let mut events = Vec::new();
    a.scan_with(Some(1), |p| events.push(p)).expect("scan A");
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
}
