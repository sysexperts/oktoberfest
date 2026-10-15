"""Walzen-Symbole des Spielautomaten im Wiesn-Stil: Maß, Brezn, Hendl, Lebkuchenherz, Edelweiß, Sieben und die Bayern-Raute (Wild).
Ergebnis: assets/casino/slot_<name>.png (192 x 192). Aufruf: python -X utf8 tools/casino_grafik/symbole.py"""
import sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from gemeinsam import *

G = 192
S = G * SS


def punkt(x, y):
    """Koordinaten 0..1 → Pixel"""
    return (x * S, y * S)


def bezier(p0, p1, p2, p3, n=40):
    pts = []
    for i in range(n + 1):
        t = i / n
        a = (1 - t) ** 3
        b = 3 * (1 - t) ** 2 * t
        c = 3 * (1 - t) * t ** 2
        d = t ** 3
        pts.append((a * p0[0] + b * p1[0] + c * p2[0] + d * p3[0], a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1]))
    return pts


def dicke_linie(d, pts, breite, farbe):
    d.line(pts, fill=farbe, width=int(breite), joint="curve")
    r = breite / 2
    for (x, y) in (pts[0], pts[-1]):
        d.ellipse([x - r, y - r, x + r, y + r], fill=farbe)


def mit_verlauf(maske, oben, unten):
    v = verlauf_senkrecht(S, S, oben, unten)
    v.putalpha(maske)
    return v


def maske_von(zeichnen):
    m = Image.new("L", (S, S), 0)
    zeichnen(ImageDraw.Draw(m))
    return m


def fertig(im, umriss=(40, 20, 10), umriss_breite=3.5):
    """Umriss um die Silhouette und weicher Schatten"""
    a = im.getchannel("A")
    rand = a.filter(ImageFilter.MaxFilter(int(umriss_breite * SS) | 1))
    kontur = Image.new("RGBA", im.size, umriss + (255,))
    kontur.putalpha(rand)
    kontur.alpha_composite(im)
    return schatten(runter(kontur), (0, 5), 5, staerke=0.55)


def mass():
    im = leer(S, S)
    # Henkel (rechts)
    h = leer(S, S)
    hd = ImageDraw.Draw(h)
    dicke_linie(hd, bezier(punkt(0.70, 0.30), punkt(0.98, 0.26), punkt(0.98, 0.72), punkt(0.70, 0.70)), 0.10 * S, (214, 226, 236, 255))
    dicke_linie(hd, bezier(punkt(0.70, 0.30), punkt(0.98, 0.26), punkt(0.98, 0.72), punkt(0.70, 0.70)), 0.045 * S, (160, 190, 214, 255))
    im.alpha_composite(h)
    # Glaskörper
    glas = maske_von(lambda d: d.polygon([punkt(0.18, 0.20), punkt(0.72, 0.20), punkt(0.68, 0.88), punkt(0.22, 0.88)], fill=255))
    im.alpha_composite(mit_verlauf(glas, (232, 242, 250, 255), (196, 214, 230, 255)))
    # Bier
    bier = maske_von(lambda d: d.polygon([punkt(0.215, 0.30), punkt(0.685, 0.30), punkt(0.665, 0.84), punkt(0.235, 0.84)], fill=255))
    im.alpha_composite(mit_verlauf(bier, (255, 214, 70, 255), (226, 140, 20, 255)))
    d = ImageDraw.Draw(im)
    # Blasen
    for (x, y, r) in ((0.32, 0.7, 0.015), (0.40, 0.55, 0.012), (0.5, 0.74, 0.016), (0.57, 0.5, 0.011), (0.45, 0.66, 0.01), (0.36, 0.42, 0.012)):
        d.ellipse([punkt(x - r, y - r), punkt(x + r, y + r)], fill=(255, 238, 160, 200))
    # Glanzstreifen
    d.polygon([punkt(0.25, 0.26), punkt(0.31, 0.26), punkt(0.33, 0.82), punkt(0.27, 0.82)], fill=(255, 255, 255, 120))
    # Schaumkrone
    for (x, y, r) in ((0.24, 0.22, 0.085), (0.36, 0.17, 0.10), (0.50, 0.15, 0.105), (0.62, 0.19, 0.095), (0.70, 0.24, 0.07), (0.45, 0.25, 0.08)):
        d.ellipse([punkt(x - r, y - r), punkt(x + r, y + r)], fill=(255, 255, 255, 255))
    for (x, y, r) in ((0.30, 0.15, 0.04), (0.55, 0.11, 0.045)):
        d.ellipse([punkt(x - r, y - r), punkt(x + r, y + r)], fill=(255, 255, 255, 255))
    d.ellipse([punkt(0.20, 0.26), punkt(0.72, 0.34)], fill=(250, 244, 226, 255))
    # Boden
    d.rounded_rectangle([punkt(0.20, 0.84), punkt(0.70, 0.91)], radius=int(0.02 * S), fill=(176, 198, 218, 255))
    return fertig(runter(im, 1), (28, 40, 60))


