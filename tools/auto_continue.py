#!/usr/bin/env python3
"""Auto-Weiter für Claude Code im Terminal: startet `claude -p` mit dem Fortsetzungs-Prompt, erkennt Limit-Meldungen,
wartet bis zum Reset und macht automatisch weiter, bis tasks.py 'NONE' meldet und keine Branches mehr offen sind.
Aufruf: python3 tools/auto_continue.py            (Umgebung: TASK_WHO, optional CLAUDE_BIN, CLAUDE_FLAGS, CONTINUE_PROMPT)
Limit-Text ist je nach Version verschieden: Uhrzeit wird per Muster gesucht, sonst Rückfall auf 5 h + 5 min. (🟡 ungeprüft gegen echte Meldungen)"""
import datetime as dt, os, re, subprocess, sys, time, pathlib
ROOT = pathlib.Path(__file__).resolve().parent.parent
BIN = os.environ.get("CLAUDE_BIN", "claude")
PROMPT = os.environ.get("CONTINUE_PROMPT", "continue. Lies AGENT_PROMPT.md und arbeite den Ablauf ab.")
LIMIT = re.compile(r"limit|usage|rate.?limit|try again|resets?", re.I)
FALLBACK = 5 * 3600 + 300

def wait_seconds(text, now=None):
    now = now or dt.datetime.now()
    m = re.search(r"resets?\s*(?:at\s*)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?", text, re.I)
    if not m: return FALLBACK
    h, mi, ap = int(m.group(1)), int(m.group(2) or 0), (m.group(3) or "").lower()
    if ap == "pm" and h < 12: h += 12
    if ap == "am" and h == 12: h = 0
    if h > 23 or mi > 59: return FALLBACK
    target = now.replace(hour=h, minute=mi, second=0, microsecond=0)
    if target <= now: target += dt.timedelta(days=1)
    return int((target - now).total_seconds()) + 120   # 2 min Puffer

def work_left():
    r = subprocess.run([sys.executable, str(ROOT / "tools" / "tasks.py"), "next"], capture_output=True, text=True, cwd=ROOT)
    mine = subprocess.run([sys.executable, str(ROOT / "tools" / "tasks.py"), "mine"], capture_output=True, text=True, cwd=ROOT)
    return r.stdout.strip() != "NONE" or bool(mine.stdout.strip())

def main():
    idle_rounds = 0
    while work_left():
        r = subprocess.run([BIN, "-p", PROMPT, "--continue", *os.environ.get("CLAUDE_FLAGS", "").split()], capture_output=True, text=True, cwd=ROOT)
        out = (r.stdout or "") + (r.stderr or "")
        if r.returncode != 0 and LIMIT.search(out):
            s = wait_seconds(out); print(f"[auto_continue] Limit erkannt, warte {s//60} min", flush=True); time.sleep(s); idle_rounds = 0
        elif r.returncode != 0:
            idle_rounds += 1
            if idle_rounds >= 3: sys.exit("[auto_continue] 3 Fehlschläge ohne Limit-Hinweis, Abbruch:\n" + out[-500:])
            time.sleep(60)
        else:
            idle_rounds = 0
    print("[auto_continue] Nichts Startbares mehr, fertig.")
if __name__ == "__main__": main()
