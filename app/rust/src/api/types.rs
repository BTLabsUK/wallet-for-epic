//! Plain data types exchanged with Dart. Amounts are in the smallest unit (1 EPIC = 100_000_000).

/// Which Epic chain the wallet talks to. Selects consensus parameters and default ports.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Chain {
    Mainnet,
    Floonet,
    Usernet,
}

/// Everything needed to locate a wallet on disk and reach its node and epicbox relay.
#[derive(Debug, Clone)]
pub struct WalletConfig {
    /// Directory owned by this wallet. The wallet creates `wallet_data/` inside it.
    pub data_dir: String,
    pub chain: Chain,
    /// Node base URL, e.g. `https://node.btlabs.uk` or `http://127.0.0.1:23413`.
    pub node_url: String,
    /// Basic-auth secret (user `epic`) sent with every node request. Optional: public nodes need
    /// none. With owner access the node's own sync status gates a refresh; without it the core
    /// judges sync from the foreign API tip (see `core/node.rs`).
    pub node_api_secret: Option<String>,
    /// Epicbox relay domain used for the wallet's address, e.g. `epicbox.epiccash.com`.
    pub epicbox_domain: String,
    pub epicbox_port: u16,
}

#[derive(Debug, Clone)]
pub struct NodeTip {
    pub height: u64,
    pub node_version: String,
}

/// Mirrors epic-wallet's `WalletInfo`.
#[derive(Debug, Clone)]
pub struct WalletSummary {
    pub last_confirmed_height: u64,
    pub minimum_confirmations: u64,
    pub total: u64,
    pub spendable: u64,
    pub awaiting_confirmation: u64,
    pub awaiting_finalization: u64,
    pub immature: u64,
    pub locked: u64,
    /// False when the refresh against the node failed and the numbers come from the local DB.
    pub validated_with_node: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TxKind {
    Coinbase,
    Received,
    Sent,
    ReceivedCancelled,
    SentCancelled,
}

/// Where a transaction stands, as far as this wallet can tell.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TxStatus {
    /// Our send, not yet signed by the recipient (not finalized).
    AwaitingRecipient,
    /// Finalized send, or a receive we signed, not yet seen on chain.
    AwaitingConfirmation,
    Confirmed,
    Cancelled,
}

/// Where a transaction row comes from.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TxSource {
    /// Made by this wallet (live in epic-wallet's log).
    Wallet,
    /// Rebuilt by a scan from an unspent output; details beyond amount and height are unknown.
    Restored,
    /// From an imported history file, with no live row in this wallet.
    Imported,
}

/// One transaction: epic-wallet's log merged with the app's history archive.
#[derive(Debug, Clone)]
pub struct TxEntry {
    /// Stable across restores: `s:<slate>`, else `k:<kernel>`, else `c:<commit>`, else `l:<id>`.
    pub key: String,
    /// Local log id, used for cancel. `None` for imported records.
    pub id: Option<u32>,
    pub slate_id: Option<String>,
    pub kind: TxKind,
    pub status: TxStatus,
    pub source: TxSource,
    pub created_at_unix: i64,
    /// Best known time: the block time for restored rows when known, else `created_at_unix`.
    pub time_unix: i64,
    pub confirmed: bool,
    pub block_height: Option<u64>,
    pub block_time_unix: Option<i64>,
    pub amount_credited: u64,
    pub amount_debited: u64,
    pub fee: Option<u64>,
    pub num_inputs: u32,
    pub num_outputs: u32,
    pub kernel_excess: Option<String>,
    /// Hex commitments of the outputs this transaction created for us (receive or change).
    pub output_commits: Vec<String>,
    /// Epicbox address or URL of the other side, when known.
    pub counterparty: Option<String>,
    pub note: Option<String>,
    pub ttl_cutoff_height: Option<u64>,
    /// True when `cancel_transaction(id)` is allowed.
    pub cancellable: bool,
    /// True for a finalized send that is not confirmed and has its final transaction stored:
    /// `repost_transaction(key)` can post it to the node again.
    pub repostable: bool,
    /// Why the status is what it is, when that is not obvious, e.g. an imported send that never
    /// reached the chain.
    pub status_detail: Option<String>,
    /// True for a finalized send the node refused and whose kernel was still not on chain a day
    /// of blocks after it was finalized: `release_stuck_send(key)` unlocks its funds.
    pub releasable: bool,
    /// When this wallet finalized the send (unix seconds), if it did.
    pub finalized_at_unix: Option<i64>,
}

