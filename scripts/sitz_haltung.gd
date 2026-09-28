@tool
class_name SitzHaltung
extends Resource
## Korrektur der Sitzhaltung einer Figur — zusätzlich zur Sitzanimation.
## Eingestellt in scenes/werkzeuge/sitz_haltung.tscn. Gedacht für Figuren, deren
## Kleidung beim Sitzen falsch aussieht (Lisa: Rock an den Beinen gewichtet).

## Oberschenkel weniger (−) oder mehr (+) anheben
@export_range(-2.0, 2.0, 0.01) var oberschenkel_vor := 0.0
## Beine zusammen (+) oder auseinander (−)
@export_range(-1.0, 1.0, 0.01) var beine_zusammen := 0.0
## Knie mehr oder weniger beugen
@export_range(-2.0, 2.0, 0.01) var unterschenkel := 0.0
## Oberkörper vor/zurück
@export_range(-1.0, 1.0, 0.01) var oberkoerper := 0.0
## Figur beim Sitzen höher/tiefer (Meter)
@export_range(-0.4, 0.4, 0.005) var hoehe := 0.0
