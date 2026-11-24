# Aufgabenübersicht (generiert von tools/tasks.py)

| ID | Besitzer | Prio | Bereich | Titel | Größe | Status | Abhängig von |
|---|---|---|---|---|---|---|---|
| [P-001](P-001.md) | A | done | CORE | Spieler: Bewegung, Kamera, Staubwedel | M | done | – |
| [P-002](P-002.md) | A | done | CORE | Stern mit Schmutzflecken und Wisch-Logik | M | done | – |
| [P-003](P-003.md) | A | done | AUDIO | Ton-Generator (Sfx) und Pentatonik beim Putzen | S | done | – |
| [C-01](C-01.md) | A | must | CORE | main.gd in Module aufteilen | M | done | P-001, P-002 |
| [C-02](C-02.md) | A | must | CORE | Autoload GameState | S | done | C-01 |
| [C-03](C-03.md) | A | must | CORE | Autoload Settings mit Speichern | S | done | C-01 |
| [C-04](C-04.md) | B | nice | CORE | Tasten umbelegen und Gamepad | S | open | C-03 |
| [N-01](N-01.md) | A | must | NET | NetworkManager: Host/Join per ENet (bis 4+) | M | done | C-02 |
| [N-02](N-02.md) | A | must | NET | Spieler-Spawner und Positions-Sync | M | done | N-01, P-001 |
| [N-03](N-03.md) | A | must | NET | Stern-Zustand serverautoritativ synchronisieren | M | done | N-01 |
| [N-04](N-04.md) | A | must | NET | Lokales 4-Instanzen-Testskript | S | done | N-01 |
| [N-05](N-05.md) | A | must | NET | Disconnect/Rejoin und Drohnen-Ersatz | M | done | N-02 |
| [N-06](N-06.md) | A | must | NET | Internet-Anleitung und optional UPnP | S | done | N-01 |
| [G-01](G-01.md) | A | must | GAME | Nacht-Timer mit Dämmerung/Mitternacht/Morgenrot | S | done | C-02 |
| [G-02](G-02.md) | A | must | GAME | Sternbild-Datenformat und 3 Beispiele | S | done | P-002 |
| [G-03](G-03.md) | A | must | GAME | Sternbild-Rätsel-Logik | M | done | G-02 |
| [G-04](G-04.md) | A | must | GAME | Sternenstaub-Währung | S | done | C-02 |
| [G-05](G-05.md) | A | must | GAME | Shop und Upgrades | M | done | G-04, U-02 |
| [G-06](G-06.md) | B | nice | GAME | Schmutztypen mit passendem Werkzeug | M | done | P-002 |
| [G-07](G-07.md) | B | nice | GAME | Wetter-Events: Wolken und Sternschnuppen | M | open | G-01 |
| [G-08](G-08.md) | A | must | GAME | Skalierung nach Spielerzahl | S | done | C-02, N-02 |
| [G-09](G-09.md) | B | nice | GAME | Regel-Presets (Zen, Kinder, Standard) | S | open | G-01 |
| [G-10](G-10.md) | B | nice | GAME | Ballon/Leiter zum Erreichen hoher Sterne | M | done | P-001 |
| [A-01](A-01.md) | C | nice | ART | Toon-Shader mit Rim-Light | M | done | P-001 |
| [A-02](A-02.md) | C | nice | ART | 4 Spielerfarben und Namensschilder | S | open | N-02 |
| [A-03](A-03.md) | C | nice | ART | Low-Poly-Props: Ballon, Leiter, Werkstatt | M | done | P-001 |
| [A-04](A-04.md) | C | nice | ART | Himmel: Verlauf, Nebel, Wolkeninsel | S | done | P-001 |
| [A-05](A-05.md) | C | nice | ART | Partikel: Staub und Funkeln beim Sauberwerden | S | done | P-002 |
| [S-01](S-01.md) | C | nice | AUDIO | Lo-Fi-Musikschleife | S | done | P-003 |
| [S-02](S-02.md) | C | nice | AUDIO | Sternakkorde und Sternbild-Melodien | M | done | P-003, G-02 |
| [S-03](S-03.md) | C | nice | AUDIO | UI- und Ambient-Sounds | S | open | U-01 |
| [U-01](U-01.md) | A | must | UI | Hauptmenü (Start, Host, Join, Einstellungen, Beenden) | M | done | C-03 |
| [U-02](U-02.md) | A | must | UI | HUD: Staub, Timer, Spielerliste | S | done | C-02 |
| [U-03](U-03.md) | A | must | UI | Pause- und Einstellungsmenü | S | done | C-03, U-01 |
| [U-04](U-04.md) | B | nice | UI | Barrierefreiheit: Untertitel, Farbenblind, UI-Skalierung | M | open | U-03 |
| [B-01](B-01.md) | A | must | BUILD | Windows-Export-Preset und Skript | S | done | P-001 |
| [B-02](B-02.md) | A | must | BUILD | NSIS-Installer-Skript | M | done | B-01 |
| [B-03](B-03.md) | C | nice | BUILD | CI-Workflow (Tests und Export) | M | done | B-01 |
| [B-04](B-04.md) | A | done | BUILD | Test-Runner für alle Selbsttests | S | done | P-002 |
| [D-01](D-01.md) | A | done | DOC | README, CONTRIBUTING, Stilregeln | S | done | – |
| [D-02](D-02.md) | C | nice | DOC | Playtest-Checkliste | S | done | P-002 |
| [A-06](A-06.md) | C | nice | ART | Styleguide und Farbpalette (Midnight Toy Garden) | S | done | A-01 |
| [A-17](A-17.md) | C | nice | ART | Asset-Katalog mit Produktionsdaten | S | done | A-06 |
| [A-07](A-07.md) | C | nice | ART | Himmelsphasen: Dämmerung, Mitternacht, Morgenrot | S | done | A-06, A-04 |
| [A-08](A-08.md) | C | nice | ART | Spieler-Look: Körper, Gliedmaßen, 4 Varianten mit Symbolen | M | done | A-06 |
| [A-09](A-09.md) | C | nice | ART | Werkzeug-Modelle: Wedel, Sauger, Tuch, Polierpad | M | done | A-06 |
| [A-10](A-10.md) | C | nice | ART | Schmutz-Texturen: Ruß, Flecken, Patina (Form statt nur Farbe) | M | done | A-06 |
| [A-11](A-11.md) | C | nice | ART | Stern-Look: Reinigungsübergang schmutzig zu golden | M | done | A-06, A-10, A-01 |
| [A-12](A-12.md) | C | nice | ART | Insel-Assets: Gras, Felsen, Büsche, Laternen, Schild | M | done | A-06, A-03 |
| [A-13](A-13.md) | C | nice | ART | Sternbild-Linien: handgezeichnet, golden, pulsierend | S | done | A-06 |
| [A-14](A-14.md) | C | nice | ART | Himmelseffekte: weiche Wolken und Sternschnuppe | S | done | A-07 |
| [A-15](A-15.md) | C | nice | ART | UI-Theme und Icons (Notizbuch-Look) | M | done | A-06 |
| [A-16](A-16.md) | C | nice | ART | Logo als SVG und Hauptmenü-Hintergrund | S | done | A-15 |
| [I-01](I-01.md) | A | must | UI | Integration: Menü, Pause, Shop in main.gd | S | done | U-01, U-03, G-05 |
| [I-02](I-02.md) | A | must | CORE | Integration: Spielerfigur, Werkzeug und Shop-Werte in player.gd | S | done | I-01, A-08, A-09 |
| [I-03](I-03.md) | A | must | ART | Integration: Sternlook, Insel-Props und Staub-Effekt in world.gd/star.gd | S | done | I-01, A-11, A-12, A-05 |
| [I-04](I-04.md) | A | must | GAME | Integration: Sternbild-Rätsel mit Linien in world.gd/star.gd | M | done | I-03, G-03, A-13 |
| [I-05](I-05.md) | A | must | UI | HUD: Sternbild-Fortschritt und Hinweise | S | done | I-04 |
| [I-06](I-06.md) | A | must | GAME | Ballon in die Welt einbauen | S | done | I-03, G-10 |
