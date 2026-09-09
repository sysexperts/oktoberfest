# Lizenzregister

Wer was darf. Für den Steam-Release muss jede Zeile auf ✅ stehen und der
Nachweis in diesem Ordner liegen.

| Assets | Dateien | Herkunft | Lizenz | Nachweis | Stand |
|---|---|---|---|---|---|
| Kirmes-Pack | `assets/kirmes/**` (126 Modelle) | gekauft | Royalty-Free | fehlt | ⚠️ |
| Spielfigur | `assets/character/character/bavarian_bean.glb` | Meshy (bezahlt, eigene Vorlagen) → Blender | volle Rechte, keine Nennung | Rechnung ablegen | ✅ |
| Zelt | `assets/models/floor,wall,roof.glb` | Meshy (bezahlt, eigene Vorlagen) → Blender | volle Rechte, keine Nennung | Rechnung ablegen | ✅ |
| Zelt-Einrichtung | `assets/models/tisch,bank,theke.glb` | Meshy (bezahlt, eigene Vorlagen) → Blender | volle Rechte, keine Nennung | Rechnung ablegen | ✅ |
| Kirmesstände (alt) | `assets/models/drehscheibe,enten,schiessstand,suessigkeiten.glb` | Meshy (bezahlt, eigene Vorlagen) → Blender | volle Rechte, keine Nennung | Rechnung ablegen | ✅ |
| Zeltmusik | `assets/audio/musik/zelt_01.mp3` | AIMusic.so | Tarif prüfen — nur bezahlt ist kommerziell | Lizenzzertifikat holen | ⚠️ |
| Ton übrig | `assets/audio/sfx`, `ambiente` | — | — | — | fehlt noch |

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

## Eigene Modelle: Meshy mit bezahltem Tarif

Alle Modelle außerhalb des Kirmes-Packs sind mit **Meshy** erzeugt und in
**Blender** nachbearbeitet. Laut Meshys Hilfe-Center:

- **Kostenloser Tarif:** Ergebnisse stehen unter CC BY 4.0 — kommerzielle
  Nutzung nur mit Nennung von Meshy.
- **Bezahlter Tarif:** private Lizenz, **volle Rechte, keine Namensnennung
  nötig**, verkaufen und verteilen erlaubt.

Wir sind auf dem bezahlten Tarif — also kein Credit nötig.

**Zwei Bedingungen bleiben:**

1. ~~Die **Eingabematerialien** dürfen keine fremden Urheberrechte verletzen.~~
   Erledigt: die Vorlagen stammen alle von Serdar selbst.
2. Maßgeblich ist der Tarif **zum Zeitpunkt der Erzeugung**, nicht heute. Läuft
   das Abo schon lange genug, ist das unkritisch — die Rechnung zeigt es.

Meshy stellt **kein Lizenzzertifikat** zum Herunterladen aus. Der Nachweis
besteht deshalb aus drei Teilen (siehe unten).

## Steam: KI-Inhalte müssen angegeben werden

Valve verlangt seit Anfang 2024 im **Content Survey** eine Angabe, ob und wie
KI eingesetzt wurde. Vorab erzeugte Inhalte werden auf der Store-Seite
ausgewiesen. Für uns betrifft das die Meshy-Modelle.

Kein Hindernis — aber Pflicht, und man muss bestätigen können, dass man die
Rechte hat. Genaue Formulierung vor dem Ausfüllen in der Steamworks-Doku
nachlesen.

---

## Nachweis ablegen

```
docs/lizenzen/
  kirmes-pack.pdf      Kaufbeleg + Lizenztext des Packs
  meshy-rechnung.pdf   Abo-Rechnung: Tarif + Zeitraum
  meshy-lizenz.pdf     Hilfe-Center-Seite zur kommerziellen Nutzung, mit Datum
  meshy-historie.pdf   Erzeugungsdatum der Modelle aus dem Konto
```

Screenshots mit sichtbarem Datum reichen. Wichtig ist, dass Rechnungszeitraum
und Erzeugungsdatum zusammenpassen.

## Musik aus AIMusic.so

Laut Anbieter: **kostenlose Nutzer haben keine kommerziellen Rechte** — sie
dürfen die Stücke nur auf nicht-kommerziellen Plattformen teilen und müssen
„Created with AIMusic.so" nennen. **Bezahlte Nutzer** behalten die vollen
Rechte an dem, was sie erzeugen, auch nach Ablauf des Abos.

Jahresabonnenten können ein **Lizenzzertifikat** anfordern. Genau das gehört
hier in den Ordner — es ist der sauberste Nachweis, den es für KI-Musik gibt.

Die Lizenzseite selbst ließ sich nicht abrufen (403), die Angaben stammen aus
Anbieter-Zusammenfassungen. Vor dem Release einmal selbst im Konto nachlesen.

**Zweite Ebene:** Ob rein KI-erzeugte Musik überhaupt urheberrechtlich
geschützt ist, ist in vielen Ländern offen. Für die Nutzung im Spiel spielt das
keine Rolle — es heißt nur, dass man anderen die Weiterverwendung womöglich
nicht verbieten kann. Kein Blocker, aber gut zu wissen.
