#!/usr/bin/env python3
"""Extrator da Fase 0 — Primogo (Unity 5.3 → Godot 4).

Lê as cenas Unity BINÁRIAS via `binary2text.exe` (ferramenta standalone do editor,
NÃO abre o projeto) e extrai os dados de cada fase do componente LevelManager +
GameManager. Somente leitura do legado; escreve só em out/.

Geração real (confirmada em GameManager.CreateTile):
  jogador     = elements[0].primo
  congelado i = elements[i].primo * elements[i-1].primo   (ou * elements[0].primo se only_one_number)
  exibido     = int(trueValue * r[i-1])
`varsArray`/`vars`/`min`/`max` são vestigiais (só no ramo morto wonTheLevel) → ignorados.

Uso:  python extract_levels.py
Saída: out/levels.json (todas as fases) + out/extraction_report.md
"""
import os
import re
import json
import glob
import subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
B2T = os.path.expanduser("~/Unity/Editors/5.3.2f1/Editor/Data/Tools/binary2text.exe")
SCENES = os.path.join(ROOT, "Assets", "Scenes")
TMP = os.path.join(ROOT, ".reversa", "tmp", "extract")
OUT = os.path.join(os.path.dirname(__file__), "out")


def dump(scene_path: str) -> str:
    os.makedirs(TMP, exist_ok=True)
    out_txt = os.path.join(TMP, os.path.basename(scene_path) + ".txt")
    subprocess.run([B2T, scene_path, out_txt], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    with open(out_txt, encoding="utf-8", errors="replace") as f:
        return f.read()


def _scalar(pattern: str, text: str):
    m = re.search(pattern, text)
    return m.group(1) if m else None


def parse(text: str) -> dict:
    lines = text.split("\n")
    data = {"rows": None, "cols": None, "only_one_number": None, "r": [], "elements": []}

    rows = _scalar(r"matrixRow (\d+) \(int\)", text)
    cols = _scalar(r"matrixColumn (\d+) \(int\)", text)
    oon = _scalar(r"onlyOneNumber (\d+) \(UInt8\)", text)
    data["rows"] = int(rows) if rows else None
    data["cols"] = int(cols) if cols else None
    data["only_one_number"] = (int(oon) != 0) if oon is not None else None

    # r (disfarce): coletar floats entre "r  (vector)" e o próximo campo ("vars")
    for i, ln in enumerate(lines):
        if re.match(r"\s*r\s+\(vector\)\s*$", ln):
            vals = []
            for j in range(i + 1, len(lines)):
                if re.search(r"\bvars\s+\(vector\)|\(Element\)|^ID:", lines[j]):
                    break
                dm = re.search(r"data \(float\)[^:]*:\s*(.*)$", lines[j])
                if dm:
                    vals += [float(x) for x in dm.group(1).split()]
            data["r"] = vals
            break

    # elements: blocos x/y/primo após "elements  (Element)"
    for i, ln in enumerate(lines):
        if re.match(r"\s*elements\s+\(Element\)", ln):
            cur = {}
            for j in range(i + 1, len(lines)):
                l = lines[j]
                if re.search(r"gameManager\s+\(PPtr|^ID:", l):
                    break
                mx = re.search(r"^\s*x (-?\d+) \(int\)", l)
                my = re.search(r"^\s*y (-?\d+) \(int\)", l)
                mp = re.search(r"^\s*primo (-?\d+) \(int\)", l)
                if mx:
                    cur = {"x": int(mx.group(1))}
                elif my:
                    cur["y"] = int(my.group(1))
                elif mp:
                    cur["primo"] = int(mp.group(1))
                    data["elements"].append(cur)
                    cur = {}
            break
    return data


def generate(level: dict):
    """Reproduz a geração do CreateTile: retorna (player_value, [frozen...], max_displayed)."""
    els = level["elements"]
    r = level["r"]
    oon = level["only_one_number"]
    if not els:
        return None, [], 0
    player = els[0]["primo"]
    frozen = []
    max_disp = player
    for i in range(1, len(els)):
        factor = els[0]["primo"] if oon else els[i - 1]["primo"]
        true_v = els[i]["primo"] * factor
        rp = r[i - 1] if (i - 1) < len(r) else 1.0
        disp = int(true_v * rp)
        frozen.append({"x": els[i]["x"], "y": els[i]["y"],
                       "primo": els[i]["primo"], "true_value": true_v, "displayed": disp})
        max_disp = max(max_disp, disp)
    return player, frozen, max_disp


def main():
    os.makedirs(OUT, exist_ok=True)
    scenes = sorted(glob.glob(os.path.join(SCENES, "Stage_*", "Level_*.unity")))
    levels = []
    report = ["# Extraction Report — Primogo (Fase 0)", ""]
    report.append(f"binary2text: `{B2T}`")
    report.append(f"cenas encontradas: **{len(scenes)}**")
    report.append("")
    report.append("| arquivo | stage | level | grid | elems | only_one | r | max exibido |")
    report.append("|---|---|---|---|---|---|---|---|")

    over_9999 = []
    for path in scenes:
        name = os.path.basename(path).replace(".unity", "")
        m = re.match(r"Level_(\d+)_(\d+)", name)
        stage, level = (int(m.group(1)), int(m.group(2))) if m else (None, None)
        parsed = parse(dump(path))
        player, frozen, max_disp = generate(parsed)
        rec = {"file": name, "stage": stage, "level": level,
               "rows": parsed["rows"], "cols": parsed["cols"],
               "only_one_number": parsed["only_one_number"],
               "r": parsed["r"], "elements": parsed["elements"],
               "player_value": player}
        levels.append(rec)
        if max_disp > 9999:
            over_9999.append(name)
        report.append(f"| {name} | {stage} | {level} | {parsed['cols']}x{parsed['rows']} | "
                      f"{len(parsed['elements'])} | {parsed['only_one_number']} | {parsed['r']} | {max_disp} |")

    with open(os.path.join(OUT, "levels.json"), "w", encoding="utf-8") as f:
        json.dump(levels, f, indent=1, ensure_ascii=False)

    report.append("")
    report.append(f"**Total extraído:** {len(levels)}")
    report.append(f"**Fases com exibido > 9999 (BR-016):** {over_9999 if over_9999 else 'nenhuma ✅'}")
    report.append("")
    report.append("> G-01: `varsArray` (com o 27) é vestigial — não entra na geração "
                  "(`CreateTile` usa `elements[i].primo`). O 27 é inerte; reproduzir fielmente.")
    with open(os.path.join(OUT, "extraction_report.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(report))

    print(f"OK: {len(levels)} fases -> out/levels.json")
    print(f"exibido > 9999: {over_9999 if over_9999 else 'nenhuma'}")


if __name__ == "__main__":
    main()
