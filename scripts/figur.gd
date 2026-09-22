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
## Betrunken torkeln — wird statt anim_gehen benutzt, wenn ein Gast zu viel
## hat (scripts/customer.gd). Leer = die Figur torkelt nicht, sie geht normal.
@export var anim_betrunken := ""
## So weit wird die Figur beim Sitzen angehoben (Bankhöhe).
@export var sitz_hoehe := 0.05
## Metallic-Anteil des Modells ignorieren. Manche Modelle bringen eine gebackene
## Metallic-Karte mit — dann spiegelt die Figur nur die Umgebung und wirkt in
## dunklen Räumen (Zelt bei Nacht) schwarz. Stoff und Haut sind nicht metallisch.
@export var metall_ignorieren := false
## Eigenleuchten mit der Farbtextur, damit alle Figuren im Zelt gleich hell
## wirken. -1 = so lassen, wie das Modell es mitbringt; 0 = aus.
## Der Bean bringt volles Eigenleuchten mit und strahlte deshalb weiß.
@export var eigenleuchten := -1.0
## Grundfarbe aufhellen (1 = unverändert) — für Modelle, bei denen Eigenleuchten
## die Textur nicht übernimmt und die Figur nur weiß färben würde (character2).
@export var helligkeit := 1.0
## Animationen eines anderen Modells mitbenutzen — nur sinnvoll bei gleichem
## Skelett (gleiche Knochennamen, Pfad Armature/Skeleton3D). Die geliehenen
## Animationen heißen dann "geliehen/<Name>".
@export var leih_animationen: PackedScene
## Weitere Quellen für geliehene Animationen (Alex: jede Animation in einer
## eigenen Datei). Heißen dann "geliehen2/<Name>", "geliehen3/<Name>" …
@export var leih_animationen_mehr: Array[PackedScene] = []
## Fertig umgerechnete Bibliothek (tools/bake_alex_animationen.gd) — für Modelle
## mit anderem Skelett, bei denen Ausleihen nicht geht. Heißt "geliehen/<Name>".
@export var leih_bibliothek: AnimationLibrary

const LEIH_BIBLIOTHEK := "geliehen"

## Geliehene Animationsbibliotheken je Quellmodell — einmal geladen, von allen
## Figuren geteilt.
static var _leih_bibliotheken := {}

## Angepasste Materialien, geteilt von allen Figuren desselben Modells — eine
## Kopie pro Figur würde bei Hunderten Besuchern die Zeichenaufrufe vervielfachen.
static var _angepasst := {}

var anim: AnimationPlayer
var skelett: Skeleton3D

func _ready() -> void:
	if metall_ignorieren or eigenleuchten >= 0.0 or helligkeit != 1.0:
		_material_anpassen()
	var aps := find_children("*", "AnimationPlayer", true, false)
	if not aps.is_empty():
		anim = aps[0]
	var sks := find_children("*", "Skeleton3D", true, false)
	if not sks.is_empty():
		skelett = sks[0]
	if anim == null:
		return
	if leih_animationen or not leih_animationen_mehr.is_empty() or leih_bibliothek:
		_animationen_ausleihen()
	# Die importierten Animationen haben keine Schleife gesetzt
	var schleifen := [anim_stehen, anim_gehen, anim_rennen, anim_sitzen, anim_betrunken]
	schleifen.append_array(anim_tanzen)
	schleifen.append_array(anim_extras)
	for n in schleifen:
		if hat(n):
			anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR

