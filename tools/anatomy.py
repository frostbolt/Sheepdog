#!/usr/bin/env python3
"""Render media/anatomy.tga: one annotated frame for the Welcome tab.

WoW needs an uncompressed TGA with power-of-two dimensions. 512x256, 32-bit with alpha.
Run from the addon folder:  python3 tools/anatomy.py
"""
from PIL import Image, ImageDraw, ImageFont
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "media", "anatomy.tga")
W, H = 512, 256

FONT = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
def font(size):
    try:
        return ImageFont.truetype(FONT, size)
    except OSError:
        return ImageFont.load_default()

img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# Frame geometry: S = 168, column 0.2 S, gap 0.035 S, bars 0.18 S
S = 168
ox, oy = 40, 44
hpH = pwH = int(S * 0.18)
colW, colGap = int(S * 0.2), int(S * 0.035)
black = (0, 0, 0, 255)

# health bar: mage class color lifted toward white
hp_fill = (int(0.41 * 0.58 * 255 + 0.42 * 255), int(0.8 * 0.58 * 255 + 0.42 * 255), int(0.94 * 0.58 * 255 + 0.42 * 255), 255)
hp_bg = (int(0.41 * 56), int(0.8 * 56), int(0.94 * 56), 255)
d.rectangle([ox, oy, ox + S, oy + hpH], fill=hp_bg, outline=black, width=2)
d.rectangle([ox, oy, ox + int(S * 0.48), oy + hpH], fill=hp_fill)
d.text((ox + 7, oy + 5), "48%", font=font(17), fill=(26, 31, 41, 255))

# portrait with CC takeover
py0, py1 = oy + hpH, oy + S - pwH
d.rectangle([ox, py0, ox + S, py1], fill=(74, 36, 86, 255), outline=black, width=2)
d.rectangle([ox + 2, py0 + 2, ox + S - 2, py1 - 2], fill=(92, 48, 108, 255))
big = font(46)
tw = d.textlength("3.8", font=big)
d.text((ox + S // 2 - tw / 2 + 2, py0 + 18), "3.8", font=big, fill=(60, 0, 0, 255))
d.text((ox + S // 2 - tw / 2, py0 + 16), "3.8", font=big, fill=(255, 46, 46, 255))
small = font(12)
tw = d.textlength("Polymorph", font=small)
d.text((ox + S // 2 - tw / 2, py1 - 18), "Polymorph", font=small, fill=(255, 255, 255, 255))

# power bar
pw_fill = (int(0.29 * 0.55 * 255 + 0.45 * 255), int(0.48 * 0.55 * 255 + 0.45 * 255), 255, 255)
pw_bg = (18, 31, 64, 255)
d.rectangle([ox, py1, ox + S, oy + S], fill=pw_bg, outline=black, width=2)
d.rectangle([ox, py1, ox + int(S * 0.89), oy + S], fill=pw_fill)
d.text((ox + 7, py1 + 5), "89%", font=font(17), fill=(26, 31, 41, 255))

# right column: 4 DR slots + trinket
cx = ox + S + colGap
n = 5
gap = 2
slotH = (S - (n - 1) * gap) / n
borders = [(245, 197, 66), (61, 220, 106), (255, 59, 59), (61, 220, 106), (255, 59, 59)]
labels = ["14", "", "9", "", "1:47"]
badges = ["½", "", "X", "", ""]
icon_fill = [(120, 60, 140), (110, 70, 30), (30, 80, 100), (70, 40, 90), (150, 110, 40)]
for i in range(n):
    y0 = oy + i * (slotH + gap)
    y1 = y0 + slotH
    d.rectangle([cx, y0, cx + colW, y1], fill=borders[i] + (255,), outline=black, width=1)
    f = icon_fill[i]
    if i in (1, 3):  # no DR: dim icon
        f = tuple(int(c * 0.5) for c in f)
    if i == 4:
        f = tuple(int(c * 0.6) for c in f)
    d.rectangle([cx + 2, y0 + 2, cx + colW - 2, y1 - 2], fill=f + (255,))
    if labels[i]:
        fs = font(13 if i < 4 else 11)
        tw = d.textlength(labels[i], font=fs)
        d.text((cx + colW / 2 - tw / 2 + 1, y0 + slotH / 2 - 8 + 1), labels[i], font=fs, fill=black)
        d.text((cx + colW / 2 - tw / 2, y0 + slotH / 2 - 8), labels[i], font=fs, fill=(255, 255, 255, 255))
    if badges[i]:
        fs = font(10)
        d.text((cx + colW - 11, y1 - 13), badges[i], font=fs, fill=borders[i] + (255,))

# callouts
accent = (105, 204, 240, 255)
def pin(x, y, num):
    d.ellipse([x - 11, y - 11, x + 11, y + 11], fill=accent, outline=black, width=2)
    fs = font(13)
    tw = d.textlength(str(num), font=fs)
    d.text((x - tw / 2, y - 8), str(num), font=fs, fill=(11, 15, 20, 255))

def label(x, y, text, sub):
    d.text((x, y), text, font=font(14), fill=accent)
    d.text((x, y + 17), sub, font=font(11), fill=(200, 206, 214, 255))

pin(ox - 16, oy + hpH // 2, 1)
pin(ox - 16, (py0 + py1) // 2, 2)
pin(ox - 16, py1 + pwH // 2, 3)
pin(cx + colW + 16, oy + int(slotH * 2), 4)
pin(cx + colW + 16, oy + S - int(slotH / 2), 5)

lx = cx + colW + 36
label(lx, oy - 2, "1  Health, class colored", "percent on the left")
label(lx, oy + 40, "2  Portrait, or what matters more", "CC countdown > cast > root > portrait")
label(lx, oy + 82, "3  Power", "mana, rage or energy")
label(lx, oy + 124, "4  Diminishing returns", "green full · yellow ½ · orange ¼ · red X")
label(lx, oy + 166, "5  Trinket", "dims and counts down after use")

d.text((ox, oy + S + 10), "arena2 · Priest", font=font(11), fill=(141, 149, 163, 255))

img.save(OUT, format="TGA", rle=False)
print("wrote", OUT, img.size)
