//! History files: the encrypted `WFEH` export and the plain CSV.
//!
//! `WFEH` layout, all integers single bytes:
//!
//! ```text
//! "WFEH" | version=1 | kdf=1 | salt[16] | check[16] | nonce[12] | ChaCha20-Poly1305(payload JSON)
//! ```
//!
//! The 50-byte header is the AAD. Keys come from HKDF-SHA256 over the wallet's root secret (the
//! key epic-wallet derives at `m` with `derive_key(0, root_key_id)`, the same root its private
//! contexts are masked with), salted per file. `check` is a second HKDF output: it tells "another
//! wallet's file" apart from "a damaged file" without revealing anything about the key. A wallet
//! restored from the same phrase has the same root secret, so it opens its own exports with no
//! passphrase; no other wallet can.
//!
//! The payload holds only public or user-entered data (`meta::Record`, contacts). Never in it:
//! private contexts, keys, the seed or phrase, the password or PIN seal, `saved_txs`, node secrets.

use ring::aead::{Aad, LessSafeKey, Nonce, UnboundKey, CHACHA20_POLY1305, NONCE_LEN};
use ring::hkdf;
use serde::{Deserialize, Serialize};
use zeroize::Zeroizing;

use super::error::{CoreError, CoreResult};
use super::meta::{ContactRec, Record};
use super::vault::random_bytes;
use crate::api::types::{TxEntry, TxKind, TxStatus};

const MAGIC: &[u8; 4] = b"WFEH";
const VERSION: u8 = 1;
const KDF_SEED: u8 = 1;
const SALT_LEN: usize = 16;
const CHECK_LEN: usize = 16;
const HEADER_LEN: usize = 4 + 1 + 1 + SALT_LEN + CHECK_LEN + NONCE_LEN;
const INFO_KEY: &[u8] = b"wfe-history-export-v1/key";
const INFO_CHECK: &[u8] = b"wfe-history-export-v1/check";
pub(crate) const FORMAT: &str = "wfe-history";
pub(crate) const PAYLOAD_VERSION: u32 = 1;

pub(crate) const DIFFERENT_WALLET: &str = "This history file belongs to a different wallet";

/// What an export file carries, before encryption.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub(crate) struct Payload {
    pub format: String,
    pub version: u32,
    /// `Chain` name: Mainnet, Floonet, Usernet.
    pub chain: String,
    /// Hex SHA-256 prefix of the wallet's epicbox public key. Derived from the seed.
    pub wallet_fp: String,
    pub exported_at_unix: i64,
    pub app_version: String,
    #[serde(default)]
    pub last_confirmed_height: Option<u64>,
    #[serde(default)]
    pub txs: Vec<Record>,
    #[serde(default)]
    pub contacts: Vec<ContactRec>,
}

struct Len(usize);

impl hkdf::KeyType for Len {
    fn len(&self) -> usize {
        self.0
    }
}

fn keys(root: &[u8], salt: &[u8]) -> CoreResult<(LessSafeKey, [u8; CHECK_LEN])> {
    let prk = hkdf::Salt::new(hkdf::HKDF_SHA256, salt).extract(root);
    let okm = prk
        .expand(&[INFO_KEY], &CHACHA20_POLY1305)
        .map_err(|_| CoreError::InvalidArgument("key derivation failed".into()))?;
    let key = LessSafeKey::new(UnboundKey::from(okm));
    let mut check = [0u8; CHECK_LEN];
    prk.expand(&[INFO_CHECK], Len(CHECK_LEN))
        .and_then(|o| o.fill(&mut check))
        .map_err(|_| CoreError::InvalidArgument("key derivation failed".into()))?;
    Ok((key, check))
}

