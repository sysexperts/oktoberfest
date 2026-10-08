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
## Weitere Clips (Mixamo, "mixamo/…", tools/bake_animationen.gd): ab und zu statt der Sitzanimation (Klatschen, Rufen …) ...
@export var anim_sitz_extras: PackedStringArray = []
## ... Stehen mit Varianten (jede Figur bleibt bei einer gewählten) ...
@export var anim_stehen_varianten: PackedStringArray = []
## ... betrunken stehen, zusätzliche Torkelgänge ...
@export var anim_betrunken_stehen: PackedStringArray = []
@export var anim_betrunken_mehr: PackedStringArray = []
## ... und Tänze, die auf dem Boden vor der Bühne getanzt werden (statt auf dem Tisch)
@export var anim_tanzen_buehne: PackedStringArray = []
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
## Andere Farbtextur für eine Kleidungs-Variante (tools/bake_kleidung.gd backt
## sie aus der Originaltextur). Leer = Textur des Modells.
@export var textur: Texture2D
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
## Mixamo-Animationen, auf den Standardkörper umgerechnet (tools/bake_animationen.gd -- mixamo). Heißen "mixamo/<Name>",
## abspielen mit abspielen().
@export var mixamo_bibliothek: AnimationLibrary

## Aufrecht stehen und gehen: die gemeinsamen Clips lassen Oberkörper und Kopf
## hängen. Winkel in Grad (positiv = aufrichten), wirkt nur bei stehen/gehen.
@export var aufrichten_ruecken := 6.0
@export var aufrichten_nacken := 6.0
@export var aufrichten_kopf := 9.0
## Becken kippen (positiv = nach vorn aufrichten); die Oberschenkel bleiben dabei,
## wie sie sind. Beine: Oberschenkel zusätzlich neigen.
@export var aufrichten_huefte := 0.0
@export var aufrichten_beine := 0.0
## Oberarme nach außen drehen (Grad), bei jeder Animation: die Clips sind für
## schlankere Körper gemacht, die Arme laufen sonst durch den Rumpf. Beim Sitzen
## kommt arme_sitzen dazu (Trinken).
@export var arme_abspreizen := 10.0
## Schultern waagerecht richten, beim Stehen und Gehen (0 = aus, 1 = ganz)
@export_range(0.0, 1.0, 0.05) var aufrichten_waage := 1.0
@export var arme_sitzen := 8.0
## Hüftschwung beim Gehen und Rennen dämpfen (0 = aus, 1 = starr)
@export_range(0.0, 1.0, 0.05) var huefte_ruhig := 0.0
## Zusätzlich beim Extra (Kopf kratzen): die Hand soll neben dem Kopf landen, nicht darin
@export var arme_extra := 14.0
## Ellbogen öffnen (Grad), solange die Hand oben am Kopf ist (Kopf kratzen, Trinken)
@export var ellbogen_auf := 0.0
## Anteil der Korrektur beim Gehen (der Kopf hängt dort weniger)
@export_range(0.0, 1.0, 0.05) var aufrichten_gehen := 0.35

const Aufrichten := preload("res://scripts/aufrichten.gd")
var _aufrichten: SkeletonModifier3D

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
	if metall_ignorieren or eigenleuchten >= 0.0 or helligkeit != 1.0 or textur:
		_material_anpassen()
	var aps := find_children("*", "AnimationPlayer", true, false)
	if not aps.is_empty():
		anim = aps[0]
	var sks := find_children("*", "Skeleton3D", true, false)
	if not sks.is_empty():
		skelett = sks[0]
	_zubehoer_anlegen()
	if anim == null:
		return
	if leih_animationen or not leih_animationen_mehr.is_empty() or leih_bibliothek:
		_animationen_ausleihen()
	if mixamo_bibliothek and not anim.has_animation_library("mixamo"):
		anim.add_animation_library("mixamo", mixamo_bibliothek)
	_sitz_angleichen()
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

