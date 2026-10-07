"""Zeichnet die App-Icons des Computer-Desktops (assets/ui/desktop/icon_<app>.png, 256 x 256).
Jedes Icon hat eine eigene Farbe und Form (abgerundetes Quadrat, Kreis, Sechseck, Schild, Raute) und ein weißes Zeichen.
Aufruf: python tools/bake_desktop_icons.py
"""
import math
import os

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ORDNER = os.path.join(os.path.dirname(__file__), '..', 'assets', 'ui', 'desktop')
os.makedirs(ORDNER, exist_ok=True)
S = 1024        # Zeichenfläche, wird auf 256 verkleinert (Kantenglättung)
WEISS = (255, 255, 255, 255)


def hexf(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


# ------------------------------------------------------------------ Formen
def maske_form(form):
    m = Image.new('L', (S, S), 0)
    d = ImageDraw.Draw(m)
    r = 40
    if form == 'quadrat':
        d.rounded_rectangle((r, r, S - r, S - r), radius=230, fill=255)
    elif form == 'kreis':
        d.ellipse((r, r, S - r, S - r), fill=255)
    elif form == 'sechseck':
        mx, my, rad = S / 2, S / 2, S / 2 - r
        pts = [(mx + rad * math.cos(math.radians(60 * i - 30 + 0)), my + rad * math.sin(math.radians(60 * i - 30))) for i in range(6)]
        d.polygon(pts, fill=255)
        m = m.filter(ImageFilter.GaussianBlur(10)).point(lambda v: 255 if v > 128 else 0).filter(ImageFilter.GaussianBlur(1.5))
    elif form == 'schild':
        pts = [(S * 0.5, r), (S - r - 40, r + 120), (S - r - 40, S * 0.55), (S * 0.5, S - r), (r + 40, S * 0.55), (r + 40, r + 120)]
        d.polygon(pts, fill=255)
        m = m.filter(ImageFilter.GaussianBlur(26)).point(lambda v: 255 if v > 128 else 0).filter(ImageFilter.GaussianBlur(1.5))
    elif form == 'raute':
        pts = [(S * 0.5, r), (S - r, S * 0.5), (S * 0.5, S - r), (r, S * 0.5)]
        d.polygon(pts, fill=255)
        m = m.filter(ImageFilter.GaussianBlur(34)).point(lambda v: 255 if v > 128 else 0).filter(ImageFilter.GaussianBlur(1.5))
    return m


def grundbild(form, oben, unten):
    m = maske_form(form)
    a = np.zeros((S, S, 3), np.float32)
    yy, xx = np.mgrid[0:S, 0:S]
    t = np.clip((xx * 0.35 + yy * 0.65) / S, 0, 1)[:, :, None]
    a = np.array(hexf(oben), np.float32) * (1 - t) + np.array(hexf(unten), np.float32) * t
    img = Image.fromarray(a.astype(np.uint8), 'RGB').convert('RGBA')
    # Glanz: heller Verlauf von oben
    glanz = Image.new('RGBA', (S, S), (255, 255, 255, 0))
    gd = ImageDraw.Draw(glanz)
    gd.ellipse((-S * 0.2, -S * 0.65, S * 1.2, S * 0.5), fill=(255, 255, 255, 46))
    glanz = glanz.filter(ImageFilter.GaussianBlur(18))
    img = Image.alpha_composite(img, glanz)
    # dünner heller Rand innen
    rand = ImageChops.subtract(m, m.filter(ImageFilter.MinFilter(9)))
    kante = Image.new('RGBA', (S, S), (255, 255, 255, 0))
    kante.putalpha(rand.point(lambda v: int(v * 0.35)))
    img = Image.alpha_composite(img, kante)
    img.putalpha(m)
    return img


def schatten_unter(img):
    """leichter Schlagschatten, damit die Icons auf hellem Hintergrund stehen"""
    a = img.split()[3]
    sch = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    sch.putalpha(a.point(lambda v: int(v * 0.35)))
    sch = ImageChops.offset(sch, 0, 22).filter(ImageFilter.GaussianBlur(20))
    return Image.alpha_composite(sch, img)


# ------------------------------------------------------------------ Zeichen (weiß, in der Mitte)
def zeichen_mail(d, farbe):
    d.rounded_rectangle((250, 330, 774, 700), radius=36, fill=WEISS)
    d.line([(262, 352), (512, 560), (762, 352)], fill=farbe + (255,), width=34, joint='curve')
    d.line([(262, 690), (430, 520)], fill=farbe + (170,), width=20)
    d.line([(762, 690), (594, 520)], fill=farbe + (170,), width=20)


def zeichen_shop(d, farbe):
    d.rounded_rectangle((262, 380, 762, 760), radius=44, fill=WEISS)
    d.arc((372, 240, 652, 540), start=180, end=360, fill=WEISS, width=44)
    d.ellipse((396, 440, 440, 484), fill=farbe + (255,))
    d.ellipse((584, 440, 628, 484), fill=farbe + (255,))
    d.arc((410, 520, 614, 680), start=20, end=160, fill=farbe + (255,), width=30)


def zeichen_quests(d, farbe):
    d.rounded_rectangle((300, 240, 724, 784), radius=46, fill=WEISS)
    d.rounded_rectangle((420, 214, 604, 296), radius=30, fill=farbe + (255,))
    d.rounded_rectangle((440, 232, 584, 278), radius=22, fill=WEISS)
    for i, y in enumerate((380, 508, 636)):
        d.line([(356, y), (390, y + 34), (452, y - 36)], fill=farbe + (255,), width=26, joint='curve')
        d.rounded_rectangle((488, y - 14, 664, y + 14), radius=14, fill=farbe + (170,))


def zeichen_bank(d, farbe):
    d.polygon([(512, 250), (790, 420), (234, 420)], fill=WEISS)
    for x in (300, 430, 560, 690):
        d.rounded_rectangle((x - 34, 450, x + 34, 690), radius=14, fill=WEISS)
    d.rounded_rectangle((240, 712, 784, 772), radius=22, fill=WEISS)
    d.ellipse((482, 322, 542, 382), fill=farbe + (255,))


def zeichen_personal(d, farbe):
    for cx, groesse, alpha in ((380, 1.0, 255), (650, 0.86, 230)):
        k = groesse
        d.ellipse((cx - 78 * k, 320 - 20 * k, cx + 78 * k, 320 + 136 * k), fill=(255, 255, 255, alpha))
        d.pieslice((cx - 150 * k, 500, cx + 150 * k, 500 + 340 * k), start=180, end=360, fill=(255, 255, 255, alpha))
    d.rectangle((200, 700, 830, 760), fill=(0, 0, 0, 0))


def zeichen_bilanz(d, farbe):
    for i, (x, h) in enumerate(((290, 180), (430, 290), (570, 400), (710, 520))):
        d.rounded_rectangle((x - 50, 780 - h, x + 50, 780), radius=18, fill=WEISS)
    d.line([(290, 470), (450, 360), (560, 410), (740, 250)], fill=farbe + (255,), width=0)
    d.polygon([(700, 240), (800, 240), (800, 340)], fill=WEISS)
    d.line([(280, 520), (440, 410), (560, 470), (790, 250)], fill=(255, 255, 255, 255), width=30, joint='curve')


def zeichen_bier(d, farbe):
    d.rounded_rectangle((300, 340, 640, 790), radius=40, fill=WEISS)
    d.arc((560, 400, 800, 700), start=270, end=90, fill=WEISS, width=54)
    for i in range(3):
        x = 360 + i * 100
        d.rounded_rectangle((x - 22, 420, x + 22, 730), radius=22, fill=farbe + (150,))
    for cx, cy, r in ((350, 330, 70), (450, 290, 86), (560, 330, 74), (640, 360, 54)):
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=WEISS)


