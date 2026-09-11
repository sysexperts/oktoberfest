extends Node3D
## Ping-Markierung (Spaß-Plan 5.3): ein Spieler zeigt seinen Mitspielern etwas —
## einen wartenden Gast, eine Pfütze, ein Paket. Sehen alle, verschwindet nach 5 s.
## Farbe je Spieler. Aufbau: scenes/ui/ping_marker.tscn.

const SYMBOLE := ["❗", "🍺", "🧽", "📦"]
const FARBEN := [Color(1, 0.85, 0.3), Color(0.4, 0.8, 1), Color(0.5, 1, 0.5), Color(1, 0.5, 0.8)]
const DAUER := 5.0

var _t := 0.0
var _basis_y := 0.0

func _ready() -> void:
	add_to_group("ping")

## art: 0 allgemein, 1 Gast, 2 Pfütze, 3 Paket · farbe: Spielernummer
func zeige(art: int, farbe: int) -> void:
	var symbol: Label3D = $Symbol
	var pfeil: Label3D = $Pfeil
	symbol.text = SYMBOLE[clampi(art, 0, SYMBOLE.size() - 1)]
	var c: Color = FARBEN[posmod(farbe, FARBEN.size())]
	symbol.modulate = c
	pfeil.modulate = c
	_basis_y = global_position.y + 2.4

func _process(delta: float) -> void:
	_t += delta
	global_position.y = _basis_y + sin(_t * 5.0) * 0.12
	var a := clampf((DAUER - _t) / 0.8, 0.0, 1.0)
	$Symbol.modulate.a = a
	$Pfeil.modulate.a = a
	if _t >= DAUER:
		queue_free()
