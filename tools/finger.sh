#!/bin/bash
# Bilder der Mittelfinger-Pose, Tuning als Argumente: bash tools/finger.sh arm=-0.6,-0.2 unter=-1.9,0
GODOT="${GODOT:-/c/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe}"
"$GODOT" --path . res://tools/finger_schuss.tscn --resolution 1100x850 -- "$@" 2>&1 | grep -E "^(SCRIPT )?ERROR: [^PR]|Parse" | head
