extends GutTest
## Tarefa 02/03 — schema do LevelResource (dados reais): construção, validação e round-trip.

const TMP_PATH := "user://test_level_resource.tres"


func _el(x: int, y: int, primo: int) -> LevelElement:
	var e := LevelElement.new()
	e.x = x
	e.y = y
	e.primo = primo
	return e


func _make_valid_level() -> LevelResource:
	var lvl := LevelResource.new()
	lvl.stage = 1
	lvl.level = 1
	lvl.grid_rows = 5
	lvl.grid_cols = 5
	lvl.only_one_number = false
	lvl.r = PackedFloat32Array([2, 2, 1])
	lvl.elements = [_el(2, 2, 2), _el(3, 0, 2), _el(1, 3, 11)]  # Level_01_01 real
	return lvl


func after_each() -> void:
	if FileAccess.file_exists(TMP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP_PATH))


func test_valid_level_passes() -> void:
	var lvl := _make_valid_level()
	assert_true(lvl.is_valid(), "Nível bem formado deveria validar. Erros: %s" % str(lvl.validate()))


func test_element_outside_grid_fails() -> void:
	var lvl := _make_valid_level()
	lvl.elements = [_el(0, 0, 2), _el(9, 9, 5)]  # fora de 5x5
	assert_false(lvl.is_valid(), "Elemento fora do grid deveria falhar")


func test_too_few_elements_fails() -> void:
	var lvl := _make_valid_level()
	lvl.elements = [_el(0, 0, 2)]  # só o jogador
	assert_false(lvl.is_valid(), "Menos de 2 elementos deveria falhar")


func test_duplicate_positions_fail() -> void:
	var lvl := _make_valid_level()
	lvl.elements = [_el(2, 2, 2), _el(2, 2, 5)]
	assert_false(lvl.is_valid(), "Posições duplicadas deveriam falhar")


func test_serialization_round_trip() -> void:
	var lvl := _make_valid_level()
	assert_eq(ResourceSaver.save(lvl, TMP_PATH), OK, "save deveria retornar OK")

	var loaded := ResourceLoader.load(TMP_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as LevelResource
	assert_not_null(loaded, "LevelResource deveria carregar do disco")
	assert_eq(loaded.stage, 1)
	assert_eq(loaded.elements.size(), 3, "elements deveriam sobreviver ao round-trip")
	assert_eq(loaded.elements[2].primo, 11, "primo preservado")
	assert_true(loaded.is_valid())
