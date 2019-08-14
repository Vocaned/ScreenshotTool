#!/bin/bash

# Parsing arguments
# TODO: --help

# TODO: Upload

OPTIONS=rfwmpqcs: #u:
LONGOPTS=region,full,window,multi,colorpicker,QR,clipboard,save: #,upload:
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 2
fi

eval set -- "$PARSED"
r=n f=n w=n c=n s=n u=n m=n p=n q=n
n=0

while true; do
    case "$1" in
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
elif [ [ $c == "n" ] && [ $s == "n" ] && [ $u == "n" ] ] && [ $p != "y" ]; then
    echo "$0: I don't know what I'm supposed to do with the image!"
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

echo "[DEBUG]: region: $r, full: $f, window: $w, clipboard: $c, save: $s, upload: $u"
echo "[DEBUG]: out: $out"

# Taking the screenshot

if [ $r == "y" ]; then
    maim -s "$out"
    eval $clip
elif [ $f == "y" ]; then
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
                maim -g "${MONW}x${MONH}+${MONX}+${MONY}" "$out"
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
    echo -ne "$col"|xclip -selection c
elif [ $q == "y" ]; then
    maim -s qr.png
    text=$(zbarimg -q --raw qr.png)
    notify-send "The code reads:" "$text"
    echo -ne "$text"|xclip -selection c
fi

if [ $s != "n" ]; then
    notify-send "Screenshot saved to $out"
elif [ $c == "y" ]; then
    notify-send "Screenshot saved to the clipboard"
fi
