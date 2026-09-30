//! The node client every wallet in this crate uses: epic-wallet's `HTTPNodeClient` with one change,
//! how "is the node synced?" is answered.
//!
//! epic-wallet 4.0.x refuses to refresh outputs unless `/v2/owner get_status` reports
//! `sync_status == "no_sync"` (`libwallet/src/internal/updater.rs:211`, added in 82242ab, first in
//! v4.0.0-beta). The owner API is the node's admin interface and public nodes keep it closed
//! (node.btlabs.uk answers 403), so against a public node a refresh could never happen.
//!
//! The sync status is taken from the first of these that answers:
//!
//! 1. `/v2/owner get_status`, as epic-wallet does.
//! 2. `GET /v1/status`, the node's REST status. Same `sync_status` and tip, and some public nodes
//!    serve it without auth (node.btlabs.uk does). Sent with `epic:<node_api_secret>` basic auth
//!    when a secret is configured, as HTTPNodeClient does.
//! 3. Only when neither answers: the foreign API's `get_tip`, the one endpoint every public node
//!    serves. It carries no sync status, so the node counts as synced when its tip is not below
//!    the highest tip this wallet has already seen.
//!
//! Every answer passes through the same height floor: the highest tip this wallet has accepted
//! (its `last_confirmed_height` when opened, then every synced tip since). A tip below it is
//! reported as not synced even if the node says `no_sync`, so a node on a stale fork or restarted
//! from old data is refused too.
//!
//! Trust trade-off, for step 3 only: the foreign API cannot say whether a node is still syncing. A
//! syncing node already past the floor would be accepted, and the refresh would mark any unspent
//! output the node does not know yet as spent (`apply_api_outputs`, `None => mark_spent`). That is
//! local wallet state only, and the next refresh against a synced node or a `scan` puts it right.
//! It is the same trust Stack Wallet places in its node: its balances come from `libwallet::scan`,
//! which never checks sync status. The floor stops the worst case, a node far behind the wallet
//! wiping recent outputs.

use std::collections::HashMap;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use std::time::Duration;

use epic_wallet_impls::HTTPNodeClient;
use epic_wallet_libwallet::{Error, NodeClient, NodeStatus, NodeVersionInfo, PoolEntry, Tip};
use epic_wallet_util::epic_core::core::{Transaction, TxKernel};
use epic_wallet_util::epic_util::secp::pedersen;

/// `sync_status` epic-wallet treats as synced.
const SYNCED: &str = "no_sync";
/// Reported when a node's tip is below one the wallet has already accepted.
const BEHIND: &str = "behind_wallet_tip";
/// `/v1/status` is one small JSON object; a node that takes longer is treated as not answering.
const STATUS_TIMEOUT: Duration = Duration::from_secs(20);

/// `sync_status` and tip height from a `/v1/status` body, or `None` if it is not one.
pub(crate) fn parse_v1_status(body: &str) -> Option<(String, u64)> {
    let v: serde_json::Value = serde_json::from_str(body).ok()?;
    let sync_status = v.get("sync_status")?.as_str()?.to_owned();
    let height = v.get("tip")?.get("height")?.as_u64()?;
    Some((sync_status, height))
}

#[derive(Clone)]
pub(crate) struct EpicNodeClient {
    inner: HTTPNodeClient,
    /// For `/v1/status`. `None` if it could not be built; step 2 is then skipped.
    http: Option<reqwest::blocking::Client>,
    /// Highest chain height this wallet has accepted. Shared by every clone of the client.
    highest_tip: Arc<AtomicU64>,
}

impl EpicNodeClient {
    /// Must not be called from inside a tokio runtime (reqwest's blocking client starts its own).
    pub(crate) fn new(inner: HTTPNodeClient) -> Self {
        let http = reqwest::blocking::Client::builder()
            .timeout(STATUS_TIMEOUT)
            .use_rustls_tls()
            .user_agent("epic-client")
            .build()
            .map_err(|e| log::warn!("no HTTP client for /v1/status: {e}"))
            .ok();
        EpicNodeClient {
            inner,
            http,
            highest_tip: Arc::new(AtomicU64::new(0)),
        }
    }

    /// Handle for raising the floor once the wallet's own last confirmed height is known.
    pub(crate) fn highest_tip(&self) -> Arc<AtomicU64> {
        self.highest_tip.clone()
    }

