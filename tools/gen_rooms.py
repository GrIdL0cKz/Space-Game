"""Room backdrops v2 - drawn at the HULL'S OWN SCALE this time.

Rob's tube section is the bible: 92px deck interiors, 55px riveted floor
bands, white outer skin with the light-blue stripe, black space beyond.
Every room is another slice of the same ship, so the 120px astronaut fills
each deck exactly as he fills Rob's corridor. Fighter bay gets a double-
height interior because hangars earn it.

Geometry (single-deck rooms):   sky | stripe 488-496 | skin 496-528 |
interior 528-620 | floor 620-675 | skin 675-707 | stripe 707-715 | sky
Player feet land at y=636 (16px into the floor band, per the hull).

Run from anywhere:  python tools/gen_rooms.py
"""
import math
import os
import random
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "astronaught", "environs", "rooms")

WALL = (204, 225, 236)
WALL_SHADE = (188, 210, 223)
FLOOR = (207, 207, 207)
FLOOR_TICK = (150, 150, 150)
LINE = (0, 0, 0)
SKIN = (255, 255, 255)
STRIPE = (105, 195, 235)
SPACE = (11, 1, 1)
STAR = (230, 235, 240)
METAL = (150, 158, 166)
DARKMETAL = (96, 102, 110)
SCREEN_BG = (14, 24, 33)
SCREEN_INK = (110, 200, 230)
AMBER = (240, 180, 70)
RED = (200, 60, 50)
GREEN = (90, 180, 90)
HAZARD = (230, 190, 60)

W, H = 1920, 1080

INT_TOP = 528
FLOOR_TOP = 620
FLOOR_BOT = 675


def tube(draw, int_top=INT_TOP, wall=WALL, rnd_seed=1):
    """Space, then a slice of ship. int_top lets the fighter bay go taller."""
    draw.rectangle([0, 0, W, H], fill=SPACE)
    rnd = random.Random(rnd_seed)
    for i in range(120):
        x, y = rnd.randint(0, W - 1), rnd.randint(0, H - 1)
        draw.point((x, y), fill=STAR)
        if rnd.random() < 0.2:
            draw.point((x + 1, y), fill=(140, 150, 160))
    skin_top = int_top - 32
    draw.rectangle([0, skin_top - 8, W, skin_top], fill=STRIPE)
    draw.rectangle([0, skin_top, W, int_top], fill=SKIN)
    draw.line([0, int_top, W, int_top], fill=LINE, width=4)
    draw.rectangle([0, int_top, W, FLOOR_TOP], fill=wall)
    # wall panel seams, hull cadence (~190px)
    for x in range(0, W + 1, 190):
        draw.line([x, int_top, x, FLOOR_TOP], fill=LINE, width=3)
    # floor band with rivet ticks
    draw.line([0, FLOOR_TOP, W, FLOOR_TOP], fill=LINE, width=4)
    draw.rectangle([0, FLOOR_TOP, W, FLOOR_BOT], fill=FLOOR)
    for x in range(24, W, 56):
        draw.line([x, FLOOR_TOP + 10, x + 14, FLOOR_TOP + 10], fill=FLOOR_TICK, width=3)
        draw.line([x + 8, FLOOR_TOP + 34, x + 22, FLOOR_TOP + 34], fill=FLOOR_TICK, width=3)
    draw.line([0, FLOOR_BOT, W, FLOOR_BOT], fill=LINE, width=4)
    draw.rectangle([0, FLOOR_BOT, W, FLOOR_BOT + 32], fill=SKIN)
    draw.rectangle([0, FLOOR_BOT + 32, W, FLOOR_BOT + 40], fill=STRIPE)


def outline_rect(d, box, fill, width=3):
    d.rectangle(box, fill=fill, outline=LINE, width=width)


