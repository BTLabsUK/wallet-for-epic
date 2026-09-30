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

/// Reads a slate file: its id, amount, fee, and whether it is a send to us or a response to
/// ours. Needs no wallet, so the UI can show the amount before anything is signed.
#[frb(sync)]
pub fn inspect_slate(json: String) -> Result<SlateInfo, WalletError> {
    crate::core::slate::inspect(&json).map_err(to_api)
}

/// True for `<52-char address>@<relay>[:port]` whose key is valid on the current chain.
#[frb(sync)]
pub fn validate_epicbox_address(address: String) -> bool {
    crate::core::epicbox::parse_address(&address).is_ok()
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

    /// Transactions, newest first by `time_unix`: epic-wallet's log merged with the app's history
    /// archive (notes, counterparties, imported records). With `refresh` it updates from the node
    /// first.
    pub fn transactions(&self, refresh: bool) -> Result<Vec<TxEntry>, WalletError> {
        self.inner.transactions(refresh).map_err(to_api)
    }

    /// Sets the note of the transaction with `TxEntry.key`; `None` or blank clears it.
    pub fn set_tx_note(&self, key: String, note: Option<String>) -> Result<(), WalletError> {
        self.inner.set_tx_note(&key, note).map_err(to_api)
    }

    /// Address book, sorted by name.
    pub fn contacts(&self) -> Result<Vec<Contact>, WalletError> {
        Ok(self.inner.contacts())
    }

    /// Adds a contact (empty `id`) or replaces the one with that id. Returns it as stored.
    pub fn save_contact(&self, contact: Contact) -> Result<Contact, WalletError> {
        self.inner.save_contact(contact).map_err(to_api)
    }

    pub fn delete_contact(&self, id: String) -> Result<(), WalletError> {
        self.inner.delete_contact(&id).map_err(to_api)
    }

    /// The whole history (transactions, notes, contacts) as an encrypted file only a wallet with
    /// the same recovery phrase can open.
    pub fn export_history(&self) -> Result<Vec<u8>, WalletError> {
        self.inner.export_history().map_err(to_api)
    }

    /// The transaction list as CSV, for records. Not encrypted and not importable.
    pub fn export_history_csv(&self) -> Result<String, WalletError> {
        self.inner.export_history_csv().map_err(to_api)
    }

    /// Merges a file from `export_history` into this wallet's history. Importing the same file
    /// again changes nothing. A file from another wallet fails with `InvalidArgument`.
    pub fn import_history(&self, data: Vec<u8>) -> Result<ImportReport, WalletError> {
        self.inner.import_history(&data).map_err(to_api)
    }

    /// The largest amount that can be sent now, and its fee. Sending `amount` spends every
    /// spendable output with no change.
    pub fn estimate_max(&self, minimum_confirmations: u64) -> Result<FeeEstimate, WalletError> {
        self.inner
            .estimate_max(minimum_confirmations)
            .map_err(to_api)
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

    /// Sends to a wallet listening on HTTP, e.g. `http://host:3415`. Completes the whole exchange:
    /// the recipient signs in the same request, then the transaction is finalized and posted.
    /// A failure before the post unlocks the outputs again. Receiving over HTTP is not offered:
    /// a phone cannot accept incoming connections.
    pub fn send_http(
        &self,
        amount: u64,
        minimum_confirmations: u64,
        url: String,
    ) -> Result<TxEntry, WalletError> {
        self.inner
            .send_http(amount, minimum_confirmations, &url)
            .map_err(to_api)
    }

    /// Sends to `<address>@<relay>[:port]` over epicbox. Returns the new, still unfinalized
    /// transaction; the listener finalizes and posts it when the recipient's response arrives.
    pub fn send_epicbox(
        &self,
        amount: u64,
        minimum_confirmations: u64,
        address: String,
    ) -> Result<TxEntry, WalletError> {
        self.inner
            .send_epicbox(amount, minimum_confirmations, &address)
            .map_err(to_api)
    }

    /// Starts the epicbox listener (no-op if it already runs) and streams what it does. Incoming
    /// sends are signed and answered, responses to our sends are finalized and posted.
    pub fn start_listener(&self, events: StreamSink<ListenerEvent>) -> Result<(), WalletError> {
        self.inner.start_listener(move |event| {
            let _ = events.add(event);
        });
        Ok(())
    }

    /// `start_listener` with a Rust callback. For Rust callers and tests.
    #[frb(ignore)]
    pub fn start_listener_with<F>(&self, on_event: F)
    where
        F: FnMut(ListenerEvent) + Send + 'static,
    {
        self.inner.start_listener(on_event);
    }

    /// Stops the listener. Takes up to about a second.
    pub fn stop_listener(&self) {
        self.inner.stop_listener();
    }

    #[frb(sync)]
    pub fn listener_running(&self) -> bool {
        self.inner.listener_running()
    }

    /// Cancels an unconfirmed transaction by log id and unlocks its outputs.
    pub fn cancel_transaction(&self, tx_id: u32) -> Result<(), WalletError> {
        self.inner.cancel_transaction(tx_id).map_err(to_api)
    }
}

pub(crate) fn to_api(e: CoreError) -> WalletError {
    let kind = match &e {
        CoreError::WrongPassword => WalletErrorKind::WrongPassword,
        CoreError::InvalidMnemonic => WalletErrorKind::InvalidMnemonic,
        CoreError::WalletExists(_) => WalletErrorKind::WalletAlreadyExists,
        CoreError::WalletNotFound(_) => WalletErrorKind::WalletNotFound,
        CoreError::InvalidArgument(_) | CoreError::ChainInUse { .. } => {
            WalletErrorKind::InvalidArgument
        }
        CoreError::InvalidSlate(_) => WalletErrorKind::InvalidSlate,
        CoreError::Relay(_) => WalletErrorKind::TransportFailed,
        CoreError::Io(_) => WalletErrorKind::Io,
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
