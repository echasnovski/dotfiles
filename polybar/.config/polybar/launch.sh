#!/usr/bin/env bash

# Remove current status bar
killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 1; done

# Define template variables
TEMPLATE="$HOME/.config/polybar/config_template.ini"
CONFIG="$HOME/.config/polybar/config.ini"

# Find and substitute local path to temperature hwmon file
LOCAL_HWMON_INFO="$HOME/.config/polybar/temperature-hwmon-path"
CPU_TEMP_PATH=""

if [[ -f $LOCAL_HWMON_INFO ]]
then
  CPU_TEMP_PATH=$(cat $LOCAL_HWMON_INFO)
fi

sed -e "s|CPU_HWMON_PATH|$CPU_TEMP_PATH|g" "$TEMPLATE" > "$CONFIG"

# Launch
polybar mybar -c ~/.config/polybar/config.ini
