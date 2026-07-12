"""Item icons for the backpack and hotbar: 64x64, flat colour with black
linework, same language as the ship. One file per item id.

Run from anywhere:  python tools/gen_icons.py
"""
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "icons")

LINE = (0, 0, 0)
GREY = (175, 169, 169)
METAL = (150, 158, 166)
DARK = (96, 102, 110)
PAPER = (234, 226, 200)
AMBER = (240, 180, 70)
RED = (200, 60, 50)
BLUE = (105, 165, 205)
GREEN = (110, 170, 120)
COPPER = (190, 120, 70)


def icon(name):
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    return img, d


def save(img, name):
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name + ".png"))
    print("wrote", name)


def rr(d, box, fill, w=3):
    d.rounded_rectangle(box, radius=5, fill=fill, outline=LINE, width=w)


# suit torso
img, d = icon("suit_torso")
rr(d, [14, 12, 50, 54], GREY)
d.rectangle([6, 16, 16, 40], fill=GREY, outline=LINE, width=3)
d.rectangle([48, 16, 58, 40], fill=GREY, outline=LINE, width=3)
d.rectangle([24, 22, 40, 34], fill=BLUE, outline=LINE, width=2)
save(img, "suit_torso")

# helmet
img, d = icon("suit_helmet")
d.ellipse([10, 10, 54, 54], fill=GREY, outline=LINE, width=3)
d.ellipse([18, 20, 46, 44], fill=(40, 60, 75), outline=LINE, width=3)
d.rectangle([22, 50, 42, 56], fill=DARK, outline=LINE, width=2)
save(img, "suit_helmet")

# wrench
img, d = icon("wrench")
d.line([18, 46, 46, 18], fill=LINE, width=13)
d.line([18, 46, 46, 18], fill=METAL, width=7)
d.ellipse([38, 8, 58, 28], fill=METAL, outline=LINE, width=3)
d.ellipse([44, 14, 52, 22], fill=(0, 0, 0, 0))
d.rectangle([44, 6, 54, 16], fill=(0, 0, 0, 0))
d.ellipse([8, 38, 26, 56], fill=METAL, outline=LINE, width=3)
save(img, "wrench")

# duct tape
img, d = icon("duct_tape")
d.ellipse([10, 10, 54, 54], fill=(120, 126, 134), outline=LINE, width=3)
d.ellipse([24, 24, 40, 40], fill=(50, 54, 60), outline=LINE, width=3)
d.rectangle([50, 24, 62, 34], fill=(120, 126, 134), outline=LINE, width=2)
save(img, "duct_tape")

# fuse
img, d = icon("fuse")
rr(d, [22, 10, 42, 54], (222, 214, 190))
d.rectangle([22, 10, 42, 20], fill=METAL, outline=LINE, width=2)
d.rectangle([22, 44, 42, 54], fill=METAL, outline=LINE, width=2)
d.line([32, 20, 32, 44], fill=AMBER, width=3)
save(img, "fuse")

# wire coil
img, d = icon("wire_coil")
for r in range(22, 8, -5):
    d.ellipse([32 - r, 32 - r, 32 + r, 32 + r], outline=COPPER, width=4)
d.ellipse([10, 10, 54, 54], outline=LINE, width=3)
d.line([50, 40, 62, 52], fill=COPPER, width=4)
save(img, "wire_coil")

# power cell
img, d = icon("power_cell")
rr(d, [16, 8, 48, 56], GREEN)
d.rectangle([26, 2, 38, 10], fill=METAL, outline=LINE, width=2)
d.polygon([(36, 18), (26, 34), (32, 34), (28, 48), (40, 30), (33, 30)], fill=AMBER, outline=LINE)
save(img, "power_cell")

# scrap metal
img, d = icon("scrap_metal")
d.polygon([(10, 26), (34, 8), (56, 22), (48, 50), (18, 54)], fill=METAL, outline=LINE)
d.line([22, 22, 40, 40], fill=DARK, width=3)
d.line([40, 20, 30, 44], fill=DARK, width=3)
save(img, "scrap_metal")

# sample rock
img, d = icon("sample_rock")
d.polygon([(14, 36), (24, 14), (46, 10), (56, 30), (44, 54), (20, 52)], fill=(110, 100, 96), outline=LINE)
d.ellipse([28, 24, 38, 34], fill=(160, 148, 140), outline=LINE, width=2)
save(img, "sample_rock")

# keycard
img, d = icon("keycard_lab")
rr(d, [8, 16, 56, 48], (222, 232, 238))
d.rectangle([8, 22, 56, 30], fill=DARK)
d.rectangle([14, 36, 30, 42], fill=BLUE, outline=LINE, width=2)
save(img, "keycard_lab")

# protein bar
img, d = icon("protein_bar")
rr(d, [8, 22, 56, 42], (170, 120, 70))
d.line([20, 22, 20, 42], fill=LINE, width=2)
d.line([44, 22, 44, 42], fill=LINE, width=2)
save(img, "protein_bar")

# manuals / readables
for name, col in [("manual_airlock", RED), ("mission_brief", BLUE), ("crew_log_medic", GREEN)]:
    img, d = icon(name)
    rr(d, [12, 8, 52, 56], PAPER)
    d.rectangle([12, 8, 22, 56], fill=col, outline=LINE, width=3)
    for ly in range(20, 48, 8):
        d.line([28, ly, 46, ly], fill=DARK, width=2)
    save(img, name)

print("done")
