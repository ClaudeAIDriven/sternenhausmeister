# Asset-Katalog (Midnight Toy Garden)

Spalten: Phase (1 Fundament, 2 Identität, 3 Gameplay, 4 Politur) · Format · Auflösung · Transp. (Transparenz) · Kachel (seamless) · Prio (must/nice) · Karte · Godot-Hinweis · Stand (✅ vorhanden · 🟡 teilweise · ❌ fehlt). Farben und Regeln: `docs/STYLEGUIDE.md`, `palette.gd`.
Alle Assets entstehen als eigene Arbeit (meist per Code erzeugt), Quellen in `docs/CREDITS.md`.

## Phase 1: Visuelles Fundament
| Asset | Zweck | Format | Auflösung | Transp. | Kachel | Prio | Karte | Godot-Hinweis | Stand |
|---|---|---|---|---|---|---|---|---|---|
| Himmelsverlauf | Hintergrund | ProceduralSky | – | nein | – | must | A-04, A-07 | `ProceduralSkyMaterial`, Compatibility-tauglich, Debanding an | ✅ |
| Hintergrundsterne | Atmosphäre, wenige | MultiMesh | – | nein | – | must | A-04 | 1 Draw Call, ca. 350 Stück; nicht mehr, damit Spielsterne auffallen | ✅ |
| Inselgrundkörper | Spielfläche | Mesh (Code/GLB) | – | nein | – | must | world.gd | flache Kuppel, StaticBody | 🟡 |
| Inselboden-Textur | Boden, handgemalt | PNG | 256x256 | nein | ja | must | A-12 | `texture_repeat`, Filter linear | ❌ |
| Spieler-Basismodell | Figur | GLB/Code | – | nein | – | must | A-08 | Capsule, Augen, Arme/Beine, 1 Material je Spieler | 🟡 |
| Staubwedel | Standardwerkzeug | GLB/Code | – | nein | – | must | A-09 | Griff + Federbüschel | 🟡 |
| Stern-Basismodell | zentrales Spielobjekt | Mesh | – | nein | – | must | A-11 | unregelmäßige Kugel, 1 Mesh für alle Zustände | 🟡 |
| Schmutz-Material | 0 % Zustand | Shader/Material | – | nein | – | must | A-10, A-11 | Matt, `Palette.DIRT_GRAY` | 🟡 |
| Sauber-Material | 100 % Zustand | Shader/Material | – | nein | – | must | A-11 | Emission gold `Palette.STAR_GOLD` | 🟡 |
| Schmutzmaske | steuert Reinigung | Textur | 256x256 | ja (Alpha) | nein | must | A-10 | Kanal pro Schmutztyp möglich | ❌ |
| Reinigungsübergang | Moment 0 % → 100 % | Shader | – | nein | – | must | A-11 | Parameter `clean` 0..1, nur einfache Eingaben | ❌ |
| Funkel-Burst | Abschluss | CPUParticles3D | – | ja | – | must | A-05 | One-shot, 60 Teilchen, räumt sich selbst auf | ✅ |
| Toon-Shader | einheitlicher Look | gdshader | – | nein | – | must | A-01 | `diffuse_toon`, 2–3 Stufen, Rim | ✅ |

## Phase 2: Spielidentität
| Asset | Zweck | Format | Auflösung | Transp. | Kachel | Prio | Karte | Godot-Hinweis | Stand |
|---|---|---|---|---|---|---|---|---|---|
| Spielerfarben (4 Varianten) | Unterscheidung | Material | – | nein | – | must | A-06, A-08 | `Palette.player_color(i, cvd)` | 🟡 |
| Spielersymbole + Fußring | Farbenblind | Code/PNG | 64x64 | ja | – | must | A-08, A-15 | Kreis/Quadrat/Dreieck/Raute | ❌ |
| Werkstatt | Shop-Ort | Mesh | – | nein | – | must | A-03 | Fenster mit Emission, warmes OmniLight | 🟡 |
| Werkstatt-Schild | Orientierung | Mesh/Text | – | nein | – | nice | A-12 | Label3D, Font siehe CREDITS | ❌ |
| Leiter | nach oben | Mesh | – | nein | – | must | A-03 | Kollision/Klettern fehlt | 🟡 |
| Sternbild-Linien | Fortschritt sichtbar | Mesh/Shader | – | ja | – | must | A-13 | dünne Quads, Knotenpunkte, Puls per Shader | ❌ |
| HUD-Theme | Notizbuch-Look | Theme (Code) | – | – | – | must | A-15 | StyleBoxFlat, abgerundet, Schriftgrößen 20–24 | ❌ |
| Logo | Identität | SVG | skalierbar | ja | – | must | A-16 | als `Texture2D` importiert | ❌ |
| Sternenstaub-Icon | Währung | PNG/Code | 32–128 | ja | – | must | A-15 | 3 Facetten + Schweif, bei 32 px lesbar | ❌ |
| Zeit-/Phasen-Icons | HUD | PNG/Code | 64x64 | ja | – | must | A-15 | Dämmerung/Mitternacht/Morgenrot | ❌ |
| Fortschrittsbalken, Buttons | HUD | Theme | – | – | – | must | A-15 | StyleBox, 9-Slice möglich | ❌ |

