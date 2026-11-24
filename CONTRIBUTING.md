# Mitmachen (Menschen und Modelle)

1. `python3 tools/tasks.py ready` zeigt Aufgaben, die jetzt startbar sind.
2. Karte in `TASKS/<ID>.md` lesen, `python3 tools/tasks.py start <ID>`.
3. Nur die Dateien der Karte ändern. Schnittstellen: `docs/ARCHITECTURE.md`.
4. `tools/run_tests.sh` muss grün sein, dazu ein Beleg (Test oder Screenshot) für „Fertig, wenn".
5. `python3 tools/tasks.py done <ID>`, eine Zeile in PLAN.md ergänzen.

Stil: GDScript mit Typangaben, kleine Dateien, Kommentare auf Deutsch, Namen auf Englisch. Pro Aufgabe ein Commit/Branch `task/<ID>`.
Bereiche: CORE, NET, GAME, ART, AUDIO, UI, BUILD, DOC. Kunst und Audio brauchen kein Programmieren, nur die Dateien der Karte.
