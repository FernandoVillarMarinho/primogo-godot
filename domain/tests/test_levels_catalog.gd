extends GutTest
## Tarefa 03 (integração) — carrega os LevelResource REAIS extraídos das cenas Unity
## e valida cada um pelo domínio via LevelCatalog. Guarda contra regressão dos dados.

const LEVELS_DIR := "res://resources/levels/"


func test_all_extracted_levels_load_and_validate() -> void:
	var dir := DirAccess.open(LEVELS_DIR)
	assert_not_null(dir, "pasta resources/levels/ deve existir")
	if dir == null:
		return

	var cat := LevelCatalog.new()
	var count := 0
	var invalid: Array = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var res := ResourceLoader.load(LEVELS_DIR + fname) as LevelResource
			assert_not_null(res, "carrega " + fname)
			if res != null:
				var errs := cat.add(LevelFactory.from_resource(res))
				if not errs.is_empty():
					invalid.append("%s: %s" % [fname, str(errs)])
				count += 1
		fname = dir.get_next()
	dir.list_dir_end()

	assert_eq(count, 122, "122 fases extraídas das cenas Unity")
	assert_eq(cat.size(), 122, "todas as 122 válidas no catálogo")
	assert_true(invalid.is_empty(), "fases inválidas: %s" % str(invalid))


func test_known_level_01_01_values() -> void:
	var res := ResourceLoader.load(LEVELS_DIR + "level_01_01.tres") as LevelResource
	assert_not_null(res)
	if res == null:
		return
	var data := LevelFactory.from_resource(res)
	assert_eq(data.player_true_value(), 2, "jogador do Level_01_01 = 2")
	var frozen := data.generate_frozen()
	assert_eq(frozen.size(), 2, "2 congelados")
	assert_eq(frozen[1]["displayed_value"], 44, "exibido 44 (11*2 * r[1]=2)")
