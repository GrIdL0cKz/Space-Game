"""Room backdrops for Space Game, in the hull's own language: pale blue
panelled walls, grey riveted floors, black linework, space where the
windows are. Drawn with care - these ride until (unless) hand art replaces
them. 1920x1080 each, matching astronaught/environs/craft interior.png.

Run from anywhere:  python tools/gen_rooms.py
"""
import os
import random
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "astronaught", "environs", "rooms")

WALL = (204, 225, 236)
WALL_SHADE = (184, 205, 218)
FLOOR = (207, 207, 207)
FLOOR_SHADE = (176, 176, 176)
LINE = (0, 0, 0)
SPACE = (8, 6, 12)
STAR = (235, 240, 245)
METAL = (150, 158, 166)
DARKMETAL = (96, 102, 110)
SCREEN_BG = (16, 28, 38)
SCREEN_INK = (110, 200, 230)
AMBER = (240, 180, 70)
RED = (200, 60, 50)
GREEN = (90, 180, 90)
HAZARD = (230, 190, 60)

W, H = 1920, 1080
FLOOR_Y = 900

random.seed(11)


def base(draw, wall=WALL):
    draw.rectangle([0, 0, W, H], fill=wall)
    # vertical wall panel lines, hull cadence
    for x in range(0, W + 1, 240):
        draw.line([x, 0, x, FLOOR_Y], fill=LINE, width=3)
    # ceiling strip
    draw.rectangle([0, 0, W, 40], fill=FLOOR)
    draw.line([0, 40, W, 40], fill=LINE, width=4)
    # floor: riveted grey band
    draw.rectangle([0, FLOOR_Y, W, H], fill=FLOOR)
    draw.line([0, FLOOR_Y, W, FLOOR_Y], fill=LINE, width=5)
    draw.rectangle([0, FLOOR_Y + 60, W, H], fill=FLOOR_SHADE)
    for x in range(30, W, 90):
        draw.line([x, FLOOR_Y + 12, x + 18, FLOOR_Y + 12], fill=DARKMETAL, width=4)


def outline_rect(draw, box, fill, width=4):
    draw.rectangle(box, fill=fill, outline=LINE, width=width)


def screen(draw, box, kind="wave"):
    outline_rect(draw, box, SCREEN_BG)
    x0, y0, x1, y1 = box
    if kind == "wave":
        pts = []
        for i in range(0, x1 - x0 - 20, 8):
            import math
            pts.append((x0 + 10 + i, (y0 + y1) / 2 + math.sin(i * 0.07) * (y1 - y0) * 0.25))
        draw.line(pts, fill=SCREEN_INK, width=3)
    elif kind == "bars":
        for i, hgt in enumerate([0.3, 0.55, 0.42, 0.7, 0.5, 0.62]):
            bx = x0 + 14 + i * ((x1 - x0 - 28) // 6)
            draw.rectangle([bx, y1 - 12 - (y1 - y0 - 24) * hgt, bx + 18, y1 - 12], fill=SCREEN_INK)
    elif kind == "text":
        for i in range(4):
            ly = y0 + 14 + i * 18
            draw.line([x0 + 12, ly, x1 - random.randint(12, 80), ly], fill=SCREEN_INK, width=4)
    elif kind == "stars":
        for i in range(30):
            sx = random.randint(x0 + 8, x1 - 8)
            sy = random.randint(y0 + 8, y1 - 8)
            draw.point((sx, sy), fill=STAR)


def window_space(draw, box, planet=False):
    x0, y0, x1, y1 = box
    draw.rectangle([x0 - 14, y0 - 14, x1 + 14, y1 + 14], fill=METAL, outline=LINE, width=4)
    draw.rectangle(box, fill=SPACE, outline=LINE, width=4)
    rnd = random.Random(5)
    for i in range(90):
        sx = rnd.randint(x0 + 6, x1 - 6)
        sy = rnd.randint(y0 + 6, y1 - 6)
        draw.point((sx, sy), fill=STAR)
        if rnd.random() < 0.15:
            draw.point((sx + 1, sy), fill=(150, 160, 175))
    if planet:
        # the destination, quietly enormous
        cx, cy, r = x1 - 200, y0 + 190, 150
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(96, 128, 118), outline=LINE, width=4)
        draw.ellipse([cx - r + 30, cy - r + 25, cx + r - 60, cy - 20], fill=(120, 152, 138))
        draw.arc([cx - r - 40, cy - 44, cx + r + 40, cy + 44], 200, 340, fill=(180, 190, 200), width=6)


def hazard_strip(draw, y, x0=0, x1=W):
    for x in range(x0, x1, 48):
        draw.polygon([(x, y), (x + 24, y), (x + 48, y + 22), (x + 24, y + 22)], fill=HAZARD)
    draw.rectangle([x0, y, x1, y + 22], outline=LINE, width=3)


def save(img, name):
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name + ".png"))
    print("wrote", name)


# ------------------------------------------------------------- science lab
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
base(d)
# workbench with scanner
outline_rect(d, [200, 700, 900, FLOOR_Y], METAL)
outline_rect(d, [240, 740, 860, 780], DARKMETAL)  # drawer line
outline_rect(d, [380, 560, 660, 700], (222, 232, 238))  # scanner housing
d.ellipse([430, 580, 610, 680], fill=SCREEN_BG, outline=LINE, width=4)  # dome
d.line([520, 580, 520, 540], fill=LINE, width=4)
d.ellipse([505, 515, 535, 545], fill=AMBER, outline=LINE, width=3)  # scan lamp
# wall screens
screen(d, [1050, 220, 1500, 420], "wave")
screen(d, [1560, 240, 1840, 400], "bars")
# shelf with jars
outline_rect(d, [1050, 560, 1840, 580], METAL)
for i, jx in enumerate(range(1090, 1800, 110)):
    jc = [(140, 190, 170), (170, 150, 190), (190, 180, 140)][i % 3]
    outline_rect(d, [jx, 490, jx + 60, 560], jc, 3)
    d.rectangle([jx, 478, jx + 60, 492], fill=DARKMETAL, outline=LINE, width=3)
