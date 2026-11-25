#!/bin/bash
# Sets up scheduled jobs on a new or rebuilt Mac: links and loads every LaunchAgent in LaunchAgents/,
# and schedules a weekly wake so the Saturday jobs run. Safe to rerun; asks for sudo for pmset.

set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
agents_dir="$HOME/Library/LaunchAgents"
domain="gui/$(id -u)"

# Wake (or power on) Saturdays shortly before com.dblock.update-dependencies runs at 3:00. macOS keeps
# only one repeating wake schedule, so this replaces any other `pmset repeat` setting.
wake_days="S"
wake_time="02:55:00"

mkdir -p "$agents_dir"
for plist in "$dir"/LaunchAgents/*.plist; do
  label="$(/usr/libexec/PlistBuddy -c 'Print :Label' "$plist")"
  link="$agents_dir/$(basename "$plist")"
  if [[ -e "$link" && ! -L "$link" ]]; then
    echo "Skipping $label: $link exists and is not a link."
    continue
  fi
  ln -sfn "$plist" "$link"
  launchctl bootout "$domain/$label" 2>/dev/null || true
  launchctl bootstrap "$domain" "$link"
  echo "Loaded $label."
done

echo "Scheduling wake: $wake_days at $wake_time."
sudo pmset repeat wakeorpoweron "$wake_days" "$wake_time"
pmset -g sched
