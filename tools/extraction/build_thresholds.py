#!/usr/bin/env python3
"""Transcreve StarManager.movementsInLevel (legado) em out/thresholds.json.

Mapeia cada fase extraída (stage SS 1..10, level NN 0..12) para {three_star, two_star, max}:
  NN >= 1  -> movementsInLevel[SS-1][NN-1]
  NN == 0  -> movementsInLevel[SS-1][12]   (tutorial; GetStars faz level<0 -> 12)
Estágios 8..10 são idênticos (placeholder não tunado, BR-030).
"""
import os
import json

HERE = os.path.dirname(__file__)

# [three_star, two_star, max] por (stage 0-based)[level 0-based] — cópia fiel de StarManager.cs
S1 = [[5,8,12],[5,8,14],[5,8,14],[4,6,12],[6,9,16],[4,6,12],[8,12,20],[8,12,20],[9,13,20],[7,11,20],[7,11,20],[6,9,20],[4,6,12]]
S2 = [[5,8,12],[10,15,24],[11,17,24],[8,12,20],[10,15,27],[13,20,36],[13,20,36],[16,24,30],[13,20,36],[13,20,36],[16,24,36],[20,30,36],[5,10,50]]
S3 = [[13,20,36],[18,27,36],[16,24,36],[15,21,36],[13,20,36],[15,23,36],[15,23,36],[17,26,36],[14,21,36],[14,21,36],[19,29,36],[14,21,36]]
S4 = [[14,21,36],[12,18,36],[11,17,36],[16,26,36],[11,17,36],[13,20,36],[11,17,36],[13,20,36],[13,20,36],[14,21,36],[15,23,36],[15,23,36]]
S5 = [[11,20,36],[12,18,36],[13,20,36],[16,24,36],[14,21,36],[15,23,36],[15,23,36],[13,20,36],[13,20,36],[21,32,36],[15,23,36],[13,20,36]]
S6 = [[19,29,42],[20,30,42],[18,27,42],[20,30,42],[18,27,42],[18,27,42],[21,32,42],[17,26,42],[18,27,42],[16,24,42],[13,20,42],[16,24,42]]
S7 = [[19,29,42],[24,36,42],[26,39,42],[22,33,42],[18,27,42],[19,29,42],[21,32,42],[16,24,42],[16,24,42],[16,24,42],[13,20,42],[16,24,42]]
S8 = [[13,20,36],[11,17,36],[18,27,36],[17,26,36],[18,27,36],[19,29,36],[19,29,36],[19,29,36],[19,29,36],[19,29,36],[19,29,36],[19,29,36]]
TABLES = [S1, S2, S3, S4, S5, S6, S7, S8, S8, S8]  # estágios 9,10 = 8 (placeholder)


def main():
    levels = json.load(open(os.path.join(HERE, "out", "levels.json"), encoding="utf-8"))
    entries = {}
    missing = []
    for lv in levels:
        stage, level = lv["stage"], lv["level"]
        table = TABLES[stage - 1]
        idx = 12 if level == 0 else level - 1
        if idx >= len(table):
            missing.append(f"{stage}_{level}")
            continue
        row = table[idx]
        entries["%d_%d" % (stage, level)] = {"three_star": row[0], "two_star": row[1], "max": row[2]}

    with open(os.path.join(HERE, "out", "thresholds.json"), "w", encoding="utf-8") as f:
        json.dump(entries, f, indent=1, ensure_ascii=False)
    print("entries=%d missing=%s" % (len(entries), missing if missing else "nenhum"))


if __name__ == "__main__":
    main()
