extends Node
## Test für Phase 1: Solo-Start, Spieleraktionen, Pausemenü, Tastenbelegung.
## Sichert vorher Spielstand UND Einstellungen und stellt beide am Ende wieder
## her — der Test verändert nichts an deinem echten Stand.
## Aufruf: godot --headless --path . res://tools/test_phase1.tscn

const DATEIEN := ["user://oktoberfest_save.json", "user://saves/slot_1.json", "user://saves/slot_2.json",
	"user://saves/slot_3.json", "user://einstellungen.cfg", "user://karte.json"]

func _ready() -> void:
	# Der Szenenwechsel würde diesen Knoten freigeben — Testlauf an die Wurzel hängen.
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var fehler := 0
	## Pfad -> ob es die Datei vor dem Test gab
	var _gab_es := {}

	func _ready() -> void:
		# Muss auch weiterlaufen, während das Pausemenü den Baum anhält.
		process_mode = Node.PROCESS_MODE_ALWAYS
		_sichern()
		get_tree().create_timer(60.0).timeout.connect(_abbruch)
		Net.start_solo(true)
		await _frames(2)
		var zuerst: String = String(get_tree().current_scene.name) if get_tree().current_scene else ""
		await _warte_auf_spiel()
		_check("Ladebildschirm vor dem Spiel (4.3)", zuerst == "Ladebildschirm", zuerst)
		await _pruefen()
		_wiederherstellen()
		print("ERGEBNIS: %s (%d Fehler)" % ["BESTANDEN" if fehler == 0 else "FEHLGESCHLAGEN", fehler])
		get_tree().quit(0 if fehler == 0 else 1)

	func _pruefen() -> void:
		var gm := get_tree().current_scene
		_check("Spielszene geladen", gm != null and gm.has_method("net_book_tent"), str(gm))
		if gm == null or not gm.has_method("net_book_tent"):
			return
		_check("Offline-Peer aktiv", multiplayer.multiplayer_peer is OfflineMultiplayerPeer,
			multiplayer.multiplayer_peer.get_class())
		_check("Spieler gespawnt", gm.get_node("Players").get_child_count() >= 1, "")
		_check("Startgeld 1200", Game.money == 1200, "Geld=%d" % Game.money)

		print("  -- Spieleraktionen")
		var schild_vorher: Node = gm.get_node_or_null("ZeltVermietung")
		if schild_vorher:
			var titel: String = schild_vorher.get_node("%Titel").text
			_check("Mietschild übersetzt", titel != "SIGN_TENT_FOR_RENT" and titel == TranslationServer.translate("SIGN_TENT_FOR_RENT"), titel)
		# Keine rohen Schlüssel und keine alten türkischen Reste über den Objekten
		var roh := []
		for l: Node in gm.find_children("*", "Label3D", true, false):
			var t: String = (l as Label3D).text
			if t.begins_with("WORLD_") or t.begins_with("SIGN_") or t.contains("Molada") \
					or t.contains("Bardak") or t.contains("Fıçı") or t.contains("Yemek ("):
				roh.append("%s: %s" % [l.name, t.left(24)])
		_check("Weltbeschriftungen übersetzt", roh.is_empty(), str(roh))
		var wagen: Node3D = null
		for c in get_tree().get_nodes_in_group("interactable"):
			if c is Caravan:
				wagen = c
		_check("eigener Wohnwagen da", wagen != null, "")
		if wagen:
			var tuer: Vector3 = wagen.interact_point()
			# Grenze läuft innen an der Stadtmauer (scenes/kulisse/strassen.tscn, Radius 98 um 0/-8)
			var grenze := gm.get_node_or_null("Kirmes/Strassen/Stadtgrenze") as Node3D
			_check("Wohnwagen innerhalb der Kartengrenze", grenze != null and Vector2(tuer.x, tuer.z + 8.0).length() < 95.0,
				"Tür z=%.1f" % tuer.z)
			var kapsel := CapsuleShape3D.new()
			kapsel.radius = 0.35
			kapsel.height = 1.6
			var abfrage := PhysicsShapeQueryParameters3D.new()
			abfrage.shape = kapsel
			var vor_tuer: Vector3 = tuer + wagen.global_transform.basis.z * 0.5 + Vector3(0, 1.0, 0)
			abfrage.transform = Transform3D(Basis(), vor_tuer)
			var treffer: Array = gm.get_world_3d().direct_space_state.intersect_shape(abfrage, 8)
			_check("vor der Wohnwagentür ist Platz", treffer.is_empty(),
				str(treffer.map(func(t: Dictionary) -> String: return str(t.collider.name))))
		var stufe0: int = gm.get("_tent_stage")
		gm.net_book_tent.rpc_id(1)
		await _frames(5)
		_check("Zelt mieten kommt an", gm.get("_tent_stage") == stufe0 + 1, "")
		var schild := gm.get_node_or_null("ZeltVermietung")
		_check("Vermietungsschild nach dem Mieten weg", schild != null and not schild.visible
			and not schild.is_in_group("interactable"), str(schild))
		var tische0: int = gm.get("_active_count")
		gm.net_buy_table.rpc_id(1)
		await _frames(5)
		_check("Tisch kaufen kommt an", gm.get("_active_count") == tische0 + 1, "")

		print("  -- Hinweis am Fadenkreuz (2.2)")
		var spieler := gm.get_node("Players").get_child(0)
		var zapfhahn := gm.get_node("Stations/MugDispenser")
		var fass := gm.get_node("Stations/Keg1")
		spieler.carry_state = 0
		_check("Krugspender, Hände leer", spieler._hint_for(zapfhahn) == "HINT_TAKE_MUG", spieler._hint_for(zapfhahn))
		_check("Fass, Hände leer", spieler._hint_for(fass) == "HINT_NEED_MUG", spieler._hint_for(fass))
		spieler.carry_state = 1
		spieler.carry_fill = 0.2
		_check("Fass mit halbem Krug", spieler._hint_for(fass) == "HINT_TAP", spieler._hint_for(fass))
		_check("Krugspender mit Krug: nichts", spieler._hint_for(zapfhahn) == "", spieler._hint_for(zapfhahn))
		# Mehrere Krüge (Spaß-Plan 2.3)
		spieler.carry_state = 1
		spieler.carry_fill = 1.0
		spieler.carry_type = 2
		_check("voller Krug: noch einen nehmen", spieler._hint_for(zapfhahn) == "HINT_TAKE_ANOTHER" and spieler.kann_weiteren_krug(),
			spieler._hint_for(zapfhahn))
		spieler._krug_weglegen()
		spieler.carry_state = 1
		spieler.carry_fill = 1.0
		spieler.carry_type = 1
		spieler._krug_weglegen()
		spieler.carry_state = 1
		spieler.carry_fill = 1.0
		spieler.carry_type = 3
		_check("höchstens 3 Krüge", spieler.extra_kruege.size() == 2 and not spieler.kann_weiteren_krug(), str(spieler.extra_kruege))
		spieler.carry_state = 0
		spieler._naechster_krug_in_hand()
		_check("nächster Krug kommt in die Hand", spieler.carry_state == 1 and spieler.carry_type == 2
			and spieler.extra_kruege.size() == 1, "Sorte %d" % spieler.carry_type)
		spieler.extra_kruege.clear()
		spieler.carry_state = 0
		spieler.carry_fill = 0.0
		var hud := gm.get_node("HUD")
		Einstellungen.sprache = "de"
		Einstellungen.anwenden()
		hud.set_hint("HINT_TAKE_MUG")
		var hinweis: String = hud.get_node("%HinweisText").text
		_check("Hinweistext mit Taste", hinweis == "[E] Krug nehmen" and hud.get_node("%Hinweis").visible, hinweis)
		hud.set_hint("")
		_check("Hinweis ausgeblendet", not hud.get_node("%Hinweis").visible, "")

		print("  -- Wiesenbüro (2.4)")
		# Stand hier: Zelt gemietet, 1 Tisch, 500 € übrig, kein Bier im Lager
		hud.open_booking()
		await _frames(3)
		var buero: Control = hud.get_node("%Wiesenbuero")
		_check("Wiesenbüro offen", hud.is_booking_open() and buero.visible, "")
		var mieten: Node = buero.get_node("%ZeltMieten")
		_check("Zelt mieten: gesperrt, schon gemietet", mieten.knopf_node(0).disabled, mieten.knopf_node(0).text)
		var tisch: Node = buero.get_node("%TischStellen")
		_check("Tisch aufstellen: frei mit Preis", not tisch.knopf_node(0).disabled and tisch.knopf_node(0).text.contains("200"),
			tisch.knopf_node(0).text + " / " + tisch.grund_text())
		var klo: Node = buero.get_node("%Toilette")
		_check("Toilette: gesperrt mit Grund", klo.knopf_node(0).disabled and klo.grund_text() != "", klo.grund_text())
		var kellner: Node = buero.get_node("%Kellner")
		_check("Kellner aufstufen: gesperrt, niemand da", kellner.knopf_node(1).disabled, kellner.grund_text())
		buero.tutorial_schritt(3)   # nach dem Putzen: Tische
		_check("Tutorial hebt Tisch hervor", tisch.ist_hervorgehoben() and not mieten.ist_hervorgehoben(), "")
		var bier: Node = buero.get_node("%Bier")
		var lieferungen: int = gm._pending.size()
		bier.knopf_node(0).pressed.emit()
		await _frames(5)
		_check("Bier ×1 bestellen kommt an", gm._pending.size() == lieferungen + 1, "Lieferungen=%d" % gm._pending.size())
		_check("Bilanz ohne Schicht", buero.get_node("%BilanzText").text == "Noch keine Schicht gespielt.", buero.get_node("%BilanzText").text)
		hud.close_booking()
		_check("Wiesenbüro zu", not hud.is_booking_open(), "")

		print("  -- Meldungen (2.5)")
		var texte := preload("res://scripts/ui/texte.gd")
		var meldung: String = texte.meldung("MSG_NO_MONEY", ["OFFER_TOILET", {"euro": 1800}])
		_check("Meldung übersetzt, Betrag formatiert", meldung == "Zu wenig Geld für Toilette einbauen (1.800 €)", meldung)
		var popup_text: String = texte.meldung("POPUP_RESERVE", [{"euro": 40}])
		_check("Popup mit echten Zeilenumbrüchen", popup_text.contains("\n\n") and not popup_text.contains("\\n"), popup_text.left(30))
		var tipp_bilanz: String = texte.bilanz({"day": 3, "missed": 15, "kellner": false, "zapfer": false,
			"urin": 5, "toilet": false, "net": 120, "pop": 40})
		_check("Bilanz nennt Tipps (Kellner, Toilette)", tipp_bilanz.contains(TranslationServer.translate("TIPP_KELLNER"))
			and tipp_bilanz.contains(TranslationServer.translate("TIPP_TOILETTE")), tipp_bilanz.right(80))
		var stapel: Node = hud.get_node("%Meldungen")
		# Toilette (1.000 €) wäre per Dispo bezahlbar — Konto dafür kurz auf −800 €
		var geld_toilette: int = Game.money
		Game.add_money(-800 - Game.money)
		gm.net_buy_toilet.rpc_id(1)   # reicht nicht → Fehlermeldung beim Auslöser
		await _frames(3)
		Game.add_money(geld_toilette - Game.money)
		var letzte: String = stapel.get_child(stapel.get_child_count() - 1).text() if stapel.get_child_count() > 0 else ""
		_check("Server-Fehler landet übersetzt im Stapel", letzte.contains("Toilette einbauen"), letzte)
		for i in 6:
			hud.melde("MSG_EVENING")
		_check("höchstens 4 Meldungen gestapelt", stapel.get_child_count() == 4, str(stapel.get_child_count()))

		print("  -- Geführtes Tutorial (2.3)")
		gm._check_quest()
		_check("Schritt 2 (Zelt putzen) nach dem Mieten", gm._quest_step == 2, "Schritt=%d" % gm._quest_step)
		var marker := gm.get_node_or_null("Zielmarker")
		_check("Zielmarker in der Szene", marker != null, "")
		if marker:
			var ziel: Node = marker.ziel_suchen()
			_check("Marker zeigt auf Wiesnchef oder Dreck", ziel is Mess or (ziel != null and ziel.has_method("ist_wiesnchef")), str(ziel))
		# Der Haken für "Zelt mieten" darf noch sichtbar sein — Überspringen darf
		# nur keinen neuen auslösen.
		var haken_vorher: int = hud._erledigt_token
		gm.net_skip_tutorial.rpc_id(1)
		await _frames(5)
		_check("Überspringen beendet Tutorial", not gm.tutorial_active(), "Schritt=%d" % gm._quest_step)
		_check("Tutorialkarte weg (Karte zeigt Tagesziel/Schulden)", not hud.get_node("%Aufgabe").visible or not hud.get_node("%AufgabeSkip").visible, "")
		_check("kein Erledigt-Haken fürs Überspringen", hud._erledigt_token == haken_vorher,
			"%d -> %d" % [haken_vorher, hud._erledigt_token])
		if marker:
			_check("Marker ohne Ziel", marker.ziel_suchen() == null, "")

		print("  -- Hilfeseite (2.6)")
		var hilfe := gm.get_node_or_null("Hilfe")
		_check("Hilfe in der Szene", hilfe != null, "")
		if hilfe:
			_check("F1 ist Hilfe", _taste("help") == KEY_F1, OS.get_keycode_string(_taste("help")))
			hilfe.oeffnen()
			await _frames(2)
			_check("Hilfe offen, Solo pausiert", hilfe.visible and get_tree().paused, "")
			var zeilen: int = hilfe.get_node("%TastenListe").get_child_count()
			_check("alle Tasten gelistet", zeilen == (Einstellungen.STANDARD_TASTEN.size() + 2) * 2, str(zeilen))
			hilfe.schliessen()
			await _frames(2)
			_check("Hilfe zu, Pause aufgehoben", not hilfe.visible and not get_tree().paused, "")

		print("  -- Endlos (3.1)")
		gm._day = 16
		gm._phase = gm.Phase.SHIFT   # Tagesende gilt nur aus einer laufenden Schicht
		gm._end_shift(0)
		await _frames(3)
		_check("nach Tag 16 kommt Tag 17", gm._day == 17, "Tag=%d" % gm._day)
		_check("HUD zeigt Tag 1/16 der neuen Wiesn", String(hud.get_node("%Zeit").text).begins_with("Tag 1/16"), hud.get_node("%Zeit").text)
		_check("Wiesn nach dem Finale bewertet", gm._saison_nr >= 2 and int(gm._stats.saisons) >= 1
			and hud.is_popup_open(), "Wiesn %d" % gm._saison_nr)
		_check("Bewertung 1–5", gm.saison_wertung({"tage": 16, "netto": 16000, "pop_summe": 1500, "bedient": 900, "verpasst": 30}) == 5
			and gm.saison_wertung({"tage": 16, "netto": -500, "pop_summe": 300, "bedient": 100, "verpasst": 100}) == 1, "")
		_check("Nach Feierabend bleibt es Nacht bis zum Schlafen", gm._daylight_factor(-1.0) >= 1.0, "")
		hud.close_popup()
		gm._meilensteine.append("SAISON_1")   # Belohnung nicht in den Meilenstein-Test unten mischen

		print("  -- Meilensteine (3.2)")
		var geld_vorher: int = Game.money
		gm._stats["served"] = 100
		gm._pruefe_meilensteine()
		_check("erste Maß und 100 Bestellungen erreicht",
			gm._meilensteine.has("ERSTE_MASS") and gm._meilensteine.has("MASS_100"), str(gm._meilensteine))
		_check("Belohnung 50 + 300 €", Game.money - geld_vorher == 350, "%d" % (Game.money - geld_vorher))
		var geld_danach: int = Game.money
		gm._pruefe_meilensteine()
		_check("keine doppelte Belohnung", Game.money == geld_danach, "")
		_check("Errungenschaft ohne Steam: kein Absturz, nichts freigeschaltet",
			SteamDienst.errungenschaft("ERSTE_MASS") == false, "")
		gm._save_game()
		var gespeichert: Variant = JSON.parse_string(FileAccess.get_file_as_string(Net.speicherstand_pfad()))
		_check("Zähler und Meilensteine im Spielstand", gespeichert is Dictionary
			and (gespeichert.get("meilensteine", []) as Array).has("MASS_100")
			and int(gespeichert.get("stats", {}).get("served", 0)) == 100, "")
		hud.set_buero(gm._buero_state())
		var ziele: Node = hud.get_node("%Wiesenbuero").get_node("%ZieleListe")
		_check("Reiter Ziele listet alle", ziele.get_child_count() == gm.Meilensteine.LISTE.size(), str(ziele.get_child_count()))

		print("  -- Wirtschaft (3.4)")
		var w := preload("res://scripts/wirtschaft.gd")
		_check("Tag 1–5 mietfrei, Tag 6 zahlt", w.miete(120, 1) == 0 and w.miete(300, 5) == 0
			and w.miete(120, 6) == 132, str(w.miete(120, 6)))
		_check("Tag 1 unverändert", w.verkaufspreis(15, 1) == 15
			and w.paketpreis(40, 1) == 40 and is_equal_approx(w.geduld(38.0, 1), 38.0), "")
		_check("Tag 11: Ware +20 %", w.paketpreis(40, 11) == 48, str(w.paketpreis(40, 11)))
		_check("Kosten höchstens doppelt", w.miete(120, 500) == 240, str(w.miete(120, 500)))
		_check("Kosten steigen schneller als Preise", w.kosten_faktor(30) > w.preis_faktor(30), "")
		_check("Geduld nie unter 60 %", w.geduld(38.0, 999) >= 38.0 * 0.6 - 0.001, str(w.geduld(38.0, 999)))
		_check("Schonfrist: bis Tag 7 kein Beliebtheitsverlust", w.beliebtheit_verlust(7) == 0.0
			and w.beliebtheit_verlust(8) > 0.0, "")
		gm._saison_nr = 1   # Wiesn-Aufschlag separat geprüft
		_check("Miete im Spiel folgt dem Tag", gm._daily_rent() ==w.miete(int(gm.TENT_RENT[gm._tent_stage]), gm._day),
			"Tag %d, Miete %d" % [gm._day, gm._daily_rent()])

		print("  -- Bierpreis")
		var preis0: int = gm._reward_for(1)
		var raum0: Vector2 = gm.bierpreis_grenzen()
		_check("ohne Lizenz Preisspielraum 80–130 %", raum0.is_equal_approx(Vector2(0.8, 1.3)), str(raum0))
		gm.net_set_bierpreis.rpc_id(1, -5)
		await _frames(3)
		_check("Bierpreis bis zur unteren Grenze", is_equal_approx(gm._bierpreis, raum0.x), str(gm._bierpreis))
		_check("billig: weniger je Maß, mehr Andrang", gm._reward_for(1) < preis0 and w.preis_andrang(raum0.x) > 1.0,
			"%d -> %d" % [preis0, gm._reward_for(1)])
		gm.net_set_bierpreis.rpc_id(1, 2)
		await _frames(3)
		_check("Bierpreis zurück auf 100 %", is_equal_approx(gm._bierpreis, 1.0), str(gm._bierpreis))
		var lic_vorher: Dictionary = gm._lic.duplicate()
		gm._lic["weizen"] = true
		gm._lic["radler"] = true
		var raum2: Vector2 = gm.bierpreis_grenzen()
		_check("Lizenzen erweitern den Preisspielraum", raum2.x < raum0.x and raum2.y > raum0.y, str(raum2))
		gm._lic = lic_vorher

		print("  -- Tische, Zeltwand, Beliebtheit (Test 13.09.)")
		_check("drinnen/draußen erkannt", gm.im_zelt(Vector3(0, 0, 0)) and not gm.im_zelt(Vector3(0, 0, 20)), "")
		var tische_vorher: int = gm._active_count
		if gm._active_count < 2:
			gm._active_count = 2
			gm._apply_tent()
		if gm._beertables.size() >= 2:
			var tisch_a: Node3D = gm._beertables[0]
			var tisch_b: Node3D = gm._beertables[1]
			var lage_a := tisch_a.position
			tisch_a.position = tisch_b.position
			var verschoben: bool = gm._tisch_freistellen(0)
			_check("Tisch auf besetztem Platz rückt auf freien Platz", verschoben
				and tisch_a.position.distance_to(tisch_b.position) >= gm.TISCH_MINDESTABSTAND - 0.01, str(tisch_a.position))
			tisch_a.position = Vector3(-5.0, 0.0, -13.2)   # ins Rückwandregal gestellt
			gm._tisch_freistellen(0)
			_check("Tisch im Regal landet auf freier Zeltfläche",
				gm._tischplatz_frei(Vector2(tisch_a.position.x, tisch_a.position.z), 0), str(tisch_a.position))
			tisch_a.position = lage_a
			gm._rebuild_seats()
		if gm._active_count != tische_vorher:
			gm._active_count = tische_vorher
			gm._apply_tent()
		var pop_vorher: float = gm._popularity
		gm._popularity = gm._pop_grenze() - 0.5
		gm._pop_erhoehen(10.0)
		_check("Bedienen hebt Beliebtheit nur bis zur Grenze", is_equal_approx(gm._popularity, gm._pop_grenze())
			and gm._pop_grenze() < 100.0, "%.1f / Grenze %.1f" % [gm._popularity, gm._pop_grenze()])
		gm._popularity = pop_vorher

		print("  -- Einrichtung")
		Game.add_money(5000)
		var deko0: int = gm._einrichtung.size()
		gm.net_buy_einrichtung.rpc_id(1, "stehlampe")
		await _frames(5)
		_check("Stehlampe gekauft und aufgestellt", gm._einrichtung.size() == deko0 + 1
			and gm.get_node("Einrichtung").get_child_count() == deko0 + 1, str(gm._einrichtung.size()))
		if gm._einrichtung.size() > deko0:
			var did: int = gm._einrichtung.keys().max()
			var lampe: Node3D = gm._einrichtung_nodes[did]
			var sp: Node3D = gm.get_node("Players").get_child(0)
			_check("Hinweis Aufnehmen", sp._hint_for(lampe) == "HINT_MOVE_DECO", sp._hint_for(lampe))
			gm.net_move_einrichtung.rpc_id(1, did)
			await _frames(3)
			_check("Spieler trägt die Lampe", gm.haelt_einrichtung(sp.name.to_int()), str(gm._haelt_deko))
			_check("Hinweis Abstellen", sp._hint_for(lampe) == "HINT_PLACE_DECO", sp._hint_for(lampe))
			gm.net_rotate_einrichtung.rpc_id(1)
			sp.global_position = Vector3(40, 0.1, 40)   # weit außerhalb des Zelts
			await _frames(3)
			gm.net_move_einrichtung.rpc_id(1, did)
			await _frames(3)
			_check("abgestellt, gedreht, im Zelt geblieben", not gm.haelt_einrichtung(sp.name.to_int())
				and absf(lampe.rotation.y - PI / 4.0) < 0.01
				and lampe.position.x <= gm.ZELT_MAX.x + 0.01 and lampe.position.z <= gm.ZELT_MAX.z + 0.01, str(lampe.position))
			gm._save_game()
			var stand: Variant = JSON.parse_string(FileAccess.get_file_as_string(Net.speicherstand_pfad()))
			_check("Einrichtung und Bierpreis im Spielstand", stand is Dictionary
				and (stand.get("einrichtung", []) as Array).size() == gm._einrichtung.size()
				and stand.has("bierpreis"), "")
			var geld_vor: int = Game.money
			gm.net_move_einrichtung.rpc_id(1, did)
			await _frames(3)
			gm.net_sell_einrichtung.rpc_id(1)
			await _frames(3)
			_check("verkauft: weg und halber Preis zurück", not gm._einrichtung.has(did)
				and not gm._einrichtung_nodes.has(did) and Game.money - geld_vor == 45
				and not gm.haelt_einrichtung(sp.name.to_int()), "%d €" % (Game.money - geld_vor))

		print("  -- Zapfer und Ausgabe")
		Game.add_money(3000)
		gm._stock[gm.WARE_BIER] = 30
		gm.net_hire_staff(gm.ROLE_ZAPFER)
		var zapfer_da := false
		for st: Dictionary in gm._staff_sim.values():
			if int(st.role) == gm.ROLE_ZAPFER:
				zapfer_da = true
		_check("Zapfer eingestellt", zapfer_da, "")
		gm._ausgabe.clear()
		gm._phase = gm.Phase.SHIFT
		gm._phase_time = gm.SHIFT_TIME   # sonst endet der Tag im nächsten Frame und räumt die Ausgabe
		for k in 200:
			gm._update_staff(0.1)
		await _frames(3)
		_check("Zapfer stellt Krüge auf die Ausgabe", gm._ausgabe_gesamt(1) >= 3, str(gm._ausgabe))
		var ausgabe_knoten: Node = get_tree().get_first_node_in_group("ausgabe")
		_check("Ausgabe zeigt die Krüge", ausgabe_knoten != null and ausgabe_knoten.anzahl(1) == gm._ausgabe_gesamt(1),
			str(ausgabe_knoten.anzahl(1)) if ausgabe_knoten else "fehlt")
		var nehmer: Node3D = gm.get_node("Players").get_child(0)
		nehmer.carry_state = 0
		var auf_ausgabe: int = gm._ausgabe_gesamt(1)
		_check("Hinweis an der Ausgabe", nehmer._hint_for(ausgabe_knoten) == "HINT_AUSGABE_TAKE", nehmer._hint_for(ausgabe_knoten))
		gm.net_take_ausgabe.rpc_id(1)
		await _frames(3)
		_check("Spieler nimmt fertigen Krug", nehmer.carry_state == 1 and nehmer.carry_fill >= 1.0
			and gm._ausgabe_gesamt(1) == auf_ausgabe - 1, "carry=%d" % nehmer.carry_state)
		nehmer.carry_state = 0
		nehmer.carry_fill = 0.0
		gm._ausgabe.clear()
		gm._ausgabe_senden()

		print("  -- Ablegen, Aufheben, Zelt eröffnen (Test 13.09.)")
		nehmer.carry_state = 1
		nehmer.carry_type = 2
		nehmer.carry_fill = 0.5
		_check("ins Leere mit Krug: trinken oder abstellen", nehmer._hint_for(null) == "HINT_HAND_KRUG", nehmer._hint_for(null))
		nehmer._ablegen()
		await _frames(3)
		_check("Krug abgelegt statt gelöscht", nehmer.carry_state == 0 and gm._abgelegt.size() == 1
			and gm._abgelegt_nodes.size() == 1, "%d abgelegt" % gm._abgelegt.size())
		if not gm._abgelegt.is_empty():
			var ablage: int = gm._abgelegt.keys()[0]
			_check("Hinweis am abgelegten Krug", nehmer._hint_for(gm._abgelegt_nodes[ablage]) == "HINT_AUFHEBEN", "")
			gm.net_aufheben(ablage)
			await _frames(3)
			_check("Krug mit Sorte und Füllstand wieder aufgehoben", nehmer.carry_state == 1 and nehmer.carry_type == 2
				and is_equal_approx(nehmer.carry_fill, 0.5) and gm._abgelegt.is_empty(), "carry=%d" % nehmer.carry_state)
		nehmer.carry_state = 0
		nehmer.carry_fill = 0.0
		nehmer.carry_type = 0
		_check("Tasten Springen und Trinken vorhanden", InputMap.has_action("springen") and InputMap.has_action("trinken"), "")
		# Echte Tasteneingaben — Feedback 14.09.: Springen ging im Spiel nicht, obwohl
		# alle Prüfungen grün waren (sie drückten nie eine Taste)
		for k in 30:
			await get_tree().physics_frame
		var boden_y: float = nehmer.global_position.y
		Input.action_press("springen")
		await get_tree().physics_frame
		await get_tree().physics_frame
		Input.action_release("springen")
		var hoechste := boden_y
		for k in 20:
			await get_tree().physics_frame
			hoechste = maxf(hoechste, nehmer.global_position.y)
		_check("Leertaste: Spieler springt wirklich", hoechste > boden_y + 0.3, "%.2f → %.2f" % [boden_y, hoechste])
		for k in 60:
			await get_tree().physics_frame
		nehmer.carry_state = 1
		nehmer.carry_type = 1
		nehmer.carry_fill = 1.0
		nehmer.promille = 0.0
		Input.action_press("trinken")
		for k in 40:
			await get_tree().physics_frame
		Input.action_release("trinken")
		_check("G halten: Bier wird getrunken, Rausch steigt", nehmer.carry_fill < 0.9 and nehmer.promille > 0.05,
			"Füllung %.2f, Promille %.2f" % [nehmer.carry_fill, nehmer.promille])
		# Selbst getrunkenes Bier geht auch vom Lager ab — vorher kostete der
		# Zapfhahn für einen selbst nichts (Fehler vom 22.09.)
		gm._stock[1] = 5
		nehmer.carry_state = 1
		nehmer.carry_type = 1
		nehmer.carry_fill = 1.0
		nehmer._getrunken = 0.0
		nehmer.promille = 0.0
		Input.action_press("trinken")
		for k in 140:
			await get_tree().physics_frame
		Input.action_release("trinken")
		_check("selbst getrunken: eine Maß weniger im Lager", int(gm._stock[1]) == 4, str(gm._stock[1]))
		nehmer.promille = 0.0
		# Zu viel Bier: der Spieler übergibt sich, es liegt ein Fleck da und der
		# Rausch ist danach fast weg (scripts/player.gd, Feature 21.09.)
		var flecken_vorher: int = gm._messes.size()
		nehmer.promille = nehmer.KOTZ_GRENZE + 0.1
		nehmer.carry_fill = 0.0
		nehmer.carry_type = 0
		await get_tree().physics_frame
		_check("zu viel Promille: Spieler übergibt sich", nehmer.kotzt() and nehmer.emote == 2,
			"kotzt=%s emote=%d" % [str(nehmer.kotzt()), nehmer.emote])
		var stand_vorher: Vector3 = nehmer.global_position
		Input.action_press("move_forward")
		for k in 30:
			await get_tree().physics_frame
		Input.action_release("move_forward")
		_check("beim Übergeben bleibt man stehen", stand_vorher.distance_to(nehmer.global_position) < 0.3,
			"%.2f m" % stand_vorher.distance_to(nehmer.global_position))
		for k in 220:
			await get_tree().physics_frame
		_check("nach dem Übergeben liegt ein Fleck und der Rausch ist weg",
			gm._messes.size() > flecken_vorher and not nehmer.kotzt() and nehmer.promille <= nehmer.KOTZ_REST + 0.01,
			"Flecken %d → %d, Promille %.2f" % [flecken_vorher, gm._messes.size(), nehmer.promille])
		nehmer.promille = 0.0
		nehmer.carry_state = 1
		nehmer.carry_type = 1
		# Weg vom eigenen Fleck: sonst putzt der nächste E-Druck den, statt den
		# Krug abzulegen
		nehmer.global_position += Vector3(4.0, 0.0, 0.0)
		await _frames(3)
		var abgelegt_vorher: int = gm._abgelegt.size()
		nehmer.carry_fill = 1.0
		nehmer._current_target = null
		Input.action_press("interact")
		await get_tree().physics_frame
		await get_tree().physics_frame
		Input.action_release("interact")
		await _frames(3)
		_check("E mit Krug: abgelegt statt gelöscht", nehmer.carry_state == 0 and gm._abgelegt.size() == abgelegt_vorher + 1,
			"carry=%d, abgelegt %d" % [nehmer.carry_state, gm._abgelegt.size()])
		nehmer.carry_state = 0
		nehmer.carry_fill = 0.0
		nehmer.carry_type = 0
		nehmer.promille = 0.0
		gm._start_shift()
		var eroeffnung: Node3D = get_tree().get_first_node_in_group("zelt_eroeffnung")
		_check("nach Tagesstart ist das Zelt zu, Fass zum Anstechen da", not gm._zelt_offen and eroeffnung != null
			and eroeffnung.visible and eroeffnung.is_in_group("interactable"), "")
		gm.net_zelt_eroeffnen()
		await _frames(2)
		_check("Zelt eröffnet, Fass verschwindet", gm._zelt_offen and eroeffnung != null and not eroeffnung.visible, "")
		gm._zelt_offen = false
		gm._phase_time = gm.SHIFT_TIME * (1.0 - (10.5 - gm.DAY_START_HOUR) / (gm.DAY_END_HOUR - gm.DAY_START_HOUR))
		gm._shift_process(0.01)
		_check("um 10 Uhr öffnet das Zelt von selbst", gm._zelt_offen, "%.2f Uhr" % gm._clock_hour())
		gm._phase_time = gm.SHIFT_TIME

		print("  -- Ausgabe je Sorte, Bestellungen, Umriss, Lagerregale, Zelt-Etage (Test 13.09.)")
		gm._ausgabe.clear()
		var passt := 0
		for k in 5:
			if gm._ausgabe_hinzufuegen(1, 2):
				passt += 1
		_check("Stellplatz Weizen fasst 3 Krüge", passt == 3 and int(gm._ausgabe.get("1_2", 0)) == 3, str(gm._ausgabe))
		_check("anderer Platz bleibt frei", gm._ausgabe_hinzufuegen(1, 1), str(gm._ausgabe))
		await _frames(2)
		var ausgabe_neu: Node = get_tree().get_first_node_in_group("ausgabe")
		var sichtbar := 0
		if ausgabe_neu:
			for c in ausgabe_neu.get_node("Plaetze/Bier2").get_children():
				if c is Krug and c.visible:
					sichtbar += 1
		_check("Krüge stehen auf dem Weizen-Platz", sichtbar == 3, "%d sichtbar" % sichtbar)
		gm._ausgabe.clear()
		gm._ausgabe_senden()
		var hud_knoten: Node = gm.get_node("HUD")
		hud_knoten._bestellungen_neu()
		_check("Bestellübersicht ohne Bestellungen versteckt", not hud_knoten.get_node("%Bestellungen").visible, "")
		var umriss_ziel: Node3D = get_tree().get_first_node_in_group("ausgabe")
		nehmer._umriss_setzen(umriss_ziel, true)
		var mit_umriss := 0
		for mi in umriss_ziel.find_children("*", "MeshInstance3D", true, false):
			if (mi as MeshInstance3D).material_overlay != null:
				mit_umriss += 1
		nehmer._umriss_setzen(umriss_ziel, false)
		_check("Umriss auf dem anvisierten Objekt", mit_umriss > 0, "%d Meshes" % mit_umriss)
		var regale_vorher: int = gm._lagerregale().size()
		_check("Lagerkapazität je Regal", gm.lager_kapazitaet() == regale_vorher * Lager.KAPAZITAET, str(gm.lager_kapazitaet()))
		gm._phase = gm.Phase.INTERMISSION
		Game.add_money(2000)
		gm.net_buy_lagerregal()
		await _frames(3)
		_check("Lagerregal gekauft", gm._lagerregale().size() == regale_vorher + 1, "%d Regale" % gm._lagerregale().size())
		gm._phase = gm.Phase.SHIFT
		var zelt := gm.get_node("Tent")
		_check("Zelt hat Dielenboden, Galerie und hohes Dach",
			zelt.has_node("Boden/Dielen") and zelt.has_node("Galerie/EmporeWest") and zelt.has_node("Dach/Plane/PlaneOst"),
			"%d Teile" % zelt.find_children("*", "Node3D", true, false).size())

		print("  -- Emporen")
		var weg_hoch: Array = gm._route(Vector3(0, 0.1, 0), Vector3(10.3, 3.7, 5.0))
		_check("Weg auf die Empore führt über die Treppe", weg_hoch.size() == 5 and (weg_hoch[2] as Vector3).y > 3.0, str(weg_hoch.size()))
		_check("Weg auf gleicher Ebene bleibt direkt", gm._route(Vector3(0, 0.1, 0), Vector3(3, 0.1, 3)).size() == 1, "")
		var tisch_e: Node3D = gm._beertables[0]
		var lage_e := tisch_e.position
		var rot_e := tisch_e.rotation.y
		tisch_e.position = Vector3(9.0, gm.EMPORE_Y, 4.0)
		gm._tisch_freistellen(0)
		_check("Tisch auf der Empore rastet längs ein", absf(tisch_e.position.x - gm.EMPORE_TISCH_X) < 0.01
			and tisch_e.position.y > 3.0 and absf(tisch_e.rotation.y - PI / 2.0) < 0.01, str(tisch_e.position))
		tisch_e.position = Vector3(10.3, gm.EMPORE_Y, -5.5)   # über dem Treppenloch
		gm._tisch_freistellen(0)
		_check("Tisch nicht über dem Treppenloch", tisch_e.position.z < -8.8 or tisch_e.position.z > -1.4, str(tisch_e.position))
		gm._rebuild_seats()
		var sitz_oben: Vector3 = gm._seats[0].pos
		var laeufer := {"pos": Vector3(0, 0.1, 8.0), "tgt": sitz_oben, "yaw": 0.0, "level": 1, "role": gm.ROLE_KELLNER, "eig": "normal"}
		var angekommen := false
		var auf_treppe := false
		for k in 4000:
			if gm._staff_move(laeufer, 0.05):
				angekommen = true
				break
			var lp: Vector3 = laeufer.pos
			if lp.y > 1.0 and lp.y < 3.0 and absf(lp.x) > 10.6:
				auf_treppe = true
		_check("Kellner läuft über die Treppe zum Platz oben", angekommen and auf_treppe
			and absf((laeufer.pos as Vector3).y - sitz_oben.y) < 0.2, str(laeufer.pos))
		laeufer.tgt = Vector3(-2.0, 0.1, -8.0)
		angekommen = false
		for k in 4000:
			if gm._staff_move(laeufer, 0.05):
				angekommen = true
				break
		_check("… und wieder hinunter zur Theke", angekommen and (laeufer.pos as Vector3).y < 0.2, str(laeufer.pos))
		tisch_e.position = lage_e
		tisch_e.rotation.y = rot_e
		gm._rebuild_seats()

		print("  -- Band auf der Bühne")
		gm._artist_tier = 3
		gm._remove_artists()
		gm._spawn_artists()
		await _frames(3)
		var buehne := get_tree().get_nodes_in_group("stage")[0] as Node3D
		var alle_drauf: bool = gm._artist_nodes.size() == 5
		for a in gm._artist_nodes:
			var lokal: Vector3 = buehne.to_local((a as Node3D).global_position)
			if absf(lokal.x) > 2.7 or lokal.z > 1.5 or lokal.z < -1.8:
				alle_drauf = false
		_check("Band steht ganz auf der Bühne", alle_drauf, "%d Künstler" % gm._artist_nodes.size())
		gm._net_band_flieht()
		await _frames(3)
		var fliehen: bool = gm._band_weg
		for a in gm._artist_nodes:
			if is_instance_valid(a) and not a.flieht():
				fliehen = false
		_check("Band flieht bei Schlägerei, Musik bleibt aus", fliehen, "")
		gm._net_band_zurueck()

		print("  -- Baumodus-Karte")
		var karte = gm.get_node("Kirmes/Karte")
		var vorher: int = karte.eintraege.size()
		karte.net_setzen("res://scenes/kirmes/schiessstand.tscn", Vector3(-20, 0, 60), 0.0)
		karte.net_setzen("res://scenes/kirmes/dosenwurf.tscn", Vector3(-26, 0, 60), 0.0)
		karte.net_setzen("res://scenes/kirmes/essen/brezn.tscn", Vector3(-32, 0, 60), 0.0)
		karte.net_setzen("res://../boese.tscn", Vector3.ZERO, 0.0)
		await _frames(2)
		_check("Baumodus setzt Buden (nur aus dem Spiel)", karte.eintraege.size() == vorher + 3, "%d → %d" % [vorher, karte.eintraege.size()])
		var neueste: int = karte.eintraege.keys().max()
		_check("Essensbude hat Verkäufer", karte.knoten(neueste).get_node_or_null("Figur") != null, "")
		karte.net_bewegen(neueste, Vector3(-34, 0, 62), 1.0)
		_check("Baumodus verschiebt", karte.knoten(neueste).position.is_equal_approx(Vector3(-34, 0, 62)), "")
		karte.net_loeschen(neueste)
		await _frames(2)
		_check("Baumodus löscht", karte.eintraege.size() == vorher + 2 and karte.knoten(neueste) == null, "")
		var vorlage = JSON.parse_string(karte.vorlage())
		_check("Vorlage liegt bei", vorlage is Dictionary and (vorlage.eintraege as Array).size() > 100, "")

		print("  -- Schießbude")
		var buden := get_tree().get_nodes_in_group("schiessstand")
		_check("Schießbude steht auf der Kirmes", buden.size() >= 1, "%d Buden" % buden.size())
		Game.add_money(100)
		var geld_vor: int = Game.money
		gm.net_schiessen_bezahlen()
		_check("Schießen kostet 2 €", Game.money == geld_vor - gm.SCHIESS_PREIS, str(Game.money - geld_vor))
		gm.net_schiessen_ende(10)
		_check("10 Treffer: Teddy (20 €)", Game.money == geld_vor - gm.SCHIESS_PREIS + 20 and gm._schiessen_bezahlt.is_empty(), str(Game.money - geld_vor))
		gm.net_schiessen_ende(10)
		_check("Ohne Bezahlen kein Preis", Game.money == geld_vor - gm.SCHIESS_PREIS + 20, "")
		var spiele := get_tree().get_nodes_in_group("kirmes_spiel")
		_check("Kirmesspiel steht auf der Kirmes", spiele.size() >= 1, "%d Stände" % spiele.size())
		if not spiele.is_empty():
			var stand: Node = spiele[0]
			var geld_stand: int = Game.money
			gm.net_schiessen_bezahlen(gm.get_path_to(stand))
			_check("Kirmesspiel kostet den Preis des Stands", Game.money == geld_stand - int(stand.preis), str(Game.money - geld_stand))
			gm.net_schiessen_ende(4)
			_check("4 Punkte: Rose (3 €)", Game.money == geld_stand - int(stand.preis) + 3, str(Game.money - geld_stand))

		print("  -- Rausch")
		gm._rebuild_seats()
		gm._spawn_guest()
		var rid: int = gm._guest_sim.keys().back()
		var rg: Dictionary = gm._guest_sim[rid]
		rg.mode = 1
		rg.pos = gm._seats[int(rg.seat)].pos
		rg.tgt = rg.pos
		rg.rausch = 0.0
		rg.okind = 1
		rg.otype = 4
		gm._rausch_nach_bedienung(rg)
		_check("Festbier steigt zu Kopf", absf(float(rg.rausch) - 26.0) < 0.01, "%.1f" % float(rg.rausch))
		rg.rausch = 95.0
		gm._rausch_aktualisieren(rg, rid, 0.1)
		_check("Ab 90 wird der Gast zur Bierleiche", int(rg.mode) == 8 and gm.rausch_stufe(rg) == 3, "Modus %d" % int(rg.mode))
		gm.net_wasser_geben(rid)
		_check("Wasser macht nüchterner und weckt auf", int(rg.mode) == 1 and float(rg.rausch) < 70.0, "%.1f" % float(rg.rausch))
		rg.rausch = 95.0
		gm._rausch_aktualisieren(rg, rid, 0.1)
		gm.net_heimbringen(rid)
		_check("Bierleiche lässt sich heimbringen", int(rg.mode) == 9 and int(rg.get("folgt", 0)) == 1, "Modus %d" % int(rg.mode))
		gm._despawn_guest(rid)

		print("  -- Massenschlägerei")
		gm._day = 4
		var geplant_frueh := false
		for k in 40:
			gm._schlaegerei_planen()
			if gm._schlaegerei_uhr >= 0.0:
				geplant_frueh = true
		_check("Vor Tag 5 keine Schlägerei", not geplant_frueh, "")
		gm._day = 5
		gm._massen_gehabt = false
		var immer := true
		for k in 20:
			gm._schlaegerei_planen()
			if gm._schlaegerei_uhr < 0.0 or gm._einzel_uhren.is_empty():
				immer = false
		_check("Ab Tag 5: erste Massenschlägerei sicher, Einzelstreits jede Schicht", immer, "")
		gm._massen_gehabt = true
		var massen := 0
		for k in 400:
			gm._schlaegerei_planen()
			if gm._schlaegerei_uhr >= 0.0:
				massen += 1
		_check("Danach ist die Massenschlägerei selten", massen > 0 and massen < 80, "%d von 400" % massen)
		gm._schlaegerei_uhr = -1.0
		gm._einzel_uhren = []
		gm._rebuild_seats()
		for k in 16:
			gm._spawn_guest()
		for id in gm._guest_sim.keys():
			var sg: Dictionary = gm._guest_sim[id]
			sg.mode = 1
			sg.pos = gm._seats[int(sg.seat)].pos
			sg.tgt = sg.pos
			gm._guest_sim[id] = sg
		var streit_start: bool = gm.einzelstreit_ausloesen()
		await _frames(3)
		var streit: Dictionary = gm._einzelstreits[0] if streit_start else {}
		_check("Einzelstreit: zwei Gäste prügeln sich", streit_start and gm._raufbolde.size() == 2, "")
		if streit_start:
			var streit_ids: Array = streit.ids
			gm._einzelstreit_beenden(streit)
			_check("Einzelstreit vorbei: beide gehen, Band bleibt", not gm._guest_sim.has(streit_ids[0])
				and not gm._guest_sim.has(streit_ids[1]) and gm._raufbolde.is_empty() and not gm._band_weg, "")
		# Genug Tische und Gäste für eine Massenschlägerei
		gm._active_count = maxi(gm._active_count, 8)
		gm._apply_tent()
		for id in gm._guest_sim.keys().duplicate():
			gm._despawn_guest(id)
		gm._rebuild_seats()
		for k in 30:
			gm._spawn_guest()
		for id in gm._guest_sim.keys():
			var sg2: Dictionary = gm._guest_sim[id]
			sg2.mode = 1
			sg2.pos = gm._seats[int(sg2.seat)].pos
			sg2.tgt = sg2.pos
			gm._guest_sim[id] = sg2
		gm._popularity = 60.0
		var pop_vor_pruegel: float = gm._popularity
		var gestartet: bool = gm.schlaegerei_ausloesen()
		await _frames(5)
		_check("Schlägerei bricht aus, Gäste werden Raufbolde", gestartet and gm._raufbolde.size() >= 10
			and gm._raufbolde.size() == gm._schlaegerei_ids.size(), "%d Raufbolde" % gm._raufbolde.size())
		if not gestartet:
			return
		var erster: int = gm._schlaegerei_ids[0]
		gm.net_rauswerfen(erster)
		await _frames(2)
		_check("Rauswurf: Gast weg, Raufbold fliegt", not gm._guest_sim.has(erster) and gm._schlaegerei_raus == 1
			and gm._raufbolde[erster].zustand == gm._raufbolde[erster].Zustand.FLIEGT, "")
		var beteiligt: Array = gm._schlaegerei_ids.duplicate()
		gm._schlaegerei_beenden()
		var alle_weg := true
		for id in beteiligt:
			if gm._guest_sim.has(id):
				alle_weg = false
		_check("Nach der Schlägerei: Gäste gehen, Beliebtheit sinkt deutlich, Dreck", alle_weg and not gm.schlaegerei_laeuft()
			and gm._popularity < pop_vor_pruegel - 8.0 and gm._messes.size() > 0 and gm._massen_gehabt, "Pop %.1f → %.1f" % [pop_vor_pruegel, gm._popularity])

		print("  -- Tanzen auf dem Tisch")
		gm._phase = gm.Phase.SHIFT
		gm._phase_time = gm.SHIFT_TIME * 0.25   # etwa 18:15
		gm._popularity = 90.0
		gm._hygiene = 100.0
		gm._rebuild_seats()
		for k in gm._seats.size():
			gm._spawn_guest()
		for id in gm._guest_sim.keys():
			var tg: Dictionary = gm._guest_sim[id]
			tg.mode = 1
			tg.ostate = 0
			tg.drinks = 2
			tg.pos = gm._seats[int(tg.seat)].pos
			gm._guest_sim[id] = tg
		_check("Stimmung gut am Abend", gm.stimmung_gut(), "Uhr %.1f" % gm._clock_hour())
		for k in 30:
			gm._tanz_timer = 0.0
			gm._update_tanz(0.1)
		var taenzer := {}
		var zu_viele := false
		for tg: Dictionary in gm._guest_sim.values():
			if int(tg.mode) == 5:
				var ti := int(gm._seats[int(tg.seat)].table)
				taenzer[ti] = int(taenzer.get(ti, 0)) + 1
				if int(taenzer[ti]) > gm.tanz_max(ti):
					zu_viele = true
		_check("Gäste tanzen auf den Tischen, höchstens 2–3 je Tisch", not taenzer.is_empty() and not zu_viele, str(taenzer))
		# Tänzer ans Ziel setzen — sichtbar tanzen sie erst dort, nicht schon auf dem Weg
		for id in gm._guest_sim.keys():
			var tg2: Dictionary = gm._guest_sim[id]
			if int(tg2.mode) == 5 or int(tg2.mode) == 6:
				tg2.pos = tg2.tgt
				gm._guest_sim[id] = tg2
		gm._update_guests(0.01)   # überträgt den Zustand an die Gast-Knoten (Host)
		await _frames(3)
		var sichtbar_tanzend := 0
		for c in get_tree().get_nodes_in_group("customer"):
			if c.tanzt():
				sichtbar_tanzend += 1
		_check("Tänzer auch sichtbar", sichtbar_tanzend > 0, str(sichtbar_tanzend))
		for id in gm._guest_sim.keys().duplicate():
			gm._despawn_guest(id)

		print("  -- Tagesereignisse")
		var weizen_vorher: bool = gm._lic["weizen"]
		gm._lic["weizen"] = true
		gm._ereignis_waehlen("fass")
		_check("Fass kaputt: Weizen fehlt, Helles bleibt", gm._fass_kaputt == 2
			and not gm._drinks_avail().has(2) and gm._drinks_avail().has(1), str(gm._drinks_avail()))
		gm._ereignis_waehlen("bus")
		_check("Touristenbus: mehr Andrang, weniger Geduld", is_equal_approx(gm._ereignis_andrang(), 1.5)
			and gm._geduld() < Wirtschaft_geduld(gm), str(gm._ereignis_andrang()))
		gm._ereignis_waehlen("happy")
		gm._phase_time = gm.SHIFT_TIME * (1.0 - (18.5 - 7.0) / 15.0)   # 18:30
		var preis_happy: int = gm._reward_for(1)
		gm._ereignis = ""
		_check("Happy Hour: Bier billiger", preis_happy < gm._reward_for(1), "%d < %d" % [preis_happy, gm._reward_for(1)])
		hud.set_buero(gm._buero_state())
		gm._ereignis = "promi"
		hud.set_buero(gm._buero_state())
		_check("Ereignis in der Leiste", hud.get_node("%Ereignis").visible, hud.get_node("%Ereignis").text)
		gm.net_ping.rpc_id(1, Vector3(0, 0.1, 5), 1)
		await _frames(2)
		_check("Ping-Markierung erscheint", get_tree().get_nodes_in_group("ping").size() > 0,
			str(get_tree().get_nodes_in_group("ping").size()))
		hud.zeige_kombo(4)
		_check("Kombo-Anzeige", hud.get_node("%Kombo").visible and hud.get_node("%Kombo").text.contains("4"), hud.get_node("%Kombo").text)
		gm._ereignis = ""
		gm._fass_kaputt = 0
		gm._lic["weizen"] = weizen_vorher

		print("  -- Schwierigkeit")
		var geduld_normal: float = gm._geduld()
		var miete_normal: int = gm._daily_rent()
		gm._schwierigkeit = 0
		var geduld_gemuetlich: float = gm._geduld()
		gm._schwierigkeit = 2
		var geduld_wahnsinn: float = gm._geduld()
		var miete_wahnsinn: int = gm._daily_rent()
		gm._schwierigkeit = 1
		_check("Gemütlich geduldiger, Wahnsinn ungeduldiger", geduld_gemuetlich > geduld_normal and geduld_wahnsinn < geduld_normal,
			"%.1f / %.1f / %.1f" % [geduld_gemuetlich, geduld_normal, geduld_wahnsinn])
		_check("Wiesn-Wahnsinn: Miete höher (oder mietfrei)", miete_wahnsinn >= miete_normal, "%d / %d" % [miete_normal, miete_wahnsinn])

		print("  -- Gästetypen")
		var typen := {}
		for k in 400:
			typen[gm._gast_typ_waehlen()] = true
		_check("alle Gästetypen kommen vor", typen.size() == gm.GAST_TYPEN.size(), str(typen.keys()))
		_check("VIP doppelter Umsatz, Stammgast geduldiger", gm._typ_umsatz({"typ": "vip"}) == 2.0
			and gm._geduld_max({"typ": "stamm"}) > gm._geduld() and gm._geduld_max({"typ": "tourist"}) < gm._geduld(), "")

		print("  -- Nächste Wiesn schwerer")
		var saison_vorher: int = gm._saison_nr
		gm._saison_nr = 1
		var miete_w1: int = gm._daily_rent()
		var geduld_w1: float = gm._geduld()
		gm._saison_nr = 3
		var miete_w3: int = gm._daily_rent()
		var geduld_w3: float = gm._geduld()
		gm._saison_nr = saison_vorher

		print("  -- Großes Zelt, Klo, Bühne")
		_check("Riesenzelt: 24 Tische vorhanden", int(gm.TENT_TABLE_LIMIT[4]) == 24 and gm._all_tables.size() >= 24,
			str(gm._all_tables.size()))
		_check("Klo-Container in der Szene", gm.get_node_or_null("KloContainer") != null, "")
		_check("Tanzplätze vor der Bühne frei", not gm.buehnen_tanzplaetze().is_empty(), str(gm.buehnen_tanzplaetze().size()))

		print("  -- Abstimmung und Klo")
		_check("Abstimmung: Mehrheit entscheidet", gm.abstimmung_ergebnis(2, 0, 3, false) == 1
			and gm.abstimmung_ergebnis(1, 0, 3, false) == 0
			and gm.abstimmung_ergebnis(1, 1, 2, false) == -1
			and gm.abstimmung_ergebnis(1, 0, 3, true) == -1
			and gm.abstimmung_ergebnis(3, 1, 4, false) == 1, "")
		var klo_vorher: bool = gm._has_toilet
		gm._has_toilet = true
		gm._klo_gast = -1
		var g_a := {"mode": 1, "bladder": 0.0, "seat": -1, "pos": Vector3.ZERO, "ostate": 0}
		var g_b := {"mode": 1, "bladder": 0.0, "seat": -1, "pos": Vector3.ZERO, "ostate": 0}
		gm._update_bladder(g_a, 9001, 0.1)
		gm._update_bladder(g_b, 9002, 0.1)
		_check("Klo: erster Gast drin, zweiter wartet", gm._klo_gast == 9001 and bool(g_b.get("klo_wartet", false)), "")
		g_b.warte_t = 0.0
		gm._update_bladder(g_b, 9002, 0.1)
		_check("Klo besetzt zu lange: Gast geht ins Zelt", bool(g_b.get("wild", false)) and not bool(g_b.get("klo_wartet", false)), "")
		gm._klo_setzen(-1)
		gm._has_toilet = klo_vorher

		print("  -- Abdeckplanen")
		# Die echten Lagerregale aus main.tscn stehen unter der Plane 14. Genau da
		# stand beim Testen immer „Regal bewegen" statt „Plane abziehen".
		var regale: Array[Node] = []
		for n in gm.get_children():
			if n is Lager:
				regale.append(n)
		_check("Lagerregale in der Welt", regale.size() >= 2, "%d" % regale.size())
		var messe_vorher: Array = gm._messes.keys()
		gm._spawn_mess_at(gm.DECKEN_PLAETZE[14], 14)
		await _frames(3)
		var plane: Mess = null
		for id: int in gm._messes.keys():
			if not id in messe_vorher and gm._messes[id] is Mess and (gm._messes[id] as Mess).ist_plane():
				plane = gm._messes[id]
		_check("Plane über dem Lager liegt da", plane != null, str(plane))
		if plane:
			var sp_plane := gm.get_node("Players").get_child(0) as Player
			var pos_vorher := sp_plane.global_position
			var dreh_vorher := sp_plane.rotation.y
			# Vor jedem zugedeckten Regal stehen und auf die Wand schauen. Später
			# dazugekaufte Regale stehen woanders und sind hier nicht gemeint.
			var zugedeckt: Array[Node3D] = []
			for regal: Node3D in regale:
				if plane.deckt(regal.global_position):
					zugedeckt.append(regal)
			_check("Beide Wandregale liegen unter der Plane", zugedeckt.size() == 2, "%d von %d" % [zugedeckt.size(), regale.size()])
			for regal: Node3D in zugedeckt:
				sp_plane.global_position = regal.global_position + Vector3(1.8, 0, 0)
				sp_plane.rotation.y = PI * 0.5
				sp_plane._update_target()
				var ziel: Node = sp_plane._current_target
				_check("Am zugedeckten Regal %s: Plane abziehen" % regal.name,
					ziel == plane and sp_plane._hint_for(ziel) == "HINT_PLANE",
					"%s / %s" % [ziel, sp_plane._hint_for(ziel) if ziel else "-"])
			# Auch am Ende der Plane, wo ihr Mittelpunkt außer Reichweite ist
			sp_plane.global_position = Vector3(-9.4, 0, -6.1)
			sp_plane.rotation.y = PI * 0.5
			sp_plane._update_target()
			_check("Auch am Planenende greift man die Plane",
				sp_plane._hint_for(sp_plane._current_target) == "HINT_PLANE",
				"%s" % sp_plane._hint_for(sp_plane._current_target))
			# Abgezogen: jetzt gehört der Griff wieder dem Regal
			plane.entfernen()
			await _frames(2)
			sp_plane.global_position = zugedeckt[0].global_position + Vector3(1.8, 0, 0)
			sp_plane.rotation.y = PI * 0.5
			sp_plane._update_target()
			_check("Ohne Plane ist das Regal wieder dran", sp_plane._current_target == zugedeckt[0],
				str(sp_plane._current_target))
			sp_plane.global_position = pos_vorher
			sp_plane.rotation.y = dreh_vorher

		print("  -- Wegweiser über liegengebliebenem Dreck")
		# Eigener Dreck für den Test: was sonst noch herumliegt, ist egal
		for p2 in [Vector3(2, 0, 2), Vector3(-2, 0, 3), Vector3(4, 0, -2)]:
			gm._spawn_mess_at(p2, Mess.DRECK)
		await _frames(3)
		var meine_mess: Array[Mess] = []
		for n in get_tree().get_nodes_in_group("mess"):
			if n is Mess and (n as Mess).ist_dreck():
				meine_mess.append(n)
		_check("Dreck liegt im Zelt", meine_mess.size() >= 3, "%d" % meine_mess.size())
		if meine_mess.size() >= 3:
			for m in meine_mess:
				m._liegt = 0.0
				m._pruef = 0.0
			await _frames(3)
			var an_vorher := 0
			for m in meine_mess:
				if m._pfeil.visible:
					an_vorher += 1
			_check("Frischer Dreck zeigt keinen Pfeil", an_vorher == 0, "%d Pfeile" % an_vorher)
			for m in meine_mess:
				m._liegt = m.MAHN_ZEIT + 1.0
				m._pruef = 0.0
			await _frames(4)
			var an_nachher := 0
			for m in meine_mess:
				if m._pfeil.visible:
					an_nachher += 1
			_check("Liegengebliebener Dreck: genau ein Wegweiser", an_nachher == 1, "%d Pfeile" % an_nachher)
			for m in meine_mess:
				m.entfernen()

		print("  -- Mülltonne")
		var tonne := gm.get_node_or_null("Muellplatz")
		_check("Mülltonne steht vor dem Zelt", tonne != null, "")
		var erzeugt_vorher: int = gm._muell_erzeugt
		var entsorgt_vorher: int = gm._muell_entsorgt
		# Zwei Säcke gefegt, dreimal abgegeben: der dritte darf nicht zählen
		gm._muellsack_hinlegen(Vector3(0, 0, 0))
		gm._muellsack_hinlegen(Vector3(1, 0, 0))
		for i in 3:
			gm.net_muell_abgeben()
		_check("Nie mehr entsorgt als gefegt", gm._muell_entsorgt - entsorgt_vorher == 2,
			"%d entsorgt, %d gefegt" % [gm._muell_entsorgt - entsorgt_vorher, gm._muell_erzeugt - erzeugt_vorher])
		if tonne:
			tonne.anzahl_setzen(9)
			var saecke_sichtbar := 0
			for sack in tonne.get_node("Saecke").get_children():
				if (sack as Node3D).visible:
					saecke_sichtbar += 1
			_check("Tonne stapelt nichts: höchstens drei Säcke sichtbar", saecke_sichtbar <= 3, "%d" % saecke_sichtbar)
			tonne.anzahl_setzen(0)

		print("  -- Lobby")
		gm.net_lobby_setzen("  Wiesn-Sepp mit viel zu langem Namen ", 3, 2)
		var eigen: Dictionary = gm._spieler_info.get(1, {})
		_check("Lobby-Wahl gespeichert, Name gekürzt", int(eigen.get("figur", -1)) == 2
			and str(eigen.get("name", "")).length() <= gm.SPIELERNAME_MAX and int(eigen.get("farbe", -1)) == 3,
			str(eigen))
		_check("Meldungen nutzen den Lobby-Namen", gm._spieler_bezeichnung(1) == str(eigen.get("name", "")), "")
		gm._spieler_info.clear()

		print("  -- Zeltname")
		_check("Zeltname wird bereinigt", gm.zeltname_pruefen("  Zum\nHirsch  ") == "ZumHirsch"
			and gm.zeltname_pruefen("x".repeat(40)).length() == gm.ZELTNAME_MAX, "")
		var name_vorher: String = gm._zelt_name
		gm._zelt_name = "Zum Durstigen Hirsch"
		gm._zeltname_anzeigen()
		var schilder := get_tree().get_nodes_in_group("zeltname")
		_check("Zeltname am Eingang und über der Theke", schilder.size() >= 2
			and schilder.all(func(n: Node) -> bool: return (n as Label3D).text == "Zum Durstigen Hirsch" and (n as Label3D).visible),
			str(schilder.size()))
		gm._zelt_name = name_vorher
		gm._zeltname_anzeigen()

		print("  -- Einrichtung an Wand und Decke")
		var lage_wand: Dictionary = gm._deko_platz("banner", 3.0, -12.9, 0.0)
		_check("Wanddeko rastet an der Rückwand ein", is_equal_approx(float(lage_wand.z), gm.WAND_HINTEN)
			and float(lage_wand.y) > 1.5 and is_zero_approx(float(lage_wand.rot)), str(lage_wand))
		var lage_west: Dictionary = gm._deko_platz("hopfen", -10.8, 0.0, 0.0)
		_check("Wanddeko an der Westwand schaut ins Zelt", is_equal_approx(float(lage_west.x), -gm.WAND_X)
			and is_equal_approx(float(lage_west.rot), PI / 2.0), str(lage_west))
		_check("Deckendeko hängt oben, Bodendeko steht unten", gm.Katalog.hoehe("kronleuchter") > 3.0
			and is_zero_approx(float(gm._deko_platz("regal", 0.0, 0.0, 0.0).y)), "")

		print("  -- Spätlizenzen")
		var stufe_vorher: int = gm._tent_stage
		gm._tent_stage = 1
		gm._saison_nr = 1
		_check("Festbier/Hendl gesperrt vor Zeltstufe 3", not gm.spaetlizenz_frei(), "")
		gm._tent_stage = 3
		_check("Festbier/Hendl ab Zeltstufe 3", gm.spaetlizenz_frei(), "")
		gm._tent_stage = stufe_vorher
		gm._saison_nr = saison_vorher
		_check("Festbier teurer als Helles, Hendl teurer als Brezn",
			gm._reward_for(1, 4) > gm._reward_for(1, 1) and gm._reward_for(2, 3) > gm._reward_for(2, 1), "")

		print("  -- Personal-Eigenschaften")
		_check("Flink kostet mehr, Schluckspecht weniger",
			gm._staff_wage(2, 1, "schnell") > gm._staff_wage(2, 1) and gm._staff_wage(2, 1, "schluckspecht") < gm._staff_wage(2, 1)
			and gm._staff_wage(2, 1, "quatsch") == gm._staff_wage(2, 1), "")
		_check("Flink läuft schneller", gm._staff_tempo({"eig": "schnell"}) > gm._staff_tempo({}), "")
		_check("Wiesn 3: mehr Miete, weniger Geduld", miete_w3 >= miete_w1 and geduld_w3 < geduld_w1,
			"Miete %d → %d, Geduld %.1f → %.1f" % [miete_w1, miete_w3, geduld_w1, geduld_w3])
		gm._phase = gm.Phase.INTERMISSION

		print("  -- Spielstände (3.3)")
		_check("Stand liegt in Platz 1", Net.speicherstand_pfad() == "user://saves/slot_1.json"
			and FileAccess.file_exists("user://saves/slot_1.json"), Net.speicherstand_pfad())
		_check("Formatversion und Zeit im Stand", gespeichert is Dictionary
			and int(gespeichert.get("format", 0)) == Net.SAVE_FORMAT and int(gespeichert.get("saved_at", 0)) > 0, "")
		_check("Info liefert Tag", int(Net.speicherstand_info(1).get("day", 0)) == gm._day, str(Net.speicherstand_info(1)))
		var zu_neu := FileAccess.open("user://saves/slot_3.json", FileAccess.WRITE)
		zu_neu.store_string(JSON.stringify({"format": 99, "day": 5, "money": 1, "saved_at": 9999999999}))
		zu_neu.close()
		_check("Stand aus neuerer Version erkannt", Net.speicherstand_info(3).get("zu_neu", false), "")
		_check("Weiterspielen ignoriert zu neuen Stand", Net.letzter_slot() == 1, str(Net.letzter_slot()))
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://saves/slot_3.json"))

		print("  -- Pleite und Rettungskredit (3.5)")
		Game.add_money(-1500 - Game.money)   # Konto auf −1.500 €
		gm._pruefe_pleite()
		_check("Brauerei gleicht Konto aus", Game.money == 0, str(Game.money))
		_check("Schuld = Fehlbetrag + 20 %", gm._kredit_rest == 1800, str(gm._kredit_rest))
		var werbung_vorher: int = gm._upg_marketing
		gm.net_buy_marketing.rpc_id(1)
		await _frames(3)
		_check("Ausbau gesperrt", gm._upg_marketing == werbung_vorher, "")
		hud.set_buero(gm._buero_state())
		hud.set_money(Game.money)
		var werbung_zeile: Node = hud.get_node("%Wiesenbuero").get_node("%Werbung")
		_check("Wiesenbüro nennt den Kredit als Grund", werbung_zeile.grund_text().contains("Rettungskredit"), werbung_zeile.grund_text())
		gm._add_income(100)
		_check("25 % jeder Einnahme gehen an die Brauerei", Game.money == 75 and gm._kredit_rest == 1775,
			"Konto %d, Schuld %d" % [Game.money, gm._kredit_rest])
		gm._save_game()
		var mit_kredit: Variant = JSON.parse_string(FileAccess.get_file_as_string(Net.speicherstand_pfad()))
		_check("Schuld im Spielstand", mit_kredit is Dictionary and int(mit_kredit.get("kredit", 0)) == 1775, "")
		gm._add_income(100000)
		_check("Kredit abbezahlt", gm._kredit_rest == 0, str(gm._kredit_rest))

		print("  -- Grafikstufen (4.4)")
		var grafik := gm.get_node_or_null("Grafikstufe")
		_check("Grafikstufe in der Szene", grafik != null and grafik.lichter_gesamt() > 0,
			str(grafik.lichter_gesamt()) if grafik else "")
		if grafik:
			var umgebung: Environment = gm.get_node("WorldEnvironment").environment
			var alle: int = grafik.lichter_gesamt()
			Einstellungen.grafik = 0
			Einstellungen.anwenden()
			await _frames(2)
			_check("Niedrig: 120 Besucher, kein SSAO und Glow", gm.get_node("Crowd").max_visitors == 120
				and not umgebung.ssao_enabled and not umgebung.glow_enabled, "")
			_check("Niedrig: ein Drittel der Kirmeslichter", grafik.sichtbare_lichter() <= ceili(alle / 3.0),
				"%d von %d" % [grafik.sichtbare_lichter(), alle])
			_check("Niedrig: Farbkorrektur aus", not umgebung.adjustment_enabled, "")
			var eingang := preload("res://scripts/menu_eingang.gd")
			_check("Kein Neustart bei gleichem Renderer",
				eingang.neustart_argumente(false, "forward_plus", "forward_plus").is_empty(), "")
			_check("Neustart nur mit --rendering-method, nie --main-pack",
				Array(eingang.neustart_argumente(false, "forward_plus", "gl_compatibility"))
				== ["--rendering-method", "gl_compatibility"], "")
			_check("Nach dem Neustart kein zweiter",
				eingang.neustart_argumente(true, "forward_plus", "gl_compatibility").is_empty(), "")
			_check("alte .exe (Generation 1) bekommt den Download-Hinweis",
				eingang.braucht_neue_exe(1, 2) and not eingang.braucht_neue_exe(2, 2), "")
			_check("Projekt ist so neu, wie das Paket es verlangt",
				int(ProjectSettings.get_setting("application/config/programm_generation", 1)) >= eingang.BENOETIGTE_GENERATION,
				str(ProjectSettings.get_setting("application/config/programm_generation", 1)))
			# Alte .exe + neues Paket: Tabellen der .exe fehlen neue Texte → rohe Schlüssel.
			# Nachgestellt durch Leeren des TranslationServers.
			TranslationServer.clear()
			var uebersetzung_roh := TranslationServer.translate("WORLD_BUERO") == "WORLD_BUERO"
			var tabellen: int = eingang.uebersetzungen_neu_laden()
			Einstellungen.anwenden()
			_check("Übersetzungen nach dem Update neu geladen (keine rohen Schlüssel)",
				uebersetzung_roh and tabellen == 3 and TranslationServer.translate("WORLD_BUERO") != "WORLD_BUERO"
				and TranslationServer.translate("SIGN_TENT_FOR_RENT") != "SIGN_TENT_FOR_RENT",
				"%d Tabellen · %s" % [tabellen, TranslationServer.translate("SIGN_TENT_FOR_RENT")])
			Einstellungen.grafik = 2
			Einstellungen.aufloesung = 0.75
			Einstellungen.anwenden()
			await _frames(2)
			_check("Hoch: alle Lichter, SSAO an", grafik.sichtbare_lichter() == alle and umgebung.ssao_enabled, "")
			_check("Renderauflösung 75 %", is_equal_approx(get_tree().root.scaling_3d_scale, 0.75),
				str(get_tree().root.scaling_3d_scale))
			Einstellungen.aufloesung = 1.0
			Einstellungen.anwenden()

		print("  -- NPC-Figuren")
		var figuren := preload("res://scripts/figuren.gd")
		_check("mindestens zwei Figuren", figuren.ALLE.size() >= 2, str(figuren.ALLE.size()))
		_check("gleiche ID ergibt gleiche Figur", figuren.fuer_id(17) == figuren.fuer_id(17), "")
		var verteilt := {}
		for i in 20:
			verteilt[figuren.fuer_id(i).resource_path] = true
		_check("IDs verteilen sich auf alle Figuren", verteilt.size() == figuren.ALLE.size(), str(verteilt.size()))
		# Alex (Meshy): Animationen liegen in vier Dateien, geliehen über
		# Figur.leih_animationen_mehr — ein falscher Bibliotheksname fällt sonst
		# still auf „geht normal" zurück
		var alex := preload("res://scenes/figuren/alex.tscn").instantiate() as Figur
		add_child(alex)
		await _frames(2)
		_check("Alex geht, rennt und torkelt", alex.hat(alex.anim_gehen) and alex.hat(alex.anim_rennen)
			and alex.kann_torkeln(), "gehen=%s rennen=%s torkeln=%s" % [str(alex.hat(alex.anim_gehen)),
			str(alex.hat(alex.anim_rennen)), str(alex.kann_torkeln())])
		_check("Alex: Knochen der Würge-Pose gefunden", alex.skelett != null
			and alex.skelett.find_bone("mixamorig_Head") >= 0, "")
		alex.queue_free()
		# Sitzende Gäste nur aus GAESTE (charakter3 spreizt beim Sitzen den Rock)
		_check("Gäste ohne charakter3", not figuren.GAESTE.has(preload("res://scenes/figuren/charakter3.tscn"))
			and figuren.GAESTE.size() >= 2, str(figuren.GAESTE.size()))
		# Stehgäste (charakter3, Alex) — etwa jeder dritte, und immer aus STEHGAESTE
		var stehend := 0
		for i in 30:
			if figuren.ist_stehgast(i):
				stehend += 1
				if not figuren.STEHGAESTE.has(figuren.fuer_gast(i)):
					stehend = -99
		_check("Stehgäste etwa jeder dritte, alle aus STEHGAESTE", stehend >= 8 and stehend <= 12, str(stehend))
		var steh_id := 0
		while not figuren.ist_stehgast(steh_id):
			steh_id += 1
		var steh_gast: Node3D = load("res://scenes/customer.tscn").instantiate()
		steh_gast.cust_id = steh_id
		gm.get_node("Customers").add_child(steh_gast)
		await _frames(20)
		_check("Stehgast setzt sich nicht", not steh_gast._seated and steh_gast._steht, "")
		steh_gast.queue_free()
		for szene: PackedScene in figuren.GAESTE:
			var id := 0
			# Deckel drauf: kommt eine Figur nie dran, lief der Test vorher endlos
			while figuren.fuer_gast(id) != szene and id < 200:
				id += 1
			_check("Gast %s kommt überhaupt vor" % szene.resource_path.get_file(), id < 200, str(id))
			var gast: Node3D = load("res://scenes/customer.tscn").instantiate()
			gast.cust_id = id
			gm.get_node("Customers").add_child(gast)
			await _frames(2)
			var f: Node = gast.get_node("Model")
			var kurz := szene.resource_path.get_file()
			_check("Gast %s: Figur mit Animation" % kurz,
				f is Figur and f.scene_file_path == szene.resource_path and f.anim != null, str(f.scene_file_path))
			gast._enter_sit()
			await _frames(2)
			if f.kann_sitzen():
				_check("Gast %s: sitzt per Animation" % kurz, f.anim.current_animation == f.anim_sitzen,
					f.anim.current_animation)
			else:
				_check("Gast %s: sitzt per Knochenpose" % kurz, gast.sitzt() and not f.anim.active, "")
			gast.queue_free()
		var angestellter: Node3D = load("res://scenes/staff.tscn").instantiate()
		angestellter.staff_id = 0
		gm.get_node("Customers").add_child(angestellter)
		await _frames(2)
		angestellter.set_carrying(3)
		_check("Personal hat Figur und Tablett mit Krügen", angestellter.figur() != null
			and angestellter._mug_nodes.size() == 12 and (angestellter.get_node("Tablett") as Node3D).visible,
			str(angestellter._mug_nodes.size()))
		angestellter.queue_free()

		print("  -- Steam-Dienst (5.2)")
		var dienst := get_tree().root.get_node_or_null("SteamDienst")
		_check("Steam-Dienst geladen", dienst != null, "")
		if dienst:
			var regel := preload("res://autoload/steam_dienst.gd")
			_check("startet nur im Steam-Build mit Bibliothek, nie auf dem Server",
				regel.soll_starten(true, false, true)
				and not regel.soll_starten(false, false, true)
				and not regel.soll_starten(true, true, true)
				and not regel.soll_starten(true, false, false), "")
			_check("außerhalb des Steam-Builds inaktiv, mit Grund", not dienst.aktiv and dienst.grund != "", dienst.grund)
			dienst.status_setzen("#Status_Solo", 3)   # darf ohne Steam nichts tun und nicht abstürzen
			_check("App-ID aus den Projekteinstellungen", dienst.app_id == int(ProjectSettings.get_setting("steam/app_id", 0)),
				str(dienst.app_id))
			print("  -- Steam-Lobby (5.3)")
			_check("Lobby aus dem Startbefehl einer Einladung",
				regel.lobby_aus_argumenten(PackedStringArray(["--x", "+connect_lobby", "109775241"])) == 109775241
				and regel.lobby_aus_argumenten(PackedStringArray(["+connect_lobby"])) == 0
				and regel.lobby_aus_argumenten(PackedStringArray()) == 0, "")
			_check("ohne Steam: keine Lobby, kein Absturz", not dienst.lobby_erstellen()
				and not dienst.lobby_beitreten(5) and dienst.lobby_id == 0, "")
			dienst.freunde_einladen()   # darf ohne Steam nichts tun
			dienst.lobby_verlassen()
			# Wichtig: im Editor gibt es die Klasse — ohne laufendes Steam darf trotzdem
			# weder gehostet noch beigetreten werden (sonst griffe der Peer ins Leere)
			_check("ohne Steam: Net lehnt Steam-Host und -Beitritt ab",
				Net.host_steam(1) == ERR_UNAVAILABLE and Net.join_steam(1) == ERR_UNAVAILABLE, "")

		print("  -- Pausemenü")
		var pause := gm.get_node_or_null("PauseMenu")
		_check("Pausemenü in der Szene", pause != null and pause.has_method("oeffnen"), str(pause))
		if pause:
			_check("anfangs geschlossen", not pause.visible, "")
			pause.oeffnen()
			await _frames(3)
			_check("sichtbar nach Öffnen", pause.visible, "")
			_check("Solo: Zeit angehalten", get_tree().paused, "")
			pause.schliessen()
			await _frames(3)
			_check("Fortsetzen: Pause aufgehoben", not get_tree().paused, "")
			_check("wieder unsichtbar", not pause.visible, "")

		print("  -- Tastenbelegung")
		_check("Standard: Benutzen auf E", _taste("interact") == KEY_E, OS.get_keycode_string(_taste("interact")))
		Einstellungen.setze_taste("interact", KEY_F)
		_check("umbelegt auf F", _taste("interact") == KEY_F, OS.get_keycode_string(_taste("interact")))
		_check("Anzeigename F", Einstellungen.tasten_name("interact") == "F", Einstellungen.tasten_name("interact"))
		Einstellungen.tasten_zuruecksetzen()
		_check("zurückgesetzt auf E", _taste("interact") == KEY_E, OS.get_keycode_string(_taste("interact")))
		_check("Prost-Aktion existiert", InputMap.has_action("emote") and _taste("emote") == KEY_Q, "")

		print("  -- Sprache")
		for lang in ["de", "en", "tr"]:
			Einstellungen.sprache = lang
			Einstellungen.anwenden()
			var t := tr("MENU_NEW_GAME")
			_check("%s übersetzt" % lang, t != "MENU_NEW_GAME", t)

	## Der Ladebildschirm braucht unterschiedlich lange — warten, bis das Spiel da ist.
	func _warte_auf_spiel() -> void:
		# Nach echter Zeit, nicht nach Bildern: headless laufen 3000 Bilder in ~3 s durch,
		# das Laden dauert mit allen Modellen länger (Deploy-Test fiel sporadisch aus)
		var bis := Time.get_ticks_msec() + 45000
		while Time.get_ticks_msec() < bis:
			var s := get_tree().current_scene
			if s != null and s.has_method("net_book_tent") and s.is_node_ready():
				break
			await get_tree().process_frame
		await _frames(30)

	func _taste(aktion: String) -> int:
		for ev in InputMap.action_get_events(aktion):
			if ev is InputEventKey:
				return (ev as InputEventKey).physical_keycode
		return KEY_NONE

	## Geduld ohne Tagesereignis (für den Vergleich im Test)
	func Wirtschaft_geduld(gm: Node) -> float:
		return preload("res://scripts/wirtschaft.gd").geduld(gm.ORDER_PATIENCE, gm._day)

	func _frames(n: int) -> void:
		for i in n:
			await get_tree().process_frame

	func _check(name: String, ok: bool, info: String) -> void:
		if not ok:
			fehler += 1
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", name, info])

	func _sichern() -> void:
		# Liegt noch eine Sicherung von einem abgebrochenen Lauf da, ist sie der
		# echte Stand — erst zurückspielen, sonst sichern wir gleich den Teststand.
		for pfad: String in DATEIEN:
			var alt := ProjectSettings.globalize_path(pfad + ".testbackup")
			if FileAccess.file_exists(pfad + ".testbackup"):
				DirAccess.copy_absolute(alt, ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(alt)
				print("  alte Sicherung zurückgespielt: ", pfad)
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad),
					ProjectSettings.globalize_path(pfad + ".testbackup"))
		print("  gesichert: ", _gab_es)

	func _wiederherstellen() -> void:
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			var backup := echt + ".testbackup"
			if _gab_es.get(pfad, false):
				DirAccess.copy_absolute(backup, echt)
				DirAccess.remove_absolute(backup)
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("  wiederhergestellt")

	func _abbruch() -> void:
		print("ERGEBNIS: ABBRUCH nach Zeitlimit")
		_wiederherstellen()
		get_tree().quit(2)
