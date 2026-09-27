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
