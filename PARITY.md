# Relatório de Paridade — Primogo (Unity 5.3 → Godot 4)

> Tarefa 16 do `reconstruction-plan.md`. Traduz `_reversa_sdd/migration/parity_specs.md` +
> `parity_tests/*.feature` (PAR-01..09). Métrica primária = **characterization tests no
> domínio puro, headless** (GUT). As ≥10 partidas amostrais vs oráculo e os golden files
> visuais são **manuais/pendentes** (dependem do APK — COD-004/009).

## Suíte automatizada (GUT)

- `domain/tests/parity/test_parity.gd` — PAR-01..06, PAR-08 (domínio puro).
- `domain/tests/parity/test_parity_shell.gd` — PAR-07 (autoloads scene_router/audio_bus/progression_store).
- **148/148 testes GUT verdes** na suíte total (inclui `test_game_fonts` e `test_grid_calibration` da Fase 3, a regressão `test_cell_px_matches_drawn_grid` da 1ª rodada de dispositivo, os 2 testes da versão 2026/RES-026 — primo inicial na coleção e troca de volta ao inicial — e os 5 da 4ª rodada: truncamento float32 do exibido corrigido (142→143, 19→20), coreografia T2 nova, instruções por passo e o walkthrough completo da 02-01); toda a paridade de **regra econômica e de gameplay** (o núcleo do critério `@critico`) é verde.
- `tools/ci/load_check.gd` — load headless das cenas/scripts da casca (parse + refs de assets), cobertura que a suíte de domínio não exercita.
- `tools/ci/levels_check.gd` — auditoria das fases (4ª rodada): as 866 células congeladas exibem números divisíveis por um primo obtenível (fixpoint que inclui a "mecânica do 1" dos estágios altos).

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

## Rodadas de teste em dispositivo (2026-07-10)

- **1ª rodada** (`testeprimogo/`, commit `3848805`): célula real da grade =
  largura_textura/colunas (regressão automatizada), centralização de modais/menu
  (CenterContainer + EXPAND_IGNORE_SIZE), splash com o pan da história do `Splash.anim`.
- **2ª rodada** (`imagens2primogo/`, commit `7459e60`): dígitos **centrados** nos tiles
  (bug raiz do `DigitRenderer.size`); **balão fiel aos prints do legado** (aba do valor
  primordial + 8 slots sempre visíveis à esquerda + valor em uso flutuante — RES-023);
  HUD XX/YY branco (IMG_3096); estrelas douradas **sobrepondo** as cinzas embutidas na
  `box_1.png` e número da fase centrado; setas alinhadas às bases; menu sem PRIMOGO
  duplicado; splash **re-coreografada** (a arte recuperada perdeu o quadrante superior
  direito — RES-024); mago `mago_anim_01..07` na derrota + dragão no canto inferior
  direito (IMG_3108) + `vocetem.png`; créditos legíveis (~4,4 s/painel); **celebração
  didática de primo novo** (RES-025) e deslize contínuo do fogo (0,05 s/célula).
- **3ª rodada — "versão 2026"** (`imagens2primogo/rodada3/` + itens escritos do Villar):
  **primos ACUMULAM** (inicial entra na `Collection` no `start`; troca livre entre todos,
  1 energia cada — divergência intencional do legado, RES-026), balão em ordem
  **crescente** com o **ativo destacado** (elevado/maior/dourado); vitória **espera** a
  celebração do último primo (modal adiado até a fila + voo terminarem); transições
  aceleradas (fade 0,15 s, personagem 0,25 s, pop-in do card); estrelas laterais da
  seleção **rotacionadas ±18,5°** (medidas por varredura de pixels na `box_1.png`);
  música da seleção = `ambiencia_passaros` (o `selecao_nivel.ogg` é efeito de 0,21 s —
  em loop era o "zumbido"; virou SFX do clique); "PAUSE" embutido na arte sem
  sobreposição (conteúdo começa abaixo do título); dígito da energia fora do círculo do
  raio; créditos com painel **DJDE-UFRJ 2026**; splash com **música desde o 1º frame**
  (intro 7,3 s emendada no loop do menu) e história completa (tela inteira do mago →
  neve atingindo a cidade → dragão no verde). Smokes novos: `tools/ci/credits_check.gd`.
- **4ª rodada** (`imagens2primogo/` raiz + itens escritos do Villar, 2026-07-12):
  **tela cheia** no desktop (fallback: janela 486×864 centrada, `stretch aspect=keep`);
  **142→143** na fase 1-6 via correção do **truncamento float32** do valor exibido no
  domínio (`LevelData._displayed_for`: produto a <0,01 de um inteiro arredonda — o bug
  corrompia **63 células em 24 fases**, de 142→143 até 0→1 na 9-9; RES-027); balão em
  **fileira única** de 8 slots na mesma linha-base, sem a aba do primordial (era a
  duplicata "13 | 13" e o quadradinho deslocado), ativo destacado **só por cor+pulso**
  (RES-028); conquista de primo **expressiva** (número em chamas + faíscas + voo em arco
  + pulso de encaixe no slot; primo repetido = reforço no slot existente, sem duplicata);
  **tutorial 2-1 consertado** (a T2 legada nunca alcançava o 6: agora DIREITA→BAIXO→
  balão→ESQUERDA, com o 4 realocado para (0,3), instruções por passo na tela e o slot
  do primo 2 pulsando no passo do balão — RES-029); grade de fases em **leitura
  horizontal** (1,2,3 na 1ª linha — RES-030); créditos com **botão Pular** sempre
  visível, painéis todos em texto vivo com o MESMO tratamento (títulos laranja + nomes
  brancos com sombra), logo DJDE ancorada **embaixo sobre o jardim** e a view se esconde
  ao terminar (root cause do "Jogar desativado": o TextureRect de tela cheia seguia
  interceptando cliques). Smokes novos: `tools/ci/levels_check.gd`.

