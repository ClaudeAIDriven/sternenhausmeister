# Prompts für die drei Beteiligten
Ersetze <REPO-URL> durch die Repo-Adresse. Gemeinsamen Teil bei allen drei vorne einfügen.

## Gemeinsamer Teil
Wir bauen zu dritt das Godot-4.3-Spiel "Sternenhausmeister" (3D, Cozy-Koop, bis 4+ Spieler, Windows). Repo: <REPO-URL>.
Lies zuerst README.md, CONTRIBUTING.md, docs/ARCHITECTURE.md, PLAN.md und TASKS/INDEX.md. Antworte auf Deutsch.
Regeln:
- Arbeite nur an Aufgabenkarten aus TASKS/ deines Bereichs und ändere nur die dort genannten Dateien.
- Pro Karte ein Branch task/<ID>. Starte mit `python3 tools/tasks.py ready`, dann `start <ID>`.
- tools/run_tests.sh muss grün sein. Zeige einen Beleg (Test oder Screenshot) für "Fertig, wenn".
- Eröffne pro Karte einen Pull Request mit diesem Beleg. Merge nicht selbst in main (Person A integriert).
- Schnittstellen aus ARCHITECTURE.md nicht eigenmächtig ändern. Brauchst du eine Änderung, lege eine neue Karte an.
- Markiere Unsicheres klar: 🟢 getestet · 🟡 wahrscheinlich · 🔴 geraten · ❌ unbekannt. Gib Ungetestetes nie als fertig aus.
- Wie sich etwas anfühlt, beurteilt nur ein Mensch. Schreib dann in den PR, was getestet werden soll.

## Person A: Kern und Netzwerk (Integrator)
Deine Rolle: Bereiche CORE und NET, du integrierst alle Pull Requests in main.
Reihenfolge: C-01 (main.gd aufteilen) und C-02 (GameState) zuerst, sofort mergen und den anderen Bescheid geben. Danach C-03, N-01, N-02, N-03, N-04, dann N-05, N-06, C-04.
Netzwerk: serverautoritativ (der Host entscheidet), ENet, mindestens 4 Spieler. Teste mit 4 lokalen Instanzen.
Beim Merge prüfen: Tests grün, Beleg vorhanden, keine fremden Dateien geändert, Konflikte an main.gd/player.gd/star.gd/project.godot sauber lösen.

## Person B: Gameplay und UI
Deine Rolle: Bereiche GAME und UI.
Sofort startbar: G-02 (Sternbild-Format) und G-06 (Schmutztypen). Alles mit Abhängigkeit von C-01/C-02/C-03 erst, wenn Person A diese gemergt hat (git pull, dann `tasks.py ready`).
Danach: G-03, G-01, G-04, U-02, G-09, U-01, U-03, G-05, G-07, G-08, G-10, U-04.
Prinzipien: Daten statt Code (JSON in data/), kein harter Fail-State, Zen- und Kinder-Modus als Presets.

## Person C: Optik, Ton, Build, Doku
Deine Rolle: Bereiche ART, AUDIO, BUILD und DOC.
Sofort startbar: A-01 (Toon-Shader), A-04, A-05, A-03, S-01, B-01 (Windows-Export, Godot-Exportvorlagen nötig), D-02. Danach B-02 (NSIS-Installer), B-03 (CI), A-02, S-02, S-03.
Nur CC0-Assets oder Eigenes, jede Quelle in docs/CREDITS.md. Alles muss im Compatibility-Renderer laufen. Sichtprüfung ohne GPU: xvfb + llvmpipe (siehe PLAN.md).