def screen(d, box, kind="wave", seed=2):
    outline_rect(d, box, SCREEN_BG)
    x0, y0, x1, y1 = box
    rnd = random.Random(seed)
    if kind == "wave":
        pts = []
        for i in range(0, x1 - x0 - 12, 5):
            pts.append((x0 + 6 + i, (y0 + y1) / 2 + math.sin(i * 0.11) * (y1 - y0) * 0.25))
        d.line(pts, fill=SCREEN_INK, width=2)
    elif kind == "bars":
        n = max(3, (x1 - x0) // 18)
        for i in range(n):
            bx = x0 + 6 + i * ((x1 - x0 - 12) // n)
            hgt = rnd.uniform(0.25, 0.8)
            d.rectangle([bx, y1 - 6 - (y1 - y0 - 14) * hgt, bx + 8, y1 - 6], fill=SCREEN_INK)
    elif kind == "text":
        for i in range((y1 - y0 - 10) // 10):
            ly = y0 + 8 + i * 10
            d.line([x0 + 6, ly, x1 - rnd.randint(8, 40), ly], fill=SCREEN_INK, width=2)


def door_recess(d, x, label_strip=True):
    """A doorway recess in the wall; the interactive door sprite sits here."""
    outline_rect(d, [x, INT_TOP + 4, x + 96, FLOOR_TOP], WALL_SHADE, 3)
    if label_strip:
        outline_rect(d, [x + 8, INT_TOP - 26, x + 88, INT_TOP - 2], DARKMETAL, 2)


def save(img, name):
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name + ".png"))
    print("wrote", name)


# ------------------------------------------------------------- science lab
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
tube(d, rnd_seed=3)
door_recess(d, 60)
# workbench with scanner dome (player-height bench)
outline_rect(d, [420, FLOOR_TOP - 52, 760, FLOOR_TOP], METAL)
d.ellipse([548, FLOOR_TOP - 92, 642, FLOOR_TOP - 46], fill=(150, 190, 205), outline=LINE, width=3)
d.arc([560, FLOOR_TOP - 86, 630, FLOOR_TOP - 56], 200, 320, fill=SKIN, width=3)
d.ellipse([585, FLOOR_TOP - 60, 605, FLOOR_TOP - 46], fill=AMBER, outline=LINE, width=2)
# wall screens in the band
screen(d, [840, INT_TOP + 14, 1080, INT_TOP + 66], "wave")
screen(d, [1110, INT_TOP + 14, 1250, INT_TOP + 66], "bars")
# shelf of jars
d.line([1320, INT_TOP + 40, 1660, INT_TOP + 40], fill=LINE, width=4)
for i, jx in enumerate(range(1340, 1640, 60)):
    jc = [(140, 190, 170), (170, 150, 190), (190, 180, 140)][i % 3]
    outline_rect(d, [jx, INT_TOP + 6, jx + 34, INT_TOP + 38], jc, 2)
# specimen locker right
outline_rect(d, [1700, FLOOR_TOP - 78, 1850, FLOOR_TOP], DARKMETAL)
d.line([1775, FLOOR_TOP - 78, 1775, FLOOR_TOP], fill=LINE, width=3)
save(img, "science_lab")

# ------------------------------------------------------------ viewing deck
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
tube(d, rnd_seed=4)
door_recess(d, 60)
# the wall band becomes glass: space and the destination seen from inside
d.rectangle([260, INT_TOP + 4, 1860, FLOOR_TOP - 2], fill=SPACE)
rnd = random.Random(7)
for i in range(60):
    d.point((rnd.randint(270, 1850), rnd.randint(INT_TOP + 8, FLOOR_TOP - 8)), fill=STAR)
cx, cy, r = 1560, INT_TOP + 46, 34
d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(96, 128, 118), outline=LINE, width=3)
d.arc([cx - r - 12, cy - 12, cx + r + 12, cy + 12], 200, 340, fill=(180, 190, 200), width=3)
for mx in range(260, 1861, 200):  # mullions
    d.line([mx, INT_TOP + 4, mx, FLOOR_TOP - 2], fill=LINE, width=5)
d.rectangle([260, INT_TOP, 1860, INT_TOP + 4], fill=METAL)
# handrail
d.line([300, FLOOR_TOP - 34, 1820, FLOOR_TOP - 34], fill=LINE, width=5)
for px in range(340, 1800, 190):
    d.line([px, FLOOR_TOP - 34, px, FLOOR_TOP], fill=LINE, width=4)
