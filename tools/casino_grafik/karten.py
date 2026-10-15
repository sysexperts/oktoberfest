"""Spielkarten fürs Casino: französisches Blatt (Blackjack, 52 Karten) und bayerisches Blatt (Watten, 32 Karten), dazu der Rücken.
Ergebnis: assets/casino/karte_<farbe>_<rang>.png (240 x 336) und karte_ruecken.png. Aufruf: python -X utf8 tools/casino_grafik/karten.py"""
import math
import sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from gemeinsam import *

KB, KH = 240, 336
B, H = KB * SS, KH * SS
ROT = (196, 30, 44)
SCHWARZ = (28, 30, 38)
GRUEN = (38, 130, 62)
BRAUN = (120, 74, 36)
GOLD = (222, 170, 58)


def v(x, y, groesse, mx, my):
    return (mx + x * groesse, my + y * groesse)


def symbol_bild(art, g, farbe, glanz=True):
    """Farbzeichen als eigenes RGBA-Bild (g x g, schon überabgetastet gedacht): herz, karo, pik, kreuz, eichel, laub, schellen."""
    S = g
    im = leer(S, S)
    d = ImageDraw.Draw(im)
    m = S / 2
    r = S * 0.46
    if art == "herz":
        pts = []
        for i in range(0, 361, 3):
            t = math.radians(i)
            x = 16 * math.sin(t) ** 3
            y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
            pts.append((m + x / 17.5 * r, m + (y + 1.0) / 17.0 * r * 1.0))
        d.polygon(pts, fill=farbe)
    elif art == "karo":
        d.polygon([(m, m - r * 1.02), (m + r * 0.68, m), (m, m + r * 1.02), (m - r * 0.68, m)], fill=farbe)
    elif art == "pik":
        pts = []
        for i in range(0, 361, 3):
            t = math.radians(i)
            x = 16 * math.sin(t) ** 3
            y = (13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
            pts.append((m + x / 17.5 * r, m + (y - 1.2) / 17.0 * r * 1.0))
        d.polygon(pts, fill=farbe)
        d.polygon([(m, m + r * 0.1), (m + r * 0.38, m + r * 0.98), (m - r * 0.38, m + r * 0.98)], fill=farbe)
    elif art == "kreuz":
        rr = r * 0.40
        for (cx, cy) in ((m, m - r * 0.52), (m - r * 0.52, m + r * 0.18), (m + r * 0.52, m + r * 0.18)):
            d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=farbe)
        d.polygon([(m, m - r * 0.1), (m + r * 0.33, m + r * 1.0), (m - r * 0.33, m + r * 1.0)], fill=farbe)
        d.rectangle([m - r * 0.1, m - r * 0.1, m + r * 0.1, m + r * 0.3], fill=farbe)
    elif art == "schellen":
        # Glocke: Kuppel, Rand, Schlitz, Klöppel
        d.ellipse([m - r * 0.72, m - r * 0.95, m + r * 0.72, m + r * 0.5], fill=farbe)
        d.rectangle([m - r * 0.72, m - r * 0.2, m + r * 0.72, m + r * 0.5], fill=farbe)
        d.rounded_rectangle([m - r * 0.86, m + r * 0.3, m + r * 0.86, m + r * 0.62], radius=int(r * 0.15), fill=farbe)
        d.ellipse([m - r * 0.2, m + r * 0.48, m + r * 0.2, m + r * 0.95], fill=farbe)
        d.ellipse([m - r * 0.12, m - r * 1.12, m + r * 0.12, m - r * 0.86], fill=farbe)
        d.line([(m - r * 0.55, m + r * 0.1), (m + r * 0.55, m + r * 0.1)], fill=(120, 80, 10, 255), width=max(2, int(S * 0.025)))
    elif art == "laub":
        # Blatt: zwei Bögen, Spitze oben, Stiel unten
        pts = []
        for i in range(0, 101):
            t = i / 100.0
            y = m + r * 0.85 - t * r * 1.9
            w = math.sin(t * math.pi) ** 0.8 * r * 0.7 * (1.0 + 0.12 * math.sin(t * math.pi * 6))
            pts.append((m + w, y))
        for i in range(100, -1, -1):
            t = i / 100.0
            y = m + r * 0.85 - t * r * 1.9
            w = math.sin(t * math.pi) ** 0.8 * r * 0.7 * (1.0 + 0.12 * math.sin(t * math.pi * 6))
            pts.append((m - w, y))
        d.polygon(pts, fill=farbe)
        d.line([(m, m + r * 1.0), (m, m - r * 0.95)], fill=(20, 70, 30, 255), width=max(2, int(S * 0.03)))
    elif art == "eichel":
        d.ellipse([m - r * 0.52, m - r * 0.35, m + r * 0.52, m + r * 1.0], fill=(204, 150, 80, 255))
        d.pieslice([m - r * 0.52, m - r * 0.35, m + r * 0.52, m + r * 1.0], 20, 160, fill=(204, 150, 80, 255))
        d.pieslice([m - r * 0.78, m - r * 0.95, m + r * 0.78, m + r * 0.18], 180, 360, fill=farbe)
        d.rounded_rectangle([m - r * 0.78, m - r * 0.30, m + r * 0.78, m + r * 0.18], radius=int(r * 0.12), fill=farbe)
        d.rectangle([m - r * 0.06, m - r * 1.15, m + r * 0.06, m - r * 0.8], fill=(90, 56, 28, 255))
        for k in range(-3, 4):
            d.line([(m + k * r * 0.2, m - r * 0.28), (m + k * r * 0.16, m - r * 0.7)], fill=(30, 80, 40, 255), width=max(1, int(S * 0.012)))
    if glanz:
        gl = verlauf_senkrecht(S, S, (255, 255, 255, 70), (255, 255, 255, 0))
        gl.putalpha(ImageChops.multiply(gl.getchannel("A"), im.getchannel("A")))
        im.alpha_composite(gl)
    return im


