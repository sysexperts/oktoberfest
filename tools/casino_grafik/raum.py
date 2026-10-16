"""Texturen für den Casino-Raum: Teppich, Tapete, Girlande, Bilder an der Wand.
Ergebnis: assets/casino/raum_teppich.png, raum_tapete.png, raum_girlande.png, bild_*.png. Aufruf: python -X utf8 tools/casino_grafik/raum.py"""
import sys
import random
sys.path.insert(0, __import__("os").path.dirname(__file__))
from gemeinsam import *


def teppich():
    g = 512
    s = g * SS
    im = Image.new("RGBA", (s, s), (92, 12, 26, 255))
    d = ImageDraw.Draw(im)
    # Rautengitter in Gold, dazwischen kleine Rosetten
    n = 4
    w = s / n
    for j in range(-1, n + 1):
        for i in range(-1, n + 1):
            cx, cy = i * w + w / 2, j * w + w / 2
            d.polygon([(cx, cy - w / 2), (cx + w / 2, cy), (cx, cy + w / 2), (cx - w / 2, cy)], outline=(214, 168, 66, 255), width=int(3 * SS))
            r = w * 0.3
            d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], fill=(118, 18, 34, 255), outline=(176, 130, 50, 255), width=int(2 * SS))
            d.ellipse([cx - 9 * SS, cy - 9 * SS, cx + 9 * SS, cy + 9 * SS], fill=(214, 168, 66, 255))
            for a in range(4):
                ax, ay = cx + w / 2 * (1 if a % 2 == 0 else 0) * (1 if a < 2 else -1), cy
            d.ellipse([i * w - 5 * SS, j * w - 5 * SS, i * w + 5 * SS, j * w + 5 * SS], fill=(214, 168, 66, 255))
    rnd = random.Random(2)
    for _ in range(5000):
        x, y = rnd.randrange(s), rnd.randrange(s)
        d.point((x, y), fill=(60, 6, 16, 80))
    return runter(im)


def tapete():
    g = 512
    s = g * SS
    im = Image.new("RGBA", (s, s), (58, 12, 20, 255))
    d = ImageDraw.Draw(im)
    # senkrechte Streifen und Damast-Medaillons
    for i in range(0, 8):
        x = i * s / 8
        d.rectangle([x, 0, x + s / 16, s], fill=(66, 15, 24, 255))
    for j in range(2):
        for i in range(2):
            cx, cy = (i + 0.5) * s / 2 + (s / 4 if j % 2 else 0), (j + 0.5) * s / 2
            cx = cx % s
            r = s * 0.13
            d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(98, 30, 40, 255), width=int(5 * SS))
            d.ellipse([cx - r * 0.5, cy - r * 0.5, cx + r * 0.5, cy + r * 0.5], fill=(78, 20, 30, 255), outline=(110, 38, 48, 255), width=int(3 * SS))
            for a in range(8):
                ax = cx + r * 1.18 * math.cos(a * math.pi / 4)
                ay = cy + r * 1.18 * math.sin(a * math.pi / 4)
                d.ellipse([ax - 9 * SS, ay - 9 * SS, ax + 9 * SS, ay + 9 * SS], fill=(98, 30, 40, 255))
    return runter(im)


def girlande():
    """Wimpelkette: blau-weiße Rauten-Fähnchen und rote Fähnchen im Wechsel, 4 Stück je Kachel, Hintergrund durchsichtig"""
    b, h = 512, 128
    s = Image.new("RGBA", (b * SS, h * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(s)
    d.line([(0, 8 * SS), (b * SS, 8 * SS)], fill=(60, 40, 20, 255), width=int(4 * SS))
    for i in range(4):
        x0 = i * b / 4 * SS
        x1 = (i + 1) * b / 4 * SS - 6 * SS
        xm = (x0 + x1) / 2
        d.polygon([(x0 + 6 * SS, 8 * SS), (x1, 8 * SS), (xm + 3 * SS, 112 * SS)], fill=(205, 30, 40, 255) if i % 2 else (245, 247, 252, 255))
        if i % 2 == 0:
            for k in range(3):
                for m in range(3 - k):
                    cx = x0 + 6 * SS + (x1 - x0 - 6 * SS) * (0.2 + 0.3 * m + 0.15 * k)
                    cy = (24 + 26 * k) * SS
                    r = 9 * SS
                    d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], fill=(40, 100, 200, 255))
    return runter(s)


