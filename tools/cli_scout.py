#!/usr/bin/env python3
"""CLI-Anything-Hub im Projekt: Kandidaten suchen, Entscheidungen im Repo festhalten, alle auf gleichen Stand bringen.
  ensure                       cli-hub installieren (pip install cli-anything-hub), falls es fehlt
  scout WORT [WORT ..]         Hub nach englischen Stichworten durchsuchen, nur noch nicht erfasste CLIs zeigen
  register NAME STATUS "Zweck" [KARTE]   in docs/CLI_TOOLS.md eintragen (STATUS: kandidat | aktiv | abgelehnt)
  install                      alle CLIs mit Status aktiv installieren (gleicher Stand für alle Coder)
  list                         Register anzeigen
Register = docs/CLI_TOOLS.md (wird per Pull Request geändert, damit alle denselben Stand haben)."""
import datetime, os, re, shutil, subprocess, sys, pathlib
ROOT = pathlib.Path(__file__).resolve().parent.parent
REG = ROOT / "docs" / "CLI_TOOLS.md"
HEAD = ("# CLI-Werkzeuge (CLI-Anything-Hub, https://github.com/HKUDS/CLI-Anything)\n\n"
        "Status: kandidat | aktiv | abgelehnt. `aktiv` = alle Coder nutzen es (`python3 tools/cli_scout.py install`). "
        "Jede Aufnahme wurde per 3-Stimmen-Entscheidung (Hauptmodell + 2 Agenten) getroffen, Ergebnis steht in PLAN.md.\n\n"
        "| CLI | Zweck | Status | Karte | Datum | Von |\n|---|---|---|---|---|---|\n")
WHO = os.environ.get("TASK_WHO", "-")

def hub(*a):
    return subprocess.run(["cli-hub", *a], capture_output=True, text=True)

def rows():
    if not REG.exists(): return []
    out = []
    for line in REG.read_text(encoding="utf-8").splitlines():
        c = [x.strip() for x in line.strip().strip("|").split("|")]
        if len(c) >= 3 and c[2] in ("kandidat", "aktiv", "abgelehnt") and c[0] != "CLI": out.append(c)
    return out

def parse(text):
    """Zeilen wie '    gimp [image] — Raster image ...' -> (name, kategorie, beschreibung)"""
    return [(m.group(1), m.group(2), m.group(3).strip())
            for m in (re.match(r"^\s{2,}(\S+)\s+\[([^\]]+)\][^—]*—\s*(.*)$", l) for l in text.splitlines()) if m]

def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "list"
    if cmd == "ensure":
        if shutil.which("cli-hub"): print("cli-hub vorhanden"); return
        r = subprocess.run([sys.executable, "-m", "pip", "install", "--break-system-packages", "-q", "cli-anything-hub"], capture_output=True, text=True)
        print("cli-hub installiert" if shutil.which("cli-hub") else "FEHLER " + r.stderr[-200:])
    elif cmd == "scout":
        if not shutil.which("cli-hub"): sys.exit("cli-hub fehlt: python3 tools/cli_scout.py ensure")
        known = {r[0] for r in rows()}; seen = {}
        for kw in sys.argv[2:]:
            r = hub("search", kw)
            if r.returncode != 0:
                sys.exit(f"FEHLER: cli-hub search {kw} fehlgeschlagen (Netz/Proxy?): " + (r.stderr.strip().splitlines() or ["?"])[-1][:200])
            for n, cat, d in parse(r.stdout):
                if n not in known: seen.setdefault(n, (cat, d, kw))
        for n, (cat, d, kw) in seen.items(): print(f"{n} [{cat}] ({kw}): {d[:100]}")
        print(f"{len(seen)} neue Kandidat(en). Nützlich? Mit 3 Stimmen entscheiden, dann `register`." if seen else "Nichts Neues zu den Stichworten.")
    elif cmd == "register":
        name, status, zweck = sys.argv[2], sys.argv[3], sys.argv[4]; card = sys.argv[5] if len(sys.argv) > 5 else "-"
        if status not in ("kandidat", "aktiv", "abgelehnt"): sys.exit("STATUS: kandidat | aktiv | abgelehnt")
        REG.parent.mkdir(exist_ok=True)
        old = REG.read_text(encoding="utf-8") if REG.exists() else HEAD
        line = f"| {name} | {zweck.replace('|', '/')} | {status} | {card} | {datetime.date.today()} | {WHO} |"
        lines = old.rstrip("\n").splitlines()
        i = next((k for k, l in enumerate(lines) if l.startswith(f"| {name} |")), None)
        if i is None: lines.append(line)
        else: lines[i] = line
        REG.write_text("\n".join(lines) + "\n", encoding="utf-8"); print("eingetragen:", name, status)
    elif cmd == "install":
        if not shutil.which("cli-hub"): sys.exit("cli-hub fehlt: python3 tools/cli_scout.py ensure")
        for r in rows():
            if r[2] == "aktiv":
                p = hub("install", r[0]); print(r[0], "OK" if p.returncode == 0 else "FEHLER " + (p.stderr or p.stdout)[-120:])
    elif cmd == "list":
        for r in rows(): print(" | ".join(r[:4]))
        if not rows(): print("Register leer (docs/CLI_TOOLS.md)")
    else:
        sys.exit(__doc__)
main()