/// Encrypts `plain` under a key derived from `root`.
pub(crate) fn seal(root: &[u8], plain: &[u8]) -> CoreResult<Vec<u8>> {
    let salt = random_bytes::<SALT_LEN>()?;
    let nonce = random_bytes::<NONCE_LEN>()?;
    let (key, check) = keys(root, &salt)?;
    let mut out = Vec::with_capacity(HEADER_LEN + plain.len() + CHACHA20_POLY1305.tag_len());
    out.extend_from_slice(MAGIC);
    out.push(VERSION);
    out.push(KDF_SEED);
    out.extend_from_slice(&salt);
    out.extend_from_slice(&check);
    out.extend_from_slice(&nonce);
    let mut body = plain.to_vec();
    key.seal_in_place_append_tag(
        Nonce::assume_unique_for_key(nonce),
        Aad::from(&out[..HEADER_LEN]),
        &mut body,
    )
    .map_err(|_| CoreError::InvalidArgument("encryption failed".into()))?;
    out.extend_from_slice(&body);
    Ok(out)
}

/// Decrypts a file made by `seal` with the same `root`.
pub(crate) fn open(root: &[u8], data: &[u8]) -> CoreResult<Zeroizing<Vec<u8>>> {
    let bad = |m: &str| CoreError::InvalidArgument(m.to_owned());
    if data.len() < HEADER_LEN || &data[..4] != MAGIC {
        return Err(bad("This is not a history file exported by this app"));
    }
    if data[4] != VERSION || data[5] != KDF_SEED {
        return Err(bad(
            "This history file was made by a newer version of the app",
        ));
    }
    let salt = &data[6..6 + SALT_LEN];
    let check = &data[6 + SALT_LEN..6 + SALT_LEN + CHECK_LEN];
    let mut nonce = [0u8; NONCE_LEN];
    nonce.copy_from_slice(&data[HEADER_LEN - NONCE_LEN..HEADER_LEN]);
    let (key, expected) = keys(root, salt)?;
    // Not secret: it only says which wallet a file belongs to.
    if check != expected {
        return Err(bad(DIFFERENT_WALLET));
    }
    let mut body = Zeroizing::new(data[HEADER_LEN..].to_vec());
    let len = key
        .open_in_place(
            Nonce::assume_unique_for_key(nonce),
            Aad::from(&data[..HEADER_LEN]),
            &mut body,
        )
        .map_err(|_| bad("This history file is damaged"))?
        .len();
    body.truncate(len);
    Ok(body)
}

/// `amount` in EPIC with 8 decimals, e.g. `-1.50000000`.
fn epic_decimal(amount: i128) -> String {
    let sign = if amount < 0 { "-" } else { "" };
    let a = amount.unsigned_abs();
    format!("{sign}{}.{:08}", a / 100_000_000, a % 100_000_000)
}

/// One CSV field: quoted when it holds a comma, quote or line break, and with a leading `'`
/// when text could be read as a spreadsheet formula (counterparty and note come from others).
fn field(value: &str, text: bool) -> String {
    let mut v = value.to_owned();
    if text && v.starts_with(['=', '+', '-', '@', '\t', '\r']) {
        v.insert(0, '\'');
    }
    if v.contains([',', '"', '\n', '\r']) {
        format!("\"{}\"", v.replace('"', "\"\""))
    } else {
        v
    }
}

