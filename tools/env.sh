# Toolchain environment for wallet-for-epic. Source it, do not execute it:
#   . tools/env.sh
# This file is the single place that names toolchain paths. The values are defaults; set the
# variable before sourcing to override it.
# Everything here is user-space; nothing needs sudo.

export JAVA_HOME="${JAVA_HOME:-$HOME/.local/opt/jdk-21.0.12.1+1}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
export ANDROID_NDK_VERSION="${ANDROID_NDK_VERSION:-28.2.13676358}"   # Flutter 3.47 default ndkVersion
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$ANDROID_HOME/ndk/$ANDROID_NDK_VERSION}"
export ANDROID_NDK_ROOT="${ANDROID_NDK_ROOT:-$ANDROID_NDK_HOME}"   # read by CMake-based -sys crates (randomx)
export FLUTTER_ROOT="${FLUTTER_ROOT:-$HOME/flutter}"

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

# The repository to take a pinned commit from: $1 when it is set (a URL or a path), else the
# checkout $2 when it has the commit $4, else the GitHub repository $3. Checkouts of LEPIC and
# lepic-flutter next to this one are used as they are; a fresh clone takes the GitHub ones.
wfe_repo() {
  if [ -n "$1" ]; then echo "$1"
  elif git -C "$2" cat-file -e "$4^{commit}" 2>/dev/null; then echo "$2"
  else echo "$3"; fi
}
