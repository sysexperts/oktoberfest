#!/usr/bin/env python3
"""Sloptoberfest-Vermittler: Warteräume mit Einladungscode.

Einer erstellt ein Spiel und bekommt einen Code (z. B. BREZN-42), Freunde treten
mit dem Code bei. Im Warteraum wählt jeder Name, Figur und Abteilung. Mit „Los"
startet hier auf dem Server ein eigenes Spiel (dedizierter Godot-Server als
systemd-Einheit) auf einem freien UDP-Port, alle verbinden sich dorthin.
Ist niemand mehr im Spiel, beendet es sich selbst (game_manager.gd) — der
Warteraum mit seinem Code bleibt, das Spiel läuft mit „Los" am Spielstand weiter.

Nur Python-Standardbibliothek. Lauscht auf 127.0.0.1; nginx reicht
https://survival.vapur-it.de/lobby/ hierher durch.

Schnittstelle: POST <aktion> mit JSON, Antwort {"ok": true, "raum": {...}} oder
{"ok": false, "fehler": "<Übersetzungsschlüssel>"}.
  /erstellen {name, version}                → neuer Raum, du bist Host
  /beitreten {code, name, version}          → in den Raum
  /raum      {code, id}                     → Stand (zugleich Lebenszeichen)
  /setzen    {code, id, name, figur, abt}   → eigene Wahl
  /los       {code, id}                     → Host startet; läuft es schon: mitspielen
  /verlassen {code, id}
"""
import json
import os
import random
import re
import secrets
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HTTP_PORT = int(os.environ.get("VERMITTLER_PORT", "8700"))
SPIEL_PORTS = [int(p) for p in os.environ.get("VERMITTLER_SPIEL_PORTS", "8650,8651,8652").split(",")]
GODOT = os.environ.get("VERMITTLER_GODOT", "/opt/godot/Godot_v4.7.2-stable_linux.x86_64")
QUELLEN = os.environ.get("VERMITTLER_QUELLEN", "/opt/oktoberfest")
VERSION_DATEI = os.environ.get("VERMITTLER_VERSION_DATEI", "/var/www/survival/version.json")
DATEI = os.environ.get("VERMITTLER_DATEI", "/var/lib/sloptoberfest/raeume.json")
EINHEIT_PREFIX = os.environ.get("VERMITTLER_EINHEIT", "sloptoberfest-spiel-")

MAX_SPIELER = 4
MAX_RAEUME = 300
NAME_MAX = 16
FIGUREN = 3
ABTEILUNGEN = ("kueche", "service", "sauberkeit", "lager")
## Sekunden ohne Lebenszeichen, bis ein Spieler aus dem Warteraum fliegt
WARTE_TIMEOUT = 20
## Solange darf ein frisch gestartetes Spiel brauchen, bis sein Port offen ist
START_ZEIT = 90
## So lange darf ein Spieler nach „Los" fehlen (Verbinden, Laden), bevor das
## Spiel ihn als gegangen meldet und sein Platz frei wird
IM_SPIEL_GNADE = 45
## Räume ohne Aktivität so lange aufheben (Spielstand liegt beim Spiel)
RAUM_ALTER = 14 * 24 * 3600
WOERTER = ["BREZN", "MASS", "HENDL", "DIRNDL", "WIESN", "KRUG", "HAXN", "RADI",
           "OBAZDA", "PROST", "FASS", "ZELT", "HOPFEN", "SENF", "GAUDI"]

sperre = threading.RLock()
raeume = {}  # schluessel (nur Buchstaben/Ziffern) -> raum


def jetzt():
    return time.time()


def schluessel(code):
    return re.sub(r"[^A-Z0-9]", "", str(code).upper())


def name_pruefen(name):
    n = re.sub(r"[\x00-\x1f\x7f]", "", str(name)).strip()
    return n[:NAME_MAX].strip()


def live_version():
    try:
        with open(VERSION_DATEI, encoding="utf-8") as f:
            return str(json.load(f)["version"])
    except (OSError, ValueError, KeyError):
        return ""


def einheit(raum):
    return EINHEIT_PREFIX + schluessel(raum["code"]).lower()