FARBEN_FRANZ = {"herz": ROT, "karo": ROT, "pik": SCHWARZ, "kreuz": SCHWARZ}
FARBEN_BAYER = {"herz": ROT, "schellen": (222, 160, 20), "eichel": (46, 120, 56), "laub": (40, 140, 60)}

PIPS = {
    2: [(0, -1), (0, 1)],
    3: [(0, -1), (0, 0), (0, 1)],
    4: [(-.55, -1), (.55, -1), (-.55, 1), (.55, 1)],
    5: [(-.55, -1), (.55, -1), (0, 0), (-.55, 1), (.55, 1)],
    6: [(-.55, -1), (.55, -1), (-.55, 0), (.55, 0), (-.55, 1), (.55, 1)],
    7: [(-.55, -1), (.55, -1), (0, -.5), (-.55, 0), (.55, 0), (-.55, 1), (.55, 1)],
    8: [(-.55, -1), (.55, -1), (0, -.5), (-.55, 0), (.55, 0), (0, .5), (-.55, 1), (.55, 1)],
    9: [(-.55, -1), (.55, -1), (-.55, -.33), (.55, -.33), (0, 0), (-.55, .33), (.55, .33), (-.55, 1), (.55, 1)],
    10: [(-.55, -1), (.55, -1), (0, -.66), (-.55, -.33), (.55, -.33), (-.55, .33), (.55, .33), (0, .66), (-.55, 1), (.55, 1)],
}


def kartengrund(farbton=(252, 250, 244)):
    k = verlauf_senkrecht(B, H, (255, 255, 252), farbton)
    m = maske_abgerundet(B, H, int(18 * SS))
    k.putalpha(m)
    d = ImageDraw.Draw(k)
    # feiner Rand und weiche Innenkante
    d.rounded_rectangle([0, 0, B - 1, H - 1], radius=int(18 * SS), outline=(120, 112, 100, 255), width=int(1.6 * SS))
    d.rounded_rectangle([int(3 * SS), int(3 * SS), B - 1 - int(3 * SS), H - 1 - int(3 * SS)], radius=int(15 * SS), outline=(225, 218, 205, 255), width=int(1 * SS))
    return k


def eckzeichen(k, rang_text, art, farbe, schrift, groesse_symbol):
    """Rang und kleines Farbzeichen oben links, gedreht unten rechts"""
    ecke = leer(int(52 * SS), int(96 * SS))
    d = ImageDraw.Draw(ecke)
    text_mittig(d, (ecke.width / 2, 24 * SS), rang_text, schrift, farbe)
    s = symbol_bild(art, int(groesse_symbol * SS), farbe, glanz=False)
    ecke.alpha_composite(s, (int((ecke.width - s.width) / 2), int(50 * SS)))
    k.alpha_composite(ecke, (int(5 * SS), int(6 * SS)))
    k.alpha_composite(ecke.rotate(180), (B - ecke.width - int(5 * SS), H - ecke.height - int(6 * SS)))


