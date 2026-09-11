extends Node
## Spielbot (Plan Spaß 0.2/0.3): spielt 30 Tage im Zeitraffer mit der echten
## Spiellogik und einer einfachen Strategie. Schreibt je Tag Zahlen nach
## build/saison.csv und misst die ersten Minuten eines neuen Spiels.
##
## Der Bot ist ein Spieler ohne Körper: jede Handlung kostet geschätzte Zeit
## (Laufwege aus den echten Positionen, Zapfen, Tragen). Er zeigt, wo das Spiel
## hakt — nicht, wie gut ein Mensch spielt.
## Sichert Spielstände und Einstellungen vorher und stellt sie wieder her.
## Aufruf: godot --headless --path . res://tools/sim_saison.tscn [-- --tage 30]

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]
const CSV := "res://build/saison.csv"
const DT := 0.2
const TEMPO := 4.5          # Laufgeschwindigkeit m/s (geschätzt, mit Sprinten)
const ZAPFEN := 2.5         # Krug holen und zapfen
const PUTZEN := 4.0         # 20 × E am Fleck
const RESERVE := 600        # so viel Geld behält der Bot für Ware

## Orte (aus scenes/main.tscn und scenes/kirmes.tscn)
const START := Vector3(-3.5, 0, -35)
const SCHILD := Vector3(4.2, 0, 13.2)
const BUERO := Vector3(38.1, 0, 18.4)
const WOHNWAGEN := Vector3(-3.3, 0, -51.2)
const THEKE := Vector3(0, 0, -7)
const ABLAGE := Vector3(0, 0, 15.5)
const LAGER := Vector3(-9, 0, -6)

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var _gab_es := {}
	var gm: Node
	var zeit := 0.0            # Spielsekunden seit Start
	var pos := START
	var beschaeftigt := 0.0    # bis dahin tut der Bot noch etwas
	var leerlauf := 0.0        # Sekunden ohne sinnvolle Handlung (in der Schicht)
	var ohne_bier := 0.0       # Sekunden in der Schicht mit leerem Lager
	var erster_gast := -1.0
	var erste_bilanz := -1.0
	var zeilen := PackedStringArray()
	var tage := 30

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var args := OS.get_cmdline_user_args()
		var i := args.find("--tage")
		if i >= 0 and i + 1 < args.size():
			tage = maxi(1, args[i + 1].to_int())
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".simbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".simbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".simbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".simbackup"))
		Net.start_solo(true, 3)
		for k in 3000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(10)
		gm = get_tree().current_scene
		gm.set_process(false)
		zeilen.append("tag,geld_ende,umsatz,netto,miete,loehne,ware,bedient,verpasst,pfuetzen,beschwerden,gegangen,beliebtheit,zeltstufe,tische,kellner,reinigung,koch,lizenzen,leerlauf_s,ohne_bier_s,kredit")
		await _spielen()
		_speichern()
		_zurueck()
		get_tree().quit()

	# ------------------------------------------------------------ Ablauf
	func _spielen() -> void:
		# Tag 1 wie ein neuer Spieler: zum Schild, mieten, zum Büro, Tische + Bier
		_gehen(SCHILD)
		gm.net_book_tent()
		_gehen(BUERO)
		for k in 2:
			gm.net_buy_table()
		gm.net_order_goods(1, 3)
		await _warten_auf_lieferung()
		await _pause_und_schlafen(true)
		for tag in tage:
			await _schicht()
			if erste_bilanz < 0.0:
				erste_bilanz = zeit
			_tageszeile()
			if tag < tage - 1:
				await _pause_und_schlafen(false)
			if tag % 5 == 4:
				print("  Tag %d · Geld %d · Beliebtheit %d %% · Zelt %d" % [gm._day - 1, Game.money, roundi(gm._popularity), gm._tent_stage])

	## Pause: einkaufen wie ein vernünftiger Spieler, auf die Ware warten, schlafen.
	func _pause_und_schlafen(erster: bool) -> void:
		if not erster:
			_gehen(BUERO)
			_einkaufen()
			await _warten_auf_lieferung()
		_gehen(WOHNWAGEN)
		gm.net_sleep()

	func _einkaufen() -> void:
		var bericht: Dictionary = gm._last_report
		var bedient := int(bericht.get("served", 20)) + int(bericht.get("missed", 0))
		# Bier: Bedarf von gestern + 30 %, abzüglich Bestand
		var bier_bedarf := int(ceil(bedient * 0.75 * 1.3))
		var packs := int(ceil(float(maxi(0, bier_bedarf - int(gm._stock[gm.WARE_BIER]))) / 10.0))
		if packs > 0:
			gm.net_order_goods(1, clampi(packs, 1, 20))
		if not gm._foods_avail().is_empty():
			var essen_bedarf := int(ceil(bedient * 0.35 * 1.3))
			var ep := int(ceil(float(maxi(0, essen_bedarf - int(gm._stock[gm.WARE_ESSEN]))) / 10.0))
			if ep > 0:
				gm.net_order_goods(2, clampi(ep, 1, 10))
		# Ausbauten der Reihe nach, solange Geld über der Reserve bleibt.
		# Mehr als 2 Tische nur mit Kellner — allein schafft man sie nicht.
		if _anzahl(2) == 0 and gm._active_count >= 2 and Game.money > 500 + RESERVE:
			gm.net_hire_staff(2)
		var limit: int = gm.TENT_TABLE_LIMIT[gm._tent_stage]
		if _anzahl(2) == 0:
			limit = mini(limit, 2)
		while gm._active_count < limit and Game.money > gm.TABLE_COST + RESERVE:
			var vorher: int = gm._active_count
			gm.net_buy_table()
			if gm._active_count == vorher:
				break
		if _anzahl(2) == 0 and Game.money > 500 + RESERVE:
			gm.net_hire_staff(2)
		if _anzahl(3) == 0 and gm._day >= 3 and Game.money > 400 + RESERVE:
			gm.net_hire_staff(3)
		if not gm._has_toilet and Game.money > gm.TOILET_COST + RESERVE:
			gm.net_buy_toilet()
		# Zapfer ab 4 Tischen — spart Kellnern und Spieler das Zapfen
		if _anzahl(4) == 0 and gm._active_count >= 4 and Game.money > 450 + RESERVE:
			gm.net_hire_staff(4)
		# Personal passend zur Tischzahl: ein Kellner je 3 Tische
		while _anzahl(2) < ceili(gm._active_count / 3.0) and Game.money > 500 + RESERVE:
			var vorher_k := _anzahl(2)
			gm.net_hire_staff(2)
			if _anzahl(2) == vorher_k:
				break
		# Zeltausbau vor Lizenzen — sonst frisst das Geld den Ausbau immer wieder
		if gm._active_count >= limit and gm.TENT_UPGRADE_COST.has(gm._tent_stage + 1):
			if Game.money > int(gm.TENT_UPGRADE_COST[gm._tent_stage + 1]) + RESERVE:
				gm.net_upgrade_tent()
			else:
				return   # sparen
		for lic: String in ["weizen", "radler", "brezn", "sosis", "festbier", "hendl"]:
			if not gm._lic[lic] and Game.money > int(gm.LIC_COST[lic]) + RESERVE * 2:
				gm.net_buy_license(lic)
		# Koch erst, wenn es Essen gibt (sonst sperrt das Spiel)
		if not gm._foods_avail().is_empty() and _anzahl(1) == 0 and Game.money > 600 + RESERVE:
			gm.net_hire_staff(1)
		if not gm._foods_avail().is_empty() and _anzahl(1) == 0 and Game.money > 600 + RESERVE * 2:
			gm.net_hire_staff(1)
		if gm._active_count >= limit and gm.TENT_UPGRADE_COST.has(gm._tent_stage + 1) \
				and Game.money > int(gm.TENT_UPGRADE_COST[gm._tent_stage + 1]) + RESERVE:
			gm.net_upgrade_tent()
		# Kellner aufstufen, wenn viel liegen blieb
		if _anzahl(2) > 0 and int(bericht.get("missed", 0)) >= 8 and Game.money > 800 + RESERVE:
			gm.net_upgrade_staff(2)
		# Zweiter Kellner ab 6 Tischen oder wenn viel liegen blieb
		if _anzahl(2) == 1 and (gm._active_count >= 6 or int(bericht.get("missed", 0)) >= 15) \
				and Game.money > 500 + RESERVE:
			gm.net_hire_staff(2)

	func _anzahl(rolle: int) -> int:
		var n := 0
		for s in gm._staff_sim.values():
			if int(s.role) == rolle:
				n += 1
		return n

	## Lieferwagen abwarten und Pakete einräumen (Zeit läuft wie beim Spieler).
	func _warten_auf_lieferung() -> void:
		var sicherheit := 0
		while (not gm._pending.is_empty() or gm._van_state != 0 or not gm._packages.is_empty()) and sicherheit < 5000:
			sicherheit += 1
			if not gm._packages.is_empty():
				_pakete_einraeumen()
			await _schritt()

	func _pakete_einraeumen() -> void:
		for id in gm._packages.keys():
			var p: Node = gm._packages[id]
			var art := int(p.kind)
			var menge := int(p.amount)
			_gehen(ABLAGE)
			gm.net_pickup_package(id)
			_gehen(LAGER)
			gm.net_store_package(art, menge)

	func _schicht() -> void:
		leerlauf = 0.0
		ohne_bier = 0.0
		while gm._phase == gm.Phase.SHIFT:
			if beschaeftigt <= 0.0:
				_handeln()
			if int(gm._stock[gm.WARE_BIER]) <= 0 and gm._clock_hour() >= gm.GUEST_START_HOUR:
				ohne_bier += DT
			await _schritt()
		# Restliche Gäste gehen noch
		for k in 100:
			await _schritt()

	## Eine Handlung in der Schicht: Pakete > Gast bedienen > putzen > nichts.
	func _handeln() -> void:
		if not gm._packages.is_empty():
			_pakete_einraeumen()
			return
		var bester := -1
		var wenigste := 1e9
		for id in gm._guest_sim.keys():
			var g: Dictionary = gm._guest_sim[id]
			if int(g.ostate) == 1 and int(g.mode) == 1 and gm._has_stock(int(g.okind)) and float(g.patience) < wenigste:
				wenigste = float(g.patience)
				bester = id
		if bester >= 0:
			var g: Dictionary = gm._guest_sim[bester]
			_gehen(THEKE)
			# Fertiges von der Ausgabe spart das Zapfen
			if not gm._ausgabe_nehmen(int(g.okind), int(g.otype)):
				beschaeftigt += ZAPFEN
			_gehen(g.pos)
			gm.net_serve_guest(bester, int(g.okind), int(g.otype))
			if erster_gast < 0.0:
				erster_gast = zeit + beschaeftigt
			return
		if not gm._messes.is_empty():
			var mid: int = gm._messes.keys()[0]
			_gehen((gm._messes[mid] as Node3D).position)
			for k in 22:
				gm.net_clean(mid)
			beschaeftigt += PUTZEN
			return
		if gm._clock_hour() >= gm.GUEST_START_HOUR:
			leerlauf += DT

	# ------------------------------------------------------------ Hilfen
	## Laufweg als Zeitkosten (Luftlinie, grob).
	func _gehen(ziel: Vector3) -> void:
		var weg := Vector2(ziel.x - pos.x, ziel.z - pos.z).length()
		beschaeftigt += weg / TEMPO
		zeit += 0.0
		pos = Vector3(ziel.x, 0, ziel.z)

	func _schritt() -> void:
		gm._process(DT)
		zeit += DT
		beschaeftigt = maxf(0.0, beschaeftigt - DT)
		# Außerhalb der Schicht zählen Laufwege sofort als vergangene Zeit
		if gm._phase != gm.Phase.SHIFT and beschaeftigt > 0.0:
			var rest := beschaeftigt
			beschaeftigt = 0.0
			var n := int(rest / DT)
			for k in n:
				gm._process(DT)
				zeit += DT
		if int(zeit / DT) % 40 == 0:
			await get_tree().process_frame

	func _tageszeile() -> void:
		var b: Dictionary = gm._last_report
		var lic := 0
		for v in gm._lic.values():
			if v:
				lic += 1
		zeilen.append("%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d" % [
			int(b.get("day", 0)), Game.money, int(b.get("earn", 0)), int(b.get("net", 0)),
			int(b.get("rent", 0)), int(b.get("wages", 0)), int(b.get("goods", 0)),
			int(b.get("served", 0)), int(b.get("missed", 0)), int(b.get("urin", 0)),
			int(b.get("complaints", 0)), int(b.get("left", 0)), roundi(gm._popularity),
			gm._tent_stage, gm._active_count, _anzahl(2), _anzahl(3), _anzahl(1), lic,
			roundi(leerlauf), roundi(ohne_bier), gm._kredit_rest])

	func _speichern() -> void:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
		var f := FileAccess.open(CSV, FileAccess.WRITE)
		if f:
			f.store_string("\n".join(zeilen) + "\n")
			f.close()
		print("ERSTER GAST nach %d s (%.1f min)" % [roundi(erster_gast), erster_gast / 60.0])
		print("ERSTE BILANZ nach %d s (%.1f min)" % [roundi(erste_bilanz), erste_bilanz / 60.0])
		print("SAISON FERTIG: %s" % ProjectSettings.globalize_path(CSV))

	func _zurueck() -> void:
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".simbackup", echt)
				DirAccess.remove_absolute(echt + ".simbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame
