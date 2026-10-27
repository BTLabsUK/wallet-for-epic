#!/usr/bin/env bash
# Live check of the Pairing UX (26.10.18) between the phone app on an Android emulator and the
# desktop app under xvfb: pairing by message both ways, Not now, Paste, and in person; the
# Android 12+ clipboard toast once per clip; no link text in logcat. Real LEPIC on both sides.
#
#   tool/pairing_message_check.sh [device]      (default emulator-5560)
#
# The device's app is replaced by a debug build: use a read-only emulator (`emulator -avd wfe_qa
# -port 5560 -read-only ...`). The "chat": what one side shares, this script hands to the other.
# A message for the phone is typed into another app of the device (Settings search) and copied
# there, so Android sees another app's clip; then the phone app comes back to the front, and a
# few screenshots catch the toast. Env: RC_OUT (default $TMPDIR) holds the run.
set -uo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
. "$here/../tools/env.sh"
DEV="${1:-emulator-5560}"
A=(adb -s "$DEV")
PKG=uk.btlabs.epiccash.mobile
OUT="${RC_OUT:-${TMPDIR:-$HOME/.cache/release-check}}"
run="$OUT/msg-$(date +%H%M%S)"
chat="$run/chat"
mkdir -p "$chat" "$run/toast"
cd "$here"

phone_get() { "${A[@]}" shell run-as "$PKG" cat "files/rc-chat/out/$1" 2>/dev/null; }
phone_put() { printf '%s' "$2" | "${A[@]}" shell run-as "$PKG" sh -c "'cat > files/rc-chat/in/$1'"; }

# The phone app in front again, with three screenshots while a toast would show.
back_to_app() {
  "${A[@]}" shell am start -n "$PKG/.MainActivity" > /dev/null 2>&1
  for i in 1 2 3; do
    sleep 0.6
    "${A[@]}" exec-out screencap -p > "$run/toast/$1-$i.png"
  done
}