## Dieselbe Anpassung (Eigenleuchten, Metallic …) für später angehängte Teile, z. B. Kleidung aus dem
## Charakter-Creator (scripts/charakter_look.gd). Durchsichtiges (Brillengläser) bleibt unberührt.
func material_nachruesten(wurzel: Node) -> void:
	_material_anpassen(wurzel)

func _material_anpassen(wurzel: Node = null) -> void:
	var netze := (wurzel if wurzel else self).find_children("*", "MeshInstance3D", true, false)
	if wurzel is MeshInstance3D:
		netze.append(wurzel)
	for mi: MeshInstance3D in netze:
		for s in mi.mesh.get_surface_count():
			var original := mi.get_active_material(s) as BaseMaterial3D
			if original == null:
				continue
			if wurzel and original.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				continue
			var schluessel := [original, metall_ignorieren, eigenleuchten, helligkeit, textur]
			if not _angepasst.has(schluessel):
				var kopie := original.duplicate() as BaseMaterial3D
				if textur:
					kopie.albedo_texture = textur
				if helligkeit != 1.0:
					var c := kopie.albedo_color
					kopie.albedo_color = Color(c.r * helligkeit, c.g * helligkeit, c.b * helligkeit, c.a)
				if metall_ignorieren:
					kopie.metallic = 0.0
					kopie.metallic_texture = null
					kopie.metallic_specular = 0.3
				if eigenleuchten == 0.0:
					kopie.emission_enabled = false
				elif eigenleuchten > 0.0:
					kopie.emission_enabled = true
					# Ohne Farbtextur (Standardkörper) leuchtet die Grundfarbe selbst;
					# sonst würde das Leuchten die Figur einfarbig weiß färben
					kopie.emission = kopie.albedo_color if kopie.albedo_texture == null else Color.WHITE
					kopie.emission_texture = kopie.albedo_texture
					# Farbe × Textur. Steht ein Modell auf „Addieren" (charakter2),
					# ergibt Weiß + Textur eine einfarbig weiße Figur.
					kopie.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
					kopie.emission_energy_multiplier = eigenleuchten
				_angepasst[schluessel] = kopie
			mi.set_surface_override_material(s, _angepasst[schluessel])

## Hut, Bart & Co. (scenes/zubehoer/*.tscn): hängen am Kopfknochen und machen
## jede Bewegung mit. Die Lage steht als metadata/lage in der Zubehör-Szene
## (in Modellkoordinaten: y = Höhe, +z = vorn) — im Editor verschiebbar.
@export var zubehoer: Array[PackedScene] = []
## Das Zubehör ist auf den Kopf von character2 zugeschnitten. Andere Köpfe
## (größer, tiefer, weiter vorn) passen es hiermit an: wirkt auf jedes Teil
## vor dessen eigener Lage.
@export var zubehoer_anpassung := Transform3D()
## Zusätzliche Anpassung einzelner Teile (Index in `zubehoer` → Transform, wirkt vor deren Lage): der Creator
## vergrößert damit Hüte über Frisuren.
var zubehoer_extra := {}

func _zubehoer_anlegen() -> void:
	if zubehoer.is_empty() or skelett == null:
		return
	var b := -1
	for name: String in KNOCHEN_NAMEN["kopf"]:
		b = skelett.find_bone(name)
		if b >= 0:
			break
	if b < 0:
		return
	var halter := BoneAttachment3D.new()
	halter.name = "Zubehoer"
	skelett.add_child(halter)
	halter.bone_name = skelett.get_bone_name(b)
	# Wie die Haut selbst rechnen (Pose × Bindungsmatrix): die Bindung weicht bei
	# manchen Modellen von der Ruhelage ab — dann säße der Hut in Animationen daneben
	var bindung := skelett.get_bone_global_rest(b).affine_inverse()
	for mi: MeshInstance3D in skelett.find_children("*", "MeshInstance3D", false, false):
		if mi.skin == null:
			continue
		for i in mi.skin.get_bind_count():
			var bn := mi.skin.get_bind_name(i)
			var idx := mi.skin.get_bind_bone(i) if bn == "" else skelett.find_bone(bn)
			if idx == b:
				bindung = mi.skin.get_bind_pose(i) * mi.transform.affine_inverse()
				break
		break
	for nr in zubehoer.size():
		var szene: PackedScene = zubehoer[nr]
		if szene == null:
			continue
		var teil: Node3D = szene.instantiate()
		var lage: Transform3D = teil.get_meta("lage", Transform3D())
		halter.add_child(teil)
		teil.transform = bindung * zubehoer_anpassung * (zubehoer_extra.get(nr, Transform3D()) as Transform3D) * lage

