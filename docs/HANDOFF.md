# Übergabe: Weiterarbeiten mit Claude Code (Stand 2026-11-24, bot-A)

Alles liegt in diesem Repository auf `main`. Es gibt keinen Zustand außerhalb von GitHub, den du brauchst.

## Start in einer neuen Umgebung
```bash
git clone https://github.com/ClaudeAIDriven/sternenhausmeister.git && cd sternenhausmeister
tools/setup_godot.sh          # lädt Godot 4.3 nach ~/.local, gibt den Pfad aus
tools/run_tests.sh            # muss mit "TESTS OK" enden
python3 tools/tasks.py status # Roadmap und offene Ideen
```
Dann gilt der Ablauf in `AGENT_PROMPT.md` (Stand prüfen, Ideen entscheiden, Karte beanspruchen, Branch `task/<ID>/<WER>`, Tests, PR, Merge).
Einstiegs-Prompt für Claude Code: *"Lies AGENT_PROMPT.md und docs/HANDOFF.md, du bist A, arbeite die nächste Karte ab."*

## Wichtige Befehle
- Netztests (Host + Clients auf localhost): `tools/test_netstars.sh`, `tools/test_netshop.sh`, `tools/test_netpuzzle.sh`, `tools/test_netdrone.sh` (`test_netplayers.sh` flackert, siehe KNOWN_ISSUES).
- Windows-Build: `tools/build_windows.sh`, Installer: `tools/build_installer.sh` (NSIS). CI veröffentlicht bei jedem Push auf main die Vorabversion `latest`.
- Screenshot ohne Grafikkarte (Linux):
  `xvfb-run -a -s "-screen 0 1280x720x24" $(tools/setup_godot.sh) --rendering-driver opengl3 --resolution 1280x720 --write-movie /tmp/shot/m.png --fixed-fps 30 --quit-after 120 -s <skript.gd>`
  (Skript startet `main.tscn` mit `Menu.launch = {"mode": "solo", ...}` und setzt den Spieler, Beispiel im Verlauf von PR #86).

## Was zuletzt kam (PR #86)
Lauf-Animation, Ballon ebenerdig und lenkbar, Kollision Haus/Laternen/Schild, Werkstatt nur in der Nähe mit F, Insel Radius 32, Lebensleiste mit Regeneration, Fall-/Schubs-/Lava-/Kaktusschaden, Rollen (Allrounder, Hüpfer, Putzer, Flitzer), Spinnennester, Minimap. Test: `tests/test_survival.gd`.

## Roadmap (Reihenfolge)
Karten in `TASKS/` (Übersicht `TASKS/INDEX.md`), je Karte ein GitHub-Issue mit Label `roadmap`:
1. G-20 Tod mit 60-s-Respawn, 10 % Staubverlust, Wiederbeleben
2. G-21 Essen (Food-Leiste) → G-22 Früchte/Inventar → G-23 Küche/Rezepte → G-24 Rollen Koch und Kletterer
3. G-25 Putz-Utensilien → G-26 XP/Fähigkeiten → G-27 Speichern/Laden
4. G-28 Gegner (Wollmaus, Spinne) → G-29 Rußwolke (Team-Gegner)
5. G-30 Orte (C), G-31 prozedurale Insel, G-32 Friedensvertrag (C), G-33 Minimap-Ping (C)
Begründungen und Recherche: `docs/IMPROVEMENT_BRAINSTORMING.md` (Abschnitt „Recherche“).

## Offene Punkte
- Jan meldete „Spieler lässt sich nach dem Umbenennen nicht mehr bewegen“. In Solo und als Host (Linux, aktueller main) bewegt sich der Spieler; `tests/test_survival.gd` prüft das. Ungeklärt, ob es die Windows-Exe, einen Beitritt als Client oder das Umbenennen im Menü betrifft: mit Jan nachstellen.
- Ballon ist nicht host-autoritativ: Jeder Rechner bewegt seinen eigenen Ballon (Lenken wirkt online nur lokal). Vor G-31 auf Host-Sync umstellen.
- `sync_to_physics` am Ballon ist absichtlich aus (sonst friert die Position beim Lenken ein).
- Windows-Exe und Spiel über das Internet sind ungetestet (kein Windows hier).
- Weitere bekannte Grenzen: `docs/KNOWN_ISSUES.md`.

## Autopilot (Skill projekt-autopilot, eingebunden 2026-11-24)
- `tools/tasks.py` ist die Skill-Version: zusätzlich `board` (wer baut was), `batch` (mehrere Karten ohne Dateiüberschneidung), atomarer `claim` (Schloss `lock/<ID>`), `release`, `ideas`/`idea`, `issues`. Alte Befehle (`next A|B|C`, `mine`, `index`, `status`) bleiben. Pfade in `tools/autopilot.json` (Ideen weiter in `docs/IMPROVEMENT_BRAINSTORMING.md`).
- `tools/cli_scout.py` + Register `docs/CLI_TOOLS.md` (CLI-Anything). Braucht Netzzugriff auf hkuds.github.io; in der Cloud-Umgebung aktuell gesperrt.
- `tools/auto_continue.py`: im Terminal nach Token-Limit automatisch weiter.
- `TASK_WHO` pro Sitzung eindeutig wählen (`bot-A1`, `bot-A2`, …), sonst bauen parallele Sitzungen dieselbe Karte.
- ❌ Wächter (geplante Aufgabe alle 30 min, `TASK_WHO=bot-waechter`) ist noch nicht eingerichtet: das Anlegen wurde in der Sitzung abgelehnt und muss vom Menschen freigegeben werden.
