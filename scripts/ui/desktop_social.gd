extends Control
## Social-Media-App des Desktops: Bewertung und Beliebtheit des Zelts links, rechts der Feed mit Gästebeiträgen.
## Die Beiträge entstehen aus den echten Tageszahlen (GameManager.konto_verlauf: Wartezeiten, Beschwerden, Pfützen).
## Aufbau: scenes/ui/desktop_social.tscn, ein Beitrag ist scenes/ui/social_post.tscn.

const POST := preload("res://scenes/ui/social_post.tscn")
const AUTOREN := ["Lena", "Maximilian", "Sophie", "Jonas", "Hannah", "Felix", "Marie", "Lukas", "Anna", "Tobias", "Katrin", "Florian"]
const FARBEN := [Color(1, 0.62, 0.7), Color(0.6, 0.8, 1), Color(0.7, 0.95, 0.7), Color(1, 0.85, 0.5), Color(0.82, 0.7, 1), Color(0.6, 0.95, 0.9)]
const MAX_BEITRAEGE := 12

var _gm: Node
var _hud: Node
var _stand := ""

func einrichten(gm: Node, hud: Node) -> void:
	_gm = gm
	_hud = hud

func zeigen() -> void:
	_stand = ""
	_pruefen()

func _process(_delta: float) -> void:
	if visible:
		_pruefen()

func _pruefen() -> void:
	var verlauf: Array = _gm.get("konto_verlauf") if _gm != null else []
	var pop := roundi(float(_hud.get("_pop"))) if _hud != null else 0
	var z: Dictionary = _hud.get("_zustand") if _hud != null else {}
	var stand := "%d|%d|%s" % [pop, verlauf.size(), z.get("zelt_name", "")]
	if stand == _stand:
		return
	_stand = stand
	_anzeigen(verlauf, pop, str(z.get("zelt_name", "")))

## Sterne aus der Beliebtheit: 0 % = 1 Stern, 100 % = 5 Sterne
func _note(pop: int) -> float:
	return 1.0 + float(clampi(pop, 0, 100)) / 100.0 * 4.0

func _anzeigen(verlauf: Array, pop: int, zelt: String) -> void:
	%ZeltName.text = zelt if zelt != "" else tr("SOCIAL_ZELT_OHNE")
	var note := _note(pop)
	%Note.text = ("%.1f" % note).replace(".", ",") if TranslationServer.get_locale().begins_with("de") else "%.1f" % note
	%Sterne.setze(note)
	%Beliebt.value = pop
	for k in %Liste.get_children():
		k.queue_free()
	var beitraege := _beitraege(verlauf)
	%Leer.visible = beitraege.is_empty()
	for b: Dictionary in beitraege:
		var p := POST.instantiate()
		%Liste.add_child(p)
		p.setze(str(b.autor), tr("BANK_TAG") % int(b.tag), float(b.sterne), tr(str(b.text)), b.farbe)

## Aus den Tagesberichten Gästebeiträge machen (neueste zuerst)
func _beitraege(verlauf: Array) -> Array:
	var liste: Array = []
	for i in range(verlauf.size() - 1, -1, -1):
		var b: Dictionary = verlauf[i]
		var tag := int(b.get("day", 0))
		var arten: Array = _arten(b)
		for n in arten.size():
			var art: Array = arten[n]
			var h := tag * 7 + n * 5 + 3
			liste.append({
				"tag": tag, "sterne": float(art[1]), "autor": AUTOREN[h % AUTOREN.size()], "farbe": FARBEN[h % FARBEN.size()],
				"text": "SOCIAL_%s_%d" % [str(art[0]), h % 3 + 1],
			})
		if liste.size() >= MAX_BEITRAEGE:
			break
	return liste.slice(0, MAX_BEITRAEGE)

## [Art, Sterne] je Beitrag eines Tages: erst das auffälligste Problem, dann ein Gesamteindruck
func _arten(b: Dictionary) -> Array:
	var r: Array = []
	if int(b.get("served", 0)) < 5:
		return r
	if int(b.get("complaints", 0)) >= 3:
		r.append(["BESCHWERDEN", 1.0])
	if int(b.get("missed", 0)) >= 4:
		r.append(["WARTEN", 2.0])
	if int(b.get("urin", 0)) > 0 and r.size() < 2:
		r.append(["DRECK", 2.0])
	if r.is_empty():
		r.append(["GUT", 5.0] if int(b.get("complaints", 0)) == 0 and int(b.get("missed", 0)) <= 1 else ["MITTEL", 3.0])
		r.append(["GUT", 4.0] if int(b.get("complaints", 0)) == 0 else ["MITTEL", 3.0])
	return r
