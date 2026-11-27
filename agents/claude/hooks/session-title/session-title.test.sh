#!/bin/bash
# Tests for the Claude Code session-title hook, using a fake shared title script. Run directly.
set -uo pipefail

hook="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-title.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export SESSION_TITLE_SCRIPT="$tmp/shared.sh" SHARED_LOG="$tmp/shared.log"
cat >"$SESSION_TITLE_SCRIPT" <<'SHARED'
#!/bin/bash
cat >>"$SHARED_LOG"
echo >>"$SHARED_LOG"
echo "ask=$SESSION_TITLE_ASK" >>"$SHARED_LOG"
[[ -n "${FAKE_TITLE:-}" ]] && echo "$FAKE_TITLE"
exit 0
SHARED
chmod +x "$SESSION_TITLE_SCRIPT"
touch "$SHARED_LOG"

failures=0
check() {
  if [[ "$2" == "$3" ]]; then echo "ok - $1"; else echo "not ok - $1: expected [$3], got [$2]"; failures=$((failures + 1)); fi
}

out="$(jq -cn '{session_id: "s1", prompt: "speed up the testlanes CI", cwd: "/work"}' | FAKE_TITLE='🧪 testlanes' "$hook" | jq -c .)"
check "sets the session title" "$out" '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","sessionTitle":"🧪 testlanes"}}'
check "passes the prompt and cwd to the shared script" "$(head -1 "$SHARED_LOG")" '{"prompt":"speed up the testlanes CI","cwd":"/work"}'

check "asks Haiku through Claude Code" "$(grep -c "^ask=.*/claude/hooks/session-title/ask-haiku.sh$" "$SHARED_LOG")" "1"

: >"$SHARED_LOG"
check "keeps an existing title" "$(jq -cn '{prompt: "improve testlanes", cwd: "/", session_title: "my-title"}' | FAKE_TITLE='🧪 testlanes' "$hook")" ""
check "does not call the shared script for a titled session" "$(grep -c . "$SHARED_LOG")" "0"
check "keeps a given ask command" "$(jq -cn '{prompt: "x", cwd: "/"}' | SESSION_TITLE_ASK=/bin/mine "$hook"; grep -c '^ask=/bin/mine$' "$SHARED_LOG")" "1"

check "stays quiet without a title" "$(jq -cn '{prompt: "hello", cwd: "/"}' | FAKE_TITLE='' "$hook")" ""

[[ "$failures" -eq 0 ]] || { echo "$failures failed"; exit 1; }
