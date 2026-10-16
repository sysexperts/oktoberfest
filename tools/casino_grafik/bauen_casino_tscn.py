"""Erzeugt scenes/casino.tscn: das Casino hinter Konrads Zelt (18 x 10 m, Tür zur Wiese, edel in Dunkelrot und Gold).
Koordinaten: Zeltsystem; Mitte (0, -14); Innenseiten der Wände bei x = ±8,85 und z = -9,15 / -18,85.
Aufruf: python -X utf8 tools/casino_grafik/bauen_casino_tscn.py   (Texturen vorher: raum.py)"""
import sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from tscn_szene import *

s = Szene()
M = "assets/zelt/materialien/"
# ---------------------------------------------------------------- Ressourcen
SK_CAS = s.res("Script", "res://scripts/kasino/casino.gd", "skript_cas")
SK_KD = s.res("Script", "res://scripts/kasino/kasino_ding.gd", "skript_kd")
SK_WT = s.res("Script", "res://scripts/welt_text.gd", "skript_wt")
SK_BL = s.res("Script", "res://scripts/kasino/blinker.gd", "skript_bl")
SK_RO = s.res("Script", "res://scripts/kasino/rotieren.gd", "skript_ro")
FONT = s.res("FontFile", "res://assets/fonts/UnifrakturCook-Bold.ttf", "font_fraktur")
ROULETTE = s.res("PackedScene", "res://assets/models/roulette.glb", "m_roulette")
KARTENTISCH = s.res("PackedScene", "res://assets/models/kartentisch.glb", "m_kartentisch")
FIGUR = s.res("PackedScene", "res://scenes/huber_figur.tscn", "s_figur")
SLOT = s.res("PackedScene", "res://scenes/kasino/slot.tscn", "s_slot")
SITZ = s.res("PackedScene", "res://scenes/kasino/sitz.tscn", "s_sitz")
A_BJ = s.res("PackedScene", "res://scenes/kasino/auflage_blackjack.tscn", "s_abj")
A_WU = s.res("PackedScene", "res://scenes/kasino/auflage_wuerfel.tscn", "s_awu")
A_WA = s.res("PackedScene", "res://scenes/kasino/auflage_watten.tscn", "s_awa")
GOLD = s.res("Material", "res://" + M + "gold.tres", "mat_gold")
HOLZ = s.res("Material", "res://" + M + "holz_dunkel.tres", "mat_holz")
STREIFEN = s.res("Material", "res://" + M + "huber_streifen.tres", "mat_streifen")
RAUTEN = s.res("Material", "res://" + M + "huber_rauten.tres", "mat_rauten")
HROT = s.res("Material", "res://" + M + "huber_rot.tres", "mat_hrot")
LACK = s.res("Material", "res://" + M + "schwarz_lack.tres", "mat_lack")
T_TEPPICH = s.res("Texture2D", "res://assets/casino/raum_teppich.png", "t_teppich")
T_TAPETE = s.res("Texture2D", "res://assets/casino/raum_tapete.png", "t_tapete")
T_GIRL = s.res("Texture2D", "res://assets/casino/raum_girlande.png", "t_girlande")
T_B1 = s.res("Texture2D", "res://assets/casino/bild_casino.png", "t_b1")
T_B2 = s.res("Texture2D", "res://assets/casino/bild_karten.png", "t_b2")
T_B3 = s.res("Texture2D", "res://assets/casino/bild_mass.png", "t_b3")

