//! Slate JSON in the exact shape epic-wallet's CLI writes to slate files
//! (`impls/src/adapters/file.rs`, `PathToSlate::put_tx`), so our slates and the CLI's interoperate.

use epic_wallet_libwallet::{Slate, SlateVersion, VersionedSlate};

use super::error::{CoreError, CoreResult};

/// Parses any slate version the wallet understands and upgrades it to the current one.
pub(crate) fn from_json(json: &str) -> CoreResult<Slate> {
    Slate::deserialize_upgrade(json).map_err(|e| CoreError::InvalidSlate(e.to_string()))
}

/// V3 when the slate carries a payment proof or TTL (features V2 lacks), V2 otherwise, as the CLI does.
pub(crate) fn to_json(slate: &Slate) -> CoreResult<String> {
    let versioned = if slate.payment_proof.is_some() || slate.ttl_cutoff_height.is_some() {
        VersionedSlate::into_version(slate.clone(), SlateVersion::V3)
    } else {
        let mut s = slate.clone();
        s.version_info.version = 2;
        s.version_info.orig_version = 2;
        VersionedSlate::into_version(s, SlateVersion::V2)
    };
    serde_json::to_string(&versioned).map_err(|e| CoreError::InvalidSlate(e.to_string()))
}
