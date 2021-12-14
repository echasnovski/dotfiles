#!/bin/bash
if [[ -d "$HOME/.wallpapers/tiles/png" ]]
then
  while true
  do
    feh --bg-tile --randomize $HOME/.wallpapers/tiles/png
    sleep 900
  done
fi
