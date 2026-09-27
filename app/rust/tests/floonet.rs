//! End to end on the public floonet, through our API only on our side.
//!
//! Run with `cargo test --test floonet -- --ignored --nocapture`. Needs the internet and a moving
//! floonet chain (`/opt/epic/floo-miner`), and takes several minutes, because each step waits for a
//! block.
//!
//! 1. The floonet faucet (`floo-explorer.btlabs.uk/api/faucet`) pays wallet A over epicbox; A's
//!    listener signs and returns it.
//! 2. A pays B over epicbox; B's listener signs, A's listener finalizes and posts.
//! 3. A pays a stock `epic-wallet listen` (HTTP) in a temp directory in one call.
//!
//! Relay `flooepicbox.btlabs.uk`, node `floo-node.btlabs.uk`. Seeds and passwords are never
//! printed.

mod common;

use std::path::Path;
use std::process::{Child, Command, Stdio};
use std::sync::mpsc::{channel, Receiver};
use std::time::{Duration, Instant};

use common::*;
use epic_wallet_core::api::types::{
    Chain, ListenerEvent, ListenerEventKind, WalletConfig, WalletSummary,
};
use epic_wallet_core::api::wallet::{validate_epicbox_address, EpicWallet};

const NODE: &str = "https://floo-node.btlabs.uk";
const RELAY: &str = "flooepicbox.btlabs.uk";
const FAUCET: &str = "https://floo-explorer.btlabs.uk/api/faucet";
const CLI: &str = "/opt/epic/user-env/bin/epic-wallet";
const MIN_CONF: u64 = 1;
const HTTP_PORT: u16 = 23875;
const PROXY_PORT: u16 = 23876;

fn floonet(dir: &Path) -> WalletConfig {
    WalletConfig {
        epicbox_domain: RELAY.into(),
        epicbox_port: 443,
        ..config(dir, Chain::Floonet, NODE)
    }
}

fn listen(wallet: &EpicWallet) -> Receiver<ListenerEvent> {
    let (tx, rx) = channel();
    wallet.start_listener_with(move |e| {
        eprintln!("  listener: {:?} {}", e.kind, e.message);
        let _ = tx.send(e);
    });
    rx
}

fn wait_event(rx: &Receiver<ListenerEvent>, kind: ListenerEventKind, minutes: u64) -> ListenerEvent {
    let end = Instant::now() + Duration::from_secs(minutes * 60);
    while Instant::now() < end {
        if let Ok(e) = rx.recv_timeout(Duration::from_secs(5)) {
            if e.kind == kind {
                return e;
            }
            assert_ne!(e.kind, ListenerEventKind::Error, "listener error: {}", e.message);
        }
    }
    panic!("no {kind:?} event within {minutes} min");
}

fn summary(w: &EpicWallet) -> WalletSummary {
    w.summary(true, MIN_CONF).expect("summary")
}

/// Polls until `pred` holds for the refreshed summary. Blocks come every one to three minutes.
fn wait_balance(w: &EpicWallet, what: &str, minutes: u64, pred: impl Fn(&WalletSummary) -> bool) {
    let end = Instant::now() + Duration::from_secs(minutes * 60);
    loop {
        match w.summary(true, MIN_CONF) {
            Ok(s) if pred(&s) => return,
            Ok(s) => eprintln!(
                "  waiting for {what}: spendable {} awaiting {} at {}",
                s.spendable, s.awaiting_confirmation, s.last_confirmed_height
            ),
            Err(e) => eprintln!("  waiting for {what}: {e}"),
        }
        assert!(Instant::now() < end, "{what} not reached within {minutes} min");
        std::thread::sleep(Duration::from_secs(20));
    }
}

/// A stock epic-wallet 4.0.0 listening on HTTP, in its own temp directory.
struct CliListener {
    child: Child,
    proxy: Child,
    _dir: tempfile::TempDir,
}

fn wait_port(port: u16, what: &str) {
    let end = Instant::now() + Duration::from_secs(60);
    while std::net::TcpStream::connect(("127.0.0.1", port)).is_err() {
        assert!(Instant::now() < end, "{what} did not start");
        std::thread::sleep(Duration::from_millis(500));
    }
}

