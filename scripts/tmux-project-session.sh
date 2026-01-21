#!/bin/bash
set -euo pipefail

check_dependencies() {
    for cmd in fzf tmux; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is not installed" >&2
            exit 1
        fi
    done
}

get_projects() {
    local PROJECTS=()

    if [[ -d "$HOME/projects" ]]; then
        while IFS= read -r line; do
            PROJECTS+=("$line")
        done < <(find "$HOME/projects" -mindepth 1 -maxdepth 1 -type d | sed "s|^$HOME/||" | sort)
    fi

    PROJECTS+=(".dotfiles")

    printf '%s\n' "${PROJECTS[@]}"
}

create_session() {
    local selected="$1"
    local selected_path="$HOME/$selected"
    local session_name
    session_name=$(basename "$selected" | tr '.' '_' | tr ' ' '-')

    if tmux has-session -t "$session_name" 2>/dev/null; then
        tmux switch-client -t "$session_name"
        return 0
    fi

    tmux new-session -d -s "$session_name" -x 200 -y 50 -c "$selected_path"

    tmux split-window -h -p 35 -t "$session_name:1" -c "$selected_path"

    if command -v opencode &> /dev/null; then
        tmux send-keys -t "$session_name:1.2" "opencode ." Enter
    fi

    tmux new-window -t "$session_name" -c "$selected_path"
    tmux rename-window -t "$session_name:2" "Terminal"

    tmux select-window -t "$session_name:1"
    tmux select-pane -t "$session_name:1.1"

    if [[ -z "${TMUX:-}" ]]; then
        tmux attach-session -t "$session_name"
    else
        tmux switch-client -t "$session_name"
    fi
}

check_dependencies

SELECTED=$(get_projects | fzf --height=50% --reverse --prompt "Select project: ")

if [[ -z "$SELECTED" ]]; then
    echo "No project selected"
    exit 0
fi

create_session "$SELECTED"
