#!/usr/bin/env python3
"""Listet Ideen aus docs/IMPROVEMENT_BRAINSTORMING.md mit Status `neu`. Exit-Code 1, wenn es welche gibt (Entscheidung Pflicht)."""
import re, sys, pathlib
p = pathlib.Path(__file__).resolve().parent.parent / "docs" / "IMPROVEMENT_BRAINSTORMING.md"
def open_ideas(text):
    out = []
    for line in text.splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) >= 5 and re.fullmatch(r"IB-\d+", cells[0]) and cells[4] == "neu":
            out.append((cells[0], cells[2], cells[3]))
    return out
if __name__ == "__main__":
    ideas = open_ideas(p.read_text(encoding="utf-8"))
    for i, who, txt in ideas: print(f"{i} ({who}): {txt[:110]}")
    print(f"{len(ideas)} Idee(n) warten auf Entscheidung (docs/IMPROVEMENT_BRAINSTORMING.md)" if ideas else "Keine offenen Ideen.")
    sys.exit(1 if ideas else 0)