TEPPICH = s.material("Teppich", (1, 1, 1, 1), 0.9, textur=T_TEPPICH, kachel=0.28)
TAPETE = s.material("Tapete", (1, 1, 1, 1), 0.9, textur=T_TAPETE, kachel=0.3)
DECKE = s.material("Decke", (0.1, 0.05, 0.04, 1), 0.9)
SAMT = s.material("Samt", (0.42, 0.04, 0.09, 1), 0.9)
SAMT_DUNKEL = s.material("SamtDunkel", (0.26, 0.03, 0.06, 1), 0.9)
NEON = s.material("Neon", (1.0, 0.85, 0.45, 1), 0.5, leuchte=(1.0, 0.75, 0.3, 1), energie=2.6)
GLUEH = s.material("Glueh", (1.0, 0.9, 0.6, 1), 0.4, leuchte=(1.0, 0.8, 0.4, 1), energie=3.0)
SCHILD = s.material("Schild", (1.0, 0.8, 0.3, 1), 0.5, leuchte=(1.0, 0.7, 0.2, 1), energie=1.4)
SCHWARZ = s.material("Schwarz", (0.03, 0.03, 0.04, 1), 0.25, metall=0.2)
HOLZ_HELL = s.material("HolzHell", (0.34, 0.18, 0.09, 1), 0.55)
HOLZ_NUSS = s.material("Nuss", (0.16, 0.08, 0.05, 1), 0.45)
FLASCHE_G = s.material("FlascheG", (0.1, 0.4, 0.15, 1), 0.2, metall=0.1)
FLASCHE_B = s.material("FlascheB", (0.45, 0.25, 0.05, 1), 0.2, metall=0.1)
FLASCHE_K = s.material("FlascheK", (0.7, 0.75, 0.8, 1), 0.15, metall=0.1)
BLATT = s.material("Blatt", (0.12, 0.38, 0.14, 1), 0.8)
TOPF = s.material("Topf", (0.5, 0.28, 0.14, 1), 0.7)
ROT_L = s.material("RotLampe", (1, 0.3, 0.2, 1), 0.4, leuchte=(1, 0.2, 0.1, 1), energie=2.0)
GIRL = s.material("Girlande", (1, 1, 1, 1), 0.9, textur=T_GIRL, transparenz=2)
BILD1 = s.material("Bild1", (1, 1, 1, 1), 0.6, textur=T_B1)
BILD2 = s.material("Bild2", (1, 1, 1, 1), 0.6, textur=T_B2)
BILD3 = s.material("Bild3", (1, 1, 1, 1), 0.6, textur=T_B3)
KUGELG = s.material("Kugelglas", (1, 0.85, 0.5, 1), 0.2, leuchte=(1, 0.7, 0.3, 1), energie=2.2)

# ---------------------------------------------------------------- Gerüst
s.node("Casino", "Node3D", None, "script = %s\n" % SK_CAS)
BREITE = 18.6      # Außenmaß der Nord- und Südwand
TIEFE = 10.4
MX, MZ = 0.0, -14.0

# Boden, Decke
s.fest("Boden", ".", (18.4, 0.1, 10.4), (0, -0.03, MZ), TEPPICH)
s.fest("Decke", ".", (18.4, 0.1, 10.4), (0, 3.25, MZ), DECKE, mit_form=False)
# Wände (innen Tapete); Ost mit Tür bei z = -14
s.fest("WandWest", ".", (0.3, 3.2, TIEFE), (-9.0, 1.6, MZ), TAPETE)
s.fest("WandNord", ".", (BREITE, 3.2, 0.3), (0, 1.6, -9.0), TAPETE)
s.fest("WandSued", ".", (BREITE, 3.2, 0.3), (0, 1.6, -19.0), TAPETE)
s.fest("WandOstL", ".", (0.3, 3.2, 3.9), (9.0, 1.6, -17.05), TAPETE)
s.fest("WandOstR", ".", (0.3, 3.2, 3.9), (9.0, 1.6, -10.95), TAPETE)
s.fest("TuerSturz", ".", (0.3, 1.0, 2.2), (9.0, 2.7, -14.0), TAPETE)
# Sperre in der Tür (Casino.gd schaltet sie ab, wenn der Türsteher einen eingelassen hat)
s.node("Sperre", "StaticBody3D", ".", tf(8.8, 1.3, -14.0), gruppen=["casino_sperre"])
s.node("Form", "CollisionShape3D", "Sperre", "shape = %s\n" % s.sub("SSperre", "BoxShape3D", "size = Vector3(0.3, 2.6, 2.2)\n"))

