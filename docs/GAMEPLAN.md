# Oktoberfest Simulator — Spielplan & Checkliste

> Vision (Serdar, 2026-09-06): Es gibt eine **Außenwelt (Wasenplatz)**. Wir **buchen** zuerst ein
> **kleines Festzelt** und dürfen darin erstmal **max. 4 Tische** aufstellen. Später **expandieren**
> wir → größeres Zelt, mehr Tische, mehr Gäste. Schichtende → zurück zum **Wohnwagen**, schlafen,
> nächster Tag. Aufbau wie klassische Simulatoren (Supermarket Simulator, PlateUp!).

## 1. Recherche — was die Klassiker gemeinsam haben

**Supermarket Simulator**
- Fester Tag-Zyklus (~20 min): öffnen → verkaufen → schließen → Markt/Preise analysieren.
- Loop: Ware bestellen → Regale einräumen → Kunden kassieren → Gewinn reinvestieren.
- Progression über **Store-Level** → schaltet neue 4×4m-Zonen frei (expand statt alles am Anfang).
- Kernspannung: **Stockout vermeiden** (leeres Regal während Nachfrage).

**PlateUp!**
- Zwei klar getrennte Phasen pro Tag: **Prep-Phase** (Layout, kaufen, automatisieren) ↔ **Service-Phase** (Gäste bedienen).
- **Nacht ab 75%** der Zeitleiste → Geduld sinkt schneller (Endspurt-Druck).
- Zwischen den Tagen: umbauen + **Upgrade/Schwierigkeits-Karte wählen** (permanente Progression).

**Übertragung auf Oktoberfest** → 3 verschachtelte Loops:
- **Makro:** Wasenplatz-Hub → Zelt buchen/upgraden, Wohnwagen (Tag beenden/schlafen).
- **Meso (pro Tag):** Aufbau/Mola (Tische stellen, Rollen wählen, einkaufen) ↔ Schicht (bedienen).
- **Mikro (in der Schicht):** Gäste sitzen → bestellen → Mutfak kocht/zapft → Garson serviert → Temizlik putzt.

## 2. Zielgerüst des Spiels

```
[Wohnwagen]  --schlafen-->  Tag N+1
    ^                           |
    | Schicht vorbei            v
[Schicht/Service] <----- [Wasenplatz-Hub / Zelt-Aufbau (Mola)]
                              |  Zelt buchen (Stufe 1..)
                              |  Tische kaufen/platzieren (Limit je Zeltstufe)
                              |  Rollen wählen (Mutfak/Temizlik/Garson)
                              |  Vorräte / Upgrades kaufen
```

- **Zeltstufen:** Stufe 1 = kleines Zelt, max 4 Tische (24 Sitze). Stufe 2/3 = größere .tscn-Zelte, mehr Tischlimit + höhere Grundbeliebtheit.
- **Tischlimit** ist an die Zeltstufe gekoppelt (nicht frei unendlich).
- **Geld** ist die einzige Ressource für Buchung + Tische + Upgrades. START_MONEY=1200 — genug für Zelt (500) + 2 Tische (400) + ein Paket Bier (60), damit der Einstieg spielbar ist.

## 3. Checkliste (Reihenfolge = Umsetzungsplan)

### Faz A — Makro-Loop Gerüst (Priorität)
- [x] A1. **Wasenplatz-Außenszene** — als `Wasen`-Node in main.tscn (v42): Gras/Weg/Bäume/Willkommensschild, Außengrenzen. Kiosk + Wohnwagen stehen draußen davor.
- [x] A2. **GameState erweitert:** Tag-Zähler (Wiesn-Tag 1..16) + Zeltstufe + aktive Tischzahl, alles über `net_meta` synced (v41).
- [x] A3. **Zelt buchen (Kiosk):** `net_book_tent` (500€) → Stufe 1; `net_upgrade_tent` (Stufe 2/3). Ohne Buchung startet keine Schicht (v41).
- [x] A4. **Wohnwagen/Schlafen:** `net_sleep` → Tag++ + Miete −150€/Tag, Wiesn-Tag-HUD (v41).
- [x] A5. **Übergang Wasen ↔ Zelt** — räumlich gelöst (v42): Eingangslücke in Nordwand, man läuft physisch rein/raus (kein Teleport, MP-sicher in einer Welt). Offen/Optik: Tent-Mesh hat an der Lücke noch sichtbare Zeltwand (Faz E).

