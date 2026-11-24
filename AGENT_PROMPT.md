# Verbindliches Vorgehen bei jedem "weiter"/Start/Reset (für Menschen und Modelle)

Einzige Quelle der Wahrheit für den Ablauf. Du bist A, B oder C (Besitzer-Buchstabe). A hält alles, was die Demo zwingend braucht (Priorität must: Kern, Netzwerk, Spielschleife, Menü/HUD, Export/Installer). B und C machen Zusätzliches (nice: B = Schmutztypen, Wetter, Presets, Ballon, Barrierefreiheit; C = Optik, Ton, CI, Playtest-Liste). Setze `export TASK_WHO=<dein Name>` (z. B. jan, bot-A, anna).

## 0. Einmalig pro Umgebung
`tools/setup_godot.sh` lädt Godot 4.3 automatisch (kein manuelles Installieren nötig). `tools/run_tests.sh` ruft es selbst auf.

## 1. Zuerst den Stand prüfen (immer, vor jeder Arbeit)
1. `git pull --ff-only origin main` und `python3 tools/tasks.py status`. Meldet es OFFLINE oder einen Fehler: **abbrechen und melden**, nichts auf Verdacht tun.
2. `tools/run_tests.sh` auf main. Rot? Dann nur die rote Stelle reparieren (neue Aufgabe `fix-…`), nichts Neues beginnen.
3. Offene Pull Requests ansehen: `gh api repos/ClaudeAIDriven/sternenhausmeister/pulls --jq '.[]|[.number,.title,.head.ref]|@tsv'`. Überschneidet sich dein Vorhaben mit Dateien eines offenen PR, melde das, statt doppelt zu bauen.

## 2. Was ist dran?
1. `python3 tools/tasks.py mine`: Hast du eine begonnene Aufgabe, mach **zuerst die** weiter (`git fetch`, Branch `task/<ID>/<WER>` auschecken, vorhandenen Code und Commits lesen, nichts neu anfangen).
2. Sonst `python3 tools/tasks.py next <A|B|C>` (eigene Aufgaben zuerst; fällt jemand aus, kommen unbeanspruchte der anderen danach). Ergebnis NONE: **sofort beenden** mit einer Zeile ("nichts Startbares: wartet auf …"). Keine eigenen Aufgaben erfinden, keine Features außerhalb der Karten.
3. `python3 tools/tasks.py claim <ID>` beansprucht die Aufgabe (legt `task/<ID>/<WER>` auf origin an). Meldet es BELEGT, nimm die nächste.

## 3. Arbeiten und abgeben
1. Branch auschecken, nur die Dateien der Karte ändern, Schnittstellen aus docs/ARCHITECTURE.md beachten.
2. `tools/run_tests.sh` grün, Beleg zu "Fertig, wenn" (Test oder Screenshot).
3. `python3 tools/tasks.py done <ID>` im Branch, eine Zeile in PLAN.md, committen, pushen, Pull Request mit Beleg eröffnen. Nicht selbst nach main mergen (nur Person A; C-01/C-02 darf der Bot direkt pushen).
4. Danach wieder bei Schritt 1, solange das Limit reicht. Bricht das Limit ab, ist der Stand durch den Claim-Branch gesichert.

## 4. Ehrlichkeit
Ungetestetes als ungetestet kennzeichnen (🟢 getestet · 🟡 wahrscheinlich · 🔴 geraten · ❌ unbekannt). Spielgefühl beurteilt nur ein Mensch. Godot 4.3: /home/claude/tools/Godot_v4.3-stable_linux.x86_64, sonst von github.com/godotengine/godot/releases laden. Sichtprüfung ohne GPU: siehe PLAN.md.

## 5. Verwaiste Claims
Ein Claim ohne Commits oder PR seit mehr als 48 h gilt als verwaist. Person A entscheidet und löscht den Branch (`git push origin --delete task/<ID>/<WER>`).