    /// The node's tip, asked once without the retries of `get_chain_tip`, for callers that have
    /// a fallback and should not wait 6 s on a node that is down.
    pub(crate) fn chain_tip_once(&self) -> Result<(u64, String), Error> {
        self.inner.get_chain_tip()
    }

    /// Applies the height floor to a node's own answer, raising the floor when it is synced.
    fn judge(&self, sync_status: &str, height: u64) -> String {
        let floor = self.highest_tip.load(Ordering::Relaxed);
        if sync_status != SYNCED {
            return sync_status.to_owned();
        }
        if height < floor {
            log::warn!("node tip {height} is below the {floor} this wallet has already seen");
            return BEHIND.to_owned();
        }
        self.highest_tip.fetch_max(height, Ordering::Relaxed);
        SYNCED.to_owned()
    }

    /// Step 2: `GET /v1/status`. `None` when it is unreachable, refused or not a status body.
    fn v1_status(&self) -> Option<(String, u64)> {
        let http = self.http.as_ref()?;
        let url = format!("{}/v1/status", self.inner.node_url().trim_end_matches('/'));
        let mut req = http.get(&url).header("Accept", "application/json");
        if let Some(secret) = self.inner.node_api_secret() {
            req = req.basic_auth("epic", Some(secret));
        }
        let resp = req
            .send()
            .map_err(|e| log::info!("/v1/status unreachable: {e}"))
            .ok()?;
        if !resp.status().is_success() {
            log::info!("/v1/status answered {}", resp.status());
            return None;
        }
        let body = resp.text().ok()?;
        let parsed = parse_v1_status(&body);
        if parsed.is_none() {
            log::info!("/v1/status body is not a node status");
        }
        parsed
    }

    fn status(&self, sync_status: String, height: u64, hash: String) -> NodeStatus {
        NodeStatus {
            protocol_version: 0,
            user_agent: String::new(),
            connections: 0,
            tip: Tip {
                height,
                last_block_pushed: hash,
                prev_block_to_last: String::new(),
                total_difficulty: HashMap::new(),
            },
            sync_status,
            sync_info: None,
        }
    }
}

/// Why an enrichment lookup stopped: the node refused (429), failed, or could not be reached.
/// The caller stops for this refresh and tries again on the next one.
#[derive(Debug)]
pub(crate) struct LookupStopped;

impl EpicNodeClient {
    /// Unix time of the block at `height`, from the foreign API's `get_header [height, null, null]`
    /// (`BlockHeaderPrintable.timestamp`, RFC 3339). `Ok(None)` when the node has no such block.
    pub(crate) fn block_time(&self, height: u64) -> Result<Option<i64>, LookupStopped> {
        let http = self.http.as_ref().ok_or(LookupStopped)?;
        let url = format!("{}/v2/foreign", self.inner.node_url().trim_end_matches('/'));
        let body = serde_json::json!({
            "jsonrpc": "2.0", "id": 1, "method": "get_header", "params": [height, null, null]
        });
        let mut req = http
            .post(&url)
            .header("Content-Type", "application/json")
            .body(body.to_string());
        if let Some(secret) = self.inner.node_api_secret() {
            req = req.basic_auth("epic", Some(secret));
        }
        let resp = req.send().map_err(|e| {
            log::info!("get_header {height}: {e}");
            LookupStopped
        })?;
        if !resp.status().is_success() {
            log::info!("get_header {height} answered {}", resp.status());
            return Err(LookupStopped);
        }
        let text = resp.text().map_err(|_| LookupStopped)?;
        let v: serde_json::Value = serde_json::from_str(&text).map_err(|_| LookupStopped)?;
        let result = v.get("result").ok_or(LookupStopped)?;
        if let Some(ts) = result
            .get("Ok")
            .and_then(|h| h.get("timestamp"))
            .and_then(|t| t.as_str())
        {
            return Ok(rfc3339_to_unix(ts));
        }
        if result.get("Err").is_some() {
            return Ok(None);
        }
        Err(LookupStopped)
    }

    /// Height of the block holding the kernel `excess`, searched between `min_height` (at least 1:
    /// the node computes `min_height - 1`) and `max_height`.
    pub(crate) fn kernel_height(
        &self,
        excess: &pedersen::Commitment,
        min_height: u64,
        max_height: u64,
    ) -> Result<Option<u64>, LookupStopped> {
        let mut inner = self.inner.clone();
        match inner.get_kernel(excess, Some(min_height.max(1)), Some(max_height)) {
            Ok(found) => Ok(found.map(|(_, height, _)| height)),
            Err(e) => {
                log::info!("get_kernel: {e}");
                Err(LookupStopped)
            }
        }
    }
}

