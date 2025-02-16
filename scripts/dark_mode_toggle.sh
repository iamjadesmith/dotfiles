#!/bin/bash

CONFIG_FILE="$HOME/.dotfiles/.config/nvim/lua/config/plugins/colors.lua"

if grep -q "dark_mode = true" "$CONFIG_FILE"; then
    sed -i '' 's/dark_mode = true/dark_mode = false/' "$CONFIG_FILE"
else
    sed -i '' 's/dark_mode = false/dark_mode = true/' "$CONFIG_FILE"
fi
