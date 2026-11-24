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
- C-03 erledigt: Settings-Autoload (speichern/laden, Test tests/test_settings.gd). PR offen.
- N-01, N-04 erledigt: NetworkManager (ENet, bis 4 Spieler, Spielerliste vom Host) + Test mit 4 lokalen Instanzen (tools/test_net4.sh) grün. Gestapelt auf C-03. Als Nächstes für A: N-02 (Spieler-Spawner), N-03, G-01..G-04, U-02.
- G-02 erledigt: Sternbild-Format (JSON) + Loader/Validierung, 3 Beispiele, Test grün. Gestapelt auf N-01.
- G-04 erledigt: Staub pro entferntem Fleck (1 Staub), GameState.dust, im Selbsttest geprüft. HUD-Anzeige folgt mit U-02. Gestapelt auf G-02.
- G-01 erledigt: Night (Dämmerung 0-20 %, Mitternacht 20-80 %, Morgenrot 80-100 %, dann Ende; kein Game Over; Standard 600 s), Test grün. Gestapelt auf G-04. Als Nächstes für A: U-02 (HUD mit Staub/Timer), N-02, N-03, G-03, U-01.
- U-02 erledigt: HUD zeigt Zeit/Phase, Staub, Sterne, Spielerliste (online). Test + Bild geprüft. Gestapelt auf G-01.
- N-02 erledigt: PlayerSpawner (MultiplayerSpawner, Name=Peer-ID=Autorität) + Positions-/Drehungs-Sync. Test tools/test_netplayers.sh grün (4 Instanzen, Host-Position kommt bei Clients an). Manuell testbar: godot -- --host bzw. -- --join <IP>. Gestapelt auf U-02. Als Nächstes für A: N-03 (Sterne synchronisieren), G-03, U-01, G-05, G-08.
