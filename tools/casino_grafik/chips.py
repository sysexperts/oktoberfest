"""Casino-Chips (Werte 10, 50, 100, 500, 1000) von oben, mit Randstreifen, Zierring und Wert; dazu Chip-Stapel und die Glückskugel.
Ergebnis: assets/casino/chip_<wert>.png (160 x 160, mit Schatten). Aufruf: python -X utf8 tools/casino_grafik/chips.py"""
import sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from gemeinsam import *

G = 160
S = G * SS
WERTE = {
    10: ((236, 236, 240), (150, 152, 166), (40, 44, 60)),
    50: ((214, 48, 52), (122, 20, 28), (255, 255, 255)),
    100: ((46, 150, 78), (18, 84, 44), (255, 255, 255)),
    500: ((52, 96, 200), (22, 46, 120), (255, 255, 255)),
    1000: ((36, 36, 44), (10, 10, 14), (240, 200, 90)),
}


def chip(wert, mit_schatten=True):
    haupt, dunkel, text = WERTE[wert]
    im = leer(S, S)
    d = ImageDraw.Draw(im)
    m = S / 2
    r = S * 0.46
    d.ellipse([m - r, m - r, m + r, m + r], fill=dunkel + (255,))
    # Randstreifen: acht helle Klötze
    for i in range(8):
        a0 = i * 45 - 11
        d.pieslice([m - r, m - r, m + r, m + r], a0, a0 + 22, fill=(250, 250, 250, 255) if wert != 10 else (60, 64, 84, 255))
    r2 = r * 0.86
    d.ellipse([m - r2, m - r2, m + r2, m + r2], fill=haupt + (255,))
    # Innenring
    r3 = r * 0.70
    d.ellipse([m - r3, m - r3, m + r3, m + r3], outline=(250, 250, 250, 220) if wert != 10 else (60, 64, 84, 220), width=int(2.2 * SS))
    r4 = r * 0.62
    d.ellipse([m - r4, m - r4, m + r4, m + r4], fill=dunkel + (60,))
    txt = str(wert) if wert < 1000 else "1K"
    schr = font(FONT_SCHWER, (46 if len(txt) < 4 else 38) * SS)
    text_mittig(d, (m, m), txt, schr, text + (255,), kontur=dunkel + (255,), kontur_breite=int(2 * SS))
    # Glanz
    gl = verlauf_radial(S, S, (255, 255, 255, 110), (255, 255, 255, 0), mitte=(0.35, 0.28), radius=0.55)
    gl.putalpha(ImageChops.multiply(gl.getchannel("A"), im.getchannel("A")))
    im.alpha_composite(gl)
    d = ImageDraw.Draw(im)
    d.ellipse([m - r, m - r, m + r, m + r], outline=(0, 0, 0, 90), width=int(1.5 * SS))
    im = runter(im)
    return schatten(im, (0, 5), 5, staerke=0.6) if mit_schatten else im


def kugel():
    s = 40 * SS
    im = leer(s, s)
    d = ImageDraw.Draw(im)
    d.ellipse([2 * SS, 2 * SS, s - 2 * SS, s - 2 * SS], fill=(236, 236, 240, 255))
    gl = verlauf_radial(s, s, (255, 255, 255, 255), (150, 152, 166, 255), mitte=(0.35, 0.3), radius=0.7)
    gl.putalpha(im.getchannel("A"))
    return schatten(runter(gl), (0, 3), 3, staerke=0.7)


if __name__ == "__main__":
    bogen = Image.new("RGBA", (5 * 200 + 40, 240), (30, 90, 56, 255))
    for i, w in enumerate(WERTE):
        c = chip(w)
        speichern(c, "chip_%d.png" % w)
        bogen.alpha_composite(c, (20 + i * 200, 30))
    speichern(kugel(), "kugel.png")
    bogen.alpha_composite(kugel(), (20, 160))
    bogen.convert("RGB").save(os.path.join(ROOT, "build", "chips_vorschau.png"))
    print("fertig")
