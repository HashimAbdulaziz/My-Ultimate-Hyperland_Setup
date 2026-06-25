#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  Copyright (c) 2026 Hashim Abdulaziz
#  https://www.linkedin.com/in/hashim-abdulaziz/
#  They call me Hashing — feel free to use this, just keep my name in the code.
# ─────────────────────────────────────────────────────────────
# LeetCode daily challenge waybar module
# left-click: open in Chrome   right-click: mark solved (green)

CACHE="$HOME/.cache/leetcode-daily.json"
SOLVED="$HOME/.cache/leetcode-daily-solved"
TODAY=$(date +%Y-%m-%d)

fetch() {
    curl -sf --max-time 10 \
        -H 'Content-Type: application/json' \
        -H 'Referer: https://leetcode.com' \
        -d '{"query":"query { activeDailyCodingChallengeQuestion { date link question { title difficulty frontendQuestionId: questionFrontendId } } }"}' \
        'https://leetcode.com/graphql' > "$CACHE.tmp" 2>/dev/null \
    && mv "$CACHE.tmp" "$CACHE"
}

# Refresh cache if it's from a different day
CACHED_DATE=$(python3 -c "import json; print(json.load(open('$CACHE'))['data']['activeDailyCodingChallengeQuestion']['date'])" 2>/dev/null)
[ "$CACHED_DATE" != "$TODAY" ] && fetch

# Parse
read_field() {
    python3 -c "import json,sys; d=json.load(open('$CACHE'))['data']['activeDailyCodingChallengeQuestion']; print($1)" 2>/dev/null
}
TITLE=$(read_field "d['question']['title']")
NUM=$(read_field "d['question']['frontendQuestionId']")
DIFF=$(read_field "d['question']['difficulty']")
LINK=$(read_field "'https://leetcode.com' + d['link']")

[ -z "$TITLE" ] && TITLE="LeetCode Daily"
[ -z "$LINK"  ] && LINK="https://leetcode.com/problemset/"

is_solved() { [ "$(cat "$SOLVED" 2>/dev/null)" = "$TODAY" ]; }

auto_check() {
    # Only query API when not already locally marked solved
    is_solved && return
    local result
    result=$(python3 ~/.scripts/leetcode-check.py 2>/dev/null)
    if [ "$result" = "solved" ]; then
        echo "$TODAY" > "$SOLVED"
    fi
}

case "$1" in
    open)
        ~/.local/bin/google-chrome "$LINK" &
        pkill -RTMIN+9 waybar 2>/dev/null
        ;;
    solved)
        echo "$TODAY" > "$SOLVED"
        pkill -RTMIN+9 waybar 2>/dev/null
        notify-send -t 2000 -i emblem-default "LeetCode" "Marked as solved!"
        ;;
    status)
        auto_check
        # Shorten long titles (max 30 chars)
        SHORT="${TITLE:0:30}"
        [ "${#TITLE}" -gt 30 ] && SHORT="${SHORT}…"

        if is_solved; then
            printf '{"text":"󰄬 #%s %s","class":"solved","tooltip":"✓ Solved today!\\n%s\\nDifficulty: %s"}\n' \
                "$NUM" "$SHORT" "$TITLE" "$DIFF"
        else
            printf '{"text":" #%s %s","class":"unsolved","tooltip":"Daily Challenge\\n%s\\nDifficulty: %s\\n\\nLeft-click: open · Right-click: mark solved"}\n' \
                "$NUM" "$SHORT" "$TITLE" "$DIFF"
        fi
        ;;
esac