save(img, "viewing_deck")

# ---------------------------------------------------------------- cockpit
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
tube(d, rnd_seed=5)
# nose taper at the left: canopy glass
d.polygon([(0, INT_TOP - 32), (330, INT_TOP - 32), (60, FLOOR_TOP), (0, FLOOR_TOP)],
          fill=SPACE, outline=LINE)
rnd = random.Random(11)
for i in range(24):
    px = rnd.randint(8, 280)
    py = rnd.randint(INT_TOP - 20, FLOOR_TOP - 30)
    if px < 330 - (py - (INT_TOP - 32)) * (270.0 / (FLOOR_TOP - INT_TOP + 32)):
        d.point((px, py), fill=STAR)
# dash console
outline_rect(d, [330, FLOOR_TOP - 64, 900, FLOOR_TOP], METAL)
screen(d, [350, FLOOR_TOP - 56, 540, FLOOR_TOP - 12], "text")
screen(d, [560, FLOOR_TOP - 56, 720, FLOOR_TOP - 12], "wave")
for i, bx in enumerate(range(740, 880, 34)):
    d.ellipse([bx, FLOOR_TOP - 40, bx + 20, FLOOR_TOP - 20], fill=[GREEN, AMBER, RED][i % 3], outline=LINE, width=2)
# pilot seat
outline_rect(d, [960, FLOOR_TOP - 84, 1080, FLOOR_TOP], (60, 70, 84))
outline_rect(d, [960, FLOOR_TOP - 104, 1050, FLOOR_TOP - 80], (60, 70, 84))
# overhead advisory panel
outline_rect(d, [1150, INT_TOP + 10, 1740, INT_TOP + 54], DARKMETAL)
for i, bx in enumerate(range(1170, 1720, 52)):
    d.ellipse([bx, INT_TOP + 22, bx + 18, INT_TOP + 40], fill=AMBER if i % 2 else GREEN, outline=LINE, width=2)
# AI core rack: a floor-standing server cabinet aft, by the door. One
# fuse socket sits open and obvious.
outline_rect(d, [1560, INT_TOP + 70, 1720, FLOOR_TOP], (52, 58, 66))
for ry in range(INT_TOP + 82, FLOOR_TOP - 18, 22):
    d.rectangle([1572, ry, 1708, ry + 12], fill=(30, 34, 40), outline=LINE, width=2)
    d.ellipse([1694, ry + 2, 1702, ry + 10], fill=AMBER)
d.rectangle([1572, FLOOR_TOP - 34, 1640, FLOOR_TOP - 10], fill=(20, 22, 26), outline=(240, 180, 70), width=3)  # empty fuse socket
door_recess(d, 1780)
save(img, "cockpit")

# -------------------------------------------------------------- fighter bay
BAY_TOP = INT_TOP - 120  # double-height hangar
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
tube(d, int_top=BAY_TOP, wall=WALL_SHADE, rnd_seed=6)
door_recess(d, 60)
for x in range(0, W, 48):  # hazard strip along the floor edge
    d.polygon([(x, FLOOR_TOP - 16), (x + 24, FLOOR_TOP - 16), (x + 40, FLOOR_TOP), (x + 16, FLOOR_TOP)], fill=HAZARD)
d.line([0, FLOOR_TOP - 16, W, FLOOR_TOP - 16], fill=LINE, width=3)
# the P-1 interceptor, drawn like it deserves: fuselage, canopy, fin, wing
fx, fy = 760, FLOOR_TOP  # nose gear reference
d.polygon([(fx - 160, fy - 60), (fx + 240, fy - 60), (fx + 330, fy - 34), (fx + 240, fy - 12),
           (fx - 120, fy - 12), (fx - 190, fy - 36)], fill=(126, 138, 148), outline=LINE)  # fuselage
d.polygon([(fx + 330, fy - 34), (fx + 396, fy - 28), (fx + 330, fy - 22)], fill=(150, 158, 166), outline=LINE)  # nose cone
d.polygon([(fx - 60, fy - 60), (fx - 10, fy - 96), (fx + 60, fy - 96), (fx + 90, fy - 60)],
          fill=SCREEN_BG, outline=LINE)  # canopy
