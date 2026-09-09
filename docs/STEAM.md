# Weg zu Steam

Stand: geprüft am aktuellen Repo, nicht abgeschrieben. Reihenfolge = Empfehlung.

---

## A · Blocker — ohne die geht es gar nicht

### A1 Lizenzen der Assets klären
**Du, kostet nur Zeit.** Register: `docs/lizenzen/README.md`.

Kirmes-Pack ist **royalty-free** — geklärt, Nachweis fehlt noch. Offen sind
Spielfigur, Zelt-Modelle und die vier alten Stände.

- Das gekaufte „Amusement Park"-Pack: erlaubt die Lizenz den Vertrieb in einem
  **verkauften** Spiel? Viele Marktplatz-Lizenzen unterscheiden zwischen
  „use in a project" und „redistribute".
- Alle anderen Modelle stammen aus **Meshy**, nachbearbeitet in Blender. Ob
  kommerzielle Nutzung ohne Namensnennung erlaubt ist, haengt am Meshy-Tarif
  zum Zeitpunkt der Erzeugung.
- Schriftarten sind unproblematisch: nur Godots Standardschrift im Projekt.

Kaufbelege und EULAs nach `docs/lizenzen/` legen. Das ist der billigste
Blocker und der einzige, der ein fertiges Spiel im Nachhinein killen kann.

### A2 Name prüfen
„Oktoberfest" und „Wiesn" sind von der Landeshauptstadt München als Marken
eingetragen (mehrere Klassen). Ob das einen Spieltitel trifft, kann ich nicht
beurteilen — **das gehört zu einem Anwalt**, bevor Store-Grafiken entstehen.
Halte einen Ersatznamen bereit.

### A3 Auto-Updater raus aus dem Steam-Build
`boot.gd` lädt bei jedem Start `version.json` und `game.pck` von
`survival.vapur-it.de`. Auf Steam ist das falsch und riskant: Steam patcht
selbst, und nachgeladener Code fällt beim Review auf.

Lösung: Feature-Tag `steam` im Export-Preset, und in `boot.gd`:

```gdscript
if OS.has_feature("steam"):
    get_tree().change_scene_to_file(MENU)
    return
```

Der bestehende Updater bleibt für die Direkt-Builds erhalten.

### A4 Mehrspieler ohne IP-Eingabe
Aktuell: fester Server `185.248.140.225` oder IP tippen. Auf Steam erwartet man
Freundesliste, Einladungen, Lobbys — und Selbst-Hosten scheitert sonst an NAT
und Portfreigabe.

Weg: **GodotSteam** + `SteamMultiplayerPeer` als Ersatz für `ENetMultiplayerPeer`
in `autoload/net.gd`. Die RPC-Schicht darüber bleibt unverändert. Dazu Lobby
erstellen/suchen/beitreten im Menü.

Das ist der größte technische Brocken. Zwischenschritt, falls es schneller
gehen soll: Server-Browser mit Liste statt IP-Feld.

### A5 Sprache vereinheitlichen
Das Spiel ist gerade zweisprachig durcheinander — Menü und Statusmeldungen
Türkisch (`"Host Aç (Oyun Kur)"`, `"Bağlanılıyor"`), HUD und Popups Deutsch.

Godot-Lokalisierung: alle Texte in eine CSV, `tr()` im Code, Deutsch + Englisch
als erste Sprachen. Englisch ist auf Steam faktisch Pflicht.

### A6 Ton
`assets/audio/` enthält **nur `.gitkeep`**. Alles, was man hört, erzeugt
`sfx.gd` prozedural als `AudioStreamWAV`. Eine Kirmes ohne Blasmusik,
Stimmengewirr und Fahrgeschäft-Lärm verkauft sich nicht.

Gebraucht: Musik im Zelt, Menü-Musik, Außen-Ambiente, SFX für Zapfen, Kasse,
Kotzen, Putzen, Fahrgeschäfte. Lizenzfrei kaufen (siehe A1).

### A7 Steamworks
**Du.** Im Content Survey muss angegeben werden, dass Modelle mit KI erzeugt
wurden (Meshy) — Valve weist das auf der Store-Seite aus. Kein Hindernis, aber
Pflicht.

Partner-Account, 100 USD Gebühr pro App, Steuer- und Bankdaten,
dann Store-Seite: Capsules (231×87, 462×174, 616×353, 1232×706), Header,
Library-Grafiken, Trailer, mindestens 5 Screenshots, Alterseinstufung.

Zwischen Store-Seite-Freigabe und Release müssen **mindestens 2 Wochen** liegen.

---

## B · Qualität — entscheidet über Bewertungen

### B1 Optionsmenü
Existiert nicht. Erwartet werden: Auflösung, Vollbild, Grafik-Voreinstellungen,
Lautstärke getrennt für Musik/SFX/Ambiente, Tastenbelegung, Mausempfindlichkeit,
Sprache. In `project.godot` gibt es weder `[display]` noch `[input]` — die
Tastenbelegung ist also gar nicht konfigurierbar.

### B2 Grafik-Voreinstellungen und Performance
143 Omni-Lichter, bis zu 220 Besucher, Glow, SSAO. Auf schwacher Hardware wird
das nicht laufen. Nötig: Presets (Niedrig/Mittel/Hoch), die Sichtweite,
Besucherzahl, Schatten, SSAO und Glow schalten — plus eine echte Messung auf
einem langsamen Rechner.

### B3 Spielstände versionieren
`user://oktoberfest_save.json` hat kein Formatversionsfeld. Jede
Wirtschaftsänderung kann alte Stände unbrauchbar machen. Vor Release:
Versionsnummer rein, Migration oder sauberes Ablehnen. Dazu Steam Cloud.

### B4 Mehrspieler-Robustheit
Was passiert bei Verbindungsabbruch mitten in der Schicht? Wenn der Host geht?
Aktuell vermutlich nichts Gutes. Braucht: Reconnect, Host-Abbruch abfangen,
Speichern beim Host absichern.

### B5 Spielumfang
Der Kreislauf steht (Zelt mieten, Personal, Ware, Schicht, Tagesbilanz). Für
einen Kauf erwarten Simulator-Spieler 10–20 Stunden. Offen: Wie viele Tage
trägt das? Zelt-Stufen enden bei 3, Personal bei Level 5. Es braucht Ziele,
Freischaltungen und einen Grund, Tag 20 zu spielen.

**Das ist inhaltlich der wichtigste Punkt** — Technik lässt sich nachziehen,
ein dünner Spielkern nicht.

### B6 Einheitlicher Look
Drei Stile treffen aufeinander: die ~1 m große Bean-Figur, das Low-Poly-Pack
und die Zelt-Modelle. Vor den Store-Screenshots entscheiden, welcher gewinnt.

---

## C · Später

- Steam-Errungenschaften (erster Gewinn, 1000 Maß, Zelt Stufe 3 …)
- Controller-Unterstützung
- Demo oder Playtest für Wunschlisten vor Release

---

## Was ich sofort erledigen kann

A3 (Steam-Build-Pfad), A5 (Lokalisierung), B1 (Optionsmenü), B2 (Presets),
B3 (Speicherstand-Version). A4 sobald entschieden ist, ob GodotSteam kommt.

Was nur du kannst: A1, A2, A6 (Dateien kaufen), A7.
