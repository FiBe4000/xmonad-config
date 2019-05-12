#!/bin/bash

#path=$HOME/Pictures/arch_wallpaper
path=$HOME/Pictures/wallpaper/new
image=$(ls $path | grep -E '(jpg|png)$' | sort -R | tail -1)
#feh --bg-fill $path/$image
feh --bg-fill $path/3.png
