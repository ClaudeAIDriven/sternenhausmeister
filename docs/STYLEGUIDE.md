# Styleguide: Midnight Toy Garden

Verbindlich für alle Grafiken. Farben stehen in `palette.gd` (Klasse `Palette`), nicht doppelt im Code pflegen.

## Leitidee
"Eine kleine Insel. Eine große Nacht. Und jede Menge Sterne, die ein bisschen Liebe gebrauchen können." Low-Poly-Spielzeugwelt, handgemalte Kinderbuchästhetik, Miniatur-Diorama bei Nacht, dezent magisch.

## Stilregeln
- Low-Poly, runde weiche Formen, klare Silhouetten.
- 2 bis 3 Toon-Lichtstufen (`shaders/toon.gdshader`), dezentes Rim-Light.
- Flächige, handgemalte Texturen und Farbverläufe, keine Fototexturen, kein PBR.
- Warme goldene Akzente, wenige gezielte Partikel, keine Lens Flares, kein Cyberpunk, keine überladene Szene.
- Einheitlich: Proportionen, Lichtrichtung (Mondlicht von links oben, `rotation_degrees = (-50, 30, 0)`), Palette, Toon-Intensität, Materialgestaltung.
- Keine fremden Marken, Figuren oder geschützten Designs nachbauen.

## Palette
| Rolle | Hex | Konstante |
|---|---|---|
| Himmel Dämmerung | #566DAB | `SKY_DUSK` |
| Himmel Mitternacht | #202746 | `SKY_MIDNIGHT` |
| Himmel Morgenrot | #C17D91 | `SKY_DAWN` |
| Insel Blaugrau | #667D91 | `ISLAND` |
| Schmutz-Grau | #777B83 | `DIRT_GRAY` |
| Sternengold | #FFD477 | `STAR_GOLD` |
| UI-Elfenbein | #F4EEDC | `UI_IVORY` |
| Spieler 1 Blau | #2878B8 | `PLAYER_COLORS[0]` |
| Spieler 2 Orange | #E69F00 | `PLAYER_COLORS[1]` |
| Spieler 3 Violett | #9B78C8 | `PLAYER_COLORS[2]` |
| Spieler 4 Türkisgrün | #009E73 | `PLAYER_COLORS[3]` |
| Ruß / Flecken / Patina | #2E3138 / #6F7F93 / #6E7550 | `DIRT_*` (abgeleitet, Vorschlag) |
| UI-Panel / Alt | #1B2140 / #3A2F63 | `UI_PANEL`, `UI_PANEL_ALT` (abgeleitet, Vorschlag) |

## Barrierefreiheit der Spielerfarben (gemessen)
Gemessen mit einer Viénot-Näherung in CIE-Lab (ΔE, größer = besser unterscheidbar; unter ca. 20 ist es schwierig):

| Paar | normal | Protanopie | Deuteranopie |
|---|---|---|---|
| Blau – Violett (S1–S3) | 32 | **5** | **13** |
| Blau – Türkis (S1–S4) | 70 | 57 | 54 |
| Orange – Türkis (S2–S4) | 89 | 52 | 66 |

Ergebnis: **Blau und Violett sind bei Rot-Grün-Schwäche praktisch nicht unterscheidbar.** Deshalb gilt:
1. Farbe allein reicht nie. Jeder Spieler hat zusätzlich Symbol (Kreis, Quadrat, Dreieck, Raute), Zubehör (keins, Mütze, Sternanhänger, Schal) und einen Fußring.
2. Im Farbenblind-Modus wird Spieler 3 heller (#D8B4F0, `PLAYER_COLORS_CVD`): ΔE zu Blau 28 (prot) / 38 (deut).
3. Schmutz wird über Form unterschieden: Ruß = runde ausgefranste Flecken, Flecken = Ringe und Tropfen, Patina = kantige verzweigte Risse.

Grenzen: Die Simulation ist eine Näherung, kein Ersatz für Tests mit Betroffenen. Tritanopie wurde nicht ausgewertet.

## Texturen und Formate
- Boden/Umgebung 256x256, Sterne 256x256, Icons 64–128 px, PNG; Logo/einfache UI als SVG; Modelle GLB.
- Kachelbare Texturen müssen seamless sein (Randpixel-Test in der jeweiligen Aufgabe).
- Wenige Materialien, wiederverwendbare Meshes, sparsame Transparenz, Schatten nur für wichtige Objekte.

## Textgrößen
HUD 20–24 px, Hauptmenü 32–44 px, Fließtext 18–22 px, Hinweise mindestens 16 px. Schriftvorschläge: Nunito, Fredoka, Atkinson Hyperlegible (Lizenz vor Einbau in docs/CREDITS.md prüfen, alle drei stehen unter der SIL Open Font License).

## Wichtigster Moment
Der Übergang eines grauen, schmutzigen Sterns zu einem warm leuchtenden goldenen Stern (A-10, A-11). Alles andere ordnet sich dem unter.
