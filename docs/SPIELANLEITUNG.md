# StarScrubber: Spielanleitung (Demo)

## Installieren (Windows)
1. Download: GitHub-Seite des Projekts, Reiter **Releases**, Eintrag **latest**, Datei `StarScrubber-Setup.exe`. Starten und den Anweisungen folgen. (Windows warnt evtl. vor einer unbekannten App: „Weitere Informationen“, dann „Trotzdem ausführen“. Das Spiel ist nicht signiert.)
2. Alternativ ohne Installation: `StarScrubber.exe` und `StarScrubber.pck` aus dem Release in denselben Ordner legen, `StarScrubber.exe` starten.

## Spielen
- Im Hauptmenü Namen eintragen, **Spielart** wählen (Standard, Kinder, Zen), dann **Allein putzen**.
- Steuerung: **WASD** laufen, **Maus** umsehen, **Leertaste** springen, **linke Maustaste** oder **E** putzen, **B** Werkstatt, **Esc** Pause und Einstellungen. In der Werkstatt (Taste **B**) kaufst du mit Sternenstaub einen größeren Wedel, schnellere Sohlen und einen längeren Stiel.
- Ziel: Alle Sterne sauber wischen. Das Sternbild muss in der **richtigen Reihenfolge** geputzt werden (der Hinweis zeigt den nächsten Stern). Falsche Reihenfolge: Die Sterne werden wieder schmutzig, ohne Strafe.
- Wer ohne Pause wischt, baut eine **Kombo** auf (mehr Staub, höherer Ton). Putzen zwei Spieler denselben Stern, gibt es **Teamarbeit-Bonus**. Mit dem **Ballon** auf der Insel erreichst du hohe Sterne.
- Am Nachtende (Standard 10 Minuten) zeigt die Zusammenfassung 1 bis 3 Sternchen. Es gibt kein Game Over, du kannst danach weiterputzen.

## Zusammen spielen (2 bis 4 Personen)
1. Eine Person wählt **Raum eröffnen (Host)**. Oben links erscheint die Adresse (Internet-Adresse nach automatischer Router-Freigabe, sonst die WLAN-Adresse). Mit **Adresse kopieren** in die Zwischenablage.
2. Alle anderen tragen die Adresse unter **Beitreten** ein (ohne `:24680`) und klicken **Beitreten**.
3. Im selben WLAN geht es sofort. Übers Internet muss der Router den **UDP-Port 24680** zum Host weiterleiten (oft automatisch, sonst von Hand) oder ihr nutzt ein VPN wie Tailscale. Details: `docs/INTERNET.md`. Windows fragt beim ersten Hosten nach der Firewall: **Zugriff erlauben**.
4. Verlässt jemand das Spiel, übernimmt eine Drohne und putzt weiter. Wer zurückkommt, tritt wieder bei.

## Bekannte Grenzen
- Unter Windows und im echten Internet noch nicht getestet. Sporadisch kann beim Beitreten ein Client keine Mitspieler sehen: einfach neu beitreten (docs/KNOWN_ISSUES.md).
- Ton wurde nie von einem Menschen angehört; Balance (Zeitlimit, Staubmengen) ist geschätzt.
- Fehler bitte als GitHub-Issue melden, mit Beschreibung, was passiert ist.
