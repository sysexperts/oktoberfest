# Oktoberfest Simulator — Plan v2: Die Kirmes

> Ersetzt ab hier `GAMEPLAN.md` als Leitplan. Das alte Dokument bleibt als Historie
> (Faz A–E sind fertig und live, Stand v53).

## 1. Die Vision (Serdars Worte, verdichtet)

Der Spieler ist **Betreiber eines Festzelts auf einer Kirmes**. Er läuft nicht als Kellner
herum, sondern **stellt Personal ein** und optimiert den Betrieb. Alles wird im
**Wiesenbüro** gekauft. Ziel: kleines Zelt → großes Zelt, besseres Personal, mehr Gäste.

**Bestätigte Entscheidungen (2026-09-08):**
- **Spielerrolle: Hybrid.** Mitarbeiter tragen die Schicht. Der Spieler springt überall
  mit ein, wo er gerade frei ist, um den Gewinn zu maximieren. → FPS-Steuerung bleibt.
- **Assets:** Platzhalter so nah wie möglich am Endzustand, vorhandene Assets
  weiterverwenden. Echte Modelle kommen später und werden dann ausgetauscht.
- **Reihenfolge:** von mir festgelegt (siehe §3).

## 2. Die Welt

```
            ┌──────────── KIRMES (geschlossene Map) ────────────┐
            │   Stand  Stand  Stand  Stand  Stand  Stand        │
            │ Stand                                     Stand   │
            │         ┌───────────────────────┐                 │
            │ Stand   │      FESTZELT         │        Stand    │
            │         │   (Bühne, Theke,      │                 │
            │ Stand   │    Tische, Klo)       │        Stand    │
            │         └───────────────────────┘                 │
            │ Stand      [WIESENBÜRO]                   Stand   │
            │   Stand  Stand   Stand   Stand   Stand            │
            │                              [WOHNWAGEN-PLATZ]    │
            └───────────────────────────────────────────────────┘
```

- **Festzelt in der Mitte**, Stände ringsherum, **Wiesenbüro** und **Wohnwagenplatz** am Rand.
- **Draußen laufen Besucher-NPCs** zwischen den Ständen herum — die Kirmes soll voll wirken.
  Diese gehen *nicht* ins Zelt; sie sind Kulisse und Stimmung.
- **Während der Vorbereitungszeit (Zelt mieten, aufbauen) ist die Kirmes leer** — keine NPCs.

## 3. Etappenplan (Reihenfolge = Umsetzung)

### E1 — Kirmes-Map (Weltgerüst) 🔨
Das Fundament, auf dem alles andere steht. Ohne die Map müsste später alles zweimal platziert werden.
- [ ] E1.1 Kirmes-Grundfläche: Zelt mittig, Ringweg drumherum, Außengrenze
- [ ] E1.2 Ständering aus den vorhandenen Buden (Drehscheibe/Enten/Schießstand/Süßigkeiten + Theke-Buden), gedreht zum Weg
- [ ] E1.3 **Wiesenbüro** als Gebäude (Platzhalter) mit Eingang + Schreibtisch-NPC
- [ ] E1.4 **Wohnwagenplatz** (mehrere Wohnwagen, deiner ist markiert)
- [ ] E1.5 Spawn + Wegführung: Spieler startet am Wohnwagen, Zelteingang bleibt erreichbar

### E2 — Wiesenbüro als zentrale Anlaufstelle
Ersetzt Buchungskiosk **und** Computer. Ein NPC am Schreibtisch, ein Menü mit Reitern.
- [ ] E2.1 Büro-NPC am Schreibtisch (Bean-Modell, sitzend — Pose existiert schon)
- [ ] E2.2 Menü mit Reitern: **Zelt · Lizenzen · Personal · Künstler · Ware**
- [ ] E2.3 Zelt mieten/vergrößern hierher umziehen (weg vom Kiosk)
- [ ] E2.4 **Lizenzen**: Start = nur Bier. Kaufbar: Weizen/Radler → Brezn/Sosis → mehr

