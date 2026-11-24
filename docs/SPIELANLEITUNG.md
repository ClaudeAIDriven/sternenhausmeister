# StarScrubber: Spielanleitung (Demo)

## Installieren (Windows)
1. Download: GitHub-Seite des Projekts, Reiter **Releases**, Eintrag **latest**, Datei `StarScrubber-Setup.exe`. Starten und den Anweisungen folgen. (Windows warnt evtl. vor einer unbekannten App: „Weitere Informationen“, dann „Trotzdem ausführen“. Das Spiel ist nicht signiert.)
2. Alternativ ohne Installation: `StarScrubber.exe` und `StarScrubber.pck` aus dem Release in denselben Ordner legen, `StarScrubber.exe` starten.

## Spielen
- Im Hauptmenü Namen eintragen, **Spielart** wählen (Standard, Kinder, Zen), dann **Allein putzen**.
- Steuerung: **WASD** laufen, **Maus** umsehen, **Leertaste** springen, **linke Maustaste** oder **E** putzen, **rechte Maustaste** schubsen, **F** an der Werkstatt, **Esc** Pause und Einstellungen. Die Werkstatt (Haus mit rotem Dach, auf der Minimap oben rechts) öffnest du in ihrer Nähe mit **F**; dort kaufst du mit Sternenstaub einen größeren Wedel, schnellere Sohlen und einen längeren Stiel.
- Rollen (im Menü wählen): **Allrounder** (ausgeglichen), **Hüpfer** (springt viel höher, danach 2,5 s Pause), **Gründlicher Putzer** (wischt 50 % breiter, traut sich nicht an Spinnennester), **Flitzer** (sehr schnell, wischt aber nur 60 % so breit).
- Lebensleiste (unten Mitte): Schaden gibt es bei Stürzen über 5 m, durch Schubser anderer Spieler, in Lava (rot leuchtend) und an Kakteen. Nach 6 s ohne Schaden füllt sie sich langsam wieder. Bei 0 bist du benommen und startest an der Laterne neu.
- Ballon: Einfach auf die Plattform laufen, er steigt. Oben lenkst du ihn mit **WASD**; zum Absteigen springen.
- Minimap oben rechts: Werkstatt (Haus), Ballon (rot), Sterne (gold = schmutzig, grün = sauber), Gefahren, Mitspieler; darunter Fortschritt und Restzeit.
- Ziel: Alle Sterne sauber wischen. Das Sternbild muss in der **richtigen Reihenfolge** geputzt werden (der Hinweis zeigt den nächsten Stern). Falsche Reihenfolge: Die Sterne werden wieder schmutzig, ohne Strafe.
- Wer ohne Pause wischt, baut eine **Kombo** auf (mehr Staub, höherer Ton). Putzen zwei Spieler denselben Stern, gibt es **Teamarbeit-Bonus**. Mit dem **Ballon** auf der Insel erreichst du hohe Sterne.
- Am Nachtende (Standard 10 Minuten) zeigt die Zusammenfassung 1 bis 3 Sternchen. Es gibt kein Game Over, du kannst danach weiterputzen.

## Neu im Finale
- **Karten** (Menü): Mondwiese (klassisch), Lavafelder, Kaktuswüste, Spinnenhöhle. Optional **Insel-Seed** eintragen: gleicher Seed = gleiche Insel (Seed steht im Pausenmenü). Ohne Eingabe ist die Mondwiese klassisch, die anderen Karten würfeln einen Seed.
- **Utensilien** in der Werkstatt: Wedel, Schwamm, Besen, Staubsauger, Dampfreiniger, Sternpolierer (je 3 Upgrades). **Spinnen** lassen sich nur mit dem **Staubsauger** entfernen, **Wollmäuse** (sie machen geputzte Flecken wieder schmutzig) mit jedem Werkzeug.
- **Rußwolke** (Boss): nur mit **zwei Spielern gleichzeitig** wischen, allein nur wenn das Schild kurz fällt (alle 25 s für 6 s). Gibt 200 Staub.
- **Essen:** **F** Früchte aufheben, **Q** essen; in der **Küche** (Feuerstelle) kochen für Buffs. Orte: Brunnen (heilt), Obstgarten, Turm (Gegner auf der Minimap), Schrein (**F**: Wischradius +25 %).
- **XP und Fähigkeiten:** **K** öffnet den Fähigkeitenbaum. Rollen: Allrounder, Hüpfer, Putzer, Koch, Kletterer (**G** Leiter), Flitzer. Rollen tragen Hüte.
- **Spaß:** Trampolinwolken (hoher Sprung), Wunsch-Sternschnuppen (fangen = Buff), Glühwürmchen zeigen zum nächsten schmutzigen Stern, mittlere Maustaste = Ping, **H** Hut wechseln (20 Erfolge schalten Hüte frei).
- **Speichern:** Pause (Esc) → *Spiel speichern* (nur Host/Solo); am Nachtende automatisch („autosave"). Im Hauptmenü *Laden:* wählen.
- Wenn du am Boden liegst: Mitspieler halten **F** (3 s) zum Wiederbeleben; sonst Neustart nach 60 s mit Staubverlust. Rauflust (Schubsen macht Schaden) ist im Menü optional.

## Zusammen spielen (2 bis 4 Personen)
1. Eine Person wählt **Raum eröffnen (Host)**. Oben links erscheint die Adresse (Internet-Adresse nach automatischer Router-Freigabe, sonst die WLAN-Adresse). Mit **Adresse kopieren** in die Zwischenablage.
2. Alle anderen tragen die Adresse unter **Beitreten** ein (ohne `:24680`) und klicken **Beitreten**.
3. Im selben WLAN geht es sofort. Übers Internet muss der Router den **UDP-Port 24680** zum Host weiterleiten (oft automatisch, sonst von Hand) oder ihr nutzt ein VPN wie Tailscale. Details: `docs/INTERNET.md`. Windows fragt beim ersten Hosten nach der Firewall: **Zugriff erlauben**.
4. Verlässt jemand das Spiel, übernimmt eine Drohne und putzt weiter. Wer zurückkommt, tritt wieder bei.

## Bekannte Grenzen
- Unter Windows und im echten Internet noch nicht getestet. Sporadisch kann beim Beitreten ein Client keine Mitspieler sehen: einfach neu beitreten (docs/KNOWN_ISSUES.md).
- Ton wurde nie von einem Menschen angehört; Balance (Zeitlimit, Staubmengen) ist geschätzt.
- Fehler bitte als GitHub-Issue melden, mit Beschreibung, was passiert ist.
