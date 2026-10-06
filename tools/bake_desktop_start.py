"""Zeichnet das Start-Icon des Desktops (assets/ui/desktop/icon_start.png): rundes Rautenwappen in Blau und Weiß mit goldenem Ring.
Aufruf: python tools/bake_desktop_start.py
"""
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ORDNER = os.path.join(os.path.dirname(__file__), '..', 'assets', 'ui', 'desktop')
S = 1024
BLAU = (36, 82, 178, 255)
HELL = (240, 244, 252, 255)
GOLD = (245, 190, 70, 255)

maske = Image.new('L', (S, S), 0)
ImageDraw.Draw(maske).ellipse((40, 40, S - 40, S - 40), fill=255)

raute = Image.new('RGBA', (S, S), HELL)
d = ImageDraw.Draw(raute)
schritt = 230
for zeile in range(-2, 7):
    for spalte in range(-2, 7):
        cx = spalte * schritt + (schritt / 2 if zeile % 2 else 0)
        cy = zeile * schritt / 2 + 20
        if (zeile + spalte) % 2 == 0 or True:
            if (spalte + (zeile // 2)) % 2 == 0:
                continue
        d.polygon([(cx, cy - schritt / 2), (cx + schritt / 2, cy), (cx, cy + schritt / 2), (cx - schritt / 2, cy)], fill=BLAU)
# einfachere, sichere Variante: Schachbrett aus gedrehten Quadraten
raute = Image.new('RGBA', (S, S), HELL)
d = ImageDraw.Draw(raute)
k = 190
for j in range(-3, 9):
    for i in range(-3, 9):
        if (i + j) % 2 == 0:
            cx = S / 2 + (i - j) * k / 2 * 1.0
            cy = S / 2 + (i + j) * k / 2 * 1.0 - 8 * k / 2
            d.polygon([(cx, cy - k / 2), (cx + k / 2, cy), (cx, cy + k / 2), (cx - k / 2, cy)], fill=BLAU)

bild = Image.new('RGBA', (S, S), (0, 0, 0, 0))
bild = Image.composite(raute, bild, maske)
bild.putalpha(maske)
# goldener Ring
ring = Image.new('RGBA', (S, S), (0, 0, 0, 0))
ImageDraw.Draw(ring).ellipse((40, 40, S - 40, S - 40), outline=GOLD, width=56)
ImageDraw.Draw(ring).ellipse((92, 92, S - 92, S - 92), outline=(255, 235, 170, 120), width=8)
bild = Image.alpha_composite(bild, ring)
# Glanz
glanz = Image.new('RGBA', (S, S), (255, 255, 255, 0))
ImageDraw.Draw(glanz).ellipse((100, -200, S - 100, 420), fill=(255, 255, 255, 50))
glanz = ImageChops.multiply(glanz, Image.merge('RGBA', (maske, maske, maske, maske)))
bild = Image.alpha_composite(bild, glanz.filter(ImageFilter.GaussianBlur(14)))
# Schatten
a = bild.split()[3]
sch = Image.new('RGBA', (S, S), (0, 0, 0, 0))
sch.putalpha(a.point(lambda v: int(v * 0.4)))
sch = ImageChops.offset(sch, 0, 20).filter(ImageFilter.GaussianBlur(18))
bild = Image.alpha_composite(sch, bild)
bild.resize((256, 256), Image.LANCZOS).save(os.path.join(ORDNER, 'icon_start.png'))
print('fertig')
