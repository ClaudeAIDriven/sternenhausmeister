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
- Person A: CORE + NET (kritischer Pfad, zuerst C-01, C-02) · Person B: GAME + UI · Person C: ART + AUDIO + BUILD + DOC
- Pro Aufgabe ein Branch `task/<ID>`, Pull Request mit Test-/Screenshot-Beleg, A integriert in main.
- Konfliktstellen: main.gd/world.gd, player.gd, star.gd, project.godot (Autoloads). Erst C-01 und C-02 mergen, dann branchen die anderen davon ab.
- Automatik-Bot (geplante Aufgabe) nur auf EINER Maschine/Konto laufen lassen, sonst doppelte Arbeit.
