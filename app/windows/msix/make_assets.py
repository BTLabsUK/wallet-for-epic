#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Makes the MSIX logos in Assets/ from the 1024 px app icon (macOS set, a full square).

Tiles and the Store logo use the square; the taskbar and Start list icons (targetsize, unplated)
use it with the rounded corners of the Windows icon. Run after the app icon changes:
  python3 app/windows/msix/make_assets.py
"""
from pathlib import Path

from PIL import Image, ImageDraw

here = Path(__file__).resolve().parent
src = Image.open(here.parent.parent / 'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png').convert('RGBA')
out = here / 'Assets'
out.mkdir(exist_ok=True)


def rounded(size: int) -> Image.Image:
    img = src.resize((size, size), Image.LANCZOS)
    big = size * 4
    mask = Image.new('L', (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, big - 1, big - 1), radius=int(big * 0.16), fill=255)
    img.putalpha(mask.resize((size, size), Image.LANCZOS))
    return img


def save(img: Image.Image, name: str) -> None:
    img.save(out / name, optimize=True)


for scale in (100, 125, 150, 200, 400):
    f = scale / 100
    save(src.resize((round(44 * f),) * 2, Image.LANCZOS), f'Square44x44Logo.scale-{scale}.png')
    save(src.resize((round(150 * f),) * 2, Image.LANCZOS), f'Square150x150Logo.scale-{scale}.png')
    save(src.resize((round(50 * f),) * 2, Image.LANCZOS), f'StoreLogo.scale-{scale}.png')
for size in (16, 20, 24, 30, 32, 36, 40, 48, 60, 64, 72, 80, 96, 256):
    save(rounded(size), f'Square44x44Logo.targetsize-{size}.png')
    save(rounded(size), f'Square44x44Logo.targetsize-{size}_altform-unplated.png')
    save(rounded(size), f'Square44x44Logo.targetsize-{size}_altform-lightunplated.png')
