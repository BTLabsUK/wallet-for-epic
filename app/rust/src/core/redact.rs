//! Scrubs secrets from text before it is logged or put in a feedback report.
//!
//! The Dart twin is `lib/src/redact.dart`. Both apply the same rules, in this order, and both
//! have tests for them:
//!
//! 1. A slate (text with `"participant_data"`, `"public_blind_excess"` or `"part_sig"`) becomes
//!    `[slate]` from its first `{` on.
//! 2. A run of 8 or more recovery-phrase words, separated only by spaces, digits and list
//!    punctuation, becomes `[words]`.
//! 3. The value after a secret key (`password=`, `pin: `, `"token":"`, `Bearer `) becomes
//!    `[redacted]`, and so does a 4 to 8 digit number right after `pin`.
//! 4. A UUID keeps its first 8 characters and gets `…`. 32 or more hex digits become `[hex]`
//!    (kernels, commitments, keys). Any other run of 64 or more token characters that is not a
//!    URL path becomes `[redacted]` (FCM tokens, JWTs, base64). 40 or more base58 characters, an
//!    epicbox address key, keep the first 6 and get `…`, so `es…@relay` stays readable.

use epic_wallet_util::epic_keychain::mnemonic;

/// Words in a row that count as a recovery phrase. Phrases have 12 or 24; a shorter run still
/// gives most of one away. Ordinary sentences rarely string 8 wordlist words together, because
/// the most common English words ("the", "a", "to", "is") are not on the list.
pub(crate) const PHRASE_RUN: usize = 8;

/// Keys whose value is secret. Matched case-insensitively, as a whole word, where `_` and `.`
/// count as word breaks, so `keychain_mask` and `fcm_token` match.
const SECRET_KEYS: &[&str] = &[
    "password",
    "passphrase",
    "pin",
    "mnemonic",
    "phrase",
    "seed",
    "mask",
    "token",
    "secret",
    "api_key",
    "apikey",
    "authorization",
];

/// Schemes whose credential follows after a space.
const AUTH_SCHEMES: &[&str] = &["bearer", "basic"];

const SLATE_MARKERS: &[&str] = &[
    "\"participant_data\"",
    "\"public_blind_excess\"",
    "\"part_sig\"",
];

pub(crate) const REDACTED: &str = "[redacted]";

/// `text` with every secret the rules above recognise replaced.
pub(crate) fn redact(text: &str) -> String {
    let text = redact_slate(text);
    let text = redact_phrases(&text);
    let text = redact_keyed(&text);
    let text = replace_runs(&text, is_uuid_byte, |run| {
        is_uuid(run).then(|| format!("{}…", &run[..8]))
    });
    let text = replace_runs(&text, is_alnum, |run| {
        (run.len() >= 32 && run.bytes().all(|b| b.is_ascii_hexdigit())).then(|| "[hex]".into())
    });
    // Before the base58 rule, which would otherwise keep the start of a long token.
    let text = replace_runs(&text, is_token_byte, |run| {
        (run.len() >= 64 && !run.contains("//")).then(|| REDACTED.into())
    });
    replace_runs(&text, is_alnum, |run| {
        (run.len() >= 40 && run.bytes().all(is_base58)).then(|| format!("{}…", &run[..6]))
    })
}

fn redact_slate(text: &str) -> String {
    if !SLATE_MARKERS.iter().any(|m| text.contains(m)) {
        return text.to_owned();
    }
    match text.find('{') {
        Some(i) => format!("{}[slate]", &text[..i]),
        None => "[slate]".into(),
    }
}

/// Byte ranges of the ASCII letter runs in `text`.
fn words(text: &str) -> Vec<(usize, usize)> {
    let bytes = text.as_bytes();
    let mut out = Vec::new();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i].is_ascii_alphabetic() {
            let start = i;
            while i < bytes.len() && bytes[i].is_ascii_alphabetic() {
                i += 1;
            }
            out.push((start, i));
        } else {
            i += 1;
        }
    }
    out
}

/// Whether the gap between two words keeps them in one phrase: spaces, digits (numbered lists)
/// and list punctuation only.
fn joins(gap: &str) -> bool {
    !gap.is_empty()
        && gap
            .bytes()
            .all(|b| b.is_ascii_whitespace() || b.is_ascii_digit() || b",.;:)(-".contains(&b))
}

fn is_phrase_word(word: &str) -> bool {
    (3..=8).contains(&word.len()) && mnemonic::search(&word.to_ascii_lowercase()).is_ok()
}

