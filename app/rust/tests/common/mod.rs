//! Helpers shared by the integration tests. Each test binary is one process, and one process uses
//! one chain, so a binary never mixes chains except where that is the point (`chain.rs`).
#![allow(dead_code)]

use std::path::Path;

use epic_wallet_core::api::types::{Chain, WalletConfig, WalletError, WalletErrorKind};

pub const EPIC: u64 = 100_000_000;
pub const PASSWORD: &str = "correct horse battery staple";

/// A port nothing listens on, so node calls fail fast with connection refused.
pub const DEAD_NODE: &str = "http://127.0.0.1:9";

pub fn config(dir: &Path, chain: Chain, node_url: &str) -> WalletConfig {
    WalletConfig {
        data_dir: dir.to_string_lossy().into_owned(),
        chain,
        node_url: node_url.to_owned(),
        node_api_secret: None,
        epicbox_domain: "epicbox.epiccash.com".to_owned(),
        epicbox_port: 443,
    }
}

/// The error kind of a failed call. Never formats the Ok value, which may be a seed.
pub fn kind_of<T>(r: Result<T, WalletError>) -> WalletErrorKind {
    match r {
        Ok(_) => panic!("expected an error, got Ok"),
        Err(e) => e.kind,
    }
}

struct StderrLogger;
impl log::Log for StderrLogger {
    fn enabled(&self, m: &log::Metadata) -> bool {
        m.level() <= log::Level::Info
    }
    fn log(&self, r: &log::Record) {
        if self.enabled(r.metadata()) {
            eprintln!("[{}] {}: {}", r.level(), r.target(), r.args());
        }
    }
    fn flush(&self) {}
}
static LOGGER: StderrLogger = StderrLogger;

/// Routes epic-wallet's own `log` output (info and above) to stderr, which cargo captures per test.
pub fn init_logging() {
    if log::set_logger(&LOGGER).is_ok() {
        log::set_max_level(log::LevelFilter::Info);
    }
}
