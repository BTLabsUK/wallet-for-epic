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
    /// The epicbox relay, or the recipient's HTTP listener, could not be reached or refused.
    #[error("{0}")]
    Relay(String),
    /// The recipient's answer came at or too near the send's TTL cutoff. The send was cancelled
    /// instead of finalized, so nothing was sent.
    #[error("{0}")]
    Expired(String),
    /// Something needed right now (the chain height) could not be read; try again later.
    #[error("{0}")]
    RetryLater(String),
    /// A wallet is still in use (a call is running on it) or being deleted.
    #[error("{0}")]
    Busy(String),
    /// Reading or writing one of the app's own files failed.
    #[error("{0}")]
    Io(String),
    #[error(transparent)]
    Wallet(#[from] LibWalletError),
}

pub(crate) type CoreResult<T> = Result<T, CoreError>;