def brezn():
    im = leer(S, S)
    braun_o, braun_u = (214, 142, 62, 255), (150, 82, 28, 255)
    teig = Image.new("L", (S, S), 0)
    td = ImageDraw.Draw(teig)
    b = 0.115 * S
    # Brezn-Form: großer Bogen unten, zwei gekreuzte Arme, die sich oben zu zwei Lappen einrollen
    unten = bezier(punkt(0.17, 0.30), punkt(0.04, 0.78), punkt(0.40, 0.98), punkt(0.50, 0.80), 60) \
        + bezier(punkt(0.50, 0.80), punkt(0.60, 0.98), punkt(0.96, 0.78), punkt(0.83, 0.30), 60)
    dicke_linie(td, unten, b, 255)
    arm_l = bezier(punkt(0.17, 0.30), punkt(0.22, 0.06), punkt(0.46, 0.08), punkt(0.60, 0.40), 50) + bezier(punkt(0.60, 0.40), punkt(0.66, 0.55), punkt(0.73, 0.62), punkt(0.80, 0.66), 30)
    arm_r = bezier(punkt(0.83, 0.30), punkt(0.78, 0.06), punkt(0.54, 0.08), punkt(0.40, 0.40), 50) + bezier(punkt(0.40, 0.40), punkt(0.34, 0.55), punkt(0.27, 0.62), punkt(0.20, 0.66), 30)
    dicke_linie(td, arm_l, b, 255)
    dicke_linie(td, arm_r, b, 255)
    teig = teig.filter(ImageFilter.GaussianBlur(1.2 * SS))
    teig = teig.point(lambda v: 255 if v > 110 else 0)
    im.alpha_composite(mit_verlauf(teig, braun_o, braun_u))
    # Wölbung: heller Mittelstreifen entlang der Arme
    hell = Image.new("L", (S, S), 0)
    hd = ImageDraw.Draw(hell)
    for pts in (unten, arm_l, arm_r):
        dicke_linie(hd, pts, b * 0.34, 255)
    hell = hell.filter(ImageFilter.GaussianBlur(3 * SS))
    hell = ImageChops.multiply(hell, teig)
    glanz = Image.new("RGBA", (S, S), (255, 226, 160, 255))
    glanz.putalpha(hell.point(lambda v: int(v * 0.55)))
    im.alpha_composite(glanz)
    d = ImageDraw.Draw(im)
    # Salzkörner
    import random
    rnd = random.Random(4)
    for _ in range(26):
        x, y = rnd.uniform(0.18, 0.82), rnd.uniform(0.12, 0.86)
        if teig.getpixel((int(x * S), int(y * S))) > 0:
            r = rnd.uniform(0.007, 0.013)
            d.rectangle([punkt(x - r, y - r * 0.6), punkt(x + r, y + r * 0.6)], fill=(255, 252, 240, 255))
    return fertig(runter(im, 1), (70, 34, 10))


def hendl():
    im = leer(S, S)
    # Knochen
    d = ImageDraw.Draw(im)
    dicke_linie(d, [punkt(0.58, 0.58), punkt(0.86, 0.86)], 0.07 * S, (248, 244, 232, 255))
    for (x, y) in ((0.86, 0.80), (0.92, 0.86)):
        d.ellipse([punkt(x - 0.055, y - 0.055), punkt(x + 0.055, y + 0.055)], fill=(248, 244, 232, 255))
    # Keule: gedrehtes Ei
    keule = Image.new("L", (S, S), 0)
    kd = ImageDraw.Draw(keule)
    kd.ellipse([punkt(0.10, 0.12), punkt(0.70, 0.66)], fill=255)
    kd.ellipse([punkt(0.38, 0.40), punkt(0.70, 0.70)], fill=255)
    keule = keule.rotate(0)
    im.alpha_composite(mit_verlauf(keule, (232, 150, 60, 255), (140, 70, 22, 255)))
    d = ImageDraw.Draw(im)
    # Glanz und Bräunung
    d.ellipse([punkt(0.18, 0.18), punkt(0.46, 0.34)], fill=(255, 220, 150, 150))
    for (x, y, r) in ((0.30, 0.50, 0.02), (0.44, 0.58, 0.016), (0.52, 0.36, 0.018), (0.22, 0.38, 0.014), (0.56, 0.52, 0.02)):
        d.ellipse([punkt(x - r, y - r), punkt(x + r, y + r)], fill=(110, 52, 14, 190))
    # Papiermanschette am Knochen
    d.polygon([punkt(0.56, 0.60), punkt(0.70, 0.66), punkt(0.76, 0.76), punkt(0.62, 0.74)], fill=(250, 246, 240, 255))
    for k in range(5):
        d.line([punkt(0.60 + k * 0.03, 0.62 + k * 0.025), punkt(0.58 + k * 0.034, 0.74 + k * 0.012)], fill=(205, 200, 195, 255), width=int(1.2 * SS))
    return fertig(runter(im, 1), (60, 28, 10))