func hat(name: String) -> bool:
	return anim != null and name != "" and anim.has_animation(name)

## Stehen: echte Stehanimation abspielen oder die Laufanimation einfrieren.
func stehen() -> void:
	if anim == null:
		return
	_haltung_an(true)
	anim.active = true
	if idle_ist_standbild:
		if hat(anim_gehen):
			anim.play(anim_gehen)
			anim.seek(standbild_zeit, true)
			anim.speed_scale = 0.0
	elif hat(anim_stehen):
		var n := _stehen_wahl()
		if n == anim_stehen:
			_spiele(anim_stehen, 1.0)
		else:
			abspielen(n)

var _stehen_name := ""
## Jede Figur steht mit einem festen Clip: meist dem Standard, manchmal einer Variante (Zwerg-Idle …)
func _stehen_wahl() -> String:
	if _stehen_name == "":
		_stehen_name = anim_stehen
		var m := Array(anim_stehen_varianten).filter(func(n: String) -> bool: return hat(n))
		if not m.is_empty() and randf() < 0.45:
			_stehen_name = m.pick_random()
	return _stehen_name

func kann_betrunken_stehen() -> bool:
	return Array(anim_betrunken_stehen).any(func(n: String) -> bool: return hat(n))

var _besoffen_stehen := ""
## Stehen mit Schwanken (Mixamo-Clips "drunk idle")
func stehen_betrunken() -> void:
	if _besoffen_stehen == "":
		var m := Array(anim_betrunken_stehen).filter(func(n: String) -> bool: return hat(n))
		_besoffen_stehen = m.pick_random() if not m.is_empty() else anim_stehen
	if _besoffen_stehen == anim_stehen:
		stehen()
	else:
		abspielen(_besoffen_stehen)

## Nur bei Standbild nötig: das Skelett jedes Bild auf die Standpose setzen,
## damit die Idle-Bewegung darauf aufsetzt.
func pose_auffrischen() -> void:
	if idle_ist_standbild and anim and anim.current_animation == anim_gehen:
		anim.seek(standbild_zeit, true)

func gehen(tempo := 1.0) -> void:
	_haltung_an(true, aufrichten_gehen)
	if hat(anim_gehen):
		_spiele(anim_gehen, tempo)

## Torkeln statt gehen — nur Figuren mit anim_betrunken können das.
func kann_torkeln() -> bool:
	return hat(anim_betrunken)

var _torkel_name := ""

func torkeln(tempo := 1.0) -> void:
	if not hat(anim_betrunken):
		gehen(tempo)
		return
	if _torkel_name == "":
		_torkel_name = anim_betrunken
		var m := Array(anim_betrunken_mehr).filter(func(n: String) -> bool: return hat(n))
		if not m.is_empty() and randf() < 0.5:
			_torkel_name = m.pick_random()
	_spiele(_torkel_name, tempo)

func rennen(tempo := 1.0) -> void:
	if hat(anim_rennen):
		_spiele(anim_rennen, tempo)
	else:
		gehen(tempo * 1.6)

## Spielt einen zufälligen Tanz. false, wenn die Figur keinen hat.
func tanzen(tempo := 1.0, buehne := false) -> bool:
	if buehne and Array(anim_tanzen_buehne).any(func(n: String) -> bool: return hat(n)):
		return _zufaellig_aus(anim_tanzen_buehne, tempo)
	return _zufaellig_aus(anim_tanzen, tempo)