func _animationen_ausleihen() -> void:
	# Mehrere Quellen: Alex bringt jede Animation in einer eigenen Datei mit,
	# jede mit demselben Skelett. Jede Quelle bekommt eine eigene Bibliothek.
	if leih_bibliothek and not anim.has_animation_library(LEIH_BIBLIOTHEK):
		anim.add_animation_library(LEIH_BIBLIOTHEK, leih_bibliothek)
	var quellen: Array[PackedScene] = []
	if leih_animationen:
		quellen.append(leih_animationen)
	for s: PackedScene in leih_animationen_mehr:
		if s:
			quellen.append(s)
	for i in quellen.size():
		var quelle_szene: PackedScene = quellen[i]
		var pfad := quelle_szene.resource_path
		if not _leih_bibliotheken.has(pfad):
			var quelle := quelle_szene.instantiate()
			var aps := quelle.find_children("*", "AnimationPlayer", true, false)
			_leih_bibliotheken[pfad] = (aps[0] as AnimationPlayer).get_animation_library("") if not aps.is_empty() else null
			quelle.free()
		var bibliothek: AnimationLibrary = _leih_bibliotheken[pfad]
		# Erste Quelle heißt „geliehen", weitere „geliehen2", „geliehen3" … — ist
		# schon eine fertige Bibliothek da, rücken die Szenen einen Platz weiter.
		var nr := i + (1 if leih_bibliothek else 0)
		var name := LEIH_BIBLIOTHEK if nr == 0 else "%s%d" % [LEIH_BIBLIOTHEK, nr + 1]
		if bibliothek and not anim.has_animation_library(name):
			anim.add_animation_library(name, bibliothek)

func _material_anpassen() -> void:
	for mi: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var original := mi.get_active_material(s) as BaseMaterial3D
			if original == null:
				continue
			var schluessel := [original, metall_ignorieren, eigenleuchten, helligkeit]
			if not _angepasst.has(schluessel):
				var kopie := original.duplicate() as BaseMaterial3D
				if helligkeit != 1.0:
					var c := kopie.albedo_color
					kopie.albedo_color = Color(c.r * helligkeit, c.g * helligkeit, c.b * helligkeit, c.a)
				if metall_ignorieren:
					kopie.metallic = 0.0
					kopie.metallic_texture = null
					kopie.metallic_specular = 0.3
				# Ohne Farbtextur würde das Leuchten die Figur einfarbig weiß färben
				if eigenleuchten == 0.0 or (eigenleuchten > 0.0 and kopie.albedo_texture == null):
					kopie.emission_enabled = false
				elif eigenleuchten > 0.0:
					kopie.emission_enabled = true
					kopie.emission = Color.WHITE
					kopie.emission_texture = kopie.albedo_texture
					# Farbe × Textur. Steht ein Modell auf „Addieren" (charakter2),
					# ergibt Weiß + Textur eine einfarbig weiße Figur.
					kopie.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
					kopie.emission_energy_multiplier = eigenleuchten
				_angepasst[schluessel] = kopie
			mi.set_surface_override_material(s, _angepasst[schluessel])

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

## Torkeln statt gehen — nur Figuren mit anim_betrunken können das.
func kann_torkeln() -> bool:
	return hat(anim_betrunken)

func torkeln(tempo := 1.0) -> void:
	if hat(anim_betrunken):
		_spiele(anim_betrunken, tempo)
	else:
		gehen(tempo)

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
		# Tänze mit eingebauter Hüftbewegung (Bean-"Dance" wandert 1,26 m) würden
		# die Figur verschieben — Tänzer liefen über den Tisch. Die Hüftspur wird
		# beim Tanzen als Root Motion abgezweigt und damit nicht angewendet.
		anim.root_motion_track = _hueft_spur(name) if name in anim_tanzen else NodePath()
		anim.play(name)
		anim.seek(randf() * anim.get_animation(name).length, true)
	anim.speed_scale = tempo

## Pfad der Hüft-Positionsspur einer Animation (leer, wenn es keine gibt).
func _hueft_spur(name: String) -> NodePath:
	var a := anim.get_animation(name)
	for t in a.get_track_count():
		if a.track_get_type(t) == Animation.TYPE_POSITION_3D and String(a.track_get_path(t)).ends_with(":Hips"):
			return a.track_get_path(t)
	return NodePath()

## Verkäufer in den Essensbuden (scripts/karte.gd, Gruppe „nachtruhe"): nach
## Feierabend heim, morgens wieder da.
func nachtruhe(an: bool) -> void:
	visible = not an

