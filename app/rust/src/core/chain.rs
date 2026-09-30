//! Process-wide chain selection.
//!
//! epic's consensus parameters live in one global (`epic_core::global::CHAIN_TYPE`), read by key
//! derivation, address version bytes, coinbase maturity and fee rules. One process therefore talks
//! to one chain at a time. Every open wallet holds a [`ChainLease`]; the chain can only change while
//! no lease is alive, so a mainnet wallet can never run with usernet parameters underneath it.

use std::sync::{Condvar, Mutex, MutexGuard};
use std::time::{Duration, Instant};

use epic_wallet_util::epic_core::global::{self, ChainTypes};

use super::error::CoreError;
use crate::api::types::Chain;

/// How long opening a wallet on another chain waits for the last wallet on the current chain to
/// close. Dart disposes a wallet at once, but the Rust side lets go only when a call still running
/// on it returns (a refresh can take seconds), so a network switch would otherwise fail.
pub(crate) const SWITCH_WAIT: Duration = Duration::from_secs(20);

struct State {
    chain: Option<Chain>,
    leases: usize,
}

/// Which chain is selected and how many open wallets hold it.
struct Registry {
    state: Mutex<State>,
    released: Condvar,
}

impl Registry {
    const fn new() -> Registry {
        Registry {
            state: Mutex::new(State {
                chain: None,
                leases: 0,
            }),
            released: Condvar::new(),
        }
    }

    fn lock(&self) -> MutexGuard<'_, State> {
        // The state is two plain fields, so a panic elsewhere cannot leave it inconsistent.
        self.state.lock().unwrap_or_else(|p| p.into_inner())
    }

    /// Takes a lease on `chain`, calling `select` when the chain changes. While another chain
    /// has leases, waits up to `wait` for the last one to be released.
    fn acquire(
        &self,
        chain: Chain,
        wait: Duration,
        select: impl FnOnce(Chain),
    ) -> Result<(), CoreError> {
        let deadline = Instant::now() + wait;
        let mut s = self.lock();
        loop {
            match s.chain {
                Some(active) if active != chain && s.leases > 0 => {
                    let left = deadline.saturating_duration_since(Instant::now());
                    if left.is_zero() {
                        return Err(CoreError::ChainInUse {
                            active,
                            requested: chain,
                        });
                    }
                    s = self
                        .released
                        .wait_timeout(s, left)
                        .unwrap_or_else(|p| p.into_inner())
                        .0;
                }
                _ => break,
            }
        }
        if s.chain != Some(chain) {
            select(chain);
            s.chain = Some(chain);
        }
        s.leases += 1;
        Ok(())
    }

    fn release(&self) {
        let mut s = self.lock();
        s.leases = s.leases.saturating_sub(1);
        if s.leases == 0 {
            self.released.notify_all();
        }
    }
}

static REGISTRY: Registry = Registry::new();

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
    /// Selects `chain` for this process. If wallets on another chain are open, waits up to
    /// [`SWITCH_WAIT`] for them to close, then fails with `ChainInUse`.
    pub(crate) fn acquire(chain: Chain) -> Result<ChainLease, CoreError> {
        REGISTRY.acquire(chain, SWITCH_WAIT, |c| {
            global::set_mining_mode(chain_type(c))
        })?;
        Ok(ChainLease(()))
    }
}

impl Drop for ChainLease {
    fn drop(&mut self) {
        REGISTRY.release();
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Arc;

    // A local registry, so these tests never touch the process-wide chain other tests read.

    #[test]
    fn another_chain_waits_for_the_last_lease_to_go() {
        let r = Arc::new(Registry::new());
        r.acquire(Chain::Mainnet, Duration::ZERO, |_| {}).unwrap();
        let releaser = {
            let r = r.clone();
            std::thread::spawn(move || {
                std::thread::sleep(Duration::from_millis(200));
                r.release();
            })
        };
        let start = Instant::now();
        let mut selected = None;
        r.acquire(Chain::Floonet, Duration::from_secs(5), |c| {
            selected = Some(c)
        })
        .expect("floonet once mainnet is released");
        assert!(start.elapsed() >= Duration::from_millis(150), "it waited");
        assert_eq!(selected, Some(Chain::Floonet));
        releaser.join().unwrap();
    }

    #[test]
    fn it_gives_up_after_the_wait_and_same_chain_never_waits() {
        let r = Registry::new();
        r.acquire(Chain::Mainnet, Duration::ZERO, |_| {}).unwrap();
        let start = Instant::now();
        r.acquire(Chain::Mainnet, Duration::from_secs(5), |_| {
            panic!("no switch")
        })
        .expect("a second mainnet lease");
        assert!(start.elapsed() < Duration::from_millis(100));
        let e = r
            .acquire(Chain::Usernet, Duration::from_millis(100), |_| {})
            .unwrap_err();
        assert!(matches!(
            e,
            CoreError::ChainInUse {
                active: Chain::Mainnet,
                requested: Chain::Usernet
            }
        ));
        r.release();
        assert!(
            r.acquire(Chain::Usernet, Duration::from_millis(100), |_| {})
                .is_err(),
            "one lease left"
        );
        r.release();
        r.acquire(Chain::Usernet, Duration::ZERO, |_| {})
            .expect("free now");
    }
}