# ---------------------------------------------------------------- Außenhaut: orange-weiße Zeltstreifen, dunkles Holz, Satteldach
s.node("Aussen", "Node3D", ".")
A = "Aussen"
dicke = 0.08
s.mesh("HautWest", A, s.box((dicke, 2.3, TIEFE + 0.2)), STREIFEN, (-9.19, 2.05, MZ))
s.mesh("HautSued", A, s.box((BREITE + 0.2, 2.3, dicke)), STREIFEN, (0, 2.05, -19.19))
s.mesh("HautOstL", A, s.box((dicke, 2.3, 3.9)), STREIFEN, (9.19, 2.05, -17.05))
s.mesh("HautOstR", A, s.box((dicke, 2.3, 3.9)), STREIFEN, (9.19, 2.05, -10.95))
s.mesh("HautOstSturz", A, s.box((dicke, 1.0, 2.2)), STREIFEN, (9.19, 2.7, -14.0))
s.mesh("HautNord", A, s.box((BREITE + 0.2, 2.3, dicke)), STREIFEN, (0, 2.05, -8.81))
# Sockel aus dunklem Holz (rundum, Tür ausgespart)
s.mesh("SockelWest", A, s.box((0.12, 0.9, TIEFE + 0.3)), HOLZ, (-9.22, 0.45, MZ))
s.mesh("SockelSued", A, s.box((BREITE + 0.3, 0.9, 0.12)), HOLZ, (0, 0.45, -19.22))
s.mesh("SockelNord", A, s.box((BREITE + 0.3, 0.9, 0.12)), HOLZ, (0, 0.45, -8.78))
s.mesh("SockelOstL", A, s.box((0.12, 0.9, 3.95)), HOLZ, (9.22, 0.45, -17.05))
s.mesh("SockelOstR", A, s.box((0.12, 0.9, 3.95)), HOLZ, (9.22, 0.45, -10.95))
# Eckpfosten und Fachwerk
for i, (x, z) in enumerate(((-9.2, -19.2), (9.2, -19.2), (-9.2, -8.8), (9.2, -8.8))):
    s.mesh("Ecke%d" % i, A, s.box((0.3, 3.35, 0.3)), HOLZ, (x, 1.67, z))
for i, x in enumerate((-6.0, -3.0, 0.0, 3.0, 6.0)):
    s.mesh("PfostenS%d" % i, A, s.box((0.2, 3.3, 0.14)), HOLZ, (x, 1.65, -19.24))
for i, z in enumerate((-17.0, -15.2, -12.8, -11.0)):
    s.mesh("PfostenO%d" % i, A, s.box((0.14, 3.3, 0.2)), HOLZ, (9.24, 1.65, z))
for i, z in enumerate((-16.5, -13.8, -11.2)):
    s.mesh("PfostenW%d" % i, A, s.box((0.14, 3.3, 0.2)), HOLZ, (-9.24, 1.65, z))
# Dachbalken und goldene Traufleiste
s.mesh("TraufeSued", A, s.box((BREITE + 0.6, 0.16, 0.2)), GOLD, (0, 3.3, -19.25))
s.mesh("TraufeWest", A, s.box((0.2, 0.16, TIEFE + 0.6)), GOLD, (-9.25, 3.3, MZ))
s.mesh("TraufeOstL", A, s.box((0.2, 0.16, 4.2)), GOLD, (9.25, 3.3, -17.1))
s.mesh("TraufeOstR", A, s.box((0.2, 0.16, 4.2)), GOLD, (9.25, 3.3, -10.9))
s.mesh("TraufeOstTuer", A, s.box((0.2, 0.16, 2.4)), GOLD, (9.25, 3.3, -14.0))
# Satteldach (First entlang x) in rot-weißen Streifen, goldener First und Wimpel
s.mesh("Dach", A, s.prisma(TIEFE + 0.5, 1.9, BREITE + 0.8), STREIFEN, (0, 4.25, MZ), ry=90, schatten=True)
s.mesh("Dachsaum", A, s.box((BREITE + 0.9, 0.12, 0.12)), GOLD, (0, 5.18, MZ))
for i, x in enumerate((-9.2, 9.2)):
    s.mesh("Mast%d" % i, A, s.zylinder(0.04, 0.05, 1.5, 8), GOLD, (x, 5.7, MZ))
    s.mesh("Fahne%d" % i, A, s.quad(0.9, 0.6), RAUTEN, (x + (0.45 if i else -0.45), 6.1, MZ), ry=90, schatten=False)
for i, x in enumerate((-6.0, -2.0, 2.0, 6.0)):
    s.mesh("Kugel%d" % i, A, s.kugel(0.13), GOLD, (x, 5.25, MZ))

