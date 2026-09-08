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

### E3 — Mitarbeiter (das Herzstück) ⭐
- [ ] E3.1 Einstellen im Büro: **Koch · Kellner · Reinigungskraft**, je mit Lohn/Schicht
- [ ] E3.2 **Level 1–10.** Kellner: trägt Lv1 = 1 Krug → Lv10 = 10 Krüge. Koch: Zubereitungstempo. Reinigung: Putztempo
- [ ] E3.3 Mitarbeiter-KI: Kellner holt Bestellungen → Theke → Gast. Koch füllt/kocht. Reinigung putzt Dreck/Urin
- [ ] E3.4 Löhne werden pro Schicht abgezogen, erscheinen im Report
- [ ] E3.5 Aufstufen kostet Geld (oder Erfahrung über Schichten)

### E4 — Wirtschaft & Report
- [ ] E4.1 **Ware einkaufen** im Büro (Bierfässer, Zutaten) → landet im Lager
- [ ] E4.2 **Ware verräumen**: aus dem Lager in Küche/Theke bringen (Spieler + Mitarbeiter)
- [ ] E4.3 Leere Fässer/Zutaten = kein Verkauf → Druck, rechtzeitig nachzufüllen
- [ ] E4.4 **Schichtreport**: Umsatz · Zeltmiete · Löhne · Wareneinsatz · Beliebtheit ± · Gewinn

### E5 — Bühne, Künstler & Stimmung
- [ ] E5.1 **Bühne** im Zelt + **Discolicht** (farbige, animierte Lichter — dauerhaft an)
- [ ] E5.2 Künstler treten auf (Bean-Modelle mit Dance-Animation, die existiert)
- [ ] E5.3 **Künstler buchen** im Büro: teuer, bringt viele Gäste (Beliebtheit + Gästezahl)

### E6 — Details, die es lebendig machen
- [ ] E6.1 **Kein Klo im kleinen Zelt** → Gäste pinkeln in die Ecke
- [ ] E6.2 Urin/Dreck → andere Gäste beschweren sich, stehen auf, gehen → Beliebtheit sinkt
- [ ] E6.3 **Klo kaufbar/Teil größerer Zelte** → Problem verschwindet
- [ ] E6.4 Alles davon sichtbar im Report

### E7 — Kirmes-Besucher (Kulisse)
- [ ] E7.1 NPCs laufen draußen zwischen den Ständen herum (Wegpunkte, kein Zeltbezug)
- [ ] E7.2 Dichte je nach Tageszeit — abends voll

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