### E3 — Mitarbeiter (das Herzstück) ⭐ — v59
- [x] E3.1 Einstellen im Büro: **Koch 600€ · Kellner 500€ · Reinigung 400€**, Lohn 120/100/80€ pro Schicht
- [x] E3.2 **Level 1–10.** Kellner trägt Lv Krüge · Koch beschleunigt Essen · Reinigung putzt schneller · alle laufen schneller
- [x] E3.3 Mitarbeiter-KI: Kellner sammelt Bestellungen → Theke → liefert aus. Koch steht in der Küche. Reinigung läuft zum nächsten Dreck
- [x] E3.4 Löhne pro Schicht abgezogen, stehen in der Tagesbilanz
- [x] E3.5 Aufstufen kostet 400€ × aktuelles Level
- **Offen:** Kündigen, Koch als eigene Station (kommt mit E4/Ware), Erfahrung statt Bezahl-Upgrade

### E4 — Wirtschaft & Report — v60
- [x] E4.1 **Ware bestellen** im Büro (🍺 Bier 60€ / 🥨 Zutaten 80€ pro Paket à 10 Einheiten)
- [x] E4.2 **Lieferung nach ~60 s**: Lieferwagen fährt vor, lädt Pakete ab, hupt zweimal „düt düt", fährt weiter. Pakete mit E aufnehmen → **Lagerregal** im Zelt
- [x] E4.3 Leeres Lager = kein Verkauf. Kellner nehmen Bestellungen ohne Bestand gar nicht erst an
- [x] E4.4 **Schichtreport**: Umsatz · Miete · Löhne · Wareneinsatz · Netto · serviert/verpasst

### E5 — Bühne, Künstler & Stimmung — v61
- [x] E5.1 **Bühne** im Zelt (Podest, Rückwand, Traverse) + **Discolicht**, läuft immer
- [x] E5.2 Künstler tanzen während der Schicht auf der Bühne
- [x] E5.3 **Künstler buchen** im Büro: 🎸 500€ (+15%) · 🎺 2000€ (+35%) · ⭐ 6000€ (+60% Andrang), gilt für die nächste Schicht

### E6 — Details, die es lebendig machen — v62
- [x] E6.1 Gäste haben eine Blase. **Ohne Klo pinkeln sie in die Ecke** (gelber Fleck)
- [x] E6.2 Gäste im Umkreis beschweren sich → Beliebtheit sinkt, 25% davon stehen auf und gehen
- [x] E6.3 **Toilette 1800€** im Büro → Problem verschwindet
- [x] E6.4 Urin-, Beschwerde- und Weggeher-Zähler im Tagesreport

### E7 — Kirmes-Besucher (Kulisse) — v63
- [x] E7.1 NPCs laufen draußen auf dem Ringweg zwischen den Ständen, bleiben ab und zu stehen
- [x] E7.2 Dichte aus der Uhrzeit: morgens leer, abends voll · geschlossen = niemand da
- Läuft **rein lokal** auf jedem Client (kein Netz-Traffic). Anzahl über `Crowd → max_visitors` einstellbar

## 4. Was bleibt, was fliegt

**Bleibt (funktioniert und passt):**
Gäste sitzen die ganze Schicht und bestellen nach · Sitzplatz-System aus `beer_table.tscn` ·
Tagesuhr 07:00–22:00 mit Gästekurve · Nacht/Abend-Beleuchtung · Speichern/Laden ·
Multiplayer host-as-server · Hygiene/Dreck · Beliebtheit

**Wird ersetzt:**
- `BookingKiosk` → **Wiesenbüro**
- `Computer` (Rollenwahl) → **Personal im Wiesenbüro**. Die alten Spielerrollen
  (Mutfak/Temizlik/Garson) entfallen — im Hybrid-Modell hilft jeder überall mit,
  die Rollen werden von *Mitarbeitern* besetzt.
- `Wasen` (nur nördlich) → **Kirmes rundherum**

**Wird umgebaut:**
- Zeltstufen: nicht nur mehr Tische, sondern **wirklich größere Zelt-Szenen** (klein/mittel/groß)

## 5. Technische Leitplanken (gelten weiter)
Siehe `GAMEPLAN.md` §4/§4a/§4b — alles als editierbare `.tscn`-Nodes, Texturlimit 2048,
Deploy-Ablauf, `class_name` ⇒ Server-Rescan. Neue Regel:
- **Platzhalter immer als eigenes Prefab in `scenes/props/`**, damit ein späterer
  Asset-Tausch nur eine Datei betrifft.
