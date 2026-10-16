"""Aufdrucke für die runden Casino-Tische im Raum (liegen als durchsichtige Platte auf dem Tuch).
Ergebnis: assets/casino/tisch_blackjack.png, tisch_wuerfel.png, tisch_watten.png (je 1024 x 1024; oben = Croupier, unten = Spieler).
Aufruf: python -X utf8 tools/casino_grafik/tische.py"""
import sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from gemeinsam import *

G = 1024
S = G * SS
M = S / 2
GOLD = (236, 190, 84, 235)
GOLD_H = (255, 232, 150, 245)


def bogentext(im, mitte, radius, text, schrift, farbe, winkel_mitte, spreizung=None, nach_innen=False):
    """Text auf einem Kreisbogen: winkel_mitte in Grad (-90 = oben), Buchstaben stehen mit den Köpfen nach außen"""
    d = ImageDraw.Draw(im)
    breiten = [d.textlength(c, font=schrift) for c in text]
    gesamt = sum(breiten)
    gradmass = math.degrees(gesamt / radius)
    w = winkel_mitte - gradmass / 2 if not nach_innen else winkel_mitte + gradmass / 2
    for c, b in zip(text, breiten):
        halb = math.degrees(b / 2 / radius)
        a = w + halb if not nach_innen else w - halb
        feld = leer(int(b + 80 * SS), int(schrift.size * 1.8))
        fd = ImageDraw.Draw(feld)
        fd.text((feld.width / 2, feld.height / 2), c, font=schrift, fill=farbe, anchor="mm")
        drehung = -(a + 90) if not nach_innen else -(a - 90)
        feld = feld.rotate(drehung, resample=Image.BICUBIC, expand=True)
        px = mitte[0] + radius * math.cos(math.radians(a)) - feld.width / 2
        py = mitte[1] + radius * math.sin(math.radians(a)) - feld.height / 2
        im.alpha_composite(feld, (int(px), int(py)))
        w += (halb * 2) if not nach_innen else -(halb * 2)


def kreis(d, r, farbe, breite, mitte=(M, M)):
    d.ellipse([mitte[0] - r, mitte[1] - r, mitte[0] + r, mitte[1] + r], outline=farbe, width=int(breite))


def raute(d, x, y, r, farbe, rand=None):
    d.polygon([(x, y - r), (x + r, y), (x, y + r), (x - r, y)], fill=farbe, outline=rand)


def speichern_tisch(im, name):
    speichern(runter(im), name)


def blackjack():
    im = leer(S, S)
    d = ImageDraw.Draw(im)
    kreis(d, 470 * SS, GOLD, 3 * SS)
    kreis(d, 458 * SS, (236, 190, 84, 120), 1.5 * SS)
    bogentext(im, (M, M), 392 * SS, "BLACKJACK ZAHLT 3 ZU 2", font(FONT_FRAKTUR, 62 * SS), GOLD_H, -90)
    bogentext(im, (M, M), 330 * SS, "DIE BANK ZIEHT BIS 17", font(FONT_FETT, 30 * SS), (236, 190, 84, 200), -90)
    # drei Einsatzfelder vor den Spielern (unten)
    for i, w in enumerate((60, 90, 120)):
        a = math.radians(w)
        x, y = M + 330 * SS * math.cos(a), M + 330 * SS * math.sin(a)
        kreis(d, 62 * SS, GOLD, 3 * SS, (x, y))
        raute(d, x, y, 26 * SS, (236, 190, 84, 140))
    # Kartenzonen: Bank oben, Spieler unten
    d.rounded_rectangle([M - 170 * SS, M - 230 * SS, M + 170 * SS, M - 90 * SS], radius=18 * SS, outline=(236, 190, 84, 120), width=2 * SS)
    d.rounded_rectangle([M - 170 * SS, M + 10 * SS, M + 170 * SS, M + 150 * SS], radius=18 * SS, outline=(236, 190, 84, 120), width=2 * SS)
    return im


