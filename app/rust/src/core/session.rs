//! An open wallet: the epic-wallet instance plus its keychain mask.
//!
//! The mask is the random value the in-memory master key is XORed with while the wallet is open.
//! It is created by `open_wallet`, passed by reference into every epic-wallet call, and never
//! leaves this module. `SecretKey` zeroizes itself on drop, and `Drop for Session` closes the
//! backend (which drops the keychain) before the mask goes.
//!
//! Every method is blocking. epic-wallet's HTTP node client runs requests with `block_on` on its
//! own global tokio runtime and panics if called from inside another runtime.

use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::mpsc;
use std::sync::Arc;

use epic_wallet_api::{Foreign, Owner};
use epic_wallet_config::EpicboxConfig;
use epic_wallet_impls::{DefaultLCProvider, DefaultWalletImpl, HTTPNodeClient, HttpSlateSender, SlateSender};
use epic_wallet_libwallet::{
    Error as LibWalletError, Slate as LibSlate, InitTxArgs, NodeClient, StatusMessage, TxLogEntry, TxLogEntryType,
    WalletInitStatus, WalletInst,
};
use epic_wallet_util::epic_keychain::ExtKeychain;
use epic_wallet_util::epic_util::secp::key::SecretKey;
use epic_wallet_util::epic_util::{to_hex, Mutex, ZeroingString};

use super::chain::ChainLease;
use super::epicbox::{self, Identity, Listener};
use super::error::{CoreError, CoreResult};
use super::node::EpicNodeClient;
use super::{mnemonic, slate};
use crate::api::types::{
    FeeEstimate, ListenerEvent, NodeTip, ScanProgress, Slate, TxEntry, TxKind, WalletConfig,
    WalletSummary,
};

type Provider = DefaultLCProvider<'static, EpicNodeClient, ExtKeychain>;
type Instance = dyn WalletInst<'static, Provider, EpicNodeClient, ExtKeychain>;
pub(crate) type WalletHandle = Arc<Mutex<Box<Instance>>>;
pub(crate) type OwnerApi = Owner<Provider, EpicNodeClient, ExtKeychain>;

/// Seed length in bytes for a wallet created without a phrase: 24 words.
const NEW_SEED_BYTES: usize = 32;

fn node_client(config: &WalletConfig) -> CoreResult<HTTPNodeClient> {
    if config.node_url.trim().is_empty() {
        return Err(CoreError::InvalidArgument("node_url is empty".into()));
    }
    let url = config.node_url.trim().trim_end_matches('/');
    Ok(HTTPNodeClient::new(url, config.node_api_secret.clone())?)
}

fn wallet_handle(config: &WalletConfig) -> CoreResult<(WalletHandle, Arc<AtomicU64>)> {
    if config.data_dir.trim().is_empty() {
        return Err(CoreError::InvalidArgument("data_dir is empty".into()));
    }
    let client = EpicNodeClient::new(node_client(config)?);
    let highest_tip = client.highest_tip();
    let wallet_impl = DefaultWalletImpl::<'static, EpicNodeClient>::new(client)
        .map_err(|e| LibWalletError::GenericError(e.to_string()))?;
    let mut wallet: Box<Instance> = Box::new(wallet_impl);
    wallet
        .lc_provider()?
        .set_top_level_directory(&config.data_dir)?;
    Ok((Arc::new(Mutex::new(wallet)), highest_tip))
}

/// True when `config.data_dir` holds a wallet seed.
pub(crate) fn wallet_exists(config: &WalletConfig) -> CoreResult<bool> {
    let (wallet, _) = wallet_handle(config)?;
    let mut w = wallet.lock();
    Ok(w.lc_provider()?.wallet_exists(None)?)
}

