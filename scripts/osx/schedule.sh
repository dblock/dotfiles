#!/bin/bash
# Sets up scheduled jobs on a new or rebuilt Mac: installs the tools they need, links and loads every LaunchAgent in
# LaunchAgents/, and schedules a daily wake so the jobs run while the Mac would otherwise sleep. Safe to rerun; asks for sudo for pmset.

set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
agents_dir="$HOME/Library/LaunchAgents"
domain="gui/$(id -u)"

# Wake (or power on) daily shortly before com.dblock.mongodb-backup runs at 5:00. launchd runs jobs missed while the
# Mac slept on wake, so this also starts the Saturday 3:00 com.dblock.update-dependencies sweep when the Mac slept
# through it. macOS keeps only one repeating wake schedule, so this replaces any other `pmset repeat` setting.
wake_days="MTWRFSU"
wake_time="04:55:00"

# Tools the scheduled jobs need, from Homebrew.
for formula in jq doctl mongosh mongodb-database-tools; do
  brew list --formula "$formula" > /dev/null 2>&1 || brew install "$formula"
done

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
