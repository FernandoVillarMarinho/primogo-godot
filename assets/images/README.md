# assets/images — arte-fonte original do Primogo

Cópia canônica e versionada da arte original do jogo, obtida pelo Villar em 2026-07-10
(pasta `ImagensPrimogo/` na raiz do workspace do legado, fora do git de lá).
Nomes normalizados: minúsculas, sem espaços/acentos/parênteses.

**Curadoria:** 157 arquivos importados; 38 excluídos (assets default do Unity em
`UI_Interface/` — `UnitySplash*`, `UnityWatermark*`, widgets genéricos de
button/toggle/slider/scrollbar/textfield/window). De `UI_Interface/` só entraram
`esctoexit_*` e `soft.png`.

## Mapa pasta → tela (specs em `_reversa_sdd/migration/target_screens.md`)

| Pasta | Tela(s) | Conteúdo | Pendência que resolve |
|---|---|---|---|
| `splashscreen/` | S-01 Splash | `splash_grande_recovered.png` | placeholder da splash |
| `menu/` | S-02 Menu · S-03 Opções · S-04 Créditos | céu (`cenario_ceu`), `logo`+`nome` (pulse BR-045), `bt-jogar/opcoes/facebook` (+bases), `opcoes-box`, toggles `pause-musica/efeitos`, `opcoes-bt-*`, `creditos_*` | COD-002 (assets de créditos) |
| `levelselect/` + `assets_levelselect/` | S-05 Seleção | `title-nivel01..14` (banner por página — ⚠️ 14 títulos × 10 estágios navegáveis, validar na T20), `box`, `star`, `bt-nivelanterior/proximonivel` (+bases), `energy-bar`, `chama-primordial`, `bt_voltar`, mockup `selecaodefases.png` | placeholders da grade |
| `gameplay/` | S-06 Jogo · S-07 Pause | `energy-bar`, `box-numbers`, `bt-pause` (+base), `bt-reload`, modal `pause-box`, `pause-bt-*`, toggles, mockups `gameplay.png`/`pause-gameplay.png` | HUD e pause reais |
| `scenery_grid/` | S-06 Jogo | backgrounds por grade — nome codifica `LINHASxCOLUNAS_CELULA_PX`: `5x5_100`, `5x7_70`, `6x7_70`, `6x8_61`, `7x7_70`, `7x8_61`, `8x8_61`, `9x9_54` (+ `5x5.png`, `9x9.png`, `background.png`; `8x7_61-14.png` na raiz de images/) | `grid_calibration.tres` (T19) |
| `iceandfire/` | S-06 Jogo | gelo `anim_gelo01..05`, `gelo`, `gelo_numero`, `gelo_derretido`, vapor `vapor01..03` (merge), fogo `fogo1..3` | animações do board |
| `endgame/` | S-08 Vitória · S-09 Derrota | `box-endgame-parabens` (variante A DEV-007), `box-fimdejogo` (variante B, referência), `bt-next/playagain/quitgame/tryagain`, `star`/`star-off`, `icon-energy`, `vocetem`, mockups `endgame*.png`/`endgame_lose.png` | evidência DEV-007 |
| `primogo/` | S-08 Fim de fase | dragão `dragao_anim01..08` (+`dragao_anim_gif`) | **COD-008 (sprite-set do dragão)** |
| `mageanimation/` | S-08 (coreografia) | mago `mago_anim_01..07`, `estrela_01..03` (partículas ⚡ das estrelas) | coreografia de entrada S-08 |
| `tutorial/` | S-10 Tutorial | mão `mao`, `mao-tutorial-{cima,baixo,esquerda,direita,clique,clique-opcao2}` | placeholder da mão (BR-047) |
| `fonts/` + `fonts2/` | dígitos/rotulagem | `numbers.png`, `font.png`/`font_2.png`, `font_select.png`, `orangefont.png` | **DEV-002 (bitmap fonts, T18)** |
| `icon/` | ícone do app | `icone-512px` (+`_vs2`), `logo_mc_horizontal`, `dragao_anim05` | ícone de export |
| `ui_interface/` | desktop | `esctoexit_back/text`, `soft` | — |
| raiz | diversos | `logo.png`, `cenario_fases-08.png`, `8x7_61-14.png` | — |
