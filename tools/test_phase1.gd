extends Node
## Test für Phase 1: Solo-Start, Spieleraktionen, Pausemenü, Tastenbelegung.
## Sichert vorher Spielstand UND Einstellungen und stellt beide am Ende wieder
## her — der Test verändert nichts an deinem echten Stand.
## Aufruf: godot --headless --path . res://tools/test_phase1.tscn

const DATEIEN := ["user://oktoberfest_save.json", "user://saves/slot_1.json", "user://saves/slot_2.json",
	"user://saves/slot_3.json", "user://einstellungen.cfg"]

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
			var grenze := gm.get_node_or_null("Kirmes/Grenze/BoundSouth") as Node3D
			_check("Wohnwagen innerhalb der Kartengrenze", grenze != null and grenze.global_position.z < tuer.z - 1.0,
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
		_check("Meldung übersetzt, Betrag formatiert", meldung == "💶 Zu wenig Geld für Toilette einbauen (1.800 €)", meldung)
		var popup_text: String = texte.meldung("POPUP_RESERVE", [{"euro": 40}])
		_check("Popup mit echten Zeilenumbrüchen", popup_text.contains("\n\n") and not popup_text.contains("\\n"), popup_text.left(30))
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
		_check("Schritt 1 (Tische) nach Zelt + 1 Tisch", gm._quest_step == 1, "Schritt=%d" % gm._quest_step)
		var marker := gm.get_node_or_null("Zielmarker")
		_check("Zielmarker in der Szene", marker != null, "")
		if marker:
			var ziel: Node = marker.ziel_suchen()
			_check("Marker zeigt aufs Wiesenbüro", ziel is OfficeDesk, str(ziel))
		# Der Haken für "Zelt mieten" darf noch sichtbar sein — Überspringen darf
		# nur keinen neuen auslösen.
		var haken_vorher: int = hud._erledigt_token
		gm.net_skip_tutorial.rpc_id(1)
		await _frames(5)
		_check("Überspringen beendet Tutorial", not gm.tutorial_active(), "Schritt=%d" % gm._quest_step)
		_check("Aufgabe ausgeblendet", not hud.get_node("%Aufgabe").visible, "")
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
		_check("HUD zeigt Tag 17", String(hud.get_node("%Zeit").text).begins_with("Tag 17"), hud.get_node("%Zeit").text)

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
		_check("Miete im Spiel folgt dem Tag", gm._daily_rent() == w.miete(int(gm.TENT_RENT[gm._tent_stage]), gm._day),
			"Tag %d, Miete %d" % [gm._day, gm._daily_rent()])

		print("  -- Bierpreis")
		var preis0: int = gm._reward_for(1)
		gm.net_set_bierpreis.rpc_id(1, -5)
		await _frames(3)
		_check("Bierpreis auf 50 %", is_equal_approx(gm._bierpreis, 0.5), str(gm._bierpreis))
		_check("billig: weniger je Maß, mehr Andrang", gm._reward_for(1) < preis0 and w.preis_andrang(0.5) > 1.0,
			"%d -> %d" % [preis0, gm._reward_for(1)])
		gm.net_set_bierpreis.rpc_id(1, 5)
		await _frames(3)
		_check("Bierpreis zurück auf 100 %", is_equal_approx(gm._bierpreis, 1.0), str(gm._bierpreis))

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
		gm._update_guests(0.01)   # überträgt den Zustand an die Gast-Knoten (Host)
		await _frames(3)
		var sichtbar_tanzend := 0
		for c in get_tree().get_nodes_in_group("customer"):
			if c.tanzt():
				sichtbar_tanzend += 1
		_check("Tänzer auch sichtbar", sichtbar_tanzend > 0, str(sichtbar_tanzend))
		for id in gm._guest_sim.keys().duplicate():
			gm._despawn_guest(id)
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
		# Sitzende Gäste nur aus GAESTE (charakter3 spreizt beim Sitzen den Rock)
		_check("Gäste ohne charakter3", not figuren.GAESTE.has(preload("res://scenes/figuren/charakter3.tscn"))
			and figuren.GAESTE.size() >= 2, str(figuren.GAESTE.size()))
		for szene: PackedScene in figuren.GAESTE:
			var id := 0
			while figuren.fuer_gast(id) != szene:
				id += 1
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
		_check("Personal hat Figur und Krüge an den Händen", angestellter.figur() != null
			and angestellter._hand_mugs.size() == 2, str(angestellter._hand_mugs.size()))
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
		for i in 3000:
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
