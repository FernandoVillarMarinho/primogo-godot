extends GutTest
## Tarefa 12 — features/level_select: índice corrigido (BR-036), paginação (BR-037) e
## estado das caixas. Lógica pura em LevelGrid; a cena só é checada quanto à compilação.

# --------------------------------------------------- índice horizontal row*3+col (4º teste)

func test_level_index_reads_left_to_right_top_to_bottom() -> void:
	assert_eq(LevelGrid.level_index(0, 0), 0, "canto sup-esq = 0")
	assert_eq(LevelGrid.level_index(1, 0), 1, "1ª linha: 1, 2, 3")
	assert_eq(LevelGrid.level_index(2, 0), 2, "1ª linha: 1, 2, 3")
	assert_eq(LevelGrid.level_index(0, 1), 3, "2ª linha começa na fase 4")
	assert_eq(LevelGrid.level_index(2, 3), 11, "última caixa = 11")
	assert_eq(LevelGrid.level_number(0, 0), 1, "1ª caixa mostra fase 1")
	assert_eq(LevelGrid.level_number(2, 0), 3, "fim da 1ª linha mostra fase 3")
	assert_eq(LevelGrid.level_number(0, 1), 4, "início da 2ª linha mostra fase 4")


func test_all_twelve_indices_are_unique() -> void:
	var seen := {}
	for col in LevelGrid.COLS:
		for row in LevelGrid.ROWS:
			seen[LevelGrid.level_index(col, row)] = true
	assert_eq(seen.size(), 12, "as 12 caixas cobrem 0..11 sem colisão (cada botão abre a fase certa)")


# ---------------------------------------------------------------- paginação trava na 10 (BR-037)

func test_pagination_locks_at_ten() -> void:
	assert_true(LevelGrid.can_navigate_to(10), "página 10 é navegável")
	assert_false(LevelGrid.can_navigate_to(11), "trava na 10 (12 construídas, nav até 10)")
	assert_eq(LevelGrid.clamp_page(0), 1, "clamp inferior = 1")
	assert_eq(LevelGrid.clamp_page(99), 10, "clamp superior = 10")
	assert_eq(LevelGrid.clamp_page(6), 6, "página válida preservada")


# ---------------------------------------------------------------- estado das caixas (BR-036)

func test_first_box_always_accessible() -> void:
	var locked := PlayerProgress.UnlockState.LOCKED
	assert_eq(LevelGrid.box_state(locked, true), PlayerProgress.UnlockState.UNLOCKED,
		"1ª caixa da página sempre acessível, mesmo se bloqueada no domínio")
	assert_eq(LevelGrid.box_state(locked, false), PlayerProgress.UnlockState.LOCKED,
		"demais bloqueadas permanecem bloqueadas")


func test_won_state_preserved() -> void:
	assert_eq(LevelGrid.box_state(PlayerProgress.UnlockState.WON, false),
		PlayerProgress.UnlockState.WON, "vencida mantém-se vencida (mostra estrelas)")


# ---------------------------------------------------------------- cena compila (autoloads)

func test_level_select_scene_compiles() -> void:
	assert_not_null(load("res://features/level_select/level_select.gd"),
		"level_select.gd compila com ProgressionStore/SceneRouter/AudioBus resolvidos")
