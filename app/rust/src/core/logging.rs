//! The process logger: one rotating log file for the Rust core and the Dart UI, redacted at the
//! sink.
//!
//! Levels: `info` for this crate and for Dart (`dart.*` targets), `warn` for every dependency,
//! epic-wallet included, whose `info` lines are per-output chatter.
//!
//! Size: `wfe.log` grows to 1 MB, then becomes `wfe.log.1`, replacing the previous one, so the log
//! never takes more than 2 MB. At about 100 bytes a line that is some 20 000 lines, weeks of
//! normal use, and the 256 KB a feedback report attaches always fits in the two files, even right
//! after a rotation. Two files and no compression keep rotation to one rename.
//!
//! On Android every line also goes to logcat under the tag `wfe`. Desktop debug builds copy lines
//! to stderr. Release builds elsewhere write only the file.

use std::collections::VecDeque;
use std::fs::{self, File, OpenOptions};
use std::io::{Read, Seek, SeekFrom, Write};
use std::path::{Path, PathBuf};
use std::sync::{Mutex, Once};
use std::time::{SystemTime, UNIX_EPOCH};

use log::{Level, LevelFilter, Log, Metadata, Record};

use super::redact::redact;

pub(crate) const FILE_NAME: &str = "wfe.log";
pub(crate) const MAX_FILE_BYTES: u64 = 1024 * 1024;
/// Longer messages are cut. epic-wallet can log whole structures.
const MAX_MESSAGE_BYTES: usize = 4096;
/// Lines kept in memory until `init` names the directory.
const EARLY_LINES: usize = 256;
/// Prefix of targets for lines that come from Dart.
pub(crate) const DART_TARGET: &str = "dart";
const OUR_CRATE: &str = "epic_wallet_core";

/// The most detailed level written for `target`.
pub(crate) fn level_for(target: &str) -> LevelFilter {
    let ours = |prefix: &str| {
        target == prefix
            || target
                .strip_prefix(prefix)
                .is_some_and(|rest| rest.starts_with("::") || rest.starts_with('.'))
    };
    if ours(OUR_CRATE) || ours(DART_TARGET) {
        LevelFilter::Info
    } else {
        LevelFilter::Warn
    }
}

/// An append-only log file that rotates to `<name>.1` when it would pass `max` bytes.
pub(crate) struct LogFile {
    path: PathBuf,
    file: File,
    size: u64,
    max: u64,
}

impl LogFile {
    pub(crate) fn open(dir: &Path, max: u64) -> std::io::Result<LogFile> {
        fs::create_dir_all(dir)?;
        let path = dir.join(FILE_NAME);
        let file = OpenOptions::new().create(true).append(true).open(&path)?;
        let size = file.metadata()?.len();
        Ok(LogFile {
            path,
            file,
            size,
            max,
        })
    }

    pub(crate) fn append(&mut self, line: &str) -> std::io::Result<()> {
        if self.size > 0 && self.size + line.len() as u64 > self.max {
            self.rotate()?;
        }
        self.file.write_all(line.as_bytes())?;
        self.size += line.len() as u64;
        Ok(())
    }

    fn rotate(&mut self) -> std::io::Result<()> {
        let previous = rotated(&self.path);
        // Windows cannot rename over a file another handle might hold; remove it first.
        let _ = fs::remove_file(&previous);
        fs::rename(&self.path, &previous)?;
        self.file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.path)?;
        self.size = 0;
        Ok(())
    }
}

fn rotated(path: &Path) -> PathBuf {
    let mut name = path.as_os_str().to_owned();
    name.push(".1");
    PathBuf::from(name)
}

/// The last `max` bytes of `bytes`, starting after a line break when it had to cut.
fn last_bytes(bytes: &[u8], max: usize) -> &[u8] {
    if bytes.len() <= max {
        return bytes;
    }
    let cut = &bytes[bytes.len() - max..];
    match cut.iter().position(|&b| b == b'\n') {
        Some(i) => &cut[i + 1..],
        None => cut,
    }
}

