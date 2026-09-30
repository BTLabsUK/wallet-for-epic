//! The app's log file, for Dart: where it goes, lines Dart adds, and its tail for a feedback
//! report. `core/logging.rs` has the levels and size limits, `core/redact.rs` what is scrubbed.

use std::path::Path;

use flutter_rust_bridge::frb;

use crate::api::types::WalletError;
use crate::api::wallet::to_api;
use crate::core::error::CoreError;
use crate::core::{logging, redact};

/// Severity of a line Dart logs. Lines below `Info` are not written.
pub enum LogLevel {
    Error,
    Warn,
    Info,
}

/// Starts writing the log to `<dir>/wfe.log`, beginning with the lines logged since the
/// process started (up to 256, kept in memory until now). Returns the file's path.
pub fn init_logging(dir: String) -> Result<String, WalletError> {
    logging::init(Path::new(&dir))
        .map(|p| p.display().to_string())
        .map_err(|e| to_api(CoreError::Io(format!("opening the log in {dir}: {e}"))))
}

/// Adds one line from Dart, under the target `dart.<tag>`. The line is redacted before it is
/// written, so a mistake on the Dart side does not reach the file.
#[frb(sync)]
pub fn log_message(level: LogLevel, tag: String, message: String) {
    let level = match level {
        LogLevel::Error => log::Level::Error,
        LogLevel::Warn => log::Level::Warn,
        LogLevel::Info => log::Level::Info,
    };
    let tag: String = tag
        .chars()
        .filter(|c| c.is_ascii_alphanumeric() || *c == '_')
        .take(32)
        .collect();
    logging::emit(level, &format!("{}.{tag}", logging::DART_TARGET), &message);
}

/// The newest `max_bytes` of the log (the current file and the one before it), from a whole
/// line on, redacted once more.
pub fn read_log_tail(max_bytes: u32) -> String {
    logging::tail(max_bytes as usize)
}

/// `text` with every secret the log's redaction recognises replaced, for text that leaves the
/// device by another way, such as a feedback message.
#[frb(sync)]
pub fn redact_text(text: String) -> String {
    redact::redact(&text)
}
