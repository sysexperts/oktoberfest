class_name Figur
extends Node3D
## Eine Figur für NPCs: das Modell plus die Namen seiner Animationen.
##
## Jedes Modell benennt seine Animationen anders ("Walk" beim Bean, "Walking"
## bei character2). Die NPC-Skripte fragen deshalb hier nach Rollen — stehen,
## gehen, rennen, tanzen, sitzen — statt nach Namen.
##
## Neue Figur: scenes/figuren/<name>.tscn anlegen (Wurzel mit diesem Skript,
## das Modell als Kind), die Felder unten im Inspector ausfüllen und die Szene
## in scripts/figuren.gd eintragen. Namen prüfen mit tools/modell_info.gd.

## Stehanimation. Ist sie nur ein Einzelbild (T-Pose), idle_ist_standbild setzen.
@export var anim_stehen := "Idle"
## true: Das Modell hat keine echte Stehanimation. Dann wird die Laufanimation
## an einer ruhigen Stelle eingefroren und IdleMotion lässt die Figur atmen.
@export var idle_ist_standbild := false
## Bei Standbild: an dieser Stelle der Laufanimation stehen die Beine geschlossen.
@export var standbild_zeit := 0.25
@export var anim_gehen := "Walk"
@export var anim_rennen := "Run"
## Eine davon wird zufällig gewählt.
@export var anim_tanzen: PackedStringArray = ["Dance"]
## Sitzen mit Trinken. Leer = Gäste werden per Knochenpose hingesetzt.
@export var anim_sitzen := ""
## Gelegentliche Stehanimationen (Kopf kratzen …), zufällig gewählt.
@export var anim_extras: PackedStringArray = []
## So weit wird die Figur beim Sitzen angehoben (Bankhöhe).
@export var sitz_hoehe := 0.05

var anim: AnimationPlayer
var skelett: Skeleton3D

func _ready() -> void:
	var aps := find_children("*", "AnimationPlayer", true, false)
	if not aps.is_empty():
		anim = aps[0]
	var sks := find_children("*", "Skeleton3D", true, false)
	if not sks.is_empty():
		skelett = sks[0]
	if anim == null:
		return
	# Die importierten Animationen haben keine Schleife gesetzt
	var schleifen := [anim_stehen, anim_gehen, anim_rennen, anim_sitzen]
	schleifen.append_array(anim_tanzen)
	schleifen.append_array(anim_extras)
	for n in schleifen:
		if hat(n):
			anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR

func hat(name: String) -> bool:
	return anim != null and name != "" and anim.has_animation(name)

## Stehen: echte Stehanimation abspielen oder die Laufanimation einfrieren.
func stehen() -> void:
	if anim == null:
		return
	anim.active = true
	if idle_ist_standbild:
		if hat(anim_gehen):
			anim.play(anim_gehen)
			anim.seek(standbild_zeit, true)
			anim.speed_scale = 0.0
	elif hat(anim_stehen):
		_spiele(anim_stehen, 1.0)

## Nur bei Standbild nötig: das Skelett jedes Bild auf die Standpose setzen,
## damit die Idle-Bewegung darauf aufsetzt.
func pose_auffrischen() -> void:
	if idle_ist_standbild and anim and anim.current_animation == anim_gehen:
		anim.seek(standbild_zeit, true)

func gehen(tempo := 1.0) -> void:
	if hat(anim_gehen):
		_spiele(anim_gehen, tempo)

func rennen(tempo := 1.0) -> void:
	if hat(anim_rennen):
		_spiele(anim_rennen, tempo)
	else:
		gehen(tempo * 1.6)

## Spielt einen zufälligen Tanz. false, wenn die Figur keinen hat.
func tanzen(tempo := 1.0) -> bool:
	return _zufaellig_aus(anim_tanzen, tempo)

func extra() -> bool:
	return _zufaellig_aus(anim_extras, 1.0)

func kann_sitzen() -> bool:
	return hat(anim_sitzen)

func sitzen() -> void:
	if hat(anim_sitzen):
		_spiele(anim_sitzen, 1.0)

func braucht_idle_bewegung() -> bool:
	return idle_ist_standbild

func _zufaellig_aus(liste: PackedStringArray, tempo: float) -> bool:
	var da := Array(liste).filter(func(n: String) -> bool: return hat(n))
	if da.is_empty():
		return false
	_spiele(da.pick_random(), tempo)
	return true

## Wechselt nur, wenn nicht schon diese Animation läuft — und startet an einer
## zufälligen Stelle, damit nicht alle Figuren im Gleichschritt gehen.
func _spiele(name: String, tempo: float) -> void:
	anim.active = true
	if anim.current_animation != name:
		anim.play(name)
		anim.seek(randf() * anim.get_animation(name).length, true)
	anim.speed_scale = tempo
