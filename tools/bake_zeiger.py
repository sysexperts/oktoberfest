# Zeichnet die Spiel-Mauszeiger (assets/ui/zeiger/*.png): Pfeil und Hand, nachtblau mit goldenem Rand
# wie der Desktop. Aufruf: python tools/bake_zeiger.py
from PIL import Image, ImageDraw, ImageFilter

S = 8          # Überabtastung
G = 32         # Zielgröße in Pixeln
NACHT = (24, 36, 74, 255)
GOLD = (255, 214, 89, 255)
SCHATTEN = (0, 0, 0, 110)


def leinwand():
    return Image.new("RGBA", (G * S, G * S), (0, 0, 0, 0))


def skaliert(pts):
    return [(x * S, y * S) for x, y in pts]


def fertig(bild, schatten_form):
    # weicher Schatten unten rechts, dann Bild darüber
    sch = Image.new("RGBA", bild.size, (0, 0, 0, 0))
    sch.paste(SCHATTEN, (int(1.0 * S), int(1.2 * S)), schatten_form)
    sch = sch.filter(ImageFilter.GaussianBlur(S * 0.9))
    sch.alpha_composite(bild)
    return sch.resize((G, G), Image.LANCZOS)


def pfeil():
    pts = [(3, 2), (3, 22.5), (8.2, 17.8), (11.6, 25.6), (15.2, 24.1), (11.8, 16.4), (18.6, 16.4)]
    form = Image.new("L", (G * S, G * S), 0)
    ImageDraw.Draw(form).polygon(skaliert(pts), fill=255)
    bild = leinwand()
    d = ImageDraw.Draw(bild)
    d.polygon(skaliert(pts), fill=NACHT)
    d.line(skaliert(pts + [pts[0]]), fill=GOLD, width=int(1.7 * S), joint="curve")
    # Glanzkante innen
    d.line(skaliert([(5.0, 6.5), (5.0, 17.5)]), fill=(120, 150, 230, 200), width=int(0.9 * S))
    return fertig(bild, form)


def hand():
    # Zeigefinger nach oben, Faust darunter
    finger = (11.0, 2.0, 15.4, 15.0)
    faust = (7.0, 12.5, 24.0, 26.5)
    form = Image.new("L", (G * S, G * S), 0)
    fd = ImageDraw.Draw(form)
    fd.rounded_rectangle([v * S for v in finger], radius=2.2 * S, fill=255)
    fd.rounded_rectangle([v * S for v in faust], radius=4.0 * S, fill=255)
    bild = leinwand()
    d = ImageDraw.Draw(bild)
    # Gold als Rand: erst etwas größer in Gold, dann Nachtblau darüber
    r = 1.4 * S
    d.rounded_rectangle([finger[0] * S - r, finger[1] * S - r, finger[2] * S + r, finger[3] * S + r], radius=2.2 * S + r, fill=GOLD)
    d.rounded_rectangle([faust[0] * S - r, faust[1] * S - r, faust[2] * S + r, faust[3] * S + r], radius=4.0 * S + r, fill=GOLD)
    d.rounded_rectangle([v * S for v in finger], radius=2.2 * S, fill=NACHT)
    d.rounded_rectangle([v * S for v in faust], radius=4.0 * S, fill=NACHT)
    # Fingerlinien
    for x in (11.6, 15.2, 18.8):
        d.line([(x * S, 17.5 * S), (x * S, 23.5 * S)], fill=(120, 150, 230, 170), width=int(0.8 * S))
    return fertig(bild, form)


if __name__ == "__main__":
    pfeil().save("assets/ui/zeiger/pfeil.png")
    hand().save("assets/ui/zeiger/hand.png")
    # Vergrößerte Vorschau
    vor = Image.new("RGBA", (G * 8 * 2 + 30, G * 8 + 20), (200, 200, 205, 255))
    vor.alpha_composite(pfeil().resize((G * 8, G * 8), Image.NEAREST), (10, 10))
    vor.alpha_composite(hand().resize((G * 8, G * 8), Image.NEAREST), (G * 8 + 20, 10))
    vor.save("build/zeiger_vorschau.png")
