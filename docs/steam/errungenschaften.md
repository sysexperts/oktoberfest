# Errungenschaften und Steam Cloud (Plan 5.4)

## Errungenschaften

Jeder Meilenstein aus `scripts/meilensteine.gd` schaltet beim Erreichen die
gleichnamige Steam-Errungenschaft frei — beim Host und bei allen, die gerade
mitspielen (`GameManager._net_errungenschaft` → `SteamDienst.errungenschaft`).
Beim Laden eines Spielstands trägt der Host bereits erreichte nach, falls Steam
beim Erreichen nicht lief.

**In Steamworks anlegen** (*Stats & Achievements → Achievements*): API-Name
**genau** wie die ID, sonst passiert nichts. Anzeigename und Beschreibung aus
`locale/texte.csv` (`MS_<ID>_TITLE`, `MS_<ID>_TEXT`, de/en/tr). Je Errungenschaft
zwei Symbole 64×64 (erreicht, grau). Danach **Publish** nicht vergessen.

| API-Name | Bedingung |
|---|---|
| `ERSTE_MASS` | 1 Maß ausgeschenkt |
| `UMSATZ_1000` | 1.000 € Umsatz insgesamt |
| `TAG_7` | Tag 7 erreicht |
| `MASS_100` | 100 Maß |
| `ZELT_2` | Zeltstufe 2 |
| `PUTZ_50` | 50 Mal geputzt |
| `ALLE_LIZENZEN` | alle 4 Lizenzen |
| `UMSATZ_10000` | 10.000 € Umsatz |
| `KELLNER_5` | ein Kellner auf Stufe 5 |
| `TAG_30` | Tag 30 erreicht |
| `MASS_1000` | 1.000 Maß |
| `ZELT_3` | Zeltstufe 3 |
| `UMSATZ_100000` | 100.000 € Umsatz |
| `SAISON_1` | erste Wiesn (16 Tage) bis zum Finale gespielt |
| `WIESN_WIRT_5` | eine Wiesn mit 5 Maßkrügen bewertet |

Neue Meilensteine nur **anhängen**, IDs nie umbenennen — sonst verlieren Spieler
ihre Errungenschaften.

**Prüfen:** Steam-Build über den Steam-Client starten, einen Meilenstein
erreichen (z. B. erste Maß), Overlay (Shift+Tab) zeigt die Meldung. Mit der
Test-App 480 geht das nicht — dort gibt es unsere Errungenschaften nicht.

## Steam Cloud (Spielstände)

Kein Code nötig: **Auto-Cloud** in Steamworks (*Application → Steam Cloud*):

1. *Byte quota per user* z. B. 10 MB, *Number of files* 20.
2. *Root Overrides* leer lassen.
3. Unter *Auto-Cloud Configuration* eine Zeile:

| Root | Subdirectory | Pattern | OS | Recursive |
|---|---|---|---|---|
| `WinAppDataRoaming` | `Godot/app_userdata/Oktoberfest Simulator/saves` | `*.json` | Windows | nein |

Das sind die drei Spielstand-Plätze (`slot_1.json` … `slot_3.json`). Die
Einstellungen (`einstellungen.cfg`) bleiben bewusst lokal — Grafikstufe und
Auflösung gehören zum Rechner, nicht zum Konto.

Achtung: Ändert sich `application/config/name` in `project.godot` oder wird
`use_custom_user_dir` gesetzt, ändert sich der Ordner — dann hier mitziehen.

**Prüfen:** auf Rechner A spielen und beenden, auf Rechner B (gleiches Konto)
starten — „Weiterspielen" zeigt denselben Stand.
