//! One process uses one chain at a time. Its own binary, because it switches the process chain.

mod common;

use common::*;
use epic_wallet_core::api::types::{Chain, WalletErrorKind};
use epic_wallet_core::api::wallet::EpicWallet;

#[test]
fn chain_switches_once_the_last_wallet_on_the_other_chain_closes() {
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

    // As when Dart disposes a wallet while a call on it is still running: the wallets close a
    // moment later, on another thread, and the usernet create waits for both.
    let closer = std::thread::spawn(move || {
        std::thread::sleep(std::time::Duration::from_millis(200));
        drop(second);
        std::thread::sleep(std::time::Duration::from_millis(200));
        drop(main_wallet);
    });
    let start = std::time::Instant::now();
    let user_wallet = EpicWallet::create(usernet, None, PASSWORD.into()).expect("usernet");
    assert!(
        start.elapsed() >= std::time::Duration::from_millis(350),
        "it waited for both"
    );
    closer.join().expect("closer");
    assert!(user_wallet.summary(false, 3).is_ok());

    // With a usernet wallet still open, mainnet is refused once the wait (20 s) runs out.
    let e = EpicWallet::open(mainnet.clone(), PASSWORD.into())
        .err()
        .expect("refused");
    assert_eq!(e.kind, WalletErrorKind::ChainBusy);
    drop(user_wallet);
    let reopened = EpicWallet::open(mainnet, PASSWORD.into()).expect("back to mainnet");
    assert!(reopened.summary(false, 10).is_ok());
}
