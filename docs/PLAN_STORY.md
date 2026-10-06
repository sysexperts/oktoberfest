# Plan: Story, Quests und Computer (Entwurf)

Stand 06.10.2026. Entwurf von Claude, Entscheidungen von Serdar sind mit **✔** markiert,
alles andere ist ein Vorschlag zum Streichen oder Ändern. Es geht nur um Inhalt, Technik kommt danach.

## 1. Entscheidungen bis jetzt

- ✔ Keine Saison mit 16 Tagen, kein Finale. Das Fest läuft in **5 Story-Kapiteln**, jedes endet mit einem erfüllten Story-Ziel.
- ✔ Gegner heißt nur **Konrad**. Er ist Dauer-Gegner (Mails, Wetten, gelegentlich Sabotage).
- ✔ Der Festleiter heißt **Festleiter Horst** (überall, in allen Sprachen, „Festleiter" wird übersetzt).
- ✔ Horst gibt **alle Quests** (Haupt + Neben) und erzählt Sepps Geschichte über seine Erinnerungen (roter Faden).
- ✔ Das Maß-Wettschleppen mit Konrad bleibt als **wiederholbare Quest, mit der man Geld verdient**.
- ✔ Kosten sind **fest**. Einnahmen steigen nur durch Personal-Upgrades und Zeltausbau.
- ✔ Sepps Schulden zahlt man **selbst ab** (Bank-App), es gibt keine festen Bankraten nach Tag.
- ✔ **Virtueller Computer-Desktop** (Büro, schon im Tutorial; später auch im Wohnwagen als „Zuhause").
- ✔ Stammgäste: **Alois, Ludwig, Veronika, Katharina, Franz, Giulia** bleiben wie heute (Wunsch + Belohnung), **keine Quests von Gästen im Zelt**. Alle Quests kommen von Horst.
- ✔ Horst bittet regelmäßig um **Gefallen** (Aktions-Quests auf der Kirmes: suchen, packen, zum Security tragen, prügeln).
- ✔ Nebenquests verfallen **je nach Quest** unterschiedlich schnell.
- ✔ Prügeln vor der Übergabe ist **nur Spaß** (kein Bonus, keine Folgen).
- ✔ **Mehrere Security-Posten** über die ganze Kirmes verteilt (nicht nur eine Figur).
- ✔ Horst bittet **alle paar Tage** um einen Gefallen.
- ✔ Hauptquests, die zu lange liegen, haben eine **spielerische Strafe** (Details offen).
- ✔ Nur echte deutsche Namen für alle Figuren.
- ✔ Brauen (Kapitel 4) auf **mittlerer** Tiefe: Rezepte mit Zutaten und Mengen, kleine Minispiel-Schritte, Qualität aus der Mischung.
- ✔ Konrads Ende bleibt **offen** (Rivale, das Ende lässt beides zu).
- ✔ Ton: **warm und humorvoll** (bayerisch-gemütlich, Konrad ein liebenswerter Fiesling). Sprachausgabe: **Brabbelton** je Figur, keine echten Stimmen.
- ✔ Spielstart mit **Kurzszene** (Ankunft am Kirmestor), dann der Brief.
- ✔ Computer steht schon im Büro. Mit E geht man per Übergangs-Animation auf den Desktop.
- ✔ Nebenquests **verfallen nach einer Zeit**.
- ✔ Die Kirmes-Buden bekommen **eigene Quests** (nicht nur Geld).
- ✔ Alte Spielstände sind nur Tests, **keine Übernahme nötig**.

## 2. Der Computer-Desktop

Eine Oberfläche wie ein Betriebssystem, Apps als Symbole. Er ersetzt das heutige Festbüro-Menü (Reiter Zelt, Lizenzen, Personal, Künstler, Ware, Bilanz, Einrichtung, Ziele) und die Taste K.

| App | Inhalt | Heute |
|---|---|---|
| **E-Mail** | Horsts Aufträge, Konrad, Krankmeldungen, Bank, Lieferant, Amt, Stammgäste | neu (Texte liegen großteils in CHEF_*, HUBER_*) |
| **Shop** | Ware bestellen, Zelt/Tische kaufen, Einrichtung, Künstler buchen, Lizenzen | Festbüro-Reiter |
| **Kalender** | Sondertage, Termine, Duell-Termin, Lieferungen | Taste K |
| **Bank** | Kontostand, Sepps Schulden, Rettungskredit, selbst abzahlen | Bankraten |
| **Personal** | Team, Löhne, Müdigkeit, Upgrades, Krankmeldungen | Reiter Personal |
| **Bilanz** | Einnahmen, Ausgaben, Verlauf | Reiter Bilanz |
| **Bierpreis** | Preis je Sorte, Andrang | Zelt-Computer |
| **Quests** | Aktive Hauptquest, Nebenquests, Meilensteine | Ziele-Reiter |
| **Wetter und Amt** | Regenvorhersage, Hygienekontrolle, Genehmigungen | Zufallsereignisse |
| **Social Media** | Bewertungen, Katharina postet, Beliebtheit | Beliebtheit im HUD |

Idee: Beim Start gibt es nur E-Mail und Shop, die übrigen Apps schalten sich mit den Kapiteln frei.
Im Wohnwagen steht ein Laptop mit demselben Desktop (nur ohne Bilanz-Detail?).

## 3. Kapitel

### Kapitel 1 · Das Erbe
**Story:** Brief von Sepp, Horst erklärt, Konrad will das Zelt, Übernahme, Putzen, erster Tag.
**Ablauf:** wie heute (Quests 0–9), aber Büro-Einkäufe laufen über den Desktop. Horst zeigt den Computer.
**Story-Ziel:** erster Feierabend.
**Horst erzählt:** „Sepp und der Konrad waren früher Freunde" (erster Faden).
**Neu:** Mail von Konrad am ersten Abend (Spott). Freigeschaltet: E-Mail, Shop.

### Kapitel 2 · Das Zelt läuft
**Story:** Aufbau. Horst schickt Mails mit den Aufträgen, die heute Quests 10–13 sind.
**Hauptquests:** Kellner einstellen, Lizenz kaufen, Toilette einbauen, Künstler buchen, Zelt auf mittlere Größe.
**Nebenquests:** je ein Stammgast (6), Wetter-Ereignisse, Gäste-Ziele.
**Story-Ziel:** mittleres Zelt und 1.500 € von Sepps Schulden abbezahlt.
**Horst erzählt:** Sepp und Konrad lernten zusammen bei der Brauerei, dann Streit um etwas, das mit einem Rezept zu tun hatte.
**Freigeschaltet:** Kalender, Bank, Personal, Bilanz, Bierpreis, Wetter und Amt, Krankmeldungen.

### Kapitel 3 · Konrads Spiele
**Story:** Konrad greift an: Wetten, Sabotage (Fass-Leck, Stinkbombe), wirbt Personal ab.
**Hauptquests:** Wette annehmen, Saboteur erwischen, Sicherheitsdienst (**Security**) einstellen, Beweise sammeln, Konrad zum Duell herausfordern.
**Story-Ziel:** Saboteur überführt und das Duell gewonnen (einmal).
**Horst erzählt:** Was Sepp und Konrad auseinandergebracht hat. Er übergibt die erste Seite von **Sepps Rezeptbuch**.
**Neu:** Security als Personal (Rolle fünf) und Duell als wiederholbare Geld-Quest. Freigeschaltet: Social Media.

### Kapitel 4 · Das eigene Bier
**Story:** Statt Bier zu kaufen, braut man selbst. Konrad will die Brauerei-Zutaten blockieren.
**Hauptquests:** Brauerei einrichten, Bräumeister einstellen, Zutaten besorgen (Hopfen, Malz), ersten Sud, Qualität prüfen, eigenes Bier ausschenken.
**Nebenquests:** Rezeptseiten finden, Testtrinker, Biermesse.
**Story-Ziel:** erstes selbstgebrautes Fass verkauft, Qualität mindestens „gut".
**Horst erzählt:** Sepps Rezept war halb Konrads Rezept. Das ist der Kern des Streits.
**Brauen (mittel):** Rezepte aus Zutaten und Mengen, kleine Schritte (Maischen, Hopfen kochen, Gären lassen), Qualität aus der Mischung.

### Kapitel 5 · Das große Zelt
**Story:** Konrad macht ein Übernahmeangebot (die Brauerei hängt an Krediten), die Wahrheit über Sepp, Versöhnung oder Sieg.
**Hauptquests:** Riesenzelt, Schulden ganz abbezahlen, Star-Act, großes Fest.
**Story-Ziel:** schuldenfrei und Riesenzelt. Danach Abschlussbrief von Sepp.
**Danach:** Weiterspielen, offene Welt (Nebenquests, Duell-Turnier, Meilensteine, Zufallsereignisse).
**Duell-Turnier (✔, spät im Spiel):** Maß-Wettschleppen in mehreren Konrad-Stufen, jede mit eigenem Preisgeld und besonderer Strecke, als Geld-Quest.

## 4. Konrad als Dauer-Gegner

- Streiche nach Kapitel gestaffelt (K3 Sabotage, K4 Zutaten, K5 Übernahme), danach seltener und schwächer.
- Mails von Konrad (Spott, Angebote, Drohungen, Wettvorschläge).
- Wetten bleiben (Gäste bedienen, keine Pfütze, keine Beschwerde).
- **Duell als Geld-Quest:** Zehn Maß durch alle Tore, Einsatz und Gewinn in Euro, einmal je Tag wiederholbar, Konrad wird je Sieg schneller.
- Konrad-Zelt bleibt als Gegenstück zum eigenen Zelt.

## 5. Systeme, die bleiben

- Tagesziele (Horst gibt sie jetzt als Nebenquests), Meilensteine (48), Zeitung (als Nebenerzählung), Ereignisse (Regen, Bus, Kontrolle, Happy Hour, Fass kaputt, Prosit, Promi), Sondertage (Anstich, Tracht, Familie, Italiener) als Kalender-Termine im Zyklus.
- Kirmes mit Minispielen als Nebenaktivität (Belohnung: Geld, Beliebtheit).
- Schlägerei im Zelt (Security verhindert sie).
- Koop: Quests gelten für alle, Abstimmungen bleiben.

## 6. Was wegfällt oder sich ändert

- Saison/16 Tage, Finale-Ereignis, Abschlussbrief am Ende des Fests, Taste K.
- Kostensteigerung mit dem Tageszähler (Miete, Ware, Preise, Gegner).
- Fest getaktete Bankraten (Tag 4, 8, 12).
- Alte Spielstände sind nur Tests, keine Übernahme.

## 7. Neue Figuren und Namen (echte deutsche Namen)

- Festleiter **Horst** (Quest-Geber), Gegner **Konrad**, Stammgäste siehe oben.
- Vorschläge: **Bräumeister Gerhard** (K4), **Bankberater Herr Schneider** (Mails), **Gerhard Maier** von der Brauerei? (zwei Gerhards vermeiden → Brauerei: **Dieter Maier**), **Amtsleiterin Frau Wagner** (Hygiene).
- Security: eine Figur (Look liegt vor), Name bei der Einführung.

## 8. Offene Fragen


## 9. Kapitel 1 im Detail (Entwurf, zum Durchgehen)

Alle Texte in der Du-Form, die Ihr-Variante für den Koop wird daraus abgeleitet. Vorhandene Zeilen bleiben, wo sie passen.

| Nr. | Ort | Was passiert | Texte |
|---|---|---|---|
| 1 | Kirmestor | **Neu:** Kurzszene. Kamera schwenkt über die Kirmes, Blaskapelle im Hintergrund, Titel „Sloptoberfest". Spieler steht mit einem Umschlag vor dem Tor, Horst winkt ihn heran. | Neu |
| 2 | Vor dem Festbüro | Horst begrüßt, kondoliert, übergibt Sepps Brief. Der Brief wird **einmal** gelesen (heute kommt er doppelt: als Brief-Fenster und noch einmal von Horst vorgelesen). | CHEF_1 bis 3, BRIEF_1 bis 3 |
| 3 | Vor dem Festbüro | Horst fragt „Übernimmst du Sepps Zelt?" (Ja/Nein). Bei Nein verabschiedet er sich, der Spieler kann es sich jederzeit anders überlegen. | CHEF_FRAGE, CHEF_WAHL_*, CHEF_NEIN_* |
| 4 | Weg zum Zelt | Horst führt, erzählt vom Zelt, den Schulden und Konrad. | CHEF_4 bis 8 |
| 5 | Zelteingang | Am roten Schild unterschreiben, dem Zelt einen Namen geben, 500 € Gebühr, die ersten 5 Tage ohne Miete. | QUEST_1 |
| 6 | Zelt | Planen abziehen, Dreck fegen, Säcke in die Mülltonne. Horst erklärt. | CHEF_PUTZ_1 bis 3, QUEST_2 |
| 7 | Festbüro | **Neu:** Horst zeigt den Computer. Mit E fährt die Kamera zum Bildschirm, **Übergangs-Animation**, Desktop erscheint (nur E-Mail und Shop). Erste Mail von Horst: „Willkommen, kauf zwei Tische und ein Paket Bier." Im Shop kauft man beides. | CHEF_BUERO, QUEST_3 und 4 (angepasst) |
| 8 | Zeltvorplatz, Lager | Lieferwagen kommt, Pakete ins Lagerregal. | CHEF_LAGER, QUEST_5 und 6 |
| 9 | Wohnwagen | Schlafen, dann ist Tag 1, 07:00. | CHEF_SCHLAF, QUEST_7 |
| 10 | Theke | Morgens erklärt Horst das Zapfen. Der erste Gast. | CHEF_ZAPF, QUEST_8 |
| 11 | Zelt | Durchhalten bis 22:00, Fußspuren wischen. | QUEST_9 |
| 12 | Feierabend | Tagesbilanz, **neu:** Mail von Konrad (Spott) und Mail von Horst („Gut gemacht, morgen schick ich dir Aufträge"). **Story-Ziel erreicht**, Kapitel 2 beginnt. | Neu |

**Entschieden:** Der Brief kommt nur einmal. Horst übergibt den Umschlag, das Brief-Fenster öffnet sich, danach stellt Horst die Frage (die Vorlese-Zeilen CHEF_BRIEF_* entfallen). Das Tutorial ist **geführt, aber frei**: Pfeil und Quest-Liste zeigen den nächsten Schritt, der Spieler darf laufen und anderes tun.

**Erste Mail von Konrad (kurz, zwei Sätze):** „Ah, Sepps Patenkind. Ich geb dir zwei Wochen, dann kauf ich dir das Zelt ab. – K."
**Erste Mail von Horst:** „Guter Anfang! Morgen schick ich dir die nächsten Aufträge. Prost, Horst."

## 10. Kapitel 2 im Detail (Entwurf)

**Titel:** Das Zelt läuft. **Story-Ziel:** mittleres Zelt und 1.500 € von Sepps Schulden bezahlt.
**Freigeschaltet bei Kapitelstart:** Kalender, Bank, Personal, Bilanz, Bierpreis, Quests-App. Horst gibt die Hauptquests per Mail, die Belohnung holt man bei ihm im Büro ab (kurzer Dialog).

### Hauptquests (feste Reihenfolge)

| Nr. | Titel | Aufgabe | Belohnung |
|---|---|---|---|
| 2.1 | Hilfe muss her | Einen Kellner einstellen (Personal-App) | 100 € |
| 2.2 | Mehr auf der Karte | Eine Lizenz kaufen (z. B. Weizen) | Horst-Erinnerung 1 |
| 2.3 | Das stille Örtchen | Toilette einbauen | 150 € |
| 2.4 | Musik! | Einen Künstler buchen | Beliebtheit |
| 2.5 | Die erste Rate | 1.500 € Schulden zahlen (Bank-App) | Dank von Horst |
| 2.6 | Mehr Platz | Zelt auf mittlere Größe | Kapitelabschluss |

### Nebenquests (verfallen nach 3 Spieltagen, Horst gibt sie, sobald das Zelt läuft)

Typen: Gäste bedienen (X Stück), Umsatz (Y €), saubere Tage, Beschwerdefrei, Biersorte X servieren. Belohnung: Geld oder Beliebtheit.

### Stammgäste (keine Quests!)
✔ Gäste im Zelt geben **keine Quests** (zu viel Chaos). Die sechs Stammgäste bleiben wie heute: sie kommen zufällig, haben einen Wunsch (Alois und Ludwig Helles, Giulia Radler, Franz Hendl, Veronika und Katharina gute Bedienung), nach dreimal zufrieden gibt es die Belohnung. Nur die Namen ändern sich (Ludwig, Veronika, Katharina).

### Horsts Gefallen (Aktions-Quests auf der Kirmes)
✔ Alle Quests kommen von Horst. Neben den Aufbau-Aufträgen bittet er **immer wieder um einen Gefallen**: eine kleine Geschichte auf der Kirmes, mit Suchen, Tragen und Prügeln. Beispiel vom Nutzer: Am **Teufelsrad** (Drehscheibe) belästigt ein **Spanner** Frauen. Man muss ihn finden, mit E packen und zum **Security** tragen. Bis dahin darf man sich mit ihm prügeln und ihm eine Lektion erteilen.

Ideensammlung (zu streichen oder zu ergänzen):

| Gefallen | Ort | Ablauf |
|---|---|---|
| **Der Spanner** (✔ heißt so) | Teufelsrad | Täter in der Menge suchen, packen, zum Security tragen, optional vorher verhauen. Darstellung harmlos (nur ein Kerl mit Kamera, der sich komisch benimmt, nichts Gezeigtes). |
| Der Taschendieb | Riesenrad | Dieb flieht durch die Menge, verfolgen, packen, Beute zurück. |
| Der Betrunkene auf dem Turm | Turm | Besoffener Tourist ist hochgeklettert und kommt nicht runter: hinaufsteigen, packen, wegtragen. |
| Das verlorene Kind | Karussell | Kind sucht die Eltern: in der Menge die Eltern finden. |
| Streit am Lukas | Hau den Lukas | Zwei Raufbolde prügeln sich: packen und zum Security bringen. |
| Konrads Spion | Brauerei/Zelt | Konrads Mann fotografiert Rezepte: erwischen. |
| Lieferung für Horst | Kirmes | Kisten von einer Bude zur anderen tragen, unter Zeitdruck. |
| Der Promi | Kirmestor | VIP abholen und ins Zelt begleiten, Menge fernhalten. |

Die Aktionen (packen, tragen, werfen, prügeln, Menge durchsuchen) gibt es teils schon (Raufbold, Schlägerei).

### Konrad in Kapitel 2
- Nach Tag 3 eine Mail mit Kaufangebot für das Zelt (Freundschaftspreis, freche Absage möglich).
- Streiche beginnen erst in Kapitel 3.

### Mitarbeiter
- Krankmeldungen per Mail („Kellner Stefan hat Fieber, Ersatz für 2 Tage?").
- Löhne und Müdigkeit wie heute, nur in der Personal-App.

### Ereignisse
- Regen, Touristenbus, Happy Hour, Prosit, Fass kaputt, Promi, Hygienekontrolle (angekündigt in Wetter und Amt).

### Horsts Erinnerung 1 (nach Quest 2.2)
„Weißt du, der Sepp und der Konrad, die haben bei derselben Brauerei gelernt. Dicke Freunde, damals. Bis irgendwas zwischen den beiden zerbrochen ist … Frag mich nicht, was. Der Sepp hat nie drüber geredet."

## 11. Kapitel 3 im Detail (Entwurf)

**Der Streit (mehrdeutig, ✔):** Konrad wollte das gemeinsame Festbier heimlich verkaufen, weil Sepp schon damals Schulden hatte und Konrad ihm helfen wollte. Sepp hat es als Verrat verstanden. Keiner hat je darüber gesprochen. Beide haben Fehler gemacht; die Wahrheit kommt in Kapitel 5 ans Licht.

**Titel:** Konrads Spiele. **Story-Ziel:** Saboteur überführt und Konrad vor allen bloßgestellt (das Duell-Turnier kommt erst spät, siehe Kapitel 5).
**Freigeschaltet bei Kapitelstart:** Social-Media-App, Wetten, Security als Personal.

### Konrads Streiche (staffeln sich im Kapitel, immer mit einer Mail davor oder danach)
1. **Wette** (Mail): „Ich wette, du schaffst heute keine 40 Gäste. Einsatz 100 €." Annehmen oder ablehnen (wie heute).
2. **Fass-Leck:** Eine Sorte ist heute nicht verfügbar (wie das Ereignis „Fass kaputt").
3. **Stinkbombe:** Das Zelt stinkt, Gäste gehen.
4. **Abwerben:** Ein Mitarbeiter bekommt ein Angebot (Mail „Konrad bietet mir mehr"), der Spieler kann mit Gehaltserhöhung antworten oder ihn ziehen lassen.
5. **Schlechte Bewertungen** (Social Media): Konrad lässt falsche Sterne posten.
6. **Der Saboteur:** Ein verdächtiger Gast schleicht im Zelt (heute vorhanden, Erwischen per E).

### Hauptquests

| Nr. | Titel | Aufgabe | Wer gibt es |
|---|---|---|---|
| 3.1 | Eine Wette | Konrads Wette annehmen und gewinnen | Mail Konrad |
| 3.2 | Es stinkt | Ursache finden: Stinkbombe suchen und entfernen | Horst |
| 3.3 | Wachpersonal | Einen Security einstellen (Personal-App) | Horst |
| 3.4 | Der Saboteur | Den Saboteur im Zelt erwischen und zum Security bringen | Horst |
| 3.4b | Das Hinterzimmer | Der Saboteur flieht zu **Konrads Zelt**. Horst: „Hinter seinem Zelt gibt es ein Casino. Da musst du rein." Man kauft bei **Gustav** das Komplettset (Tarnung, ✔), schleicht ins **Casino** und spielt die erste Runde (Pflichtquest, ✔ Casino-Freischaltung). | Horst |
| 3.5 | Beweise | Beim Saboteur einen Zettel mit Konrads Handschrift finden, Horst zeigen | Horst |
| 3.6 | Zur Rede gestellt | Konrad die Beweise vor seinem Zelt vorlegen (kurze Szene, er streitet es ab, Gäste hören zu) | Horst |

Danach ist Konrad vorläufig ruhiger und kündigt Revanche an. Das Maß-Wettschleppen kommt in Kapitel 5 als Turnier.

### Security im Zelt (Personal Rolle fünf, muss **erst eingestellt werden**)
- Beendet Prügeleien, wirft Raufbolde raus (Hausverbot), wehrt Saboteure ab.
- Auf der Kirmes gibt es **feste Security-Posten** (nicht angestellt), die bei Gefallen-Quests Gegner übernehmen.
- Eigene Löhne, Stufen und Müdigkeit wie bei den anderen.
- Der Security ist die Figur, die wir schon gebaut haben (schwarze Cap, Warnweste, Security-Brille).

### Horsts Erinnerung 2 (nach 3.5)
„Der Sepp und der Konrad, die haben damals zusammen ein Festbier erfunden. Ein richtig gutes. Dann hat der Konrad es heimlich an die große Brauerei verkaufen wollen. Warum, hat er nie gesagt. Und der Sepp hat nie gefragt. Zwei Sturschädel." Horst übergibt die **erste Seite von Sepps Rezeptbuch**.

### Gefallen in Kapitel 3
Der Spanner am Teufelsrad, der Taschendieb am Riesenrad, Konrads Spion (siehe Tabelle bei Kapitel 2).

### Konrad-Mails (kurz, zwei Sätze, Beispiele)
- „Gerücht: Dein Fass hat ein Loch. Zufall? Ich war's nicht. – K."
- „Dein Kellner schaut neuerdings zu meinem Zelt hinüber. Ich zahl halt besser."
- Nach dem Duell: „Glück gehabt. Nächste Woche will ich Revanche."

### Strafe, wenn Hauptquests zu lange liegen (offen)
Beispiele: Zinsen auf den Schulden steigen, Konrad schickt einen weiteren Streich, ein Mitarbeiter wird unzufrieden. Wird im Querschnitt entschieden.

## 12. Kapitel 4 im Detail (Entwurf)

**Titel:** Das eigene Bier. **Story-Ziel:** erstes selbstgebrautes Fass verkauft, Qualität mindestens „gut".
**Freigeschaltet bei Kapitelstart:** Rezeptbuch (Quests-App), Brauerei-Einkauf im Shop.

**Was es schon gibt:** Braukeller mit Maischbottich, Sudkessel, Gärfass und Transportfass. Maischen (Malz und Wasser rühren), Kochen (Hopfen bei 60 %), Gären (5 Minuten), Abfüllen. Die Kellertür öffnet erst ab Zeltstufe 2.
**Was dazukommt (✔ „Rezept + 3 Schritte", „billiger und besser"):**
- **Ein einziges Rezept (✔): Sepps Festbier.** Die drei Rezeptseiten schalten **Verbesserungen** frei (Seite 1 gut, Seite 2 sehr gut, Seite 3 perfekt). Die anderen Sorten bleiben gekauft.
- **Drei Schritte** (Maischen, Kochen, Gären) bleiben wie heute (E halten) mit Timing-Punkten (z. B. Hopfen bei 60 %) und Temperatur halten; Qualität aus den Ergebnissen. Im Koop darf jeder jeden Schritt machen.
- **Qualität** (schlecht, normal, gut, hervorragend) steuert Preis, Geduld, Trinkgeld und Beliebtheit.
- **Eigenes Bier** kostet weniger als Ware aus dem Shop und erzielt Premium-Preise.
- **Bräumeister** als Mitarbeiter (Personal Rolle sechs), der Sude für dich braut.

### Hauptquests

| Nr. | Titel | Aufgabe |
|---|---|---|
| 4.1 | Der Schlüssel | Horst gibt den Kellerschlüssel (Voraussetzung: mittleres Zelt) |
| 4.2 | Sepps Braukeller | Braukeller aufräumen und in Betrieb nehmen |
| 4.3 | Zutaten | Malz und Hopfen im Shop bestellen |
| 4.4 | Der erste Sud | Nach Rezeptseite 1 maischen, kochen, gären lassen |
| 4.5 | Probe | Einen Testtrinker (Gast) das Bier probieren lassen |
| 4.6 | Konrads Blockade | Konrad blockiert Zutaten (Hopfen kommt nicht): Alternative besorgen |
| 4.7 | Ein Fass für alle | Eigenes Bier ausschenken, Qualität mindestens „gut" |

### Nebenquests
Weitere Rezeptseiten finden, Testtrinker-Aufträge, Bier an die Kirmes liefern, Qualitätswettbewerb auf der Biermesse (Einladung per Mail).

### Konrad
- Blockiert Zutaten (Mail „Der Hopfen ist leider aus").
- Lässt schlechte Bewertungen für das neue Bier posten.
- Schickt einen Spion in den Braukeller (Gefallen-Quest).

### Horsts Erinnerung 3
Er erzählt vom Rezept: „Das Festbier hat drei Seiten. Zwei hat der Sepp aufgeschrieben, die dritte … die hatte der Konrad." Er übergibt die zweite Rezeptseite. Die dritte findet sich erst in Kapitel 5.

### Neue Dinge
- Rezeptbuch (Seiten sammeln), Qualitätsanzeige, Bräumeister (Figur mit Mütze und Schürze, **Name: Gerhard**), Shop-Artikel Hopfen und Malz in drei Güten.

## 13. Kapitel 5 im Detail (Entwurf)

**Titel:** Das große Zelt. **Story-Ziel:** schuldenfrei und Riesenzelt, dann das große Fest und Sepps Abschlussbrief.
**Freigeschaltet bei Kapitelstart:** Duell-Turnier (erste Stufe), Star-Act, Riesenzelt-Ausbau.

**Keine Schulden-Wendung (✔):** Die Bank bleibt die Bank, Konrad bleibt der Gegner. Das Rätsel um Sepp und Konrad löst sich nur über die dritte Rezeptseite und Horsts Erinnerung, ohne Sieg oder Niederlage für Konrad.

### Hauptquests

| Nr. | Titel | Aufgabe |
|---|---|---|
| 5.1 | Das letzte Angebot | Mail von Konrad: ein hohes Angebot fürs Zelt. Annehmen ist nicht möglich, man lehnt per Antwort ab (frech oder höflich). |
| 5.2 | Das Turnier beginnt | Erste Stufe des Wettschleppens gegen Konrad gewinnen |
| 5.3 | Die dritte Seite | Nach dem Turnier gibt Konrad die letzte Rezeptseite (Gespräch mit Horst) |
| 5.4 | Das perfekte Festbier | Sepps Festbier in perfekter Qualität brauen |
| 5.5 | Das Riesenzelt | Zelt auf die größte Stufe ausbauen |
| 5.6 | Die letzte Rate | Sepps Schulden restlos abzahlen (Bank-App) |
| 5.7 | Das große Fest | Star-Act buchen, Fest ausrichten (siehe unten) |

### Das große Fest (✔ hoher Moment)
Besonderer Sondertag mit **kurzer Cutscene** zu Beginn (Horst eröffnet das Fest), Zelt rappelvoll, Star-Act, **Feuerwerk** am Abend, **Konrads Auftritt** als Gast (offen, ob er bleibt oder grußlos geht) und danach Sepps Brief als Fenster. Es gibt weder Sieg noch Niederlage für Konrad, das Ende bleibt offen. Am Schluss erscheint nur die Meldung „Story abgeschlossen" (✔ kein Abspann), danach wird weitergespielt.

### Abschlussbrief (Entwurf, ✔ Ton warm und humorvoll)
„Wenn du das liest, hast du es geschafft. Das Zelt gehört dir und die Schulden sind weg. Eins noch: Wenn der Konrad vorbeikommt, schenk ihm eine Maß ein. Auf mich. Er war mein bester Freund, auch wenn keiner von uns beiden das je zugeben wollte. Prost, dein Onkel Sepp."

### Horsts Erinnerung 4 (Auflösung)
„Weißt, der Konrad hat dem Sepp zuliebe das Rezept verkaufen wollen. Und der Sepp hat's nie erfahren. Ich hab's gewusst und nix gesagt. Auch ich hab Fehler gemacht."

### Duell-Turnier (✔, spät im Spiel)
- Maß-Wettschleppen gegen Konrad in mehreren Stufen, jede mit eigener Strecke und Preisgeld (Stufe 1 ab Kapitel 5, weitere danach).
- Wiederholbar als Geld-Quest, Konrad wird mit jeder Stufe schneller.

### Danach: offene Welt
Gefallen von Horst (alle paar Tage), Nebenquests, Turnier-Stufen, Meilensteine, Zufallsereignisse, Sondertage. Neue Kapitel später möglich (z. B. Wiesn-Expansion, Hotel, Bahnhof-Zelt).

## 14. Querschnitt: Quest-System, Kirmes, Mitarbeiter, Ereignisse

### Quest-Arten
| Art | Wer | Verfall |
|---|---|---|
| **Hauptquest** | Horst (Mail und Gespräch) | **kein Verfall** (✔), sie müssen erledigt werden |
| **Nebenquest** | Horst | Verfällt nach einiger Zeit, je nach Quest unterschiedlich (✔) |
| **Gefallen** | Horst, etwa alle paar Tage (✔) | Kurze Frist in **Spieltagen** (✔), sonst „zu spät" |
| **Kirmes-Quest** | Budenbesitzer über Horst | Frist je nach Quest |

### Wenn eine Frist abläuft (✔)
Horst sagt etwa: „Zu spät, Konrad hat es schon erledigt. Auch wenn ich dich mag, manche Dinge haben Priorität." Die Quest ist weg. Je nach Quest hat das **Folgen** (Konrad bekommt einen Vorteil oder man verpasst einen Bonus), nie ein Spielende.
**✔ Story-wichtige Quests haben nie eine Frist** (müssen erledigt werden, sonst ginge die Story kaputt). Fristen gibt es nur für Nebenquests, Gefallen und Kirmes-Quests. Der Satz „Zu spät, Konrad hat es erledigt" gilt also nur für diese.

### Kirmes-Quests (✔ Gäste lotsen, Bude retten, Minispiel-Rekorde, Lieferungen)
- **Gäste lotsen:** Der Budenbesitzer will mehr Kundschaft. Man schickt Gäste (Ansprache oder Schilder) zur Bude, Belohnung vom Besitzer.
- **Bude retten:** Etwas ist kaputt, gestohlen oder im Streit. Man hilft (Gefallen-Muster).
- **Minispiel-Rekorde:** An Buden bestimmte Punktzahlen erreichen (Dosenwurf, Lukas, Maulwurf usw.).
- **Lieferungen:** Waren oder Essen zu Buden bringen.

### Mitarbeiter
- Krankmeldungen per Mail, Löhne und Müdigkeit in der Personal-App, Abwerben durch Konrad (Kapitel 3).
- Rollen: Koch, Kellner, Reinigung, Zapfer, **Security** (neu, Kapitel 3), **Bräumeister** (neu, Kapitel 4).

### Ereignisse
Regen, Touristenbus, Hygienekontrolle, Happy Hour, Fass kaputt, Prosit-Tag, Promi. Sondertage (Anstich, Tracht, Familie, Italiener) als Kalender-Zyklus. Wetter und Amt kündigen vor.

### Fristen
✔ Fristen zählen in **Spieltagen** (z. B. Gefallen 2 Tage, Nebenquests 3 bis 5, Kirmes-Quests je nach Aufgabe).

### Dauer (✔)
Jedes Kapitel etwa **1–2 Stunden**, die Story insgesamt etwa 6–10 Stunden, danach offene Welt.

## 15. Gesamtliste: was gebaut wird, was entfällt

### Systeme (neu oder umgebaut)
1. **Kapitel-Fortschritt** (Spielstand, Story-Ziele, Freischaltungen je Kapitel).
2. **Quest-System** mit Haupt-, Neben-, Gefallen- und Kirmes-Quests, Fristen in Spieltagen, „zu spät"-Meldung, Belohnungen.
3. **Computer-Desktop** (Übergangs-Animation per E, Fenster, Apps): E-Mail, Shop, Kalender, Bank, Personal, Bilanz, Bierpreis, Quests, Wetter und Amt, Social Media. Später **Laptop im Wohnwagen**.
4. **E-Mail-System** (Postfach, Absender, Antworten mit zwei Auswahlmöglichkeiten, Krankmeldungen, Konrad-Mails, Bank, Amt, Lieferant).
5. **Gefallen-Generator** (Horst, alle paar Tage) mit Ortsereignissen auf der Kirmes: Täter erscheint, wird gefunden, gepackt, getragen, übergeben.
6. **Security** als Personal (Rolle fünf) und **feste Security-Posten** auf der Kirmes.
7. **Bräumeister** als Personal (Rolle sechs), **Rezeptbuch**, Qualitätsstufen, Rezeptseiten.
8. **Duell-Turnier** mit Stufen und Preisgeld.
9. **Wetten, Sabotage, Abwerben, Bewertungen** (Konrad) an die Kapitel gekoppelt.
10. **Kirmes-Quests** an den Buden (Gäste lotsen, retten, Rekorde, Lieferungen).
11. **Brabbelton** je Figur im Dialog (statt Sprachausgabe).

### Figuren
Vorhanden: Horst (Glatze, Walross), Konrad (Zylinder, Monokel), Security, alle Berufe.
Neu zu erstellen (über den Charakter-Creator, sofern nichts Neues nötig ist): Täter der Gefallen (Spanner, Taschendieb, Betrunkener, Raufbolde), verlorenes Kind, Konrads Spion, Promi, Bräumeister Gerhard, ggf. Bankberater.

### Orte
Büro mit Computer-Animation, Wohnwagen-Laptop, Braukeller (vorhanden, überarbeiten), Kirmes mit Security-Posten und Quest-Orten (Teufelsrad, Riesenrad, Turm, Karussell, Lukas).

### Texte (grobe Schätzung)
- Kapitel-Dialoge Horst: ca. 120 Zeilen, Erinnerungen 1–4.
- Mails: ca. 80–100 (Horst-Aufträge, Konrad, Krankmeldungen, Bank, Amt, Lieferant, Social Media).
- Quest-Titel und Texte: ca. 80 Haupt- und Nebenquests plus Gefallen.
- Alles in Deutsch, Englisch und Türkisch, Du-/Ihr-Form.

### Entfällt
Saison/16 Tage, Finale und Duell am letzten Tag, Taste K, fest getaktete Bankraten, Kostensteigerung mit dem Tageszähler, Abschlussbrief am Saisonende (wird zum Brief nach dem großen Fest), Doppel-Brief im Tutorial.

### Anpassen
Namen (Konrad, Festleiter Horst, Ludwig, Veronika, Katharina), Zeitung („Alois Konrad" → „Konrad"), Meilensteine (Saison-Meilensteine ersetzen), Tutorial (Computer-Einführung).

## 16. Reihenfolge der Umsetzung (Vorschlag von Claude, ✔ Serdar hat die Wahl überlassen)

Idee: **zuerst ein durchgehender Schnitt**, damit man früh sieht, ob sich das neue Spiel richtig anfühlt, danach Kapitel für Kapitel füllen.

1. **Grundlage:** Kapitel-Fortschritt im Spielstand, Quest-System (Quest-Daten, Fristen, Belohnungen), E-Mail-System.
2. **Desktop:** Übergangs-Animation am Büro-Computer, Desktop-Fenster, Apps (zuerst E-Mail, Shop, Quests, Bank, Bilanz, Bierpreis, Personal, dann Kalender, Wetter/Amt, Social Media). Festbüro-Menü und Taste K werden abgelöst.
3. **Saison entfernen:** Kosten fix, Finale und Bankraten raus, Namen und Texte angleichen.
4. **Kapitel 1 komplett:** Kurzszene, Brief, Horst, Tutorial über den Desktop, erster Feierabend, erste Mails.
5. **Kapitel 2:** Einkaufs-Mails, Krankmeldungen, Wetter und Amt, Zelt-Ausbau, Bank-Abzahlung.
6. **Gefallen-System und Security:** Security-Posten, Täter-Figuren, Teufelsrad-Quest, danach die weiteren Gefallen.
7. **Kapitel 3:** Konrads Streiche, Security im Zelt, Saboteur-Beweise.
8. **Kapitel 4:** Rezeptbuch, Qualität, Bräumeister, Braukeller überarbeiten.
9. **Kapitel 5 und Duell-Turnier:** Riesenzelt, großes Fest mit Cutscene und Feuerwerk, Schluss-Brief.
10. **Kirmes-Quests, Wohnwagen-Zuhause, Brabbelton, Balancing, Tests.**

Balancing (✔) erfolgt **nach dem Bau** mit Testspielen und `tools/sim_saison`.

## 17. Hinweise, Gäste, Wohnwagen

### Hinweise (✔ „Hinweise im Moment")
Beim **ersten Mal** erscheint ein kurzer Hinweis genau dann, wenn er gebraucht wird (erste Bestellblase, erste Pfütze, erster Streit, erster Mitarbeiter krank …). Das Hilfe-Fenster (H) und die Tipps in der Bilanz bleiben vorerst, werden aber bei Bedarf umgestellt.

### Gäste (✔ Gruppen und Wunschlieder, mehr Chaos)
- **Gruppen:** Gäste kommen als Gruppe (Familie, Stammtisch, Verein, Junggesellenabschied) und setzen sich zusammen. Gruppen bestellen gemeinsam und gehen gemeinsam.
- **Wunschlieder:** Gruppen wünschen sich vom Künstler ein Lied. Erfüllt man den Wunsch (Künstler spielt es), gibt es Beliebtheit und Trinkgeld.
- **Mehr Chaos:** Neue Zwischenfälle wie verschüttetes Bier, Flirt am Tisch, Heiratsantrag, Karaoke-Runde. Sie bringen Chancen und Probleme.
- Die vorhandenen Gasttypen (Stammgast, Tourist, Tracht, VIP) und Rausch-Stufen bleiben.

### Wohnwagen als Zuhause (✔ alles)
- **Laptop** mit demselben Desktop wie im Büro.
- **Spiegel** öffnet den **Charakter-Creator** (Aussehen, Kleidung, Schuhe).
- **Regale** für Trophäen (Meilensteine, Quest-Belohnungen) und **Sepp-Fotos** (Erinnerungsstücke, die Horst übergibt).
- **Einrichtung kaufen** (Bett, Sofa, Teppich, Poster) im Shop, platzieren wie im Zelt.

## 18. Ideenkatalog (Claude, zum Auswählen und Streichen)

Ziel: In jedem Kapitel soll es über die Story-Quests hinaus **genug zu tun** geben, und im Late Game **Dinge, für die sich Geld lohnt**.

### 18.1 Gefallen von Horst (Aktion auf der Kirmes oder im Zelt)
Schon notiert: Spanner, Taschendieb, Betrunkener auf dem Turm, verlorenes Kind, Streit am Lukas, Konrads Spion, Lieferung, Promi.
Neu vorgeschlagen:
1. **Die Sau ist los:** Eine Sau vom Sauerennen ist ausgebüxt. Einfangen und zurückbringen.
2. **Brand am Imbiss:** Feuer an einer Bude. Eimerkette bilden (Wasser holen, löschen).
3. **Falschgeld:** An einer Bude taucht Falschgeld auf. Den Fälscher unter den Gästen finden.
4. **Schnapsleichen:** Betrunkene liegen zwischen den Buden. Einsammeln und zum Sanitäter tragen.
5. **Hochzeit im Zelt:** Ein Brautpaar feiert, Musik wünschen, Torte holen, Schleier suchen.
6. **Sturmwarnung:** Planen und Lichterketten sichern, bevor der Sturm kommt.
7. **Reporter vom Wiesn-Blatt:** In zwei Minuten das Zelt vorzeigefertig machen, dann Interview.
8. **Gruppenfoto:** Gäste für das Titelbild der Zeitung zusammentrommeln.
9. **Gestohlene Krüge:** Krüge verschwinden von den Tischen. Dieb auf frischer Tat ertappen.
10. **Fahrgeschäft streikt:** Die Sicherung finden und reparieren, bevor Gäste unruhig werden.
11. **Verlorener Hund:** Besitzer unter den Gästen finden.
12. **Wettessen:** Brezn- oder Hendl-Wettessen organisieren, Teilnehmer finden, Preis stellen.
13. **Entlaufene Kutschpferde:** Pferd beruhigen und zum Stall führen (Trachtenumzug).
14. **Streit zweier Vereine:** Schlichten durch Freibier an beide.

### 18.2 Nebenquests (Wirtschaft, kurz, mit Frist)
Gäste bedienen, Umsatzziel, saubere Tage, keine Beschwerde, Sorte als Hit (viele Weizen), Kombo xN, Happy-Hour-Auftrag („300 Maß in einer Stunde"), Tanzrekord, Hygienekontrolle bestehen, Stammgast-Streak, Bühne ausverkauft, Promi bedient, voller als gestern.

### 18.3 Late Game: wofür man viel Geld ausgibt
1. **Zelt-Ausbauten:** Empore, VIP-Lounge, Biergarten, größere Bühne, zweite Theke.
2. **Brauerei-Ausbau:** Maschinen, mehr Gärfässer, **Bier an andere Zelte verkaufen** (Einnahmequelle), Qualität steigern.
3. **Kirmes-Buden kaufen und betreiben:** Eine Bude selbst führen (Mitarbeiter, Gewinn).
4. **Zweites Zelt / Filiale:** Auf einem anderen Platz, mit eigenem Personal (Verwalten über den Desktop).
5. **Sponsoring und Werbung:** Plakate, Radiospots, Banner. Mehr Gäste.
6. **Personal-Akademie:** Mitarbeiter trainieren (Spezialisierungen, Stufe 10).
7. **Prestige:** Pokale, Statuen, Ehrenplakette, Sepp-Denkmal vor dem Zelt, Wiesn-Orden.
8. **Konrads Zelt aufkaufen** (später Handlungsstrang).
9. **Neue Kapitel:** weitere Orte und Geschichten als Updates.

### 18.4 Glücksspiel und Wetten (außer Teufelsrad und Glücksrad)
Vorschläge (alle klein, an Buden oder am Tisch, Einsatz in Euro):
1. **Hütchenspiel** (drei Krüge, wo ist der Taler?), der Trickser kann betrügen.
2. **Würfeln um die Rechnung** am Stammtisch (Knobeln, doppelt oder nichts).
3. **Kartenspiel Schafkopf oder Watten** mit Stammgästen (Einsatz, Mini-Version).
4. **Sauerennen:** Wetten auf eine von sechs Säuen, Lauf live auf der Kirmes.
5. **Tombola und Los-Bude:** Lose kaufen, Preise (Plüschbär, Freibier, Geld).
6. **Roulette im Hinterzimmer** (Konrads Revier).
7. **Armdrücken** gegen Gäste (Einsatz).
8. **Bierkrug-Wette** zwischen zwei Gästen (wer trinkt zuerst leer), Wettbüro.

### 18.5 Koop und Wohnwagen
Der Wohnwagen ist für mehrere Spieler zu klein. Vorschläge:
- **Jeder Spieler hat einen eigenen Wohnwagen** (Wohnwagenplatz mit mehreren Wagen), mit eigenem Laptop, Spiegel, Regal.
- **Gemeinsamer Aufenthaltsraum** (großer Wohnwagen oder Hütte) für Trophäen, Sepp-Fotos und Besprechungen.
- Geteiltes Konto, Quests für alle, jeder sieht die Mails (oder nur der Büro-Spieler).

### 18.6 Was man in jedem Kapitel tut (Alltag, nicht nur Story)
**Tagesablauf (von Anfang an):** Morgen Aufbau und Bestellungen (Desktop), Mittag erster Andrang, Nachmittag Gefallen und Nebenquests auf der Kirmes, Abend Hauptandrang mit Tanzen, Nacht Feierabend, Bilanz, Mails.
**Entwicklung:** K1 lernen, K2 Personal und Ausbau, K3 gegen Konrad bestehen, K4 selbst brauen, K5 großes Fest, danach Late Game (Brauerei verkaufen, Buden, Turnier, zweites Zelt).

## 19. Entschieden aus dem Ideenkatalog

- ✔ **Late-Game-Ausgaben:** Zelt-Ausbauten, Brauerei verkaufen (Bier an andere Zelte), Buden und Zweitzelt. Nicht gewählt: Werbung, Akademie, Prestige (kann als Teil des Endziels wiederkommen).
- ✔ **Offene Frage von Serdar:** Brauchen wir ein **Endziel**, für das man das Geld ausgibt? (Siehe Fragen unten.)
- ✔ **Glücksspiel:** nur **Karten (Schafkopf/Watten)** und **Roulette** (Hinterzimmer). Hütchenspiel, Würfeln, Armdrücken, Sauerennen, Tombola entfallen vorerst.
- ✔ **Wohnwagen im Koop:** **Eigener Wohnwagen je Spieler.** Jeder kann ihn **innen und außen anpassen** (Farbe, ausbauen, größer machen) und bekommt dadurch **Vorteile**.
- ✔ **Gefallen:** Die Sau ist los, Brand am Imbiss, Sturmwarnung, Falschgeld, gestohlene Krüge (Diebe), Konrads Spion, Hochzeit im Zelt, Reporter, Wettessen. **Nicht** gewählt: Schnapsleichen, Hund, Pferde.
- Idee Serdar: **Skilltree** (z. B. mehr Krüge tragen). Meine Einschätzung: sinnvoll als persönlicher Fortschritt je Spieler im Koop.

## 20. Endziel, Casino, Wohnwagen (Entwurf auf Basis deiner Antworten)

### Endgame-Ziele (✔ „Das eigene Fest" und „Sammeln und Meister")

**A. Das eigene Fest.** Nach Kapitel 5 darf man selbst **Feste ausrichten**.
- Am Desktop (App „Fest") wählt man ein **Motto** (Trachtenfest, Bierfest, Italienische Nacht, Rockabend, Oldtimer-Treffen …), ein **Programm** (Künstler, Wettbewerbe, Feuerwerk), **Dekoration** und **Werbung**.
- Das Fest läuft an einem Sondertag. Es kostet Geld (Künstler, Dekor, Werbung) und bringt **Festruhm** (Punkte) abhängig von Gästezahl, Zufriedenheit, Bierqualität und Zwischenfällen.
- Festruhm schaltet **Festränge** frei: Dorffest, Stadtfest, Landesfest, Wiesn-Highlight, Weltfest. Jeder Rang gibt Prestige-Gegenstände (Statue, Banner, Ehrenplatz) und mehr Gäste.
- Hier fließt das Geld: Ausbauten, Brauerei, Buden, Zweitzelt, Künstler, Dekor.

**B. Sammeln und Meister.** Eine **Meister-Liste** (Quests-App) mit allem, was es gibt: Trophäen, alle Gefallen einmal, alle Turnierstufen, alle Ausbauten, Sepp-Fotos, Rezeptseiten, alle Buden, alle Personalstufen, alle Stammgast-Belohnungen. 100 % = Titel „Wiesn-Meister" und goldener Krug am Wohnwagen.

### Skilltree (✔ entfällt, nicht nötig)
Bleibt vorerst weg. Persönlicher Fortschritt kommt über Wohnwagen-Upgrades und Ausrüstung (siehe unten), nicht über Erfahrungspunkte.

### Casino (✔ Hinterzimmer im Zelt, ✔ Pflichtquest in Kapitel 3)
- ✔ Das Casino liegt **hinter Konrads Zelt** (siehe Abschnitt 25), nicht im eigenen Zelt. Freigeschaltet durch die **Pflichtquest 3.4b** in Kapitel 3. Horst kann erzählen, dass Sepp früher dort verloren hat, was einen Teil der Schulden erklärt (offene Idee).
- **Roulette** (gegen den Croupier, Einsatz in Euro, klassische Zahlen/Farben) und **Karten** (Schafkopf/Watten gegen Stammgäste, Mini-Version mit Einsatz).
- Eigene Einnahmen/Verluste in der Bilanz. Schwelle: Limit pro Tag, damit man sich nicht ruiniert.
- Glücksrad bleibt als Kirmes-Spiel.

### Wohnwagen je Spieler (✔)
- Eigener Wohnwagen für jeden Spieler auf einem **Wohnwagenplatz**.
- **Anpassen:** innen (Einrichtung, Laptop, Spiegel, Regal) und **außen** (Farbe, Anbau, größer).
- **Vorteile (✔ Schlafqualität, Aussehen und Status):** Besseres Bett gibt mehr Energie am Morgen und längere Arbeitszeit. Aussehen bringt Prestige-Punkte (Festruhm). Keine Lager- oder Laptop-Boni.
- Gemeinsamer Aufenthaltsraum für Trophäen und Sepp-Fotos.

## 21. Der Festtag (Entwurf, ✔ „ein Ereignis: Band buchen, Feuerwerk usw.")

**Rhythmus (✔ alle 10 Spieltage):** Man plant ein Fest am Desktop (App „Fest") für einen freien Tag. Danach etwa 10 Spieltage Pause. **Konkurrenz:** Konrads Zelt hat ebenfalls Festruhm als Vergleichswert.

### Vorbereitung (am Desktop und im Zelt)
1. **Motto wählen:** Trachtenfest, Bierfest, Italienische Nacht, Rockabend, Familienfest. Das Motto verändert die Gästemischung und die Musik.
2. **Band buchen** (Pflicht): Straßenmusiker, Blaskapelle, Star-Act, später mehr Bands. Je Band Preis, Set-Dauer und Beliebtheit.
3. **Feuerwerk kaufen** (Stufen: klein, mittel, groß).
4. **Dekoration und Werbung** (optional): Banner, Lichterketten, Plakate, Radiospot.
5. **Personal verstärken:** Aushilfen (Kellner, Security) für diesen Tag mieten.
6. **Ware vorbereiten:** mehr Bier und Essen lagern, sonst läuft es aus.

### Der Tag
- **Morgens:** Aufbau der Bühne und des Feuerwerks, Plakate hängen.
- **Mittag:** Tor öffnet, erste Gäste, Motto-Gäste (z. B. Trachtler).
- **Nachmittag:** Band spielt Sets (Wunschlieder, Gruppen), Wettbewerbe (Maßkrug-Stemmen, Brezn-Wettessen).
- **Abend:** Hauptandrang, Tanzen auf Tischen, Zwischenfälle (Schlägerei, Verschüttetes, Heiratsantrag).
- **21:00 Uhr:** **Feuerwerk** (Cutscene-artig, Gäste jubeln, Bonus auf Beliebtheit).
- **22:00 Uhr:** Finale, Bilanz und Zeitung (Titelseite des Wiesn-Blatts).

### Bewertung und Belohnung
- **Festruhm** aus Gästezahl, Zufriedenheit, Umsatz, Bierqualität, Zwischenfällen (wenig ist gut) und der Band.
- **Festränge:** Dorffest, Stadtfest, Landesfest, Wiesn-Highlight, Weltfest. Jeder Rang schaltet Prestige-Gegenstände (Statue, Banner, Ehrenplatz) und mehr Gäste frei.
- **Konrad** reagiert mit Mails (neidisch oder anerkennend), und sein Festruhm steigt ebenfalls.

### Offene Punkte
- Wie viele verschiedene Bands (nur die vorhandenen drei oder mehr)?
- Welche Wettbewerbe gibt es am Festtag (vorhanden: Maß-Wettschleppen, Minispiele)?
- Gibt es zufällige Katastrophen (Regen am Fest, Stromausfall) und was kann man dagegen kaufen?

## 22. Sabotage: Konrad gegen dich, du gegen Konrad (Entwurf)

**Wichtig zum Ist-Zustand:** Die frühere Konrad-Handlung (Wetten, Saboteur, Abwerben, Duell) ist seit **v269 (28.09.2026)** im Spiel **abgeschaltet** (`_huber_morgen` bricht sofort ab). Der Code für Wette, Fass-Leck, Stinkbombe, Saboteur-Figur und Duell ist noch da, läuft aber nicht. Auch die Saison und die Bankraten sind laut diesem Stand schon raus. Das Kapitel-System setzt dort neu an.

### 22.1 Wie Konrad dich sabotiert

Prinzip: Jeder Streich hat **Vorwarnung** (Mail, Gerücht, verdächtige Gestalt), **Ausführung** (Ereignis im Zelt) und **Gegenmittel** (Reaktion des Spielers oder vorbeugende Einrichtung). Er sabotiert, wenn er „Laune" hat: je erfolgreicher der Spieler, desto aggressiver. Streiche wachsen nach Kapitel.

| Streich | Ab Kapitel | Vorwarnung | Wirkung | Gegenmittel |
|---|---|---|---|---|
| Fass-Leck | 3 | Mail oder Gestalt am Lager | Bier läuft aus, kostet Ware | Fass finden und abdichten, Security |
| Stinkbombe | 3 | verdächtiger Gast | Gestank, Gäste gehen, Sauberkeit sinkt | Lüften (Fenster), Reinigung |
| Saboteur im Zelt | 3 | Gerücht | Gast mit Rucksack schleicht zu Fass/Lager | Security, Spieler packt ihn |
| Abwerben | 3 | Krankmeldung/Mail | Mitarbeiter kündigt | Gehalt erhöhen, Gespräch |
| Falsche Bewertungen | 3 | Social-Media-Meldung | Beliebtheit sinkt | Bewertungen melden (Social-App), Gäste zufriedenstellen |
| Hygiene-Tipp ans Amt | 3 | **keine** (ohne Vorwarnung, nur Hinweis von Horst) | Frau Wagner steht plötzlich mit Klemmbrett im Zelt (Figur), Ergebnis kommt per Mail danach | Zelt sauber halten |
| Lieferwagen umleiten | 4 | verspätete Lieferung | Ware kommt später | Bestellung früher aufgeben, Lager |
| Zutaten blockieren | 4 | Mail der Brauerei | Hopfen/Malz fehlt | Alternative Quelle, Vorrat |
| Diebe (Krüge) | 4 | verschwundene Krüge | Weniger Krüge | Überwachung (Kamera), Security |
| Stromausfall | 4 | flackerndes Licht | Zelt dunkel, Gäste unruhig | Sicherungskasten reparieren |
| Künstler abwerben | 5 | Absage-Mail | Band sagt am Festtag ab | Zweite Band, Vertrag (Anzahlung) |
| Preisdumping | 5 | Aushang | Konrad verkauft billiger, Gäste wandern ab | Preis senken, Aktion |
| Übernahme-Angebot | 5 | Mail | Hoher Druck, Entscheidung | Ablehnen (Quest 5.1) |

**Eskalation:** Konrads Laune sinkt, wenn man ihn schlägt (Turnier, Beweise), und steigt, wenn man ihn ignoriert.
**Schutz** (Einrichtung, Shop): Schloss am Lager, Kamera, Wachhund, Alarmanlage, Versicherung. Sie verringern die Wirkung oder zeigen den Täter.

### 22.2 Wie du Konrads Zelt sabotierst

Die Zelt-Szene (rotes Konrad-Zelt) gibt es schon. Vorschlag: **Nur über Quests und die Desktop-App „Spion"/Kontakte**, nicht frei, damit es kontrollierbar bleibt.

| Aktion | Wie | Risiko |
|---|---|---|
| Spion einschleusen | Mini-Auftrag: Rezept oder Preise im Konrad-Zelt auskundschaften (Schleichen) | Erwischt = Ruf −, Konrad schickt Mail |
| Fass anstechen | Im Konrad-Zelt unbemerkt ein Fass anbohren | Erwischt = Security wirft dich raus |
| Gerücht streuen | Zeitungs-Anzeige oder Social Media | Kostet Geld, Gegenschlag möglich |
| Gäste abwerben | Freibier-Aktion vor seinem Zelt, Plakat | Kostet Ware |
| Mitarbeiter abwerben | Gehaltsangebot an seine Leute (Mail) | Kostet Gehalt, Konrad rächt sich |
| Hygiene-Tipp ans Amt | Meldung am Desktop (Wetter und Amt) | Amt kann auch dich prüfen |
| Künstler wegschnappen | Beliebte Band zuerst buchen | Preis steigt |

**Entschieden (✔):** Sabotage am Konrad-Zelt ist **frei, aber begrenzt**: Man darf jederzeit hin, aber jede Aktion hat eine **Wartezeit** (z. B. eine pro Spieltag und Art). Es gibt **keinen Fairplay-Wert**, nur **Risiko**: Wer erwischt wird, wird rausgeworfen, zahlt eine Strafe oder bekommt eine Mail von Konrad. **Konrad schlägt zurück:** Auf jede Sabotage folgt in den nächsten Tagen ein stärkerer Streich von ihm (Eskalation).

### 22.3 Wann Sabotage gespielt wird
Kapitel 3: Konrad sabotiert, du sammelst Beweise. Kapitel 4 und 5: Gegenschläge möglich (Spion, Abwerben). Nach der Story: seltener, aber dauerhaft, damit Konrad als Dauer-Gegner spürbar bleibt.

## 23. Sabotage im Detail: Händler, Werkzeuge, Ablauf (Entwurf)

### 23.1 Der Händler
- **Schwarzmarkt-Händler Gustav** (✔ Name), steht abends hinter dem Riesenrad oder zwischen zwei Buden, zwielichtiger Typ mit Hut und Koffer.
- Wird in Kapitel 3 per Quest eingeführt („Horst: Ich kenn da einen, aber ich weiß von nix"). Vorher ist er nicht ansprechbar.
- Sortiment wechselt nach Tagen und Kapiteln, die Preise schwanken. Bezahlt wird bar.
- Man kann bei ihm auch **Schutz** kaufen (Schloss, Kamera) und Informationen über Konrads Pläne (Hinweis auf den nächsten Streich).
- Spaßfaktor: Er verkauft manchmal auch an Konrad. Dann kommt der nächste Streich schneller.

### 23.2 Werkzeuge (Auswahl, jeweils ein Einzelstück, das verbraucht wird)

| Werkzeug | Ziel | Wirkung | Risiko |
|---|---|---|---|
| **Fassbohrer** | Fass im Konrad-Zelt | Fass läuft aus, Bier und Umsatz sinken | Wachen und Kamera |
| **Zange** | Sicherungskasten | Stromausfall im Zelt für einige Minuten | gering, aber laut |
| **Stinkbombe** | Gastraum | Gestank, Gäste verlassen das Zelt | Spuren (Verdächtiger) |
| **Mäusekiste** | Küche, Lager | Mäuse laufen herum, Hygieneprobleme, Amt meldet sich | Quietschen |
| **Juckpulver** | Kellner-Uniformen oder Sitzbänke | Gäste und Personal kratzen sich, langsamer | mittel |
| **Flugblätter** | Kirmes | Gerüchte, Beliebtheit sinkt | Reaktion in der Zeitung |
| **Bestechung** | Personal | Mitarbeiter wechselt zu dir | Geldverlust, wenn er ablehnt |
| **Schmiergeld** | Lieferfahrer | Lieferung zu Konrad verzögert | Auffliegen |
| **Tarn-Maske** (✔) | dich selbst | Die Schnauzer-Brille mit den dicken Augenbrauen (Spaß-Verkleidung, passt zum Creator-Aussehen). Konrad erkennt dich nicht sofort. | Beim Erwischen peinlich |
| **Furzkissen** (neu) | Sitzbänke | Gäste lachen, Gäste stehen auf, Chaos | gering |
| **Seifenblasen-Pulver** (neu) | Fass | Bierschaum quillt über, kleine Pfütze, Spaß | gering |

### 23.3 Ablauf einer Sabotage (✔ umziehen, Konrad läuft durchs Zelt)
1. Werkzeug beim Händler Gustav kaufen (Preis zwischen 50 und 400 €).
2. **Umziehen (✔):** Wer **ohne Klamottenwechsel** hingeht, wird von Konrad **leichter erkannt** (größerer Erkennungsradius, schnellere Entdeckung). Bei Gustav kauft man einen **Mantel** oder ein **Komplettset mit Maske** (Mantel, Hut, **Schnauzer-Brille mit dicken Augenbrauen**). Das Komplettset ist am sichersten, Mantel allein hilft ein bisschen.
3. Ins Konrad-Zelt gehen. **Konrad läuft während seiner Schicht selbst durchs Zelt** (kein Wachen-Sichtkegel nötig). Wer sabotiert, **während Konrad ihn ansieht**, wird erwischt.
4. Ziel erreichen und Werkzeug einsetzen (E halten, Balken, Geräusch). Nur ausführen, wenn Konrad gerade woanders hinschaut.
5. **Erwischt:** Bußgeld (**Höhe wird später entschieden**), Rauswurf, Werkzeug verbraucht.
6. **Gelingt es:** Konrad **verliert Kunden**, und **du gewinnst Kunden dazu** (Gäste wandern ab). Konrad antwortet in den nächsten Tagen mit einem stärkeren Streich (Eskalation, ✔).

### 23.4 Begrenzung (✔ „frei, aber begrenzt")
- Pro Werkzeugart **eine Anwendung pro Spieltag**.
- Der Händler hat nur 2–3 Stück pro Tag auf Lager.
- Zu viele Sabotagen in kurzer Zeit machen Konrad wachsamer (er schaut häufiger umher).

### 23.5 Konrads Gegenmaßnahmen
Er schaut häufiger umher, stellt Kameras und Schlösser auf, gelegentlich ein Wachhund. Seine Zeitungs-Interviews drohen („Ich weiß, wer's war").

## 24. Konrads Zelt überarbeiten (Plan, ✔ „muss überarbeitet werden")

**Ist-Zustand** (`scenes/huber_zelt.tscn`): Eine verkleinerte, rot gefärbte Kopie unseres Zeltgerüsts (`scenes/tent.tscn`) mit Schild „Konrad". Innen stehen 9 **Biergarten-Tische** (`scenes/zelt/biergarten_tisch.tscn`) und 3 Fässer (`fass.tscn`). Konrad steht davor als einzelne Figur. **Es gibt keinen Zapftresen, keine Bühne, kein Lager, keinen Sicherungskasten, kein Personal, keine Gäste.**

**Soll-Zustand (Vorschlag):**
- **Gleiche Tische und Bänke wie bei uns** (`scenes/beer_table.tscn`), mit denselben Sitzplätzen.
- **Zapftresen und Ausgabe** wie bei uns (`schanktheke`, `ausgabe`), dazu Kochtheke, Lagerregal, Bühne, Klo.
- **Sabotage-Ziele** gut erkennbar: Fass, Sicherungskasten, Küche, Bänke, Lager.
- **Leben:** Konrads **Personal** (Kellner, Zapfer) läuft herum, und Gäste sitzen an den Tischen (Zahl hängt von seinem Festruhm ab).
- **Konrad selbst** läuft während seiner Schicht eine feste Runde durchs Zelt und schaut sich um (sein Blickfeld bestimmt das Erwischen).
- **Wachstum:** Konrads Zelt wird mit den Kapiteln größer und besser, damit er ein glaubwürdiger Gegner bleibt.
- **Optik:** Rote Farbgebung, Zylinder-Schild, gemeinsame Einrichtung (dieselben Modelle wie bei uns).
- **Konrad-Figur:** Zylinder, Monokel, Fumanchu, weinroter Janker (schon im Spiel).

**Gäste und Kunden (✔ Idee):** Konrads Kundenzahl ist ein Wert (nicht jeder Gast ein echter Spieler-Gast). Sabotage und Aktionen verschieben diese Zahl zu dir oder zu ihm.

## 25. Korrektur: Casino liegt hinter Konrads Zelt

✔ Serdar: **Konrads Zelt muss vergrößert werden, wegen des Casinos dahinter.** Das ersetzt meinen früheren Vorschlag (Casino als Sepps Spielzimmer im eigenen Zelt, Quest „Die Geheimtür").

- **Konrads Zelt bekommt einen Anbau hinten: das Casino** (Roulette, Kartentische, Croupier, Türsteher). Dadurch ist sein Zelt größer als heute (siehe Abschnitt 24).
- **Pflichtquest in Kapitel 2 oder 3 (✔):** Der Spieler muss das Casino kennenlernen (Auftrag von Horst, z. B. Konrads Spion verfolgen oder eine Einladung erhalten). Damit schaltet sich das Casino zum Spielen frei.
- ✔ **Das Casino gehört Konrad, für immer.** Man spielt als Gast gegen seine Bank (Gewinne und Verluste gehen von und zu ihm). Man kann es sabotieren, aber nicht übernehmen.
- ✔ **Zugang nur mit Tarnung:** Der Türsteher lässt nur Verkleidete herein (Komplettset von Gustav). Ohne Tarnung erkennt man dich und wirft dich raus.
- Konsequenz für die Sabotage: Im Casino kann man ebenfalls Streiche spielen (Roulette-Kessel, Karten, Strom), mit Wachen.

## 26. Regeln (Antworten aus der Fragerunde)

- ✔ **Pleite = Rückschlag, kein Game Over:** Personal kündigt, Ausbau wird gesperrt, Horst gibt eine Rettungsquest, der Betrieb läuft weiter.
- ✔ **Schwierigkeit wie bisher** (Gemütlich, Normal, Festwahnsinn): Geduld der Gäste, Miete, Andrang. Konrads Aggression und Fristen bleiben gleich.
- ✔ **Koop:** Quests, Mails und Belohnungen gehören **allen gemeinsam** (eine Quest-Liste, gemeinsames Konto).
- ✔ **Bußgeld wächst** mit Kapitel und Zeltgröße (etwa 150 € am Anfang bis etwa 800 € im Late Game).
- ✔ **Bands:** wie heute **drei** (Straßenmusiker, Blaskapelle, Star-Act). Mehr Stufen nur durch Ausbau der Bühne.
- ✔ **Wettbewerbe am Festtag:** **Fassanstich** (auf der Bühne, die Bühne ist immer frei, dort steht nie ein Tisch) und **Maßkrug-Stemmen**. Kein Wettessen, keine Trachtenwahl.
- ✔ **Zufallskatastrophen am Festtag** (mit Gegenmitteln im Shop): Regen (Planen, Heizpilz), Stromausfall (Notstrom-Aggregat), zu viele Gäste (Security am Eingang, mehr Personal), Band fällt aus (zweite Band oder Vertrag mit Anzahlung).
- ✔ **Tageslänge:** wie heute lassen.

## 27. Sabotage und Konrads Zelt: Entscheidungen

- ✔ **Konrads Route:** zufällig zwischen Zielpunkten (Theke, Tische, Casino-Eingang, Bühne), unvorhersehbar.
- ✔ **Erwischen = Blickfeld und Verdächtig-Balken (beides):** Konrads Sichtfeld löst den Balken aus, Tarnung (Mantel, Komplettset) verlangsamt ihn, voll = erwischt.
- ✔ **Umfang:** **erst klein, später mehr.** Kapitel 3 startet mit 5 bis 6 Aktionen (z. B. Stinkbombe, Mäusekiste, Juckpulver, Furzkissen, Flugblätter, Fassbohrer), weitere (Zange, Bestechung, Schmiergeld, Casino-Streiche, Seifenblasen) kommen in den späteren Kapiteln.
- ✔ **Konrads Zelt-Größe:** **wie dein Zelt auf derselben Stufe, dazu der Casino-Anbau.** Wächst er mit dir mit, bleibt der Vergleich fair.

## 28. Casino-Regeln und Texte

- ✔ **Mehrere Spiele mit simplen Regeln:** Roulette, **Blackjack**, Karten (Schafkopf oder Watten in Mini-Form) und weitere einfache Spiele (z. B. Würfeln, Slot-Maschine nach Bedarf). Alle gegen Konrads Bank.
- ✔ **Kein Limit** bei den Einsätzen. Das Risiko trägt der Spieler. (Nebenwirkung: Das Casino ist die schnellste Art, Geld zu verlieren oder zu gewinnen. Pleite ist ein Rückschlag, kein Game Over.)
- ✔ **Texte:** kapitelweise gemeinsam. Claude schreibt je Kapitel einen kompletten Textblock auf Deutsch (Dialoge, Mails, Quests), Serdar liest und korrigiert, danach folgen die Übersetzungen.

## 29. Vier Themen im Entwurf (zum Durchgehen)

### 29.1 Kirmes-Quests der Buden
Zwölf Buden: Dosenwurf, Entenangeln, Glücksrad, Hau den Lukas, Kegeln, Krugschieben, Maulwurf, Nagelbalken, Pfeilwurf, Ringwurf, Schießstand, Stemmen. Der Budenbesitzer ist ein zufällig erzeugter Mensch mit echtem deutschem Namen (ID aus der Bude). Horst vermittelt die Quests (✔ alle Quests von Horst).

Pro Bude vier Quest-Typen (✔ aus Runde 14):
| Typ | Beispiel |
|---|---|
| **Gäste lotsen** | Schick fünf Gäste vom Zelt zum Dosenwurf (Ansprache E am Tisch). |
| **Bude retten** | Dem Maulwurf-Mann wurde der Hammer gestohlen. Täter finden. |
| **Minispiel-Rekord** | Erreiche 20 Punkte am Hau den Lukas. |
| **Lieferung** | Bring Ersatz-Dosen vom Lager zur Bude. |

Belohnung: Geld, Beliebtheit, kleine Preise (Dekoration fürs Zelt). Eine **Buden-Serie** („Bude für Bude") führt zum Meilenstein „Kirmes-Meister".

### 29.2 Meilensteine neu
Bisher 48 Meilensteine, darunter Saison-Meilensteine (Erstes Fest, Drei Feste, Fünf Maßkrüge), die wegfallen oder umgebaut werden.
Neue Gruppen:
- **Story:** je Kapitel ein Meilenstein, plus „Geschichte abgeschlossen".
- **Wirtschaft und Zelt:** Umsatz, Zeltstufen, Lizenzen (bleiben).
- **Personal:** Mitarbeiter-Anzahl, Stufen, alle Berufe eingestellt.
- **Brauen:** erstes Fass, perfekte Qualität, Bier verkauft.
- **Gefallen und Kirmes:** je 10 und 25 Gefallen, alle Buden, Rekorde.
- **Sabotage:** erste erfolgreiche Sabotage, 10 Sabotagen, nie erwischt.
- **Casino:** erste Runde, 10.000 € gewonnen, alles verloren.
- **Fest:** erster Festtag, jeder Festrang.
- **Sammeln:** Wiesn-Meister (100 %).

### 29.3 Zeitung und Social Media
- **Wiesn-Blatt** bleibt als Vollbild nach Feierabend (✔ „digital" wurde nicht gewählt), mit neuen Themen: Kapitelmeldungen, Konrads Streiche, Gefallen („Spanner am Teufelsrad gefasst"), Casino-Gerüchte, Festtag-Titelseite, Braukunst.
- **Social Media** (App): Bewertungen als Sterne, Kommentare von Gästen, Katharina postet, Konrad lässt falsche Bewertungen posten, man kann melden. Reagiert auf Quests und Streiche (positive Posts nach Gefallen).

### 29.4 Mitarbeiter und Personal-App
- **Rollen:** Koch, Kellner, Reinigung, Zapfer (vorhanden), **Security** (Kapitel 3), **Bräumeister** (Kapitel 4). Croupier gehört zu Konrad, nicht zu dir.
- **Eigenschaften** (vorhanden): flink, gemütlich, Charmeur, Schluckspecht, unauffällig. Dazu neu: **Zuverlässig/unzuverlässig** (Krankmeldungen), **Loyal** (schwer abzuwerben).
- **Stufen** 1 bis 10 mit Trainingskosten. Gehalt wächst mit Stufe.
- **Namen:** echte deutsche Namen (Liste prüfen, siehe Gedächtnis).
- **Krankmeldungen** per Mail (Ersatz für zwei Tage oder zahlen).
- **Abwerben:** Konrad (Kapitel 3 und später), der Spieler kann Konrads Leute abwerben (Sabotage-Aktion Bestechung).
- **Kleidung:** Berufskleidung (schon erstellt) und Schuhe.

## 30. Entscheidungen zu Abschnitt 29

- ✔ **Kirmes-Quests:** Nicht jede Bude braucht eine Quest, **wir dürfen nicht mit Quests überfahren**. Wenige, gut gewählte Buden-Quests (Richtwert 6 bis 8 insgesamt), der Rest bleibt Minispiel ohne Auftrag. Qualität vor Menge.
- ✔ **Meilensteine:** **etwas Geld** als Belohnung, ansonsten **Steam-Errungenschaften** (keine Gegenstände).
- ✔ **Social Media: mittelwichtig:** Beiträge liken, auf Kommentare antworten, Konrads Fake-Bewertungen melden. Wirkung auf Beliebtheit, aber kein eigenes Werbesystem.
- ✔ **Mitarbeiter:** **kurze Mails** (Wunsch, Urlaub, Hochzeit), keine eigenen Quests.
- ✔ **Allgemein:** Weniger ist mehr bei Quests. Auf dem Bildschirm sind höchstens eine Hauptquest und wenige Neben-/Gefallen-Quests gleichzeitig sichtbar.

## 31. Quest-Tempo und Konrads Grundriss

### Quest-Tempo (✔)
- Gleichzeitig offen: **1 Hauptquest + höchstens 3 andere** (Neben, Gefallen, Kirmes).
- **Angebot:** Nebenquests und Gefallen kommen **zufällig per Mail** von Horst. Der Spieler nimmt an oder ignoriert sie (verfallen mit der Frist).
- **Kapitelwechsel:** ruhig. **Am selben Abend kommt eine Mail** von Horst mit dem nächsten Hauptziel, keine Pause und kein hartes Umschalten.

### Konrads Zelt mit Casino (✔)
- **Größe und Aufbau:** wie dein Zelt, aber **Tresen, Ausgabe, Küche, Bühne und Tische anders angeordnet**, damit er eigen wirkt.
- **Casino im Keller (✔):** Eine Treppe oder Kellertür hinter Konrads Theke führt hinunter. Der Türsteher steht an der Kellertreppe (Tarnung nötig).
- **Technische Auflage (✔):** Das Casino darf **nicht buggy sein**, kein Clipping (Wände, Treppen, Tische), saubere Kollision, passende Beleuchtung und Wegfindung.
- Konrad läuft zufällig durchs Zelt (Obergeschoss), im Keller arbeiten Croupiers und Türsteher.
