extends GutTest
## Tarefa 05 — domínio Board: deslizamento célula a célula, merge (BR-001), SnowBreak
## (BR-004), punição de gelo com ordem AROUND (BR-003), cerco (BR-006), exaustão (BR-021),
## troca pelo balão (BR-012/013). Puro, sem engine.

func _elem(x: int, y: int, primo_index: int) -> Dictionary:
	return {"x": x, "y": y, "primo_index": primo_index}


func _level(rows: int, cols: int, only_one: bool, elements: Array) -> LevelData:
	return LevelData.new(
		1, 1, rows, cols,
		PackedInt32Array([2, 3, 5, 7]),
		only_one,
		PackedFloat32Array([2, 1, 1, 1, 1, 1, 1, 1, 1]),
		elements
	)


func _blank_match(cols: int, rows: int) -> Match:
	var m := Match.new()
	m.grid = Grid.new(cols, rows)
	m.collection = Collection.new()
	m.budget = 99
	m.status = Match.Status.PLAYING
	return m


# ---------------------------------------------------------------- merge / slide

func test_move_merges_and_wins_via_primo_fallback() -> void:
	# jogador(2) desliza e funde o congelado exibido 30 (true 15, não divisível por 2)
	var lvl := _level(1, 3, false, [_elem(0, 0, 0), _elem(2, 0, 2)])
	var m := Match.new()
	m.start(lvl, 5)
	m.move(Match.Direction.RIGHT)
	assert_eq(m.status, Match.Status.WON, "fundir o último congelado vence")
	assert_true(m.collection.has(5), "coleta o fator primo de fallback (5)")
	assert_eq(m.player_pos(), Vector2i(2, 0), "jogador avança para a célula do alvo")
	assert_eq(m.player_value(), 2, "valor do jogador não muda no merge")


func test_merge_uses_quotient_when_true_divisible() -> void:
	# congelado true=6 (divisível por 2) -> quociente 3
	var lvl := _level(1, 3, false, [_elem(0, 0, 0), _elem(2, 0, 1)])
	var m := Match.new()
	m.start(lvl, 5)
	m.move(Match.Direction.RIGHT)
	assert_true(m.collection.has(3), "true=6 divisível por 2 → coleta o quociente 3")


func test_slides_through_empty_to_wall() -> void:
	var lvl := _level(2, 3, false, [_elem(0, 0, 0), _elem(0, 1, 2)])
	var m := Match.new()
	m.start(lvl, 5)
	m.move(Match.Direction.RIGHT)
	assert_eq(m.player_pos(), Vector2i(2, 0), "desliza até a última coluna")
	assert_eq(m.status, Match.Status.PLAYING)


func test_merge_triggers_snow_break() -> void:
	var m := _blank_match(3, 2)
	m.grid.set_cell(0, 0, Cell.player(0, 0, 2))
	m.grid.set_cell(2, 0, Cell.frozen(2, 0, 4, 4, 2))
	m.grid.set_cell(0, 1, Cell.ice(0, 1))
	m.move(Match.Direction.RIGHT)
	assert_eq(m.grid.at(0, 1).kind, Cell.Kind.EMPTY, "SnowBreak derrete o gelo ao fundir")
	assert_eq(m.status, Match.Status.WON)


# ---------------------------------------------------------------- punição de gelo

func test_ice_spawn_interior_goes_right_down() -> void:
	var m := _blank_match(3, 3)
	m.grid.set_cell(0, 0, Cell.player(0, 0, 7))
	m.grid.set_cell(1, 1, Cell.frozen(1, 1, 4, 4, 2))
	var spawned := m._spawn_ice()
	assert_eq(spawned.size(), 1)
	assert_eq(m.grid.at(2, 2).kind, Cell.Kind.ICE, "interior: 1º gelo em RIGHT_DOWN (2,2)")


func test_ice_spawn_top_edge_goes_right() -> void:
	var m := _blank_match(3, 3)
	m.grid.set_cell(0, 2, Cell.player(0, 2, 7))
	m.grid.set_cell(1, 0, Cell.frozen(1, 0, 4, 4, 2))
	var spawned := m._spawn_ice()
	assert_eq(m.grid.at(2, 0).kind, Cell.Kind.ICE, "borda superior: 1º gelo em RIGHT (2,0)")


func test_ice_spawn_at_most_one_per_frozen() -> void:
	var m := _blank_match(3, 3)
	m.grid.set_cell(0, 0, Cell.player(0, 0, 7))
	m.grid.set_cell(1, 1, Cell.frozen(1, 1, 4, 4, 2))
	var spawned := m._spawn_ice()
	assert_eq(spawned.size(), 1, "no máximo 1 gelo por congelado por movimento")