func extra() -> bool:
	return _zufaellig_aus(anim_extras, 1.0)

func kann_sitzen() -> bool:
	return hat(anim_sitzen)

## Korrektur fürs Sitzen (z. B. Rock bei Lisa), eingestellt in
## scenes/werkzeuge/sitz_haltung.tscn. Leer = Sitzanimation unverändert.
@export var sitz_korrektur: SitzHaltung
var _sitz_mod: SitzKorrektur

func sitzen() -> void:
	if hat(anim_sitzen):
		_spiele(anim_sitzen, 1.0)
	_sitz_korrektur_an(true)
	_sitz_aktiv = hat(anim_sitzen) and not anim_sitz_extras.is_empty()
	_sitz_im_extra = false
	_sitz_zeit = randf_range(4.0, 12.0)
	set_process(_sitz_aktiv)

var _sitz_aktiv := false
var _sitz_im_extra := false
var _sitz_zeit := 0.0

## Wer sitzt, klatscht, ruft oder jubelt ab und zu (Mixamo-Clips) und trinkt dazwischen wie gewohnt
func _process(delta: float) -> void:
	if not _sitz_aktiv or anim == null:
		return
	_sitz_zeit -= delta
	if _sitz_zeit > 0.0:
		return
	if _sitz_im_extra:
		_sitz_im_extra = false
		_spiele(anim_sitzen, 1.0)
		_sitz_zeit = randf_range(6.0, 16.0)
	else:
		var m := Array(anim_sitz_extras).filter(func(n: String) -> bool: return hat(n))
		if m.is_empty():
			return
		_sitz_im_extra = true
		var n: String = m.pick_random()
		abspielen(n)
		_sitz_zeit = randf_range(2.5, 6.0)

## Mixamo-Sitzclips auf die Hüfthöhe und -lage der Sitzanimation bringen (sonst schweben oder versinken Figuren beim Wechsel)
func _sitz_angleichen() -> void:
	if anim == null or not hat(anim_sitzen) or anim_sitz_extras.is_empty():
		return
	var ref: Variant = _hueft_mittel(anim.get_animation(anim_sitzen))
	if ref == null:
		return
	for n in anim_sitz_extras:
		if not hat(n):
			continue
		var a := anim.get_animation(n)
		if a.has_meta("sitz_angeglichen"):
			continue
		var m: Variant = _hueft_mittel(a)
		if m == null:
			continue
		var diff: Vector3 = (ref as Vector3) - (m as Vector3)
		for t in a.get_track_count():
			if a.track_get_type(t) == Animation.TYPE_POSITION_3D and String(a.track_get_path(t)).ends_with(":Hips"):
				for k in a.track_get_key_count(t):
					a.track_set_key_value(t, k, (a.track_get_key_value(t, k) as Vector3) + diff)
		a.set_meta("sitz_angeglichen", true)

func _hueft_mittel(a: Animation) -> Variant:
	for t in a.get_track_count():
		if a.track_get_type(t) == Animation.TYPE_POSITION_3D and String(a.track_get_path(t)).ends_with(":Hips"):
			var summe := Vector3.ZERO
			var n := a.track_get_key_count(t)
			for k in n:
				summe += a.track_get_key_value(t, k) as Vector3
			return summe / maxf(n, 1.0)
	return null

func _sitz_korrektur_an(an: bool) -> void:
	if sitz_korrektur == null or skelett == null:
		return
	if _sitz_mod == null:
		if not an:
			return
		_sitz_mod = SitzKorrektur.new()
		_sitz_mod.name = "SitzKorrektur"
		_sitz_mod.haltung = sitz_korrektur
		skelett.add_child(_sitz_mod)
	_sitz_mod.active = an

## Höhe beim Sitzen: Grundwert der Figur plus Korrektur
func sitz_hoehe_gesamt() -> float:
	return sitz_hoehe + (sitz_korrektur.hoehe if sitz_korrektur else 0.0)

