"""Zeichnet das Hintergrundbild und die Bauteile des Computer-Desktops (assets/ui/desktop/*.png).
Eigene Bilder, keine Vorlage: Alpenwiese mit Festzelt für den Hintergrund, Farbverläufe für Taskleiste, Titelleiste und Knöpfe.
Aufruf: python tools/bake_desktop_bilder.py
"""
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ORDNER = os.path.join(os.path.dirname(__file__), '..', 'assets', 'ui', 'desktop')
os.makedirs(ORDNER, exist_ok=True)
random.seed(7)
np.random.seed(7)


def hexf(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def verlauf(w, h, oben, unten):
    a = np.zeros((h, w, 3), np.float32)
    for y in range(h):
        t = y / max(h - 1, 1)
        a[y, :, :] = np.array(oben) * (1 - t) + np.array(unten) * t
    return Image.fromarray(a.astype(np.uint8), 'RGB')


# ------------------------------------------------------------------ Hintergrundbild
def hintergrund():
    W, H = 1920, 1080
    horizont = int(H * 0.52)
    himmel = verlauf(W, H, hexf('#2f78d8'), hexf('#bfe2ff')).convert('RGBA')
    # Wolken: weiche Ellipsen
    wolken = Image.new('RGBA', (W, H), (255, 255, 255, 0))
    d = ImageDraw.Draw(wolken)
    for _ in range(26):
        cx = random.randint(-100, W + 100)
        cy = random.randint(60, int(H * 0.42))
        for _k in range(random.randint(5, 9)):
            rx = random.randint(70, 190)
            ry = random.randint(24, 55)
            dx = random.randint(-150, 150)
            dy = random.randint(-22, 22)
            d.ellipse((cx + dx - rx, cy + dy - ry, cx + dx + rx, cy + dy + ry), fill=(255, 255, 255, random.randint(70, 150)))
    wolken = wolken.filter(ImageFilter.GaussianBlur(9))
    bild = Image.alpha_composite(himmel, wolken)

    def grat(n, h0, rauheit, seed):
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
        return [h0 + p * 1.0 for p in pts]

    def gebirge(ebene, farbe_oben, farbe_unten, hoehe, rauheit, seed, schnee):
        n = 512
        kurve = grat(n, 0, rauheit, seed)
        lo, hi = min(kurve), max(kurve)
        ebene_img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        d2 = ImageDraw.Draw(ebene_img)
        xs = np.linspace(0, W, n + 1)
        punkte = []
        for x, v in zip(xs, kurve):
            y = horizont - (v - lo) / (hi - lo) * hoehe
            punkte.append((x, y))
        d2.polygon(punkte + [(W, H), (0, H)], fill=farbe_unten + (255,))
        # Verlauf von oben nach unten
        maske = ebene_img.split()[3]
        grad = verlauf(W, H, farbe_oben, farbe_unten).convert('RGBA')
        ebene_img = Image.composite(grad, ebene_img, maske)
        ebene_img.putalpha(maske)
        if schnee:
            sd = ImageDraw.Draw(ebene_img)
            rnd2 = random.Random(seed + 5)
            tiefe = [rnd2.uniform(0.3, 1.0) for _ in range(40)]
            for (x0, y0), (x1, y1) in zip(punkte[:-1], punkte[1:]):
                if y0 < horizont - hoehe * 0.62 or y1 < horizont - hoehe * 0.62:
                    d0 = 26 + 48 * tiefe[int(x0 / W * 39)]
                    sd.polygon([(x0, y0), (x1, y1), (x1, y1 + d0 * 0.8), (x0, y0 + d0)], fill=(246, 249, 255, 255))
        return ebene_img

    bild = Image.alpha_composite(bild, gebirge(0, hexf('#7f9cc6'), hexf('#a9c3e2'), 330, 0.62, 3, True).filter(ImageFilter.GaussianBlur(1.2)))
    bild = Image.alpha_composite(bild, gebirge(1, hexf('#5d7fa8'), hexf('#8fb2d6'), 220, 0.58, 11, False))

    # Wiesenhügel: drei Lagen
    def huegel(y0, amp, freq, phase, oben, unten):
        ebene_img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        d2 = ImageDraw.Draw(ebene_img)
        pts = []
        for x in range(0, W + 8, 8):
            y = y0 + amp * math.sin(x / freq + phase) + amp * 0.4 * math.sin(x / (freq * 0.43) + phase * 1.7)
            pts.append((x, y))
        d2.polygon(pts + [(W, H), (0, H)], fill=(0, 0, 0, 255))
        maske = ebene_img.split()[3]
        grad = verlauf(W, H, oben, unten).convert('RGBA')
        out = Image.composite(grad, ebene_img, maske)
        out.putalpha(maske)
        return out, pts

    h1, p1 = huegel(horizont + 20, 26, 190, 0.4, hexf('#7cc055'), hexf('#4f9b3a'))
    bild = Image.alpha_composite(bild, h1)
    h2, p2 = huegel(horizont + 130, 38, 260, 2.1, hexf('#5eaa3e'), hexf('#3c8a2c'))

    # Festzelt auf dem hinteren Hügel (weiß-blau gestreift) mit Fähnchen
    zelt = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    zd = ImageDraw.Draw(zelt)
    zx, zy = 1330, horizont + 36
    breite, hoehe = 250, 96
    maske = Image.new('L', (W, H), 0)
    md = ImageDraw.Draw(maske)
    md.rectangle((zx - breite // 2, zy - hoehe, zx + breite // 2, zy), fill=255)
    md.polygon([(zx - breite // 2 - 12, zy - hoehe), (zx, zy - hoehe - 80), (zx + breite // 2 + 12, zy - hoehe)], fill=255)
    streifen_img = Image.new('RGBA', (W, H), (236, 238, 244, 255))
    sd2 = ImageDraw.Draw(streifen_img)
    for i in range(0, 17):
        x0 = zx - breite // 2 - 12 + i * (breite + 24) / 16
        if i % 2 == 0:
            sd2.rectangle((x0, 0, x0 + (breite + 24) / 16, H), fill=(46, 94, 190, 255))
    zelt = Image.composite(streifen_img, zelt, maske)
    zelt.putalpha(maske)
    zd = ImageDraw.Draw(zelt)
    zd.rectangle((zx - 26, zy - 58, zx + 26, zy), fill=(70, 40, 24, 255))
    zd.line((zx, zy - hoehe - 80, zx, zy - hoehe - 122), fill=(60, 40, 30, 255), width=4)
    zd.polygon([(zx, zy - hoehe - 122), (zx + 46, zy - hoehe - 110), (zx, zy - hoehe - 98)], fill=(220, 40, 40, 255))
    for i in range(18):
        xa = zx - 330 + i * 38
        ya = zy - hoehe + 20 + 14 * math.sin(i / 17 * math.pi)
        zd.polygon([(xa, ya), (xa + 24, ya), (xa + 12, ya + 28)], fill=[(46, 94, 190, 255), (236, 238, 244, 255)][i % 2])
    zelt = zelt.filter(ImageFilter.GaussianBlur(0.6))
    bild = Image.alpha_composite(bild, zelt)
    bild = Image.alpha_composite(bild, h2)

    # Bäume auf dem vorderen Hügel
    baeume = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(baeume)
    for x, y, g in ((210, horizont + 150, 1.0), (330, horizont + 170, 0.8), (1560, horizont + 160, 1.1), (1680, horizont + 185, 0.85), (880, horizont + 200, 0.7)):
        bd.rectangle((x - 5 * g, y - 40 * g, x + 5 * g, y), fill=(84, 54, 32, 255))
        for k in range(3):
            bd.polygon([(x - (46 - k * 10) * g, y - (30 + k * 38) * g), (x + (46 - k * 10) * g, y - (30 + k * 38) * g), (x, y - (92 + k * 38) * g)], fill=(34, 100, 54, 255))
    bild = Image.alpha_composite(bild, baeume)

    h3, p3 = huegel(horizont + 280, 46, 330, 4.2, hexf('#7dd05a'), hexf('#2f7a24'))
    bild = Image.alpha_composite(bild, h3)
    # Blumenpunkte auf der Wiese
    bl = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    bld = ImageDraw.Draw(bl)
    for _ in range(420):
        x = random.randint(0, W)
        y = random.randint(horizont + 330, H - 4)
        r = random.randint(2, 5)
        farbe = random.choice([(255, 255, 255), (255, 214, 64), (255, 120, 140), (190, 140, 255)])
        bld.ellipse((x - r, y - r * 0.6, x + r, y + r * 0.6), fill=farbe + (230,))
    bild = Image.alpha_composite(bild, bl)
    # leichtes Korn und Vignette
    a = np.asarray(bild.convert('RGB'), np.float32)
    a += np.random.normal(0, 2.0, a.shape)
    yy, xx = np.mgrid[0:H, 0:W]
    v = 1 - 0.18 * (((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2)
    a *= v[:, :, None]
    Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGB').save(os.path.join(ORDNER, 'hintergrund.png'), optimize=True)


# ------------------------------------------------------------------ Bauteile
def teil(name, w, h, oben, unten, rand=None, abrunden=0, linie_oben=None):
    img = verlauf(w, h, hexf(oben), hexf(unten)).convert('RGBA')
    d = ImageDraw.Draw(img)
    if linie_oben:
        d.line((0, 0, w, 0), fill=hexf(linie_oben) + (255,))
    if rand:
        d.rectangle((0, 0, w - 1, h - 1), outline=hexf(rand) + (255,))
    if abrunden:
        m = Image.new('L', (w, h), 0)
        ImageDraw.Draw(m).rounded_rectangle((0, 0, w - 1, h - 1), radius=abrunden, fill=255)
        img.putalpha(m)
    img.save(os.path.join(ORDNER, name + '.png'))


hintergrund()
teil('taskleiste', 8, 44, '#2f66c8', '#173f95', linie_oben='#7ea4ec')
teil('titel_aktiv', 8, 30, '#3a79de', '#1c4aa8', linie_oben='#8fb4f2')
teil('titel_inaktiv', 8, 30, '#8a9fc8', '#6b82b0', linie_oben='#b5c4e2')
teil('start_normal', 112, 40, '#f4c24a', '#c98a14', rand='#8a5a08', abrunden=10)
teil('start_hover', 112, 40, '#ffd569', '#dc9d22', rand='#8a5a08', abrunden=10)
teil('start_gedrueckt', 112, 40, '#b87c10', '#e0a232', rand='#6a4204', abrunden=10)
teil('task_ruhe', 8, 34, '#4a7dd8', '#2a56b4', rand='#173f95', abrunden=4)
teil('task_aktiv', 8, 34, '#1a3f8c', '#2a56b4', rand='#0f2a6a', abrunden=4)
teil('schliessen_knopf', 24, 24, '#e9805e', '#c2381a', rand='#ffffff', abrunden=4)
teil('klein_knopf', 24, 24, '#5b90ea', '#2556b8', rand='#ffffff', abrunden=4)
teil('startmenue_kopf', 8, 52, '#2f66c8', '#173f95')
print('fertig', ORDNER)
