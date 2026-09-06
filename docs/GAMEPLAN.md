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
- [x] A1. **Wasenplatz-Außenszene** — als `Wasen`-Node in main.tscn (v42): Gras/Weg/Bäume/Willkommensschild, Außengrenzen. Kiosk + Wohnwagen stehen draußen davor.
- [x] A2. **GameState erweitert:** Tag-Zähler (Wiesn-Tag 1..16) + Zeltstufe + aktive Tischzahl, alles über `net_meta` synced (v41).
- [x] A3. **Zelt buchen (Kiosk):** `net_book_tent` (500€) → Stufe 1; `net_upgrade_tent` (Stufe 2/3). Ohne Buchung startet keine Schicht (v41).
- [x] A4. **Wohnwagen/Schlafen:** `net_sleep` → Tag++ + Miete −150€/Tag, Wiesn-Tag-HUD (v41).
- [x] A5. **Übergang Wasen ↔ Zelt** — räumlich gelöst (v42): Eingangslücke in Nordwand, man läuft physisch rein/raus (kein Teleport, MP-sicher in einer Welt). Offen/Optik: Tent-Mesh hat an der Lücke noch sichtbare Zeltwand (Faz E).

### Faz B — Aufbau/Prep sauber
- [x] B1. **Tischlimit je Zeltstufe** (Stufe1=4, Stufe2/3=6) + Kauf-UI im Kiosk-Panel (v41).
- [x] B2. **Tische kaufen/verkaufen + verschieben:** `net_buy_table` (200€), `net_sell_table` (+100€), verschieben (mola) — v43. Grid/Snap-Feinschliff später.
- [ ] B3. **Rollenwahl** am Computer beibehalten; leere Rolle = Tasarom-NPC.
- [x] B4. **Upgrades-Shop (Kiosk):** Werbung (+Beliebtheit-Schub) & Deko (+Einnahmen) mit Leveln — v44.

### Faz C — Schicht/Service (Feinschliff bestehend)
- [ ] C1. Gäste kommen nach Beliebtheit, sitzen ganze Schicht, bestellen wiederholt (steht, balancing v40).
- [x] C2. **Nacht-Endspurt** — son %25 sabır 1.8x hızlı azalır + HUD 🌙 + banner (v43).
- [~] C3. Sarhoşluk → Kusma/Kir → Temizlik/Hijyen (mess/hijyen var; kusma animasyonu yok).
- [x] C4. Tagesabschluss-**Bilanz** im Wohnwagen (Kazanç/Kira/Net/Servis/Kaçırılan) beim Schlafen (v43).

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