# specimen table
outline_rect(d, [1150, 760, 1500, FLOOR_Y], (222, 232, 238))
save(img, "science_lab")

# ------------------------------------------------------------ viewing deck
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
base(d)
window_space(d, [260, 160, 1660, 640], planet=True)
# handrail
d.line([200, 760, 1720, 760], fill=LINE, width=6)
d.rectangle([200, 760, 1720, 772], fill=METAL, outline=LINE, width=3)
for px in range(260, 1700, 240):
    outline_rect(d, [px, 772, px + 16, FLOOR_Y], METAL, 3)
# bench
outline_rect(d, [760, 800, 1160, 840], (222, 232, 238))
outline_rect(d, [790, 840, 820, FLOOR_Y], DARKMETAL, 3)
outline_rect(d, [1100, 840, 1130, FLOOR_Y], DARKMETAL, 3)
save(img, "viewing_deck")

# ---------------------------------------------------------------- cockpit
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
base(d)
# canopy: angled window filling the left
d.polygon([(0, 80), (760, 160), (760, 620), (0, 760)], fill=SPACE, outline=LINE)
rnd = random.Random(9)
for i in range(60):
    sx = rnd.randint(30, 720)
    sy = rnd.randint(140, 660)
    d.point((sx, sy), fill=STAR)
# console bank
outline_rect(d, [760, 560, 1860, FLOOR_Y], METAL)
screen(d, [800, 600, 1140, 780], "text")
screen(d, [1180, 600, 1520, 780], "wave")
screen(d, [1560, 600, 1820, 780], "bars")
for i, bx in enumerate(range(820, 1800, 70)):
    col = [GREEN, AMBER, RED][i % 3]
    d.ellipse([bx, 820, bx + 22, 842], fill=col, outline=LINE, width=3)
# pilot seat
outline_rect(d, [980, 380, 1180, 560], (60, 70, 84))
outline_rect(d, [980, 340, 1160, 390], (60, 70, 84))
# overhead panel
outline_rect(d, [900, 60, 1700, 150], DARKMETAL)
for bx in range(940, 1660, 90):
    d.ellipse([bx, 88, bx + 26, 114], fill=AMBER if (bx // 90) % 2 else GREEN, outline=LINE, width=3)
save(img, "cockpit")

# -------------------------------------------------------------- fighter bay
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
base(d, WALL_SHADE)
hazard_strip(d, FLOOR_Y - 22, 200, 1700)
# the little fighter on its cradle
d.polygon([(560, 700), (1160, 700), (1300, 640), (1160, 560), (700, 560), (560, 640)],
          fill=(120, 130, 140), outline=LINE)
d.polygon([(1300, 640), (1420, 620), (1300, 590)], fill=(120, 130, 140), outline=LINE)  # nose
d.rectangle([820, 500, 1000, 566], fill=SCREEN_BG, outline=LINE, width=4)  # canopy
d.polygon([(620, 560), (520, 460), (580, 450), (700, 556)], fill=DARKMETAL, outline=LINE)  # tail fin
outline_rect(d, [640, 700, 760, 780], DARKMETAL)   # cradle legs
outline_rect(d, [1060, 700, 1180, 780], DARKMETAL)
# tool chest + fuel line
outline_rect(d, [220, 760, 460, FLOOR_Y], RED)
for dy in [790, 830, 870]:
    d.line([240, dy, 440, dy], fill=LINE, width=3)
d.line([1420, 620, 1700, 620, 1700, FLOOR_Y], fill=DARKMETAL, width=8)
# bay door outline on back wall
outline_rect(d, [1480, 120, 1860, 700], (170, 190, 205))
d.line([1480, 410, 1860, 410], fill=LINE, width=5)
save(img, "fighter_bay")

# ---------------------------------------------------------------- airlock
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
base(d, WALL_SHADE)
hazard_strip(d, FLOOR_Y - 22)
# inner door (left) and outer door (right)
for x0, label_led in [(120, GREEN), (1500, RED)]:
    outline_rect(d, [x0, 200, x0 + 300, FLOOR_Y], METAL, 6)
    d.line([x0 + 150, 200, x0 + 150, FLOOR_Y], fill=LINE, width=5)
    d.ellipse([x0 + 120, 300, x0 + 180, 360], fill=SCREEN_BG, outline=LINE, width=4)  # porthole
    d.ellipse([x0 + 130, 420, x0 + 170, 460], fill=label_led, outline=LINE, width=3)  # status led
# pressure console between doors
outline_rect(d, [760, 480, 1180, 760], (222, 232, 238))
screen(d, [790, 510, 1150, 610], "bars")
for i, bx in enumerate(range(800, 1140, 90)):
    d.ellipse([bx, 650, bx + 50, 700], fill=METAL, outline=LINE, width=4)  # valve wheels
    d.line([bx + 25, 650, bx + 25, 700], fill=LINE, width=3)
# suit rack
outline_rect(d, [420, 560, 700, FLOOR_Y], DARKMETAL)
d.line([440, 600, 680, 600], fill=METAL, width=6)
save(img, "airlock")
print("done")
