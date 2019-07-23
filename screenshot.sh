#!/bin/bash

# Parsing arguments
# TODO: --help

# TODO: Upload

OPTIONS=rfwmcs: #u:
LONGOPTS=region,full,window,multi,clipboard,save: #,upload:
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 2
fi

eval set -- "$PARSED"
r=n f=n w=n c=n s=n u=n m=n
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
elif [ $c == "n" ] && [ $s == "n" ] && [ $u == "n" ]; then
    echo "$0: I don't know what I'm supposed to do with the image!"
    exit 1
elif [ $c == "y" ] && [ $u != "n" ]; then
    echo "URL will be saved to the clipboard instead of the image."
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
    maim "$out"
    eval $clip
elif [ $w == "y" ]; then
    maim -i $(xdotool getactivewindow) "$out"
    eval $clip
elif [ $m == "y" ]; then
    scrot -m "$out"
    eval $clip
fi

if [ $s != "n" ]; then
    notify-send "Screenshot saved to $out"
elif [ $c == "y" ]; then
    notify-send "Screenshot saved to the clipboard"
fi
