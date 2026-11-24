# Sternenhausmeister – Plan und Stand

Engine: Godot 4.3 (GDScript). Ziel: Windows-Demo, 3D, Koop für mind. 4 Spieler (LAN/IP), Installer.
Godot-Binary lokal: /home/claude/tools/Godot_v4.3-stable_linux.x86_64

## Aufgaben (nach Limit-Reset hier weitermachen)
- [x] Block 1: Putz-Prototyp solo (Bewegung, Wischen, Partikel, Ton, 3 Sterne) – Selbsttest `-- --selftest` ist grün
- [ ] Block 2: Netzwerk-Skelett, bis 4 Spieler, Host/Join per IP, serverautoritativer Himmel
- [ ] Block 3: Spielschleife (Nacht-Timer, Sternbild-Rätsel, Sternenstaub, Shop, Skalierung nach Spielerzahl)
- [ ] Block 4: Windows-Export + Installer (NSIS)
- [ ] Block 5: Politur (Menü, Einstellungen, Zen-Modus, Fehlerbehebung)

## Notizen
- Test ohne GPU: `xvfb-run ... godot --rendering-method gl_compatibility --rendering-driver opengl3 --write-movie /tmp/shots/f.png --quit-after 45`
- Logik-Selbsttest: `godot --headless --quit-after 60 -- --selftest`
- Offen: Renderer (Forward+ braucht Vulkan, Compatibility läuft auf mehr PCs) – vor Release entscheiden.
- Feel (Putzen) kann nur der Nutzer beurteilen.

## Zusammenarbeit (3 Personen)
- Person A: alles Demo-Pflichtige (CORE, NET, Spielschleife G-01..G-05/G-08, Menü/HUD U-01..U-03, Export/Installer B-01/B-02) · Person B: Zusatz (G-06, G-07, G-09, G-10, U-04, C-04) · Person C: Zusatz (A-01..A-05, S-01..S-03, B-03, D-02). Fällt B oder C aus, übernimmt A deren Aufgaben per `next A`.
- Pro Aufgabe ein Branch `task/<ID>/<wer>`, Pull Request mit Test-/Screenshot-Beleg, A integriert in main.
- Konfliktstellen: main.gd/world.gd, player.gd, star.gd, project.godot (Autoloads). Erst C-01 und C-02 mergen, dann branchen die anderen davon ab.
- Automatik-Bot (geplante Aufgabe) nur auf EINER Maschine/Konto laufen lassen, sonst doppelte Arbeit.
- C-01, C-02 erledigt: main.gd aufgeteilt (NightSky, World, Hud), GameState-Autoload mit Selbsttest. Als Nächstes für A: C-03, N-01.
- G-06 (bot-A): Schmutztypen Ruß/Flecken/Patina (star.gd) + Werkzeuge Sauger/Tuch/Polierpad (tools.gd, `CleanTool`); falsches Werkzeug wirkt zu 34 %. 🟢 Test: richtiges Werkzeug 1 Zug, falsches 3 Züge (`CleanTool.selftest`, per `godot --headless --path . -s <Runner>` mit `await`, noch nicht in run_tests.sh eingehängt, da main.gd/run_tests.sh nicht zur Karte gehören). ❌ Werkzeugwechsel im Spiel (Eingabe/HUD) fehlt noch; `wipe()` ohne Werkzeug verhält sich wie vorher.
- B-01 (bot-A): Windows-Export-Preset + `tools/build_windows.sh` -> build/Sternenhausmeister.exe + .pck. 🟢 Export läuft headless durch (exe 84 MB, pck 41 KB). ❌ Start unter Windows ungetestet (Mensch: exe + pck zusammen auf Windows starten).