### Faz B — Aufbau/Prep sauber
- [x] B1. **Tischlimit je Zeltstufe** (Stufe 1=4, Stufe 2=8, Stufe 3=12) + Kauf-UI im Kiosk-Panel (v41/v45).
- [x] B2. **Tische kaufen/verkaufen + verschieben:** `net_buy_table` (200€), `net_sell_table` (+100€), verschieben (mola) — v43. Grid/Snap-Feinschliff später.
- [x] B3. **Rollenwahl** am Computer (Mutfak/Temizlik/Garson); leere Rolle = Tasarom-NPC (seit v26).
- [x] B4. **Upgrades-Shop (Kiosk):** Werbung (+Beliebtheit-Schub) & Deko (+Einnahmen) mit Leveln — v44.

### Faz C — Schicht/Service (Feinschliff bestehend)
- [x] C1. Gäste kommen nach Beliebtheit, sitzen ganze Schicht, bestellen wiederholt + feiern (v38-40).
- [x] C2. **Nacht-Endspurt** — son %25 sabır 1.8x hızlı azalır + HUD 🌙 + banner (v43).
- [x] C3. Sarhoşluk → **Kusma-Animation** (Gast beugt sich vor, 🤮, erzeugt Dreck) → Temizlik/Hijyen (v48).
- [x] C4. Tagesabschluss-**Bilanz** im Wohnwagen (Kazanç/Kira/Net/Servis/Kaçırılan) beim Schlafen (v43).

### Faz D — Progression & Expand
- [x] D1. **Zelt-Ausbau real:** 12 Tische (3×4) in main.tscn, Tischlimit 4/8/12 je Stufe, natürliche Tischsortierung (v45). (Eigene größere Zelt-Meshes für L2/L3 = Optik, Faz E.)
- [x] D2. Freischalt-Kurve: Sorten öffnen sich nach Tag (Sosis T2, Weizen T3, Radler T5) + Unlock-Meldung (v46).
- [x] D3. Ökonomie-Balance: Miete steigt täglich (150€ + 40€/Tag), Bilanz zeigt echte Tagesmiete (v46).

### Faz E — Politur (später)
- [x] E1. Optik: Nacht-Beleuchtung ✅ (v47), **Zeltwand an der Eingangslücke entfernt** — echter offener Eingang, Laternen beleuchten ihn (v48). Später optional: größere Zelt-Meshes für Stufe 2/3.
- [x] E5. **pck verkleinert: 216 MB → 96 MB** (Texturen auf 2048 begrenzt, VRAM-Kompression) — v48.
- [ ] E2. Echte Audio-Assets statt prozedural. — **braucht Dateien von dir** (lizenzfreie Musik/SFX); prozedurale Sounds laufen bis dahin.
- [x] E3. **Speichern/Laden** — Geld/Tag/Zeltstufe/Tische/Upgrades/Beliebtheit in `user://oktoberfest_save.json`, bei jedem Zustandswechsel gespeichert, beim Start geladen (v48).
- [ ] E4. Steam/itch-Seite. — **braucht deinen Account + Freigabe**; Store-Texte kann ich vorbereiten.

## 4. Technische Leitplanken (fix)
- **Alles als .tscn/Node**, editierbar in Godot — kein prozeduraler Weltaufbau im Code. (Ausnahme: HUD-Overlay.)
- Multiplayer host-as-server (ENet); neue State-Felder via bestehende `_net_*` sync + `net_meta`.
- Deploy: pck-Export → web root + version.json++ ; class_name-Änderungen → Server-Editor-Rescan vor restart.
- Autoloads (net.gd/game.gd/project.godot) kommen NICHT per pck — brauchen exe-Rebuild + BASE_VERSION++.
- **Texturen: `process/size_limit=2048`** in jeder `.import` — sonst wächst die pck explosionsartig (4K-Backtexturen: 216 MB → 96 MB).

