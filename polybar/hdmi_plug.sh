#!/bin/bash

export XAUTHORITY=/home/winson/.Xauthority
export DISPLAY=:0

polybar_script=/home/winson/.config/polybar/launch.sh

connected_monitors=($(xrandr | grep " connected" | awk '{print $1}'))
if [ ${#connected_monitors[@]} -gt 1 ]; then
	xrandr --output "${connected_monitors[1]}" --auto --right-of "${connected_monitors[0]}"
else
	xrandr --auto
fi

devices=$(xinput list --name-only | grep -E 'Pen|Finger')

while IFS= read -r device; do
	device_id=$(xinput list --id-only "$device")
	xinput map-to-output "$device_id" "${connected_monitors[0]}"
done <<< "$devices"

/usr/bin/sh -c "$polybar_script" winson > /dev/null 2>&1 & 