# Eingang (Ost): Rahmen, Schild, Baldachin, Teppich und Laternen auf der Wiese
s.mesh("TuerRahmenO", A, s.box((0.3, 2.6, 0.14)), GOLD, (9.28, 1.3, -12.85))
s.mesh("TuerRahmenW", A, s.box((0.3, 2.6, 0.14)), GOLD, (9.28, 1.3, -15.15))
s.mesh("TuerRahmenOben", A, s.box((0.3, 0.14, 2.44)), GOLD, (9.28, 2.62, -14.0))
s.node("Schild", "StaticBody3D", ".", tf(9.5, 3.02, -14.0))
s.mesh("Mesh", "Schild", s.box((0.06, 0.55, 2.6)), SCHILD, (0, 0, 0))
s.node("Beschriftung", "Label3D", "Schild", tf(0.05, 0, 0, ry=90) + 'pixel_size = 0.0055\nmodulate = Color(0.16, 0.07, 0.03, 1)\noutline_size = 0\ntext = "WORLD_CASINO"\nfont = %s\nfont_size = 72\nscript = %s\nschluessel = "WORLD_CASINO"\n' % (FONT, SK_WT))
s.mesh("Teppich", A, s.box((4.2, 0.025, 1.9)), SAMT, (11.2, 0.012, -14.0))
s.mesh("TeppichRand0", A, s.box((4.2, 0.03, 0.07)), GOLD, (11.2, 0.02, -13.05))
s.mesh("TeppichRand1", A, s.box((4.2, 0.03, 0.07)), GOLD, (11.2, 0.02, -14.95))
for i, (x, z) in enumerate(((10.0, -12.75), (12.9, -12.75), (10.0, -15.25), (12.9, -15.25))):
    s.mesh("PfostenSeil%d" % i, A, s.zylinder(0.045, 0.045, 1.0, 10), GOLD, (x, 0.5, z))
s.mesh("Seil0", A, s.box((2.9, 0.03, 0.03)), SAMT_DUNKEL, (11.45, 0.88, -12.75))
s.mesh("Seil1", A, s.box((2.9, 0.03, 0.03)), SAMT_DUNKEL, (11.45, 0.88, -15.25))
for i, z in enumerate((-12.0, -16.0)):
    s.mesh("Laterne%d" % i, A, s.zylinder(0.05, 0.05, 2.3, 10), GOLD, (9.9, 1.15, z))
    s.mesh("LaterneLampe%d" % i, A, s.kugel(0.18), GLUEH, (9.9, 2.4, z))
    s.licht("LaternenLicht%d" % i, A, (9.9, 2.3, z), (1, 0.78, 0.45), 1.1, 6.0)
# Blumenkästen und Lorbeerbäumchen am Eingang
for i, z in enumerate((-12.0, -16.0)):
    s.mesh("Kasten%d" % i, A, s.box((0.35, 0.3, 1.4)), HOLZ_HELL, (9.4, 0.85, z - (0.9 if i else -0.9)))
    s.mesh("Blumen%d" % i, A, s.box((0.3, 0.14, 1.3)), s.material("Blumen", (0.8, 0.15, 0.25, 1), 0.8), (9.4, 1.07, z - (0.9 if i else -0.9)))
for i, z in enumerate((-12.3, -15.7)):
    pass
# Neonrahmen um die Tür
s.mesh("NeonOben", A, s.box((0.04, 0.04, 2.5)), NEON, (9.34, 2.7, -14.0), schatten=False)
s.mesh("NeonO", A, s.box((0.04, 2.7, 0.04)), NEON, (9.34, 1.35, -12.75), schatten=False)
s.mesh("NeonW", A, s.box((0.04, 2.7, 0.04)), NEON, (9.34, 1.35, -15.25), schatten=False)
# Außen: Fensterbänder mit Lichtschein (rot-goldene Fenster in der Südwand)
for i, x in enumerate((-6.0, -3.0, 0.0, 3.0, 6.0)):
    s.mesh("FensterS%d" % i, A, s.box((1.4, 1.3, 0.04)), s.material("FensterGlas", (1, 0.7, 0.35, 1), 0.2, leuchte=(1, 0.6, 0.25, 1), energie=1.3), (x + 1.5, 1.8, -19.25), schatten=False)
for i, z in enumerate((-16.5, -13.8, -11.2)):
    s.mesh("FensterW%d" % i, A, s.box((0.04, 1.3, 1.4)), s.material("FensterGlas", (1, 0.7, 0.35, 1), 0.2, leuchte=(1, 0.6, 0.25, 1), energie=1.3), (-9.28, 1.8, z + 1.4), schatten=False)