def einheit_aktiv(raum):
    r = subprocess.run(["systemctl", "is-active", "--quiet", einheit(raum)])
    return r.returncode == 0


def port_offen(port):
    r = subprocess.run(["ss", "-Hluln", f"sport = :{port}"], capture_output=True, text=True)
    return str(port) in r.stdout


def speichern():
    os.makedirs(os.path.dirname(DATEI), exist_ok=True)
    tmp = DATEI + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(raeume, f, ensure_ascii=False)
    os.replace(tmp, DATEI)


def laden():
    global raeume
    try:
        with open(DATEI, encoding="utf-8") as f:
            raeume = json.load(f)
    except (OSError, ValueError):
        raeume = {}
    for raum in raeume.values():
        if raum["status"] != "warten" and not einheit_aktiv(raum):
            spiel_vorbei(raum)
        # Warteraum-Spieler von vor dem Neustart sind weg
        for sid in [s for s, d in raum["spieler"].items() if not d.get("im_spiel")]:
            del raum["spieler"][sid]


def neuer_code():
    for _ in range(200):
        code = "%s-%02d" % (random.choice(WOERTER), random.randint(10, 99))
        if schluessel(code) not in raeume:
            return code
    return "WIESN-%s" % secrets.token_hex(3).upper()


def spieler_neu(name):
    return {"name": name_pruefen(name), "figur": 0, "abt": "", "zuletzt": jetzt(), "im_spiel": False}


def ansicht(raum, fuer_id=""):
    spieler = []
    for sid, d in raum["spieler"].items():
        spieler.append({"id": sid, "name": d["name"], "figur": d["figur"], "abt": d["abt"],
                        "host": sid == raum["host"], "im_spiel": d.get("im_spiel", False),
                        "ich": sid == fuer_id})
    return {"code": raum["code"], "status": raum["status"], "port": raum.get("port", 0),
            "host": raum["host"], "spieler": spieler, "max": MAX_SPIELER,
            "fehler": raum.get("fehler", "")}


def aufraeumen():
    """Stumme Warteraum-Spieler entfernen, Host weitergeben, alte Räume löschen."""
    t = jetzt()
    for k in list(raeume.keys()):
        raum = raeume[k]
        for sid in [s for s, d in raum["spieler"].items()
                    if not d.get("im_spiel") and t - d["zuletzt"] > WARTE_TIMEOUT]:
            del raum["spieler"][sid]
        if raum["host"] not in raum["spieler"] and raum["spieler"]:
            raum["host"] = next(iter(raum["spieler"]))
        if raum["status"] == "warten" and not raum["spieler"] and t - raum["aktiv"] > RAUM_ALTER:
            del raeume[k]


def spiel_vorbei(raum):
    raum["status"] = "warten"
    raum["port"] = 0
    for sid in [s for s, d in raum["spieler"].items() if d.get("im_spiel")]:
        del raum["spieler"][sid]


def freier_port():
    belegt = {r.get("port", 0) for r in raeume.values() if r["status"] != "warten"}
    for p in SPIEL_PORTS:
        if p not in belegt and not port_offen(p):
            return p
    return 0


def spiel_starten(raum):
    port = freier_port()
    if port == 0:
        return "LOBBY_ERR_SERVER_FULL"
    subprocess.run(["systemctl", "reset-failed", einheit(raum)], capture_output=True)
    r = subprocess.run(["systemd-run", "--unit", einheit(raum), "--collect",
                        "--property=WorkingDirectory=" + QUELLEN,
                        GODOT, "--headless", "--path", QUELLEN, "--",
                        "--server", "--port", str(port), "--spiel", raum["code"]],
                       capture_output=True, text=True)
    if r.returncode != 0:
        print("Start fehlgeschlagen:", r.stderr.strip(), flush=True)
        return "LOBBY_ERR_START"
    raum["status"] = "startet"
    raum["port"] = port
    raum["gestartet"] = jetzt()
    raum["fehler"] = ""
    print("Spiel %s startet auf Port %d" % (raum["code"], port), flush=True)
    return ""


