# Relatório de Paridade — Primogo (Unity 5.3 → Godot 4)

> Tarefa 16 do `reconstruction-plan.md`. Traduz `_reversa_sdd/migration/parity_specs.md` +
> `parity_tests/*.feature` (PAR-01..09). Métrica primária = **characterization tests no
> domínio puro, headless** (GUT). As ≥10 partidas amostrais vs oráculo e os golden files
> visuais são **manuais/pendentes** (dependem do APK — COD-004/009).

## Suíte automatizada (GUT)

- `domain/tests/parity/test_parity.gd` — PAR-01..06, PAR-08 (domínio puro).
- `domain/tests/parity/test_parity_shell.gd` — PAR-07 (autoloads scene_router/audio_bus/progression_store).
- **140/140 testes GUT verdes** na suíte total (inclui `test_game_fonts` e `test_grid_calibration` da Fase 3); toda a paridade de **regra econômica e de gameplay** (o núcleo do critério `@critico`) é verde.

## Integração visual (Fase 3, 2026-07-10 — arte-fonte original `ImagensPrimogo`)

O jogo **não usa mais placeholders**: T17 importou os 157 assets originais; T18 ligou as
4 bitmap fonts convertidas dos `.fnt` do legado (métricas exatas); T19 aplicou cenário por
grade + `grid_calibration.tres` (transcrita do `GameManager`), chama do player, gelo,
efeitos one-shot (vapor/anim_gelo) e a pausa real; T20 montou splash/menu/opções/créditos/
seleção/fim-de-fase/tutorial com a arte original. Resolvidos nesta fase: **COD-002**
(créditos, geração "New"), **COD-007/AMB-201** (tile-espelho = slot selecionado do balão
elevado +0,25 un., conforme `BalloonController.SetPrimogoValue`/`ChangeNumber`),
**COD-008/AMB-202** (dragão = set laranja `primogo/dragao_anim01..08`). APK debug com o
visual novo: **43,5 MB**, export limpo. Restam 🟡 de ajuste fino (owner Villar, contra os
prints): `fine_offset` da calibração por grade, posições/escalas de HUD/balão/dragão/mão,
durações canônicas (COD-001).

## Cobertura por fluxo

| PAR | Fluxo | Cobertura automatizada | Pendente (manual/oráculo) |
|-----|-------|------------------------|---------------------------|
| 01 | Merge/disfarce/célula a célula | ✅ merge coleta quociente; disfarce (divisibilidade pelo exibido); `@ordem`+`@idempotencia` (vitória 1×, só na última célula); swipe inválido sem custo | comparação visual do deslizamento (goldens) |
| 02 | Punição/derrotas | ✅ exaustão `@idempotencia` (match_lost 1×, razão certa); cerco/gelo cobertos em `test_board` | — |
| 03 | Troca pelo balão | ✅ troca válida (custo, novo valor), descarte do valor corrente (L-09), troca inválida inerte; gate T2 em `test_tutorial` | — |
| 04 | Economia fim de fase | ✅ recorde+estrelas, recorde não regride, recompensa deriva do recorde (replay 3★=+4), 1★=+0 (L-01), saturação em 50, reset punitivo do estágio, `@idempotencia` (register_win) | — |
| 05 | Gate de entrada | ✅ redirect tutorial 2, 3★ grátis, pago debita 2, válvula fase 01, recusa; débito só na entrada | — |
| 06 | Desbloqueio/seleção | ✅ máquina LOCKED→UNLOCKED→WON, estágio completo no 12º, índice `i*4+j` (DEV-005), paginação trava na 10 (L-04) | estados visuais das caixas (goldens) |
| 07 | Navegação/áudio | ✅ navegação serializada (1 troca por vez), Voltar por contexto, gate central de efeitos (`@idempotencia`), mute reativo imediato, toggle persiste | — |
| 08 | Onboarding/tutoriais | ✅ sequências T1/T2, passo do balão só no 3º, filtro do gate de movimento, gesto fora da sequência sem custo | ciclo da mão em tempo real (validação visual) |
| 09 | Contrato de telas | ⚠️ **parcial** — estrutura das cenas compila e os literais/ordem do modal (DEV-007) estão no código; validação visual formal = **manual/goldens** | contract test formal das 10 telas + goldens (todos `pending`) |

## Dimensões do paradigma (procedural→OO+sinais)

- **@invariante** (I1..I6 do Match): valor do jogador na cadeia, coleção sem duplicatas/não encolhe, sem gelo após merge, teto 9999 — cobertos em `test_board`/`test_parity`.
- **@idempotencia** (polling→sinais): `match_won`/`match_lost` e conclusão de tutorial emitem/persistem exatamente 1× — cobertos (PAR-01/02/04/07/08).
- **@ordem** (frames→tempo real): resolução célula a célula, vitória só na última — coberto (PAR-01).
- **@validacao** (factories): `LevelData` inválido falha na carga — coberto em `test_level_resource`/`test_levels_catalog`.

## Reconciliação de redação (não é divergência)

- **PAR-01 "novo valor do jogador = quociente":** o domínio validado (`GameManager.cs`, `test_board`) **mantém** o valor do jogador e **coleta** o quociente na coleção. O "valor novo" da spec é o valor coletado. Comportamento idêntico ao legado — apenas fraseado de forma diferente na spec.

## Exceções aprovadas (deviations — não são divergência)

DEV-001 (texto literal, não pixel), DEV-002 (bitmap fonts por glifo), DEV-003 (ícone raio), DEV-004 (tempo real, ±10%), DEV-005 (grade `i*4+j` — o oráculo é a spec corrigida, **não** o legado bugado), DEV-006 (tokens), DEV-007 (modal variante A; a variante B **não** deve aparecer), DEV-008 (fundo clareia no fim de fase). Também: recarga 1★=+0 (L-01), recompensa pelo recorde (BR-027), estágios 11–12 inalcançáveis (L-04), cheat inerte em produção (L-11 — testado).

## Pendências manuais (bloqueiam o gate de cutover, owner = Villar)

1. **≥10 partidas amostrais vs oráculo** (mesma fase + mesma sequência → mesmo resultado de energia/estrelas/desbloqueio), usando o APK/VM Unity 5.3 como oráculo. Depende de ter o oráculo rodando (COD-004).
2. **Golden files** (`_reversa_sdd/screens/golden/manifest.yaml`, todos `pending`) — captura no APK e comparação visual dos 5 layouts (`grid_calibration.tres`) e da coreografia de fim de fase. Enquanto não capturados, os **runtime references** (prints IMG_3089–3108) valem como oráculo de composição/comportamento, não de cor exata (DEV-006).
3. **Contract test formal das 10 telas** (PAR-09) — a arte original já está integrada (Fase 3); falta a conferência lado a lado com os prints e o ajuste fino (`fine_offset`, posições, durações COD-001).

## Critério de bloqueio

Qualquer cenário `@critico` vermelho ou divergência econômica reproduzível contra o oráculo bloqueia o passo 6 do `cutover_plan.md` (go/no-go). **Estado atual:** characterization `@critico` 100% verde; sample-matches vs oráculo e goldens **pendentes** (não confirmados nem refutados).
