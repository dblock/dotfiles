#!/bin/bash
# Tests for the Copilot session-title hook, using a fake shared title script.
set -uo pipefail

hook="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/session-title.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export COPILOT_HOME="$tmp/copilot"
export SESSION_TITLE_SCRIPT="$tmp/shared.sh"
cat >"$SESSION_TITLE_SCRIPT" <<'SHARED'
#!/bin/bash
cat >>"$COPILOT_HOME/../shared.log"
echo >>"$COPILOT_HOME/../shared.log"
echo "ask=$SESSION_TITLE_ASK" >>"$COPILOT_HOME/../shared.log"
[[ -n "${FAKE_TITLE:-}" ]] && echo "$FAKE_TITLE"
exit 0
SHARED
chmod +x "$SESSION_TITLE_SCRIPT"

failures=0
check() {
  if [[ "$2" == "$3" ]]; then echo "ok - $1"; else echo "not ok - $1: expected [$3], got [$2]"; failures=$((failures + 1)); fi
}
run() { jq -cn --arg s "$1" --arg p "$2" '{sessionId: $s, timestamp: 1, cwd: "/work", prompt: $p}' | "$hook"; }

out="$(FAKE_TITLE='🧪 testlanes' run s1 'speed up the testlanes CI')"
check "asks the agent to rename a new session" "$(jq -r .additionalContext <<<"$out")" \
  'Before anything else, call rename_session with name "🧪 testlanes". Do not mention the rename. If rename_session is unavailable or leaves the name unchanged, continue without it.'
check "passes the prompt and cwd to the shared script" "$(head -1 "$tmp/shared.log")" \
  '{"prompt":"speed up the testlanes CI","cwd":"/work"}'

check "leaves later prompts alone" "$(FAKE_TITLE='🧪 testlanes' run s1 'and the lint job')" ""
check "does not call the shared script again" "$(grep -c '^{' "$tmp/shared.log")" "1"
check "asks Haiku through Copilot CLI" "$(grep -c "^ask=.*/copilot/hooks/session-title/ask-haiku.sh$" "$tmp/shared.log")" "1"

out="$(FAKE_TITLE='💬 say "hi"' run s2 'x')"
check "encodes quotes in the title" "$(jq -r .additionalContext <<<"$out" | cut -d. -f1)" \
  'Before anything else, call rename_session with name "💬 say \"hi\""'

check "stays quiet without a title" "$(FAKE_TITLE='' run s3 'hello')" ""
check "stays quiet without a session id" "$(jq -cn '{prompt: "x", cwd: "/"}' | FAKE_TITLE='🏠 dotfiles' "$hook")" ""
check "stays quiet on invalid input" "$(echo 'not json' | "$hook"; echo "exit $?")" "exit 0"
FAKE_TITLE='🏠 dotfiles' run '../escape' 'x' >/dev/null
check "keeps session ids inside its folder" "$([[ -f "$COPILOT_HOME/session-title/.._escape" && ! -e "$COPILOT_HOME/escape" ]] && echo yes)" "yes"

[[ "$failures" -eq 0 ]] || { echo "$failures failed"; exit 1; }
