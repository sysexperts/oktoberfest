# Lizenzregister

Wer was darf. Für den Steam-Release muss jede Zeile auf ✅ stehen und der
Nachweis (Kaufbeleg, Lizenztext, Store-Seite als PDF) in diesem Ordner liegen.

| Assets | Dateien | Herkunft | Lizenz | Nachweis | Stand |
|---|---|---|---|---|---|
| Kirmes-Pack | `assets/kirmes/**` (126 Modelle) | gekauft | **Royalty-Free** | fehlt noch | ⚠️ |
| Spielfigur | `assets/character/character/bavarian_bean.glb` | **Meshy → Blender** | Meshy-Tarif prüfen | — | ⚠️ |
| Zelt | `assets/models/floor,wall,roof.glb` | **Meshy → Blender** | Meshy-Tarif prüfen | — | ⚠️ |
| Zelt-Einrichtung | `assets/models/tisch,bank,theke.glb` | **Meshy → Blender** | Meshy-Tarif prüfen | — | ⚠️ |
| Kirmesstände (alt) | `assets/models/drehscheibe,enten,schiessstand,suessigkeiten.glb` | **Meshy → Blender** | Meshy-Tarif prüfen | — | ⚠️ |
| Ton | `assets/audio/` | — | — | — | leer, alles synthetisch |

Schriftarten: keine eigenen im Projekt, es läuft alles über Godots
Standardschrift. Emoji rendert das System.

---

## Kirmes-Pack: was „Royalty-Free" abdeckt

Royalty-free heißt **keine Abgabe pro verkauftem Exemplar** — die Hauptsorge ist
damit erledigt. Beim Nachlesen noch zwei Dinge mitnehmen:

- Steht irgendwo „Editorial Use Only" oder eine Beschränkung auf
  nicht-kommerzielle Projekte? Dann wird es eng.
- Verlangt die Lizenz eine **Namensnennung**? Dann brauchen wir einen
  Credits-Bildschirm.

## Eigene Modelle: Meshy-Tarif entscheidet

Alle Modelle außerhalb des Kirmes-Packs sind mit **Meshy** erzeugt und in
**Blender** nachbearbeitet. Damit gehören sie dir — mit einer Einschränkung:

**Meshy räumt die kommerziellen Rechte je nach Tarif unterschiedlich ein.**
Bei kostenlosen Konten stehen die Ergebnisse üblicherweise unter einer
Creative-Commons-Lizenz mit **Namensnennungspflicht**; bezahlte Tarife geben in
der Regel die vollen kommerziellen Rechte ohne Nennung. Welche Fassung für dein
Konto gilt, steht in Meshys Nutzungsbedingungen und hängt am Tarif zum
**Zeitpunkt der Erzeugung**.

Zu klären: mit welchem Tarif wurden die Modelle erzeugt? Falls kostenlos →
entweder Credits-Bildschirm mit Meshy-Nennung, oder neu erzeugen unter einem
bezahlten Tarif.

## Steam: KI-Inhalte müssen angegeben werden

Valve verlangt seit Anfang 2024 im **Content Survey** eine Angabe, ob und wie
KI bei der Entwicklung eingesetzt wurde. Vorab erzeugte Inhalte („pre-generated")
werden auf der Store-Seite ausgewiesen. Für uns betrifft das die Meshy-Modelle.

Das ist **kein Hindernis** — viele Spiele auf Steam machen diese Angabe. Aber
sie muss gemacht werden, und man sollte dabei sagen können, dass man die Rechte
an den erzeugten Inhalten hat. Die genaue Formulierung des Fragebogens vor dem
Ausfüllen in der Steamworks-Dokumentation nachlesen.

---

## Nachweis ablegen

Pro Quelle eine Datei hier im Ordner:

```
docs/lizenzen/
  kirmes-pack.pdf     Kaufbeleg + Lizenztext
  meshy-tarif.pdf     Rechnung / Tarifübersicht + Nutzungsbedingungen
```

Screenshot der Seite mit sichtbarem Lizenztext und Datum reicht.