def bild(titel, untertitel, motiv):
    b, h = 400, 540
    s = Image.new("RGBA", (b * SS, h * SS), (30, 12, 14, 255))
    d = ImageDraw.Draw(s)
    d.rectangle([14 * SS, 14 * SS, (b - 14) * SS, (h - 14) * SS], outline=(214, 168, 66, 255), width=int(5 * SS))
    d.rectangle([28 * SS, 28 * SS, (b - 28) * SS, (h - 28) * SS], outline=(150, 112, 40, 255), width=int(2 * SS))
    # Rautenband oben und unten
    for i in range(10):
        cx = 60 * SS + i * 31 * SS
        for cy in (48 * SS, (h - 48) * SS):
            r = 11 * SS
            d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], fill=(40, 100, 200, 255) if i % 2 == 0 else (245, 247, 252, 255))
    text_mittig(d, (b * SS / 2, 120 * SS), titel, font(FONT_FRAKTUR, 76 * SS), (255, 226, 130, 255))
    text_mittig(d, (b * SS / 2, (h - 112) * SS), untertitel, font(FONT_FETT, 30 * SS), (236, 190, 84, 255))
    mx, my = b * SS / 2, 290 * SS
    if motiv == "karte":
        for k, (dx, rot) in enumerate(((-70, -14), (0, 0), (70, 14))):
            karte = Image.new("RGBA", (130 * SS, 190 * SS), (0, 0, 0, 0))
            kd = ImageDraw.Draw(karte)
            kd.rounded_rectangle([0, 0, 129 * SS, 189 * SS], radius=14 * SS, fill=(250, 246, 236, 255), outline=(60, 40, 20, 255), width=int(3 * SS))
            text_mittig(kd, (65 * SS, 95 * SS), ["♥", "♠", "♦"][k], font("C:/Windows/fonts/seguisym.ttf", 90 * SS), (200, 30, 40, 255) if k != 1 else (20, 20, 24, 255))
            karte = karte.rotate(rot, expand=True, resample=Image.BICUBIC)
            s.alpha_composite(karte, (int(mx + dx * SS - karte.width / 2), int(my - karte.height / 2)))
    elif motiv == "mass":
        sym = Image.open(os.path.join(AUS, "slot_mass.png")).convert("RGBA").resize((300 * SS, 300 * SS), Image.LANCZOS)
        s.alpha_composite(sym, (int(mx - 150 * SS), int(my - 150 * SS)))
    else:
        sym = Image.open(os.path.join(AUS, "chip_500.png")).convert("RGBA").resize((260 * SS, 260 * SS), Image.LANCZOS)
        s.alpha_composite(sym, (int(mx - 130 * SS), int(my - 130 * SS)))
        sym2 = Image.open(os.path.join(AUS, "slot_sieben.png")).convert("RGBA").resize((150 * SS, 150 * SS), Image.LANCZOS)
        s.alpha_composite(sym2, (int(mx - 75 * SS), int(my - 75 * SS)))
    return runter(s)


if __name__ == "__main__":
    speichern(teppich(), "raum_teppich.png")
    speichern(tapete(), "raum_tapete.png")
    speichern(girlande(), "raum_girlande.png")
    speichern(bild("Casino", "Prosit & Glück", "chip"), "bild_casino.png")
    speichern(bild("Blatt", "Bayerisch spielen", "karte"), "bild_karten.png")
    speichern(bild("Maß", "Eine Maß geht immer", "mass"), "bild_mass.png")
    v = Image.new("RGBA", (1700, 560), (30, 30, 30, 255))
    x = 10
    for n in ("raum_teppich", "raum_tapete", "bild_casino", "bild_karten", "bild_mass"):
        im = Image.open(os.path.join(AUS, n + ".png")).convert("RGBA")
        im = im.resize((int(im.width * 540 / im.height) if im.height > 512 else im.width, min(im.height, 540)))
        v.alpha_composite(im, (x, 10))
        x += im.width + 10
    v.convert("RGB").save(os.path.join(ROOT, "build", "raum_vorschau.png"))
    print("fertig")