/// Tip of the configured node. Needs no wallet and no chain selection.
pub(crate) fn node_tip(config: &WalletConfig) -> CoreResult<NodeTip> {
    let mut client = node_client(config)?;
    let (height, _hash) = client.get_chain_tip()?;
    let node_version = client
        .get_version_info()
        .map(|v| v.node_version)
        .unwrap_or_else(|| "unknown".into());
    Ok(NodeTip {
        height,
        node_version,
    })
}

pub(crate) struct Session {
    wallet: WalletHandle,
    mask: Option<SecretKey>,
    owner: Arc<OwnerApi>,
    config: WalletConfig,
    identity: Identity,
    listener: std::sync::Mutex<Option<Listener>>,
    _chain: ChainLease,
}

impl Session {
    /// Creates a wallet in `config.data_dir`, restoring `mnemonic` if given, and opens it.
    pub(crate) fn create(
        config: &WalletConfig,
        mnemonic: Option<String>,
        password: ZeroingString,
    ) -> CoreResult<Session> {
        let lease = ChainLease::acquire(config.chain)?;
        let phrase = match mnemonic {
            Some(p) => {
                let p = mnemonic::normalize(p);
                if !mnemonic::is_valid(&p) {
                    return Err(CoreError::InvalidMnemonic);
                }
                Some(p)
            }
            None => None,
        };
        let (wallet, highest_tip) = wallet_handle(config)?;
        {
            let mut w = wallet.lock();
            let lc = w.lc_provider()?;
            if lc.wallet_exists(None)? {
                return Err(CoreError::WalletExists(config.data_dir.clone()));
            }
            // create_wallet ignores a failure to write the seed file, so check that it exists after.
            lc.create_wallet(None, phrase, NEW_SEED_BYTES, password.clone(), false)?;
            if !lc.wallet_exists(None)? {
                return Err(CoreError::InvalidArgument(format!(
                    "could not write the wallet seed in {}",
                    config.data_dir
                )));
            }
        }
        Self::open_handle(config, wallet, highest_tip, password, lease)
    }

    /// Opens the wallet in `config.data_dir`.
    pub(crate) fn open(config: &WalletConfig, password: ZeroingString) -> CoreResult<Session> {
        let lease = ChainLease::acquire(config.chain)?;
        let (wallet, highest_tip) = wallet_handle(config)?;
        {
            let mut w = wallet.lock();
            if !w.lc_provider()?.wallet_exists(None)? {
                return Err(CoreError::WalletNotFound(config.data_dir.clone()));
            }
        }
        Self::open_handle(config, wallet, highest_tip, password, lease)
    }

    fn open_handle(
        config: &WalletConfig,
        wallet: WalletHandle,
        highest_tip: Arc<AtomicU64>,
        password: ZeroingString,
        lease: ChainLease,
    ) -> CoreResult<Session> {
        let mask = {
            let mut w = wallet.lock();
            let lc = w.lc_provider()?;
            // The seed file exists (checked by the callers), so a decryption failure is the password.
            let mask = lc
                .open_wallet(None, password, true, false)
                .map_err(|_| CoreError::WrongPassword)?;
            // The node-sync fallback refuses tips below what this wallet has already confirmed.
            let confirmed = lc.wallet_inst()?.last_confirmed_height()?;
            highest_tip.fetch_max(confirmed, Ordering::Relaxed);
            mask
        };
        let owner = Owner::new(wallet.clone(), None, Arc::new(AtomicBool::new(true)));
        let epicbox = EpicboxConfig {
            epicbox_domain: Some(config.epicbox_domain.clone()),
            epicbox_port: Some(config.epicbox_port),
            ..EpicboxConfig::default()
        };
        owner.set_epicbox_config(Some(epicbox));
        let identity = Identity::derive(&wallet, mask.as_ref(), config)?;
        Ok(Session {
            wallet,
            mask,
            owner: Arc::new(owner),
            config: config.clone(),
            identity,
            listener: std::sync::Mutex::new(None),
            _chain: lease,
        })
    }

    fn mask(&self) -> Option<&SecretKey> {
        self.mask.as_ref()
    }

