extends GutTest
## Suíte de PARIDADE (PAR-01..08) — characterization do domínio puro contra o oráculo do
## legado, traduzida dos Gherkins em `_reversa_sdd/migration/parity_tests/*.feature`.
## Métrica primária do gate de cutover (parity_specs.md). Roda headless. As ≥10 partidas
## amostrais vs oráculo (APK) e os golden files visuais (PAR-09) são MANUAIS/PENDENTES
## (COD-004/009) — ver PARITY.md.
##
## Reconciliação de redação: onde o .feature diz "novo valor do jogador = quociente", o
## domínio validado (GameManager.cs, test_board) MANTÉM o valor do jogador e COLETA o
## quociente. O "valor novo" da spec é o valor coletado — sem divergência comportamental.

var TH := {"three_star": 4, "two_star": 7, "max": 12}   # {3★:4, 2★:7, máx:12} (PAR-04)


func _match(cols: int, rows: int) -> Match:
	var m := Match.new()
	m.grid = Grid.new(cols, rows)
	m.collection = Collection.new()
	m.budget = 10
	m.status = Match.Status.PLAYING
	return m


# ================================================================ PAR-01 · merge

func test_par01_merge_collects_quotient() -> void:
	var m := _match(2, 1)
	m.grid.set_cell(0, 0, Cell.player(0, 0, 2))
	m.grid.set_cell(1, 0, Cell.frozen(1, 0, 6, 6, 3))  # exibido 6, true 6
	m.move(Match.Direction.RIGHT)
	assert_true(m.collection.has(3), "6/2 = 3 coletado (spec: 'novo valor 3')")
	assert_eq(m.player_value(), 2, "valor do jogador inalterado (oráculo GameManager)")
	assert_eq(m.grid.count_frozen(), 0, "congelado sai do grid")
	assert_eq(m.status, Match.Status.WON, "sem congelados → vitória")


func test_par01_disguise_uses_displayed_for_divisibility() -> void:
	var m := _match(2, 1)
	m.grid.set_cell(0, 0, Cell.player(0, 0, 3))
	m.grid.set_cell(1, 0, Cell.frozen(1, 0, 12, 6, 3))  # exibido 12 (disfarce), true 6
	m.move(Match.Direction.RIGHT)
	assert_true(m.collection.has(2), "divisibilidade pelo exibido; quociente pelo true (6/3=2)")


func test_par01_cell_by_cell_single_win_event() -> void:
	# @ordem/@idempotencia: avança célula a célula; vitória só na última, emitida 1 vez.
	var m := _match(4, 1)
	m.grid.set_cell(0, 0, Cell.player(0, 0, 2))
	m.grid.set_cell(3, 0, Cell.frozen(3, 0, 4, 4, 2))  # (1,0) e (2,0) vazias
	var ev := m.move(Match.Direction.RIGHT)
	var types: Array = ev.map(func(e): return e["type"])
	assert_true(types.count("moved") >= 2, "desliza célula a célula")
	assert_eq(types.count("match_won"), 1, "vitória emitida exatamente 1 vez")
	assert_gt(types.find("match_won"), types.find("merged"), "vitória avaliada só após a resolução")


func test_par01_invalid_move_costs_nothing() -> void:
	var m := _match(2, 1)
	m.grid.set_cell(0, 0, Cell.player(0, 0, 2))
	m.move(Match.Direction.LEFT)  # fora do grid
	assert_eq(m.budget, 10, "swipe inválido não custa (BR-008)")


# ================================================================ PAR-02 · punição/derrota

