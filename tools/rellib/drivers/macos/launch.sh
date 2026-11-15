#!/bin/zsh
# SPDX-License-Identifier: Apache-2.0
# The macOS trust lane starts the app with this, in a terminal pane in the user's GUI session
# (drivers/macos/macos_platform.py). Usage: launch.sh <lane home> <app bundle> <log> <pid file>
#
# The app gets a home of its own (HOME, CFFIXED_USER_HOME): its data folder and its keychain are
# there. The keychain is the home's throwaway one (made on the first start, kept for the update's
# restart), set as the home's default and unlocked HERE, in the session the app runs in: a keychain
# unlocked over ssh stays locked for the GUI session, and the app's first secure-storage write then
# asks for its password on screen. The app starts only when the home's default is that keychain
# and the user's own default is what it was.
set -u
home=$1 app=$2 log=$3 pidf=$4
kc="$home/Library/Keychains/lane.keychain-db"
realhome=$HOME
own="$(security default-keychain -d user 2>/dev/null)"
refuse() { print -r -- "launch refused: $1" > "$log"; print -r -- "refused" > "$pidf"; exit 1; }
[ -n "$own" ] || refuse "the user's own default keychain is not known"
mkdir -p "$home/Library/Keychains" "$home/Library/Preferences" || refuse "no lane home"
export HOME="$home" CFFIXED_USER_HOME="$home"
[ -f "$kc" ] || security create-keychain -p "" "$kc" || refuse "the throwaway keychain was not made"
security unlock-keychain -p "" "$kc" || refuse "the throwaway keychain did not unlock"
# Never locks by itself (no timeout, not on sleep): a locked one would ask for its password.
security set-keychain-settings "$kc" || refuse "keychain settings"
security list-keychains -d user -s "$kc" || refuse "keychain search list"
security default-keychain -d user -s "$kc" || refuse "default keychain"
have="$(security default-keychain -d user 2>/dev/null | sed 's/^ *"//; s/"$//')"
[ "$have" = "$kc" ] || refuse "the lane home's default keychain is $have"
[ "$(env HOME="$realhome" CFFIXED_USER_HOME="$realhome" security default-keychain -d user 2>/dev/null)" = "$own" ] \
  || refuse "the user's own default keychain changed"
"$app/Contents/MacOS/btwallet" -AppleLanguages "(en)" > "$log" 2>&1 &
print -r -- $! > "$pidf"
wait
