//! Against the mainnet node we control (`node.btlabs.uk`). Needs network, so `#[ignore]`.
//! Run with `cargo test --test mainnet -- --ignored`. Read-only: no funds move.

mod common;

use common::*;
use epic_wallet_core::api::types::Chain;
use epic_wallet_core::api::wallet::{node_tip, EpicWallet};

const NODE: &str = "https://node.btlabs.uk";

#[test]
#[ignore = "needs https://node.btlabs.uk"]
fn mainnet_tip_and_fresh_wallet() {
    let dir = tempfile::tempdir().expect("tempdir");
    let config = config(dir.path(), Chain::Mainnet, NODE);
    let tip = node_tip(config.clone()).expect("node tip");
    assert!(tip.height > 3_000_000, "mainnet is past 3M blocks");
    assert_ne!(tip.node_version, "unknown");

    let wallet = EpicWallet::create(config, None, PASSWORD.into()).expect("create");
    // epic-wallet 4.0.2 refreshes outputs only after `/v2/owner get_status` reports the node
    // synced. node.btlabs.uk's proxy answers that endpoint with 403 (checked 2026-09-27), so the
    // refresh is reported as not validated rather than failing.
    let summary = wallet.summary(true, 10).expect("summary");
    assert!(!summary.validated_with_node);
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