def herz():
    im = leer(S, S)
    pts = []
    for i in range(0, 361, 2):
        t = math.radians(i)
        x = 16 * math.sin(t) ** 3
        y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((0.5 + x / 38.0, 0.52 + (y + 1.0) / 36.0 * 1.05))
    form = maske_von(lambda d: d.polygon([punkt(*p) for p in pts], fill=255))
    im.alpha_composite(mit_verlauf(form, (150, 82, 40, 255), (92, 44, 18, 255)))
    # Zuckerguss: Rand (weiß) und Schnörkel
    d = ImageDraw.Draw(im)
    innen = [(0.5 + (p[0] - 0.5) * 0.84, 0.52 + (p[1] - 0.52) * 0.84) for p in pts]
    d.line([punkt(*p) for p in innen] + [punkt(*innen[0])], fill=(255, 250, 240, 255), width=int(5.5 * SS), joint="curve")
    # Mittelschnörkel
    dicke_linie(d, bezier(punkt(0.34, 0.42), punkt(0.45, 0.30), punkt(0.55, 0.52), punkt(0.66, 0.40), 30), 4.5 * SS, (255, 250, 240, 255))
    dicke_linie(d, bezier(punkt(0.38, 0.58), punkt(0.46, 0.48), punkt(0.54, 0.66), punkt(0.62, 0.56), 30), 4.0 * SS, (255, 250, 240, 255))
    for (x, y) in ((0.30, 0.34), (0.70, 0.34), (0.5, 0.74)):
        d.ellipse([punkt(x - 0.022, y - 0.022), punkt(x + 0.022, y + 0.022)], fill=(255, 250, 240, 255))
    # Band zum Aufhängen
    d.arc([punkt(0.34, 0.02), punkt(0.66, 0.30)], 180, 360, fill=(200, 30, 40, 255), width=int(6 * SS))
    d.polygon([punkt(0.42, 0.26), punkt(0.58, 0.26), punkt(0.62, 0.34), punkt(0.38, 0.34)], fill=(200, 30, 40, 255))
    return fertig(runter(im, 1), (50, 22, 8))


def edelweiss():
    im = leer(S, S)
    d = ImageDraw.Draw(im)
    # Blätter hinter der Blüte
    for w in (210, 330, 270):
        a = math.radians(w)
        cx, cy = 0.5 + 0.3 * math.cos(a), 0.55 + 0.3 * math.sin(a)
        blatt = leer(S, S)
        bd = ImageDraw.Draw(blatt)
        bd.ellipse([punkt(cx - 0.05, cy - 0.20), punkt(cx + 0.05, cy + 0.20)], fill=(86, 140, 86, 255))
        blatt = blatt.rotate(-(w + 90), center=punkt(cx, cy))
        im.alpha_composite(blatt)
    # Wollige Blütenblätter: zwölf Ellipsen, zweilagig
    for lage, (n, laenge, farbe) in enumerate(((12, 0.40, (236, 238, 232, 255)), (12, 0.34, (252, 252, 248, 255)))):
        for i in range(n):
            w = math.radians(i * 360 / n + (15 if lage else 0))
            blatt = leer(S, S)
            bd = ImageDraw.Draw(blatt)
            bd.ellipse([punkt(0.5 - 0.055, 0.5 - laenge), punkt(0.5 + 0.055, 0.5 + 0.02)], fill=farbe, outline=(190, 194, 188, 255), width=int(1.5 * SS))
            blatt = blatt.rotate(-math.degrees(w), center=punkt(0.5, 0.5))
            im.alpha_composite(blatt)
    d = ImageDraw.Draw(im)
    # Gelber Blütenkopf
    d.ellipse([punkt(0.40, 0.40), punkt(0.60, 0.60)], fill=(248, 206, 54, 255))
    for (x, y) in ((0.46, 0.46), (0.54, 0.45), (0.5, 0.53), (0.45, 0.54), (0.55, 0.54), (0.5, 0.47)):
        d.ellipse([punkt(x - 0.028, y - 0.028), punkt(x + 0.028, y + 0.028)], fill=(255, 232, 110, 255), outline=(214, 160, 20, 255), width=int(1.2 * SS))
    return fertig(runter(im, 1), (80, 90, 80), 3.0)


