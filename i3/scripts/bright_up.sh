#!/bin/bash

max_brightness=$(cat /sys/class/backlight/intel_backlight/max_brightness)
brightness=$(cat /sys/class/backlight/intel_backlight/brightness)

if (($brightness < $max_brightness)); then
    let brightness=$brightness+300
    echo "echo $brightness > /sys/class/backlight/intel_backlight/brightness" | sudo zsh #or bash
    let "rate=${brightness}*100/${max_brightness}"
    notify-send Brightness "${rate}" -t 200
fi