# ---------------------------------------------------------------- Innenausbau: Täfelung, Vorhänge, Säulen, Bilder, Girlanden
I = "Innen"
s.node(I, "Node3D", ".")
s.mesh("TaefelSued", I, s.box((17.6, 1.05, 0.06)), HOLZ_NUSS, (0, 0.55, -18.82))
s.mesh("TaefelNord", I, s.box((17.6, 1.05, 0.06)), HOLZ_NUSS, (0, 0.55, -9.18))
s.mesh("TaefelWest", I, s.box((0.06, 1.05, 9.6)), HOLZ_NUSS, (-8.82, 0.55, MZ))
s.mesh("TaefelOstL", I, s.box((0.06, 1.05, 3.7)), HOLZ_NUSS, (8.82, 0.55, -17.0))
s.mesh("TaefelOstR", I, s.box((0.06, 1.05, 3.7)), HOLZ_NUSS, (8.82, 0.55, -11.0))
s.mesh("LeisteSued", I, s.box((17.6, 0.06, 0.1)), GOLD, (0, 1.11, -18.8))
s.mesh("LeisteNord", I, s.box((17.6, 0.06, 0.1)), GOLD, (0, 1.11, -9.2))
s.mesh("LeisteWest", I, s.box((0.1, 0.06, 9.6)), GOLD, (-8.8, 1.11, MZ))
s.mesh("DeckenLeisteSued", I, s.box((17.6, 0.1, 0.18)), GOLD, (0, 3.12, -18.78))
s.mesh("DeckenLeisteNord", I, s.box((17.6, 0.1, 0.18)), GOLD, (0, 3.12, -9.22))
s.mesh("DeckenLeisteWest", I, s.box((0.18, 0.1, 9.6)), GOLD, (-8.78, 3.12, MZ))
s.mesh("DeckenLeisteOst", I, s.box((0.18, 0.1, 9.6)), GOLD, (8.78, 3.12, MZ))
# Deckenbalken
for i, x in enumerate((-6.5, -2.2, 2.2, 6.5)):
    s.mesh("Balken%d" % i, I, s.box((0.35, 0.22, 10.2)), HOLZ, (x, 3.1, MZ))
# Vorhänge an der Südwand und der Westwand
for i, x in enumerate((-7.4, -3.7, 0.0, 3.7, 7.4)):
    s.mesh("VorhangS%d" % i, I, s.box((1.9, 2.9, 0.12)), SAMT, (x, 1.7, -18.76))
    s.mesh("VorhangStange%d" % i, I, s.box((2.0, 0.05, 0.05)), GOLD, (x, 3.12, -18.7))
for i, z in enumerate((-17.8, -14.0, -10.4)):
    s.mesh("VorhangW%d" % i, I, s.box((0.12, 2.9, 1.8)), SAMT, (-8.76, 1.7, z))
# Bilder an der Westwand und der Nordwand
for i, (z, t) in enumerate(((-16.0, BILD1), (-12.0, BILD2))):
    s.mesh("RahmenW%d" % i, I, s.box((0.05, 1.3, 1.0)), GOLD, (-8.8, 2.1, z), schatten=False)
    s.mesh("BildW%d" % i, I, s.quad(0.88, 1.18), t, (-8.77, 2.1, z), ry=90, schatten=False)
for i, (x, t) in enumerate(((-1.0, BILD3), (2.0, BILD1))):
    s.mesh("RahmenN%d" % i, I, s.box((1.0, 1.3, 0.05)), GOLD, (x, 2.3, -9.2), schatten=False)
    s.mesh("BildN%d" % i, I, s.quad(0.88, 1.18), t, (x, 2.3, -9.17), ry=180, schatten=False)
# Wimpelketten quer durch den Raum
for i, z in enumerate((-11.5, -15.5)):
    s.mesh("Girlande%d" % i, I, s.quad(17.4, 0.7), s.material("Girlande%d" % i, (1, 1, 1, 1), 0.9, textur=T_GIRL, transparenz=2, uv=(8, 1)), (0, 2.85, z), ry=0, schatten=False)
# Säulen mit Gold: zwischen den Tischen und am Eingang
for i, (x, z) in enumerate(((-1.35, -17.9), (2.75, -17.9), (8.35, -16.0), (8.35, -12.0))):
    s.node("Saeule%d" % i, "StaticBody3D", I, tf(x, 0, z))
    p = I + "/Saeule%d" % i
    s.mesh("Schaft", p, s.zylinder(0.24, 0.27, 3.1, 14), SAMT_DUNKEL, (0, 1.55, 0))
    s.mesh("Sockel", p, s.box((0.7, 0.18, 0.7)), GOLD, (0, 0.09, 0))
    s.mesh("Kapitell", p, s.box((0.7, 0.2, 0.7)), GOLD, (0, 3.1, 0))
    s.mesh("Ring", p, s.zylinder(0.3, 0.3, 0.06, 14), GOLD, (0, 1.2, 0))
    s.node("Form", "CollisionShape3D", p, tf(0, 1.55, 0) + "shape = %s\n" % s.sub("SSaeule", "BoxShape3D", "size = Vector3(0.6, 3.1, 0.6)\n"))
