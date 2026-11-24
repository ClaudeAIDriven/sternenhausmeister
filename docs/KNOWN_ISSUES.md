
## Netztest `tools/test_netplayers.sh` flackert (~1 von 10-25 Läufen)
Beobachtung (mit `NETP_DEBUG=1`): Ein Client ist verbunden (Status 2), sieht kurz Host+sich (2 Spieler), dann verschwinden
alle Spieler-Knoten lokal (n=0), obwohl der Host nichts despawnt hat. Tritt auch bei 0,4 s Abstand zwischen den Clients auf,
ist also kein reines Gleichzeitig-Beitreten. Ursache offen (Verdacht: Godot-4.3-Spawner-Race oder Frame-Stalls durch
Fehlerflut der Headless-Meshes). Nicht Teil von `run_tests.sh`. Für Demo: bei fehlenden Spielern Spiel neu beitreten.

## Ballon nur lokal (I-11)
Steigen, Sinken und Lenken rechnet jeder Rechner selbst. Online können Ballonpositionen auseinanderlaufen, wenn mehrere lenken. Lösung: Host-Autorität mit MultiplayerSynchronizer (vor G-31).

## Bewegung nach dem Umbenennen (Meldung Jan, 2026-11-24)
Nicht nachstellbar in Solo/Host unter Linux; siehe docs/HANDOFF.md.