fn days_from_civil(y: i64, m: i64, d: i64) -> i64 {
    let y = if m <= 2 { y - 1 } else { y };
    let era = y.div_euclid(400);
    let yoe = y.rem_euclid(400);
    let mp = if m > 2 { m - 3 } else { m + 9 };
    let doy = (153 * mp + 2) / 5 + d - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    era * 146_097 + doe - 719_468
}

/// `2026-09-07T19:38:10+00:00` (or `Z`, or fractional seconds) to unix seconds.
pub(crate) fn rfc3339_to_unix(s: &str) -> Option<i64> {
    let num = |r: std::ops::Range<usize>| s.get(r)?.parse::<i64>().ok();
    let (y, mo, d) = (num(0..4)?, num(5..7)?, num(8..10)?);
    let (h, mi, se) = (num(11..13)?, num(14..16)?, num(17..19)?);
    if s.get(4..5)? != "-" || s.get(10..11).map(|c| c.to_ascii_uppercase())? != "T" {
        return None;
    }
    let mut rest = s.get(19..)?;
    if let Some(frac) = rest.strip_prefix('.') {
        rest = frac.trim_start_matches(|c: char| c.is_ascii_digit());
    }
    let offset = match rest {
        "Z" | "z" => 0,
        _ => {
            let sign = match rest.get(0..1)? {
                "+" => 1,
                "-" => -1,
                _ => return None,
            };
            let oh = rest.get(1..3)?.parse::<i64>().ok()?;
            let om = rest.get(4..6)?.parse::<i64>().ok()?;
            sign * (oh * 3_600 + om * 60)
        }
    };
    Some(days_from_civil(y, mo, d) * 86_400 + h * 3_600 + mi * 60 + se - offset)
}

/// Retries a read that failed. Public nodes sit behind rate-limiting proxies (floo-node.btlabs.uk
/// answers 429 after about ten requests in a burst), and HTTPNodeClient reports that only as an
/// unparsable response. Reads are idempotent, so trying again after a pause is safe.
fn retry_read<T>(what: &str, mut call: impl FnMut() -> Result<T, Error>) -> Result<T, Error> {
    const DELAYS_MS: [u64; 3] = [500, 1500, 4000];
    let mut attempt = 0;
    loop {
        match call() {
            Ok(v) => return Ok(v),
            Err(e) if attempt < DELAYS_MS.len() => {
                log::info!("{what} failed ({e}), retrying");
                std::thread::sleep(std::time::Duration::from_millis(DELAYS_MS[attempt]));
                attempt += 1;
            }
            Err(e) => return Err(e),
        }
    }
}

impl NodeClient for EpicNodeClient {
    fn get_node_status(&self) -> Result<NodeStatus, Error> {
        match self.inner.get_node_status() {
            Ok(mut status) => {
                status.sync_status = self.judge(&status.sync_status, status.tip.height);
                return Ok(status);
            }
            Err(e) => log::info!("owner get_status unavailable ({e}), trying /v1/status"),
        }
        if let Some((sync_status, height)) = self.v1_status() {
            let judged = self.judge(&sync_status, height);
            return Ok(self.status(judged, height, String::new()));
        }
        log::info!("/v1/status unavailable, judging sync from the foreign API tip");
        let (height, hash) = self.inner.get_chain_tip()?;
        let judged = self.judge(SYNCED, height);
        Ok(self.status(judged, height, hash))
    }

