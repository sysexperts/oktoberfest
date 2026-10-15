"""Würfelbecher aus braunem Leder mit Goldrand, von schräg oben. Ergebnis: assets/casino/wuerfel_becher.png (300 x 340).
Aufruf: python -X utf8 tools/casino_grafik/becher.py"""
import sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from gemeinsam import *

B, H = 300, 340
SB, SH = B * SS, H * SS


def p(x, y):
    return (x * SS, y * SS)


def bauen():
    im = leer(SB, SH)
    # Körper: unten schmal, oben weit
    form = Image.new("L", (SB, SH), 0)
    ImageDraw.Draw(form).polygon([p(70, 300), p(230, 300), p(262, 74), p(38, 74)], fill=255)
    ImageDraw.Draw(form).ellipse([p(70, 280), p(230, 322)], fill=255)
    leder = verlauf_senkrecht(SB, SH, (150, 92, 48, 255), (84, 46, 20, 255))
    # seitliche Rundung: dunkler an den Rändern
    seite = Image.new("RGBA", (SB, SH), (0, 0, 0, 0))
    sd = ImageDraw.Draw(seite)
    for i in range(60):
        a = int(110 * (1 - i / 60.0) ** 2)
        sd.line([p(38 + i * 0.5, 74), p(70 + i * 0.5, 300)], fill=(0, 0, 0, a), width=SS)
        sd.line([p(262 - i * 0.5, 74), p(230 - i * 0.5, 300)], fill=(0, 0, 0, a), width=SS)
    leder.alpha_composite(seite)
    glanz = Image.new("RGBA", (SB, SH), (0, 0, 0, 0))
    ImageDraw.Draw(glanz).polygon([p(100, 90), p(130, 90), p(120, 290), p(96, 290)], fill=(255, 220, 170, 70))
    leder.alpha_composite(glanz.filter(ImageFilter.GaussianBlur(10 * SS / 4)))
    leder.putalpha(form)
    im.alpha_composite(leder)
    d = ImageDraw.Draw(im)
    # Nähte (gestrichelt)
    for y in range(110, 290, 14):
        t = (y - 74) / 226.0
        xl = 38 + 32 * t
        xr = 262 - 32 * t
        d.line([p(xl + 14, y), p(xl + 14, y + 7)], fill=(236, 200, 140, 200), width=2 * SS)
        d.line([p(xr - 14, y), p(xr - 14, y + 7)], fill=(236, 200, 140, 200), width=2 * SS)
    # Goldband unten
    d.polygon([p(66, 268), p(234, 268), p(238, 288), p(62, 288)], fill=(214, 168, 66, 255))
    d.polygon([p(66, 268), p(234, 268), p(235, 273), p(65, 273)], fill=(255, 232, 140, 255))
    # Mundrand
    d.ellipse([p(30, 40), p(270, 108)], fill=(210, 160, 62, 255))
    d.ellipse([p(38, 46), p(262, 102)], fill=(48, 24, 10, 255))
    d.ellipse([p(52, 56), p(248, 98)], fill=(22, 10, 4, 255))
    d.arc([p(30, 40), p(270, 108)], 190, 350, fill=(255, 240, 160, 255), width=3 * SS)
    return schatten(runter(im), (0, 8), 8, staerke=0.5)


if __name__ == "__main__":
    b = bauen()
    speichern(b, "wuerfel_becher.png")
    v = Image.new("RGBA", (b.width + 40, b.height + 40), (24, 100, 60, 255))
    v.alpha_composite(b, (20, 20))
    v.convert("RGB").save(os.path.join(ROOT, "build", "becher_vorschau.png"))
    print("fertig", b.size)