def waechter():
    """Startende Spiele auf ‚läuft' setzen, beendete zurück auf ‚warten'."""
    while True:
        time.sleep(2)
        with sperre:
            geaendert = False
            for raum in raeume.values():
                if raum["status"] == "startet":
                    if port_offen(raum["port"]):
                        raum["status"] = "laeuft"
                        geaendert = True
                    elif jetzt() - raum["gestartet"] > START_ZEIT or not einheit_aktiv(raum):
                        subprocess.run(["systemctl", "stop", einheit(raum)], capture_output=True)
                        spiel_vorbei(raum)
                        raum["fehler"] = "LOBBY_ERR_START"
                        geaendert = True
                elif raum["status"] == "laeuft" and not einheit_aktiv(raum):
                    print("Spiel %s beendet" % raum["code"], flush=True)
                    spiel_vorbei(raum)
                    geaendert = True
            aufraeumen()
            if geaendert:
                speichern()


# ------------------------------------------------------------------ Aktionen
def raum_und_spieler(daten):
    raum = raeume.get(schluessel(daten.get("code", "")))
    if raum is None:
        return None, None, "LOBBY_ERR_CODE"
    sid = str(daten.get("id", ""))
    if sid not in raum["spieler"]:
        return raum, None, "LOBBY_ERR_GONE"
    return raum, raum["spieler"][sid], ""


def a_erstellen(d):
    if str(d.get("version", "")) != live_version():
        return {"ok": False, "fehler": "LOBBY_ERR_VERSION"}
    if len(raeume) >= MAX_RAEUME:
        return {"ok": False, "fehler": "LOBBY_ERR_SERVER_FULL"}
    code = neuer_code()
    sid = secrets.token_hex(6)
    raum = {"code": code, "status": "warten", "port": 0, "host": sid,
            "spieler": {sid: spieler_neu(d.get("name", ""))}, "aktiv": jetzt()}
    raeume[schluessel(code)] = raum
    speichern()
    return {"ok": True, "id": sid, "raum": ansicht(raum, sid)}


def a_beitreten(d):
    if str(d.get("version", "")) != live_version():
        return {"ok": False, "fehler": "LOBBY_ERR_VERSION"}
    raum = raeume.get(schluessel(d.get("code", "")))
    if raum is None:
        return {"ok": False, "fehler": "LOBBY_ERR_CODE"}
    if len(raum["spieler"]) >= MAX_SPIELER:
        return {"ok": False, "fehler": "LOBBY_ERR_ROOM_FULL"}
    sid = secrets.token_hex(6)
    sp = spieler_neu(d.get("name", ""))
    # Freie Figur vorschlagen, damit nicht alle gleich aussehen
    genommen = {x["figur"] for x in raum["spieler"].values()}
    sp["figur"] = next((f for f in range(FIGUREN) if f not in genommen), 0)
    raum["spieler"][sid] = sp
    if raum["host"] not in raum["spieler"]:
        raum["host"] = sid
    raum["aktiv"] = jetzt()
    speichern()
    return {"ok": True, "id": sid, "raum": ansicht(raum, sid)}


def a_raum(d):
    raum, sp, fehler = raum_und_spieler(d)
    if fehler:
        return {"ok": False, "fehler": fehler}
    sp["zuletzt"] = jetzt()
    return {"ok": True, "raum": ansicht(raum, d.get("id", ""))}


def a_setzen(d):
    raum, sp, fehler = raum_und_spieler(d)
    if fehler:
        return {"ok": False, "fehler": fehler}
    sp["zuletzt"] = jetzt()
    if "name" in d:
        sp["name"] = name_pruefen(d["name"])
    if "figur" in d:
        sp["figur"] = max(0, min(FIGUREN - 1, int(d["figur"])))
    if "abt" in d:
        abt = str(d["abt"])
        if abt not in ABTEILUNGEN:
            abt = ""
        # Jede Abteilung hat höchstens einen Teamleiter
        if abt and any(x["abt"] == abt for s, x in raum["spieler"].items() if x is not sp):
            return {"ok": False, "fehler": "LOBBY_ERR_DEPT_TAKEN", "raum": ansicht(raum, d.get("id", ""))}
        sp["abt"] = abt
    raum["aktiv"] = jetzt()
    speichern()
    return {"ok": True, "raum": ansicht(raum, d.get("id", ""))}


