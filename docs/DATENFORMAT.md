# Datenformat für Quests, Mails und Hinweise (P1, umgesetzt)

Stand 06.10.2026. Die Daten liegen als **JSON** unter `daten/` (`quests.json`, `mails.json`, `hinweise.json`) und werden von `scripts/story/daten.gd` geladen. Die Logik steht in `scripts/story/story.gd` (Node „Story" in `scenes/main.tscn`).
Alle **Texte** stehen nicht im JSON, sondern in `locale/texte.csv` unter Schlüsseln (DE, EN, TR, Du/Ihr mit `_DU`/`_IHR`). Das JSON hat nur Struktur, Auslöser und Bedingungen.
Das System ist mit `aktiv = false` abgeschaltet (das alte Tutorial läuft weiter) und wird in **P3** eingeschaltet.

## Quests (`daten/quests.json`)

```json
{
  "id": "2.1",
  "typ": "haupt",                 // haupt | neben | gefallen | kirmes
  "kapitel": 2,
  "titel": "Q_2_1_TITLE",
  "text": "Q_2_1_TEXT",
  "ausloeser": {"nach": "1.9", "kapitel": 2},
  "bedingung": {"mw": "personal_kellner", "min": 1},
  "frist_tage": 0,                // 0 = keine Frist (Hauptquests haben nie eine)
  "belohnung": {"geld": 100},     // geld, beliebtheit
  "mail_erfuellt": ["M2-02"],     // Mails, die nach Erfüllung kommen
  "kapitelabschluss": 2           // optional: erfüllt = Kapitel 2 ist zu Ende, Kapitel 3 beginnt
}
```

**Auslöser** (alle genannten Schlüssel müssen zutreffen): `{"start": true}` · `{"nach": "1.9"}` (Quest erfüllt) · `{"kapitel": 2}` · `{"flag": "name"}` · `{"mw": "schluessel", "min": n}` · `{"zufall": {"ab_kapitel": 2, "bis_kapitel": 2, "chance": 0.5}}` (täglich gewürfelt, nur Neben, Gefallen, Kirmes) · `{"mail": "M1-01"}` (Mail beim Freischalten senden).

**Bedingungen:** `{"mw": "zelt_stufe", "min": 2}` (Messwert aus dem Spiel) · `{"flag": "geschlafen"}` (Ereignis gemeldet, bei Zahl `"min"`) · `{"quest": "1.9"}` · `{"alle": [...]}` · `{"einer": [...]}` · `{"nicht": {...}}`.

**Messwerte** (`_story_messwerte()` im GameManager): `zelt_stufe`, `tische`, `personal_koch/kellner/reinigung/zapfer`, `lizenzen`, `toilette`, `kuenstler`, `bier_bestellt`, `lieferung_da`, `pakete_eingeraeumt`, `geschlafen`, `gaeste_bedient`, `gaeste_heute`, `feierabend`, `zelt_sauber`, `schulden_bezahlt`, `schulden_rest`. Neue Messwerte kommen mit den späteren Phasen dazu.
**Ereignisse** (`story.ereignis("name", wert)`): z. B. `horst_zusage`, `pfuetzenfreier_tag`.

**Zustände:** `angeboten` (Neben/Gefallen/Kirmes, wartet auf Antwort) · `offen` · `erfuellt` · `verfallen`. Hauptquests starten sofort als `offen`.
**Limits:** eine Hauptquest und höchstens drei andere gleichzeitig offen (`MAX_HAUPT`, `MAX_ANDERE`), höchstens zwei Angebote warten (`MAX_ANGEBOTE`).
**Fristen:** `frist_tage` zählt ab Angebot in Spieltagen herunter, bei 0 verfällt die Quest und die Mail `M-VERFALLEN` („Zu spät …") kommt.

## Mails (`daten/mails.json`)

```json
{
  "id": "M2-13",
  "absender": "HORST",             // Schlüssel für den Absender (ABSENDER_HORST)
  "betreff": "MAIL_M2_13_BETREFF",
  "text": "MAIL_M2_13_TEXT",
  "antworten": [
    {"text": "MAIL_M2_13_A1", "folge": {"quest_annehmen": "N-2-1"}},
    {"text": "MAIL_M2_13_A2", "folge": {"quest_ablehnen": "N-2-1"}}
  ],
  "mehrfach": true                 // optional: darf mehrfach kommen
}
```

**Folgen einer Antwort:** `quest_annehmen`, `quest_ablehnen`, `quest_starten`, `flag`, `mail`, `kapitel` (von der Story selbst), `geld`, `beliebtheit` (Belohnung, GameManager) und alle anderen Schlüssel (`mitarbeiter_fehlt_tage`, `lohn_faktor_tag` …) gehen an `story_folge()` im GameManager und kommen in späteren Phasen.

## Hinweise (`daten/hinweise.json`)

```json
{"id": "H-PFUETZE", "ausloeser": "erste_pfuetze", "text": "HINT_PFUETZE_1"}
```
`story.hinweis_zeigen("erste_pfuetze")` gibt den Text-Schlüssel genau einmal zurück.

## Netz und Speichern
Der Server rechnet. Der Stand (Kapitel, Quests, Post, Hinweise, Flaggen) steht im Spielstand unter `story` und im Büro-Zustand (`net_meta`) für die Clients. Antworten auf Mails laufen über `net_post_antwort(nr, antwort)` und `net_post_gelesen(nr)` am Server.

## Test
`godot --headless --path . res://tools/test_story.tscn` (Kapitel 1 bis 2, Zufallsangebote, Fristen, Mails, Speichern, Hinweise, Datenprüfung).
