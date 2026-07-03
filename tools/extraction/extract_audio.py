#!/usr/bin/env python3
"""Extrator de áudio da Fase 0 — bancos FMOD (FSB5 Vorbis) → .ogg.

Os banks em Assets/StreamingAssets/*.bank são contêineres RIFF com um bloco FSB5 v1
codificado em Vorbis (48kHz estéreo). Este script usa python-fsb5 para reconstruir os
OGG. O rebuild de Vorbis do fsb5 depende da lib nativa `vorbis` (libvorbis) disponível
no sistema — sem ela, só os metadados são lidos (ver build do audio_manifest).

Alternativa robusta sem libvorbis: `vgmstream-cli` (decodifica FSB5 Vorbis → WAV) +
ffmpeg (WAV → OGG).

Uso:  python extract_audio.py
Saída: ../../assets/audio/<bank>__<sample>.ogg
"""
import os
import glob
import fsb5

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
BANKS = os.path.join(ROOT, "Assets", "StreamingAssets")
OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio"))


def _safe(name: str) -> str:
    return "".join(c if (c.isalnum() or c in "._-") else "_" for c in name)


def main():
    os.makedirs(OUT, exist_ok=True)
    total = 0
    for bank_path in sorted(glob.glob(os.path.join(BANKS, "*.bank"))):
        data = open(bank_path, "rb").read()
        i = data.find(b"FSB5")
        if i < 0:
            continue
        fsb = fsb5.FSB5(data[i:])
        ext = fsb.get_sample_extension()
        bank = _safe(os.path.splitext(os.path.basename(bank_path))[0])
        for idx, sample in enumerate(fsb.samples):
            name = _safe(sample.name or f"{bank}_{idx}")
            try:
                rebuilt = fsb.rebuild_sample(sample)
            except Exception as e:  # libvorbis ausente, etc
                print(f"  ERRO {bank}/{name}: {e}")
                continue
            with open(os.path.join(OUT, f"{bank}__{name}.{ext}"), "wb") as f:
                f.write(rebuilt)
            total += 1
            print(f"  {bank}: {name}.{ext} ({len(rebuilt)} bytes)")
    print(f"total extraído: {total}")


if __name__ == "__main__":
    main()