## Cobertura por fluxo

| PAR | Fluxo | Cobertura automatizada | Pendente (manual/oráculo) |
|-----|-------|------------------------|---------------------------|
| 01 | Merge/disfarce/célula a célula | ✅ merge coleta quociente; disfarce (divisibilidade pelo exibido); `@ordem`+`@idempotencia` (vitória 1×, só na última célula); swipe inválido sem custo | comparação visual do deslizamento (goldens) |
| 02 | Punição/derrotas | ✅ exaustão `@idempotencia` (match_lost 1×, razão certa); cerco/gelo cobertos em `test_board` | — |
| 03 | Troca pelo balão | ✅ troca válida (custo, novo valor), descarte do valor corrente (L-09), troca inválida inerte; gate T2 em `test_tutorial` | — |
| 04 | Economia fim de fase | ✅ recorde+estrelas, recorde não regride, recompensa deriva do recorde (replay 3★=+4), 1★=+0 (L-01), saturação em 50, reset punitivo do estágio, `@idempotencia` (register_win) | — |
| 05 | Gate de entrada | ✅ redirect tutorial 2, 3★ grátis, pago debita 2, válvula fase 01, recusa; débito só na entrada | — |
| 06 | Desbloqueio/seleção | ✅ máquina LOCKED→UNLOCKED→WON, estágio completo no 12º, índice horizontal `row*3+col` (RES-030 substitui o `i*4+j` do DEV-005), paginação trava na 10 (L-04) | estados visuais das caixas (goldens) |
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

**RES-026 (versão 2026, pedido explícito do Villar no 3º teste)**: o primo INICIAL entra
na coleção no início da partida — o jogador acumula e troca livremente entre TODOS os
primos da fase (o legado descartava o acesso ao valor corrente não coletado, L-09/RES-006).
Nas ~10 partidas vs oráculo, esta é uma divergência **esperada**: o oráculo para PAR-03 é
a spec 2026, não o APK legado.

**RES-027..030 (4ª rodada, pedidos escritos do Villar em 2026-07-12)** — divergências
intencionais adicionais; o oráculo passa a ser a spec da 4ª rodada, não o APK legado:
- **RES-027 · números exibidos**: o truncamento `(int)(true × r)` do legado herdava o
  erro do float32 (55×2.6 = 142.99999 → "142", indivisível — fase insolúvel). O domínio
  agora arredonda produtos a <0,01 de um inteiro (63 células corrigidas; auditadas as
  866 pela `levels_check.gd`). Partidas vs oráculo nas 24 fases afetadas mostrarão
  números diferentes do APK legado — o correto é o Godot.
- **RES-028 · balão**: sem a aba do valor primordial (o primo inicial já está na fileira
  via RES-026); destaque do ativo por cor+pulso, sem deslocamento vertical.
- **RES-029 · tutorial 2 (02-01)**: sequência DIREITA→BAIXO→balão→ESQUERDA e o 4 em
  (0,3) — a T2 legada (DIREITA→ESQUERDA→balão→ESQUERDA) não descongelava o 6; instruções
  textuais por passo (não existiam no legado).
- **RES-030 · seleção de fases**: leitura horizontal `row*3+col` (o DEV-005 `i*4+j`
  lia por colunas).

## Pendências manuais (bloqueiam o gate de cutover, owner = Villar)

1. **≥10 partidas amostrais vs oráculo** (mesma fase + mesma sequência → mesmo resultado de energia/estrelas/desbloqueio), usando o APK/VM Unity 5.3 como oráculo. Depende de ter o oráculo rodando (COD-004).
2. **Golden files** (`_reversa_sdd/screens/golden/manifest.yaml`, todos `pending`) — captura no APK e comparação visual dos 5 layouts (`grid_calibration.tres`) e da coreografia de fim de fase. Enquanto não capturados, os **runtime references** (prints IMG_3089–3108) valem como oráculo de composição/comportamento, não de cor exata (DEV-006).
3. **Contract test formal das 10 telas** (PAR-09) — a arte original já está integrada (Fase 3); falta a conferência lado a lado com os prints e o ajuste fino (`fine_offset`, posições, durações COD-001).

## Critério de bloqueio

Qualquer cenário `@critico` vermelho ou divergência econômica reproduzível contra o oráculo bloqueia o passo 6 do `cutover_plan.md` (go/no-go). **Estado atual:** characterization `@critico` 100% verde; sample-matches vs oráculo e goldens **pendentes** (não confirmados nem refutados).