## Phase 3: Gameplay-Erweiterungen
| Asset | Zweck | Format | Auflösung | Transp. | Kachel | Prio | Karte | Godot-Hinweis | Stand |
|---|---|---|---|---|---|---|---|---|---|
| Sternensauger | Werkzeug | Mesh | – | nein | – | nice | A-09 | Leuchtring (Emission), Einsaugpartikel | 🟡 |
| Reinigungstuch | Werkzeug | Mesh | – | nein | – | nice | A-09 | weiche Falten per Mesh | ❌ |
| Polierpad | Werkzeug | Mesh | – | nein | – | nice | A-09 | goldenes Zentrum, Glanzring beim Einsatz | ❌ |
| Ballon + Gondel | Höhe erreichen | Mesh | – | nein | – | nice | A-03, G-10 | `Balloon` + `Props.balloon()` | ✅ |
| Ruß-Overlay | Schmutztyp 1: runde ausgefranste Flecken | Textur | 256x256 | ja | nein | nice | A-10 | zusätzlich Form statt nur Farbe | ❌ |
| Flecken-Overlay | Schmutztyp 2: Ringe, Tropfen | Textur | 256x256 | ja | nein | nice | A-10 | | ❌ |
| Patina-Overlay | Schmutztyp 3: kantig, verzweigt | Textur | 256x256 | ja | nein | nice | A-10 | | ❌ |
| Wolken | Wetter | Mesh/Quad | – | ja | – | nice | A-14 | weich, rund, langsam, `reduced_motion` | 🟡 |
| Sternschnuppe | Wetter-Event | Partikel/Quad | – | ja | – | nice | A-14 | kurzer Streifen mit Schweif | ❌ |
| Putzstaub | Feedback | CPUParticles3D | – | ja | – | nice | A-05 | Wedeln nach außen, Saugen zur Düse | 🟡 |

## Phase 4: Politur
| Asset | Zweck | Format | Auflösung | Transp. | Kachel | Prio | Karte | Godot-Hinweis | Stand |
|---|---|---|---|---|---|---|---|---|---|
| Gras, Steine, Büsche, Laternen | Insel-Deko | Mesh (wiederverwendet) | – | nein | – | nice | A-12 | MultiMesh für Gras/Steine | ❌ |
| Tageszeit-Übergänge | Stimmung | Code | – | – | – | nice | A-07 | Tween über Himmels-/Lichtfarben | ❌ |
| Werkstatt-Upgrades (sichtbar) | Belohnung | Mesh | – | nein | – | nice | – | Folgekarte nötig | ❌ |
| Weitere Sternbilder (Fuchs, Wal, Teekessel, Drache, Segelboot) | Vielfalt | JSON + Symbol | 64x64 | ja | – | nice | G-02 | Daten in `data/`, Icons A-15 | 🟡 |
| Zusätzliche Animationen, erweiterte Partikel | Politur | Code | – | – | – | nice | – | Folgekarten | ❌ |

## Hinweise
- Compatibility-Renderer: keine Reflexionen, wenige Lichter, Schatten nur für wichtige Objekte, Transparenz sparsam. Billigere Ersatzlösung nennen, wenn ein Effekt nicht geht.
- Kachelbare Texturen immer mit Randpixel-Test prüfen, nicht nur ansehen.
- Echte handgemalte Texturen (Bildgenerator oder Malerei) sind noch nicht erstellt: alles hier ist prozedural; Stil kann ein Mensch später mit gemalten Texturen derselben Auflösung ersetzen.

## Stand nach Karten A-06 bis A-17 (aktualisiert)
Die Stand-Spalte oben stammt aus der Planung. Tatsächlich gebaut (alles als eigene, prozedurale Arbeit; Einbau ins Spiel fehlt überall noch, weil die Spielskripte nicht zu den Karten gehörten):

| Karte | Datei(en) | Was es ist | Eingebaut im Spiel |
|---|---|---|---|
| A-06 | `palette.gd`, `docs/STYLEGUIDE.md` | Farben, Farbenblind-Palette, Messung | nein |
| A-07 | `sky.gd` | Himmelsphasen mit Tween, Mond (Dämmerung/Mitternacht/Morgenrot) | ja (NightSky wird schon benutzt) |
| A-08 | `player_look.gd` | 4 Spieler mit Symbol, Zubehör, Fußring | nein (player.gd) |
| A-09 | `tool_models.gd` | Wedel, Sauger, Tuch, Polierpad | nein |
| A-10 | `dirt_textures.gd` | Overlays Ruß/Flecken/Patina, Schmutzmaske | nein |
| A-11 | `shaders/star_clean.gdshader`, `star_look.gd` | Stern mit Reinigungsübergang 0..100 % | nein (star.gd) |
| A-12 | `island_props.gd` | Boden (kachelbar), Gras, Steine, Büsche, Laterne, Schild | nein (world.gd) |
| A-13 | `constellation_lines.gd` | Sternbild-Linien, Puls, Fertig-Burst | nein |
| A-14 | `sky_fx.gd` | Wolken, Sternschnuppe, `reduced_motion` | nein |
| A-15 | `ui_theme.gd`, `ui_icons.gd` | Theme, 10 Icons, 4 Spielersymbole | nein (hud.gd) |
| A-16 | `assets/ui/logo.svg`, `menu_backdrop.gd` | Logo, Menü-Hintergrund | nein |

Noch offen aus dem Art-Prompt: Anbindung aller obigen Teile an die Spielskripte (Folgekarten nötig), echte handgemalte Texturen, Schrift (Nunito/Fredoka mit Lizenz), Shop-/Einstellungs-/Sternbild-Übersicht-Oberfläche, Animationen der Figuren und Werkzeuge, Werkstatt-Upgrades, weitere Sternbild-Motive, Test auf echter GPU und mit Betroffenen (Farbenblindheit).
