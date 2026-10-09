extends Node
## Grafikstufe (Plan 4.4) — schaltet die teuren Dinge je nach Einstellung:
##   Niedrig: 90 Besucher, jedes dritte Kirmeslicht, kein Glow, Nebel, SSAO,
##            keine Farbkorrektur, harte Schatten, kein Detail-Shader, kein Bildfilter
##   Mittel:  200 Besucher, zwei von drei Lichtern, Glow, Nebel, Farbkorrektur,
##            weiche Schatten, Detail-Shader und Bildfilter, kein SSAO
##   Hoch:    alles, wie gebaut, dazu SSIL
## Kantenglättung: Niedrig keine, Mittel FXAA (rund 5 % GPU), Hoch MSAA 2× plus FXAA
## (rund 19 %). Ohne sie flimmern Kanten, an denen zwei Objekte zusammentreffen
## (Geländer an der Zeltwand, Treppenwangen), sobald sich die Kamera bewegt.
## Lichter blenden auf Niedrig/Mittel in der Ferne aus. Die Zeltbeleuchtung
## bleibt immer an — dort wird gespielt.
## Look „Stil“ (tools/look_test.tscn, Variante C): Farb-LUT in main.tscn,
## Detail-Shader als zweiter Durchgang auf Kirmes-, Zelt- und Tischmaterialien.
## Werte messen: tools/grafik_messen.tscn. Liegt als Knoten in main.tscn.

const BESUCHER := [24, 48, 80]
## Sichtweite der Kleinteile (scripts/sichtweite.gd) je Stufe: auf schwächerer Grafik früher ausblenden
const SICHT_FAKTOR := [0.4, 0.6, 0.75]
## Schattenstufen der Sonne: Niedrig eine, Mittel zwei, Hoch vier (Schatten zeichnen die Karte mehrfach neu)
const SCHATTEN_STUFEN := [DirectionalLight3D.SHADOW_ORTHOGONAL, DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS, DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS]
const SCHATTEN_WEITE := [50.0, 80.0, 0.0]
var _schatten_weite0 := -1.0
## Ab dieser Entfernung blenden Kirmeslichter aus (0 = nie)
const LICHT_AUSBLENDEN := [22.0, 32.0, 42.0]
const DETAIL := preload("res://assets/shader/detail.gdshader")
## Weiche Schatten der Sonne (Stufe Mittel/Hoch)
const SONNE_WINKEL := 1.2

@export var welt: NodePath = ^"../WorldEnvironment"
@export var menge: NodePath = ^"../Crowd"
@export var sonne: NodePath = ^"../Sun"
@export var bildfilter: NodePath = ^"../Bildfilter"
## Nur Lichter unterhalb dieses Knotens werden reduziert.
@export var kirmes: NodePath = ^"../Kirmes"
## Materialien unter diesen Knoten bekommen den Detail-Shader (Altstadt ausgenommen).
@export var detail_wurzeln: Array[NodePath] = [^"../Kirmes", ^"../Tent", ^"../Tables"]

var _lichter: Array[OmniLight3D] = []
var _detail_mats: Array[BaseMaterial3D] = []
var _detail: ShaderMaterial

func _ready() -> void:
	var wurzel := get_node_or_null(kirmes)
	if wurzel:
		for l in wurzel.find_children("*", "OmniLight3D", true, false):
			_lichter.append(l as OmniLight3D)
	_detail = ShaderMaterial.new()
	_detail.shader = DETAIL
	for pfad in detail_wurzeln:
		var w := get_node_or_null(pfad)
		if w == null:
			continue
		for m in w.find_children("*", "MeshInstance3D", true, false):
			if String(m.get_path()).contains("/Altstadt/"):
				continue
			var mi := m as MeshInstance3D
			if mi.mesh == null:
				continue
			for s in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(s) as BaseMaterial3D
				if mat and mat.next_pass == null and mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED \
						and not _detail_mats.has(mat):
					_detail_mats.append(mat)
	Einstellungen.geaendert.connect(anwenden)
	anwenden()

func anwenden() -> void:
	var stufe := clampi(Einstellungen.grafik, 0, 2)
	var we := get_node_or_null(welt) as WorldEnvironment
	if we and we.environment:
		we.environment.ssao_enabled = stufe >= 2
		we.environment.ssil_enabled = stufe >= 2
		we.environment.glow_enabled = stufe >= 1
		we.environment.fog_enabled = stufe >= 1
		# Farbkorrektur kostet einen ganzen Nachbearbeitungsschritt — gemessen
		# ~13 ms pro Bild auf integrierter Grafik, mehr als Glow und Nebel zusammen
		we.environment.adjustment_enabled = stufe >= 1
	# Kantenglättung: MSAA glättet Geometriekanten und Schnittlinien, FXAA den Rest
	var vp := get_viewport()
	# Anisotrope Filterung: Böden im flachen Blickwinkel (Dielen) flimmern sonst an den Fugen
	vp.anisotropic_filtering_level = [Viewport.ANISOTROPY_4X, Viewport.ANISOTROPY_8X, Viewport.ANISOTROPY_16X][stufe]
	vp.msaa_3d = Viewport.MSAA_2X if stufe >= 2 else Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if stufe >= 1 else Viewport.SCREEN_SPACE_AA_DISABLED
	var s := get_node_or_null(sonne) as DirectionalLight3D
	if s:
		s.light_angular_distance = SONNE_WINKEL if stufe >= 1 else 0.0
		s.directional_shadow_mode = SCHATTEN_STUFEN[stufe]
		if _schatten_weite0 < 0.0:
			_schatten_weite0 = s.directional_shadow_max_distance
		s.directional_shadow_max_distance = SCHATTEN_WEITE[stufe] if SCHATTEN_WEITE[stufe] > 0.0 else _schatten_weite0
	_sichtweiten(SICHT_FAKTOR[stufe])
	var f := get_node_or_null(bildfilter) as CanvasLayer
	if f:
		f.visible = stufe >= 1
	for mat in _detail_mats:
		mat.next_pass = _detail if stufe >= 1 else null
	var m := get_node_or_null(menge)
	if m and "max_visitors" in m:
		m.max_visitors = BESUCHER[stufe]
	for i in _lichter.size():
		var l := _lichter[i]
		# Fest nach Position in der Liste, damit immer dieselben an bleiben
		l.visible = stufe == 2 or (stufe == 1 and i % 3 != 2) or (stufe == 0 and i % 3 == 0)
		l.distance_fade_enabled = LICHT_AUSBLENDEN[stufe] > 0.0
		l.distance_fade_begin = LICHT_AUSBLENDEN[stufe]
		l.distance_fade_length = 10.0

## Sichtweiten der Kleinteile mit dem Faktor der Stufe skalieren (Ursprungswert steht in der Meta "vr0")
func _sichtweiten(faktor: float) -> void:
	var wurzel := get_node_or_null(kirmes)
	if wurzel == null:
		return
	for g in wurzel.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if gi.visibility_range_end <= 0.0 and not gi.has_meta("vr0"):
			continue
		if not gi.has_meta("vr0"):
			gi.set_meta("vr0", gi.visibility_range_end)
		gi.visibility_range_end = float(gi.get_meta("vr0")) * faktor

func lichter_gesamt() -> int:
	return _lichter.size()

func sichtbare_lichter() -> int:
	return _lichter.filter(func(l: OmniLight3D) -> bool: return l.visible).size()
