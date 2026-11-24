#!/usr/bin/env python3
"""Aufgabenverwaltung über Git. Befehle:
  status | list | ready [AREA,..] | next [AREA,..] | mine | claim ID (atomar, markiert Issue) | start ID | done ID | release ID
  add < karten.json     neue Karten (JSON-Liste) anlegen, INDEX.md erzeugen
  issues                je Karte ein GitHub-Issue (Label roadmap) anlegen, falls gh vorhanden
  board                 wer baut gerade was (Claims, letzter Commit, Alter, offene PRs, verwaist?)
  batch [PUNKTE]        empfiehlt mehrere startbare Karten ohne Dateiüberschneidung (S=1, M=2 Punkte, Standard 3)
  ideas | idea "Text"   Ideen-Datei: offene Ideen (Status neu) listen / neue Idee eintragen
  index                 INDEX.md aus tasks.json neu erzeugen
  next/ready A|B|C      Besitzer-Filter: eigene Karten zuerst, dann unbeanspruchte der anderen (B/C nur nice)
Bestehende Projekte: tools/autopilot.json {"ideas_file": "docs/IDEEN.md", "base": "main"} überschreibt die Standards.
TASK_WHO=<Name> setzen. Beanspruchen = Branch task/<ID>/<WER> auf origin (Remote ist die Wahrheit).
Startbar = Status open, alle Abhängigkeiten done, von niemand anderem beansprucht."""
import json, os, re, subprocess, sys, time, pathlib
ROOT = pathlib.Path(__file__).resolve().parent.parent
F = ROOT / "TASKS" / "tasks.json"
WHO = os.environ.get("TASK_WHO", "")
CFG_FILE = ROOT / "tools" / "autopilot.json"
CFG = json.loads(CFG_FILE.read_text(encoding="utf-8")) if CFG_FILE.exists() else {}
CARD = """# {id} · {title}
- Bereich: {area}
- Besitzer: {owner}  ·  Priorität: {prio}  (must = für Ziel zwingend, nice = Zusatz)
- Größe: {size}
- Status: {status}   (open | in_progress | done)
- Abhängig von: {deps}

## Ziel
{goal}

## Dateien (nur diese anfassen)
{files}

## Fertig, wenn
{accept}

## Ablauf
1. `python3 tools/tasks.py claim {id}`, dann Branch `task/{id}/<WER>` auschecken.
2. Nur die Dateien oben ändern (Schnittstellen: docs/ARCHITECTURE.md).
3. Tests grün (`tools/run_tests.sh`), Beleg zu "Fertig, wenn" sammeln.
4. `python3 tools/tasks.py done {id}`, eine Zeile in PLAN.md, Pull Request öffnen.
"""

def load(): return json.loads(F.read_text(encoding="utf-8")) if F.exists() else []
def git(*a): return subprocess.run(["git", "-C", str(ROOT), *a], capture_output=True, text=True)

def base():
    if CFG.get("base"): return CFG["base"]
    r = git("symbolic-ref", "--short", "refs/remotes/origin/HEAD")
    return r.stdout.strip().split("/", 1)[-1] if r.returncode == 0 and r.stdout.strip() else "main"

def write_card(x):
    x.setdefault("owner", "A"); x.setdefault("prio", "must"); x.setdefault("size", "S"); x.setdefault("status", "open")
    x.setdefault("deps", []); x.setdefault("goal", ""); x.setdefault("accept", "")
    files = "\n".join(f"- {f}" for f in x.get("files", [])) or "- (siehe Ziel)"
    (ROOT / "TASKS").mkdir(exist_ok=True)
    (ROOT / "TASKS" / f"{x['id']}.md").write_text(
        CARD.format(**{**x, "deps": ", ".join(x["deps"]) or "–", "files": files}), encoding="utf-8")

def save(t):
    F.parent.mkdir(exist_ok=True)
    F.write_text(json.dumps(t, ensure_ascii=False, indent=1), encoding="utf-8")
    rows = ["# Aufgabenübersicht (generiert von tools/tasks.py)\n",
            "| ID | Besitzer | Prio | Bereich | Titel | Größe | Status | Abhängig von | Issue |", "|---|---|---|---|---|---|---|---|---|"]
    for x in t:
        rows.append(f"| [{x['id']}]({x['id']}.md) | {x.get('owner','-')} | {x.get('prio','-')} | {x['area']} | {x['title']} | "
                    f"{x['size']} | {x['status']} | {', '.join(x['deps']) or '–'} | {('#'+str(x['issue'])) if x.get('issue') else '–'} |")
    (ROOT / "TASKS" / "INDEX.md").write_text("\n".join(rows) + "\n", encoding="utf-8")

