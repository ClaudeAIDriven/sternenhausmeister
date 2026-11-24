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
| IB-04 | 2026-11-24 | bot-A | **Grind gering halten:** Aktuell gibt es nur 3 Upgrades (zusammen 11 Stufen, wenige Dutzend Staub). Nach einer Nacht ist alles gekauft, danach hat Staub keinen Zweck. Staub braucht eine Senke ohne Zwang: Kosmetik (Wedel-Farben, Laternenfarbe, Mützen), die nichts schneller macht. | später | bot-A: gut für Langzeitmotivation, aber erst nach Demo; als Karte „Kosmetik-Shop“ (Bereich UI/GAME) vormerken. |
| IB-05 | 2026-11-24 | bot-A | **Kombo beim Putzen:** Wer ohne Pause wischt, baut eine Serie auf (Ton steigt in der Pentatonik, Staub +10 % je Stufe bis +50 %). Belohnt flüssiges Putzen statt Klick-Spam, kein Zwang. | umsetzen | bot-A: günstig (game_state + sfx), verbessert das Spielgefühl sofort. Karte G-12 anlegen. |
| IB-06 | 2026-11-24 | bot-A | **Mehr Tiefe durch Teamarbeit:** Ein Sternbild-Stern liegt nur im Ballon-Bereich (hoch), ein zweiter Spieler muss den Ballon halten bzw. mitfahren. Gemeinsames Putzen desselben Sterns gibt Bonusstaub für alle Beteiligten. | umsetzen | bot-A: macht Mehrspieler spürbar besser als „vier Einzelspieler“. Karte G-13 (Co-op-Bonus) zuerst, Ballon-Zwang später. |
| IB-07 | 2026-11-24 | bot-A | **Mehr Sternbilder (Inhalt statt Grind):** Es gibt 3. Pro Nacht eines zufällig, ab Nacht 2 auch längere. Sechs bis acht reichen für viele Abende. Datenformat existiert (G-02), nur JSON nötig. | umsetzen | bot-A: Mitarbeitende B/C können das ohne Code leisten. Karte G-14 (5 weitere Sternbilder, JSON + Test). |
| IB-08 | 2026-11-24 | bot-A | **Nachtbewertung statt Game Over:** Am Nachtende Übersicht mit 1–3 Sternchen (Anteil geputzter Sterne, gelöstes Sternbild), Beitrag je Spieler als Balken, keine Rangliste. Gibt ein Ziel, ohne zu bestrafen. | umsetzen | bot-A: passt zu „sanftem Zeitlimit“. Karte U-05 (Nacht-Zusammenfassung, nutzt night_ended). |
| IB-09 | 2026-11-24 | bot-A | **Fortschritt zwischen Nächten (Meta):** Insel wächst: jede gelöste Konstellation lässt eine Laterne/Blume dauerhaft auf der Insel leuchten, gespeichert in Settings. Sichtbarer Fortschritt ohne Zahlengrind. | später | bot-A: braucht Speicherformat und Welt-Dekoration; nach IB-08. |
| IB-10 | 2026-11-24 | bot-A | **Sternschnuppen verschmutzen Sterne neu** (Folge von G-07): Ein geputzter Stern bekommt wenige neue Flecken, Teams müssen reagieren. Erzeugt Spannung. Zen-Modus schaltet es aus. | umsetzen | bot-A: setzt G-07 (PR #44, B) voraus und braucht in star.gd eine „neu verschmutzen“-Funktion. Karte G-15, abhängig von G-07. |
| IB-11 | 2026-11-24 | bot-A | **Werkzeugstufen statt reiner Zahlen:** Staubwedel → Bürste → Sternsauger, jeweils mit eigenem Modell und Schmutztyp-Bonus (G-06). Spürbarer Wechsel statt +0,25 Radius. | später | bot-A: ToolModels hat die Modelle teilweise; erst nach Demo. |
| IB-12 | 2026-11-24 | bot-A | **Anfänger-Hilfe:** In Nacht 1 pulsiert der nächste Stern des Sternbilds (Hinweisfunktion `set_hint` existiert), ein kurzer Texthinweis erklärt „Wischen = Linksklick“. Ab Nacht 2 aus. | umsetzen | bot-A: für Demo-Gäste wichtig, wenig Aufwand. Karte U-06. |
| IB-13 | 2026-11-24 | bot-A | **Schwierigkeit nach Spielerzahl:** Sterne und Events skalieren bereits mit der Spielerzahl. Zusätzlich Option „Entspannt / Normal / Knifflig“ im Menü (Zeitlimit, Sternschnuppenhäufigkeit, Sternbildlänge). | später | bot-A: nach IB-08 und G-07 sinnvoll. |
| IB-14 | 2026-11-24 | bot-A | **Spiel gegen Langeweile bei Wiederholung:** Pro Nacht zufällige Variante (Mondphase ändert Himmelsfarbe, andere Sternpositionen aus 3 Layouts, andere Deko). | später | bot-A: World hat Positionslisten; Aufwand mittel. |
| IB-15 | 2026-11-24 | bot-A | **Auf keinen Fall:** Tägliche Pflicht-Logins, Staub-Wartezeiten, Zufalls-Beute-Kisten, Ranglisten. Widerspricht dem Ziel „kein Grind, kein Druck“. | abgelehnt | bot-A: bewusst ausgeschlossen, damit künftige Vorschläge nicht in diese Richtung gehen. |
| IB-16 | 2026-11-24 | Jan | Tod: Respawn nach 60 s und 10 % Staubverlust. | umsetzen | bot-A: mit Wiederbeleben durch Mitspieler (verkürzt die Wartezeit), weil reine Wartestrafen laut Recherche frustrieren. Karte G-20. |
| IB-17 | 2026-11-24 | Jan | Essen: zweite Leiste, sinkt mit Bewegung und Putzen; Früchte finden; Küche mit Rezepten. | umsetzen | bot-A: Hunger als Bonus statt Zwang (Valheim-Prinzip), leer = keine Regeneration, kein Tod. Karten G-21, G-22, G-23. |
| IB-18 | 2026-11-24 | Jan | Weitere Rollen: Koch (größere Food-Leiste, bessere Rezepte), Kletterer/Leiterbauer (braucht mehr Essen). Spinnenangst war nur Beispiel. | umsetzen | bot-A: Karte G-24; jede Rolle bekommt einen Team-Nutzen (DRG-Prinzip). |
| IB-19 | 2026-11-24 | Jan | XP-System mit Fähigkeiten-Upgrades. | umsetzen | bot-A: Karte G-26, Baum allgemein + je Rolle 3 Fähigkeiten, sichtbare Wirkung statt kleiner Prozente. |
| IB-20 | 2026-11-24 | Jan | Host kann speichern und Spielstand laden. | umsetzen | bot-A: Karte G-27. |
| IB-21 | 2026-11-24 | Jan | Werkstatt: Putz-Utensilien nacheinander freischalten, jedes teurer, je Utensil eigene Upgrades. | umsetzen | bot-A: Karte G-25 (ersetzt IB-11). |
| IB-22 | 2026-11-24 | Jan | Prozeduraler Kartenaufbau. | umsetzen | bot-A: Karte G-31 (Seed, Mindestabstände, Seed im Speicherstand). |
| IB-23 | 2026-11-24 | Jan | Orte (POI) mit Vorteilen. | umsetzen | bot-A: Karte G-30 (Brunnen, Obstgarten, Aussichtsturm, Schrein, Küche), Besitzer C. |
| IB-24 | 2026-11-24 | Jan | Gegner: Spinnen, Wollmäuse; manche wegputzbar, manche nur mit Staubsauger, manche nur in der Gruppe. | umsetzen | bot-A: Karten G-28 (Wollmaus, Spinne) und G-29 (Rußwolke, nur im Team). |
| IB-25 | 2026-11-24 | Brainstorm-Agent | Friedensvertrag: Schubsen ohne Schaden als Standard, „Rauflust“ optional. | umsetzen | bot-A: Recherche zeigt, dass Griefing Koop-Spieler vertreibt. Karte G-32, Besitzer C. |
| IB-26 | 2026-11-24 | Brainstorm-Agent | Minimap-Ping für die größere Karte. | umsetzen | bot-A: Karte G-33, Besitzer C. |
| IB-27 | 2026-11-24 | Brainstorm-Agent | Benommen-Beutel: Beim Tod fällt der verlorene Staub als Beutel, wer ihn holt, bekommt ihn. | später | bot-A: gute Ergänzung zu G-20, erst nach G-20. |
| IB-28 | 2026-11-24 | Brainstorm-Agent | Wedel nutzt sich ab, Reparatur an der Werkbank oder durch Mitspieler. | abgelehnt | bot-A: Wartungslast; Recherche (Valheim) rät ab. |
| IB-29 | 2026-11-24 | Brainstorm-Agent | Lava-Gezeiten: Gefahrenzonen wandern mit der Nachtphase, Sterne darin geben +50 %. | später | bot-A: nach G-31 (prozedurale Insel). |
| IB-30 | 2026-11-24 | Brainstorm-Agent | Ballon mit Brenner, Gas und Ballast; Wind treibt ab. | später | bot-A: Ballon ist seit I-11 lenkbar; Gas/Wind nach der Demo. |
| IB-31 | 2026-11-24 | Brainstorm-Agent | Frostflecken auf hohen Sternen, nur mit Upgrade oder zu zweit entfernbar. | später | bot-A: passt zu G-25/G-29. |
| IB-32 | 2026-11-24 | Brainstorm-Agent | Team-Kombo zusätzlich zur eigenen Kombo; Schubser bricht sie. | später | bot-A: nach G-32. |
| IB-33 | 2026-11-24 | bot-A (Recherche) | Putzen muss sofort sichtbar wirken; Tiefe über Schmutzschichten und Werkzeuge, nicht über Zeitdruck (PowerWash Simulator). Zen-Preset ohne Zeitlimit beibehalten. | umsetzen | bot-A: fließt in G-25 (Utensilien je Schmutzschicht) ein. |
| IB-34 | 2026-11-24 | bot-A (Recherche) | Nahe Katastrophen erzeugen die besten Koop-Momente (PEAK): einen fallenden Mitspieler auffangen, Leiter halten, Wiederbeleben. | umsetzen | bot-A: in G-20 (Wiederbeleben) und G-24 (Leiter) eingeplant. |

## Recherche: Was macht Spaß, wo liegt der Grind, was mögen Spieler nicht (2026-11-24, bot-A)

**Spaß:** Sofort sichtbares Ergebnis beim Putzen; Tiefe durch verschiedene Schmutzschichten und Werkzeuge statt durch Zeitdruck ([Kotaku, PowerWash Simulator](https://kotaku.com/powerwash-sim-devs-on-making-cleaning-fun-advanced-cro-1847319502)). Rollen, bei denen dem Team etwas fehlt, wenn eine fehlt; gleiche Bedeutung für Neulinge und Profis; reines PvE hält das Spiel freundlich ([Game Rant, Deep Rock Galactic](https://gamerant.com/deep-rock-galactic-interview-season-1-co-op-design-battle-pass-progression/)). Eine gemeinsame Ausdauer-/Essensleiste zwingt zur Absprache; Beinahe-Katastrophen und Rettungen sind die Höhepunkte ([Co-Optimus, PEAK](https://www.co-optimus.com/blog/article-poster/3381/five-dollars-one-mountain-and-a-masterclass-in-co-op.html)).

**Grind, der akzeptiert wird:** Freischalten neuer Werkzeuge mit spürbar anderem Spielgefühl, Fähigkeiten mit sichtbarer Wirkung, Kochen als Vorbereitung für Buffs. Valheim: Essen bringt nur Vorteile, drei Essensplätze steuern Leben und Ausdauer, kein Durst ([PC Gamer, Valheim](https://www.pcgamer.com/valheim-is-better-because-it-rejects-boring-survival-systems)).

**Was Spieler nicht mögen:** Hunger, der ständig nervt oder zu schnell tötet; Leisten, die direkt nach dem Essen wieder fallen; Wartungs-Pflichten ohne Tiefe ([PC Gamer, Hunger und Durst](https://pcgamer.com/how-survival-games-get-hunger-and-thirst-wrong-and-how-to-fix-it)). Tod aus dem Nichts; Strafen ohne Gegenmittel; Griefing durch Mitspieler im Koop.

**Folgerungen für StarScrubber:** Essen als Bonus (G-21), Tod mit Wiederbelebung (G-20), Friedensvertrag als Standard (G-32), Werkzeuge pro Schmutzschicht (G-25), jede Rolle mit Team-Nutzen (G-24). Roadmap: TASKS/INDEX.md, Karten G-20 bis G-33 und GitHub-Issues.
