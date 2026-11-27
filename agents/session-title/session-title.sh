#!/bin/bash
# Prints a session title, "<emoji> <name>", for the {"prompt", "cwd"} JSON on stdin, or nothing. Shared by the
# agent session-title hooks, each of which supplies its own model command. The name is the repository under ~/source named in the
# prompt, else the repository that holds the working directory, else a short topic that a model writes from
# the prompt. Names are lowercase words joined by hyphens.
#
# Emojis come from the pinned file, else the cache, else the model, whose pick is cached. The project list is
# cached and rebuilt when the root changes or after a day.
#
# Environment:
#   SESSION_TITLE_ROOT    where projects live (default ~/source)
#   SESSION_TITLE_PINS    "<project> <emoji>" lines that override cached emojis (default session-emojis.txt
#                         next to this script)
#   SESSION_TITLE_CACHE   cache directory (default ~/.cache/session-title)
#   SESSION_TITLE_ASK     command that answers the question on stdin with one line, such as a small model
#                         (default: none, so emojis fall back to 🗂️ and unmatched prompts get no title)

[[ -n "$SESSION_TITLE_NESTED" ]] && exit 0

root="${SESSION_TITLE_ROOT:-$HOME/source}"
script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
pins_file="${SESSION_TITLE_PINS:-$script_dir/session-emojis.txt}"
cache_dir="${SESSION_TITLE_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/session-title}"
ask_cmd="${SESSION_TITLE_ASK:-}"
emojis_cache="$cache_dir/emojis.txt"
projects_cache="$cache_dir/projects.txt"

input="$(cat)"
prompt="$(jq -r '.prompt // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"
mkdir -p "$cache_dir"

# Lowercase words joined by hyphens, such as mongoid-fulltext for mongoid_fulltext.
slug() {
  tr '[:upper:]' '[:lower:]' <<<"$1" | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

# Ask the model a one-line question. SESSION_TITLE_NESTED stops any hook it runs from calling this again.
ask_model() {
  [[ -n "$ask_cmd" ]] || return 1
  (cd "$cache_dir" && printf '%s' "$1" | SESSION_TITLE_NESTED=1 "$ask_cmd" 2>/dev/null) | head -1
}

# A checkout inside a repository container, such as master, upstream-<repo>, or dblock-<repo>.
is_checkout_name() {
  [[ "$1" == master || "$1" == main || "$1" == *-"$2" ]]
}

# A top-level directory that holds checkouts of one repository rather than several repositories.
is_repo_container() {
  local dir="$1" parent child
  parent="$(basename "$dir")"
  [[ -e "$dir/.git" ]] && return 0
  for child in "$dir"/*/; do
    is_checkout_name "$(basename "$child")" "$parent" && return 0
  done
  return 1
}

# Project names: every top-level directory, plus the subdirectories of organization directories.
scan_projects() {
  local dir child
  for dir in "$root"/*/; do
    [[ -d "$dir" ]] || continue
    basename "$dir"
    is_repo_container "$dir" && continue
    for child in "$dir"*/; do
      [[ -d "$child" ]] && basename "$child"
    done
  done | sort -u
}

projects() {
  if [[ ! -s "$projects_cache" || "$root" -nt "$projects_cache" ]] ||
    [[ -n "$(find "$projects_cache" -mmin +1440 2>/dev/null)" ]]; then
    scan_projects >"$projects_cache.$$" && mv "$projects_cache.$$" "$projects_cache"
  fi
  cat "$projects_cache"
}

# The longest project name that appears in the prompt as a whole word, ignoring case.
project_in_prompt() {
  local words
  words=" $(tr '[:upper:]' '[:lower:]' <<<"$prompt" | tr -c 'a-z0-9._-' ' ' | tr -s ' ') "
  words="${words//. / }"
  projects | awk -v words="$words" '
    length($0) >= 3 && length($0) > length(best) && index(words, " " tolower($0) " ") { best = $0 }
    END { print best }'
}

# The project holding the working directory, such as testlanes for ~/source/testlanes/master/lib.
project_in_cwd() {
  local rel first second=""
  [[ "$cwd" == "$root"/* ]] || return 0
  rel="${cwd#"$root"/}"
  first="${rel%%/*}"
  [[ "$rel" == */* ]] && second="${rel#*/}" && second="${second%%/*}"
  if [[ -n "$second" ]] && ! is_repo_container "$root/$first"; then
    echo "$second"
  else
    echo "$first"
  fi
}

# One emoji without letters or spaces, or nothing.
valid_emoji() {
  [[ -n "$1" && ${#1} -le 8 && "$1" != *[[:alnum:][:space:]]* ]]
}

lookup() {
  [[ -f "$2" ]] && awk -v p="$1" '$1 == p { print $2; exit }' "$2"
}

emoji_for() {
  local name="$1" emoji
  emoji="$(lookup "$name" "$pins_file")"
  [[ -z "$emoji" ]] && emoji="$(lookup "$name" "$emojis_cache")"
  if [[ -z "$emoji" ]]; then
    emoji="$(ask_model "Reply with one emoji that fits a software project named \"$name\". Output only the emoji.")"
    emoji="${emoji//[[:space:]]/}"
    valid_emoji "$emoji" && echo "$name $emoji" >>"$emojis_cache"
  fi
  valid_emoji "$emoji" || emoji="🗂️"
  echo "$emoji"
}

project="$(project_in_prompt)"
[[ -z "$project" ]] && project="$(project_in_cwd)"

if [[ -n "$project" ]]; then
  name="$(slug "$project")"
  title="$(emoji_for "$name") $name"
else
  [[ -z "$prompt" ]] && exit 0
  reply="$(ask_model "Write a session title for this request: \"${prompt:0:1000}\". Rules: lowercase words joined by hyphens, 2 to 4 words, no punctuation. On one line output one fitting emoji, a space, then the title. Output nothing else.")"
  emoji="${reply%% *}"
  name="$(slug "${reply#* }")"
  [[ -z "$name" || "$reply" != *" "* ]] && exit 0
  valid_emoji "$emoji" || emoji="💬"
  title="$emoji $name"
fi

echo "$title"
