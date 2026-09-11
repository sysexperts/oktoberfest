# Plan v3 — Vom Prototyp zum Steam-Release

Ziel: Ein Spieler, der das Spiel zum ersten Mal startet, versteht ohne Hilfe,
was er tun soll, kann es in seiner Sprache spielen, und alles fühlt sich wie
ein fertiges Spiel an. Am Ende steht die Veröffentlichung auf **Steam**.

## Entscheidungen (festgelegt)

| Thema | Entscheidung |
|---|---|
| Sprachen | **Deutsch, Englisch, Türkisch** — Deutsch ist Ausgangssprache |
| Spielmodus | **Solo zuerst**, Koop als eigener Menüpunkt |
| Struktur | **Endlos** — kein Saisonende, Motivation über Meilensteine |
| Koop auf Steam | **Steam-Lobbys + Freunde einladen** (GodotSteam) |

## Leitplanken

- **Alles als echte Szene.** Menüs, HUD, Einstellungen werden `.tscn`-Dateien,
  die im Editor bearbeitbar sind. `hud.gd` und `menu.gd` bauen die Oberfläche
  heute komplett im Code — das wird umgebaut.
- **Kein sichtbarer Text ohne `tr()`.** Jeder neue String geht sofort in die
  Übersetzungstabelle, damit die drei Sprachen nie wieder auseinanderlaufen.
- **Jeder Schritt wird aus der fertigen pck geprüft**, nicht nur im Projekt.
- Nach jeder Etappe: Deploy, damit du im echten Spiel testen kannst.

---

## Bestandsaufnahme — warum Spieler heute scheitern

| Befund | Folge |
|---|---|
| Nach Tag 16 springt der Zähler still auf Tag 1 | wirkt wie ein Fehler, kein Fortschrittsgefühl |
| Solo = „Host Aç" öffnet Netzwerkserver auf Port 8642 | Firewall-Abfrage beim Alleinspielen |
| ESC gibt nur die Maus frei | kein Pausemenü, kein Beenden, keine Einstellungen |
| 174 sichtbare Texte: 59 deutsch, 21 türkisch, teils im selben Satz | niemand versteht alles |
| Steuerungshilfe ist ein 180-Zeichen-Satz am unteren Rand | wird nicht gelesen |
| Tutorial = 11 Textzeilen in einer Ecke | man weiß nicht, *wo* und *was* |
| Tasten fest verdrahtet (Q, C) bzw. zur Laufzeit angelegt | nicht umbelegbar |
| Menü zeigt „Build v6", Stand ist v99 | Verwirrung beim Testen |

---

## Phase 1 · Fundament — Menüs und Sprache

Alles Weitere baut darauf auf. Ohne Übersetzungssystem müsste jeder neue Text
später nochmal angefasst werden.

- [x] **1.1 Übersetzungssystem** — `locale/texte.csv` mit Spalten `de`, `en`,
      `tr`; Sprache aus dem Betriebssystem, per Einstellung überschreibbar.
- [x] **1.2 Hauptmenü als Szene** — Weiterspielen · Neues Spiel · Koop ·
      Einstellungen · Credits · Beenden. Solo ohne Netzwerkserver, also ohne
      Firewall-Abfrage.
- [x] **1.3 Pausemenü (ESC)** — Fortsetzen · Einstellungen · Speichern und zum
      Hauptmenü · Beenden. Im Solo steht die Zeit dabei wirklich still.
- [x] **1.4 Einstellungen** — Grafik (Vollbild, VSync), Ton (Gesamt, Musik,
      Effekte, Umgebung getrennt), Steuerung (Mausempfindlichkeit, Y-Umkehr,
      alle Tasten umbelegbar), Sprache. Gespeichert in `user://einstellungen.cfg`.
      *Auflösung und Grafikqualität kommen mit 4.4* — vorher würden sie nichts
      bewirken.
- [x] **1.5 Versionsanzeige** aus einer einzigen Quelle.