fn redact_phrases(text: &str) -> String {
    let words = words(text);
    let mut spans = Vec::new();
    let mut run: Option<(usize, usize, usize)> = None; // start, end, count
    for (i, &(start, end)) in words.iter().enumerate() {
        let word = &text[start..end];
        if !is_phrase_word(word) {
            if let Some(r) = run.take() {
                spans.push(r);
            }
            continue;
        }
        let continues = i > 0 && run.is_some() && joins(&text[words[i - 1].1..start]);
        run = match run {
            Some((s, _, n)) if continues => Some((s, end, n + 1)),
            previous => {
                if let Some(r) = previous {
                    spans.push(r);
                }
                Some((start, end, 1))
            }
        };
    }
    if let Some(r) = run {
        spans.push(r);
    }
    let mut out = String::with_capacity(text.len());
    let mut at = 0;
    for (start, end, n) in spans {
        if n >= PHRASE_RUN {
            out.push_str(&text[at..start]);
            out.push_str("[words]");
            at = end;
        }
    }
    out.push_str(&text[at..]);
    out
}

fn is_word_byte(b: u8) -> bool {
    b.is_ascii_alphanumeric()
}

fn ends_value(b: u8) -> bool {
    b.is_ascii_whitespace() || b"\"',;})]&<".contains(&b)
}

fn skip(bytes: &[u8], mut i: usize, what: impl Fn(u8) -> bool) -> usize {
    while i < bytes.len() && what(bytes[i]) {
        i += 1;
    }
    i
}

/// Where the secret after the key ending at `after` sits, if one does.
fn keyed_value(key: &str, bytes: &[u8], after: usize) -> Option<(usize, usize)> {
    let quote_or_space = |b: u8| b == b'"' || b == b'\'' || b == b' ' || b == b'\t';
    let mut i = skip(bytes, after, quote_or_space);
    let start;
    if AUTH_SCHEMES.contains(&key) {
        if i == after || i >= bytes.len() {
            return None;
        }
        start = i;
    } else if i < bytes.len() && (bytes[i] == b':' || bytes[i] == b'=') {
        i = skip(bytes, i + 1, quote_or_space);
        start = i;
    } else if key == "pin" {
        // "PIN 123456": a bare number after the word.
        let end = skip(bytes, i, |b| b.is_ascii_digit());
        let digits = end - i;
        let bounded = end >= bytes.len() || !bytes[end].is_ascii_alphanumeric();
        return ((4..=8).contains(&digits) && bounded).then_some((i, end));
    } else {
        return None;
    }
    let end = skip(bytes, start, |b| !ends_value(b));
    (end > start).then_some((start, end))
}

fn redact_keyed(text: &str) -> String {
    // ASCII lowercasing keeps every byte offset.
    let lower = text.to_ascii_lowercase();
    let bytes = text.as_bytes();
    let mut spans: Vec<(usize, usize)> = Vec::new();
    for key in SECRET_KEYS.iter().chain(AUTH_SCHEMES) {
        let mut from = 0;
        while let Some(found) = lower[from..].find(key) {
            let at = from + found;
            let after = at + key.len();
            from = after;
            let starts_word = at == 0 || !is_word_byte(bytes[at - 1]);
            let ends_word = after >= bytes.len() || !is_word_byte(bytes[after]);
            if !(starts_word && ends_word) {
                continue;
            }
            if let Some(span) = keyed_value(key, bytes, after) {
                if &text[span.0..span.1] != REDACTED {
                    spans.push(span);
                }
            }
        }
    }
    spans.sort();
    let mut out = String::with_capacity(text.len());
    let mut at = 0;
    for (start, end) in spans {
        if start < at {
            continue;
        }
        out.push_str(&text[at..start]);
        out.push_str(REDACTED);
        at = end;
    }
    out.push_str(&text[at..]);
    out
}

fn is_alnum(b: u8) -> bool {
    b.is_ascii_alphanumeric()
}

fn is_uuid_byte(b: u8) -> bool {
    b.is_ascii_alphanumeric() || b == b'-'
}

fn is_token_byte(b: u8) -> bool {
    b.is_ascii_alphanumeric() || b"_-+/=:.~".contains(&b)
}

fn is_base58(b: u8) -> bool {
    b.is_ascii_alphanumeric() && !matches!(b, b'0' | b'O' | b'I' | b'l')
}

fn is_uuid(run: &str) -> bool {
    let groups: Vec<&str> = run.split('-').collect();
    groups.len() == 5
        && groups
            .iter()
            .zip([8, 4, 4, 4, 12])
            .all(|(g, n)| g.len() == n && g.bytes().all(|b| b.is_ascii_hexdigit()))
}