def claims():
    r = git("ls-remote", "--heads", "origin", "task/*")
    if r.returncode != 0:
        sys.exit("OFFLINE: Remote nicht erreichbar, nichts auf Verdacht tun. " + r.stderr.strip()[:200])
    out = {}
    for m in re.finditer(r"refs/heads/task/([\w.-]+)/(\S+)", r.stdout):
        out.setdefault(m.group(1), []).append(m.group(2))
    return out

def ready(t, areas=None):
    """areas: Bereichsnamen (GAME,UI) oder ein Besitzer-Buchstabe A|B|C (eigene zuerst, dann als Rückfall
    die unbeanspruchten der anderen; B/C übernehmen von anderen nur nice, must bleibt bei A)."""
    done = {x["id"] for x in t if x["status"] == "done"}
    c = claims()
    free = [x for x in t if x["status"] == "open" and all(d in done for d in x["deps"])
            and not [w for w in c.get(x["id"], []) if w != WHO]]
    free.sort(key=lambda x: {"must": 0, "nice": 1}.get(x.get("prio"), 2))
    if not areas: return free
    if len(areas) == 1 and re.fullmatch(r"[A-Z]", areas[0]) and areas[0] not in {x["area"] for x in t}:
        own = [x for x in free if x.get("owner") == areas[0]]
        others = [x for x in free if x.get("owner") != areas[0] and (areas[0] == "A" or x.get("prio") == "nice")]
        return own + others
    return [x for x in free if x["area"] in areas]

IDEAS = ROOT / CFG.get("ideas_file", "BRAINSTORM/INDEX.md")
HEAD = "# Brainstorm (jeder Coder sichtet das regelmäßig)\n\nStatus: neu | umsetzen | später | abgelehnt. Wer eine Idee entscheidet, trägt Status + Grund ein; `umsetzen` = neue Karte per `tasks.py add`.\n\n| ID | Datum | Von | Idee | Status | Grund |\n|---|---|---|---|---|---|\n"

def open_ideas():
    if not IDEAS.exists(): return []
    out = []
    for line in IDEAS.read_text(encoding="utf-8").splitlines():
        c = [x.strip() for x in line.strip().strip("|").split("|")]
        if len(c) >= 5 and re.fullmatch(r"IB-\d+", c[0]) and c[4] == "neu": out.append((c[0], c[2], c[3]))
    return out

def add_idea(text):
    import datetime
    IDEAS.parent.mkdir(exist_ok=True)
    old = IDEAS.read_text(encoding="utf-8") if IDEAS.exists() else HEAD
    nums = [int(x) for x in re.findall(r"^\| IB-(\d+)", old, re.M)]
    n = max(nums, default=0) + 1
    row = f"| IB-{n:02d} | {datetime.date.today()} | {WHO or '-'} | {text.replace('|', '/')} | neu |  |"
    lines = old.rstrip("\n").splitlines()
    # Hinter der letzten Ideen-Zeile einfügen (bestehende Dateien haben oft Text unter der Tabelle)
    last = max((i for i, l in enumerate(lines) if re.match(r"\| IB-\d+", l)), default=None)
    if last is None:
        last = max((i for i, l in enumerate(lines) if re.match(r"\|[-| ]+\|$", l)), default=len(lines) - 1)
    lines.insert(last + 1, row)
    IDEAS.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return f"IB-{n:02d}"

