# Mit Freunden übers Internet spielen

StarScrubber nutzt **UDP-Port 24680**. Einer hostet („Raum eröffnen“), die anderen treten mit der Adresse des Hosts bei. Im selben WLAN/LAN geht es sofort. Übers Internet gibt es drei Wege. Nimm den einfachsten, der bei euch funktioniert.

## Weg 1: VPN-Programm (am einfachsten, kein Router nötig)
Alle installieren dasselbe kostenlose Programm und landen in einem gemeinsamen virtuellen Netz. Der Host nennt den anderen seine VPN-Adresse.

- **Tailscale** (tailscale.com): Alle melden sich an (derselbe „Tailnet“, Freunde über „Share“ einladen). Die Adresse des Hosts beginnt mit `100.` und steht in der Tailscale-App.
- **Radmin VPN** (Windows): Netzwerk anlegen, Freunde treten mit Name und Passwort bei. Die Adresse beginnt meist mit `26.`.
- **ZeroTier**: Netzwerk-ID teilen, Adresse steht in der App.

Dann: Host klickt „Raum eröffnen“, die anderen tragen die VPN-Adresse unter „Beitreten“ ein. Das funktioniert auch hinter Mobilfunk-Internet oder Firmen-Routern.

## Weg 2: Automatisch (UPnP)
Beim Hosten versucht das Spiel selbst, den Port am Router freizugeben (UPnP). Klappt das, steht im Spiel/Log „Port 24680 UDP automatisch freigegeben“, und die Freunde nutzen deine **öffentliche IP-Adresse** (z. B. auf „wieistmeineip.de“ nachsehen). Klappt es nicht (viele Router haben UPnP aus), läuft das Spiel normal weiter, und du nimmst Weg 1 oder 3. Die Freigabe wird beim Beenden des Raums wieder entfernt.

## Weg 3: Port von Hand freigeben (Port-Weiterleitung)
1. Router-Oberfläche öffnen (meist `192.168.0.1` oder `192.168.178.1` im Browser; Anmeldedaten stehen oft auf dem Router).
2. Menü „Port-Weiterleitung“, „Portfreigabe“ oder „Port Forwarding“ suchen.
3. Neue Regel: **Protokoll UDP**, **Port 24680** (extern und intern), Ziel = die **lokale IP des Host-PCs** (in Windows: `ipconfig`, Eintrag „IPv4-Adresse“).
4. Windows-Firewall: Beim ersten Start des Spiels „Zugriff zulassen“ bestätigen (privates Netzwerk).
5. Freunde geben deine öffentliche IP-Adresse ein.

## Wenn es nicht klappt
- **Verbindung kommt nicht zustande:** Prüfe, dass alle dieselbe Spielversion haben, und dass die Regel **UDP** (nicht TCP) ist.
- **Provider mit „CGNAT“ / DS-Lite** (häufig bei Kabel/Mobilfunk): Der Router hat keine eigene öffentliche IPv4-Adresse, Weg 2 und 3 gehen dann nicht. Nimm Weg 1.
- **Nur ihr zwei im Haus?** Dann reicht dieselbe WLAN-Verbindung, trage die lokale IP des Hosts ein.
- **Sicherheit:** Gib die Adresse nur Leuten, die mitspielen sollen. Entferne die Port-Weiterleitung, wenn ihr fertig seid. Es gibt kein Passwort, wer die Adresse kennt, kann beitreten (maximal 4 Spieler).

## Für Entwickler
- Standardport: `NetworkManager.DEFAULT_PORT` (24680). `NetworkManager.use_upnp = false` schaltet den UPnP-Versuch ab.
- `NetworkManager.upnp_result(ok, message, external_ip)` meldet das Ergebnis (läuft in einem eigenen Thread, Fehler brechen das Hosten nie ab). 🟢 Ohne Router getestet (`tests/test_upnp.gd`: Fehlschlag wird gemeldet, Hosten läuft). ❌ Mit echtem Router, echtem Internet und anderen Providern ungetestet.
- Hinweis: `installer.nsi` nennt noch UDP-Port 7777, der echte Port ist 24680 (Installer-Text anpassen).
