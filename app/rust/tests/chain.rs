//! One process uses one chain at a time. Its own binary, because it switches the process chain.

mod common;

use common::*;
use epic_wallet_core::api::types::{Chain, WalletErrorKind};
use epic_wallet_core::api::wallet::EpicWallet;

#[test]
fn chain_switches_only_when_no_wallet_is_open() {
    let main_dir = tempfile::tempdir().expect("tempdir");
    let user_dir = tempfile::tempdir().expect("tempdir");
    let mainnet = config(main_dir.path(), Chain::Mainnet, DEAD_NODE);
    let usernet = config(user_dir.path(), Chain::Usernet, DEAD_NODE);

    let main_wallet = EpicWallet::create(mainnet.clone(), None, PASSWORD.into()).expect("mainnet");
    // A second wallet on the same chain is fine.
    let second_dir = tempfile::tempdir().expect("tempdir");
    let second = EpicWallet::create(
        config(second_dir.path(), Chain::Mainnet, DEAD_NODE),
        None,
        PASSWORD.into(),
    )
    .expect("second mainnet wallet");
    assert_eq!(
        kind_of(EpicWallet::create(usernet.clone(), None, PASSWORD.into())),
        WalletErrorKind::InvalidArgument
    );
    drop(second);
    assert_eq!(
        kind_of(EpicWallet::create(usernet.clone(), None, PASSWORD.into())),
        WalletErrorKind::InvalidArgument,
        "still one mainnet wallet open"
    );
    drop(main_wallet);

    let user_wallet = EpicWallet::create(usernet, None, PASSWORD.into()).expect("usernet");
    assert!(user_wallet.summary(false, 3).is_ok());
    drop(user_wallet);
    let reopened = EpicWallet::open(mainnet, PASSWORD.into()).expect("back to mainnet");
    assert!(reopened.summary(false, 10).is_ok());
}
