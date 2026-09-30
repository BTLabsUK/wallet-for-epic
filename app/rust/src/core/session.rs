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
use epic_wallet_impls::{
    DefaultLCProvider, DefaultWalletImpl, HTTPNodeClient, HttpSlateSender, SlateSender,
};
use epic_wallet_libwallet::{
    Error as LibWalletError, InitTxArgs, NodeClient, Slate as LibSlate, StatusMessage, TxLogEntry,
    TxLogEntryType, WalletInitStatus, WalletInst,
};
use epic_wallet_util::epic_core::core::amount_to_hr_string;
use epic_wallet_util::epic_core::libtx::tx_fee;
use epic_wallet_util::epic_keychain::{ExtKeychain, Keychain, SwitchCommitmentType};
use epic_wallet_util::epic_util::secp::key::SecretKey;
use epic_wallet_util::epic_util::secp::pedersen;
use epic_wallet_util::epic_util::{Mutex, ZeroingString};
use zeroize::Zeroizing;

use super::chain::ChainLease;
use super::dirlock::DirLease;
use super::epicbox::{self, Identity, Listener};
use super::error::{CoreError, CoreResult};
use super::history::{self, LiveTx, MergedTx};
use super::meta::{ContactRec, MetaStore};
use super::node::EpicNodeClient;
use super::{export, mnemonic, slate, stored_tx};
use crate::api::types::{
    Contact, FeeEstimate, ImportReport, ListenerEvent, NodeTip, ScanProgress, Slate, TxEntry,
    TxKind, TxSource, TxStatus, WalletConfig, WalletSummary,
};

type Provider = DefaultLCProvider<'static, EpicNodeClient, ExtKeychain>;
type Instance = dyn WalletInst<'static, Provider, EpicNodeClient, ExtKeychain>;
pub(crate) type WalletHandle = Arc<Mutex<Box<Instance>>>;
pub(crate) type OwnerApi = Owner<Provider, EpicNodeClient, ExtKeychain>;

/// Seed length in bytes for a wallet created without a phrase: 24 words.
const NEW_SEED_BYTES: usize = 32;
/// TTL of every send, in blocks: 14 days of one-minute blocks. The default mailbox keeps a slate
/// 7 days, and the recipient's answer can wait up to 7 more in ours.
pub(crate) const SEND_TTL_BLOCKS: u64 = 20_160;
/// Node calls one `enrich_history` may spend on block heights and times. floo-node answers 429 to bursts
/// of about ten, so a restored wallet with many rows fills in over several refreshes.
const LOOKUPS_PER_REFRESH: usize = 25;

fn now_unix() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0)
}

fn node_client(config: &WalletConfig) -> CoreResult<HTTPNodeClient> {
    if config.node_url.trim().is_empty() {
        return Err(CoreError::InvalidArgument("node_url is empty".into()));
    }
    let url = config.node_url.trim().trim_end_matches('/');
    Ok(HTTPNodeClient::new(url, config.node_api_secret.clone())?)
}

/// The wallet and a clone of its node client (clones share the height floor).
fn wallet_handle(config: &WalletConfig) -> CoreResult<(WalletHandle, EpicNodeClient)> {
    if config.data_dir.trim().is_empty() {
        return Err(CoreError::InvalidArgument("data_dir is empty".into()));
    }
    let client = EpicNodeClient::new(node_client(config)?);
    let node = client.clone();
    let wallet_impl = DefaultWalletImpl::<'static, EpicNodeClient>::new(client)
        .map_err(|e| LibWalletError::GenericError(e.to_string()))?;
    let mut wallet: Box<Instance> = Box::new(wallet_impl);
    wallet
        .lc_provider()?
        .set_top_level_directory(&config.data_dir)?;
    Ok((Arc::new(Mutex::new(wallet)), node))
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
    meta: Arc<MetaStore>,
    /// For block times and kernel heights; the wallet has its own clone.
    node: EpicNodeClient,
    listener: std::sync::Mutex<Option<Listener>>,
    send_ttl_blocks: AtomicU64,
    _chain: ChainLease,
    /// Last field, so it is released after everything else: a delete waits for it.
    _dir: DirLease,
}

impl Session {
    /// Creates a wallet in `config.data_dir`, restoring `mnemonic` if given, and opens it.
    pub(crate) fn create(
        config: &WalletConfig,
        mnemonic: Option<String>,
        password: ZeroingString,
    ) -> CoreResult<Session> {
        let lease = (
            DirLease::acquire(&config.data_dir)?,
            ChainLease::acquire(config.chain)?,
        );
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
        let (wallet, node) = wallet_handle(config)?;
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
        Self::open_handle(config, wallet, node, password, lease)
    }

