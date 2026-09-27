//! The wallet API Dart calls. This file is the contract between the Rust core and the Flutter UI.
//!
//! Threading: every non-`sync` function runs on flutter_rust_bridge's worker pool and returns a
//! Future in Dart. epic-wallet's HTTP client blocks on its own runtime, so never make these
//! functions `async` (that would run them inside a tokio executor and can panic).
//!
//! Chain: epic's consensus parameters are process-global, so one process uses one `Chain` at a
//! time. Opening or creating a wallet on a different chain fails with `InvalidArgument` while any
//! wallet on the current chain is still open; drop every `EpicWallet` first to switch.
//!
//! Secrets: the keychain mask never leaves Rust. Passwords and mnemonics arrive as Strings from
//! Dart and are moved into `ZeroingString` immediately.

use flutter_rust_bridge::frb;

use epic_wallet_libwallet::Error as LibWalletError;
use epic_wallet_util::epic_util::ZeroingString;

use crate::api::types::*;
use crate::core::error::CoreError;
use crate::core::{mnemonic, session};
use crate::frb_generated::StreamSink;

/// Generates a new BIP-39 recovery phrase. `word_count` is 12 or 24.
#[frb(sync)]
pub fn generate_mnemonic(word_count: u32) -> Result<String, WalletError> {
    mnemonic::generate(word_count).map_err(to_api)
}

/// True when every word is in the wordlist and the checksum matches.
#[frb(sync)]
pub fn validate_mnemonic(phrase: String) -> bool {
    mnemonic::is_valid(&mnemonic::normalize(phrase))
}

/// True when `config.data_dir` already holds a wallet seed.
pub fn wallet_exists(config: WalletConfig) -> bool {
    session::wallet_exists(&config).unwrap_or(false)
}

/// Current tip of the configured node, without opening a wallet.
pub fn node_tip(config: WalletConfig) -> Result<NodeTip, WalletError> {
    session::node_tip(&config).map_err(to_api)
}

/// An open wallet. Opaque to Dart; dropping it closes the wallet and zeroizes the keychain mask.
#[frb(opaque)]
pub struct EpicWallet {
    pub(crate) inner: crate::core::session::Session,
}

impl EpicWallet {
    /// Creates a wallet in `config.data_dir`. With `mnemonic` it restores that seed (call
    /// `scan` afterwards); without it a fresh seed is generated. Returns the opened wallet.
    pub fn create(
        config: WalletConfig,
        mnemonic: Option<String>,
        password: String,
    ) -> Result<EpicWallet, WalletError> {
        let password = ZeroingString::from(password);
        session::Session::create(&config, mnemonic, password)
            .map(|inner| EpicWallet { inner })
            .map_err(to_api)
    }

    /// Opens an existing wallet. Wrong password gives `WalletErrorKind::WrongPassword`.
    pub fn open(config: WalletConfig, password: String) -> Result<EpicWallet, WalletError> {
        let password = ZeroingString::from(password);
        session::Session::open(&config, password)
            .map(|inner| EpicWallet { inner })
            .map_err(to_api)
    }

    /// Recovery phrase of this wallet, re-checked against `password`.
    pub fn mnemonic(&self, password: String) -> Result<String, WalletError> {
        self.inner
            .mnemonic(ZeroingString::from(password))
            .map_err(to_api)
    }

    /// Balances. With `refresh` the wallet first updates output state from the node.
    pub fn summary(
        &self,
        refresh: bool,
        minimum_confirmations: u64,
    ) -> Result<WalletSummary, WalletError> {
        self.inner
            .summary(refresh, minimum_confirmations)
            .map_err(to_api)
    }

    /// Rescans the chain for this wallet's outputs from `start_height` (default: the wallet's
    /// last scanned height, or 1 for a restore), streaming progress until `finished`.
    pub fn scan(
        &self,
        start_height: Option<u64>,
        progress: StreamSink<ScanProgress>,
    ) -> Result<(), WalletError> {
        self.scan_with(start_height, move |p| {
            // A closed Dart stream only means nobody is listening; the scan itself carries on.
            let _ = progress.add(p);
        })
    }

    /// `scan` with a Rust callback instead of a Dart stream. For Rust callers and tests.
    #[frb(ignore)]
    pub fn scan_with<F>(&self, start_height: Option<u64>, on_progress: F) -> Result<(), WalletError>
    where
        F: FnMut(ScanProgress) + Send,
    {
        self.inner.scan(start_height, on_progress).map_err(to_api)
    }