def sieben():
    im = leer(S, S)
    d = ImageDraw.Draw(im)
    schr = font(FONT_SCHWER, 0.96 * S)
    text = Image.new("L", (S, S), 0)
    td = ImageDraw.Draw(text)
    text_mittig(td, (S / 2, S * 0.52), "7", schr, 255)
    # goldene Rahmenlinie, dann roter Verlauf
    rand = text.filter(ImageFilter.MaxFilter(int(10 * SS) | 1))
    gold = mit_verlauf(rand, (255, 236, 130, 255), (196, 134, 24, 255))
    im.alpha_composite(gold)
    rot = mit_verlauf(text, (255, 90, 80, 255), (170, 12, 24, 255))
    im.alpha_composite(rot)
    d = ImageDraw.Draw(im)
    # Glanz
    gl = verlauf_senkrecht(S, S, (255, 255, 255, 130), (255, 255, 255, 0))
    obere = Image.new("L", (S, S), 0)
    ImageDraw.Draw(obere).rectangle([0, 0, S, int(S * 0.45)], fill=255)
    gl.putalpha(ImageChops.multiply(ImageChops.multiply(gl.getchannel("A"), text), obere))
    im.alpha_composite(gl)
    return fertig(runter(im, 1), (60, 12, 12))


def raute():
    im = leer(S, S)
    # Schild mit Bayern-Rauten, Goldrahmen, Aufschrift
    form = maske_von(lambda d: d.rounded_rectangle([punkt(0.12, 0.08), punkt(0.88, 0.92)], radius=int(0.14 * S), fill=255))
    muster = leer(S, S)
    md = ImageDraw.Draw(muster)
    r = 0.12 * S
    for j in range(-1, 10):
        for i in range(-1, 10):
            if (i + j) % 2 != 0:
                continue
            cx, cy = 0.12 * S + i * r, 0.08 * S + j * r
            md.polygon([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)], fill=(244, 246, 252, 255) if i % 2 == 0 else (36, 100, 200, 255))
    muster.putalpha(ImageChops.multiply(muster.getchannel("A"), form))
    im.alpha_composite(muster)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([punkt(0.12, 0.08), punkt(0.88, 0.92)], radius=int(0.14 * S), outline=(232, 188, 60, 255), width=int(7 * SS))
    d.rounded_rectangle([punkt(0.17, 0.13), punkt(0.83, 0.87)], radius=int(0.10 * S), outline=(255, 232, 140, 255), width=int(2.5 * SS))
    # Band mit WILD
    d.rounded_rectangle([punkt(0.10, 0.40), punkt(0.90, 0.62)], radius=int(0.05 * S), fill=(200, 30, 40, 255), outline=(255, 232, 140, 255), width=int(3 * SS))
    text_mittig(d, (S / 2, S * 0.51), "WILD", font(FONT_SCHWER, 0.15 * S), (255, 244, 200, 255), kontur=(80, 6, 14, 255), kontur_breite=int(2 * SS))
    gl = glanzlicht(S, S, int(0.14 * S), 0.40, 70)
    gl.putalpha(ImageChops.multiply(gl.getchannel("A"), form))
    im.alpha_composite(gl)
    return fertig(runter(im, 1), (40, 30, 20))


SYMBOLE = {"mass": mass, "brezn": brezn, "hendl": hendl, "herz": herz, "edelweiss": edelweiss, "sieben": sieben, "raute": raute}

if __name__ == "__main__":
    bogen = Image.new("RGBA", (7 * 214 + 30, 260), (246, 240, 224, 255))
    for i, (name, f) in enumerate(SYMBOLE.items()):
        bild = f()
        speichern(bild, "slot_%s.png" % name)
        bogen.alpha_composite(bild, (20 + i * 214, 20))
    bogen.convert("RGB").save(os.path.join(ROOT, "build", "symbole_vorschau.png"))
    print("fertig")