def board(t):
    git("fetch", "--quiet", "origin")
    b = base(); titles = {x["id"]: x["title"] for x in t}
    done = {x["id"] for x in t if x["status"] == "done"}   # alte Claim-Branches fertiger Karten ausblenden
    print(f"{'ID':8} {'WER':12} {'Commits':7} {'Letzter Commit':16} Titel / Hinweis")
    for ref in git("for-each-ref", "--format=%(refname:short)", "refs/remotes/origin/task/").stdout.split():
        m = re.match(r"origin/task/([\w.-]+)/(.+)", ref)
        if not m: continue
        id_, who = m.groups()
        if id_ in done: continue
        n = git("rev-list", "--count", f"origin/{b}..{ref}").stdout.strip()
        age = git("log", "-1", "--format=%cr", ref).stdout.strip()
        hrs = int(git("log", "-1", "--format=%ct", ref).stdout.strip() or 0)
        import time; old = n == "0" and time.time() - hrs > 48 * 3600
        print(f"{id_:8} {who:12} {n:7} {age:16} {titles.get(id_, '?')}{'  [VERWAIST? >48h ohne Commit]' if old else ''}")
    if subprocess.run(["gh", "--version"], capture_output=True).returncode == 0:
        r = subprocess.run(["gh", "pr", "list", "--json", "number,title,headRefName", "--jq", '.[]|"PR #\\(.number) \\(.headRefName) \\(.title)"'], capture_output=True, text=True, cwd=ROOT)
        if r.stdout.strip(): print(r.stdout.strip())

def mark_issue(t, id_, on):
    """Markiert die Karte sichtbar im GitHub-Issue (Label in-progress + Kommentar). Best effort, ohne gh still."""
    n = next((x.get("issue") for x in t if x["id"] == id_), None)
    if not n or subprocess.run(["gh", "--version"], capture_output=True).returncode != 0: return
    subprocess.run(["gh", "label", "create", "in-progress", "--color", "fbca04", "--force"], capture_output=True, cwd=ROOT)
    subprocess.run(["gh", "issue", "edit", str(n), "--add-label" if on else "--remove-label", "in-progress"], capture_output=True, cwd=ROOT)
    subprocess.run(["gh", "issue", "comment", str(n), "--body", f"{'Beansprucht von' if on else 'Freigegeben von'} {WHO}"], capture_output=True, cwd=ROOT)

def batch(t, points):
    picked, files, used = [], set(), 0
    for x in ready(t):
        w = 2 if x["size"] == "M" else 1
        f = set(x.get("files", []))
        if used + w > points or f & files: continue
        picked.append(x); files |= f; used += w
    return picked

def set_status(t, id_, status):
    for x in t:
        if x["id"] == id_:
            x["status"] = status
            card = ROOT / "TASKS" / f"{id_}.md"
            if card.exists():
                card.write_text(re.sub(r"- Status: \S+", f"- Status: {status}", card.read_text(encoding="utf-8"), count=1), encoding="utf-8")
            return
    sys.exit(f"Unbekannte ID {id_}")

