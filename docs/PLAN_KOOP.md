# Plan: Koop mit Rollen (Stand 13.09.2026, v133)

Ziel: Im Mehrspieler hat **jeder Spieler eine eigene Aufgabe**. Rollen geben
Boni, verbieten aber nichts — jeder kann im Notfall alles. Grundlage für den
ersten Live-Test heute Abend und die Zeit danach.

---

## 1. Ausgangslage (aus dem Code)

| Thema | Heute |
|---|---|
| Lobby | Keine. Host/Steam-Lobby wechselt sofort ins Zelt, Mitspieler steigen jederzeit ein (`Net.host_game`, `join_game`). Dauerserver: ein gemeinsamer Spielstand. |
| Rollen | Früher Koch/Reinigung/Kellner als Schicht-Rollen, wieder entfernt. Reste: `ROLE_*`, `_npc_roles` im GameManager. |
| Personal | NPC-Koch, -Kellner, -Reinigung, -Zapfer frei im Wiesenbüro mietbar — auch im Koop. |
| Skalierung | +50 % Gäste je weiterem Spieler (`KOOP_ANDRANG_JE_SPIELER`), sonst alles wie solo. |
| Schlafen | **Ein** Spieler am Wohnwagen startet den Tag für alle. |
| Spielerfigur | Immer die Bean, nur die Schalfarbe unterscheidet (Taste C). `Net.player_name` existiert, wird kaum genutzt. |

**Problem:** Zu viert erledigt oft ein Spieler mit NPC-Personal alles, die
anderen stehen herum; wer zuerst schläft, beendet für alle den Abend.

## 2. Was andere Koop-Spiele machen (Recherche aus bekannten Titeln)

- **Overcooked:** keine festen Rollen — die Aufteilung entsteht durch getrennte
  Stationen und Zeitdruck. Lehre: *Stationen räumlich trennen* erzeugt Absprachen.
- **PlateUp!:** Kundenzahl skaliert mit Spielern, Automatisierung kostet Geld.
  Lehre: *Andrang an Spielerzahl koppeln*, Hilfsmittel knapp halten.
- **Klassen mit Stärken statt Verboten** (z. B. Deep Rock Galactic): jeder kann
  alles, aber die Klasse macht eine Sache deutlich besser. Lehre: *Boni statt
  Sperren*, sonst blockiert ein fehlender Spieler das Spiel.
- **Abstimmung vor Levelwechsel** (viele Koop-Spiele: „Bereit"-Status aller):
  niemand wird mitten im Tun aus der Runde geworfen.

## 3. Vorschlag

### 3.1 Rollen und Boni
Jeder Spieler wählt **eine** Rolle. Ohne Rolle = „Aushilfe" (keine Boni, keine Nachteile).

| Rolle | Aufgabe | Boni (Vorschlag) |
|---|---|---|
| 👨‍🍳 Koch | Essen an der Kochtheke | kocht 2× so schnell, trägt 2 Teller |
| 🍺 Kellner | Bier zapfen und servieren | zapft 1,5× schneller, trägt 4 statt 3 Krüge, +20 % Trinkgeld |
| 🧹 Reinigung | Pfützen/Erbrochenes, Klo | putzt 3× schneller, +Sauberkeit, sieht Flecken durch Wände (Markierung) |
| 📦 Lager/Einkauf *(optional)* | Pakete, Ware, Computer | trägt 2 Pakete, Ware kommt schneller |
| 🛡 Sicherheitsdienst *(später)* | Randalierer rauswerfen, Betrunkene bremsen | braucht neues Ereignis „Streit/Randale" → eigene Ausbaustufe |

Bonus-Werte stehen später zentral in einer Tabelle, damit wir sie nach dem Test leicht ändern.

### 3.2 Lobby und Charakterwahl
Neuer Bildschirm **vor** dem Zelt (Host und Mitspieler):
- Spielername, **Figur** (Bean, charakter2, charakter3 — später mehr), Schalfarbe
- **Rolle** wählen; jede Rolle zeigt, wer sie schon hat (doppelt erlaubt? → Frage B)
- „Bereit"-Knopf; Host startet, wenn alle bereit sind
- Wer später einsteigt (Dauerserver, Drop-in), bekommt denselben Bildschirm als Fenster
- Rolle wechseln: am Zelt-Computer, nur zwischen den Schichten

### 3.3 NPC-Personal im Mehrspieler
- **Solo:** unverändert — Personal mieten wie bisher.
- **Mehrspieler:** NPC nur für Rollen, die **kein Spieler** hat.
  Beispiel 2 Spieler (Koch + Kellner) → Reinigung als NPC mietbar, Koch/Kellner nicht.
- Im Wiesenbüro/Computer erscheint bei besetzten Rollen „von Spieler X übernommen".
- Verlässt ein Spieler das Spiel, wird seine Rolle wieder für NPC frei.

### 3.4 Skalierung Mehrspieler
Heute: +50 % Gäste je Spieler. Vorschlag: nach **besetzten Aufgaben** rechnen:
- Grundandrang × (1 + 0,6 je weiterem Spieler)
- Geduld der Gäste im Koop etwas höher (mehr Wege), Bestellungen gemischter (mehr Essen, damit der Koch zu tun hat)
- Verschmutzung skaliert mit Gästen automatisch → Reinigung hat Arbeit
- Prüfen mit dem Spielbot (`tools/sim_saison.tscn`) für 1–4 Spieler

### 3.5 Schlafen per Abstimmung
- Spieler am Wohnwagen → Fenster bei **allen**: „Nächsten Tag starten? Ja / Nein" (30 s)
- Alle Ja → Tag startet · ein Nein → abgebrochen, Meldung „X will noch nicht"
- Zeitablauf ohne Antwort zählt als Nein (Frage D)
- Solo: sofort wie bisher

## 4. Umsetzung in Stufen

| Stufe | Inhalt | Aufwand | Für heute Abend? |
|---|---|---|---|
| **A** | Schlaf-Abstimmung Ja/Nein | klein | ✅ ja |
| **B** | Rollen + Boni, Wahl über ein Fenster beim Einstieg (noch ohne Lobby), Anzeige über dem Kopf | mittel | ✅ ja |
| **C** | NPC-Personal nur für unbesetzte Rollen | klein | ✅ ja |
| **D** | Skalierung Mehrspieler neu + Bot-Lauf für 2–4 Spieler | mittel | ⚠️ Grundwerte ja, Feinschliff nach dem Test |
| **E** | Echte Lobby vor dem Start mit Figur, Name, Bereit-Status | groß | ❌ nach dem Test |
| **F** | Sicherheitsdienst mit Randale-Ereignis | groß | ❌ später |

Empfehlung: **A–C heute**, D als erste Schätzung, beim Live-Test Feedback
sammeln, dann E und F. Eine Lobby unter Zeitdruck ist das größte Risiko für
den Test (Beitritt, Dauerserver, Drop-in).

## 5. Offene Fragen an dich

- **A** Rollen-Liste: Koch, Kellner, Reinigung — dazu „Lager/Einkauf" als vierte Rolle für 4 Spieler?
- **B** Darf eine Rolle doppelt gewählt werden (zwei Kellner)?
- **C** Sollen Boni so stark sein wie oben oder milder?
- **D** Abstimmung: zählt keine Antwort als Nein oder als Ja?
- **E** Figurenwahl: reichen erst mal die 3 vorhandenen Figuren?
- **F** Dauerserver: wer darf dort Rollen/Personal verwalten — alle oder nur der erste Spieler?
