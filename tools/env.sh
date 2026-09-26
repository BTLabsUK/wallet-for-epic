# Toolchain environment for wallet-for-epic. Source it, do not execute it:
#   . tools/env.sh
# This file is the single place that names toolchain paths on this machine.
# Everything here is user-space; nothing needs sudo.

export JAVA_HOME="$HOME/.local/opt/jdk-21.0.12.1+1"
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_NDK_VERSION="28.2.13676358"   # Flutter 3.47 default ndkVersion
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$ANDROID_NDK_VERSION"
export ANDROID_NDK_ROOT="$ANDROID_NDK_HOME"   # read by CMake-based -sys crates (randomx)
export FLUTTER_ROOT="$HOME/flutter"

_wfe_path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}
_wfe_path_prepend "$HOME/.cargo/bin"
_wfe_path_prepend "$HOME/.pub-cache/bin"
_wfe_path_prepend "$ANDROID_HOME/emulator"
_wfe_path_prepend "$ANDROID_HOME/platform-tools"
_wfe_path_prepend "$ANDROID_HOME/cmdline-tools/latest/bin"
_wfe_path_prepend "$FLUTTER_ROOT/bin"
_wfe_path_prepend "$JAVA_HOME/bin"
unset -f _wfe_path_prepend
export PATH
