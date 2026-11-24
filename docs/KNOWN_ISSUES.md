
## Netztest `tools/test_netplayers.sh` flackert (~1 von 10-25 Läufen)
Beobachtung (mit `NETP_DEBUG=1`): Ein Client ist verbunden (Status 2), sieht kurz Host+sich (2 Spieler), dann verschwinden
alle Spieler-Knoten lokal (n=0), obwohl der Host nichts despawnt hat. Tritt auch bei 0,4 s Abstand zwischen den Clients auf,
ist also kein reines Gleichzeitig-Beitreten. Ursache offen (Verdacht: Godot-4.3-Spawner-Race oder Frame-Stalls durch
Fehlerflut der Headless-Meshes). Nicht Teil von `run_tests.sh`. Für Demo: bei fehlenden Spielern Spiel neu beitreten.

## Ballon nur lokal (I-11)
Steigen, Sinken und Lenken rechnet jeder Rechner selbst. Online können Ballonpositionen auseinanderlaufen, wenn mehrere lenken. Lösung: Host-Autorität mit MultiplayerSynchronizer (vor G-31).

## Bewegung nach dem Umbenennen (Meldung Jan, 2026-11-24)
Nicht nachstellbar in Solo/Host unter Linux; siehe docs/HANDOFF.md.

## Finale (M-01 bis M-10): ehrliche Lücken
- 🟢 Mit Xvfb/llvmpipe gerendert und angesehen: Menü, HUD, Himmel, Sterne, Rußwolke. 🔴 Nie auf echter GPU/Windows gesehen: Schatten, SSAO, Glow-Stärke, Shader (Gras, Milchstraße, Polarlicht) sind nur im Compatibility-Renderer geprüft; Szene wirkt eher hell/blau.
- 🔴 Balance ist geschätzt: Staubpreise, XP-Kurve, Gegnerhäufigkeit, Bossleben, Wunschhäufigkeit, Trampolinhöhe.
- 🟡 Netz zu zweit nur per Headless-Tests (Sterne, Gegner, Früchte, Neu-Verschmutzen, Rätsel); Karten-/Seed-RPC, Mitspieler-XP-Speicherung, Anruf Spieler am Boden/Wiederbeleben, Ping, Rauflust sind nicht von Menschen getestet.
- 🟡 Hut-Auswahl (H) ist nur lokal sichtbar; Rollen-Hüte sind für alle sichtbar. Kein Erfolge-/Tagebuch-Menü (nur Meldungen und Datei).
- 🟢 (M-11 behoben) Fähigkeiten `ladder_time`/`climb` und XP fürs Wiederbeleben angebunden; `GameState.stars_cleaned` zählt jeden Stern pro Nacht einmal.
- 🟡 Spinnen/Wollmäuse sitzen auf Sternoberflächen (Wisch-Zielstrahl trifft nur Sterne); Rußwolke „verdunkelt" nur optisch durch dunkle Kugeln.
- Headless-Tests melden viele Zeilen „Parameter m is null" (Dummy-Renderer), harmlos.
