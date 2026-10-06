# Datenformat für Quests und Mails (P0, Entwurf)

Stand 06.10.2026. Quests und Mails liegen als **JSON-Dateien** unter `data/` (neu, wird in P1 angelegt). Alle Texte stehen **nicht** in den JSON-Dateien, sondern in `locale/texte.csv` unter einem Schlüssel (DE, EN, TR, Du/Ihr wie bisher mit `_DU`/`_IHR`). Das JSON enthält nur Struktur, Auslöser und Bedingungen.

## Quests (`data/quests.json`)

```json
{
  "id": "2.1",
  "typ": "haupt",            // haupt | neben | gefallen | kirmes
  "kapitel": 2,
  "titel": "QUEST_2_1_TITLE",
  "text": "QUEST_2_1_TEXT",
  "ausloeser": {"nach": "1.9", "mail": "M2-01"},   // Quest erfüllt, Zeitpunkt (abend/morgen), zufällig, Ereignis
  "bedingung": {"art": "personal", "rolle": "kellner", "anzahl": 1},
  "frist_tage": 0,           // 0 = keine Frist (Hauptquests)
  "belohnung": {"geld": 100, "beliebtheit": 0, "gegenstand": ""},
  "danach": ["2.2"]
}
```

**Bedingungsarten** (Messgrößen, die der Server prüft): `personal`, `lizenz`, `toilette`, `kuenstler`, `zelt_stufe`, `schulden_abbezahlt`, `gaeste_bedient`, `umsatz`, `serviert_sorte`, `sauber_tag`, `gespraech`, `gegenstand_geliefert`, `wettschleppen`, `sud_gebraut`, `sud_qualitaet`, `sabotage_erledigt`, `person_getragen_zu`, `ort_betreten`, `casino_runde`, `fest_ausgerichtet`.

## Mails (`data/mails.json`)

```json
{
  "id": "M2-08",
  "absender": "STEFAN",          // Schlüssel für den Absendernamen (ABSENDER_STEFAN)
  "betreff": "MAIL_M2_08_BETREFF",
  "text": "MAIL_M2_08_TEXT",
  "ausloeser": {"art": "ereignis", "name": "krank"},
  "antworten": [
    {"text": "MAIL_M2_08_A1", "folge": {"mitarbeiter_fehlt_tage": 2}},
    {"text": "MAIL_M2_08_A2", "folge": {"lohn_faktor": 1.2}}
  ]
}
```

- `antworten` leer = keine Antwort nötig.
- Folgen sind Schlüssel mit festem Verhalten im Code (z. B. `geld`, `lohn_faktor`, `quest_starten`, `beliebtheit`).

## Hinweise im Moment (`data/hinweise.json`)

```json
{"id": "H-PFUETZE", "ausloeser": "erste_pfuetze", "text": "HINT_PFUETZE_1"}
```

## Absender (`ABSENDER_*` in `locale/texte.csv`)

HORST („Festleiter Horst"), KONRAD, SCHNEIDER („Herr Schneider, Bank"), WAGNER („Frau Wagner, Amt"), MAIER („Dieter Maier, Brauerei"), GERHARD („Gerhard, Bräumeister"), STEFAN, SABINE, WETTERDIENST.

## Regeln
- IDs wie in `docs/QUEST_LISTE.md` und `docs/MAIL_LISTE.md`.
- Beträge in den Dateien sind Platzhalter, das Balancing legt sie fest.
- Keine neuen `class_name`, Laden per `preload` in einem Skript `scripts/daten.gd` (P1).
