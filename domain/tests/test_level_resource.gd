extends GutTest
## Tarefa 02 — schema do LevelResource: construção, validação e round-trip de serialização.

const TMP_PATH := "user://test_level_resource.tres"


func _make_element(x: int, y: int, primo: int) -> LevelElement:
	var e := LevelElement.new()
	e.x = x
	e.y = y
	e.primo_index = primo
	return e


func _make_valid_level() -> LevelResource:
	var lvl := LevelResource.new()
	lvl.stage = 1
	lvl.level = 1
	lvl.grid_rows = 5
	lvl.grid_cols = 5
	lvl.chain = PackedInt32Array([2, 3, 5, 7])
	lvl.only_one_number = false
	lvl.elements = [_make_element(0, 0, 0), _make_element(1, 1, 1)]
	return lvl


func after_each() -> void:
	if FileAccess.file_exists(TMP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_PATH))


func test_valid_level_passes() -> void:
	var lvl := _make_valid_level()
	assert_true(lvl.is_valid(), "Nível bem formado deveria validar. Erros: %s" % str(lvl.validate()))


func test_default_disguise_has_nine_entries() -> void:
	var lvl := _make_valid_level()
	assert_eq(lvl.disguise.size(), LevelResource.DISGUISE_SIZE, "disguise default deve ter 9 entradas")


func test_element_outside_grid_fails() -> void:
	var lvl := _make_valid_level()
	lvl.elements = [_make_element(0, 0, 0), _make_element(9, 9, 1)]  # fora de 5x5
	assert_false(lvl.is_valid(), "Elemento fora do grid deveria falhar")


func test_too_few_elements_fails() -> void:
	var lvl := _make_valid_level()
	lvl.elements = [_make_element(0, 0, 0)]  # só o jogador
	assert_false(lvl.is_valid(), "Menos de 2 elementos deveria falhar")


func test_duplicate_positions_fail() -> void:
	var lvl := _make_valid_level()
	lvl.elements = [_make_element(2, 2, 0), _make_element(2, 2, 1)]
	assert_false(lvl.is_valid(), "Posições duplicadas deveriam falhar")


func test_primo_index_out_of_chain_fails() -> void:
	var lvl := _make_valid_level()
	lvl.elements = [_make_element(0, 0, 0), _make_element(1, 1, 99)]  # chain tem só 4
	assert_false(lvl.is_valid(), "primo_index fora da cadeia deveria falhar")


func test_chain_reaches_27_flag() -> void:
	var lvl := _make_valid_level()
	assert_false(lvl.chain_reaches_27(), "Cadeia [2,3,5,7] não alcança 27")
	lvl.chain = PackedInt32Array([2, 3, 27])
	assert_true(lvl.chain_reaches_27(), "Cadeia com 27 deve ser sinalizada (insumo G-01)")


func test_serialization_round_trip() -> void:
	var lvl := _make_valid_level()
	var err := ResourceSaver.save(lvl, TMP_PATH)
	assert_eq(err, OK, "ResourceSaver.save deveria retornar OK")

	var loaded := ResourceLoader.load(TMP_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as LevelResource
	assert_not_null(loaded, "LevelResource deveria carregar do disco")
	assert_eq(loaded.stage, 1)
	assert_eq(loaded.level, 1)
	assert_eq(loaded.grid_rows, 5)
	assert_eq(loaded.elements.size(), 2, "elements deveriam sobreviver ao round-trip")
	assert_true(loaded.is_valid(), "Nível carregado deveria validar")
