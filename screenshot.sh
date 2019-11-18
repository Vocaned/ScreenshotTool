#!/bin/bash

# Parsing arguments
# TODO: --help

help () {
    echo "Usage: $0 [options]

    Options:
        -h, --help          Show help
        -r, --region        Captures the screen withing a selected region
        -f, --full          Captures the whole screen
        -w, --window        Captures the current window
        -m, --multi         Captures all monitors
        -p, --colorpicker   Shows the hex color of a selected pixel
        -q, --QR            Decodes a selected QR code
        -c, --clipboard     Copy the output to the clipboard
        -s, --save PATH     Saves the output to a path"
}

# TODO: Upload

OPTIONS=hrfwmpqcs: #u:
LONGOPTS=help,region,full,window,multi,colorpicker,QR,clipboard,save: #,upload:
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 2
fi

eval set -- "$PARSED"
r=n f=n w=n c=n s=n u=n m=n p=n q=n
n=0

while true; do
    case "$1" in
        -h|--help)
            help
            exit 2
            ;;
        -r|--region)
            r=y
            ((n++))
            shift
            ;;
        -f|--full)
            f=y
            ((n++))
            shift
            ;;
        -w|--window)
            w=y
            ((n++))
            shift
            ;;
        -m|--multi)
            m=y
            ((n++))
            shift 
            ;;
        -p|--colorpicker)
            p=y
            ((n++))
            shift 
            ;;
        -q|--QR)
            q=y
            ((n++))
            shift 
            ;;
        -c|--clipboard)
            c=y
            shift
            ;;
        -s|--save)
            s=$2
            shift 2
            ;;
        -u|--upload)
            u=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
    esac
done

if [ $n -gt 1 ]; then
    echo "$0: You can't take a different types of screenshots at the same time!"
    exit 1
elif [ $p == "y" ] && [ $s == "y" ]; then
    echo "You can't save hex colors."
elif [ $p == "y" ] && [ $c == "y" ]; then
    echo "Hex colors are automatically copied to the clipboard"
elif [ $c == "y" ] && [ $u != "n" ]; then
    echo "URL will be copied to the clipboard instead of the image."
fi

out=tmp.png clip=:

if [ $s != "n" ]; then
    out="$(date +"$s")"
fi
if [ $c == "y" ]; then
    clip="xclip -selection c -t image/png $out"
fi
if [ ${out##*.} != "png" ]; then
    echo "$0: Output must be a png, sorry!"
    exit 1
fi

monitorShot () {
    # https://gist.github.com/naelstrof/f9b74b5221cdc324c0911c89a47b8d97
    found="n"
    MONITORS=$(xrandr | grep -o '[0-9]*x[0-9]*[+-][0-9]*[+-][0-9]*')
    # Get the location of the mouse
    XMOUSE=$(xdotool getmouselocation | awk -F "[: ]" '{print $2}')
    YMOUSE=$(xdotool getmouselocation | awk -F "[: ]" '{print $4}')

    for mon in ${MONITORS}; do
        # Parse the geometry of the monitor
        MONW=$(echo ${mon} | awk -F "[x+]" '{print $1}')
        MONH=$(echo ${mon} | awk -F "[x+]" '{print $2}')
        MONX=$(echo ${mon} | awk -F "[x+]" '{print $3}')
        MONY=$(echo ${mon} | awk -F "[x+]" '{print $4}')
        # Use a simple collision check
        if (( ${XMOUSE} >= ${MONX} )); then
          if (( ${XMOUSE} <= ${MONX}+${MONW} )); then
            if (( ${YMOUSE} >= ${MONY} )); then
              if (( ${YMOUSE} <= ${MONY}+${MONH} )); then
                # We have found our monitor!
                maim -g "${MONW}x${MONH}+${MONX}+${MONY}" "$1"
                found="y"
              fi
            fi
          fi
        fi
    done
    if [ $found == "n" ]; then
        echo "Oh no! The mouse is in the void!"
        exit 1
    fi
}

regionShot () {
    monitorShot temp.png
    feh temp.png -FNYx. &
    pid=$!
    maim -s "$1"
    ex=$?
    kill $pid
    if [ $ex != 0 ]; then
        exit 1
    fi
}

# Taking the screenshot

if [ $r == "y" ]; then
    regionShot "$out"
    eval $clip
elif [ $f == "y" ]; then
    monitorShot "$out"
    eval $clip
elif [ $w == "y" ]; then
    maim -i $(xdotool getactivewindow) "$out"
    eval $clip
elif [ $m == "y" ]; then
    maim "$out"
    eval $clip
elif [ $p == "y" ]; then
    col=$(colorpicker --one-shot --short)
    notify-send "Color: $col"
    echo "$col"
    echo -ne "$col"|xclip -selection c
elif [ $q == "y" ]; then
    regionShot qr.png
    text=$(zbarimg -q --raw qr.png)
    notify-send "The code reads:" "$text"
    echo "$text"
    echo -ne "$text"|xclip -selection c
fi

if [ $s != "n" ]; then
    notify-send "Screenshot saved to $out"
elif [ $c == "y" ]; then
    notify-send "Screenshot saved to the clipboard"
fi