# [text] copied in another app (Chrome's address bar), then back to the phone app. Typed in
# chunks: one long `input text` is cut short. Chrome starts without its first-run screens
# (a read-only emulator forgets the flag file at shutdown).
copy_on_phone() {
  "${A[@]}" shell "echo '_ --disable-fre --no-default-browser-check --no-first-run' > /data/local/tmp/chrome-command-line"
  "${A[@]}" shell am set-debug-app --persistent com.android.chrome > /dev/null 2>&1
  "${A[@]}" shell am start -a android.intent.action.VIEW -d about:blank com.android.chrome > /dev/null 2>&1
  sleep 3
  local bar
  "${A[@]}" shell uiautomator dump /sdcard/rc-ui.xml > /dev/null 2>&1
  bar=$("${A[@]}" shell cat /sdcard/rc-ui.xml | grep -oE 'resource-id="com.android.chrome:id/url_bar"[^>]*bounds="\[[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+' | grep -oE '[0-9]+,[0-9]+\]\[[0-9]+,[0-9]+' | sed 's/\]\[/,/' | tr ',' ' ')
  [ -n "$bar" ] || bar="210 144 670 275"
  set -- "$1" "$2" $bar
  "${A[@]}" shell input tap $(( ($3 + ${5:-$3}) / 2 )) $(( ($4 + ${6:-$4}) / 2 ))
  sleep 1
  "${A[@]}" shell input keycombination 113 29
  "${A[@]}" shell input keyevent 67
  local e="${2// /%s}" i
  for ((i = 0; i < ${#e}; i += 60)); do "${A[@]}" shell input text "'${e:$i:60}'"; done
  "${A[@]}" shell input keycombination 113 29
  "${A[@]}" shell input keyevent 278
  sleep 1
  back_to_app "$1"
}

away_and_back() {
  "${A[@]}" shell input keyevent HOME
  sleep 2
  back_to_app "$1"
}

# The release app's signature differs from a debug build's.
"${A[@]}" uninstall "$PKG" > /dev/null 2>&1
"${A[@]}" logcat -c
echo "phone: building and starting the test"
flutter test -d "$DEV" integration_test/pairing_message_phone_test.dart > "$run/phone.log" 2>&1 &
phone=$!
# The desktop build starts once the phone's is done, not at the same time.
until grep -q 'RC .* | the phone pairs' "$run/phone.log" 2>/dev/null || ! kill -0 "$phone" 2>/dev/null; do sleep 5; done
echo "desktop: building and starting the test"
RC_CHAT="$chat" RC_OUT="$run" tool/release_check.sh desktop integration_test/release_check/pairing_message_desk_test.dart > "$run/desk.log" 2>&1 &
desk=$!

done_list=" "
mark() { done_list="$done_list$1 "; }
seen() { [[ "$done_list" == *" $1 "* ]]; }
end=$(( $(date +%s) + 2400 ))
while [ "$(date +%s)" -lt "$end" ]; do
  for n in p-invite p-finish p-reply p-card p-sas1 p-sas2 p-sas3; do
    seen "$n" && continue
    t="$(phone_get "$n")"
    [ -n "$t" ] && { printf '%s' "$t" > "$chat/$n"; mark "$n"; echo "phone -> desk: $n"; }
  done
  for n in d-reply d-invite d-finish; do
    seen "$n" && continue
    [ -f "$chat/$n" ] || continue
    copy_on_phone "$n" "$(cat "$chat/$n")"
    phone_put "clip-$n" ok
    mark "$n"; echo "desk -> phone (clipboard): $n"
  done
  if ! seen d-card && [ -f "$chat/d-card" ]; then phone_put d-card "$(cat "$chat/d-card")"; mark d-card; echo "desk -> phone: d-card"; fi
  for k in 1 2; do
    if ! seen "away$k" && [ -n "$(phone_get "p-away$k")" ]; then away_and_back "away$k"; phone_put "back$k" ok; mark "away$k"; echo "phone away and back ($k)"; fi
  done
  for k in 1 2 3; do
    seen "sas$k" && continue
    if [ -f "$chat/p-sas$k" ] && [ -f "$chat/d-sas$k" ]; then
      p="$(cat "$chat/p-sas$k")"; d="$(cat "$chat/d-sas$k")"
      if [ -n "$p" ] && [ "$p" = "$d" ]; then echo "RC PASS | words $k match | $p"; else echo "RC FAIL | words $k differ | phone: $p / desk: $d"; fi
      mark "sas$k"
    fi
  done
  if grep -q 'RC DONE desk' "$run/desk.log" 2>/dev/null && grep -q 'RC DONE phone' "$run/phone.log" 2>/dev/null && seen sas3; then break; fi
  if ! kill -0 "$phone" 2>/dev/null && ! kill -0 "$desk" 2>/dev/null; then break; fi
  sleep 2
done

"${A[@]}" logcat -d > "$run/logcat.txt" 2>/dev/null
links=$(grep -c 'epiccash://' "$run/logcat.txt")
# Android logs each "pasted from your clipboard" toast: one per new clip, none for an unchanged one.
echo "RC NOTE | clipboard toasts: $(grep -c 'pasted from your clipboard' "$run/logcat.txt") at $(grep 'pasted from your clipboard' "$run/logcat.txt" | awk '{print $2}' | tr '\n' ' ')"
[ "$links" -eq 0 ] && echo "RC PASS | no link text in logcat | $(wc -l < "$run/logcat.txt") lines" || echo "RC FAIL | link text in logcat | $links lines"
grep -h 'RC PASS\|RC FAIL' "$run/phone.log" | sed 's/^.*RC /phone RC /' | sort -u
grep -h 'RC PASS\|RC FAIL' "$run/desk.log" | sed 's/^.*RC /desk RC /' | sort -u
kill "$phone" "$desk" 2>/dev/null
echo "run: $run"
