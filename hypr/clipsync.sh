#!/bin/bash
while clipnotify; do
  selection="$(xclip -o -selection clipboard 2>/dev/null)"
  if [ $? -eq 0 ]; then
    # X11 app copied something → push to Wayland
    printf "%s" "$selection" | wl-copy
  else
    # Wayland app copied something → push to X11 (for Wine to read)
    wl-paste | xclip -i -selection clipboard
  fi
done