fn read_last(path: &Path, max: u64) -> Vec<u8> {
    let Ok(mut file) = File::open(path) else {
        return Vec::new();
    };
    let len = file.metadata().map(|m| m.len()).unwrap_or(0);
    let start = len.saturating_sub(max);
    let mut out = Vec::new();
    if file.seek(SeekFrom::Start(start)).is_ok() {
        let _ = file.read_to_end(&mut out);
    }
    out
}

/// The newest `max` bytes across `<dir>/wfe.log.1` and `<dir>/wfe.log`, from a whole line on.
pub(crate) fn tail_of(dir: &Path, max: usize) -> String {
    let current = dir.join(FILE_NAME);
    // One byte more than asked, so a cut inside a line is seen and dropped by `last_bytes`.
    let mut bytes = read_last(&current, max as u64 + 1);
    if bytes.len() <= max {
        let mut older = read_last(&rotated(&current), (max - bytes.len()) as u64 + 1);
        older.extend_from_slice(&bytes);
        bytes = older;
    }
    String::from_utf8_lossy(last_bytes(&bytes, max)).into_owned()
}

struct State {
    file: Option<LogFile>,
    early: VecDeque<String>,
}

static STATE: Mutex<State> = Mutex::new(State {
    file: None,
    early: VecDeque::new(),
});

fn state() -> std::sync::MutexGuard<'static, State> {
    // A panic while logging must not stop every later line.
    STATE
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
}

/// Writes one line, if `level` passes the filter for `target`. Redacts it first.
pub(crate) fn emit(level: Level, target: &str, message: &str) {
    write(level, target, message, true);
}

/// `emit`, but with `wait` false it drops the line rather than wait for the file lock, which a
/// panic inside `emit` may still hold.
fn write(level: Level, target: &str, message: &str, wait: bool) {
    if level > level_for(target) {
        return;
    }
    let body = redact(&shorten(message)).replace('\n', "\n    ");
    mirror(level, target, &body);
    let line = format!(
        "{} {:<5} {target}: {body}\n",
        timestamp(SystemTime::now()),
        level
    );
    let mut state = if wait {
        state()
    } else {
        match STATE.try_lock() {
            Ok(s) => s,
            Err(std::sync::TryLockError::Poisoned(p)) => p.into_inner(),
            Err(std::sync::TryLockError::WouldBlock) => return,
        }
    };
    match state.file.as_mut() {
        // Nowhere to report a failed write: the log is the report. The line still reached logcat.
        Some(file) => {
            let _ = file.append(&line);
        }
        None => {
            if state.early.len() == EARLY_LINES {
                state.early.pop_front();
            }
            state.early.push_back(line);
        }
    }
}

/// Starts writing to `<dir>/wfe.log`, first the lines logged since the process started.
pub(crate) fn init(dir: &Path) -> std::io::Result<PathBuf> {
    let mut file = LogFile::open(dir, MAX_FILE_BYTES)?;
    let path = file.path.clone();
    let mut state = state();
    for line in state.early.drain(..) {
        let _ = file.append(&line);
    }
    state.file = Some(file);
    Ok(path)
}

/// The newest `max` bytes of the log, redacted again in case an older build wrote them.
pub(crate) fn tail(max: usize) -> String {
    let dir = {
        let state = state();
        match &state.file {
            Some(f) => f.path.parent().map(Path::to_path_buf),
            None => {
                let early: String = state.early.iter().map(String::as_str).collect();
                return redact(&String::from_utf8_lossy(last_bytes(early.as_bytes(), max)));
            }
        }
    };
    dir.map(|d| redact(&tail_of(&d, max))).unwrap_or_default()
}