# ---------------------------------------------------------------- cerco (BR-006)

func test_surrounded_true_without_escape() -> void:
	var m := _blank_match(3, 3)
	m.grid.set_cell(1, 1, Cell.player(1, 1, 7))
	m.grid.set_cell(0, 1, Cell.frozen(0, 1, 5, 5, 5))
	m.grid.set_cell(2, 1, Cell.frozen(2, 1, 5, 5, 5))
	m.grid.set_cell(1, 0, Cell.frozen(1, 0, 5, 5, 5))
	m.grid.set_cell(1, 2, Cell.frozen(1, 2, 5, 5, 5))
	assert_true(m._check_surrounded(), "5%7!=0 e sem coletados → cercado")
	assert_true(m._is_siege(), "cercado → derrota por cerco")


func test_surrounded_false_with_collected_divisor() -> void:
	var m := _blank_match(3, 3)
	m.grid.set_cell(1, 1, Cell.player(1, 1, 7))
	m.grid.set_cell(0, 1, Cell.frozen(0, 1, 5, 5, 5))
	m.grid.set_cell(2, 1, Cell.frozen(2, 1, 5, 5, 5))
	m.grid.set_cell(1, 0, Cell.frozen(1, 0, 5, 5, 5))
	m.grid.set_cell(1, 2, Cell.frozen(1, 2, 5, 5, 5))
	m.collection.add(5)  # 5 % 5 == 0 → há saída por número coletado
	assert_false(m._check_surrounded(), "coletado divide um congelado ortogonal → escapa")


func test_siege_false_when_empty_around_frozen() -> void:
	var m := _blank_match(3, 3)
	m.grid.set_cell(0, 0, Cell.player(0, 0, 7))  # tem (1,0) vazio → não cercado
	m.grid.set_cell(2, 2, Cell.frozen(2, 2, 5, 5, 5))  # vizinhos vazios
	assert_false(m._is_siege(), "congelado com vizinho vazio → sem cerco")


# ---------------------------------------------------------------- exaustão / rejeição

func test_exhaustion_on_zero_budget() -> void:
	var lvl := _level(2, 3, false, [_elem(0, 0, 0), _elem(0, 1, 2)])
	var m := Match.new()
	m.start(lvl, 1)
	m.move(Match.Direction.RIGHT)  # desliza até a parede, não vence, orçamento → 0
	assert_eq(m.status, Match.Status.LOST_EXHAUSTION)


func test_move_out_of_grid_rejected_without_cost() -> void:
	var lvl := _level(1, 3, false, [_elem(0, 0, 0), _elem(2, 0, 2)])
	var m := Match.new()
	m.start(lvl, 5)
	var ev := m.move(Match.Direction.LEFT)  # jogador em x=0
	assert_eq(ev[0]["reason"], "OUT_OF_GRID")
	assert_eq(m.budget, 5, "direção fora do grid não custa energia")


func test_tutorial_gate_rejects_wrong_direction() -> void:
	var lvl := _level(2, 3, false, [_elem(0, 0, 0), _elem(2, 1, 2)])
	var m := Match.new()
	m.start(lvl, 5)
	m.set_tutorial_sequence([Match.Direction.RIGHT])
	var ev := m.move(Match.Direction.DOWN)  # dentro do grid, mas fora da sequência
	assert_eq(ev[0]["reason"], "TUTORIAL_SEQUENCE")
	assert_eq(m.budget, 5, "movimento fora da sequência não custa energia")


# ---------------------------------------------------------------- troca / coleção

func test_swap_requires_collected_and_different() -> void:
	var lvl := _level(2, 3, false, [_elem(0, 0, 0), _elem(2, 1, 2)])
	var m := Match.new()
	m.start(lvl, 5)
	assert_eq(m.swap_value(3)[0]["type"], "swap_rejected", "valor não coletado é rejeitado")
	m.collection.add(3)
	m.swap_value(3)
	assert_eq(m.player_value(), 3, "troca aplica o valor coletado")
	assert_eq(m.budget, 4, "troca custa 1 de energia")
	assert_eq(m.swap_value(3)[0]["type"], "swap_rejected", "trocar pelo valor atual é rejeitado")


func test_collection_dedupe() -> void:
	var c := Collection.new()
	assert_true(c.add(5), "primeiro add é aceito")
	assert_false(c.add(5), "duplicata é rejeitada")
	assert_eq(c.size(), 1)
