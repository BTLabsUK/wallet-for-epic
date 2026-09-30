//! Reads epic-wallet's stored transactions (`<data_dir>/wallet_data/saved_txs/<slate>.epictx`)
//! without panicking.
//!
//! epic-wallet's own `get_stored_tx` `unwrap`s both the hex decode and the deserialization
//! (`impls/src/backends/lmdb.rs:428-430`), so one damaged file would panic whatever called it. This
//! is the same format read with every failure turned into an error: the hex of the transaction
//! serialized at protocol version 1.

use std::path::{Path, PathBuf};

use epic_wallet_libwallet::TxLogEntry;
use epic_wallet_util::epic_core::core::Transaction;
use epic_wallet_util::epic_core::ser::{self, ProtocolVersion};
use epic_wallet_util::epic_util::from_hex;

use super::error::{CoreError, CoreResult};

/// epic-wallet's wallet directory under the app's data dir (`EPIC_WALLET_DIR`), and its
/// stored-transaction directory (`TX_SAVE_DIR`).
const WALLET_DIR: &str = "wallet_data";
const TX_SAVE_DIR: &str = "saved_txs";

fn damaged(name: &str) -> CoreError {
    CoreError::InvalidArgument(format!(
        "the saved copy of this payment ({name}) is damaged"
    ))
}

fn path_for(data_dir: &str, name: &str) -> CoreResult<PathBuf> {
    // epic-wallet writes `<uuid>.epictx`; anything with a path in it did not come from there.
    let plain = !name.is_empty()
        && !name.contains(['/', '\\'])
        && name != "."
        && name != ".."
        && !name.contains(':');
    if !plain {
        return Err(damaged(name));
    }
    Ok(Path::new(data_dir)
        .join(WALLET_DIR)
        .join(TX_SAVE_DIR)
        .join(name))
}

/// Parses the text of a stored transaction file.
pub(crate) fn parse(name: &str, text: &str) -> CoreResult<Transaction> {
    let bytes = from_hex(text.trim().to_owned()).map_err(|_| damaged(name))?;
    ser::deserialize::<Transaction>(&mut &bytes[..], ProtocolVersion(1)).map_err(|_| damaged(name))
}

/// The transaction stored for `entry`: `Ok(None)` when it has none or the file is gone, an error
/// when the file cannot be read or parsed.
pub(crate) fn load(data_dir: &str, entry: &TxLogEntry) -> CoreResult<Option<Transaction>> {
    let Some(name) = entry.stored_tx.as_deref() else {
        return Ok(None);
    };
    let path = path_for(data_dir, name)?;
    let text = match std::fs::read_to_string(&path) {
        Ok(t) => t,
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => return Ok(None),
        Err(e) => return Err(CoreError::Io(format!("reading {}: {e}", path.display()))),
    };
    parse(name, &text).map(Some)
}

/// True once the transaction carries its final kernel. Before finalization epic-wallet stores
/// the slate's transaction, whose kernel is still `TxKernel::empty()` (an all-zero excess);
/// `update_stored_tx` replaces it with the finalized one (`libwallet/src/internal/tx.rs:366`).
pub(crate) fn kernel_is_final(tx: &Transaction) -> bool {
    tx.kernels()
        .first()
        .is_some_and(|k| k.excess.0.iter().any(|b| *b != 0))
}

#[cfg(test)]
mod tests {
    use super::*;
    use epic_wallet_libwallet::TxLogEntryType;
    use epic_wallet_util::epic_core::core::TxKernel;
    use epic_wallet_util::epic_keychain::{ExtKeychain, Keychain};
    use epic_wallet_util::epic_util::secp::pedersen::Commitment;
    use epic_wallet_util::epic_util::to_hex;

    fn hex_of(tx: &Transaction) -> String {
        to_hex(ser::ser_vec(tx, ProtocolVersion(1)).unwrap())
    }

    fn entry(stored: Option<&str>) -> TxLogEntry {
        let mut e = TxLogEntry::new(
            ExtKeychain::derive_key_id(2, 0, 0, 0, 0),
            TxLogEntryType::TxSent,
            1,
        );
        e.stored_tx = stored.map(str::to_owned);
        e
    }

    fn write(dir: &Path, name: &str, text: &str) {
        let d = dir.join(WALLET_DIR).join(TX_SAVE_DIR);
        std::fs::create_dir_all(&d).unwrap();
        std::fs::write(d.join(name), text).unwrap();
    }

    #[test]
    fn reads_what_epic_wallet_writes_and_tells_final_from_unfinalized() {
        let dir = tempfile::tempdir().unwrap();
        let data_dir = dir.path().to_str().unwrap();
        let empty = Transaction::empty().with_kernel(TxKernel::empty());
        write(dir.path(), "a.epictx", &hex_of(&empty));
        let loaded = load(data_dir, &entry(Some("a.epictx"))).unwrap().unwrap();
        assert!(!kernel_is_final(&loaded), "the slate's placeholder kernel");

        let mut kernel = TxKernel::empty();
        kernel.excess = Commitment::from_vec(vec![8; 33]);
        let final_tx = Transaction::empty().with_kernel(kernel);
        write(dir.path(), "b.epictx", &hex_of(&final_tx));
        assert!(kernel_is_final(
            &load(data_dir, &entry(Some("b.epictx"))).unwrap().unwrap()
        ));
    }

    #[test]
    fn damaged_or_missing_files_are_errors_not_panics() {
        let dir = tempfile::tempdir().unwrap();
        let data_dir = dir.path().to_str().unwrap();
        assert!(load(data_dir, &entry(None)).unwrap().is_none());
        assert!(load(data_dir, &entry(Some("gone.epictx")))
            .unwrap()
            .is_none());
        write(dir.path(), "odd.epictx", "abc");
        write(dir.path(), "junk.epictx", "zz");
        write(dir.path(), "short.epictx", "0001");
        for name in ["odd.epictx", "junk.epictx", "short.epictx"] {
            let e = load(data_dir, &entry(Some(name))).unwrap_err().to_string();
            assert!(e.contains("damaged"), "{name}: {e}");
        }
        for name in ["../x.epictx", "a/b.epictx", "..", "", "c:\\x"] {
            assert!(load(data_dir, &entry(Some(name))).is_err(), "{name:?}");
        }
    }
}