def franz_karte(art, rang):
    farbe = FARBEN_FRANZ[art]
    k = kartengrund()
    namen = {1: "A", 11: "B", 12: "D", 13: "K"}
    text = namen.get(rang, str(rang))
    sch = font(FONT_ZAHL if rang < 11 else FONT_FRAKTUR, (44 if rang < 11 else 50) * SS)
    if rang == 10:
        sch = font(FONT_ZAHL, 40 * SS)
    eckzeichen(k, text, art, farbe, sch, 30)
    d = ImageDraw.Draw(k)
    # Feld in der Mitte
    fx0, fx1 = int(60 * SS), int(B - 60 * SS)
    fy0, fy1 = int(34 * SS), int(H - 34 * SS)
    if rang == 1:
        s = symbol_bild(art, int(140 * SS), farbe)
        k.alpha_composite(s, (int((B - s.width) / 2), int((H - s.height) / 2)))
    elif rang <= 10:
        g = int(44 * SS)
        s = symbol_bild(art, g, farbe)
        sr = s.rotate(180)
        cx, cy = B / 2, H / 2
        bx = (fx1 - fx0) / 2 - g * 0.5
        by = (fy1 - fy0) / 2 - g * 0.5
        for (px, py) in PIPS[rang]:
            x = cx + px * bx - g / 2
            y = cy + py * by - g / 2
            k.alpha_composite(sr if py > 0 else s, (int(x), int(y)))
    else:
        # Bildkarte: Rahmenfeld, großer Fraktur-Buchstabe, Zeichen oben und unten (gedreht)
        tint = {11: (236, 240, 252), 12: (252, 236, 240), 13: (250, 244, 224)}[rang]
        d.rounded_rectangle([fx0, fy0, fx1, fy1], radius=int(10 * SS), fill=tint + (255,), outline=GOLD + (255,), width=int(3 * SS))
        d.rounded_rectangle([fx0 + 7 * SS, fy0 + 7 * SS, fx1 - 7 * SS, fy1 - 7 * SS], radius=int(6 * SS), outline=(farbe[0], farbe[1], farbe[2], 255), width=int(1.4 * SS))
        gross = font(FONT_FRAKTUR, 150 * SS)
        text_mittig(d, (B / 2, H / 2), text, gross, farbe, kontur=(255, 255, 255), kontur_breite=int(2 * SS))
        s = symbol_bild(art, int(46 * SS), farbe)
        k.alpha_composite(s, (int(B / 2 - s.width / 2), int(fy0 + 14 * SS)))
        k.alpha_composite(s.rotate(180), (int(B / 2 - s.width / 2), int(fy1 - 14 * SS - s.height)))
    return runter(k)


def bayer_karte(art, rang):
    """rang 0..7 = Sieben, Acht, Neun, Zehn, Unter, Ober, König, Ass"""
    farbe = FARBEN_BAYER[art]
    k = kartengrund((250, 246, 232))
    namen = ["7", "8", "9", "10", "U", "O", "K", "A"]
    sch = font(FONT_ZAHL if rang < 4 else FONT_FRAKTUR, (42 if rang < 4 else 50) * SS)
    if rang == 3:
        sch = font(FONT_ZAHL, 38 * SS)
    ecktext = namen[rang]
    ecke_farbe = farbe if art != "schellen" else (200, 120, 10)
    eckzeichen(k, ecktext, art, ecke_farbe, sch, 30)
    d = ImageDraw.Draw(k)
    fx0, fx1 = int(60 * SS), int(B - 60 * SS)
    fy0, fy1 = int(34 * SS), int(H - 34 * SS)
    if rang == 7:
        s = symbol_bild(art, int(150 * SS), farbe)
        k.alpha_composite(s, (int((B - s.width) / 2), int((H - s.height) / 2)))
    elif rang < 4:
        anzahl = [7, 8, 9, 10][rang]
        g = int(44 * SS)
        s = symbol_bild(art, g, farbe)
        sr = s.rotate(180)
        cx, cy = B / 2, H / 2
        bx = (fx1 - fx0) / 2 - g * 0.5
        by = (fy1 - fy0) / 2 - g * 0.5
        for (px, py) in PIPS[anzahl]:
            k.alpha_composite(sr if py > 0 else s, (int(cx + px * bx - g / 2), int(cy + py * by - g / 2)))
    else:
        tint = [(236, 244, 236), (244, 236, 236), (250, 244, 224)][rang - 4]
        d.rounded_rectangle([fx0, fy0, fx1, fy1], radius=int(10 * SS), fill=tint + (255,), outline=GOLD + (255,), width=int(3 * SS))
        d.rounded_rectangle([fx0 + 7 * SS, fy0 + 7 * SS, fx1 - 7 * SS, fy1 - 7 * SS], radius=int(6 * SS), outline=farbe + (255,), width=int(1.4 * SS))
        gross = font(FONT_FRAKTUR, 150 * SS)
        text_mittig(d, (B / 2, H / 2), namen[rang], gross, ecke_farbe, kontur=(255, 255, 255), kontur_breite=int(2 * SS))
        s = symbol_bild(art, int(46 * SS), farbe)
        k.alpha_composite(s, (int(B / 2 - s.width / 2), int(fy0 + 14 * SS)))
        k.alpha_composite(s.rotate(180), (int(B / 2 - s.width / 2), int(fy1 - 14 * SS - s.height)))
    return runter(k)