# Wandleuchter an den Säulen
for i, (x, z, ry) in enumerate(((-1.35, -17.55, 0), (2.75, -17.55, 0), (8.0, -16.0, 90), (8.0, -12.0, 90))):
    s.mesh("Leuchter%d" % i, I, s.kugel(0.11), KUGELG, (x, 2.2, z), schatten=False)
# Kronleuchter (drehen sich langsam)
for i, (x, z) in enumerate(((-5.5, -13.4), (0.0, -14.6), (5.5, -13.4))):
    n = "Kronleuchter%d" % i
    s.node(n, "Node3D", I, tf(x, 2.75, z) + "script = %s\ngrad_pro_sekunde = %s\n" % (SK_RO, 9.0 + 4 * i))
    s.mesh("Kette", I + "/" + n, s.zylinder(0.015, 0.015, 0.5, 6), GOLD, (0, 0.45, 0))
    s.mesh("Ring", I + "/" + n, s.torus(0.5, 0.58), GOLD, (0, 0, 0))
    s.mesh("RingInnen", I + "/" + n, s.torus(0.2, 0.26), GOLD, (0, 0.12, 0))
    for k in range(8):
        a = math.radians(k * 45)
        s.mesh("Flamme%d" % k, I + "/" + n, s.kugel(0.07, 8), KUGELG, (0.54 * math.cos(a), 0.1, 0.54 * math.sin(a)), schatten=False)
    s.mesh("Zapfen", I + "/" + n, s.kugel(0.12), GOLD, (0, -0.15, 0))
    s.licht("Licht", I + "/" + n, (0, -0.1, 0), (1, 0.78, 0.5), 2.6, 9.0)
s.licht("LichtBar", I, (0.5, 2.6, -11.0), (1, 0.7, 0.4), 1.8, 6.0)
s.licht("LichtRoulette", I, (-6.4, 2.4, -14.4), (1, 0.75, 0.5), 1.5, 6.0)
s.licht("LichtTuer", I, (7.0, 2.6, -14.0), (1, 0.75, 0.5), 1.6, 6.0)

# Neonschrift CASINO an der Südwand (flackert leicht)
s.node("NeonSchrift", "Label3D", I, tf(0, 2.55, -18.62) + 'pixel_size = 0.012\nmodulate = Color(1, 0.82, 0.4, 1)\noutline_size = 8\noutline_modulate = Color(0.6, 0.2, 0.05, 1)\nshaded = false\nno_depth_test = false\ntext = "WORLD_CASINO"\nfont = %s\nfont_size = 140\nscript = %s\nschluessel = "WORLD_CASINO"\n' % (FONT, SK_WT))
for i, (x, y, gr) in enumerate(((0, 3.0, (4.6, 0.05, 0.05)), (0, 2.08, (4.6, 0.05, 0.05)), (-2.3, 2.54, (0.05, 0.97, 0.05)), (2.3, 2.54, (0.05, 0.97, 0.05)))):
    s.node("NeonRohr%d" % i, "MeshInstance3D", I, tf(x, y, -18.66) + "mesh = %s\nsurface_material_override/0 = %s\nscript = %s\ntakt = %s\n" % (s.box(gr), NEON, SK_BL, 1.1 + 0.4 * i))

# ---------------------------------------------------------------- Bar an der Nordwand
B = "Bar"
s.node(B, "Node3D", ".")
s.fest("Theke", B, (5.2, 1.05, 0.7), (0.5, 0.525, -10.7), HOLZ_NUSS)
s.mesh("ThekePlatte", B, s.box((5.4, 0.08, 0.95)), SCHWARZ, (0.5, 1.09, -10.75))
s.mesh("ThekeKante", B, s.box((5.4, 0.04, 0.05)), GOLD, (0.5, 1.12, -11.24))
s.mesh("Fussrohr", B, s.zylinder(0.035, 0.035, 5.2, 10), GOLD, (0.5, 0.2, -11.15), rz=90)
s.mesh("RueckenRegal", B, s.box((6.0, 0.06, 0.35)), HOLZ_HELL, (0.5, 1.5, -9.3))
s.mesh("RueckenRegal2", B, s.box((6.0, 0.06, 0.35)), HOLZ_HELL, (0.5, 2.0, -9.3))
s.mesh("RueckenSpiegel", B, s.box((6.0, 1.3, 0.04)), s.material("Spiegel", (0.75, 0.8, 0.85, 1), 0.05, metall=0.9), (0.5, 1.75, -9.17), schatten=False)
for i in range(14):
    mat = (FLASCHE_G, FLASCHE_B, FLASCHE_K)[i % 3]
    x = -2.2 + i * 0.35
    s.mesh("Flasche%d" % i, B, s.zylinder(0.045, 0.06, 0.3, 8), mat, (x, 1.68, -9.3))
    s.mesh("FlascheHals%d" % i, B, s.zylinder(0.02, 0.025, 0.12, 8), mat, (x, 1.89, -9.3))
