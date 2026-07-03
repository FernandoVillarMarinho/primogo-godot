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


func test_move_sequence_strips_balloon() -> void:
	var moves := TutorialSequence.move_sequence(TutorialSequence.T2)
	assert_eq(moves, [Match.Direction.RIGHT, Match.Direction.LEFT, Match.Direction.LEFT],
		"só direções vão ao gate do domínio (sem o passo BALLOON, BR-009)")


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
	ov.advance()           # → passo 1 (LEFT)
	assert_false(ov.balloon_clickable(), "passo 1 (LEFT): balão travado")
	ov.advance()           # → passo 2 (BALLOON)
	assert_true(ov.balloon_clickable(), "passo 2: balão liberado (BR-049)")
	ov.notify_balloon_used()  # avança do balão → passo 3 (LEFT)
	assert_false(ov.balloon_clickable(), "após o clique, balão volta a travar")
	ov.advance()           # esgota a sequência
	assert_true(ov.is_finished(), "sequência concluída")
	assert_signal_emitted(ov, "tutorial_finished")


func test_board_still_compiles_with_tutorial() -> void:
	assert_not_null(load("res://features/board/board.gd"),
		"board.gd compila com TutorialOverlay/TutorialSequence integrados")
