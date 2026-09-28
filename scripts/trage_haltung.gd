class_name TrageHaltung
extends Resource
## Wie ein Fass oder Karton getragen wird — eingestellt in scenes/werkzeuge/trage_haltung.tscn,
## gespeichert in assets/trage_haltung.tres, gelesen von TragePose (Arme) und
## player.gd (Lage des Fasses am Körper und in der Ich-Sicht).

## Oberarm aus der T-Pose: vor/zurück und nach unten/oben (Bogenmaß)
@export_range(-3.2, 3.2, 0.01) var oberarm_vor := -0.9
@export_range(-3.2, 3.2, 0.01) var oberarm_innen := -0.85
## Unterarm beugen
@export_range(-3.2, 3.2, 0.01) var unterarm := 0.9
## Fass am Körper (relativ zur Spielerfigur) — das sehen die Mitspieler
@export var fass := Transform3D(Basis().scaled(Vector3.ONE * 0.26), Vector3(0, 0.66, -0.3))
## Fass in der eigenen Ich-Sicht (relativ zur Kamera)
@export var pov := Transform3D(Basis().scaled(Vector3.ONE * 0.2), Vector3(0, -0.5, -0.75))
## Karton am Körper (Mitspieler) und in der Ich-Sicht — Arme wie beim Fass
@export var karton := Transform3D(Basis().scaled(Vector3.ONE * 0.5), Vector3(0, 0.55, -0.35))
@export var karton_pov := Transform3D(Basis().scaled(Vector3.ONE * 0.5), Vector3(0, -0.55, -0.6))
