#!/usr/bin/env bash

# Get the current status from Timewarrior
STATUS=$(timew)

if [[ "$STATUS" == *"Tracking"* ]]; then
    # Extract the task name and strip double quotes to prevent JSON errors!
    TASK=$(echo "$STATUS" | sed -n '1p' | sed 's/Tracking //' | tr -d '"')
    TIME=$(echo "$STATUS" | grep -oE '[0-9]+:[0-9]{2}:[0-9]{2}' | tail -n 1)

    # Output valid JSON for Waybar
    echo "{\"text\": \"⏱ $TIME  $TASK\", \"class\": \"active\"}"
else
    # If no timer is running, just show the To-Do icon
    echo "{\"text\": \"  Tasks\", \"class\": \"inactive\"}"
fi
