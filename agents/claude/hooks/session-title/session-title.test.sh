#!/bin/bash
# Tests for session-title.sh against a temporary project root and a fake claude command. Run directly.
set -u
hook="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-title.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
failures=0

root="$tmp/source"
mkdir -p "$root/testlanes/master/.git" "$root/testlanes/implementation/.git" \
  "$root/excalc/.git" "$root/excalc-rs/.git" "$root/mongoid/mongoid_fulltext/upstream-mongoid_fulltext/.git" \
  "$root/mongoid/mongoid_orderable/.git" "$root/g/.git"
printf 'testlanes 🧪\n' >"$tmp/pins.txt"

# A fake claude that records each call and question, and answers emoji questions with 🦀 and title requests with a title.
cat >"$tmp/claude" <<'FAKE'
#!/bin/bash
question="$(cat)"
echo "$* :: $question" >>"$FAKE_LOG"
case "$question" in
  *"one emoji"*) echo "🦀" ;;
  *) echo "🔊 Loud Laptop Fan" ;;
esac
FAKE
chmod +x "$tmp/claude"
export FAKE_LOG="$tmp/calls.log"
touch "$FAKE_LOG"

run() {
  jq -n --arg prompt "$1" --arg cwd "${2:-$tmp}" --arg title "${3:-}" \
    '{prompt: $prompt, cwd: $cwd} + (if $title == "" then {} else {session_title: $title} end)' |
    SESSION_TITLE_ROOT="$root" SESSION_TITLE_PINS="$tmp/pins.txt" SESSION_TITLE_CACHE="$tmp/cache" \
      SESSION_TITLE_CLAUDE="$tmp/claude" "$hook" | jq -r '.hookSpecificOutput.sessionTitle // empty'
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
expect "existing title is kept" "" "$(run "improve testlanes" "$tmp" "my-title")"
expect "nested hook does nothing" "" "$(SESSION_TITLE_NESTED=1 run "improve testlanes")"

run "update excalc" >/dev/null
: >"$FAKE_LOG"
expect "cached emoji" "🦀 excalc" "$(run "update excalc")"
expect "cached emoji skips Haiku" "0" "$(grep -c 'one emoji' "$FAKE_LOG" | tr -d ' ')"
expect "Haiku title topic is slugged" "🔊 loud-laptop-fan" "$(run "why is my laptop fan loud")"
expect "Haiku call disables hooks" "1" "$(grep -c 'disableAllHooks' "$FAKE_LOG" | tr -d ' ')"
expect "emojis cached once" "excalc 🦀" "$(grep '^excalc ' "$tmp/cache/emojis.txt")"

touch -t 202001010000 "$tmp/cache/projects.txt"
mkdir -p "$root/newproject/.git"
expect "project cache rebuilds when root changes" "🦀 newproject" "$(run "start newproject")"

printf '#!/bin/bash\necho "not an emoji"\n' >"$tmp/claude" && rm -f "$tmp/cache/emojis.txt"
expect "invalid Haiku emoji falls back and is not cached" "🗂️ excalc" "$(run "update excalc")"
expect "invalid emoji not cached" "" "$(lookup_cache excalc)"

expect "unavailable Haiku keeps generated title" "" "$(echo '{"prompt":"hello there","cwd":"/"}' |
  SESSION_TITLE_ROOT="$root" SESSION_TITLE_CACHE="$tmp/cache" SESSION_TITLE_CLAUDE=false "$hook")"

exit "$failures"
