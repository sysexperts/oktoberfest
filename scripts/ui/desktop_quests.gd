extends Control
## Quests-App des Desktops: Kapitel, Hauptquest, laufende Aufträge, Angebote (annehmen oder ablehnen).
## Daten kommen von scripts/story/story.gd, der Server entscheidet (net_quest_annehmen/_ablehnen). Aufbau: desktop_quests.tscn.

const Daten := preload("res://scripts/story/daten.gd")
const ZEILE := preload("res://scenes/ui/quest_zeile.tscn")

var _gm: Node
var _story: Node

func einrichten(gm: Node, story: Node) -> void:
	_gm = gm
	_story = story

func _titel(id: String) -> String:
	var q := Daten.quest(id)
	var t := tr(str(q.get("titel", "")))
	return t if t != str(q.get("titel", "")) else "%s (%s)" % [tr("QUESTS_QUEST"), id]

func _text(id: String) -> String:
	var q := Daten.quest(id)
	var k := str(q.get("text", ""))
	for v in [k + ("_IHR" if multiplayer.get_peers().size() > 0 else "_DU"), k + "_DU", k]:
		var t := tr(v)
		if t != v:
			return t
	return ""

func _frist(id: String) -> String:
	var rest := int((_story.quests.get(id, {}) as Dictionary).get("rest", 0))
	return tr("QUESTS_FRIST") % rest if rest > 0 else ""

func _leeren(knoten: Node) -> void:
	for k in knoten.get_children():
		k.queue_free()

func _zeile(ziel: Node, id: String, angebot: bool) -> void:
	var z := ZEILE.instantiate()
	ziel.add_child(z)
	z.setze(id, _titel(id), _text(id), _frist(id), angebot, _story.platz_frei(str(Daten.quest(id).get("typ", "neben"))))
	if angebot:
		z.angenommen.connect(func() -> void: _gm.net_quest_annehmen.rpc_id(1, id))
		z.abgelehnt.connect(func() -> void: _gm.net_quest_ablehnen.rpc_id(1, id))

func zeigen() -> void:
	if _story == null:
		return
	_leeren(%Haupt)
	_leeren(%Auftraege)
	_leeren(%Angebote)
	%Kapitel.text = tr("QUESTS_KAPITEL") % int(_story.kapitel)
	var haupt: String = _story.haupt_offen()
	if haupt != "":
		_zeile(%Haupt, haupt, false)
	var andere: Array = _story.offene(false)
	for id: String in andere:
		_zeile(%Auftraege, id, false)
	var angebote: Array = _story.angebote()
	for id: String in angebote:
		_zeile(%Angebote, id, true)
	%AuftraegeTitel.visible = not andere.is_empty()
	%AngeboteTitel.visible = not angebote.is_empty()
	%Leer.visible = haupt == "" and andere.is_empty() and angebote.is_empty()
	var erledigt := 0
	for id: String in _story.quests:
		if _story.zustand(id) == "erfuellt":
			erledigt += 1
	%Erledigt.text = tr("QUESTS_ERLEDIGT") % erledigt
