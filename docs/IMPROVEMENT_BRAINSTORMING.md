# Improvement Brainstorming

Sammelstelle für Verbesserungsideen von Mitarbeitenden, Bots (A/B/C) und externen KIs (z. B. ChatGPT, Gemini, Midjourney-Ergebnisse). Jeder darf hier eine Idee eintragen. **Jeder Mitarbeitende und jeder Bot MUSS dieses Dokument bei jedem Start prüfen** (AGENT_PROMPT.md, Schritt 1) und jede Idee mit Status `neu` entscheiden.

## Regeln
1. **Eintragen:** Neue Zeile ganz unten in die Tabelle, Status `neu`, nächste freie ID (`IB-<Nr>`), Kurztext (1–2 Sätze), Quelle (Name, Bot oder Tool). Nur eine Zeile pro Idee, keine bestehenden Zeilen löschen.
2. **Entscheiden (Pflicht):** Wer das Dokument prüft, entscheidet alle `neu`-Ideen im selben Lauf:
   - `umsetzen`: Aufgabenkarte anlegen (`TASKS/`, siehe CONTRIBUTING.md), Kartennummer in „Entscheidung" eintragen.
   - `später`: sinnvoll, aber nicht jetzt; kurzer Grund.
   - `abgelehnt`: kurzer Grund (z. B. zu groß für die Demo, widerspricht dem Stil, doppelt).
3. **Maßstab:** Hilft es der Demo (Solo spielbar, 2–4 Spieler online, kein Game Over, „Midnight Toy Garden"-Stil)? Dann `umsetzen` oder `später`, sonst `abgelehnt`. Keine Rückfragen: selbst entscheiden und begründen.
4. **Externe KI-Vorschläge** (Grafik, Töne, Texte): nur als Idee eintragen. Dateien erst nach Prüfung von Lizenz und Stil in `assets/` legen und in docs/CREDITS.md nennen. Der Prompt, mit dem sie entstanden sind, wird in der Zeile festgehalten.
5. Prüfen: `python3 tools/ideas.py` (listet Ideen mit Status `neu`; Exit-Code 1, wenn es welche gibt).

Status: `neu` · `umsetzen` · `später` · `abgelehnt`

| ID | Datum | Quelle | Idee | Status | Entscheidung (wer, warum / Karte) |
|----|-------|--------|------|--------|-----------------------------------|
| IB-01 | 2026-11-24 | Jan | Ein KI-Bildwerkzeug (z. B. von OpenAI oder Google) soll die Grafiken verbessern: Logo, Hintergrund des Hauptmenüs, Sternbilder-Poster, Symbole. Prompt und Referenzbilder siehe docs/ARTWORK_BRIEF.md. | später | bot-A: braucht einen Menschen mit Zugang zu einem Bildwerkzeug (Jan); Brief liegt bereit. Ergebnisse als neue Ideen/Dateien eintragen. |
| IB-02 | 2026-11-24 | bot-A | Host-Info ist da; als nächstes könnte ein Beitritts-Link oder Code ("Raumcode") das Eintippen der IP ersetzen. | später | bot-A: Eintippen der IP reicht für die Demo; erst nach dem Internet-Test von Jan sinnvoll. |
| IB-03 | 2026-11-24 | bot-A | Netztest `test_netplayers.sh` flackert (siehe docs/KNOWN_ISSUES.md); Ursache klären (Godot-Spawner-Verdacht), bevor Online-Demo. | umsetzen | bot-A: wird als Fehlersuche von Person A weiterverfolgt (Mitarbeitende B/C: nicht anfassen). |
