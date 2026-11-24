# Playtest-Checkliste

Für Menschen: Spielgefühl beurteilt kein Modell. Pro Punkt ✅ / ❌ und eine Zeile Notiz. Bitte immer angeben: Build (Commit oder Setup.exe), PC (CPU/GPU/RAM), Spielerzahl, Dauer.

## 0. Vorbereitung
- [ ] `tools/run_tests.sh` ist grün (oder CI grün).
- [ ] Windows: `build/StarScrubber.exe` + `.pck` (oder Setup.exe) starten, Installation und Deinstallation prüfen (B-01/B-02 sind unter Windows noch ungetestet).
- [ ] Zum Vergleich: Kamera/Maus-Empfindlichkeit notieren.

## 1. Putz-Feel (allein)
- [ ] Linke Maustaste/E: Reagiert das Putzen sofort (< 0,2 s bis zum ersten sichtbaren Effekt)?
- [ ] Ziel ist immer klar: Man sieht, wohin der Wedel wischt (Fadenkreuz, Reichweite 9 m).
- [ ] Ein Stern ist in 20–60 s sauber. Zu kurz? Zu lang? Zeit notieren.
- [ ] Gefühl "Fortschritt": Der Stern wird sichtbar heller, während man putzt.
- [ ] Töne: Pentatonik-Töne passen, nerven nicht nach 5 Minuten. Stummschalten möglich?
- [ ] Schmutztypen (Ruß/Flecken/Patina) und Werkzeuge (Sauger/Tuch/Polierpad): Ist klar, welches Werkzeug wozu passt? Wirkt das falsche spürbar schwächer, aber nicht frustrierend (34 %)? Hinweis: Werkzeugwechsel im Spiel ist noch nicht eingebaut.
- [ ] Abschluss eines Sterns fühlt sich belohnend an (Leuchten, Ton, Funken).
- [ ] Ballon: Man erreicht Sterne in 12 m Höhe, Fahrt fühlt sich nicht zu langsam an. (Noch nicht in der Welt eingebaut.)

## 2. Bewegung und Kamera
- [ ] WASD, Springen, Maus: kein Ruckeln, keine Übelkeit.
- [ ] Kamera kollidiert nicht unangenehm mit der Insel.
- [ ] Maus einfangen (Klick) und loslassen (Esc) funktioniert.
- [ ] Herunterfallen vom Rand: Respawn ohne Frust.

## 3. Koop (2–4 Spieler)
- [ ] Host starten, bis zu 3 Clients treten bei (LAN, dann Internet). Dauer bis zum Beitritt notieren.
- [ ] Alle sehen sich gegenseitig ohne starkes Ruckeln (Positions-Sync).
- [ ] Zwei Spieler putzen denselben Stern: Fortschritt zählt für beide, kein Flackern.
- [ ] Sternzustand ist bei allen gleich (sauber/schmutzig).
- [ ] Spieler verlässt das Spiel und tritt wieder bei: Spiel läuft weiter.
- [ ] Mit 4 Spielern ist genug zu tun, mit 1 Spieler nicht unfair (Skalierung).
- [ ] Namen/Farben der Mitspieler sind unterscheidbar.

## 4. Spielschleife und Menü
- [ ] Nachtverlauf (Dämmerung, Mitternacht, Morgenrot): Zeitlimit wirkt sanft, kein harter Fail-State.
- [ ] HUD: Zeit, Phase, Sternenstaub, Sterne, Spielerliste gut lesbar auf 1280x720 und größer.
- [ ] Hauptmenü: Start, Host, Join, Einstellungen, Beenden. Fehlermeldung bei falscher IP verständlich.
- [ ] Einstellungen (Lautstärke, Maus, FOV, Name) bleiben nach Neustart erhalten.

## 5. Performance
- [ ] FPS auf einem schwachen PC (Ziel: stabil ≥ 30, besser 60). Werte: Szene leer / bei 4 Spielern / beim Putzen mit Partikeln.
- [ ] Compatibility-Renderer läuft ohne Darstellungsfehler (Himmel, Dunst, Partikel, Toon-Shader).
- [ ] Kein Speicherwachstum nach 30 Minuten (Task-Manager vor/nach).
- [ ] Ladezeit bis zum Spielstart < 10 s.
- [ ] Netzwerk: Ping/Latenz spürbar? Lag beim Putzen anderer Spieler?

## 6. Barrierefreiheit und Komfort
- [ ] Text ist lesbar (Kontrast, Größe). Farbenblind: Sterne und Schmutz unterscheidbar?
- [ ] Spiel ist auch in Pausen/AFK nicht bestrafend.

## 6b. Schnelltest für die Demo (10 Minuten, bitte zuerst)
Build: Release `latest`, `StarScrubber-Setup.exe`. Alles ungetestet unter Windows, bitte abhaken oder als Issue melden.
- [ ] Setup installiert, Spiel startet, Hauptmenü mit Logo „StarScrubber“ erscheint (Windows-Warnung „unbekannter Herausgeber“ ist erwartet).
- [ ] „Allein putzen“: Hinweise erscheinen (nur beim ersten Spiel), Stern wischen klappt, Staub steigt, an der Werkstatt öffnet F die Upgrades, Kauf funktioniert.
- [ ] Alle Sterne putzen, Sternbild in richtiger Reihenfolge: Linien leuchten, Bonus-Staub. Falsche Reihenfolge: Sterne werden wieder schmutzig.
- [ ] Esc: Pause mit Reglern und Barrierefreiheit-Panel; „Zum Hauptmenü“ geht.
- [ ] Zu zweit: Host „Raum eröffnen“, Adresse oben links, zweite Person tritt bei, beide sehen sich, Putzen und Kauf wirken bei beiden. Teamarbeit-Bonus erscheint, wenn beide denselben Stern putzen.
- [ ] Ton: Putzen klingt angenehm, nicht zu laut? (nie von einem Menschen gehört)
- [ ] Nachtende nach 10 Minuten (oder Zen/Kinder-Spielart): Zusammenfassung mit Sternchen.

## 7. Abschluss
Drei Dinge, die Spaß gemacht haben. Drei, die gestört haben. Würdest du eine zweite Nacht spielen? Bugs als GitHub-Issue mit Build, PC und Schritten.
