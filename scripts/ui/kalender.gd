extends CanvasLayer
## Festkalender (Taste K): die 16 Tage der Saison mit Sondertagen und
## geplanten Ereignissen (GameManager._plan), Bankraten, Hubers Wetttagen
## (ab Tag 3 jeder dritte) und dem Finale. Heute ist hervorgehoben, vergangene
## Tage sind blass. Aufbau: scenes/ui/kalender.tscn (16 Zellen „TagN").

const Texte := preload("res://scripts/ui/texte.gd")
const Wirtschaft := preload("res://scripts/wirtschaft.gd")

@export var zelle_normal: StyleBoxFlat

var _heute: StyleBoxFlat

func _ready() -> void:
	add_to_group("kalender")
	_heute = zelle_normal.duplicate() as StyleBoxFlat
	_heute.bg_color = Color(1.0, 0.85, 0.45, 0.85)
	_heute.border_color = Color(0.7, 0.25, 0.05, 1)
	_heute.set_border_width_all(4)

func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action("kalender") and event.is_action_pressed("kalender"):
		if visible:
			visible = false
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			zeigen()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()

func zeigen() -> void:
	var gm := get_parent()
	var z: Dictionary = gm._hud._zustand if "_hud" in gm and gm._hud else {}
	var plan: Array = z.get("plan", [])
	var tag_heute := Wirtschaft.saison_tag(int(z.get("day", 1)))
	var saison_start := int(z.get("day", 1)) - tag_heute + 1
	var raten := {}
	var faktor: float = [0.6, 1.0, 1.3][clampi(int(gm._schwierigkeit), 0, 2)] if "_schwierigkeit" in gm else 1.0
	if int(z.get("saison_nr", 1)) == 1:
		var offen: Array = z.get("bank_naechste", [])
		for r: Array in Wirtschaft.BANK_RATEN:
			if offen.is_empty() or int(r[0]) < int(offen[0]):
				continue   # schon bezahlt
			raten[int(r[0])] = roundi(float(r[1]) * faktor / 100.0) * 100
	%Titel.text = tr("KALENDER_TITEL") % int(z.get("saison_nr", 1))
	%Legende.text = tr("KALENDER_LEGENDE")
	for i in 16:
		var tag := i + 1
		var zelle := %Tage.get_child(i) as PanelContainer
		var ereignis := str(plan[i]) if i < plan.size() else ""
		var e_text := ""
		if ereignis != "":
			e_text = tr("EREIGNIS_%s_TITEL" % ereignis.to_upper())
		elif tag == 1:
			e_text = tr("KALENDER_ERSTER")
		zelle.get_node("Inhalt/Nummer").text = str(saison_start + i)
		zelle.get_node("Inhalt/Ereignis").text = e_text
		var extras: Array[String] = []
		if raten.has(tag):
			extras.append(tr("KALENDER_BANK") % Texte.euro(int(raten[tag])))
		if tag >= 3 and tag % 3 == 0:
			extras.append(tr("KALENDER_WETTE"))
		if tag == 16:
			extras.append(tr("KALENDER_DUELL"))
		zelle.get_node("Inhalt/Extras").text = "\n".join(extras)
		zelle.add_theme_stylebox_override("panel", _heute if tag == tag_heute else zelle_normal)
		zelle.modulate.a = 0.45 if tag < tag_heute else 1.0
	visible = true