    /// Recovery phrase, re-checked against `password`.
    pub(crate) fn mnemonic(&self, password: ZeroingString) -> CoreResult<String> {
        let mut w = self.wallet.lock();
        let phrase = w
            .lc_provider()?
            .get_mnemonic(None, password)
            .map_err(|_| CoreError::WrongPassword)?;
        Ok(phrase.to_string())
    }

    pub(crate) fn summary(
        &self,
        refresh: bool,
        minimum_confirmations: u64,
    ) -> CoreResult<WalletSummary> {
        let (validated, info) =
            self.owner
                .retrieve_summary_info(self.mask(), refresh, minimum_confirmations)?;
        Ok(WalletSummary {
            last_confirmed_height: info.last_confirmed_height,
            minimum_confirmations: info.minimum_confirmations,
            total: info.total,
            spendable: info.amount_currently_spendable,
            awaiting_confirmation: info.amount_awaiting_confirmation,
            awaiting_finalization: info.amount_awaiting_finalization,
            immature: info.amount_immature,
            locked: info.amount_locked,
            validated_with_node: validated,
        })
    }

    /// Where `scan` starts when the caller gives no height: 1 for a restored wallet that was never
    /// scanned, otherwise the last block the wallet scanned.
    fn default_scan_start(&self) -> CoreResult<u64> {
        let mut guard = self.wallet.lock();
        let w = guard.lc_provider()?.wallet_inst()?;
        let height = match w.init_status()? {
            WalletInitStatus::InitNeedsScanning => 1,
            _ => w.last_scanned_block()?.height,
        };
        Ok(height.max(1))
    }

    /// Rescans from `start_height`, calling `on_progress` for every status message and once more
    /// with `finished: true` at the end, whether the scan succeeded or not.
    pub(crate) fn scan<F>(&self, start_height: Option<u64>, mut on_progress: F) -> CoreResult<()>
    where
        F: FnMut(ScanProgress) + Send,
    {
        let result = self.scan_inner(start_height, &mut on_progress);
        let last = match &result {
            Ok(()) => ScanProgress {
                percent: Some(100),
                message: "Scan complete".into(),
                finished: true,
            },
            Err(e) => ScanProgress {
                percent: None,
                message: format!("Scan failed: {e}"),
                finished: true,
            },
        };
        on_progress(last);
        result
    }

    fn scan_inner<F>(&self, start_height: Option<u64>, on_progress: &mut F) -> CoreResult<()>
    where
        F: FnMut(ScanProgress) + Send,
    {
        let start = match start_height {
            Some(h) => h.max(1),
            None => self.default_scan_start()?,
        };
        let (tx, rx) = mpsc::channel::<StatusMessage>();
        std::thread::scope(|scope| {
            // Ends when the scan Owner, which holds the only sender, is dropped below.
            scope.spawn(move || {
                for message in rx {
                    on_progress(progress_from(message));
                }
            });
            let owner = Owner::new(
                self.wallet.clone(),
                Some(tx),
                Arc::new(AtomicBool::new(true)),
            );
            let result = owner.scan(self.mask(), Some(start), false);
            drop(owner);
            result
        })?;
        // Owner::scan records the scanned block but leaves a restored wallet flagged as needing a
        // full scan, which would make the next refresh repeat it.
        let mut guard = self.wallet.lock();
        let w = guard.lc_provider()?.wallet_inst()?;
        let mut batch = w.batch(self.mask.as_ref())?;
        batch.save_init_status(WalletInitStatus::InitComplete)?;
        batch.commit()?;
        Ok(())
    }

    /// Transaction log, newest first.
    pub(crate) fn transactions(&self, refresh: bool) -> CoreResult<Vec<TxEntry>> {
        let res = self
            .owner
            .retrieve_txs(self.mask(), refresh, None, None, None, None, None)?;
        let mut txs = res.txs;
        txs.sort_by(|a, b| {
            b.creation_ts
                .cmp(&a.creation_ts)
                .then_with(|| b.id.cmp(&a.id))
        });
        Ok(txs.iter().map(tx_entry).collect())
    }