    fn node_url(&self) -> &str {
        self.inner.node_url()
    }
    fn set_node_url(&mut self, node_url: &str) {
        self.inner.set_node_url(node_url)
    }
    fn node_api_secret(&self) -> Option<String> {
        self.inner.node_api_secret()
    }
    fn set_node_api_secret(&mut self, node_api_secret: Option<String>) {
        self.inner.set_node_api_secret(node_api_secret)
    }
    fn post_tx(&self, tx: &Transaction, fluff: bool) -> Result<(), Error> {
        self.inner.post_tx(tx, fluff)
    }
    fn post_tx_tor(&self, tx: &Transaction, tor_url: &str) -> Result<(), Error> {
        self.inner.post_tx_tor(tx, tor_url)
    }
    fn get_mempool(&self) -> Result<Vec<PoolEntry>, Error> {
        self.inner.get_mempool()
    }
    fn get_version_info(&mut self) -> Option<NodeVersionInfo> {
        self.inner.get_version_info()
    }
    fn get_chain_tip(&self) -> Result<(u64, String), Error> {
        retry_read("get_tip", || self.inner.get_chain_tip())
    }
    fn get_kernel(
        &mut self,
        excess: &pedersen::Commitment,
        min_height: Option<u64>,
        max_height: Option<u64>,
    ) -> Result<Option<(TxKernel, u64, u64)>, Error> {
        self.inner.get_kernel(excess, min_height, max_height)
    }
    fn get_outputs_from_node(
        &self,
        wallet_outputs: Vec<pedersen::Commitment>,
    ) -> Result<HashMap<pedersen::Commitment, (String, u64, u64)>, Error> {
        retry_read("get_outputs", || {
            self.inner.get_outputs_from_node(wallet_outputs.clone())
        })
    }
    #[allow(clippy::type_complexity)]
    fn get_outputs_by_pmmr_index(
        &self,
        start_height: u64,
        end_height: Option<u64>,
        max_outputs: u64,
    ) -> Result<
        (
            u64,
            u64,
            Vec<(pedersen::Commitment, pedersen::RangeProof, bool, u64, u64)>,
        ),
        Error,
    > {
        retry_read("get_unspent_outputs", || {
            self.inner
                .get_outputs_by_pmmr_index(start_height, end_height, max_outputs)
        })
    }
    fn height_range_to_pmmr_indices(
        &self,
        start_height: u64,
        end_height: Option<u64>,
    ) -> Result<(u64, u64), Error> {
        retry_read("get_pmmr_indices", || {
            self.inner
                .height_range_to_pmmr_indices(start_height, end_height)
        })
    }
    fn get_onion_addresses(&self) -> Result<Vec<String>, Error> {
        self.inner.get_onion_addresses()
    }
}

#[cfg(test)]
mod tests {
    use super::parse_v1_status;

    #[test]
    fn parses_a_node_status_body() {
        // Shape of node.btlabs.uk's /v1/status, trimmed.
        let body = r#"{
            "protocol_version": 2,
            "user_agent": "MW/Epic 4.0.4",
            "connections": 55,
            "tip": {
                "height": 3728476,
                "last_block_pushed": "781b24fa",
                "prev_block_to_last": "6c1861cd",
                "total_difficulty": {"randomx": 1, "progpow": 2, "cuckoo": 3}
            },
            "sync_status": "no_sync"
        }"#;
        assert_eq!(
            parse_v1_status(body),
            Some(("no_sync".to_owned(), 3_728_476))
        );
    }

    #[test]
    fn parses_header_timestamps() {
        use super::rfc3339_to_unix;
        // node.btlabs.uk, get_header [3700000, null, null], 2026-09-30.
        assert_eq!(
            rfc3339_to_unix("2026-09-07T19:38:10+00:00"),
            Some(1_788_809_890)
        );
        assert_eq!(
            rfc3339_to_unix("2026-09-07T21:38:10+02:00"),
            Some(1_788_809_890)
        );
        assert_eq!(
            rfc3339_to_unix("2026-09-07T19:38:10.123Z"),
            Some(1_788_809_890)
        );
        assert_eq!(rfc3339_to_unix("1970-01-01T00:00:00Z"), Some(0));
        assert_eq!(rfc3339_to_unix("yesterday"), None);
    }

    #[test]
    fn keeps_a_not_synced_answer() {
        let body = r#"{"tip": {"height": 10}, "sync_status": "header_sync",
                       "sync_info": {"current_height": 10, "highest_height": 99}}"#;
        assert_eq!(parse_v1_status(body), Some(("header_sync".to_owned(), 10)));
    }

    #[test]
    fn rejects_bodies_that_are_not_a_status() {
        assert_eq!(parse_v1_status(""), None);
        assert_eq!(
            parse_v1_status("Node administration is not publicly available."),
            None
        );
        assert_eq!(parse_v1_status(r#"{"sync_status": "no_sync"}"#), None);
        assert_eq!(parse_v1_status(r#"{"tip": {"height": 5}}"#), None);
        assert_eq!(
            parse_v1_status(r#"{"tip": {"height": "5"}, "sync_status": "no_sync"}"#),
            None
        );
        assert_eq!(
            parse_v1_status(r#"{"tip": {"height": 5}, "sync_status": 1}"#),
            None
        );
    }
}