func test_par02_exhaustion_lost_once() -> void:
	# @idempotencia: derrota por exaustão decretada exatamente 1 vez, com a razão certa.
	# Bloqueio num congelado não-divisível; o gelo preenche o único vazio (sem cerco), e o
	# orçamento zera → exaustão pura.
	var m := _match(3, 1)
	m.grid.set_cell(0, 0, Cell.player(0, 0, 2))
	m.grid.set_cell(1, 0, Cell.frozen(1, 0, 5, 5, 5))  # 5 % 2 != 0 → bloqueia
	m.budget = 1
	var ev := m.move(Match.Direction.RIGHT)
	var lost: Array = ev.filter(func(e): return e["type"] == "match_lost")
	assert_eq(lost.size(), 1, "match_lost uma única vez")
	assert_eq(lost[0]["reason"], "EXHAUSTION", "razão EXHAUSTION")


# ================================================================ PAR-03 · troca pelo balão

func test_par03_swap_discards_current_value() -> void:
	# Troca válida: novo valor, custa 1; o valor antigo NÃO retorna à coleção (L-09).
	var m := _match(2, 1)
	m.grid.set_cell(0, 0, Cell.player(0, 0, 3))
	m.grid.set_cell(1, 0, Cell.frozen(1, 0, 9, 9, 3))
	m.collection.add(2)
	m.swap_value(2)
	assert_eq(m.player_value(), 2, "valor do jogador passa a 2")
	assert_eq(m.budget, 9, "troca custa 1")
	assert_false(m.collection.has(3), "valor antigo (3) não volta à coleção (L-09)")


func test_par03_invalid_swap_is_inert() -> void:
	var m := _match(2, 1)
	m.grid.set_cell(0, 0, Cell.player(0, 0, 3))
	var ev := m.swap_value(7)  # não coletado
	assert_eq(ev[0]["type"], "swap_rejected", "troca inválida é inerte (sem débito/gelo)")
	assert_eq(m.budget, 10)


# ================================================================ PAR-04 · economia fim de fase

func test_par04_record_and_three_stars() -> void:
	var pp := PlayerProgress.new()
	pp.global_energy = 40
	pp.register_win(1, 3, 9, TH)
	assert_eq(pp.record_of(1, 3), 9, "recorde gravado = 9")
	assert_eq(pp.stars_of(1, 3, TH), 3, "9 ≥ 12−4 → 3★")


func test_par04_record_never_regresses() -> void:
	var pp := PlayerProgress.new()
	pp.records[Vector2i(1, 3)] = 9
	pp.register_win(1, 3, 5, TH)
	assert_eq(pp.record_of(1, 3), 9, "recorde não regride")


func test_par04_reward_derives_from_record_replay() -> void:
	var pp := PlayerProgress.new()
	pp.global_energy = 40
	pp.records[Vector2i(1, 3)] = 9                                    # já 3★
	pp.unlocks[Vector2i(1, 3)] = PlayerProgress.UnlockState.WON
	pp.register_win(1, 3, 1, TH)                                      # replay com 1★ de partida
	assert_eq(pp.global_energy, 44, "replay de fase 3★ recompensa +4 (deriva do recorde, BR-027)")


func test_par04_one_star_recharges_zero() -> void:
	var pp := PlayerProgress.new()
	var th := {"three_star": 5, "two_star": 8, "max": 12}
	pp.global_energy = 30
	pp.register_win(1, 1, 2, th)                                     # 2 restante → 1★
	assert_eq(pp.global_energy, 30, "1★ recarrega +0 (L-01 mantido)")


func test_par04_energy_saturates_at_fifty() -> void:
	var pp := PlayerProgress.new()
	pp.global_energy = 48
	pp.register_win(1, 1, 12, TH)                                    # 1ª vitória 3★ → +5
	assert_eq(pp.global_energy, 50, "energia satura em 50")


func test_par04_punitive_stage_reset() -> void:
	var pp := PlayerProgress.new()
	pp.global_energy = 1
	pp.records[Vector2i(3, 5)] = 9
	pp.unlocks[Vector2i(3, 5)] = PlayerProgress.UnlockState.WON
	pp.records[Vector2i(2, 1)] = 5
	var ev := pp.register_loss(3, 5)
	assert_true(ev.any(func(e): return e["type"] == "stage_reset"), "reset do estágio 3")
	assert_eq(pp.record_of(3, 5), 0, "recordes do estágio 3 zerados")
	assert_eq(pp.record_of(2, 1), 5, "demais estágios intactos")