for i in range(12):
    mat = (FLASCHE_B, FLASCHE_K, FLASCHE_G)[i % 3]
    x = -1.9 + i * 0.37
    s.mesh("FlascheO%d" % i, B, s.zylinder(0.045, 0.055, 0.28, 8), mat, (x, 2.18, -9.3))
for i in range(5):
    x = -1.5 + i * 1.0
    s.node("Barhocker%d" % i, "Node3D", B, tf(x + 0.5, 0, -11.7, ry=0))
    s.mesh("Polster", B + "/Barhocker%d" % i, s.zylinder(0.24, 0.24, 0.09, 18), SAMT, (0, 0.72, 0))
    s.mesh("Stiel", B + "/Barhocker%d" % i, s.zylinder(0.035, 0.035, 0.68, 8), GOLD, (0, 0.36, 0))
    s.mesh("Fuss", B + "/Barhocker%d" % i, s.zylinder(0.2, 0.22, 0.03, 18), GOLD, (0, 0.015, 0))

# ---------------------------------------------------------------- Klavier, Sofa, Pflanzen, Läufer
P = "Moebel"
s.node(P, "Node3D", ".")
s.fest("Klavier", P, (1.7, 0.95, 1.2), (7.75, 0.5, -18.0), SCHWARZ)
s.mesh("KlavierDeckel", P, s.box((1.7, 0.05, 1.2)), LACK, (7.75, 1.0, -18.0))
s.mesh("Tasten", P, s.box((0.5, 0.05, 1.1)), s.material("Tasten", (0.95, 0.93, 0.88, 1), 0.4), (6.75, 0.86, -18.0))
s.mesh("KlavierBein0", P, s.zylinder(0.05, 0.05, 0.5, 8), SCHWARZ, (8.4, 0.25, -17.5))
s.mesh("KlavierBein1", P, s.zylinder(0.05, 0.05, 0.5, 8), SCHWARZ, (8.4, 0.25, -18.5))
s.mesh("Klavierhocker", P, s.zylinder(0.22, 0.22, 0.06, 14), SAMT, (6.2, 0.46, -18.0))
s.mesh("KlavierhockerStiel", P, s.zylinder(0.04, 0.04, 0.44, 8), GOLD, (6.2, 0.22, -18.0))
for i, x in enumerate((7.4,)):
    s.fest("Sofa%d" % i, P, (2.2, 0.5, 0.8), (x - 0.0, 0.25, -9.6), SAMT)
    s.mesh("SofaLehne%d" % i, P, s.box((2.2, 0.55, 0.2)), SAMT, (x, 0.75, -9.28))
    s.mesh("SofaArm0_%d" % i, P, s.box((0.2, 0.3, 0.8)), SAMT, (x - 1.1, 0.5, -9.6))
    s.mesh("SofaArm1_%d" % i, P, s.box((0.2, 0.3, 0.8)), SAMT, (x + 1.1, 0.5, -9.6))
s.fest("Sofa1", P, (0.8, 0.5, 2.0), (-8.4, 0.25, -17.9), SAMT_DUNKEL, mit_form=False)
for i, (x, z) in enumerate(((-8.3, -9.5), (8.3, -9.5), (-8.3, -18.5), (-0.5, -9.7), (8.2, -14.0))):
    if i == 4:
        continue
    s.mesh("Topf%d" % i, P, s.zylinder(0.28, 0.2, 0.5, 12), TOPF, (x, 0.25, z))
    s.mesh("Palme%d" % i, P, s.kugel(0.55, 10), BLATT, (x, 1.15, z))
    s.mesh("PalmeOben%d" % i, P, s.kugel(0.38, 10), BLATT, (x + 0.12, 1.65, z - 0.08))
s.mesh("Laeufer", P, s.box((7.4, 0.02, 1.7)), SAMT_DUNKEL, (4.9, 0.006, -14.0))
s.mesh("LaeuferR0", P, s.box((7.4, 0.025, 0.06)), GOLD, (4.9, 0.012, -13.15))
s.mesh("LaeuferR1", P, s.box((7.4, 0.025, 0.06)), GOLD, (4.9, 0.012, -14.85))

