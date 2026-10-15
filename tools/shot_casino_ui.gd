extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Alle Casino-Fenster durchspielen (Roulette, Blackjack, Würfel, Automat) → SHOT_DIR/casino_*.png, prüft Abbuchung und Auszahlung
##   SHOT_DIR=build/casino godot --path . res://tools/shot_casino_ui.tscn --resolution 1280x720
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var gm: Node
	var sp: Node3D
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
	func _bild(name: String) -> void:
		await _warten(0.35)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/casino_%s.png" % name)
	func _ding(art: String) -> Node3D:
		for n in get_tree().get_nodes_in_group("interactable"):
			if n.has_method("kasino_aktion") and str(n.get("art")) == art:
				return n
		return null
	func _hin(art: String) -> Node3D:
		var ziel := _ding(art)
		var vor := ziel.global_position + ziel.global_transform.basis.z * 1.8
		sp.global_position = Vector3(vor.x, 0.1, vor.z)
		sp.look_at(Vector3(ziel.global_position.x, 1.0, ziel.global_position.z), Vector3.UP)
		sp._head.rotation.x = -0.35
		await _warten(0.8)
		return ziel
	func _dialog_zu() -> void:
		var d := get_tree().get_first_node_in_group("dialog")
		if d and d.has_method("beenden"):
			d.beenden()
		await _warten(0.2)
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
		gm = await Spielstart.starten(self)
		if gm == null:
			return
		TranslationServer.set_locale("de")
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		sp = gm._players_nodes.get(1)
		var story: Node = gm.get_node("Story")
		gm._quest_step = gm.QUEST_COUNT
		story.kapitel_setzen(3)
		story.quests["2.6"] = {"z": "erfuellt"}
		await _warten(0.5)
		story.ereignis("wette_gewonnen")
		story.quests["3.2"] = {"z": "erfuellt"}
		story.quests["3.3"] = {"z": "erfuellt"}
		story.ereignis("saboteur_gefasst")
		Game.money = 5000
		gm._tarnung_stufe = 2
		gm._tarnung_an = true
		gm._casino_tag = gm._day
		gm._broadcast_meta()
		await _warten(1.0)
		var geld0: int = Game.money
		var fehler := 0
		var r := await _hin("roulette")
		r.kasino_aktion(sp)
		await _warten(0.6)
		var ui: Node = get_tree().get_first_node_in_group("roulette_ui")
		if not ui.aktiv:
			print("FEHLER: Roulette-Fenster nicht offen")
			fehler += 1
		await _bild("r_leer")
		ui._jeton_waehlen(100)
		for n in ["zahl_17", "zahl_17", "rot", "dutzend_0", "spalte_2", "zahl_0"]:
			ui._feld_geklickt(ui._felder.get_node(n))
		ui._jeton_waehlen(500)
		ui._feld_geklickt(ui._felder.get_node("schwarz"))
		await _warten(0.5)
		await _bild("r_gesetzt")
		if ui._summe() != 1100:
			print("FEHLER: Einsatzsumme %d statt 1100" % ui._summe())
			fehler += 1
		ui._zurueck()
		if ui._summe() != 600:
			print("FEHLER: Zurueck, Summe %d statt 600" % ui._summe())
			fehler += 1
		ui._jeton_waehlen(500)
		ui._feld_geklickt(ui._felder.get_node("schwarz"))
		ui._drehen()
		await _warten(0.4)
		var nach_einsatz: int = Game.money   # (kann die Belohnung der Quest „Rien ne va plus“ enthalten)
		if nach_einsatz > geld0 - 1100 + 400:
			print("FEHLER: Einsatz nicht abgebucht: %d statt %d" % [nach_einsatz, geld0 - 1100])
			fehler += 1
		await _warten(1.8)
		await _bild("r_kugel_laeuft")
		await _warten(2.6)
		await _bild("r_kugel_faellt")
		await _warten(3.0)
		await _bild("r_ergebnis")
		var zahl: int = ui.REIHENFOLGE[ui._ziel]
		var erwartet := 0
		for w in ui._letzte:
			erwartet += gm.roulette_auszahlung(w, zahl)
		await _warten(2.0)
		print("Zahl %d, Auszahlung erwartet %d, Geld %d (Start %d)" % [zahl, erwartet, Game.money, geld0])
		if Game.money != nach_einsatz + erwartet and Game.money != nach_einsatz + erwartet + 300:   # +300: Questbelohnung kommt zeitversetzt
			print("FEHLER: Auszahlung falsch")
			fehler += 1
		if ui._gesperrt:
			print("FEHLER: Fenster bleibt gesperrt")
			fehler += 1
		ui._wiederholen()
		await _bild("r_wiederholt")
		print("Roulette: ", "OK" if fehler == 0 else "%d Fehler" % fehler)
		ui.beenden()
		await _warten(0.4)
		# --- Blackjack
		var bj_ui: Node
		var b := await _hin("blackjack")
		b.kasino_aktion(sp)
		await _warten(0.5)
		bj_ui = get_tree().get_first_node_in_group("blackjack_ui")
		if not bj_ui.aktiv:
			print("FEHLER: Blackjack-Fenster nicht offen")
			fehler += 1
		await _bild("b_leer")
		bj_ui._jeton_gedrueckt(100)
		bj_ui._jeton_gedrueckt(50)
		var vor_bj: int = Game.money
		bj_ui._austeilen()
		await _warten(0.4)
		if Game.money > vor_bj - 150 + 400:
			print("FEHLER: Blackjack-Einsatz nicht abgebucht")
			fehler += 1
		await _warten(2.6)
		await _bild("b_karten")
		var zuege := 0
		while bj_ui._runde and bj_ui.get_node("%Aktionen").visible and zuege < 3:
			if bj_ui.wert(bj_ui._sp.map(func(k): return k.code)) < 15:
				bj_ui._aktion(1)
			else:
				bj_ui._aktion(2)
			zuege += 1
			await _warten(2.2)
			await _bild("b_zug%d" % zuege)
		await _warten(4.0)
		await _bild("b_ende")
		await _warten(3.5)
		if bj_ui._runde or not gm._bj.is_empty():
			print("FEHLER: Blackjack-Runde nicht beendet")
			fehler += 1
		print("Blackjack: Geld vorher %d, nachher %d" % [vor_bj, Game.money])
		# erzwungener Blackjack für das Gewinnbild: Herz-Ass + Herz-König gegen Karo 8 + Karo 9
		Game.add_money(-100)
		gm._bj[1] = {"spieler": [1, 13], "bank": [21, 22], "einsatz": 100, "doppelt": false}
		var vor_bjw: int = Game.money
		gm._bj_ende(1)
		await _warten(3.6)
		await _bild("b_blackjack")
		await _warten(3.0)
		if Game.money != vor_bjw + 250:
			print("FEHLER: Blackjack zahlt nicht 3:2 (%d statt %d)" % [Game.money, vor_bjw + 250])
			fehler += 1
		bj_ui.beenden()
		await _warten(0.4)
		# --- Würfel
		var w := await _hin("wuerfel")
		w.kasino_aktion(sp)
		await _warten(0.5)
		var wu: Node = get_tree().get_first_node_in_group("wuerfel_ui")
		if not wu.aktiv:
			print("FEHLER: Würfel-Fenster nicht offen")
			fehler += 1
		await _bild("w_leer")
		wu._jeton_waehlen(100)
		wu._feld_geklickt(wu._felder.get_node("tief"))
		wu._feld_geklickt(wu._felder.get_node("sieben"))
		wu._jeton_waehlen(50)
		wu._feld_geklickt(wu._felder.get_node("pasch"))
		await _warten(0.4)
		await _bild("w_gesetzt")
		var vor_w: int = Game.money
		wu._drehen()
		await _warten(0.4)
		var nach_w: int = Game.money
		if nach_w > vor_w - 250 + 400:
			print("FEHLER: Würfel-Einsatz nicht abgebucht")
			fehler += 1
		await _warten(0.7)
		await _bild("w_schuettelt")
		await _warten(1.2)
		await _bild("w_wurf")
		await _warten(2.0)
		await _bild("w_ende")
		await _warten(3.0)
		var ab: Array = wu.letzter_wurf
		var erw_w := 0
		for e in [{"typ": "tief", "einsatz": 100}, {"typ": "sieben", "einsatz": 100}, {"typ": "pasch", "einsatz": 50}]:
			erw_w += gm.wuerfel_auszahlung(e, int(ab[0]), int(ab[1]))
		print("Würfel %d/%d: erwartet +%d, Geld %d -> %d" % [ab[0], ab[1], erw_w, nach_w, Game.money])
		if Game.money != nach_w + erw_w:
			print("FEHLER: Würfel-Auszahlung falsch")
			fehler += 1
		wu.beenden()
		await _warten(0.4)
		# --- Automat
		var s := await _hin("slot")
		s.kasino_aktion(sp)
		await _warten(0.5)
		var sl: Node = get_tree().get_first_node_in_group("slot_ui")
		if not sl.aktiv:
			print("FEHLER: Automat-Fenster nicht offen")
			fehler += 1
		await _bild("s_leer")
		sl._einsatz_waehlen(100)
		var vor_s: int = Game.money
		sl._drehen()
		await _warten(0.4)
		var nach_s: int = Game.money
		if nach_s > vor_s - 100 + 400:
			print("FEHLER: Automat-Einsatz nicht abgebucht")
			fehler += 1
		await _warten(1.2)
		await _bild("s_dreht")
		await _warten(2.2)
		await _bild("s_bremst")
		await _warten(3.0)
		await _bild("s_stop")
		await _warten(3.0)
		print("Automat: Auszahlung %d, Geld %d -> %d" % [sl.letzte_auszahlung, nach_s, Game.money])
		if Game.money != nach_s + sl.letzte_auszahlung:
			print("FEHLER: Automat-Auszahlung falsch")
			fehler += 1
		if sl._gesperrt:
			print("FEHLER: Automat bleibt gesperrt")
			fehler += 1
		# erzwungener Treffer: drei Sieben in der Mitte (Halt 0 auf jeder Walze) für das Gewinnbild
		sl._gesperrt = true
		var vor_sw: int = Game.money
		gm._slot_auswerten([[1, 5, 0], [1, 5, 0], [1, 5, 0]], [0, 0, 0], 100, 1)
		await _warten(4.2)
		await _bild("s_gewinn")
		await _warten(3.0)
		if Game.money != vor_sw - 100 + 1560:   # Mitte 3 Sieben x60, oben 3 Brezn x4, unten 3 Maß x14, je 20 € Linieneinsatz
			print("FEHLER: Automat zahlt nicht x60 (%d)" % Game.money)
			fehler += 1
		sl.beenden()
		await _warten(0.4)
		# --- Watten
		var wt := await _hin("watten")
		wt.kasino_aktion(sp)
		await _warten(0.5)
		var wa: Node = get_tree().get_first_node_in_group("watten_ui")
		if not wa.aktiv:
			print("FEHLER: Watten-Fenster nicht offen")
			fehler += 1
		await _bild("t_leer")
		wa._jeton_gedrueckt(100)
		var vor_wa: int = Game.money
		wa._austeilen()
		await _warten(3.6)
		await _bild("t_karten")
		var runden := 0
		while wa._runde and runden < 4:
			if runden == 0:
				wa._watten()
				await _warten(1.0)
				await _bild("t_gewattet")
			wa._hand_gedrueckt(wa._sichtbare()[0])
			await _warten(1.6)
			await _bild("t_stich%d" % runden)
			await _warten(2.2)
			runden += 1
		await _warten(1.6)
		await _bild("t_ende")
		if wa._runde:
			print("FEHLER: Watten-Runde nicht beendet")
			fehler += 1
		print("Watten: Geld vorher %d, nachher %d" % [vor_wa, Game.money])
		wa._tisch_leeren()
		wa.beenden()
		print("CASINO_UI: ", "OK" if fehler == 0 else "%d Fehler" % fehler)
		get_tree().quit()
