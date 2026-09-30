//! Which wallet directories are in use, so a delete waits for them.
//!
//! Dart drops a wallet at once, but the Rust `Session` goes only when a call still running on it
//! returns (a refresh, `enrich_history`, the listener finalizing a payment). Deleting the
//! directory before that lets the late call write `wfe_meta.json` again, and the next wallet in
//! the same directory would inherit the old notes and contacts. Every `Session` holds a
//! [`DirLease`]; [`delete_wallet_dir`] waits for the last one, keeps new ones out meanwhile, and
//! only then removes the directory.

use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::sync::{Condvar, Mutex, MutexGuard};
use std::time::{Duration, Instant};

use super::error::{CoreError, CoreResult};

/// How long a delete waits for calls on the wallet to finish.
pub(crate) const DELETE_WAIT: Duration = Duration::from_secs(20);

#[derive(Default)]
struct State {
    open: HashMap<PathBuf, usize>,
    deleting: HashSet<PathBuf>,
}

struct Dirs {
    state: Mutex<Option<State>>,
    changed: Condvar,
}

static DIRS: Dirs = Dirs {
    state: Mutex::new(None),
    changed: Condvar::new(),
};

fn lock() -> MutexGuard<'static, Option<State>> {
    DIRS.state.lock().unwrap_or_else(|p| p.into_inner())
}

/// The same spelling of a directory always gives the same key, whether or not it exists.
fn key(dir: &str) -> PathBuf {
    Path::new(dir.trim()).components().collect()
}

fn wait(
    guard: MutexGuard<'static, Option<State>>,
    deadline: Instant,
) -> Option<MutexGuard<'static, Option<State>>> {
    let left = deadline.saturating_duration_since(Instant::now());
    if left.is_zero() {
        return None;
    }
    Some(
        DIRS.changed
            .wait_timeout(guard, left)
            .unwrap_or_else(|p| p.into_inner())
            .0,
    )
}

/// Marks a wallet directory in use. Released on drop.
#[derive(Debug)]
pub(crate) struct DirLease(PathBuf);

impl DirLease {
    /// Fails while the directory is being deleted (after waiting for the delete to finish).
    pub(crate) fn acquire(dir: &str) -> CoreResult<DirLease> {
        let k = key(dir);
        let deadline = Instant::now() + DELETE_WAIT;
        let mut g = lock();
        loop {
            let s = g.get_or_insert_with(State::default);
            if !s.deleting.contains(&k) {
                *s.open.entry(k.clone()).or_insert(0) += 1;
                return Ok(DirLease(k));
            }
            g = wait(g, deadline)
                .ok_or_else(|| CoreError::Busy("this wallet is being deleted".into()))?;
        }
    }
}

impl Drop for DirLease {
    fn drop(&mut self) {
        let mut g = lock();
        if let Some(s) = g.as_mut() {
            if let Some(n) = s.open.get_mut(&self.0) {
                *n -= 1;
                if *n == 0 {
                    s.open.remove(&self.0);
                }
            }
        }
        DIRS.changed.notify_all();
    }
}

/// Removes `dir` once no wallet uses it, waiting up to `max_wait`. A missing directory is fine.
pub(crate) fn delete_wallet_dir(dir: &str, max_wait: Duration) -> CoreResult<()> {
    if dir.trim().is_empty() {
        return Err(CoreError::InvalidArgument("data_dir is empty".into()));
    }
    let k = key(dir);
    let deadline = Instant::now() + max_wait;
    let mut g = lock();
    g.get_or_insert_with(State::default)
        .deleting
        .insert(k.clone());
    let result = loop {
        let busy = g.as_ref().is_some_and(|s| s.open.contains_key(&k));
        if !busy {
            break match std::fs::remove_dir_all(dir.trim()) {
                Ok(()) => Ok(()),
                Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(()),
                Err(e) => Err(CoreError::Io(format!("deleting {dir}: {e}"))),
            };
        }
        match wait(g, deadline) {
            Some(next) => g = next,
            None => {
                g = lock();
                break Err(CoreError::Busy(
                    "the wallet is still finishing a task; try again in a moment".into(),
                ));
            }
        }
    };
    if let Some(s) = g.as_mut() {
        s.deleting.remove(&k);
    }
    DIRS.changed.notify_all();
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn delete_waits_for_the_last_lease_and_keeps_new_ones_out() {
        let tmp = tempfile::tempdir().unwrap();
        let dir = tmp.path().join("w");
        std::fs::create_dir_all(&dir).unwrap();
        std::fs::write(dir.join("wfe_meta.json"), b"{}").unwrap();
        let d = dir.to_str().unwrap().to_owned();

        let lease = DirLease::acquire(&d).unwrap();
        let e = delete_wallet_dir(&d, Duration::from_millis(100)).unwrap_err();
        assert!(matches!(e, CoreError::Busy(_)), "{e}");
        assert!(dir.exists(), "not deleted while in use");

        let releaser = std::thread::spawn(move || {
            std::thread::sleep(Duration::from_millis(200));
            drop(lease);
        });
        let start = Instant::now();
        delete_wallet_dir(&d, Duration::from_secs(5)).unwrap();
        assert!(start.elapsed() >= Duration::from_millis(150), "it waited");
        assert!(!dir.exists());
        releaser.join().unwrap();

        // A deleted directory can be used again, and deleting a missing one is fine.
        drop(DirLease::acquire(&d).unwrap());
        delete_wallet_dir(&d, Duration::ZERO).unwrap();
    }
}
