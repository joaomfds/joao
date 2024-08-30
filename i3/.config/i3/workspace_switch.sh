#!/bin/bash

direction="$1"

current_workspace=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).num')
if [ "$direction" == "next" ]; then
    next_workspace=$((current_workspace + 1))
else
    next_workspace=$((current_workspace - 1))
fi

if i3-msg workspace number "$next_workspace" | grep -q "ERROR"; then
    i3-msg workspace number "$next_workspace"
else
    i3-msg workspace number "$next_workspace"
fi
