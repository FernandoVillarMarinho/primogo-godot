extends GutTest
## Tarefa 19 (Fase 3) — grid_calibration.tres transcrita do GameManager legado:
## as 4 grades reais das 122 fases têm layout com cenário existente e balão calibrado.

const PATH := "res://resources/balance/grid_calibration.tres"

# grades efetivamente usadas pelas 122 fases (levels.json): RxC
const GRIDS := [[5, 5], [7, 6], [7, 7], [7, 8]]


func test_calibration_loads_without_placeholder() -> void:
	var cal := load(PATH) as GridCalibration
	assert_not_null(cal, "grid_calibration.tres carrega")
	assert_false(cal.placeholder, "não é mais placeholder (valores do legado)")


func test_all_used_grids_have_layout_with_existing_texture() -> void:
	var cal := load(PATH) as GridCalibration
	for g in GRIDS:
		var layout: Dictionary = cal.layout_for(g[0], g[1])
		assert_false(layout.is_empty(), "grade %dx%d tem layout" % [g[0], g[1]])
		var tex := str(layout.get("texture", ""))
		assert_true(ResourceLoader.exists(tex), "cenário %s existe" % tex)
		assert_gt(GridCalibration.spacing_of(layout), 0.0, "espaçamento > 0")


func test_balloon_positions_follow_legacy() -> void:
	var cal := load(PATH) as GridCalibration
	# BalloonController.UpdatePos: só 7x6 (y=1.6) e 7x8 (y=0.15) desviam do default 0.75
	assert_eq(cal.balloon_for(5, 5), GridCalibration.DEFAULT_BALLOON, "5x5 usa default")
	assert_eq(cal.balloon_for(7, 7), GridCalibration.DEFAULT_BALLOON, "7x7 usa default")
	assert_lt(cal.balloon_for(7, 6).y, GridCalibration.DEFAULT_BALLOON.y,
		"7x6: balão mais alto (1.6 un.)")
	assert_gt(cal.balloon_for(7, 8).y, GridCalibration.DEFAULT_BALLOON.y,
		"7x8: balão mais baixo (0.15 un.)")
