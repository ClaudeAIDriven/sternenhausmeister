# Artwork-Brief für externe KI-Bildwerkzeuge (StarScrubber)

Zweck: Du gibst einem Bildwerkzeug (z. B. ChatGPT/gpt-image von OpenAI, Gemini/„Nano Banana“ von Google, Midjourney, Flux) diesen Brief. Ergebnisse sind **Vorlagen und Ideen**; sie werden nur nach Prüfung (Lizenz, Stil, Auflösung) in `assets/` übernommen und in docs/CREDITS.md genannt. Vorschläge im Dokument docs/IMPROVEMENT_BRAINSTORMING.md eintragen.

## Was du mitgeben solltest
1. **Screenshots** des Ist-Zustands (Menü, Insel, Stern, Spieler, HUD) und `assets/ui/logo.svg` als Referenz.
2. **Die Palette** (Hex-Werte) und den Stilsatz unten.
3. **Konkrete Aufgabe** mit Ausgabeformat (Größe, transparenter Hintergrund ja/nein, Anzahl Varianten).
4. **Verbote** (keine Marken, keine bekannten Figuren, kein Text im Bild außer „StarScrubber“).

## Basis-Prompt (anpassen)
> Game artwork for a cozy co-op game called "StarScrubber": a tiny low-poly toy island at night, players clean dusty stars with feather dusters and brushes. Style "Midnight Toy Garden": hand-painted children's picture-book look, soft rounded shapes, clear silhouettes, 2–3 step toon shading, gentle rim light, moonlight from the upper left, warm golden accents, no photo textures, no cyberpunk, no lens flares, uncluttered. Palette: dusk sky #566DAB, midnight sky #202746, dawn #C17D91, island blue-grey #667D91, dust grey #777B83, star gold #FFD477, UI ivory #F4EEDC, panel navy #1B2140, purple #3A2F63. Player colours: blue #2878B8, orange #E69F00, violet #9B78C8, teal #009E73. No existing brands, characters or logos. [AUFGABE HIER]

## Aufgaben (jeweils an den Basis-Prompt anhängen)
- **Logo:** „Logo lockup with the text 'StarScrubber', a golden star with a small feather duster, flat vector style, transparent background, 2048 px, 4 variants.“
- **Menühintergrund:** „Wide 16:9 key art: tiny island with workshop and lanterns under a huge starry sky, three stars half cleaned and glowing, 3840×2160, no text.“
- **Sternbild-Poster (je 1):** „Illustrated night-sky poster of the constellation <Name> drawn as golden dotted lines between glowing stars, soft navy background, no text.“
- **Symbole:** „Set of 8 UI icons (duster, brush, star dust, shop, pause, host, join, settings), rounded, ivory on transparent, 256 px, consistent line weight.“
- **Charakter-Konzepte:** „Four small round toy-like caretakers in the player colours holding cleaning tools, turnaround views, plain background.“ (nur als Vorlage, Umsetzung bleibt Low-Poly-Code in `player_look.gd`.)

## Was die Werkzeuge gut / schlecht können (allgemeine Erfahrung, nicht geprüft)
- Gut für Key-Art, Hintergründe, Moodboards und Logo-Ideen; schlecht bei konsistenten Symbolsätzen, exakten Hex-Farben und lesbarem Text (Text im Bild nachträglich selbst setzen).
- Für einheitliche Serien: erst ein Referenzbild festlegen, dann „same style as the attached image“ verwenden.
- Ausgabe immer prüfen: Lizenz-/Nutzungsbedingungen des Dienstes für kommerzielle Nutzung, und dass keine Marke/Figur nachgebaut wurde.