fn shorten(message: &str) -> std::borrow::Cow<'_, str> {
    if message.len() <= MAX_MESSAGE_BYTES {
        return message.into();
    }
    let mut end = MAX_MESSAGE_BYTES;
    while !message.is_char_boundary(end) {
        end -= 1;
    }
    format!("{}…", &message[..end]).into()
}

/// `2026-10-01T00:22:20.700Z`.
fn timestamp(t: SystemTime) -> String {
    let d = t.duration_since(UNIX_EPOCH).unwrap_or_default();
    let secs = d.as_secs() as i64;
    let (days, rem) = (secs.div_euclid(86_400), secs.rem_euclid(86_400));
    // Howard Hinnant's civil_from_days.
    let z = days + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z.rem_euclid(146_097);
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let day = doy - (153 * mp + 2) / 5 + 1;
    let month = if mp < 10 { mp + 3 } else { mp - 9 };
    let year = yoe + era * 400 + i64::from(month <= 2);
    format!(
        "{year:04}-{month:02}-{day:02}T{:02}:{:02}:{:02}.{:03}Z",
        rem / 3600,
        rem % 3600 / 60,
        rem % 60,
        d.subsec_millis()
    )
}

#[cfg(target_os = "android")]
fn mirror(level: Level, target: &str, body: &str) {
    use std::ffi::CString;
    use std::os::raw::{c_char, c_int};

    #[link(name = "log")]
    extern "C" {
        fn __android_log_write(prio: c_int, tag: *const c_char, text: *const c_char) -> c_int;
    }
    let prio = match level {
        Level::Error => 6,
        Level::Warn => 5,
        Level::Info => 4,
        Level::Debug => 3,
        Level::Trace => 2,
    };
    let Ok(text) = CString::new(format!("{target}: {body}").replace('\0', " ")) else {
        return;
    };
    // SAFETY: both pointers are NUL-terminated strings that outlive the call.
    unsafe {
        __android_log_write(prio, c"wfe".as_ptr(), text.as_ptr());
    }
}

#[cfg(all(not(target_os = "android"), debug_assertions))]
fn mirror(level: Level, target: &str, body: &str) {
    eprintln!("{level:<5} {target}: {body}");
}

#[cfg(all(not(target_os = "android"), not(debug_assertions)))]
fn mirror(_level: Level, _target: &str, _body: &str) {}

struct CoreLogger;

impl Log for CoreLogger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= level_for(metadata.target())
    }

    fn log(&self, record: &Record) {
        if self.enabled(record.metadata()) {
            emit(record.level(), record.target(), &record.args().to_string());
        }
    }

    fn flush(&self) {}
}

static LOGGER: CoreLogger = CoreLogger;