/// `unix` as `YYYY-MM-DDTHH:MM:SSZ` (days-to-civil conversion from Howard Hinnant's algorithm).
fn iso_utc(unix: i64) -> String {
    let days = unix.div_euclid(86_400);
    let secs = unix.rem_euclid(86_400);
    let z = days + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z.rem_euclid(146_097);
    let yoe = (doe - doe / 1_460 + doe / 36_524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let day = doy - (153 * mp + 2) / 5 + 1;
    let month = if mp < 10 { mp + 3 } else { mp - 9 };
    let year = yoe + era * 400 + i64::from(month <= 2);
    format!(
        "{year:04}-{month:02}-{day:02}T{:02}:{:02}:{:02}Z",
        secs / 3_600,
        secs % 3_600 / 60,
        secs % 60
    )
}

/// Net amount the user sees: what a send delivered (without the fee) as a negative number, what a
/// receive brought in as a positive one.
fn net_amount(tx: &TxEntry) -> i128 {
    let credited = tx.amount_credited as i128;
    let debited = tx.amount_debited as i128;
    match tx.kind {
        TxKind::Sent | TxKind::SentCancelled => -(debited - credited - tx.fee.unwrap_or(0) as i128),
        _ => credited - debited,
    }
}

/// Confirmations after which the app calls a payment completed (the UI's `minimumConfirmations`).
pub(crate) const CONFIRMATIONS_TARGET: u64 = 10;

/// The type column, in the words the app shows (`txKindLabel` in `lib/src/ui/common.dart`).
fn type_word(kind: TxKind) -> &'static str {
    match kind {
        TxKind::Coinbase => "Mining reward",
        TxKind::Received | TxKind::ReceivedCancelled => "Received",
        TxKind::Sent | TxKind::SentCancelled => "Sent",
    }
}

/// The status column, in the words of the app's status chip (`txStatusLabel`), with `tip` the
/// wallet's last confirmed height when known.
fn status_words(tx: &TxEntry, tip: Option<u64>) -> String {
    let confirmations = match (tx.block_height, tip) {
        (Some(h), Some(t)) => Some((t + 1).saturating_sub(h)),
        _ => None,
    };
    let incoming = matches!(tx.kind, TxKind::Received | TxKind::ReceivedCancelled);
    match tx.status {
        TxStatus::Cancelled => "Cancelled".into(),
        _ if tx.id.is_none() && tx.status != TxStatus::Confirmed => {
            "From backup, status unknown".into()
        }
        TxStatus::AwaitingRecipient => "Waiting for recipient".into(),
        TxStatus::AwaitingConfirmation if tx.block_height.is_none() && incoming => {
            "Waiting for sender".into()
        }
        TxStatus::AwaitingConfirmation => {
            format!(
                "Confirming {}/{CONFIRMATIONS_TARGET}",
                confirmations.unwrap_or(0)
            )
        }
        TxStatus::Confirmed => match confirmations {
            Some(n) if n < CONFIRMATIONS_TARGET => format!("Confirming {n}/{CONFIRMATIONS_TARGET}"),
            _ => "Completed".into(),
        },
    }
}

