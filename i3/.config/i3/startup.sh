#!/bin/bash

### Code for custom i3 startup actions ###

# Manage keyboard layout
setxkbmap -layout us,ru
setxkbmap -option 'grp:alt_shift_toggle'

# Start `compton` to reduce screen tearing
compton --config ~/.config/compton.conf -b

# Start process of showing regularly changed wallpapers
if [[ -f ~/.wallpapers/random-wallpapers.sh ]]
then
  chmod u+x ~/.wallpapers/random-wallpapers.sh
  ~/.wallpapers/random-wallpapers.sh &
fi

# Open predefined windows
## Main terminal
i3-msg 'workspace "1:main"'
sleep 0.5

kitty &
sleep 0.5

## Permanent windows (usually should stay opened)
## NOTEs:
## - If command throws error (usually because program is not present), it
##   should still execute the rest.
## - Tried to do custom saved layout but decided to go simpler because not all
##   programs might be present everywhere this setup is run.

i3-msg 'workspace "10:permanent"; layout splith'
sleep 0.5

telegram-desktop &
sleep 0.5

thunderbird &
sleep 0.5

kitty btop &
sleep 0.5

## Show default "void" workspace with wallpaper
i3-msg 'workspace "0:void"'
