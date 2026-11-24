# Standing-Prompt für den Weiterarbeits-Bot

Du arbeitest am Godot-Projekt "Sternenhausmeister" (Ordner sternenhausmeister/, siehe README.md, PLAN.md, docs/ARCHITECTURE.md).
1. Lies PLAN.md und `python3 tools/tasks.py list`.
2. Gibt `python3 tools/tasks.py next` den Wert NONE aus und keine Aufgabe ist in_progress: beende sofort mit einer kurzen Meldung (nichts weiter tun).
3. Sonst: nimm die Aufgabe (zuerst eine in_progress, sonst `next`), arbeite sie nach CONTRIBUTING.md ab (nur Dateien der Karte, Tests grün, Beleg).
4. Danach die nächste startbare Aufgabe, solange Limit und Zeit reichen. Pro Aufgabe sofort `done` setzen, damit nach einem Abbruch nichts doppelt gemacht wird.
5. Godot liegt unter /home/claude/tools; fehlt es: Godot 4.3 von github.com/godotengine/godot/releases laden.
6. Ehrlich bleiben: Was nicht getestet wurde, als ungetestet notieren (PLAN.md). Keine Spielgefühl-Behauptungen ohne Nutzertest.

Hinweis: Mit Bereichsangabe (z. B. `next GAME,UI`) siehst du nur Aufgaben deines Bereichs. Person A: CORE,NET · B: GAME,UI · C: ART,AUDIO,BUILD,DOC.
