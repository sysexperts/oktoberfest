#!/bin/bash
# Legt zu jeder GLB in assets/creator/<ordner>/ die Zubehör-Szene scenes/creator/<ordner>/<name>.tscn an
# (Aufbau wie bei den Hüten: Node3D mit metadata/lage und dem Modell). Aufruf: bash tools/szenen_aus_glb.sh frisuren
set -e
cd "$(dirname "$0")/.."
ordner="$1"
mkdir -p "scenes/creator/$ordner"
for f in assets/creator/$ordner/*.glb; do
	n=$(basename "$f" .glb)
	cat > "scenes/creator/$ordner/$n.tscn" <<SZ
[gd_scene format=3]

[ext_resource type="PackedScene" path="res://assets/creator/$ordner/$n.glb" id="1_glb"]

[node name="$n" type="Node3D"]
metadata/lage = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)

[node name="Modell" parent="." instance=ExtResource("1_glb")]
SZ
done