def wuerfel():
    im = leer(S, S)
    d = ImageDraw.Draw(im)
    kreis(d, 470 * SS, GOLD, 3 * SS)
    kreis(d, 458 * SS, (236, 190, 84, 120), 1.5 * SS)
    bogentext(im, (M, M), 392 * SS, "WÜRFELBECHER", font(FONT_FRAKTUR, 70 * SS), GOLD_H, -90)
    # Wurfzone in der Mitte
    for k in range(36):
        a0 = math.radians(k * 10)
        a1 = math.radians(k * 10 + 6)
        r = 190 * SS
        d.line([(M + r * math.cos(a0), M + r * math.sin(a0)), (M + r * math.cos(a1), M + r * math.sin(a1))], fill=GOLD, width=int(3 * SS))
    text_mittig(d, (M, M), "WURF", font(FONT_FRAKTUR, 80 * SS), (236, 190, 84, 110))
    # vier Wettfelder auf dem unteren Bogen
    namen = [("TIEF", "1 : 1"), ("SIEBEN", "4 : 1"), ("HOCH", "1 : 1"), ("PASCH", "4 : 1")]
    for i, (n, q) in enumerate(namen):
        w = 140 - i * 33.3
        a = math.radians(w)
        x, y = M + 345 * SS * math.cos(a), M + 345 * SS * math.sin(a)
        feld = leer(int(190 * SS), int(120 * SS))
        fd = ImageDraw.Draw(feld)
        fd.rounded_rectangle([4 * SS, 4 * SS, 186 * SS, 116 * SS], radius=16 * SS, outline=GOLD, width=3 * SS, fill=(0, 0, 0, 40))
        text_mittig(fd, (95 * SS, 44 * SS), n, font(FONT_SCHWER, 34 * SS), GOLD_H)
        text_mittig(fd, (95 * SS, 86 * SS), q, font(FONT_FETT, 30 * SS), (236, 190, 84, 220))
        feld = feld.rotate(-(w - 90) + 180 if False else -(w - 90), resample=Image.BICUBIC, expand=True)
        im.alpha_composite(feld, (int(x - feld.width / 2), int(y - feld.height / 2)))
    return im


def watten():
    im = leer(S, S)
    d = ImageDraw.Draw(im)
    # Rautenkranz am Rand
    n = 44
    for i in range(n):
        a = math.radians(i * 360 / n)
        x, y = M + 452 * SS * math.cos(a), M + 452 * SS * math.sin(a)
        raute(d, x, y, 17 * SS, (60, 120, 220, 230) if i % 2 == 0 else (245, 247, 252, 230))
    kreis(d, 478 * SS, GOLD, 3 * SS)
    kreis(d, 426 * SS, GOLD, 3 * SS)
    bogentext(im, (M, M), 350 * SS, "WATTEN", font(FONT_FRAKTUR, 96 * SS), GOLD_H, -90)
    bogentext(im, (M, M), 270 * SS, "ZWEI STICHE GEWINNEN", font(FONT_FETT, 30 * SS), (236, 190, 84, 200), -90)
    # Stichzone und Handkarten
    for x0, y0, b, h in ((-210, -60, 190, 130), (20, -60, 190, 130)):
        d.rounded_rectangle([M + x0 * SS, M + y0 * SS, M + (x0 + b) * SS, M + (y0 + h) * SS], radius=14 * SS, outline=(236, 190, 84, 130), width=2 * SS)
    raute(d, M, M + 260 * SS, 60 * SS, (60, 120, 220, 120))
    raute(d, M, M + 260 * SS, 36 * SS, (245, 247, 252, 120))
    return im


if __name__ == "__main__":
    bogen = Image.new("RGBA", (3 * 540 + 20, 560), (24, 100, 60, 255))
    for i, (name, f) in enumerate((("blackjack", blackjack), ("wuerfel", wuerfel), ("watten", watten))):
        b = runter(f())
        speichern(b, "tisch_%s.png" % name)
        bogen.alpha_composite(b.resize((520, 520), Image.LANCZOS), (10 + i * 540, 20))
    bogen.convert("RGB").save(os.path.join(ROOT, "build", "tische_vorschau.png"))
    print("fertig")
