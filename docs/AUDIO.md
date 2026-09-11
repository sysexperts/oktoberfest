# Ton — was gebraucht wird

**Stand 2026-09-11:** eine Zeltmusik (`musik/zelt_01.mp3`), sonst noch keine
Audiodatei. Alles andere erzeugt `scripts/sfx.gd` als Ersatztöne — daher der
8-Bit-Eindruck.

Das System nimmt jetzt **echte Dateien, sobald sie da sind**, und fällt nur auf
die Piepstöne zurück, wo noch nichts liegt. Du musst also nichts programmieren:
Datei mit dem richtigen Namen in den richtigen Ordner legen, fertig.

## Format

**OGG Vorbis**, 44,1 kHz. Godot importiert `.ogg` direkt und es ist deutlich
kleiner als WAV. `.wav` und `.mp3` gehen auch, `.ogg` wird bevorzugt.

Musik und Ambiente müssen **nahtlos loopen**. Beim Import in Godot bei diesen
Dateien den Haken **Loop** setzen.

---

## Musik — `assets/audio/musik/`

Beliebig viele Dateien, der Name ist egal. Das Spiel mischt sie zufällig durch
und spielt nach jedem Stück das nächste.

| gebraucht | Länge | Stimmung |
|---|---|---|
| 3–5 Zeltstücke | je 2–4 min | Schlager, Blasmusik, Partystimmung — das, was im Festzelt läuft |
| 1 Menüstück | 1–2 min | ruhiger, Akkordeon, einladend |

Menüstück später `menue.ogg` nennen, dann kann ich es getrennt ansteuern.

### ⚠️ Kein echter Schlager

„Anton aus Tirol", „Fürstenfeld" und Konsorten sind **urheberrechtlich
geschützt** — die kann man nicht ins Spiel legen, auch nicht als Cover, auch
nicht kurz. Auf Steam fliegt das spätestens beim ersten Let's Play auf.

Was du brauchst, ist **Production Music im Schlager-/Blasmusik-Stil** mit
Lizenz für Spiele. Achte auf zwei Dinge:

- Die Lizenz muss **Videospiele** ausdrücklich abdecken, nicht nur „Video".
- **GEMA-frei** bzw. P.R.O.-frei. Ist der Komponist bei einer
  Verwertungsgesellschaft, kann trotz gekaufter Lizenz eine Meldepflicht
  bestehen.

Quellen, die Oktoberfest-Material führen: Proud Music Library (deutsche
Bibliothek, Lizenzstufen sauber getrennt), TunePocket (nennt Spiele explizit),
Epidemic Sound (eigene Spiele-Lizenz), Motion Array, AudioHub.

---

## Ambiente — `assets/audio/ambiente/`

| Datei | Länge | Inhalt |
|---|---|---|
| `kirmes.ogg` | 1–2 min, loopbar | Stimmengewirr, entfernte Fahrgeschäfte, Kirmesorgel |

Läuft draußen dauerhaft im Hintergrund.

---

## Soundeffekte — `assets/audio/sfx/`

Kurz, trocken, ohne Hall. Namen genau so, sonst werden sie nicht gefunden.

### Ersetzt bestehende Piepstöne

| Datei | Länge | Was |
|---|---|---|
| `pop.ogg` | 0,2 s | Krug abstellen, Klick, allgemeines Bestätigen |
| `ding.ogg` | 0,4 s | Bestellung fertig, Erfolg |
| `glug.ogg` | 1–2 s | Bier zapfen, Glucksen |
| `sizzle.ogg` | 0,5 s | Grill, Essen zubereiten |
| `scrub.ogg` | 0,8 s | Wischen, putzen |
| `splash.ogg` | 0,6 s | Kotze, Verschütten |
| `cheer.ogg` | 1,5 s | Prost, Jubel der Gäste |
| `honk.ogg` | 1 s | Lieferwagen — zweimal „düt düt" |

### Neu — fehlen bisher ganz

| Datei | Länge | Was |
|---|---|---|
| `kasse.ogg` | 0,6 s | Kassenklingel beim Verkauf |
| `zapfen.ogg` | 2 s | Zapfhahn auf, Schaum |
| `prost.ogg` | 1 s | Krüge klirren aneinander |
| `schritte.ogg` | 0,4 s | Schritt auf Kies |
| `tuer.ogg` | 0,5 s | Wohnwagentür |
| `muenzen.ogg` | 0,5 s | Trinkgeld |
| `fahrgeschaeft.ogg` | 2 s, loopbar | Motorbrummen, in der Nähe der Fahrgeschäfte |

**Alle sind angeschlossen** (Plan 4.1) und erklingen, sobald die Datei da ist:
`kasse` beim Bedienen · `muenzen` beim Trinkgeld fürs Putzen · `prost` mit der
Prost-Taste · `zapfen` beim Ansetzen am Fass · `schritte` beim Laufen ·
`tuer` beim Schlafen im Wohnwagen (bis dahin der Klick) · `fahrgeschaeft` als
Raumklang an jedem Fahrgeschäft · `musik/menue.ogg` als Menümusik.
Datei ablegen, neu exportieren — mehr ist nicht nötig.

---

## Mischpult

Es gibt jetzt drei Busse neben Master: **Musik**, **SFX**, **Ambiente**
(`default_bus_layout.tres`). Damit kann das spätere Optionsmenü drei getrennte
Regler anbieten, so wie man es erwartet.

---

## Lizenz nicht vergessen

Jede gekaufte Datei kommt mit Beleg ins Lizenzregister
(`docs/lizenzen/README.md`). Bei Musik ist das strenger als bei Modellen —
Musikrechte sind der häufigste Grund, warum Spiele nachträglich Ärger bekommen.
