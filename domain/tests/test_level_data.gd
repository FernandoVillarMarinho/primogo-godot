extends GutTest
## Tarefa 04 — domínio Content: geração de valores (BR-010), disfarce (BR-007),
## teto (BR-016), validação, factory e catálogo. Puro, sem engine.

var CHAIN := PackedInt32Array([2, 3, 5, 7])          # primos (Packed não pode ser const no GDScript)
var DISGUISE := PackedFloat32Array([2, 1, 1, 1, 1, 1, 1, 1, 1])


func _elem(x: int, y: int, primo_index: int) -> Dictionary:
	return {"x": x, "y": y, "primo_index": primo_index}


func _level(only_one := false, elements := []) -> LevelData:
	var els: Array = elements if not elements.is_empty() else [_elem(0, 0, 0), _elem(1, 1, 2)]
	return LevelData.new(1, 1, 5, 5, CHAIN, only_one, DISGUISE, els)


func test_player_true_value_is_chain_member() -> void:
	# jogador com primo_index 0 -> chain[0] = 2 (I2)
	var lvl := _level(false, [_elem(0, 0, 0), _elem(1, 1, 2)])
	assert_eq(lvl.player_true_value(), 2, "valor do jogador deve ser um primo da cadeia")


func test_frozen_generation_br010() -> void:
	# congelado primo_index=2 -> chain[2]*chain[1] = 5*3 = 15 (BR-010)
	var lvl := _level(false, [_elem(0, 0, 0), _elem(1, 1, 2)])
	var frozen := lvl.generate_frozen()
	assert_eq(frozen.size(), 1)
	assert_eq(frozen[0]["true_value"], 15, "true = chain[k]*chain[k-1] = 5*3")


func test_first_frozen_is_disguised_doubled_br007() -> void:
	# 1º congelado dobra o exibido; matemática usa o real
	var lvl := _level(false, [_elem(0, 0, 0), _elem(1, 1, 2)])
	var f: Dictionary = lvl.generate_frozen()[0]
	assert_eq(f["true_value"], 15, "valor real intacto")
	assert_eq(f["displayed_value"], 30, "exibido = 15*2 (disfarce do 1º congelado)")


func test_second_frozen_not_disguised() -> void:
	# 2º congelado (r=1) não dobra
	var lvl := _level(false, [_elem(0, 0, 0), _elem(1, 1, 2), _elem(2, 2, 3)])
	var frozen := lvl.generate_frozen()
	# congelado 2: primo_index=3 -> chain[3]*chain[2] = 7*5 = 35, r=1 -> 35
	assert_eq(frozen[1]["true_value"], 35)
	assert_eq(frozen[1]["displayed_value"], 35, "2º congelado não é disfarçado")


func test_only_one_number_uses_chain_zero() -> void:
	# only_one_number: factor é chain[0] em vez de chain[k-1]
	var lvl := _level(true, [_elem(0, 0, 0), _elem(1, 1, 2)])
	var f: Dictionary = lvl.generate_frozen()[0]
	assert_eq(f["true_value"], 10, "true = chain[2]*chain[0] = 5*2 = 10 (only_one_number)")


func test_valid_level_passes() -> void:
	var lvl := _level()
	assert_true(lvl.is_valid(), "nível bem formado deve validar; erros=%s" % str(lvl.validate()))


func test_primo_index_out_of_chain_fails() -> void:
	var lvl := _level(false, [_elem(0, 0, 0), _elem(1, 1, 99)])
	assert_false(lvl.is_valid(), "primo_index fora da cadeia deve falhar sem crashar")


func test_too_few_elements_fails() -> void:
	var lvl := _level(false, [_elem(0, 0, 0)])
	assert_false(lvl.is_valid(), "menos de 2 elementos deve falhar")


func test_displayed_over_9999_fails_br016() -> void:
	# cadeia grande para estourar o teto: 100*99 = 9900, disfarçado *2 = 19800 > 9999
	var big := PackedInt32Array([99, 100])
	var lvl := LevelData.new(1, 1, 5, 5, big, false, DISGUISE, [_elem(0, 0, 0), _elem(1, 1, 1)])
	assert_false(lvl.is_valid(), "exibido acima de 9999 deve falhar (BR-016)")


func test_key_is_stage_level() -> void:
	var lvl := LevelData.new(3, 7, 5, 5, CHAIN, false, DISGUISE, [_elem(0, 0, 0), _elem(1, 1, 2)])
	assert_eq(lvl.key(), Vector2i(3, 7))


func test_factory_from_resource_maps_fields() -> void:
	var res := LevelResource.new()
	res.stage = 2
	res.level = 5
	res.grid_rows = 6
	res.grid_cols = 7
	res.chain = CHAIN
	res.only_one_number = false
	var e0 := LevelElement.new(); e0.x = 0; e0.y = 0; e0.primo_index = 0
	var e1 := LevelElement.new(); e1.x = 1; e1.y = 1; e1.primo_index = 2
	res.elements = [e0, e1]

	var data := LevelFactory.from_resource(res)
	assert_eq(data.stage, 2)
	assert_eq(data.level, 5)
	assert_eq(data.rows, 6)
	assert_eq(data.cols, 7)
	assert_eq(data.elements.size(), 2)
	assert_eq(data.player_true_value(), 2)
	assert_true(data.is_valid(), "nível vindo do factory deve validar")


func test_catalog_add_get_has_size() -> void:
	var cat := LevelCatalog.new()
	var lvl := LevelData.new(1, 1, 5, 5, CHAIN, false, DISGUISE, [_elem(0, 0, 0), _elem(1, 1, 2)])
	var errs := cat.add(lvl)
	assert_true(errs.is_empty(), "add de nível válido não retorna erros")
	assert_eq(cat.size(), 1)
	assert_true(cat.has(1, 1))
	assert_eq(cat.get_level(1, 1), lvl)
	assert_null(cat.get_level(9, 9), "nível ausente retorna null")


func test_catalog_rejects_invalid() -> void:
	var cat := LevelCatalog.new()
	var bad := LevelData.new(1, 1, 5, 5, CHAIN, false, DISGUISE, [_elem(0, 0, 0)])
	var errs := cat.add(bad)
	assert_false(errs.is_empty(), "nível inválido retorna erros")
	assert_eq(cat.size(), 0, "nível inválido não entra no catálogo")