# --------------------------------------------------------------------- Würgen
## Übergeben ohne eigene Animationsdatei: die Knochen werden selbst gestellt.
##
## Die Modelle heißen ihre Knochen unterschiedlich: Bean und character2/3 haben
## Spine02/Spine01/Spine/neck/Head, Alex kommt aus Meshy mit mixamorig_Spine/
## _Spine1/_Spine2/_Neck/_Head. Deshalb spricht der Code Rollen an und sucht
## sich den Knochen aus der ersten passenden Schreibweise (tools/modell_info.gd
## zeigt die Namen eines Modells).
##
## `heftig` ist der Takt des Würgens: 0 = Luft holen, 1 = voller Stoß. Damit
## sehen die eigene Sicht (scripts/player.gd) und die Figur denselben Rhythmus.
const KNOCHEN_NAMEN := {
	"wirbel_unten": ["Spine02", "mixamorig_Spine"],
	"wirbel_mitte": ["Spine01", "mixamorig_Spine1"],
	"wirbel_oben": ["Spine", "mixamorig_Spine2"],
	"nacken": ["neck", "mixamorig_Neck"],
	"kopf": ["Head", "mixamorig_Head"],
	"arm_l": ["LeftArm", "mixamorig_LeftArm"],
	"arm_r": ["RightArm", "mixamorig_RightArm"],
	"unterarm_l": ["LeftForeArm", "mixamorig_LeftForeArm"],
	"unterarm_r": ["RightForeArm", "mixamorig_RightForeArm"],
	"oberschenkel_l": ["LeftUpLeg", "mixamorig_LeftUpLeg"],
	"oberschenkel_r": ["RightUpLeg", "mixamorig_RightUpLeg"],
	"unterschenkel_l": ["LeftLeg", "mixamorig_LeftLeg"],
	"unterschenkel_r": ["RightLeg", "mixamorig_RightLeg"],
}
const KOTZ_KNOCHEN := ["wirbel_unten", "wirbel_mitte", "wirbel_oben", "nacken", "kopf",
	"arm_l", "arm_r", "unterarm_l", "unterarm_r",
	"oberschenkel_l", "oberschenkel_r", "unterschenkel_l", "unterschenkel_r"]

func kotz_pose(heftig: float) -> void:
	if skelett == null:
		return
	# Eine laufende Animation würde die Knochen jedes Bild überschreiben
	if anim:
		anim.active = false
	var h := clampf(heftig, 0.0, 1.0)
	# Oberkörper vornüber, mit jedem Stoß tiefer (Modelle sind 180° gebacken →
	# positiv um RIGHT ist vorwärts, geprüft mit einer Seitenansicht)
	_knochen("wirbel_unten", 0.16 + 0.13 * h)
	_knochen("wirbel_mitte", 0.22 + 0.15 * h)
	_knochen("wirbel_oben", 0.26 + 0.17 * h)
	_knochen("nacken", 0.18 + 0.22 * h)
	_knochen("kopf", 0.25 + 0.35 * h)
	# Arme nach vorn/unten, Ellbogen gebeugt — Hände Richtung Knie
	_knochen("arm_l", -0.45 - 0.2 * h)
	_knochen("arm_r", -0.45 - 0.2 * h)
	_knochen("unterarm_l", -0.35)
	_knochen("unterarm_r", -0.35)
	# Leicht in die Knie
	_knochen("oberschenkel_l", 0.30 + 0.12 * h)
	_knochen("oberschenkel_r", 0.30 + 0.12 * h)
	_knochen("unterschenkel_l", -0.55 - 0.15 * h)
	_knochen("unterschenkel_r", -0.55 - 0.15 * h)

## Zurück in die Ruhelage und Animationen wieder laufen lassen.
## Alter Name, ruft pose_loesen() auf.
func kotz_pose_loesen() -> void:
	pose_loesen()


## Knochen zu einer Rolle aus KNOCHEN_NAMEN drehen. Kennt das Modell keine der
## Schreibweisen, passiert nichts — dann fehlt eben dieser Teil der Pose.
func _knochen(rolle: String, winkel: float, achse := Vector3.RIGHT) -> void:
	var b := -1
	for name: String in KNOCHEN_NAMEN.get(rolle, [rolle]):
		b = skelett.find_bone(name)
		if b >= 0:
			break
	if b < 0:
		return
	var rest := skelett.get_bone_rest(b).basis.get_rotation_quaternion()
	skelett.set_bone_pose_rotation(b, rest * Quaternion(achse, winkel))