/// One row per payment, newest first as given.
pub(crate) fn csv(txs: &[TxEntry], tip: Option<u64>) -> String {
    let mut out = String::from(
        "date,type,status,amount_epic,fee_epic,counterparty,note,slate_id,kernel,block_height\n",
    );
    for tx in txs {
        let row = [
            field(&iso_utc(tx.time_unix), false),
            field(type_word(tx.kind), false),
            field(&status_words(tx, tip), false),
            field(&epic_decimal(net_amount(tx)), false),
            field(
                &tx.fee.map(|f| epic_decimal(f as i128)).unwrap_or_default(),
                false,
            ),
            field(tx.counterparty.as_deref().unwrap_or(""), true),
            field(tx.note.as_deref().unwrap_or(""), true),
            field(tx.slate_id.as_deref().unwrap_or(""), false),
            field(tx.kernel_excess.as_deref().unwrap_or(""), false),
            field(
                &tx.block_height.map(|h| h.to_string()).unwrap_or_default(),
                false,
            ),
        ];
        out.push_str(&row.join(","));
        out.push('\n');
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::types::TxSource;

    #[test]
    fn seal_then_open_round_trips() {
        let root = [7u8; 32];
        let sealed = seal(&root, b"{\"hello\":1}").unwrap();
        assert_eq!(&sealed[..4], b"WFEH");
        assert_eq!(&open(&root, &sealed).unwrap()[..], b"{\"hello\":1}");
        assert_ne!(
            seal(&root, b"x").unwrap(),
            seal(&root, b"x").unwrap(),
            "fresh salt and nonce"
        );
    }

    #[test]
    fn another_wallet_is_told_so() {
        let sealed = seal(&[7u8; 32], b"data").unwrap();
        let e = open(&[8u8; 32], &sealed).unwrap_err().to_string();
        assert_eq!(e, DIFFERENT_WALLET);
    }

    #[test]
    fn tampering_is_detected() {
        let root = [7u8; 32];
        let mut sealed = seal(&root, b"some history").unwrap();
        let last = sealed.len() - 1;
        sealed[last] ^= 1;
        assert!(open(&root, &sealed)
            .unwrap_err()
            .to_string()
            .contains("damaged"));
        let mut sealed = seal(&root, b"some history").unwrap();
        sealed[HEADER_LEN - 1] ^= 1; // nonce, part of the AAD
        assert!(open(&root, &sealed)
            .unwrap_err()
            .to_string()
            .contains("damaged"));
        assert!(open(&root, b"not a file")
            .unwrap_err()
            .to_string()
            .contains("not a history file"));
        let mut sealed = seal(&root, b"x").unwrap();
        sealed[4] = 9;
        assert!(open(&root, &sealed)
            .unwrap_err()
            .to_string()
            .contains("newer version"));
    }

    fn tx(note: &str, counterparty: &str) -> TxEntry {
        TxEntry {
            key: "s:1".into(),
            id: Some(1),
            slate_id: Some("1".into()),
            kind: TxKind::Sent,
            status: TxStatus::Confirmed,
            source: TxSource::Wallet,
            created_at_unix: 1_790_000_000,
            time_unix: 1_790_000_000,
            confirmed: true,
            block_height: Some(12),
            block_time_unix: None,
            amount_credited: 50_000_000,
            amount_debited: 200_000_000,
            fee: Some(800_000),
            num_inputs: 1,
            num_outputs: 1,
            kernel_excess: Some("08ab".into()),
            output_commits: vec![],
            counterparty: Some(counterparty.into()),
            note: Some(note.into()),
            ttl_cutoff_height: None,
            cancellable: false,
            repostable: false,
            status_detail: None,
            releasable: false,
            finalized_at_unix: None,
        }
    }

    #[test]
    fn csv_quotes_and_defuses_formulas() {
        let out = csv(
            &[tx("rent, \"march\"\nsecond line", "=HYPERLINK(\"x\")")],
            Some(40),
        );
        let mut lines = out.splitn(2, '\n');
        assert_eq!(
            lines.next().unwrap(),
            "date,type,status,amount_epic,fee_epic,counterparty,note,slate_id,kernel,block_height"
        );
        assert_eq!(
            lines.next().unwrap(),
            "2026-09-21T14:13:20Z,Sent,Completed,-1.49200000,0.00800000,\
             \"'=HYPERLINK(\"\"x\"\")\",\"rent, \"\"march\"\"\nsecond line\",1,08ab,12\n"
        );
        assert_eq!(epic_decimal(5), "0.00000005");

        let mut t = tx("", "");
        assert_eq!(status_words(&t, Some(15)), "Confirming 4/10");
        assert_eq!(status_words(&t, Some(21)), "Completed");
        assert_eq!(status_words(&t, None), "Completed");
        t.status = TxStatus::AwaitingRecipient;
        assert_eq!(status_words(&t, Some(21)), "Waiting for recipient");
        t.status = TxStatus::AwaitingConfirmation;
        t.block_height = None;
        assert_eq!(status_words(&t, Some(21)), "Confirming 0/10");
        t.kind = TxKind::Received;
        assert_eq!(status_words(&t, Some(21)), "Waiting for sender");
        t.id = None;
        assert_eq!(status_words(&t, Some(21)), "From backup, status unknown");
        t.status = TxStatus::Cancelled;
        assert_eq!(status_words(&t, Some(21)), "Cancelled");
        t.kind = TxKind::Coinbase;
        assert_eq!(type_word(t.kind), "Mining reward");
        assert_eq!(iso_utc(0), "1970-01-01T00:00:00Z");
        assert_eq!(iso_utc(951_782_400), "2000-02-29T00:00:00Z");
    }
}
