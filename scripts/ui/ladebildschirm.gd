extends Control
## Ladebildschirm (Plan 4.3): lädt die Zielszene im Hintergrund, zeigt
## Fortschritt und einen Tipp und blendet dann über Schwarz um.
## Das Ziel setzt Net.wechsle_zu(). Aufbau: scenes/ui/ladebildschirm.tscn.

const Texte := preload("res://scripts/ui/texte.gd")
## Anzahl der Tipps LOAD_TIP_1 … LOAD_TIP_n in texte.csv
const TIPPS := 6
## So lange bleibt der Bildschirm mindestens stehen — sonst flackert der Tipp nur
const MIN_ANZEIGE := 0.8
## Nach so vielen Sekunden kommt der nächste Tipp
const TIPP_WECHSEL := 4.5
## Prozent pro Sekunde, mit denen der Balken dem echten Wert nachläuft. Der
## Lader springt oft von 0 auf 100 — nachgezogen sieht man den Fortschritt.
const BALKEN_TEMPO := 190.0

var _ziel := ""
var _zeit := 0.0
var _fertig := false
var _anzeige := 0.0
var _tipp_zeit := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_ziel = Net.ziel_szene
	_naechster_tipp()
	create_tween().tween_property(%Schwarz, "color:a", 0.0, 0.3)
	if _ziel == "" or ResourceLoader.load_threaded_request(_ziel) != OK:
		_abbrechen()

func _naechster_tipp() -> void:
	%Tipp.text = Texte.mit_tasten("LOAD_TIP_%d" % (randi() % TIPPS + 1))
	%Tipp.modulate.a = 0.0
	create_tween().tween_property(%Tipp, "modulate:a", 1.0, 0.4)

func _process(delta: float) -> void:
	if _fertig:
		return
	_zeit += delta
	_tipp_zeit += delta
	if _tipp_zeit >= TIPP_WECHSEL:
		_tipp_zeit = 0.0
		_naechster_tipp()
	var fortschritt := []
	var status := ResourceLoader.load_threaded_get_status(_ziel, fortschritt)
	var soll := 0.0
	if not fortschritt.is_empty():
		soll = float(fortschritt[0]) * 100.0
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		soll = 100.0
	_anzeige = move_toward(_anzeige, soll, delta * BALKEN_TEMPO)
	%Balken.value = _anzeige
	%Prozent.text = "%d %%" % roundi(_anzeige)
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			# Erst wechseln, wenn der Balken auch sichtbar vollgelaufen ist
			if _zeit >= MIN_ANZEIGE and _anzeige >= 99.9:
				_wechseln()
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_abbrechen()

func _wechseln() -> void:
	_fertig = true
	%Balken.value = 100.0
	%Prozent.text = "100 %"
	var szene := ResourceLoader.load_threaded_get(_ziel) as PackedScene
	var tw := create_tween()
	tw.tween_property(%Schwarz, "color:a", 1.0, 0.25)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_packed(szene))

## Laden ging schief — zurück ins Menü statt auf einem stehenden Bildschirm zu hängen.
func _abbrechen() -> void:
	_fertig = true
	push_error("Ladebildschirm: '%s' konnte nicht geladen werden." % _ziel)
	get_tree().change_scene_to_file.call_deferred(Net.MENU_SCENE)
