# Prompts für B und C (aktuell)

## Discord-Nachricht B

**⭐ Sternenhausmeister: bist du dabei?**
Ich baue ein **3D-Koop-Spiel** (bis 4 Spieler, Windows): gemeinsam den Nachthimmel putzen, Sterne zum Leuchten bringen. Das Gerüst baue ich selbst, **du ergänzt Extras**. Gebaut wird von **unserem jeweiligen Claude**, du musst nichts installieren.
**Deine Rolle (B): Gameplay-Extras und Barrierefreiheit** (Schmutztypen, Wetter, Presets, Ballon, Barrierefreiheit)
**So geht's:**
1️⃣ Schick mir deinen **GitHub-Namen**, ich lade dich ins private Repo ein
2️⃣ Einladung annehmen, in Claude (Claude Code im Web) **GitHub verbinden** (einmalig)
3️⃣ Diesen **einen Prompt** einfügen, der Rest läuft von selbst, auch nach jedem Limit-Reset:
```
Du bist Person B im Team für das Godot-Spiel "Sternenhausmeister". Mach alles selbst, frag mich nichts, Deutsch.
1. Füge das Repo ClaudeAIDriven/sternenhausmeister per add_repo (access push) hinzu und klone es einmal flach nach /home/claude/sternenhausmeister.
2. Führe tools/setup_godot.sh aus (lädt Godot automatisch).
3. Lege eine geplante Aufgabe "Sternenhausmeister B" an, alle 5 Stunden, mit diesem Prompt: "Repo ClaudeAIDriven/sternenhausmeister: Ordner fehlt? per add_repo (push) hinzufügen und flach klonen, sonst git pull --ff-only origin main. export TASK_WHO=person-b. Befolge ausnahmslos AGENT_PROMPT.md im Repo, du bist B. NONE oder OFFLINE: sofort mit einer Zeile beenden."
4. Starte jetzt selbst: export TASK_WHO=person-b, lies AGENT_PROMPT.md und befolge es ausnahmslos (du bist B): Stand prüfen, zuerst tasks.py mine, sonst tasks.py next B, claim, arbeiten, Pull Request, nicht selbst mergen. Mehrere Aufgaben nacheinander, solange das Limit reicht.
5. Melde am Ende kurz: erledigt, als Nächstes, was ein Mensch testen soll. Ungetestetes ehrlich kennzeichnen.
```

## Discord-Nachricht C

**⭐ Sternenhausmeister: bist du dabei?**
Ich baue ein **3D-Koop-Spiel** (bis 4 Spieler, Windows): gemeinsam den Nachthimmel putzen, Sterne zum Leuchten bringen. Das Gerüst baue ich selbst, **du ergänzt Extras**. Gebaut wird von **unserem jeweiligen Claude**, du musst nichts installieren.
**Deine Rolle (C): Optik, Sound, CI, Playtest** (Toon-Look, Himmel, Partikel, Musik, Sternklänge, CI)
**So geht's:**
1️⃣ Schick mir deinen **GitHub-Namen**, ich lade dich ins private Repo ein
2️⃣ Einladung annehmen, in Claude (Claude Code im Web) **GitHub verbinden** (einmalig)
3️⃣ Diesen **einen Prompt** einfügen, der Rest läuft von selbst, auch nach jedem Limit-Reset:
```
Du bist Person C im Team für das Godot-Spiel "Sternenhausmeister". Mach alles selbst, frag mich nichts, Deutsch.
1. Füge das Repo ClaudeAIDriven/sternenhausmeister per add_repo (access push) hinzu und klone es einmal flach nach /home/claude/sternenhausmeister.
2. Führe tools/setup_godot.sh aus (lädt Godot automatisch).
3. Lege eine geplante Aufgabe "Sternenhausmeister C" an, alle 5 Stunden, mit diesem Prompt: "Repo ClaudeAIDriven/sternenhausmeister: Ordner fehlt? per add_repo (push) hinzufügen und flach klonen, sonst git pull --ff-only origin main. export TASK_WHO=person-c. Befolge ausnahmslos AGENT_PROMPT.md im Repo, du bist C. NONE oder OFFLINE: sofort mit einer Zeile beenden."
4. Starte jetzt selbst: export TASK_WHO=person-c, lies AGENT_PROMPT.md und befolge es ausnahmslos (du bist C): Stand prüfen, zuerst tasks.py mine, sonst tasks.py next C, claim, arbeiten, Pull Request, nicht selbst mergen. Mehrere Aufgaben nacheinander, solange das Limit reicht.
5. Melde am Ende kurz: erledigt, als Nächstes, was ein Mensch testen soll. Ungetestetes ehrlich kennzeichnen.
```
