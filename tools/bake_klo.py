# Aufruf: python tools/bake_klo.py  (im Projektordner) — schreibt scenes/klo_container.tscn neu
# Baut scenes/klo_container.tscn neu: bayerisches Toilettenhäusl aus Grundformen.
# Grundriss wie vorher: Mitte (0.02, 0.4), 3.4 (X) × 2.35 (Z); Türen auf der -X-Seite.
import math
M = 'res://assets/zelt/materialien/'
mats = ['holz_dunkel','holz_hell','creme_lack','rauten','gold','schindel','messing','schwarz_lack']
ext = ['[ext_resource type="Script" path="res://scripts/welt_text.gd" id="2_wt"]',
       '[ext_resource type="Script" path="res://scripts/klo_container.gd" id="3_klo"]',
       '[ext_resource type="FontFile" path="res://assets/fonts/UnifrakturCook-Bold.ttf" id="4_fraktur"]']
for i,m in enumerate(mats):
    ext.append(f'[ext_resource type="Material" path="{M}{m}.tres" id="m_{m}"]')
subs = []
nodes = []
mesh_id = {}
def box(size):
    k = 'box_%.3f_%.3f_%.3f' % size
    if k not in mesh_id:
        mesh_id[k] = k
        subs.append(f'[sub_resource type="BoxMesh" id="{k}"]\nsize = Vector3({size[0]}, {size[1]}, {size[2]})\n')
    return k
def prisma(size):
    k = 'prisma_%.3f_%.3f_%.3f' % size
    if k not in mesh_id:
        mesh_id[k] = k
        subs.append(f'[sub_resource type="PrismMesh" id="{k}"]\nsize = Vector3({size[0]}, {size[1]}, {size[2]})\n')
    return k
def basis_y(deg):
    r = math.radians(deg); c, s = math.cos(r), math.sin(r)
    # Zeilen der Basis (Godot schreibt Zeilen)
    return (c, 0, s, 0, 1, 0, -s, 0, c)
def basis_x(deg):
    r = math.radians(deg); c, s = math.cos(r), math.sin(r)
    return (1, 0, 0, 0, c, -s, 0, s, c)
def tf(pos, b=(1,0,0,0,1,0,0,0,1)):
    return 'Transform3D(%s, %s)' % (', '.join('%.4g' % v for v in b), ', '.join('%.4g' % v for v in pos))
def teil(name, parent, mesh, mat, pos, b=(1,0,0,0,1,0,0,0,1)):
    nodes.append(f'[node name="{name}" type="MeshInstance3D" parent="{parent}"]\ntransform = {tf(pos,b)}\nmesh = SubResource("{mesh}")\nsurface_material_override/0 = ExtResource("m_{mat}")\n')

CX, CZ = 0.02, 0.4
BX, BZ = 3.3, 2.25        # Wandmaße
H = 2.1                   # Wandhöhe
FX = CX - BX/2            # Vorderseite (Türen)
nodes.append('[node name="Haeusl" type="Node3D" parent="."]\n')
P = 'Haeusl'
# Sockel und Wände
teil('Sockel', P, box((BX+0.2, 0.16, BZ+0.2)), 'holz_dunkel', (CX, 0.08, CZ))
teil('Waende', P, box((BX, H, BZ)), 'creme_lack', (CX, 0.16+H/2, CZ))
# Fachwerk: Rahmen und Streben auf allen vier Seiten
d = 0.09
for seite, (nx, lang, achse) in {'Vorn': (-1, BZ, 'z'), 'Hinten': (1, BZ, 'z')}.items():
    x = CX + nx*(BX/2 + 0.01)
    for j, z in enumerate([CZ-BZ/2+d/2, CZ, CZ+BZ/2-d/2]):
        teil(f'{seite}Pfosten{j}', P, box((0.04, H, d)), 'holz_dunkel', (x, 0.16+H/2, z))
    for j, y in enumerate([0.16+d/2, 0.16+H-d/2]):
        teil(f'{seite}Riegel{j}', P, box((0.04, d, lang)), 'holz_dunkel', (x, y, CZ))
for seite, nz in {'Links': -1, 'Rechts': 1}.items():
    z = CZ + nz*(BZ/2 + 0.01)
    for j, x in enumerate([CX-BX/2+d/2, CX, CX+BX/2-d/2]):
        teil(f'{seite}Pfosten{j}', P, box((d, H, 0.04)), 'holz_dunkel', (x, 0.16+H/2, z))
    for j, y in enumerate([0.16+d/2, 0.16+H*0.55, 0.16+H-d/2]):
        teil(f'{seite}Riegel{j}', P, box((BX, d, 0.04)), 'holz_dunkel', (CX, y, z))
    # Andreaskreuz-Streben in beiden Feldern
    feld_b = BX/2 - d
    feld_h = H*0.45
    lang_s = math.hypot(feld_b, feld_h)
    w = math.degrees(math.atan2(feld_h, feld_b))
    for j, x in enumerate([CX-BX/4, CX+BX/4]):
        for k, sg in enumerate([1, -1]):
            r = math.radians(sg*w); c, s = math.cos(r), math.sin(r)
            teil(f'{seite}Strebe{j}{k}', P, box((lang_s, 0.07, 0.04)), 'holz_dunkel',
                 (x, 0.16+H*0.55+H*0.225, z), (c, -s, 0, s, c, 0, 0, 0, 1))
