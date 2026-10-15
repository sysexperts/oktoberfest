"""Roulette-Kessel von oben (europäisch, 37 Fächer) als Bild, das sich im Spiel dreht. Fach 0 liegt oben (Mittelpunkt bei -90°),
die Reihenfolge der Zahlen steht in REIHENFOLGE (auch in scripts/ui/casino_roulette.gd). Ergebnis: assets/casino/roulette_rad.png (1024 x 1024).
Aufruf: python -X utf8 tools/casino_grafik/rad.py"""
import sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from gemeinsam import *

REIHENFOLGE = [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26]
ROT = {1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36}
G = 1024
S = G * SS
M = S / 2


def ring_polygon(r_innen, r_aussen, w0, w1, schritte=24):
    pts = []
    for i in range(schritte + 1):
        w = math.radians(w0 + (w1 - w0) * i / schritte)
        pts.append((M + r_aussen * math.cos(w), M + r_aussen * math.sin(w)))
    for i in range(schritte, -1, -1):
        w = math.radians(w0 + (w1 - w0) * i / schritte)
        pts.append((M + r_innen * math.cos(w), M + r_innen * math.sin(w)))
    return pts


def kreis(d, r, fuell=None, rand=None, breite=1):
    d.ellipse([M - r, M - r, M + r, M + r], fill=fuell, outline=rand, width=breite)


def bauen():
    R = S * 0.5
    im = leer(S, S)
    # Außenrand aus Holz: radialer Verlauf, dazu Maserung als feine Ringe
    holz = verlauf_radial(S, S, (122, 70, 34), (58, 30, 14), mitte=(0.5, 0.5), radius=0.55)
    ring_maske = maske_kreis(S, S)
    holz.putalpha(ring_maske)
    im.alpha_composite(holz)
    d = ImageDraw.Draw(im)
    for k in range(6):
        rr = R * (0.99 - k * 0.02)
        kreis(d, rr, rand=(30, 14, 6, 110), breite=int(1.5 * SS))
    kreis(d, R * 0.935, rand=(236, 190, 90, 255), breite=int(4 * SS))
    # Kugelbahn: gebürstetes Metall, dunkel
    bahn = verlauf_radial(S, S, (120, 124, 136), (46, 48, 58), mitte=(0.35, 0.3), radius=0.9)
    bm = Image.new("L", (S, S), 0)
    bd = ImageDraw.Draw(bm)
    bd.ellipse([M - R * 0.925, M - R * 0.925, M + R * 0.925, M + R * 0.925], fill=255)
    bd.ellipse([M - R * 0.80, M - R * 0.80, M + R * 0.80, M + R * 0.80], fill=0)
    bahn.putalpha(bm)
    im.alpha_composite(bahn)
    d = ImageDraw.Draw(im)
    kreis(d, R * 0.80, rand=(236, 190, 90, 255), breite=int(5 * SS))
    # Fächer
    dw = 360.0 / 37.0
    for i, zahl in enumerate(REIHENFOLGE):
        w0 = -90 - dw / 2 + i * dw
        w1 = w0 + dw
        farbe = (24, 120, 60) if zahl == 0 else ((196, 28, 40) if zahl in ROT else (24, 24, 30))
        d.polygon(ring_polygon(R * 0.545, R * 0.795, w0, w1), fill=farbe + (255,))
        # dunkler Fachboden innen (Tiefe)
        d.polygon(ring_polygon(R * 0.545, R * 0.62, w0, w1), fill=tuple(int(c * 0.62) for c in farbe) + (255,))
    # Fachtrenner (Goldstege)
    for i in range(37):
        w = math.radians(-90 - dw / 2 + i * dw)
        d.line([(M + R * 0.545 * math.cos(w), M + R * 0.545 * math.sin(w)), (M + R * 0.795 * math.cos(w), M + R * 0.795 * math.sin(w))],
               fill=(232, 188, 84, 255), width=int(2.4 * SS))
    kreis(d, R * 0.545, rand=(232, 188, 84, 255), breite=int(4 * SS))
    # Zahlen, radial ausgerichtet
    schr = font(FONT_FETT, 38 * SS)
    for i, zahl in enumerate(REIHENFOLGE):
        w = -90 + i * dw
        feld = leer(int(80 * SS), int(60 * SS))
        fd = ImageDraw.Draw(feld)
        text_mittig(fd, (feld.width / 2, feld.height / 2), str(zahl), schr, (250, 250, 250, 255))
        feld = feld.rotate(-(w + 90), expand=True, resample=Image.BICUBIC)
        px = M + R * 0.725 * math.cos(math.radians(w)) - feld.width / 2
        py = M + R * 0.725 * math.sin(math.radians(w)) - feld.height / 2
        im.alpha_composite(feld, (int(px), int(py)))
    # Innenkegel: dunkles Holz mit Goldringen und Speichen
    kegel = verlauf_radial(S, S, (150, 92, 44), (52, 26, 12), mitte=(0.42, 0.38), radius=0.34)
    km = Image.new("L", (S, S), 0)
    ImageDraw.Draw(km).ellipse([M - R * 0.535, M - R * 0.535, M + R * 0.535, M + R * 0.535], fill=255)
    kegel.putalpha(km)
    im.alpha_composite(kegel)
    d = ImageDraw.Draw(im)
    for rr, br in ((0.48, 3), (0.34, 3), (0.20, 2)):
        kreis(d, R * rr, rand=(232, 188, 84, 200), breite=int(br * SS))
    for k in range(8):
        w = math.radians(k * 45 + 22.5)
        d.line([(M + R * 0.16 * math.cos(w), M + R * 0.16 * math.sin(w)), (M + R * 0.52 * math.cos(w), M + R * 0.52 * math.sin(w))],
               fill=(232, 188, 84, 235), width=int(7 * SS))
        d.line([(M + R * 0.16 * math.cos(w), M + R * 0.16 * math.sin(w)), (M + R * 0.52 * math.cos(w), M + R * 0.52 * math.sin(w))],
               fill=(255, 238, 170, 255), width=int(2.5 * SS))
    # Mittelstück (goldener Knauf)
    knauf = verlauf_radial(S, S, (255, 240, 170, 255), (170, 118, 30, 255), mitte=(0.46, 0.44), radius=0.12)
    kn = Image.new("L", (S, S), 0)
    ImageDraw.Draw(kn).ellipse([M - R * 0.10, M - R * 0.10, M + R * 0.10, M + R * 0.10], fill=255)
    knauf.putalpha(kn)
    im.alpha_composite(knauf)
    kreis(ImageDraw.Draw(im), R * 0.10, rand=(120, 80, 20, 255), breite=int(2 * SS))
    # Glanzlicht quer über den Kessel (nur Oberfläche, sehr dezent)
    gl = verlauf_radial(S, S, (255, 255, 255, 46), (255, 255, 255, 0), mitte=(0.3, 0.25), radius=0.5)
    gl.putalpha(ImageChops.multiply(gl.getchannel("A"), maske_kreis(S, S)))
    im.alpha_composite(gl)
    return runter(im)


if __name__ == "__main__":
    rad = bauen()
    speichern(rad, "roulette_rad.png")
    vorschau = Image.new("RGBA", (G + 40, G + 40), (24, 80, 50, 255))
    vorschau.alpha_composite(schatten(rad, (0, 14), 20), (-20, -10)) if False else vorschau.alpha_composite(rad, (20, 20))
    vorschau.convert("RGB").resize((800, 800), Image.LANCZOS).save(os.path.join(ROOT, "build", "rad_vorschau.png"))
    print("fertig")