def zeichen_kalender(d, farbe):
    d.rounded_rectangle((232, 262, 792, 780), radius=60, fill=(250, 250, 252, 255))
    d.rounded_rectangle((232, 262, 792, 420), radius=60, fill=(235, 64, 64, 255))
    d.rectangle((232, 360, 792, 420), fill=(235, 64, 64, 255))
    for x in (360, 664):
        d.rounded_rectangle((x - 22, 214, x + 22, 316), radius=20, fill=(60, 60, 70, 255))
    for r in range(3):
        for c in range(4):
            x = 320 + c * 126
            y = 500 + r * 90
            d.rounded_rectangle((x - 30, y - 24, x + 30, y + 24), radius=10, fill=(120, 130, 150, 255) if (r + c) % 5 else (235, 64, 64, 255))


def zeichen_wetter(d, farbe):
    d.ellipse((520, 290, 680, 450), fill=(255, 214, 70, 255))
    for k in range(8):
        a = math.radians(45 * k)
        d.line([(600 + 98 * math.cos(a), 370 + 98 * math.sin(a)), (600 + 128 * math.cos(a), 370 + 128 * math.sin(a))], fill=(255, 214, 70, 255), width=18)
    d.ellipse((260, 470, 500, 710), fill=WEISS)
    d.ellipse((420, 400, 680, 660), fill=WEISS)
    d.ellipse((560, 500, 770, 710), fill=WEISS)
    d.rounded_rectangle((300, 560, 750, 720), radius=80, fill=WEISS)