    /// `<pubkey>@<domain>[:port]`, from the key epic-wallet's epicbox adapter uses.
    pub(crate) fn epicbox_address(&self) -> CoreResult<String> {
        let address = self
            .owner
            .get_public_address(self.mask(), epicbox::ADDRESS_INDEX)?;
        Ok(address.to_string())
    }

    fn send_args(amount: u64, minimum_confirmations: u64, estimate_only: bool) -> InitTxArgs {
        InitTxArgs {
            amount,
            minimum_confirmations,
            selection_strategy_is_use_all: false,
            estimate_only: Some(estimate_only),
            ..InitTxArgs::default()
        }
    }

    pub(crate) fn estimate_fee(
        &self,
        amount: u64,
        minimum_confirmations: u64,
    ) -> CoreResult<FeeEstimate> {
        if amount == 0 {
            return Err(CoreError::InvalidArgument(
                "amount must be above zero".into(),
            ));
        }
        let s = self.owner.init_send_tx(
            self.mask(),
            Self::send_args(amount, minimum_confirmations, true),
            Arc::new(AtomicBool::new(true)),
        )?;
        // In estimate-only mode epic-wallet puts the selected inputs' total in `slate.amount`.
        Ok(FeeEstimate { amount, fee: s.fee })
    }

    /// `init_send_tx` then `tx_lock_outputs`, the CLI's `send` sequence up to the transport.
    fn init_and_lock(
        &self,
        amount: u64,
        minimum_confirmations: u64,
        dest: Option<String>,
    ) -> CoreResult<LibSlate> {
        if amount == 0 {
            return Err(CoreError::InvalidArgument(
                "amount must be above zero".into(),
            ));
        }
        let s = self.owner.init_send_tx(
            self.mask(),
            Self::send_args(amount, minimum_confirmations, false),
            Arc::new(AtomicBool::new(true)),
        )?;
        self.owner.tx_lock_outputs(self.mask(), &s, 0, dest)?;
        Ok(s)
    }

    /// Unlocks the outputs of a send whose transport failed, so a failed send leaves no trace.
    fn abandon(&self, s: &LibSlate) {
        if let Err(e) = self.owner.cancel_tx(self.mask(), None, Some(s.id)) {
            log::warn!("cancelling failed send {}: {e}", s.id);
        }
    }

    /// Step 1 of a manual (file/JSON) send.
    pub(crate) fn create_send_slate(
        &self,
        amount: u64,
        minimum_confirmations: u64,
    ) -> CoreResult<Slate> {
        let s = self.init_and_lock(amount, minimum_confirmations, None)?;
        Ok(Slate {
            slate_id: s.id.to_string(),
            json: slate::to_json(&s)?,
        })
    }

    /// Sends to a wallet listening on HTTP (`epic-wallet listen`): the recipient signs in the same
    /// request, then we finalize and post. On any failure before the post the outputs are unlocked.
    pub(crate) fn send_http(
        &self,
        amount: u64,
        minimum_confirmations: u64,
        url: &str,
    ) -> CoreResult<TxEntry> {
        let base = http_base_url(url)?;
        let sender = HttpSlateSender::new(&base, Arc::new(AtomicBool::new(true)))
            .map_err(|_| CoreError::InvalidArgument("the address must start with http:// or https://".into()))?;
        let s = self.init_and_lock(amount, minimum_confirmations, Some(base.clone()))?;
        let response = match sender.send_tx(&s) {
            Ok(r) => r,
            Err(e) => {
                self.abandon(&s);
                return Err(CoreError::Relay(format!(
                    "the recipient at {base} did not answer: {e}"
                )));
            }
        };
        match self.finalize_slate(&response) {
            Ok(entry) => Ok(entry),
            Err(e) => {
                self.abandon(&s);
                Err(e)
            }
        }
    }