/// Installs the logger and a panic hook that logs the panic before the previous hook runs.
/// Idempotent. Lines stay in memory until `init`.
pub(crate) fn install() {
    static ONCE: Once = Once::new();
    ONCE.call_once(|| {
        if log::set_logger(&LOGGER).is_ok() {
            log::set_max_level(LevelFilter::Info);
        }
        let previous = std::panic::take_hook();
        std::panic::set_hook(Box::new(move |info| {
            write(
                Level::Error,
                "epic_wallet_core::panic",
                &info.to_string(),
                false,
            );
            previous(info);
        }));
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn our_lines_log_at_info_and_dependencies_at_warn() {
        assert_eq!(level_for("epic_wallet_core"), LevelFilter::Info);
        assert_eq!(level_for("epic_wallet_core::session"), LevelFilter::Info);
        assert_eq!(level_for("dart.unlock"), LevelFilter::Info);
        assert_eq!(
            level_for("epic_wallet_libwallet::api_impl"),
            LevelFilter::Warn
        );
        assert_eq!(level_for("epic_wallet_core_other"), LevelFilter::Warn);
        assert_eq!(level_for("tungstenite::protocol"), LevelFilter::Warn);
    }

    #[test]
    fn the_file_rotates_and_stays_bounded() {
        let dir = tempfile::tempdir().unwrap();
        let mut file = LogFile::open(dir.path(), 1000).unwrap();
        for i in 0..100 {
            file.append(&format!("line {i:03} {}\n", "x".repeat(40)))
                .unwrap();
        }
        let current = fs::metadata(dir.path().join(FILE_NAME)).unwrap().len();
        let previous = fs::metadata(dir.path().join("wfe.log.1")).unwrap().len();
        assert!(current <= 1000 && previous <= 1000, "{current} {previous}");
        let entries = fs::read_dir(dir.path()).unwrap().count();
        assert_eq!(entries, 2, "only the current and one previous file");

        let tail = tail_of(dir.path(), 1500);
        assert!(tail.len() <= 1500);
        assert!(tail.ends_with("line 099 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\n"));
        assert!(
            tail.starts_with("line "),
            "starts on a whole line: {tail:.20}"
        );
        assert!(!tail.contains("line 000"));
        // It reaches into the rotated file when the current one is short.
        assert!(tail.len() > current as usize);
    }

    #[test]
    fn a_reopened_file_carries_on_where_it_was() {
        let dir = tempfile::tempdir().unwrap();
        LogFile::open(dir.path(), 1000)
            .unwrap()
            .append("first\n")
            .unwrap();
        LogFile::open(dir.path(), 1000)
            .unwrap()
            .append("second\n")
            .unwrap();
        assert_eq!(tail_of(dir.path(), 1000), "first\nsecond\n");
        assert_eq!(tail_of(dir.path(), 8), "second\n");
    }

    #[test]
    fn the_sink_filters_redacts_and_keeps_early_lines() {
        let target = "epic_wallet_core::logging_test";
        emit(Level::Info, target, "before init");
        let dir = tempfile::tempdir().unwrap();
        let path = init(dir.path()).unwrap();
        emit(Level::Info, target, "unlock with PIN 123456");
        emit(
            Level::Warn,
            target,
            "restore abandon ability able about above absent absorb abstract absurd abuse",
        );
        emit(
            Level::Info,
            target,
            "listening as esWn9r2zQj5eKkVh3sT4YpX7cBdF8gHmNaLuRvS6tE1iPo2wZxC9@epicbox.epiccash.com",
        );
        emit(
            Level::Info,
            "epic_wallet_libwallet::x",
            "dependency chatter",
        );
        emit(
            Level::Warn,
            "epic_wallet_libwallet::x",
            "dependency warning",
        );
        emit(Level::Info, "dart.push", "multi\nline");

        let written = fs::read_to_string(path).unwrap();
        assert!(written.contains("before init"));
        assert!(written.contains("unlock with PIN [redacted]"));
        assert!(!written.contains("123456"));
        assert!(written.contains("restore [words]"));
        assert!(!written.contains("abandon"));
        assert!(written.contains("listening as esWn9r…@epicbox.epiccash.com"));
        assert!(!written.contains("dependency chatter"));
        assert!(written.contains("WARN  epic_wallet_libwallet::x: dependency warning"));
        assert!(written.contains("dart.push: multi\n    line\n"));
        assert!(tail(64 * 1024).contains("dependency warning"));
    }

    #[test]
    fn long_messages_are_cut_on_a_character() {
        let long = "é".repeat(MAX_MESSAGE_BYTES);
        let short = shorten(&long);
        assert!(short.len() <= MAX_MESSAGE_BYTES + "…".len());
        assert!(short.ends_with('…'));
    }

    #[test]
    fn timestamps_are_utc_iso() {
        let t = UNIX_EPOCH + std::time::Duration::from_millis(1_790_000_000_123);
        assert_eq!(timestamp(t), "2026-09-21T14:13:20.123Z");
        assert_eq!(timestamp(UNIX_EPOCH), "1970-01-01T00:00:00.000Z");
    }
}
