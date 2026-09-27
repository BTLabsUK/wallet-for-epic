//! Against the mainnet node we control (`node.btlabs.uk`). Needs network, so `#[ignore]`.
//! Run with `cargo test --test mainnet -- --ignored`. Read-only: no funds move.

mod common;

use common::*;
use epic_wallet_core::api::types::Chain;
use epic_wallet_core::api::wallet::{node_tip, EpicWallet};

const NODE: &str = "https://node.btlabs.uk";

#[test]
#[ignore = "needs https://node.btlabs.uk"]
fn mainnet_tip_and_fresh_wallet_refresh() {
    init_logging();
    let dir = tempfile::tempdir().expect("tempdir");
    let config = config(dir.path(), Chain::Mainnet, NODE);
    let tip = node_tip(config.clone()).expect("node tip");
    assert!(tip.height > 3_000_000, "mainnet is past 3M blocks");
    assert_ne!(tip.node_version, "unknown");

    let wallet = EpicWallet::create(config, None, PASSWORD.into()).expect("create");
    // node.btlabs.uk closes /v2/owner (403), so this goes through the foreign-API sync fallback.
    let summary = wallet.summary(true, 10).expect("summary");
    assert!(
        summary.validated_with_node,
        "refresh must work without the owner API"
    );
    assert!(summary.last_confirmed_height >= tip.height);
    assert_eq!(summary.total, 0);

    let address = wallet.epicbox_address().expect("address");
    let (key, domain) = address.split_once('@').expect("key@domain");
    assert_eq!(domain, "epicbox.epiccash.com");
    assert_eq!(
        key.len(),
        52,
        "base58check of a compressed key plus 2 version bytes"
    );
}

/// Every mainnet relay `status.btlabs.uk` reports healthy accepts our listener's subscription.
/// Relays whose host this machine cannot resolve correctly are skipped and named: the ISP resolver
/// here answers `epicbox.epiccash.com` with a filter address (81.99.162.48), not the relay.
#[test]
#[ignore = "needs the internet and status.btlabs.uk"]
fn listener_subscribes_on_every_healthy_mainnet_relay() {
    use epic_wallet_core::api::types::ListenerEventKind;
    use std::time::Duration;

    init_logging();
    let body = reqwest::blocking::get("https://status.btlabs.uk/api/v1/status.json")
        .and_then(|r| r.text())
        .expect("status");
    let status: serde_json::Value = serde_json::from_str(&body).expect("status json");
    let relays: Vec<(String, u16)> = status["epicbox"]
        .as_array()
        .expect("epicbox list")
        .iter()
        .filter(|r| r["state"] == "healthy")
        .filter_map(|r| {
            let url = reqwest::Url::parse(r["endpoint"].as_str()?).ok()?;
            Some((url.host_str()?.to_string(), url.port().unwrap_or(443)))
        })
        .collect();
    assert!(!relays.is_empty(), "the monitor lists no healthy mainnet relay");

    let mut connected = Vec::new();
    let mut failed = Vec::new();
    for (host, port) in relays {
        let dir = tempfile::tempdir().expect("tempdir");
        let mut cfg = config(dir.path(), Chain::Mainnet, NODE);
        cfg.epicbox_domain = host.clone();
        cfg.epicbox_port = port;
        let wallet = EpicWallet::create(cfg, None, PASSWORD.into()).expect("create");
        let address = wallet.epicbox_address().expect("address");
        assert!(address.ends_with(&format!("@{host}")), "{address}");
        let (tx, rx) = std::sync::mpsc::channel();
        wallet.start_listener_with(move |e| {
            let _ = tx.send(e);
        });
        let mut outcome = None;
        while let Ok(e) = rx.recv_timeout(Duration::from_secs(30)) {
            match e.kind {
                ListenerEventKind::Connected => {
                    outcome = Some(Ok(()));
                    break;
                }
                ListenerEventKind::Disconnected => {
                    outcome = Some(Err(e.message));
                    break;
                }
                _ => {}
            }
        }
        wallet.stop_listener();
        match outcome {
            Some(Ok(())) => connected.push(host),
            Some(Err(why)) => failed.push(format!("{host}: {why}")),
            None => failed.push(format!("{host}: no answer in 30 s")),
        }
    }
    eprintln!("subscribed on: {connected:?}");
    eprintln!("could not reach: {failed:?}");
    assert!(
        connected.len() >= 2,
        "expected at least two mainnet relays to accept a subscription"
    );
}