    /// Transaction log, newest first. With `refresh` it updates from the node first.
    pub fn transactions(&self, refresh: bool) -> Result<Vec<TxEntry>, WalletError> {
        self.inner.transactions(refresh).map_err(to_api)
    }

    /// The wallet's epicbox address, `<pubkey>@<epicbox_domain>` (port appended if not 443).
    pub fn epicbox_address(&self) -> Result<String, WalletError> {
        self.inner.epicbox_address().map_err(to_api)
    }

    /// Fee the wallet would pay to send `amount` now.
    pub fn estimate_fee(
        &self,
        amount: u64,
        minimum_confirmations: u64,
    ) -> Result<FeeEstimate, WalletError> {
        self.inner
            .estimate_fee(amount, minimum_confirmations)
            .map_err(to_api)
    }

    /// Step 1 of a manual (file/JSON) send: builds the slate and locks the inputs.
    /// Hand `Slate.json` to the recipient; their response goes to `finalize_and_post`.
    pub fn create_send_slate(
        &self,
        amount: u64,
        minimum_confirmations: u64,
    ) -> Result<Slate, WalletError> {
        self.inner
            .create_send_slate(amount, minimum_confirmations)
            .map_err(to_api)
    }

    /// Recipient side: signs an incoming send slate and returns the response slate JSON.
    pub fn receive_slate(&self, slate_json: String) -> Result<Slate, WalletError> {
        self.inner.receive_slate(&slate_json).map_err(to_api)
    }

    /// Sender side: finalizes the recipient's response and posts the transaction to the node.
    pub fn finalize_and_post(&self, slate_json: String) -> Result<TxEntry, WalletError> {
        self.inner.finalize_and_post(&slate_json).map_err(to_api)
    }

    /// Cancels an unconfirmed transaction by log id and unlocks its outputs.
    pub fn cancel_transaction(&self, tx_id: u32) -> Result<(), WalletError> {
        self.inner.cancel_transaction(tx_id).map_err(to_api)
    }
}

fn to_api(e: CoreError) -> WalletError {
    let kind = match &e {
        CoreError::WrongPassword => WalletErrorKind::WrongPassword,
        CoreError::InvalidMnemonic => WalletErrorKind::InvalidMnemonic,
        CoreError::WalletExists(_) => WalletErrorKind::WalletAlreadyExists,
        CoreError::WalletNotFound(_) => WalletErrorKind::WalletNotFound,
        CoreError::InvalidArgument(_) | CoreError::ChainInUse { .. } => {
            WalletErrorKind::InvalidArgument
        }
        CoreError::InvalidSlate(_) => WalletErrorKind::InvalidSlate,
        CoreError::Wallet(w) => kind_of(w),
    };
    WalletError {
        kind,
        message: e.to_string(),
    }
}

fn kind_of(e: &LibWalletError) -> WalletErrorKind {
    use LibWalletError as E;
    match e {
        E::NotEnoughFunds { .. } => WalletErrorKind::NotEnoughFunds,
        // Transport failures. A node that answers with a JSON-RPC error is `BadRequest`, below.
        E::ClientCallback(_)
        | E::Node
        | E::NodeStatus(_)
        | E::Hyper
        | E::RequestError(_)
        | E::HttpError(..)
        | E::InternalServerError(_)
        | E::Unauthorized
        // Its only use: cancel_tx refuses to run when the node cannot be reached.
        | E::TransactionCancellationError(_) => WalletErrorKind::NodeUnreachable,
        E::SlateDeser
        | E::SlateSer
        | E::SlateVersion(_)
        | E::SlateVersionParse
        | E::Signature(_)
        | E::Compatibility(_)
        | E::TransactionAlreadyReceived(_)
        | E::TransactionExpired => WalletErrorKind::InvalidSlate,
        E::WalletSeedExists(_) => WalletErrorKind::WalletAlreadyExists,
        E::WalletSeedDoesntExist => WalletErrorKind::WalletNotFound,
        E::WalletSeedDecryption => WalletErrorKind::WrongPassword,
        E::TransactionDoesntExist(_)
        | E::TransactionNotCancellable(_)
        | E::TransactionAlreadyConfirmed
        | E::ArgumentError(_)
        | E::Fee(_) => WalletErrorKind::InvalidArgument,
        E::StdIO(_) | E::IOError(_) => WalletErrorKind::Io,
        _ => WalletErrorKind::Other,
    }
}
