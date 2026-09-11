extends RefCounted
## Wirtschaft fürs Endlosspiel (Plan 3.4): Kosten, Verkaufspreise und die Geduld
## der Gäste wandern mit dem Spieltag, damit Tag 40 nicht trivial wird.
## Alle Stellschrauben stehen hier an einer Stelle.
##
## Kosten steigen schneller als Verkaufspreise, Gäste werden ungeduldiger und
## die Beliebtheit bröckelt über Nacht — wer nicht ausbaut (Personal, Werbung,
## Deko, größeres Zelt), gerät nach und nach unter Druck.
## Ohne class_name (Server-Klassencache), Einbinden per preload.

## Miete und Ware: +2 % je Tag, höchstens doppelt so teuer
const KOSTEN_JE_TAG := 0.02
const KOSTEN_MAX := 2.0
## Verkaufspreise: +1,5 % je Tag, höchstens +80 %
const PREIS_JE_TAG := 0.015
const PREIS_MAX := 1.8
## Geduld der Gäste: −1 % je Tag, nie unter 60 %
const GEDULD_JE_TAG := 0.01
const GEDULD_MIN := 0.6
## So viele Tage bleibt die Beliebtheit über Nacht stabil …
const SCHONFRIST_TAGE := 7
## … danach sinkt sie jede Nacht um so viele Punkte
const BELIEBTHEIT_JE_NACHT := 2.0

## Rettungskredit (Plan 3.5): Aufschlag auf den Fehlbetrag …
const KREDIT_AUFSCHLAG := 0.2
## … und dieser Anteil jeder Einnahme geht an die Brauerei, bis alles getilgt ist
const KREDIT_ANTEIL := 0.25

static func _vergangen(tag: int) -> float:
	return float(maxi(tag, 1) - 1)

static func kosten_faktor(tag: int) -> float:
	return minf(1.0 + KOSTEN_JE_TAG * _vergangen(tag), KOSTEN_MAX)

static func preis_faktor(tag: int) -> float:
	return minf(1.0 + PREIS_JE_TAG * _vergangen(tag), PREIS_MAX)

## Die ersten Tage kostet das Zelt keine Miete — Zeit zum Einrichten.
const MIETFREIE_TAGE := 5

static func miete(basis: int, tag: int) -> int:
	if tag <= MIETFREIE_TAGE:
		return 0
	return roundi(float(basis) * kosten_faktor(tag))

## Bierpreis (Zelt-Computer): Faktor auf den Tagespreis je Maß
const BIERPREIS_MIN := 0.5
const BIERPREIS_MAX := 2.0
## Wie stark der Andrang auf den Preis reagiert: je 10 % billiger 9 % mehr Gäste
const PREIS_WIRKUNG := 0.9

## Andrang-Faktor zum Bierpreis: 50 % Preis → 145 %, 150 % → 55 %, nie unter 25 %.
static func preis_andrang(faktor: float) -> float:
	return clampf(1.0 + (1.0 - faktor) * PREIS_WIRKUNG, 0.25, 1.5)

static func paketpreis(basis: int, tag: int) -> int:
	return roundi(float(basis) * kosten_faktor(tag))

static func verkaufspreis(basis: int, tag: int) -> int:
	return roundi(float(basis) * preis_faktor(tag))

static func geduld(basis: float, tag: int) -> float:
	return basis * maxf(1.0 - GEDULD_JE_TAG * _vergangen(tag), GEDULD_MIN)

## Beliebtheitsverlust in der Nacht nach diesem Tag.
static func beliebtheit_verlust(tag: int) -> float:
	return BELIEBTHEIT_JE_NACHT if tag > SCHONFRIST_TAGE else 0.0
