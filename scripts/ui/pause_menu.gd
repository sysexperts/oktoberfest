extends CanvasLayer
## Pausemenü, geöffnet mit ESC (über player.gd).
## Im Solo steht die Zeit still, im Koop läuft sie weiter — man kann ja nicht
## für alle anderen die Welt anhalten.
## Aufbau liegt in scenes/ui/pause.tscn.

const EINSTELLUNGEN_SZENE := "res://scenes/ui/einstellungen.tscn"

@onready var _fortsetzen: Button = %Fortsetzen
@onready var _zum_menue: Button = %ZumMenue
@onready var _koop_hinweis: Label = %KoopHinweis

var _einstellungen_offen := false

func _ready() -> void:
	visible = false
	_fortsetzen.pressed.connect(schliessen)
	%Einstellungen.pressed.connect(_on_einstellungen)
	_zum_menue.pressed.connect(_on_zum_menue)
	%Beenden.pressed.connect(_on_beenden)
	%TutorialSkip.pressed.connect(_on_tutorial_skip)
	%Einladen.pressed.connect(SteamDienst.freunde_einladen)
	%Hilfe.pressed.connect(func() -> void:
		var hilfe := get_parent().get_node_or_null("Hilfe")
		if hilfe:
			hilfe.oeffnen())

func ist_offen() -> bool:
	return visible

func oeffnen() -> void:
	if visible:
		return
	visible = true
	get_tree().paused = Net.solo
	_koop_hinweis.visible = not Net.solo
	var gm := get_parent()
	%TutorialSkip.visible = gm != null and gm.has_method("tutorial_active") and gm.tutorial_active()
	# Freunde einladen nur in einem Steam-Koop-Spiel
	%Einladen.visible = SteamDienst.aktiv and SteamDienst.lobby_id != 0
	# Wer den Spielstand hält (Solo oder Host), speichert beim Verlassen.
	_zum_menue.text = "PAUSE_SAVE_MENU" if multiplayer.is_server() else "PAUSE_LEAVE_MENU"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_fortsetzen.grab_focus()

func schliessen() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## Liegt in main.tscn hinter den Spielern, bekommt ESC also zuerst.
## Solange das Einstellungsmenü offen ist, schließt ESC nur das.
func _unhandled_input(event: InputEvent) -> void:
	if visible and not _einstellungen_offen and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		schliessen()

func _on_einstellungen() -> void:
	var menue := (load(EINSTELLUNGEN_SZENE) as PackedScene).instantiate()
	_einstellungen_offen = true
	menue.geschlossen.connect(_on_einstellungen_zu)
	add_child(menue)

func _on_einstellungen_zu() -> void:
	_einstellungen_offen = false
	_fortsetzen.grab_focus()

func _on_zum_menue() -> void:
	_speichern_falls_host()
	Net.zum_menue()

func _on_tutorial_skip() -> void:
	get_parent().net_skip_tutorial.rpc_id(1)
	schliessen()

func _on_beenden() -> void:
	_speichern_falls_host()
	get_tree().quit()

func _speichern_falls_host() -> void:
	var gm := get_parent()
	if multiplayer.is_server() and gm and gm.has_method("_save_game"):
		gm._save_game()
