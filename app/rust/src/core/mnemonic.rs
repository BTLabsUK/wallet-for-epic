//! BIP-39 phrases, using epic's own wordlist and checksum code (`epic_keychain::mnemonic`), which is
//! what `WalletSeed` uses to turn a phrase into the wallet seed.

use epic_wallet_util::epic_keychain::mnemonic;
use epic_wallet_util::epic_util::secp::rand::{rng, Rng};
use epic_wallet_util::epic_util::ZeroingString;
use zeroize::Zeroize;

use super::error::{CoreError, CoreResult};

/// A new random phrase of `word_count` words (12 or 24).
pub(crate) fn generate(word_count: u32) -> CoreResult<String> {
    let entropy_len = match word_count {
        12 => 16,
        24 => 32,
        other => {
            return Err(CoreError::InvalidArgument(format!(
                "word_count must be 12 or 24, got {other}"
            )))
        }
    };
    let mut entropy = vec![0u8; entropy_len];
    rng().fill(&mut entropy[..]);
    let phrase = mnemonic::from_entropy(&entropy);
    entropy.zeroize();
    phrase.map_err(|_| CoreError::InvalidMnemonic)
}

/// Lowercases in place (the wordlist is ASCII) and moves the phrase into a `ZeroingString`.
pub(crate) fn normalize(mut phrase: String) -> ZeroingString {
    phrase.make_ascii_lowercase();
    ZeroingString::from(phrase)
}

/// True when every word is in the wordlist and the checksum matches.
pub(crate) fn is_valid(phrase: &ZeroingString) -> bool {
    match mnemonic::to_entropy(phrase) {
        Ok(mut entropy) => {
            entropy.zeroize();
            true
        }
        Err(_) => false,
    }
}
