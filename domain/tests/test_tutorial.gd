extends GutTest
## Tarefa 14 — features/tutorial: sequências (BR-048), identidade da fase (D-003), filtro
## do gate de movimento (BR-009) e gate do balão por passo (BR-049). Overlay testado sem
## board real; o board só é checado quanto à compilação.

# ---------------------------------------------------------------- sequências (BR-048)

func test_sequences_literal() -> void:
	assert_eq(TutorialSequence.T1,
		[Match.Direction.UP, Match.Direction.RIGHT, Match.Direction.DOWN, Match.Direction.LEFT],
		"T1 = UP→RIGHT→DOWN→LEFT")
	assert_eq(TutorialSequence.T2[2], TutorialSequence.BALLOON, "T2 tem clique no balão no 3º passo")


func test_identity_maps_to_tutorial() -> void:
	assert_true(TutorialSequence.is_tutorial(1, 0), "(1,0) = tutorial 1")
	assert_true(TutorialSequence.is_tutorial(2, 1), "(2,1) = tutorial 2")
	assert_false(TutorialSequence.is_tutorial(1, 1), "(1,1) não é tutorial")
	assert_eq(TutorialSequence.which(2, 1), "t2")
	assert_eq(TutorialSequence.which(1, 0), "t1")


func test_t2_choreography_reaches_the_six() -> void:
	# 4º teste em dispositivo: a T2 legada (RIGHT, LEFT, balão, LEFT) nunca alcançava o
	# 6 em (4,3) — o descongelamento não acontecia. Coreografia corrigida.
	assert_eq(TutorialSequence.T2,
		[Match.Direction.RIGHT, Match.Direction.DOWN, TutorialSequence.BALLOON, Match.Direction.LEFT],
		"T2 = DIREITA (leva o 3), BAIXO (descongela o 6), balão (primo 2), ESQUERDA (divide o 4)")


func test_move_sequence_strips_balloon() -> void:
	var moves := TutorialSequence.move_sequence(TutorialSequence.T2)
	assert_eq(moves, [Match.Direction.RIGHT, Match.Direction.DOWN, Match.Direction.LEFT],
		"só direções vão ao gate do domínio (sem o passo BALLOON, BR-009)")


func test_captions_follow_steps() -> void:
	assert_eq(TutorialSequence.captions_for(2, 1).size(), TutorialSequence.T2.size(),
		"uma instrução por passo na T2 (4º teste)")
	assert_eq(TutorialSequence.captions_for(1, 0).size(), TutorialSequence.T1.size(),
		"uma instrução por passo na T1")
	assert_true(str(TutorialSequence.captions_for(2, 1)[2]).contains("primo 2"),
		"o passo do balão orienta o clique no primo 2")


func test_balloon_step_detection() -> void:
	assert_false(TutorialSequence.is_balloon_step(TutorialSequence.T2, 0), "passo 0 = direção")
	assert_true(TutorialSequence.is_balloon_step(TutorialSequence.T2, 2), "passo 2 = balão")
	assert_false(TutorialSequence.is_balloon_step(TutorialSequence.T1, 2), "T1 nunca tem balão")


# ---------------------------------------------------------------- overlay: gate + avanço

func test_overlay_balloon_gate_and_completion() -> void:
	var ov := TutorialOverlay.new()
	add_child_autofree(ov)
	ov.setup(2, 1, null)   # T2, sem adapter (não conecta sinais)
	watch_signals(ov)
	assert_false(ov.balloon_clickable(), "passo 0 (RIGHT): balão travado")
	ov.advance()           # → passo 1 (DOWN)
	assert_false(ov.balloon_clickable(), "passo 1 (DOWN): balão travado")
	ov.advance()           # → passo 2 (BALLOON)
	assert_true(ov.balloon_clickable(), "passo 2: balão liberado (BR-049)")
	ov.notify_balloon_used()  # avança do balão → passo 3 (LEFT)
	assert_false(ov.balloon_clickable(), "após o clique, balão volta a travar")
	ov.advance()           # esgota a sequência
	assert_true(ov.is_finished(), "sequência concluída")
	assert_signal_emitted(ov, "tutorial_finished")


## Regressão do 4º teste em dispositivo: a coreografia T2 resolve a 02-01 de ponta a
## ponta no domínio real — DIREITA, BAIXO descongela o 6 (conquista o 2), a troca pelo
## balão ativa o 2 e a ESQUERDA divide o 4, vencendo a fase.
func test_t2_walkthrough_solves_level_02_01() -> void:
	var res := load("res://resources/levels/level_02_01.tres") as LevelResource
	var m := Match.new()
	m.start(LevelFactory.from_resource(res), 12)
	m.set_tutorial_sequence(TutorialSequence.move_sequence(TutorialSequence.T2))
	assert_eq(str(m.move(Match.Direction.RIGHT)[0]["type"]), "move_accepted", "DIREITA aceita")
	var ev2 := m.move(Match.Direction.DOWN)
	var merged := ev2.filter(func(e): return str(e["type"]) == "merged")
	assert_eq(merged.size(), 1, "BAIXO descongela o número 6")
	assert_eq(int(merged[0]["collected"]), 2, "conquista o primo 2 (6 ÷ 3 = 2)")
	assert_true(m.collection.has(2), "o primo 2 entra na lista")
	assert_eq(str(m.swap_value(2)[0]["type"]), "value_swapped", "clique no primo 2 ativa o 2")
	var ev4 := m.move(Match.Direction.LEFT)
	assert_true(ev4.any(func(e): return str(e["type"]) == "match_won"),
		"ESQUERDA divide o número 4 e vence a fase")


func test_board_still_compiles_with_tutorial() -> void:
	assert_not_null(load("res://features/board/board.gd"),
		"board.gd compila com TutorialOverlay/TutorialSequence integrados")
