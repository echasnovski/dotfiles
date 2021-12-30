#!/bin/sh

DATE="WDAY:$(date +"%w, %Y-%m-%d %H:%M:%S")"

case "$1" in
--popup)
  kitty --class="kitty-cal" --title="Calendar" --hold cal -3
  ;;
*)
  echo "$DATE"
  ;;
esac