    /// Posts a send to an epicbox address. The transaction stays unconfirmed and locked until the
    /// recipient's response arrives through the listener, which then finalizes and posts it.
    pub(crate) fn send_epicbox(
        &self,
        amount: u64,
        minimum_confirmations: u64,
        address: &str,
    ) -> CoreResult<TxEntry> {
        let to = epicbox::parse_address(address)?;
        if to.public_key == self.identity.address.public_key {
            return Err(CoreError::InvalidArgument("that is this wallet's own address".into()));
        }
        let s = self.init_and_lock(amount, minimum_confirmations, Some(to.to_string()))?;
        if let Err(e) = epicbox::post_once(&self.config, &self.identity, &to, &s) {
            self.abandon(&s);
            return Err(e);
        }
        self.tx_for_slate(s.id)
    }

    /// Starts the epicbox listener, or does nothing if it runs. `on_event` is called from the
    /// listener thread.
    pub(crate) fn start_listener<F>(&self, on_event: F)
    where
        F: FnMut(ListenerEvent) + Send + 'static,
    {
        let mut slot = self.listener.lock().unwrap_or_else(|p| p.into_inner());
        if slot.as_ref().is_some_and(|l| l.is_running()) {
            return;
        }
        *slot = Some(Listener::start(
            self.config.clone(),
            self.identity.clone(),
            self.wallet.clone(),
            self.mask.clone(),
            self.owner.clone(),
            on_event,
        ));
    }

    /// Stops the listener and waits for it, at most about a second.
    pub(crate) fn stop_listener(&self) {
        let listener = self.listener.lock().unwrap_or_else(|p| p.into_inner()).take();
        drop(listener);
    }

    pub(crate) fn listener_running(&self) -> bool {
        self.listener
            .lock()
            .unwrap_or_else(|p| p.into_inner())
            .as_ref()
            .is_some_and(|l| l.is_running())
    }

    fn tx_for_slate(&self, id: uuid::Uuid) -> CoreResult<TxEntry> {
        let res = self
            .owner
            .retrieve_txs(self.mask(), false, None, Some(id), None, None, None)?;
        res.txs
            .iter()
            .find(|t| {
                matches!(
                    t.tx_type,
                    TxLogEntryType::TxSent
                        | TxLogEntryType::TxSentMempool
                        | TxLogEntryType::TxSentCreated
                )
            })
            .or_else(|| res.txs.first())
            .map(tx_entry)
            .ok_or_else(|| {
                CoreError::InvalidSlate(format!("no transaction log entry for slate {id}"))
            })
    }

    /// The CLI's `receive` sequence: verify messages, `Foreign::receive_tx`.
    pub(crate) fn receive_slate(&self, slate_json: &str) -> CoreResult<Slate> {
        let incoming = slate::from_json(slate_json)?;
        let foreign = Foreign::new(self.wallet.clone(), self.mask.clone(), None);
        foreign
            .verify_slate_messages(&incoming)
            .map_err(|e| CoreError::InvalidSlate(e.to_string()))?;
        let response = foreign.receive_tx(&incoming, None, None, None)?;
        Ok(Slate {
            slate_id: response.id.to_string(),
            json: slate::to_json(&response)?,
        })
    }

    /// The CLI's `finalize` sequence for a send: verify messages, `finalize_tx`, `post_tx`.
    /// Posts with fluff, skipping Dandelion's stem phase, as flutter_libepiccash does.
    pub(crate) fn finalize_and_post(&self, slate_json: &str) -> CoreResult<TxEntry> {
        self.finalize_slate(&slate::from_json(slate_json)?)
    }

    fn finalize_slate(&self, response: &LibSlate) -> CoreResult<TxEntry> {
        self.owner
            .verify_slate_messages(self.mask(), response)
            .map_err(|e| CoreError::InvalidSlate(e.to_string()))?;
        let finalized = self.owner.finalize_tx(self.mask(), response)?;
        self.owner.post_tx(self.mask(), &finalized.tx, true)?;
        self.tx_for_slate(finalized.id)
    }

