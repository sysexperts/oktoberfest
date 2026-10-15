"""Würfel: sechs Seiten (Elfenbein, Augen schwarz, die Eins und die Vier rot) mit Rundung, Abkantung und Schatten.
Ergebnis: assets/casino/wuerfel_1..6.png (176 x 176). Aufruf: python -X utf8 tools/casino_grafik/wuerfel.py"""
import sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from gemeinsam import *

G = 176
S = G * SS
AUGEN = {
    1: [(0, 0)], 2: [(-1, -1), (1, 1)], 3: [(-1, -1), (0, 0), (1, 1)], 4: [(-1, -1), (1, -1), (-1, 1), (1, 1)],
    5: [(-1, -1), (1, -1), (0, 0), (-1, 1), (1, 1)], 6: [(-1, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (1, 1)],
}


def wuerfel(zahl):
    rand = 14 * SS
    ks = S - rand * 2
    k = verlauf_senkrecht(ks, ks, (255, 252, 240), (226, 218, 196))
    m = maske_abgerundet(ks, ks, int(ks * 0.18))
    k.putalpha(m)
    d = ImageDraw.Draw(k)
    # Abkantung: heller Rand oben links, dunkler unten rechts
    d.rounded_rectangle([0, 0, ks - 1, ks - 1], radius=int(ks * 0.18), outline=(120, 110, 90, 255), width=int(2.4 * SS))
    d.rounded_rectangle([int(5 * SS), int(5 * SS), ks - 1 - int(5 * SS), ks - 1 - int(5 * SS)], radius=int(ks * 0.15), outline=(255, 255, 255, 190), width=int(3 * SS))
    farbe = (190, 24, 36, 255) if zahl in (1, 4) else (26, 26, 32, 255)
    r = ks * (0.105 if zahl != 1 else 0.14)
    a = ks * 0.26
    for (px, py) in AUGEN[zahl]:
        cx = ks / 2 + px * a
        cy = ks / 2 + py * a
        # Vertiefung (Innenschatten), dann Auge
        d.ellipse([cx - r * 1.15, cy - r * 1.15, cx + r * 1.15, cy + r * 1.15], fill=(150, 140, 120, 255))
        d.ellipse([cx - r, cy - r + r * 0.12, cx + r, cy + r + r * 0.12], fill=farbe)
        d.ellipse([cx - r * 0.45, cy - r * 0.62, cx + r * 0.05, cy - r * 0.25], fill=(255, 255, 255, 120))
    gl = glanzlicht(ks, ks, int(ks * 0.18), 0.45, 55)
    k.alpha_composite(gl)
    img = leer(S, S)
    img.alpha_composite(k, (rand, rand))
    return schatten(runter(img), (0, 6), 6, staerke=0.55)


if __name__ == "__main__":
    bogen = Image.new("RGBA", (6 * 230 + 20, 260), (24, 100, 60, 255))
    for z in range(1, 7):
        w = wuerfel(z)
        speichern(w, "wuerfel_%d.png" % z)
        bogen.alpha_composite(w, (20 + (z - 1) * 230, 20))
    bogen.convert("RGB").save(os.path.join(ROOT, "build", "wuerfel_vorschau.png"))
    print("fertig")
