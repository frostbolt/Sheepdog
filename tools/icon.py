#!/usr/bin/env python3
"""Render the addon icon: media/icon.tga (64x64, shown in the AddOns list on clients that support
IconTexture) and curseforge/icon-512.png / icon-256.png for the CurseForge project avatar.

A white sheep on a dark square with the green "safe to CC" border. Run from the addon folder:
python3 tools/icon.py
"""
from PIL import Image, ImageDraw
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SIZE = 1024  # draw big, downsample for smooth edges


def render(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = size
    r = s * 0.14
    # dark rounded square with the green DR border
    d.rounded_rectangle([0, 0, s - 1, s - 1], radius=r, fill=(61, 220, 106, 255))
    inset = s * 0.045
    d.rounded_rectangle([inset, inset, s - inset - 1, s - inset - 1], radius=r * 0.8, fill=(21, 24, 29, 255))
    # faint mage-blue ground glow
    d.ellipse([s * 0.1, s * 0.55, s * 0.9, s * 1.05], fill=(41, 70, 96, 255))
    d.rounded_rectangle([inset, s * 0.78, s - inset - 1, s - inset - 1], radius=r * 0.8, fill=(21, 24, 29, 255))

    white = (245, 245, 240, 255)
    dark = (40, 36, 44, 255)
    # legs
    for x in (0.34, 0.44, 0.56, 0.66):
        d.rounded_rectangle([s * x, s * 0.62, s * (x + 0.07), s * 0.80], radius=s * 0.02, fill=dark)
    # fluffy body: overlapping circles
    body = [(0.30, 0.50, 0.14), (0.42, 0.42, 0.17), (0.56, 0.42, 0.17), (0.68, 0.50, 0.14),
            (0.36, 0.60, 0.13), (0.50, 0.62, 0.15), (0.63, 0.60, 0.13), (0.50, 0.50, 0.18)]
    for cx, cy, rr in body:
        d.ellipse([s * (cx - rr), s * (cy - rr), s * (cx + rr), s * (cy + rr)], fill=white)
    # head on the right, with an ear and an eye
    d.ellipse([s * 0.66, s * 0.30, s * 0.90, s * 0.54], fill=dark)
    d.ellipse([s * 0.62, s * 0.30, s * 0.74, s * 0.40], fill=dark)        # ear
    d.ellipse([s * 0.64, s * 0.22, s * 0.78, s * 0.36], fill=white)        # tuft
    d.ellipse([s * 0.80, s * 0.38, s * 0.845, s * 0.425], fill=white)      # eye
    d.ellipse([s * 0.815, s * 0.39, s * 0.835, s * 0.41], fill=(21, 24, 29, 255))
    return img


big = render(SIZE)
os.makedirs(os.path.join(ROOT, "curseforge"), exist_ok=True)
for px in (512, 256):
    big.resize((px, px), Image.LANCZOS).save(os.path.join(ROOT, "curseforge", f"icon-{px}.png"))
icon = big.resize((64, 64), Image.LANCZOS)
icon.save(os.path.join(ROOT, "media", "icon.tga"), format="TGA", rle=False)
print("wrote curseforge/icon-512.png, curseforge/icon-256.png, media/icon.tga")
