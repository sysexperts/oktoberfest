"""Symbole für das Q-Emote-Rad: moderne Piktogramme (weiß, abgerundete Striche) auf durchsichtigem Grund.
Ergebnis: assets/ui/emote/<name>.png (192 x 192). Das Rad färbt die Scheibe dahinter (scripts/ui/emote_rad.gd).
Aufruf: python -X utf8 tools/emote_icons.py"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
AUS = os.path.join(ROOT, "assets", "ui", "emote")
os.makedirs(AUS, exist_ok=True)
SS = 4
G = 192
S = G * SS
WEISS = (255, 255, 255, 255)
AMBER = (255, 205, 80, 255)
GRUEN = (150, 235, 120, 255)
BLAU = (150, 215, 255, 255)


def neu():
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def p(x, y):
    return (x * S / 100.0, y * S / 100.0)


def linie(d, pts, breite=7, farbe=WEISS):
    """Dicker Strich mit runden Enden und Ecken (Koordinaten 0..100)"""
    q = [p(*a) for a in pts]
    w = breite * S / 100.0
    d.line(q, fill=farbe, width=int(w), joint="curve")
    r = w / 2
    for x, y in (q[0], q[-1]):
        d.ellipse([x - r, y - r, x + r, y + r], fill=farbe)


def kreis(d, x, y, r, farbe=WEISS, rand=None, rand_breite=0):
    cx, cy = p(x, y)
    rr = r * S / 100.0
    d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=farbe, outline=rand, width=int(rand_breite * S / 100.0))


def bogen(d, x, y, r, von, bis, breite=6, farbe=WEISS):
    cx, cy = p(x, y)
    rr = r * S / 100.0
    d.arc([cx - rr, cy - rr, cx + rr, cy + rr], von, bis, fill=farbe, width=int(breite * S / 100.0))


def polygon(d, pts, farbe=WEISS):
    d.polygon([p(*a) for a in pts], fill=farbe)


def abrunden(d, pts, farbe=WEISS, radius=2.2):
    """Gefülltes Polygon mit weichen Ecken: füllen und mit rundem Strich umranden"""
    polygon(d, pts, farbe)
    linie(d, pts + [pts[0]], radius * 2, farbe)


def funkeln(d, x, y, r, farbe=WEISS):
    polygon(d, [(x, y - r), (x + r * 0.28, y - r * 0.28), (x + r, y), (x + r * 0.28, y + r * 0.28), (x, y + r), (x - r * 0.28, y + r * 0.28), (x - r, y), (x - r * 0.28, y - r * 0.28)], farbe)


def speichern(im, name):
    # weicher Schatten für Lesbarkeit auf hellen Scheiben
    sch = Image.new("RGBA", im.size, (0, 0, 0, 0))
    a = im.getchannel("A").filter(ImageFilter.GaussianBlur(5 * SS))
    sch.paste((0, 0, 0, 255), (0, 6 * SS), a.point(lambda v: int(v * 0.35)))
    sch.alpha_composite(im)
    sch.resize((G, G), Image.LANCZOS).save(os.path.join(AUS, name + ".png"))


def krug(d, x, y, breite=26, hoehe=38, farbe=WEISS, bier=AMBER):
    """Maßkrug mit Henkel, Schaum und Bier (linke obere Ecke bei x, y)"""
    b, h = breite, hoehe
    abrunden(d, [(x, y + 8), (x + b, y + 8), (x + b - 2, y + h), (x + 2, y + h)], farbe, 1.8)
    abrunden(d, [(x + 3, y + 16), (x + b - 3, y + 16), (x + b - 4.5, y + h - 3), (x + 4.5, y + h - 3)], bier, 1.2)
    for (cx, cy, r) in ((x + 5, y + 7, 5.5), (x + b / 2, y + 4, 7), (x + b - 5, y + 7, 5.5)):
        kreis(d, cx, cy, r, farbe)
    bogen(d, x + b + 1, y + h * 0.5, h * 0.27, -80, 80, 4.2, farbe)


def jubel():
    im, d = neu()
    krug(d, 14, 34, 30, 42)
    krug(d, 56, 34, 30, 42)
    funkeln(d, 50, 18, 8)
    funkeln(d, 30, 14, 4.5)
    funkeln(d, 71, 15, 5)
    linie(d, [(48, 40), (52, 40)], 3, WEISS)
    return im


def trinken():
    im, d = neu()
    krug(d, 28, 22, 36, 54)
    funkeln(d, 78, 24, 6)
    funkeln(d, 20, 18, 4)
    return im


def tanzen():
    im, d = neu()
    kreis(d, 44, 20, 8)
    linie(d, [(44, 30), (46, 52)], 8)                         # Körper
    linie(d, [(45, 36), (66, 24), (76, 12)], 7)              # Arm hoch
    linie(d, [(45, 38), (27, 50), (18, 44)], 7)              # Arm angewinkelt
    linie(d, [(46, 52), (36, 72), (28, 88)], 7.5)            # Standbein
    linie(d, [(46, 52), (60, 66), (74, 62)], 7.5)            # Spielbein
    # Noten
    kreis(d, 80, 40, 5.2)
    linie(d, [(84.5, 40), (84.5, 20), (92, 24)], 3.6)
    kreis(d, 14, 70, 4.2)
    linie(d, [(17.8, 70), (17.8, 54)], 3)
    return im


def sitzen():
    im, d = neu()
    kreis(d, 38, 22, 9)
    linie(d, [(38, 33), (40, 56)], 9)                         # Rücken
    linie(d, [(40, 56), (62, 56), (66, 84)], 8)              # Oberschenkel, Unterschenkel
    linie(d, [(41, 40), (58, 50), (70, 46)], 7)              # Arm auf dem Knie
    linie(d, [(30, 56), (30, 90)], 5, (255, 255, 255, 150))  # Stuhlbeine
    linie(d, [(26, 56), (50, 56)], 5, (255, 255, 255, 150))
    linie(d, [(26, 40), (26, 56)], 5, (255, 255, 255, 150))  # Lehne
    linie(d, [(52, 56), (52, 90)], 5, (255, 255, 255, 150))
    return im


def posen():
    im, d = neu()
    kreis(d, 50, 16, 8.5)
    abrunden(d, [(40, 28), (60, 28), (64, 56), (36, 56)], WEISS, 3)    # Oberkörper
    linie(d, [(40, 32), (24, 40), (20, 22)], 8)                        # Bizeps links
    linie(d, [(60, 32), (76, 40), (80, 22)], 8)                        # Bizeps rechts
    kreis(d, 21, 33, 6.5)
    kreis(d, 79, 33, 6.5)
    linie(d, [(42, 56), (38, 90)], 8)
    linie(d, [(58, 56), (62, 90)], 8)
    funkeln(d, 86, 10, 6)
    funkeln(d, 12, 12, 5)
    funkeln(d, 90, 56, 4)
    return im


def winken():
    im, d = neu()
    # Hand: Handfläche mit fünf Fingern
    abrunden(d, [(32, 56), (68, 56), (72, 76), (60, 90), (40, 90), (28, 76)], WEISS, 4)
    for x, top in ((33, 28), (44, 20), (55, 20), (66, 28)):
        linie(d, [(x, 56), (x, top + 4)], 9)
    linie(d, [(32, 62), (18, 50), (16, 42)], 9)               # Daumen
    # Winkbogen
    bogen(d, 52, 52, 44, -145, -108, 3.4, (255, 255, 255, 170))
    bogen(d, 52, 52, 44, -72, -35, 3.4, (255, 255, 255, 170))
    return im


def gesicht(d, mund, traene=False, speiben=False):
    kreis(d, 50, 50, 38, WEISS)
    kreis(d, 50, 50, 38, (0, 0, 0, 0))
    return d


def traurig():
    im, d = neu()
    kreis(d, 50, 50, 38, (255, 255, 255, 255))
    kreis(d, 37, 44, 4.4, (60, 60, 80, 255))
    kreis(d, 63, 44, 4.4, (60, 60, 80, 255))
    linie(d, [(30, 40), (44, 34)], 3.4, (60, 60, 80, 255))      # Brauen: innen hoch
    linie(d, [(70, 40), (56, 34)], 3.4, (60, 60, 80, 255))
    bogen(d, 50, 74, 16, 205, 335, 4.4, (60, 60, 80, 255))
    polygon(d, [(35, 52), (31, 62), (39, 62)], BLAU)             # Träne
    kreis(d, 35, 63, 4, BLAU)
    return im


def kotzen():
    im, d = neu()
    kreis(d, 42, 44, 34, (190, 235, 150, 255))
    linie(d, [(26, 38), (36, 42)], 3.6, (40, 70, 40, 255))      # zugekniffene Augen
    linie(d, [(48, 42), (58, 38)], 3.6, (40, 70, 40, 255))
    linie(d, [(26, 38), (36, 34)], 0.1, (40, 70, 40, 255))
    kreis(d, 54, 62, 9, (40, 70, 40, 255))                        # offener Mund
    # Strahl
    abrunden(d, [(60, 62), (86, 56), (92, 72), (66, 72)], GRUEN, 3)
    for x, y, r in ((88, 84, 4.4), (74, 88, 3.6), (94, 66, 3.2), (80, 94, 2.6)):
        kreis(d, x, y, r, GRUEN)
    return im


def abwenden():
    """Wendet sich ab und geht: Figur von hinten, die den Kopf wegdreht, dazu ein Wendepfeil und Geschwindigkeitsstriche"""
    im, d = neu()
    kreis(d, 38, 22, 9)
    abrunden(d, [(28, 34), (48, 34), (52, 62), (24, 62)], WEISS, 3)       # Rücken
    linie(d, [(30, 38), (18, 52), (22, 62)], 7)                           # Arm schwingt zurück
    linie(d, [(46, 38), (56, 50)], 7)
    linie(d, [(32, 62), (28, 92)], 8)
    linie(d, [(44, 62), (54, 78), (62, 92)], 8)                           # Schritt nach rechts
    # Wendepfeil
    bogen(d, 62, 40, 24, -170, -20, 5.5, (255, 255, 255, 235))
    polygon(d, [(86, 34), (96, 52), (76, 50)], (255, 255, 255, 235))
    for y in (70, 80, 90):
        linie(d, [(6, y), (16, y)], 3, (255, 255, 255, 150))
    return im


def catwalk():
    im, d = neu()
    # High Heel von der Seite: Spitze unten links, Ferse oben rechts, dünner Absatz
    polygon(d, [(8, 76), (9, 66), (28, 56), (52, 38), (60, 20), (80, 20), (82, 42), (74, 60)], WEISS)
    linie(d, [(8, 76), (74, 60)], 5)
    linie(d, [(74, 60), (80, 92)], 6.5)
    linie(d, [(60, 20), (80, 20)], 4, (255, 120, 170, 255))
    funkeln(d, 22, 28, 7)
    funkeln(d, 90, 70, 4)
    return im


ICONS = {"jubel": jubel, "trinken": trinken, "tanzen": tanzen, "sitzen": sitzen, "posen": posen, "winken": winken,
         "sad": traurig, "kotzen": kotzen, "abwenden": abwenden, "catwalk": catwalk}

if __name__ == "__main__":
    bogen_bild = Image.new("RGBA", (len(ICONS) * 210 + 10, 230), (60, 40, 90, 255))
    for i, (n, f) in enumerate(ICONS.items()):
        im = f()
        speichern(im, n)
        bogen_bild.alpha_composite(Image.open(os.path.join(AUS, n + ".png")), (10 + i * 210, 20))
    bogen_bild.convert("RGB").save(os.path.join(ROOT, "build", "emote_icons_vorschau.png"))
    print("fertig")
