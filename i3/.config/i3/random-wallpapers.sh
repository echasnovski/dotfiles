#!/bin/bash
if [[ -d "$HOME/wallpapers" ]]
then
  while true
    do
      feh --bg-scale --randomize $HOME/wallpapers
      sleep 3600
  done
fi