**Unterwegs gefunden und behoben:** Im Host-Modus kam keine einzige Spieleraktion
an — alle 20 `net_*`-RPCs waren `any_peer` ohne `call_local`, und Godot verwirft
einen solchen Aufruf an sich selbst. Aufgefallen ist es nie, weil immer als
Client auf dem Server gespielt wurde. Jetzt mit `call_local`; `tools/test_phase1`
prüft Solo, Aktionen, Pause, Tastenbelegung und alle drei Sprachen (21 Prüfungen).

## Phase 2 · Verständlichkeit — Spieler wissen, was zu tun ist

- [x] **2.0 Eigenes Theme** — eine `Theme`-Ressource für alle Menüs. Das
      Godot-Standardtheme ist auf dunklem Grund kaum lesbar: **ausgeschaltete
      Schalter sehen aus wie ein grauer Punkt**, Panelränder verschwinden,
      Knöpfe verschwimmen mit dem Hintergrund. Gefunden in den Renders von
      Phase 1. *`assets/ui/theme.tres`, Schalter/Haken/Regler als SVG.*
- [x] **2.1 Neues HUD als Szene** — obere Leiste (Geld · Tag und Uhrzeit ·
      Beliebtheit), darunter Lager und Sauberkeit. Der Riesensatz unten fällt
      weg. *`scenes/ui/hud.tscn`; Tutorialtexte jetzt in allen drei Sprachen.*