## Aufrichten-Modifier (scripts/aufrichten.gd) ans Skelett hängen und ein-/ausschalten
func _haltung_an(an: bool, staerke := 1.0, sitzend := false, extra := false, gehend := false) -> void:
	if skelett == null:
		return
	if _aufrichten == null:
		if not an:
			return
		_aufrichten = Aufrichten.new()
		_aufrichten.name = "Aufrichten"
		_aufrichten.figur = self
		skelett.add_child(_aufrichten)
	_aufrichten.ruecken = aufrichten_ruecken * staerke
	_aufrichten.nacken = aufrichten_nacken * staerke
	_aufrichten.kopf = aufrichten_kopf * staerke
	_aufrichten.huefte = aufrichten_huefte * staerke
	_aufrichten.waage = aufrichten_waage * staerke
	_aufrichten.huefte_ruhig = huefte_ruhig if gehend else 0.0
	_aufrichten.arme_hoch = arme_extra
	_aufrichten.ellbogen_auf = ellbogen_auf
	_aufrichten.arme = arme_abspreizen + (arme_sitzen if sitzend else 0.0)
	_aufrichten.beine = aufrichten_beine * staerke
	_aufrichten.active = an

func braucht_idle_bewegung() -> bool:
	return idle_ist_standbild

func _zufaellig_aus(liste: PackedStringArray, tempo: float) -> bool:
	var da := Array(liste).filter(func(n: String) -> bool: return hat(n))
	if da.is_empty():
		return false
	_spiele(da.pick_random(), tempo)
	return true

## Animationen, die nur Männer bekommen (Frauen im Dirndl: der Rock macht sie nicht mit)
const NUR_MAENNER := ["mixamo/flair_2"]

## Eine beliebige Animation abspielen (z. B. "mixamo/Sitting_Drinking"). Gibt false zurück, wenn es sie nicht gibt.
## Dauerschleifen starten an einer zufälligen Stelle, einmalige Bewegungen am Anfang.
func abspielen(name: String, tempo := 1.0) -> bool:
	if not hat(name):
		return false
	# Bewegungen, die ein Rock nicht mitmacht (Überschläge …): nur für Männer
	if name in NUR_MAENNER and str(get_meta("geschlecht", "m")) == "w":
		return false
	anim.active = true
	if not name in anim_sitz_extras:
		_sitz_aktiv = false
		set_process(false)
	# Mixamo-Clips sind schon auf unsere Körperform gerechnet (Arme/Kopf, tools/bake_animationen.gd): kein Aufrichten darüber.
	# Die älteren Clips behalten die Arm-Korrektur des Aufrichten-Modifiers.
	_haltung_an(not name.begins_with("mixamo/"), 0.0, false, true, false)
	_sitz_korrektur_an(false)
	anim.root_motion_track = NodePath()
	if anim.current_animation != name:
		anim.play(name)
		if anim.get_animation(name).loop_mode != Animation.LOOP_NONE:
			anim.seek(randf() * anim.get_animation(name).length, true)
	anim.speed_scale = tempo
	return true

## Wechselt nur, wenn nicht schon diese Animation läuft — und startet an einer
## zufälligen Stelle, damit nicht alle Figuren im Gleichschritt gehen.
func _spiele(name: String, tempo: float) -> void:
	if name.begins_with("mixamo/"):
		if abspielen(name, tempo):
			# Tänze: die Hüftbewegung zählt nicht (wie bei den alten Tänzen), sonst wandert die Figur über den Tisch
			anim.root_motion_track = _hueft_spur(name) if (name in anim_tanzen or name in anim_tanzen_buehne) else NodePath()
		return
	if name != anim_sitzen:
		_sitz_aktiv = false
		set_process(false)
	anim.active = true
	# Arme gelten bei jeder Animation, Rücken/Kopf nur beim Stehen und Gehen
	var staerke := 1.0 if name == anim_stehen else (aufrichten_gehen if name == anim_gehen else 0.0)
	_haltung_an(true, staerke, name == anim_sitzen, name in anim_extras or name == anim_sitzen, name == anim_gehen or name == anim_rennen)
	if name != anim_sitzen:
		_sitz_korrektur_an(false)
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
	"huefte": ["Hips", "mixamorig_Hips"],
	"wirbel_unten": ["Spine02", "mixamorig_Spine"],
	"wirbel_mitte": ["Spine01", "mixamorig_Spine1"],
	"wirbel_oben": ["Spine", "mixamorig_Spine2"],
	"nacken": ["neck", "mixamorig_Neck"],
	"kopf": ["Head", "mixamorig_Head"],
	"arm_l": ["LeftArm", "mixamorig_LeftArm"],
	"arm_r": ["RightArm", "mixamorig_RightArm"],
	"unterarm_l": ["LeftForeArm", "mixamorig_LeftForeArm"],
	"unterarm_r": ["RightForeArm", "mixamorig_RightForeArm"],
	"hand_r": ["RightHand", "mixamorig_RightHand"],
	"hand_l": ["LeftHand", "mixamorig_LeftHand"],
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

