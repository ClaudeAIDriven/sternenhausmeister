# Aufgabenübersicht (generiert von tools/tasks.py)

| ID | Bereich | Titel | Größe | Status | Abhängig von |
|---|---|---|---|---|---|
| [P-001](P-001.md) | CORE | Spieler: Bewegung, Kamera, Staubwedel | M | done | – |
| [P-002](P-002.md) | CORE | Stern mit Schmutzflecken und Wisch-Logik | M | done | – |
| [P-003](P-003.md) | AUDIO | Ton-Generator (Sfx) und Pentatonik beim Putzen | S | done | – |
| [C-01](C-01.md) | CORE | main.gd in Module aufteilen | M | open | P-001, P-002 |
| [C-02](C-02.md) | CORE | Autoload GameState | S | open | C-01 |
| [C-03](C-03.md) | CORE | Autoload Settings mit Speichern | S | open | C-01 |
| [C-04](C-04.md) | CORE | Tasten umbelegen und Gamepad | S | open | C-03 |
| [N-01](N-01.md) | NET | NetworkManager: Host/Join per ENet (bis 4+) | M | open | C-02 |
| [N-02](N-02.md) | NET | Spieler-Spawner und Positions-Sync | M | open | N-01, P-001 |
| [N-03](N-03.md) | NET | Stern-Zustand serverautoritativ synchronisieren | M | open | N-01 |
| [N-04](N-04.md) | NET | Lokales 4-Instanzen-Testskript | S | open | N-01 |
| [N-05](N-05.md) | NET | Disconnect/Rejoin und Drohnen-Ersatz | M | open | N-02 |
| [N-06](N-06.md) | NET | Internet-Anleitung und optional UPnP | S | open | N-01 |
| [G-01](G-01.md) | GAME | Nacht-Timer mit Dämmerung/Mitternacht/Morgenrot | S | open | C-02 |
| [G-02](G-02.md) | GAME | Sternbild-Datenformat und 3 Beispiele | S | open | P-002 |
| [G-03](G-03.md) | GAME | Sternbild-Rätsel-Logik | M | open | G-02 |
| [G-04](G-04.md) | GAME | Sternenstaub-Währung | S | open | C-02 |
| [G-05](G-05.md) | GAME | Shop und Upgrades | M | open | G-04, U-02 |
| [G-06](G-06.md) | GAME | Schmutztypen mit passendem Werkzeug | M | open | P-002 |
| [G-07](G-07.md) | GAME | Wetter-Events: Wolken und Sternschnuppen | M | open | G-01 |
| [G-08](G-08.md) | GAME | Skalierung nach Spielerzahl | S | open | C-02, N-02 |
| [G-09](G-09.md) | GAME | Regel-Presets (Zen, Kinder, Standard) | S | open | G-01 |
| [G-10](G-10.md) | GAME | Ballon/Leiter zum Erreichen hoher Sterne | M | open | P-001 |
| [A-01](A-01.md) | ART | Toon-Shader mit Rim-Light | M | open | P-001 |
| [A-02](A-02.md) | ART | 4 Spielerfarben und Namensschilder | S | open | N-02 |
| [A-03](A-03.md) | ART | Low-Poly-Props: Ballon, Leiter, Werkstatt | M | open | P-001 |
| [A-04](A-04.md) | ART | Himmel: Verlauf, Nebel, Wolkeninsel | S | open | P-001 |
| [A-05](A-05.md) | ART | Partikel: Staub und Funkeln beim Sauberwerden | S | open | P-002 |
| [S-01](S-01.md) | AUDIO | Lo-Fi-Musikschleife | S | open | P-003 |
| [S-02](S-02.md) | AUDIO | Sternakkorde und Sternbild-Melodien | M | open | P-003, G-02 |
| [S-03](S-03.md) | AUDIO | UI- und Ambient-Sounds | S | open | U-01 |
| [U-01](U-01.md) | UI | Hauptmenü (Start, Host, Join, Einstellungen, Beenden) | M | open | C-03 |
| [U-02](U-02.md) | UI | HUD: Staub, Timer, Spielerliste | S | open | C-02 |
| [U-03](U-03.md) | UI | Pause- und Einstellungsmenü | S | open | C-03, U-01 |
| [U-04](U-04.md) | UI | Barrierefreiheit: Untertitel, Farbenblind, UI-Skalierung | M | open | U-03 |
| [B-01](B-01.md) | BUILD | Windows-Export-Preset und Skript | S | open | P-001 |
| [B-02](B-02.md) | BUILD | NSIS-Installer-Skript | M | open | B-01 |
| [B-03](B-03.md) | BUILD | CI-Workflow (Tests und Export) | M | open | B-01 |
| [B-04](B-04.md) | BUILD | Test-Runner für alle Selbsttests | S | done | P-002 |
| [D-01](D-01.md) | DOC | README, CONTRIBUTING, Stilregeln | S | done | – |
| [D-02](D-02.md) | DOC | Playtest-Checkliste | S | open | P-002 |