def ruecken():
    k = verlauf_senkrecht(B, H, (28, 70, 150), (14, 40, 100))
    d = ImageDraw.Draw(k)
    # Bayerische Raute: weiß-blaues Rautenmuster (Rauten stoßen Kante an Kante)
    r = 30 * SS
    for j in range(-2, int(H / r) + 3):
        for i in range(-2, int(B / r) + 3):
            if (i + j) % 2 != 0:
                continue
            cx, cy = i * r, j * r
            weiss = i % 2 == 0
            d.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], fill=(244, 246, 252, 255) if weiss else (36, 86, 176, 255))
    # Mittelmedaillon und Goldrahmen
    d.ellipse([B / 2 - 62 * SS, H / 2 - 62 * SS, B / 2 + 62 * SS, H / 2 + 62 * SS], fill=(14, 40, 100, 255), outline=GOLD + (255,), width=int(5 * SS))
    d.ellipse([B / 2 - 48 * SS, H / 2 - 48 * SS, B / 2 + 48 * SS, H / 2 + 48 * SS], outline=GOLD + (255,), width=int(2 * SS))
    text_mittig(d, (B / 2, H / 2), "S", font(FONT_FRAKTUR, 96 * SS), GOLD)
    k.putalpha(maske_abgerundet(B, H, int(18 * SS)))
    d = ImageDraw.Draw(k)
    d.rounded_rectangle([0, 0, B - 1, H - 1], radius=int(18 * SS), outline=(240, 200, 100, 255), width=int(5 * SS))
    d.rounded_rectangle([int(11 * SS), int(11 * SS), B - 1 - int(11 * SS), H - 1 - int(11 * SS)], radius=int(12 * SS), outline=(240, 200, 100, 200), width=int(2 * SS))
    return runter(k)


if __name__ == "__main__":
    namen_rang = {1: "ass", 11: "bube", 12: "dame", 13: "koenig"}
    for art in ("herz", "karo", "pik", "kreuz"):
        for rang in range(1, 14):
            speichern(franz_karte(art, rang), "karte_%s_%s.png" % (art, namen_rang.get(rang, str(rang))))
    bayer_namen = ["7", "8", "9", "10", "unter", "ober", "koenig", "ass"]
    for art in ("herz", "schellen", "eichel", "laub"):
        for rang in range(8):
            speichern(bayer_karte(art, rang), "bkarte_%s_%s.png" % (art, bayer_namen[rang]))
    speichern(ruecken(), "karte_ruecken.png")
    # Vorschaubogen
    bogen = Image.new("RGBA", (KB * 7 + 60, KH * 3 + 40), (30, 90, 56, 255))
    proben = [franz_karte("herz", 1), franz_karte("pik", 12), franz_karte("karo", 10), franz_karte("kreuz", 7), franz_karte("herz", 13),
              franz_karte("pik", 11), ruecken(), bayer_karte("herz", 7), bayer_karte("eichel", 4), bayer_karte("schellen", 3),
              bayer_karte("laub", 5), bayer_karte("herz", 6), bayer_karte("schellen", 0), bayer_karte("eichel", 2), franz_karte("karo", 8),
              franz_karte("herz", 5), franz_karte("kreuz", 9), franz_karte("pik", 1), bayer_karte("laub", 7), bayer_karte("eichel", 7), bayer_karte("schellen", 7)]
    for i, p in enumerate(proben):
        bogen.alpha_composite(p, (10 + (i % 7) * (KB + 6), 10 + (i // 7) * (KH + 8)))
    bogen.convert("RGB").save(os.path.join(ROOT, "build", "karten_vorschau.png"))
    print("fertig")
