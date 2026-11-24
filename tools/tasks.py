#!/usr/bin/env python3
"""Aufgabenverwaltung: list | next [BEREICHE] | ready [BEREICHE] | start ID | done ID | index
BEREICHE = kommagetrennt, z. B. GAME,UI
Nächste Aufgabe = erste mit Status open, deren Abhängigkeiten alle done sind."""
import json, re, sys, pathlib
ROOT = pathlib.Path(__file__).resolve().parent.parent
F = ROOT / "TASKS" / "tasks.json"

def load(): return json.loads(F.read_text(encoding="utf-8"))
def save(t):
    F.write_text(json.dumps(t, ensure_ascii=False, indent=1), encoding="utf-8")
    lines = ["# Aufgabenübersicht (generiert von tools/tasks.py)\n", "| ID | Bereich | Titel | Größe | Status | Abhängig von |", "|---|---|---|---|---|---|"]
    for x in t:
        lines.append(f"| [{x['id']}]({x['id']}.md) | {x['area']} | {x['title']} | {x['size']} | {x['status']} | {', '.join(x['deps']) or '–'} |")
    (ROOT / "TASKS" / "INDEX.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

def set_status(t, id, status):
    for x in t:
        if x["id"] == id:
            x["status"] = status
            card = ROOT / "TASKS" / f"{id}.md"
            s = card.read_text(encoding="utf-8")
            card.write_text(re.sub(r"- Status: \S+", f"- Status: {status}", s, count=1), encoding="utf-8")
            return
    sys.exit(f"Unbekannte ID {id}")

def ready(t, areas=None):
    done = {x["id"] for x in t if x["status"] == "done"}
    return [x for x in t if x["status"] == "open" and all(d in done for d in x["deps"])
            and (not areas or x["area"] in areas)]

def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "list"
    t = load()
    if cmd == "list":
        for x in t: print(f"{x['id']:6} {x['status']:12} {x['area']:6} {x['title']}")
    elif cmd in ("next", "ready"):
        areas = sys.argv[2].split(",") if len(sys.argv) > 2 else None   # z. B. GAME,UI
        r = ready(t, areas)
        if cmd == "next": print(r[0]["id"] if r else "NONE")
        else:
            for x in r: print(x["id"], x["title"])
    elif cmd in ("start", "done"):
        set_status(t, sys.argv[2], "in_progress" if cmd == "start" else "done"); save(t)
    elif cmd == "index":
        save(t)
    else:
        sys.exit(__doc__)
main()