def zeichen_social(d, farbe):
    d.rounded_rectangle((240, 270, 784, 660), radius=120, fill=WEISS)
    d.polygon([(340, 640), (330, 790), (480, 650)], fill=WEISS)
    # Herz
    pts = []
    for i in range(361):
        t = math.radians(i)
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((512 + x * 15, 440 - y * 15))
    d.polygon(pts, fill=farbe + (255,))


def zeichen_fest(d, farbe):
    # Feuerwerksstern
    import math as m
    mx, my = 512, 480
    for k in range(10):
        a = m.radians(36 * k)
        d.line([(mx + 90 * m.cos(a), my + 90 * m.sin(a)), (mx + 250 * m.cos(a), my + 250 * m.sin(a))], fill=WEISS, width=34)
        d.ellipse((mx + 270 * m.cos(a) - 30, my + 270 * m.sin(a) - 30, mx + 270 * m.cos(a) + 30, my + 270 * m.sin(a) + 30), fill=WEISS)
    d.ellipse((mx - 70, my - 70, mx + 70, my + 70), fill=farbe + (255,))
    d.rounded_rectangle((470, 700, 554, 820), radius=20, fill=WEISS)


ICONS = [
    ('mail', 'quadrat', '#4f9bff', '#1b48c4', zeichen_mail),
    ('shop', 'kreis', '#ffa04d', '#e0501a', zeichen_shop),
    ('quests', 'sechseck', '#b394ff', '#6a2fd0', zeichen_quests),
    ('bank', 'schild', '#3fe0a8', '#067a57', zeichen_bank),
    ('personal', 'kreis', '#38e0d0', '#0b7c78', zeichen_personal),
    ('bilanz', 'quadrat', '#ff7d92', '#c01a48', zeichen_bilanz),
    ('bierpreis', 'sechseck', '#ffd04a', '#c06a0a', zeichen_bier),
    ('kalender', 'quadrat', '#9fb4cf', '#5a6f8f', zeichen_kalender),
    ('wetter', 'raute', '#52c8ff', '#0b6fbe', zeichen_wetter),
    ('social', 'kreis', '#ff7cc4', '#b81a78', zeichen_social),
    ('fest', 'sechseck', '#ffd34a', '#d6361e', zeichen_fest),
]

for name, form, oben, unten, zeichner in ICONS:
    img = grundbild(form, oben, unten)
    zeichen = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    zeichner(ImageDraw.Draw(zeichen), hexf(unten))
    # Zeichen leicht schattieren, damit es sich abhebt
    sch = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    sch.putalpha(zeichen.split()[3].point(lambda v: int(v * 0.28)))
    sch = ImageChops.offset(sch, 0, 12).filter(ImageFilter.GaussianBlur(8))
    img = Image.alpha_composite(img, sch)
    img = Image.alpha_composite(img, zeichen)
    img = img.copy()
    maske = maske_form(form)
    img.putalpha(ImageChops.multiply(img.split()[3], maske))
    img = schatten_unter(img)
    img.resize((256, 256), Image.LANCZOS).save(os.path.join(ORDNER, f'icon_{name}.png'))
print('fertig')