d.polygon([(fx - 160, fy - 60), (fx - 230, fy - 128), (fx - 190, fy - 132), (fx - 96, fy - 62)],
          fill=DARKMETAL, outline=LINE)  # tail fin
d.polygon([(fx + 20, fy - 12), (fx + 130, fy - 12), (fx + 100, fy + 6), (fx + 40, fy + 6)],
          fill=DARKMETAL, outline=LINE)  # wing root under
d.ellipse([fx - 220, fy - 46, fx - 176, fy - 24], fill=(40, 46, 54), outline=LINE, width=3)  # engine
d.line([fx - 90, fy - 12, fx - 90, fy], fill=LINE, width=4)  # gear
d.line([fx + 180, fy - 12, fx + 180, fy], fill=LINE, width=4)
# shark sticker
d.polygon([(fx + 240, fy - 44), (fx + 270, fy - 38), (fx + 240, fy - 32)], fill=(230, 230, 235), outline=LINE)
# tool chest + breaker board
outline_rect(d, [200, FLOOR_TOP - 56, 380, FLOOR_TOP], RED)
d.line([210, FLOOR_TOP - 38, 370, FLOOR_TOP - 38], fill=LINE, width=3)
d.line([210, FLOOR_TOP - 20, 370, FLOOR_TOP - 20], fill=LINE, width=3)
outline_rect(d, [1560, INT_TOP - 60, 1700, FLOOR_TOP - 40], (70, 78, 88))
for i in range(3):
    d.rectangle([1580 + i * 40, INT_TOP - 40, 1600 + i * 40, INT_TOP], fill=AMBER if i < 2 else DARKMETAL, outline=LINE, width=2)
door_recess(d, 1780)
save(img, "fighter_bay")

# ---------------------------------------------------------------- airlock
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
tube(d, wall=WALL_SHADE, rnd_seed=8)
for x in range(0, W, 48):
    d.polygon([(x, FLOOR_TOP - 14), (x + 24, FLOOR_TOP - 14), (x + 40, FLOOR_TOP), (x + 16, FLOOR_TOP)], fill=HAZARD)
door_recess(d, 100)   # inner door home
door_recess(d, 1720)  # outer door home
# pressure console
outline_rect(d, [820, FLOOR_TOP - 78, 1100, FLOOR_TOP], (222, 232, 238))
screen(d, [840, FLOOR_TOP - 68, 1080, FLOOR_TOP - 44], "bars")
for bx in range(850, 1080, 60):
    d.ellipse([bx, FLOOR_TOP - 36, bx + 30, FLOOR_TOP - 6], fill=METAL, outline=LINE, width=3)
    d.line([bx + 15, FLOOR_TOP - 36, bx + 15, FLOOR_TOP - 6], fill=LINE, width=2)
# suit rack
outline_rect(d, [420, FLOOR_TOP - 84, 640, FLOOR_TOP], DARKMETAL)
d.line([440, FLOOR_TOP - 64, 620, FLOOR_TOP - 64], fill=METAL, width=4)
d.ellipse([470, FLOOR_TOP - 60, 500, FLOOR_TOP - 30], fill=(175, 169, 169), outline=LINE, width=2)  # helmet on rack
# warning stencil
outline_rect(d, [1280, INT_TOP + 16, 1560, INT_TOP + 60], (250, 240, 200), 2)
save(img, "airlock")

# ------------------------------------------------------------ crew quarters
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
tube(d, rnd_seed=9)
door_recess(d, 60)
# two double-stacked bunks
for bx in [360, 760]:
    outline_rect(d, [bx, FLOOR_TOP - 88, bx + 260, FLOOR_TOP - 52], (170, 185, 200))  # top bunk
    outline_rect(d, [bx, FLOOR_TOP - 40, bx + 260, FLOOR_TOP - 4], (170, 185, 200))   # low bunk
    outline_rect(d, [bx + 8, FLOOR_TOP - 84, bx + 70, FLOOR_TOP - 66], SKIN, 2)       # pillows
    outline_rect(d, [bx + 8, FLOOR_TOP - 36, bx + 70, FLOOR_TOP - 18], SKIN, 2)
    d.line([bx, FLOOR_TOP - 88, bx, FLOOR_TOP], fill=LINE, width=4)
    d.line([bx + 260, FLOOR_TOP - 88, bx + 260, FLOOR_TOP], fill=LINE, width=4)
