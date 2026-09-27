//! Wallet password generation and PIN sealing.
//!
//! The app creates each wallet with a random password the user never sees. The password is stored
//! sealed under a key derived from the user's PIN: PBKDF2-HMAC-SHA512 over the PIN and a random
//! salt, then ChaCha20-Poly1305. A PIN has little entropy, so the sealed text must also live in
//! the platform's secure storage (Android Keystore, iOS Keychain, libsecret), and the app limits
//! attempts. The same primitives protect epic-wallet's own `wallet.seed`.

use ring::aead::{Aad, LessSafeKey, Nonce, UnboundKey, CHACHA20_POLY1305, NONCE_LEN};
use ring::pbkdf2;
use ring::rand::{SecureRandom, SystemRandom};
use std::num::NonZeroU32;
use zeroize::{Zeroize, Zeroizing};

use super::error::{CoreError, CoreResult};

/// Format tag of the sealed text. Bump it when the construction changes.
const VERSION: &str = "v1";
/// OWASP's 2023 figure for PBKDF2-HMAC-SHA512.
pub(crate) const DEFAULT_ITERATIONS: u32 = 210_000;
const SALT_LEN: usize = 16;
const PASSWORD_BYTES: usize = 32;
const AAD: &[u8] = b"epic-wallet-vault-v1";

fn random_bytes<const N: usize>() -> CoreResult<[u8; N]> {
    let mut buf = [0u8; N];
    SystemRandom::new()
        .fill(&mut buf)
        .map_err(|_| CoreError::InvalidArgument("the system random generator failed".into()))?;
    Ok(buf)
}

/// A new wallet password: 32 bytes from the OS generator, hex encoded (256 bits).
pub(crate) fn generate_password() -> CoreResult<String> {
    let mut bytes = random_bytes::<PASSWORD_BYTES>()?;
    let password = hex::encode(bytes);
    bytes.zeroize();
    Ok(password)
}

fn derive_key(pin: &str, salt: &[u8], iterations: NonZeroU32) -> CoreResult<LessSafeKey> {
    let mut key = Zeroizing::new([0u8; 32]);
    pbkdf2::derive(
        pbkdf2::PBKDF2_HMAC_SHA512,
        iterations,
        salt,
        pin.as_bytes(),
        &mut key[..],
    );
    let unbound = UnboundKey::new(&CHACHA20_POLY1305, &key[..])
        .map_err(|_| CoreError::InvalidArgument("bad key length".into()))?;
    Ok(LessSafeKey::new(unbound))
}

/// Seals `secret` under `pin`. Output: `v1.<iterations>.<salt>.<nonce>.<ciphertext>`, hex parts.
pub(crate) fn seal(pin: &str, secret: &str, iterations: u32) -> CoreResult<String> {
    if pin.is_empty() {
        return Err(CoreError::InvalidArgument("the PIN is empty".into()));
    }
    let rounds = NonZeroU32::new(iterations)
        .ok_or_else(|| CoreError::InvalidArgument("iterations must be positive".into()))?;
    let salt = random_bytes::<SALT_LEN>()?;
    let nonce = random_bytes::<NONCE_LEN>()?;
    let key = derive_key(pin, &salt, rounds)?;
    let mut data = Zeroizing::new(secret.as_bytes().to_vec());
    key.seal_in_place_append_tag(
        Nonce::assume_unique_for_key(nonce),
        Aad::from(AAD),
        &mut *data,
    )
    .map_err(|_| CoreError::InvalidArgument("sealing failed".into()))?;
    Ok(format!(
        "{VERSION}.{iterations}.{}.{}.{}",
        hex::encode(salt),
        hex::encode(nonce),
        hex::encode(&*data)
    ))
}

fn malformed() -> CoreError {
    CoreError::InvalidArgument("the stored wallet key is damaged".into())
}

/// Opens text from [`seal`]. A wrong PIN gives [`CoreError::WrongPassword`].
pub(crate) fn open(pin: &str, sealed: &str) -> CoreResult<String> {
    let parts: Vec<&str> = sealed.split('.').collect();
    let [version, iterations, salt, nonce, data] = parts[..] else {
        return Err(malformed());
    };
    if version != VERSION {
        return Err(malformed());
    }
    let rounds = iterations
        .parse::<u32>()
        .ok()
        .and_then(NonZeroU32::new)
        .ok_or_else(malformed)?;
    let salt = hex::decode(salt).map_err(|_| malformed())?;
    let nonce: [u8; NONCE_LEN] = hex::decode(nonce)
        .map_err(|_| malformed())?
        .try_into()
        .map_err(|_| malformed())?;
    let mut data = Zeroizing::new(hex::decode(data).map_err(|_| malformed())?);
    let key = derive_key(pin, &salt, rounds)?;
    let plain = key
        .open_in_place(
            Nonce::assume_unique_for_key(nonce),
            Aad::from(AAD),
            &mut *data,
        )
        .map_err(|_| CoreError::WrongPassword)?;
    String::from_utf8(plain.to_vec()).map_err(|_| malformed())
}

#[cfg(test)]
mod tests {
    use super::*;

    // Few rounds keep the unoptimised test build fast; the format carries the count.
    const FAST: u32 = 1_000;

    #[test]
    fn passwords_are_long_random_hex() {
        let a = generate_password().unwrap();
        let b = generate_password().unwrap();
        assert_eq!(a.len(), 64);
        assert!(a.chars().all(|c| c.is_ascii_hexdigit()));
        assert_ne!(a, b);
    }

    #[test]
    fn seal_round_trips_and_rejects_wrong_pin() {
        let sealed = seal("123456", "wallet password", FAST).unwrap();
        assert!(sealed.starts_with("v1.1000."));
        assert_eq!(open("123456", &sealed).unwrap(), "wallet password");
        assert!(matches!(
            open("654321", &sealed),
            Err(CoreError::WrongPassword)
        ));
    }

    #[test]
    fn same_input_seals_differently() {
        let a = seal("123456", "secret", FAST).unwrap();
        let b = seal("123456", "secret", FAST).unwrap();
        assert_ne!(a, b, "salt and nonce must be fresh");
    }

    #[test]
    fn damaged_text_is_not_a_wrong_pin() {
        let sealed = seal("123456", "secret", FAST).unwrap();
        for bad in [
            "",
            "v2.1000.00.00.00",
            "v1.0.00.00.00",
            "v1.1000.zz.00.00",
            &sealed[..sealed.len() - 2],
        ] {
            let result = open("123456", bad);
            assert!(
                !matches!(result, Ok(_)),
                "damaged text {bad:?} must not open"
            );
        }
        // A short nonce is a format error, not a wrong PIN.
        assert!(matches!(
            open("123456", "v1.1000.00.0011.00"),
            Err(CoreError::InvalidArgument(_))
        ));
    }

    #[test]
    fn empty_pin_is_refused() {
        assert!(matches!(
            seal("", "secret", FAST),
            Err(CoreError::InvalidArgument(_))
        ));
    }
}
