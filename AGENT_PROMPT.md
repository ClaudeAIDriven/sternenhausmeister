# Verbindliches Vorgehen bei jedem "weiter"/Start/Reset (für Menschen und Modelle)

Einzige Quelle der Wahrheit für den Ablauf. Du bist A, B oder C (Besitzer-Buchstabe). A hält alles, was die Demo zwingend braucht (Priorität must: Kern, Netzwerk, Spielschleife, Menü/HUD, Export/Installer). B und C machen Zusätzliches (nice: B = Schmutztypen, Wetter, Presets, Ballon, Barrierefreiheit; C = Optik, Ton, CI, Playtest-Liste). Setze `export TASK_WHO=<dein Name>` (z. B. jan, bot-A, anna).

## 0. Einmalig pro Umgebung
`tools/setup_godot.sh` lädt Godot 4.3 automatisch (kein manuelles Installieren nötig). `tools/run_tests.sh` ruft es selbst auf.

## 1. Zuerst den Stand prüfen (immer, vor jeder Arbeit)
1. `git pull --ff-only origin main`, `python3 tools/tasks.py status` und `python3 tools/tasks.py board` (wer baut gerade was, Commits, Alter, `[VERWAIST?]`). Meldet es OFFLINE oder einen Fehler: **abbrechen und melden**, nichts auf Verdacht tun.
2. `tools/run_tests.sh` auf main. Rot? Dann nur die rote Stelle reparieren (neue Aufgabe `fix-…`), nichts Neues beginnen.
3. Offene Pull Requests ansehen: `gh api repos/ClaudeAIDriven/sternenhausmeister/pulls --jq '.[]|[.number,.title,.head.ref]|@tsv'`. Überschneidet sich dein Vorhaben mit Dateien eines offenen PR, melde das, statt doppelt zu bauen.

4. **Pflicht: Ideen prüfen.** `python3 tools/tasks.py ideas` (oder `tools/ideas.py`; neue Idee: `tasks.py idea "Text"`). Jede Idee mit Status `neu` in `docs/IMPROVEMENT_BRAINSTORMING.md` entscheidest du jetzt: `umsetzen` (Karte anlegen), `später` oder `abgelehnt`, jeweils mit kurzem Grund. Eigene Ideen trägst du dort ein, statt sie auf Verdacht zu bauen. Das geht per kleinem PR nur an dieser Datei (und ggf. neuen Karten) und zählt nicht als Feature-Arbeit.

5. Werkzeuge: `python3 tools/cli_scout.py install` (alle `aktiv` im Register `docs/CLI_TOOLS.md`).

## 2. Was ist dran?
1. `python3 tools/tasks.py mine`: Hast du eine begonnene Aufgabe, mach **zuerst die** weiter (`git fetch`, Branch `task/<ID>/<WER>` auschecken, vorhandenen Code und Commits lesen, nichts neu anfangen).
2. Sonst `python3 tools/tasks.py next <A|B|C>` (eigene Aufgaben zuerst; fällt jemand aus, kommen unbeanspruchte der anderen danach). Ergebnis NONE: **sofort beenden** mit einer Zeile ("nichts Startbares: wartet auf …"). Keine eigenen Aufgaben erfinden, keine Features außerhalb der Karten.
   Mehrere kleine, unabhängige Karten auf einmal nur bei reichlich Budget: `python3 tools/tasks.py batch` (ohne Dateiüberschneidung). Sonst genau eine, nie auf Vorrat.
3. `python3 tools/tasks.py claim <ID>` beansprucht die Aufgabe **vor der ersten Änderung**, atomar (Schloss `lock/<ID>`, legt `task/<ID>/<WER>` an, markiert das Issue). Nur bei `CLAIMED` arbeiten, bei `BELEGT` die nächste. Nicht mehr bearbeitete Karten mit `tasks.py release <ID>` freigeben.
4. `TASK_WHO` muss pro Sitzung **eindeutig** sein (z. B. `bot-A1`, `bot-A2`): Zwei Sitzungen mit demselben Namen sehen die Claims der anderen als eigene und bauen dieselbe Karte doppelt (so geschehen bei G-21).
5. CLI-Check pro Karte: 2 bis 5 englische Stichworte, `python3 tools/cli_scout.py scout <Stichworte>`. Sinnvolle CLI per 3-Stimmen-Entscheidung mit `register <name> aktiv "Zweck" <Karte>` eintragen, `docs/CLI_TOOLS.md` im selben PR abgeben.

## 3. Arbeiten und abgeben
1. Branch auschecken, nur die Dateien der Karte ändern, Schnittstellen aus docs/ARCHITECTURE.md beachten.
2. `tools/run_tests.sh` grün, Beleg zu "Fertig, wenn" (Test oder Screenshot).
3. `python3 tools/tasks.py done <ID>` im Branch, eine Zeile in PLAN.md, committen, pushen, Pull Request mit Beleg eröffnen. Nicht selbst nach main mergen (nur Person A; C-01/C-02 darf der Bot direkt pushen).
4. Nach jedem kleinen Schritt committen und pushen (absturzsicher). Danach wieder bei Schritt 1, solange das Limit reicht.

## 3b. Limit / wenig Token
Nichts Neues beanspruchen, committen, pushen, Stand in PLAN.md. Weiter geht es automatisch: der Wächter (geplante Aufgabe alle 30 min, ID in PLAN.md) startet eine Sitzung, in der Cloud-Sitzung zusätzlich `send_later` zum Reset, im Terminal `python3 tools/auto_continue.py`.

## 4. Ehrlichkeit
Ungetestetes als ungetestet kennzeichnen (🟢 getestet · 🟡 wahrscheinlich · 🔴 geraten · ❌ unbekannt). Spielgefühl beurteilt nur ein Mensch. Godot 4.3: /home/claude/tools/Godot_v4.3-stable_linux.x86_64, sonst von github.com/godotengine/godot/releases laden. Sichtprüfung ohne GPU: siehe PLAN.md.

## 5. Verwaiste Claims
Ein Claim ohne Commits oder PR seit mehr als 48 h gilt als verwaist. Person A entscheidet und löscht den Branch (`git push origin --delete task/<ID>/<WER>`).

## 6. Entscheidungsregel (Wunsch von Jan: keine Rückfragen)
- Bei offenen Designfragen **selbst entscheiden** und die Entscheidung in PLAN.md festhalten. Nicht beim Nutzer nachfragen.
- Jede echte Entscheidung (mehr als eine vernünftige Option: Architektur, Bibliothek, CLI-Auswahl, Aufteilung) mit 3 Stimmen: eigene Empfehlung zuerst aufschreiben, dann **2 weitere Agenten** unabhängig mit derselben Frage befragen (je kurze Empfehlung mit Begründung), Mehrheit umsetzen, Ergebnis mit "Entscheidung: X (2:1, Gründe)" in PLAN.md notieren.
- **Ausgenommen von Abstimmungen:** Sicherheitsfragen und abgelehnte Aktionen (Berechtigungen, Pushen nach main ohne Pull Request, Löschen fremder Branches). Eine Ablehnung wird nicht per Mehrheit umgangen: sicheren Weg wählen oder im Bericht erwähnen.
