extends GutTest
## Tarefa 11 — features/board (casca): adaptador do domínio (AD-02) e detector de
## swipe (BR-008). Prova a partida ponta a ponta contra `domain/board` via sinais.

# ---------------------------------------------------------------- adaptador (AD-02)

func _win_in_one_move_adapter() -> MatchAdapter:
	# Grid 2x1: jogador(2) à esquerda, congelado(4) divisível à direita → 1 move vence.
	var m := Match.new()
	m.grid = Grid.new(2, 1)
	m.collection = Collection.new()
	m.budget = 5
	m.status = Match.Status.PLAYING
	m.grid.set_cell(0, 0, Cell.player(0, 0, 2))
	m.grid.set_cell(1, 0, Cell.frozen(1, 0, 4, 4, 2))
	var ad := MatchAdapter.new()
	add_child_autofree(ad)
	ad.match_game = m
	return ad


func test_move_translates_events_to_signals() -> void:
	var ad := _win_in_one_move_adapter()
	watch_signals(ad)
	ad.move(Match.Direction.RIGHT)
	assert_signal_emitted(ad, "budget_changed", "movimento aceito debita orçamento")
	assert_signal_emitted(ad, "value_collected", "merge coleta um valor")
	assert_signal_emitted(ad, "match_won", "sem congelados restantes → vitória")
	assert_signal_emitted(ad, "move_resolved", "entrega a fila para animar (AD-03)")


func test_rejected_move_has_no_animation() -> void:
	var ad := _win_in_one_move_adapter()
	watch_signals(ad)
	ad.move(Match.Direction.LEFT)  # fora do grid → rejeitado sem custo
	assert_signal_emitted(ad, "move_rejected")
	assert_signal_not_emitted(ad, "move_resolved", "rejeição não dispara animação")
	assert_signal_not_emitted(ad, "budget_changed", "rejeição não custa orçamento")


func test_move_resolved_carries_ordered_queue() -> void:
	var ad := _win_in_one_move_adapter()
	var events := ad.move(Match.Direction.RIGHT)
	assert_eq(str(events[0]["type"]), "move_accepted", "primeiro evento = aceite")
	assert_true(events.any(func(e): return e["type"] == "match_won"), "fila contém a vitória")


# ---------------------------------------------------------------- swipe (BR-008)

func test_swipe_dominant_axis() -> void:
	assert_eq(SwipeDetector.direction_for(Vector2(50, 5)), Match.Direction.RIGHT, "→ = RIGHT")
	assert_eq(SwipeDetector.direction_for(Vector2(-50, 5)), Match.Direction.LEFT, "← = LEFT")
	assert_eq(SwipeDetector.direction_for(Vector2(5, 50)), Match.Direction.DOWN, "↓ = DOWN (y cresce p/ baixo)")
	assert_eq(SwipeDetector.direction_for(Vector2(5, -50)), Match.Direction.UP, "↑ = UP")


func test_swipe_below_threshold_is_none() -> void:
	assert_eq(SwipeDetector.direction_for(Vector2(5, 5)), Match.Direction.NONE, "curto demais = NONE")


# ---------------------------------------------------------------- compila a cena (autoloads)

func test_board_scene_compiles_with_autoloads() -> void:
	# Força a compilação de board.gd no runtime do projeto (autoloads registrados);
	# não instancia (não roda _ready, que carrega nível/áudio).
	var script := load("res://features/board/board.gd")
	assert_not_null(script, "board.gd compila com AudioBus/SceneRouter/ProgressionStore resolvidos")
