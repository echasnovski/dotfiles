#!/bin/sh

DATE="WDAY=$(date +"%w %Y-%m-%d %H:%M:%S")"

case "$1" in
--popup)
  xfce4-terminal --title="Popup-Calendar" --hold --execute bash -c 'cal -3; read -n1; i3-msg kill'
  ;;
*)
  echo "$DATE"
  ;;
esac
