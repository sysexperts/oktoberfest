# Aufruf: python tools/bake_keller_szene.py — schreibt scenes/braukeller.tscn (Kollision, Geräte, Lichter) passend zu tools/bake_braukeller.gd
import math
# Maße wie tools/bake_braukeller.gd
SX0, SX1, SZ0, SZ1 = -12.0, -10.4, 0.9, 5.3
BY, DY = -3.4, -0.35
RX0, RX1, RZ0, RZ1 = -12.0, 4.0, -13.8, 0.2
TZO, TZU = 5.2, 0.8
TX, TB = -11.2, 1.2
H = DY - BY
shapes = []
nodes = []
def box_shape(sid, size):
    shapes.append(f'[sub_resource type="BoxShape3D" id="{sid}"]\nsize = Vector3({size[0]:.3f}, {size[1]:.3f}, {size[2]:.3f})\n')
def kol(name, sid, size, pos, basis='1, 0, 0, 0, 1, 0, 0, 0, 1'):
    box_shape(sid, size)
    nodes.append(f'[node name="{name}" type="CollisionShape3D" parent="Kollision"]\ntransform = Transform3D({basis}, {pos[0]:.3f}, {pos[1]:.3f}, {pos[2]:.3f})\nshape = SubResource("{sid}")\n')

wy = BY + H / 2.0
kol('Boden', 'KolBoden', (RX1 - RX0 + 0.4, 0.4, RZ1 - RZ0 + 0.4), ((RX0 + RX1) / 2, BY - 0.2, (RZ0 + RZ1) / 2))
kol('BodenGang', 'KolBodenGang', (SX1 - SX0 + 0.3, 0.4, SZ1 - RZ1 + 0.3), ((SX0 + SX1) / 2, BY - 0.2, (RZ1 + SZ1) / 2))
kol('Decke', 'KolDecke', (RX1 - RX0 + 0.4, 0.3, RZ1 - RZ0 + 0.4), ((RX0 + RX1) / 2, DY + 0.15, (RZ0 + RZ1) / 2))
kol('WandWest', 'KolWandWest', (0.3, H, SZ1 - RZ0), (RX0 - 0.15, wy, (RZ0 + SZ1) / 2))
kol('WandOst', 'KolWandOst', (0.3, H, RZ1 - RZ0), (RX1 + 0.15, wy, (RZ0 + RZ1) / 2))
kol('WandSued', 'KolWandSued', (RX1 - RX0, H, 0.3), ((RX0 + RX1) / 2, wy, RZ0 - 0.15))
kol('WandNord', 'KolWandNord', (RX1 - (SX1 + 0.3), H, 0.3), (((SX1 + 0.3) + RX1) / 2, wy, RZ1 + 0.15))
kol('GangOst', 'KolGangOst', (0.3, H, SZ1 - RZ1), (SX1 + 0.15, wy, (RZ1 + SZ1) / 2))
kol('GangStirn', 'KolGangStirn', (SX1 - SX0 + 0.3, H, 0.3), ((SX0 + SX1 + 0.3) / 2, wy, SZ1 + 0.15))
kol('TuerwandWest', 'KolTuerW', ((TX - TB / 2) - SX0, H, 0.3), ((SX0 + TX - TB / 2) / 2, wy, RZ1 + 0.15))
kol('TuerwandOst', 'KolTuerO', ((SX1 + 0.3) - (TX + TB / 2), H, 0.3), ((TX + TB / 2 + SX1 + 0.3) / 2, wy, RZ1 + 0.15))
# Rampe unter der Treppe (Oberkante = Stufenkanten), steigt Richtung +z
lauf = TZO - TZU
w = math.atan2(-BY, lauf)
schraeg = math.hypot(-BY, lauf)
c, s_ = math.cos(w), math.sin(w)
# Drehung um x um -w: +z wird nach oben geneigt (Zeilen der Basis)
basis = f'1, 0, 0, 0, {c:.6f}, {s_:.6f}, 0, {-s_:.6f}, {c:.6f}'
mitte = ((SX0 + SX1) / 2, BY / 2 - 0.15 * c, (TZO + TZU) / 2 + 0.15 * s_)
kol('Rampe', 'KolRampe', (SX1 - SX0 - 0.1, 0.3, schraeg), mitte, basis)
# Geländer oben am Schacht (Seite zur Halle und tiefes Ende) — nicht hineinfallen
kol('GelaenderOst', 'KolGelOst', (0.1, 1.0, SZ1 - SZ0), (SX1 + 0.05, 0.57, (SZ0 + SZ1) / 2))
kol('GelaenderSued', 'KolGelSued', (SX1 - SX0, 1.0, 0.1), ((SX0 + SX1) / 2, 0.57, SZ0 + 0.03))