## Knochen so drehen, dass die Strecke zu seinem Kindknochen in `richtung` zeigt
## (Figur-Raum). Die Winkel jedes Modells sind verschieden — Zielrichtungen
## sehen auf jedem Rig gleich aus. Eltern müssen vorher gerichtet sein.
func _richte(rolle: String, kind_rolle: String, richtung: Vector3) -> void:
	var b := _knochen_index(rolle)
	var c := _knochen_index(kind_rolle)
	if b < 0 or c < 0:
		return
	skelett.set_bone_pose_rotation(b, skelett.get_bone_rest(b).basis.get_rotation_quaternion())
	var ist := skelett.get_bone_global_pose(c).origin - skelett.get_bone_global_pose(b).origin
	var skel_zu_figur := global_basis.orthonormalized().inverse() * skelett.global_basis.orthonormalized()
	var soll := skel_zu_figur.inverse() * richtung.normalized()
	var drehung := Quaternion(ist.normalized(), soll.normalized())
	var eltern := skelett.get_bone_parent(b)
	var eltern_rot := Quaternion.IDENTITY if eltern < 0 else skelett.get_bone_global_pose(eltern).basis.orthonormalized().get_rotation_quaternion()
	var jetzt := skelett.get_bone_global_pose(b).basis.orthonormalized().get_rotation_quaternion()
	skelett.set_bone_pose_rotation(b, eltern_rot.inverse() * drehung * jetzt)

func _knochen_index(rolle: String) -> int:
	for name: String in KNOCHEN_NAMEN.get(rolle, [rolle]):
		var b := skelett.find_bone(name)
		if b >= 0:
			return b
	return -1

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

## Zapfen am Fass: linke Hand hält den Krug vor den Hahn, die rechte zieht den
## Hebel immer wieder nach unten, der Oberkörper neigt sich leicht mit.
func zapf_pose(t: float) -> void:
	if skelett == null:
		return
	if anim:
		anim.active = false
	var zug := 0.5 + 0.5 * sin(t * 3.2)   # 0 = Hebel oben, 1 = ganz gezogen
	_knochen("arm_l", -0.85)
	_knochen("unterarm_l", -1.1)
	_knochen("arm_r", -0.95 - 0.35 * zug)
	_knochen("unterarm_r", -0.9 - 0.4 * zug)
	_knochen("wirbel_oben", 0.08 + 0.08 * zug)
	_knochen("nacken", 0.05)
	_knochen("kopf", 0.1 - 0.05 * zug)

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

## Tragehaltung (Fass/Karton vor der Brust) an- oder ausschalten. Liegt als
## SkeletonModifier3D über der Animation — die Beine laufen dabei weiter.
var _trage: TragePose

## art: 0 = Fass, 1 = Karton (eigene Armwinkel, siehe TragePose)
func trage_pose(an: bool, art := 0) -> void:
	if skelett == null:
		return
	if _trage == null:
		if not an:
			return
		_trage = TragePose.new()
		_trage.name = "TragePose"
		skelett.add_child(_trage)
	_trage.active = an
	_trage.art = art

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