# wardrobe: tall locker with mirror strip
outline_rect(d, [1180, INT_TOP + 8, 1330, FLOOR_TOP], DARKMETAL)
d.line([1255, INT_TOP + 8, 1255, FLOOR_TOP], fill=LINE, width=3)
outline_rect(d, [1350, INT_TOP + 14, 1420, FLOOR_TOP - 6], (180, 210, 225), 3)  # mirror
# personal wall: photos
for i, px in enumerate(range(1500, 1720, 70)):
    outline_rect(d, [px, INT_TOP + 20, px + 48, INT_TOP + 58], [(200, 190, 170), (170, 190, 200), (190, 170, 180)][i % 3], 2)
save(img, "crew_quarters")


# ------------------------------------------------------- EVA stern (RGBA)
# The back of the Perennial, seen from outside during the EVA. Same flat
# black-outline language as the hull: white skin, blue stripe, riveted
# band, three engine bells, the outer hatch, and the ship's name.
st = Image.new("RGBA", (620, 1000), (0, 0, 0, 0))
d = ImageDraw.Draw(st)
HX = 300  # hull slab right edge
d.rectangle([0, 60, HX, 940], fill=SKIN, outline=LINE, width=5)
# stripes continuing the tube bands
for sy in [150, 815]:
    d.rectangle([0, sy, HX, sy + 26], fill=STRIPE)
# riveted mid band like the deck floors
d.rectangle([0, 470, HX, 530], fill=FLOOR, outline=LINE, width=3)
for rx in range(16, HX - 8, 44):
    d.line([rx, 484, rx + 14, 484], fill=FLOOR_TICK, width=4)
    d.line([rx + 22, 512, rx + 36, 512], fill=FLOOR_TICK, width=4)
# panel seams
for sy in [240, 350, 620, 730]:
    d.line([12, sy, HX - 12, sy], fill=(205, 213, 220), width=4)
# scorch marks from the strike
for (ex0, ey0, ex1, ey1) in [(150, 268, 250, 320), (60, 588, 140, 640), (190, 700, 262, 744)]:
    d.ellipse([ex0, ey0, ex1, ey1], fill=(96, 102, 110, 160))
    d.ellipse([ex0 + 18, ey0 + 10, ex1 - 14, ey1 - 8], fill=(60, 64, 72, 200))
# stern cap
d.rectangle([HX, 100, HX + 70, 900], fill=DARKMETAL, outline=LINE, width=5)
for sy in [220, 420, 620, 820]:
    d.line([HX + 10, sy, HX + 60, sy], fill=(70, 76, 84), width=4)
# engine bells: rim, cone widening right, dark nozzle mouth
for by in [260, 500, 740]:
    d.rectangle([HX + 70, by - 34, HX + 96, by + 34], fill=METAL, outline=LINE, width=4)
    d.polygon([(HX + 96, by - 30), (HX + 210, by - 62), (HX + 210, by + 62), (HX + 96, by + 30)],
              fill=METAL, outline=LINE)
    d.ellipse([HX + 196, by - 58, HX + 224, by + 58], fill=(30, 34, 40), outline=LINE, width=4)
# RCS cluster up top
for i, ry in enumerate([116, 140]):
    d.rectangle([HX + 8, ry, HX + 40, ry + 16], fill=METAL, outline=LINE, width=3)
