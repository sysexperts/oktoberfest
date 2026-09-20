extends Node
## Kurze Oberflächenklänge (assets/audio/sfx/ui_*.wav, erzeugt von
## tools/ui_klaenge_bauen.gd). Läuft über den SFX-Bus, damit der Regler in den
## Einstellungen greift.
##
## Mehrere Spieler im Wechsel, sonst schneidet ein schneller zweiter Klick den
## ersten ab — beim Wandern durch eine Liste fällt das sofort auf.
##
##   Klang.klick()  Knopf gedrückt
##   Klang.hover()  Maus wandert auf einen Knopf
##   Klang.wechsel()  andere Kategorie oder Reiter
##   Klang.zurueck()  schließen, abbrechen
##   Klang.schalter()  Schalter umgelegt
##   Klang.an_knoepfe(wurzel)  hängt die Klänge an alle Knöpfe darunter

const ORDNER := "res://assets/audio/sfx/%s.wav"
const SPIELER := 5
## Oberflächenklänge sollen leiser sein als Spielgeräusche
const PEGEL_DB := -6.0

var _spieler: Array[AudioStreamPlayer] = []
var _naechster := 0
var _klaenge := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # auch im pausierten Menü hörbar
	for name in ["ui_hover", "ui_klick", "ui_wechsel", "ui_zurueck", "ui_schalter"]:
		var pfad: String = ORDNER % name
		if ResourceLoader.exists(pfad):
			_klaenge[name] = load(pfad)
	for i in SPIELER:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_spieler.append(p)

func spiele(name: String, db: float = PEGEL_DB) -> void:
	if not _klaenge.has(name) or _spieler.is_empty():
		return
	var p := _spieler[_naechster]
	_naechster = (_naechster + 1) % _spieler.size()
	p.stream = _klaenge[name]
	p.volume_db = db
	p.play()

func hover() -> void: spiele("ui_hover", -14.0)
func klick() -> void: spiele("ui_klick")
func wechsel() -> void: spiele("ui_wechsel")
func zurueck() -> void: spiele("ui_zurueck")
func schalter() -> void: spiele("ui_schalter")

## Hängt Klänge an alle Knöpfe unter `wurzel`. Knöpfe, die schon verbunden sind,
## werden übersprungen — die Funktion darf also mehrfach laufen.
func an_knoepfe(wurzel: Node) -> void:
	for n in wurzel.get_children():
		if n is BaseButton and not n.has_meta("klang"):
			var k: BaseButton = n
			k.set_meta("klang", true)
			k.mouse_entered.connect(func() -> void:
				if not k.disabled:
					hover())
			if k is CheckButton or k is CheckBox:
				k.toggled.connect(func(_an: bool) -> void: schalter())
			elif k.toggle_mode:
				k.pressed.connect(wechsel)
			else:
				k.pressed.connect(klick)
		an_knoepfe(n)
