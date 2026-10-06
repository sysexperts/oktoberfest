"""Zeichnet das Hintergrundbild des Computer-Desktops: Abenddämmerung auf der Wiese mit Festzelt, Riesenrad und Lichterketten.
Eigenes Bild (assets/ui/desktop/hintergrund.png, 1920 x 1080). Aufruf: python tools/bake_desktop_hintergrund.py
"""
import math
import os
import random

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ORDNER = os.path.join(os.path.dirname(__file__), '..', 'assets', 'ui', 'desktop')
os.makedirs(ORDNER, exist_ok=True)
random.seed(11)
np.random.seed(11)
W, H = 1920, 1080
HOR = 640   # Horizont


def hexf(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def verlauf(w, h, stops):
    """stops: [(position 0..1, '#rrggbb'), …] von oben nach unten"""
    a = np.zeros((h, w, 3), np.float32)
    ys = np.linspace(0, 1, h)
    for c in range(3):
        a[:, :, c] = np.interp(ys, [s[0] for s in stops], [hexf(s[1])[c] for s in stops])[:, None]
    return Image.fromarray(a.astype(np.uint8), 'RGB').convert('RGBA')


def ebene():
    return Image.new('RGBA', (W, H), (0, 0, 0, 0))


# ------------------------------------------------------------------ Himmel
bild = verlauf(W, H, [(0.0, '#0b1a47'), (0.30, '#2b3a8c'), (0.50, '#8a5aa6'), (0.60, '#f08a58'), (0.66, '#ffc98a'), (1.0, '#ffc98a')])

# Sterne
st = ebene()
sd = ImageDraw.Draw(st)
for _ in range(260):
    x = random.randint(0, W)
    y = int(abs(random.gauss(0, 1)) * 150)
    if y > HOR - 220:
        continue
    r = random.choice([1, 1, 1, 2])
    sd.ellipse((x - r, y - r, x + r, y + r), fill=(255, 255, 255, random.randint(120, 255)))
bild = Image.alpha_composite(bild, st)

# Glühen der untergegangenen Sonne
gl = ebene()
gd = ImageDraw.Draw(gl)
gd.ellipse((900, HOR - 230, 1700, HOR + 230), fill=(255, 200, 120, 130))
gl = gl.filter(ImageFilter.GaussianBlur(120))
bild = Image.alpha_composite(bild, gl)

# Wolken: lange, warm beleuchtete Streifen
wo = Image.new('RGBA', (W, H), (255, 190, 150, 0))
wd = ImageDraw.Draw(wo)
for _ in range(34):
    cx = random.randint(-100, W + 100)
    cy = random.randint(150, HOR - 90)
    t = (cy - 150) / (HOR - 240)
    farbe = (int(120 + 135 * t), int(100 + 90 * t), int(180 - 40 * t))
    for _k in range(random.randint(3, 6)):
        rx = random.randint(120, 330)
        ry = random.randint(10, 26)
        wd.ellipse((cx + random.randint(-160, 160) - rx, cy + random.randint(-14, 14) - ry, cx + random.randint(-160, 160) + rx, cy + ry), fill=farbe + (random.randint(60, 120),))
wo = wo.filter(ImageFilter.GaussianBlur(11))
bild = Image.alpha_composite(bild, wo)


# ------------------------------------------------------------------ Berge mit Dunst
def grat(n, rauheit, seed):
    rnd = random.Random(seed)
    pts = [0.0] * (n + 1)
    pts[0] = rnd.uniform(-1, 1)
    pts[n] = rnd.uniform(-1, 1)
    schritt = n
    amp = 1.0
    while schritt > 1:
        halb = schritt // 2
        for i in range(halb, n, schritt):
            pts[i] = (pts[i - halb] + pts[i + halb]) / 2 + rnd.uniform(-amp, amp)
        amp *= rauheit
        schritt = halb
    return pts


def gebirge(hoehe, oben, unten, rauheit, seed, versatz=0, schnee=None):
    n = 512
    kurve = grat(n, rauheit, seed)
    lo, hi = min(kurve), max(kurve)
    xs = np.linspace(0, W, n + 1)
    punkte = [(x, HOR + versatz - (v - lo) / (hi - lo) * hoehe) for x, v in zip(xs, kurve)]
    m = Image.new('L', (W, H), 0)
    ImageDraw.Draw(m).polygon(punkte + [(W, H), (0, H)], fill=255)
    farbe = verlauf(W, H, [(0.0, oben), (0.5, unten), (1.0, unten)])
    e = ebene()
    e = Image.composite(farbe, e, m)
    e.putalpha(m)
    if schnee:
        sn = ebene()
        snd = ImageDraw.Draw(sn)
        grenze = HOR + versatz - hoehe * 0.6
        rnd = random.Random(seed + 3)
        for (x0, y0), (x1, y1) in zip(punkte[:-1], punkte[1:]):
            if y0 < grenze or y1 < grenze:
                tief = 18 + rnd.random() * 40
                snd.polygon([(x0, y0), (x1, y1), (x1, y1 + tief * 0.7), (x0, y0 + tief)], fill=hexf(schnee) + (230,))
        e = Image.alpha_composite(e, sn)
    return e


bild = Image.alpha_composite(bild, gebirge(300, '#7c6bb0', '#a77aa8', 0.62, 5, 0, '#ffd9c0'))
bild = Image.alpha_composite(bild, gebirge(210, '#4d4a98', '#6a5a9c', 0.58, 17, 6))
bild = Image.alpha_composite(bild, gebirge(130, '#2b2e6a', '#3b3b7a', 0.55, 23, 14))


# ------------------------------------------------------------------ Riesenrad (Silhouette mit Lichtern)
rr = ebene()
rd = ImageDraw.Draw(rr)
cx, cy, R = 1480, HOR - 80, 245
farbe_rad = (22, 22, 52, 255)
rd.line([(cx - 130, HOR + 110), (cx, cy), (cx + 130, HOR + 110)], fill=farbe_rad, width=16)
rd.line([(cx - 60, HOR + 110), (cx, cy), (cx + 60, HOR + 110)], fill=farbe_rad, width=10)
rd.ellipse((cx - R, cy - R, cx + R, cy + R), outline=farbe_rad, width=10)
rd.ellipse((cx - R + 40, cy - R + 40, cx + R - 40, cy + R - 40), outline=farbe_rad, width=5)
for k in range(16):
    a = math.radians(360 / 16 * k)
    rd.line([(cx, cy), (cx + R * math.cos(a), cy + R * math.sin(a))], fill=farbe_rad, width=5)
rd.ellipse((cx - 16, cy - 16, cx + 16, cy + 16), fill=farbe_rad)
lichter = ebene()
ld = ImageDraw.Draw(lichter)
for k in range(48):
    a = math.radians(360 / 48 * k)
    x, y = cx + R * math.cos(a), cy + R * math.sin(a)
    ld.ellipse((x - 7, y - 7, x + 7, y + 7), fill=(255, 220, 130, 255))
for k in range(16):
    a = math.radians(360 / 16 * k + 11)
    x, y = cx + (R - 6) * math.cos(a), cy + (R - 6) * math.sin(a)
    ld.rounded_rectangle((x - 17, y - 5, x + 17, y + 25), radius=6, fill=(255, 160, 80, 255))
leuchten = lichter.filter(ImageFilter.GaussianBlur(10))
bild = Image.alpha_composite(bild, rr)
bild = Image.alpha_composite(bild, leuchten)
bild = Image.alpha_composite(bild, lichter)


# ------------------------------------------------------------------ Wiese
def huegel(y0, amp, freq, phase, oben, unten):
    pts = [(x, y0 + amp * math.sin(x / freq + phase) + amp * 0.4 * math.sin(x / (freq * 0.43) + phase * 1.7)) for x in range(0, W + 8, 8)]
    m = Image.new('L', (W, H), 0)
    ImageDraw.Draw(m).polygon(pts + [(W, H), (0, H)], fill=255)
    e = Image.composite(verlauf(W, H, [(0.0, oben), (1.0, unten)]), ebene(), m)
    e.putalpha(m)
    return e


bild = Image.alpha_composite(bild, huegel(HOR + 70, 22, 200, 0.6, '#5b7f56', '#2f5a3a'))

# Festzelt (links) im Dämmerlicht mit warm leuchtendem Eingang
zx, zy = 520, HOR + 150
bw, bh = 400, 140
zelt = ebene()
maske = Image.new('L', (W, H), 0)
md = ImageDraw.Draw(maske)
md.rectangle((zx - bw // 2, zy - bh, zx + bw // 2, zy), fill=255)
md.polygon([(zx - bw // 2 - 18, zy - bh), (zx, zy - bh - 120), (zx + bw // 2 + 18, zy - bh)], fill=255)
streifen = Image.new('RGBA', (W, H), (205, 208, 226, 255))
sd2 = ImageDraw.Draw(streifen)
n_s = 20
for i in range(0, n_s + 1):
    if i % 2 == 0:
        x0 = zx - bw // 2 - 18 + i * (bw + 36) / n_s
        sd2.rectangle((x0, 0, x0 + (bw + 36) / n_s, H), fill=(54, 86, 170, 255))
zelt = Image.composite(streifen, zelt, maske)
zelt.putalpha(maske)
# Dämmerschatten über dem Zelt
dunkel = Image.new('RGBA', (W, H), (30, 20, 60, 70))
dunkel.putalpha(ImageChops.multiply(maske, Image.new('L', (W, H), 90)))
zelt = Image.alpha_composite(zelt, dunkel)
zd = ImageDraw.Draw(zelt)
zd.rounded_rectangle((zx - 52, zy - 96, zx + 52, zy), radius=16, fill=(255, 190, 90, 255))
zd.line((zx, zy - bh - 120, zx, zy - bh - 170), fill=(40, 30, 40, 255), width=5)
zd.polygon([(zx, zy - bh - 170), (zx + 56, zy - bh - 156), (zx, zy - bh - 142)], fill=(220, 60, 60, 255))
fenster = ebene()
fd = ImageDraw.Draw(fenster)
for fx in (-150, -100, 100, 150):
    fd.rounded_rectangle((zx + fx - 20, zy - 108, zx + fx + 20, zy - 52), radius=8, fill=(255, 205, 120, 255))
fenster_glow = fenster.filter(ImageFilter.GaussianBlur(14))
tor_glow = ebene()
ImageDraw.Draw(tor_glow).rounded_rectangle((zx - 52, zy - 96, zx + 52, zy), radius=16, fill=(255, 190, 90, 255))
tor_glow = tor_glow.filter(ImageFilter.GaussianBlur(26))
bild = Image.alpha_composite(bild, tor_glow)
bild = Image.alpha_composite(bild, zelt)
bild = Image.alpha_composite(bild, fenster_glow)
bild = Image.alpha_composite(bild, fenster)

# Lichterketten vom Zelt zu Masten
masten = ebene()
mdraw = ImageDraw.Draw(masten)
lk = ebene()
lkd = ImageDraw.Draw(lk)
for (x0, y0, x1, y1) in ((zx - bw // 2 - 18, zy - bh, 130, zy - bh - 40), (zx + bw // 2 + 18, zy - bh, 960, zy - bh - 20), (960, zy - bh - 20, 1230, zy - bh + 30)):
    mdraw.line((x1, y1 - 10, x1, zy + 36), fill=(30, 24, 40, 255), width=7)
    for k in range(31):
        t = k / 30
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t + 48 * math.sin(t * math.pi)
        lkd.ellipse((x - 5, y - 5, x + 5, y + 5), fill=random.choice([(255, 226, 150, 255), (255, 170, 90, 255), (255, 240, 200, 255)]))
bild = Image.alpha_composite(bild, masten)
bild = Image.alpha_composite(bild, lk.filter(ImageFilter.GaussianBlur(7)))
bild = Image.alpha_composite(bild, lk)

# Bäume und vordere Wiese
bm = ebene()
bd = ImageDraw.Draw(bm)
for x, y, g in ((120, HOR + 260, 1.2), (250, HOR + 285, 0.9), (1020, HOR + 250, 0.8), (1700, HOR + 270, 1.2), (1830, HOR + 300, 0.95)):
    bd.rectangle((x - 6 * g, y - 40 * g, x + 6 * g, y), fill=(24, 20, 30, 255))
    for k in range(3):
        bd.polygon([(x - (54 - k * 12) * g, y - (30 + k * 42) * g), (x + (54 - k * 12) * g, y - (30 + k * 42) * g), (x, y - (104 + k * 42) * g)], fill=(18, 40, 38, 255))
bild = Image.alpha_composite(bild, bm)
bild = Image.alpha_composite(bild, huegel(HOR + 330, 42, 330, 4.1, '#2c5535', '#0f2418'))

# Glühwürmchen
gw = ebene()
gwd = ImageDraw.Draw(gw)
for _ in range(70):
    x = random.randint(0, W)
    y = random.randint(HOR + 300, H - 20)
    r = random.randint(2, 4)
    gwd.ellipse((x - r, y - r, x + r, y + r), fill=(255, 235, 140, random.randint(160, 255)))
bild = Image.alpha_composite(bild, gw.filter(ImageFilter.GaussianBlur(5)))
bild = Image.alpha_composite(bild, gw)

# Gesamtfinish: Korn, Vignette, etwas abdunkeln für lesbare Symbole
a = np.asarray(bild.convert('RGB'), np.float32)
a += np.random.normal(0, 1.6, a.shape)
yy, xx = np.mgrid[0:H, 0:W]
v = 1 - 0.30 * (((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2)
a *= v[:, :, None]
Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGB').save(os.path.join(ORDNER, 'hintergrund.png'), optimize=True)
print('fertig')
