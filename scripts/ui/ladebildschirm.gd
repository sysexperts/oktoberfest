extends Control
## Ladebildschirm (Plan 4.3): lädt die Zielszene im Hintergrund, zeigt
## Fortschritt und einen Tipp und blendet dann über Schwarz um.
## Das Ziel setzt Net.wechsle_zu(). Aufbau: scenes/ui/ladebildschirm.tscn.

const Texte := preload("res://scripts/ui/texte.gd")
## Anzahl der Tipps LOAD_TIP_1 … LOAD_TIP_n in texte.csv
const TIPPS := 6
## So lange bleibt der Bildschirm mindestens stehen — sonst flackert der Tipp nur
const MIN_ANZEIGE := 0.8

var _ziel := ""
var _zeit := 0.0
var _fertig := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_ziel = Net.ziel_szene
	%Tipp.text = Texte.mit_tasten("LOAD_TIP_%d" % (randi() % TIPPS + 1))
	create_tween().tween_property(%Schwarz, "color:a", 0.0, 0.3)
	if _ziel == "" or ResourceLoader.load_threaded_request(_ziel) != OK:
		_abbrechen()

func _process(delta: float) -> void:
	if _fertig:
		return
	_zeit += delta
	var fortschritt := []
	var status := ResourceLoader.load_threaded_get_status(_ziel, fortschritt)
	if not fortschritt.is_empty():
		%Balken.value = float(fortschritt[0]) * 100.0
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			if _zeit >= MIN_ANZEIGE:
				_wechseln()
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_abbrechen()

func _wechseln() -> void:
	_fertig = true
	%Balken.value = 100.0
	var szene := ResourceLoader.load_threaded_get(_ziel) as PackedScene
	var tw := create_tween()
	tw.tween_property(%Schwarz, "color:a", 1.0, 0.25)
	tw.tween_callback(func() -> void: get_tree().change_scene_to_packed(szene))

## Laden ging schief — zurück ins Menü statt auf einem stehenden Bildschirm zu hängen.
func _abbrechen() -> void:
	_fertig = true
	push_error("Ladebildschirm: '%s' konnte nicht geladen werden." % _ziel)
	get_tree().change_scene_to_file.call_deferred(Net.MENU_SCENE)