    pub(crate) fn cancel_transaction(&self, tx_id: u32) -> CoreResult<()> {
        self.owner.cancel_tx(self.mask(), Some(tx_id), None)?;
        Ok(())
    }
}

impl Drop for Session {
    fn drop(&mut self) {
        // The listener uses the wallet and the mask, so it goes first.
        self.stop_listener();
        {
            let mut w = self.wallet.lock();
            if let Ok(lc) = w.lc_provider() {
                if let Err(e) = lc.close_wallet(None) {
                    log::warn!("closing wallet: {e}");
                }
            }
        }
        // SecretKey zeroizes itself on drop; take it explicitly so it goes before anything else.
        drop(self.mask.take());
    }
}

/// The base URL `HttpSlateSender` wants: scheme and host, without the `/v2/foreign` it appends.
fn http_base_url(url: &str) -> CoreResult<String> {
    let url = url.trim().trim_end_matches('/');
    let base = url.strip_suffix("/v2/foreign").unwrap_or(url);
    let rest = base
        .strip_prefix("http://")
        .or_else(|| base.strip_prefix("https://"))
        .ok_or_else(|| {
            CoreError::InvalidArgument("the address must start with http:// or https://".into())
        })?;
    if rest.is_empty() || rest.contains(char::is_whitespace) {
        return Err(CoreError::InvalidArgument("the address has no host".into()));
    }
    Ok(base.to_owned())
}

fn progress_from(message: StatusMessage) -> ScanProgress {
    let (percent, message) = match message {
        StatusMessage::Scanning(s, pct) => (Some(pct.min(100)), s),
        StatusMessage::ScanningComplete(s) => (Some(100), s),
        StatusMessage::UpdatingOutputs(s)
        | StatusMessage::UpdatingTransactions(s)
        | StatusMessage::FullScanWarn(s)
        | StatusMessage::UpdateWarning(s) => (None, s),
    };
    ScanProgress {
        percent,
        message,
        finished: false,
    }
}

fn tx_entry(t: &TxLogEntry) -> TxEntry {
    let kind = match t.tx_type {
        TxLogEntryType::ConfirmedCoinbase => TxKind::Coinbase,
        TxLogEntryType::TxReceived | TxLogEntryType::TxReceivedMempool => TxKind::Received,
        TxLogEntryType::TxSent | TxLogEntryType::TxSentMempool | TxLogEntryType::TxSentCreated => {
            TxKind::Sent
        }
        TxLogEntryType::TxReceivedCancelled => TxKind::ReceivedCancelled,
        TxLogEntryType::TxSentCancelled => TxKind::SentCancelled,
    };
    TxEntry {
        id: t.id,
        slate_id: t.tx_slate_id.map(|u| u.to_string()),
        kind,
        created_at_unix: t.creation_ts.timestamp(),
        confirmed: t.confirmed,
        amount_credited: t.amount_credited,
        amount_debited: t.amount_debited,
        fee: t.fee,
        num_inputs: u32::try_from(t.num_inputs).unwrap_or(u32::MAX),
        num_outputs: u32::try_from(t.num_outputs).unwrap_or(u32::MAX),
        kernel_excess: t.kernel_excess.map(|c| to_hex(c.0.to_vec())),
    }
}

#[cfg(test)]
mod tests {
    use super::http_base_url;

    #[test]
    fn http_base_url_strips_the_api_path() {
        assert_eq!(http_base_url("http://1.2.3.4:3415").unwrap(), "http://1.2.3.4:3415");
        assert_eq!(
            http_base_url(" https://w.example/v2/foreign/ ").unwrap(),
            "https://w.example"
        );
        assert!(http_base_url("1.2.3.4:3415").is_err());
        assert!(http_base_url("http://").is_err());
    }
}
