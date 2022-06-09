#!/usr/bin/env bash

# Remove current status bar
killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 1; done

# Define template variables
TEMPLATE="$HOME/.config/polybar/config_template.ini"
CONFIG="$HOME/.config/polybar/config.ini"

# Define temperature source: first line is a full hwmon path
LOCAL_TEMPERATURE_DEFINITION="$HOME/.config/polybar/definition-temperature"
TEMPERATURE_SOURCE=""

if [[ -f $LOCAL_TEMPERATURE_DEFINITION ]]
then
  TEMPERATURE_SOURCE=$(cat $LOCAL_TEMPERATURE_DEFINITION)
fi

# Define battery source: first line is a battery name, second - adapter
LOCAL_BATTERY_DEFINITION="$HOME/.config/polybar/definition-battery"
BATTERY_BATTERY=""
BATTERY_ADAPTER=""

if [[ -f $LOCAL_BATTERY_DEFINITION ]]
then
  BATTERY_BATTERY=$(cat $LOCAL_BATTERY_DEFINITION | head -n 1)
  BATTERY_ADAPTER=$(cat $LOCAL_BATTERY_DEFINITION | head -n 2 | tail -n 1)
fi

# Define backlight source: first line is a name of a card
LOCAL_BACKLIGHT_DEFINITION="$HOME/.config/polybar/definition-backlight"
BACKLIGHT_CARD=""

if [[ -f $LOCAL_BACKLIGHT_DEFINITION ]]
then
  BACKLIGHT_CARD=$(cat $LOCAL_BACKLIGHT_DEFINITION)
fi

# Substitute variables
sed \
  -e "s|TEMPERATURE_SOURCE|$TEMPERATURE_SOURCE|g" \
  -e "s|BATTERY_BATTERY|$BATTERY_BATTERY|g" \
  -e "s|BATTERY_ADAPTER|$BATTERY_ADAPTER|g" \
  -e "s|BACKLIGHT_CARD|$BACKLIGHT_CARD|g" \
  "$TEMPLATE" > "$CONFIG"

# Launch
polybar mybar -c ~/.config/polybar/config.ini
