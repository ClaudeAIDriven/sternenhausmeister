# Einladungen mit To-dos und Automatik

Ersetze nichts, die Repo-Adresse steht schon drin. Jeder Block: 1) Nachricht zum Weiterschicken, 2) Einrichtungs-To-dos, 3) Automatik-Prompt.
Repo: https://github.com/ClaudeAIDriven/sternenhausmeister

---
## Person B: Gameplay und UI

### 1) Einladung (per WhatsApp schicken)
Hey! Ich baue mit zwei Leuten ein 3D-Koop-Spiel ("Sternenhausmeister": ihr putzt gemeinsam den Nachthimmel, Sterne leuchten auf, bis 4 Spieler, Windows). Gebaut wird mit Godot und unserem jeweiligen Claude. Ich habe dich im GitHub-Repo eingeladen: https://github.com/ClaudeAIDriven/sternenhausmeister . Deine Rolle: Gameplay und Menüs (Rätsel, Shop, Wetter, HUD, Menüs). Unten stehen deine To-dos und ein Prompt für dein Claude. Aufwand: ein paar Stunden pro Woche reichen, jede Aufgabe ist klein.

### 2) To-dos zum Einrichten
1. GitHub-Einladung annehmen (E-Mail oder github.com/notifications).
2. Godot 4.3 (Standard, nicht .NET) von godotengine.org laden, entpacken.
3. Repo klonen: `git clone https://github.com/ClaudeAIDriven/sternenhausmeister` und in Godot öffnen (F5 startet den Prototyp).
4. Dein Claude mit dem Repo verbinden (Claude Code im Ordner oder claude.ai mit GitHub-Anbindung) und den Prompt aus `docs/PROMPTS.md` einfügen: "Gemeinsamer Teil" + "Person B".
5. Erste Aufgaben: G-02 (Sternbild-Format), G-06 (Schmutztypen). Alles andere wartet auf Person A (C-01, C-02, C-03).
6. Pro Aufgabe: Branch `task/<ID>`, Test grün, Pull Request mit Beleg.

### 3) Automatik-Prompt (als geplante Aufgabe alle ~5 Stunden, oder nach jedem Limit-Reset manuell einfügen)
Du arbeitest am Godot-Spiel "Sternenhausmeister" weiter. Repo: https://github.com/ClaudeAIDriven/sternenhausmeister. Fehlt der lokale Ordner, klone es (flach), sonst `git pull --ff-only origin main`. Lies AGENT_PROMPT.md, CONTRIBUTING.md und docs/ARCHITECTURE.md. Deine Bereiche: GAME und UI. `python3 tools/tasks.py next GAME,UI` nennt die nächste Aufgabe (NONE = beenden, eine Zeile Meldung). Pro Aufgabe: Branch task/<ID>, nur die Dateien der Karte ändern, `tools/run_tests.sh` grün, `tasks.py done <ID>`, committen, pushen, Pull Request mit Beleg eröffnen, nicht selbst nach main mergen. Mehrere Aufgaben nacheinander, solange das Limit reicht. Ungetestetes ehrlich so kennzeichnen. Am Ende kurz melden: erledigt, als Nächstes, was ein Mensch testen soll.

---
## Person C: Optik, Ton, Build, Doku

### 1) Einladung (per WhatsApp schicken)
Hey! Ich baue mit zwei Leuten ein 3D-Koop-Spiel ("Sternenhausmeister": ihr putzt gemeinsam den Nachthimmel, bis 4 Spieler, Windows, Godot). Ich habe dich ins GitHub-Repo eingeladen: https://github.com/ClaudeAIDriven/sternenhausmeister . Deine Rolle: Optik, Sound, Windows-Installer und Doku. Dafür musst du kaum programmieren, dein Claude macht das mit. Unten stehen deine To-dos und ein Prompt.

### 2) To-dos zum Einrichten
1. GitHub-Einladung annehmen.
2. Godot 4.3 (Standard) laden und das geklonte Repo öffnen: `git clone https://github.com/ClaudeAIDriven/sternenhausmeister`.
3. Dein Claude mit dem Repo verbinden und den Prompt aus `docs/PROMPTS.md` einfügen: "Gemeinsamer Teil" + "Person C".
4. Erste Aufgaben (alle sofort startbar): A-01 Toon-Shader, A-04 Himmel, A-05 Partikel, A-03 Props, S-01 Musik, B-01 Windows-Export, D-02 Playtest-Checkliste.
5. Nur CC0-Assets oder Eigenes, Quelle in `docs/CREDITS.md`.
6. Pro Aufgabe: Branch `task/<ID>`, Test grün, Pull Request mit Screenshot oder Hörprobe.

### 3) Automatik-Prompt (geplante Aufgabe alle ~5 Stunden, oder nach jedem Limit-Reset manuell einfügen)
Du arbeitest am Godot-Spiel "Sternenhausmeister" weiter. Repo: https://github.com/ClaudeAIDriven/sternenhausmeister. Fehlt der lokale Ordner, klone es (flach), sonst `git pull --ff-only origin main`. Lies AGENT_PROMPT.md, CONTRIBUTING.md und docs/ARCHITECTURE.md. Deine Bereiche: ART, AUDIO, BUILD, DOC. `python3 tools/tasks.py next ART,AUDIO,BUILD,DOC` nennt die nächste Aufgabe (NONE = beenden, eine Zeile Meldung). Pro Aufgabe: Branch task/<ID>, nur die Dateien der Karte ändern, `tools/run_tests.sh` grün, `tasks.py done <ID>`, committen, pushen, Pull Request mit Beleg eröffnen, nicht selbst nach main mergen. Nur CC0-Assets, Quellen in docs/CREDITS.md. Mehrere Aufgaben nacheinander, solange das Limit reicht. Ungetestetes ehrlich kennzeichnen. Am Ende kurz melden.

---
## Person A (du): Kern, Netzwerk, Integration

### To-dos
1. Einladungen an B und C verschicken (Repo → Settings → Collaborators).
2. Der Bot baut C-01 und C-02 (oder ich jetzt sofort). Sobald beide auf `main` sind, B und C Bescheid geben.
3. Pull Requests der anderen prüfen und mergen (Tests grün, Beleg da, nur erlaubte Dateien).
4. Nach jedem Meilenstein einen Windows-Test-Build (B-01) und gemeinsamer Playtest mit `docs/PLAYTEST.md`.

### Automatik (läuft bereits, alle 5 Stunden)
Geplante Aufgabe "Sternenhausmeister Weiterbau": nimmt `next CORE,NET`, arbeitet pro Branch, eröffnet Pull Requests. Nur C-01 und C-02 gehen direkt nach main.

---
## Ehrliche Hinweise
- 🟡 Ob dein Plan geplante Aufgaben anbietet, siehst du in deinen Claude-Einstellungen. Ohne sie reicht der Prompt als Einzeiler nach jedem Reset: "Mach mit dem Automatik-Prompt weiter."
- ❌ Wann genau deine Limits zurückgesetzt werden, weiß ich nicht. Die Automatik läuft deshalb im festen Takt.
- 🔴 Dein Claude braucht Push-Rechte aufs Repo (Collaborator-Einladung angenommen, GitHub in Claude verbunden). Ohne die kann es nur lokal arbeiten.
