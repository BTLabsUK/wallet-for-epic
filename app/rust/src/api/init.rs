#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Our logger instead of flutter_rust_bridge's default, which sends every level of every crate
    // to logcat and writes no file. Lines wait in memory until `init_logging` names the directory.
    crate::core::logging::install();
    flutter_rust_bridge::setup_backtrace();
}