# ================================================================ PAR-05 · gate de entrada

func test_par05_gate_redirect_tutorial2() -> void:
	var pp := PlayerProgress.new()
	assert_eq(pp.try_enter(2, 1, TH)[0]["type"], "entry_redirected", "02-01 1ª visita → tutorial 2, sem débito")


func test_par05_gate_three_star_free() -> void:
	var pp := PlayerProgress.new()
	pp.records[Vector2i(1, 2)] = 12
	pp.global_energy = 40
	assert_eq(pp.try_enter(1, 2, TH)[0]["mode"], "free", "3★ entra grátis")
	assert_eq(pp.global_energy, 40, "sem débito")


func test_par05_gate_paid_debits_two() -> void:
	var pp := PlayerProgress.new()
	pp.global_energy = 40
	assert_eq(pp.try_enter(1, 2, TH)[0]["mode"], "paid")
	assert_eq(pp.global_energy, 38, "debita 2 na entrada")


func test_par05_gate_level1_escape_valve() -> void:
	var pp := PlayerProgress.new()
	pp.global_energy = 0
	assert_eq(pp.try_enter(1, 1, TH)[0]["mode"], "free", "fase 01 grátis quando sem energia")


func test_par05_gate_refused_when_broke() -> void:
	var pp := PlayerProgress.new()
	pp.global_energy = 0
	assert_eq(pp.try_enter(1, 3, TH)[0]["type"], "entry_refused", "≠01 sem energia → recusa")


# ================================================================ PAR-06 · desbloqueio/seleção

func test_par06_unlock_machine() -> void:
	var pp := PlayerProgress.new()
	pp.unlocks[Vector2i(2, 3)] = PlayerProgress.UnlockState.UNLOCKED
	pp.register_win(2, 3, 8, TH)
	assert_eq(pp.unlock_of(2, 3), PlayerProgress.UnlockState.WON, "2-3 → vencido")
	assert_eq(pp.unlock_of(2, 4), PlayerProgress.UnlockState.UNLOCKED, "2-4 → desbloqueado")


func test_par06_stage_completed_on_twelfth() -> void:
	var pp := PlayerProgress.new()
	var ev := pp.register_win(1, PlayerProgress.LEVELS_PER_STAGE, 5, TH)
	assert_true(ev.any(func(e): return e["type"] == "stage_completed"), "12º nível completa o estágio")


func test_par06_grid_corrected_and_pagination_locked() -> void:
	assert_eq(LevelGrid.level_index(1, 0), 4, "índice i*4+j (DEV-005), não i*3+j")
	assert_false(LevelGrid.can_navigate_to(11), "paginação trava na 10 (L-04)")


# ================================================================ PAR-08 · tutoriais

func test_par08_t2_sequence_and_balloon_step() -> void:
	assert_eq(TutorialSequence.T2,
		[Match.Direction.RIGHT, Match.Direction.LEFT, TutorialSequence.BALLOON, Match.Direction.LEFT],
		"T2 = RIGHT, LEFT, [balão], LEFT")
	assert_true(TutorialSequence.is_balloon_step(TutorialSequence.T2, 2), "clique no balão só no 3º passo")
	assert_eq(TutorialSequence.move_sequence(TutorialSequence.T2).size(), 3, "só direções vão ao gate (BR-009)")


func test_par08_tutorial_gate_rejects_off_sequence_no_cost() -> void:
	var m := _match(3, 3)
	m.grid.set_cell(1, 1, Cell.player(1, 1, 2))
	m.set_tutorial_sequence([Match.Direction.UP, Match.Direction.RIGHT])
	var ev := m.move(Match.Direction.LEFT)  # fora da sequência
	assert_eq(ev[0]["reason"], "TUTORIAL_SEQUENCE", "gesto fora da sequência é ignorado")
	assert_eq(m.budget, 10, "sem custo (BR-009)")
