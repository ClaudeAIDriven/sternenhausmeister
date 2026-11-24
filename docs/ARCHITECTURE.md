# Architektur und Schnittstellen

Damit mehrere Leute/Modelle parallel arbeiten können, gelten feste Verträge. Wer einen Vertrag ändern will, legt zuerst eine Aufgabenkarte dafür an.

## Ordner
- `/` Godot-Projekt (Skripte, Szenen) · `data/` JSON-Daten (Sternbilder, Upgrades, Presets) · `assets/` Modelle/Audio (mit Lizenz in docs/CREDITS.md) · `shaders/` · `tools/` Skripte · `TASKS/` Aufgabenkarten · `docs/`

## Autoloads (globale Dienste)
| Name | Datei | Zweck | Wichtige API |
|---|---|---|---|
| GameState | game_state.gd | Spielzustand | `player_count`, `night_state`, `dust`; Signale `night_started`, `night_ended`, `star_cleaned(star)` |
| Settings | settings.gd | Einstellungen | `get_value(key)`, `set_value(key,v)`, Signal `changed(key)` |
| NetworkManager | network_manager.gd | Netzwerk | `host(port)`, `join(ip,port)`, `leave()`; Signale `player_joined(id)`, `player_left(id)`; `is_host()` |

## Klassen (bereits vorhanden)
- `Player` (player.gd): Signal `wipe_requested(point)`, Eigenschaften `cleaning`, `aim_point`, `aim_valid`.
- `Star` (star.gd): `wipe(world_point, radius) -> int`, Signale `scrubbed(n)`, `cleaned`, Eigenschaften `progress`, `is_clean`, `spots`.
- `Sfx` (sfx.gd): `make_tone(freq,dur,vol,noise)`, `play(stream,pitch,db)`.

## Regeln
1. **Server-Autorität:** Alle Spielzustände ändert nur der Host. Clients senden Anfragen per RPC.
2. **Daten statt Code:** Sternbilder, Upgrades, Presets liegen als JSON in `data/`.
3. **Kein harter Fail-State.** Zeitlimit ist sanft.
4. **Jede Aufgabe hat einen Selbsttest** (`--selftest` oder eigener Test), der `tools/run_tests.sh` nicht bricht.
5. **Lizenzen:** Nur CC0/eigene Assets, Quelle in docs/CREDITS.md.
6. **Renderer:** Muss im Compatibility-Renderer laufen (schwächere PCs).
7. Sichtprüfung ohne GPU: siehe PLAN.md (xvfb + llvmpipe + --write-movie).