lichter = ''
for i, (lx, lz) in enumerate([(-9.0, -10.5), (-3.0, -10.5), (2.0, -10.5), (-9.0, -2.5), (-3.0, -2.5), (2.0, -2.5)]):
    lichter += f'[node name="Licht{i+1}" type="OmniLight3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {lx}, {DY - 0.95:.2f}, {lz})\nlight_color = Color(1, 0.85, 0.62, 1)\nlight_energy = 1.7\nomni_range = 7.5\nomni_attenuation = 1.3\n\n'
mx = (SX0 + SX1) / 2
lichter += f'[node name="LichtTreppe" type="OmniLight3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {mx:.2f}, -1.2, 3.2)\nlight_color = Color(1, 0.84, 0.6, 1)\nlight_energy = 1.3\nomni_range = 5.0\nomni_attenuation = 1.5\n\n'
lichter += f'[node name="LichtTuer" type="OmniLight3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {mx:.2f}, -1.5, 1.1)\nlight_color = Color(1, 0.82, 0.58, 1)\nlight_energy = 1.4\nomni_range = 4.5\nomni_attenuation = 1.5\n\n'

def inst(name, rid, pos, basis='1, 0, 0, 0, 1, 0, 0, 0, 1'):
    return f'[node name="{name}" parent="." instance=ExtResource("{rid}")]\ntransform = Transform3D({basis}, {pos[0]}, {pos[1]}, {pos[2]})\n\n'

geraete = inst('Maischbottich', '2_maisch', (-8.0, BY, -1.2)) + inst('Sudkessel', '3_kessel', (-5.0, BY, -1.2))
for i, x in enumerate([-8.0, -4.5, -1.0]):
    geraete += inst(f'Gaerfass{i+1}', '4_fass', (x, BY, -12.0))
# Tür in der Querwand (Blatt spannt entlang x): 90° um y gedreht
geraete += inst('Kellertuer', '5_tuer', (TX, BY, RZ1 + 0.15), '0, 0, 1, 0, 1, 0, -1, 0, 0')

text = f'''[gd_scene format=3]

[ext_resource type="ArrayMesh" path="res://assets/braukeller/keller.tres" id="1_keller"]
[ext_resource type="PackedScene" path="res://scenes/brau/maischbottich.tscn" id="2_maisch"]
[ext_resource type="PackedScene" path="res://scenes/brau/sudkessel.tscn" id="3_kessel"]
[ext_resource type="PackedScene" path="res://scenes/brau/gaerfass.tscn" id="4_fass"]
[ext_resource type="PackedScene" path="res://scenes/brau/kellertuer.tscn" id="5_tuer"]
[ext_resource type="Script" path="res://scripts/welt_text.gd" id="6_wt"]

{chr(10).join(shapes)}
[node name="Braukeller" type="Node3D"]

[node name="Gewoelbe" type="MeshInstance3D" parent="."]
mesh = ExtResource("1_keller")

[node name="Kollision" type="StaticBody3D" parent="."]

{chr(10).join(nodes)}
{geraete}{lichter}[node name="Schild" type="Label3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {mx:.2f}, 1.35, 5.8)
billboard = 1
pixel_size = 0.005
font_size = 48
outline_size = 12
modulate = Color(1, 0.9, 0.6, 1)
text = "WORLD_BRAUKELLER"
script = ExtResource("6_wt")
schluessel = "WORLD_BRAUKELLER"
'''
open('scenes/braukeller.tscn', 'w', encoding='utf-8', newline='\n').write(text)
print('ok')