/// Replaces each maximal run of ASCII bytes in `class` for which `f` gives a replacement.
fn replace_runs(text: &str, class: fn(u8) -> bool, f: impl Fn(&str) -> Option<String>) -> String {
    let bytes = text.as_bytes();
    let mut out = String::with_capacity(text.len());
    let mut at = 0;
    let mut i = 0;
    while i < bytes.len() {
        if !class(bytes[i]) {
            i += 1;
            continue;
        }
        let start = i;
        i = skip(bytes, i, class);
        // Runs are ASCII and bounded by ASCII or non-class bytes, so these are char boundaries.
        if let Some(replacement) = f(&text[start..i]) {
            out.push_str(&text[at..start]);
            out.push_str(&replacement);
            at = i;
        }
    }
    out.push_str(&text[at..]);
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    const PHRASE: &str = "abandon ability able about above absent absorb abstract absurd abuse \
                          access accident";
    const ADDRESS: &str =
        "esWn9r2zQj5eKkVh3sT4YpX7cBdF8gHmNaLuRvS6tE1iPo2wZxC9@epicbox.epiccash.com";

    #[test]
    fn a_recovery_phrase_is_scrubbed() {
        let out = redact(&format!("restoring from {PHRASE}"));
        assert_eq!(out, "restoring from [words]");
        let numbered = "1. abandon 2. ability 3. able 4. about 5. above 6. absent 7. absorb \
                        8. abstract 9. absurd";
        assert!(
            !redact(numbered).contains("abandon"),
            "{}",
            redact(numbered)
        );
        assert!(!redact(&PHRASE.to_uppercase()).contains("ABANDON"));
    }

    #[test]
    fn ordinary_sentences_keep_their_words() {
        let text = "the payment to alice could not reach the node, please try again later";
        assert_eq!(redact(text), text);
        // Seven wordlist words in a row are below the threshold.
        let seven = "abandon ability able about above absent absorb";
        assert_eq!(redact(seven), seven);
    }

    #[test]
    fn a_pin_is_scrubbed_in_every_shape() {
        assert_eq!(redact("PIN 123456 rejected"), "PIN [redacted] rejected");
        assert_eq!(redact("pin=654321"), "pin=[redacted]");
        assert_eq!(redact(r#"{"pin": "112233"}"#), r#"{"pin": "[redacted]"}"#);
        assert_eq!(redact("Wrong PIN, 3 tries left"), "Wrong PIN, 3 tries left");
        assert_eq!(redact("pinned 123456"), "pinned 123456");
    }

    #[test]
    fn secret_keys_lose_their_values() {
        assert_eq!(redact("password=hunter2 ok"), "password=[redacted] ok");
        assert_eq!(redact("keychain_mask: 00ff"), "keychain_mask: [redacted]");
        assert_eq!(
            redact("Authorization: Bearer abc.def"),
            "Authorization: [redacted] [redacted]"
        );
        assert_eq!(redact("fcm_token=cX1:APA91b"), "fcm_token=[redacted]");
        assert_eq!(redact("password was wrong"), "password was wrong");
    }

    #[test]
    fn an_epicbox_address_keeps_only_its_start_and_relay() {
        let out = redact(&format!("sent to {ADDRESS}."));
        assert_eq!(out, "sent to esWn9r…@epicbox.epiccash.com.");
    }

    #[test]
    fn ids_hex_and_tokens_are_shortened_or_dropped() {
        assert_eq!(
            redact("slate 0f3b2a1c-9d8e-4f7a-b6c5-d4e3f2a1b0c9 posted"),
            "slate 0f3b2a1c… posted"
        );
        let kernel = "08a4c7e1f2b3d4c5e6f708192a3b4c5d6e7f8091a2b3c4d5e6f708192a3b4c5d6e";
        assert_eq!(redact(&format!("kernel {kernel}")), "kernel [hex]");
        assert_eq!(
            redact(&format!("GET /v1/kernel/{kernel}")),
            "GET /v1/kernel/[hex]"
        );
        let fcm = format!("cX1abc:APA91b{}", "Q".repeat(140));
        assert_eq!(redact(&format!("token {fcm}")), "token [redacted]");
        let url =
            "https://github.com/blacktyger/wallet-for-epic/releases/latest/download/update.json";
        assert_eq!(redact(url), url);
        assert_eq!(
            redact("node https://node.btlabs.uk"),
            "node https://node.btlabs.uk"
        );
    }

    #[test]
    fn slates_are_dropped_whole() {
        let slate = r#"invalid slate {"id":"x","participant_data":[{"part_sig":"ab"}]}"#;
        assert_eq!(redact(slate), "invalid slate [slate]");
    }

    #[test]
    fn redaction_is_stable_when_applied_twice() {
        let text = format!("{PHRASE} pin 123456 to {ADDRESS} 0f3b2a1c-9d8e-4f7a-b6c5-d4e3f2a1b0c9");
        let once = redact(&text);
        assert_eq!(redact(&once), once);
    }

    #[test]
    fn non_ascii_text_passes_through() {
        assert_eq!(redact("Zahlung für Café ✓"), "Zahlung für Café ✓");
    }
}