def a_los(d):
    raum, sp, fehler = raum_und_spieler(d)
    if fehler:
        return {"ok": False, "fehler": fehler}
    sp["zuletzt"] = jetzt()
    sid = str(d.get("id", ""))
    if raum["status"] == "warten":
        if sid != raum["host"]:
            return {"ok": False, "fehler": "LOBBY_ERR_NOT_HOST"}
        fehler = spiel_starten(raum)
        if fehler:
            return {"ok": False, "fehler": fehler}
        for x in raum["spieler"].values():
            x["im_spiel"] = True
            x["im_spiel_seit"] = jetzt()
    else:
        sp["im_spiel"] = True
        sp["im_spiel_seit"] = jetzt()
    raum["aktiv"] = jetzt()
    speichern()
    return {"ok": True, "raum": ansicht(raum, sid)}


def a_verlassen(d):
    raum, sp, fehler = raum_und_spieler(d)
    if raum and sp:
        del raum["spieler"][str(d.get("id", ""))]
        aufraeumen()
        speichern()
    return {"ok": True}


def a_spielstand(d):
    """Das laufende Spiel meldet, wer drin ist (Warteraum-IDs). Wer das Spiel
    verlassen hat, gibt Platz und Abteilung frei — sonst kämen Freunde nach
    einem Absturz nicht mehr rein („voll", „Abteilung belegt")."""
    raum = raeume.get(schluessel(d.get("code", "")))
    if raum is None:
        return {"ok": False, "fehler": "LOBBY_ERR_CODE"}
    ids = {str(i) for i in d.get("ids", [])}
    t = jetzt()
    for sid in list(raum["spieler"].keys()):
        sp = raum["spieler"][sid]
        if not sp.get("im_spiel"):
            continue
        if sid in ids:
            sp["gesehen"] = t
        elif t - max(sp.get("im_spiel_seit", 0), sp.get("gesehen", 0)) > IM_SPIEL_GNADE:
            del raum["spieler"][sid]
    if raum["host"] not in raum["spieler"] and raum["spieler"]:
        raum["host"] = next(iter(raum["spieler"]))
    speichern()
    return {"ok": True}


AKTIONEN = {"/erstellen": a_erstellen, "/beitreten": a_beitreten, "/raum": a_raum,
            "/setzen": a_setzen, "/los": a_los, "/verlassen": a_verlassen,
            "/spielstand": a_spielstand}
## Nur das Spiel auf diesem Server darf melden, nicht Anfragen über nginx
NUR_INTERN = {"/spielstand"}


class Handler(BaseHTTPRequestHandler):
    def _antwort(self, code, daten):
        body = json.dumps(daten, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path.rstrip("/") in ("", "/gesund"):
            with sperre:
                laufend = sum(1 for r in raeume.values() if r["status"] != "warten")
            self._antwort(200, {"ok": True, "raeume": len(raeume), "spiele": laufend,
                                "plaetze": len(SPIEL_PORTS)})
        else:
            self._antwort(404, {"ok": False})

    def do_POST(self):
        pfad = self.path.rstrip("/")
        aktion = AKTIONEN.get(pfad)
        if pfad in NUR_INTERN and self.headers.get("X-Extern"):
            aktion = None
        if aktion is None:
            self._antwort(404, {"ok": False, "fehler": "LOBBY_ERR_SERVER"})
            return
        try:
            laenge = min(int(self.headers.get("Content-Length", "0")), 4096)
            daten = json.loads(self.rfile.read(laenge) or b"{}")
            if not isinstance(daten, dict):
                raise ValueError
        except ValueError:
            self._antwort(400, {"ok": False, "fehler": "LOBBY_ERR_SERVER"})
            return
        with sperre:
            self._antwort(200, aktion(daten))

    def log_message(self, fmt, *args):
        pass


def main():
    with sperre:
        laden()
        speichern()
    threading.Thread(target=waechter, daemon=True).start()
    print("Vermittler auf 127.0.0.1:%d, Spielports %s" % (HTTP_PORT, SPIEL_PORTS), flush=True)
    ThreadingHTTPServer(("127.0.0.1", HTTP_PORT), Handler).serve_forever()


if __name__ == "__main__":
    main()
