class_name Fahrgeschaeft
extends Node3D
## Bewegt ein Fahrgeschäft aus dem Kirmes-Pack. Die Modelle bringen keine
## fertigen Animationen mit, haben aber alle einen sauber gesetzten Dreh-Knoten
## (z. B. "FerrisWheel_Rotate"). Den hängen wir hier an.
##
## Rein lokal — jeder Client rechnet es selbst, es geht nichts übers Netz.

enum Art {
	DREHEN,     ## läuft endlos rund (Karussell, Riesenrad)
	SCHAUKELN,  ## pendelt hin und her (Schiffschaukel, Top Spin)
	HEBEN,      ## fährt hoch und runter (Turm)
}

## Der Knoten, der sich bewegt. Leer = der erste Kindknoten.
@export var teil: NodePath
@export var art: Art = Art.DREHEN
## Drehachse im lokalen Raum. Riesenrad/Schaukel = Z, Karussell/Turm = Y.
@export var achse := Vector3(0, 1, 0)
## Grad pro Sekunde beim Drehen.
@export var tempo := 20.0
## Maximaler Ausschlag in Grad beim Schaukeln.
@export var ausschlag := 45.0
## Sekunden für eine volle Schaukel- bzw. Hub-Periode.
@export var dauer := 6.0
## Hubhöhe in Metern beim Heben.
@export var hub := 6.0
## Gondeln waagerecht halten (Riesenrad). Gilt für Kinder mit "Cabin" im Namen.
@export var gondeln_gerade := false
## Zusätzliche langsame Eigendrehung des Teils um Y (Turm, Wave).
@export var eigendrehung := 0.0

var _teil: Node3D
var _gondeln: Array[Node3D] = []
var _rest := Transform3D()
var _t := 0.0

func _ready() -> void:
	_teil = get_node_or_null(teil) as Node3D
	if _teil == null:
		_teil = _erstes_kind()
	if _teil == null:
		set_process(false)
		return
	_rest = _teil.transform
	if gondeln_gerade:
		for c in _teil.get_children():
			if c is Node3D and "Cabin" in String(c.name):
				_gondeln.append(c)
	# Damit nicht alle Fahrgeschäfte im Gleichschritt laufen.
	_t = randf() * dauer

func _erstes_kind() -> Node3D:
	for c in get_children():
		if c is Node3D:
			# Bei instanzierten FBX steckt das Modell noch eine Ebene tiefer.
			for e in c.get_children():
				if e is Node3D and ("Rotate" in String(e.name) or "Part" in String(e.name) \
						or "Seats" in String(e.name) or "Ship" in String(e.name)):
					return e
			return c
	return null

func _process(delta: float) -> void:
	_t += delta
	var a := achse.normalized()
	if a == Vector3.ZERO:
		a = Vector3.UP
	var winkel := 0.0
	var t := _rest
	match art:
		Art.DREHEN:
			winkel = deg_to_rad(tempo) * _t
			t = Transform3D(_rest.basis * Basis(a, winkel), _rest.origin)
		Art.SCHAUKELN:
			winkel = deg_to_rad(ausschlag) * sin(TAU * _t / maxf(dauer, 0.1))
			t = Transform3D(_rest.basis * Basis(a, winkel), _rest.origin)
		Art.HEBEN:
			# weiche Fahrt: hoch, oben kurz stehen, wieder runter
			var f := 0.5 - 0.5 * cos(TAU * _t / maxf(dauer, 0.1))
			t = _rest.translated_local(Vector3.UP * hub * f)
	if eigendrehung != 0.0:
		t.basis = t.basis * Basis(Vector3.UP, deg_to_rad(eigendrehung) * _t)
	_teil.transform = t
	# Gondeln gegenrechnen, damit sie waagerecht hängen bleiben.
	for g in _gondeln:
		g.basis = Basis(a, -winkel)
