//! Wallet passwords the user never sees, sealed under a PIN. See `core/vault.rs` for the
//! construction. The app keeps the sealed text in the platform's secure storage.

use flutter_rust_bridge::frb;

use crate::api::types::WalletError;
use crate::api::wallet::to_api;
use crate::core::vault;

/// A new random wallet password (256 bits, hex encoded).
#[frb(sync)]
pub fn generate_wallet_password() -> Result<String, WalletError> {
    vault::generate_password().map_err(to_api)
}

/// Seals `password` under `pin`. Slow on purpose (PBKDF2, 210k rounds), so it runs off the UI
/// thread. The result is text safe to store.
pub fn seal_password(pin: String, password: String) -> Result<String, WalletError> {
    let pin = zeroize::Zeroizing::new(pin);
    let password = zeroize::Zeroizing::new(password);
    vault::seal(&pin, &password, vault::DEFAULT_ITERATIONS).map_err(to_api)
}

/// Opens text from `seal_password`. A wrong PIN gives `WalletErrorKind::WrongPassword`; damaged
/// text gives `InvalidArgument`.
pub fn open_password(pin: String, sealed: String) -> Result<String, WalletError> {
    let pin = zeroize::Zeroizing::new(pin);
    vault::open(&pin, &sealed).map_err(to_api)
}
