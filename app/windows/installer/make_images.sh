#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Generates the installer's images from the untouched sources (ImageMagick 7):
#   images/back-<w>x<h>.png  the landing-page hero, cropped to Inno's 497:360 wizard area with the
#                            left and bottom fade baked in, at the three sizes Inno picks from
#                            (100 %, 150 %, 200 % DPI; it stretches to the rest)
#   images/sheet*.png        the Options sheet background (90 % black, hairline border, alpha), 2x
#   images/icon.png          the app icon, 256 px layer of windows/runner/resources/app_icon.ico
# Usage: app/windows/installer/make_images.sh <path to landing-page/img/hero.webp>
set -euo pipefail
hero=${1:?hero.webp path}
here=$(cd "$(dirname "$0")" && pwd)
out=$here/images
mkdir -p "$out"
# 1136x823 at x=500 keeps the gold block in the right third (the design's crop).
crop="-crop 1136x823+500+0 +repage"
for size in 596x432 994x720 1272x922; do
  w=${size%x*}; h=${size#*x}
  magick "$hero" $crop -resize "${size}!" \
    \( -size "$size" gradient:'rgba(8,8,10,0.78)-rgba(8,8,10,0)' -rotate -90 \
       -resize "${size}!" \) -compose over -composite \
    \( -size "${w}x$((h*4/10))" gradient:'rgba(8,8,10,0)-rgba(8,8,10,0.55)' \) \
    -gravity south -compose over -composite \
    -strip -define png:compression-level=9 "$out/back-$size.png"
done
# Options sheet: 424x104 CSS px (first install) and 424x122 (update, one more line), at 2x,
# 90 % #0D0D10, 1 px #33333D border, 8 px radius.
for spec in sheet:208 sheet-update:244; do
  name=${spec%:*}; h=${spec#*:}
  magick -size 848x$h xc:none -fill 'rgba(13,13,16,0.90)' -stroke '#33333D' -strokewidth 2 \
    -draw "roundrectangle 1,1 846,$((h-2)) 16,16" -strip "$out/$name.png"
done
magick "$here/../runner/resources/app_icon.ico[6]" -strip "$out/icon.png"
ls -la "$out"
