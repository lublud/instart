#!/bin/bash

brightness=$(cat /sys/class/backlight/intel_backlight/brightness)

if (($brightness > 0)); then
    let brightness=$brightness-50
    echo "echo $brightness > /sys/class/backlight/intel_backlight/brightness" | sudo zsh #or bash
    notify-send Brightness "${brightness}/${max_brightness}" -t 200
fi
