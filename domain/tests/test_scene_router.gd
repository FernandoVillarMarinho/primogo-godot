extends GutTest
## Tarefa 09 — autoload scene_router: "Voltar" por contexto (BR-040), navegação
## serializada (BR-041) e payload sem static (D-003). Testa a lógica decoplada do
## swap real (que destruiria o runner); o swap em si é exercido só via _prepare/guard.

const RouterScript = preload("res://autoload/scene_router.gd")

var _routers: Array = []


func _fresh_router() -> Node:
	var r := RouterScript.new()
	add_child_autofree(r)  # _ready monta o overlay de fade
	_routers.append(r)
	return r


func after_each() -> void:
	_routers.clear()


# ---------------------------------------------------------------- Voltar (BR-040)

func test_back_map_matches_br040() -> void:
	var r := _fresh_router()
	assert_eq(r.back_target(RouterScript.Context.MENU), RouterScript.QUIT, "Menu → sair do app")
	assert_eq(r.back_target(RouterScript.Context.LEVEL_SELECT), RouterScript.Context.MENU, "Seleção → Menu")
	assert_eq(r.back_target(RouterScript.Context.BOARD), RouterScript.Context.LEVEL_SELECT, "Fase → Seleção")
	assert_eq(r.back_target(RouterScript.Context.TUTORIAL), RouterScript.Context.LEVEL_SELECT, "Tutorial → Seleção")


# ---------------------------------------------------------------- serialização (BR-041)

func test_second_request_ignored_during_transition() -> void:
	var r := _fresh_router()
	watch_signals(r)
	assert_true(r._prepare_navigation(RouterScript.Context.BOARD, {}), "1ª navegação prossegue")
	assert_true(r.is_transitioning(), "entra em transição")
	assert_false(r._prepare_navigation(RouterScript.Context.MENU, {}), "2ª navegação é ignorada")
	assert_signal_emitted(r, "navigation_ignored")
	assert_eq(r.current_context, RouterScript.Context.BOARD, "contexto permanece o da 1ª")


func test_go_back_ignored_during_transition() -> void:
	var r := _fresh_router()
	r._prepare_navigation(RouterScript.Context.BOARD, {})  # trava
	watch_signals(r)
	r.go_back()
	assert_signal_emitted(r, "navigation_ignored")


# ---------------------------------------------------------------- payload (D-003)

func test_payload_travels_and_is_consumed() -> void:
	var r := _fresh_router()
	r._prepare_navigation(RouterScript.Context.BOARD, {"stage": 3, "level": 7})
	assert_eq(r.peek_payload(), {"stage": 3, "level": 7}, "payload viaja com a navegação")
	var p: Dictionary = r.consume_payload()
	assert_eq(p["level"], 7, "consumo devolve o payload")
	assert_eq(r.peek_payload(), {}, "consumo esvazia (não vira static global)")


func test_payload_is_isolated_copy() -> void:
	var r := _fresh_router()
	var src := {"stage": 1, "level": 1}
	r._prepare_navigation(RouterScript.Context.BOARD, src)
	src["level"] = 99  # mutar a origem não deve afetar o payload guardado
	assert_eq(r.peek_payload()["level"], 1, "payload é cópia isolada")


# ---------------------------------------------------------------- overlay de fade

func test_fade_overlay_built_hidden() -> void:
	var r := _fresh_router()
	assert_not_null(r._fade_rect, "overlay de fade criado no _ready")
	assert_eq(r._fade_rect.color.a, 0.0, "começa transparente (cena visível)")
	assert_eq(r._fade_rect.mouse_filter, Control.MOUSE_FILTER_IGNORE, "não intercepta clique quando ocioso")
