#!/usr/bin/env bash

# Sync package databases
sudo pacman -Sy --noconfirm >/dev/null 2>&1

# Get updates
repo_raw=$(pacman -Qu 2>/dev/null)
aur_raw=$(yay -Qua 2>/dev/null)

# Counters
repo_count=$(echo "$repo_raw" | grep -c '^[^ ]' 2>/dev/null)
aur_count=$(echo "$aur_raw" | grep -c '^[^ ]' 2>/dev/null)
critical_count=0

# Critical package keywords
critical_keywords="linux|systemd|openssl|glibc|mesa|nvidia|kernel"

# Count critical updates
count_criticals() {
    while IFS= read -r line; do
        pkg=$(echo "$line" | awk '{print $1}')
        if [[ "$pkg" =~ $critical_keywords ]]; then
            ((critical_count++))
        fi
    done <<< "$1"
}

count_criticals "$repo_raw"
count_criticals "$aur_raw"

total=$((repo_count + aur_count))

# No updates
if [[ $total -eq 0 ]]; then
    notify-send "System Status" "Your system is fully up to date!"
    exit 0
fi

# Build notification message
summary="Updates available: $total"
[[ $critical_count -gt 0 ]] && summary+=" | ★ Critical: $critical_count"

msg+="• Repo updates (${repo_count})\n"
msg+="• AUR updates (${aur_count})"

notify-send "$summary" "$msg" --expire-time=0
