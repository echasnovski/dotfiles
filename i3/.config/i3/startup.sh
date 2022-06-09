#!/bin/bash

#============================================================================#
#                     Code for custom i3 startup actions                     #
#============================================================================#

# Enable settings ============================================================
# Manage keyboard layout
setxkbmap -layout us,ru
setxkbmap -option 'grp:alt_shift_toggle'

# Start processes ============================================================
# `picom` to reduce screen tearing
picom --config ~/.config/picom/picom.conf -b

# `dunst` notification daemon
dunst -config ~/.config/dunst/dunstrc &

# Process of showing regularly changed wallpapers
if [[ -f ~/.wallpapers/random-wallpapers.sh ]]
then
  chmod u+x ~/.wallpapers/random-wallpapers.sh
  ~/.wallpapers/random-wallpapers.sh &
fi

# Open predefined windows ====================================================
# Permanent windows (usually should stay opened)
# NOTEs:
# - If command throws error (usually because program is not present), it
#   should still execute the rest.
# - Tried to do custom saved layout but decided to go simpler because not all
#   programs might be present everywhere this setup is run.
i3-msg 'workspace "10:monitor"; layout splith'
sleep 1

xfce4-terminal -e btop &
sleep 1