# outer hatch where the airlock returns you (world ~x230, y540 - canvas y-40)
d.ellipse([170, 440, 280, 550], fill=(222, 232, 238), outline=LINE, width=5)
d.ellipse([196, 466, 254, 524], fill=DARKMETAL, outline=LINE, width=4)
d.line([225, 466, 225, 524], fill=LINE, width=5)
d.line([196, 495, 254, 495], fill=LINE, width=5)
# ship name stencil, vertical
try:
    from PIL import ImageFont
    fnt = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 36)
    tw_img = Image.new("RGBA", (260, 48), (0, 0, 0, 0))
    ImageDraw.Draw(tw_img).text((0, 0), "PERENNIAL", font=fnt, fill=(96, 102, 110, 255))
    tw_img = tw_img.rotate(90, expand=True)
    st.paste(tw_img, (34, 560), tw_img)
except Exception:
    pass
st.save(os.path.join(OUT, "eva_stern.png"))
print("stern saved")

# -------------------------------------------------------------- lander dock
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
tube(d, rnd_seed=13)
door_recess(d, 60)
# hazard strip along the deck edge
for hx in range(0, W, 48):
    d.polygon([(hx, FLOOR_TOP - 8), (hx + 24, FLOOR_TOP - 8), (hx + 12, FLOOR_TOP)], fill=HAZARD)
# the lander on its cradle: stubby, boxy, four legs, one round window
lx, ly = 1150, FLOOR_TOP  # nose points left
outline_rect(d, [lx - 200, ly - 78, lx + 200, ly - 22], METAL)          # body
d.polygon([(lx - 200, ly - 78), (lx - 258, ly - 50), (lx - 200, ly - 22)],
          fill=METAL, outline=LINE)                                      # nose
outline_rect(d, [lx - 80, ly - 100, lx + 110, ly - 78], DARKMETAL)      # cabin hump
d.ellipse([lx - 40, ly - 66, lx - 4, ly - 32], fill=SCREEN_BG, outline=LINE, width=3)  # window
d.rectangle([lx - 190, ly - 56, lx + 190, ly - 48], fill=STRIPE)        # our blue stripe
for leg in [lx - 150, lx + 60]:
    d.line([leg, ly - 22, leg - 18, ly], fill=LINE, width=5)
    d.line([leg + 30, ly - 22, leg + 48, ly], fill=LINE, width=5)
# dock clamps: two heavy arms from the ceiling band
for cx in [lx - 120, lx + 96]:
    outline_rect(d, [cx, INT_TOP + 4, cx + 26, INT_TOP + 56], DARKMETAL)
    outline_rect(d, [cx - 10, INT_TOP + 56, cx + 36, INT_TOP + 74], DARKMETAL)
# clamp status box
outline_rect(d, [340, INT_TOP + 12, 470, INT_TOP + 60], DARKMETAL)
d.ellipse([355, INT_TOP + 26, 375, INT_TOP + 46], fill=RED, outline=LINE, width=2)
d.ellipse([390, INT_TOP + 26, 410, INT_TOP + 46], fill=AMBER, outline=LINE, width=2)
save(img, "lander_dock")

# ------------------------------------------------------------ derelict deck
DWALL = (96, 104, 116)
DWALL_SHADE = (82, 90, 102)
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
tube(d, wall=DWALL, rnd_seed=21)
# kill the white skin: the Reprieve wears grey and an orange stripe
d.rectangle([0, INT_TOP - 32, W, INT_TOP], fill=(140, 146, 154))
d.rectangle([0, INT_TOP - 40, W, INT_TOP - 32], fill=(214, 128, 52))
d.rectangle([0, FLOOR_BOT, W, FLOOR_BOT + 32], fill=(140, 146, 154))
d.rectangle([0, FLOOR_BOT + 32, W, FLOOR_BOT + 40], fill=(214, 128, 52))
d.line([0, INT_TOP, W, INT_TOP], fill=LINE, width=4)
# hatch recess where the lander clamps on
outline_rect(d, [60, INT_TOP + 4, 156, FLOOR_TOP], DWALL_SHADE, 3)
# dead screens
screen(d, [300, INT_TOP + 14, 520, INT_TOP + 66], "text")
d.rectangle([306, INT_TOP + 20, 514, INT_TOP + 60], fill=(20, 22, 26))  # dead
# emergency lamp, the only thing still trying
d.ellipse([760, INT_TOP + 16, 796, INT_TOP + 52], fill=(120, 30, 24), outline=LINE, width=3)
for r in range(3):
    d.arc([760 - r * 26, INT_TOP + 16 - r * 14, 796 + r * 26, INT_TOP + 52 + r * 14],
          210, 330, fill=(120, 30, 24), width=2)
