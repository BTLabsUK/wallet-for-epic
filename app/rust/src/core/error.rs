//! Errors produced by the core. `api::wallet` maps them onto `WalletError` for Dart.

use epic_wallet_libwallet::Error as LibWalletError;

use crate::api::types::Chain;

#[derive(Debug, thiserror::Error)]
pub(crate) enum CoreError {
    #[error("wrong password")]
    WrongPassword,
    #[error("invalid recovery phrase")]
    InvalidMnemonic,
    #[error("a wallet already exists in {0}")]
    WalletExists(String),
    #[error("no wallet in {0}")]
    WalletNotFound(String),
    #[error("{0}")]
    InvalidArgument(String),
    #[error("invalid slate: {0}")]
    InvalidSlate(String),
    #[error(
        "this process already uses {active:?} for an open wallet; close it before using {requested:?}"
    )]
    ChainInUse { active: Chain, requested: Chain },
    #[error(transparent)]
    Wallet(#[from] LibWalletError),
}

pub(crate) type CoreResult<T> = Result<T, CoreError>;