# ---------------------------------------------------------------- Emote-Posen
## Winken, Jubeln, Posieren: auch dafür bringt kein Modell eine Animation mit,
## also werden die Knochen gestellt — wie beim Würgen. `t` ist die Zeit seit
## dem Start, damit die Pose lebt (Arm wedelt, Körper wippt).
## Gelöst wird alles zusammen mit kotz_pose_loesen().
const EMOTE_KNOCHEN := ["arm_l", "arm_r", "unterarm_l", "unterarm_r",
	"wirbel_oben", "nacken", "kopf", "oberschenkel_l", "oberschenkel_r",
	"unterschenkel_l", "unterschenkel_r"]

func winke_pose(t: float) -> void:
	if skelett == null:
		return
	if anim:
		anim.active = false
	# Rechter Arm hoch, die Hand wedelt hin und her
	_knochen_xz("arm_r", -1.95, -0.3)
	_knochen_xz("unterarm_r", -0.45, sin(t * 7.0) * 0.5)
	_knochen("arm_l", -0.15)
	_knochen("wirbel_oben", 0.05)
	_knochen("kopf", sin(t * 3.5) * 0.06)

func jubel_pose(t: float) -> void:
	if skelett == null:
		return
	if anim:
		anim.active = false
	# Beide Arme hoch, dabei leicht wippen
	var wippe := absf(sin(t * 4.0))
	_knochen_xz("arm_l", -1.75 - 0.2 * wippe, 0.4)
	_knochen_xz("arm_r", -1.75 - 0.2 * wippe, -0.4)
	_knochen("unterarm_l", -0.35)
	_knochen("unterarm_r", -0.35)
	_knochen("wirbel_oben", -0.12 - 0.08 * wippe)
	_knochen("kopf", -0.15)

func posen_pose(t: float) -> void:
	if skelett == null:
		return
	if anim:
		anim.active = false
	# Arme verschränkt, Gewicht auf einem Bein, ruhiges Atmen
	var atmen := sin(t * 1.6) * 0.03
	_knochen("arm_l", -0.95)
	_knochen("arm_r", -0.95)
	_knochen("unterarm_l", -1.75)
	_knochen("unterarm_r", -1.75)
	_knochen("wirbel_oben", 0.06 + atmen)
	_knochen("kopf", -0.05 + atmen)
	_knochen("oberschenkel_l", 0.12)
	_knochen("unterschenkel_l", -0.18)

## Hinsetzen ohne Sitzanimation: Beine angewinkelt, Oberkörper aufrecht.
func sitz_pose() -> void:
	if skelett == null:
		return
	if anim:
		anim.active = false
	_knochen("oberschenkel_l", 1.35)
	_knochen("oberschenkel_r", 1.35)
	_knochen("unterschenkel_l", -1.5)
	_knochen("unterschenkel_r", -1.5)
	_knochen("wirbel_oben", -0.05)
	_knochen("arm_l", -0.25)
	_knochen("arm_r", -0.25)

## Alle gestellten Knochen zurück in die Ruhelage.
func pose_loesen() -> void:
	if skelett == null:
		return
	for name: String in KOTZ_KNOCHEN:
		_knochen(name, 0.0)
	for name: String in EMOTE_KNOCHEN:
		_knochen(name, 0.0, Vector3.FORWARD)
		_knochen(name, 0.0)
	if anim:
		anim.active = true

## Knochen um zwei Achsen drehen: vor/zurück (RIGHT) und seitwärts (FORWARD).
## Zwei einzelne _knochen-Aufrufe gehen nicht — der zweite überschreibt den
## ersten, weil die Drehung immer von der Ruhelage aus gesetzt wird.
func _knochen_xz(rolle: String, vor: float, seit: float) -> void:
	var b := -1
	for name: String in KNOCHEN_NAMEN.get(rolle, [rolle]):
		b = skelett.find_bone(name)
		if b >= 0:
			break
	if b < 0:
		return
	var rest := skelett.get_bone_rest(b).basis.get_rotation_quaternion()
	skelett.set_bone_pose_rotation(b, rest * Quaternion(Vector3.RIGHT, vor) * Quaternion(Vector3.FORWARD, seit))