- [x] **2.2 Interaktionshinweis am Fadenkreuz** — „[E] Krug nehmen",
      „[E] Gast bedienen", „[E] Schlafen". Zeigt nur, was *jetzt* geht.
      *Zeigt die tatsächlich belegte Taste; reine Auskünfte („Wiesenbüro öffnet
      nach Feierabend") gedämpft.*
- [x] **2.3 Geführtes Tutorial** — Zielmarker in der Welt über dem nächsten
      Ziel (Wiesenbüro, Fass, Gast), im Wiesenbüro wird der richtige Reiter und
      Knopf hervorgehoben, Haken plus Ton bei jedem erledigten Schritt,
      überspringbar.
      *Zielmarker (`scenes/ui/zielmarker.tscn`) folgt dem, was man in der Hand
      hat; Überspringen im Pausemenü.*
- [x] **2.4 Wiesenbüro aufräumen** — einheitliches Layout, Preise sichtbar,
      gesperrte Knöpfe sagen *warum* („Zuerst Zelt mieten").
      *`scenes/ui/wiesenbuero.tscn` aus `angebot.tscn`-Zeilen, Zelt-Computer als
      eigene Szene. Der Server schickt Zahlen statt Text, die Bilanz wird beim
      Spieler übersetzt.*
- [x] **2.5 Rückmeldung** — schwebende Beträge bei Verkauf und Trinkgeld,
      Benachrichtigungen stapeln sich statt sich zu überschreiben.
      *Meldungen unten in der Mitte, farbig nach Art; Probleme sieht nur, wer
      sie ausgelöst hat. Alle Servermeldungen jetzt als Schlüssel in drei
      Sprachen — kein Türkisch-Deutsch-Mischmasch mehr.*
- [x] **2.6 Hilfeseite (F1)** — Steuerung und Spielablauf auf einen Blick.
      *`scenes/ui/hilfe.tscn`, auch im Pausemenü; Tasten aus der aktuellen
      Belegung, im Solo steht die Zeit beim Lesen still.*

## Phase 3 · Spielfluss — Endlos, aber mit Ziel

Endlos heißt nicht ziellos. Ohne Saisonende braucht es einen anderen Grund,
morgen weiterzuspielen.

- [x] **3.1 Tageszähler ohne Rücksprung** — Tag 17, 18, 19 … statt „1/16".
- [x] **3.2 Meilensteine** — gestaffelte Ziele (erste 1.000 €, 100 Maß, Zelt
      Stufe 2, erster Kellner Level 5 …) mit Belohnung oder Freischaltung.
      Werden später 1:1 zu Steam-Errungenschaften.
      *13 Meilensteine in `scripts/meilensteine.gd` mit festen IDs, Geldbelohnung,
      Lebenszeit-Zähler im Spielstand, Reiter „Ziele" im Wiesenbüro.*
- [x] **3.3 Spielstände** — mehrere Slots, Formatversion, Autospeichern beim
      Schlafen, „Weiterspielen" lädt den letzten.
      *Drei Plätze unter `user://saves/`, der alte Einzelstand wird Platz 1.
      Stände aus neueren Versionen werden angezeigt, aber nicht geladen.
      Gespeichert wird bei jeder Zustandsänderung, also auch beim Schlafen.*
- [x] **3.4 Wirtschaft fürs Endlosspiel** — Nachfrage und Kosten skalieren mit
      dem Fortschritt, damit Tag 40 nicht trivial wird.
      *`scripts/wirtschaft.gd`: Miete und Ware +2 %/Tag (max. doppelt),
      Verkaufspreise +1,5 %/Tag (max. +80 %), Geduld −1 %/Tag (min. 60 %),
      ab Tag 8 −2 Beliebtheit pro Nacht. Wiesenbüro zeigt den Aufschlag.
      Werte sind erste Schätzung — beim Testen nachjustieren.*
- [ ] **3.5 Pleite** — was passiert am Dispolimit? Heute nicht definiert.

## Phase 4 · Ton und Präsentation

- [ ] **4.1 Soundeffekte anschließen** — die sieben neuen Namen an die
      passenden Stellen hängen. *Braucht Dateien von dir* (siehe `AUDIO.md`).
- [ ] **4.2 Menühintergrund** — der Kirmesplatz bei Nacht hinter dem Hauptmenü.
- [ ] **4.3 Ladebildschirm und Übergänge**
- [ ] **4.4 Grafikstufen umsetzen und messen** — 400 Besucher, 143 Lichter,
      Glow und SSAO pro Stufe schaltbar.

## Phase 5 · Steam-Integration

- [ ] **5.1 Steam-Build-Pfad** — Feature-Tag `steam`, der Auto-Updater wird
      im Steam-Build übersprungen.
- [ ] **5.2 GodotSteam einbinden** — Initialisierung, Overlay, Rich Presence.
- [ ] **5.3 Koop über Steam-Lobbys** — Freunde einladen, beitreten per Klick.
      `SteamMultiplayerPeer` ersetzt `ENetMultiplayerPeer`; die RPCs bleiben.
- [ ] **5.4 Steam Cloud und Errungenschaften** (aus 3.2)
- [ ] **5.5 Robustheit** — Verbindungsabbruch, Host verlässt das Spiel.
- [ ] **5.6 Deploy aus einem Guss** — Server und Client aus demselben Git-Stand
      synchronisieren, per Skript statt Datei für Datei. Beim Deploy von v100
      gefunden: vier Stand-Modelle (`drehscheibe`, `enten`, `schiessstand`,
      `suessigkeiten`) fehlten seit dem 8.9. auf dem Server — alle 46 Stände
      samt Kollision waren dort weg, während die Clients sie hatten. Behoben;
      die Ursache (Handkopie) bleibt, bis das Skript steht.

## Phase 6 · Veröffentlichung

- [ ] **6.1 Credits-Bildschirm**, Lizenzregister vollständig
- [ ] **6.2 Außenstehende testen lassen** — Leute, die das Spiel nie gesehen
      haben. Zuschauen, nicht erklären.
- [ ] **6.3 Namensprüfung** — „Oktoberfest"/„Wiesn" sind Marken der Stadt
      München. *Du, mit Anwalt.*
- [ ] **6.4 Steamworks** — Account, Store-Seite, Grafiken, Trailer,
      KI-Angabe, Alterseinstufung. *Du.*

---

## Wer macht was

| | |
|---|---|
| **Ich** | Phase 1–5 komplett, 6.1 |
| **Du** | Audiodateien (4.1), Namensprüfung (6.3), Steamworks (6.4), Türkisch gegenlesen, Tests (6.2) |

Die Übersetzungen ins Englische und Türkische schreibe ich — das Türkische
solltest du gegenlesen, bevor es live geht.