impl CliListener {
    fn start() -> CliListener {
        let dir = tempfile::tempdir().expect("tempdir");
        // The CLI receives only behind a node that reports itself synced; see the script.
        let proxy = Command::new("python3")
            .arg(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/support/node_proxy.py"))
            .arg(PROXY_PORT.to_string())
            .arg(NODE)
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn()
            .expect("node proxy");
        wait_port(PROXY_PORT, "node proxy");
        let run = |args: &[&str]| {
            let mut c = Command::new(CLI);
            c.args(["--floonet", "--pass", "cli-http-test"])
                .args(args)
                .current_dir(dir.path())
                .stdin(Stdio::null())
                .stdout(Stdio::null())
                .stderr(Stdio::null());
            c
        };
        let status = run(&["init", "-w"]).status().expect("cli init");
        assert!(status.success(), "cli init failed");
        let toml = dir.path().join("epic-wallet.toml");
        let text = std::fs::read_to_string(&toml).expect("toml");
        let text = text
            .lines()
            .map(|l| {
                if l.starts_with("api_listen_port") {
                    format!("api_listen_port = {HTTP_PORT}")
                } else if l.starts_with("check_node_api_http_addr") {
                    format!("check_node_api_http_addr = \"http://127.0.0.1:{PROXY_PORT}\"")
                } else if l.starts_with("node_api_secret_path") {
                    format!("#{l}")
                } else {
                    l.to_string()
                }
            })
            .collect::<Vec<_>>()
            .join("\n");
        std::fs::write(&toml, text).expect("write toml");
        let child = run(&["listen", "-m", "http"]).spawn().expect("cli listen");
        wait_port(HTTP_PORT, "cli listener");
        CliListener {
            child,
            proxy,
            _dir: dir,
        }
    }
}

impl Drop for CliListener {
    fn drop(&mut self) {
        for child in [&mut self.child, &mut self.proxy] {
            let _ = child.kill();
            let _ = child.wait();
        }
    }
}

#[test]
#[ignore = "public floonet, several minutes"]
fn faucet_then_epicbox_then_http() {
    init_logging();
    let dir_a = tempfile::tempdir().unwrap();
    let dir_b = tempfile::tempdir().unwrap();
    let a = EpicWallet::create(floonet(dir_a.path()), None, PASSWORD.into()).expect("create A");
    let b = EpicWallet::create(floonet(dir_b.path()), None, PASSWORD.into()).expect("create B");
    let addr_a = a.epicbox_address().unwrap();
    let addr_b = b.epicbox_address().unwrap();
    assert!(addr_a.ends_with(&format!("@{RELAY}")), "{addr_a}");
    assert!(validate_epicbox_address(addr_b.clone()));
    eprintln!("A {addr_a}\nB {addr_b}");

    let events_a = listen(&a);
    let events_b = listen(&b);
    wait_event(&events_a, ListenerEventKind::Connected, 1);
    wait_event(&events_b, ListenerEventKind::Connected, 1);

    // 1. Faucet to A over epicbox.
    let claim = reqwest::blocking::Client::new()
        .post(format!("{FAUCET}/claim"))
        .query(&[("method", "epicbox"), ("destination", addr_a.as_str())])
        .timeout(Duration::from_secs(60))
        .send()
        .expect("faucet claim");
    let status = claim.status();
    let body = claim.text().unwrap_or_default();
    assert!(status.is_success(), "faucet refused: {status} {body}");
    wait_event(&events_a, ListenerEventKind::Received, 5);
    wait_balance(&a, "faucet funds", 20, |s| s.spendable >= 5 * EPIC);
    let start = summary(&a).spendable;

    // A failed transport leaves nothing locked.
    let before = summary(&a);
    assert_eq!(before.locked, 0);
    let err = a
        .send_http(EPIC / 4, MIN_CONF, format!("http://127.0.0.1:{}", HTTP_PORT + 1))
        .map(|_| ())
        .unwrap_err();
    assert_eq!(err.kind, epic_wallet_core::api::types::WalletErrorKind::TransportFailed);
    let after = summary(&a);
    assert_eq!(after.locked, before.locked, "a failed send must unlock its outputs");


    // 2. A to B over epicbox.
    let sent = a.send_epicbox(EPIC, MIN_CONF, addr_b.clone()).expect("epicbox send");
    assert!(!sent.confirmed);
    wait_event(&events_b, ListenerEventKind::Received, 5);
    wait_event(&events_a, ListenerEventKind::Finalized, 5);
    wait_balance(&b, "B funds", 20, |s| s.spendable == EPIC);

    // 3. A to a stock CLI wallet over HTTP.
    let cli = CliListener::start();
    wait_balance(&a, "A change", 20, |s| s.spendable >= 2 * EPIC);
    let tx = a
        .send_http(EPIC / 2, MIN_CONF, format!("http://127.0.0.1:{HTTP_PORT}"))
        .expect("http send");
    assert!(tx.amount_debited > 0);
    eprintln!("  http send posted, tx {}", tx.id);
    drop(cli);

    wait_balance(&a, "A settled", 20, |s| {
        s.awaiting_confirmation == 0 && s.locked == 0 && s.spendable < start
    });
    a.stop_listener();
    b.stop_listener();
    assert!(!a.listener_running());
}
