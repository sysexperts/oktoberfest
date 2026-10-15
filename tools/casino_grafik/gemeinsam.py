"""Gemeinsame Zeichenhelfer für die Casino-Grafiken (assets/casino/*.png): alles wird 4x überabgetastet und herunterskaliert,
damit Kanten glatt sind. Aufruf der Teile: python -X utf8 tools/casino_grafik/karten.py  (bzw. chips.py, rad.py, wuerfel.py, symbole.py)."""
import math
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
AUS = os.path.join(ROOT, "assets", "casino")
os.makedirs(AUS, exist_ok=True)
SS = 4   # Überabtastung

FONT_FRAKTUR = os.path.join(ROOT, "assets", "fonts", "UnifrakturCook-Bold.ttf")
FONT_SERIF_FETT = "C:/Windows/Fonts/georgiab.ttf"
FONT_ZAHL = "C:/Windows/Fonts/timesbd.ttf"
FONT_FETT = "C:/Windows/Fonts/arialbd.ttf"
FONT_SCHWER = "C:/Windows/Fonts/ariblk.ttf"


def font(pfad, groesse):
    return ImageFont.truetype(pfad, int(groesse))


def leer(b, h):
    return Image.new("RGBA", (b, h), (0, 0, 0, 0))


def runter(img, faktor=SS):
    return img.resize((img.width // faktor, img.height // faktor), Image.LANCZOS)


def verlauf_senkrecht(b, h, oben, unten):
    """RGBA-Bild mit senkrechtem Farbverlauf (Farben als (r,g,b[,a]) 0..255)"""
    oben = np.array(list(oben) + [255] * (4 - len(oben)), dtype=np.float32)
    unten = np.array(list(unten) + [255] * (4 - len(unten)), dtype=np.float32)
    t = np.linspace(0.0, 1.0, h, dtype=np.float32)[:, None]
    zeile = oben[None, :] * (1 - t) + unten[None, :] * t
    arr = np.repeat(zeile[:, None, :], b, axis=1)
    return Image.fromarray(arr.astype(np.uint8), "RGBA")


def verlauf_radial(b, h, innen, aussen, mitte=(0.5, 0.5), radius=0.75):
    innen = np.array(list(innen) + [255] * (4 - len(innen)), dtype=np.float32)
    aussen = np.array(list(aussen) + [255] * (4 - len(aussen)), dtype=np.float32)
    y, x = np.mgrid[0:h, 0:b].astype(np.float32)
    d = np.sqrt(((x / b) - mitte[0]) ** 2 + ((y / h) - mitte[1]) ** 2) / radius
    t = np.clip(d, 0.0, 1.0)[..., None]
    arr = innen[None, None, :] * (1 - t) + aussen[None, None, :] * t
    return Image.fromarray(arr.astype(np.uint8), "RGBA")


def maske_kreis(b, h, rand=0):
    m = Image.new("L", (b, h), 0)
    ImageDraw.Draw(m).ellipse([rand, rand, b - 1 - rand, h - 1 - rand], fill=255)
    return m


def maske_abgerundet(b, h, radius):
    m = Image.new("L", (b, h), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, b - 1, h - 1], radius=radius, fill=255)
    return m


def maske_kreis_alt(b, h, rand=0):
    m = Image.new("L", (b, h), 0)
    ImageDraw.Draw(m).ellipse([rand, rand, b - 1 - rand, h - 1 - rand], fill=255)
    return m


def schatten(bild, versatz=(0, 10), unschaerfe=14, farbe=(0, 0, 0), staerke=0.55):
    """Weicher Schlagschatten hinter einem RGBA-Bild (gibt größeres Bild mit Rand zurück)"""
    rand = unschaerfe * 3 + max(abs(versatz[0]), abs(versatz[1]))
    b, h = bild.width + rand * 2, bild.height + rand * 2
    s = Image.new("RGBA", (b, h), (0, 0, 0, 0))
    a = bild.getchannel("A").point(lambda v: int(v * staerke))
    s.paste(Image.new("RGBA", bild.size, farbe + (255,)), (rand + versatz[0], rand + versatz[1]), a)
    s = s.filter(ImageFilter.GaussianBlur(unschaerfe))
    s.alpha_composite(bild, (rand, rand))
    return s


def glanzlicht(b, h, radius, hoehe=0.5, staerke=60):
    """Heller Streifen oben (Glasglanz) mit abgerundeter Maske"""
    g = verlauf_senkrecht(b, h, (255, 255, 255, staerke), (255, 255, 255, 0))
    m = Image.new("L", (b, h), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, b - 1, int(h * hoehe)], radius=radius, fill=255)
    g.putalpha(ImageChops.multiply(g.getchannel("A"), m))
    return g


def text_mittig(d, mitte, text, schrift, fuell, kontur=None, kontur_breite=0):
    bb = d.textbbox((0, 0), text, font=schrift)
    x = mitte[0] - (bb[2] - bb[0]) / 2 - bb[0]
    y = mitte[1] - (bb[3] - bb[1]) / 2 - bb[1]
    if kontur is not None and kontur_breite > 0:
        d.text((x, y), text, font=schrift, fill=fuell, stroke_width=kontur_breite, stroke_fill=kontur)
    else:
        d.text((x, y), text, font=schrift, fill=fuell)


def speichern(img, name):
    pfad = os.path.join(AUS, name)
    img.save(pfad)
    return pfad
