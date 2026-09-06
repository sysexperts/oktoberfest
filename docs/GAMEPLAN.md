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
- **Geld** ist die einzige Ressource für Buchung + Tische + Upgrades. START_MONEY=0 zum Release (aktuell 10000 nur Test).

## 3. Checkliste (Reihenfolge = Umsetzungsplan)

### Faz A — Makro-Loop Gerüst (Priorität)
- [ ] A1. **Wasenplatz-Außenszene** (`scenes/wasen.tscn`): Boden/Himmel, Platz mit leerem Bauslot fürs Zelt, Wohnwagen-Objekt, Buchungs-Schild/Kiosk. Echte Nodes.
- [ ] A2. **GameState-Phasen erweitern:** `HUB` (Wasenplatz, frei laufen) ↔ `PREP` (im Zelt aufbauen) ↔ `SHIFT` ↔ `SLEEP`. Aktuell nur INTERMISSION/SHIFT.
- [ ] A3. **Zelt buchen:** am Kiosk interagieren → Stufe-1-Zelt für X€ mieten; erst danach betretbar. Zeltstufe in GameState + synced.
- [ ] A4. **Wohnwagen/Schlafen:** nach Schicht Interaktion "Schlafen" → Tag++ → zurück in HUB/PREP. Tageszähler + Datum (Wiesn-Tag 1..16).
- [ ] A5. **Übergänge/Teleport** zwischen Wasen ↔ Zeltinnenraum (Türtrigger oder Fade).

### Faz B — Aufbau/Prep sauber
- [ ] B1. **Tischlimit je Zeltstufe** durchsetzen (Stufe1=4). Kauf-UI im Zelt (nicht nur Computer).
- [ ] B2. **Tische kaufen + frei platzieren** (Grid/Snap), verschieben, verkaufen. (Move existiert schon → Kauf/Limit ergänzen.)
- [ ] B3. **Rollenwahl** am Computer beibehalten; leere Rolle = Tasarom-NPC.
- [ ] B4. **Vorräte/Upgrades-Shop:** z.B. schnellerer Zapfhahn, zweite Kochstation, Deko (+Beliebtheit).

### Faz C — Schicht/Service (Feinschliff bestehend)
- [ ] C1. Gäste kommen nach Beliebtheit, sitzen ganze Schicht, bestellen wiederholt (steht, balancing v40).
- [ ] C2. **Nacht-Endspurt** wie PlateUp: ab 75% Schichtzeit Geduld schneller sinkend.
- [ ] C3. Sarhoşluk → Kusma/Kir → Temizlik/Hijyen (teils da).
- [ ] C4. Tagesabschluss-**Bilanz** (Umsatz, Bahşiş, Beliebtheit ±, Kosten) im Wohnwagen vor dem Schlafen.

### Faz D — Progression & Expand
- [ ] D1. **Zelt-Upgrade** (Stufe 2/3): neue größere `zelt_L2.tscn`/`zelt_L3.tscn`, höheres Tischlimit, mehr Sitze.
- [ ] D2. Freischalt-Kurve: neue Bier-/Essenssorten, Deko, Personal-Slots je Fortschritt.
- [ ] D3. Ökonomie-Balance: Miete/Kosten pro Tag vs. Einnahmen (soll fordernd bleiben).

### Faz E — Politur (später)
- [ ] E1. Optik/Deko cozy, Lichter, Menschenmenge-Ambiente.
- [ ] E2. Echte Audio-Assets statt prozedural.
- [ ] E3. Speichern/Laden (Fortschritt über Sitzungen).
- [ ] E4. Steam/itch-Seite.

## 4. Technische Leitplanken (fix)
- **Alles als .tscn/Node**, editierbar in Godot — kein prozeduraler Weltaufbau im Code. (Ausnahme: HUD-Overlay.)
- Multiplayer host-as-server (ENet); neue State-Felder via bestehende `_net_*` sync + `net_meta`.
- Deploy: pck-Export → web root + version.json++ ; class_name-Änderungen → Server-Editor-Rescan vor restart.
- Autoloads (net.gd/game.gd/project.godot) kommen NICHT per pck — brauchen exe-Rebuild + BASE_VERSION++.
