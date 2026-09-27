//! Process-wide chain selection.
//!
//! epic's consensus parameters live in one global (`epic_core::global::CHAIN_TYPE`), read by key
//! derivation, address version bytes, coinbase maturity and fee rules. One process therefore talks
//! to one chain at a time. Every open wallet holds a [`ChainLease`]; the chain can only change while
//! no lease is alive, so a mainnet wallet can never run with usernet parameters underneath it.

use std::sync::{Mutex, MutexGuard};

use epic_wallet_util::epic_core::global::{self, ChainTypes};

use super::error::CoreError;
use crate::api::types::Chain;

struct State {
    chain: Option<Chain>,
    leases: usize,
}

static STATE: Mutex<State> = Mutex::new(State {
    chain: None,
    leases: 0,
});

fn state() -> MutexGuard<'static, State> {
    // The state is two plain fields, so a panic elsewhere cannot leave it inconsistent.
    STATE
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
}

fn chain_type(chain: Chain) -> ChainTypes {
    match chain {
        Chain::Mainnet => ChainTypes::Mainnet,
        Chain::Floonet => ChainTypes::Floonet,
        Chain::Usernet => ChainTypes::UserTesting,
    }
}

/// Keeps the global chain type fixed while a wallet is open. Released on drop.
#[derive(Debug)]
pub(crate) struct ChainLease(());

impl ChainLease {
    /// Selects `chain` for this process, or fails if another chain is in use by an open wallet.
    pub(crate) fn acquire(chain: Chain) -> Result<ChainLease, CoreError> {
        let mut s = state();
        if let Some(active) = s.chain {
            if active != chain && s.leases > 0 {
                return Err(CoreError::ChainInUse {
                    active,
                    requested: chain,
                });
            }
        }
        if s.chain != Some(chain) {
            global::set_mining_mode(chain_type(chain));
            s.chain = Some(chain);
        }
        s.leases += 1;
        Ok(ChainLease(()))
    }
}

impl Drop for ChainLease {
    fn drop(&mut self) {
        let mut s = state();
        s.leases = s.leases.saturating_sub(1);
    }
}