# Zwei Türen mit Herzerl, Griff und Schild
for j, (name, z) in enumerate([('Damen', CZ-0.52), ('Herren', CZ+0.52)]):
    tp = f'{P}/Tuer{name}'
    nodes.append(f'[node name="Tuer{name}" type="Node3D" parent="{P}"]\ntransform = {tf((FX-0.03, 0.16, z))}\n')
    teil('Blatt', tp, box((0.06, 1.75, 0.82)), 'holz_hell', (0, 0.875+0.05, 0))
    for k, y in enumerate([0.35, 1.0, 1.6]):
        teil(f'Leiste{k}', tp, box((0.03, 0.08, 0.84)), 'holz_dunkel', (-0.04, y, 0))
    teil('Griff', tp, box((0.05, 0.05, 0.12)), 'messing', (-0.07, 0.95, 0.28 if j == 0 else -0.28))
    nodes.append(f'[node name="Herz" type="Label3D" parent="{tp}"]\ntransform = {tf((-0.045, 1.35, 0), basis_y(-90))}\npixel_size = 0.004\nmodulate = Color(0.16, 0.08, 0.04, 1)\noutline_size = 0\nfont_size = 64\ntext = "♥"\n')
    nodes.append(f'[node name="Schild" type="Label3D" parent="{tp}"]\ntransform = {tf((-0.06, 1.98, 0), basis_y(-90))}\npixel_size = 0.0045\nmodulate = Color(0.98, 0.9, 0.7, 1)\noutline_modulate = Color(0.2, 0.1, 0.04, 1)\noutline_size = 10\nfont = ExtResource("4_fraktur")\nfont_size = 56\ntext = "{name}"\n')
    teil('Schildbrett', tp, box((0.03, 0.2, 0.62)), 'holz_dunkel', (-0.035, 1.98, 0))
# Satteldach mit Rauten, First entlang X, Goldkante
DX, DZ, DH = BX+0.4, BZ+0.5, 0.5
teil('Dach', P, prisma((DZ, DH, DX)), 'rauten', (CX, 0.16+H+DH/2, CZ), basis_y(90))
teil('Traufe', P, box((DX+0.04, 0.08, DZ+0.04)), 'gold', (CX, 0.16+H+0.04, CZ))
teil('First', P, box((DX+0.1, 0.1, 0.1)), 'gold', (CX, 0.16+H+DH+0.02, CZ))
# Giebeldreieck vorn/hinten in Holz
for j, x in enumerate([CX-DX/2+0.02, CX+DX/2-0.02]):
    teil(f'Giebel{j}', P, prisma((DZ-0.1, DH-0.05, 0.05)), 'holz_dunkel', (x, 0.16+H+(DH-0.05)/2, CZ), basis_y(90))
# Kleines Herzfenster im Giebel vorn
nodes.append(f'[node name="GiebelHerz" type="Label3D" parent="{P}"]\ntransform = {tf((CX-DX/2-0.01, 0.16+H+0.32, CZ), basis_y(-90))}\npixel_size = 0.004\nmodulate = Color(1, 0.85, 0.45, 1)\noutline_size = 0\nfont_size = 72\ntext = "♥"\n')

head = f'[gd_scene format=3]\n\n' + '\n'.join(ext) + '\n\n[sub_resource type="BoxShape3D" id="Kollision"]\nsize = Vector3(3.4, 2.3, 2.35)\n\n[sub_resource type="SphereMesh" id="LampeMesh"]\nradius = 0.09\nheight = 0.18\nradial_segments = 12\nrings = 6\n\n[sub_resource type="StandardMaterial3D" id="LampeMat"]\nresource_local_to_scene = true\nalbedo_color = Color(0.2, 1, 0.3, 1)\nemission_enabled = true\nemission = Color(0.2, 1, 0.3, 1)\nemission_energy_multiplier = 3.0\n\n'
rest = '''[node name="KloContainer" type="Node3D"]
script = ExtResource("3_klo")

''' + '\n'.join(nodes) + '''
[node name="Body" type="StaticBody3D" parent="."]

[node name="CollisionShape3D" type="CollisionShape3D" parent="Body"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.02, 1.15, 0.4)
shape = SubResource("Kollision")

[node name="Schild" type="Label3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3.55, 0.4)
billboard = 1
pixel_size = 0.01
font_size = 48
outline_size = 12
text = "WORLD_TOILET"
script = ExtResource("2_wt")
schluessel = "WORLD_TOILET"

[node name="Lampe" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.76, 2.1, 0.4)
mesh = SubResource("LampeMesh")
material_override = SubResource("LampeMat")

[node name="LampenLicht" type="OmniLight3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.95, 2.1, 0.4)
light_color = Color(0.2, 1, 0.3, 1)
light_energy = 1.2
omni_range = 2.5
'''
open('scenes/klo_container.tscn', 'w', encoding='utf-8', newline='\n').write(head + '\n'.join(subs) + '\n' + rest)
print('ok', len(nodes))
