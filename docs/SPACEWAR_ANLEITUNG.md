# Sloptoberfest — Spacewar-Testversion (vor dem Steam-Start)

Diese Version nutzt Valves Test-App „Spacewar“ (App-ID 480). Damit funktionieren Steam-Freunde, Einladungen und
der Koop-Modus, ohne dass das Spiel schon im Store ist. In der Freundesliste steht „Spacewar“ statt „Sloptoberfest“.

## Voraussetzungen (für alle Mitspieler)
1. **Steam ist gestartet und angemeldet** (der Steam-Client muss laufen, sonst startet das Spiel ohne Steam).
2. Die **Mitspieler sind auf Steam befreundet** (Freundesliste), sonst sieht man sich nicht in der Lobby.
3. Windows, Grafikkarte mit Vulkan (RTX/GTX, Radeon, neuere Intel). Rund 8 GB Arbeitsspeicher.

## Installation
1. ZIP entpacken (zum Beispiel nach `C:\Spiele\Sloptoberfest`). Die Dateien müssen zusammen im selben Ordner bleiben:
   `Sloptoberfest.exe`, `steam_api64.dll`, `libgodotsteam.windows.template_release.x86_64.dll`, `steam_appid.txt`.
2. `Sloptoberfest.exe` starten. Der erste Start dauert länger (bis zu 1–2 Minuten, nicht abbrechen).

## Koop spielen
- **Host:** Hauptmenü → **Koop** → „Mit Steam-Freunden spielen“. Im Spiel mit **Esc → „Freunde einladen“** die Freunde einladen.
- **Gast:** Einladung im Steam-Overlay (Shift+Tab) annehmen oder in der Freundesliste „Spiel beitreten“ wählen.
- Beide Seiten müssen **dieselbe Version** haben (die Version steht unten im Hauptmenü).

## Hilfreiche Tasten
- **F3** Leistungsanzeige (FPS, Bildzeit), **F4** Leistungstest (dauert eine Minute, Screenshot an uns schicken)
- **Q** halten: Emote-Rad · **F1** Hilfe

## Wenn etwas nicht klappt
- „Steam nicht gestartet“ im Log: Steam-Client starten und das Spiel neu starten.
- Mitspieler nicht sichtbar: prüfen, ob beide wirklich als Freunde in Steam stehen.
- Log: `%APPDATA%\Godot\app_userdata\Sloptoberfest\logs\godot.log`