/// An address book entry. An empty `id` in `save_contact` creates a new one.
#[derive(Debug, Clone)]
pub struct Contact {
    pub id: String,
    pub name: String,
    pub address: String,
    pub note: Option<String>,
}

/// What `import_history` did.
#[derive(Debug, Clone)]
pub struct ImportReport {
    /// Records that matched a transaction already shown and filled in its details.
    pub merged: u32,
    /// Records with no match, now shown as imported history.
    pub added: u32,
    /// Records already known from an earlier import.
    pub skipped: u32,
    pub contacts_added: u32,
}

/// Progress of a scan or refresh, forwarded from epic-wallet's `StatusMessage`.
#[derive(Debug, Clone)]
pub struct ScanProgress {
    /// 0..=100, or `None` for messages that carry no percentage.
    pub percent: Option<u8>,
    pub message: String,
    pub finished: bool,
}

/// A transaction slate travelling between two wallets as JSON.
#[derive(Debug, Clone)]
pub struct Slate {
    pub slate_id: String,
    pub json: String,
}

/// What a slate file asks this wallet to do.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SlateStage {
    /// Someone sends to us: sign it with `receive_slate` and return the response.
    Send,
    /// The recipient's answer to one of our sends: `finalize_and_post` it.
    Response,
    /// A payment request (invoice). Not supported.
    Invoice,
}

/// A slate's header, read without touching the wallet.
#[derive(Debug, Clone)]
pub struct SlateInfo {
    pub slate_id: String,
    pub amount: u64,
    pub fee: u64,
    pub stage: SlateStage,
}

/// `amount` is the amount to send, as requested; `fee` comes on top of it.
#[derive(Debug, Clone)]
pub struct FeeEstimate {
    pub amount: u64,
    pub fee: u64,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WalletErrorKind {
    InvalidMnemonic,
    WrongPassword,
    WalletAlreadyExists,
    WalletNotFound,
    NodeUnreachable,
    NotEnoughFunds,
    InvalidSlate,
    InvalidArgument,
    /// The epicbox relay or the recipient's HTTP listener could not be reached, or refused.
    TransportFailed,
    /// A wallet is still open on another network, or a call on this wallet is still running
    /// (network switch, delete). Waiting a moment and trying again usually works.
    ChainBusy,
    Io,
    Other,
}

/// What the epicbox listener did.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ListenerEventKind {
    /// Subscribed at the relay; `message` is the address it listens on.
    Connected,
    /// The connection dropped or could not be made; it retries with backoff.
    Disconnected,
    /// Signed an incoming send and returned it to the sender.
    Received,
    /// Finalized and posted one of our sends.
    Finalized,
    /// A slate could not be handled, or the relay reported an error.
    Error,
    /// The listener ended; no more events follow.
    Stopped,
}

#[derive(Debug, Clone)]
pub struct ListenerEvent {
    pub kind: ListenerEventKind,
    pub slate_id: Option<String>,
    pub message: String,
    /// For `Received` and `Finalized`: the slate's amount (what arrived, or what we sent),
    /// in the smallest unit. `None` for every other kind.
    pub amount: Option<u64>,
}

/// The single error type every API call returns. Dart receives it as a thrown exception.
#[derive(Debug, Clone, thiserror::Error)]
#[error("{kind:?}: {message}")]
pub struct WalletError {
    pub kind: WalletErrorKind,
    pub message: String,
}
