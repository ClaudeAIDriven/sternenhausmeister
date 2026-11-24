#!/usr/bin/env python3
"""Aufgabenverwaltung: list | next [A|B|C|BEREICHE] | ready [A|B|C|BEREICHE] | start ID | done ID | claim ID [WER] | mine | status | index\nTASK_WHO=<Name> setzen (z. B. jan, bot-A). Beanspruchen = Branch task/<ID>/<WER> auf origin.
BEREICHE = kommagetrennt, z. B. GAME,UI
Nächste Aufgabe = erste mit Status open, deren Abhängigkeiten alle done sind."""
import json, os, re, subprocess, sys, pathlib
ROOT = pathlib.Path(__file__).resolve().parent.parent
F = ROOT / "TASKS" / "tasks.json"

def load(): return json.loads(F.read_text(encoding="utf-8"))
def save(t):
    F.write_text(json.dumps(t, ensure_ascii=False, indent=1), encoding="utf-8")
    lines = ["# Aufgabenübersicht (generiert von tools/tasks.py)\n", "| ID | Besitzer | Prio | Bereich | Titel | Größe | Status | Abhängig von |", "|---|---|---|---|---|---|---|---|"]
    for x in t:
        lines.append(f"| [{x['id']}]({x['id']}.md) | {x.get('owner','-')} | {x.get('prio','-')} | {x['area']} | {x['title']} | {x['size']} | {x['status']} | {', '.join(x['deps']) or '–'} |")
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

WHO = os.environ.get("TASK_WHO", "")

def git(*a):
    return subprocess.run(["git", "-C", str(ROOT), *a], capture_output=True, text=True)

def claims():
    """Remote-Branches task/<ID>/<wer> = Aufgabe ist von jemandem beansprucht. Offline = Abbruch."""
    r = git("ls-remote", "--heads", "origin", "task/*")
    if r.returncode != 0:
        sys.exit("OFFLINE: Remote nicht erreichbar, nichts auf Verdacht tun. " + r.stderr.strip()[:200])
    out = {}
    for m in re.finditer(r"refs/heads/task/([A-Z]-\d+)/(\S+)", r.stdout):
        out.setdefault(m.group(1), []).append(m.group(2))
    return out

def ready(t, filt=None):
    """Startbar = open, Abhängigkeiten done, von niemand ANDEREM beansprucht.
    filt: ['A'|'B'|'C'] = Besitzer (eigene Aufgaben zuerst, danach als Rückfall die unbeanspruchten der anderen,
    damit die Demo auch entsteht, wenn jemand ausfällt) oder Bereichsnamen wie GAME,UI."""
    done = {x["id"] for x in t if x["status"] == "done"}
    c = claims()
    free = [x for x in t if x["status"] == "open" and all(d in done for d in x["deps"])
            and not [w for w in c.get(x["id"], []) if w != WHO]]
    prio = {"must": 0, "nice": 1}
    free.sort(key=lambda x: prio.get(x.get("prio"), 2))
    if not filt: return free
    if len(filt) == 1 and filt[0] in ("A", "B", "C"):
        own = [x for x in free if x.get("owner") == filt[0]]
        others = [x for x in free if x.get("owner") != filt[0]]
        if filt[0] != "A":   # B/C nehmen nur Zusätzliches (nice) von anderen, Demo-Pflicht (must) bleibt bei A
            others = [x for x in others if x.get("prio") == "nice"]
        return own + others
    return [x for x in free if x["area"] in filt]

def mine(t):
    """Meine bereits beanspruchten, noch nicht fertigen Aufgaben (nach Reset zuerst weitermachen)."""
    c = claims()
    return [x for x in t if x["status"] != "done" and WHO and WHO in c.get(x["id"], [])]

def sync_check():
    git("fetch", "--quiet", "origin", "main")
    behind = git("rev-list", "--count", "HEAD..origin/main").stdout.strip()
    return int(behind or 0)

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
    elif cmd == "mine":
        for x in mine(t): print(x["id"], x["title"])
    elif cmd == "claim":
        id_, who = sys.argv[2], (sys.argv[3] if len(sys.argv) > 3 else WHO)
        if not who: sys.exit("TASK_WHO oder Namen angeben")
        if [w for w in claims().get(id_, []) if w != who]: sys.exit(f"BELEGT: {id_} ist schon beansprucht")
        b = f"task/{id_}/{who}"
        r = git("push", "origin", f"origin/main:refs/heads/{b}")
        print("CLAIMED " + b if r.returncode == 0 else "FEHLER " + r.stderr[:200])
    elif cmd == "status":
        behind = sync_check()
        print("Lokal hinter origin/main um", behind, "Commit(s)" + ("  -> erst `git pull --ff-only origin main`!" if behind else " (aktuell)"))
        from collections import Counter
        print("Stand:", dict(Counter(x["status"] for x in t)))
        print("Beansprucht:", claims() or "nichts")
        print("Startbar:", [x["id"] for x in ready(t)])
    elif cmd == "index":
        save(t)
    else:
        sys.exit(__doc__)
main()