def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    t = load()
    areas = sys.argv[2].split(",") if len(sys.argv) > 2 and cmd in ("ready", "next") else None
    if cmd == "list":
        c = claims()
        for x in t: print(f"{x['id']:8} {x['status']:12} {x['area']:8} {x['title']}" + (f"   [IN ARBEIT: {', '.join(c[x['id']])}]" if x['id'] in c and x['status'] != 'done' else ""))
    elif cmd == "next":
        r = ready(t, areas); print(r[0]["id"] if r else "NONE")
    elif cmd == "ready":
        for x in ready(t, areas): print(x["id"], x["title"])
    elif cmd == "mine":
        c = claims()
        for x in t:
            if x["status"] != "done" and WHO and WHO in c.get(x["id"], []): print(x["id"], x["title"])
    elif cmd == "claim":
        id_ = sys.argv[2]
        if not WHO: sys.exit("TASK_WHO setzen")
        c = claims().get(id_, [])
        if WHO in c: print(f"CLAIMED task/{id_}/{WHO} (schon deins)"); return
        if c: sys.exit(f"BELEGT: {id_} von {', '.join(c)}")
        git("fetch", "--quiet", "origin", base())
        tree = git("rev-parse", f"origin/{base()}^{{tree}}").stdout.strip(); parent = git("rev-parse", f"origin/{base()}").stdout.strip()
        # Atomares Schloss: einzigartiger Commit, zweiter Versuch wird als Nicht-Fast-Forward abgelehnt
        env = {**os.environ, "GIT_AUTHOR_NAME": WHO, "GIT_AUTHOR_EMAIL": "claim@local", "GIT_COMMITTER_NAME": WHO, "GIT_COMMITTER_EMAIL": "claim@local"}
        lock = subprocess.run(["git", "-C", str(ROOT), "commit-tree", tree, "-p", parent, "-m", f"claim {id_} by {WHO} {time.time_ns()}"], capture_output=True, text=True, env=env).stdout.strip()
        if git("push", "origin", f"{lock}:refs/heads/lock/{id_}").returncode != 0: sys.exit(f"BELEGT: {id_} (gerade von jemand anderem beansprucht; hängt ein Schloss verwaist, hilft `tasks.py release <ID>`)")
        r = git("push", "origin", f"origin/{base()}:refs/heads/task/{id_}/{WHO}")
        if r.returncode != 0: git("push", "origin", "--delete", f"lock/{id_}"); sys.exit("FEHLER " + r.stderr[:200])
        mark_issue(t, id_, True)
        print(f"CLAIMED task/{id_}/{WHO}")
    elif cmd == "release":
        who = sys.argv[3] if len(sys.argv) > 3 else WHO
        r = git("push", "origin", "--delete", f"task/{sys.argv[2]}/{who}"); git("push", "origin", "--delete", f"lock/{sys.argv[2]}")
        mark_issue(t, sys.argv[2], False)
        print("RELEASED" if r.returncode == 0 else "FEHLER " + r.stderr[:200])
    elif cmd in ("start", "done"):
        set_status(t, sys.argv[2], "in_progress" if cmd == "start" else "done"); save(t)
    elif cmd == "add":
        new = json.load(sys.stdin); ids = {x["id"] for x in t}
        known = ids | {x["id"] for x in new}
        for x in new:
            if x["id"] in ids: sys.exit(f"ID doppelt: {x['id']}")
            for d in x.get("deps", []):
                if d not in known: sys.exit(f"{x['id']}: Abhängigkeit {d} unbekannt")
        for x in new:
            write_card(x); t.append(x)
        save(t); print(f"{len(new)} Karte(n) angelegt")
    elif cmd == "issues":
        if subprocess.run(["gh", "--version"], capture_output=True).returncode != 0: sys.exit("gh fehlt, Issues übersprungen")
        subprocess.run(["gh", "label", "create", "roadmap", "--color", "1d76db", "--force"], capture_output=True, cwd=ROOT)
        for x in t:
            if x.get("issue") or x["status"] == "done": continue
            r = subprocess.run(["gh", "issue", "create", "--title", f"[{x['id']}] {x['title']}", "--label", "roadmap",
                                "--body-file", str(ROOT / "TASKS" / f"{x['id']}.md")], capture_output=True, text=True, cwd=ROOT)
            m = re.search(r"/issues/(\d+)", r.stdout)
            if m: x["issue"] = int(m.group(1)); print(x["id"], "->", "#" + m.group(1))
            else: print(x["id"], "FEHLER", r.stderr[:120])
        save(t)
    elif cmd == "board": board(t)
    elif cmd == "batch":
        for x in batch(t, int(sys.argv[2]) if len(sys.argv) > 2 else 3): print(x["id"], x["size"], x["title"])
    elif cmd == "ideas":
        for i, who, txt in open_ideas(): print(f"{i} ({who}): {txt[:110]}")
        print(f"{len(open_ideas())} Idee(n) warten auf Entscheidung ({IDEAS.relative_to(ROOT)})")
    elif cmd == "idea": print(add_idea(sys.argv[2]))
    elif cmd == "index": save(t)
    elif cmd == "status":
        from collections import Counter
        git("fetch", "--quiet", "origin", base())
        behind = int(git("rev-list", "--count", f"HEAD..origin/{base()}").stdout.strip() or 0)
        print("Hinter origin:", behind, "Commit(s)" + (" -> erst `git pull --ff-only`" if behind else " (aktuell)"))
        print("Stand:", dict(Counter(x["status"] for x in t)))
        print("Beansprucht:", claims() or "nichts")
        print("Startbar:", [x["id"] for x in ready(t)])
        n = len(open_ideas())
        print(f"IDEEN: {n} offen -> `tasks.py ideas`, jede entscheiden (Pflicht)" if n else "Ideen: keine offenen")
    else:
        sys.exit(__doc__)
main()
