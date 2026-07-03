# Audio Manifest — Primogo (bancos FMOD, Fase 0)

18 samples nos headers FSB5 (`Assets/StreamingAssets/*.bank`), todos **48kHz estéreo
Vorbis**. Nomes vindos da name table do FSB5. **BYTES EXTRAÍDOS** (`vgmstream-cli` FSB5→WAV
+ `ffmpeg` WAV→OGG q6): **14 `.ogg` únicos** em `assets/audio/` (18 − 4 duplicatas de
`ambiencia_passaros`/`stinger-*` dedupadas). Durações conferidas contra o manifesto.

## Vocabulário → eventos do `audio_bus` (BR-055, Tarefa 08)

| Sample | Bank | Duração | Evento no alvo |
|---|---|---|---|
| `gelo_nascendo` | Master | 1.47s | efeito: gelo surgindo (CreateIce) |
| `gelo_derretendo` | Master | 0.92s | efeito: gelo derretendo (SnowBreak/UNFREEZE) |
| `colisao_gelo` | Master | 1.35s | efeito: colisão não divisível (ATTEMPTUNFREEZE) |
| `movimentacao` | Master | 0.39s | efeito: movimento/troca de primo |
| `selecao_nivel` | Master | 0.21s | efeito: seleção de fase |
| `click_ok` | Master | 0.08s | efeito: botão confirmar |
| `click_back` | Master | 0.03s | efeito: botão voltar |
| `stinger - vitoria` | Master, stingers | 4.65s | stinger de VITÓRIA |
| `stinger - derrota` | Master, stingers | 6.96s | stinger de DERROTA |
| `menu - intro` | musicas | 7.29s | música: intro do menu |
| `menu - intro sfx` | musicas | 7.33s | música: intro do menu (variante sfx) |
| `menu - loop` | musicas | 72.0s | música: loop do menu |
| `gameplay` | musicas | 94.5s | música: loop de gameplay |
| `ambiencia_passaros` | (3 banks) | 37.32s | ambiência: pássaros (loop de fundo) |

Observações:
- `stinger - vitoria/derrota` e `ambiencia_passaros` aparecem **duplicados** em vários banks
  (Master + stingers/musicas) — no alvo, um único asset por som (dedupe, D-016).
- Mapeia os 5 eventos de gameplay + 2 stingers + músicas do BR-055. `menu - intro sfx`
  é a variante do BR-055 "entradas duplicadas" — consolidar.
- Formato alvo: `AudioStreamOggVorbis` nativo Godot (AD-07), buses `Music`/`Effects`.