# supply locker, door hanging open
outline_rect(d, [900, INT_TOP + 8, 1030, FLOOR_TOP], DWALL_SHADE)
d.polygon([(1030, INT_TOP + 8), (1096, INT_TOP + 30), (1096, FLOOR_TOP - 30), (1030, FLOOR_TOP)],
          fill=DWALL_SHADE, outline=LINE)
# escape pod bays: two empty rings, launch rails, dust
for px in [1300, 1520]:
    d.ellipse([px, INT_TOP + 14, px + 150, FLOOR_TOP - 6], fill=SPACE, outline=LINE, width=5)
    d.line([px + 20, FLOOR_TOP - 14, px + 130, FLOOR_TOP - 14], fill=(60, 64, 70), width=4)
# log terminal: one desk, one screen, one chair pushed back forever
outline_rect(d, [1720, FLOOR_TOP - 60, 1880, FLOOR_TOP], (110, 116, 126))
screen(d, [1740, FLOOR_TOP - 118, 1860, FLOOR_TOP - 66], "text")
save(img, "derelict_deck")

# ------------------------------------------------- derelict exterior (RGBA)
ext = Image.new("RGBA", (900, 560), (0, 0, 0, 0))
d = ImageDraw.Draw(ext)
# grey hull tube seen from the side, nose left, orange stripe, battle scars
d.rounded_rectangle([40, 120, 860, 440], radius=90, fill=(150, 156, 164),
                    outline=LINE, width=6)
d.rectangle([40, 180, 860, 214], fill=(214, 128, 52))
d.rectangle([40, 356, 860, 390], fill=(214, 128, 52))
for sx in range(140, 860, 150):
    d.line([sx, 126, sx, 434], fill=(120, 126, 134), width=4)
# the wound from our stern: a crumpled dark bite out of the nose
d.polygon([(40, 210), (150, 240), (110, 300), (170, 330), (60, 360)],
          fill=(52, 56, 64), outline=LINE)
# dead viewport row
for wx in range(300, 800, 90):
    d.ellipse([wx, 250, wx + 40, 290], fill=(24, 26, 32), outline=LINE, width=4)
# dock hatch, our way in (mid-belly)
d.ellipse([470, 380, 560, 452], fill=(222, 232, 238), outline=LINE, width=5)
d.ellipse([492, 398, 538, 434], fill=(80, 86, 96), outline=LINE, width=4)
# name stencil
try:
    from PIL import ImageFont
    fnt = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 40)
    d.text((490, 300), "CSV REPRIEVE", font=fnt, fill=(90, 96, 106, 255))
except Exception:
    pass
ext.save(os.path.join(OUT, "derelict_exterior.png"))
print("wrote derelict_exterior")

# ---------------------------------------------------------- lander (RGBA)
lnd = Image.new("RGBA", (240, 130), (0, 0, 0, 0))
d = ImageDraw.Draw(lnd)
outline_rect(d, [30, 40, 210, 100], METAL)                       # body
d.polygon([(30, 40), (4, 70), (30, 100)], fill=METAL, outline=LINE)   # nose
outline_rect(d, [90, 16, 186, 40], DARKMETAL)                    # cabin
d.ellipse([54, 52, 86, 84], fill=SCREEN_BG, outline=LINE, width=3)    # window
d.rectangle([34, 64, 206, 74], fill=STRIPE)
d.line([70, 100, 54, 126], fill=LINE, width=5)
d.line([170, 100, 186, 126], fill=LINE, width=5)
d.polygon([(210, 52), (236, 62), (236, 80), (210, 90)], fill=DARKMETAL, outline=LINE)  # engine
lnd.save(os.path.join(OUT, "lander.png"))
print("wrote lander")

print("done - all rooms at hull scale")
