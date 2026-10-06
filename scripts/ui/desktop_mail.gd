extends Control
## E-Mail-App des Desktops: Posteingang links, gewählte Mail rechts, darunter die Antworten.
## Der Server entscheidet (GameManager.net_post_antwort), hier wird nur angezeigt. Aufbau: scenes/ui/desktop_mail.tscn.

const Daten := preload("res://scripts/story/daten.gd")
const ZEILE := preload("res://scenes/ui/post_zeile.tscn")

var _gm: Node
var _story: Node
var _gewaehlt := -1

func einrichten(gm: Node, story: Node) -> void:
	_gm = gm
	_story = story
	for i in 3:
		(get_node("%%Antwort%d" % (i + 1)) as Button).pressed.connect(_antworten.bind(i))

## Ist ein Mehrspieler-Spiel? Dann gilt die Ihr-Form (Texte mit _IHR), sonst Du (_DU)
func _endung() -> String:
	return "_IHR" if _gm != null and multiplayer.get_peers().size() > 0 else "_DU"

## Text mit Du-/Ihr-Variante, sonst der Schlüssel selbst
func _text(schluessel: String) -> String:
	for k in [schluessel + _endung(), schluessel + "_DU", schluessel]:
		var t := tr(k)
		if t != k:
			return t
	return schluessel

func zeigen() -> void:
	if _story == null:
		return
	for k in %Liste.get_children():
		k.queue_free()
	var post: Array = _story.post
	%Leer.visible = post.is_empty()
	# Neueste oben
	for n in range(post.size() - 1, -1, -1):
		var m: Dictionary = post[n]
		var def := Daten.mail(str(m.id))
		var z := ZEILE.instantiate()
		%Liste.add_child(z)
		z.setze(tr("ABSENDER_" + str(def.get("absender", "SYSTEM"))), _text(str(def.get("betreff", ""))),
			tr("MAIL_TAG") % int(m.tag), not bool(m.gelesen), n == _gewaehlt)
		z.pressed.connect(_waehlen.bind(n))
	_anzeigen()

func _waehlen(nr: int) -> void:
	_gewaehlt = nr
	if _gm and not bool((_story.post[nr] as Dictionary).gelesen):
		_gm.net_post_gelesen.rpc_id(1, nr)
	zeigen()

func _anzeigen() -> void:
	var da: bool = _gewaehlt >= 0 and _gewaehlt < int(_story.post.size())
	%Lesen.visible = da
	%Nichts.visible = not da
	if not da:
		return
	var m: Dictionary = _story.post[_gewaehlt]
	var def := Daten.mail(str(m.id))
	%Betreff.text = _text(str(def.get("betreff", "")))
	%Von.text = "%s · %s" % [tr("ABSENDER_" + str(def.get("absender", "SYSTEM"))), tr("MAIL_TAG") % int(m.tag)]
	%Text.text = _text(str(def.get("text", "")))
	var antworten: Array = def.get("antworten", [])
	var gegeben := int(m.antwort)
	%AntwortenTitel.visible = not antworten.is_empty() and gegeben < 0
	for i in 3:
		var knopf := get_node("%%Antwort%d" % (i + 1)) as Button
		knopf.visible = i < antworten.size() and gegeben < 0
		if i < antworten.size():
			knopf.text = _text(str((antworten[i] as Dictionary).get("text", "")))
	%Beantwortet.visible = gegeben >= 0 and gegeben < antworten.size()
	if %Beantwortet.visible:
		%Beantwortet.text = tr("MAIL_BEANTWORTET") % _text(str((antworten[gegeben] as Dictionary).get("text", "")))

func _antworten(nr: int) -> void:
	if _gm and _gewaehlt >= 0:
		_gm.net_post_antwort.rpc_id(1, _gewaehlt, nr)