    /// Opens the wallet in `config.data_dir`.
    pub(crate) fn open(config: &WalletConfig, password: ZeroingString) -> CoreResult<Session> {
        let lease = (
            DirLease::acquire(&config.data_dir)?,
            ChainLease::acquire(config.chain)?,
        );
        let (wallet, node) = wallet_handle(config)?;
        {
            let mut w = wallet.lock();
            if !w.lc_provider()?.wallet_exists(None)? {
                return Err(CoreError::WalletNotFound(config.data_dir.clone()));
            }
        }
        Self::open_handle(config, wallet, node, password, lease)
    }

    fn open_handle(
        config: &WalletConfig,
        wallet: WalletHandle,
        node: EpicNodeClient,
        password: ZeroingString,
        (dir, lease): (DirLease, ChainLease),
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
            node.highest_tip().fetch_max(confirmed, Ordering::Relaxed);
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
        let meta = Arc::new(MetaStore::open(&config.data_dir)?);
        Ok(Session {
            wallet,
            mask,
            owner: Arc::new(owner),
            config: config.clone(),
            identity,
            meta,
            node,
            listener: std::sync::Mutex::new(None),
            send_ttl_blocks: AtomicU64::new(SEND_TTL_BLOCKS),
            _chain: lease,
            _dir: dir,
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

    /// epic-wallet's log for the current account, with what the outputs say about each row.
    fn live_rows(&self, refresh: bool) -> CoreResult<Vec<LiveTx>> {
        let res = self
            .owner
            .retrieve_txs(self.mask(), refresh, None, None, None, None, None)?;
        let mut guard = self.wallet.lock();
        let w = guard.lc_provider()?.wallet_inst()?;
        let current: Vec<_> = w.iter().collect();
        let history_rows: Vec<_> = w.history_iter().collect();
        Ok(history::live_rows(
            res.txs,
            &current,
            &history_rows,
            |entry| stored_final(&self.config.data_dir, entry),
        ))
    }

    fn merged(&self, refresh: bool) -> CoreResult<Vec<MergedTx>> {
        let live = self.live_rows(refresh)?;
        Ok(history::merge(&live, &self.meta.snapshot()))
    }

    /// Live log merged with the history archive, newest first. With `refresh` the outputs are
    /// updated from the node first. Block heights and times come from `enrich_history`.
    pub(crate) fn transactions(&self, refresh: bool) -> CoreResult<Vec<TxEntry>> {
        Ok(self.merged(refresh)?.into_iter().map(|m| m.tx).collect())
    }

    /// Fetches missing block heights, block times and verdicts for imported pending records, at
    /// most `LOOKUPS_PER_REFRESH` node calls, without refreshing outputs. Returns how many rows
    /// changed, so the caller reloads the list only when something did.
    pub(crate) fn enrich_history(&self) -> CoreResult<u32> {
        let live = self.live_rows(false)?;
        let before = history::merge(&live, &self.meta.snapshot());
        self.enrich(&before);
        let after = history::merge(&live, &self.meta.snapshot());
        Ok(history::changed_rows(&before, &after))
    }

    /// Sets or clears the note of the transaction with `key`. The note replaces any note the
    /// transaction had under another of its keys.
    pub(crate) fn set_tx_note(&self, key: &str, note: Option<String>) -> CoreResult<()> {
        let note = note.map(|n| n.trim().to_owned()).filter(|n| !n.is_empty());
        let rows = self.merged(false)?;
        let shared = history::shared_aliases(&rows);
        // Only aliases this row alone carries: the other side of a self-send keeps its note.
        let aliases: Vec<String> = rows
            .into_iter()
            .find(|m| m.tx.key == key)
            .map(|m| m.aliases)
            .unwrap_or_else(|| vec![key.to_owned()])
            .into_iter()
            .filter(|a| a == key || !shared.contains(a))
            .collect();
        self.meta.update(|m| {
            for a in &aliases {
                m.notes.remove(a);
            }
            if let Some(n) = note {
                m.notes.insert(key.to_owned(), n);
            }
            Ok(())
        })
    }

    pub(crate) fn contacts(&self) -> Vec<Contact> {
        let mut list: Vec<Contact> = self
            .meta
            .snapshot()
            .contacts
            .into_iter()
            .map(contact_to_api)
            .collect();
        list.sort_by_key(|c| c.name.to_lowercase());
        list
    }

    /// Adds (empty `id`) or replaces a contact.
    pub(crate) fn save_contact(&self, contact: Contact) -> CoreResult<Contact> {
        let name = contact.name.trim().to_owned();
        let address = contact.address.trim().to_owned();
        if name.is_empty() {
            return Err(CoreError::InvalidArgument(
                "the contact needs a name".into(),
            ));
        }
        if address.is_empty() {
            return Err(CoreError::InvalidArgument(
                "the contact needs an address".into(),
            ));
        }
        let rec = ContactRec {
            id: if contact.id.trim().is_empty() {
                super::vault::random_hex::<16>()?
            } else {
                contact.id.trim().to_owned()
            },
            name,
            address,
            note: contact
                .note
                .map(|n| n.trim().to_owned())
                .filter(|n| !n.is_empty()),
        };
        self.meta.update(|m| {
            match m.contacts.iter_mut().find(|c| c.id == rec.id) {
                Some(existing) => *existing = rec.clone(),
                None if contact.id.trim().is_empty() => m.contacts.push(rec.clone()),
                None => {
                    return Err(CoreError::InvalidArgument(format!(
                        "no contact with id {}",
                        rec.id
                    )))
                }
            }
            Ok(())
        })?;
        Ok(contact_to_api(rec))
    }

    pub(crate) fn delete_contact(&self, id: &str) -> CoreResult<()> {
        self.meta.update(|m| {
            m.contacts.retain(|c| c.id != id);
            Ok(())
        })
    }

    /// The wallet's root secret (`derive_key(0, root_key_id)`), for the history file key. It
    /// stays in Rust and is zeroized on drop.
    fn root_secret(&self) -> CoreResult<Zeroizing<[u8; 32]>> {
        let mut guard = self.wallet.lock();
        let w = guard.lc_provider()?.wallet_inst()?;
        let keychain = w.keychain(self.mask())?;
        let key = keychain
            .derive_key(
                0,
                &ExtKeychain::root_key_id(),
                &SwitchCommitmentType::Regular,
            )
            .map_err(|e| CoreError::InvalidArgument(format!("root key: {e}")))?;
        let mut out = Zeroizing::new([0u8; 32]);
        out.copy_from_slice(&key.0);
        Ok(out)
    }

    /// Public fingerprint of this wallet's seed: SHA-256 of its epicbox key, first 16 bytes.
    fn wallet_fp(&self) -> String {
        let digest = ring::digest::digest(
            &ring::digest::SHA256,
            self.identity.address.public_key.as_bytes(),
        );
        hex::encode(&digest.as_ref()[..16])
    }

    fn chain_name(&self) -> String {
        format!("{:?}", self.config.chain)
    }

    /// The history as an encrypted `WFEH` file (see `core/export.rs`).
    pub(crate) fn export_history(&self) -> CoreResult<Vec<u8>> {
        let merged = self.merged(false)?;
        let meta = self.meta.snapshot();
        let last_confirmed_height = {
            let mut guard = self.wallet.lock();
            guard
                .lc_provider()?
                .wallet_inst()?
                .last_confirmed_height()
                .ok()
        };
        // A rebuilt row with nothing added by the user comes back by itself after a restore.
        let txs = merged
            .iter()
            .filter(|m| !(m.tx.source == TxSource::Restored && m.tx.note.is_none()))
            .map(history::to_record)
            .collect();
        let payload = export::Payload {
            format: export::FORMAT.into(),
            version: export::PAYLOAD_VERSION,
            chain: self.chain_name(),
            wallet_fp: self.wallet_fp(),
            exported_at_unix: now_unix(),
            app_version: env!("CARGO_PKG_VERSION").into(),
            last_confirmed_height,
            txs,
            contacts: meta.contacts,
        };
        let plain = Zeroizing::new(
            serde_json::to_vec(&payload)
                .map_err(|e| CoreError::InvalidArgument(format!("encoding history: {e}")))?,
        );
        export::seal(&self.root_secret()?[..], &plain)
    }

    pub(crate) fn export_history_csv(&self) -> CoreResult<String> {
        let tip = {
            let mut guard = self.wallet.lock();
            guard
                .lc_provider()?
                .wallet_inst()?
                .last_confirmed_height()
                .ok()
        };
        Ok(export::csv(&self.transactions(false)?, tip))
    }

    /// Merges an export of this wallet. Writes only the app's archive, never epic.db.
    pub(crate) fn import_history(&self, data: &[u8]) -> CoreResult<ImportReport> {
        let payload = export::decode_payload(&self.root_secret()?[..], data)?;
        if payload.chain != self.chain_name() {
            return Err(CoreError::InvalidArgument(format!(
                "This history file is from {}, but this wallet is on {}",
                payload.chain,
                self.chain_name()
            )));
        }
        if payload.wallet_fp != self.wallet_fp() {
            return Err(CoreError::InvalidArgument(export::DIFFERENT_WALLET.into()));
        }
        let shown: Vec<TxEntry> = self.transactions(false)?;
        self.meta.update(|m| {
            let mut report = ImportReport {
                merged: 0,
                added: 0,
                skipped: 0,
                contacts_added: 0,
            };
            for mut r in payload.txs {
                let identified = r.slate_id.is_some()
                    || r.kernel_excess.is_some()
                    || !r.output_commits.is_empty();
                if !identified {
                    report.skipped += 1;
                    continue;
                }
                r.exported_at_unix = Some(payload.exported_at_unix);
                if let Some(existing) = m.records.iter_mut().find(|e| e.same_tx(&r)) {
                    // Known from an earlier import: take what this file adds.
                    if existing.merge_from(&r) {
                        report.merged += 1;
                    } else {
                        report.skipped += 1;
                    }
                    continue;
                }
                let live = shown
                    .iter()
                    .any(|t| t.id.is_some() && history::record_matches(&r, t));
                if live {
                    report.merged += 1;
                } else {
                    report.added += 1;
                }
                m.records.push(r);
            }
            for c in payload.contacts {
                if m.contacts
                    .iter()
                    .any(|e| e.address.trim() == c.address.trim())
                {
                    continue;
                }
                let mut c = c;
                if c.id.is_empty() || m.contacts.iter().any(|e| e.id == c.id) {
                    c.id = super::vault::random_hex::<16>()?;
                }
                m.contacts.push(c);
                report.contacts_added += 1;
            }
            Ok(report)
        })
    }

    /// The largest amount `send_*` can send now, and its fee: every spendable output, no change.
    ///
    /// epic-wallet selects the smallest outputs until they cover amount plus fee, and pays the
    /// no-change fee `tx_fee(inputs, 1, 1)` when inputs equal amount plus fee exactly
    /// (`select_coins_and_fee`, `selection.rs:386-395`). So the maximum is the spendable total
    /// minus that fee. The result is checked with epic-wallet's own estimate before it is returned.
    pub(crate) fn estimate_max(&self, minimum_confirmations: u64) -> CoreResult<FeeEstimate> {
        // Refreshes outputs from the node, as a real send would, and fails early with no funds.
        self.owner.init_send_tx(
            self.mask(),
            InitTxArgs {
                amount: 1,
                minimum_confirmations,
                selection_strategy_is_use_all: true,
                estimate_only: Some(true),
                ..InitTxArgs::default()
            },
            Arc::new(AtomicBool::new(true)),
        )?;
        let (count, total) = {
            let mut guard = self.wallet.lock();
            let w = guard.lc_provider()?.wallet_inst()?;
            let height = w.last_confirmed_height()?;
            let parent = w.parent_key_id();
            w.iter()
                .filter(|o| {
                    o.root_key_id == parent && o.eligible_to_spend(height, minimum_confirmations)
                })
                .fold((0usize, 0u64), |(n, t), o| (n + 1, t + o.value))
        };
        let not_enough = |needed: u64| {
            CoreError::Wallet(LibWalletError::NotEnoughFunds {
                available: total,
                available_disp: amount_to_hr_string(total, false),
                needed,
                needed_disp: amount_to_hr_string(needed, false),
            })
        };
        let mut fee = tx_fee(count, 1, 1, None);
        if total <= fee {
            return Err(not_enough(fee + 1));
        }
        let mut amount = total - fee;
        for _ in 0..3 {
            let s = self.owner.init_send_tx(
                self.mask(),
                self.send_args(amount, minimum_confirmations, true),
                Arc::new(AtomicBool::new(true)),
            )?;
            // In estimate-only mode `s.amount` is the selected inputs' total.
            if s.amount == amount + s.fee {
                return Ok(FeeEstimate { amount, fee: s.fee });
            }
            fee = s.fee;
            if s.amount <= fee {
                return Err(not_enough(fee + 1));
            }
            amount = s.amount - fee;
        }
        Err(CoreError::InvalidArgument(
            "could not settle on a send-all amount; try again after a refresh".into(),
        ))
    }

    /// Fetches missing kernel heights and block times, at most `LOOKUPS_PER_REFRESH` node calls,
    /// and caches them in the archive. Stops at the first refusal (429) or failure; the next
    /// refresh carries on.
    fn enrich(&self, rows: &[MergedTx]) {
        let meta = self.meta.snapshot();
        let mut budget = LOOKUPS_PER_REFRESH;
        let mut kernel_heights = std::collections::BTreeMap::new();
        let mut tip: Option<u64> = None;
        // A wallet waiting to switch chains waits for this session to close; stop early for it.
        let stop = || super::chain::switch_pending();
        for m in rows {
            if budget == 0 || stop() {
                break;
            }
            let (Some(k), Some(min)) = (&m.tx.kernel_excess, m.kernel_lookup_min_height) else {
                continue;
            };
            if !m.tx.confirmed || m.tx.block_height.is_some() || meta.kernel_heights.contains_key(k)
            {
                continue;
            }
            let Ok(bytes) = hex::decode(k) else { continue };
            let max = match tip {
                Some(t) => t,
                None => match self.node.get_chain_tip() {
                    Ok((t, _)) => *tip.insert(t),
                    Err(_) => return,
                },
            };
            budget -= 1;
            let excess = pedersen::Commitment::from_vec(bytes);
            match self.node.kernel_height(&excess, min, max) {
                // 0 marks "not found", so it is not asked again every refresh.
                Ok(h) => {
                    kernel_heights.insert(k.clone(), h.unwrap_or(0));
                }
                Err(_) => break,
            }
        }
        // Finalized sends the node refused: once a day of blocks has passed since finalize, see
        // whether the kernel ever reached the chain. Not found makes the send releasable.
        let mut absent = Vec::new();
        for m in rows {
            if budget == 0 || stop() {
                break;
            }
            let (Some(after), Some(k), Some(slate)) =
                (m.release_check_after, &m.tx.kernel_excess, &m.tx.slate_id)
            else {
                continue;
            };
            let checked = meta
                .annotations
                .get(slate)
                .and_then(|a| a.kernel_absent_at)
                .is_some_and(|t| t >= after);
            if checked {
                continue;
            }
            let Ok(bytes) = hex::decode(k) else { continue };
            let max = match tip {
                Some(t) => t,
                None => match self.node.get_chain_tip() {
                    Ok((t, _)) => *tip.insert(t),
                    Err(_) => break,
                },
            };
            if max < after {
                continue;
            }
            budget -= 1;
            let min = m.kernel_lookup_min_height.unwrap_or(1);
            match self
                .node
                .kernel_height(&pedersen::Commitment::from_vec(bytes), min, max)
            {
                Ok(None) => absent.push((slate.clone(), max)),
                Ok(Some(h)) => {
                    kernel_heights.insert(k.clone(), h);
                }
                Err(_) => break,
            }
        }
        // Imported records still pending at export, with no live row: settle them by kernel.
        let mut settlements = Vec::new();
        for m in rows.iter().filter(|m| history::needs_settling(m)) {
            if budget == 0 || stop() {
                break;
            }
            let (Some(k), Some(min)) = (&m.tx.kernel_excess, m.kernel_lookup_min_height) else {
                continue;
            };
            let Ok(bytes) = hex::decode(k) else { continue };
            let max = match tip {
                Some(t) => t,
                None => match self.node.get_chain_tip() {
                    Ok((t, _)) => *tip.insert(t),
                    Err(_) => break,
                },
            };
            budget -= 1;
            let excess = pedersen::Commitment::from_vec(bytes);
            match self.node.kernel_height(&excess, min, max) {
                Ok(found) => {
                    if let Some(s) = history::settle(found, min, m.tx.ttl_cutoff_height, max) {
                        if let history::Settlement::Confirmed(h) = s {
                            kernel_heights.insert(k.clone(), h);
                        }
                        settlements.push((k.clone(), s));
                    }
                }
                Err(_) => break,
            }
        }
        let mut heights = std::collections::BTreeSet::new();
        for m in rows {
            let h = m.tx.block_height.or_else(|| {
                m.tx.kernel_excess
                    .as_ref()
                    .and_then(|k| kernel_heights.get(k).copied())
                    .filter(|h| *h > 0)
            });
            if let Some(h) = h {
                if m.tx.block_time_unix.is_none() && !meta.block_times.contains_key(&h) {
                    heights.insert(h);
                }
            }
        }
        let mut block_times = std::collections::BTreeMap::new();
        for h in heights {
            if budget == 0 || stop() {
                break;
            }
            budget -= 1;
            match self.node.block_time(h) {
                Ok(Some(t)) => {
                    block_times.insert(h, t);
                }
                // 0 marks "the node has no such block", so it is not asked again every minute.
                Ok(None) => {
                    block_times.insert(h, 0);
                }
                Err(_) => break,
            }
        }
        if kernel_heights.is_empty()
            && block_times.is_empty()
            && settlements.is_empty()
            && absent.is_empty()
        {
            return;
        }
        let r = self.meta.update(|m| {
            m.kernel_heights.extend(kernel_heights);
            m.block_times.extend(block_times);
            for (slate, at) in absent {
                m.annotations.entry(slate).or_default().kernel_absent_at = Some(at);
            }
            for (kernel, s) in settlements {
                for r in m
                    .records
                    .iter_mut()
                    .filter(|r| r.kernel_excess.as_deref() == Some(kernel.as_str()))
                {
                    history::apply_settlement(r, s);
                }
            }
            Ok(())
        });
        if let Err(e) = r {
            log::warn!("caching block data: {e}");
        }
    }

    /// `<pubkey>@<domain>[:port]`, from the key epic-wallet's epicbox adapter uses.
    pub(crate) fn epicbox_address(&self) -> CoreResult<String> {
        let address = self
            .owner
            .get_public_address(self.mask(), epicbox::ADDRESS_INDEX)?;
        Ok(address.to_string())
    }

    /// Every send gets a TTL (`ttl_blocks`): epic-wallet then cancels it on a refresh once the
    /// chain passes `ttl_cutoff_height` and unlocks its inputs (`owner.rs` `update_wallet_state`,
    /// step 5), and a recipient or our own finalize refuses it after that (`check_ttl`).
    fn send_args(
        &self,
        amount: u64,
        minimum_confirmations: u64,
        estimate_only: bool,
    ) -> InitTxArgs {
        InitTxArgs {
            amount,
            minimum_confirmations,
            selection_strategy_is_use_all: false,
            estimate_only: Some(estimate_only),
            ttl_blocks: Some(self.send_ttl_blocks.load(Ordering::Relaxed)),
            ..InitTxArgs::default()
        }
    }

    /// Test hook: the TTL, in blocks, of sends created from now on.
    pub(crate) fn set_send_ttl_blocks(&self, blocks: u64) {
        self.send_ttl_blocks.store(blocks, Ordering::Relaxed);
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
            self.send_args(amount, minimum_confirmations, true),
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
            self.send_args(amount, minimum_confirmations, false),
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
        let sender =
            HttpSlateSender::new(&base, Arc::new(AtomicBool::new(true))).map_err(|_| {
                CoreError::InvalidArgument("the address must start with http:// or https://".into())
            })?;
        let s = self.init_and_lock(amount, minimum_confirmations, Some(base.clone()))?;
        self.meta
            .annotate(&s.id.to_string(), |a| a.counterparty = Some(base.clone()));
        let response = match sender.send_tx(&s) {
            Ok(r) => r,
            Err(e) => {
                self.abandon(&s);
                return Err(CoreError::Relay(format!(
                    "the recipient at {base} did not answer: {e}"
                )));
            }
        };
        let finalized = match self.finalize_only(&response) {
            Ok(f) => f,
            Err(e) => {
                self.abandon(&s);
                return Err(e);
            }
        };
        // Past this point the recipient has signed and the transaction is final. A failed post
        // is not cancelled: the node may have taken it despite the error, and cancelling would
        // unlock inputs the chain can still spend. The send stays repostable instead, and is
        // returned as a result, not an error, so nobody pays a second time.
        Ok(self.post_and_entry(&finalized))
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
            return Err(CoreError::InvalidArgument(
                "that is this wallet's own address".into(),
            ));
        }
        let s = self.init_and_lock(amount, minimum_confirmations, Some(to.to_string()))?;
        self.meta
            .annotate(&s.id.to_string(), |a| a.counterparty = Some(to.to_string()));
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
            self.meta.clone(),
            on_event,
        ));
    }

