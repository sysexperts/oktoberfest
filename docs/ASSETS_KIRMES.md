# Kirmes-Asset-Pack

126 Modelle aus dem gekauften „Amusement Park"-Pack, fertig in Godot importiert.

## Wo liegt was

```
assets/kirmes/
  Models/
    Attractions/   CableRailway, OtherRides, RollerCoaster, ShipRide, TopSpin, WaterRide, Wave
    Foliage/       Bäume, Büsche, Steine, Blumen, Teich
    Ground/        5×5 m Bodenkacheln: Grass, Dirt, Gravel, Sand, Parking, Road_*
    Props/         Bänke, Zäune, Lampen, Mülleimer, Absperrungen, Brunnen …
    Shops/         Buden, WC, Gazebo, OpenAirDisco, Park_Entrance …
    Vehicles/      Autos, Transporter, Van
  textures/        gemeinsame Paletten-Texturen
```

## Katalog zum Anschauen

`scenes/katalog_kirmes.tscn` im Editor öffnen: alle 126 Modelle liegen dort
nach Kategorie sortiert auf einem Raster, jedes mit Namensschild.

**So baust du damit die Map um:** Modell im Katalog auswählen → Strg+C →
`scenes/kirmes.tscn` öffnen → Strg+V → an die richtige Stelle ziehen.
Alternativ das `.fbx` direkt aus dem FileSystem-Dock in die Szene ziehen.

Der Katalog ist reine Anschauung und wird nie geladen — er kostet im Spiel nichts.

## Maßstab

Alle Modelle sind **in echten Metern** — Skalierung 1.0, nichts umrechnen.
Zur Orientierung: Bodenkachel 5×5 m, WC 3,4 m breit, Riesenrad 18 m hoch,
Bank 1,4 m, Laterne (`Lamp_1`) 2,7 m.

Die genauen Maße aller Modelle stehen in `tools/kirmes_sizes.json`.

## Kollision

Die FBX bringen **keine Kollisionsformen** mit. Für alles, wo man dagegenlaufen
soll, im Editor `StaticBody3D` + `CollisionShape3D` daruntersetzen — so wie es
`scenes/props/schiessstand.tscn` schon macht. Deko (Blumen, Steine, Bäume am
Rand) braucht keine.

## Werkzeuge

| Befehl | Zweck |
|---|---|
| `godot --headless --path . --script res://tools/scan_kirmes.gd` | misst alle Modelle neu → `tools/kirmes_sizes.json` |
| `godot --headless --path . --script res://tools/make_katalog.gd` | baut `scenes/katalog_kirmes.tscn` neu |

Beides nur nötig, wenn Modelle dazukommen oder verschwinden.

## Zwei Notlösungen im Pack

Drei FBX verweisen auf Texturen, die der Pack nicht mitliefert
(`Models/Shops/Texture.psd`, `Models/Vehicles/Texture.psd`,
`Models/Foliage/Color.jpg`). Ohne sie wären Buden, Fahrzeuge und ein Teil der
Bäume weiß. Als Ersatz liegen dort jetzt Kopien der Paletten-Texturen unter
genau diesen Dateinamen — deshalb nicht löschen.
