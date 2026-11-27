#!/bin/bash
# Tests for the shared session-title.sh against a temporary project root and a fake model command. Run directly.
set -u
script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-title.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
failures=0

root="$tmp/source"
mkdir -p "$root/testlanes/master/.git" "$root/testlanes/implementation/.git" \
  "$root/excalc/.git" "$root/excalc-rs/.git" "$root/mongoid/mongoid_fulltext/upstream-mongoid_fulltext/.git" \
  "$root/mongoid/mongoid_orderable/.git" "$root/g/.git"
printf 'testlanes 🧪\n' >"$tmp/pins.txt"

# A fake model that records each question, and answers emoji questions with 🦀 and title requests with a title.
cat >"$tmp/ask" <<'FAKE'
#!/bin/bash
question="$(cat)"
echo "nested=$SESSION_TITLE_NESTED :: $question" >>"$FAKE_LOG"
case "$question" in
  *"one emoji"*) echo "🦀" ;;
  *) echo "🔊 Loud Laptop Fan" ;;
esac
FAKE
chmod +x "$tmp/ask"
export FAKE_LOG="$tmp/calls.log"
touch "$FAKE_LOG"

run() {
  jq -n --arg prompt "$1" --arg cwd "${2:-$tmp}" '{prompt: $prompt, cwd: $cwd}' |
    SESSION_TITLE_ROOT="$root" SESSION_TITLE_PINS="$tmp/pins.txt" SESSION_TITLE_CACHE="$tmp/cache" \
      SESSION_TITLE_ASK="$tmp/ask" "$script"
}

lookup_cache() {
  [[ -f "$tmp/cache/emojis.txt" ]] && awk -v p="$1" '$1 == p { print $2 }' "$tmp/cache/emojis.txt"
}

expect() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "ok - $name"
  else
    echo "not ok - $name: expected '$expected', got '$actual'"
    failures=$((failures + 1))
  fi
}

expect "pinned project in prompt" "🧪 testlanes" "$(run "let's improve TestLanes.")"
expect "longest matching project" "🦀 excalc-rs" "$(run "port excalc to excalc-rs")"
expect "organization subdirectory, hyphenated" "🦀 mongoid-fulltext" "$(run "fix mongoid_fulltext search")"
expect "container checkouts are not projects" "🔊 loud-laptop-fan" "$(run "work on implementation")"
expect "short names are ignored" "🔊 loud-laptop-fan" "$(run "g is great")"
expect "working directory project" "🧪 testlanes" "$(run "fix the build" "$root/testlanes/master/lib")"
expect "working directory in organization" "🦀 mongoid-orderable" "$(run "fix the build" "$root/mongoid/mongoid_orderable")"
expect "nested call does nothing" "" "$(SESSION_TITLE_NESTED=1 run "improve testlanes")"

run "update excalc" >/dev/null
: >"$FAKE_LOG"
expect "cached emoji" "🦀 excalc" "$(run "update excalc")"
expect "cached emoji skips the model" "0" "$(grep -c 'one emoji' "$FAKE_LOG" | tr -d ' ')"
expect "model title topic is slugged" "🔊 loud-laptop-fan" "$(run "why is my laptop fan loud")"
expect "model calls are marked nested" "0" "$(grep -vc '^nested=1 ' "$FAKE_LOG" | tr -d ' ')"
expect "emojis cached once" "excalc 🦀" "$(grep '^excalc ' "$tmp/cache/emojis.txt")"

touch -t 202001010000 "$tmp/cache/projects.txt"
mkdir -p "$root/newproject/.git"
expect "project cache rebuilds when root changes" "🦀 newproject" "$(run "start newproject")"

printf '#!/bin/bash\necho "not an emoji"\n' >"$tmp/ask" && rm -f "$tmp/cache/emojis.txt"
expect "invalid model emoji falls back and is not cached" "🗂️ excalc" "$(run "update excalc")"
expect "invalid emoji not cached" "" "$(lookup_cache excalc)"

expect "no model gives no generated title" "" "$(echo '{"prompt":"hello there","cwd":"/"}' |
  SESSION_TITLE_ROOT="$root" SESSION_TITLE_CACHE="$tmp/cache" "$script")"
expect "no model falls back to the default emoji" "🗂️ newproject" "$(echo '{"prompt":"start newproject","cwd":"/"}' |
  SESSION_TITLE_ROOT="$root" SESSION_TITLE_CACHE="$tmp/empty-cache" "$script")"

exit "$failures"
