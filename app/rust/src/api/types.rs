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

/// One entry of the wallet's transaction log (`TxLogEntry`).
#[derive(Debug, Clone)]
pub struct TxEntry {
    /// Local log id, used for cancel.
    pub id: u32,
    pub slate_id: Option<String>,
    pub kind: TxKind,
    pub created_at_unix: i64,
    pub confirmed: bool,
    pub amount_credited: u64,
    pub amount_debited: u64,
    pub fee: Option<u64>,
    pub num_inputs: u32,
    pub num_outputs: u32,
    pub kernel_excess: Option<String>,
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
}

/// The single error type every API call returns. Dart receives it as a thrown exception.
#[derive(Debug, Clone, thiserror::Error)]
#[error("{kind:?}: {message}")]
pub struct WalletError {
    pub kind: WalletErrorKind,
    pub message: String,
}