# ---------------------------------------------------------------- Tische (Modelle) mit Auflage, Sitz und Croupier
def tisch(name, modell, art, pos, ry, auflage=None, sitz=(0, 0, 1.62)):
    s.node(name, "Node3D", ".", tf(pos[0], 0, pos[1], ry=ry) + "script = %s\nart = \"%s\"\n" % (SK_KD, art), instanz=modell)
    if auflage:
        s.node("Auflage", "Node3D", name, "", instanz=auflage)
    s.node("Sitz", "Node3D", name, tf(sitz[0], 0, sitz[2]), instanz=SITZ)


def croupier(name, pos, ry, nr, beruf="kellner", extra=""):
    s.node(name, "Node3D", ".", tf(pos[0], 0, pos[1], ry=ry) + 'beruf = "%s"\nnr = %d\nbleibt = true\n%s' % (beruf, nr, extra), instanz=FIGUR)


tisch("Roulette0", ROULETTE, "roulette", (-6.4, -12.6), -90, sitz=(-0.35, 0, 1.15))
croupier("Croupier0", (-4.8, -12.6), 90, 20)
tisch("Roulette1", ROULETTE, "roulette", (-6.4, -16.2), -90, sitz=(-0.35, 0, 1.15))
croupier("Croupier1", (-4.8, -16.2), 90, 21)
tisch("WuerfelTisch", KARTENTISCH, "wuerfel", (-3.4, -17.2), 0, A_WU)
croupier("CroupierWuerfel", (-3.4, -18.62), 0, 24)
tisch("Kartentisch", KARTENTISCH, "blackjack", (0.7, -17.2), 0, A_BJ)
croupier("CroupierKarten", (0.7, -18.62), 0, 22)
tisch("WattenTisch", KARTENTISCH, "watten", (4.8, -17.2), 0, A_WA)
croupier("CroupierWatten", (4.8, -18.62), 0, 23)

# Spielautomaten an der Nordwand (Blick in den Raum); der Sitz hängt am Automaten selbst
for i, x in enumerate((-7.8, -6.6, -5.4, -4.2, 4.0, 5.2)):
    s.node("Slot%d" % i, "Node3D", ".", tf(x, 0, -9.55, ry=180), instanz=SLOT)

# ---------------------------------------------------------------- Leben im Raum: Personal und Gäste
croupier("Barkeeper", (0.5, -9.75), 0, 40, "zapfer")
croupier("Pianist", (6.2, -17.35), -90, 41, "", "")
# Kellnerinnen gehen ihre Runde mit dem Tablett
runde1 = "Array[Vector3]([Vector3(0, 0, 0), Vector3(3.6, 0, 0), Vector3(3.6, 0, 3.4), Vector3(0, 0, 3.4)])"
s.node("Kellnerin0", "Node3D", ".", tf(-1.5, 0, -12.8) + 'beruf = "kellner"\nnr = 42\nbleibt = true\nrunde = %s\ntempo = 0.9\npause = 2.5\n' % runde1, instanz=FIGUR)
runde2 = "Array[Vector3]([Vector3(0, 0, 0), Vector3(-3.0, 0, 0), Vector3(-3.0, 0, -2.4), Vector3(0, 0, -2.4)])"
s.node("Kellner1", "Node3D", ".", tf(5.6, 0, -12.6) + 'beruf = "kellner"\nnr = 43\nbleibt = true\nrunde = %s\ntempo = 0.8\npause = 3.0\n' % runde2, instanz=FIGUR)
# Gäste an der Bar, am Sofa, am Klavier
for i, (x, z, ry, nr) in enumerate(((-1.2, -11.6, 180, 50), (0.1, -11.7, 190, 51), (1.6, -11.6, 170, 52), (7.2, -10.5, 90, 53), (7.9, -10.2, 120, 54), (-8.0, -14.5, -90, 55), (6.9, -16.3, 160, 56))):
    s.node("Gast%d" % i, "Node3D", ".", tf(x, 0, z, ry=ry) + 'nr = %d\nbleibt = true\n' % nr, instanz=FIGUR)

# Türsteher: vor der Tür, auf der Wiese (Blick zur Straße der Gäste)
croupier("Tuersteher", (10.0, -12.3), 0, 30, "security")
s.node("TuerKontakt", "Node3D", ".", tf(10.2, 0, -13.3) + 'script = %s\nart = "tuer"\n' % SK_KD)
croupier("Tuersteher2", (10.0, -15.7), 180, 31, "security")

s.schreiben("scenes/casino.tscn")
