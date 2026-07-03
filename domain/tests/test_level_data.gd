extends GutTest
## Tarefa 04 (corrigida na Fase 0) — geração fiel ao CreateTile do legado:
## true = elements[i].primo * elements[i-1].primo (ou *elements[0] se only_one);
## exibido = int(true * r[i-1]); teto 9999. Puro, sem engine.

var R := PackedFloat32Array([2, 2, 1])


func _elem(x: int, y: int, primo: int) -> Dictionary:
	return {"x": x, "y": y, "primo": primo}


func _level(only_one := false, elements := [], r := R) -> LevelData:
	var els: Array = elements if not elements.is_empty() else [_elem(2, 2, 2), _elem(3, 0, 2), _elem(1, 3, 11)]
	return LevelData.new(1, 1, 5, 5, only_one, r, els)


func test_player_value_is_first_element_primo() -> void:
	assert_eq(_level().player_true_value(), 2, "jogador = elements[0].primo")


func test_frozen_generation_matches_level_01_01() -> void:
	# Level_01_01 real: elements primo [2,2,11], r=[2,2,1]
	var frozen := _level().generate_frozen()
	assert_eq(frozen.size(), 2)
	assert_eq(frozen[0]["true_value"], 4, "2*2")
	assert_eq(frozen[0]["displayed_value"], 8, "4*r[0]=2")
	assert_eq(frozen[1]["true_value"], 22, "11*2")
	assert_eq(frozen[1]["displayed_value"], 44, "22*r[1]=2")
	assert_eq(frozen[1]["primo"], 11, "primo de fallback = elements[i].primo")


func test_only_one_number_uses_first_element() -> void:
	var els := [_elem(0, 0, 2), _elem(1, 1, 3), _elem(2, 2, 5)]
	var normal := LevelData.new(1, 1, 5, 5, false, R, els).generate_frozen()
	var oon := LevelData.new(1, 1, 5, 5, true, R, els).generate_frozen()
	assert_eq(normal[1]["true_value"], 15, "normal: 5 * elements[1].primo(3)")
	assert_eq(oon[1]["true_value"], 10, "only_one: 5 * elements[0].primo(2)")


func test_displayed_truncates_like_c_sharp_cast() -> void:
	# r fracionário: 21 * 0.6667 = 14.0007 → int() trunca para 14
	var els := [_elem(0, 0, 3), _elem(1, 1, 7)]
	var lvl := LevelData.new(1, 1, 5, 5, false, PackedFloat32Array([0.666667]), els)
	assert_eq(lvl.generate_frozen()[0]["true_value"], 21, "7*3")
	assert_eq(lvl.generate_frozen()[0]["displayed_value"], 14, "int(21*0.6667)")


func test_valid_level_passes() -> void:
	assert_true(_level().is_valid(), "erros=%s" % str(_level().validate()))


func test_too_few_elements_fails() -> void:
	assert_false(_level(false, [_elem(0, 0, 2)]).is_valid())


func test_displayed_over_9999_fails() -> void:
	var els := [_elem(0, 0, 100), _elem(1, 1, 100)]
	var lvl := LevelData.new(1, 1, 5, 5, false, PackedFloat32Array([2]), els)
	assert_false(lvl.is_valid(), "10000*2 > 9999 (BR-016)")


func test_key_is_stage_level() -> void:
	var lvl := LevelData.new(3, 7, 5, 5, false, R, [_elem(0, 0, 2), _elem(1, 1, 5)])
	assert_eq(lvl.key(), Vector2i(3, 7))


func test_factory_from_resource_maps_fields() -> void:
	var res := LevelResource.new()
	res.stage = 2
	res.level = 5
	res.grid_rows = 6
	res.grid_cols = 7
	res.only_one_number = false
	res.r = PackedFloat32Array([2, 1])
	var e0 := LevelElement.new(); e0.x = 0; e0.y = 0; e0.primo = 2
	var e1 := LevelElement.new(); e1.x = 1; e1.y = 1; e1.primo = 5
	res.elements = [e0, e1]

	var data := LevelFactory.from_resource(res)
	assert_eq(data.stage, 2)
	assert_eq(data.cols, 7)
	assert_eq(data.player_true_value(), 2)
	assert_eq(data.generate_frozen()[0]["true_value"], 10, "5*2")
	assert_true(data.is_valid())
