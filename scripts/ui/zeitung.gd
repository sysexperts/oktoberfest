extends CanvasLayer
## „Wiesn-Kurier": nach Feierabend eine Zeitungsseite über den Tag (Schlagzeile
## aus den Zahlen der Tagesbilanz, ein paar Kurzmeldungen). Kommt bei jedem
## Spieler lokal mit der Bilanz (GameManager.net_report → HUD.set_report).
## Klick, E oder Enter schließt. Aufbau: scenes/ui/zeitung.tscn.
## Texte: ZEITUNG_* in locale/texte.csv.

const Texte := preload("res://scripts/ui/texte.gd")

@onready var _blatt: Control = %Blatt

var aktiv := false
var _t := 0.0
var _spieler: Node = null

func _ready() -> void:
	add_to_group("zeitung")
	visible = false

func laeuft() -> bool:
	return aktiv

## Bilanz des Tages (Schlüssel wie in GameManager._end_shift → net_report)
func zeigen(b: Dictionary, zustand: Dictionary) -> void:
	var welt := get_parent()
	_spieler = welt._players_nodes.get(multiplayer.get_unique_id()) if "_players_nodes" in welt else null
	if _spieler == null or aktiv:
		return
	var zelt := str(zustand.get("zelt_name", ""))
	if zelt == "":
		zelt = tr("TENT_NAME_DEFAULT")
	%Ausgabe.text = tr("ZEITUNG_AUSGABE") % int(b.get("day", 1))
	var kopf := schlagzeile(b, zelt)
	%Schlagzeile.text = kopf[0]
	%Unterzeile.text = kopf[1]
	%Meldungen.text = "\n".join(meldungen(b, zustand))
	%Zahlen.text = tr("ZEITUNG_ZAHLEN") % [int(b.get("served", 0)), Texte.euro(int(b.get("earn", 0))), int(b.get("pop", 0))]
	%Hinweis.text = tr("ZEITUNG_SCHLIESSEN")
	aktiv = true
	visible = true
	_t = 0.0
	_spieler.minispiel = self
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

## [Schlagzeile, Unterzeile] — die auffälligste Sache des Tages zuerst
static func schlagzeile(b: Dictionary, zelt: String) -> Array[String]:
	var bedient := int(b.get("served", 0))
	var t := func(k: String) -> String: return TranslationServer.translate(k)
	if bedient == 0:
		return [t.call("ZEITUNG_LEER") % zelt, t.call("ZEITUNG_LEER_UNTER")]
	if int(b.get("complaints", 0)) >= 5:
		return [t.call("ZEITUNG_BESCHWERDEN") % zelt, t.call("ZEITUNG_BESCHWERDEN_UNTER") % int(b.complaints)]
	if int(b.get("urin", 0)) >= 5:
		return [t.call("ZEITUNG_PFUETZEN") % zelt, t.call("ZEITUNG_PFUETZEN_UNTER") % int(b.urin)]
	if int(b.get("left", 0)) >= 10:
		return [t.call("ZEITUNG_GEGANGEN") % int(b.left), t.call("ZEITUNG_GEGANGEN_UNTER") % zelt]
	if int(b.get("net", 0)) < 0:
		return [t.call("ZEITUNG_VERLUST") % zelt, t.call("ZEITUNG_VERLUST_UNTER")]
	if bedient >= 100:
		return [t.call("ZEITUNG_REKORD") % bedient, t.call("ZEITUNG_REKORD_UNTER") % zelt]
	if int(b.get("pop", 0)) >= 80:
		return [t.call("ZEITUNG_BELIEBT") % zelt, t.call("ZEITUNG_BELIEBT_UNTER")]
	return [t.call("ZEITUNG_SOLIDE") % [zelt, bedient], t.call("ZEITUNG_SOLIDE_UNTER")]

## Kurzmeldungen: Huber, Schulden, Klo, Personal
static func meldungen(b: Dictionary, z: Dictionary) -> Array[String]:
	var m: Array[String] = []
	var t := func(k: String) -> String: return TranslationServer.translate(k)
	if int(z.get("kredit", 0)) > 0:
		m.append("• " + t.call("ZEITUNG_M_KREDIT"))
	var bank: Array = z.get("bank_naechste", [])
	if not bank.is_empty():
		m.append("• " + t.call("ZEITUNG_M_BANK") % [int(bank[0]), Texte.euro(int(bank[1]))])
	if not bool(b.get("toilet", true)):
		m.append("• " + t.call("ZEITUNG_M_KLO"))
	if int(b.get("missed", 0)) >= 5 and not bool(b.get("kellner", true)):
		m.append("• " + t.call("ZEITUNG_M_KELLNER"))
	# Küche: wer den ganzen Tag gekocht hat, stand vorher nirgends im Blatt
	var gekocht := int(b.get("gekocht", 0))
	if gekocht > 0:
		m.append("• " + t.call("ZEITUNG_M_KUECHE") % gekocht)
	elif int(b.get("served", 0)) > 0:
		m.append("• " + t.call("ZEITUNG_M_KUECHE_LEER"))
	var raus := int(b.get("rausgeworfen", 0))
	if raus == 1:
		m.append("• " + t.call("ZEITUNG_M_RAUSWURF_1"))
	elif raus > 1:
		m.append("• " + t.call("ZEITUNG_M_RAUSWURF") % raus)
	for e: Array in b.get("ehren", []):
		m.append("• " + String(TranslationServer.translate("MSG_EHRE_" + str(e[0]).to_upper())) % [str(e[1]), int(e[2])])
	var huber := ["ZEITUNG_M_HUBER_1", "ZEITUNG_M_HUBER_2", "ZEITUNG_M_HUBER_3", "ZEITUNG_M_HUBER_4"]
	m.append("• " + t.call(huber[int(b.get("day", 1)) % huber.size()]))
	return m

func eingabe(event: InputEvent) -> void:
	if _t < 0.4:
		return
	var mb := event as InputEventMouseButton
	if (mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT) or event.is_action_pressed("ui_accept") \
			or event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		schliessen()

func _process(delta: float) -> void:
	if not aktiv:
		return
	_t += delta
	_blatt.pivot_offset = _blatt.size * 0.5
	var k := minf(1.0, _t * 3.0)
	_blatt.scale = Vector2.ONE * lerpf(0.6, 1.0, k)
	_blatt.rotation = lerpf(-0.35, -0.03, k)

func schliessen() -> void:
	if not aktiv:
		return
	aktiv = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _spieler and is_instance_valid(_spieler) and _spieler.minispiel == self:
		_spieler.minispiel_beendet()
