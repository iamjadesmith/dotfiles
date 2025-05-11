#!/bin/bash
TASK_NAME="waybar"
if pgrep -x "$TASK_NAME" > /dev/null; then
    pkill -f -x "$TASK_NAME"
else
    "$TASK_NAME"
fi