    /// Stops the listener and waits for it, at most about a second.
    pub(crate) fn stop_listener(&self) {
        let listener = self
            .listener
            .lock()
            .unwrap_or_else(|p| p.into_inner())
            .take();
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
        let slate_id = id.to_string();
        let rows: Vec<TxEntry> = self
            .transactions(false)?
            .into_iter()
            .filter(|t| t.slate_id.as_deref() == Some(slate_id.as_str()))
            .collect();
        rows.iter()
            .find(|t| t.kind == TxKind::Sent)
            .or_else(|| rows.first())
            .cloned()
            .ok_or_else(|| CoreError::InvalidSlate(format!("no payment with id {id}")))
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

    /// Verifies and finalizes the recipient's response. Stores the final transaction.
    fn finalize_only(&self, response: &LibSlate) -> CoreResult<LibSlate> {
        self.owner
            .verify_slate_messages(self.mask(), response)
            .map_err(|e| CoreError::InvalidSlate(e.to_string()))?;
        let finalized = self.owner.finalize_tx(self.mask(), response)?;
        record_finalized(&self.meta, &finalized, wallet_height(&self.wallet));
        Ok(finalized)
    }

    fn finalize_slate(&self, response: &LibSlate) -> CoreResult<TxEntry> {
        let finalized = self.finalize_only(response)?;
        Ok(self.post_and_entry(&finalized))
    }

    /// Posts a finalized send and returns its row. Never fails: a post the node did not take is
    /// recorded (`status_detail`, `repostable`), and a failure to read the row back afterwards
    /// gives a minimal entry, because the payment itself is done either way.
    fn post_and_entry(&self, finalized: &LibSlate) -> TxEntry {
        let posted = post_recorded(&self.owner, self.mask(), &self.meta, finalized);
        if let Err(e) = &posted {
            log::warn!("the node did not take payment {}: {e}", finalized.id);
        }
        match self.tx_for_slate(finalized.id) {
            Ok(t) => t,
            Err(e) => {
                log::warn!("reading payment {} back: {e}", finalized.id);
                minimal_entry(finalized, posted.err())
            }
        }
    }

    /// epic-wallet's log entry for a send with `key`, without a full merge: `s:<slate>`,
    /// `s:<slate>#l<id>` or `l:<id>`, else looked up in the merged list.
    fn live_send_by_key(&self, key: &str) -> CoreResult<TxLogEntry> {
        let missing = || CoreError::InvalidArgument(format!("no payment {key}"));
        let (base, id_suffix) = match key.split_once("#l") {
            Some((b, i)) => (b, i.parse::<u32>().ok()),
            None => (key, None),
        };
        let (by_id, by_slate) = if let Some(s) = base.strip_prefix("s:") {
            (
                id_suffix,
                Some(uuid::Uuid::parse_str(s).map_err(|_| missing())?),
            )
        } else if let Some(i) = base.strip_prefix("l:") {
            (Some(i.parse::<u32>().map_err(|_| missing())?), None)
        } else {
            let row = self
                .transactions(false)?
                .into_iter()
                .find(|t| t.key == key)
                .ok_or_else(missing)?;
            (Some(row.id.ok_or_else(missing)?), None)
        };
        self.owner
            .retrieve_txs(self.mask(), false, by_id, by_slate, None, None, None)?
            .txs
            .into_iter()
            .filter(|t| by_id.is_none_or(|i| t.id == i))
            .find(|t| {
                matches!(
                    t.tx_type,
                    TxLogEntryType::TxSentCreated
                        | TxLogEntryType::TxSent
                        | TxLogEntryType::TxSentMempool
                        | TxLogEntryType::TxSentCancelled
                )
            })
            .ok_or_else(missing)
    }

    /// Unlocks the funds of a finalized send the node refused and that never reached the chain
    /// (`TxEntry.releasable`). Asks the node once more first: if the kernel is on chain or in its
    /// pool, nothing is released. See the contract log for what it can still cost.
    pub(crate) fn release_stuck_send(&self, key: &str) -> CoreResult<()> {
        let row = self
            .merged(false)?
            .into_iter()
            .find(|m| m.tx.key == key)
            .ok_or_else(|| CoreError::InvalidArgument(format!("no payment {key}")))?;
        let refuse = |why: &str| Err(CoreError::InvalidArgument(why.to_owned()));
        let (Some(id), Some(kernel), true) =
            (row.tx.id, row.tx.kernel_excess.clone(), row.tx.releasable)
        else {
            return refuse("only a payment the network refused, and that has not reached it for a day, can be released");
        };
        let excess = pedersen::Commitment::from_vec(
            hex::decode(&kernel).map_err(|_| CoreError::InvalidArgument("bad kernel".into()))?,
        );
        let (tip, _) = self.node.get_chain_tip()?;
        let min = row.kernel_lookup_min_height.unwrap_or(1);
        match self.node.kernel_height(&excess, min, tip) {
            Ok(None) => {}
            Ok(Some(_)) => return refuse("this payment is on the chain; it cannot be released"),
            Err(_) => {
                return Err(CoreError::Wallet(LibWalletError::ClientCallback(
                    "could not ask the node whether the payment reached the chain".into(),
                )))
            }
        }
        let pool = self.node.get_mempool()?;
        if pool.iter().any(|p| {
            p.tx.kernels()
                .iter()
                .any(|k| hex::encode(k.excess.0) == kernel)
        }) {
            return refuse(
                "the node still holds this payment and may confirm it; it cannot be released",
            );
        }
        self.owner.cancel_tx(self.mask(), Some(id), None)?;
        Ok(())
    }

    pub(crate) fn cancel_transaction(&self, tx_id: u32) -> CoreResult<()> {
        self.owner.cancel_tx(self.mask(), Some(tx_id), None)?;
        Ok(())
    }

    /// Posts the stored final transaction of the send with `key` again, as the CLI's `repost`
    /// does. For a send that was finalized but never reached the chain.
    pub(crate) fn repost_transaction(&self, key: &str) -> CoreResult<()> {
        let entry = self.live_send_by_key(key)?;
        let refuse = || {
            CoreError::InvalidArgument(
                "only a finished payment that has not reached the network can be sent to it again"
                    .into(),
            )
        };
        if entry.confirmed || entry.tx_type == TxLogEntryType::TxSentCancelled {
            return Err(refuse());
        }
        let tx = stored_tx::load(&self.config.data_dir, &entry)?
            .filter(stored_tx::kernel_is_final)
            .ok_or_else(refuse)?;
        let slate_id = entry.tx_slate_id.map(|u| u.to_string()).unwrap_or_default();
        let posted = self.owner.post_tx(self.mask(), &tx, true);
        record_post(&self.meta, &slate_id, &posted);
        posted?;
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

/// True when the send's stored transaction parses and carries the final kernel. A damaged file
/// is logged and counts as not final (and so not repostable).
fn stored_final(data_dir: &str, entry: &TxLogEntry) -> bool {
    match stored_tx::load(data_dir, entry) {
        Ok(Some(tx)) => stored_tx::kernel_is_final(&tx),
        Ok(None) => false,
        Err(e) => {
            log::warn!("transaction {}: {e}", entry.id);
            false
        }
    }
}

/// Notes that this wallet finalized `slate`, with its final kernel. Called before the post, so a
/// post that fails still shows the send as awaiting confirmation, as it can be reposted.
pub(crate) fn record_finalized(meta: &MetaStore, slate: &LibSlate, height: Option<u64>) {
    let kernel = slate.tx.kernels().first().map(|k| hex::encode(k.excess.0));
    meta.annotate(&slate.id.to_string(), |a| {
        a.finalized = true;
        a.finalized_at_unix = Some(now_unix());
        a.finalized_height = height.or(a.finalized_height);
        if kernel.is_some() {
            a.kernel_excess = kernel;
        }
    });
}

/// Records how a post of `slate_id` went. A JSON-RPC error from the node (`BadRequest`) is a
/// refusal; anything else (no answer, 429, a timeout) is not, since the node may have taken it.
pub(crate) fn record_post(meta: &MetaStore, slate_id: &str, result: &Result<(), LibWalletError>) {
    if slate_id.is_empty() {
        return;
    }
    meta.annotate(slate_id, |a| match result {
        Ok(()) => a.post_error = None,
        Err(e) => {
            a.post_error = Some(e.to_string());
            if matches!(e, LibWalletError::BadRequest(_)) {
                a.post_refused = true;
            }
        }
    });
}

/// `post_tx` with fluff, recorded in the archive.
pub(crate) fn post_recorded(
    owner: &OwnerApi,
    mask: Option<&SecretKey>,
    meta: &MetaStore,
    slate: &LibSlate,
) -> Result<(), LibWalletError> {
    let posted = owner.post_tx(mask, &slate.tx, true);
    record_post(meta, &slate.id.to_string(), &posted);
    posted
}

/// The wallet's last confirmed height, if it can be read.
pub(crate) fn wallet_height(wallet: &WalletHandle) -> Option<u64> {
    let mut guard = wallet.lock();
    guard
        .lc_provider()
        .ok()?
        .wallet_inst()
        .ok()?
        .last_confirmed_height()
        .ok()
}

/// What `send_http` or `finalize_and_post` returns when the row cannot be read back after the
/// post: enough for the UI to show the payment and not offer to send it again.
fn minimal_entry(slate: &LibSlate, post_error: Option<LibWalletError>) -> TxEntry {
    let id = slate.id.to_string();
    let now = now_unix();
    TxEntry {
        key: format!("s:{id}"),
        id: None,
        slate_id: Some(id),
        kind: TxKind::Sent,
        status: TxStatus::AwaitingConfirmation,
        source: TxSource::Wallet,
        created_at_unix: now,
        time_unix: now,
        confirmed: false,
        block_height: None,
        block_time_unix: None,
        amount_credited: 0,
        amount_debited: slate.amount + slate.fee,
        fee: Some(slate.fee),
        num_inputs: 0,
        num_outputs: 0,
        kernel_excess: slate.tx.kernels().first().map(|k| hex::encode(k.excess.0)),
        output_commits: Vec::new(),
        counterparty: None,
        note: None,
        ttl_cutoff_height: slate.ttl_cutoff_height,
        cancellable: false,
        repostable: post_error.is_some(),
        status_detail: post_error
            .map(|e| format!("The network has not taken this payment yet: {e}")),
        releasable: false,
        finalized_at_unix: Some(now),
    }
}

fn contact_to_api(c: ContactRec) -> Contact {
    Contact {
        id: c.id,
        name: c.name,
        address: c.address,
        note: c.note,
    }
}

#[cfg(test)]
mod tests {
    use super::{http_base_url, record_post, LibWalletError, MetaStore};

    #[test]
    fn a_node_refusal_is_told_apart_from_no_answer() {
        let dir = tempfile::tempdir().unwrap();
        let meta = MetaStore::open(dir.path().to_str().unwrap()).unwrap();
        let ann = |m: &MetaStore| m.snapshot().annotations["s1"].clone();
        record_post(
            &meta,
            "s1",
            &Err(LibWalletError::ClientCallback("timed out".into())),
        );
        assert!(ann(&meta).post_error.is_some());
        assert!(!ann(&meta).post_refused, "no answer is not a refusal");
        record_post(
            &meta,
            "s1",
            &Err(LibWalletError::BadRequest(
                "Unable to parse response for push_transaction".into(),
            )),
        );
        assert!(ann(&meta).post_refused);
        record_post(&meta, "s1", &Ok(()));
        assert_eq!(
            ann(&meta).post_error,
            None,
            "a post the node took clears the error"
        );
        assert!(ann(&meta).post_refused, "the refusal stays on record");
    }

    #[test]
    fn http_base_url_strips_the_api_path() {
        assert_eq!(
            http_base_url("http://1.2.3.4:3415").unwrap(),
            "http://1.2.3.4:3415"
        );
        assert_eq!(
            http_base_url(" https://w.example/v2/foreign/ ").unwrap(),
            "https://w.example"
        );
        assert!(http_base_url("1.2.3.4:3415").is_err());
        assert!(http_base_url("http://").is_err());
    }
}