## 4a. Die Map selbst bearbeiten (für Serdar)

**Alles liegt in `scenes/main.tscn`.** Dort öffnen und im Szenenbaum umstellen — nichts davon wird von Code überschrieben:

| Node | Was drin ist |
|---|---|
| `Tent` | Das Zelt (Wände/Dach/Laternen) — `scenes/tent.tscn` |
| `Walls` | Kollision des Zeltes. **Nordwand ist geteilt** (`WallNorthW`/`WallNorthE`) → dazwischen der Eingang |
| `Bar` | Die 9 Theken-Teile |
| `Stations` | Zapfhähne (`beer_type` 1-3), Küche (`food_type` 1-2), Krugausgabe |
| `Tables` | **12 Biertische.** Verschieben = neue Sitzplätze. Reihenfolge zählt: `BeerTable0` wird als erster freigeschaltet |
| `Wasen` | Außenwelt: `Grass`, `Path`, `Sign`, Bäume, `Attraktionen`, Außenmauern |
| `Wasen/Attraktionen` | Die Jahrmarkt-Buden (Drehscheibe, Enten, Schießstand, Süßigkeiten) |
| `BookingKiosk` / `Caravan` | Buchungskiosk und Wohnwagen |
| `SpawnPoints` | Wo Spieler starten (4 Marker) |

**Wichtige Regeln beim Umbauen:**
- **Tische:** immer als Instanz von `scenes/beer_table.tscn`. Der Name muss auf eine Zahl enden (`BeerTable12`) — danach wird sortiert. Sitzplätze kommen automatisch aus dem `Seats`-Node im Prefab.
- **Zelt vergrößern?** Dann `Walls`-Kollision mitziehen, sonst laufen Spieler durch.
- **Eingang verschieben?** `WallNorthW`/`WallNorthE` anpassen **und** in `game_manager.gd` die Konstante `ENTRANCE` — dort erscheinen die Gäste.

## 4b. Neue Assets einbauen (Rezept)

1. **`.glb` nach `assets/models/` legen.** Keine Umlaute im Dateinamen (`süssigkeiten` → `suessigkeiten`).
2. **Godot einmal öffnen** → importiert automatisch.
3. **Texturlimit setzen** (sonst bläht sich die pck auf): in Godot die neuen Texturen anwählen → Reiter *Import* → `Process → Size Limit = 2048` → *Reimport*.
4. **Prefab bauen** — neue Szene in `scenes/props/`, Aufbau wie bei den vorhandenen:
   ```
   Node3D  (Wurzel, benannt wie das Objekt)
   ├── Model            → das .glb instanziert, y = halbe Höhe (Modelle sind mittig zentriert!)
   └── Body (StaticBody3D)
       └── CollisionShape3D → BoxShape3D in Modellgröße, gleiche y-Verschiebung
   ```
5. **In `main.tscn` ziehen** — Attraktionen unter `Wasen/Attraktionen`, Zeltmöbel unter `Tables`.

**Modellgröße herausfinden** (statt raten) — Pfade in `tools/measure_aabb.gd` eintragen, dann:
```bash
godot --headless --path . --script res://tools/measure_aabb.gd
```
Gibt Breite/Höhe/Tiefe und Mittelpunkt aus → daraus Box-Größe und y-Verschiebung ablesen.

**Soll das Objekt benutzbar sein** (wie Kiosk/Computer)? Dann zusätzlich ein Skript mit `class_name` anlegen, im `_ready()` `add_to_group("interactable")`, und in `player.gd::_handle_interaction` einen `elif _current_target is DeinTyp:`-Zweig ergänzen. **Achtung:** neuer `class_name` ⇒ beim Deploy muss der Server seinen Klassencache neu scannen (siehe oben).
